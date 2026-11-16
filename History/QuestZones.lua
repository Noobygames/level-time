-- Quests je Zone (LT-261): für einen Charakter je Quest-ID, ob er sie abgegeben hat ("erledigt") oder nur andere eigene
-- Charaktere ("offen"), mit Zone und den Namen dieser anderen Charaktere. Quelle: Journal questLog aller Charaktere
-- (inklusive Archiv; Zone = GetZoneText bei der Abgabe). Vollständig nur bezogen auf bisher gesehene Quests.
-- Für den eingeloggten Charakter zählt zusätzlich QuestLog.IsFlaggedCompleted (z.B. vor der Installation abgegeben).
-- Neu berechnet nur bei neuem Journal-Stand, anderer Charakterzahl oder anderem Charakter.
local _, ns = ...

local QuestZones = {}
ns.QuestZones = QuestZones

local cache, cachedFor

-- Quest-Eintrag des Ergebnisses; zone/name vom ersten Journal-Eintrag mit Wert
local function recordOf(records, byQuest, questID)
  local record = byQuest[questID]
  if not record then
    record = { questID = questID, done = false, others = {} }
    byQuest[questID] = record
    records[#records + 1] = record
  end
  return record
end

local function build(characterKey)
  local records, byQuest = {}, {}
  for _, entry in ipairs(ns.Journal.GetEntries(characterKey, "questLog")) do
    if type(entry.questID) == "number" then
      local record = recordOf(records, byQuest, entry.questID)
      record.done = true
      record.zone = record.zone or entry.zone
      record.name = record.name or entry.name
    end
  end
  for _, key in ipairs(ns.History.GetCharacterKeys()) do
    if key ~= characterKey then
      local displayName = ns.History.DisplayName(key)
      for _, entry in ipairs(ns.Journal.GetEntries(key, "questLog")) do
        if type(entry.questID) == "number" then
          local record = recordOf(records, byQuest, entry.questID)
          record.zone = record.zone or entry.zone
          record.name = record.name or entry.name
          if record.others[#record.others] ~= displayName then  -- Einträge eines Charakters kommen am Stück
            record.others[#record.others + 1] = displayName
          end
        end
      end
    end
  end
  local current = characterKey == ns.characterKey
  for _, record in ipairs(records) do
    if not record.done and current then record.done = ns.QuestLog.IsFlaggedCompleted(record.questID) end
    record.name = record.name or ns.QuestLog.Title(record.questID)
    record.othersText = table.concat(record.others, ", ")
  end
  return records
end

-- Alle bekannten Quests des Charakters (Liste, nicht verändern):
-- { questID, name, zone, done, others = { Anzeigename, ... }, othersText }
function QuestZones.GetRecords(characterKey)
  local key = table.concat({ ns.Journal.Revision("questLog"), #ns.History.GetCharacterKeys(), characterKey,
    tostring(ns.db and ns.db.streamerPrivacy) }, ":")
  if key ~= cachedFor then
    cache, cachedFor = build(characterKey), key
  end
  return cache
end
