local oUF_Hank_Banaak = {}
local cfg = oUF_Hank_Banaak_config

local unpack = unpack
local pairs = pairs
local ipairs = ipairs
local select = select
local tinsert = table.insert
local upper = string.upper
local strlen = string.len
local strsub = string.sub
local gmatch = string.gmatch
local match = string.match

oUF_Hank_Banaak.digitTexCoords = {
    ["1"] = { 1, 20 },
    ["2"] = { 21, 31 },
    ["3"] = { 53, 30 },
    ["4"] = { 84, 33 },
    ["5"] = { 118, 30 },
    ["6"] = { 149, 31 },
    ["7"] = { 181, 30 },
    ["8"] = { 212, 31 },
    ["9"] = { 244, 31 },
    ["0"] = { 276, 31 },
    ["%"] = { 308, 17 },
    ["X"] = { 326, 31 }, -- Dead
    ["G"] = { 358, 36 }, -- Ghost
    ["Off"] = { 395, 23 }, -- Offline
    ["B"] = { 419, 42 }, -- Boss
    ["height"] = 42,
    ["texWidth"] = 512,
    ["texHeight"] = 128
}

oUF_Hank_Banaak.classResources = {
    ['PALADIN'] = {
        inactive = { 'Interface\\AddOns\\oUF_Hank_Banaak\\textures\\HolyPower.blp', { 0, 18 / 64, 0, 18 / 32 } },
        active = { 'Interface\\AddOns\\oUF_Hank_Banaak\\textures\\HolyPower.blp', { 18 / 64, 36 / 64, 0, 18 / 32 } },
        size = { 18, 18 },
        max = 5,
    },
    ['MONK'] = {
        inactive = { 'Interface\\PlayerFrame\\MonkNoPower' },
        active = { 'Interface\\PlayerFrame\\MonkLightPower' },
        size = { 20, 20 },
        max = 6,
    },
    ['SHAMAN'] = {
        inactive = { 'Interface\\AddOns\\oUF_Hank_Banaak\\textures\\blank.blp', { 0, 23 / 128, 0, 20 / 32 } },
        active = { 'Interface\\AddOns\\oUF_Hank_Banaak\\textures\\totems.blp', { (1 + 23) / 128, ((23 * 2) + 1) / 128, 0, 20 / 32 } },
        size = { 23, 20 },
        spacing = -3,
        inverse = true,
        max = 3,
    },
    ['WARLOCK'] = {
        inactive = { 'Interface\\AddOns\\oUF_Hank_Banaak\\textures\\shard_bg.blp' },
        active = { 'Interface\\AddOns\\oUF_Hank_Banaak\\textures\\shard.blp' },
        size = { 16, 16 },
        spacing = 5,
        max = 6,
    },
    ['DRUID'] = {
        inactive = { 'Interface\\PlayerFrame\\MonkNoPower' },
        active = { 'Interface\\PlayerFrame\\MonkLightPower' },
        size = { 20, 20 },
        max = 5,
    }
}

local fntBig = CreateFont("UFFontBig")
fntBig:SetFont(unpack(cfg.FontStyleBig))
local fntMedium = CreateFont("UFFontMedium")
fntMedium:SetFont(unpack(cfg.FontStyleMedium))
fntMedium:SetTextColor(unpack(cfg.colors.text))
fntMedium:SetShadowColor(unpack(cfg.colors.textShadow))
fntMedium:SetShadowOffset(1, -1)
local fntSmall = CreateFont("UFFontSmall")
fntSmall:SetFont(unpack(cfg.FontStyleSmall))
fntSmall:SetTextColor(unpack(cfg.colors.text))
fntSmall:SetShadowColor(unpack(cfg.colors.textShadow))
fntSmall:SetShadowOffset(1, -1)

local canDispel = {}

-- Functions -------------------------------------

-- Unit menu
oUF_Hank_Banaak.menu = function(self)
    local unit = self.unit:sub(1, -2)
    local cunit = self.unit:gsub("(.)", upper, 1)

    -- Swap menus in vehicle
    if self == oUF_player and cunit == "Vehicle" then cunit = "Player" end
    if self == oUF_pet and cunit == "Player" then cunit = "Pet" end

    if (unit == "party" or unit == "partypet") then
        ToggleDropDownMenu(nil, nil, _G["PartyMemberFrame" .. self.id .. "DropDown"], "cursor", 0, 0)
    elseif (_G[cunit .. "FrameDropDown"]) then
        ToggleDropDownMenu(nil, nil, _G[cunit .. "FrameDropDown"], "cursor", 0, 0)
    end
end

-- Party frames be gone!
oUF_Hank_Banaak.HideParty = function()
    for i = 1, 4 do
        local party = "PartyMemberFrame" .. i
        local frame = _G[party]

        frame:UnregisterAllEvents()
        frame.Show = function() end
        frame:Hide()

        _G[party .. "HealthBar"]:UnregisterAllEvents()
        _G[party .. "ManaBar"]:UnregisterAllEvents()
    end
end

-- Set up the mirror bars (breath, exhaustion etc.)
oUF_Hank_Banaak.AdjustMirrorBars = function()
    for k, v in pairs(MirrorTimerColors) do
        MirrorTimerColors[k].r = cfg.colors.castbar.bar[1]
        MirrorTimerColors[k].g = cfg.colors.castbar.bar[2]
        MirrorTimerColors[k].b = cfg.colors.castbar.bar[3]
    end

    for i = 1, MIRRORTIMER_NUMTIMERS do
        local mirror = _G["MirrorTimer" .. i]
        local statusbar = _G["MirrorTimer" .. i .. "StatusBar"]
        local backdrop = select(1, mirror:GetRegions())
        local border = _G["MirrorTimer" .. i .. "Border"]
        local text = _G["MirrorTimer" .. i .. "Text"]

        mirror:ClearAllPoints()
        mirror:SetPoint("BOTTOM", (i == 1) and oUF_player.Castbar or _G["MirrorTimer" .. i - 1], "TOP", 0, 5 + ((i == 1) and 5 or 0))
        mirror:SetSize(cfg.CastbarSize[1], 12)
        statusbar:SetStatusBarTexture(cfg.CastbarTexture)
        statusbar:SetAllPoints(mirror)
        backdrop:SetTexture(cfg.CastbarBackdropTexture)
        backdrop:SetVertexColor(0.22, 0.22, 0.19, 0.8)
        backdrop:SetAllPoints(mirror)
        border:Hide()
        text:SetFont(unpack(cfg.CastBarMedium))
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")
        text:ClearAllPoints()
        text:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 10, 0)
        text:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -10, 0)
    end
end

-- Update the dispel table after talent changes
oUF_Hank_Banaak.UpdateDispel = function()
    canDispel = {
        ["DEMONHUNTER"] = {},
        ["DEATHKNIGHT"] = {},
        ["DRUID"] = { ["Poison"] = true, ["Curse"] = true, ["Magic"] = (GetSpecialization() == 4) },
        ["HUNTER"] = {},
        ["MAGE"] = { ["Curse"] = true },
        ["MONK"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = (GetSpecialization() == 2) },
        ["PALADIN"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = (GetSpecialization() == 1) },
        ["PRIEST"] = { ["Disease"] = true, ["Magic"] = (GetSpecialization() ~= 3) },
        ["ROGUE"] = {},
        ["SHAMAN"] = { ["Curse"] = true, ["Magic"] = (GetSpecialization() == 3) },
        ["WARLOCK"] = { ["Magic"] = true },
        ["WARRIOR"] = {},
    }
end

