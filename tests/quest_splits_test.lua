-- Quest-Splits: Dauer von der Annahme bis zur Abgabe, Bestzeit je Quest-ID, Abweichung im Journal.
local QuestSplits = addon.QuestSplits

wow.login({ name = "Neu", level = 5, playedSeconds = 0 })
wow.fire("TIME_PLAYED_MSG", 1000, 0)

-- Retail/Forever: QUEST_ACCEPTED(questID)
wow.fire("QUEST_ACCEPTED", 42)
wow.advance(300)
wow.fire("QUEST_TURNED_IN", 42, 100, 0)
local entry = addon.character.questLog[#addon.character.questLog]
expect("Dauer", entry.duration, 300)
expect("erste Abgabe ohne Abweichung", entry.delta, nil)
expect("Bestzeit", QuestSplits.GetBest(42), 300)
expect("Level im Eintrag", entry.level, 5)
expect("XP im Eintrag", entry.xp, 100)

-- Classic: QUEST_ACCEPTED(questIndex, questID), schneller
addon.Set("questSplitNotice", true)
wow.fire("QUEST_ACCEPTED", 3, 42)
wow.advance(200)
wow.fire("QUEST_TURNED_IN", 42, 100, 0)
entry = addon.character.questLog[#addon.character.questLog]
expect("Classic-Signatur", entry.duration, 200)
expect("Abweichung zur alten Bestzeit", entry.delta, -100)
expect("neue Bestzeit", QuestSplits.GetBest(42), 200)
expectTrue("Chatzeile", wow.printed[#wow.printed]:find(addon.Format.SplitDelta(-100), 1, true) ~= nil)

-- Ohne Annahme (vor der Installation angenommen): keine Dauer
wow.fire("QUEST_TURNED_IN", 7, 50, 0)
expect("ohne Annahme keine Dauer", addon.character.questLog[#addon.character.questLog].duration, nil)
expect("nur Quests mit Dauer", #QuestSplits.GetRecords(addon.characterKey), 2)

-- Kompakte Form im Archiv behält die neuen Felder
local Journal = addon.Journal
local fields = Journal.LOGS.questLog.fields
expect("Felder hinten angehängt", fields[#fields - 1].path .. "," .. fields[#fields].path, "duration,delta")
