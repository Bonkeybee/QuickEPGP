local function getTradableTime(text)
  local isTradeable = strmatch(text, "You may trade this")
  if (isTradeable) then
    local hours = strmatch(text, "(%d+) %a+ %d+")
    local minutes = strmatch(text, "%d+ %a+ (%d+)")
    return hours, minutes
  end
end

local function EnumerateTooltipLines_helper(...)
  for i = 1, select("#", ...) do
    local region = select(i, ...)
    if (region) and region:GetObjectType() == "FontString" then
      local text = region:GetText()
      if (text) then
        local hours, minutes = getTradableTime(text)
        if (hours or minutes) then
          print((hours or 0) .. "hours" + (minutes or 0))
        end
      end
    end
  end
end

local function EnumerateTooltipLines(tooltip)
  EnumerateTooltipLines_helper(tooltip:GetRegions())
end

local function TooltipSetItem(frame)
  if not frame.__hasEPGPTooltip and QUICKEPGP_OPTIONS.TOOLTIP.enabled then
    frame.__hasEPGPTooltip = true
    local _, link = frame:GetItem()
    if link then
      local itemId = QUICKEPGP.itemIdFromLink(link)
      if itemId then
        local gp = QUICKEPGP.getItemGP(itemId, true)
        if gp and gp > 0 then
          frame:AddLine("|cFFFFFF00" .. gp .. " GP|r", 1, 1, 1)
        end

      --EnumerateTooltipLines(frame)
      end
    end
  end
end

local function TooltipClearItem(frame)
  frame.__hasEPGPTooltip = false
end

local function HookTooltip(tooltip)
  tooltip:HookScript("OnTooltipSetItem", TooltipSetItem)
  tooltip:HookScript("OnTooltipCleared", TooltipClearItem)
end

function QUICKEPGP:InitializeTooltip()
  HookTooltip(GameTooltip)
  HookTooltip(ItemRefTooltip)
end
