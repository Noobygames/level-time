-- Sessions: zählen parallel zum Level, überstehen /reload und Level-Ups,
-- landen nach dem nächsten echten Login in der Historie.
local Stats = addon.Stats
local History = addon.History

local function kill()
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
end

wow.login({ level = 10, xp = 500, xpMax = 1000, playedSeconds = 3600 })
local firstSessionStart = addon.character.currentSession.startedAt

kill()
wow.state.xp = 600
wow.fire("PLAYER_XP_UPDATE", "player")
wow.advance(1200)

expect("Level zählt Kill", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 1)
expect("Session zählt Kill", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 1)
expectNear("Session-Zeit", Stats.GetSeconds(Stats.SESSION), 1200)
expectNear("Level-Zeit vom Server", Stats.GetSeconds(Stats.LEVEL), 4800)
expect("Session-XP aus Zuwachs", Stats.GetXp(Stats.SESSION), 100)
expect("Level-XP = UnitXP", Stats.GetXp(Stats.LEVEL), 600)

-- /reload: Session läuft weiter
wow.logout()
wow.advance(20)
wow.login()
expect("Reload: gleiche Session", addon.character.currentSession.startedAt, firstSessionStart)
expect("Reload: nichts archiviert", #addon.character.sessionHistory, 0)
wow.advance(600)
expectNear("Reload: Zeit läuft weiter", Stats.GetSeconds(Stats.SESSION), 1800)

-- Level-Up mitten in der Session: Level beginnt neu, Session nicht
wow.state.xp = 950
wow.fire("PLAYER_XP_UPDATE", "player")
wow.levelUp(11, 1200)
wow.state.xp = 50
wow.fire("PLAYER_XP_UPDATE", "player")
kill()
expect("Level nach Level-Up neu", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 1)
expect("Session behält Kills", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 2)
expect("Session-XP über Level-Up hinweg", Stats.GetXp(Stats.SESSION), 100 + 350 + 100)

local current = History.GetSessionRecords(addon.characterKey)[1]
expect("laufende Session markiert", current.isCurrent, true)
expect("Level-Spanne Start", current.startLevel, 10)
expect("Level-Spanne Ende", current.endLevel, 11)

-- Lange Pause: alte Session wird archiviert, neue beginnt
wow.logout()
wow.advance(3600)
wow.login({ level = 11 })
expect("alte Session archiviert", #addon.character.sessionHistory, 1)
local archived = addon.character.sessionHistory[1]
expectNear("archivierte Dauer", archived.seconds, 1800)
expect("archivierte Kills", archived.counters.pveKills, 2)
expect("archiviertes End-Level", archived.endLevel, 11)
expect("neue Session ohne Kills", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 0)
expect("Level-Zähler bleiben über Sessions", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 1)

-- Sehr kurze Session wird nicht archiviert
wow.advance(10)
wow.logout()
wow.advance(3600)
wow.login()
expect("kurze Session nicht archiviert", #addon.character.sessionHistory, 1)

-- Auswertung: Summe über alle Sessions
local records = History.GetSessionRecords(addon.characterKey)
local summary = History.Summarize(records)
expect("Summe Kills", summary.counters.pveKills, 2)
expect("Anzahl Einträge", summary.count, 2)

-- Neue Session per Befehl: laufende wird sofort archiviert, Zähler beginnen bei 0
wow.advance(600)
kill()
local before = #addon.character.sessionHistory
SlashCmdList.LEVELTIMER("newsession")
expect("manuell archiviert", #addon.character.sessionHistory, before + 1)
local manual = addon.character.sessionHistory[#addon.character.sessionHistory]
expectNear("archivierte Zeit bis jetzt", manual.seconds, 600)
expect("archivierter Kill", manual.counters.pveKills, 1)
expect("neue Session ohne Kills", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 0)
expectNear("neue Session ohne Zeit", Stats.GetSeconds(Stats.SESSION), 0)
expect("Level-Zähler unberührt", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 2)
expectTrue("Rückmeldung im Chat", wow.printed[#wow.printed]:find(addon.L.NEW_SESSION_STARTED, 1, true) ~= nil)

-- Neue Session läuft normal weiter und übersteht /reload
wow.advance(120)
wow.logout()
wow.advance(20)
wow.login()
expect("nach Reload nichts zusätzlich archiviert", #addon.character.sessionHistory, before + 1)
expectNear("neue Session zählt weiter", Stats.GetSeconds(Stats.SESSION), 120)

-- Button in den Einstellungen
SlashCmdList.LEVELTIMER("config")
wow.advance(120)
wow.popup = nil
expectTrue("Button Neue Session", wow.click(addon.L.NEW_SESSION))
-- Roadmap 208: erst die Rückfrage mit der Dauer der laufenden Session
expect("Button fragt nach", #addon.character.sessionHistory, before + 1)
expect("Rückfrage nennt die Dauer", wow.popup and wow.popup.text, addon.Format.Duration(addon.Stats.GetSeconds(addon.Stats.SESSION)))
StaticPopupDialogs[wow.popup.name].OnAccept()
expect("Button archiviert", #addon.character.sessionHistory, before + 2)
