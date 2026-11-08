-- Level Time Goals, Roadmap 306/432: Glücksrad als drehendes Rad, landet auf dem gezogenen Eintrag, begrenzte
-- Neuwürfe, Drehen bei Level-Up, ohne Animation sofort.
local Goals = streamGoal.Goals
local Wheel = streamGoal.Wheel
local WheelDisplay = streamGoal.WheelDisplay
local Library = streamGoal.Library
local Pool = streamGoal.Pool
local L = streamGoal.L

local function finishSpin()
  for _ = 1, 100 do
    if not Wheel.IsSpinning() then return end
    wow.update(0.1)
  end
end

-- Winkel: reine Funktionen
local SLICES = WheelDisplay.SLICES
expect("Ruhe: Stück 1 oben", WheelDisplay.SliceAt(0), 1)
expect("eine Stückbreite gegen den Uhrzeigersinn: das letzte Stück oben", WheelDisplay.SliceAt(2 * math.pi / SLICES),
  SLICES)
expect("eine Stückbreite im Uhrzeigersinn: Stück 2 oben", WheelDisplay.SliceAt(-2 * math.pi / SLICES), 2)
for _, case in ipairs({ { 0, 1 }, { 1.3, 7 }, { 5.9, 12 }, { -2, 4 } }) do
  for _, offset in ipairs({ -0.4, 0, 0.4 }) do
    local target = WheelDisplay.TargetRotation(case[1], case[2], SLICES, 3, offset)
    expectTrue("mindestens drei Umdrehungen", target >= case[1] + 3 * 2 * math.pi)
    expectTrue("weniger als vier", target < case[1] + 4 * 2 * math.pi)
    expect("landet auf Stück " .. case[2], WheelDisplay.SliceAt(target), case[2])
  end
end
expect("Auslaufen Start", WheelDisplay.Ease(0), 0)
expect("Auslaufen Ende", WheelDisplay.Ease(1), 1)
expectTrue("schnell los", WheelDisplay.Ease(0.25) > 0.5)

wow.login({ level = 10 })
-- Nur eigene Texte im Rad: alle mitgelieferten aus
for _, item in ipairs(Pool.Items()) do Wheel.SetEnabled(item.key, false) end
for _, text in ipairs({ "Rad A", "Rad B", "Rad C" }) do Library.AddText(text) end
expect("drei Einträge im Rad", #Wheel.Pool(), 3)

SlashCmdList.STREAMGOAL("wheel")
expect("dreht", Wheel.IsSpinning(), true)
expect("Rad am Bildschirm", StreamGoalWheel:IsShown(), true)
expect("noch kein Ziel", #Goals.Active(), 0)
SlashCmdList.STREAMGOAL("wheel")
expect("zweimal gleichzeitig geht nicht", wow.printed[#wow.printed]:find(L.SG_WHEEL_BUSY, 1, true) ~= nil, true)
wow.update(0.5)
expectTrue("dreht sich", WheelDisplay.Rotation() > 0)
finishSpin()
expect("Ergebnis angelegt", #Goals.Active(), 1)
local first = Goals.Active()[1]
expect("aus dem Pool", first.kind, "custom")
expect("Zeiger steht auf dem Ergebnis", WheelDisplay.SliceTitle(WheelDisplay.SliceUnderPointer()), Goals.Title(first))
expect("Karte zeigt Ergebnis", StreamGoalWheelCard.body._text, Goals.Title(first))
expect("Meldung mit Neuwürfen", wow.printed[#wow.printed]:find(string.format(L.SG_CHAT_WHEEL, Goals.Title(first), 2), 1,
  true) ~= nil, true)
wow.runTimers()
expect("Rad verschwindet danach", StreamGoalWheel:IsShown(), false)

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

-- Viele Einträge (mehr als Stücke): das Ergebnis steht trotzdem unter dem Zeiger
for _, item in ipairs(Pool.Items()) do Wheel.SetEnabled(item.key, true) end
for _ = 1, 5 do
  local before = #Goals.Active()
  SlashCmdList.STREAMGOAL("wheel")
  finishSpin()
  local newest = Goals.Active()[#Goals.Active()]
  if #Goals.Active() > before then
    expect("Zeiger auf dem Ergebnis", WheelDisplay.SliceTitle(WheelDisplay.SliceUnderPointer()), Goals.Title(newest))
    Goals.Cancel(newest.id)
  end
end

-- Weniger Bewegung: ohne Animation steht das Ergebnis sofort fest
streamGoal.SetSetting("wheelAnimation", false)
local before = #Goals.Active()
SlashCmdList.STREAMGOAL("wheel")
expect("sofort fertig", Wheel.IsSpinning(), false)
expect("sofort angelegt", #Goals.Active(), before + 1)

-- Leerer Pool
for _, item in ipairs(Pool.Items()) do Wheel.SetEnabled(item.key, false) end
expect("leer", select(2, Wheel.Spin()), L.SG_WHEEL_EMPTY)

-- Edit-Modus: Beispiel-Rad zum Verschieben
addon.EditMode.Enter()
expect("Rad im Edit-Modus", StreamGoalWheel:IsShown(), true)
expectTrue("verschiebbar", addon.EditMode.Overlay(WheelDisplay.FRAME_ID) ~= nil)
addon.EditMode.Leave()
expect("danach weg", StreamGoalWheel:IsShown(), false)
