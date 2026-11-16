-- Einheitlicher Hinweis "für Forever unbestätigt" in Tooltips (LT-64): ein Sternchen hinter jeder nur aus Classic
-- übernommenen Zeile (Fähigkeiten-Tipps, Bossbeute) und darunter eine Erklärzeile, beides in der Hinweisfarbe
-- Theme "muted". Ob eine Zeile unbestätigt ist, entscheidet das jeweilige Modul (nur im Forever-Client).
local _, ns = ...
local L = ns.L

local UnverifiedHint = {}
ns.UnverifiedHint = UnverifiedHint

-- Sternchen zum Anhängen an eine Zeile
function UnverifiedHint.Mark()
  return ns.Theme.Hex("muted") .. "*|r"
end

-- Erklärzeile (der Text beginnt selbst mit dem Sternchen)
function UnverifiedHint.AddLine(tooltip)
  local r, g, b = ns.Theme.RGB("muted")
  tooltip:AddLine(L.FOREVER_UNVERIFIED, r, g, b, true)
end
