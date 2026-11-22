-- Live-Tracker für Dungeon- und Raid-Runs (Roadmap 493, Einstellung showRunTracker, Standard an): eine Karte
-- (Lib/Card.lua), nur solange die Uhr des Instanz-Laufs läuft. Titel = Instanz, große Zeile = Laufzeit und Abstand
-- zur Bestzeit beim letzten Boss (Format.SplitDelta: Theme good = schneller, bad = langsamer), Text = Bossliste
-- (Haken, Split und Abstand zum Split der Bestzeit; ">" = nächster Boss; Rar-Bosse und besiegte Rare mit "Rar", nie
-- im Balken), Beute-Symbole des nächsten Bosses (Assist/BossLoot.lua, mit Item-Tooltip) und Kills, Tode, XP/h; Balken = besiegte Bosse; im
-- Symbolfeld das Porträt des nächsten Bosses
-- (Lib/CreatureModel.lua, nur mit NPC-ID). Vergleich = schnellster abgeschlossener Lauf derselben Instanz und Route;
-- Zeiten ab der ersten Bewegung (InstanceRuns.lua).
-- Position und Größe über Lib/Frames.lua (Id "dungeonRun", im Edit-Modus mit Beispiel-Lauf). Aktualisiert einmal je
-- Sekunde, solange die Einstellung an ist. Linksklick (ohne Ziehen) öffnet den Dungeon-Recap mit dem Zwischenstand
-- (LT-405), der Tooltip sagt das.
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
local LOOT_ICON_SIZE = 16
-- Beispiel für den Edit-Modus: Todesminen (Classic-Bossliste; ohne Liste nur Zeit und Werte)
local SAMPLE_MAP, SAMPLE_DIFFICULTY = 36, 1
local SAMPLE_SECONDS = 1458

local ROW_SPACING = 4  -- Abstand zwischen den Bossreihen (DESIGN.md: 4er-Raster)
local COLLAPSE_ABOVE_BOSSES = 8  -- mehr Bosse: nur besiegte und der nächste, der Rest als "+N weitere"
local PORTRAIT_SIZE = 48  -- Porträt des nächsten Bosses größer als das Standard-Symbol einer Karte
-- X: diesen Lauf nicht mehr zeigen (dismissedRun = Startzeit des Laufs); ganz abschalten: showRunTracker
local dismissedRun
local card = ns.Card.Create(ns.GlobalName("DungeonRun"), { iconSize = PORTRAIT_SIZE, bodySpacing = ROW_SPACING, onClose = function()
  local records = ns.History and ns.characterKey and ns.History.GetInstanceLog(ns.characterKey)
  dismissedRun = records and records[1] and records[1].time
  ns.InstanceRunTracker.Refresh()
end })
ns.Widgets.EnableItemLinks(card.frame)  -- Beute-Symbole des nächsten Bosses mit Item-Tooltip
-- Stern an unbestätigter Beute: Erklärzeile im Item-Tooltip
card.frame:SetScript("OnHyperlinkEnter", function(self, link)
  GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
  GameTooltip:SetHyperlink(link)
  if ns.BossLoot.IsUnverifiedLink(link) then ns.UnverifiedHint.AddLine(GameTooltip) end
  GameTooltip:Show()
end)
local previewing = false
local cachedBest = {}  -- Bestzeit zum offenen Lauf: { key, record }
local portrait  -- Porträt des nächsten Bosses, beim ersten Bedarf angelegt
local bossCount, expanded = 0, true  -- zuletzt gezeigter Lauf (für Layout())

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

local function tableIndex(list, value)
  for index, entry in ipairs(list) do
    if entry == value then return index end
  end
end

