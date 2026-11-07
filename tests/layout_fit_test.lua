-- Texte passen in ihre Fenster: Einstellungen wachsen mit der Sprache, Unterreiter der Historie brechen um.
local L = addon.L

wow.login()

-- Klickbares Element (Schalter, Reiter) mit dieser Beschriftung; Überschriften zählen nicht
local function findByLabel(text)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == text and frame._points[1] ~= nil and frame._scripts.OnClick ~= nil
  end)
end

-- x-Abstand eines Ankers "TOPLEFT", x, y zum Elternfenster
local function anchorX(frame)
  local point = frame._points[1]
  return point[#point - 1]
end

---------------------------------------------------------------------------
-- Einstellungen: Schalter in einer Zeile überlappen nicht, Sprachwahl passt ins Fenster
---------------------------------------------------------------------------
local options = LevelTimerOptions

local function checkOptions(language)
  addon.Set("language", language)
  SlashCmdList.LEVELTIMER("config")

  -- Schalterpaare in einer Zeile, je Reiter eins: links und rechts überlappen nicht. Schalter auf Unterseiten stehen
  -- rechts neben der Seitenleiste (Versatz der Unterseite)
  local function subPageOffset(frame)
    local parent = frame:GetParent()
    return parent and parent._points[1] and anchorX(parent) or 0
  end
  for _, pair in ipairs({
    { "SHOW_XP_BAR", "AUTO_INSTANCE_TAB" },
    { "STAT_XP_RATE", "STAT_RECENT_XP_RATE" },
    { "ALERT_TOGGLE_LEVEL_UP", "ALERT_TOGGLE_RARE" },
    { "WARN_BAGS_FULL_TOGGLE", "WARN_DURABILITY_TOGGLE" },
    { "AUTO_ACCEPT_QUESTS", "AUTO_ACCEPT_SHARED" },
  }) do
    local left, right = findByLabel(L[pair[1]]), findByLabel(L[pair[2]])
    local leftEnd = anchorX(left) + left:GetWidth() + addon.Widgets.CHECKBOX_LABEL_GAP + left.label:GetStringWidth()
    expectTrue(language .. ": " .. pair[2] .. " beginnt hinter " .. pair[1], anchorX(right) > leftEnd)
    expectTrue(language .. ": " .. pair[2] .. " passt ins Fenster",
      subPageOffset(right) + anchorX(right) + right:GetWidth() + right.label:GetStringWidth() <= options:GetWidth())
  end

  -- Seitenleisten: jede Unterseite beginnt rechts neben dem breitesten Eintrag aller Leisten
  local offset = subPageOffset(findByLabel(L.SHOW_XP_BAR))
  expectTrue(language .. ": Fenster-Schalter auf einer Unterseite", offset > 0)
  for _, page in ipairs(addon.OptionsWindow.PageKeys()) do
    if page.sub then
      local entry = findByLabel(L[page.sub])
      expectTrue(language .. ": Leiste " .. page.sub, entry and entry:GetWidth() < offset)
    end
  end

  -- Suchfeld links und Titel in der Mitte überlappen nicht
  local search = LevelTimerOptionsSearch
  local titleWidth = (addon.DISPLAY_NAME .. " - " .. L.SETTINGS):len() * 6
  expectTrue(language .. ": Suchfeld neben dem Titel",
    16 + search:GetWidth() + 6 <= (options:GetWidth() - titleWidth) / 2)

  -- Sprachwahl: Beschriftung und alle Reiter nebeneinander
  local row = L.LANGUAGE:len() * 6
  for _, entry in ipairs(addon.languages) do
    row = row + findByLabel(entry.name):GetWidth()
  end
  expectTrue(language .. ": Sprachwahl passt ins Fenster", row < options:GetWidth())

  SlashCmdList.LEVELTIMER("config")  -- schließen
end

checkOptions("deDE")
checkOptions("frFR")
checkOptions("esES")

---------------------------------------------------------------------------
-- Historie: Unterreiter der Graphen bleiben in der Breite, der Inhalt rückt nach unten
---------------------------------------------------------------------------
addon.Set("language", "deDE")
SlashCmdList.LEVELTIMER("history")
local history = LevelTimerHistory
expectTrue("Reiter Graphen", wow.click(L.HISTORY_TAB_CHARTS))

local SUBTABS_TOP = -88  -- wie in HistoryWindow.lua
local SINGLE_ROW_HEIGHT = 110 + addon.HistoryWindow.CONTENT_HEIGHT + 16  -- Fenster mit einer Unterreiter-Zeile
local contentRight = 16 + addon.HistoryWindow.CONTENT_WIDTH

-- Unterreiter: sichtbare Buttons mit Anker "TOPLEFT", x, y ab der Unterreiter-Zeile
local subtabs = {}
wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  local point = frame._points[1]
  if label and frame:IsShown() and point and point[1] == "TOPLEFT" and #point == 3 and type(point[3]) == "number" and point[3] <= SUBTABS_TOP then
    table.insert(subtabs, frame)
  end
  return false
end)
expectTrue("Unterreiter gefunden", #subtabs > 5)

local wrapped = false
for _, subtab in ipairs(subtabs) do
  local x, y = subtab._points[1][2], subtab._points[1][3]
  expectTrue("Unterreiter " .. subtab.label._text .. " in der Breite", x + subtab:GetWidth() <= contentRight)
  if y < SUBTABS_TOP then wrapped = true end
end
expectTrue("Unterreiter brechen in eine zweite Zeile um", wrapped)
expectTrue("Fenster wächst mit den Zeilen", history:GetHeight() > SINGLE_ROW_HEIGHT)

-- Buttons mit übersetztem Text werden so breit wie ihr Text (Historie: Daten löschen, Profil speichern)
for _, language in ipairs({ "frFR", "esES", "deDE", "enUS" }) do
  addon.Set("language", language)
  SlashCmdList.LEVELTIMER("history")
  local deleteButton = wow.findFrame(function(frame) return frame._text == addon.L.DELETE_CHARACTER end)
  expectTrue(language .. ": Löschen-Button passt", deleteButton and deleteButton:GetWidth() >= deleteButton:GetTextWidth())
  SlashCmdList.LEVELTIMER("config")
  local saveButton = wow.findFrame(function(frame) return frame._text == addon.L.PROFILE_SAVE end)
  expectTrue(language .. ": Speichern-Button passt", saveButton and saveButton:GetWidth() >= saveButton:GetTextWidth())
end
