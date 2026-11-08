-- Level Time Goals, Roadmap 295: Gold verdienen (Einnahmen von Level Time) und Gold besitzen (Bestand).
local Goals = streamGoal.Goals
local L = streamGoal.L
local GOLD = 10000

wow.state.money = 5 * GOLD
wow.login({ level = 20 })

local function earn(copper)
  wow.state.money = wow.state.money + copper
  wow.fire("PLAYER_MONEY")
  wow.runTimers()
end

SlashCmdList.STREAMGOAL("add gold 10")
local earnGoal = Goals.Active()[1]
expect("Gold-Art", earnGoal.kind, "gold")
expect("verdienen ist Standard", earnGoal.params.mode, "earn")
expect("Ziel in Kupfer", earnGoal.target, 10 * GOLD)
expect("beginnt bei 0", earnGoal.progress, 0)
expect("Titel", Goals.Title(earnGoal), string.format(L.SG_GOAL_GOLD_EARN, 10))
expect("Stand in Gold", Goals.CountText(earnGoal), "0" .. addon.L.UNIT_GOLD_SHORT .. " / 10" .. addon.L.UNIT_GOLD_SHORT)

SlashCmdList.STREAMGOAL("add gold 8 own")
local ownGoal = Goals.Active()[2]
expect("besitzen", ownGoal.params.mode, "own")
expect("Bestand beim Anlegen", ownGoal.progress, 5 * GOLD)
expectNear("Anteil vom Bestand", Goals.Fraction(ownGoal), 5 / 8)

local goal, err = Goals.Create("gold", { mode = "own" }, 3)
expect("schon besessen", goal, nil)
expect("Meldung schon erreicht", err, L.SG_ERR_ALREADY_REACHED)
expect("0 Gold", select(1, Goals.Create("gold", {}, 0)), nil)

earn(2 * GOLD)
expect("Einnahme zählt", earnGoal.progress, 2 * GOLD)
expect("Bestand folgt", ownGoal.progress, 7 * GOLD)

-- Ausgaben senken den Bestand, nicht die Einnahmen
wow.state.money = wow.state.money - 3 * GOLD
wow.fire("PLAYER_MONEY")
expect("Ausgabe ändert Einnahmen nicht", earnGoal.progress, 2 * GOLD)
expect("Bestand sinkt", ownGoal.progress, 4 * GOLD)

earn(4 * GOLD)
expect("Bestand erreicht", ownGoal.status, Goals.DONE)
earn(4 * GOLD)
expect("Einnahmen erreicht", earnGoal.status, Goals.DONE)

-- Formular: Gold und Art
SlashCmdList.STREAMGOAL("")
expectTrue("Kachel Gold", wow.click(L.SG_KIND_GOLD))
expectTrue("Art umschalten", wow.click(L.SG_FORM_GOLD_EARN))
local form = streamGoal.Manager
expect("gewählte Art", form.SelectedKind(), "gold")
form.FormWidget("amount"):SetText("50")
expectTrue("Hinzufügen", wow.click(L.SG_FORM_ADD))
local formGoal = Goals.Active()[1]
expect("aus dem Formular", formGoal.kind, "gold")
expect("Art aus der Auswahl", formGoal.params.mode, "own")
expect("Ziel aus dem Feld", formGoal.target, 50 * GOLD)
