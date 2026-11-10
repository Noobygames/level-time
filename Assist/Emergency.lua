-- Notfall bei wenig Leben (Roadmap 267, Einstellung emergencyHighlight, Standard aus), wie RXP: sobald das Leben unter
-- die Beinahe-Tod-Schwelle fällt (NearDeath.LOW_HEALTH), leuchten die Aktionsknöpfe mit Heiltrank, Gesundheitsstein oder
-- Notfallzauber, und der Bildschirmrand wird rot. Aus, sobald das Leben über EXIT_HEALTH steigt oder man stirbt.
-- Nur wo UnitHealth lesbar ist (NearDeath.IsAvailable: Classic Era und TBC). In Retail und WoW Forever ist das Leben
-- des Spielers immer geheim (generierte Doku, SecretReturns): dort gibt es weder Schalter noch Hinweis.
-- Quellen (Blizzard_ActionBar/Shared/ActionButton.lua, alle Clients): Knöpfe tragen ihren Aktionsplatz in button.action,
-- GetActionInfo(platz) liefert Art ("item", "spell", "macro") und ID. Makros werden nicht ausgewertet.
-- Die Markierungen sind eigene, ungeschützte Kind-Frames der Knöpfe (wie Glow-Bibliotheken); zeigen/verstecken geht
-- auch im Kampf, Blizzards Knöpfe selbst werden nicht verändert.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    emergencyHighlight = false,
  },
})

local Emergency = {}
ns.Emergency = Emergency

local EXIT_HEALTH = 0.15   -- Abstand zur Schwelle, damit schwankendes Leben nicht flackert
local EDGE_SIZE = 48       -- Breite des roten Rands in Pixeln
local EDGE_COLOR = { 0.9, 0, 0, 0.35 }
local GLOW_SIZE = 3        -- Rahmenstärke um markierte Knöpfe
local GLOW_COLOR = { 0.2, 1, 0.2, 0.9 }

-- Eigene Liste: Heiltränke und Gesundheitssteine (Classic Era, TBC), Item-IDs
Emergency.ITEMS = {
  118, 858, 929, 1710, 3928, 13446, 4596, 17348, 17349,  -- Heiltränke von schwach bis erheblich, Heiltränke (PvP)
  22829, 32947,                                          -- TBC: Superheiltrank, Auchenai-Heiltrank
  5512, 19004, 19005, 5511, 19006, 19007, 5509, 19008, 19009,  -- Gesundheitssteine (auch mit Talent verbessert)
  5510, 19010, 19011, 9421, 19012, 19013, 22103, 22104, 22105,
}
-- Notfallzauber (Rang 1; verglichen wird über den Namen, damit alle Ränge passen)
Emergency.SPELLS = {
  642, 498, 633, 1022,   -- Paladin: Gottesschild, Göttlicher Schutz, Handauflegung, Segen des Schutzes
  13908, 17,             -- Priester: Verzweifeltes Gebet, Machtwort: Schild
  11958, 45438,          -- Magier: Eisblock (Classic-Talent, TBC)
  5277, 1856,            -- Schurke: Entrinnen, Verschwinden
  5384,                  -- Jäger: Totstellen
  871, 12975,            -- Krieger: Schildwall, Letztes Gefecht
  6789,                  -- Hexenmeister: Todesmantel
  22842, 22812,          -- Druide: Rasende Regeneration, Baumrinde
  16188,                 -- Schamane: Schnelligkeit der Natur
}

local itemSet = {}
for _, itemId in ipairs(Emergency.ITEMS) do itemSet[itemId] = true end
local spellNames  -- [Name] = true, beim ersten Gebrauch aus der Client-Sprache

local active = false
local dirty = true      -- Leisten neu durchsuchen (Platz, Seite oder Haltung geändert)
local marked = {}       -- markierte Knöpfe
local glows = {}        -- [Knopf] = eigener Rahmen
local edge              -- roter Bildschirmrand

function Emergency.IsAvailable()
  return ns.NearDeath.IsAvailable()
end

local function spellName(spellId)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellId) end
  return GetSpellInfo and (GetSpellInfo(spellId)) or nil
end

local function emergencySpellNames()
  if spellNames then return spellNames end
  spellNames = {}
  for _, spellId in ipairs(Emergency.SPELLS) do
    local name = spellName(spellId)
    if type(name) == "string" and not ns.IsSecret(name) then spellNames[name] = true end
  end
  return spellNames
end

-- Gehört die Aktion auf diesem Platz in den Notfall?
function Emergency.IsEmergencyAction(slot)
  if type(slot) ~= "number" or not GetActionInfo then return false end
  local actionType, id = GetActionInfo(slot)
  if ns.IsSecret(actionType) or ns.IsSecret(id) then return false end
  if actionType == "item" then return itemSet[id] == true end
  if actionType == "spell" then
    local name = spellName(id)
    return type(name) == "string" and not ns.IsSecret(name) and emergencySpellNames()[name] == true
  end
  return false
end

