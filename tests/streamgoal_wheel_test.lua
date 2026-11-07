-- Level Time Goals, Roadmap 306: Glücksrad mit Dreh-Animation, begrenzte Neuwürfe, Drehen bei Level-Up.
local Goals = streamGoal.Goals
local Wheel = streamGoal.Wheel
local L = streamGoal.L

local function finishSpin()
  for _ = 1, 20 do
    if not Wheel.IsSpinning() then return end
    wow.runTimers()
  end
end

wow.login({ level = 10 })
streamGoal.Bingo.POOL = {}
StreamGoalDB.settings.bingoTexts = { "Rad A", "Rad B", "Rad C" }

SlashCmdList.STREAMGOAL("wheel")
expect("dreht", Wheel.IsSpinning(), true)
expect("Karte der Animation", StreamGoalWheelCard:IsShown(), true)
SlashCmdList.STREAMGOAL("wheel")
expect("zweimal gleichzeitig geht nicht", wow.printed[#wow.printed]:find(L.SG_WHEEL_BUSY, 1, true) ~= nil, true)
finishSpin()
expect("Ergebnis angelegt", #Goals.Active(), 1)
local first = Goals.Active()[1]
expect("aus dem Pool", first.kind, "custom")
expect("Karte zeigt Ergebnis", StreamGoalWheelCard.body._text, Goals.Title(first))
expect("Meldung mit Neuwürfen", wow.printed[#wow.printed]:find(string.format(L.SG_CHAT_WHEEL, Goals.Title(first), 2), 1,
  true) ~= nil, true)

-- Neu drehen: altes Ergebnis abgebrochen, Neuwürfe zählen herunter
SlashCmdList.STREAMGOAL("wheel reroll")
finishSpin()
expect("altes abgebrochen", first.status, Goals.CANCELLED)
expect("neues Ergebnis", #Goals.Active(), 1)
SlashCmdList.STREAMGOAL("wheel reroll")
finishSpin()
SlashCmdList.STREAMGOAL("wheel reroll")
expect("keine Neuwürfe mehr", wow.printed[#wow.printed]:find(L.SG_WHEEL_NO_REROLLS, 1, true) ~= nil, true)

-- Bei Level-Up drehen
streamGoal.SetSetting("wheelOnLevelUp", true)
wow.levelUp(11)
finishSpin()
expect("Level-Up dreht", #Goals.Active(), 2)
