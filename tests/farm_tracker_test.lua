-- Roadmap 324: Farm-Tracker. Beutewert je Bereich (Auctionator-Preis, sonst Händlerpreis), Gold/h inkl. Beute,
-- Spalte Beutewert in der Historie und Teil der Voreinstellung "Farmen".
local Stats = addon.Stats
local Format = addon.Format
local L = addon.L

local function link(name)
  return "|cffffffff|Hitem:1234::::::::20:::::|h[" .. name .. "]|h|r"
end
local CLOTH = link("Leinenstoff")
local HIDE = link("Leichtes Leder")
local UNKNOWN = link("Unbekannt")

local function row(index)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == "showLootValue" then return line.rows[index] end
  end
end
local function lootValue(scope) return Stats.Get(scope, Stats.LOOT_VALUE) end

wow.state.sellPrices[CLOTH] = 10
wow.state.sellPrices[HIDE] = 25
wow.login({ level = 20, xp = 0, xpMax = 100000, playedSeconds = 0 })

-- Händlerpreis je Stück mal Anzahl; unbekannte Items und Käufe beim Händler zählen ohne Wert
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. CLOTH .. "x5.")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. UNKNOWN .. ".")
wow.fire("MERCHANT_SHOW")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet einen Gegenstand: " .. HIDE .. "x20.")
wow.fire("MERCHANT_CLOSED")
expect("Händlerpreis 5 x 10", lootValue(Stats.SESSION), 50)
expect("auch im Level", lootValue(Stats.LEVEL), 50)

-- Auctionator geladen: Auktionspreis vor Händlerpreis; ohne Auktionspreis und bei Fehlern der Händlerpreis
local calls = { caller = nil }
Auctionator = { API = { v1 = { GetAuctionPriceByItemLink = function(caller, itemLink)
  calls.caller = caller
  if itemLink == CLOTH then error("kaputt") end
  return itemLink == HIDE and 300 or nil
end } } }
wow.advance(5)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. HIDE .. "x2.")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. CLOTH .. ".")
expect("Auctionator-Aufrufer", calls.caller, "LevelTimer")
expect("Auktionspreis 2 x 300 + Händlerpreis 10", lootValue(Stats.SESSION), 50 + 600 + 10)
Auctionator = nil

-- Zeilen: Beutewert und Gold/h inkl. Beute über die Spielzeit (10 min)
wow.advance(600 - 5)
wow.fire("TIME_PLAYED_MSG", 100000, 600)
expect("Zeile Beutewert", row(1).value(Stats.SESSION), Format.Money(660))
expect("Gold/h inkl. Beute", row(2).value(Stats.SESSION), Format.Money(addon.Money.PerHour(660, 600)))
expect("ohne Instanz-Lauf", row(2).value(Stats.INSTANCE), "-")

-- Historie: Spalte Beutewert in Sessions > Kills & Items
SlashCmdList.LEVELTIMER("history")
expectTrue("Sessions > Kills & Items", addon.HistoryWindow.ShowView("HISTORY_TAB_SESSION_KILLS"))
local header = wow.shownTable():BuildCsv():match("^[^\n]*")
expectTrue("Session-Tabelle hat Beutewert", header:find(L.HISTORY_LOOT_VALUE, 1, true) ~= nil)
SlashCmdList.LEVELTIMER("history")

-- Voreinstellung Farmen schaltet den Beutewert ein
for _, preset in ipairs(addon.STAT_PRESETS) do
  if preset.label == "PRESET_FARMING" then addon.ApplyStatPreset(preset) end
end
expect("Farmen: Beutewert", LevelTimerDB.showLootValue, true)