-- Vier gleich breite Linien um den Knopf
local function glowFor(button)
  if glows[button] then return glows[button] end
  local glow = CreateFrame("Frame", nil, button)
  glow:SetAllPoints(button)
  glow:SetFrameLevel((button:GetFrameLevel() or 1) + 5)
  local sides = {
    { "TOPLEFT", "TOPRIGHT", 0, GLOW_SIZE }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, GLOW_SIZE },
    { "TOPLEFT", "BOTTOMLEFT", GLOW_SIZE, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", GLOW_SIZE, 0 },
  }
  for _, side in ipairs(sides) do
    local line = glow:CreateTexture(nil, "OVERLAY")
    line:SetColorTexture(unpack(GLOW_COLOR))
    line:SetPoint(side[1])
    line:SetPoint(side[2])
    if side[3] > 0 then line:SetWidth(side[3]) else line:SetHeight(side[4]) end
  end
  glow:Hide()
  glows[button] = glow
  return glow
end

local function edgeFrame()
  if edge then return edge end
  edge = CreateFrame("Frame", ns.GlobalName("Emergency"), UIParent)
  edge:SetAllPoints(UIParent)
  edge:SetFrameStrata("BACKGROUND")
  local sides = {
    { "TOPLEFT", "TOPRIGHT", nil, EDGE_SIZE }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, EDGE_SIZE },
    { "TOPLEFT", "BOTTOMLEFT", EDGE_SIZE, nil }, { "TOPRIGHT", "BOTTOMRIGHT", EDGE_SIZE, nil },
  }
  for _, side in ipairs(sides) do
    local bar = edge:CreateTexture(nil, "BACKGROUND")
    bar:SetColorTexture(unpack(EDGE_COLOR))
    bar:SetPoint(side[1])
    bar:SetPoint(side[2])
    if side[3] then bar:SetWidth(side[3]) else bar:SetHeight(side[4]) end
  end
  edge:Hide()
  return edge
end

local function clearMarks()
  for button in pairs(marked) do
    if glows[button] then glows[button]:Hide() end
  end
  marked = {}
end

local function markButtons()
  clearMarks()
  local names = {}
  for _, button in ipairs(ns.ActionBars.Buttons()) do
    if Emergency.IsEmergencyAction(button.action) then
      marked[button] = true
      glowFor(button):Show()
      names[#names + 1] = ns.Overrides.NameOf(button) .. "=" .. tostring(button.action)
    end
  end
  ns.Debug("emergency", "marked %s", table.concat(names, ", "))
  dirty = false
end

local function setActive(on)
  if on == active then
    if on and dirty then markButtons() end
    return
  end
  active = on
  ns.Debug("emergency", "active %s", on)
  if on then
    markButtons()
    edgeFrame():Show()
  else
    clearMarks()
    if edge then edge:Hide() end
  end
end

function Emergency.IsActive()
  return active
end

local function update()
  if not (ns.db and ns.db.emergencyHighlight) or not Emergency.IsAvailable() or UnitIsDeadOrGhost("player") then
    setActive(false)
    return
  end
  local fraction = ns.NearDeath.HealthFraction()
  if not fraction then
    setActive(false)
    return
  end
  if fraction <= ns.NearDeath.LOW_HEALTH then
    setActive(true)
  elseif fraction >= EXIT_HEALTH then
    setActive(false)
  else
    setActive(active)  -- dazwischen bleibt der Zustand, nur geänderte Leisten neu markieren
  end
end

-- Vorschau (Testen-Knopf): Markierung und Rand ein paar Sekunden zeigen, danach gilt wieder der echte Zustand
function Emergency.Preview()
  setActive(true)
  C_Timer.After(ns.Frames.PREVIEW_SECONDS, update)
end

local function onSlotsChanged()
  dirty = true
  if active then markButtons() end
end

-- Lebens-Events nur für den Spieler und nur, solange der Hinweis an und verfügbar ist
local healthEvents = ns.NewEventGroup()
for _, event in ipairs({ "UNIT_HEALTH", "UNIT_HEALTH_FREQUENT", "UNIT_MAXHEALTH" }) do
  healthEvents.Add(event, "player", update)
end
ns.RegisterEvent("PLAYER_DEAD", update)
for _, event in ipairs({ "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR" }) do
  ns.RegisterEvent(event, onSlotsChanged)
end
ns.RegisterApply(function(db)
  healthEvents.SetActive(db.emergencyHighlight and Emergency.IsAvailable())
  update()
end)

-- /lt debug check: welche Items und Zauber der Liste der Client kennt (Namen in der Client-Sprache)
ns.DebugLog.AddCheck("emergency.actions", function()
  local items, spells = {}, {}
  for _, itemId in ipairs(Emergency.ITEMS) do
    items[#items + 1] = { id = itemId, name = C_Item and C_Item.GetItemInfo and (C_Item.GetItemInfo(itemId)) or nil }
  end
  for _, spellId in ipairs(Emergency.SPELLS) do
    spells[#spells + 1] = { id = spellId, name = spellName(spellId) }
  end
  return { items = items, spells = spells }
end)
