-- Rückfragen abkürzen: Bestätigungswort beim Löschen vorausgefüllt, Filme ohne Rückfrage beenden
wow.login({ level = 20 })

local function showDelete(which)
  StaticPopup1.which = which
  StaticPopup1:Show()
  StaticPopup1EditBox:SetText("")
  wow.fire("DELETE_ITEM_CONFIRM", "Mondsichelstab", 3, 1)
end

showDelete("DELETE_GOOD_ITEM")
expect("aus: Feld leer", StaticPopup1EditBox:GetText(), "")
addon.Set("easyDelete", true)
showDelete("DELETE_GOOD_ITEM")
expect("Wort vorausgefüllt", StaticPopup1EditBox:GetText(), DELETE_ITEM_CONFIRM_STRING)
showDelete("DELETE_ITEM")
expect("einfacher Dialog ohne Feld: nichts", StaticPopup1EditBox:GetText(), "")
StaticPopup1:Hide()

local function pressKey(key)
  CinematicFrame._scripts.OnKeyUp(CinematicFrame, key)
end
pressKey("ESCAPE")
expect("aus: keine Bestätigung", rawget(CinematicFrameCloseDialogConfirmButton, "_clicks"), nil)
addon.Set("fasterMovieSkip", true)
pressKey("ESCAPE")
expect("Esc bestätigt", rawget(CinematicFrameCloseDialogConfirmButton, "_clicks"), 1)
pressKey("W")
expect("andere Taste: nichts", rawget(CinematicFrameCloseDialogConfirmButton, "_clicks"), 1)
expect("keine Fehler", #wow.errors, 0)
