-- Graphen der Historie: Reiter "Graphen" mit einem Unterreiter je Diagramm.
-- Daten aus Analysis.lua, Darstellung aus Charts.lua.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Analysis = ns.Analysis
local Charts = ns.Charts

local GROUP = "HISTORY_TAB_CHARTS"

-- Level mit einer Nachkommastelle ("23.4"), ganze Level ohne
local function formatLevel(level)
  if level == math.floor(level) then return tostring(level) end
  return string.format("%.1f", level)
end

-- kind: Säulen (Verlauf), Rangliste oder Heatmap (data liefert dann ein Raster mit total); axis beschriftet bei
-- Säulen den Maximalwert
local function createChartView(tab, kind, data, axis)
  local function create(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)

    local chart
    if kind == "column" then
      chart = Charts.CreateColumnChart(frame, width, height)
    elseif kind == "heatmap" then
      chart = Charts.CreateHeatmap(frame, width, height)
    elseif kind == "line" then
      chart = Charts.CreateLineChart(frame, width, height)
    else
      chart = Charts.CreateRankChart(frame, width, height)
    end
    chart:SetPoint("TOPLEFT")

    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER")

    function frame:Render(characterKey)
      local items = data(characterKey)
      local hasData
      if kind == "heatmap" then hasData = items.total > 0 else hasData = #items > 0 end  -- line: Liste der Reihen
      emptyText:SetText(L.CHART_EMPTY)
      emptyText:SetShown(not hasData)
      chart:SetShown(hasData)
      if hasData and kind == "line" then
        chart:SetSeries(items, axis, formatLevel)
      elseif hasData then
        chart:SetItems(items, axis)
      end
    end

    return frame
  end

  return { tab = tab, group = GROUP, Create = create }
end

local AddView = ns.HistoryWindow.AddView
AddView(createChartView("CHART_LEVEL_TIME", "column", Analysis.TimePerLevel, Format.Duration))
AddView(createChartView("CHART_LEVEL_XP_RATE", "column", Analysis.XpRatePerLevel, Format.Number))
AddView(createChartView("CHART_KILLS_PER_DAY", "column", Analysis.KillsPerDay, tostring))
AddView(createChartView("CHART_TOP_KILLS", "rank", Analysis.TopKills))
AddView(createChartView("CHART_DEATH_CAUSES", "rank", Analysis.DeathCauses))
AddView(createChartView("CHART_ZONE_XP_RATE", "rank", Analysis.XpRatePerZone))
AddView(createChartView("CHART_PLAYTIME_PER_DAY", "column", Analysis.PlayTimePerDay, Format.Duration))
AddView(createChartView("CHART_PLAYTIME_PER_WEEK", "column", Analysis.PlayTimePerWeek, Format.Duration))
AddView(createChartView("CHART_SESSION_XP", "column", Analysis.SessionXpTimeline, Format.Number))
AddView(createChartView("CHART_PLAY_HOURS", "heatmap", Analysis.PlayHours))
AddView(createChartView("CHART_PROGRESS", "line", ns.ProgressCurve.Series, Format.Duration))
