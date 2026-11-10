-- Minimap-Button-Sammler (minimapButtonBar): fremde Addon-Minimap-Buttons einsammeln,
-- in einklappbarer Leiste anordnen, beim Ausschalten vollständig und umkehrbar an Originalposition zurücksetzen.
local MinimapBar = addon.MinimapBar

-- Fremde Buttons und Blizzard/eigene Frames erzeugen
local details = CreateFrame("Button", "LibDBIcon10_Details", Minimap)
details:SetSize(31, 31)
details:SetPoint("CENTER", Minimap, "CENTER", 80, 0)

local myAddon = CreateFrame("Button", "MyAddonMinimapButton", Minimap)
myAddon:SetSize(32, 32)
myAddon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 10, -10)

local questiePin = CreateFrame("Button", "QuestieFrame123", Minimap)
questiePin:SetSize(20, 20)
questiePin:SetPoint("CENTER", Minimap, "CENTER", 50, 50)

GameTimeFrame = CreateFrame("Button", "GameTimeFrame", Minimap)
GameTimeFrame:SetSize(40, 40)

LevelTimerMinimapButton = CreateFrame("Button", "LevelTimerMinimapButton", Minimap)
LevelTimerMinimapButton:SetSize(31, 31)

wow.login()

expect("minimapButtonBar standardmäßig aus", addon.db.minimapButtonBar, false)
expect("noch keine Buttons gesammelt", #MinimapBar.Collected(), 0)
expect("BarFrame ausgeblendet", MinimapBar.BarFrame():IsShown(), false)
expect("ToggleButton ausgeblendet", MinimapBar.ToggleButton():IsShown(), false)

-- Frame-Erkennung prüfen
expectTrue("LibDBIcon erkannt", MinimapBar.IsMinimapButton(details))
expectTrue("MyAddonMinimapButton erkannt", MinimapBar.IsMinimapButton(myAddon))
expect("QuestieFrame ignoriert", MinimapBar.IsMinimapButton(questiePin), false)
expect("GameTimeFrame ignoriert", MinimapBar.IsMinimapButton(GameTimeFrame), false)
expect("LevelTimerMinimapButton ignoriert", MinimapBar.IsMinimapButton(LevelTimerMinimapButton), false)

-- Einschalten
addon.Set("minimapButtonBar", true)
expect("2 Buttons gesammelt", #MinimapBar.Collected(), 2)

local bar = MinimapBar.BarFrame()
expect("Details in Bar", details:GetParent(), bar)
expect("MyAddon in Bar", myAddon:GetParent(), bar)

-- Auf- und Zuklappen
expect("initial eingeklappt", MinimapBar.IsExpanded(), false)
expect("BarFrame versteckt", bar:IsShown(), false)
expect("ToggleButton sichtbar", MinimapBar.ToggleButton():IsShown(), true)

MinimapBar.Toggle()
expect("aufgeklappt", MinimapBar.IsExpanded(), true)
expect("BarFrame gezeigt", bar:IsShown(), true)

MinimapBar.Toggle()
expect("zugeklappt", MinimapBar.IsExpanded(), false)
expect("BarFrame wieder versteckt", bar:IsShown(), false)

-- Ausschalten: alles zurücksetzen
addon.Set("minimapButtonBar", false)
expect("keine Buttons mehr in der Bar", #MinimapBar.Collected(), 0)
expect("Details wieder an Minimap", details:GetParent(), Minimap)
expect("MyAddon wieder an Minimap", myAddon:GetParent(), Minimap)

local p, _, _, x, y = details:GetPoint(1)
expect("Details Anker wieder CENTER", p, "CENTER")
expect("Details X wieder 80", x, 80)
expect("Details Y wieder 0", y, 0)

local mp, _, _, mx, my = myAddon:GetPoint(1)
expect("MyAddon Anker wieder TOPLEFT", mp, "TOPLEFT")
expect("MyAddon X wieder 10", mx, 10)
expect("MyAddon Y wieder -10", my, -10)

expect("BarFrame ausgeblendet", bar:IsShown(), false)
expect("ToggleButton ausgeblendet", MinimapBar.ToggleButton():IsShown(), false)
