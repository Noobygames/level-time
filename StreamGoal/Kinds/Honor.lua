-- Zielart Ehre (Roadmap 309): N Ehre sammeln. Quelle: CHAT_MSG_COMBAT_HONOR_GAIN in den Formen
-- COMBATLOG_HONORGAIN ("%s stirbt, ehrenhafter Sieg Rang: %s (Geschätzte Ehrenpunkte: %d)"),
-- COMBATLOG_HONORGAIN_NO_RANK (ohne Rang) und COMBATLOG_HONORAWARD ("Euch wurden %d Ehrenpunkte zuerkannt.");
-- gezählt wird die letzte Zahl der Meldung (geschätzte Ehre bei Siegen, Bonusehre bei Zielen und Siegen im
-- Schlachtfeld). Ob Retail die Ehre (dort eine Währung) noch so meldet, ist im Spiel zu prüfen (ManualToCheck 176).
-- params: keine
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Honor = {}
ns.HonorGoals = Honor

local ICON = "Interface\\Icons\\INV_BannerPVP_01"
local FORMATS = { "COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK", "COMBATLOG_HONORAWARD" }

Goals.RegisterKind("honor", {
  label = "SG_KIND_HONOR",
  usage = "SG_USAGE_HONOR",
  color = LT.Theme.COLORS.bad,
  icon = ICON,
  form = { amount = "SG_FORM_AMOUNT" },
  parse = function(args) return {}, tonumber(args[1]) end,
  validate = function(_, target) return Kinds.ValidAmount(target) end,
  title = function(goal) return string.format(L.SG_GOAL_HONOR, goal.target) end,
})

-- Ehre aus einer Meldung (letzte Zahl unter den Argumenten), nil wenn keine Ehre darin steht
local formats
function Honor.Parse(message)
  if type(message) ~= "string" or LT.IsSecret(message) then return nil end
  formats = formats or LT.ChatPatterns.CompileGlobals(FORMATS)
  local args = LT.ChatPatterns.MatchAny(message, formats)
  if not args then return nil end
  local amount
  for _, value in ipairs(args) do amount = tonumber(value) or amount end
  if amount and amount > 0 then return math.floor(amount) end
end

LT.RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", function(message)
  if not ns.db or not Goals.HasActive("honor") then return end
  local amount = Honor.Parse(message)
  if not amount then return end
  ns.Debug("tracking", "honor +%s", amount)
  Goals.Add("honor", function() return true end, amount)
end)
