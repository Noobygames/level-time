-- Quest-Markierung: Symbol über der Namensplakette von Questzielen, weg wenn das Ziel erfüllt ist.
local QuestMarks = addon.QuestMarks

local related = {}
local plates = { nameplate1 = CreateFrame("Frame"), nameplate2 = CreateFrame("Frame") }
local bar = CreateFrame("Frame")
bar:SetHeight(12)
plates.nameplate1.UnitFrame = { healthBar = bar }
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
C_QuestLog = { UnitIsRelatedToActiveQuest = function(unit) return related[unit] or false end }


wow.login({ level = 10 })
expectTrue("verfügbar", QuestMarks.IsAvailable())

-- Mit dem Zeiger auf die Plakette: Marke ist ein Kind-Frame der Plakette (parent bei CreateFrame)
local created = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent then created[parent] = frame end
  return frame
end

related.nameplate1 = true
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("aus: keine Markierung", created[plates.nameplate1], nil)

addon.Set("questMarks", true)
wow.update(1.1)
local mark = created[plates.nameplate1]
expectTrue("an: Markierung erstellt", mark ~= nil)
expect("Markierung sichtbar", mark:IsShown(), true)
expect("etwas höher als der Lebensbalken", mark:GetHeight(), 18)
local point = mark._points[#mark._points]
expect("links vom Lebensbalken: Anker", point[1], "RIGHT")
expect("links vom Lebensbalken: Bezug", point[2], bar)
expect("links vom Lebensbalken: Seite", point[3], "LEFT")
expect("Abstand", point[4], -5)
mark._points = { { "unverändert" } }
wow.update(1.1)
expect("gleicher Balken: nicht neu verankert", mark._points[1][1], "unverändert")
bar:SetHeight(20)
wow.update(1.1)
expect("folgt dem Balken", mark:GetHeight(), 30)
bar:SetHeight(12)

-- Nicht zugehörig: nichts
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
expect("kein Questziel: keine Markierung", created[plates.nameplate2], nil)

-- Ziel erfüllt: das Spiel meldet false, Markierung weg
related.nameplate1 = false
wow.update(1.1)
expect("Ziel erfüllt: Markierung weg", mark:IsShown(), false)
related.nameplate1 = true
wow.update(1.1)
expect("Quest wieder offen: Markierung da", mark:IsShown(), true)

-- Geheimer Rückgabewert: keine Markierung, kein Fehler
issecretvalue = function(value) return value == "geheim" end
related.nameplate1 = "geheim"
wow.update(1.1)
expect("geheim: Markierung weg", mark:IsShown(), false)
issecretvalue = nil
related.nameplate1 = true

-- Plakette verschwindet
wow.fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
expect("Plakette weg: Markierung versteckt", mark:IsShown(), false)

-- Größe
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
addon.Set("questMarkScale", 2)
expect("Größe", mark:GetScale(), 2)

-- Ausschalten
addon.Set("questMarks", false)
expect("aus: Markierung weg", mark:IsShown(), false)
expect("Fehler?", #wow.errors, 0)
