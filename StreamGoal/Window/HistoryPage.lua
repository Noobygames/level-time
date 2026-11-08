-- Reiter "Historie" im Fenster /sg: Tabelle aller abgeschlossenen, abgebrochenen und gescheiterten Ziele (TableView von
-- Level Time: Filter, Sortieren, CSV-Export); Summenzeile mit Erreichten und Punkten. Aufräumen steht unter
-- Einstellungen > Daten (Knopf "Einstellungen" auf dieser Seite).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Manager = ns.Manager
local L = ns.L
local Format = LT.Format
local Theme = LT.Theme

local STATUS_LABELS = { [Goals.DONE] = "SG_STATUS_DONE", [Goals.CANCELLED] = "SG_STATUS_CANCELLED",
  [Goals.FAILED] = "SG_STATUS_FAILED" }
local STATUS_COLORS = { [Goals.DONE] = Theme.COLORS.text, [Goals.CANCELLED] = Theme.COLORS.muted,
  [Goals.FAILED] = Theme.COLORS.bad }

local page = Manager.AddPage({
  key = "history", label = "SG_TAB_HISTORY", settingsPage = ns.SETTINGS_PAGES.DATA,
  render = function() Manager.history:Render(nil, false, true) end,
})

local function characterName(goal)
  local ok, name = pcall(LT.History.DisplayName, goal.character)
  return ok and name or tostring(goal.character)
end

local function duration(goal)
  return math.max(0, (goal.finishedAt or goal.createdAt) - goal.createdAt)
end

local historyColumns = {
  { header = "SG_COL_DATE", width = 80, align = "LEFT",
    value = function(g) return date("%Y-%m-%d", g.finishedAt) end, sort = function(g) return g.finishedAt end },
  { header = "SG_COL_GOAL", width = 210, align = "LEFT", value = function(g) return Goals.Title(g) end },
  { header = "SG_COL_CHARACTER", width = 100, align = "LEFT", value = characterName },
  { header = "SG_COL_PROGRESS", width = 70,
    value = function(g) return Goals.HasCount(g) and Goals.CountText(g) or "" end,
    sort = function(g) return Goals.Fraction(g) end },
  { header = "SG_COL_RESULT", width = 70, align = "LEFT", value = function(g) return L[STATUS_LABELS[g.status]] end },
  { header = "SG_COL_TIME", width = 70, value = function(g) return Format.Duration(duration(g)) end, sort = duration },
}

local historyView = LT.TableView.Create({
  tab = "SG_TAB_HISTORY",
  columns = historyColumns,
  records = function() return Goals.History() end,
  footer = function(_, records)
    local done = 0
    for _, goal in ipairs(records) do
      if goal.status == Goals.DONE then done = done + 1 end
    end
    return { string.format(L.SG_HISTORY_FOOTER, done, #records, ns.Rewards.TotalPoints()) }
  end,
  rowColor = function(goal) return STATUS_COLORS[goal.status] or Theme.COLORS.muted end,
})
Manager.history = historyView.Create(page, Manager.PAGE_WIDTH, Manager.PAGE_HEIGHT)