-- This is where the magic happens. Handle health update, display digit textures
oUF_Hank_Banaak.UpdateHealth = function(self)
    -- self.unit == "vehicle" works fine
    local h, hMax = UnitHealth(self.unit), UnitHealthMax(self.unit)

    local status = (not UnitIsConnected(self.unit) or nil) and "Off" or UnitIsGhost(self.unit) and "G" or UnitIsDead(self.unit) and "X"

    if not status then
        local hPerc = ("%d%%"):format(h / hMax * 100 + 0.5)
        local len = strlen(hPerc)

        if self.unit:find("boss") then
            self.health[1]:SetSize(oUF_Hank_Banaak.digitTexCoords["B"][2], oUF_Hank_Banaak.digitTexCoords["height"])
            self.health[1]:SetTexCoord(oUF_Hank_Banaak.digitTexCoords["B"][1] / oUF_Hank_Banaak.digitTexCoords["texWidth"], (oUF_Hank_Banaak.digitTexCoords["B"][1] + oUF_Hank_Banaak.digitTexCoords["B"][2]) / oUF_Hank_Banaak.digitTexCoords["texWidth"], 1 / oUF_Hank_Banaak.digitTexCoords["texHeight"], (1 + oUF_Hank_Banaak.digitTexCoords["height"]) / oUF_Hank_Banaak.digitTexCoords["texHeight"])
            self.health[1]:Show()
            self.healthFill[1]:SetSize(oUF_Hank_Banaak.digitTexCoords["B"][2], oUF_Hank_Banaak.digitTexCoords["height"] * h / hMax)
            self.healthFill[1]:SetTexCoord(
                oUF_Hank_Banaak.digitTexCoords["B"][1] / oUF_Hank_Banaak.digitTexCoords["texWidth"],
                (oUF_Hank_Banaak.digitTexCoords["B"][1] + oUF_Hank_Banaak.digitTexCoords["B"][2]) / oUF_Hank_Banaak.digitTexCoords["texWidth"],
                (2 + 2 * oUF_Hank_Banaak.digitTexCoords["height"] - oUF_Hank_Banaak.digitTexCoords["height"] * h / hMax) / oUF_Hank_Banaak.digitTexCoords["texHeight"],
                (2 + 2 * oUF_Hank_Banaak.digitTexCoords["height"]) / oUF_Hank_Banaak.digitTexCoords["texHeight"]
            )
            self.healthFill[1]:Show()
        else
            for i = 1, 4 do
                if i > len then
                    self.health[5 - i]:Hide()
                    self.healthFill[5 - i]:Hide()
                else
                    local digit
                    if self == oUF_player then
                        digit = strsub(hPerc, -i, -i)
                    elseif self == oUF_target or self == oUF_focus then
                        digit = strsub(hPerc, i, i)
                    end
                    self.health[5 - i]:SetSize(oUF_Hank_Banaak.digitTexCoords[digit][2], oUF_Hank_Banaak.digitTexCoords["height"])
                    self.health[5 - i]:SetTexCoord(oUF_Hank_Banaak.digitTexCoords[digit][1] / oUF_Hank_Banaak.digitTexCoords["texWidth"], (oUF_Hank_Banaak.digitTexCoords[digit][1] + oUF_Hank_Banaak.digitTexCoords[digit][2]) / oUF_Hank_Banaak.digitTexCoords["texWidth"], 1 / oUF_Hank_Banaak.digitTexCoords["texHeight"], (1 + oUF_Hank_Banaak.digitTexCoords["height"]) / oUF_Hank_Banaak.digitTexCoords["texHeight"])
                    self.health[5 - i]:Show()
                    self.healthFill[5 - i]:SetSize(oUF_Hank_Banaak.digitTexCoords[digit][2], oUF_Hank_Banaak.digitTexCoords["height"] * h / hMax)
                    self.healthFill[5 - i]:SetTexCoord(oUF_Hank_Banaak.digitTexCoords[digit][1] / oUF_Hank_Banaak.digitTexCoords["texWidth"], (oUF_Hank_Banaak.digitTexCoords[digit][1] + oUF_Hank_Banaak.digitTexCoords[digit][2]) / oUF_Hank_Banaak.digitTexCoords["texWidth"], (2 + 2 * oUF_Hank_Banaak.digitTexCoords["height"] - oUF_Hank_Banaak.digitTexCoords["height"] * h / hMax) / oUF_Hank_Banaak.digitTexCoords["texHeight"], (2 + 2 * oUF_Hank_Banaak.digitTexCoords["height"]) / oUF_Hank_Banaak.digitTexCoords["texHeight"])
                    self.healthFill[5 - i]:Show()
                end
            end

            if self == oUF_player then
                self.power:SetPoint("BOTTOMRIGHT", self.health[5 - len], "BOTTOMLEFT", -5, 0)
            elseif self == oUF_target or self == oUF_focus then
                self.power:SetPoint("BOTTOMLEFT", self.health[5 - len], "BOTTOMRIGHT", 5, 0)
            end
        end
    else
        if self.unit:find("boss") then
            self.healthFill[1]:Hide()
            self.health[1]:SetSize(oUF_Hank_Banaak.digitTexCoords[status][2], oUF_Hank_Banaak.digitTexCoords["height"])
            self.health[1]:SetTexCoord(oUF_Hank_Banaak.digitTexCoords[status][1] / oUF_Hank_Banaak.digitTexCoords["texWidth"], (oUF_Hank_Banaak.digitTexCoords[status][1] + oUF_Hank_Banaak.digitTexCoords[status][2]) / oUF_Hank_Banaak.digitTexCoords["texWidth"], 1 / oUF_Hank_Banaak.digitTexCoords["texHeight"], (1 + oUF_Hank_Banaak.digitTexCoords["height"]) / oUF_Hank_Banaak.digitTexCoords["texHeight"])
            self.health[1]:Show()
        else
            for i = 1, 4 do
                self.healthFill[i]:Hide()
                self.health[i]:Hide()
            end

            self.health[4]:SetSize(oUF_Hank_Banaak.digitTexCoords[status][2], oUF_Hank_Banaak.digitTexCoords["height"])
            self.health[4]:SetTexCoord(oUF_Hank_Banaak.digitTexCoords[status][1] / oUF_Hank_Banaak.digitTexCoords["texWidth"], (oUF_Hank_Banaak.digitTexCoords[status][1] + oUF_Hank_Banaak.digitTexCoords[status][2]) / oUF_Hank_Banaak.digitTexCoords["texWidth"], 1 / oUF_Hank_Banaak.digitTexCoords["texHeight"], (1 + oUF_Hank_Banaak.digitTexCoords["height"]) / oUF_Hank_Banaak.digitTexCoords["texHeight"])
            self.health[4]:Show()

            if self == oUF_player then
                self.power:SetPoint("BOTTOMRIGHT", self.health[4], "BOTTOMLEFT", -5, 0)
            elseif self == oUF_target or self == oUF_focus then
                self.power:SetPoint("BOTTOMLEFT", self.health[4], "BOTTOMRIGHT", 5, 0)
            end
        end
    end
end

-- Manual status icons update
oUF_Hank_Banaak.UpdateStatus = function(self)
    local referenceElement
    -- TODO find a better way to do this
    hasAdditionalPower = {
        ["DEMONHUNTER"] = false,
        ["DEATHKNIGHT"] = false,
        ["DRUID"] = (GetSpecialization() ~= 4),
        ["HUNTER"] = false,
        ["MAGE"] = false,
        ["MONK"] = false,
        ["PALADIN"] = false,
        ["PRIEST"] = (GetSpecialization() == 3),
        ["ROGUE"] = false,
        ["SHAMAN"] = (GetSpecialization() == 1 or GetSpecialization() == 2),
        ["WARLOCK"] = false,
        ["WARRIOR"] = false,
    }
    if cfg.AdditionalPower and self.additionalPower and hasAdditionalPower[select(2, UnitClass("player"))] then
        referenceElement = self.additionalPower
    else
        referenceElement = self.power
    end
    -- Attach the first icon to the right border of self.power
    local lastElement = { "BOTTOMRIGHT", referenceElement, "TOPRIGHT" }

    -- Status icon texture names and conditions
    local icons = {
        ["C"] = { "CombatIndicator", UnitAffectingCombat("player") },
        ["R"] = { "RestingIndicator", IsResting() },
        ["L"] = { "LeaderIndicator", UnitIsGroupLeader("player") },
        ["M"] = { "MasterLooterIndicator", ({ GetLootMethod() })[1] == "master" and (
            (({ GetLootMethod() })[2]) == 0 or
                ((({ GetLootMethod() })[2]) and UnitIsUnit("player", "party" .. ({ GetLootMethod() })[2])) or
                ((({ GetLootMethod() })[3]) and UnitIsUnit("player", "raid" .. ({ GetLootMethod() })[3]))
            ) },
        ["P"] = { "PvPIndicator", UnitIsPVPFreeForAll("player") or UnitIsPVP("player") },
        ["A"] = { "AssistantIndicator", UnitInRaid("player") and UnitIsGroupAssistant("player") and not UnitIsGroupLeader("player") },
    }

    for i = -1, -strlen(cfg.StatusIcons), -1 do
        if icons[strsub(cfg.StatusIcons, i, i)][2] then
            self[icons[strsub(cfg.StatusIcons, i, i)][1]]:ClearAllPoints()
            self[icons[strsub(cfg.StatusIcons, i, i)][1]]:SetPoint(unpack(lastElement))
            self[icons[strsub(cfg.StatusIcons, i, i)][1]]:Show()
            -- Arrange any successive icon to the last one
            lastElement = { "RIGHT", self[icons[strsub(cfg.StatusIcons, i, i)][1]], "LEFT" }
        else
            -- Condition for displaying the icon not met
            self[icons[strsub(cfg.StatusIcons, i, i)][1]]:Hide()
        end
    end
