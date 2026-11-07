-- Reiterzeile: Reiter (Widgets.CreateTab) nebeneinander, von links nach rechts. Ohne maxWidth hängt jeder Reiter am
-- vorigen (wächst mit den Texten von selbst); mit maxWidth ordnet Layout() sie in Zeilen an und bricht um, sobald
-- ein Reiter nicht mehr passt (Unterreiter der Historie in langen Sprachen).
local _, ns = ...
local Widgets = ns.Widgets

local TabStrip = {}
ns.TabStrip = TabStrip

-- options = { font, left, top (Anker TOPLEFT am parent), gap, maxWidth (optional: umbrechen), rowHeight (mit maxWidth) }
function TabStrip.New(parent, options)
  local strip = { tabs = {} }

  -- Neuer Reiter am Ende; onClick wie bei Widgets.CreateTab
  function strip:Add(onClick)
    local tab = Widgets.CreateTab(parent, options.font, onClick)
    local previous = self.tabs[#self.tabs]
    if not options.maxWidth then
      if previous then
        tab:SetPoint("LEFT", previous, "RIGHT", options.gap, 0)
      else
        tab:SetPoint("TOPLEFT", options.left, options.top)
      end
    end
    table.insert(self.tabs, tab)
    return tab
  end

  -- Nur mit maxWidth: Reiter in Zeilen anordnen (erwartet gesetzte Beschriftungen); gibt die Zahl der Zeilen zurück
  function strip:Layout()
    local x, row = 0, 0
    for _, tab in ipairs(self.tabs) do
      local width = tab:GetWidth()
      if x > 0 and x + width > options.maxWidth then
        x, row = 0, row + 1
      end
      tab:ClearAllPoints()
      tab:SetPoint("TOPLEFT", options.left + x, options.top - row * options.rowHeight)
      x = x + width + options.gap
    end
    return row + 1
  end

  -- Breite aller Reiter in einer Zeile samt Abständen
  function strip:Width()
    local width = 0
    for i, tab in ipairs(self.tabs) do
      width = width + tab:GetWidth() + (i > 1 and options.gap or 0)
    end
    return width
  end

  return strip
end
