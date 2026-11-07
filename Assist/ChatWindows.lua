-- Chatfenster anpassen (Reiter Komfort, Chat; je Einstellung, Standard aus). Alles umkehrbar ohne /reload: beim
-- ersten Ändern merkt sich das Modul den Originalwert und setzt ihn beim Ausschalten zurück.
--   hideCombatLogTab  Reiter des Kampflogs (ChatFrame2Tab) unsichtbar und nicht klickbar: auf 1 % skaliert, damit
--                     die übrigen Reiter im Dock (an ihm verankert) aufrücken; nach jedem FCFDock_UpdateTabs neu
--                     gesetzt (hooksecurefunc). Nur angedockt; war das Kampflog gewählt, wird Fenster 1 gewählt.
--   hideChatButtons   Menü-, Kanal-, Sprach- und Sozial-Knöpfe und die Knopfleiste je Fenster (Classic: Blättern)
--                     an einen versteckten Rahmen gehängt. Blizzard blendet die Leiste beim Überfahren mit
--                     UIFrameFadeIn wieder ein, daher Elternwechsel statt Hide; FCF_SetFullScreenFrame hängt nur
--                     Rahmen um, deren Eltern noch der alte Vollbildrahmen ist, unseren also nicht. Mausrad blättert.
--   chatEditBoxTop    Eingabezeile über den Reitern statt unter dem Fenster (Anker des EditBox).
--   chatArrowKeys     Pfeiltasten bewegen den Cursor in der Eingabezeile ohne Alt (EditBox:SetAltArrowKeyMode).
--   noChatFade        Text verblasst nicht (ScrollingMessageFrame:SetFading).
--   unclampChat       Fenster bis an den Bildschirmrand ziehen: Klemm-Abstände 0 (SetClampRectInsets; Classic setzt
--                     -35/35/26/-50 in FloatingChatFrame.lua und nach FloatingChatFrame_UpdateBackgroundAnchors neu,
--                     dort per hooksecurefunc nachgezogen). Am Bildschirm geklemmt bleibt das Fenster.
-- Fenster: ns.ChatFrames() und temporäre Fenster (Flüstern, Haustierkampf) aus Blizzards Liste CHAT_FRAMES; neue
-- temporäre Fenster nach FCF_OpenTemporaryWindow. Keins der Fenster ist geschützt, im Kampf geht es daher auch.
local _, ns = ...

local ChatWindows = {}
ns.ChatWindows = ChatWindows

local HIDDEN_TAB_SCALE = 0.01  -- unsichtbar, aber Blizzards Reiter-Layout bleibt intakt
local EDIT_BOX_INSET = 5       -- wie Blizzards Anker: Eingabezeile ragt links und rechts etwas hinaus
local EDIT_BOX_GAP = 2
local DEFAULT_TAB_HEIGHT = 24  -- falls ein Fenster keinen Reiter hat

-- Buttons am Chat, je Client verschieden; fehlende Namen fallen weg (FloatingChatFrame*.xml, QuickJoin)
ChatWindows.BUTTONS = {
  "ChatFrameMenuButton", "ChatFrameChannelButton", "ChatFrameToggleVoiceDeafenButton",
  "ChatFrameToggleVoiceMuteButton", "QuickJoinToastButton", "FriendsMicroButton", "TextToSpeechButtonFrame",
}

-- Alle Chatfenster inklusive temporärer, jedes einmal
function ChatWindows.All()
  local list, seen = {}, {}
  local function add(chatFrame)
    if chatFrame and not seen[chatFrame] then
      seen[chatFrame] = true
      table.insert(list, chatFrame)
    end
  end
  for _, chatFrame in ipairs(ns.ChatFrames()) do add(chatFrame) end
  for _, name in pairs(CHAT_FRAMES or {}) do add(_G[name]) end
  return list
end

local override = ns.Overrides.New

local setFading = override(
  function(chatFrame) return chatFrame:GetFading() end,
  function(chatFrame, fading) chatFrame:SetFading(fading) end)

local setAltArrows = override(
  function(editBox) return editBox:GetAltArrowKeyMode() end,
  function(editBox, mode) editBox:SetAltArrowKeyMode(mode) end)

local setParent = ns.Overrides.Parent()

-- Anker als Liste { point, relativeTo, relativePoint, x, y }
local function readPoints(frame)
  local points = {}
  for index = 1, frame:GetNumPoints() or 0 do
    points[index] = { frame:GetPoint(index) }
  end
  return points
end

local function writePoints(frame, points)
  frame:ClearAllPoints()
  for _, point in ipairs(points) do frame:SetPoint(unpack(point)) end
end

local setPoints = override(readPoints, writePoints)

