-- Tooltipzeilen an Gegenständen und Objekten, die Dungeonquests starten (LT-38): Gegenstand 2874 startet Quest 373
-- (Allianz, ab 16), Objekt 2868 „Crumpled Map“ den Kettenanfang 720 (ab 35). Objekte nur auf englischen Clients.
local Starters = addon.DungeonQuestStarters

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
local locale = "enUS"
function GetLocale() return locale end

wow.state.class = "WARRIOR"
wow.login({ level = 20 })  -- Todesminen-Quest 373: im Levelbereich der Instanz (LT-330)
wow.fire("QUEST_LOG_UPDATE")

-- Gegenstand: Zeile über OnTooltipSetItem
GameTooltip.GetItem = function() return "Map", "|cffffffff|Hitem:2874::::|h[Map]|h|r" end
GameTooltip._lines = {}
GameTooltip._scripts.OnTooltipSetItem(GameTooltip)
local line = GameTooltip._lines[1]
local offer = addon.DungeonQuests.GiverOffers("item", 2874)[1]
expectTrue("Gegenstand: Angebot", offer ~= nil and offer.questID == 373)
expect("Gegenstand: Zeile", line, addon.DungeonQuestGivers.OfferLine(offer))

-- Objekt: Welt-Tooltip mit Titel „Crumpled Map“ (Kette nach Uldaman ab 35)
wow.levelUp(40)
GameTooltip.GetItem = function() return nil end
GameTooltip.GetUnit = function() return nil end
GameTooltip.GetOwner = function() return UIParent end
GameTooltip.GetName = function() return "GameTooltip" end
GameTooltipTextLeft1 = CreateFrame("Frame")
GameTooltipTextLeft1.GetText = function() return "Crumpled Map" end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
expect("Objekt: eine Zeile", #GameTooltip._lines, 1)
expect("Objekt: Kettenschritt", #Starters.ObjectOffers("Crumpled Map"), 1)

-- Anderes Objekt, Einheit oder fremder Besitzer: nichts
GameTooltipTextLeft1.GetText = function() return "Mailbox" end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
expect("fremdes Objekt: keine Zeile", #GameTooltip._lines, 0)
GameTooltipTextLeft1.GetText = function() return "Crumpled Map" end
GameTooltip.GetOwner = function() return Minimap end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
expect("kein Welt-Tooltip: keine Zeile", #GameTooltip._lines, 0)

-- Direkter Wechsel zwischen Objekten (Tooltip bleibt offen, kein OnShow): Prüfung im Takt ergänzt neu, nie doppelt
GameTooltip.GetOwner = function() return UIParent end
GameTooltip.IsShown = function() return true end
GameTooltipTextLeft1.GetText = function() return "Mailbox" end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
GameTooltipTextLeft1.GetText = function() return "Crumpled Map" end
wow.update(Starters.REFRESH_SECONDS + 0.1)
expect("Wechsel: Zeile ergänzt", #GameTooltip._lines, 1)
wow.update(Starters.REFRESH_SECONDS + 0.1)
expect("Wechsel: nicht doppelt", #GameTooltip._lines, 1)
GameTooltip._lines = {}
GameTooltip._scripts.OnTooltipCleared(GameTooltip)
wow.update(Starters.REFRESH_SECONDS + 0.1)
expect("geleert, gleicher Titel: wieder ergänzt", #GameTooltip._lines, 1)

-- Objekt-ID aus dem Welt-Tooltip (C_TooltipInfo.GetWorldCursor): erkannt auch mit übersetztem Namen
locale = "deDE"
C_TooltipInfo = { GetWorldCursor = function() return { guid = "GameObject-0-1-0-0-2868-0000ABCDEF" } end }
expect("Objekt-ID aus GUID", Starters.CursorObjectID(), 2868)
GameTooltipTextLeft1.GetText = function() return "Zerknitterte Karte" end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
expect("deDE per Objekt-ID: eine Zeile", #GameTooltip._lines, 1)
C_TooltipInfo = nil
locale = "enUS"

-- Angenommen bzw. andere Sprache: nichts
completed[720] = true
wow.fire("QUEST_LOG_UPDATE")
expect("abgegeben: kein Angebot", #Starters.ObjectOffers("Crumpled Map"), 0)
completed[720] = nil
wow.fire("QUEST_LOG_UPDATE")
locale = "deDE"
expectTrue("deDE: Objektnamen", Starters.NamesAvailable())
expect("deDE: englischer Name kein Treffer", #Starters.ObjectOffers("Crumpled Map"), 0)
expect("deDE: Name übersetzt", Starters.ObjectName(2868), "Zerknitterte Karte")
expect("deDE: Angebot per übersetztem Namen", #Starters.ObjectOffers("Zerknitterte Karte"), 1)
expect("frFR: Name übersetzt", (function() locale = "frFR"; return Starters.ObjectName(2868) end)() ~= "Crumpled Map", true)
locale = "ruRU"
expectTrue("ruRU: keine Objektnamen", not Starters.NamesAvailable() and Starters.ObjectName(2868) == nil)
locale = "deDE"

-- Aus: keine Zeile am Gegenstand
addon.Set("dungeonQuestGivers", false)
GameTooltip.GetItem = function() return "Map", "|cffffffff|Hitem:2874::::|h[Map]|h|r" end
GameTooltip._lines = {}
GameTooltip._scripts.OnTooltipSetItem(GameTooltip)
expect("aus: keine Zeile", #GameTooltip._lines, 0)
