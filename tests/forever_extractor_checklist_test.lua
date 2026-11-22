-- Spiel-Checkliste (/lte todo): Trigger meldet einmal, Liste öffnet, OK speichert und loggt, off schaltet Hinweise ab,
-- Client-Filter (Forever-Tickets in Forever offen)
local extractor = wow.loadExtractor()
wow.login()
local CheckList = extractor.CheckList
expectTrue("Checkliste geladen", CheckList ~= nil)

local function toastShown() return _G.LevelTimerCheckListToast ~= nil and _G.LevelTimerCheckListToast:IsShown() end

-- Client-Filter: Forever-Ticket offen
local open = {}
for _, item in ipairs(CheckList.Open()) do open[item.entry.id] = true end
expectTrue("Forever-Ticket offen", open["LT-321"])

-- Instanz betreten: ein Hinweis, ein zweites Mal nicht
wow.state.instance = { type = "party", name = "Test" }
wow.fire("PLAYER_ENTERING_WORLD")
expectTrue("Hinweisfenster nach Instanz", toastShown())
_G.LevelTimerCheckListToast:Hide()
wow.fire("PLAYER_ENTERING_WORLD")
expect("kein zweiter Hinweis", toastShown(), false)

-- /lte todo öffnet die Liste
SlashCmdList.LEVELTIMEREXTRACTOR("todo")
expectTrue("Liste offen", _G.LevelTimerCheckList ~= nil and _G.LevelTimerCheckList:IsShown())

-- OK markiert und schreibt ins Debug-Log
CheckList.Mark("LT-321", "ok", "")
local result = LevelTimerDebugLog.checkResults["LT-321"]
expect("Status ok", result and result.status, "ok")
local logged = false
for _, line in ipairs(LevelTimerDebugLog.lines or {}) do
  if line:find("checklist", 1, true) and line:find("LT-321 ok", 1, true) then logged = true end
end
expectTrue("Debug-Log-Zeile", logged)
open = {}
for _, item in ipairs(CheckList.Open()) do open[item.entry.id] = true end
expect("erledigt nicht mehr offen", open["LT-321"], nil)

-- Später bleibt offen
CheckList.Mark("LT-390", "skip", "")
open = {}
for _, item in ipairs(CheckList.Open()) do open[item.entry.id] = true end
expectTrue("Später bleibt offen", open["LT-390"])

-- retry: nachgebesserter Eintrag, älteres "fail" ist wieder offen, neues Ergebnis nicht
LevelTimerDebugLog.checkResults["LT-388"] = { status = "fail", t = "2026-11-17 16:05:51", note = "" }
open = {}
for _, item in ipairs(CheckList.Open()) do open[item.entry.id] = true end
expectTrue("altes fail nach retry offen", open["LT-388"])
CheckList.Mark("LT-388", "fail", "")
open = {}
for _, item in ipairs(CheckList.Open()) do open[item.entry.id] = true end
expect("neues fail bleibt zu", open["LT-388"], nil)

-- off: keine Hinweise mehr
SlashCmdList.LEVELTIMEREXTRACTOR("todo off")
expect("Hinweise aus", CheckList.Enabled(), false)
_G.LevelTimerCheckListToast:Hide()
wow.fire("QUEST_ACCEPTED", 1)
expect("kein Hinweis bei aus", toastShown(), false)
SlashCmdList.LEVELTIMEREXTRACTOR("todo on")
expect("Hinweise an", CheckList.Enabled(), true)

-- nicht im Kampf
wow.state.combatLockdown = true
wow.fire("LOOT_OPENED")
expect("kein Hinweis im Kampf", toastShown(), false)
wow.state.combatLockdown = false

expect("keine Lua-Fehler", #wow.errors, 0)
