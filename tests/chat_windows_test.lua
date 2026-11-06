-- Chatfenster anpassen: Kampflog-Reiter, Chat-Buttons, Eingabezeile oben, Pfeiltasten, kein Verblassen.
-- Alles umkehrbar: ausgeschaltet gelten wieder die Werte von vorher.
local chat1, chat2 = ChatFrame1, ChatFrame2

wow.login()

-- Chat-Buttons wie im Client (Menü an der Knopfleiste von Fenster 1, Sprache am UIParent)
ChatFrameMenuButton = CreateFrame("Button", nil, chat1.buttonFrame)
ChatFrameToggleVoiceMuteButton = CreateFrame("Button", nil, UIParent)
-- Kampflog angedockt, Reiter klickbar; Dock wie Blizzard (FCFDock_UpdateTabs, FCF_SelectDockFrame)
chat2.isDocked = true
ChatFrame2Tab:EnableMouse(true)
GENERAL_CHAT_DOCK = { selected = chat2 }
local dockUpdates = 0
function FCFDock_UpdateTabs() dockUpdates = dockUpdates + 1 end
function FCFDock_GetSelectedWindow(dock) return dock.selected end
function FCF_SelectDockFrame(frame) GENERAL_CHAT_DOCK.selected = frame; FCFDock_UpdateTabs() end
local originalEditBoxPoint = chat1.editBox._points[1]

-- Aus: nichts verändert
addon.ApplySettings()
expect("aus: verblasst", chat1:GetFading(), true)
expect("aus: Alt für Pfeiltasten", chat1.editBox:GetAltArrowKeyMode(), true)
expect("aus: Knopfleiste am Fenster", chat1.buttonFrame:GetParent(), chat1)
expect("aus: Kampflog-Reiter normal", ChatFrame2Tab:GetScale(), 1)

addon.Set("noChatFade", true)
addon.Set("chatArrowKeys", true)
expect("verblasst nicht", chat1:GetFading(), false)
expect("auch Fenster 2", chat2:GetFading(), false)
expect("Pfeiltasten ohne Alt", chat1.editBox:GetAltArrowKeyMode(), false)

addon.Set("hideChatButtons", true)
local holder = chat1.buttonFrame:GetParent()
expectTrue("Knopfleiste versteckt", holder ~= chat1 and not holder:IsShown())
expect("Menü-Button versteckt", ChatFrameMenuButton:GetParent(), holder)
expect("Sprach-Button versteckt", ChatFrameToggleVoiceMuteButton:GetParent(), holder)

addon.Set("chatEditBoxTop", true)
local point = chat1.editBox._points[1]
expect("Eingabe über dem Fenster", point[1], "BOTTOMLEFT")
expect("am Chatfenster", point[2], chat1)
expect("oben", point[3], "TOPLEFT")
expectTrue("über den Reitern", point[5] > 0)

addon.Set("hideCombatLogTab", true)
expect("Kampflog-Reiter winzig", ChatFrame2Tab:GetScale(), 0.01)
expect("Kampflog-Reiter nicht klickbar", ChatFrame2Tab:IsMouseEnabled(), false)
expect("gewähltes Kampflog verlassen", GENERAL_CHAT_DOCK.selected, DEFAULT_CHAT_FRAME)
-- Blizzard ordnet die Reiter neu (z.B. neues Fenster): bleibt versteckt
ChatFrame2Tab:SetScale(1)
FCFDock_UpdateTabs()
expect("nach Dock-Update wieder versteckt", ChatFrame2Tab:GetScale(), 0.01)

-- Neues temporäres Fenster (Flüstern) bekommt dieselben Einstellungen
local whisperFrame = CreateFrame("ScrollingMessageFrame", "ChatFrame11")
whisperFrame.editBox = CreateFrame("EditBox")
whisperFrame.buttonFrame = CreateFrame("Frame", nil, whisperFrame)
function FCF_OpenTemporaryWindow() table.insert(CHAT_FRAMES, "ChatFrame11") end
addon.ApplySettings()  -- Hook auf FCF_OpenTemporaryWindow wird beim nächsten Anwenden gesetzt
FCF_OpenTemporaryWindow()
expect("temporäres Fenster verblasst nicht", whisperFrame:GetFading(), false)

-- Alles aus: Originalwerte zurück
for _, setting in ipairs({ "noChatFade", "chatArrowKeys", "hideChatButtons", "chatEditBoxTop", "hideCombatLogTab" }) do
  addon.Set(setting, false)
end
expect("verblasst wieder", chat1:GetFading(), true)
expect("Alt wieder nötig", chat1.editBox:GetAltArrowKeyMode(), true)
expect("Knopfleiste zurück", chat1.buttonFrame:GetParent(), chat1)
expect("Menü-Button zurück", ChatFrameMenuButton:GetParent(), chat1.buttonFrame)
expect("Sprach-Button zurück", ChatFrameToggleVoiceMuteButton:GetParent(), UIParent)
expect("Eingabe-Anker zurück", chat1.editBox._points[1][1], originalEditBoxPoint[1])
expect("Eingabe-Anker zurück (Ziel)", chat1.editBox._points[1][3], originalEditBoxPoint[3])
expect("Kampflog-Reiter normal", ChatFrame2Tab:GetScale(), 1)
expect("Kampflog-Reiter klickbar", ChatFrame2Tab:IsMouseEnabled(), true)
FCFDock_UpdateTabs()
expect("aus: Dock-Update ändert nichts", ChatFrame2Tab:GetScale(), 1)

-- Abgedocktes Kampflog bleibt sichtbar
chat2.isDocked = false
addon.Set("hideCombatLogTab", true)
expect("abgedockt: Reiter bleibt", ChatFrame2Tab:GetScale(), 1)
expect("keine Fehler", #wow.errors, 0)
