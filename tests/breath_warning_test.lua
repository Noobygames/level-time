-- Atem-Warnung: unter der Schwelle einmal je Abtauchen Karte, Ton und Blinken; Auftauchen und Ende stoppen
local L = addon.L

wow.login({ level = 20 })
wow.state.mirrorProgress = {}

local function dive(valueMs)
  wow.fire("MIRROR_TIMER_START", "BREATH", valueMs, 60000, -1, 0, "Atem")
end

dive(60000)
wow.advance(50)
wow.update(1)
expect("aus: nichts", wow.flashes, 0)

addon.Set("warnBreath", true)
addon.Alerts.Clear()
wow.fire("MIRROR_TIMER_STOP", "BREATH")
dive(60000)
wow.advance(30)
wow.update(1)
expect("30 s übrig: noch nichts", wow.flashes, 0)
-- Direkt nach dem Start liefert der Client 0 (Debug-Log), dann die Schätzung; später der echte Rest
wow.state.mirrorProgress.BREATH = 14000
wow.update(1)
expect("unter 15 s: Blinken", wow.flashes, 1)
expect("Karte", LevelTimerNotice.title:GetText(), L.NOTICE_BREATH)
expect("Text mit Sekunden", LevelTimerNotice.body:GetText(), string.format(L.WARN_BREATH, 14))
wow.state.mirrorProgress.BREATH = 8000
wow.update(1)
expect("nur einmal je Abtauchen", wow.flashes, 1)

-- Auftauchen (Leiste füllt sich) und erneut abtauchen: wieder scharf
wow.fire("MIRROR_TIMER_START", "BREATH", 20000, 60000, 10, 0, "Atem")
wow.state.mirrorProgress.BREATH = nil
wow.fire("MIRROR_TIMER_STOP", "BREATH")
dive(60000)
wow.advance(46)
wow.update(1)
expect("Schätzung ohne Fortschritt", wow.flashes, 2)

-- Erschöpfung und geheime Werte
wow.fire("MIRROR_TIMER_START", "EXHAUSTION", 10000, 60000, -1, 0, "Erschöpfung")
wow.update(1)
expect("Erschöpfung warnt", LevelTimerNotice.title:GetText(), L.NOTICE_FATIGUE)
wow.fire("MIRROR_TIMER_STOP", "EXHAUSTION")
wow.fire("MIRROR_TIMER_STOP", "BREATH")
wow.fire("MIRROR_TIMER_START", wow.SECRET, 1000, 60000, -1, 0, "Atem")
local before = wow.flashes
wow.update(1)
expect("geheim: nichts", wow.flashes, before)
expect("andere Leisten egal", (function()
  wow.fire("MIRROR_TIMER_START", "FEIGNDEATH", 1000, 60000, -1, 0, "Totstellen")
  wow.update(1)
  return wow.flashes
end)(), before)
