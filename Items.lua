QUICKEPGP.Items = {Array = {}}

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

      local index = 0
      for i = 1, #self.Array do
        index = i
        if item.Expiration < self.Array[i].Expiration then
          break
        end
      end

      index = index + 1

      local next = item
      repeat
        local current = self.Array[index]
        self.Array[index] = next
        next = current
        index = index + 1
      until not next

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

function QUICKEPGP.Items:Deserialize()
  if QUICKEPGP_LOOT then
    for _, v in pairs(QUICKEPGP_LOOT) do
      QUICKEPGP.Items:Track(v.Id, v.Expiration, v.Winner, true)
    end
    NotifyChanged()
  end
end

local function Serialize()
  QUICKEPGP_LOOT = {}
  for k, v in pairs(QUICKEPGP.Items.Array) do
    QUICKEPGP_LOOT[k] = {Id = v.Id, Winner = v.Winner, Expiration = v.Expiration}
  end
end

QUICKEPGP.Items:AddChangeHandler(Serialize)
