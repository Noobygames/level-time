-- Datentext über LibDataBroker, wenn ein anderes Addon die Bibliothek geladen hat.

-- Nachgebaute LibDataBroker (normalerweise von Titan Panel, ElvUI usw.)
local registered = {}
local broker = {
  NewDataObject = function(_, name, dataObject)
    registered[name] = dataObject
    return dataObject
  end,
}
LibStub = function(libraryName, silent)
  if libraryName == "LibDataBroker-1.1" then return broker end
  if not silent then error("Bibliothek fehlt: " .. libraryName) end
end

wow.login({ level = 20, xp = 300, xpMax = 1000, playedSeconds = 1800 })

local dataObject = registered["LevelTimer"]
expectTrue("Datentext angemeldet", dataObject ~= nil)
expect("Typ", dataObject.type, "data source")

addon.Broker.Refresh()
expect("Text: Spielzeit und XP/h", dataObject.text, "30m 00s - 600 XP/h")

-- Tooltip: eingeschaltete Zeilen mit Bezeichnung und Wert
local lines = {}
local tooltip = {
  AddLine = function(_, text) table.insert(lines, text) end,
  AddDoubleLine = function(_, left, right) table.insert(lines, left .. "=" .. right) end,
}
dataObject.OnTooltipShow(tooltip)
local text = table.concat(lines, "\n")
expectTrue("Tooltip mit XP/h", text:find("XP/h=600", 1, true) ~= nil)
expectTrue("Tooltip mit PvE-Kills", text:find("Kills (PvE)=0", 1, true) ~= nil)

-- Klicks wie beim Minimap-Button
dataObject.OnClick(nil, "RightButton")
expect("Rechtsklick blendet Fenster aus", LevelTimerDB.showTimer, false)

-- Erneuter Login-Ablauf (z.B. Daten löschen) meldet nicht doppelt an
registered["LevelTimer"] = nil
addon.DeleteCharacter(addon.characterKey)
expect("keine zweite Anmeldung", registered["LevelTimer"], nil)

-- Ohne Leiste, die den Datentext zeigt, kein Neuberechnen (Roadmap 396); mit Anzeige nur geänderte Texte
broker.callbacks = { events = { LibDataBroker_AttributeChanged_Other = { [{}] = true } } }
expect("fremdes Objekt: keine Anzeige", addon.Broker.HasDisplay(), false)
dataObject.text = "alt"
wow.advance(5)
wow.update(1)
expect("ohne Anzeige: Text unverändert", dataObject.text, "alt")
broker.callbacks.events.LibDataBroker_AttributeChanged_LevelTimer_text = { [{}] = true }
expectTrue("eigenes Feld: Anzeige", addon.Broker.HasDisplay())
wow.update(1)
expectTrue("mit Anzeige: neuer Text", dataObject.text ~= "alt")
broker.callbacks.events.LibDataBroker_AttributeChanged_LevelTimer_text = nil
broker.callbacks.events.LibDataBroker_AttributeChanged = { [{}] = true }
expectTrue("alle Objekte: Anzeige", addon.Broker.HasDisplay())
