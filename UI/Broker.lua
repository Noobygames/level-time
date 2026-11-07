-- Datentext für Leisten wie Titan Panel, ElvUI oder Bazooka über LibDataBroker.
-- Das Addon bringt die Bibliothek nicht selbst mit: Sie wird genutzt, wenn ein anderes Addon sie
-- geladen hat (beim Login sind alle Addons geladen). Ohne sie bleibt der Datentext einfach aus.
-- Text: Spielzeit und XP/h im Bereich des Fensters; Tooltip: alle eingeschalteten Werte.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience

local Broker = {}
ns.Broker = Broker

local UPDATE_INTERVAL = 1  -- Sekunden
local TEXT_SEPARATOR = " - "  -- "|" ist in WoW-Texten ein Steuerzeichen

local dataObject  -- nil, solange keine LibDataBroker verfügbar ist
local library     -- die geladene LibDataBroker

local function brokerText()
  local scope = ns.db.windowScope
  if not Stats.IsOpen(scope) then return L.INSTANCE_NONE end
  local seconds = Stats.GetSeconds(scope)
  local text = seconds and Format.Duration(seconds) or "..."
  local rate = Experience.IsLeveling() and Experience.GetRatePerHour(scope)
  if rate then
    text = text .. TEXT_SEPARATOR .. Format.Number(rate) .. " " .. L.ROW_XP_RATE
  end
  return text
end

-- Zeigt eine Leiste den Datentext? (Roadmap 396) Anzeigen hören über CallbackHandler auf
-- "LibDataBroker_AttributeChanged" (alle), "..._LevelTimer[_text]" (dieses Objekt) oder "...__text" (dieses Feld);
-- LibDataBroker-1.1 legt sie in library.callbacks.events ab. Unbekannter Aufbau: lieber aktualisieren.
local GENERIC_EVENT = "LibDataBroker_AttributeChanged"
local OWN_EVENT = GENERIC_EVENT .. "_LevelTimer"
local TEXT_EVENT = GENERIC_EVENT .. "__text"

local function listening(name, handlers)
  if type(handlers) ~= "table" or next(handlers) == nil or type(name) ~= "string" then return false end
  return name == GENERIC_EVENT or name == TEXT_EVENT or name:sub(1, #OWN_EVENT) == OWN_EVENT
end

function Broker.HasDisplay()
  local events = type(library) == "table" and type(library.callbacks) == "table" and library.callbacks.events
  if type(events) ~= "table" then return true end
  for name, handlers in pairs(events) do
    if listening(name, handlers) then return true end
  end
  return false
end

local function showTooltip(tooltip)
  local scope = ns.db.windowScope
  local open = Stats.IsOpen(scope)
  tooltip:AddLine(ns.DISPLAY_NAME)
  for _, stat in ipairs(ns.STAT_LINES) do
    if ns.IsStatShown(stat, ns.db) then
      for _, row in ipairs(stat.rows) do
        tooltip:AddDoubleLine(L[row.label], open and row.value(scope) or "-", 1, 0.82, 0, 1, 1, 1)
      end
    end
  end
  tooltip:AddLine(" ")
  tooltip:AddLine(L.TOOLTIP_LEFT, 0.7, 0.7, 0.7)
  tooltip:AddLine(L.TOOLTIP_SHIFT_LEFT, 0.7, 0.7, 0.7)
  tooltip:AddLine(L.TOOLTIP_RIGHT, 0.7, 0.7, 0.7)
end

-- Klicks wie beim Minimap-Button
local function onClick(_, mouseButton)
  if mouseButton == "RightButton" then
    ns.Set("showTimer", not ns.db.showTimer)
  elseif IsShiftKeyDown() then
    ns.ToggleHistory()
  else
    ns.ToggleOptions()
  end
end

-- Text nur setzen, wenn er sich geändert hat (jede Zuweisung löst bei LibDataBroker Callbacks aus)
function Broker.Refresh()
  if not dataObject then return end
  local text = brokerText()
  if dataObject.text ~= text then dataObject.text = text end
end

-- Jede Sekunde, aber nur mit Datentext und einer Leiste, die ihn zeigt
local function tick()
  if Broker.HasDisplay() then Broker.Refresh() end
end

ns.OnLogin(function()
  local broker = LibStub and LibStub("LibDataBroker-1.1", true)
  if not broker or dataObject then return end
  library = broker
  dataObject = broker:NewDataObject("LevelTimer", {
    type = "data source",
    label = ns.DISPLAY_NAME,
    icon = ns.Widgets.ICON,
    text = "...",
    OnClick = onClick,
    OnTooltipShow = showTooltip,
  })
  ns.RefreshTasks()  -- die Aufgabe läuft erst mit Datentext
end)

ns.Every(UPDATE_INTERVAL, tick, function() return dataObject ~= nil end)
