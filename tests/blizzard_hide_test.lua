-- Blizzard-Oberfläche ausblenden (Roadmap 366), Retail: Liste der Elemente, Alpha und Maus umkehrbar, Blizzards eigene
-- Alpha-Änderungen bleiben 0 (und kommen danach zurück), geschützte Elemente erst nach dem Kampf, Einträge mit eigener
-- Einstellung, Ereignisse abmelden, gemeinsame Frames, Bereinigung beim Import, Flächen im Edit-Modus.
UIParent._width, UIParent._height = 1024, 768

local function blizzardFrame(name, parent)
  local frame = CreateFrame("Frame", name, parent)
  frame:EnableMouse(true)
  return frame
end

blizzardFrame("PlayerFrame")
blizzardFrame("TargetFrame")
local mainBar = blizzardFrame("MainActionBar")
for index = 1, 12 do blizzardFrame("ActionButton" .. index, mainBar) end
local pageButton = blizzardFrame(nil, mainBar)  -- Unterframe ohne Namen (z.B. Seitenknöpfe)
mainBar.GetChildren = function() return pageButton end
local cluster = blizzardFrame("MinimapCluster")
cluster.ZoneTextButton = blizzardFrame(nil, cluster)
cluster.GetChildren = function() return cluster.ZoneTextButton end
blizzardFrame("ObjectiveTrackerFrame")
blizzardFrame("StanceBar")
local talkingHead = blizzardFrame("TalkingHeadFrame")
talkingHead:RegisterEvent("TALKINGHEAD_REQUESTED")
talkingHead:RegisterEvent("TALKINGHEAD_CLOSE")
talkingHead:Hide()  -- nur zu sehen, während jemand spricht

wow.login({ level = 20 })
local L = addon.L
local BlizzardHide = addon.BlizzardHide
local get = BlizzardHide.Get

-- Liste: vorhandene Frames gefunden, fehlende fallen weg, Gebietsname als Unterframe der Minimap
expectTrue("Spielerrahmen gefunden", BlizzardHide.IsAvailable(get("player")))
expect("Fokus fehlt in diesem Stub", BlizzardHide.IsAvailable(get("focus")), false)
expect("Fokus kann es in Retail geben", BlizzardHide.IsSupported(get("focus")), true)
expect("Gebietsname = Unterframe", BlizzardHide.Frames(get("zoneText"))[1], cluster.ZoneTextButton)
expect("Aktionsleiste 2 beschriftet", BlizzardHide.Label(get("bar2")), string.format(L.BLIZZ_FRAME_BAR, 2))
expect("Haltungsleiste über ihre Einstellung", get("stance").setting, "hideStanceBar")

-- Ausblenden: Alpha 0, Maus aus; Ausschalten stellt genau her
BlizzardHide.SetHidden("player", true)
expect("Einstellung gesetzt", LevelTimerDB.hiddenBlizzardFrames.player, true)
expect("Spielerrahmen unsichtbar", PlayerFrame:GetAlpha(), 0)
expect("Spielerrahmen ohne Maus", PlayerFrame:IsMouseEnabled(), false)
expect("Ziel unberührt", TargetFrame:GetAlpha(), 1)
-- Blizzard setzt selbst Alpha (Deckkraft aus dem Edit Mode): bleibt 0, danach gilt Blizzards Wert
PlayerFrame:SetAlpha(0.8)
expect("Blizzards Alpha bleibt 0", PlayerFrame:GetAlpha(), 0)
BlizzardHide.SetHidden("player", false)
expect("Einstellung leer", LevelTimerDB.hiddenBlizzardFrames, nil)
expect("Blizzards Wert zurück", PlayerFrame:GetAlpha(), 0.8)
expect("Maus zurück", PlayerFrame:IsMouseEnabled(), true)
PlayerFrame:SetAlpha(1)
BlizzardHide.Toggle("player")
BlizzardHide.Toggle("player")
expect("ohne Blizzard-Änderung: Original", PlayerFrame:GetAlpha(), 1)

