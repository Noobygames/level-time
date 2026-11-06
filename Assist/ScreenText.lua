-- Texte auf dem Bildschirm ausblenden (Reiter Komfort, Oberfläche; je Einstellung, Standard aus):
--   hideErrors    rote Fehlermeldungen ("Nicht genug Mana", "Ziel ist nicht im Sichtfeld") ausblenden; wichtige
--                 (IMPORTANT_ERRORS: Taschen voll, Questlog voll, tot, ...) bleiben. UIErrorsFrame hört dafür nicht
--                 mehr auf UI_ERROR_MESSAGE, wir zeigen die wichtigen selbst (AddMessage in Blizzards Fehlerfarbe).
--                 Gelbe Hinweise (UI_INFO_MESSAGE) bleiben unberührt. Ausgeschaltet bekommt das Fenster das Event
--                 zurück. Blizzards OnEvent wird nicht ersetzt (kein Taint).
--   hideZoneText  Zonen- und Unterzonentext beim Betreten eines Gebiets ausblenden (ZoneTextFrame, SubZoneTextFrame).
local _, ns = ...

local ScreenText = {}
ns.ScreenText = ScreenText

local ERROR_EVENT = "UI_ERROR_MESSAGE"
local ERROR_COLOR = { 1, 0.1, 0.1 }
-- Globale Texte der Meldungen, die trotz hideErrors erscheinen (fehlende gibt es im Client nicht)
local IMPORTANT_ERRORS = { "ERR_INV_FULL", "ERR_QUEST_LOG_FULL", "ERR_PLAYER_DEAD", "ERR_PET_SPELL_DEAD",
  "ERR_RAID_GROUP_ONLY", "ERR_ITEM_MAX_COUNT", "ERR_NOT_ENOUGH_MONEY" }

local errorsHidden = false
local importantErrors

local function important()
  if not importantErrors then
    importantErrors = {}
    for _, key in ipairs(IMPORTANT_ERRORS) do
      if _G[key] then importantErrors[_G[key]] = true end
    end
  end
  return importantErrors
end

-- true, wenn die Meldung trotz hideErrors erscheint (geheime Texte lassen sich nicht prüfen: zeigen)
function ScreenText.IsImportant(message)
  return ns.IsSecret(message) or important()[message] == true
end

local function onError(_, message)
  if not errorsHidden or not message or not ScreenText.IsImportant(message) then return end
  UIErrorsFrame:AddMessage(message, unpack(ERROR_COLOR))
end

local function applyErrors()
  local hide = ns.db.hideErrors == true
  if hide == errorsHidden or not UIErrorsFrame then return end
  errorsHidden = hide
  if hide then
    UIErrorsFrame:UnregisterEvent(ERROR_EVENT)
  else
    UIErrorsFrame:RegisterEvent(ERROR_EVENT)
  end
end

local zoneHooked = false
local function hookZoneText()
  if zoneHooked then return end
  zoneHooked = true
  for _, frame in ipairs({ ZoneTextFrame, SubZoneTextFrame }) do
    frame:HookScript("OnShow", function(self)
      if ns.db.hideZoneText then self:Hide() end
    end)
  end
end

ns.RegisterApply(function()
  applyErrors()
  if ns.db.hideZoneText and ZoneTextFrame and SubZoneTextFrame then hookZoneText() end
end)
ns.RegisterEvent(ERROR_EVENT, onError)
