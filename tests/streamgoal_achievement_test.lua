-- Level Time Goals, Roadmap 309: Erfolg erreichen (Kriterien als Fortschritt, nur mit Erfolgs-API) und Ehre sammeln.
local Goals = streamGoal.Goals
local L = streamGoal.L

wow.login({ level = 60 })

---------------------------------------------------------------------------
-- Ohne Erfolgs-API (Classic Era, TBC): keine Art
---------------------------------------------------------------------------
expect("ohne API nicht verfügbar", Goals.IsAvailable("achievement"), false)
SlashCmdList.STREAMGOAL("add achievement 1000")
expect("ohne API kein Ziel", #Goals.Active(), 0)

---------------------------------------------------------------------------
-- Mit Erfolgs-API (Retail): ein Kriterium mit Menge
---------------------------------------------------------------------------
local achievements = {
  [1000] = { name = "Wolfsjäger", completed = false, criteria = { { "Wölfe", 0, false, 12, 50 } } },
  [2000] = { name = "Schon da", completed = true, criteria = {} },
  [3000] = { name = "Drei Dinge", completed = false,
    criteria = { { "Eins", 0, true, 0, 0 }, { "Zwei", 0, false, 0, 0 }, { "Drei", 0, false, 0, 0 } } },
}
function GetAchievementInfo(id)
  local a = achievements[id]
  if not a then return nil end
  return id, a.name, 10, a.completed, 1, 1, 24, "", 0, 236
end
function GetAchievementNumCriteria(id) return #achievements[id].criteria end
function GetAchievementCriteriaInfo(id, index) return unpack(achievements[id].criteria[index]) end
function GetAchievementLink(id) return "|cffffff00|Hachievement:" .. id .. ":0:0:0:0:0:0:0:0|h[" .. achievements[id].name .. "]|h|r" end

expect("mit API verfügbar", Goals.IsAvailable("achievement"), true)
SlashCmdList.STREAMGOAL("add achievement " .. GetAchievementLink(1000))
local wolves = Goals.Active()[1]
expect("Erfolg aus dem Link", wolves.params.achievementId, 1000)
expect("Titel mit Name", Goals.Title(wolves), string.format(L.SG_GOAL_ACHIEVEMENT, "Wolfsjäger"))
expect("Ziel = Menge des Kriteriums", wolves.target, 50)
expect("Stand aus dem Kriterium", wolves.progress, 12)

SlashCmdList.STREAMGOAL("add achievement 2000")
expect("schon erreicht: kein Ziel", #Goals.Active(), 1)
expect("unbekannter Erfolg", select(2, Goals.Create("achievement", { input = "999" })), L.SG_ERR_ACHIEVEMENT)

SlashCmdList.STREAMGOAL("add achievement 3000")
local three = Goals.Active()[2]
expect("drei Kriterien", three.target, 3)
expect("eins erledigt", three.progress, 1)

achievements[1000].criteria[1][4] = 30
achievements[3000].criteria[2][3] = true
wow.fire("CRITERIA_UPDATE")
expect("Menge steigt", wolves.progress, 30)
expect("zweites Kriterium", three.progress, 2)

wow.fire("ACHIEVEMENT_EARNED", 1000, false)
expect("Erfolg erreicht", wolves.status, Goals.DONE)
expect("anderer läuft weiter", three.status, Goals.ACTIVE)

---------------------------------------------------------------------------
-- Ehre
---------------------------------------------------------------------------
COMBATLOG_HONORAWARD = "Euch wurden %d Ehrenpunkte zuerkannt."
SlashCmdList.STREAMGOAL("add honor 100")
local honor = Goals.Active()[2]
expect("Ehre-Art", honor.kind, "honor")
wow.fire("CHAT_MSG_COMBAT_HONOR_GAIN", "Grimbar stirbt, ehrenhafter Sieg Rang: Gefreiter (Geschätzte Ehrenpunkte: 12)")
expect("Sieg zählt geschätzte Ehre", honor.progress, 12)
wow.fire("CHAT_MSG_COMBAT_HONOR_GAIN", "Euch wurden 82 Ehrenpunkte zuerkannt.")
expect("Bonusehre zählt", honor.progress, 94)
wow.fire("CHAT_MSG_COMBAT_HONOR_GAIN", "Euch wurden 6 Ehrenpunkte zuerkannt.")
expect("Ehre erreicht", honor.status, Goals.DONE)
