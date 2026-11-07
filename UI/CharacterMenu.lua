-- Ausklappliste aller gespeicherten Charaktere (Historie): Klick auf einen Namen wählt ihn, mehr als MENU_ROWS Einträge
-- scrollen mit dem Mausrad, ein Klick daneben oder ESC schließt sie. Namen in Klassenfarbe.
local _, ns = ...
local Widgets = ns.Widgets
local Theme = ns.Theme
local History = ns.History

local CharacterMenu = {}
ns.CharacterMenu = CharacterMenu

local MENU_ROWS = 12
local MENU_ROW_HEIGHT = 18
local MENU_PADDING = 8
local MENU_ALPHA = 0.98
local ANCHOR_GAP = 4
local NAME_COLOR = { 1, 1, 1 }  -- ohne bekannte Klasse

-- options = { name = globaler Rahmenname, anchor = Element, unter dem die Liste aufklappt,
--             onSelect = function(characterKey) }; parent = Fenster, in dem ein Klick daneben schließt
function CharacterMenu.Create(parent, options)
  local menu = CreateFrame("Frame", options.name, parent, "BackdropTemplate")
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetBackdrop({ bgFile = Widgets.WHITE_TEXTURE, edgeFile = Widgets.WHITE_TEXTURE, edgeSize = 1 })
  local r, g, b = Theme.RGB("background")
  menu:SetBackdropColor(r, g, b, MENU_ALPHA)
  menu:SetBackdropBorderColor(unpack(Widgets.COLORS.border))
  menu:EnableMouse(true)
  menu:EnableMouseWheel(true)
  menu:Hide()
  table.insert(UISpecialFrames, options.name)

  -- Unsichtbarer Fänger hinter dem Menü: ein Klick irgendwo im Fenster schließt es
  local catcher = CreateFrame("Button", nil, parent)
  catcher:SetAllPoints(parent)
  catcher:SetFrameStrata("FULLSCREEN_DIALOG")
  catcher:SetFrameLevel(menu:GetFrameLevel() - 1)
  catcher:SetScript("OnClick", function() menu:Hide() end)
  catcher:Hide()
  menu:HookScript("OnShow", function() catcher:Show() end)
  menu:HookScript("OnHide", function() catcher:Hide() end)

  local rows = {}
  local offset = 0

  local function refresh()
    local keys = History.GetCharacterKeys()
    offset = math.max(0, math.min(offset, #keys - MENU_ROWS))
    local shown = math.min(#keys, MENU_ROWS)
    local widest = 0
    for i = 1, shown do
      local row = rows[i]
      if not row then
        row = Widgets.CreateTab(menu, "GameFontHighlight", function(self)
          menu:Hide()
          options.onSelect(self.characterKey)
        end)
        row:SetPoint("TOPLEFT", MENU_PADDING, -MENU_PADDING - (i - 1) * MENU_ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", -MENU_PADDING, -MENU_PADDING - (i - 1) * MENU_ROW_HEIGHT)
        rows[i] = row
      end
      local key = keys[i + offset]
      row.characterKey = key
      row:SetLabel(History.DisplayName(key))
      row.label:SetTextColor(unpack(Theme.ClassColor(History.GetCharacter(key).class, NAME_COLOR)))
      row:Show()
      widest = math.max(widest, row:GetWidth())
    end
    for i = shown + 1, #rows do rows[i]:Hide() end
    menu:SetSize(widest + 2 * MENU_PADDING, shown * MENU_ROW_HEIGHT + 2 * MENU_PADDING)
  end

  menu:SetScript("OnMouseWheel", function(_, delta)
    offset = offset - delta
    refresh()
  end)

  local self = {}

  function self.Hide()
    menu:Hide()
  end

  -- Auf- oder zuklappen
  function self.Toggle()
    if menu:IsShown() then
      menu:Hide()
      return
    end
    refresh()
    menu:ClearAllPoints()
    menu:SetPoint("TOP", options.anchor, "BOTTOM", 0, -ANCHOR_GAP)
    menu:Show()
  end

  return self
end
