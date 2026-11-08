-- Teilen und Importieren an einer Stelle: Pakete (Packs.lua) und eigene Ziele (Library.lua) teilen dasselbe Text-Format
-- "LT1:goals:..."; eigene Ziele tragen dabei own = true. Ein Import erkennt daran, wohin der Text gehört: eigene Ziele
-- in die Sammlung, sonst ein Paket. Ältere Texte eigener Ziele ohne Kennung erkennt er am Namen (SG_OWN_GOALS in einer
-- der Sprachen, so hieß der Text beim Teilen).
-- Genutzt vom Reiter "Sammlung" (CollectionPage.lua) und von /sg import, /sg pack import, /sg own share.
local _, ns = ...
local LT = ns.LT
local Packs = ns.Packs
local Library = ns.Library
local L = ns.L

local Sharing = {}
ns.Sharing = Sharing

-- Name eines geteilten Texts eigener Ziele in irgendeiner Sprache (ältere Texte ohne own-Kennung)
local function isOwnName(name)
  for _, texts in pairs(ns.locales) do
    if texts.SG_OWN_GOALS == name then return true end
  end
  return false
end

-- Text einlesen; Rückgabe: Meldung, true bei Erfolg (Form wie Export.ShowImport sie erwartet)
function Sharing.Import(text)
  local entries, name, own = Packs.Decode(text, Library.MAX_ENTRIES)
  if not entries then return L.SG_ERR_IMPORT, false end
  if own or isOwnName(name) then
    local added, err = Library.Import(text)
    if not added then return err, false end
    return string.format(L.SG_CHAT_OWN_IMPORTED, added), true
  end
  local packName, err = Packs.Import(text)
  if not packName then return err, false end
  return string.format(L.SG_CHAT_PACK_IMPORTED, packName), true
end

-- Fenster zum Einfügen; onDone() nach jedem Versuch (Listen neu zeichnen)
function Sharing.ShowImport(onDone)
  LT.Export.ShowImport(L.SG_IMPORT_TITLE, function(text)
    local message, ok = Sharing.Import(text)
    if onDone then onDone() end
    return message, ok
  end)
end

-- Text eines Pakets zum Kopieren zeigen; false = unbekanntes Paket
function Sharing.SharePack(key)
  local text = Packs.Export(key)
  if not text then return false end
  LT.Export.Show(Packs.Label(key), text)
  return true
end

-- Text aller eigenen Ziele zum Kopieren zeigen; ohne eigene Ziele eine Chatzeile
function Sharing.ShareOwn()
  local text = Library.Export()
  if not text then
    ns.Print(L.SG_OWN_EMPTY)
    return false
  end
  LT.Export.Show(L.SG_OWN_GOALS, text)
  return true
end
