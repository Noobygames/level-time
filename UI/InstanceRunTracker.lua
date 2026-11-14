-- Live-Tracker für Dungeon- und Raid-Runs (Roadmap 493, Einstellung showRunTracker, Standard an): eine Karte
-- (Lib/Card.lua), nur solange die Uhr des Instanz-Laufs läuft. Titel = Instanz, große Zeile = Laufzeit und Abstand
-- zur Bestzeit beim letzten Boss (Format.SplitDelta: Theme good = schneller, bad = langsamer), Text = Bossliste
-- (Haken, Split und Abstand zum Split der Bestzeit; ">" = nächster Boss; Rar-Bosse und besiegte Rare mit "Rar", nie
-- im Balken) und Kills, Tode, XP/h; Balken = besiegte Bosse; im Symbolfeld das Porträt des nächsten Bosses
-- (Lib/CreatureModel.lua, nur mit NPC-ID). Vergleich = schnellster abgeschlossener Lauf derselben Instanz und Route;
-- Zeiten ab der ersten Bewegung (InstanceRuns.lua).
-- Position und Größe über Lib/Frames.lua (Id "dungeonRun", im Edit-Modus mit Beispiel-Lauf). Aktualisiert einmal je
-- Sekunde, solange die Einstellung an ist.
-- shortcut: die Bossliste ist ein Text ohne Spalten; bei Bedarf eigene Zeilen wie in der Split-Liste.
local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local Format = ns.Format
local InstanceBosses = ns.InstanceBosses
local InstanceRuns = ns.InstanceRuns
local CreatureModel = ns.CreatureModel

ns.RegisterDefaults({
  settings = {
    showRunTracker = true,
  },
})

local InstanceRunTracker = {}
ns.InstanceRunTracker = InstanceRunTracker

local DEFAULT_POS = { "TOPRIGHT", "TOPRIGHT", -220, -220 }
local CHECK_MARK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t"
local NEXT_MARK = ">"
local SECONDS_PER_HOUR = 3600
-- Beispiel für den Edit-Modus: Todesminen (Classic-Bossliste; ohne Liste nur Zeit und Werte)
local SAMPLE_MAP, SAMPLE_DIFFICULTY = 36, 1
local SAMPLE_SECONDS = 1458

local card = ns.Card.Create(ns.GlobalName("DungeonRun"))
local previewing = false
local cachedBest = {}  -- Bestzeit zum offenen Lauf: { key, record }
local portrait  -- Porträt des nächsten Bosses, beim ersten Bedarf angelegt