end

-- Reanchoring / -sizing on name update
oUF_Hank_Banaak.PostUpdateName = function(self)
    if (self.name) then
        -- Reanchor raid icon to the largest string (either name or power)
        if self.name:GetWidth() >= self.power:GetWidth() then
            self.RaidTargetIndicator:SetPoint("LEFT", self.name, "RIGHT", 10, 0)
        else
            self.RaidTargetIndicator:SetPoint("LEFT", self.power, "RIGHT", 10, 0)
        end
    end
end

-- Sticky aura colors
oUF_Hank_Banaak.PostUpdateIcon = function(icons, unit, icon, index, offset)
    -- We want the border, not the color for the type indication
    icon.overlay:SetVertexColor(1, 1, 1)

    local _, _, _, dtype, _, _, caster, _, _, _ = UnitAura(unit, index, icon.filter)
    if caster == "vehicle" then caster = "player" end

    if icon.filter == "HELPFUL" and not UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. upper(unit)].StickyAuras.myBuffs then
        -- Sticky aura: myBuffs
        icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
        icon.icon:SetDesaturated(false)
    elseif icon.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. upper(unit)].StickyAuras.myDebuffs then
        -- Sticky aura: myDebuffs
        icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
        icon.icon:SetDesaturated(false)
    elseif icon.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "pet" and cfg["Auras" .. upper(unit)].StickyAuras.petDebuffs then
        -- Sticky aura: petDebuffs
        icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
        icon.icon:SetDesaturated(false)
    elseif icon.filter == "HARMFUL" and not UnitCanAttack("player", unit) and canDispel[({ UnitClass("player") })[2]][dtype] and cfg["Auras" .. upper(unit)].StickyAuras.curableDebuffs then
        -- Sticky aura: curableDebuffs
        icon.icon:SetVertexColor(DebuffTypeColor[dtype].r, DebuffTypeColor[dtype].g, DebuffTypeColor[dtype].b)
        icon.icon:SetDesaturated(false)
    elseif icon.filter == "HELPFUL" and UnitCanAttack("player", unit) and UnitIsUnit(unit, caster or "") and cfg["Auras" .. upper(unit)].StickyAuras.enemySelfBuffs then
        -- Sticky aura: enemySelfBuffs
        icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
        icon.icon:SetDesaturated(false)
    else
        icon.icon:SetVertexColor(1, 1, 1)
        icon.icon:SetDesaturated(true)
    end
end

-- Custom filters
oUF_Hank_Banaak.customFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
    if caster == "vehicle" then caster = "player" end
    if icons.filter == "HELPFUL" and not UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. upper(unit)].StickyAuras.myBuffs then
        -- Sticky aura: myBuffs
        return true
    elseif icons.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. upper(unit)].StickyAuras.myDebuffs then
        -- Sticky aura: myDebuffs
        return true
    elseif icons.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "pet" and cfg["Auras" .. upper(unit)].StickyAuras.petDebuffs then
        -- Sticky aura: petDebuffs
        return true
    elseif icons.filter == "HARMFUL" and not UnitCanAttack("player", unit) and canDispel[({ UnitClass("player") })[2]][dtype] and cfg["Auras" .. upper(unit)].StickyAuras.curableDebuffs then
        -- Sticky aura: curableDebuffs, enemySelfBuffs
        return true
    else
        -- Aura is not sticky, filter is set to blacklist
        if cfg["Auras" .. upper(unit)].FilterMethod[icons.filter == "HELPFUL" and "Buffs" or "Debuffs"] == "BLACKLIST" then
            for _, v in ipairs(cfg["Auras" .. upper(unit)].BlackList) do
                if v == name then
                    return false
                end
            end
            return true
            -- Aura is not sticky, filter is set to whitelist
        elseif cfg["Auras" .. upper(unit)].FilterMethod[icons.filter == "HELPFUL" and "Buffs" or "Debuffs"] == "WHITELIST" then
            for _, v in ipairs(cfg["Auras" .. upper(unit)].WhiteList) do
                if v == name then
                    return true
                end
            end
            return false
            -- Aura is not sticky, filter is set to none
        else
            return true
        end
    end
end

-- Aura mouseover
oUF_Hank_Banaak.OnEnterAura = function(self, icon)
    -- Aura magnification
    if icon.isDebuff then
        self.HighlightAura:SetSize(cfg.DebuffSize * cfg.AuraMagnification, cfg.DebuffSize * cfg.AuraMagnification)
        self.HighlightAura.icon:SetSize(cfg.DebuffSize * cfg.AuraMagnification, cfg.DebuffSize * cfg.AuraMagnification)
        self.HighlightAura.border:SetSize(cfg.DebuffSize * cfg.AuraMagnification * 1.1, cfg.DebuffSize * cfg.AuraMagnification * 1.1)
        self.HighlightAura:SetPoint("TOPLEFT", icon, "TOPLEFT", -(cfg.DebuffSize * cfg.AuraMagnification - cfg.DebuffSize) / 2, (cfg.DebuffSize * cfg.AuraMagnification - cfg.DebuffSize) / 2)
    else
        self.HighlightAura:SetSize(cfg.BuffSize * cfg.AuraMagnification, cfg.BuffSize * cfg.AuraMagnification)
        self.HighlightAura.icon:SetSize(cfg.BuffSize * cfg.AuraMagnification, cfg.BuffSize * cfg.AuraMagnification)
        self.HighlightAura.border:SetSize(cfg.BuffSize * cfg.AuraMagnification * 1.1, cfg.BuffSize * cfg.AuraMagnification * 1.1)
        self.HighlightAura:SetPoint("TOPLEFT", icon, "TOPLEFT", -(cfg.BuffSize * cfg.AuraMagnification - cfg.BuffSize) / 2, (cfg.BuffSize * cfg.AuraMagnification - cfg.BuffSize) / 2)
    end
    self.HighlightAura.icon:SetTexture(icon.icon:GetTexture())
    self.HighlightAura:Show()
end

-- Aura mouseout
oUF_Hank_Banaak.OnLeaveAura = function(self)
    self.HighlightAura:Hide()
end

-- Hook aura scripts, set aura border
oUF_Hank_Banaak.PostCreateIcon = function(icons, icon)
    if cfg.AuraBorder then
        -- Custom aura border
        icon.overlay:SetTexture(cfg.AuraBorder)
        icon.overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
        icon.overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
        icon.overlay:SetTexCoord(0, 1, 0, 1)
        icons.showType = true
    end
    icon.cd:SetReverse(true)
    icon:HookScript("OnEnter", function() oUF_Hank_Banaak.OnEnterAura(icons:GetParent(), icon) end)
    icon:HookScript("OnLeave", function() oUF_Hank_Banaak.OnLeaveAura(icons:GetParent()) end)
    -- Cancel player buffs on right click
    icon:HookScript("OnClick", function(_, button, down)
        if button == "RightButton" and down == false then
            if icon.filter == "HELPFUL" and UnitIsUnit("player", icons:GetParent().unit) then
                CancelUnitBuff("player", icon:GetID())
                oUF_Hank_Banaak.OnLeaveAura(icons:GetParent())
            end
        end
    end)
