-- Zusammenfassung beim Level-Up mit den Werten des abgeschlossenen Levels:
-- Chatzeile für sich selbst (Einstellung levelUpSummary) und optional als Ansage an
-- Gruppe oder Gilde (Einstellung levelUpAnnounce = "off" | "party" | "guild").
-- Kein /sagen: das verlangt außerhalb von Instanzen eine Hardware-Eingabe, die ein Level-Up nicht hat
-- (Einstellungs-Migration v4 setzt alte "say"-Werte auf "off").
-- Läuft in OnLevelCompleted, also bevor die Zähler für das neue Level zurückgesetzt werden.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience

local LevelUpSummary = {
  ANNOUNCE_OFF = "off",
  ANNOUNCE_PARTY = "party",
  ANNOUNCE_GUILD = "guild",
}
ns.LevelUpSummary = LevelUpSummary


local function summaryText(completedLevel)
  local seconds = Stats.GetSeconds(Stats.LEVEL)
  -- Bedarf des alten Levels; Zeit wie im Fenster (ohne AFK, wenn eingestellt)
  local rate = Experience.RecordRate({ xp = Experience.XpMaxOf(completedLevel), seconds = seconds, counters = Stats.Snapshot(Stats.LEVEL) })
  return string.format(L.LEVEL_UP_SUMMARY,
    completedLevel + 1,
    completedLevel,
    seconds and Format.Duration(seconds) or "?",
    Stats.GetTotalKills(Stats.LEVEL),
    Stats.Get(Stats.LEVEL, Stats.DEATHS),
    rate and Format.Number(rate) or "-")
end

-- Ansage: Chat-Art passend zur Einstellung, nil wenn man nicht in Gruppe bzw. Gilde ist (Lib/GroupChat.lua)
local GroupChat = ns.GroupChat

local function announceChannel(target)
  if target == LevelUpSummary.ANNOUNCE_GUILD then return GroupChat.GuildChannel() end
  if target == LevelUpSummary.ANNOUNCE_PARTY then return GroupChat.PartyChannel() end
  return nil
end

local chatLocked = GroupChat.Locked

local function announce(text)
  local target = ns.db.levelUpAnnounce
  local chatType = announceChannel(target)
  if not chatType or chatLocked() then
    ns.Debug("announce", "skipped: target %s, channel %s, lockdown %s", target, chatType, chatLocked())
    return
  end
  ns.Debug("announce", "sending to %s", chatType)
  GroupChat.Send(text, chatType)
end

-- Fehlersuche (/lt debug levelup): Zusammenfassung des laufenden Levels, als wäre es geschafft.
-- Sendet nichts, sondern nennt nur den Kanal.
function LevelUpSummary.Preview()
  local text = summaryText(ns.level)
  ns.Print(text)
  local target = ns.db.levelUpAnnounce
  ns.DebugPrint("announce", "preview: target %s, channel %s, lockdown %s",
    target, announceChannel(target), chatLocked())
end

ns.OnLevelCompleted(function(completedLevel)
  local text = summaryText(completedLevel)
  if ns.db.levelUpSummary then ns.Print(text) end
  announce(text)
end)

-- Zuwachs (Leben, Mana, Werte) als eigene Chatzeile kurz nach der Zusammenfassung
ns.LevelGains.OnReady(function(_, gains)
  if gains and ns.db.levelUpGains then ns.Print(table.concat(ns.LevelGains.Lines(gains), "  |  ")) end
end)
