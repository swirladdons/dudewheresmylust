DudeWheresMyLust = DudeWheresMyLust or {}
local DWML = DudeWheresMyLust

local SPELLS = {
    2825, -- lust
    32182, -- hero
    80353, -- time warp
    390386, -- fury of the aspects
    264667, -- primal rage
    466904, -- harrier's cry
}

local DEBUFFS = {
    57723, -- exhaustion
    390435, -- exhaustion
    57724, -- sated
    80354, -- temporal displacement
    95809, -- insanity
    264689, -- drums
    160455, -- netherwinds
}

local DB_DEFAULTS = {
    enabled = true,
    lustersOnly = true,
    dungeonPull = false,
    debuffExpiry = true,
    text = {
        enabled = true,
        content = "LUST?!?!?!",
    },
    font = {
        path = "Friz Quadrata TT",
        size = 128,
        outline = "OUTLINE",
        color = {
            r = 1,
            g = 1,
            b = 0,
            a = 1
        },
    },
    animation = {
        enabled = true,
        style = "Shake",
        duration = 5,
    },
    sound = {
        enabled = true,
        file = "Raid Warning",
    },
    anchor = {
        point = "CENTER",
        to = "CENTER",
        frame = "UIParent",
        x = 0,
        y = 200,
    },
}

local db

DWML.alertUnlocked = false
DWML.watchingDebuffExpiry = false
DWML.watchingForLustCast = false
DWML.firstPullPending = false

function DWML:CanLust()
    for _, id in ipairs(SPELLS) do
        if C_SpellBook.IsSpellInSpellBook(id) then return true end
    end
    local _, class = UnitClass("player")
    return class == "HUNTER"
end

function DWML:HasLustDebuff()
    for _, id in ipairs(DEBUFFS) do
        if C_UnitAuras.GetPlayerAuraBySpellID(id) then return true end
    end
    return false
end

local alertFrame, alertText, alertGlow

local function ApplyTextStyle()
    if not alertText then return end
    local f = db.font
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local fontPath = LSM and LSM:Fetch("font", f.path) or f.path
    alertText:SetFont(fontPath, f.size, f.outline)
    alertText:SetTextColor(f.color.r, f.color.g, f.color.b, f.color.a)
    alertText:SetText(db.text.content)
    alertGlow:SetFont(fontPath, f.size, f.outline)
    alertGlow:SetTextColor(0, 0, 0, 0.3)
    alertGlow:SetText(db.text.content)
end

local function ResetAlertVisuals()
    alertFrame:SetScale(1)
    alertText:SetAlpha(1)
    alertGlow:SetAlpha(0.3)
    alertText:ClearAllPoints()
    alertText:SetPoint("CENTER")
    alertGlow:ClearAllPoints()
    alertGlow:SetPoint("CENTER", 2, -2)
end

local function RunOnUpdate(self, dt)
    self.elapsed = self.elapsed + dt

    if self.elapsed >= db.animation.duration then
        self:Hide()
        alertFrame:SetScale(1)
        DWML.watchingForLustCast = false
        return
    end

    if DWML.watchingForLustCast and DWML:HasLustDebuff() then
        self:Hide()
        alertFrame:SetScale(1)
        DWML.watchingForLustCast = false
        return
    end

    if not db.animation.enabled then return end
    local anim = db.animation.style
    if anim == "Bounce" then
        local y = math.abs(math.sin(self.elapsed * 4)) * 40
        alertText:SetPoint("CENTER", alertFrame, "CENTER", 0, y)
        alertGlow:SetPoint("CENTER", alertFrame, "CENTER", 2, y - 2)
    elseif anim == "Shake" then
        local x = math.sin(self.elapsed * 30) * 12
        local y = math.cos(self.elapsed * 25) * 6
        alertText:SetPoint("CENTER", alertFrame, "CENTER", x, y)
        alertGlow:SetPoint("CENTER", alertFrame, "CENTER", x + 2, y - 2)
    elseif anim == "Pulse" then
        alertFrame:SetScale(1 + 0.25 * math.sin(self.elapsed * 5))
    elseif anim == "Fade" then
        local alpha = 0.5 + 0.5 * math.abs(math.sin(self.elapsed * 3))
        alertText:SetAlpha(alpha)
        alertGlow:SetAlpha(alpha * 0.3)
    end
end

