-- Alte Zauberränge auf der Aktionsleiste (WoW Forever): C_SpellBook.IsSpellBookItemLowRank.
local L = addon.L
local OldSpellRanks = addon.OldSpellRanks

local FROSTBOLT_1, FROSTBOLT_2 = 116, 205
wow.state.spellNames[FROSTBOLT_1] = "Frostblitz"
wow.state.spellNames[FROSTBOLT_2] = "Frostblitz"
wow.state.spellBook = { { FROSTBOLT_1, true }, { FROSTBOLT_2 } }
wow.state.actions = { [1] = { "spell", FROSTBOLT_2 } }

local function hints()
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find(string.format(L.WARN_OLD_SPELL_RANKS, "Frostblitz"), 1, true) then found = found + 1 end
  end
  return found
end

expectTrue("Forever: verfügbar", OldSpellRanks.IsAvailable())
wow.login({ level = 20 })
wow.update(OldSpellRanks.SCAN_INTERVAL + 1)
expect("höchster Rang: still", hints(), 0)

-- Nach dem Lernen liegt der alte Rang auf Platz 2
wow.state.actions[2] = { "spell", FROSTBOLT_1 }
wow.fire("SPELLS_CHANGED")
wow.update(OldSpellRanks.SCAN_INTERVAL + 1)
expect("alter Rang: Hinweis", hints(), 1)

-- Einstellung aus: kein Durchgang
addon.Set("warnOldSpellRanks", false)
wow.state.spellNames[133] = "Feuerball"
wow.state.spellBook[3] = { 133, true }
wow.state.actions[3] = { "spell", 133 }
wow.fire("SPELLS_CHANGED")
wow.update(OldSpellRanks.SCAN_INTERVAL + 1)
local feuerball = 0
for _, line in ipairs(wow.printed) do
  if line:find("Feuerball", 1, true) then feuerball = feuerball + 1 end
end
expect("aus: still", feuerball, 0)
