-- Graphen der Historie: Reiter "Graphen" mit einem Unterreiter je Diagramm.
-- Daten aus Analysis.lua, Darstellung aus Charts.lua. Unter jedem Diagramm eine Hinweiszeile (<Reiter-Key>_HINT): was
-- die Achsen zeigen und was hervorgehoben ist, wie der Hinweis unter den Tabellen.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Analysis = ns.Analysis
local Charts = ns.Charts
local Widgets = ns.Widgets

local GROUP = "HISTORY_TAB_CHARTS"
local HINT_LINES = 2          -- so viele Zeilen hat der Hinweis höchstens (umgebrochen)
local HINT_LINE_HEIGHT = 12
local HINT_GAP = 4            -- Abstand zwischen Diagramm und Hinweis

-- Level mit einer Nachkommastelle ("23.4"), ganze Level ohne
local function formatLevel(level)
  if level == math.floor(level) then return tostring(level) end
  return string.format("%.1f", level)
end

-- kind: Säulen (Verlauf), Rangliste oder Heatmap (data liefert dann ein Raster mit total); axis beschriftet bei
-- Säulen den Maximalwert. revision (optional, z.B. Journal.RevisionOf(log)): die Daten hängen nur vom Journal ab; dann wird
-- nur bei geändertem Stand, Charakter oder Sprache neu ausgewertet statt jede Sekunde (Ranglisten über das ganze
-- Kill-Journal), Roadmap 213.
local function createChartView(tab, kind, data, axis, revision)
  local function create(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetTextColor(unpack(Widgets.COLORS.muted))
    hint:SetPoint("BOTTOMLEFT", 0, 0)
    hint:SetPoint("BOTTOMRIGHT", 0, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetMaxLines(HINT_LINES)
    frame.hint = hint  -- Tests
    height = height - HINT_LINES * HINT_LINE_HEIGHT - HINT_GAP

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

    local lastKey
    function frame:Render(characterKey)
      Widgets.SetTextIfChanged(hint, L[tab .. "_HINT"])
      if revision then
        local key = table.concat({ characterKey or "", ns.db and ns.db.language or "", revision() }, ":")
        if key == lastKey then return end
        lastKey = key
      end
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
AddView(createChartView("CHART_TOP_KILLS", "rank", Analysis.TopKills, nil, ns.Journal.RevisionOf("killLog")))
AddView(createChartView("CHART_DEATH_CAUSES", "rank", Analysis.DeathCauses, nil, ns.Journal.RevisionOf("deathLog")))
AddView(createChartView("CHART_ZONE_XP_RATE", "rank", Analysis.XpRatePerZone))
AddView(createChartView("CHART_PLAYTIME_PER_DAY", "column", Analysis.PlayTimePerDay, Format.Duration))
AddView(createChartView("CHART_PLAYTIME_PER_WEEK", "column", Analysis.PlayTimePerWeek, Format.Duration))
AddView(createChartView("CHART_SESSION_XP", "column", Analysis.SessionXpTimeline, Format.Number))
AddView(createChartView("CHART_PLAY_HOURS", "heatmap", Analysis.PlayHours))
AddView(createChartView("CHART_PROGRESS", "line", ns.ProgressCurve.Series, Format.Duration))
