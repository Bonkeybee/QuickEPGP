local MODULE_NAME = "QEPGP-Items"

QUICKEPGP.Items = {Array = {}, Deserializing = false}

local function NotifyChanged()
  if QUICKEPGP.Items.ChangeHandlers then
    for callback in pairs(QUICKEPGP.Items.ChangeHandlers) do
      callback()
    end
  end
end

function QUICKEPGP.Items:AddChangeHandler(callback)
  if not self.ChangeHandlers then
    self.ChangeHandlers = {}
  end
  self.ChangeHandlers[callback] = callback
end

function QUICKEPGP.Items:RemoveChangeHandler(callback)
  if self.ChangeHandlers then
    self.ChangeHandlers[callback] = nil
  end
end

function QUICKEPGP.Items:TrackFromBagSlot(bagId, slotId)
  print("Not implemented.", bagId, slotId)
end

function QUICKEPGP.Items:Track(itemIdOrLink, expiration, winner, skipNotify)
  local itemInfo = Item:CreateFromItemID(tonumber(itemIdOrLink) or QUICKEPGP.itemIdFromLink(itemIdOrLink))
  itemInfo:ContinueOnItemLoad(
    function()
      if itemInfo:IsItemEmpty() then
        QUICKEPGP.error("Item with id " .. itemIdOrLink .. " does not exist.")
        return
      end

      local item = {
        Expiration = expiration or (GetServerTime() + 7200),
        Link = itemInfo:GetItemLink(),
        Id = itemInfo:GetItemID(),
        Icon = itemInfo:GetItemIcon(),
        Winner = winner
      }

      function item:GetWinner()
        return self.Winner
      end

      function item:SetWinner(name)
        self.Winner = name
        NotifyChanged()
      end

      function item:RevertWinner()
        if self.Winner then
          local gp = QUICKEPGP.getItemGP(self.Id)
          if gp then
            QUICKEPGP.modifyEPGP(self.Winner, nil, 0 - gp, self.Link)
            self:SetWinner()
          end
        end
      end

      function item:StartRolling()
        QUICKEPGP.startRolling(self.Id, self.Link)
        QUICKEPGP.ROLLING.TrackedItem = self
      end

      self.Array[#self.Array + 1] = item

      table.sort(
        self.Array,
        function(a, b)
          return a.Expiration < b.Expiration
        end
      )

      if not skipNotify then
        NotifyChanged()
      end
    end
  )
end

function QUICKEPGP.Items:Untrack(item)
  for i = 1, #self.Array do
    if item == self.Array[i] then
      local nextIndex = i
      repeat
        self.Array[nextIndex] = self.Array[nextIndex + 1]
        nextIndex = nextIndex + 1
      until not self.Array[nextIndex]
      NotifyChanged()
      break
    end
  end
end

local function Deserialize()
  if QUICKEPGP_LOOT and not QUICKEPGP.Items.Serializing then
    QUICKEPGP.Items.Deserializing = true
    QUICKEPGP.Items.Array = {}
    for _, v in pairs(QUICKEPGP_LOOT) do
      if v and v.Item then
        QUICKEPGP.Items:Track(v.Id, v.Expiration, v.Winner, true)
      end
    end
    NotifyChanged()
    QUICKEPGP.Items.Deserializing = false
  end
end

local function Serialize()
  if not QUICKEPGP.Items.Deserializing then
    QUICKEPGP.Items.Serializing = true
    QUICKEPGP_LOOT = {}
    for k, v in pairs(QUICKEPGP.Items.Array) do
      QUICKEPGP_LOOT[k] = {Id = v.Id, Winner = v.Winner, Expiration = v.Expiration}
    end
    QUICKEPGP.Items.Serializing = false
  end
end

local function IsLootMaster()
  local method, partyId, _ = GetLootMethod()
  return method == "master" and partyId == 0
end

local function Share()
  if IsLootMaster() then
    local message = ""

    for _, v in pairs(QUICKEPGP.Items.Array) do
      message = string.format("%s%s:%s:%s;", message, v.Id, v.Winner, v.Expiration)
    end

    QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, message, "RAID", nil, "BULK")
  end
end

local function FindRef(table, id, expiration)
  for _, v in pairs(table) do
    if v.Id == id and v.Expiration == expiration then
      return v
    end
  end
end

local function Receive(prefix, message, _, sender)
  if prefix == MODULE_NAME and not UnitIsUnit(sender, "player") then
    local entries = {strsplit(";", message)}

    local oldItems = QUICKEPGP.Items.Array
    QUICKEPGP.Items.Array = {}

    for _, v in pairs(entries) do
      local id, winner, expiration = strsplit(":", v)
      id = tonumber(id)
      expiration = tonumber(expiration)
      if id then
        local existing = FindRef(oldItems, id, expiration)
        if existing then
          existing.Winner = winner
          QUICKEPGP.Items.Array[#QUICKEPGP.Items.Array + 1] = existing
        else
          QUICKEPGP.Items:Track(id, expiration, winner, true)
        end
      end
    end

    table.sort(
      QUICKEPGP.Items.Array,
      function(a, b)
        return a.Expiration < b.Expiration
      end
    )

    NotifyChanged()
  end
end

function QUICKEPGP.Items:Initialize()
  Deserialize()
  QUICKEPGP.Items:AddChangeHandler(Serialize)
  QUICKEPGP.Items:AddChangeHandler(Share)
  if CanEditOfficerNote() then
    QUICKEPGP.LIBS:RegisterComm(MODULE_NAME, Receive)
  end
end