end

-- Debuff anchoring
oUF_Hank_Banaak.PreSetPosition = function(buffs, max)
    if buffs.visibleBuffs > 0 then
        -- Anchor debuff frame to bottomost buff icon, i.e the last buff row
        buffs:GetParent().Debuffs:SetPoint("TOP", buffs[buffs.visibleBuffs], "BOTTOM", 0, -cfg.AuraSpacing - 2)
    else
        -- No buffs
        if buffs:GetParent().CPoints then
            buffs:GetParent().Debuffs:SetPoint("TOP", buffs:GetParent().CPoints[1], "BOTTOM", 0, -10)
        else
            buffs:GetParent().Debuffs:SetPoint("TOP", buffs:GetParent(), "BOTTOM", 0, -10)
        end
    end
end

-- Castbar
oUF_Hank_Banaak.PostCastStart = function(castbar, unit, name, rank, castid)
    castbar.castIsChanneled = false
    if unit == "vehicle" then unit = "player" end

    if unit ~= "focus" then
        -- Cast layout
        castbar.Text:SetJustifyH("LEFT")
        castbar.Time:SetJustifyH("LEFT")
        if cfg.CastbarIcon then castbar.Dummy.Icon:SetTexture(castbar.Icon:GetTexture()) end
    end

    -- Uninterruptible spells
    if castbar.Shield:IsShown() and UnitCanAttack("player", unit) then
        castbar.Background:SetBackdropBorderColor(unpack(cfg.colors.castbar.noInterrupt))
    else
        castbar.Background:SetBackdropBorderColor(0, 0, 0)
    end
end

oUF_Hank_Banaak.PostChannelStart = function(castbar, unit, name, rank)
    castbar.castIsChanneled = true
    if unit == "vehicle" then unit = "player" end

    if unit ~= "focus" then
        -- Channel layout
        castbar.Text:SetJustifyH("RIGHT")
        castbar.Time:SetJustifyH("RIGHT")
        if cfg.CastbarIcon then castbar.Dummy.Icon:SetTexture(castbar.Icon:GetTexture()) end
    end

    if castbar.Shield:IsShown() and UnitCanAttack("player", unit) then
        castbar.Background:SetBackdropBorderColor(unpack(cfg.colors.castbar.noInterrupt))
    else
        castbar.Background:SetBackdropBorderColor(0, 0, 0)
    end
end

-- Castbar animations
oUF_Hank_Banaak.PostCastSucceeded = function(castbar, spell)
    -- No animation on instant casts (castbar text not set)
    if castbar.Text:GetText() == spell then
        castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castSuccess))
        castbar.Dummy:Show()
        castbar.Dummy.anim:Play()
    end
end

oUF_Hank_Banaak.PostCastStop = function(castbar, unit, spellname, spellrank, castid)
    if not castbar.Dummy.anim:IsPlaying() then
        castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castFail))
        castbar.Dummy:Show()
        castbar.Dummy.anim:Play()
    end
end

oUF_Hank_Banaak.PostChannelStop = function(castbar, unit, spellname, spellrank)
    if not spellname then
        castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castSuccess))
        castbar.Dummy:Show()
        castbar.Dummy.anim:Play()
    else
        castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castFail))
        castbar.Dummy:Show()
        castbar.Dummy.anim:Play()
    end
end

oUF_Hank_Banaak.PostSpawnFrames = function(this)
    -- custom_modifications function
    oUF_Hank_Banaak.UpdateDispel()
end

-- Frame constructor -----------------------------

