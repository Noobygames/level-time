-- Fortschrittskurve (Roadmap 279): Level (mit Bruchteil) über der Gesamtspielzeit (/played) für den gewählten
-- Charakter, bis zu OTHER_CHARACTERS weitere Charaktere mit den meisten Leveln und den Vergleich der Splits
-- (Splits.GetReference: Bestzeit je Level, PB oder gewählter Lauf) übereinander.
-- Punkte je Charakter: Erreichen von Level L+1 bei levelHistory[L].totalPlayed; fehlt /played (Level vor der
-- Installation oder ohne Server-Antwort), wird von der letzten bekannten Stelle mit den Level-Zeiten weitergezählt.
-- Laufendes Level: eingeloggt bei /played jetzt mit XP-Anteil, sonst bei der letzten bekannten Stelle plus der Zeit
-- auf dem Level (Stand beim Logout, ohne Bruchteil).
-- Der Vergleich hat nur Zeiten je Level: er beginnt bei seinem ersten Level an derselben Stelle wie der gewählte
-- Charakter (sonst bei 0) und läuft mit den Zeiten weiter.
local _, ns = ...
local History = ns.History

local ProgressCurve = {}
ns.ProgressCurve = ProgressCurve

ProgressCurve.OTHER_CHARACTERS = 3
local REFERENCE_COLOR = { 1, 1, 1 }
local FALLBACK_COLOR = { 0.6, 0.8, 1 }

local function classColor(class)
  local color = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
  if color then return { color.r, color.g, color.b } end
  return FALLBACK_COLOR
end

-- Abgeschlossene Level aufsteigend
local function completedAscending(characterKey)
  local records = {}
  for _, record in pairs(History.GetCharacter(characterKey).levelHistory or {}) do
    records[#records + 1] = record
  end
  table.sort(records, function(a, b) return a.level < b.level end)
  return records
end

-- Fortschritt im laufenden Level: XP-Anteil beim eingeloggten Charakter, sonst 0
local function currentFraction(characterKey)
  if characterKey ~= ns.characterKey then return 0 end
  local xpMax = UnitXPMax("player")
  if not xpMax or xpMax <= 0 then return 0 end
  return math.min(1, UnitXP("player") / xpMax)
end

-- Punkte { x = /played, y = Level } eines Charakters, älteste zuerst
function ProgressCurve.CharacterPoints(characterKey)
  local points, x = {}, nil
  for _, record in ipairs(completedAscending(characterKey)) do
    local known = record.totalPlayed ~= nil or record.seconds ~= nil  -- ohne beides kein Punkt (kein Sprung)
    if record.totalPlayed then
      if #points == 0 and record.seconds then
        points[#points + 1] = { x = record.totalPlayed - record.seconds, y = record.level }
      end
      x = record.totalPlayed
    elseif record.seconds then
      if not x then
        x = 0
        points[#points + 1] = { x = 0, y = record.level }
      end
      x = x + record.seconds
    end
    if x and known then points[#points + 1] = { x = x, y = record.level + 1 } end
  end
  local character = History.GetCharacter(characterKey)
  local level = characterKey == ns.characterKey and ns.level or character.currentLevel.level
  local nowX
  if characterKey == ns.characterKey then
    nowX = ns.PlayedTime.GetTotalSeconds()
  elseif x and character.currentLevel.seconds then
    nowX = x + character.currentLevel.seconds
  end
  if nowX and level and level > 0 then
    if #points == 0 then
      local levelSeconds = characterKey == ns.characterKey and ns.PlayedTime.GetLevelSeconds() or nil
      points[#points + 1] = { x = nowX - (levelSeconds or 0), y = level }
    end
    points[#points + 1] = { x = nowX, y = level + currentFraction(characterKey) }
  end
  return points
end

-- Stelle (x) eines Levels in einer Punktliste, nil wenn nicht enthalten
local function xAtLevel(points, level)
  for _, point in ipairs(points) do
    if point.y == level then return point.x end
  end
  return nil
end

-- Punkte des Vergleichs aus seinen Zeiten je Level; startX = Stelle seines ersten Levels
local function referencePoints(anchorPoints)
  local Splits = ns.Splits
  local maxLevel = ns.level
  for level in pairs(ns.character.levelHistory) do maxLevel = math.max(maxLevel, level) end
  local first, last
  local maxPlayerLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or maxLevel
  for level = 1, math.max(maxLevel, maxPlayerLevel) do
    if Splits.GetReference(level) then
      first = first or level
      last = level
    elseif first then
      break  -- Lücke: danach ist die Kurve nicht mehr fortlaufend
    end
  end
  if not first then return {} end
  local x = xAtLevel(anchorPoints, first) or 0
  local points = { { x = x, y = first } }
  for level = first, last do
    x = x + Splits.GetReference(level)
    points[#points + 1] = { x = x, y = level + 1 }
  end
  return points
end

-- Weitere Charaktere mit den meisten abgeschlossenen Leveln
local function otherKeys(selectedKey)
  local keys = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    if key ~= selectedKey then keys[#keys + 1] = key end
  end
  local function levelCount(key)
    local count = 0
    for _ in pairs(History.GetCharacter(key).levelHistory or {}) do count = count + 1 end
    return count
  end
  table.sort(keys, function(a, b) return levelCount(a) > levelCount(b) end)
  while #keys > ProgressCurve.OTHER_CHARACTERS do table.remove(keys) end
  return keys
end

-- Reihen für Charts.CreateLineChart: { { label, color, points, dashed } }, gewählter Charakter zuerst;
-- Reihen mit weniger als zwei Punkten fallen weg
function ProgressCurve.Series(selectedKey)
  local series = {}
  local function add(label, color, points, dashed)
    if #points >= 2 then series[#series + 1] = { label = label, color = color, points = points, dashed = dashed } end
  end
  local selectedPoints = ProgressCurve.CharacterPoints(selectedKey)
  add(History.DisplayName(selectedKey), classColor(History.GetCharacter(selectedKey).class), selectedPoints)
  for _, key in ipairs(otherKeys(selectedKey)) do
    add(History.DisplayName(key), classColor(History.GetCharacter(key).class), ProgressCurve.CharacterPoints(key))
  end
  if selectedKey == ns.characterKey then
    add(ns.L.PROGRESS_REFERENCE, REFERENCE_COLOR, referencePoints(selectedPoints), true)
  end
  return series
end
