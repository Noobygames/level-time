-- Notfall bei wenig Leben: unter 10 % Notfall-Knöpfe markieren und Bildschirmrand rot, aus ab 15 %; nur Classic
local Emergency = addon.Emergency
wow.state.interface = 11509  -- Classic Era: Leben lesbar

local function actionButton(name, slot)
  local button = CreateFrame("CheckButton", name)
  button.action = slot
  return button
end
local potionButton = actionButton("ActionButton1", 1)
local shieldButton = actionButton("ActionButton2", 2)
local otherButton = actionButton("ActionButton3", 3)
wow.state.spellNames[642] = "Gottesschild"
wow.state.spellNames[1020] = "Gottesschild"  -- höherer Rang, gleicher Name
wow.state.spellNames[635] = "Heiliges Licht"
wow.state.actions = { { "item", 929 }, { "spell", 1020 }, { "spell", 635 } }

local function health(percent)
  wow.state.health = wow.state.healthMax * percent / 100
  wow.fire("UNIT_HEALTH", "player")
end

local function glowShown(button)
  local glow = wow.findFrame(function(frame) return frame._parent == button end)
  return glow ~= nil and glow:IsShown()
end

wow.login({ level = 30 })
expectTrue("in Classic verfügbar", Emergency.IsAvailable())
expectTrue("Heiltrank erkannt", Emergency.IsEmergencyAction(1))
expectTrue("anderer Rang über den Namen", Emergency.IsEmergencyAction(2))
expectTrue("normaler Zauber nicht", not Emergency.IsEmergencyAction(3))

-- Aus: nichts
health(5)
expectTrue("aus: inaktiv", not Emergency.IsActive())

addon.Set("emergencyHighlight", true)
expectTrue("an: sofort aktiv bei 5 %", Emergency.IsActive())
expectTrue("Trank markiert", glowShown(potionButton))
expectTrue("Gottesschild markiert", glowShown(shieldButton))
expectTrue("anderer Knopf nicht", not glowShown(otherButton))
expectTrue("roter Rand", LevelTimerEmergency:IsShown())

-- Leiste geändert, während der Notfall läuft
wow.state.actions[3] = { "item", 5509 }
wow.fire("ACTIONBAR_SLOT_CHANGED", 3)
expectTrue("neuer Gesundheitsstein markiert", glowShown(otherButton))

-- Dazwischen bleibt es, ab 15 % aus
health(12)
expectTrue("12 %: noch aktiv", Emergency.IsActive())
health(20)
expectTrue("20 %: aus", not Emergency.IsActive())
expectTrue("Markierung weg", not glowShown(potionButton))
expectTrue("Rand weg", not LevelTimerEmergency:IsShown())
health(12)
expectTrue("12 % von oben: nicht aktiv", not Emergency.IsActive())

-- Tod beendet es
health(5)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
expectTrue("tot: aus", not Emergency.IsActive())
wow.state.dead = false

-- Geheimes Leben (wie Retail/Forever): aus
health(5)
expectTrue("wieder aktiv", Emergency.IsActive())
wow.state.health = wow.SECRET
wow.fire("UNIT_HEALTH", "player")
expectTrue("geheim: aus", not Emergency.IsActive())

-- Retail/Forever: gar nicht verfügbar
wow.state.interface = 16001
expectTrue("Forever: nicht verfügbar", not Emergency.IsAvailable())
