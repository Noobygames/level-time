-- Level Time Goals: Titel mit Anzahl in Einzahl ("1 Gebiet entdecken") und Mehrzahl ("3 Gebiete entdecken"), in allen
-- vier Sprachen ein eigener _ONE-Text.
local Goals = streamGoal.Goals
local Pool = streamGoal.Pool
local L = streamGoal.L

wow.login({ level = 10 })

-- { Art, params, Locale-Key }
local CASES = {
  { "kills", { source = "any" }, "SG_GOAL_KILLS_ANY" },
  { "kills", { source = "pve" }, "SG_GOAL_KILLS_PVE" },
  { "kills", { source = "pvp" }, "SG_GOAL_KILLS_PVP" },
  { "bgwin", {}, "SG_GOAL_BGWIN_ANY" },
  { "quest", { mode = "count" }, "SG_GOAL_QUESTS" },
  { "explore", { mode = "count" }, "SG_GOAL_EXPLORE" },
  { "dungeon", {}, "SG_GOAL_BOSS_ANY" },
  { "honor", {}, "SG_GOAL_HONOR" },
  { "gold", { mode = "earn" }, "SG_GOAL_GOLD_EARN" },
}
for _, case in ipairs(CASES) do
  local kind, params, key = case[1], case[2], case[3]
  if Goals.IsAvailable(kind) then
    local one = Goals.Create(kind, Goals.CopyFlat(params), 1)
    expect(key .. " Einzahl", one and Goals.Title(one), string.format(L[key .. "_ONE"], 1))
    local many = Goals.Create(kind, Goals.CopyFlat(params), 3)
    expect(key .. " Mehrzahl", many and Goals.Title(many), string.format(L[key], 3))
    for _, goal in ipairs(Goals.Active()) do Goals.Cancel(goal.id) end
  end
end

-- Jede Sprache hat eine eigene Einzahl, die sich (wo die Sprache es verlangt) von der Mehrzahl unterscheidet
for _, code in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  local texts = streamGoal.locales[code]
  expectTrue(code .. ": Gebiet in Einzahl", texts.SG_GOAL_EXPLORE_ONE ~= texts.SG_GOAL_EXPLORE)
  expectTrue(code .. ": Quest in Einzahl", texts.SG_GOAL_QUESTS_ONE ~= texts.SG_GOAL_QUESTS)
end
expect("deutsch", streamGoal.locales.deDE.SG_GOAL_EXPLORE_ONE, "%d Gebiet entdecken")

-- Mitgelieferter Bingo-/Rad-Eintrag "1 Gebiet entdecken"
expect("Pool-Eintrag Einzahl", Pool.Title(Pool.Get("p:explore1")), string.format(L.SG_GOAL_EXPLORE_ONE, 1))

-- Checkliste mit einem Punkt
local list = Goals.Create("checklist", { text = "Nur eins" })
if list then expect("Checkliste Einzahl", Goals.Title(list), string.format(L.SG_GOAL_CHECKLIST_ONE, 1)) end
