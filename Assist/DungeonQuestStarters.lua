-- Tooltipzeilen an Objekten und Gegenständen, die eine Dungeonquest oder einen Kettenschritt starten (LT-38; unter der
-- Einstellung dungeonQuestGivers): dieselben Zeilen wie an NPCs ("Dungeonquest: Titel (Instanz)", "Vorquest: ...",
-- DungeonQuestGivers.AddOfferLines), nur solange der Charakter die Quest jetzt annehmen kann.
-- Gegenstände: Item-ID aus tooltip:GetItem() (Taschen, Beute, Links); Anschluss wie QuestItemTooltip.lua:
-- TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item) mit dem Tooltip-Datensystem, sonst
-- HookScript("OnTooltipSetItem") an GameTooltip und ItemRefTooltip.
-- Objekte der Spielwelt: Welt-Tooltip (Besitzer UIParent, keine Einheit, kein Gegenstand). Objekt-ID aus der GUID von
-- C_TooltipInfo.GetWorldCursor(), falls der Client sie liefert (nur Forever/Retail; ungeprüft, LT38.tooltip.object),
-- sonst Titel (GameTooltipTextLeft1) verglichen mit ns.DungeonDB.objectNames.
-- Wechselt die Maus direkt von einem Objekt zum nächsten, bleibt der Tooltip offen (kein OnShow): Titel alle
-- REFRESH_SECONDS prüfen, neu ergänzen, sobald er sich geändert hat oder der Tooltip geleert wurde (OnTooltipCleared).
-- Objektnamen: englisch aus ns.DungeonDB.objectNames, deDE/frFR/esES aus ns.DungeonObjectNames (fehlender Eintrag:
-- englisch); in anderen Sprachen ohne Objekt-ID im Tooltip kein Objekt-Hinweis.
local _, ns = ...

local DungeonQuests = ns.DungeonQuests
local Givers = ns.DungeonQuestGivers

local DungeonQuestStarters = {}
ns.DungeonQuestStarters = DungeonQuestStarters

-- Spielsprache -> Sprache der Namenstabelle
local NAME_LOCALES = { enUS = "enUS", enGB = "enUS", deDE = "deDE", frFR = "frFR", esES = "esES", esMX = "esES" }

local objectsByName  -- [Name] = { objectID, ... } in der Sprache objectsByNameLocale
local objectsByNameLocale

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

local function isEnabled()
  return ns.db and ns.db.dungeonQuestGivers and Givers.IsAvailable()
end

-- Werden Objektnamen in dieser Spielsprache erkannt?
function DungeonQuestStarters.NamesAvailable()
  return GetLocale ~= nil and NAME_LOCALES[GetLocale()] ~= nil
end

-- Name eines Objekt-Gebers in der Spielsprache (englisch als Rückfall); nil ohne Namenstabelle
function DungeonQuestStarters.ObjectName(objectID)
  local db = ns.DungeonDB
  if not (db and db.objectNames and DungeonQuestStarters.NamesAvailable()) then return nil end
  local names = ns.DungeonObjectNames and ns.DungeonObjectNames[NAME_LOCALES[GetLocale()]]
  return names and names[objectID] or db.objectNames[objectID]
end

-- Angebote aller Objekte mit diesem Namen
function DungeonQuestStarters.ObjectOffers(name)
  local db = ns.DungeonDB
  if not (db and db.objectNames and DungeonQuestStarters.NamesAvailable()) then return {} end
  if objectsByNameLocale ~= GetLocale() then
    objectsByNameLocale = GetLocale()
    objectsByName = {}
    for objectID in pairs(db.objectNames) do
      local objectName = DungeonQuestStarters.ObjectName(objectID)
      objectsByName[objectName] = objectsByName[objectName] or {}
      table.insert(objectsByName[objectName], objectID)
    end
  end
  local offers = {}
  for _, objectID in ipairs(objectsByName[name] or {}) do
    for _, offer in ipairs(DungeonQuests.GiverOffers("object", objectID)) do table.insert(offers, offer) end
  end
  return offers
end

local function onItemTooltip(tooltip)
  if not isEnabled() or type(tooltip) ~= "table" or type(tooltip.GetItem) ~= "function" then return end
  local _, link = tooltip:GetItem()
  link = readable(link)
  local itemID = type(link) == "string" and tonumber((link:match("item:(%d+)")))
  if not itemID then return end
  Givers.AddOfferLines(tooltip, DungeonQuests.GiverOffers("item", itemID))
end

-- Objekt-ID unter dem Mauszeiger aus der GUID "GameObject-0-Server-Instanz-Zone-ID-Spawn"; nil ohne lesbare GUID
function DungeonQuestStarters.CursorObjectID()
  if not (C_TooltipInfo and C_TooltipInfo.GetWorldCursor) then return nil end
  local ok, data = pcall(C_TooltipInfo.GetWorldCursor)
  local guid = ok and type(data) == "table" and readable(data.guid)
  return type(guid) == "string" and tonumber((guid:match("^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)"))) or nil
end

local annotatedTitle  -- Titel, zu dem der offene Tooltip schon ergänzt ist

-- Welt-Tooltip ohne Einheit und Gegenstand: Angebote des Objekts (per ID, sonst per Titel) anhängen
local function refreshWorldTooltip(tooltip)
  if not isEnabled() or not tooltip:IsShown() or tooltip:GetOwner() ~= UIParent then return end
  if readable(tooltip:GetUnit()) or readable(tooltip:GetItem()) then return end
  local frameName = tooltip:GetName()
  local title = type(frameName) == "string" and _G[frameName .. "TextLeft1"]
  local name = title and readable(title:GetText())
  if type(name) ~= "string" or name == annotatedTitle then return end
  annotatedTitle = name
  local objectID = DungeonQuestStarters.CursorObjectID()
  local offers = objectID and DungeonQuests.GiverOffers("object", objectID) or DungeonQuestStarters.ObjectOffers(name)
  if #offers == 0 then return end
  Givers.AddOfferLines(tooltip, offers)
  tooltip:Show()  -- Größe nach den neuen Zeilen anpassen
end

local function resetWorldTooltip()
  annotatedTitle = nil
end

DungeonQuestStarters.REFRESH_SECONDS = 0.2

ns.Every(DungeonQuestStarters.REFRESH_SECONDS, function()
  if GameTooltip then refreshWorldTooltip(GameTooltip) end
end, function(db) return db.dungeonQuestGivers and Givers.IsAvailable() end)

local hooked = false
local function hook()
  if hooked or not GameTooltip then return end
  hooked = true
  local itemType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and itemType then
    TooltipDataProcessor.AddTooltipPostCall(itemType, onItemTooltip)
  else
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
      tooltip:HookScript("OnTooltipSetItem", function(self)
        onItemTooltip(self)
        self:Show()
      end)
    end
  end
  GameTooltip:HookScript("OnShow", function(self)
    resetWorldTooltip()
    refreshWorldTooltip(self)
  end)
  GameTooltip:HookScript("OnTooltipCleared", resetWorldTooltip)
end

ns.RegisterApply(function(db)
  if db.dungeonQuestGivers and Givers.IsAvailable() then hook() end
end)
