-- Bibliotheksbücher (WoW Forever, Einstellung libraryBooks): merkt sich jedes Buch, das der Spieler liest
-- (ITEM_TEXT_BEGIN mit ItemTextGetItem), accountweit mit Fundort, und meldet neue Bücher im Chat.
-- LevelTimerStatsDB.libraryBooks[Buchname] = { by = Charakter-Schlüssel, mapID, x, y }.
-- Datenlücke: Eine lokale Liste aller Bücher samt Fundorten gibt es nicht (LT-287: der Extractor sammelt sie, Collect/Books.lua);
-- Kartenpins (Lib/MapPins.lua) brauchen so eine Liste und fehlen deshalb.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    libraryBooks = true,
  },
})
local L = ns.L

local LibraryBooks = {}
ns.LibraryBooks = LibraryBooks

local function store()
  LevelTimerStatsDB.libraryBooks = LevelTimerStatsDB.libraryBooks or {}
  return LevelTimerStatsDB.libraryBooks
end

-- Alle gelesenen Bücher [Name] = Eintrag (nicht verändern)
function LibraryBooks.All()
  return LevelTimerStatsDB and LevelTimerStatsDB.libraryBooks or {}
end

function LibraryBooks.Count()
  local count = 0
  for _ in pairs(LibraryBooks.All()) do count = count + 1 end
  return count
end

ns.RegisterEvent("ITEM_TEXT_BEGIN", function()
  if not ns.db.libraryBooks or not ns.Client.IsForever() then return end
  local name = ItemTextGetItem and ItemTextGetItem()
  if ns.IsSecret(name) or type(name) ~= "string" or name == "" then return end
  local books = store()
  if books[name] then return end
  local entry = { by = ns.characterKey }
  entry.mapID, entry.x, entry.y = ns.DeathPlace.Position()
  books[name] = entry
  ns.Debug("books", "book read: %s (map %s)", name, entry.mapID)
  ns.Print(string.format(L["LIBRARY_BOOK_LEARNED"], name, LibraryBooks.Count()))
end)
