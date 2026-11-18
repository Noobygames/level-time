-- Review C: Verschiebung von Splits/Rares ganzzahlig, Abstecher in andere Instanz, Schwierigkeit nach dem Betreten,
-- Zeitpunkt des Wiedereintritts bei ReportNewCopy
local Instances = addon.Instances
local InstanceCopy = addon.InstanceCopy

local function enter(name, difficulty)
  wow.state.instance = name and { name = name, type = "party", difficulty = difficulty } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function run() return Instances.GetCurrentRun() end

wow.login({ level = 20, xp = 0, xpMax = 100000 })
enter(nil)

-- Gebrochene Verschiebung: keine zerrissenen Zahlen, nie negativ
expect("Rares +0,63 s", addon.InstanceBosses.ShiftRares("123:119:Name", 0.63), "123:120:Name")
expect("Rares negativ klemmt auf 0", addon.InstanceBosses.ShiftRares("123:1:Name", -5.6), "123:0:Name")

-- Abstecher: Höhlen -> Verlies -> Höhlen innerhalb von 30 Minuten ist derselbe Lauf
enter("Die Höhlen des Wehklagens", 1)
wow.advance(300)
enter("Burg Shadowfang", 1)
wow.advance(60)
enter("Die Höhlen des Wehklagens", 1)
expect("Abstecher: Höhlen laufen weiter", run().name, "Die Höhlen des Wehklagens")
expectTrue("Abstecher: erster Teil zurückgeführt", run().seconds >= 300)
expect("Abstecher: nur Shadowfang im Journal", #addon.character.instanceLog, 1)
expect("Abstecher: Shadowfang beendet", addon.character.instanceLog[1].name, "Burg Shadowfang")

-- Schwierigkeit 0 beim Betreten, später die echte: der Lauf übernimmt sie
enter(nil)
enter("Burg Shadowfang", 0)
expect("unsettled: Schwierigkeit 0", run().difficultyID, 0)
wow.state.instance.difficulty = 1
wow.fire("PLAYER_ENTERING_WORLD")
expect("settled: Schwierigkeit 1", run().difficultyID, 1)

-- ReportNewCopy meldet den Zeitpunkt des letzten Betretens, nicht des ersten der unbestätigten Kette
enter(nil)
wow.advance(600)
local reentered = time()
enter("Burg Shadowfang", 1)
local reported
InstanceCopy.OnCorrected(function(_, _, _, enteredAt) reported = enteredAt end)
InstanceCopy.ReportNewCopy()
expect("ReportNewCopy: Zeit des Wiedereintritts", reported, reentered)

-- Abweisung "zu viele Instanzen" auch über die Fehlerzeile erkannt
addon.Set("warnInstanceLimit", true)
local printed = #wow.printed
wow.fire("UI_ERROR_MESSAGE", 1, TRANSFER_ABORT_TOO_MANY_INSTANCES)
expectTrue("Abweisung über UI_ERROR_MESSAGE", #wow.printed > printed)
