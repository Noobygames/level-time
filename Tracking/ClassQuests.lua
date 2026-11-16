-- Klassenquests (von Hand gepflegt, Stand 2026-11-14): ab welchem Level eine Klassenquest wartet und was sie bringt
-- (Fähigkeiten als Spell-IDs, Belohnungen als Item-IDs für Chat-Links). Nur Classic Era und WoW Forever; Retail und
-- TBC haben andere Klassenquests. Quelle: warcraft.wiki.gg (Druid_quests, Shaman_quests, Warlock_quests,
-- Warrior_quests, Paladin_quests, Hunter_quests, Rogue_quests), IDs per wowhead classic; siehe sources.md.
-- Magier und Priester fehlen (keine Klassenquest mit eigener Fähigkeit); Forever ist nicht eigens geprüft.
-- Anzeige: Level-Up-Fenster (Hinweiszeile), sonst Chatzeile und ohne Fenster eine Einblendung (Einstellung
-- remindClassQuest).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    remindClassQuest = true,
  },
})
local L = ns.L

-- [Klasse][Level] = { spells = { Spell-ID, ... }, items = { Item-ID, ... } }
local QUESTS = {
  DRUID = {
    [10] = { spells = { 5487 } },        -- Bärengestalt
    [16] = { spells = { 1066 } },        -- Wassergestalt
  },
  HUNTER = {
    [10] = { spells = { 1515 } },        -- Wildtier zähmen
  },
  PALADIN = {
    [12] = { spells = { 7328 } },        -- Erlösung
    [60] = { spells = { 23214 } },       -- Streitross beschwören
  },
  ROGUE = {
    [20] = { spells = { 2842 } },        -- Gifte
  },
  SHAMAN = {
    [4] = { items = { 5175 } },          -- Erdtotem
    [10] = { items = { 5176 } },         -- Feuertotem
    [20] = { items = { 5177 } },         -- Wassertotem
    [30] = { items = { 5178 } },         -- Lufttotem
  },
  WARLOCK = {
    [10] = { spells = { 697 } },         -- Leerwandler
    [20] = { spells = { 712 } },         -- Sukkubus
    [30] = { spells = { 691 } },         -- Teufelsjäger
    [40] = { spells = { 5784 } },        -- Teufelsross
    [60] = { spells = { 23161 } },       -- Schreckensross
  },
  WARRIOR = {
    [10] = { spells = { 71 } },          -- Verteidigungshaltung
    [30] = { spells = { 2458 } },        -- Berserkerhaltung (Questreihe beginnt mit 30)
    [40] = { items = { 6975, 6976, 6977 } },  -- Wirbelwindaxt, -hammer, -schwert (Wahl)
  },
}

local ClassQuests = {}
ns.ClassQuests = ClassQuests

function ClassQuests.IsAvailable()
  return ns.Client.IsClassicEra() or ns.Client.IsForever()
end

-- Eintrag für genau dieses Level (nil ohne Klassenquest)
function ClassQuests.ForLevel(level)
  if not ClassQuests.IsAvailable() then return nil end
  local byLevel = QUESTS[(select(2, UnitClass("player")))]
  return byLevel and byLevel[level]
end

local function spellText(spellID)
  local getLink = (C_Spell and C_Spell.GetSpellLink) or GetSpellLink
  local getName = (C_Spell and C_Spell.GetSpellName) or GetSpellInfo
  return (getLink and getLink(spellID)) or (getName and getName(spellID)) or ("#" .. spellID)
end

-- Unbekanntes Item (noch nicht im Cache): Link nur mit der ID, der Tooltip lädt es beim Draufzeigen
local function itemText(itemID)
  return ns.Items.GetLink(itemID) or string.format("|cffffffff|Hitem:%d|h[%d]|h|r", itemID, itemID)
end

-- "Klassenquest ab Level 10: [Bärengestalt]"; nil ohne Klassenquest
function ClassQuests.Text(level)
  local entry = ClassQuests.ForLevel(level)
  if not entry then return nil end
  local parts = {}
  for _, spellID in ipairs(entry.spells or {}) do table.insert(parts, spellText(spellID)) end
  for _, itemID in ipairs(entry.items or {}) do table.insert(parts, itemText(itemID)) end
  return string.format(L.CLASS_QUEST_HINT, level, table.concat(parts, ", "))
end

-- Chatzeile (klickbare Links) und ohne Level-Up-Fenster zusätzlich eine Einblendung
local function remind(level)
  local text = ClassQuests.Text(level)
  if not text then return end
  ns.Debug("classquest", "hint for level %s", level)
  ns.Print(text)
  if not ns.db.levelUpWindow then
    ns.Alerts.Notify({ title = L.NOTICE_CLASS_QUEST, text = text, icon = ns.Alerts.ICONS.trainer },
      ns.Alerts.REMINDER_COLOR)
  end
end

ns.OnLevelStarted(function(newLevel)
  if ns.db.remindClassQuest then remind(newLevel) end
end)
