-- Abklingzeit-Zahlen auf Aktionsleisten und Gegenständen (Reiter Komfort, Oberfläche; Roadmap 446).
-- Setzt die CVar countdownForCooldowns auf 1 und zeigt lesbare, farbkodierte Restzeit-Zahlen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    cooldownNumbers = false,
  },
})

local CooldownNumbers = {}
ns.CooldownNumbers = CooldownNumbers

local CVAR = "countdownForCooldowns"
local activeCooldowns = {}
local hooked = false

CooldownNumbers.COLORS = {
  red = ns.Theme.COLORS.bad,
  yellow = ns.Theme.COLORS.neutral,
  white = ns.Theme.COLORS.text,
  grey = ns.Theme.COLORS.muted,
}

function CooldownNumbers.FormatRemaining(seconds)
  if seconds < 3 then
    return string.format("%.1f", seconds), 1, 0.2, 0.2, "red"
  elseif seconds < 60 then
    return string.format("%d", math.ceil(seconds)), 1, 0.85, 0.2, "yellow"
  elseif seconds < 3600 then
    return string.format("%dm", math.ceil(seconds / 60)), 1, 1, 1, "white"
  else
    return string.format("%dh", math.ceil(seconds / 3600)), 0.7, 0.7, 0.7, "grey"
  end
end

local function getTextOverlay(cooldown)
  local text = rawget(cooldown, "_ltText")
  if not text then
    text = cooldown:CreateFontString(nil, "OVERLAY")
    if text.SetFontObject then
      text:SetFontObject(NumberFontNormal or GameFontNormalLarge)
    end
    text:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
    cooldown._ltText = text
  end
  return text
end

-- Verbotene Frames (z. B. Namensplaketten in Forever) dürfen wir nicht anfassen: IsShown wirft dort einen Fehler.
-- IsForbidden selbst ist auf jedem Frame erlaubt; ein Frame kann es auch erst nach dem Hook werden.
local function isForbidden(cooldown)
  return cooldown.IsForbidden and cooldown:IsForbidden()
end

local function updateCooldown(cooldown, info, now)
  if isForbidden(cooldown) then
    activeCooldowns[cooldown] = nil
    return
  end
  local remaining = (info.start + info.duration) - now
  local overlay = rawget(cooldown, "_ltText")
  if remaining <= 0 then
    activeCooldowns[cooldown] = nil
    if overlay then overlay:Hide() end
    return
  end

  if cooldown.IsShown and not cooldown:IsShown() then
    if overlay then overlay:Hide() end
    return
  end

  local text, r, g, b = CooldownNumbers.FormatRemaining(remaining)
  overlay = getTextOverlay(cooldown)
  overlay:SetText(text)
  if overlay.SetTextColor then
    overlay:SetTextColor(r, g, b)
  end
  overlay:Show()
end

local function onTick()
  if not ns.db or not ns.db.cooldownNumbers then return end
  local now = GetTime()
  for cooldown, info in pairs(activeCooldowns) do
    updateCooldown(cooldown, info, now)
  end
end

local function onCooldownSet(cooldown, start, duration, enable)
  if not cooldown or not ns.db or not ns.db.cooldownNumbers or isForbidden(cooldown) then return end
  if ns.IsSecret(start) or ns.IsSecret(duration) or ns.IsSecret(enable) then return end
  local isEnabled = enable == nil or enable == 1 or enable == true
  if not isEnabled or not start or not duration or duration <= 1.5 then
    if activeCooldowns[cooldown] then
      activeCooldowns[cooldown] = nil
      local overlay = rawget(cooldown, "_ltText")
      if overlay then overlay:Hide() end
    end
    return
  end

  local now = GetTime()
  local info = { start = start, duration = duration }
  activeCooldowns[cooldown] = info
  updateCooldown(cooldown, info, now)
end

local function hookCooldownFrame()
  if hooked or type(CooldownFrame_Set) ~= "function" then return end
  hooked = true
  hooksecurefunc("CooldownFrame_Set", onCooldownSet)
end

local function apply(db)
  db = db or ns.db
  if not db then return end
  hookCooldownFrame()
  if db.cooldownNumbers == true then
    ns.CVars.Override(CVAR, "1")
  else
    ns.CVars.Restore(CVAR)
    for cooldown in pairs(activeCooldowns) do
      local overlay = rawget(cooldown, "_ltText")
      if overlay then overlay:Hide() end
      activeCooldowns[cooldown] = nil
    end
  end
end

CooldownNumbers.Apply = apply
CooldownNumbers.OnCooldownSet = onCooldownSet
CooldownNumbers.HookCooldownFrame = hookCooldownFrame
CooldownNumbers.GetActiveCooldowns = function() return activeCooldowns end

hookCooldownFrame()
ns.RegisterApply(apply)
ns.Every(0.2, onTick, function(db) return db.cooldownNumbers == true end)
