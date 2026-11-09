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

---------------------------------------------------------------------------
-- UX (G1, G20): Rad über den Fenstern, Ergebnis bleibt stehen, Neu drehen per Knopf und Karte
---------------------------------------------------------------------------
local Manager = streamGoal.Manager
local WheelView = streamGoal.WheelView
for _, goal in ipairs(Goals.Active()) do Goals.Cancel(goal.id) end
for _, item in ipairs(Pool.Items()) do Wheel.SetEnabled(item.key, false) end
for _, item in ipairs(Pool.OwnItems()) do Wheel.SetEnabled(item.key, true) end
streamGoal.SetSetting("wheelAnimation", true)
streamGoal.SetSetting("wheelOnLevelUp", false)
-- Ebene merken (der Stub kennt keine Strata)
for _, frame in ipairs({ StreamGoalWheel, StreamGoalWheelCard }) do
  frame.SetFrameStrata = function(self, strata) self._strata = strata end
end

-- Drehen aus dem offenen Fenster: das Rad liegt über dem Fenster (DIALOG)
wow.runTimers()
Manager.Toggle("wheel")
expect("Reiter Glücksrad offen", Manager.ShownPage(), "wheel")
expect("ohne Ergebnis kein Neu-drehen-Knopf", WheelView.rerollButton:IsShown(), false)
WheelView.spinButton._scripts.OnClick(WheelView.spinButton, "LeftButton")
expect("dreht", Wheel.IsSpinning(), true)
expect("Rad über den Fenstern", StreamGoalWheel._strata, WheelDisplay.SPIN_STRATA)
expect("Fenster bleibt offen", StreamGoalWindow:IsShown(), true)
expect("während des Drehens kein Neu drehen", WheelView.rerollButton:IsShown(), false)
finishSpin()
local result = Goals.Active()[1]
-- Ausblend-Timer dieses Ergebnisses (zuletzt geplant), für die Prüfung nach dem Neu drehen
local hideFirst = wow.timers[#wow.timers]
expect("Ergebnis-Karte sichtbar", StreamGoalWheelCard:IsShown(), true)
expect("Knopf Neu drehen da", WheelView.rerollButton:IsShown(), true)
expect("Knopf zeigt Neuwürfe", WheelView.rerollButton.label._text, string.format(L.SG_WHEEL_REROLL_LEFT, 2))
expectTrue("Knopf mit Tooltip", WheelView.rerollButton._scripts.OnEnter ~= nil)

-- Neu drehen über den Knopf: altes Ergebnis abgebrochen, Zähler sinkt
WheelView.rerollButton._scripts.OnClick(WheelView.rerollButton, "LeftButton")
finishSpin()
expect("altes Ergebnis abgebrochen", result.status, Goals.CANCELLED)
expect("Knopf zählt herunter", WheelView.rerollButton.label._text, string.format(L.SG_WHEEL_REROLL_LEFT, 1))
-- Der Ausblend-Timer des ersten Ergebnisses lässt das neue stehen
hideFirst()
expect("alter Timer blendet neues Ergebnis nicht aus", StreamGoalWheelCard:IsShown(), true)
local printed = #wow.printed
-- Rechtsklick auf die Karte = Neu drehen (letzter Neuwurf)
StreamGoalWheelCard._scripts.OnMouseUp(StreamGoalWheelCard, "RightButton")
finishSpin()
expectTrue("Rechtsklick dreht neu", #wow.printed > printed)
local last = Goals.Active()[1]
expect("Chat ohne Neuwurf-Hinweis bei 0", wow.printed[#wow.printed]:find(string.format(L.SG_CHAT_WHEEL_LAST,
  Goals.Title(last)), 1, true) ~= nil, true)
expect("kein /sg wheel reroll bei 0", wow.printed[#wow.printed]:find("reroll", 1, true), nil)
expect("ohne Neuwürfe kein Knopf", WheelView.rerollButton:IsShown(), false)
expect("Wheel.RerollsLeft 0", Wheel.RerollsLeft(), 0)
wow.runTimers()
expect("Ergebnis nach der Anzeigedauer weg", StreamGoalWheelCard:IsShown(), false)
expect("Rad nach der Anzeigedauer weg", StreamGoalWheel:IsShown(), false)

-- Anzeigedauer 0: Ergebnis bleibt, bis man die Karte anklickt
expect("Standard-Anzeigedauer", StreamGoalDB.settings.wheelResultSeconds, 15)
streamGoal.SetSetting("wheelResultSeconds", 0)
Goals.Cancel(last.id)
Wheel.Spin()
finishSpin()
wow.runTimers()
expect("bleibt stehen", StreamGoalWheelCard:IsShown(), true)
expect("Rad bleibt stehen", StreamGoalWheel:IsShown(), true)
StreamGoalWheelCard._scripts.OnMouseUp(StreamGoalWheelCard, "LeftButton")
expect("Linksklick blendet aus", StreamGoalWheelCard:IsShown(), false)
expect("Rad auch weg", StreamGoalWheel:IsShown(), false)
expect("Ziel bleibt", Goals.Active()[1].status, Goals.ACTIVE)

-- Ungültige gespeicherte Dauer fällt beim Login auf den Standard zurück
StreamGoalDB.settings.wheelResultSeconds = 999
wow.logout()
wow.login()
expect("Dauer bereinigt", StreamGoalDB.settings.wheelResultSeconds, 15)

-- Einstellungen: Knopf Neu drehen und Regler für die Anzeigedauer
streamGoal.Options.Show(streamGoal.SETTINGS_PAGES.WHEEL)
expect("Neu drehen in den Einstellungen", wow.click(L.SG_WHEEL_REROLL), true)
finishSpin()
expectTrue("Regler Anzeigedauer im Suchindex", #streamGoal.Options.builder.Search(L.SG_OPTIONS_WHEEL_RESULT) > 0)

-- Chat-Abstimmung (Roadmap 306)
for _, goal in ipairs(Goals.Active()) do Goals.Cancel(goal.id) end
Wheel.Dismiss()
SlashCmdList.STREAMGOAL("wheel vote 30")
expectTrue("Abstimmung läuft", Wheel.IsVoting())
local vote = Wheel.ActiveVote()
expectTrue("Optionen vorhanden", #vote.options >= 2)
wow.fire("CHAT_MSG_PARTY", "1", "Alice")
wow.fire("CHAT_MSG_GUILD", "!2", "Bob")
wow.fire("CHAT_MSG_WHISPER", "2", "Charlie")
wow.fire("CHAT_MSG_SAY", "2", "Alice") -- Alice ändert Stimme von 1 auf 2
local results, total = Wheel.VoteResults()
expect("3 Stimmen für Option 2", results[2], 3)
expect("0 Stimmen für Option 1", results[1], 0)
expect("insgesamt 3 Stimmen", total, 3)
Wheel.FinishVote()
expect("Abstimmung beendet", Wheel.IsVoting(), false)
expect("Rad dreht sich für Gewinner", Wheel.IsSpinning(), true)
finishSpin()
local won = Goals.Active()[1]
expect("Gewinner entspricht Option 2", Goals.Title(won), streamGoal.Pool.Title(vote.options[2]))

-- Button "Abstimmung" im Reiter Glücksrad
local WheelView = streamGoal.WheelView
expect("Abstimmungs-Button existiert", WheelView.voteButton ~= nil, true)
streamGoal.Manager.Toggle("wheel")
expect("Button beschriftet mit Abstimmung", WheelView.voteButton.label._text, L.SG_WHEEL_VOTE)
WheelView.voteButton._scripts.OnClick(WheelView.voteButton, "LeftButton")
expectTrue("Abstimmung per Button gestartet", Wheel.IsVoting())
WheelView.RenderReroll()
expect("Button beschriftet mit Beenden", WheelView.voteButton.label._text, L.SG_WHEEL_VOTE_FINISH)
WheelView.voteButton._scripts.OnClick(WheelView.voteButton, "LeftButton")
expect("Abstimmung per Button beendet", Wheel.IsVoting(), false)
finishSpin()

