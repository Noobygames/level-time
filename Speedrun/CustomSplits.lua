-- Eigene Splits neben den Level-Splits: /lt split [Name] (oder Tastenbelegung, Bindings.xml) setzt einen Split
-- mit der laufenden /played-Zeit, /lt split undo nimmt den letzten zurück.
--   character.customSplits = { { name, played, time, level } }, älteste zuerst
-- Name: angegeben, sonst der nächste Name der Vorlage, sonst die Zone.
-- Vorlage (/lt split template, accountweit LevelTimerStatsDB.splitTemplate = { source, names, times }): Namen und
-- /played-Zeiten der Splits des eingeloggten Charakters. Neue Charaktere bekommen daraus die Namen und
-- vergleichen Split für Split dagegen (Lauf gegen Lauf, gleiche Position).
local _, ns = ...
local L = ns.L

local CustomSplits = {}
ns.CustomSplits = CustomSplits

local UNDO = "undo"
local TEMPLATE = "template"

local function splits()
  return ns.character.customSplits
end

function CustomSplits.GetAll()
  return splits()
end

function CustomSplits.GetTemplate()
  return LevelTimerStatsDB.splitTemplate
end

-- Name für den nächsten Split ohne Angabe: aus der Vorlage (andere Charaktere), sonst die Zone
local function defaultName()
  local template = CustomSplits.GetTemplate()
  local fromTemplate = template and template.source ~= ns.characterKey and template.names[#splits() + 1]
  return fromTemplate or (GetZoneText and GetZoneText()) or "?"
end

-- Abweichung des Splits an Position index zur Vorlage; nil ohne Vergleichswert
function CustomSplits.GetDelta(index)
  local template = CustomSplits.GetTemplate()
  local split = splits()[index]
  if not template or template.source == ns.characterKey or not split then return nil end
  local reference = template.times[index]
  return reference and split.played - reference or nil
end

-- Split setzen; false, solange /played unbekannt ist
function CustomSplits.Add(name)
  local played = ns.PlayedTime.GetTotalSeconds()
  if not played then return false end
  local split = { name = (name and name ~= "") and name or defaultName(), played = played, time = time(), level = ns.level }
  table.insert(splits(), split)
  ns.Debug("splits", "custom split %s at %s", split.name, played)
  return true
end

function CustomSplits.Undo()
  return table.remove(splits())
end

-- Splits des eingeloggten Charakters als Vorlage; false ohne Splits
function CustomSplits.SaveTemplate()
  if #splits() == 0 then return false end
  local names, times = {}, {}
  for i, split in ipairs(splits()) do
    names[i], times[i] = split.name, split.played
  end
  LevelTimerStatsDB.splitTemplate = { source = ns.characterKey, names = names, times = times }
  return true
end

-- /lt split [Name] | undo | template
function CustomSplits.Command(argument)
  local Format = ns.Format
  if argument:lower() == UNDO then
    local removed = CustomSplits.Undo()
    ns.Print(removed and string.format(L.CUSTOM_SPLIT_UNDONE, removed.name) or L.CUSTOM_SPLIT_NONE)
  elseif argument:lower() == TEMPLATE then
    ns.Print(CustomSplits.SaveTemplate() and string.format(L.CUSTOM_SPLIT_TEMPLATE_SAVED, #splits())
      or L.CUSTOM_SPLIT_NONE)
  elseif CustomSplits.Add(argument) then
    local index = #splits()
    local split = splits()[index]
    ns.Print(string.format(L.CUSTOM_SPLIT_SET, split.name, Format.Duration(split.played),
      Format.SplitDelta(CustomSplits.GetDelta(index))))
  else
    ns.Print(L.CUSTOM_SPLIT_NO_PLAYED)
  end
end

-- Tastenbelegung (Bindings.xml): Split mit Standardnamen
function LevelTimer_CustomSplit()
  if ns.character then CustomSplits.Command("") end
end

-- Beschriftungen der Tastenbelegung (Optionen > Tastaturbelegung > AddOns), in der Sprache des Addons
ns.RegisterApply(function()
  BINDING_HEADER_LEVELTIMER = ns.DISPLAY_NAME
  BINDING_NAME_LEVELTIMER_CUSTOM_SPLIT = L.CUSTOM_SPLIT_BINDING
end)