local setTabHidden = override(
  function(tab) return tab:GetScale(), tab:IsMouseEnabled() end,
  function(tab, scale, mouse)
    tab:SetScale(scale)
    tab:EnableMouse(mouse)
  end)

local holder = ns.Overrides.HiddenParent

local NO_INSETS = 0
local setClampInsets = override(
  function(chatFrame) return chatFrame:GetClampRectInsets() end,
  function(chatFrame, left, right, top, bottom) chatFrame:SetClampRectInsets(left, right, top, bottom) end)

local function applyClamp(chatFrame, enabled)
  setClampInsets(chatFrame, enabled, NO_INSETS, NO_INSETS, NO_INSETS, NO_INSETS)
end

local function editBoxOf(chatFrame)
  return chatFrame.editBox or (chatFrame.GetName and _G[(chatFrame:GetName() or "") .. "EditBox"])
end

local function tabOf(chatFrame)
  return chatFrame.GetName and _G[(chatFrame:GetName() or "") .. "Tab"]
end

local function topPoints(chatFrame)
  local tab = tabOf(chatFrame)
  local lift = (tab and tab:GetHeight() or DEFAULT_TAB_HEIGHT) + EDIT_BOX_GAP
  return {
    { "BOTTOMLEFT", chatFrame, "TOPLEFT", -EDIT_BOX_INSET, lift },
    { "BOTTOMRIGHT", chatFrame, "TOPRIGHT", EDIT_BOX_INSET, lift },
  }
end

local function applyToChatFrame(chatFrame, db)
  setFading(chatFrame, db.noChatFade, false)
  local editBox = editBoxOf(chatFrame)
  setAltArrows(editBox, db.chatArrowKeys, false)
  setPoints(editBox, db.chatEditBoxTop, editBox and topPoints(chatFrame))
  setParent(chatFrame.buttonFrame, db.hideChatButtons, holder())
  applyClamp(chatFrame, db.unclampChat)
end

---------------------------------------------------------------------------
-- Kampflog-Reiter
---------------------------------------------------------------------------
local combatLogHooked = false

local function combatLogTabShouldHide()
  return ns.db ~= nil and ns.db.hideCombatLogTab and ChatFrame2 ~= nil and ChatFrame2.isDocked
end

local function applyCombatLogTab()
  if ChatFrame2Tab then setTabHidden(ChatFrame2Tab, combatLogTabShouldHide(), HIDDEN_TAB_SCALE, false) end
end

-- Ein unsichtbarer Reiter darf nicht gewählt bleiben: Fenster 1 zeigen (nicht aus dem Dock-Hook heraus,
-- FCF_SelectDockFrame ordnet das Dock selbst wieder neu)
local function leaveCombatLog()
  local dock = GENERAL_CHAT_DOCK
  if not (combatLogTabShouldHide() and dock and FCFDock_GetSelectedWindow and FCF_SelectDockFrame) then return end
  if FCFDock_GetSelectedWindow(dock) == ChatFrame2 then FCF_SelectDockFrame(DEFAULT_CHAT_FRAME) end
end

-- Blizzard ordnet die Reiter bei jeder Dock-Änderung neu; der Hook bleibt, prüft aber die Einstellung
local function hookDockUpdates()
  if combatLogHooked or not FCFDock_UpdateTabs then return end
  combatLogHooked = true
  hooksecurefunc("FCFDock_UpdateTabs", function()
    if combatLogTabShouldHide() then applyCombatLogTab() end
  end)
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------
local temporaryHooked = false
local anchorsHooked = false

-- Classic setzt die Klemm-Abstände beim Neuanordnen des Hintergrunds neu (Bildlaufleiste)
local function hookBackgroundAnchors()
  if anchorsHooked or not FloatingChatFrame_UpdateBackgroundAnchors then return end
  anchorsHooked = true
  hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", function(chatFrame)
    if ns.db and ns.db.unclampChat then applyClamp(chatFrame, true) end
  end)
end

function ChatWindows.Apply(db)
  for _, chatFrame in ipairs(ChatWindows.All()) do applyToChatFrame(chatFrame, db) end
  for _, name in ipairs(ChatWindows.BUTTONS) do setParent(_G[name], db.hideChatButtons, holder()) end
  if db.hideCombatLogTab then hookDockUpdates() end
  if db.unclampChat then hookBackgroundAnchors() end
  applyCombatLogTab()
  leaveCombatLog()
  -- Neue temporäre Fenster (z.B. Flüstern in eigenem Fenster) bekommen dieselben Einstellungen
  if not temporaryHooked and FCF_OpenTemporaryWindow then
    temporaryHooked = true
    hooksecurefunc("FCF_OpenTemporaryWindow", function()
      if ns.db then ChatWindows.Apply(ns.db) end
    end)
  end
end

ns.RegisterApply(ChatWindows.Apply)