oUF_Hank_Banaak.sharedStyle = function(self, unit, isSingle)
    self.menu = oUF_Hank_Banaak.menu
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    self:RegisterForClicks("AnyDown")
    self:SetAttribute("*type2", "menu")

    self.colors = cfg.colors

    -- Update dispel table on talent update
    if unit == "player" then self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", oUF_Hank_Banaak.UpdateDispel, true) end
    if unit == "player" then self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", oUF_Hank_Banaak.UpdateStatus, true) end

    -- HP%
    local health = {}
    local healthFill = {}

    if unit == "player" or unit == "target" or unit == "focus" or unit:find("boss") then
        self:RegisterEvent("UNIT_HEALTH", function(_, _, ...)
            if unit == ... then
                oUF_Hank_Banaak.UpdateHealth(self)
            elseif unit == "player" and UnitHasVehicleUI("player") and ... == "vehicle" then
                oUF_Hank_Banaak.UpdateHealth(self)
            end
        end)

        self:RegisterEvent("UNIT_MAXHEALTH", function(_, _, ...)
            if unit == ... then
                oUF_Hank_Banaak.UpdateHealth(self)
            elseif unit == "player" and UnitHasVehicleUI("player") and ... == "vehicle" then
                oUF_Hank_Banaak.UpdateHealth(self)
            end
        end)

        -- Health update on unit switch
        -- Thanks @ pelim for this approach
        tinsert(self.__elements, oUF_Hank_Banaak.UpdateHealth)

        for i = unit:find("boss") and 1 or 4, 1, -1 do
            health[i] = self:CreateTexture(nil, "ARTWORK")
            health[i]:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\digits.blp")
            health[i]:Hide()
            healthFill[i] = self:CreateTexture(nil, "OVERLAY")
            healthFill[i]:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\digits.blp")
            healthFill[i]:SetVertexColor(unpack(cfg.colors.text))
            healthFill[i]:Hide()
        end

        if unit == "player" then
            health[4]:SetPoint("RIGHT")
            health[3]:SetPoint("RIGHT", health[4], "LEFT")
            health[2]:SetPoint("RIGHT", health[3], "LEFT")
            health[1]:SetPoint("RIGHT", health[2], "LEFT")
        elseif unit == "target" or unit == "focus" then
            health[4]:SetPoint("LEFT")
            health[3]:SetPoint("LEFT", health[4], "RIGHT")
            health[2]:SetPoint("LEFT", health[3], "RIGHT")
            health[1]:SetPoint("LEFT", health[2], "RIGHT")
        elseif unit:find("boss") then
            health[1]:SetPoint("RIGHT")
        end

        if not unit:find("boss") then
            healthFill[4]:SetPoint("BOTTOM", health[4])
            healthFill[3]:SetPoint("BOTTOM", health[3])
            healthFill[2]:SetPoint("BOTTOM", health[2])
        end
        healthFill[1]:SetPoint("BOTTOM", health[1])

        self.health = health
        self.healthFill = healthFill

        -- Reanchoring handled in UpdateHealth()
    end

    local name, power
    local playerClass = select(2, UnitClass("player"))

    -- Power, threat
    if unit == "player" or unit == "target" or unit == "focus" or unit:find("boss") then
        power = self:CreateFontString(nil, "OVERLAY")
        power:SetFontObject("UFFontMedium")

        if unit == "player" then power:SetPoint("BOTTOMRIGHT", health[4], "BOTTOMLEFT", -5, 0)
        elseif unit == "target" or unit == "focus" then power:SetPoint("BOTTOMLEFT", health[4], "BOTTOMRIGHT", 5, 0)
        elseif unit:find("boss") then power:SetPoint("BOTTOMRIGHT", health[1], "BOTTOMLEFT", -5, 0) end

        if unit == "player" then self:Tag(power, "[ppDetailed]")
        elseif unit == "target" or unit == "focus" then self:Tag(power, cfg.ShowThreat and "[hpDetailed] || [ppDetailed] [threatPerc]" or "[hpDetailed] || [ppDetailed]")
        elseif unit:find("boss") then self:Tag(power, cfg.ShowThreat and "[threatBoss] || [perhp]%" or "[perhp]%") end

        self.power = power
    end

    -- Name
    if unit == "target" or unit == "focus" then
        name = self:CreateFontString(nil, "OVERLAY")
        name:SetFontObject("UFFontBig")
        name:SetPoint("BOTTOMLEFT", power, "TOPLEFT")
        self:Tag(name, "[statusName]")
    elseif unit:find("boss") then
        name = self:CreateFontString(nil, "OVERLAY")
        name:SetFontObject("UFFontBig")
        name:SetPoint("BOTTOMRIGHT", power, "TOPRIGHT")
        self:Tag(name, "[statusName]")
    elseif unit == "pet" then
        name = self:CreateFontString(nil, "OVERLAY")
        name:SetFontObject("UFFontSmall")
        name:SetPoint("RIGHT")
        self:Tag(name, "[petName] @[perhp]%")
    elseif unit == "targettarget" or unit == "targettargettarget" or unit == "focustarget" then
        name = self:CreateFontString(nil, "OVERLAY")
        name:SetFontObject("UFFontSmall")
        name:SetPoint("LEFT")
        if unit == "targettarget" or unit == "focustarget" then self:Tag(name, "\226\128\186  [smartName] @[perhp]%")
        elseif unit == "targettargettarget" then self:Tag(name, "\194\187 [smartName] @[perhp]%") end
    end

    self.name = name

    -- Status icons
    if unit == "player" then
        -- Remove invalid or duplicate placeholders
        local fixedString = ""

        for placeholder in gmatch(cfg.StatusIcons, "[CRPMAL]") do
            fixedString = fixedString .. (match(fixedString, placeholder) and "" or placeholder)
        end

        cfg.StatusIcons = fixedString

        -- Create the status icons
        for i, icon in ipairs({
            { "C", "CombatIndicator" },
            { "R", "RestingIndicator" },
            { "L", "LeaderIndicator" },
            { "M", "MasterLooterIndicator" },
            { "P", "PvPIndicator" },
            { "A", "AssistantIndicator" },
        }) do
            if match(cfg.StatusIcons, icon[1]) then
                self[icon[2]] = self:CreateTexture(nil, "OVERLAY")
                self[icon[2]]:SetSize(24, 24)
                self[icon[2]]:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\statusicons.blp")
                self[icon[2]]:SetTexCoord((i - 1) * 24 / 256, i * 24 / 256, 0, 24 / 32)
                self[icon[2]].Override = oUF_Hank_Banaak.UpdateStatus
            end

        end

        -- Anchoring handled in UpdateStatus()
    end

    -- Raid targets
    if unit == "player" then
        self.RaidTargetIndicator = self:CreateTexture(nil, "OVERLAY")
        self.RaidTargetIndicator:SetSize(40, 40)
        self.RaidTargetIndicator:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\raidicons.blp")
        self.RaidTargetIndicator:SetPoint("RIGHT", self.power, "LEFT", -15, 0)
        self.RaidTargetIndicator:SetPoint("TOP", self, "TOP", 0, -5)
    elseif unit == "target" or unit == "focus" then
        self.RaidTargetIndicator = self:CreateTexture(nil, "OVERLAY")
        self.RaidTargetIndicator:SetSize(40, 40)
        self.RaidTargetIndicator:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\raidicons.blp")
        self.RaidTargetIndicator:SetPoint("LEFT", self.name, "RIGHT", 10, 0)
        self.RaidTargetIndicator:SetPoint("TOP", self, "TOP", 0, -5)

        -- Anchoring on name update
        tinsert(self.__elements, oUF_Hank_Banaak.PostUpdateName)
        self:RegisterEvent("PLAYER_FLAGS_CHANGED", function(_, _, unit)
            if unit == self.unit then
                oUF_Hank_Banaak.PostUpdateName(unit)
            end
        end)
    elseif unit:find("boss") then
        self.RaidTargetIndicator = self:CreateTexture(nil)
        self.RaidTargetIndicator:SetDrawLayer("OVERLAY", 1)
        self.RaidTargetIndicator:SetSize(24, 24)
        self.RaidTargetIndicator:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\raidicons.blp")
        self.RaidTargetIndicator:SetPoint("BOTTOMRIGHT", health[1], 5, -5)
    end

    -- XP, reputation
    if unit == "player" and cfg.ShowXP then
        local xprep = self:CreateFontString(nil, "OVERLAY")
        xprep:SetFontObject("UFFontMedium")
        xprep:SetPoint("RIGHT", power, "RIGHT")
        xprep:SetAlpha(0)
        self:Tag(xprep, "[xpRep]")
        self.xprep = xprep

        -- Some animation dummies
        local xprepDummy = self:CreateFontString(nil, "OVERLAY")
        xprepDummy:SetFontObject("UFFontMedium")
        xprepDummy:SetAllPoints(xprep)
        xprepDummy:SetAlpha(0)
        xprepDummy:Hide()
        local powerDummy = self:CreateFontString(nil, "OVERLAY")
        powerDummy:SetFontObject("UFFontMedium")
        powerDummy:SetAllPoints(power)
        powerDummy:Hide()
        local raidIconDummy = self:CreateTexture(nil, "OVERLAY")
        raidIconDummy:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\raidicons.blp")
        raidIconDummy:SetAllPoints(self.RaidTargetIndicator)
        raidIconDummy:Hide()

        local animXPFadeIn = xprepDummy:CreateAnimationGroup()
        -- A short delay so the user needs to mouseover a short time for the xp/rep display to show up
        local delayXP = animXPFadeIn:CreateAnimation("Alpha")
        delayXP:SetFromAlpha(0)
        delayXP:SetToAlpha(0)
        delayXP:SetDuration(cfg.DelayXP)
        delayXP:SetOrder(1)
        local alphaInXP = animXPFadeIn:CreateAnimation("Alpha")
        alphaInXP:SetFromAlpha(0)
        alphaInXP:SetToAlpha(1)
        alphaInXP:SetSmoothing("OUT")
        alphaInXP:SetDuration(1.5)
        alphaInXP:SetOrder(2)

        local animPowerFadeOut = powerDummy:CreateAnimationGroup()
        local delayPower = animPowerFadeOut:CreateAnimation("Alpha")
        delayPower:SetFromAlpha(1)
        delayPower:SetToAlpha(1)
        delayPower:SetDuration(cfg.DelayXP)
        delayPower:SetOrder(1)
        local alphaOutPower = animPowerFadeOut:CreateAnimation("Alpha")
        alphaOutPower:SetFromAlpha(1)
        alphaOutPower:SetToAlpha(0)
        alphaOutPower:SetSmoothing("OUT")
        alphaOutPower:SetDuration(1.5)
        alphaOutPower:SetOrder(2)

        local animRaidIconFadeOut = raidIconDummy:CreateAnimationGroup()
        local delayIcon = animRaidIconFadeOut:CreateAnimation("Alpha")
        delayIcon:SetFromAlpha(1)
        delayIcon:SetToAlpha(1)
        delayIcon:SetDuration(cfg.DelayXP * .75)
        delayIcon:SetOrder(1)

        local alphaOutIcon = animRaidIconFadeOut:CreateAnimation("Alpha")
        alphaOutIcon:SetFromAlpha(1)
        alphaOutIcon:SetToAlpha(0)
        alphaOutIcon:SetSmoothing("OUT")
        alphaOutIcon:SetDuration(0.5)
        alphaOutIcon:SetOrder(2)

        animXPFadeIn:SetScript("OnFinished", function()
            xprep:SetAlpha(1)
            xprepDummy:Hide()
        end)
        animPowerFadeOut:SetScript("OnFinished", function() powerDummy:Hide() end)
        animRaidIconFadeOut:SetScript("OnFinished", function() raidIconDummy:Hide() end)

        self:HookScript("OnEnter", function(_, motion)
            if motion then
                self.power:SetAlpha(0)
                self.RaidTargetIndicator:SetAlpha(0)
                powerDummy:SetText(self.power:GetText())
                powerDummy:Show()
                xprepDummy:SetText(self.xprep:GetText())
                xprepDummy:Show()
                raidIconDummy:SetTexCoord(self.RaidTargetIndicator:GetTexCoord())
                if self.RaidTargetIndicator:IsShown() then raidIconDummy:Show() end
                animXPFadeIn:Play()
                animPowerFadeOut:Play()
                if self.RaidTargetIndicator:IsShown() then animRaidIconFadeOut:Play() end
            end
        end)

        self:HookScript("OnLeave", function()
            if animXPFadeIn:IsPlaying() then animXPFadeIn:Stop() end
            if animPowerFadeOut:IsPlaying() then animPowerFadeOut:Stop() end
            if animRaidIconFadeOut:IsPlaying() then animRaidIconFadeOut:Stop() end
            powerDummy:Hide()
            xprepDummy:Hide()
            raidIconDummy:Hide()
            self.xprep:SetAlpha(0)
            self.power:SetAlpha(1)
            self.RaidTargetIndicator:SetAlpha(1)
        end)
    end

    -- Runes
    if unit == "player" and playerClass == "DEATHKNIGHT" then
        self.Runes = CreateFrame("Frame", nil, self)
        self.Runes:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
        self.Runes:SetSize(96, 16)
        self.Runes.anchor = "TOPLEFT"
        self.Runes.growth = "RIGHT"
        self.Runes.height = 16
        self.Runes.width = 16

        -- TODO why doesn't UnitPowerMax("player", SPELL_POWER_RUNES) return the right number on init?
        for i = 1, 6 do
            self.Runes[i] = CreateFrame("StatusBar", nil, self.Runes)
            self.Runes[i]:SetStatusBarTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\blank.blp")
            self.Runes[i]:SetSize(16, 16)

            if i == 1 then
                self.Runes[i]:SetPoint("TOPLEFT", self.Runes, "TOPLEFT")
            else
                self.Runes[i]:SetPoint("LEFT", self.Runes[i - 1], "RIGHT")
            end

            local backdrop = self.Runes[i]:CreateTexture(nil, "ARTWORK")
            backdrop:SetSize(16, 16)
            backdrop:SetAllPoints()
            backdrop:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\combo.blp")
            backdrop:SetTexCoord(0, 16 / 64, 0, 1)

            -- This is actually the fill layer, but "bg" gets automatically vertex-colored by the runebar module. So let's make use of that!
            self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "OVERLAY")
            self.Runes[i].bg:SetSize(16, 16)
            self.Runes[i].bg:SetPoint("BOTTOM")
            self.Runes[i].bg:SetTexture("Interface\\AddOns\\oUF_Hank_Banaak\\textures\\combo.blp")
            self.Runes[i].bg:SetTexCoord(0.5, 0.75, 0, 1)

            -- Shine effect
            local shinywheee = CreateFrame("Frame", nil, self.Runes[i])
            shinywheee:SetAllPoints()
            shinywheee:SetAlpha(0)
            shinywheee:Hide()

            local shine = shinywheee:CreateTexture(nil, "OVERLAY")
            shine:SetAllPoints()
            shine:SetPoint("CENTER")
            shine:SetTexture("Interface\\Cooldown\\star4.blp")
            shine:SetBlendMode("ADD")

            local anim = shinywheee:CreateAnimationGroup()
            local alphaIn = anim:CreateAnimation("Alpha")
            alphaIn:SetDuration(0.4)
            alphaIn:SetOrder(1)
            local rotateIn = anim:CreateAnimation("Rotation")
            rotateIn:SetDegrees(-90)
            rotateIn:SetDuration(0.4)
            rotateIn:SetOrder(1)
            local scaleIn = anim:CreateAnimation("Scale")
            scaleIn:SetScale(2, 2)
            scaleIn:SetOrigin("CENTER", 0, 0)
            scaleIn:SetDuration(0.4)
            scaleIn:SetOrder(1)
            local alphaOut = anim:CreateAnimation("Alpha")
            alphaOut:SetDuration(0.4)
            alphaOut:SetOrder(2)
            local rotateOut = anim:CreateAnimation("Rotation")
            rotateOut:SetDegrees(-90)
            rotateOut:SetDuration(0.3)
            rotateOut:SetOrder(2)
            local scaleOut = anim:CreateAnimation("Scale")
            scaleOut:SetScale(-2, -2)
            scaleOut:SetOrigin("CENTER", 0, 0)
            scaleOut:SetDuration(0.4)
            scaleOut:SetOrder(2)

            anim:SetScript("OnFinished", function() shinywheee:Hide() end)
            shinywheee:SetScript("OnShow", function() anim:Play() end)

            self.Runes[i]:SetScript("OnValueChanged", function(self, val)
                local start, duration, runeReady = GetRuneCooldown(i)
                if runeReady then
                    self.last = 0
                    -- Rune ready: show all 16x16px, play animation
                    self.bg:SetSize(16, 16)
                    self.bg:SetTexCoord(0.5, 0.75, 0, 1)
                    shinywheee:Show()
                else
                    -- Dot distance from top & bottom of texture: 4px
                    self.bg:SetSize(16, 4 + 8 * val / 10)
                    -- Show at least the empty 4 bottom pixels + val% of the 8 pixels of the actual dot = 12px max
                    self.bg:SetTexCoord(0.25, 0.5, 12 / 16 - 8 * val / 10 / 16, 1)
                end
            end)
        end

        self.Runes.PostUpdate = function(self, runemap)
            for index, runeID in next, runemap do
                rune = self[index]
                if (not rune) then break end

                start, duration, runeReady = GetRuneCooldown(runeID)
                if not runeReady then
                    local val = GetTime() - start
                    -- Dot distance from top & bottom of texture: 4px
                    rune.bg:SetSize(16, 4 + 8 * val / 10)
                    -- Show at least the empty 4 bottom pixels + val% of the 8 pixels of the actual dot = 12px max
                    rune.bg:SetTexCoord(0.25, 0.5, 12 / 16 - 8 * val / 10 / 16, 1)
                end
            end
        end
    end

    local initClassIconAnimation, updateClassIconAnimation
    local initClassPower, initClassSingleIcon
    -- animation: fade in
    if unit == "player" and (playerClass == "MONK" or playerClass == "PALADIN" or playerClass == "WARLOCK" or playerClass == "DRUID") then
        initClassIconAnimation = function(unitFrame, i)
            unitFrame.ClassPower.animations[i] = unitFrame.ClassPower[i]:CreateAnimationGroup()
            local alphaIn = unitFrame.ClassPower.animations[i]:CreateAnimation("Alpha")
            -- alphaIn:SetChange(1)
            alphaIn:SetFromAlpha(0)
            alphaIn:SetToAlpha(1)
            alphaIn:SetSmoothing("OUT")
            alphaIn:SetDuration(1)
            alphaIn:SetOrder(1)

            unitFrame.ClassPower.animations[i]:SetScript("OnFinished", function() unitFrame.ClassPower[i]:SetAlpha(1) end)
        end
        updateClassIconAnimation = function(unitFrame, current, max)
            -- bail if we don't have ClassPower to animate
            if current == nil then return end

            unitFrame.ClassPower.animLastState = unitFrame.ClassPower.animLastState or 0
            if current > 0 then
                if unitFrame.ClassPower.animLastState < current then
                    -- Play animation only when we gain power
                    unitFrame.ClassPower[current]:SetAlpha(0)
                    unitFrame.ClassPower.animations[current]:Play();
                end
            else
                for i = 1, max do
                    -- no holy power, stop all running animations
                    unitFrame.ClassPower.animLastState = current
                    if unitFrame.ClassPower.animations[i]:IsPlaying() then
                        unitFrame.ClassPower.animations[i]:Stop()
                    end
                end
            end
            unitFrame.ClassPower.animLastState = current
        end
    end

    -- Holy power
    if unit == "player" and playerClass == "PALADIN" then
        initClassPower = function(unitFrame)
            unitFrame.ClassPower.animLastState = UnitPower("player", SPELL_POWER_HOLY_POWER)
        end
        initClassSingleIcon = function(unitFrame, i)
            unitFrame.ClassPower[i]:SetVertexColor(unpack(cfg.colors.power.HOLY_POWER))
        end
    end

    -- StatusBarIcons
    if unit == "player" and (playerClass == "MONK" or playerClass == "PALADIN" or playerClass == "WARLOCK" or playerClass == "DRUID") then
        local data = oUF_Hank_Banaak.classResources[playerClass]
        local bg = {}
        self.ClassPower = {}
        self.ClassPower.animations = {}

        if initClassPower then
            initClassPower(self)
        end

        for i = 1, oUF_Hank_Banaak.classResources[playerClass].max do
            bg[i] = CreateFrame("Frame", nil, self)
            bg[i]:SetSize(data.size[1] or 28, data.size[2] or 28)

            bg[i].tex = bg[i]:CreateTexture(nil, "ARTWORK")
            bg[i].tex:SetTexture(data['inactive'][1])
            if data['inactive'][2] then
                bg[i].tex:SetTexCoord(unpack(data['inactive'][2]))
            else
                bg[i].tex:SetTexCoord(0, 1, 0, 1)
            end
            bg[i].tex:SetAllPoints(bg[i])

            if i == 1 then
                bg[i]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", data.offset or -78, 0)
            else
                bg[i]:SetPoint(
                    data.inverse and "RIGHT" or "LEFT",
                    bg[i - 1],
                    data.inverse and "LEFT" or "RIGHT",
                    data.spacing or 0,
                    0
                )
            end

            self.ClassPower[i] = bg[i]:CreateTexture(nil, "OVERLAY")
            self.ClassPower[i]:SetTexture(data['active'][1])
            if data['active'][2] then
                self.ClassPower[i]:SetTexCoord(unpack(data['active'][2]))
            else
                self.ClassPower[i]:SetTexCoord(0, 1, 0, 1)
            end
            self.ClassPower[i]:SetAllPoints(bg[i])

            -- need access to the background in the PostUpdate function
            self.ClassPower[i].bg = bg[i].tex

            -- start hidden
            self.ClassPower[i]:Hide()
            self.ClassPower[i].bg:Hide()

            -- we don't use a StatusBar for Monk/Paladin/Warlock so make noop functions to get around null errors
            self.ClassPower.UpdateColor = function()
            end
            self.ClassPower[i].SetValue = function()
            end

            if initClassSingleIcon then
                initClassSingleIcon(self, i)
            end
            if initClassIconAnimation then
                initClassIconAnimation(self, i)
            end
        end

        self.ClassPower.PostUpdate = function(_, current, max, changed, powerType)
            local hide = false
            for i = 1, oUF_Hank_Banaak.classResources[playerClass].max do
                if hide or max == nil or i > max then
                    self.ClassPower[i]:Hide()
                    self.ClassPower[i].bg:Hide()
                else
                    self.ClassPower[i].bg:Show()
                end
            end
            if updateClassIconAnimation then
                updateClassIconAnimation(self, current, max)
            end
        end
    end

    if unit == "player" and cfg.AdditionalPower and (playerClass == "DRUID" or playerClass == 'PRIEST' or playerClass == "SHAMAN") then
        local additionalPower = self:CreateFontString(nil, "OVERLAY")
        additionalPower:SetFontObject("UFFontMedium")
        additionalPower:SetPoint("TOPRIGHT", power, "TOPRIGHT", 0, 15)
        self:Tag(additionalPower, "[apDetailed]")
        self.additionalPower = additionalPower

        -- Register it with oUF
        local dummyBar = CreateFrame("StatusBar", nil, self)
        self.AdditionalPower = dummyBar

        self.AdditionalPower.PostUpdate = function(_, unit, current, max)
            if select(2, UnitPowerType(unit)) ~= ADDITIONAL_POWER_BAR_NAME then
                additionalPower:Show()
            else
                additionalPower:Hide()
            end
        end
    end

    -- Auras
    if unit == "target" or unit == "focus" then
        -- Buffs
        self.Buffs = CreateFrame("Frame", unit .. "_Buffs", self) -- ButtonFace needs a name
        self.Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -5)
        self.Buffs:SetHeight(cfg.BuffSize)
        self.Buffs:SetWidth(225)
        self.Buffs.size = cfg.BuffSize
        self.Buffs.spacing = cfg.AuraSpacing
        self.Buffs.initialAnchor = "LEFT"
        self.Buffs["growth-y"] = "DOWN"
        self.Buffs.num = cfg["Auras" .. upper(unit)].MaxBuffs
        self.Buffs.filter = "HELPFUL" -- Explicitly set the filter or the first customFilter call won't work

        -- Debuffs
        self.Debuffs = CreateFrame("Frame", unit .. "_Debuffs", self)
        self.Debuffs:SetPoint("LEFT", self, "LEFT", 0, 0)
        self.Debuffs:SetPoint("TOP", self, "TOP", 0, 0) -- We will reanchor this in PreAuraSetPosition
        self.Debuffs:SetHeight(cfg.DebuffSize)
        self.Debuffs:SetWidth(225)
        self.Debuffs.size = cfg.DebuffSize
        self.Debuffs.spacing = cfg.AuraSpacing
        self.Debuffs.initialAnchor = "LEFT"
        self.Debuffs["growth-y"] = "DOWN"
        self.Debuffs.num = cfg["Auras" .. upper(unit)].MaxDebuffs
        self.Debuffs.filter = "HARMFUL"

        -- Buff magnification effect on mouseover
        self.HighlightAura = CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")
        self.HighlightAura:SetFrameLevel(5) -- Above auras (level 3) and their cooldown overlay (4)
        self.HighlightAura:SetBackdrop({ bgFile = cfg.AuraBorder })
        self.HighlightAura:SetBackdropColor(0, 0, 0, 1)
        self.HighlightAura.icon = self.HighlightAura:CreateTexture(nil, "ARTWORK")
        self.HighlightAura.icon:SetPoint("CENTER")
        self.HighlightAura.border = self.HighlightAura:CreateTexture(nil, "OVERLAY")
        self.HighlightAura.border:SetTexture(cfg.AuraBorder)
        self.HighlightAura.border:SetPoint("CENTER")

        self.Buffs.PostUpdateIcon = oUF_Hank_Banaak.PostUpdateIcon
        self.Debuffs.PostUpdateIcon = oUF_Hank_Banaak.PostUpdateIcon
        self.Buffs.PostCreateIcon = oUF_Hank_Banaak.PostCreateIcon
        self.Debuffs.PostCreateIcon = oUF_Hank_Banaak.PostCreateIcon
        self.Buffs.PreSetPosition = oUF_Hank_Banaak.PreSetPosition
        self.Buffs.CustomFilter = oUF_Hank_Banaak.customFilter
        self.Debuffs.CustomFilter = oUF_Hank_Banaak.customFilter
    end

    -- Castbar
    if cfg.Castbar and (unit == "player" or unit == "target" or unit == "focus") then
        -- StatusBar
        local cb = CreateFrame("StatusBar", nil, self)
        cb:SetStatusBarTexture(cfg.CastbarTexture)
        cb:SetStatusBarColor(unpack(cfg.colors.castbar.bar))
        cb:SetSize(cfg.CastbarSize[1], cfg.CastbarSize[2])
        if unit == "player" then
            cb:SetPoint("LEFT", self, "RIGHT", (cfg.CastbarIcon and (cfg.CastbarSize[2] + 5) or 0) + 5 + cfg.CastbarMargin[1], cfg.CastbarMargin[2])
        elseif unit == "focus" then
            cb:SetSize(0.8 * cfg.CastbarSize[1], cfg.CastbarSize[2])
            cb:SetPoint("LEFT", self, "RIGHT", -10 - cfg.CastbarFocusMargin[1], cfg.CastbarFocusMargin[2])
        else
            cb:SetPoint("RIGHT", self, "LEFT", (cfg.CastbarIcon and (-cfg.CastbarSize[2] - 5) or 0) - 5 - cfg.CastbarMargin[1], cfg.CastbarMargin[2])
        end

        -- BG
        cb.Background = CreateFrame("Frame", nil, cb, BackdropTemplateMixin and "BackdropTemplate")
        cb.Background:SetFrameStrata("BACKGROUND")
        cb.Background:SetPoint("TOPLEFT", cb, "TOPLEFT", -5, 5)
        cb.Background:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 5, -5)

        local backdrop = {
            bgFile = cfg.CastbarBackdropTexture,
            edgeFile = cfg.CastbarBorderTexture,
            tileSize = 16, edgeSize = 16, tile = true,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        }

        cb.Background:SetBackdrop(backdrop)
        cb.Background:SetBackdropColor(0.22, 0.22, 0.19)
        cb.Background:SetBackdropBorderColor(0, 0, 0, 1)
        cb.Background:SetAlpha(0.8)

        -- Spark
        cb.Spark = cb:CreateTexture(nil, "OVERLAY")
        cb.Spark:SetSize(20, 35 * 2.2)
        cb.Spark:SetBlendMode("ADD")

        -- Spell name
        cb.Text = cb:CreateFontString(nil, "OVERLAY")
        cb.Text:SetTextColor(unpack(cfg.colors.castbar.text))
        if unit == "focus" then
            cb.Text:SetFont(unpack(cfg.CastBarBig))
            cb.Text:SetShadowOffset(1.5, -1.5)
            cb.Text:SetPoint("LEFT", 3, 0)
            cb.Text:SetPoint("RIGHT", -3, 0)
        else
            cb.Text:SetFont(unpack(cfg.CastBarMedium))
            cb.Text:SetShadowOffset(0.8, -0.8)
            cb.Text:SetPoint("LEFT", 3, 9)
            cb.Text:SetPoint("RIGHT", -3, 9)
        end

        if unit ~= "focus" then
            -- Icon
            if cfg.CastbarIcon then
                cb.Icon = cb:CreateTexture(nil, "OVERLAY")
                cb.Icon:SetSize(cfg.CastbarSize[2], cfg.CastbarSize[2])
                cb.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                if unit == "player" or unit == "focus" then
                    cb.Icon:SetPoint("RIGHT", cb, "LEFT", -5, 0)
                else
                    cb.Icon:SetPoint("LEFT", cb, "RIGHT", 5, 0)
                end
            end

            -- Cast time
            cb.Time = cb:CreateFontString(nil, "OVERLAY")
            cb.Time:SetFont(unpack(cfg.CastBarBig))
            cb.Time:SetTextColor(unpack(cfg.colors.castbar.text))
            cb.Time:SetShadowOffset(0.8, -0.8)
            cb.Time:SetPoint("TOP", cb.Text, "BOTTOM", 0, -3)
            cb.Time:SetPoint("LEFT", 3, 9)
            cb.Time:SetPoint("RIGHT", -3, 9)
            cb.CustomTimeText = function(_, t)
                cb.Time:SetText(("%.2f / %.2f"):format(cb.castIsChanneled and t or cb.max - t, cb.max))
            end
            cb.CustomDelayText = function(_, t)
                cb.Time:SetText(("%.2f |cFFFF5033%s%.2f|r"):format(cb.castIsChanneled and t or cb.max - t, cb.castIsChanneled and "-" or "+", cb.delay))
            end
        end

        -- Animation dummy
        cb.Dummy = CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")
        cb.Dummy:SetAllPoints(cb.Background)
        cb.Dummy:SetBackdrop(backdrop)
        cb.Dummy:SetBackdropColor(0.22, 0.22, 0.19)
        cb.Dummy:SetBackdropBorderColor(0, 0, 0, 1)
        cb.Dummy:SetAlpha(0.8)

        cb.Dummy.Fill = cb.Dummy:CreateTexture(nil, "OVERLAY")
        cb.Dummy.Fill:SetTexture(cfg.CastbarTexture)
        cb.Dummy.Fill:SetAllPoints(cb)

        if unit ~= "focus" and cfg.CastbarIcon then
            cb.Dummy.Icon = cb.Dummy:CreateTexture(nil, "OVERLAY")
            cb.Dummy.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            cb.Dummy.Icon:SetAllPoints(cb.Icon)
        end

        cb.Dummy:Hide()

        cb.Dummy.anim = cb.Dummy:CreateAnimationGroup()
        local alphaOut = cb.Dummy.anim:CreateAnimation("Alpha")
        alphaOut:SetFromAlpha(1)
        alphaOut:SetToAlpha(0)
        alphaOut:SetDuration(1)
        alphaOut:SetOrder(0)

        cb:SetScript("OnShow", function()
            if cb.Dummy.anim:IsPlaying() then cb.Dummy.anim:Stop() end
            cb.Dummy:Hide()
        end)

        cb.Dummy.anim:SetScript("OnFinished", function() cb.Dummy:Hide() end)

        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, _, unit, spell, rank)
            if UnitIsUnit(unit, self.unit) and not cb.castIsChanneled then
                oUF_Hank_Banaak.PostCastSucceeded(cb, spell)
            end
        end)

        -- Shield dummy
        cb.Shield = cb:CreateTexture(nil, "BACKGROUND")

        cb.PostCastStart = oUF_Hank_Banaak.PostCastStart
        cb.PostChannelStart = oUF_Hank_Banaak.PostChannelStart
        cb.PostCastStop = oUF_Hank_Banaak.PostCastStop
        cb.PostChannelStop = oUF_Hank_Banaak.PostChannelStop

        self.Castbar = cb
    end

    -- Initial size
    if unit == "player" then
        self:SetSize(175, 50)
    elseif unit == "target" or unit == "focus" then
        self:SetSize(250, 50)
    elseif unit == "pet" or unit == "targettarget" or unit == "targettargettarget" or unit == "focustarget" then
        self:SetSize(125, 16)
    elseif unit:find("boss") then
        self:SetSize(250, 50)
    end

