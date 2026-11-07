-- Blizzards Erfahrungs- und Rufleiste ausblenden (Roadmap 365), Retail: StatusTrackingBarManager mit zwei Behältern,
-- je Behälter eine Leiste je Art (bars[BarsEnum]). Alpha und Maus umkehrbar, Rahmen folgt der gezeigten Art,
-- im Kampf nachgeholt, Schalter in der Leiste des Edit-Modus.
UIParent._width, UIParent._height = 1024, 768
StatusTrackingBarInfo = { BarsEnum = { None = -1, Reputation = 1, Experience = 4 } }
local XP, REP = 4, 1

local function container(name)
  local frame = CreateFrame("Frame", name)
  frame.BarFrameTexture = frame:CreateTexture()
  frame.bars = {}
  for _, index in ipairs({ REP, XP }) do
    local bar = CreateFrame("Frame", nil, frame)
    bar:EnableMouse(true)
    frame.bars[index] = bar
  end
  frame.bars[XP].ExhaustionTick = CreateFrame("Button", nil, frame.bars[XP])
  frame.bars[XP].ExhaustionTick:EnableMouse(true)
  -- wie StatusTrackingBarContainerMixin:ApplyPendingBarToShow (gekürzt)
  function frame:ApplyPendingBarToShow()
    self.shownBarIndex = self.pendingBarToShowIndex
    self.pendingBarToShowIndex = nil
  end
  return frame
end
local main = container("MainStatusTrackingBarContainer")
local secondary = container("SecondaryStatusTrackingBarContainer")
main.shownBarIndex, secondary.shownBarIndex = XP, REP
StatusTrackingBarManager = CreateFrame("Frame")
StatusTrackingBarManager.barContainers = { main, secondary }

wow.login({ level = 20 })
local HideFrames = addon.HideFrames
expectTrue("Leisten gefunden", HideFrames.HasXpBar() and HideFrames.HasRepBar())
expect("je Behälter eine XP-Leiste", #HideFrames.StatusBars("experience"), 2)

-- Aus: nichts verändert
expect("aus: XP sichtbar", main.bars[XP]:GetAlpha(), 1)
expect("aus: Rahmen sichtbar", main.BarFrameTexture:GetAlpha(), 1)

-- XP-Leiste aus: beide XP-Leisten unsichtbar und ohne Maus, Rahmen nur am Behälter mit XP
addon.Set("hideBlizzardXpBar", true)
expect("XP unsichtbar", main.bars[XP]:GetAlpha(), 0)
expect("XP im zweiten Behälter unsichtbar", secondary.bars[XP]:GetAlpha(), 0)
expect("XP ohne Maus", main.bars[XP]:IsMouseEnabled(), false)
expect("Ruhe-Marke ohne Maus", main.bars[XP].ExhaustionTick:IsMouseEnabled(), false)
expect("Rahmen am XP-Behälter weg", main.BarFrameTexture:GetAlpha(), 0)
expect("Ruf bleibt", main.bars[REP]:GetAlpha(), 1)
expect("Rahmen am Ruf-Behälter bleibt", secondary.BarFrameTexture:GetAlpha(), 1)
expect("Behälter selbst unberührt", main:GetAlpha(), 1)

-- Blizzard wechselt die Art (Max-Level: Ruf im ersten Behälter): Rahmen kommt zurück, und wieder weg
main.pendingBarToShowIndex = REP
main:ApplyPendingBarToShow()
expect("Ruf im ersten Behälter: Rahmen da", main.BarFrameTexture:GetAlpha(), 1)
main.pendingBarToShowIndex = XP
main:ApplyPendingBarToShow()
expect("wieder XP: Rahmen weg", main.BarFrameTexture:GetAlpha(), 0)

-- Rufleiste getrennt
addon.Set("hideBlizzardRepBar", true)
expect("Ruf unsichtbar", secondary.bars[REP]:GetAlpha(), 0)
expect("Rahmen am Ruf-Behälter weg", secondary.BarFrameTexture:GetAlpha(), 0)

-- Beide aus: alles wie vorher
addon.Set("hideBlizzardXpBar", false)
addon.Set("hideBlizzardRepBar", false)
expect("XP zurück", main.bars[XP]:GetAlpha(), 1)
expect("Maus zurück", main.bars[XP]:IsMouseEnabled(), true)
expect("Ruhe-Marke mit Maus", main.bars[XP].ExhaustionTick:IsMouseEnabled(), true)
expect("Rahmen zurück", main.BarFrameTexture:GetAlpha(), 1)
expect("Ruf zurück", secondary.bars[REP]:GetAlpha(), 1)
expect("Ruf-Rahmen zurück", secondary.BarFrameTexture:GetAlpha(), 1)

-- Im Kampf: erst danach
wow.state.combatLockdown = true
addon.Set("hideBlizzardXpBar", true)
expect("im Kampf unverändert", main.bars[XP]:GetAlpha(), 1)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf unsichtbar", main.bars[XP]:GetAlpha(), 0)

-- Edit-Modus: Schalter in der Leiste zeigt und ändert dieselbe Einstellung
SlashCmdList.LEVELTIMER("edit")
local check = LevelTimerEditMode.xpBarCheck
expect("Schalter sichtbar", check:IsShown(), true)
expect("Schalter an", check:GetChecked(), true)
expect("Schalter beschriftet", check.label:GetText(), addon.L.HIDE_BLIZZARD_XP_BAR)
check:SetChecked(false)
check._scripts.OnClick(check)
expect("Einstellung aus", addon.db.hideBlizzardXpBar, false)
expect("XP-Leiste wieder da", main.bars[XP]:GetAlpha(), 1)
expect("Modus bleibt offen", addon.EditMode.IsActive(), true)
check:SetChecked(true)
check._scripts.OnClick(check)
expect("Einstellung an", addon.db.hideBlizzardXpBar, true)
expect("XP-Leiste weg", main.bars[XP]:GetAlpha(), 0)
SlashCmdList.LEVELTIMER("edit")
expect("Modus beendet", addon.EditMode.IsActive(), false)
expect("bleibt nach dem Modus aus", main.bars[XP]:GetAlpha(), 0)

expect("keine Lua-Fehler", #wow.errors, 0)
