-- Quest-Fokus (LT-260) in Classic Era: Rechtsklick auf eine Quest im Questlog (Post-Hook auf
-- QuestLogTitleButton_OnClick) fokussiert sie, nochmal Rechtsklick hebt auf; Linksklick und Überschriften nicht.
local QuestFocus = addon.QuestFocus

local offset = { value = 0 }
function FauxScrollFrame_GetOffset() return offset.value end
function QuestLogTitleButton_OnClick() end

wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { questID = 60, title = "Eberjagd" },
}
wow.login({ level = 10 })
addon.Set("questMap", true)

local function title(id, isHeader)
  return { GetID = function() return id end, isHeader = isHeader }
end

QuestLogTitleButton_OnClick(title(2), "LeftButton")
expect("Linksklick: kein Fokus", QuestFocus.Get(), nil)
QuestLogTitleButton_OnClick(title(1, true), "RightButton")
expect("Überschrift: kein Fokus", QuestFocus.Get(), nil)
QuestLogTitleButton_OnClick(title(2), "RightButton")
expect("Rechtsklick: fokussiert", QuestFocus.Get(), 60)
QuestLogTitleButton_OnClick(title(2), "RightButton")
expect("nochmal: aufgehoben", QuestFocus.Get(), nil)

-- Gescrollt: Index = Knopf-ID + Versatz
offset.value = 1
QuestLogTitleButton_OnClick(title(1), "RightButton")
expect("Versatz beachtet", QuestFocus.Get(), 60)
expect("Fehler?", #wow.errors, 0)
