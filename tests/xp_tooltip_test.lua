-- XP-Tooltip auf dem Balken (alle Layouts mit Balken): genaue Zahlen mit Trennzeichen der Sprache, Rest, Erholung
-- absolut und als Anteil, Deckung des Rests, Aktualisierung nur bei Ereignissen und nur solange offen, Max-Level.
local L = addon.L

wow.login({ level = 20 })
wow.update(1)
local elements = addon.TimerWindow.Elements()
local hover = elements.xpBar.hover
wow.state.xp, wow.state.xpMax, wow.state.rested = 12345, 31700, 0
hover._scripts.OnEnter(hover)
expect("Titel", GameTooltip._text, string.format(L.XP_TOOLTIP_TITLE, 20))
expect("Fortschritt", GameTooltip._lines[1], string.format(L.XP_TOOLTIP_PROGRESS, "12.345", "31.700", "38,9 %"))
expect("Rest", GameTooltip._lines[2], string.format(L.XP_TOOLTIP_MISSING, "19.355"))
expect("ohne Erholung", GameTooltip._lines[3], L.XP_TOOLTIP_NO_RESTED)
-- Neue Erholung kommt per Ereignis, ohne neues Überfahren
wow.state.rested = 4200
wow.fire("UPDATE_EXHAUSTION")
expect("Erholung", GameTooltip._lines[3], string.format(L.XP_TOOLTIP_RESTED, "4.200", "13,2 %"))
expect("Erholung deckt", GameTooltip._lines[4], string.format(L.XP_TOOLTIP_RESTED_COVERS, "21,7 %"))
hover._scripts.OnLeave(hover)
-- Nach dem Verlassen kein Neuaufbau mehr
GameTooltip._lines = {}
wow.fire("PLAYER_XP_UPDATE", "player")
expect("geschlossen: keine Zeilen", #GameTooltip._lines, 0)
-- Englisch: Komma als Tausender-Trennzeichen, Punkt als Dezimalzeichen
addon.Set("language", "enUS")
hover._scripts.OnEnter(hover)
expect("englisch", GameTooltip._lines[1], string.format(L.XP_TOOLTIP_PROGRESS, "12,345", "31,700", "38.9%"))
hover._scripts.OnLeave(hover)
addon.Set("language", "deDE")

-- Fertige Quests (QuestLogXp.lua): eigene Zeile mit Anteil am Level
local questXp = addon.QuestLogXp.Get
addon.QuestLogXp.Get = function() return 3170, 500 end
local content = addon.XpTooltip.Build()
expect("fertige Quests", content.lines[5], string.format(L.XP_TOOLTIP_QUESTS, "3.170", "10,0 %"))
addon.QuestLogXp.Get = questXp

-- Geheime Werte (Retail/Forever): kein Tooltip statt eines Fehlers
local isSecret = addon.IsSecret
addon.IsSecret = function(value) return value == 12345 end
expect("geheim: kein Inhalt", addon.XpTooltip.Build(), nil)
addon.IsSecret = isSecret

wow.levelUp(60)
wow.update(0.3)
content = addon.XpTooltip.Build()
expect("Max-Level: eine Zeile", #content.lines, 1)
expect("Max-Level: Text", content.lines[1], L.XP_TOOLTIP_MAX_LEVEL)
hover._scripts.OnEnter(hover)
expect("Max-Level: Tooltip-Zeile", GameTooltip._lines[1], L.XP_TOOLTIP_MAX_LEVEL)
hover._scripts.OnLeave(hover)
expect("Fehlerfrei", #wow.errors, 0)