-- Aktionsleiste: Knöpfe und Unterframes ohne Maus
BlizzardHide.SetHidden("mainBar", true)
expect("Leiste unsichtbar", mainBar:GetAlpha(), 0)
expect("Knopf ohne Maus", ActionButton1:IsMouseEnabled(), false)
expect("Knopf 12 ohne Maus", ActionButton12:IsMouseEnabled(), false)
expect("Unterframe ohne Maus", pageButton:IsMouseEnabled(), false)
expect("Knopf selbst nicht transparent (erbt vom Rahmen)", ActionButton1:GetAlpha(), 1)
BlizzardHide.SetHidden("mainBar", false)
expect("Knopf mit Maus", ActionButton1:IsMouseEnabled(), true)
expect("Unterframe mit Maus", pageButton:IsMouseEnabled(), true)

-- Geschützt: im Kampf erst danach, auch das Herstellen
wow.state.combatLockdown = true
BlizzardHide.SetHidden("mainBar", true)
expect("im Kampf unverändert", mainBar:GetAlpha(), 1)
expect("wartet", BlizzardHide.IsPending(), true)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf unsichtbar", mainBar:GetAlpha(), 0)
expect("nach dem Kampf ohne Maus", ActionButton1:IsMouseEnabled(), false)
wow.state.combatLockdown = true
BlizzardHide.SetHidden("mainBar", false)
expect("Herstellen wartet", mainBar:GetAlpha(), 0)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("hergestellt", mainBar:GetAlpha(), 1)
expect("Knopf mit Maus nach dem Kampf", ActionButton1:IsMouseEnabled(), true)

-- Gemeinsamer Frame: Minimap ganz und Gebietsname; der Gebietsname bleibt ohne Maus, solange die Minimap aus ist
BlizzardHide.SetHidden("minimap", true)
BlizzardHide.SetHidden("zoneText", true)
BlizzardHide.SetHidden("zoneText", false)
expect("Gebietsname noch ohne Maus (Minimap aus)", cluster.ZoneTextButton:IsMouseEnabled(), false)
BlizzardHide.SetHidden("minimap", false)
expect("Gebietsname mit Maus", cluster.ZoneTextButton:IsMouseEnabled(), true)
expect("Minimap sichtbar", cluster:GetAlpha(), 1)

-- Eigene Einstellung eines anderen Moduls: Haltungsleiste
BlizzardHide.SetHidden("stance", true)
expect("hideStanceBar an", LevelTimerDB.hideStanceBar, true)
expect("nicht in der eigenen Liste", LevelTimerDB.hiddenBlizzardFrames, nil)
expectTrue("als ausgeblendet gemeldet", BlizzardHide.IsHidden("stance"))
BlizzardHide.SetHidden("stance", false)
expect("hideStanceBar aus", LevelTimerDB.hideStanceBar, false)

-- Sprechender Kopf: Ereignis abgemeldet statt Alpha, danach wieder angemeldet
BlizzardHide.SetHidden("talkingHead", true)
expect("Ereignis abgemeldet", talkingHead:IsEventRegistered("TALKINGHEAD_REQUESTED"), false)
expect("anderes Ereignis bleibt", talkingHead:IsEventRegistered("TALKINGHEAD_CLOSE"), true)
expect("kein Alpha", talkingHead:GetAlpha(), 1)
BlizzardHide.SetHidden("talkingHead", false)
expect("Ereignis zurück", talkingHead:IsEventRegistered("TALKINGHEAD_REQUESTED"), true)

-- Import und Profile: nur eigene, bekannte Ids mit true
local clean = addon.Database.SanitizeSettings({
  hiddenBlizzardFrames = { player = true, bogus = true, stance = true, target = "ja", [1] = true },
})
expect("Spieler bleibt", clean.hiddenBlizzardFrames.player, true)
expect("unbekannt fällt weg", clean.hiddenBlizzardFrames.bogus, nil)
expect("fremde Einstellung fällt weg", clean.hiddenBlizzardFrames.stance, nil)
expect("kein true fällt weg", clean.hiddenBlizzardFrames.target, nil)
expect("kein Text-Schlüssel fällt weg", clean.hiddenBlizzardFrames[1], nil)
expect("kein Table: weg", addon.Database.SanitizeSettings({ hiddenBlizzardFrames = "player" }).hiddenBlizzardFrames, nil)

