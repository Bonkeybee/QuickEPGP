QUICKEPGP.INVENTORY = CreateFrame("Frame")

local tip = CreateFrame("GameTooltip", "QuickEPGP-InvScanner", nil, "GameTooltipTemplate")
local inventory = {}
EPGPINVENTORY = inventory

local function getTradableTime(text)
  local isTradeable = strmatch(text, "You may trade this")
  if (isTradeable) then
    local hours = strmatch(text, "(%d+) %a+ %d+")
    local minutes = strmatch(text, "%d+ %a+ (%d+)")
    return hours, minutes
  end
end

local function EnumerateTooltipLines(bagId, slotId)
  tip:ClearLines()
  tip:SetOwner(UIParent, "ANCHOR_NONE")
  tip:SetBagItem(bagId, slotId)
  for i = 1, select("#", tip:GetRegions()) do
    local region = select(i, tip:GetRegions())
    if (region) and region:GetObjectType() == "FontString" then
      local text = region:GetText()
      if (text) then
        local hours, minutes = getTradableTime(text)
        if (hours or minutes) then
          return hours, minutes
        end
      end
    end
  end
  tip:Hide()
end

local function recordItem(bagId, slotId, hours, minutes)
  local key = bagId .. "," .. slotId
  local _, _, _, _, _, _, itemLink = GetContainerItemInfo(bagId, slotId)
  inventory[key] = {itemLink, hours, minutes}
  print(itemLink .. " " .. hours .. " hours" .. minutes .. "minutes")
end

local function recordAllItems()
  inventory = {}
  for bagId = 0, NUM_BAG_SLOTS do
    for slotId = 1, GetContainerNumSlots(bagId) do
      local hours, minutes = EnumerateTooltipLines(bagId, slotId)
      if (hours or minutes) then
        recordItem(bagId, slotId, hours, minutes)
      end
    end
  end
end

local function onEvent(_, event, arg1)
  if (QUICKEPGP_OPTIONS.LOOTING.enabled) then
    if (event == "PLAYER_ENTERING_WORLD" or event == "BAG_UPDATE") then
    --recordAllItems()
    end
  end
end

QUICKEPGP.INVENTORY:RegisterEvent("PLAYER_ENTERING_WORLD")
QUICKEPGP.INVENTORY:RegisterEvent("BAG_UPDATE")
QUICKEPGP.INVENTORY:SetScript("OnEvent", onEvent)