end

-- Frame creation --------------------------------

oUF:RegisterStyle("Hank", oUF_Hank_Banaak.sharedStyle)
oUF:SetActiveStyle("Hank")
oUF:Spawn("player", "oUF_player"):SetPoint("RIGHT", UIParent, "CENTER", -cfg.FrameMargin[1], -cfg.FrameMargin[2])
oUF:Spawn("pet", "oUF_pet"):SetPoint("BOTTOMRIGHT", oUF_player, "TOPRIGHT")
oUF:Spawn("target", "oUF_target"):SetPoint("LEFT", UIParent, "CENTER", cfg.FrameMargin[1], -cfg.FrameMargin[2])
oUF:Spawn("targettarget", "oUF_ToT"):SetPoint("BOTTOMLEFT", oUF_target, "TOPLEFT")
oUF:Spawn("targettargettarget", "oUF_ToTT"):SetPoint("BOTTOMLEFT", oUF_ToT, "TOPLEFT")
oUF:Spawn("focus", "oUF_focus"):SetPoint("CENTER", UIParent, "CENTER", -cfg.FocusFrameMargin[1], -cfg.FocusFrameMargin[2])
oUF:Spawn("focustarget", "oUF_ToF"):SetPoint("BOTTOMLEFT", oUF_focus, "TOPLEFT", 0, 5)

