local DWML = DudeWheresMyLust
local SUI = SwirlUI
local C = SUI.Components
local db

local OUTLINE_OPTIONS = { "NONE", "OUTLINE", "THICKOUTLINE" }
local ANIMATION_OPTIONS = { "Shake", "Bounce", "Pulse", "Fade" }
local ANCHOR_OPTIONS = {
    "CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT",
    "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT",
}

local function LSMList(mediaType)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return {} end

    local list = {}
    for name in pairs(LSM:HashTable(mediaType)) do
        list[#list + 1] = name
    end
    table.sort(list)

    return list
end

local function BuildGeneralCard(parent)
    local card = C:CreateCard(parent, "Lust Reminder")

    card:AddEnableToggle("Enable", db.enabled, function(val)
        db.enabled = val
        SUI.SettingsChanged = true
    end)

    card:AddWidget(C:CreateButton(card, "Test Alert", {
        callback = function() DWML:ShowAlert() end,
    }))

    return card
end

local function BuildOptionsCard(scrollChild)
    local card = C:CreateCard(scrollChild, "Options")

    card:AddWidget(C:CreateToggle(card, "Lusters Only", db.lustersOnly, function(val)
        db.lustersOnly = val
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateToggle(card, "Alert on First Dungeon Pull", db.dungeonPull, function(val)
        db.dungeonPull = val
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateToggle(card, "Alert when Lust Debuff Expires Mid-Fight", db.debuffExpiry, function(val)
        db.debuffExpiry = val
        SUI.SettingsChanged = true
    end))

    return card
end

local function BuildTextCard(scrollChild)
    local card = C:CreateCard(scrollChild, "Text")

    card:AddWidget(C:CreateEditBox(card, "Alert Text", db.text.content, function(val)
        db.text.content = val
        DWML:RefreshAlert()
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateColorPicker(card, "Font Color", CreateColor(db.font.color.r, db.font.color.g, db.font.color.b, db.font.color.a), function(color)
        db.font.color = { r = color.r, g = color.g, b = color.b, a = color.a }
        DWML:RefreshAlert()
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateSlider(card, "Font Size", 8, 256, 1,
        function() return db.font.size end,
        function(val) db.font.size = val; DWML:RefreshAlert(); SUI.SettingsChanged = true end
    ))

    card:AddWidget(C:CreateDropdown(card, "Font", LSMList("font"), db.font.path, function(val)
        db.font.path = val
        DWML:RefreshAlert()
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateDropdown(card, "Outline", OUTLINE_OPTIONS, db.font.outline, function(val)
        db.font.outline = val
        DWML:RefreshAlert()
        SUI.SettingsChanged = true
    end))

    return card
end

local function BuildAnimationCard(scrollChild)
    local card = C:CreateCard(scrollChild, "Animation")

    card:AddWidget(C:CreateToggle(card, "Enable Animation", db.animation.enabled, function(val)
        db.animation.enabled = val
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateDropdown(card, "Animation Style", ANIMATION_OPTIONS, db.animation.style, function(val)
        db.animation.style = val
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateSlider(card, "Duration (seconds)", 1, 30, 0.5,
        function() return db.animation.duration end,
        function(val) db.animation.duration = val; SUI.SettingsChanged = true end
    ))

    return card
end

local function BuildSoundCard(scrollChild)
    local card = C:CreateCard(scrollChild, "Sound")

    card:AddWidget(C:CreateToggle(card, "Play Sound Alert", db.sound.enabled, function(val)
        db.sound.enabled = val
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateDropdown(card, "Sound", LSMList("sound"), db.sound.file, function(val)
        db.sound.file = val
        SUI.SettingsChanged = true
    end))

    return card
end

local function BuildPositionCard(scrollChild)
    local card = C:CreateCard(scrollChild, "Position")

    local xyWidget = C:CreateXYPosition(card,
        function() return db.anchor.x end,
        function(val) db.anchor.x = val; DWML:UpdateAlertPosition(); SUI.SettingsChanged = true end,
        function() return db.anchor.y end,
        function(val) db.anchor.y = val; DWML:UpdateAlertPosition(); SUI.SettingsChanged = true end
    )
    card:AddWidget(xyWidget)
    DWML.OnPositionChanged = function() xyWidget:Refresh() end

    card:AddWidget(C:CreateDropdown(card, "Anchor From", ANCHOR_OPTIONS, db.anchor.point, function(val)
        db.anchor.point = val
        DWML:UpdateAlertPosition()
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateDropdown(card, "Anchor To", ANCHOR_OPTIONS, db.anchor.to, function(val)
        db.anchor.to = val
        DWML:UpdateAlertPosition()
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateEditBox(card, "Anchor Frame (e.g. UIParent)", db.anchor.frame, function(val)
        db.anchor.frame = val
        DWML:UpdateAlertPosition()
        SUI.SettingsChanged = true
    end))

    card:AddWidget(C:CreateButton(card, "Unlock / Lock Position", {
        callback = function()
            if DWML.alertUnlocked then DWML:LockAlert() else DWML:UnlockAlert() end
        end,
    }))

    return card
end

local function CreateSettings(content)
    db = DudeWheresMyLustDB
    local tab = C:CreateTabScroller(content)
    local generalCard = tab:AddCard(BuildGeneralCard(tab))
    local dependents = {
        tab:AddCard(BuildOptionsCard(tab)),
        tab:AddCard(BuildTextCard(tab)),
        tab:AddCard(BuildAnimationCard(tab)),
        tab:AddCard(BuildSoundCard(tab)),
        tab:AddCard(BuildPositionCard(tab)),
    }
    generalCard:SetDependents(unpack(dependents))
    tab:Commit()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event ~= "ADDON_LOADED" or addonName ~= "DudeWheresMyLust" then return end
    if SwirlUI_AddTab then
        local built = false
        SwirlUI_AddTab("DudeWheresMyLust", "Lust Reminder", function(content)
            if built then return end
            built = true
            CreateSettings(content)
        end)
    end
end)
