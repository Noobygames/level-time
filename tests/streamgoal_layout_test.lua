-- Level Time Goals, Roadmap 433: Anordnung des Fensters /sg in allen vier Sprachen. Zeilen mit Knöpfen, Feldern und
-- Beschriftungen passen in die Breite und überlappen nicht (Breiten aus den Ankern frame._points und den Textbreiten
-- des Stubs); jeder Knopf mit Locale-Key hat einen Tooltip-Text.
local Manager = streamGoal.Manager
local CollectionView = streamGoal.CollectionView
local BingoEditor = streamGoal.BingoEditor
local WheelView = streamGoal.WheelView

local WIDTH = Manager.PAGE_WIDTH
local GAP = Manager.BUTTON_GAP
local CHECKBOX_WIDTH = 26 + addon.Widgets.CHECKBOX_LABEL_GAP
local MIN_BOX_WIDTH = 100     -- Textfelder bleiben benutzbar breit
local MIN_PACK_LABEL = 150    -- Name eines Pakets neben seinen Knöpfen
local MIN_ROW_TEXT = 300      -- Titel eines laufenden Ziels neben Bearbeiten, Abbrechen, + und -

local function rowWidth(widgets)
  local width = 0
  for index, widget in ipairs(widgets) do
    if widget:IsShown() then width = width + widget:GetWidth() + (index > 1 and GAP or 0) end
  end
  return width
end

local function textWidth(fontString)
  return fontString:GetStringWidth()
end

wow.login({ level = 10 })
SlashCmdList.STREAMGOAL("add custom Ragnaros legen")
local running = streamGoal.Goals.Active()[1]
SlashCmdList.STREAMGOAL("")

for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  addon.Set("language", language)
  local L = addon.L

  -- Ziele: "Weitere Optionen" links, Speichern und Hinzufügen rechts in einer Zeile
  Manager.Toggle("goals")
  for _, kind in ipairs({ "level", "custom", "reputation" }) do
    Manager.SelectKind(kind)
    local used = rowWidth({ Manager.extrasButton, Manager.saveOwnButton, Manager.addButton }) + GAP
    expectTrue(language .. ": Knopfzeile Ziele (" .. kind .. ") " .. used, used <= WIDTH)
  end
  Manager.ToggleExtras(true)
  local used = rowWidth({ Manager.extrasButton, Manager.saveOwnButton, Manager.addButton }) + GAP
  expectTrue(language .. ": Knopfzeile aufgeklappt " .. used, used <= WIDTH)
  Manager.ToggleExtras(false)

  -- Laufendes Ziel: Text neben Bearbeiten/Abbrechen/+ noch lesbar; Bearbeiten: Speichern und Beenden in der Breite
  local activeRow = Manager.ActiveRow(running.id)
  expectTrue(language .. ": Text der laufenden Zeile breit genug", activeRow.text:GetWidth() >= MIN_ROW_TEXT)
  Manager.EditGoal(running.id)
  used = rowWidth({ Manager.saveEditButton, Manager.stopEditButton })
  expectTrue(language .. ": Knopfzeile Bearbeiten " .. used, used <= WIDTH)
  Manager.StopEditing()

  -- Bingo: Textfeld neben "Ins Feld", Knopfzeile in der Breite
  Manager.Toggle("bingo")
  expectTrue(language .. ": Bingo-Textfeld breit genug", BingoEditor.textBox:GetWidth() >= MIN_BOX_WIDTH)
  expectTrue(language .. ": Bingo-Knöpfe in der Breite", rowWidth(BingoEditor.Buttons()) <= WIDTH)

  -- Glücksrad: Haken links, Knöpfe rechts in derselben Zeile ohne Überlappung
  Manager.Toggle("wheel")
  local switches = rowWidth(WheelView.switchButtons)
  local spin = WheelView.spinButton:GetWidth()
  for index, check in ipairs(WheelView.checks) do
    local right = CHECKBOX_WIDTH + textWidth(check.label)
    local buttons = index == 1 and switches or spin
    expectTrue(language .. ": Haken " .. index .. " neben den Knöpfen", right + GAP <= WIDTH - buttons)
  end

  -- Sammlung: Unterreiter und Knöpfe oben, Paketzeilen, Speicherzeile, Textfeld der eigenen Ziele
  Manager.Toggle("collection")
  for _, section in ipairs({ "packs", "own" }) do
    CollectionView.SelectSection(section)
    local tabs = 0
    for _, key in ipairs({ "SG_SECTION_PACKS", "SG_SECTION_OWN" }) do tabs = tabs + #L[key] * 6 + 16 + 14 end
    local top = tabs + rowWidth({ CollectionView.importButton, CollectionView.shareOwnButton })
    expectTrue(language .. ": Kopfzeile Sammlung (" .. section .. ") " .. top, top <= WIDTH)
  end
  CollectionView.SelectSection("packs")
  for index, row in ipairs(CollectionView.packRows) do
    if row.key then
      expectTrue(language .. ": Paketname " .. index .. " breit genug", row.label:GetWidth() >= MIN_PACK_LABEL)
    end
  end
  local saveRow = textWidth(CollectionView.nameLabel) + Manager.LABEL_GAP + Manager.BOX_BORDER
    + CollectionView.nameBox:GetWidth() + GAP + CollectionView.saveButton:GetWidth()
  expectTrue(language .. ": Speicherzeile " .. saveRow, saveRow <= WIDTH)
  CollectionView.SelectSection("own")
  expectTrue(language .. ": Textfeld eigene Ziele breit genug", CollectionView.textBox:GetWidth() >= MIN_BOX_WIDTH)
end

-- Jeder Knopf mit Locale-Key hat einen Tooltip-Text in jeder Sprache
local labelled = {}
wow.findFrame(function(frame)
  local key = rawget(frame, "labelKey")
  if type(key) == "string" and key:find("^SG_") then labelled[key] = true end
  return false
end)
expectTrue("Knöpfe mit Locale-Key gefunden", next(labelled) ~= nil)
for key in pairs(labelled) do
  for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
    expectTrue(language .. ": Tooltip " .. key, streamGoal.locales[language][key .. "_TIP"] ~= nil)
  end
end
addon.Set("language", "deDE")
