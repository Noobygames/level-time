-- Wann ich spiele (Roadmap 277): aktive Zeit und XP je Wochentag und Stunde, Heatmap in den Graphen.
local PlayHours = addon.PlayHours

-- Mittwoch, 14.10.2026 13:59:50 (Ortszeit)
wow.state.clock = os.time({ year = 2026, month = 10, day = 14, hour = 13, min = 59, sec = 50 })
wow.login({ level = 10, xp = 0, xpMax = 1000 })

local day, hour = PlayHours.Slot(wow.state.clock)
expect("Mittwoch = 3", day, 3)
expect("Stunde", hour, 13)
expect("Sonntag = 7", (PlayHours.Slot(os.time({ year = 2026, month = 10, day = 18, hour = 9 }))), 7)

-- 5 s aktiv um 13 Uhr
wow.advance(5)
wow.update(5)
expect("aktive Zeit gebucht", addon.character.playHours["3-13"].seconds, 5)

-- XP um 14 Uhr
wow.advance(10)
wow.state.xp = 300
wow.fire("PLAYER_XP_UPDATE", "player")
expect("XP in der Stunde", addon.character.playHours["3-14"].xp, 300)

-- AFK zählt nicht
wow.state.afk = true
wow.advance(5)
wow.update(5)
expect("AFK nicht gebucht", addon.character.playHours["3-14"].seconds, 0)
wow.state.afk = false

-- Raster und Texte
local grid = PlayHours.Grid(addon.characterKey)
expect("Raster Mittwoch 13 Uhr", grid.cells[3][13].seconds, 5)
expect("Summe", grid.total, 5)
local label, text = PlayHours.CellText(3, 13, grid.cells[3][13])
expect("Beschriftung", label, "Mi 13-14 Uhr")
expect("Wert", text, string.format("%s aktiv, %s XP", addon.Format.Duration(5), "0"))

local chartGrid = addon.Analysis.PlayHours(addon.characterKey)
expect("7 Zeilen", #chartGrid.rows, 7)
expect("24 Spalten", #chartGrid.columns, 24)
expect("Zelle 13 Uhr in Spalte 14", chartGrid.cells[3][14].value, 5)

-- Historie: Heatmap anklickbar, ohne Daten der Hinweis
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Graphen", wow.click("Graphen"))
expectTrue("Diagramm Wann", wow.click("Spielzeiten (Tag × Stunde)"))
wow.logout()
wow.login({ name = "Neuling", level = 1 })
SlashCmdList.LEVELTIMER("history")
expectTrue("leer: Diagramm Wann", wow.click("Spielzeiten (Tag × Stunde)"))