for i = 1, MAX_BOSS_FRAMES do
    oUF:Spawn("boss" .. i, "oUF_boss" .. i):SetPoint("RIGHT", UIParent, cfg.BossFrameMargin[1], -55 * (i - 1) - cfg.BossFrameMargin[2])
    _G["oUF_boss" .. i]:SetScale(cfg.FrameScale * cfg.BossFrameScale)
end

oUF_player:SetScale(cfg.FrameScale)
oUF_pet:SetScale(cfg.FrameScale)
oUF_target:SetScale(cfg.FrameScale)
oUF_ToT:SetScale(cfg.FrameScale)
oUF_ToTT:SetScale(cfg.FrameScale)
oUF_focus:SetScale(cfg.FrameScale * cfg.FocusFrameScale)
if cfg.FocusFrameScale <= 0.7 then
    oUF_ToF:SetScale(cfg.FrameScale * cfg.FocusFrameScale * 1.25)
else
    oUF_ToF:SetScale(cfg.FrameScale * cfg.FocusFrameScale)
end

if cfg.HideParty then oUF_Hank_Banaak.HideParty() end
if cfg.Castbar then oUF_Hank_Banaak.AdjustMirrorBars() end

-- Call for custom_modifications
oUF_Hank_Banaak.PostSpawnFrames(oUF_Hank_Banaak)
