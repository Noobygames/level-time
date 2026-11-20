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

-- LT-409: Upgrade-Knopf im Hinweisfenster legt den höchsten Rang auf den Platz, nicht im Kampf
-- Knopf der Standardleiste für Platz 2: Überfahren des Upgrade-Knopfs hebt ihn hervor
local barButton = CreateFrame("Button", "ActionButton2", UIParent)
barButton.action = 2
_G.ActionButton2 = barButton
local rows = addon.Hints.Rows and addon.Hints.Rows() or {}
local upgrade
for _, row in ipairs(rows) do
  local detail = rawget(row, "detail")  -- Stub-Frames liefern für fehlende Felder Funktionen
  if row:IsShown() and type(detail) == "table" and detail.action then upgrade = row end
end
expectTrue("Upgrade-Knopf an der Zauberzeile", upgrade ~= nil and upgrade.action:IsShown())
expect("Upgrade-Tooltip", upgrade.detail.action.tip, L.OLD_RANKS_UPGRADE_TIP)
upgrade.action._scripts.OnEnter(upgrade.action)
expect("Überfahren: Platz 2 hervorgehoben", addon.ActionBars.HighlightedSlot(), 2)
upgrade.action._scripts.OnLeave(upgrade.action)
expect("Verlassen: keine Hervorhebung", addon.ActionBars.HighlightedSlot(), nil)
wow.state.combatLockdown = true
upgrade.action._scripts.OnClick(upgrade.action)
expect("im Kampf: Platz unverändert", wow.state.actions[2][2], FROSTBOLT_1)
expectTrue("im Kampf: Hinweis im Chat", wow.printed[#wow.printed]:find(L.OLD_RANKS_UPGRADE_COMBAT, 1, true) ~= nil)
wow.state.combatLockdown = false
upgrade.action._scripts.OnClick(upgrade.action)
expect("Upgrade: höchster Rang auf Platz 2", wow.state.actions[2][2], FROSTBOLT_2)
expect("Upgrade: Platz 1 unberührt", wow.state.actions[1][2], FROSTBOLT_2)
expect("Mauszeiger leer", wow.state.cursorSpell, nil)
expect("Upgrade: Zeile weg, nicht ausgeblendet", addon.OldSpellRanks.IgnoredCount(), 0)
expect("keine Fehler", #wow.errors, 0)

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
