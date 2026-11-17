-- LT-349, WoW Forever: Wasserschild hat dort die Spell-ID 408510 (24398/52127 kennt der Client nicht). Der Standard
-- enthält sie, und der alte gespeicherte Standard wird beim Login nachgezogen.
local CollapsedBuffs = addon.CollapsedBuffs
local FOREVER_WATER_SHIELD = 408510

wow.state.spellNames[FOREVER_WATER_SHIELD] = "Wasserschild"
local bar = { expanded = false }
BuffFrame = CreateFrame("Frame", "BuffFrame", UIParent)
BuffFrame.IsExpanded = function() return bar.expanded end
wow.state.buffs = {
  { name = "Wasserschild", spellId = FOREVER_WATER_SHIELD, icon = 132315, applications = 3, duration = 600,
    expirationTime = GetTime() + 540 },
}
LevelTimerDB = { collapsedBuffsList = "324, 24398, 52127, 974" }  -- alter Standard aus einer früheren Version
wow.login()
expect("alter Standard nachgezogen", LevelTimerDB.collapsedBuffsList, "324, 24398, 408510, 52127, 974")
wow.advance(1)
wow.update(1)
expect("Wasserschild eingeklappt sichtbar", CollapsedBuffs.ShownCount(), 1)
expect("Stapel", (CollapsedBuffs.IconTexts(1)), "3")
expect("keine Fehler", #wow.errors, 0)