-- Erste n Bosse der Liste als bosses/splits-Text (Beispiel-Lauf)
local function sampleRecord(splits)
  local list = InstanceBosses.List(SAMPLE_MAP, SAMPLE_DIFFICULTY) or {}
  local ids = {}
  for index = 1, math.min(#splits, #list) do ids[index] = list[index] end
  return {
    name = L.DUNGEON_RUN_SAMPLE_NAME, mapID = SAMPLE_MAP, difficultyID = SAMPLE_DIFFICULTY, seconds = SAMPLE_SECONDS,
    bosses = #ids > 0 and table.concat(ids, ",") or nil,
    splits = #ids > 0 and table.concat(splits, ",", 1, #ids) or nil,
    xp = 9200, counters = { kills = 58, deaths = 1 },
  }
end

-- Offener Lauf (nur mit laufender Uhr) und seine Bestzeit; zwischengespeichert, bis sich das Instanz-Journal ändert
local function currentAndBest()
  if previewing then return sampleRecord({ 192, 588, 860, 1197 }), sampleRecord({ 220, 631, 902, 1334 }) end
  if not ns.Instances.IsRunning() then return nil end
  local records = ns.History.GetInstanceLog(ns.characterKey)
  local record = records[1]
  if not (record and record.isCurrent) then return nil end
  -- Bosse im Schlüssel: der erste Kill legt den Flügel fest und damit den Vergleichslauf
  local key = record.time .. "#" .. (record.bosses or "") .. "#" .. ns.Journal.Revision("instanceLog")
  if cachedBest.key ~= key then
    cachedBest.key, cachedBest.record = key, InstanceRuns.Reference(records, 1, InstanceRuns.BEST)
  end
  return record, cachedBest.record
end

-- Name mit "Rar"-Markierung
local function rareName(name)
  return name .. " " .. Theme.Hex("accent") .. L.DUNGEON_RUNS_RARE_TAG .. "|r"
end

-- Zeilen der Bossliste, Abstand zur Bestzeit beim zuletzt besiegten Boss (nil ohne Vergleich) und nächster Boss
local function bossLines(record, best)
  local list = InstanceBosses.List(record.mapID, record.difficultyID)
  if not list then return {}, nil, nil end
  local killed, splits = InstanceBosses.Killed(record), InstanceRuns.Splits(record)
  local bestSplits = best and InstanceRuns.Splits(best) or {}
  local lines, nextID, lastDelta, lastSplit = {}, nil, nil, -1
  for _, id in ipairs(list) do
    local name = InstanceBosses.Name(id) or "?"
    if InstanceBosses.IsRare(id) then name = rareName(name) end
    if killed[id] then
      local split, line = splits[id], CHECK_MARK .. " " .. name
      if split then
        line = line .. "  " .. Format.Duration(split)
        if bestSplits[id] then
          line = line .. "  " .. Format.SplitDelta(split - bestSplits[id])
          if split > lastSplit then lastSplit, lastDelta = split, split - bestSplits[id] end
        end
      end
      lines[#lines + 1] = line
    elseif not nextID and not InstanceBosses.IsRare(id) then
      nextID = id
      lines[#lines + 1] = Theme.Hex("accent") .. NEXT_MARK .. " " .. name .. "|r"
    else
      lines[#lines + 1] = Theme.Hex("muted") .. "   " .. name .. "|r"
    end
  end
  -- Rare ohne Encounter: nur besiegte, unter der Bossliste
  for _, rare in ipairs(InstanceBosses.Rares(record)) do
    lines[#lines + 1] = CHECK_MARK .. " " .. rareName(rare.name or tostring(rare.npcID)) .. "  "
      .. Format.Duration(rare.seconds)
  end
  return lines, lastDelta, nextID
end

-- Porträt des nächsten Bosses über dem Kartensymbol (nur mit NPC-ID)
local function showPortrait(npcID)
  if not npcID and not portrait then return end
  if not portrait then
    portrait = CreatureModel.Create(card.frame, 1)
    portrait:SetAllPoints(card.frame.icon)
  end
  portrait:SetShown(npcID ~= nil)
  CreatureModel.Set(portrait, npcID)
end

local function footer(record)
  local rate = record.seconds > 0 and record.xp * SECONDS_PER_HOUR / record.seconds or 0
  return Theme.Hex("muted") .. string.format(L.DUNGEON_RUN_TRACKER_FOOTER, record.counters.kills,
    record.counters.deaths, Format.Number(rate)) .. "|r"
end

function InstanceRunTracker.Refresh()
  if not ns.db then return end
  local record, best = currentAndBest()
  if not record or not (previewing or ns.db.showRunTracker) then
    card.frame:Hide()
    return
  end
  local lines, delta, nextID = bossLines(record, best)
  local npcID = nextID and InstanceBosses.NpcID(nextID)
  lines[#lines + 1] = footer(record)
  local timeText = Format.Duration(InstanceRuns.Seconds(record))
  if delta then timeText = timeText .. "  " .. string.format(L.DUNGEON_RUN_VS_BEST, Format.SplitDelta(delta)) end
  card.Set({ color = { Theme.RGB("accent") }, title = record.name or "?", body = table.concat(lines, "\n"),
    time = true, timeText = timeText, icon = npcID and CreatureModel.FALLBACK_ICON or nil })  -- Platzhalter, das Porträt liegt deckend darüber
  showPortrait(npcID)
  -- Balken = Fortschritt ohne Rar-Bosse ("3/7")
  local done, required = InstanceBosses.Progress(record)
  card.SetFraction(done and required > 0 and done / required or 0)
  card.frame:Show()
end

-- Test-Zugriff: die Karte (frame.title/.body/.time) und das Porträt des nächsten Bosses (nil = nie gebraucht)
function InstanceRunTracker.Card()
  return card, portrait
end

ns.Frames.Register({
  id = "dungeonRun", frame = card.frame, label = "EDIT_FRAME_DUNGEON_RUN", default = DEFAULT_POS,
  settingsPage = "OPTIONS_PAGE_DUNGEON_RUNS", clickable = true,
  preview = function(on)
    previewing = on and true or false
    InstanceRunTracker.Refresh()
  end,
  hide = function()
    ns.Set("showRunTracker", false)
  end,
})

ns.Every(1, InstanceRunTracker.Refresh, function(db) return db.showRunTracker end)
ns.RegisterApply(InstanceRunTracker.Refresh)
