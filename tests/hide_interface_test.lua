-- Oberfläche (Roadmap 329, Schritt 4): Tasten- und Makrotext, rot außer Reichweite, Boss-Banner, Ereignis-
-- Einblendungen, Meldungen, Haltungsleiste, Ruhe-Animation, Porträtzahlen. Alles umkehrbar.

-- Aktionsknöpfe wie im Client: HotKey, Name, icon und UpdateUsable (Blizzard: weiß, blau bei fehlendem Mana)
local function actionButton(name)
  local button = CreateFrame("CheckButton", name)
  button.HotKey = button:CreateFontString()
  button.Name = button:CreateFontString()
  button.icon = button:CreateTexture()
  button.noMana = false
  function button:UpdateUsable()
    if self.noMana then self.icon:SetVertexColor(0.5, 0.5, 1) else self.icon:SetVertexColor(1, 1, 1) end
  end
  return button
end
local button1, button2 = actionButton("ActionButton1"), actionButton("MultiBarBottomLeftButton3")
function ActionButton_UpdateRangeIndicator() end  -- Blizzards Funktion (färbt nur den Tastentext)

-- Frames je Client: Boss-Banner, Toasts und Meldungen mit ihren Ereignissen
BossBanner = CreateFrame("Frame")
BossBanner:RegisterEvent("BOSS_KILL")
BossBanner:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
EventToastManagerFrame = CreateFrame("Frame")
EventToastManagerFrame:RegisterEvent("DISPLAY_EVENT_TOASTS")
AlertFrame = CreateFrame("Frame")
AlertFrame:RegisterEvent("ACHIEVEMENT_EARNED")
AlertFrame:RegisterEvent("NEW_TOY_ADDED")
StanceBar = CreateFrame("Frame", nil, UIParent)
-- Retail/Forever-Spielerrahmen: Ruhe-Animation und Trefferzahl
local restLoop, hitText = CreateFrame("Frame"), CreateFrame("Frame")
PlayerFrame = CreateFrame("Frame")
PlayerFrame.PlayerFrameContent = {
  PlayerFrameContentContextual = { PlayerRestLoop = restLoop },
  PlayerFrameContentMain = { HitIndicator = { HitText = hitText } },
}
PetHitIndicator = CreateFrame("Frame")

wow.login()
local HideFrames = addon.HideFrames
expectTrue("Schalter für vorhandene Frames", HideFrames.HasBossBanner() and HideFrames.HasRestAnimation()
  and HideFrames.HasPortraitNumbers() and HideFrames.HasStanceBar())
