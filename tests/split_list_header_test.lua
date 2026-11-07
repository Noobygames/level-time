-- UX 215: Split-Liste mit Kopfzeile "Level / Zeit / ±" (abschaltbar) und Tooltip am Fenster
local L = addon.L
wow.login({ level = 12, playedSeconds = 300 })
addon.Set("showSplitList", true)
wow.update(1)

local function hasText(text)
  return wow.findFrame(function(f) return f._text == text and f:IsShown() end) ~= nil
end
local muted = addon.Theme.Hex("muted")
expectTrue("Kopf Level", hasText(muted .. L.SPLIT_LIST_HEADER_LEVEL .. "|r"))
expectTrue("Kopf Zeit", hasText(muted .. L.SPLIT_LIST_HEADER_TIME .. "|r"))
expectTrue("Kopf ±", hasText(muted .. L.SPLIT_LIST_HEADER_DELTA .. "|r"))
local height = LevelTimerSplits:GetHeight()

addon.Set("splitListHeader", false)
wow.update(1)
expect("ohne Kopf: kein Kopf", hasText(muted .. L.SPLIT_LIST_HEADER_LEVEL .. "|r"), false)
expectTrue("eine Zeile niedriger", LevelTimerSplits:GetHeight() < height)

-- Tooltip nennt den Vergleich
LevelTimerSplits._scripts.OnEnter(LevelTimerSplits)
local lines = GameTooltip._lines or {}
expectTrue("Tooltip erklärt", lines[1] ~= nil and lines[1]:find(L.COMPARE_CHOICE_BEST, 1, true) ~= nil)

expect("keine Fehler", #wow.errors, 0)
