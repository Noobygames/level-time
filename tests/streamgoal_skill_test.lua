-- Level Time Goals, Roadmap 297: Beruf auf einen Wert bringen (Startwert aus dem Client, Stand aus CHAT_MSG_SKILL).
local Goals = streamGoal.Goals
local L = streamGoal.L

SKILL_RANK_UP = "Eure Fertigkeit in %s hat sich auf %d erhöht."
-- Classic-Liste der Fertigkeiten: Überschrift, dann Berufe
local skillLines = {
  { "Berufe", true, true, 0 },
  { "Kräuterkunde", false, false, 40 },
  { "Bergbau", false, false, 12 },
}
function GetNumSkillLines() return #skillLines end
function GetSkillLineInfo(index) return unpack(skillLines[index]) end

wow.login({ level = 20 })

SlashCmdList.STREAMGOAL("add skill 75 kräuter")
local herbs = Goals.Active()[1]
expect("Beruf-Art", herbs.kind, "skill")
expect("voller Name aus dem Client", herbs.params.skill, "Kräuterkunde")
expect("Startwert aus dem Client", herbs.progress, 40)
expect("Titel", Goals.Title(herbs), string.format(L.SG_GOAL_SKILL, "Kräuterkunde", 75))

local goal, err = Goals.Create("skill", { skill = "Bergbau" }, 10)
expect("schon erreicht", goal, nil)
expect("Meldung erreicht", err, L.SG_ERR_ALREADY_REACHED)
expect("ohne Name", select(2, Goals.Create("skill", { skill = " " }, 10)), L.SG_ERR_SKILL)

-- Unbekannter Beruf (z.B. noch nicht gelernt): beginnt bei 0
SlashCmdList.STREAMGOAL("add skill 5 Angeln")
local fishing = Goals.Active()[2]
expect("unbekannt bei 0", fishing.progress, 0)

wow.fire("CHAT_MSG_SKILL", "Eure Fertigkeit in Bergbau hat sich auf 13 erhöht.")
expect("anderer Beruf zählt nicht", herbs.progress, 40)
wow.fire("CHAT_MSG_SKILL", "Eure Fertigkeit in Kräuterkunde hat sich auf 41 erhöht.")
expect("Kräuterkunde 41", herbs.progress, 41)
wow.fire("CHAT_MSG_SKILL", "Eure Fertigkeit in Angeln hat sich auf 5 erhöht.")
expect("Angeln erreicht", fishing.status, Goals.DONE)
wow.fire("CHAT_MSG_SKILL", "Eure Fertigkeit in Kräuterkunde hat sich auf 75 erhöht.")
expect("Kräuterkunde erreicht", herbs.status, Goals.DONE)
