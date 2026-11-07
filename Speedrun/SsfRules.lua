-- SSF-Regelhelfer für Speedruns (speedrun.com WoW Classic SSF, SUNLA-Regeln): zeigt nur an, verbietet nichts.
-- Kategorie (Einstellung ssfCategory): "off", "1-20" oder "1-60". Je Kategorie:
--   restedBars  Grenze für verbrauchte Ruhe-XP in Balken (1 Balken = XP eines Levels); gezählt wird der
--               Ruhe-Bonus (Zähler xpRested) je Level geteilt durch die XP dieses Levels
--   logouts     höchstens so viele echte Logouts (/reload zählt nicht, Session.LoggedInAfterLogout)
-- Dazu die neuen Instanzen der letzten Stunde (InstanceLimit.lua), eine Uhr mit Datum für den VOD-Nachweis
-- und ein Hinweis beim Öffnen von Handel, Post oder Auktionshaus (für SSF nicht erlaubt).
-- Die Grenzen stammen aus der Roadmap (Regeln der Kategorie); im Spiel nicht prüfbar, daher nur Anzeige.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats

local SsfRules = {
  OFF = "off",
  CATEGORIES = {
    ["1-20"] = { level = 20, restedBars = 2, logouts = 3 },
    ["1-60"] = { level = 60, restedBars = 40, logouts = 5 },
  },
  ORDER = { "1-20", "1-60" },
}
ns.SsfRules = SsfRules

local CLOCK_FORMAT = "%Y-%m-%d %H:%M:%S"
local OVER_LIMIT_COLOR = "|cffff4040"
local NEAR_LIMIT_COLOR = "|cffffd040"
local OK_COLOR = "|cff40ff40"

-- Fenster, die SSF verbieten: Event -> Text des Hinweises
local FORBIDDEN_WINDOWS = {
  TRADE_SHOW = "SSF_TRADE",
  MAIL_SHOW = "SSF_MAIL",
  AUCTION_HOUSE_SHOW = "SSF_AUCTION",
}

function SsfRules.GetCategory()
  return SsfRules.CATEGORIES[ns.db.ssfCategory]
end

-- Verbrauchte Ruhe-XP in Balken bis zum Level der Kategorie: abgeschlossene Level plus das laufende
function SsfRules.RestedBars(category)
  local bars = 0
  for level, record in pairs(ns.character.levelHistory) do
    local rested = record.counters and record.counters[Stats.XP_RESTED]
    if level < category.level and rested and record.xp and record.xp > 0 then
      bars = bars + rested / record.xp
    end
  end
  local xpMax = UnitXPMax("player")
  if ns.level < category.level and xpMax and xpMax > 0 then
    bars = bars + Stats.Get(Stats.LEVEL, Stats.XP_RESTED) / xpMax
  end
  return bars
end

function SsfRules.GetLogouts()
  return ns.character.ssfLogouts or 0
end

-- Farbe gegen eine Grenze: rot darüber, gelb genau an der Grenze, sonst grün
local function limitColor(value, limit)
  if value > limit then return OVER_LIMIT_COLOR end
  if value == limit then return NEAR_LIMIT_COLOR end
  return OK_COLOR
end

-- Zeilen für die Split-Liste: { Bezeichnung, Wert, Zusatz }; leer ohne Kategorie
function SsfRules.BuildLines()
  local category = SsfRules.GetCategory()
  if not category then return {} end
  local bars = SsfRules.RestedBars(category)
  local logouts = SsfRules.GetLogouts()
  local instances, limit = ns.InstanceLimit.GetHourCount(), ns.InstanceLimit.GetLimit()
  return {
    { string.format(L.SSF_TITLE, ns.db.ssfCategory), "", "" },
    { L.SSF_RESTED, string.format("%.1f / %d", bars, category.restedBars),
      bars > category.restedBars and (OVER_LIMIT_COLOR .. L.SSF_OVER .. "|r") or "" },
    { L.SSF_LOGOUTS, limitColor(logouts, category.logouts) .. logouts .. " / " .. category.logouts .. "|r", "" },
    { L.SSF_INSTANCES, limitColor(instances, limit) .. instances .. " / " .. limit .. "|r", "" },
    { L.SSF_CLOCK, date(CLOCK_FORMAT), "" },
  }
end

-- Echter Logout seit dem letzten Login: zählen (Session.lua entscheidet beim Login, daher danach geladen)
ns.OnLogin(function()
  if ns.Session.LoggedInAfterLogout() then
    ns.character.ssfLogouts = SsfRules.GetLogouts() + 1
    ns.Debug("ssf", "logout counted (%s)", ns.character.ssfLogouts)
  end
end)

local function onForbiddenWindow(event)
  if not SsfRules.GetCategory() then return end
  ns.Debug("ssf", "forbidden window %s", event)
  ns.Alerts.Notify({ title = L.SSF_WARNING_TITLE, text = L[FORBIDDEN_WINDOWS[event]] }, ns.Alerts.WARNING_COLOR)
end

for event in pairs(FORBIDDEN_WINDOWS) do
  ns.RegisterEvent(event, function() onForbiddenWindow(event) end)
end
