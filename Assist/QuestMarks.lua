-- Quest-Markierung: ein Symbol links vom Lebensbalken der Namensplakette von Gegnern und NPCs, die zu einer aktiven Quest gehören
-- (Einstellung questMarks im Reiter "Komfort", aus; Größe questMarkScale).
-- Quelle ist C_QuestLog.UnitIsRelatedToActiveQuest (in WoW Forever im Spiel geprüft: true für Questmobs, false
-- nach erfülltem Ziel). Der Wert kann in eingeschränkten Situationen geheim sein; dann gibt es keine Markierung.
-- Welt-Objekte (Kisten, Hebel) haben keine Einheit und keine Namensplakette und lassen sich so nicht markieren.
-- Stand am Symbol (Roadmap 340, Einstellung questMarkProgress, aus): "3/8" des ersten offenen Ziels aus den
-- Questzeilen des Einheiten-Tooltips (Lib/QuestTooltip.lua, je Name zwischengespeichert).
-- Neu bewertet wird bei neuen Plaketten und nach Änderungen am Questlog (QUEST_LOG_UPDATE,
-- UNIT_QUEST_LOG_CHANGED für den Spieler; gebündelt), dazu alle SAFETY_SECONDS als Sicherheitsnetz.
local _, ns = ...

local QuestMarks = {}
ns.QuestMarks = QuestMarks

QuestMarks.MIN_SCALE = 0.5  -- Grenzen des Reglers in den Einstellungen
QuestMarks.MAX_SCALE = 2

local ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local FALLBACK_SIZE = 16  -- ohne erkennbaren Lebensbalken (andere Plakettenaddons)
local GAP = 5               -- Abstand zum Lebensbalken
local BAR_HEIGHT_FACTOR = 1.5  -- das Bild hat Rand, daher etwas höher als der Balken, damit es so hoch wirkt
local PROGRESS_GAP = 2       -- Abstand des Zählers links vom Symbol
local DIRTY_SECONDS = 0.5    -- Questlog-Änderungen gebündelt verarbeiten
local SAFETY_SECONDS = 5     -- Sicherheitsnetz ohne Ereignis (z.B. Ziel per Gruppe erfüllt)

local marks = {}  -- [Namensplakette] = Markierungs-Frame
local anchors = {}  -- [Markierung] = { target, height } der letzten Verankerung (Anker setzen löst ein Layout aus)
local units = {}  -- sichtbare Namensplaketten: [Einheit] = Plakette (beim Entfernen liefert das Spiel sie evtl. nicht mehr)

-- Ohne C_QuestLog.UnitIsRelatedToActiveQuest (Classic Era/TBC) markiert es gelernte Questgegner (QuestMobs.lua)
function QuestMarks.HasClientQuestUnits()
  return C_QuestLog ~= nil and C_QuestLog.UnitIsRelatedToActiveQuest ~= nil
end

function QuestMarks.IsAvailable()
  return C_NamePlate ~= nil and C_NamePlate.GetNamePlateForUnit ~= nil
end

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Gelernter Gegner eines offenen Ziels: nur lebende Nicht-Spieler
local function isLearnedQuestUnit(unit)
  if readable(UnitIsPlayer(unit)) ~= false or readable(UnitIsDead(unit)) ~= false then return false end
  return ns.QuestMobs.IsQuestMob(readable(UnitName(unit)))
end

-- Nach erfülltem Ziel meldet das Spiel selbst false (im Spiel geprüft)
local function isQuestUnit(unit)
  if not QuestMarks.HasClientQuestUnits() then return isLearnedQuestUnit(unit) end
  local related = C_QuestLog.UnitIsRelatedToActiveQuest(unit)
  return not ns.IsSecret(related) and related == true
end

-- Zähler fürs Symbol: aus dem Tooltip, sonst aus dem gelernten Ziel im Questlog
local function progressText(unit)
  return ns.QuestTooltip.ProgressText(unit) or ns.QuestMobs.ProgressOf(readable(UnitName(unit))) or ""
end

function QuestMarks.CurrentScale()
  local scale = ns.db and ns.db.questMarkScale or 1
  return math.max(QuestMarks.MIN_SCALE, math.min(QuestMarks.MAX_SCALE, scale))
