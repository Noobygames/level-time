-- Schlüssel- und Einstimmungsreihen (LT-254, Classic Era): Skelettschlüssel für Scholomance je Fraktion aus den von
-- Hand ergänzten Quests der Dungeon-DB, ohne Forever-Hinweis; Geber-Ort aus gelernten Daten.
local L = addon.L
local Attunements = addon.Attunements

-- Vorquests der Argentumdämmerung (5066, 5092, 5097) vor dem Schlüsselauftrag 5533 erledigt
local completed = { [5066] = true, [5092] = true, [5097] = true, [5533] = true }
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
C_Map = C_Map or {}
C_Map.GetMapInfo = function(uiMapID) return { name = "Karte " .. uiMapID } end
GetRealZoneText = function(mapID) return "Instanz " .. tostring(mapID) end
wow.login({ level = 56 })

local function ids(steps)
  local list = {}
  for _, step in ipairs(steps) do table.insert(list, step.questID) end
  return table.concat(list, ",")
end

local scholo = Attunements.At(289)[1]
expect("Allianz: Schritte", ids(scholo.steps), "5066,5092,5097,5533,5537,5538,5801,5803")
expect("Allianz: erledigt", scholo.done, 4)

-- Gelernter Geber-Ort, wenn die Dungeon-DB keinen kennt
addon.QuestNpcs.Get = function(questID)
  if questID == 5537 then return { giver = { name = "Arbington", mapID = 1422, x = 0.427, y = 0.84 } } end
  return nil
end
GameTooltip:SetOwner(UIParent)
Attunements.AddLines(GameTooltip, 289)
expect("Kopf ohne Sternchen", GameTooltip._lines[1], string.format(L.ATTUNEMENT_KEY_TITLE, "Instanz 289", 4, 8))
expectTrue("nächster Schritt mit gelerntem Ort", GameTooltip._lines[2]:find("Karte 1422 (43, 84)", 1, true) ~= nil)
expect("Araj ab Level 55 offen", GameTooltip._lines[5]:sub(-#L.ATTUNEMENT_OPEN), L.ATTUNEMENT_OPEN)
expectTrue("kein Forever-Hinweis", GameTooltip._lines[#GameTooltip._lines] ~= L.FOREVER_UNVERIFIED)

wow.state.faction = "Horde"
expect("Horde: Schritte", ids(Attunements.At(289)[1].steps), "5093,5096,5098,838,964,5514,5802,5804")
