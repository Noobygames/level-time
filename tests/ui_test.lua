-- Oberfläche und Befehle: nichts darf abstürzen, Einstellungen wirken, Texte sind lokalisiert.
wow.login({ playedSeconds = 600 })

expect("unbekanntes Event -> false statt Fehler", addon.RegisterEvent(wow.UNKNOWN_EVENT, function() end), false)

-- Jede Stat-Zeile liefert einen Wert (Level und Session) und hat Texte und einen Default
for _, stat in ipairs(addon.STAT_LINES) do
  expectTrue("Default für " .. stat.setting, LevelTimerDB[stat.setting] ~= nil)
  expectTrue("Locale-Key " .. stat.label, addon.L[stat.label] ~= stat.label)
  for _, row in ipairs(stat.rows) do
    expectTrue("Locale-Key " .. row.label, addon.L[row.label] ~= row.label)
    for _, scope in ipairs({ addon.Stats.LEVEL, addon.Stats.SESSION }) do
      local value = row.value(scope)
      expectTrue("Wert für " .. row.label .. " (" .. scope .. ")", type(value) == "string" and value ~= "")
    end
  end
end

-- Werte als reine Zahlen/Angaben, Bezeichnung steht separat
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
local function rowValue(label)
  for _, stat in ipairs(addon.STAT_LINES) do
    for _, row in ipairs(stat.rows) do
      if row.label == label then return row.value(addon.Stats.LEVEL) end
    end
  end
end
expect("PvE-Kills als Zahl", rowValue("ROW_PVE_KILLS"), "1")
expect("PvP-Kills als Zahl", rowValue("ROW_PVP_KILLS"), "0")
expect("Kills pro Tod ohne Tod", rowValue("ROW_KILLS_PER_DEATH"), "-")

-- PvE und PvP einzeln abschaltbar
addon.Set("showPvpKills", false)
expect("PvP aus", LevelTimerDB.showPvpKills, false)
expect("PvE bleibt an", LevelTimerDB.showPveKills, true)
addon.Set("showPvpKills", true)

-- Fenster zwischen Level und Session umschalten
addon.Set("windowScope", addon.Stats.SESSION)
expect("Bereich Session", LevelTimerDB.windowScope, "session")
addon.Set("windowScope", addon.Stats.LEVEL)

-- Sprachwechsel greift sofort
expect("deutscher Text", addon.L.ROW_DEATHS, "Tode")
addon.Set("language", "enUS")
expect("englischer Text", addon.L.ROW_DEATHS, "Deaths")

-- Befehle
SlashCmdList.LEVELTIMER("lock")
expect("lock", LevelTimerDB.locked, true)
SlashCmdList.LEVELTIMER(" UNLOCK ")
expect("unlock mit Leerzeichen/Großschreibung", LevelTimerDB.locked, false)
SlashCmdList.LEVELTIMER("hide")
expect("hide", LevelTimerDB.showTimer, false)
SlashCmdList.LEVELTIMER("show")
expect("show", LevelTimerDB.showTimer, true)
SlashCmdList.LEVELTIMER("minimap")
expect("minimap aus", LevelTimerDB.minimap.hide, true)
SlashCmdList.LEVELTIMER("minimap")
expect("minimap an", LevelTimerDB.minimap.hide, false)

local printedBefore = #wow.printed
SlashCmdList.LEVELTIMER("gibtsnicht")
expectTrue("unbekannter Befehl wird gemeldet",
  wow.printed[printedBefore + 1]:find(string.format(addon.L.COMMAND_UNKNOWN, "gibtsnicht"), 1, true) ~= nil)
expect("nur eine Zeile mit Verweis auf die Hilfe", #wow.printed, printedBefore + 1)

-- Fenster öffnen/schließen und Einstellungen ändern ohne Fehler
SlashCmdList.LEVELTIMER("")
SlashCmdList.LEVELTIMER("history")
addon.Frames.SetScale("main", 1.2)
addon.Set("showMoney", false)
wow.state.shiftDown = true
LevelTimer_OnAddonCompartmentClick()

-- Historie: Session-Ansicht und Charakter-Wechsel rendern ohne Fehler
addon.Set("language", "deDE")
expectTrue("Reiter Sessions klickbar", wow.click("Sessions"))
expectTrue("Reiter Level klickbar", wow.click("Level"))
expectTrue("nächster Charakter", wow.click(">"))
expectTrue("Session-Reiter im Fenster", wow.click("Session"))
expect("Fenster zeigt Session", LevelTimerDB.windowScope, "session")

-- Eigenes Icon: Pfad zeigt auf eine Datei im Addon (WoW ergänzt die Endung selbst)
local iconFile = addon.Widgets.ICON:gsub("\\", "/"):gsub("^Interface/AddOns/LevelTimer/", "") .. ".tga"
local handle = io.open(wow.ADDON_DIR .. "/" .. iconFile, "rb")
expectTrue("Icon-Datei vorhanden: " .. iconFile, handle ~= nil)
if handle then handle:close() end

-- Einstellungen: Sprache über die Reiter wählen
expectTrue("Sprach-Reiter English", wow.click("English"))
expect("Sprache Englisch", LevelTimerDB.language, "enUS")
expectTrue("Sprach-Reiter Deutsch", wow.click("Deutsch"))
expect("Sprache Deutsch", LevelTimerDB.language, "deDE")
