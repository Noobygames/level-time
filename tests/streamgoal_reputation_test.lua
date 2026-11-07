-- Level Time Goals, Roadmap 303: Ruf gewinnen (Chat) und eine Rufstufe erreichen (Rufliste, Classic- und Retail-API).
local Goals = streamGoal.Goals
local L = streamGoal.L

FACTION_STANDING_INCREASED = "Euer Ruf bei der Fraktion '%s' hat sich um %d verbessert."
FACTION_STANDING_LABEL5, FACTION_STANDING_LABEL6 = "Freundlich", "Wohlwollend"
-- Classic-Rufliste: Überschrift, Fraktionen
local factions = {
  { "Horde", "", 4, 0, 0, 0, false, false, true },
  { "Orgrimmar", "", 5, 3000, 9000, 4000, false, false, false },
}
function GetNumFactions() return #factions end
function GetFactionInfo(index) return unpack(factions[index]) end

wow.login({ level = 30 })

SlashCmdList.STREAMGOAL("add rep honored orgri")
local honored = Goals.Active()[1]
expect("Stufe", honored.params.mode, "standing")
expect("voller Name", honored.params.faction, "Orgrimmar")
expect("Ziel = Schwelle Wohlwollend", honored.target, 9000)
expect("Start beim Rufwert", honored.start, 4000)
expect("Titel", Goals.Title(honored), string.format(L.SG_GOAL_REP_STANDING, "Orgrimmar", "Wohlwollend"))
expect("Stand als Stufen", Goals.CountText(honored), "Freundlich > Wohlwollend")
expect("unbekannte Fraktion", select(2, Goals.Create("reputation", { mode = "standing", faction = "Sturmwind", standing = 6 })),
  L.SG_ERR_FACTION_UNKNOWN)
SlashCmdList.STREAMGOAL("add rep friendly Orgrimmar")
expect("schon freundlich: kein Ziel", #Goals.Active(), 1)

-- Ruf gewinnen (auch ohne Eintrag in der Liste)
SlashCmdList.STREAMGOAL("add rep 500 Dunkelspeertrolle")
local gain = Goals.Active()[2]
expect("gewinnen", gain.params.mode, "gain")
wow.fire("CHAT_MSG_COMBAT_FACTION_CHANGE", "Euer Ruf bei der Fraktion 'Dunkelspeertrolle' hat sich um 250 verbessert.")
expect("Ruf gezählt", gain.progress, 250)
wow.fire("CHAT_MSG_COMBAT_FACTION_CHANGE", "Euer Ruf bei der Fraktion 'Orgrimmar' hat sich um 250 verbessert.")
expect("andere Fraktion zählt nicht", gain.progress, 250)

-- Stufe über UPDATE_FACTION
factions[2][6] = 6500
wow.fire("UPDATE_FACTION")
expectNear("halber Weg", streamGoal.Goals.Fraction(honored), 0.5)
factions[2][3], factions[2][6] = 6, 9000
wow.fire("UPDATE_FACTION")
expect("Wohlwollend erreicht", honored.status, Goals.DONE)

-- Retail-API wird bevorzugt
C_Reputation = { GetNumFactions = function() return 1 end,
  GetFactionDataByIndex = function() return { name = "Silbermond", reaction = 4, currentStanding = 100, isHeader = false } end }
SlashCmdList.STREAMGOAL("add rep exalted Silbermond")
expect("Retail-Liste", Goals.Active()[2].params.faction, "Silbermond")
expect("Retail-Wert", Goals.Active()[2].progress, 100)
