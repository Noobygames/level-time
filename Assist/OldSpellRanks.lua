-- Hinweis, wenn auf der Aktionsleiste noch ein alter Zauberrang liegt (Einstellung warnOldSpellRanks, Reiter
-- Chat & Erinnerungen > Erinnerungen). Nach dem Lernen (SPELLS_CHANGED, in allen Clients laut
-- SpellBookDocumentation) und beim Login prüft ein Durchgang alle Aktionsplätze (GetActionInfo, nur Art "spell";
-- Makros und Gegenstände zählen nicht) und nennt jeden Zauber einmal je Sitzung. Kein automatisches Ersetzen.
-- Erkennung je Client:
--   WoW Forever: C_SpellBook.IsSpellBookItemLowRank(slot, bank) (nur Forever, SpellBookDocumentation.lua). Niedrige
--     Ränge sind eigene Einträge im Zauberbuch (Blizzard_SpellBookFrame.lua blendet sie nur per Filter aus).
--   Classic Era/TBC: Rangzahl aus dem Untertext ("Rang 3", Widgets.SpellRank). Höchster Rang je Name aus dem
--     Zauberbuch (GetSpellTabInfo, GetSpellBookItemName wie Vanilla/SpellBookFrame.lua); niedrige Ränge stehen dort
--     nur mit CVar ShowAllSpellRanks, der höchste immer. Der Knopf ist alt, wenn sein Rang darunter liegt.
-- Upgrade (LT-409, Knopf je Zauber im Hinweisfenster): legt den höchsten Rang aus dem Zauberbuch auf jeden Platz mit
-- dem alten Rang (PickupSpell, PlaceAction, ClearCursor; nicht im Kampf, dort sperrt der Client Aktionsleisten).
-- Retail kennt keine Ränge: nicht verfügbar, keine Einstellung.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    warnOldSpellRanks = true,
  },
})
local L = ns.L

local OldSpellRanks = {}
ns.OldSpellRanks = OldSpellRanks

-- Aktionsplätze 1-180 (Classic 1-120 mit Haltungsleisten, neuere Clients mehr Leisten); leere Plätze liefern nil
OldSpellRanks.MAX_ACTION_SLOT = 180
-- SPELLS_CHANGED feuert beim Lernen mehrfach: gesammelt höchstens ein Durchgang je Intervall
OldSpellRanks.SCAN_INTERVAL = 2
local BOOKTYPE_SPELL = "spell"

local dirty = false
local notified = {}  -- Zaubername -> true: in dieser Sitzung schon gemeldet

local function hasLowRankApi()
  return C_SpellBook ~= nil and C_SpellBook.IsSpellBookItemLowRank ~= nil
end

local function hasLegacySpellBook()
  return GetNumSpellTabs ~= nil and GetSpellTabInfo ~= nil and GetSpellBookItemName ~= nil
end

function OldSpellRanks.IsAvailable()
  return not ns.Client.IsRetail() and (hasLowRankApi() or hasLegacySpellBook())
end

local function rankOf(spellID)
  return tonumber((ns.Widgets.SpellRank(spellID)))
end

-- Prüffunktionen: spellID -> Rang im Zauberbuch (der höchste dieses Namens), wenn der Knopf einen niedrigeren hat,
-- sonst nil; false statt Zahl, wo der Rang nicht lesbar ist. Zweiter Wert: Spell-ID des höchsten Rangs (Upgrade-Ziel)
-- WoW Forever: Spell-IDs aller niedrigen Ränge im Zauberbuch, höchster Rang je Name aus allen Einträgen
local function foreverLowRankCheck()
  local bank = Enum.SpellBookSpellBank.Player
  local low, highest, best = {}, {}, {}  -- best: Name -> Spell-ID des Eintrags, der kein niedriger Rang ist
  for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
    if info then
      for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
        local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
        if item and item.spellID then
          local name, rank = C_Spell.GetSpellName(item.spellID), rankOf(item.spellID)
          if C_SpellBook.IsSpellBookItemLowRank(slot, bank) then
            low[item.spellID] = true
          elseif name then
            best[name] = item.spellID
          end
          if name and rank and rank > (highest[name] or 0) then highest[name] = rank end
        end
      end
    end
  end
  return function(spellID)
    if not low[spellID] then return nil end
    local name = C_Spell.GetSpellName(spellID)
    return highest[name] or false, best[name]
  end
end

-- Classic Era/TBC: höchster bekannter Rang je Name, verglichen mit dem Rang des Knopfs
local function legacyLowRankCheck()
  local highest, best = {}, {}  -- best: Name -> Spell-ID des höchsten Rangs
  for tab = 1, GetNumSpellTabs() do
    local _, _, offset, numSlots = GetSpellTabInfo(tab)
    for slot = offset + 1, offset + numSlots do
      local name, _, spellID = GetSpellBookItemName(slot, BOOKTYPE_SPELL)
      local rank = spellID and rankOf(spellID)
      if name and rank and rank > (highest[name] or 0) then highest[name], best[name] = rank, spellID end
    end
  end
  return function(spellID)
    local name, rank = C_Spell.GetSpellName(spellID), rankOf(spellID)
    if name ~= nil and rank ~= nil and rank < (highest[name] or 0) then return highest[name], best[name] end
  end
