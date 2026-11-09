-- Rückfragen abkürzen (Reiter Komfort, System; je Einstellung, Standard aus):
--   easyDelete       Gegenstand löschen ohne das Bestätigungswort zu tippen: bei DELETE_ITEM_CONFIRM steht das Wort
--                    (DELETE_ITEM_CONFIRM_STRING, z.B. "LÖSCHEN") schon im Eingabefeld des Dialogs; Blizzards
--                    OnTextChanged gibt dann wie beim Tippen die Taste frei, löschen bleibt ein eigener Klick.
--   fasterMovieSkip  Zwischensequenzen und Filme mit Esc, Leertaste oder Enter ohne Rückfrage beenden: die
--                    Bestätigung des Blizzard-Dialogs (CinematicFrameCloseDialogConfirmButton bzw.
--                    MovieFrame.CloseDialog) wird direkt geklickt. Nur per HookScript, Blizzards Skripte bleiben.
-- Dialognamen wie in Blizzards StaticPopup.lua (DELETE_GOOD_ITEM, DELETE_GOOD_QUEST_ITEM); Rahmen StaticPopup1..N
-- mit .which und Eingabefeld (.editBox, .EditBox oder <Name>EditBox, je nach Client).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    easyDelete = false,
    fasterMovieSkip = false,
  },
})

local SkipDialogs = {}
ns.SkipDialogs = SkipDialogs

local MAX_POPUPS = 4
local TYPED_DELETE = { DELETE_GOOD_ITEM = true, DELETE_GOOD_QUEST_ITEM = true }
local SKIP_KEYS = { ESCAPE = true, SPACE = true, ENTER = true }

-- Unterrahmen als Feld; nur Tabellen zählen (Clients ohne das Feld liefern nil)
local function child(frame, key)
  local value = frame and frame[key]
  return type(value) == "table" and value or nil
end

local function editBoxOf(dialog)
  return child(dialog, "editBox") or child(dialog, "EditBox") or child(_G, dialog:GetName() .. "EditBox")
end

-- Sichtbarer Lösch-Dialog, der das Bestätigungswort verlangt
local function typedDeleteDialog()
  for index = 1, MAX_POPUPS do
    local dialog = _G["StaticPopup" .. index]
    if dialog and dialog:IsShown() and TYPED_DELETE[dialog.which] then return dialog end
  end
  return nil
end

local function onDeleteConfirm()
  if not ns.db.easyDelete or not DELETE_ITEM_CONFIRM_STRING then return end
  local dialog = typedDeleteDialog()
  local editBox = dialog and editBoxOf(dialog)
  if not editBox then return end
  ns.Debug("comfort", "delete confirm word filled in")
  editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end

local function clickIfShown(button)
  if button and button:IsShown() then button:Click() end
end

local function confirmButtonOf(movieFrame)
  local dialog = child(movieFrame, "CloseDialog")
  return child(child(dialog, "Buttons"), "ConfirmButton") or child(dialog, "ConfirmButton")
end

local hooked = {}
local function hookSkip(frame, confirm)
  if not frame or hooked[frame] then return end
  hooked[frame] = true
  frame:HookScript("OnKeyUp", function(_, key)
    if ns.db.fasterMovieSkip and SKIP_KEYS[key] then clickIfShown(confirm()) end
  end)
end

local function hookMovies()
  hookSkip(CinematicFrame, function() return CinematicFrameCloseDialogConfirmButton end)
  if MovieFrame then hookSkip(MovieFrame, function() return confirmButtonOf(MovieFrame) end) end
end

ns.RegisterEvent("DELETE_ITEM_CONFIRM", onDeleteConfirm)
ns.OnLogin(hookMovies)
-- MovieFrame ist in manchen Clients ein eigenes Blizzard-Addon und kommt später
ns.RegisterEvent("ADDON_LOADED", function() if MovieFrame then hookMovies() end end)
