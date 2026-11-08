-- Session-Karte in Classic Era: Beinahe-Tode sind dort messbar und stehen in der Karte (W10)
local L = addon.L
local RecapWindow = addon.RecapWindow

local function row(label)
  for _, line in ipairs(RecapWindow.BuildRows()) do
    if line[1] == label then return line[2] end
  end
end

wow.login({ level = 10, xp = 0, xpMax = 1000 })
expectTrue("Era: Beinahe-Tode messbar", addon.NearDeath.IsAvailable())
expect("Era: Beinahe-Tode-Zeile", row(L.ROW_NEAR_DEATHS), "0")
addon.Stats.Increment(addon.Stats.NEAR_DEATHS, 1)
expect("Era: Beinahe-Tod gezählt", row(L.ROW_NEAR_DEATHS), "1")
