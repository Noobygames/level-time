-- Level Time Goals, Roadmap 300: Regel-Ziele, die scheitern können (Tod, Hilfe von außen, Flug, Rüstung, Heiltrank),
-- erreicht beim Level oder am Ende der Frist.
local Goals = streamGoal.Goals
local L = streamGoal.L

wow.login({ level = 10 })

SlashCmdList.STREAMGOAL("add rule nodeath 12")
local noDeath = Goals.Active()[1]
expect("Regel", noDeath.params.rule, "nodeath")
expect("mit Level", noDeath.params.level, true)
expect("Start beim Level", noDeath.progress, 10)
expect("Titel", Goals.Title(noDeath), string.format(L.SG_GOAL_RULE_LEVEL, L.SG_RULE_NODEATH, 12))
expect("unbekannte Regel", select(2, Goals.Create("rule", { rule = "nofun" })), L.SG_ERR_RULE)

SlashCmdList.STREAMGOAL("add rule nohelp")
local noHelp = Goals.Active()[2]
expect("ohne Level kein Zähler", Goals.HasCount(noHelp), false)
SlashCmdList.STREAMGOAL("add rule notaxi")
SlashCmdList.STREAMGOAL("add rule nopotion")
local noTaxi, noPotion = Goals.Active()[3], Goals.Active()[4]

-- Nackt: mit Rüstung kein Ziel; Rüstung kurz anprobieren ist erlaubt, anbehalten nicht
wow.state.equipped = { [5] = "|cffffffff|Hitem:6125::::::::10:::::|h[Hemd]|h|r" }
SlashCmdList.STREAMGOAL("add rule naked")
expect("mit Rüstung kein Nackt-Ziel", #Goals.Active(), 4)
expect("Meldung ausziehen", wow.printed[#wow.printed]:find(L.SG_ERR_NAKED, 1, true) ~= nil, true)
wow.state.equipped = {}
SlashCmdList.STREAMGOAL("add rule naked")
local naked = Goals.Active()[5]
wow.state.equipped = { [1] = "Helm" }
wow.fire("PLAYER_EQUIPMENT_CHANGED", 1, true)
wow.state.equipped = {}
wow.runTimers()
expect("kurz anprobiert: hält", naked.status, Goals.ACTIVE)
wow.state.equipped = { [1] = "Helm" }
wow.fire("PLAYER_EQUIPMENT_CHANGED", 1, true)
wow.runTimers()
expect("Rüstung behalten: gescheitert", naked.status, Goals.FAILED)
expect("Grund Rüstung", naked.failReason, L.SG_BROKEN_NAKED)
wow.state.equipped = {}

-- Heiltrank: anderer Zauber zählt nicht
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 133)
expect("Feuerball ist erlaubt", noPotion.status, Goals.ACTIVE)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 441)
expect("Heiltrank: gescheitert", noPotion.status, Goals.FAILED)

-- Hilfe von außen: Briefkasten
wow.fire("MAIL_SHOW")
expect("Briefkasten: gescheitert", noHelp.status, Goals.FAILED)
expect("Grund Post", noHelp.failReason, L.SG_BROKEN_NOHELP)
expect("andere Regel hält", noTaxi.status, Goals.ACTIVE)

-- Flug: die Zeitaufteilung von Level Time bucht Flugzeit
addon.Stats.Increment(addon.Stats.TAXI_SECONDS, 10)
expect("Flug: gescheitert", noTaxi.status, Goals.FAILED)

-- Level erreicht ohne Tod: erreicht
wow.levelUp(11)
expect("Level zählt", noDeath.progress, 11)
wow.levelUp(12)
expect("bis Level gehalten", noDeath.status, Goals.DONE)

-- Tod lässt ein neues Regel-Ziel scheitern
SlashCmdList.STREAMGOAL("add rule nodeath 20")
local second = Goals.Active()[1]
wow.state.dead = true
wow.fire("PLAYER_DEAD")
expect("Tod: gescheitert", second.status, Goals.FAILED)
wow.state.dead = false
wow.fire("PLAYER_ALIVE")

-- Regel mit Frist: Ablauf = erreicht
SlashCmdList.STREAMGOAL("add rule nodeath")
local timed = Goals.Active()[1]
SlashCmdList.STREAMGOAL("deadline " .. timed.id .. " 1m")
wow.advance(61)
wow.update(1)
expect("Frist gehalten = erreicht", timed.status, Goals.DONE)