local function CreateAlertFrame()
    if alertFrame then return end

    alertFrame = CreateFrame("Frame", "DudeWheresMyLustAlertFrame", UIParent)
    alertFrame:SetSize(600, 120)
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", db.anchor.x, db.anchor.y)
    alertFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    alertFrame:SetMovable(true)
    alertFrame:SetUserPlaced(false)
    alertFrame:RegisterForDrag("LeftButton")
    alertFrame:Hide()

    alertFrame:SetScript("OnDragStart", function(self)
        if self.unlocked then self:StartMoving() end
    end)
    alertFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(false)
        local cx, cy = UIParent:GetCenter()
        local fx, fy = self:GetCenter()
        db.anchor.x = math.floor(fx - cx + 0.5)
        db.anchor.y = math.floor(fy - cy + 0.5)
        if DWML.OnPositionChanged then DWML.OnPositionChanged() end
    end)

    alertFrame:SetScript("OnUpdate", function(self)
        if not self.unlocked then return end
        local cx, cy = UIParent:GetCenter()
        local fx, fy = self:GetCenter()
        db.anchor.x = math.floor(fx - cx + 0.5)
        db.anchor.y = math.floor(fy - cy + 0.5)
        if DWML.OnPositionChanged then DWML.OnPositionChanged() end
    end)

    alertText = alertFrame:CreateFontString(nil, "OVERLAY")
    alertText:SetPoint("CENTER")

    alertGlow = alertFrame:CreateFontString(nil, "ARTWORK")
    alertGlow:SetPoint("CENTER", 2, -2)
    alertGlow:SetAlpha(0.3)

    alertFrame.elapsed = 0
end

function DWML:UpdateAlertPosition()
    if not alertFrame then return end
    local anchor = _G[db.anchor.frame or "UIParent"] or UIParent
    alertFrame:ClearAllPoints()
    alertFrame:SetPoint(db.anchor.point or "CENTER", anchor, db.anchor.to or "CENTER", db.anchor.x, db.anchor.y)
end

function DWML:RefreshAlert()
    if alertFrame and alertFrame:IsShown() then
        ApplyTextStyle()
    end
end

function DWML:UnlockAlert()
    CreateAlertFrame()
    ApplyTextStyle()
    ResetAlertVisuals()
    self.alertUnlocked = true
    alertFrame.unlocked = true
    alertFrame:EnableMouse(true)
    alertFrame:SetScript("OnUpdate", nil)
    self:UpdateAlertPosition()
    alertFrame:Show()
end

function DWML:LockAlert()
    if not alertFrame then return end
    self.alertUnlocked = false
    alertFrame.unlocked = false
    alertFrame:EnableMouse(false)
    alertFrame:SetScript("OnUpdate", RunOnUpdate)
    alertFrame:Hide()
end

function DWML:ShowAlert()
    if self.alertUnlocked then self:LockAlert() end
    CreateAlertFrame()

    if db.sound.enabled and db.sound.file then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        local path = LSM and LSM:Fetch("sound", db.sound.file) or db.sound.file
        if type(path) == "number" then
            PlaySound(path, "Master")
        elseif path then
            PlaySoundFile(path, "Master")
        end
    end

    if db.text.enabled then
        ApplyTextStyle()
        ResetAlertVisuals()
        alertFrame:EnableMouse(false)
        alertFrame.unlocked = false
        self:UpdateAlertPosition()
        alertFrame.elapsed = 0
        alertFrame:SetScript("OnUpdate", RunOnUpdate)
        alertFrame:Show()
    end

    self.watchingForLustCast = true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DudeWheresMyLust" then
        DudeWheresMyLustDB = DudeWheresMyLustDB or {}
        db = DudeWheresMyLustDB

    for k, v in pairs(DB_DEFAULTS) do
            if db[k] == nil then
                db[k] = type(v) == "table" and CopyTable(v) or v
            end
        end
        return
    end

    if not db or not db.enabled then return end

    if event == "ENCOUNTER_START" then
        if DWML:HasLustDebuff() then
            if db.debuffExpiry then
                DWML.watchingDebuffExpiry = true
                eventFrame:RegisterEvent("UNIT_AURA")
            end
        else
            DWML:ShowAlert()
        end

    elseif event == "ENCOUNTER_END" then
        DWML.watchingDebuffExpiry = false
        eventFrame:UnregisterEvent("UNIT_AURA")

    elseif event == "UNIT_AURA" then
        if arg1 ~= "player" or not DWML.watchingDebuffExpiry then return end
        if not DWML:HasLustDebuff() then
            DWML.watchingDebuffExpiry = false
            eventFrame:UnregisterEvent("UNIT_AURA")
            DWML:ShowAlert()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if db.lustersOnly and not DWML:CanLust() then
            eventFrame:UnregisterEvent("ENCOUNTER_START")
            eventFrame:UnregisterEvent("ENCOUNTER_END")
            eventFrame:UnregisterEvent("CHALLENGE_MODE_START")
            eventFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
            eventFrame:UnregisterEvent("UNIT_AURA")
            return
        end
        local _, instanceType = IsInInstance()
        DWML.firstPullPending = (instanceType == "party")

    elseif event == "CHALLENGE_MODE_START" then
        DWML.firstPullPending = true

    elseif event == "PLAYER_REGEN_DISABLED" then
        if not DWML.firstPullPending or not db.dungeonPull then return end
        DWML.firstPullPending = false
        if not DWML:HasLustDebuff() then
            DWML:ShowAlert()
        end
    end
end)