end

-- Lebensbalken der Blizzard-Plakette (Retail/Forever: im Container, ältere Clients: direkt am UnitFrame)
local function asTable(value)
  return type(value) == "table" and value or nil
end

local function healthBarOf(plate)
  local unitFrame = asTable(plate.UnitFrame)
  if not unitFrame then return nil end
  local container = asTable(unitFrame.HealthBarsContainer)
  return asTable(container and container.healthBar) or asTable(unitFrame.healthBar)
end

-- Symbol links vom Lebensbalken, etwas höher als dieser (Größe-Regler skaliert darüber hinaus);
-- ohne Balken über der Plakette. Läuft bei jedem Update, weil sich der Balken ändern kann (z.B. Ziel größer);
-- neu verankert wird nur, wenn sich Balken oder Höhe geändert haben.
local function layout(mark, plate)
  local bar = healthBarOf(plate)
  local height = bar and bar:GetHeight()
  if not (type(height) == "number" and not ns.IsSecret(height) and height > 0) then height = nil end
  local target = height and bar or plate
  local anchor = anchors[mark]
  if anchor and anchor.target == target and anchor.height == height then return end
  anchors[mark] = { target = target, height = height }
  mark:ClearAllPoints()
  if height then
    mark:SetSize(height * BAR_HEIGHT_FACTOR, height * BAR_HEIGHT_FACTOR)
    mark:SetPoint("RIGHT", bar, "LEFT", -GAP, 0)
  else
    mark:SetSize(FALLBACK_SIZE, FALLBACK_SIZE)
    mark:SetPoint("BOTTOM", plate, "TOP", 0, GAP)
  end
end

local function markFor(plate)
  if marks[plate] then return marks[plate] end
  local mark = CreateFrame("Frame", nil, plate)
  mark.icon = mark:CreateTexture(nil, "OVERLAY")
  mark.icon:SetAllPoints()
  mark.icon:SetTexture(ICON)
  mark.progress = mark:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  mark.progress:SetPoint("RIGHT", mark, "LEFT", -PROGRESS_GAP, 0)
  mark:SetScale(QuestMarks.CurrentScale())
  marks[plate] = mark
  return mark
end

local function plateOf(unit)
  local plate = C_NamePlate.GetNamePlateForUnit(unit)
  if not plate or (plate.IsForbidden and plate:IsForbidden()) then return nil end
  return plate
end

local function update(unit)
  local plate = plateOf(unit)
  if not plate then return end
  local show = ns.db and ns.db.questMarks and isQuestUnit(unit)
  if show then
    local mark = markFor(plate)
    layout(mark, plate)
    local progress = ns.db.questMarkProgress and progressText(unit) or ""
    ns.Widgets.SetTextIfChanged(mark.progress, progress)
    mark:Show()
  elseif marks[plate] then
    marks[plate]:Hide()
  end
end

local function refreshAll()
  if not (ns.db and ns.db.questMarks) or not QuestMarks.IsAvailable() then return end
  for unit in pairs(units) do update(unit) end
end

ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
  if not unit or not QuestMarks.IsAvailable() then return end
  units[unit] = plateOf(unit)
  update(unit)
end)

ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
  if not unit then return end
  local plate = units[unit]
  units[unit] = nil
  if plate and marks[plate] then marks[plate]:Hide() end
end)

-- Questziele ändern sich beim Spielen (Ziel erfüllt, Quest abgegeben): nach Questlog-Änderungen neu bewerten
local dirty = false
local sinceSafety = 0
local function markDirty() dirty = true end
ns.RegisterEvent("QUEST_LOG_UPDATE", markDirty)
ns.RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player", markDirty)

ns.Every(DIRTY_SECONDS, function(elapsed)
  sinceSafety = sinceSafety + elapsed
  if not dirty and sinceSafety < SAFETY_SECONDS then return end
  dirty, sinceSafety = false, 0
  refreshAll()
end, function(db) return db.questMarks end)

ns.RegisterApply(function(db)
  for _, mark in pairs(marks) do mark:SetScale(QuestMarks.CurrentScale()) end
  for _, mark in pairs(marks) do if not db.questMarks then mark:Hide() end end
  refreshAll()
end)
