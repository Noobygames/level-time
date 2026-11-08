-- Level Time Goals, Roadmap 439: Weglaufen. Zählt, wenn ein Gegner den Spieler mindestens 2 s angriff und der Kampf
-- endet, ohne dass er oder der Spieler stirbt, oder wenn jemand anderes ihm die Aggro abnimmt; nie in Instanzen, nicht
-- nach Totstellen oder Verschwinden, höchstens einmal je Kampf.
local Goals = streamGoal.Goals
local Escape = streamGoal.EscapeGoals
local L = streamGoal.L

local me = { name = "Testchar" }
local units = wow.state.units
local nextGuid = 0

local function wolf()
  nextGuid = nextGuid + 1
  return { name = "Wolf", hostile = true, combat = true, guid = "Creature-0-1-" .. nextGuid }
end

-- Gegner als Ziel greift den Spieler seconds Sekunden an (Prüfung alle 0,5 s wie im Spiel)
local function attackedBy(mob, seconds)
  units.target, units.targettarget = mob, me
  wow.state.inCombat = true
  wow.fire("PLAYER_REGEN_DISABLED")
  for _ = 1, seconds * 2 do
    wow.advance(0.5)
    Escape.Check()
  end
  return mob
end

local function tick(seconds)
  for _ = 1, seconds * 2 do
    wow.advance(0.5)
    Escape.Check()
  end
end

local function combatEnds()
  wow.state.inCombat = false
  wow.fire("PLAYER_REGEN_ENABLED")
  units.target, units.targettarget = nil, nil
end

wow.login({ level = 20 })
units.player = me

-- Ohne Ziel: nichts verfolgt
attackedBy(wolf(), 3)
units.target = nil
combatEnds()

SlashCmdList.STREAMGOAL("add escape 20")
local goal = Goals.Active()[1]
expect("Art", goal.kind, "escape")
expect("Titel", Goals.Title(goal), string.format(L.SG_GOAL_ESCAPE, 20))
SlashCmdList.STREAMGOAL("add escape")
expect("ohne Zahl einmal", Goals.Title(Goals.Active()[2]), L.SG_GOAL_ESCAPE_ONE)
Goals.Cancel(Goals.Active()[2].id)

-- Weggelaufen: Gegner außer Sicht, Kampf endet
attackedBy(wolf(), 3)
units.target = nil
tick(1)
combatEnds()
expect("weggelaufen", goal.progress, 1)

-- Gegner getötet (als Ziel tot gesehen)
local mob = attackedBy(wolf(), 3)
mob.dead = true
Escape.Check()
combatEnds()
expect("getötet zählt nicht", goal.progress, 1)

-- Gegner außer Sicht, aber Kill im Journal mit seinem Namen
attackedBy(wolf(), 3)
units.target = nil
addon.Journal.AddKill("pve", "Wolf")
combatEnds()
expect("Kill im Journal zählt nicht", goal.progress, 1)

-- Namenloser Kill (geheime Meldung) und Gegner außer Sicht: unsicher, zählt nicht
attackedBy(wolf(), 3)
units.target = nil
addon.Journal.AddKill("pve", nil)
combatEnds()
expect("namenloser Kill zählt nicht", goal.progress, 1)

-- Gegner bricht ab (außer Kampf, lebend zu sehen): zählt, auch mit namenlosem Kill eines anderen Gegners
mob = attackedBy(wolf(), 3)
addon.Journal.AddKill("pve", nil)
mob.combat = false
units.targettarget = nil
combatEnds()
expect("abgebrochen und lebend gesehen", goal.progress, 2)

-- Plakette verschwindet mit totem Gegner
mob = wolf()
units.nameplate1, units.nameplate1target = mob, me
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
attackedBy(mob, 3)
units.target = nil
mob.dead = true
wow.fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
units.nameplate1, units.nameplate1target = nil, nil
combatEnds()
expect("tot beim Entfernen der Plakette", goal.progress, 2)

-- Nur kurz angegriffen (Körperzug)
attackedBy(wolf(), 1)
units.target = nil
combatEnds()
expect("zu kurz", goal.progress, 2)

-- Spieler stirbt
attackedBy(wolf(), 3)
units.target = nil
wow.state.dead = true
wow.fire("PLAYER_DEAD")
combatEnds()
wow.state.dead = false
expect("Tod zählt nicht", goal.progress, 2)

-- In einer Instanz nie, auch nicht, wenn der Kampf dort begann und draußen endet
wow.state.instance = { name = "Höhlen des Wehklagens", type = "party" }
attackedBy(wolf(), 3)
units.target = nil
combatEnds()
expect("Dungeon zählt nicht", goal.progress, 2)
attackedBy(wolf(), 3)
wow.state.instance = nil
units.target = nil
combatEnds()
expect("im Dungeon begonnen zählt nicht", goal.progress, 2)
wow.state.instance = { name = "Arathibecken", type = "pvp" }
attackedBy(wolf(), 3)
units.target = nil
combatEnds()
wow.state.instance = nil
expect("Schlachtfeld zählt nicht", goal.progress, 2)

-- Totstellen und Verschwinden
attackedBy(wolf(), 3)
units.target = nil
wow.state.feignDeath = true
combatEnds()
wow.state.feignDeath = false
expect("Totstellen zählt nicht", goal.progress, 2)
attackedBy(wolf(), 3)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 1856)
units.target = nil
combatEnds()
expect("Verschwinden zählt nicht", goal.progress, 2)

-- Aggro abgenommen: Gegner lebt, kämpft mit jemand anderem, Spieler noch im Kampf
attackedBy(wolf(), 3)
units.targettarget = { name = "Helfer" }
tick(1)
expect("noch nicht bestätigt", goal.progress, 2)
tick(1.5)
expect("Aggro abgenommen", goal.progress, 3)
combatEnds()
expect("je Kampf einmal", goal.progress, 3)

-- Der eigene Begleiter hat die Aggro: kein Weglaufen
units.pet = { name = "Wolfsjunges", playerControlled = true }
mob = attackedBy(wolf(), 3)
units.targettarget = units.pet
tick(3)
expect("Begleiter zählt nicht", goal.progress, 3)
mob.dead = true
Escape.Check()
combatEnds()
expect("Begleiter tötet den Gegner", goal.progress, 3)
units.pet = nil

-- Ein zweiter Gegner greift noch an: noch nicht entkommen
local first = attackedBy(wolf(), 3)
local second = wolf()
units.nameplate2, units.nameplate2target = second, me
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
units.targettarget = { name = "Helfer" }
tick(3)
expect("zweiter Gegner noch dran", goal.progress, 3)
first.dead, second.dead = true, true
Escape.Check()
units.nameplate2, units.nameplate2target = nil, nil
combatEnds()
expect("beide tot", goal.progress, 3)

-- Debug-Zustand lesbar, keine Fehler
expect("Zustand ohne Kampf", Escape.Snapshot().fighting, false)
expect("keine Lua-Fehler", #wow.errors, 0)
