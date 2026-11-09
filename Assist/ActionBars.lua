-- Aktionsleisten anpassen (Reiter Komfort, Oberfläche; je Einstellung, Standard aus). Alles umkehrbar ohne /reload.
--   hideKeybindText  Tastenbelegung auf den Knöpfen unsichtbar (Alpha 0 auf button.HotKey; Blizzard zeigt, versteckt
--                    und färbt den Text nur, die Transparenz fasst es nicht an). Der Reichweitenpunkt verschwindet mit.
--   hideMacroText    Makronamen unsichtbar (button.Name, ebenso Alpha 0).
--   rangeColor       Symbol rot, solange das Ziel außer Reichweite ist. Blizzard färbt bei fehlendem Mana schon blau
--                    und bei Unbenutzbarkeit grau (ActionBarActionButtonMixin:UpdateUsable), wir nur zusätzlich rot.
-- Quelle (Blizzard_ActionBar/Shared/ActionButton.lua, gleich in Retail, Forever und Classic): ACTION_RANGE_CHECK_UPDATE
-- ruft die globale Funktion ActionButton_UpdateRangeIndicator(button, checksRange, inRange); UpdateUsable setzt die
-- Symbolfarbe bei jeder Änderung neu. Beide werden nur per hooksecurefunc ergänzt (kein Ersetzen, kein Taint); die
-- Farbe des Symbols (Textur) zu setzen ist auch im Kampf erlaubt. Geheime Reichweitenwerte lassen wir aus.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    hideKeybindText = false,
    hideMacroText = false,
    rangeColor = false,
  },
})

local ActionBars = {}
ns.ActionBars = ActionBars

local BUTTONS_PER_BAR = 12
-- Knopfnamen der Leisten (Name der Leiste + "Button" + Nummer); MultiBar5-7 gibt es nicht in jedem Client
ActionBars.BAR_PREFIXES = {
  "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
  "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
}
ActionBars.OUT_OF_RANGE_COLOR = { 0.85, 0.15, 0.15 }

local setAlpha = ns.Overrides.Alpha()
local HIDDEN = 0

-- Alle vorhandenen Aktionsknöpfe der Standardleisten
function ActionBars.Buttons()
  local list = {}
  for _, prefix in ipairs(ActionBars.BAR_PREFIXES) do
    for index = 1, BUTTONS_PER_BAR do
      local button = _G[prefix .. index]
      if button then table.insert(list, button) end
    end
  end
  return list
end

---------------------------------------------------------------------------
-- Reichweite
---------------------------------------------------------------------------
local outOfRange = {}  -- Knopf -> true, solange rot gefärbt
local managed = {}     -- Knöpfe mit UpdateUsable-Hook (nur unsere Standardleisten, nicht Begleiter- oder Haltungsleiste)
local rangeHooked = false

local function paintOutOfRange(button)
  if button.icon then button.icon:SetVertexColor(unpack(ActionBars.OUT_OF_RANGE_COLOR)) end
end

local function onRangeUpdate(button, checksRange, inRange)
  if not managed[button] or not ns.db.rangeColor then return end
  if ns.IsSecret(checksRange) or ns.IsSecret(inRange) then return end
  local out = checksRange and not inRange and true or false
  if out == (outOfRange[button] == true) then return end
  outOfRange[button] = out or nil
  if out then
    paintOutOfRange(button)
  else
    button:UpdateUsable()  -- Blizzards Farbe (weiß, blau oder grau) zurück
  end
end

-- Nach Blizzards UpdateUsable: rot bleibt, solange außer Reichweite
local function onUsableUpdate(button)
  if outOfRange[button] and ns.db.rangeColor then paintOutOfRange(button) end
end

local function hookRange()
  if rangeHooked or not ActionButton_UpdateRangeIndicator then return end
  rangeHooked = true
  hooksecurefunc("ActionButton_UpdateRangeIndicator", onRangeUpdate)
  for _, button in ipairs(ActionBars.Buttons()) do
    if button.UpdateUsable then
      managed[button] = true
      hooksecurefunc(button, "UpdateUsable", onUsableUpdate)
    end
  end
end

-- Ausgeschaltet: rote Knöpfe bekommen Blizzards Farbe zurück
local function clearRange()
  for button in pairs(outOfRange) do
    outOfRange[button] = nil
    button:UpdateUsable()
  end
end

function ActionBars.IsOutOfRange(button)
  return outOfRange[button] == true
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------
-- Nur bei geänderten eigenen Einstellungen (Roadmap 395): jedes Apply (jede Einstellung, Profilwechsel) fasste sonst
-- rund 100 Tasten- und Makrotexte an. Blizzard ändert die Transparenz dieser Texte nicht, die Knöpfe bleiben dieselben.
local applied = {}

function ActionBars.Apply(db)
  local hotKeys, macros, range = db.hideKeybindText and true or false, db.hideMacroText and true or false,
    db.rangeColor and true or false
  if applied.hotKeys == hotKeys and applied.macros == macros and applied.range == range then return end
  if applied.hotKeys ~= hotKeys or applied.macros ~= macros then
    for _, button in ipairs(ActionBars.Buttons()) do
      setAlpha(button.HotKey, hotKeys, HIDDEN)
      setAlpha(button.Name, macros, HIDDEN)
    end
  end
  applied.hotKeys, applied.macros, applied.range = hotKeys, macros, range
  if range then hookRange() else clearRange() end
end

ns.RegisterApply(ActionBars.Apply)
