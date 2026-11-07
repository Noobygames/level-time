-- Erfassung: macht aus Spielereignissen Fortschritt der Ziele.
--   level  Level Time meldet jedes Level (OnLevelStarted) und beim Login den Stand
--   kills  neue Kill-Einträge im Journal von Level Time (PvE: Gegner mit XP, PvP: ehrenhafte Siege)
--   item   eigene Beute und selbst hergestellte Items im Chat (alle Qualitäten), gezählt wird die Anzahl
--   bgwin  Ende eines Schlachtfelds: GetBattlefieldWinner() gegen die eigene Fraktion
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local ChatPatterns = LT.ChatPatterns

local Tracking = {}
ns.Tracking = Tracking

local BATTLEGROUND = "pvp"      -- IsInInstance-Typ von Schlachtfeldern (Arenen heißen "arena")
local DRAW = 255                -- GetBattlefieldWinner bei Unentschieden
local WINNER_BY_FACTION = { Horde = 0, Alliance = 1 }

local function inBattleground()
  local _, instanceType = IsInInstance()
  return instanceType == BATTLEGROUND
end

---------------------------------------------------------------------------
-- Level
---------------------------------------------------------------------------
LT.OnLogin(function() Goals.Set("level", LT.level) end)
LT.OnLevelStarted(function(level) Goals.Set("level", level) end)

---------------------------------------------------------------------------
-- Kills: Kill-Einträge des Journals (kind = "pve" oder "pvp")
---------------------------------------------------------------------------
LT.Journal.OnAdd(function(logName, entry)
  if logName ~= "killLog" then return end
  local atBattleground = inBattleground()
  Goals.Add("kills", function(goal)
    local params = goal.params
    return (params.source == "any" or params.source == entry.kind)
      and (not params.battleground or atBattleground)
  end, 1)
end)

---------------------------------------------------------------------------
-- Items: eigene Beute (wie Loot.lua von Level Time, aber jede Qualität) und Hergestelltes ("Ihr stellt her: ...");
-- LOOT_ITEM_PUSHED_SELF (Kauf, Post, Quest) zählt nicht
---------------------------------------------------------------------------
-- Speziellere Formate (mit Anzahl) zuerst, sonst passt das einfache Format auch auf sie
local lootFormats = ChatPatterns.CompileGlobals({
  "LOOT_ITEM_SELF_MULTIPLE",
  "LOOT_ITEM_CREATED_SELF_MULTIPLE",
  "LOOT_ITEM_SELF",
  "LOOT_ITEM_CREATED_SELF",
}, ChatPatterns.LINK)

if #lootFormats > 0 then
  LT.RegisterEvent("CHAT_MSG_LOOT", function(message)
    if LT.IsSecret(message) then return end
    local args = ChatPatterns.MatchAny(message, lootFormats)
    if not args then return end
    local itemId = tonumber(args[1]:match("item:(%d+)"))
    if not itemId then return end
    local quantity = tonumber(args[2]) or 1
    Goals.Add("item", function(goal) return goal.params.itemId == itemId end, quantity)
  end)
end

---------------------------------------------------------------------------
-- Schlachtfeld-Siege
-- Das Ergebnis steht erst am Ende fest und wird von mehreren Ereignissen gemeldet (Retail/Forever:
-- PVP_MATCH_COMPLETE, alle Clients: UPDATE_BATTLEFIELD_SCORE); pro Schlachtfeld zählt es einmal.
---------------------------------------------------------------------------
-- Sieger: GetBattlefieldWinner (nil bis das Ergebnis feststeht, wie bei Blizzards eigenen Schlachtfeld-Filtern).
-- C_PvP.GetActiveMatchWinner liefert immer eine Zahl (laut Dokumentation nie nil) und taugt deshalb nicht als
-- "fertig"-Prüfung; es gilt nur, wo es GetBattlefieldWinner nicht gibt. nil = läuft noch oder keine API.
local function getWinner()
  if GetBattlefieldWinner then return GetBattlefieldWinner() end
  if C_PvP and C_PvP.GetActiveMatchWinner then return C_PvP.GetActiveMatchWinner() end
  return nil
end

local function playerWon(winner)
  if winner == DRAW then return false end
  return winner == WINNER_BY_FACTION[UnitFactionGroup("player")]
end

-- "Schon gezählt" steht in StreamGoalDB, damit ein /reload im fertigen Schlachtfeld nichts doppelt zählt
local function checkBattlegroundResult()
  if not ns.db or ns.db.bgResultCounted or not inBattleground() then return end
  local winner = getWinner()
  if winner == nil then return end  -- läuft noch
  ns.db.bgResultCounted = true
  ns.Debug("tracking", "battleground over: winner %s, faction %s, won %s", winner, UnitFactionGroup("player"),
    playerWon(winner))
  if not playerWon(winner) then return end
  local name = (GetInstanceInfo()) or ""
  Goals.Add("bgwin", function(goal)
    local wanted = goal.params.battleground
    return not wanted or name:lower():find(wanted:lower(), 1, true) ~= nil
  end, 1)
end

LT.RegisterEvent("PVP_MATCH_COMPLETE", checkBattlegroundResult)
LT.RegisterEvent("UPDATE_BATTLEFIELD_SCORE", checkBattlegroundResult)
-- Neues Schlachtfeld: Ergebnis wieder zählen (erst außerhalb zurücksetzen, damit ein Reload mitten drin nichts doppelt zählt)
LT.RegisterEvent("PLAYER_ENTERING_WORLD", function()
  if ns.db and not inBattleground() then ns.db.bgResultCounted = false end
end)
