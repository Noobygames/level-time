-- Alte Zauberränge auf der Aktionsleiste (Classic Era): Rang aus dem Untertext, höchster Rang aus dem Zauberbuch.
local L = addon.L
local OldSpellRanks = addon.OldSpellRanks

local FROSTBOLT_1, FROSTBOLT_2, FIREBALL_1 = 116, 205, 133
wow.state.spellNames[FROSTBOLT_1] = "Frostblitz"
wow.state.spellNames[FROSTBOLT_2] = "Frostblitz"
wow.state.spellNames[FIREBALL_1] = "Feuerball"
wow.state.spellSubtexts[FROSTBOLT_1] = "Rang 1"
wow.state.spellSubtexts[FROSTBOLT_2] = "Rang 2"
wow.state.spellSubtexts[FIREBALL_1] = "Rang 1"
-- CVar ShowAllSpellRanks aus: im Zauberbuch steht nur der höchste Rang
wow.state.spellBook = { { FROSTBOLT_2 }, { FIREBALL_1 } }
wow.state.actions = {
  [1] = { "spell", FROSTBOLT_1 },
  [2] = { "spell", FIREBALL_1 },
  [3] = { "macro", 1 },
  [4] = { "item", FROSTBOLT_1 },
  [5] = { "spell", FROSTBOLT_1 },  -- zweimal derselbe alte Rang: einmal genannt
}

local function hints()
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find(string.format(L.WARN_OLD_SPELL_RANKS, "Frostblitz"), 1, true) then found = found + 1 end
  end
  return found
end

expectTrue("Era: verfügbar", OldSpellRanks.IsAvailable())
wow.login({ level = 20 })
expect("Standard an nach Login", addon.db.warnOldSpellRanks, true)
expect("nur Frostblitz, einmal", table.concat(OldSpellRanks.Find(), ","), "Frostblitz")

wow.update(OldSpellRanks.SCAN_INTERVAL + 1)
expect("Hinweis beim Login", hints(), 1)
expect("Karte: Titel", LevelTimerNotice.title:GetText(), L.NOTICE_OLD_SPELL_RANKS)

wow.fire("SPELLS_CHANGED")
wow.update(OldSpellRanks.SCAN_INTERVAL + 1)
expect("je Sitzung nur einmal", hints(), 1)

-- Neuer Rang ersetzt: nichts mehr alt
wow.state.actions[1] = { "spell", FROSTBOLT_2 }
wow.state.actions[5] = nil
expect("ersetzt: nichts", #OldSpellRanks.Find(), 0)

-- Retail kennt keine Ränge
wow.state.interface = 120105
expect("Retail: nicht verfügbar", OldSpellRanks.IsAvailable(), false)
