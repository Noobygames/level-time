-- Verschobene Fenster skalieren: Strg+Mausrad, Strg+Rechtsklick zurück, gemerkt und beim Öffnen gesetzt
local L = addon.L
local MoveFrames = addon.MoveFrames

local character = CreateFrame("Frame", "CharacterFrame")
wow.login({ level = 10 })
addon.Set("moveFrames", true)
expect("Mausrad an", character:IsMouseWheelEnabled(), true)

-- Ohne Strg nichts
character._scripts.OnMouseWheel(character, 1)
expect("ohne Strg unverändert", character:GetScale(), 1)

wow.state.controlDown = true
character._scripts.OnMouseWheel(character, 1)
character._scripts.OnMouseWheel(character, 1)
expectNear("größer", character:GetScale(), 1.2)
expectNear("gemerkt", LevelTimerDB.movedFrameScales.CharacterFrame, 1.2)
for _ = 1, 20 do character._scripts.OnMouseWheel(character, -1) end
expectNear("Untergrenze", character:GetScale(), MoveFrames.MIN_SCALE)

-- Beim Öffnen gesetzt
character:SetScale(1)
character._scripts.OnShow(character)
expectNear("beim Öffnen wiederhergestellt", character:GetScale(), MoveFrames.MIN_SCALE)

-- Strg+Rechtsklick: zurück auf 1 und vergessen; Linksklick nicht
character._scripts.OnMouseUp(character, "LeftButton")
expectNear("Linksklick egal", character:GetScale(), MoveFrames.MIN_SCALE)
character._scripts.OnMouseUp(character, "RightButton")
expect("zurückgesetzt", character:GetScale(), 1)
expect("vergessen", LevelTimerDB.movedFrameScales.CharacterFrame, nil)

-- Geschützt im Kampf: nicht skalieren; ungeschützt im Kampf schon
character.IsProtected = function() return true end
wow.state.combatLockdown = true
character._scripts.OnMouseWheel(character, 1)
expect("geschützt im Kampf: nichts", character:GetScale(), 1)
character.IsProtected = function() return false end
character._scripts.OnMouseWheel(character, 1)
expectNear("ungeschützt im Kampf: ja", character:GetScale(), 1.1)
wow.state.combatLockdown = false

-- Ausgeschaltet: nichts
addon.Set("moveFrames", false)
character._scripts.OnMouseWheel(character, 1)
expectNear("aus: nichts", character:GetScale(), 1.1)

-- Zurücksetzen-Knopf: Größe sofort 1
addon.Set("moveFrames", true)
wow.state.controlDown = false
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Komfort", wow.click(L.OPTIONS_TAB_COMFORT))
expectTrue("Button Zurücksetzen", wow.click(L.MOVE_FRAMES_RESET))
expect("Größe zurück", character:GetScale(), 1)
expect("Größen vergessen", LevelTimerDB.movedFrameScales, nil)

-- Import: ungültige Größen fallen weg
local clean = addon.Database.SanitizeSettings({ movedFrameScales = { A = "groß", B = 1.5, C = -1 } })
expect("gültige Größe bleibt", clean.movedFrameScales.B, 1.5)
expect("Text verworfen", clean.movedFrameScales.A, nil)
expect("negativ verworfen", clean.movedFrameScales.C, nil)
