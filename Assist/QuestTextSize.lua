-- Questtext-Größe (Reiter Komfort, Quest-Anzeige; questTextResize, Standard aus): Blizzards Quest-Schriften bekommen
-- die Größe questTextSize, Überschriften TITLE_EXTRA Punkte mehr. Die Font-Objekte stehen in allen vier Clients in
-- Blizzard_Fonts_Shared/Shared (FontStyles.xml, GameFontStyles.xml): QuestFont, QuestFontLeft, QuestFontNormalSmall
-- (Text und Ziele), QuestTitleFont, QuestTitleFontBlackShadow (Überschriften). Wie Blizzard selbst geändert per
-- SetFont am Font-Objekt (Schrift und Kontur bleiben), umkehrbar über Overrides; Font-Objekte sind nicht geschützt.
-- Alles, was diese Schriften erbt (z.B. Teile des Dungeonbrowsers), wächst mit.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questTextResize = false,
    questTextSize = 14,
  },
})

local QuestTextSize = {}
ns.QuestTextSize = QuestTextSize

QuestTextSize.MIN = 10
QuestTextSize.MAX = 24
QuestTextSize.TITLE_EXTRA = 4
QuestTextSize.BODY_FONTS = { "QuestFont", "QuestFontLeft", "QuestFontNormalSmall" }
QuestTextSize.TITLE_FONTS = { "QuestTitleFont", "QuestTitleFontBlackShadow" }

local setFont = ns.Overrides.New(
  function(font) return font:GetFont() end,
  function(font, face, size, flags) font:SetFont(face, size, flags) end)

local function fontOf(name)
  local font = _G[name]
  if type(font) == "table" and font.GetFont and font.SetFont then return font end
end

function QuestTextSize.IsAvailable()
  return fontOf(QuestTextSize.BODY_FONTS[1]) ~= nil
end

local function apply(names, enabled, size)
  for _, name in ipairs(names) do
    local font = fontOf(name)
    if font then
      local face, _, flags = font:GetFont()
      setFont(font, enabled and face ~= nil, face, size, flags)
    end
  end
end

ns.RegisterApply(function(db)
  local size = math.max(QuestTextSize.MIN, math.min(QuestTextSize.MAX, tonumber(db.questTextSize) or QuestTextSize.MIN))
  local enabled = db.questTextResize == true
  apply(QuestTextSize.BODY_FONTS, enabled, size)
  apply(QuestTextSize.TITLE_FONTS, enabled, size + QuestTextSize.TITLE_EXTRA)
end)
