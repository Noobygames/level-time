-- Level Time Goals: Debug-Checks für offene Goals-Prüfungen laufen mit /lt debug check ohne Lua-Fehler.
local function hasLine(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return line end
  end
end

local CHECKS = { "LT114.goals.active", "LT97.goals.achievement", "LT117.goals.packs", "LT158.goals.minimapButton",
  "LT166.goals.wheelState", "LT169.goals.firstRun", "LT148.recap.state" }

wow.login()
streamGoal.Goals.Create("custom", { text = "Test" }, nil, { points = 5 })
SlashCmdList.LEVELTIMER("debug check")
for _, name in ipairs(CHECKS) do
  local line = hasLine('"name":"' .. name .. '"')
  expectTrue("Prüfung " .. name .. " geschrieben", line ~= nil)
  expect("Prüfung " .. name .. " ohne Fehler", line and line:match('"error":"([^"]*)"'), nil)
end
expect("keine Lua-Fehler", #wow.errors, 0)
