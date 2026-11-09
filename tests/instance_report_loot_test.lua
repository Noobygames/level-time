-- Beute im Instanz-Bericht (Roadmap 441): Zeilen je gewonnenem Wurf des Laufs, Qualitätsfilter, Höchstzahl mit "+N",
-- nur ein Lauf, alle gepasst fehlt, aus = nur die Zusammenfassung, eine Zeile je Sekunde, Boss-Präfix.
local L = addon.L
local Journal, LootRolls, InstanceReport = addon.Journal, addon.LootRolls, addon.InstanceReport

local function link(id, quality, name)
  return string.format("|cnIQ%d:|Hitem:%d::::::::70:::::|h[%s]|h|r", quality, id, name)
end
local function enter(name)
  wow.state.instance = name and { name = name, type = "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end
local function sent() return wow.sentChat end
local function roll(id, quality, winner, extra)
  local entry = { link = link(id, quality, "Item" .. id), quality = quality, winner = winner, winnerRoll = 80 + id % 10,
    winnerChoice = "need", runStart = addon.Instances.GetCurrentRun().startedAt }
  for key, value in pairs(extra or {}) do entry[key] = value end
  Journal.AddRoll(entry)
end

wow.sentChat = {}
wow.state.clock = os.time({ year = 2026, month = 10, day = 2, hour = 12 })
wow.login({ level = 20, xp = 0, xpMax = 10000, money = 0 })
wow.state.inGroup = true
addon.Set("announceInstanceReport", true)

-- Aus: nur die Zusammenfassung
enter("Die Todesminen")
wow.advance(120)
roll(1, 4, "Grimbar")
enter(nil)
expect("aus: eine Zeile", #sent(), 1)
wow.update(5)
expect("aus: keine Beute", #sent(), 1)
wow.sentChat = {}
expect("Standard aus", addon.db.instanceReportLoot, false)
expect("Standard Qualität", addon.db.instanceReportLootQuality, 3)
expect("Standard Höchstzahl", addon.db.instanceReportLootMax, 5)

-- An: Zeilen mit Link, Gewinner, Wahl und Wurf; Boss-Präfix; Filter; fremder Lauf; alle gepasst
addon.Set("instanceReportLoot", true)
addon.Set("instanceReportLootMax", 2)
enter("Burg Schattenfang")
wow.advance(120)
roll(10, 4, "Grimbar", { encounter = "Arugal" })
roll(11, 2, "Lyra")                                  -- zu niedrige Qualität
roll(12, 3, "Lyra", { winnerChoice = "greed", winnerRoll = 12 })
roll(13, 3, nil, { allPassed = 1 })                  -- alle gepasst
roll(14, 4, "Testchar", { runStart = 1 })            -- anderer Lauf
roll(15, 4, "Grimbar")                               -- über der Höchstzahl
roll(16, 3, "Grimbar")
enter(nil)
expect("Zusammenfassung sofort", #sent(), 1)
wow.update(1)
expect("nach 1 s: erste Beute", #sent(), 2)
expect("Boss, Link, Gewinner, Wahl, Wurf", sent()[2].message,
  "Level Time: " .. string.format(L.INSTANCE_REPORT_LOOT_BOSS, "Arugal",
    link(10, 4, "Item10") .. " - Grimbar (" .. L.LOOT_ROLL_KIND_NEED .. " 80)"))
expect("Gruppenchat", sent()[2].chatType, "PARTY")
wow.update(0.5)
expect("noch keine zweite", #sent(), 2)
wow.update(0.5)
expect("nach 2 s: zweite", #sent(), 3)
expect("ohne Boss", sent()[3].message,
  "Level Time: " .. link(12, 3, "Item12") .. " - Lyra (" .. L.LOOT_ROLL_KIND_GREED .. " 12)")
wow.update(1)
expect("nach 3 s: Rest", #sent(), 4)
expect("+N weitere", sent()[4].message, "Level Time: " .. string.format(L.INSTANCE_REPORT_LOOT_MORE, 2))
wow.update(5)
expect("danach nichts", #sent(), 4)

-- Gesperrter Chat hält die Zeilen zurück (von Hand gesendet), Epic-Filter
wow.sentChat = {}
addon.Set("instanceReportLootQuality", 4)
addon.Set("instanceReportLootMax", 5)
wow.fire("CHAT_MSG_SYSTEM", string.format(INSTANCE_RESET_SUCCESS, "Burg Schattenfang"))
enter("Burg Schattenfang")
wow.advance(10)
roll(20, 4, "Grimbar")
roll(21, 3, "Grimbar")
SlashCmdList.LEVELTIMER("report")
expect("von Hand: Zusammenfassung", #sent(), 1)
wow.state.chatLockdown = true
wow.update(3)
expect("gesperrt: nichts", #sent(), 1)
wow.state.chatLockdown = false
wow.update(1)
expect("frei: Beute", #sent(), 2)
expectTrue("nur Epic", sent()[2].message:find("Item20", 1, true) ~= nil)
wow.update(3)
expect("Rare gefiltert", #sent(), 2)
expect("keine Fehler", #wow.errors, 0)
