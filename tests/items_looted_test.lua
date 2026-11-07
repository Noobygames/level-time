-- Roadmap 382: erbeutete Gegenstände nach Anzahl (alle Qualitäten) je Bereich, Gegenstände/h, letzte 15 Minuten,
-- Spalte Items/h in der Historie, Voreinstellung "Farmen" und neue Zeilen passen in jedes Layout (fr/es).
local Stats = addon.Stats
local Experience = addon.Experience
local RecentCounts = addon.RecentCounts
local Format = addon.Format
local L = addon.L

local function link(color, name)
  return "|cff" .. color .. "|Hitem:1234::::::::20:::::|h[" .. name .. "]|h|r"
end
local CLOTH = link("ffffff", "Leinenstoff")
local JUNK = link("9d9d9d", "Zerbrochener Zahn")

local function row(setting, index)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == setting then return line.rows[index] end
  end
end
local function items(scope) return Stats.Get(scope, Stats.ITEMS_LOOTED) end

wow.login({ level = 20, xp = 0, xpMax = 100000, playedSeconds = 0 })

-- Eigene Beute einzeln und als Stapel, auch grau; fremde Beute, Herstellen und geheime Zeilen zählen nicht
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. CLOTH .. ".")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. CLOTH .. "x5.")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. JUNK .. ".")
wow.fire("CHAT_MSG_LOOT", "Grimbar erhält Beute: " .. CLOTH .. "x3.")
wow.fire("CHAT_MSG_LOOT", "Ihr stellt her: " .. CLOTH .. "x2.")
wow.fire("CHAT_MSG_LOOT", wow.SECRET)
expect("einzeln + Stapel + grau", items(Stats.SESSION), 7)
expect("auch im Level", items(Stats.LEVEL), 7)

-- Erhaltene Gegenstände (Questbelohnung) zählen, Käufe beim Händler nicht (auch kurz nach dem Schließen)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet einen Gegenstand: " .. CLOTH .. "x2.")
expect("erhaltener Stapel zählt", items(Stats.SESSION), 9)
wow.fire("MERCHANT_SHOW")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet einen Gegenstand: " .. CLOTH .. "x20.")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. CLOTH .. ".")  -- echte Beute zählt auch am Händler
wow.fire("MERCHANT_CLOSED")
wow.advance(1)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet einen Gegenstand: " .. CLOTH .. ".")
expect("Kauf zählt nicht", items(Stats.SESSION), 10)
wow.advance(5)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet einen Gegenstand: " .. CLOTH .. ".")
expect("nach dem Händler wieder", items(Stats.SESSION), 11)

-- Gegenstände/h über die Spielzeit wie XP/h, Zeilen im Fenster
wow.advance(600 - 6)
wow.fire("TIME_PLAYED_MSG", 100000, 600)
expect("Zeile Gegenstände", row("showItemsLooted", 1).value(Stats.SESSION), "11")
expect("Session: 66 Gegenstände/h", row("showItemsLooted", 2).value(Stats.SESSION), Format.Number(66))
expect("Level: 66 Gegenstände/h", row("showItemsLooted", 2).value(Stats.LEVEL), Format.Number(66))
expect("ohne Instanz-Lauf", row("showItemsLooted", 2).value(Stats.INSTANCE), "...")

-- Letzte 15 Minuten: alles aus den ersten 10 Minuten, nach 15 min Pause leer
expect("15 min: alle", row("showRecentItems", 1).value(), "11")
expect("15 min: Rate über 10 min", row("showRecentItems", 2).value(), Format.Number(66))
wow.advance(900)
expect("15 min: herausgefallen", RecentCounts.Count(Stats.ITEMS_LOOTED), 0)

-- Instanz-Lauf zählt mit
wow.state.instance = { name = "Die Todesminen", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. CLOTH .. "x4.")
wow.advance(120)
expect("Instanz: Gegenstände", items(Stats.INSTANCE), 4)
expect("Instanz: Gegenstände/h", row("showItemsLooted", 2).value(Stats.INSTANCE), Format.Number(120))
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")

-- Historie: Spalte Items/h; Summenzeile über bekannte Spielzeit
local record = { seconds = 1800, counters = { [Stats.ITEMS_LOOTED] = 90 } }
local summary = addon.History.Summarize({ record })
expectNear("Items/h eines Eintrags", Experience.CountRate(summary.counters[Stats.ITEMS_LOOTED],
  Experience.RecordRateSeconds(summary)), 180, 0.001)
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Sessions", wow.click(L.HISTORY_TAB_SESSIONS))
local header = wow.shownTable():BuildCsv():match("^[^\n]*")
expectTrue("Session-Tabelle hat Items/h", header:find(L.HISTORY_ITEM_RATE, 1, true) ~= nil)
SlashCmdList.LEVELTIMER("history")

-- Voreinstellung Farmen
local farming
for _, preset in ipairs(addon.STAT_PRESETS) do
  if preset.label == "PRESET_FARMING" then farming = preset end
end
expectTrue("Voreinstellung Farmen", farming ~= nil)
addon.ApplyStatPreset(farming)
for _, setting in ipairs({ "showKillRate", "showRecentKills", "showItemsLooted", "showRecentItems", "showIncome" }) do
  expect("Farmen: " .. setting, LevelTimerDB[setting], true)
end
expect("Farmen: XP/h aus", LevelTimerDB.showXpRate, false)

-- Neue Zeilen passen in jedes Layout und jede Sprache (wie window_layouts)
local Layouts = addon.WindowLayouts
local window = LevelTimerFrame
local checked = { count = 0 }
for _, language in ipairs({ "deDE", "frFR", "esES", "enUS" }) do
  addon.Set("language", language)
  for _, id in ipairs(Layouts.ORDER) do
    addon.Set("windowLayout", id)
    wow.update(0.3)
    local elements = addon.TimerWindow.Elements()
    for _, line in ipairs(elements.rows) do
      for _, fontString in ipairs({ line.label, line.value }) do
        if fontString:IsShown() and fontString._text ~= "" then
          checked.count = checked.count + 1
          expectTrue(language .. " " .. id .. ": " .. fontString._text, fontString:GetStringWidth() <= window:GetWidth())
        end
      end
    end
    for _, tile in ipairs(elements.tiles) do
      if tile.frame:IsShown() then
        checked.count = checked.count + 1
        expectTrue(language .. " Kachel " .. tile.label._text, tile.label:GetStringWidth() <= tile.frame:GetWidth())
      end
    end
  end
end
expectTrue("Zeilen geprüft", checked.count > 40)
addon.Set("language", "deDE")
