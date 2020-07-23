
local function TooltipSetItem(frame)
    if not frame.__hasEPGPTooltip and QUICKEPGP_OPTIONS.TOOLTIP.enabled then
        frame.__hasEPGPTooltip = true
        local _, link = frame:GetItem()
        if link then
            local itemId = QUICKEPGP.itemIdFromLink(link)
            if itemId then
                local gp = QUICKEPGP.getItemGP(itemId, true)
                if gp and gp > 0 then
                    frame:AddLine(gp.." GP", 1, 1, 1)
                end
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