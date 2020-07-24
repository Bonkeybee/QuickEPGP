QUICKEPGP.RaidStandings = {}

local function compareMembersByPR(table, a, b)
    local memberA = table[a]
    local memberB = table[b]
    local prA = (memberA[4] or 0) / (memberA[5] or 50)
    local prB = (memberB[4] or 0) / (memberB[5] or 50)
    return prA > prB
end

local function BuildFrame()
    local root = CreateFrame("Frame", "QuickEPGPRaidStandingsFrame", UIParent)
    tinsert(UISpecialFrames, root:GetName())
    root:SetFrameStrata("DIALOG")
    root:SetSize(350, 500)
    root:SetPoint(QUICKEPGP_OPTIONS.RaidStandings.Point, UIParent, QUICKEPGP_OPTIONS.RaidStandings.Point, QUICKEPGP_OPTIONS.RaidStandings.X, QUICKEPGP_OPTIONS.RaidStandings.Y)
    root:SetClampedToScreen(true)
    root:EnableMouse(true)
    root:SetToplevel(true)
    root:SetMovable(true)
    root:RegisterForDrag("LeftButton")
    root:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
      tile = true,
      tileSize = 16
    })
    root:SetScript("OnDragStart", function(self)
      self:StartMoving()
    end)
    root:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      local point, _, _, x, y = self:GetPoint(1)
      QUICKEPGP_OPTIONS.RaidStandings.X = x
      QUICKEPGP_OPTIONS.RaidStandings.Y = y
      QUICKEPGP_OPTIONS.RaidStandings.Point = point
    end)

    root.numText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    root.numText:SetPoint("LEFT", root, "LEFT", 3, 3)
    root.numText:SetPoint("TOP", root, "TOP", -3, -3)
    root.numText:SetText("1.\n2.\n3.\n4.\n5.\n6.\n7.\n8.\n9.\n10.\n11.\n12.\n13.\n14.\n15.\n16.\n17.\n18.\n19.\n20.\n21.\n22.\n23.\n24.\n25.\n26.\n27.\n28.\n29.\n30.\n31.\n32.\n33.\n34.\n35.\n36.\n37.\n38.\n39.\n40.\n")

    root.nameText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    root.nameText:SetPoint("TOP", root.numText, "TOP", 0, 0)
    root.nameText:SetPoint("LEFT", root.numText, "RIGHT", 0, 0)

    root.prText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    root.prText:SetPoint("TOP", root.numText, "TOP", 0, 0)
    root.prText:SetPoint("LEFT", root.nameText, "RIGHT", 5, 5)

    local closeButton = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
    closeButton:SetText("X")
    closeButton:SetPoint("TOPRIGHT", root, "TOPRIGHT", -3, -3)
    closeButton:Show()
    closeButton:SetScript("OnClick", function()
        QUICKEPGP.RaidStandings:HideFrame()
    end)

    function root:UpdateRaidStandings()
        local raidMembers = {}
        for i = 1,40 do
            local name, _ = UnitName("raid"..i)
            if name then
                local member = QUICKEPGP.guildMember(name, true)
                if member then
                    raidMembers[name] = member
                end
            else
                break
            end
        end

        local i = 1
        local names = ""
        local prs = ""

        for k,v in QUICKEPGP.spairs(raidMembers, compareMembersByPR) do
            local ep = v[4] or 0;
            local gp = v[5] or 50;
            names = names..QUICKEPGP.colorByClass(k, v[6]).."\n"
            prs = format("%s%.2f PR (%d ep / %d gp)\n", prs, ep / gp, ep, gp)
            i = i + 1
        end

        self.nameText:SetText(names)
        self.prText:SetText(prs)
    end

    return root
end

function QUICKEPGP.RaidStandings:ShowFrame()
    if not self.frame then
        self.frame = BuildFrame()
    end
    self.frame:UpdateRaidStandings()
    self.frame:Show()
end

function QUICKEPGP.RaidStandings:HideFrame()
    if self.frame then
        self.frame:Hide()
    end
end

function QUICKEPGP.RaidStandings:ToggleFrame()
    if self.frame and self.frame:IsShown() then
        self:HideFrame()
    else
        self:ShowFrame()
    end
end