-- Roadmap 445 (DialogKey-Tastensteuerung) & 447 (Reichweiten-Anzeige am Zielrahmen)
local DialogKey = addon.DialogKey
local TargetRange = addon.TargetRange

local function lastAction()
  local action = wow.questActions[#wow.questActions]
  return action and table.concat(action, " ", 1, #action) or nil
end

local function reset()
  wow.questActions = {}
end

wow.login()

---------------------------------------------------------------------------
-- 1. DialogKey: Standardeinstellung und Tastensteuerung
---------------------------------------------------------------------------
expect("dialogKeys default false", addon.Database.SettingDefault("dialogKeys"), false)

-- Deaktiviert: PressSpace und PressKey tun nichts
wow.fire("QUEST_DETAIL")
expect("disabled: PressSpace does nothing", DialogKey.PressSpace(), false)
expect("disabled: lastAction nil", lastAction(), nil)
wow.fire("QUEST_FINISHED")

-- Aktivieren
addon.Set("dialogKeys", true)

-- QUEST_DETAIL -> Leertaste nimmt an
wow.fire("QUEST_DETAIL")
expect("open state detail", DialogKey.GetDialogOpen(), "detail")
expectTrue("bindings active for ownerFrame", wow.overrideBindings[DialogKey.ownerFrame] ~= nil)
expectTrue("space pressed successfully", DialogKey.PressSpace())
expect("detail: AcceptQuest called", lastAction(), "accept")
reset()

-- QUEST_PROGRESS -> unvollständig vs vollständig
wow.fire("QUEST_PROGRESS")
expect("open state progress", DialogKey.GetDialogOpen(), "progress")
wow.state.questCompletable = false
expect("incomplete: PressSpace returns false", DialogKey.PressSpace(), false)
expect("incomplete: no action", lastAction(), nil)

wow.state.questCompletable = true
expectTrue("completable: PressSpace returns true", DialogKey.PressSpace())
expect("complete: CompleteQuest called", lastAction(), "complete")
reset()

-- QUEST_COMPLETE -> Belohnungsauswahl (<=1 vs >1)
-- Fall 1: 0 Belohnungen
wow.state.questChoices = {}
wow.fire("QUEST_COMPLETE")
expect("open state complete", DialogKey.GetDialogOpen(), "complete")
expectTrue("0 choices: PressSpace returns true", DialogKey.PressSpace())
expect("0 choices: reward called", lastAction(), "reward")
reset()

-- Fall 2: 1 Belohnung
wow.state.questChoices = { "Stab" }
wow.fire("QUEST_COMPLETE")
expectTrue("1 choice: PressSpace returns true", DialogKey.PressSpace())
expect("1 choice: reward 1 called", lastAction(), "reward 1")
reset()

-- Fall 3: Mehrere Belohnungen -> Leertaste tut nichts, PressKey wählt
wow.state.questChoices = { "Stab", "Schwert", "Schild" }
wow.fire("QUEST_COMPLETE")
expect("multiple choices: PressSpace returns false", DialogKey.PressSpace(), false)
expect("multiple choices: no action on Space", lastAction(), nil)

expectTrue("PressKey(2) returns true", DialogKey.PressKey(2))
expect("PressKey(2): reward 2 called", lastAction(), "reward 2")
reset()

-- PressKey außerhalb des Bereichs tut nichts
expect("PressKey(5) out of range returns false", DialogKey.PressKey(5), false)
expect("PressKey(5): no action", lastAction(), nil)

-- GOSSIP_SHOW -> aktive Quests, verfügbare Quests, Optionen
-- Fall A: aktive abgeschlossene Quest hat Vorrang
wow.state.gossip.active = { { questID = 101, isComplete = true } }
wow.state.gossip.available = { { questID = 102 } }
wow.state.gossip.options = { { gossipOptionID = 201, orderIndex = 1 } }
wow.fire("GOSSIP_SHOW")
expect("open state gossip", DialogKey.GetDialogOpen(), "gossip")
expectTrue("gossip active quest: PressSpace true", DialogKey.PressSpace())
expect("gossip: active quest selected", lastAction(), "selectActive 101")
reset()

-- Fall B: keine aktive Quest, erste verfügbare gewählt
wow.state.gossip.active = {}
wow.state.gossip.available = { { questID = 102 } }
wow.state.gossip.options = { { gossipOptionID = 201, orderIndex = 1 } }
wow.fire("GOSSIP_SHOW")
expectTrue("gossip available quest: PressSpace true", DialogKey.PressSpace())
expect("gossip: available quest selected", lastAction(), "selectAvailable 102")
reset()

-- Fall C: genau 1 Gesprächsoption
wow.state.gossip.active = {}
wow.state.gossip.available = {}
wow.state.gossip.options = { { gossipOptionID = 201, orderIndex = 1 } }
wow.fire("GOSSIP_SHOW")
expectTrue("gossip single option: PressSpace true", DialogKey.PressSpace())
expect("gossip: single option selected", lastAction(), "selectOption 201")
reset()

-- Fall D: PressKey(2) über aktive Quests, verfügbare Quests und Optionen hinweg
wow.state.gossip.active = { { questID = 101, isComplete = false } }     -- Index 1
wow.state.gossip.available = { { questID = 102 } }                       -- Index 2
wow.state.gossip.options = { { gossipOptionID = 201, orderIndex = 1 } } -- Index 3
wow.fire("GOSSIP_SHOW")
expectTrue("PressKey(2) selects available quest", DialogKey.PressKey(2))
expect("gossip PressKey(2): selectAvailable 102", lastAction(), "selectAvailable 102")
reset()

expectTrue("PressKey(3) selects gossip option", DialogKey.PressKey(3))
expect("gossip PressKey(3): selectOption 201", lastAction(), "selectOption 201")
reset()

-- Dialog schließen setzt Bindings und Status zurück
wow.fire("GOSSIP_CLOSED")
expect("dialogOpen nil after GOSSIP_CLOSED", DialogKey.GetDialogOpen(), nil)
expectTrue("bindings cleared", wow.overrideBindings[DialogKey.ownerFrame] == nil)

wow.fire("QUEST_DETAIL")
expect("dialogOpen detail", DialogKey.GetDialogOpen(), "detail")
wow.fire("QUEST_FINISHED")
expect("dialogOpen nil after QUEST_FINISHED", DialogKey.GetDialogOpen(), nil)

-- Kampf (PLAYER_REGEN_DISABLED) hebt Bindings auf und sperrt PressSpace
wow.fire("QUEST_DETAIL")
expect("dialogOpen detail before combat", DialogKey.GetDialogOpen(), "detail")
expectTrue("bindings present before combat", wow.overrideBindings[DialogKey.ownerFrame] ~= nil)

wow.state.inCombat = true
wow.fire("PLAYER_REGEN_DISABLED")
expect("dialogOpen reset on combat", DialogKey.GetDialogOpen(), nil)
expectTrue("bindings cleared on combat", wow.overrideBindings[DialogKey.ownerFrame] == nil)
expect("PressSpace blocked in combat", DialogKey.PressSpace(), false)
expect("no action in combat", lastAction(), nil)
wow.state.inCombat = false

-- Shift-Taste und Tastaturfokus blockieren Tastendruck
wow.fire("QUEST_DETAIL")
wow.state.shiftDown = true
expect("shift down blocks PressSpace", DialogKey.PressSpace(), false)
expect("no action with shift", lastAction(), nil)
wow.state.shiftDown = false

local editBox = CreateFrame("EditBox")
editBox:SetFocus()
expect("focus blocks PressSpace", DialogKey.PressSpace(), false)
expect("no action with keyboard focus", lastAction(), nil)
editBox:ClearFocus()

expectTrue("PressSpace works without focus", DialogKey.PressSpace())
expect("detail accepted after focus cleared", lastAction(), "accept")
reset()
wow.fire("QUEST_FINISHED")

---------------------------------------------------------------------------
-- 2. TargetRange: Reichweiten-Schätzung und Frame
---------------------------------------------------------------------------
expect("showTargetRange default false", addon.Database.SettingDefault("showTargetRange"), false)
expectTrue("TargetRange frame exists", TargetRange.Frame() ~= nil)
expect("frame initially hidden", TargetRange.Frame():IsShown(), false)

addon.Set("showTargetRange", true)

-- Ohne Ziel: nil und Frame versteckt
wow.state.units.target = nil
expect("no target: Estimate nil", TargetRange.Estimate("target"), nil)
TargetRange.Update()
expect("no target: frame hidden", TargetRange.Frame():IsShown(), false)

-- Ziel existiert
wow.state.units.target = { name = "Gegner", dead = false }

-- Distanz 3: 0-10 m
wow.state.targetInteractDistance = { [3] = true, [2] = true, [1] = true }
expect("Estimate 0-10 m", TargetRange.Estimate("target"), "0-10 m")
wow.fire("PLAYER_TARGET_CHANGED")
expectTrue("frame shown with target", TargetRange.Frame():IsShown())
expect("text 0-10 m", TargetRange.Text(), "0-10 m")

-- Distanz 2: 10-11 m
wow.state.targetInteractDistance = { [3] = false, [2] = true, [1] = true }
expect("Estimate 10-11 m", TargetRange.Estimate("target"), "10-11 m")
wow.advance(0.25)
wow.update(0.25)
expect("text 10-11 m on periodic update", TargetRange.Text(), "10-11 m")

-- Distanz 1: 11-28 m
wow.state.targetInteractDistance = { [3] = false, [2] = false, [1] = true }
expect("Estimate 11-28 m", TargetRange.Estimate("target"), "11-28 m")
TargetRange.Update()
expect("text 11-28 m", TargetRange.Text(), "11-28 m")

-- Außerhalb Distanz 1: 28+ m
wow.state.targetInteractDistance = { [3] = false, [2] = false, [1] = false }
expect("Estimate 28+ m", TargetRange.Estimate("target"), "28+ m")
TargetRange.Update()
expect("text 28+ m", TargetRange.Text(), "28+ m")

-- Totes Ziel: Estimate nil und Frame versteckt
wow.state.units.target.dead = true
expect("dead target: Estimate nil", TargetRange.Estimate("target"), nil)
TargetRange.Update()
expect("dead target: frame hidden", TargetRange.Frame():IsShown(), false)
wow.state.units.target.dead = false

-- Geheime API-Rückgabe (Retail/Forever): Fallback 28+ m
wow.state.targetInteractDistance = wow.SECRET
expect("secret distance: fallback 28+ m", TargetRange.Estimate("target"), "28+ m")

-- Deaktivieren blendet Frame aus
addon.Set("showTargetRange", false)
expect("disabled: frame hidden", TargetRange.Frame():IsShown(), false)
