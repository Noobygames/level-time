-- Schlüssel und Einstimmungen klassischer Instanzen (LT-254; von Hand gepflegt, Stand 2026-11-15, siehe sources.md).
-- Je Eintrag nur die letzte Quest der Reihe; die Schritte davor ergeben sich aus pre/preAny in ns.DungeonDB.questInfo
-- (Assist/Attunements.lua). Alle Reihen stammen aus Classic-Daten und gelten in WoW Forever als unbestätigt.
-- ns.AttunementData = { { mapID, at, kind, quest }, ... }
--   mapID = Instanz, die der Schlüssel bzw. die Einstimmung öffnet; at = Instanz, an deren Eingang die Reihe steht
--   (Schlachtzüge ohne eigenen Eingang auf der Karte); kind = "key" oder "attunement";
--   quest = letzte questID (beide Fraktionen) oder { A = questID, H = questID }.
-- Nicht enthalten: der Schlüssel zum Scharlachroten Kloster (keine Quest, liegt in der Bibliothek).
local _, ns = ...
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

ns.AttunementData = {
  { mapID = 230, at = 230, kind = "key", quest = 3802 },                         -- Schattenschmiedeschlüssel
  { mapID = 229, at = 229, kind = "key", quest = 4743 },                         -- Siegel des Aufstiegs
  { mapID = 289, at = 289, kind = "key", quest = { A = 5803, H = 5804 } },       -- Skelettschlüssel
  { mapID = 409, at = 230, kind = "attunement", quest = 7848 },                  -- Geschmolzener Kern (Schwarzfels)
  { mapID = 249, at = 229, kind = "attunement", quest = { A = 6502, H = 6602 } },  -- Onyxia (Reihe endet in der Spitze)
}
