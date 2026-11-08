-- Level Time Goals: Debug-Checks für offene Fragen im Spiel laufen mit /lt debug check ohne Lua-Fehler.
local function hasLine(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return line end
  end
end

local CHECKS = { "300.goals.potionSpells", "297.goals.skills", "307.goals.formats", "303.goals.reputation",
  "432.goals.wheel", "439.goals.escape", "439.goals.moments" }

wow.login()
SlashCmdList.LEVELTIMER("debug check")
for _, name in ipairs(CHECKS) do
  local line = hasLine('"name":"' .. name .. '"')
  expectTrue("Prüfung " .. name .. " geschrieben", line ~= nil)
  expect("Prüfung " .. name .. " ohne Fehler", line and line:match('"error":"([^"]*)"'), nil)
end
expect("keine Lua-Fehler", #wow.errors, 0)
