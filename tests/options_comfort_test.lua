-- Komfort-Reiter mit Seitenleiste wie Leatrix Plus: je Kategorie eine Unterseite, nur eine sichtbar, rechts neben
-- der Seitenleiste und im Fenster
local L = addon.L

wow.login()

local function findByLabel(text)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == text and frame._points[1] ~= nil and frame._scripts.OnClick ~= nil
  end)
end

local function anchorX(frame)
  local point = frame._points[1]
  return point[#point - 1]
end

for _, language in ipairs({ "deDE", "frFR" }) do
  addon.Set("language", language)
  SlashCmdList.LEVELTIMER("config")
  expectTrue(language .. ": Reiter Komfort", wow.click(L.OPTIONS_TAB_COMFORT))

  local repair, duels = findByLabel(L.AUTO_REPAIR), findByLabel(L.DECLINE_DUELS)
  local automation, social = repair:GetParent(), duels:GetParent()
  expectTrue(language .. ": eigene Unterseiten", automation ~= social)
  expect(language .. ": Automatik zuerst", automation:IsShown(), true)
  expect(language .. ": Sozial verdeckt", social:IsShown(), false)

  expectTrue(language .. ": Sozial wählen", wow.click(L.COMFORT_PAGE_SOCIAL))
  expect(language .. ": Sozial sichtbar", social:IsShown(), true)
  expect(language .. ": Automatik verdeckt", automation:IsShown(), false)

  -- Unterseite rechts neben dem breitesten Eintrag der Seitenleiste, Schalter passen ins Fenster
  local entry = findByLabel(L.COMFORT_PAGE_AUTOMATION)
  local offset = anchorX(automation)
  expectTrue(language .. ": Unterseite neben der Leiste", offset >= entry:GetWidth())
  local guild = findByLabel(L.AUTO_SELL_JUNK)
  expectTrue(language .. ": rechte Spalte im Fenster",
    offset + anchorX(guild) + guild:GetWidth() + guild.label:GetStringWidth() <= LevelTimerOptions:GetWidth())
  wow.click(L.COMFORT_PAGE_AUTOMATION)
  LevelTimerOptions:Hide()
end
-- Stichwort fürs Einladen per Flüstern: Eingabefeld auf der Sozial-Seite, übernommen beim Verlassen des Felds
SlashCmdList.LEVELTIMER("config")
wow.click(L.OPTIONS_TAB_COMFORT)
wow.click(L.COMFORT_PAGE_SOCIAL)
-- Eingabefelder über den Suchindex: Sperrliste der Quest-Automatik (Seite Quests) und Stichwort (Seite Sozial)
local function inputBox(labelKey)
  for _, entry in ipairs(addon.OptionsWindow.Search(L[labelKey])) do
    if entry.tipKey == labelKey .. "_TIP" then return entry.right end
  end
end
local excludeBox, keywordBox = inputBox("QUEST_EXCLUDE"), inputBox("INVITE_KEYWORD")
expect("Sperrliste leer", excludeBox:GetText(), "")
expect("Feld zeigt das Stichwort", keywordBox:GetText(), "inv")
keywordBox:SetText(" einladen ")
keywordBox._scripts.OnEditFocusLost(keywordBox)
expect("Stichwort übernommen", addon.db.inviteKeyword, "einladen")
keywordBox:SetText("verworfen")
keywordBox._scripts.OnEscapePressed(keywordBox)
expect("Esc verwirft", keywordBox:GetText(), "einladen")
LevelTimerOptions:Hide()
expect("keine Fehler", #wow.errors, 0)
