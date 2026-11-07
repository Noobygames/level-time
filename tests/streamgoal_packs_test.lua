-- Level Time Goals, Roadmap 301: fertige Pakete, eigene Pakete aus laufenden Zielen, Teilen und Importieren.
local Goals = streamGoal.Goals
local Packs = streamGoal.Packs
local L = streamGoal.L

wow.login({ level = 10 })

-- Fertiges Paket: Ziele relativ zum Level
SlashCmdList.STREAMGOAL("pack hardcore")
expect("drei Ziele angelegt", #Goals.Active(), 3)
expect("Regel bis Level 20", Goals.Active()[1].target, 20)
expect("Level 15", Goals.Active()[2].target, 15)
expect("Meldung", wow.printed[#wow.printed], "|cfff4c95dLevel Time Goals:|r "
  .. string.format(L.SG_CHAT_PACK_APPLIED, 3, L.SG_PACK_HARDCORE))

-- Kein Platz: nichts angelegt
SlashCmdList.STREAMGOAL("pack selffound")
SlashCmdList.STREAMGOAL("pack explorer")
expect("kein Platz für drei weitere", #Goals.Active(), 6)
expect("Meldung Platz", wow.printed[#wow.printed]:find(string.format(L.SG_ERR_PACK_ROOM, 3, 0), 1, true) ~= nil, true)

-- Eigenes Paket aus den laufenden Zielen (Eingaben vor prepare, z.B. Quest-Kette als Text)
for _, goal in ipairs(Goals.Active()) do Goals.Cancel(goal.id) end
SlashCmdList.STREAMGOAL("add quest 101 102")
SlashCmdList.STREAMGOAL("add custom 3 Drei Wölfe")
SlashCmdList.STREAMGOAL("deadline " .. Goals.Active()[2].id .. " 2h")
expect("ohne Namen", Packs.Save(" "), L.SG_ERR_PACK_NAME)
expect("Name eines fertigen Pakets", Packs.Save("hardcore"), L.SG_ERR_PACK_NAME)

SlashCmdList.STREAMGOAL("")
expectTrue("Reiter Vorlagen", wow.click(L.SG_TAB_PACKS))
streamGoal.PacksView.nameBox:SetText("Wolfstag")
expectTrue("Speichern", wow.click(L.SG_PACK_SAVE))
local saved = StreamGoalDB.packs["Wolfstag"]
expectTrue("Paket gespeichert", saved ~= nil and #saved.goals == 2)
expect("Eingabe der Kette", saved.goals[1].params.input, "101 102")
expect("Frist als Eingabe", saved.goals[2].extras.deadline, "7200s")

-- Teilen und Importieren
local text = Packs.Export("Wolfstag")
expect("Text mit Kennung", text:sub(1, 9), "LT1:goals")
expect("kein |", text:find("|", 1, true), nil)
Packs.Delete("Wolfstag")
expect("Unsinn wird abgelehnt", select(2, Packs.Import("LT1:goals:quatsch")), L.SG_ERR_IMPORT)
local name = Packs.Import(text)
expect("Name aus dem Text", name, "Wolfstag")

for _, goal in ipairs(Goals.Active()) do Goals.Cancel(goal.id) end
streamGoal.PacksView.Apply("Wolfstag")
expect("importiertes Paket angelegt", #Goals.Active(), 2)
expect("Kette wieder da", Goals.Active()[1].params.quests[2], 102)
expect("Frist wieder da", Goals.Active()[2].deadline.seconds, 7200)

-- Löschen mit Rückfrage
streamGoal.PacksView.Render()
wow.click(L.SG_PACK_DELETE)
expect("fertige Pakete lassen sich nicht löschen", wow.popup, nil)
expectTrue("Löschen-Knopf", wow.click(L.SG_PACK_DELETE, true))
expect("Rückfrage", wow.popup.name, "STREAMGOAL_DELETE_PACK")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("gelöscht", StreamGoalDB.packs["Wolfstag"], nil)
