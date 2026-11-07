-- Arten der großen Einblendungen (UI/Alerts.lua) für Stream-Momente: Level-Up, Rare- und Elite-Kill, epische Beute,
-- Beinahe-Tod, Quest fertig. Jede Art ist einzeln schaltbar (Einstellungen alert*), alle aus.
-- Quellen: LevelGains.OnReady und neue Journal-Einträge (Journal.OnAdd), kein eigenes Event-Parsing.
-- In Dungeons und Raids ist fast jeder Gegner Elite: dort keine Elite-Einblendung (IsInInstance).
-- In Raids ist epische Beute normal: dort keine Beute-Einblendung.
local _, ns = ...
local L = ns.L
local Alerts = ns.Alerts
local Journal = ns.Journal
local Classification = ns.Classification

local EPIC_QUALITY = 4
local GROUP_INSTANCES = { party = true, raid = true }  -- Instanzarten von IsInInstance mit Elite-Gegnern
local COLORS = Alerts.COLORS

-- Arten: Einstellung, inCombat ("hold" = im Kampf zurückhalten und danach zeigen), Farbe, Symbol (Alerts.ICONS), Text aus einem Wert (Level, Name, Link, Prozent) und Beispielwert
-- für /lt debug alert
Alerts.KINDS = {
  levelUp = { setting = "alertLevelUp", color = COLORS.levelUp, format = "ALERT_LEVEL_UP", inCombat = "hold",
    sample = function() return ns.level + 1 end,
    sampleBody = function() local gains = ns.LevelGains.Sample(); return gains and table.concat(ns.LevelGains.Lines(gains), "\n") end },
  rare = { setting = "alertRareKill", color = COLORS.rare, format = "ALERT_RARE_KILL",
    sample = function() return "Hogger" end },
  elite = { setting = "alertEliteKill", color = COLORS.elite, format = "ALERT_ELITE_KILL",
    sample = function() return "Hogger" end },
  loot = { setting = "alertEpicLoot", color = COLORS.loot, format = "ALERT_EPIC_LOOT",
    sample = function() return "[Thunderfury]" end },
  nearDeath = { setting = "alertNearDeath", color = COLORS.nearDeath, format = "ALERT_NEAR_DEATH",
    sample = function() return 4 end },
  questComplete = { setting = "alertQuestComplete", color = COLORS.quest, format = "ALERT_QUEST_COMPLETE", inCombat = "hold",
    sample = function() return "Hogger" end },
  rareSpotted = { setting = "alertRareSpotted", color = COLORS.rare, format = "ALERT_RARE_SPOTTED",
    sample = function() return "Mor'Ladim" end },
  questObjective = { setting = "alertQuestObjective", color = COLORS.quest, format = "ALERT_QUEST_OBJECTIVE", inCombat = "hold",
    sample = function() return "Hogger: 1/1" end },
}

-- Text und Karte einer Art: im Stil "Banner" als Karte mit Symbol (wie die Hinweise), im Stil "Text" nur als Schrift
local function kindMessage(kind, value, body)
  local message = string.format(L[Alerts.KINDS[kind].format], value)
  return message, Alerts.IsBanner() and { icon = Alerts.ICONS[kind], title = message, body = body } or nil
end

-- Nur, wenn die Art eingeschaltet ist
local function alert(kind, value, body)
  local definition = Alerts.KINDS[kind]
  if not ns.db[definition.setting] then return end
  local message, card = kindMessage(kind, value, body)
  Alerts.Show(message, definition.color, { sound = true, notice = card, combat = definition.inCombat })
end

-- Einblendung einer Art für andere Module (Quest fertig, ...), nur wenn die Art eingeschaltet ist
function Alerts.Raise(kind, value, body)
  alert(kind, value, body)
end

-- Beispiel unabhängig von der Einstellung (Fehlersuche); false bei unbekannter Art
function Alerts.ShowSample(kind)
  local definition = Alerts.KINDS[kind]
  if not definition then return false end
  local body = ns.db.levelUpGains and definition.sampleBody and definition.sampleBody() or nil
  local message, card = kindMessage(kind, definition.sample(), body)
  Alerts.ShowSampleMessage(message, definition.color, card, true)
  return true
end

-- Erst wenn der Zuwachs feststeht (LevelGains), damit die Karte Leben und Werte zeigen kann
ns.LevelGains.OnReady(function(level, gains)
  if ns.db.levelUpWindow then return end  -- das Level-Up-Fenster zeigt dieselben Zuwächse
  local lines = ns.db.levelUpGains and gains and ns.LevelGains.Lines(gains)
  alert("levelUp", level, lines and table.concat(lines, "\n") or nil)
end)

local function instanceType()
  local inInstance, kind = IsInInstance()
  return inInstance and kind or nil
end

local handlers = {
  killLog = function(entry)
    local name = entry.name or L.UNKNOWN_NAME
    if Classification.IsRare(entry.classification) and ns.db.alertRareKill then
      alert("rare", name)
    elseif Classification.IsElite(entry.classification) and not GROUP_INSTANCES[instanceType()] then
      alert("elite", name)
    end
  end,
  lootLog = function(entry)
    if (entry.quality or 0) >= EPIC_QUALITY and instanceType() ~= "raid" then
      alert("loot", entry.link or entry.name or "?")
    end
  end,
  nearDeathLog = function(entry)
    alert("nearDeath", entry.lowestPercent)
  end,
}

Journal.OnAdd(function(logName, entry)
  local handler = handlers[logName]
  if handler then handler(entry) end
end)

-- Vorschau: eine Beispiel-Einblendung mit den aktuellen Einstellungen
local PREVIEW_ORDER = { "levelUp", "rare", "elite", "loot", "nearDeath", "notice" }
local previewIndex = 0

-- Beispiel einer Hinweis-Karte (wie "Taschen fast voll"), ohne Chatzeile
local function showNoticeSample()
  local sample = { icon = Alerts.ICONS.bags, title = L.NOTICE_BAGS, text = L.WARN_BAGS_FULL }
  Alerts.ShowSampleMessage(sample.text, Alerts.WARNING_COLOR, Alerts.NoticeCard(sample))
end

function Alerts.Preview()
  if Alerts.IsEditing() then return end
  previewIndex = previewIndex % #PREVIEW_ORDER + 1
  local kind = PREVIEW_ORDER[previewIndex]
  if kind == "notice" then showNoticeSample() else Alerts.ShowSample(kind) end
end