-- Optionen: ein Schalter je Eintrag, Text aus der Liste; Einträge mit eigener Einstellung schalten diese (UX S15:
-- alles Ausblenden an einem Ort)
local toggles = BlizzardHide.Toggles()
local labels = {}
for _, toggle in ipairs(toggles) do labels[toggle.text()] = toggle end
expectTrue("Schalter Spielerrahmen", labels[L.BLIZZ_FRAME_PLAYER] ~= nil)
local stance = labels[L.BLIZZ_FRAME_STANCE]
expectTrue("Haltungsleiste in der Liste", stance ~= nil)
expect("Haltungsleiste: Einstellung", stance.setting, "hideStanceBar")
expect("Haltungsleiste: eigene Erklärung", stance.tip, "HIDE_STANCE_BAR_TIP")
stance.set(true)
expect("Schalter setzt die Einstellung", LevelTimerDB.hideStanceBar, true)
expect("nicht in der eigenen Liste", (LevelTimerDB.hiddenBlizzardFrames or {}).stance, nil)
stance.set(false)
expect("Einstellung wieder aus", LevelTimerDB.hideStanceBar, false)
for _, key in ipairs({ "BLIZZ_FRAME_XP_BAR", "BLIZZ_FRAME_REP_BAR", "BLIZZ_FRAME_CALENDAR", "BLIZZ_FRAME_CHAT_BUTTONS" }) do
  expectTrue("Schalter " .. key, labels[L[key]] ~= nil and labels[L[key]].setting ~= nil)
end
labels[L.BLIZZ_FRAME_TARGET].set(true)
expect("Schalter blendet aus", TargetFrame:GetAlpha(), 0)
expect("Schalter liest", labels[L.BLIZZ_FRAME_TARGET].get(LevelTimerDB), true)
labels[L.BLIZZ_FRAME_TARGET].set(false)

-- Edit-Modus: außerhalb keine Flächen
local Overlays = addon.BlizzardOverlays
expect("keine Fläche vor dem Edit-Modus", Overlays.Overlay("player"), nil)
SlashCmdList.LEVELTIMER("edit")
local playerOverlay = Overlays.Overlay("player")
expectTrue("Fläche über dem Spielerrahmen", playerOverlay ~= nil and playerOverlay:IsShown())
expect("beschriftet", playerOverlay.label:GetText(), L.BLIZZ_FRAME_PLAYER)
expect("keine Fläche ohne Frame", Overlays.Overlay("focus"), nil)
expect("keine Fläche für versteckten Sprechenden Kopf", Overlays.Overlay("talkingHead"), nil)
expectTrue("Fläche für die Haltungsleiste", Overlays.Overlay("stance"):IsShown())
-- Kleinere Elemente liegen über größeren
cluster._width, cluster._height = 200, 200
cluster.ZoneTextButton._width, cluster.ZoneTextButton._height = 140, 12
addon.ApplySettings()
expectTrue("Gebietsname über der Minimap",
  Overlays.Overlay("zoneText"):GetFrameLevel() > Overlays.Overlay("minimap"):GetFrameLevel())

-- Haken auf der Fläche blendet aus, die Fläche bleibt als Platzhalter
playerOverlay.check:SetChecked(true)
playerOverlay.check._scripts.OnClick(playerOverlay.check)
expect("ausgeblendet per Fläche", PlayerFrame:GetAlpha(), 0)
expect("Platzhalter bleibt", playerOverlay:IsShown(), true)
expect("Platzhalter beschriftet", playerOverlay.label:GetText(),
  string.format(L.EDIT_MODE_BLIZZARD_HIDDEN, L.BLIZZ_FRAME_PLAYER))
expect("Haken gesetzt", playerOverlay.check:GetChecked(), true)
playerOverlay.check:SetChecked(false)
playerOverlay.check._scripts.OnClick(playerOverlay.check)
expect("wieder da", PlayerFrame:GetAlpha(), 1)

-- Schalter in der Leiste: Flächen aus und wieder an
expect("Schalter Blizzard-Elemente an", LevelTimerDB.editBlizzardFrames, true)
addon.Set("editBlizzardFrames", false)
expect("Flächen weg", playerOverlay:IsShown(), false)
addon.Set("editBlizzardFrames", true)
expect("Flächen wieder da", playerOverlay:IsShown(), true)

-- Verlassen: alle Flächen weg, Einstellungen bleiben
SlashCmdList.LEVELTIMER("edit")
expect("Modus aus", addon.EditMode.IsActive(), false)
expect("Fläche weg", playerOverlay:IsShown(), false)
addon.ApplySettings()
expect("bleibt weg nach Apply", playerOverlay:IsShown(), false)