-- Kompakt: besiegte Bosse und der nächste, der Rest als "+N weitere" (lines[i] gehört zu list[i])
local function compact(lines, nextID, list)
  if not nextID then return lines end
  local result, hidden = {}, 0
  for index, line in ipairs(lines) do
    if index <= (tableIndex(list, nextID)) then result[#result + 1] = line else hidden = hidden + 1 end
  end
  if hidden > 0 then
    result[#result + 1] = Theme.Hex("muted") .. "   " .. string.format(L.DUNGEON_RUN_MORE_BOSSES, hidden) .. "|r"
  end
  return result
end

-- Zeilen der Bossliste, Abstand zur Bestzeit beim zuletzt besiegten Boss (nil ohne Vergleich) und nächster Boss
local function bossLines(record, best)
  local list = InstanceBosses.RunList(record)
  if not list then bossCount, expanded = 0, true return {}, nil, nil end
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
  bossCount, expanded = #list, #list <= COLLAPSE_ABOVE_BOSSES
  if not expanded then lines = compact(lines, nextID, list) end
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
    CreatureModel.AddBorder(portrait)
  end
  portrait:SetShown(npcID ~= nil)
  CreatureModel.Set(portrait, npcID)
end

-- Fußzeile nur, sobald ein Wert über 0 liegt (nil sonst)
local function footer(record)
  local rate = record.seconds > 0 and record.xp * SECONDS_PER_HOUR / record.seconds or 0
  if record.counters.kills <= 0 and record.counters.deaths <= 0 and rate <= 0 then return nil end
  return Theme.Hex("muted") .. string.format(L.DUNGEON_RUN_TRACKER_FOOTER, record.counters.kills,
    record.counters.deaths, Format.Number(rate)) .. "|r"
end

function InstanceRunTracker.Refresh()
  if not ns.db then return end
  local record, best = currentAndBest()
  if not record or not (previewing or ns.db.showRunTracker) or (not previewing and record.time == dismissedRun) then
    card.frame:Hide()
    return
  end
  local lines, delta, nextID = bossLines(record, best)
  local npcID = nextID and InstanceBosses.NpcID(nextID)
  local loot = nextID and ns.BossLoot.IconLinks(ns.BossLoot.ForBoss(npcID, record.mapID, nextID), LOOT_ICON_SIZE)
  if loot then lines[#lines + 1] = loot end
  lines[#lines + 1] = footer(record)  -- nil = keine Zeile
  local timeText = Format.Duration(InstanceRuns.Seconds(record))
  if delta then timeText = timeText .. "  " .. string.format(L.DUNGEON_RUN_VS_BEST, Format.SplitDelta(delta)) end
  -- icon = Platzhalter, das Porträt liegt deckend darüber
  card.Set({ color = { Theme.RGB("accent") }, title = record.name or "?", body = table.concat(lines, "\n"),
    time = true, timeText = timeText, icon = npcID and CreatureModel.FALLBACK_ICON or nil })
  showPortrait(npcID)
  -- Balken = Fortschritt ohne Rar-Bosse ("3/7")
  local done, required = InstanceBosses.Progress(record)
  card.SetFraction(done and required > 0 and done / required or 0)
  card.frame:Show()
end

-- Aufbau des Trackers (Boss-Anzahl, ausgeklappt?, Reihenabstand, Porträtrahmen); für Tests und Checks
function InstanceRunTracker.Layout()
  return { bosses = bossCount, expanded = expanded, rowSpacing = ROW_SPACING,
    collapseAbove = COLLAPSE_ABOVE_BOSSES, portraitBorder = portrait and portrait.border and true or false }
end

-- Test-Zugriff: die Karte (frame.title/.body/.time) und das Porträt des nächsten Bosses (nil = nie gebraucht)
function InstanceRunTracker.Card()
  return card, portrait
end

ns.Frames.Register({
  id = "dungeonRun", frame = card.frame, label = "EDIT_FRAME_DUNGEON_RUN", default = DEFAULT_POS,
  settingsPage = "OPTIONS_PAGE_DUNGEON_RUNS", clickable = true, dragWhenUnlocked = true,
  actionsTip = function() return L.DUNGEON_RUN_TRACKER_CLICK_TIP end,
  preview = function(on)
    previewing = on and true or false
    InstanceRunTracker.Refresh()
  end,
  hide = function()
    ns.Set("showRunTracker", false)
  end,
})

-- Linksklick: Recap des offenen Laufs; nach Frames.Register, weil das OnDragStart setzt (ein Ziehen ist kein Klick)
local dragged = false
card.frame:HookScript("OnDragStart", function() dragged = true end)
card.frame:HookScript("OnMouseUp", function(_, mouseButton)
  local wasDragged = dragged
  dragged = false
  if mouseButton ~= "LeftButton" or wasDragged or previewing or (ns.EditMode and ns.EditMode.IsActive()) then return end
  ns.DungeonRecapWindow.Show()
end)

ns.Every(1, InstanceRunTracker.Refresh, function(db) return db.showRunTracker end)
ns.RegisterApply(InstanceRunTracker.Refresh)
