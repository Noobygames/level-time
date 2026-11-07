-- Blizzards Erfahrungs- und Rufleiste ausblenden (Roadmap 365), WoW Forever: die Leisten stehen im Blizzard-Addon
-- Blizzard_StatusTrackingBar. Ist die Einstellung schon an, wenn es lädt, wird bei ADDON_LOADED angewendet.
StatusTrackingBarInfo = { BarsEnum = { None = -1, Reputation = 1, Experience = 4 } }
local XP, REP = 4, 1

wow.login({ level = 20 })
local HideFrames = addon.HideFrames
expect("noch keine Leiste", HideFrames.HasXpBar(), false)
addon.Set("hideBlizzardXpBar", true)
expect("keine Lua-Fehler ohne Leisten", #wow.errors, 0)

-- Blizzard_StatusTrackingBar lädt
local function container(name)
  local frame = CreateFrame("Frame", name)
  frame.BarFrameTexture = frame:CreateTexture()
  frame.bars = { [REP] = CreateFrame("Frame", nil, frame), [XP] = CreateFrame("Frame", nil, frame) }
  frame.bars[XP]:EnableMouse(true)
  return frame
end
local main = container("MainStatusTrackingBarContainer")
main.shownBarIndex = XP
StatusTrackingBarManager = CreateFrame("Frame")
StatusTrackingBarManager.barContainers = { main, container("SecondaryStatusTrackingBarContainer") }
wow.fire("ADDON_LOADED", "Blizzard_StatusTrackingBar")
expect("XP unsichtbar nach dem Laden", main.bars[XP]:GetAlpha(), 0)
expect("Rahmen weg", main.BarFrameTexture:GetAlpha(), 0)

-- Im Kampf einschalten der Rufleiste: erst danach
wow.state.combatLockdown = true
addon.Set("hideBlizzardRepBar", true)
expect("im Kampf unverändert", main.bars[REP]:GetAlpha(), 1)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf unsichtbar", main.bars[REP]:GetAlpha(), 0)

addon.Set("hideBlizzardXpBar", false)
addon.Set("hideBlizzardRepBar", false)
expect("XP zurück", main.bars[XP]:GetAlpha(), 1)
expect("Maus zurück", main.bars[XP]:IsMouseEnabled(), true)
expect("Ruf zurück", main.bars[REP]:GetAlpha(), 1)
expect("Rahmen zurück", main.BarFrameTexture:GetAlpha(), 1)

-- Edit-Modus: Schalter da, sobald es die Leiste gibt
UIParent._width, UIParent._height = 1024, 768
SlashCmdList.LEVELTIMER("edit")
expect("Schalter sichtbar", LevelTimerEditMode.xpBarCheck:IsShown(), true)
expect("Schalter aus", LevelTimerEditMode.xpBarCheck:GetChecked(), false)
SlashCmdList.LEVELTIMER("edit")

expect("keine Lua-Fehler", #wow.errors, 0)
