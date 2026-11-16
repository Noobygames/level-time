-- Quest-Check beim Betreten einer Instanz auch in Classic Era (Daten aus ns.DungeonDB): Todesminen, Allianz, Level 20,
-- "Oh Brother. . ." (167) offen; ohne Client-Titel steht der englische Name aus der DungeonDB in der Zeile.
local L = addon.L
local Check = addon.InstanceQuestCheck

C_QuestLog.IsQuestFlaggedCompleted = function() return false end
wow.login({ level = 20 })
wow.fire("QUEST_LOG_UPDATE")

expectTrue("Era: verfügbar", Check.IsAvailable())
local found
for _, quest in ipairs(Check.Missing(36)) do
  if quest.questID == 167 then found = quest end
end
expectTrue("167 fehlt im Log", found ~= nil)
expect("Rückfall-Name", found and found.title, "Oh Brother. . .")

wow.state.instance = { name = "Die Todesminen", type = "party", mapID = 36 }
wow.fire("PLAYER_ENTERING_WORLD")
local line = wow.printed[#wow.printed] or ""
expectTrue("Chatzeile mit Kopf", line:find(string.format(L.INSTANCE_QUEST_CHECK_MISSING, #Check.Missing(36), ""), 1, true) ~= nil)
expectTrue("Chatzeile mit Quest", line:find("[20] Oh Brother. . .", 1, true) ~= nil)
