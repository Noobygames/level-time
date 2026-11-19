-- Kreatur-Porträt: bleibt das Modell leer (Kreatur noch nicht im Cache), lädt ein Wiederholer SetCreature erneut,
-- bis GetModelFileID etwas liefert; danach keine weiteren Versuche.
local CreatureModel = addon.CreatureModel
wow.login()
local portrait = CreatureModel.Create(UIParent, 20)
local state = { calls = 0, file = nil }  -- Tabelle statt Locals (gopher-lua)
CreatureModel.Set(portrait, 644)
local model = portrait.model
function model:SetCreature() state.calls = state.calls + 1 end
function model:GetModelFileID() return state.file end
CreatureModel.Set(portrait, nil)
CreatureModel.Set(portrait, 644)
expect("erster Versuch", state.calls, 1)
expectTrue("Wiederholer läuft", portrait.retry:IsShown())
wow.update(0.6)
expect("zweiter Versuch nach Pause", state.calls, 2)
state.file = 12345
wow.update(0.6)
expectTrue("geladen: Wiederholer aus", not portrait.retry:IsShown())
wow.update(0.6)
expect("keine weiteren Versuche", state.calls, 2)