expect("Porträtzahlen: Spieler und Begleiter", #HideFrames.HitTexts(), 2)

-- Aus: nichts verändert
expect("aus: Tastentext sichtbar", button1.HotKey:GetAlpha(), 1)
expect("aus: Boss-Banner hört zu", BossBanner:IsEventRegistered("BOSS_KILL"), true)

-- Tasten- und Makrotext
addon.Set("hideKeybindText", true)
addon.Set("hideMacroText", true)
expect("Tastentext unsichtbar", button1.HotKey:GetAlpha(), 0)
expect("auch zweite Leiste", button2.HotKey:GetAlpha(), 0)
expect("Makroname unsichtbar", button1.Name:GetAlpha(), 0)
addon.Set("hideKeybindText", false)
addon.Set("hideMacroText", false)
expect("Tastentext zurück", button1.HotKey:GetAlpha(), 1)
expect("Makroname zurück", button1.Name:GetAlpha(), 1)

-- Reichweite: aus = Blizzards Farbe bleibt
ActionButton_UpdateRangeIndicator(button1, true, false)
expect("aus: nicht rot", (button1.icon:GetVertexColor()), 1)
addon.Set("rangeColor", true)
ActionButton_UpdateRangeIndicator(button1, true, false)
local r, g = button1.icon:GetVertexColor()
expectTrue("außer Reichweite rot", r > 0.8 and g < 0.2)
-- Blizzard aktualisiert die Benutzbarkeit: bleibt rot
button1:UpdateUsable()
expectTrue("nach UpdateUsable weiter rot", (select(2, button1.icon:GetVertexColor())) < 0.2)
-- Wieder in Reichweite: Blizzards Farbe (hier blau, kein Mana)
button1.noMana = true
ActionButton_UpdateRangeIndicator(button1, true, true)
expect("in Reichweite: blau wie Blizzard", (button1.icon:GetVertexColor()), 0.5)
-- Geheime Werte: nichts ändern
ActionButton_UpdateRangeIndicator(button1, true, wow.SECRET)
expect("geheim: unverändert", (button1.icon:GetVertexColor()), 0.5)
-- Ausschalten stellt rote Knöpfe zurück
ActionButton_UpdateRangeIndicator(button2, true, false)
expectTrue("Knopf 2 rot", addon.ActionBars.IsOutOfRange(button2))
addon.Set("rangeColor", false)
expect("aus: Knopf 2 wieder weiß", (select(2, button2.icon:GetVertexColor())), 1)
ActionButton_UpdateRangeIndicator(button2, true, false)
expect("aus: Hook färbt nicht mehr", (select(2, button2.icon:GetVertexColor())), 1)

-- Ereignisse abmelden und wieder anmelden (nur die vorher angemeldeten)
addon.Set("hideBossBanner", true)
addon.Set("hideEventToasts", true)
addon.Set("hideAlerts", true)
expect("Boss-Banner still", BossBanner:IsEventRegistered("BOSS_KILL"), false)
expect("Boss-Beute still", BossBanner:IsEventRegistered("ENCOUNTER_LOOT_RECEIVED"), false)
expect("Toasts still", EventToastManagerFrame:IsEventRegistered("DISPLAY_EVENT_TOASTS"), false)
expect("Meldungen still", AlertFrame:IsEventRegistered("ACHIEVEMENT_EARNED"), false)
addon.Set("hideBossBanner", false)
addon.Set("hideEventToasts", false)
addon.Set("hideAlerts", false)
expect("Boss-Banner zurück", BossBanner:IsEventRegistered("BOSS_KILL"), true)
expect("Toasts zurück", EventToastManagerFrame:IsEventRegistered("DISPLAY_EVENT_TOASTS"), true)
expect("Spielzeug-Meldung zurück", AlertFrame:IsEventRegistered("NEW_TOY_ADDED"), true)
expect("nicht angemeldete bleiben weg", AlertFrame:IsEventRegistered("LOOT_ITEM_ROLL_WON"), false)

-- Ruhe-Animation
addon.Set("hideRestAnimation", true)
expect("Zzz unsichtbar", restLoop:GetAlpha(), 0)
addon.Set("hideRestAnimation", false)
expect("Zzz zurück", restLoop:GetAlpha(), 1)

-- Porträtzahlen: Blizzards Show wird sofort versteckt
addon.Set("hidePortraitNumbers", true)
hitText:Show()
expect("Trefferzahl versteckt", hitText:IsShown(), false)
PetHitIndicator:Show()
expect("Begleiterzahl versteckt", PetHitIndicator:IsShown(), false)
addon.Set("hidePortraitNumbers", false)
hitText:Show()
expect("aus: Trefferzahl sichtbar", hitText:IsShown(), true)

-- Haltungsleiste: nicht im Kampf, danach nachgeholt
wow.state.combatLockdown = true
addon.Set("hideStanceBar", true)
expect("im Kampf unverändert", StanceBar:GetParent(), UIParent)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
local holder = StanceBar:GetParent()
expectTrue("nach dem Kampf versteckt", holder ~= UIParent and not holder:IsShown())
addon.Set("hideStanceBar", false)
expect("Haltungsleiste zurück", StanceBar:GetParent(), UIParent)