end

-- Dauerhaft ausgeblendete Ränge (ns.db.ignoredSpellRanks[spellID] = true, genau dieser Rang), Tabelle erst bei Bedarf
local function ignoredRanks() return ns.db.ignoredSpellRanks end

function OldSpellRanks.IgnoredCount()
  local count = 0
  for _ in pairs(ignoredRanks() or {}) do count = count + 1 end
  return count
end

function OldSpellRanks.Ignore(spellID)
  ns.db.ignoredSpellRanks = ns.db.ignoredSpellRanks or {}
  ns.db.ignoredSpellRanks[spellID] = true
  ns.ApplySettings()  -- Beschriftung des Optionsknopfs
end

function OldSpellRanks.ClearIgnored()
  ns.db.ignoredSpellRanks = nil
  ns.ApplySettings()
end

-- Zauber, die als niedriger Rang auf einem Aktionsplatz liegen (je Name einmal, ohne ausgeblendete Ränge):
-- { { spellID, name, barRank, bookRank, upgradeID, slots = { Platz, ... } }, ... }; ein Rang ist nil, wo er nicht
-- lesbar ist, upgradeID nil, wo der höchste Rang im Zauberbuch fehlt
function OldSpellRanks.Find()
  local bookRankOf = hasLowRankApi() and foreverLowRankCheck() or legacyLowRankCheck()
  local found, byName = {}, {}
  for slot = 1, OldSpellRanks.MAX_ACTION_SLOT do
    local actionType, id = GetActionInfo(slot)
    if not ns.IsSecret(actionType) and actionType == "spell" and not ns.IsSecret(id) and type(id) == "number"
        and not (ignoredRanks() and ignoredRanks()[id]) and bookRankOf(id) ~= nil then
      local name = C_Spell.GetSpellName(id)
      if name and not byName[name] then
        local bookRank, upgradeID = bookRankOf(id)
        byName[name] = { spellID = id, name = name, barRank = rankOf(id), bookRank = bookRank or nil,
          upgradeID = upgradeID, slots = {} }
        table.insert(found, byName[name])
      end
      if name then table.insert(byName[name].slots, slot) end
    end
  end
  return found
end

-- Höchsten Rang auf alle Plätze von spell (Eintrag aus Find) legen; false im Kampf oder ohne Upgrade-Ziel. Ein Platz,
-- auf dem inzwischen etwas anderes liegt, bleibt unberührt.
function OldSpellRanks.Upgrade(spell)
  if InCombatLockdown() then
    ns.Print(L.OLD_RANKS_UPGRADE_COMBAT)
    return false
  end
  if not spell.upgradeID then return false end
  local placed = 0
  for _, slot in ipairs(spell.slots) do
    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" and id == spell.spellID then
      PickupSpell(spell.upgradeID)
      PlaceAction(slot)
      ClearCursor()  -- der alte Rang landet beim Tauschen auf dem Mauszeiger
      placed = placed + 1
    end
  end
  ns.Debug("spellranks", "upgrade %s to %s on %s slots", spell.spellID, spell.upgradeID, placed)
  return true
end

local function rankText(rank)
  return rank and tostring(rank) or "?"
end

function OldSpellRanks.Check()
  dirty = false
  local fresh = {}
  for _, spell in ipairs(OldSpellRanks.Find()) do
    if not notified[spell.name] then
      notified[spell.name] = true
      table.insert(fresh, spell)
    end
  end
  ns.Debug("spellranks", "old ranks on action bars, new: %s", #fresh)
  if #fresh == 0 then return end
  local names, rows = {}, {}
  for _, spell in ipairs(fresh) do
    table.insert(names, spell.name)
    table.insert(rows, { spellID = spell.spellID, name = spell.name,
      columns = { rankText(spell.barRank), rankText(spell.bookRank) },
      onDismiss = function() OldSpellRanks.Ignore(spell.spellID) end,
      action = spell.upgradeID and { tip = L.OLD_RANKS_UPGRADE_TIP, run = function() return OldSpellRanks.Upgrade(spell) end } })
  end
  ns.Alerts.Notify({ title = L.NOTICE_OLD_SPELL_RANKS,
    text = string.format(L.WARN_OLD_SPELL_RANKS, table.concat(names, ", ")),
    icon = ns.Alerts.ICONS.trainer, rows = rows,
    header = { L.OLD_RANKS_COL_SPELL, L.OLD_RANKS_COL_BAR, L.OLD_RANKS_COL_BOOK } },
    ns.Alerts.REMINDER_COLOR, ns.Alerts.COLLECT)
end

ns.RegisterEvent("SPELLS_CHANGED", function() dirty = true end)
ns.OnLogin(function() dirty = true end)
ns.Every(OldSpellRanks.SCAN_INTERVAL, function()
  if dirty then OldSpellRanks.Check() end
end, function(db) return db.warnOldSpellRanks and OldSpellRanks.IsAvailable() end)
