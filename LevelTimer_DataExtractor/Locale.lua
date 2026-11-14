-- Texte des Data Extractors (nur lokal genutzt, daher nur Deutsch und Englisch; andere Sprachen nehmen Englisch).
local _, X = ...

local TEXTS = {
  enUS = {
    STATUS = "Data Extractor: %d NPCs, %d quests, %d items, %d objects, %d vendors, %d trainers, %d flight paths. Debug log %s, %d lines.",
    RESET_HINT = "/lte reset confirm deletes all collected data (the debug log stays).",
    RESET_DONE = "Data Extractor: collected data deleted.",
    HELP = "/lte: status | reset confirm: delete collected data | log [off]: debug log on/off | check: run all checks. Level Time test commands: /lt debug help",
    DEBUG_ON = "Debug on: extended logging in chat (until /reload). Test commands: /lt debug help",
    DEBUG_OFF = "Debug off.",
    DEBUG_HELP = "/lt debug: logging on/off | state: internal state | levelup: test level-up summary, announcement and alert | alert <kind>: test an alert | remind: check buff reminders | death: check death cause | splits: reference times | log [off/clear/status]: persistent debug log on (off: off) | check: run every check once and write it to the debug log | perf [on/off/report/reset]: CPU usage per handler",
    DEBUG_LOG_ON = "Debug log on: debug lines, errors and event probes are saved (also across /reload). File: WTF\\Account\\<account>\\SavedVariables\\LevelTimer_DataExtractor.lua, written on /reload or logout.",
    DEBUG_LOG_OFF = "Debug log off until /reload (/lt debug log turns it on again). Existing lines stay saved (/lt debug log clear deletes them).",
    DEBUG_LOG_CLEARED = "Debug log cleared.",
    DEBUG_LOG_STATUS = "Debug log %s, %d of at most %d lines.",
    DEBUG_LOG_STATE_ON = "on",
    DEBUG_LOG_STATE_OFF = "off",
    DEBUG_CHECK_DONE = "Debug check: %d checks written to the debug log, %d with errors. /reload saves the file.",
    NO_LEVEL_TIME = "Level Time is not loaded: only data collection runs, no debug log or checks.",
  },
  deDE = {
    STATUS = "Data Extractor: %d NPCs, %d Quests, %d Gegenstände, %d Objekte, %d Händler, %d Lehrer, %d Flugrouten. Debug-Log %s, %d Zeilen.",
    RESET_HINT = "/lte reset confirm löscht alle gesammelten Daten (das Debug-Log bleibt).",
    RESET_DONE = "Data Extractor: gesammelte Daten gelöscht.",
    HELP = "/lte: Status | reset confirm: gesammelte Daten löschen | log [off]: Debug-Log an/aus | check: alle Prüfungen. Testbefehle von Level Time: /lt debug help",
    DEBUG_ON = "Fehlersuche an: erweitertes Logging im Chat (bis /reload). Testbefehle: /lt debug help",
    DEBUG_OFF = "Fehlersuche aus.",
    DEBUG_HELP = "/lt debug: Logging an/aus | state: Zustand | levelup: Level-Up-Zusammenfassung, Ansage und Einblendung testen | alert <art>: Einblendung testen | remind: Buff-Hinweise prüfen | death: Todesursache prüfen | splits: Vergleichszeiten | log [off/clear/status]: dauerhaftes Debug-Log an (off: aus) | check: alles einmal prüfen und ins Debug-Log schreiben | perf [on/off/report/reset]: CPU-Messung je Handler",
    DEBUG_LOG_ON = "Debug-Log an: Debug-Zeilen, Fehler und Ereignis-Proben werden gespeichert (auch nach /reload). Datei: WTF\\Account\\<Konto>\\SavedVariables\\LevelTimer_DataExtractor.lua, geschrieben bei /reload oder Logout.",
    DEBUG_LOG_OFF = "Debug-Log aus bis /reload (/lt debug log schaltet es wieder an). Bisherige Zeilen bleiben gespeichert (/lt debug log clear löscht sie).",
    DEBUG_LOG_CLEARED = "Debug-Log geleert.",
    DEBUG_LOG_STATUS = "Debug-Log %s, %d von höchstens %d Zeilen.",
    DEBUG_LOG_STATE_ON = "an",
    DEBUG_LOG_STATE_OFF = "aus",
    DEBUG_CHECK_DONE = "Debug-Prüfung: %d Prüfungen ins Debug-Log geschrieben, %d mit Fehler. /reload speichert die Datei.",
    NO_LEVEL_TIME = "Level Time ist nicht geladen: nur die Datensammlung läuft, kein Debug-Log und keine Prüfungen.",
  },
}

X.L = setmetatable(TEXTS[GetLocale()] or {}, { __index = TEXTS.enUS })
