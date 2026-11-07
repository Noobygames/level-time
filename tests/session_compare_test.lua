-- Session-Vergleich beim Login (Roadmap 281): Chatzeile mit Dauer, XP und XP/h-Änderung zur Session davor.
local SessionCompare = addon.SessionCompare
local L = addon.L

local function printedWith(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return line end
  end
end

-- Reine Rechnung: 2 h mit 20k XP (10k XP/h) gegen 1 h mit 8k XP: +25 %
local text = SessionCompare.Text({ seconds = 7200, xp = 20000, counters = {} }, { seconds = 3600, xp = 8000, counters = {} })
expect("Text", text, string.format(L.SESSION_COMPARE, "2h 00m", "20.0k") .. " " .. string.format(L.SESSION_COMPARE_RATE, "+25%"))
expect("ohne vorherige", SessionCompare.Text({ seconds = 600, xp = 0, counters = {} }, nil),
  string.format(L.SESSION_COMPARE, "10m 00s", "0"))

-- Erste Session: keine Zeile
wow.login({ level = 10, xp = 0, xpMax = 100000 })
expect("erste Session: keine Zeile", printedWith(L.SESSION_COMPARE:sub(1, 8)), nil)

-- Session mit 1000 XP in 20 min, ausloggen, lange Pause
wow.advance(1200)
addon.Stats.Increment(addon.Stats.XP_GAINED, 1000)
wow.logout()
wow.advance(3600)
wow.login()
expectTrue("Zeile nach echter Pause", printedWith("1.0k XP") ~= nil)

-- Zweite Session mit doppelter Rate: +100 %
wow.advance(1200)
addon.Stats.Increment(addon.Stats.XP_GAINED, 2000)
wow.logout()
wow.advance(3600)
wow.login()
expectTrue("Vergleich mit der vorherigen", printedWith(string.format(L.SESSION_COMPARE_RATE, "+100%")) ~= nil)

-- /reload (kurze Pause): Session läuft weiter, keine Zeile
local count = #wow.printed
wow.logout()
wow.advance(10)
wow.login()
local newLines = 0
for i = count + 1, #wow.printed do
  if wow.printed[i]:find(string.format(L.SESSION_COMPARE, ".-", ".-"):sub(1, 8), 1, true) then newLines = newLines + 1 end
end
expect("keine Zeile nach /reload", newLines, 0)

-- Einstellung aus
addon.Set("sessionCompareLogin", false)
wow.advance(1200)
wow.logout()
wow.advance(3600)
count = #wow.printed
wow.login()
local found = false
for i = count + 1, #wow.printed do
  if wow.printed[i]:find(string.format(L.SESSION_COMPARE, "", ""):sub(1, 8), 1, true) then found = true end
end
expect("aus: keine Zeile", found, false)
