-- Blizzards Erfahrungs- und Rufleiste ausblenden (Roadmap 365), Classic Era: derselbe StatusTrackingBarManager wie
-- Retail, aber der Rahmen besteht aus den Textur-Listen MainMenuBarTextures/StandaloneTextures; ohne
-- StatusTrackingBarInfo gelten die Rückfall-Indizes. Danach ein älterer Client mit MainMenuExpBar/ReputationWatchBar.
local XP, REP = 4, 1

local function container(name)
  local frame = CreateFrame("Frame", name)
  frame.MainMenuBarTextures = { frame:CreateTexture(), frame:CreateTexture() }
  frame.StandaloneTextures = { frame:CreateTexture() }
  frame.bars = {}
  for _, index in ipairs({ REP, XP }) do
    local bar = CreateFrame("Frame", nil, frame)
    bar:EnableMouse(true)
    frame.bars[index] = bar
  end
  return frame
end
local main = container("MainStatusTrackingBarContainer")
local secondary = container("SecondaryStatusTrackingBarContainer")
main.shownBarIndex, secondary.shownBarIndex = XP, -1
-- ohne barContainers am Manager: die globalen Namen
StatusTrackingBarManager = CreateFrame("Frame")

wow.login({ level = 20 })
local HideFrames = addon.HideFrames
expect("zwei Behälter über die Namen", #HideFrames.StatusBarContainers(), 2)
expect("Rückfall-Index Erfahrung", HideFrames.BarIndex("experience"), XP)

addon.Set("hideBlizzardXpBar", true)
expect("XP unsichtbar", main.bars[XP]:GetAlpha(), 0)
expect("ohne Maus", main.bars[XP]:IsMouseEnabled(), false)
expect("Hauptleisten-Rahmen weg", main.MainMenuBarTextures[2]:GetAlpha(), 0)
expect("freier Rahmen weg", main.StandaloneTextures[1]:GetAlpha(), 0)
expect("leerer Behälter: Rahmen bleibt", secondary.MainMenuBarTextures[1]:GetAlpha(), 1)
expect("Ruf unberührt", main.bars[REP]:GetAlpha(), 1)

-- Im Kampf ausschalten: erst danach zurück
wow.state.combatLockdown = true
addon.Set("hideBlizzardXpBar", false)
expect("im Kampf weiter unsichtbar", main.bars[XP]:GetAlpha(), 0)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf zurück", main.bars[XP]:GetAlpha(), 1)
expect("Maus zurück", main.bars[XP]:IsMouseEnabled(), true)
expect("Rahmen zurück", main.MainMenuBarTextures[2]:GetAlpha(), 1)

-- Älterer Client ohne Manager: die globalen Leisten
StatusTrackingBarManager, MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer = nil, nil, nil
MainMenuExpBar = CreateFrame("StatusBar", "MainMenuExpBar")
MainMenuExpBar:EnableMouse(true)
ExhaustionTick = CreateFrame("Button", "ExhaustionTick")
ExhaustionTick:EnableMouse(true)
ReputationWatchBar = CreateFrame("Frame", "ReputationWatchBar")
expectTrue("alte Leisten gefunden", HideFrames.HasXpBar() and HideFrames.HasRepBar())
addon.Set("hideBlizzardXpBar", true)
addon.Set("hideBlizzardRepBar", true)
expect("alte XP-Leiste unsichtbar", MainMenuExpBar:GetAlpha(), 0)
expect("Ruhe-Marke ohne Maus", ExhaustionTick:IsMouseEnabled(), false)
expect("alte Rufleiste unsichtbar", ReputationWatchBar:GetAlpha(), 0)
addon.Set("hideBlizzardXpBar", false)
addon.Set("hideBlizzardRepBar", false)
expect("alte XP-Leiste zurück", MainMenuExpBar:GetAlpha(), 1)
expect("Ruhe-Marke mit Maus", ExhaustionTick:IsMouseEnabled(), true)
expect("alte Rufleiste zurück", ReputationWatchBar:GetAlpha(), 1)

expect("keine Lua-Fehler", #wow.errors, 0)
