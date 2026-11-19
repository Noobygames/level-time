-- Dungeonbilder aus Blizzards Dungeonkompendium (LT-393): je Instanz-Karten-ID (wie GetInstanceInfo, 8. Wert) das
-- Lore-Bild der Instanzseite, ohne eines das Kachelbild der Instanzliste. Quelle: EJ_GetInstanceByIndex(index, isRaid)
-- = instanceID, name, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link,
-- shouldDisplayDifficulty, mapID (Blizzard_EncounterJournal, Forever Mainline und Era Cata). Die Liste gilt je
-- Erweiterung (EJ_SelectTier); danach wird die vorher gewählte Erweiterung wiederhergestellt.
-- Ob Forever für die Classic-Dungeons Bilder liefert: Debug-Check LT393.dungeonArt.coverage.
--   DungeonArt.ForMap(mapID, width, height) -> { texture, left, right, top, bottom } (Ausschnitt fürs Banner) oder nil
local _, ns = ...

local DungeonArt = {}
ns.DungeonArt = DungeonArt

-- Sichtbarer Teil der Texturen wie in Blizzards XML (Rest der Datei ist leer); aspect = Breite/Höhe der Datei
-- (Lore 512 x 512: 390 x 336 sichtbar; Kachel 256 x 128: 174 x 96 sichtbar)
local LORE_COORDS = { right = 0.76171875, bottom = 0.65625, aspect = 1 }
local BUTTON_COORDS = { right = 0.68359375, bottom = 0.7421875, aspect = 2 }

local byMap  -- Karten-ID -> { lore, button }; einmal gesammelt

local function hasJournal()
  return type(EJ_GetNumTiers) == "function" and type(EJ_SelectTier) == "function"
    and type(EJ_GetInstanceByIndex) == "function"
end

local function collectTier(isRaid)
  local index = 1
  while true do
    local ok, journalID, _, _, _, buttonImage, loreImage, _, _, _, _, mapID = pcall(EJ_GetInstanceByIndex, index, isRaid)
    if not ok or not journalID then return end
    if type(mapID) == "number" and not byMap[mapID] and (loreImage or buttonImage) then
      byMap[mapID] = { lore = loreImage, button = buttonImage }
    end
    index = index + 1
  end
end

local function collect()
  byMap = {}
  if not hasJournal() then return end
  local previous = type(EJ_GetCurrentTier) == "function" and EJ_GetCurrentTier() or nil
  for tier = 1, EJ_GetNumTiers() or 0 do
    EJ_SelectTier(tier)
    collectTier(false)
    collectTier(true)
  end
  -- 0 = noch keine Erweiterung gewählt (Kompendium nie geöffnet); EJ_SelectTier(0) wirft einen Fehler
  if previous and previous > 0 then EJ_SelectTier(previous) end
end

-- Bild einer Instanz für ein Banner der Größe width x height: mittiger Streifen über die volle Breite
function DungeonArt.ForMap(mapID, width, height)
  if not mapID then return nil end
  -- Das offene Kompendium nicht umschalten: dann erst beim nächsten Mal sammeln
  if not byMap and not (EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown()) then collect() end
  local art = byMap and byMap[mapID]
  if not art then return nil end
  local coords = art.lore and LORE_COORDS or BUTTON_COORDS
  local span = coords.right * coords.aspect * height / width  -- Streifenhöhe in Texturkoordinaten
  local top = math.max(0, (coords.bottom - span) / 2)
  return { texture = art.lore or art.button, left = 0, right = coords.right, top = top,
    bottom = math.min(coords.bottom, top + span) }
end

-- Für den Debug-Check: Anzahl gefundener Bilder (sammelt bei Bedarf)
function DungeonArt.Count()
  if not byMap then DungeonArt.ForMap(-1, 1, 1) end
  local count = 0
  for _ in pairs(byMap or {}) do count = count + 1 end
  return count, hasJournal()
end
