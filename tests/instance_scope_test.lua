-- Dritter Bereich "Instanz": Zähler des laufenden Laufs wie bei Level und Session, Reiter im Fenster,
-- Zeile "Erhaltene XP" und Umwandlung eines Laufs aus älteren Versionen.
local Stats = addon.Stats
local Instances = addon.Instances

local function enter(name)
  wow.state.instance = name and { name = name, type = "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function rowValue(setting, scope)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == setting then return line.rows[1].value(scope) end
  end
end

wow.login({ level = 20, xp = 0, xpMax = 100000 })
enter(nil)
expect("ohne Lauf: Zeit 0", Stats.GetSeconds(Stats.INSTANCE), 0)
expect("ohne Lauf: keine XP", Stats.GetXp(Stats.INSTANCE), 0)
expect("ohne Lauf: kein Bereich", Stats.IsOpen(Stats.INSTANCE), false)

enter("Die Todesminen")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Defias-Schurke stirbt, Ihr bekommt 100 Erfahrung.")
gainXp(100)
wow.advance(120)
expect("Lauf offen", Stats.IsOpen(Stats.INSTANCE), true)
expect("Instanz-XP", Stats.GetXp(Stats.INSTANCE), 100)
expect("Instanz-Kills", Stats.GetTotalKills(Stats.INSTANCE), 1)
expectNear("Instanz-Zeit", Stats.GetSeconds(Stats.INSTANCE), 120)
expect("XP-Zeile Instanz", rowValue("showXpGained", Stats.INSTANCE), addon.Format.Number(100))

-- Draußen zählt nur Level und Session
enter(nil)
gainXp(40)
expect("Instanz-XP draußen unverändert", Stats.GetXp(Stats.INSTANCE), 100)
expect("Session-XP", Stats.GetXp(Stats.SESSION), 140)
expect("XP-Zeile Session", rowValue("showXpGained", Stats.SESSION), addon.Format.Number(140))
expect("XP-Zeile Level", rowValue("showXpGained", Stats.LEVEL), addon.Format.Number(140))

-- Reiter schaltet den Bereich um
expectTrue("Instanz-Reiter klickbar", wow.click(addon.L.TAB_INSTANCE))
expect("Fenster zeigt Instanz", LevelTimerDB.windowScope, Stats.INSTANCE)
wow.update(1)
addon.Set("windowScope", Stats.LEVEL)

-- Neuer Lauf beginnt bei null
enter("Burg Schattenfang")
expect("neuer Lauf: XP null", Stats.GetXp(Stats.INSTANCE), 0)

-- Zurücksetzen: Befehl fragt nach, Bestätigung setzt Zähler und Zeit auf null, der Lauf bleibt offen
wow.popup = nil
SlashCmdList.LEVELTIMER("resetinstance")
expect("Rückfrage für Burg Schattenfang", wow.popup.data, nil)
expect("Rückfrage nennt die Instanz", wow.popup.text, "Burg Schattenfang")
gainXp(250)
wow.advance(90)
expectNear("vor Reset: XP", Stats.GetXp(Stats.INSTANCE), 250)
local dialog = StaticPopupDialogs[wow.popup.name]
dialog.OnAccept()
expect("nach Reset: XP null", Stats.GetXp(Stats.INSTANCE), 0)
expectNear("nach Reset: Zeit null", Stats.GetSeconds(Stats.INSTANCE), 0, 1)
expect("Lauf bleibt offen", Instances.GetCurrentRun().name, "Burg Schattenfang")
expect("Session unberührt", Stats.GetXp(Stats.SESSION) >= 250, true)
wow.advance(30)
gainXp(10)
expect("Zählung läuft nach Reset weiter", Stats.GetXp(Stats.INSTANCE), 10)
expectNear("Uhr läuft nach Reset weiter", Stats.GetSeconds(Stats.INSTANCE), 30, 1)

-- Ohne Lauf nur Hinweis, keine Rückfrage
enter(nil)
wow.popup = nil
if not LevelTimerOptions:IsShown() then SlashCmdList.LEVELTIMER("config") end
expectTrue("Button klickbar", wow.click(addon.L.INSTANCE_RESET))
-- Der Lauf ist nach dem Verlassen noch offen (Händlergang), also auch hier Rückfrage
expectTrue("offener Lauf draußen: Rückfrage", wow.popup ~= nil)
addon.character.currentRun = nil
wow.popup = nil
SlashCmdList.LEVELTIMER("resetinstance")
expect("kein Lauf: keine Rückfrage", wow.popup, nil)
expect("kein Lauf: Hinweis", wow.printed[#wow.printed]:find(addon.L.INSTANCE_RESET_NONE, 1, true) ~= nil, true)
enter("Burg Schattenfang")

-- Lauf aus älteren Versionen (xp, counters) wird beim Login umgewandelt
addon.character.currentRun = { name = "Burg Schattenfang", instanceType = "party", startedAt = 1, seconds = 30,
  level = 20, xp = 700, counters = { kills = 4, deaths = 1 } }
wow.logout()
wow.login()
local run = Instances.GetCurrentRun()
expect("alter Lauf: XP", Stats.Get(Stats.INSTANCE, Stats.XP_GAINED), 700)
expect("alter Lauf: Kills", Stats.GetTotalKills(Stats.INSTANCE), 4)
expect("alter Lauf: Tode", Stats.Get(Stats.INSTANCE, Stats.DEATHS), 1)
expect("alter Lauf: alte Felder weg", run.xp, nil)

-- Ungebuchte Zeit (Kampf) zählt nur bei laufender Lauf-Uhr in den Instanz-Bereich
enter("Burg Schattenfang")
local seconds = function(scope) return addon.TimeBreakdown.GetSeconds(scope, Stats.COMBAT_SECONDS) end
wow.state.inCombat = true
addon.TimeBreakdown.Update(1)
addon.TimeBreakdown.Update(1)
expectTrue("drin: Kampfzeit zählt", seconds(Stats.INSTANCE) > 0)
enter(nil)
expect("draußen: Lauf steht", Stats.IsCounting(Stats.INSTANCE), false)
addon.TimeBreakdown.Update(1)
local frozen = seconds(Stats.INSTANCE)
addon.TimeBreakdown.Update(1)
expect("draußen: Kampfzeit steht", seconds(Stats.INSTANCE), frozen)
wow.state.inCombat = false

-- Automatischer Reiter: rein = Instanz, raus = zurück; manueller Wechsel dazwischen bleibt
addon.character.currentRun = nil
enter(nil)
addon.Set("windowScope", Stats.SESSION)
addon.Set("autoInstanceTab", true)
enter("Burg Schattenfang")
expect("beim Betreten: Instanz", LevelTimerDB.windowScope, Stats.INSTANCE)
enter(nil)
expect("beim Verlassen: zurück", LevelTimerDB.windowScope, Stats.SESSION)
enter("Burg Schattenfang")
addon.Set("windowScope", Stats.LEVEL)
enter(nil)
expect("manueller Wechsel bleibt", LevelTimerDB.windowScope, Stats.LEVEL)
addon.Set("autoInstanceTab", false)

-- Leerer Zustand: Instanz-Reiter ohne Lauf zeigt "Kein Lauf" und Striche
addon.character.currentRun = nil
addon.Set("windowScope", Stats.INSTANCE)
wow.update(1)
local noRun = wow.findFrame(function(frame) return frame.GetText and frame:GetText() == addon.L.INSTANCE_NONE end)
expectTrue("Hinweis Kein Lauf", noRun ~= nil)
addon.Set("windowScope", Stats.LEVEL)

-- Merker ging verloren (z.B. /reload in der Instanz): beim Verlassen zurück auf Level statt hängen zu bleiben
enter(nil)
addon.Set("autoInstanceTab", true)
addon.Set("windowScope", Stats.INSTANCE)
enter("Burg Schattenfang")
enter(nil)
expect("ohne Merker auf Level zurück", LevelTimerDB.windowScope, Stats.LEVEL)
addon.Set("autoInstanceTab", false)

-- Zurücksetzen bucht ungebuchte Zeit noch vor dem Nullen: nichts davon landet im neuen Stand
enter("Burg Schattenfang")
wow.state.inCombat = true
addon.TimeBreakdown.Update(1)
for _ = 1, 5 do addon.TimeBreakdown.Update(1) end
addon.Instances.ResetCurrent()
expect("nach Reset keine Kampfzeit", Stats.Get(Stats.INSTANCE, Stats.COMBAT_SECONDS), 0)
wow.state.inCombat = false
enter(nil)
