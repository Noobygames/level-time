-- Lesbare Objekte und Bücher (X.db.books[Name]): wie oft geöffnet, Ort des Spielers (X.AddSpot), Objekt-IDs der
-- Gegenüber-Einheiten beim Öffnen (objects[ID] = Anzahl) und Material. Grundlage für die Bücherliste von Level Time
-- (LT-287): eine lokale Liste aller Bibliotheksbücher mit Fundort gibt es nicht.
-- ITEM_TEXT_BEGIN; ItemTextGetItem, ItemTextGetMaterial (Blizzard-API-Dokumentation, alle Zweige).
-- Welche Einheit das Buchobjekt liefert, ist offen: "npc" (Interaktionsziel), "softinteract", "mouseover", "target".
local _, X = ...

local Books = {}
X.Books = Books

local OBJECT_UNITS = { "npc", "softinteract", "mouseover", "target" }

X.On("ITEM_TEXT_BEGIN", function()
  if not X.db then return end
  local name = X.Call("ItemTextGetItem")
  if type(name) ~= "string" or name == "" then return end
  local record = X.Record("books", name)
  X.Increment(record, "opened")
  record.material = X.Call("ItemTextGetMaterial") or record.material
  X.AddSpot(record)
  for _, unit in ipairs(OBJECT_UNITS) do
    local kind, id = X.ParseGuid(X.Call("UnitGUID", unit))
    if kind == "GameObject" and id then
      record.objects = record.objects or {}
      X.Increment(record.objects, id)
    end
  end
end)
