-- Quest-Level vor Questnamen (Roadmap 259, Einstellung questLevels, Standard aus): "[12] Titel", "[12+] Titel" für
-- Gruppenquests (suggestedGroup > 0) in Questlog, Gesprächs- und Grußlisten und (Classic) im Quest-Tracker.
-- Die Hooks auf Blizzards Listen (Rahmen je Client) liegen in Lib/QuestListHooks.lua; hier nur der Text.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questLevels = false,
  },
})

local QuestLevels = {}
ns.QuestLevels = QuestLevels

local PREFIX_PATTERN = "^%[%d+%+?%] "  -- schon ergänzt (Blizzard hat den Text nicht neu gesetzt)

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- "[12] " bzw. "[12+] "; nil ohne lesbares Level
function QuestLevels.Tag(level, group)
  level = readable(level)
  if type(level) ~= "number" or level <= 0 then return nil end
  return string.format("[%d%s] ", level, group and "+" or "")
end

-- Fügt das Level nach führenden Leerzeichen ein (Blizzards Questlog rückt mit "  " ein), nur einmal
function QuestLevels.Prefix(text, level, group)
  local tag = QuestLevels.Tag(level, group)
  text = readable(text)
  if not tag or type(text) ~= "string" then return nil end
  local indent, rest = text:match("^(%s*)(.*)$")
  if rest:find(PREFIX_PATTERN) then return nil end
  return indent .. tag .. rest
end

ns.QuestListHooks.Register({
  enabled = function(db) return db.questLevels end,
  decorate = function(text, quest) return QuestLevels.Prefix(text, quest.level, quest.group) end,
})
