-- Beute im Instanz-Bericht (Roadmap 441): kurz je Gewinner in derselben Nachricht wie der Bericht, Qualitätsfilter,
-- Höchstzahl mit "+N", nur ein Lauf, alle gepasst fehlt, aus = nur die Zusammenfassung, Überlauf in Folgenachrichten
-- (höchstens 255 Bytes samt Präfix, eine je Sekunde).
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

-- An: eine Nachricht, Gewinner ohne Realm mit ihren Gegenständen; Filter; fremder Lauf; alle gepasst; "+N"
addon.Set("instanceReportLoot", true)
addon.Set("instanceReportLootMax", 3)
enter("Burg Schattenfang")
wow.advance(120)
roll(10, 4, "Grimbar-Aegwynn", { encounter = "Arugal" })
roll(11, 2, "Lyra")                                  -- zu niedrige Qualität
roll(12, 3, "Lyra", { winnerChoice = "greed", winnerRoll = 12 })
roll(13, 3, nil, { allPassed = 1 })                  -- alle gepasst
roll(14, 4, "Testchar", { runStart = 1 })            -- anderer Lauf
roll(15, 4, "Grimbar-Aegwynn")
roll(16, 3, "Grimbar")                               -- über der Höchstzahl
enter(nil)
expect("eine Nachricht", #sent(), 1)
local message = sent()[1].message
local loot = string.format(L.INSTANCE_REPORT_LOOT, "Grimbar " .. link(10, 4, "Item10") .. " " .. link(15, 4, "Item15")
  .. ", Lyra " .. link(12, 3, "Item12") .. ", " .. string.format(L.INSTANCE_REPORT_LOOT_MORE, 1))
expectTrue("Bericht vorne", message:find("^Level Time: Burg Schattenfang: ") ~= nil)
expectTrue("Beute angehängt", message:sub(-#loot) == loot)
expectTrue("unter 255 Bytes", #message <= 255)
expect("Gruppenchat", sent()[1].chatType, "PARTY")
wow.update(5)
expect("danach nichts", #sent(), 1)

-- Zu viel für eine Nachricht: Folgenachrichten "Beute: ...", eine je Sekunde, jede höchstens 255 Bytes
wow.sentChat = {}
addon.Set("instanceReportLootMax", 10)
wow.fire("CHAT_MSG_SYSTEM", string.format(INSTANCE_RESET_SUCCESS, "Burg Schattenfang"))
enter("Burg Schattenfang")
wow.advance(120)
for id = 30, 39 do roll(id, 4, "Spieler" .. id) end
enter(nil)
expect("erste Nachricht sofort", #sent(), 1)
wow.update(1)
expect("nach 1 s: Folgenachricht", #sent(), 2)
wow.update(5)
local total = ""
for _, entry in ipairs(sent()) do
  expectTrue("höchstens 255 Bytes", #entry.message <= 255)
  total = total .. entry.message
end
expectTrue("Folgenachricht beginnt mit Beute", sent()[2].message:find("Level Time: "
  .. string.format(L.INSTANCE_REPORT_LOOT, ""), 1, true) == 1)
for id = 30, 39 do expectTrue("Gegenstand " .. id .. " dabei", total:find("Item" .. id, 1, true) ~= nil) end

-- Von Hand (/lt report) mit Epic-Filter: Beute in derselben Nachricht
wow.sentChat = {}
addon.Set("instanceReportLootQuality", 4)
addon.Set("instanceReportLootMax", 5)
wow.fire("CHAT_MSG_SYSTEM", string.format(INSTANCE_RESET_SUCCESS, "Burg Schattenfang"))
enter("Burg Schattenfang")
wow.advance(10)
roll(20, 4, "Grimbar")
roll(21, 3, "Grimbar")
SlashCmdList.LEVELTIMER("report")
expect("von Hand: eine Nachricht", #sent(), 1)
expectTrue("Epic dabei", sent()[1].message:find("Item20", 1, true) ~= nil)
expect("Rare gefiltert", sent()[1].message:find("Item21", 1, true), nil)

-- Gesperrter Chat hält Folgenachrichten zurück
wow.sentChat = {}
for id = 40, 49 do roll(id, 4, "Spieler" .. id) end
SlashCmdList.LEVELTIMER("report")
expect("erste sofort", #sent(), 1)
wow.state.chatLockdown = true
wow.update(3)
expect("gesperrt: keine Folgenachricht", #sent(), 1)
wow.state.chatLockdown = false
wow.update(1)
expect("frei: Folgenachricht", #sent(), 2)
expect("keine Fehler", #wow.errors, 0)
