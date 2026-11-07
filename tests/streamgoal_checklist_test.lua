-- Level Time Goals, Roadmap 304: Checkliste mit Punkten zum Abhaken und Teilzielen anderer Arten.
local Goals = streamGoal.Goals
local L = streamGoal.L

local function clickCard(index, shift)
  local card = _G["StreamGoalCard" .. index]
  wow.state.shiftDown = shift or false
  card._scripts.OnMouseUp(card, "LeftButton")
  wow.state.shiftDown = false
end

wow.login({ level = 10 })

SlashCmdList.STREAMGOAL("add list Holz sammeln; Boss legen ;  ; Ruf freundlich")
local list = Goals.Active()[1]
expect("Checkliste", list.kind, "checklist")
expect("drei Punkte (leere fallen weg)", #list.params.items, 3)
expect("Ziel = Punkte", list.target, 3)
expect("Titel", Goals.Title(list), string.format(L.SG_GOAL_CHECKLIST, 3))
expect("leere Liste", select(2, Goals.Create("checklist", { text = " ; " })), L.SG_ERR_CHECKLIST)

-- Teilziel: Kills, hängt an der Liste und hat keine eigene Karte
SlashCmdList.STREAMGOAL("add kills 2")
local kills = Goals.Active()[2]
expect("eigene Karte vor dem Anhängen", StreamGoalCard2:IsShown(), true)
SlashCmdList.STREAMGOAL("sub " .. list.id .. " " .. kills.id)
expect("angehängt", kills.parentId, list.id)
expect("Ziel wächst", list.target, 4)
expect("keine eigene Karte mehr", StreamGoalCard2:IsShown(), false)
expect("Zeile in der Checkliste", StreamGoalCard1.body._text:find(Goals.Title(kills), 1, true) ~= nil, true)
SlashCmdList.STREAMGOAL("sub " .. kills.id .. " " .. list.id)
expect("falsche Richtung", wow.printed[#wow.printed]:find(L.SG_ERR_NOT_CHECKLIST, 1, true) ~= nil, true)

-- Abhaken per Klick, Shift+Klick nimmt zurück
clickCard(1)
expect("erster Punkt", list.params.items[1].done, true)
expect("Stand 1", list.progress, 1)
clickCard(1)
clickCard(1, true)
expect("zweiter zurückgenommen", list.params.items[2].done, false)
expect("Stand wieder 1", list.progress, 1)
clickCard(1)
clickCard(1)
expect("drei Punkte erledigt", list.progress, 3)
expect("Liste läuft, Teilziel fehlt", list.status, Goals.ACTIVE)

-- Teilziel erreicht: Liste fertig
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 45 Erfahrung.")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 45 Erfahrung.")
expect("Teilziel erreicht", kills.status, Goals.DONE)
expect("Checkliste erreicht", list.status, Goals.DONE)
