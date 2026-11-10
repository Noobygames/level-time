-- Auswahlliste mit Suche (Roadmap 477): öffnen, filtern, Enter wählt den ersten Treffer, Pfeiltasten überspringen
-- Gruppen-Überschriften, Auswahl setzt die Einstellung, Schließen per Esc, Klick daneben und Verbergen des Knopfs.
local L = addon.L
local Dropdown = addon.Dropdown

wow.login({ level = 10 })

local picked
local builder = addon.OptionsBuilder.New({ name = "LevelTimerTestDropdown", alpha = 0.9, title = function() return "Test" end })
builder.AddPage("OPTIONS_TAB_GENERAL")
local NAMES = { "Alpha", "Beta", "Cafe", "Café Noir", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Julia", "Kilo" }
builder.AddDropdown({
  label = "LANGUAGE",
  choices = function()
    local list = {}
    for i, name in ipairs(NAMES) do list[i] = { key = i, group = i <= 6 and "Erste" or "Zweite" } end
    return list
  end,
  get = function() return picked or 1 end,
  set = function(key) picked = key end,
  nameOf = function(key) return NAMES[key] end,
})
builder.AddDropdown({
  label = "THEME",
  choices = function() return { { key = "a" }, { key = "b" } } end,
  get = function() return "a" end,
  set = function(key) picked = key end,
  nameOf = function(key) return "Mode " .. key:upper() end,
})
builder.FinishPage()
builder.Finish()
builder.panel:Show()
builder.Refresh(addon.db)

local function dropdownButton(text)
  return wow.findFrame(function(frame)
    return frame._scripts.OnClick ~= nil and rawget(frame, "label") ~= nil and frame.label._text == text
  end)
end
local function click(button) button._scripts.OnClick(button, "LeftButton") end
local function texts()
  local list = {}
  for _, row in ipairs(Dropdown.State().rows) do list[#list + 1] = row.text end
  return list
end
local function type_(text)
  local box = Dropdown.State().search
  box:SetText(text)
  box._scripts.OnTextChanged(box, true)
end

local button = dropdownButton("Alpha")
expectTrue("Knopf zeigt die Wahl", button ~= nil)
expect("zu", Dropdown.IsOpen(), false)

click(button)
local state = Dropdown.State()
expect("offen", state.open, true)
expect("Suchfeld ab 8 Einträgen", state.searchable, true)
expect("Überschrift + 12 Einträge + Überschrift", #state.rows, 14)
expect("erste Zeile ist Überschrift", state.rows[1].header, true)
expect("Überschrift Text", state.rows[1].text, "Erste")
expect("aktuelle Wahl markiert", state.rows[2].selected and state.rows[2].highlighted, true)

-- Pfeiltasten: Überschrift "Zweite" (Zeile 8) wird übersprungen
local box = state.search
for _ = 1, 5 do box._scripts.OnArrowPressed(box, "DOWN") end
local rows = Dropdown.State().rows
expect("Markierung auf Foxtrot", rows[7].highlighted, true)
box._scripts.OnArrowPressed(box, "DOWN")
rows = Dropdown.State().rows
expect("Überschrift übersprungen", rows[9].highlighted, true)
expect("Überschrift nicht markiert", rows[8].highlighted, false)
box._scripts.OnArrowPressed(box, "UP")
expect("zurück über die Überschrift", Dropdown.State().rows[7].highlighted, true)

-- Filter: Groß-/Kleinschreibung und Akzente egal, leere Gruppen fallen weg
type_("CAFE")
expect("Filter: Überschrift + 2 Treffer", #texts(), 3)
expect("Filter: Akzent gefunden", texts()[3], "Café Noir")
type_("golf")
expect("Filter: Gruppe Zweite", table.concat(texts(), ","), "Zweite,Golf")
type_("zzz")
expect("Filter ohne Treffer: keine Einträge", #Dropdown.State().rows, 1)
type_("de")
expect("Enter wählt den ersten Treffer", Dropdown.State().rows[2].highlighted, true)
box._scripts.OnEnterPressed(box)
expect("Auswahl gesetzt", picked, 5)
expect("nach Auswahl zu", Dropdown.IsOpen(), false)

-- Esc schließt nur die Liste
builder.Refresh(addon.db)
click(dropdownButton("Delta"))
expect("wieder offen", Dropdown.IsOpen(), true)
Dropdown.State().search._scripts.OnEscapePressed(Dropdown.State().search)
expect("Esc schließt", Dropdown.IsOpen(), false)
expect("Fenster bleibt", builder.panel:IsShown(), true)

-- Kurze Liste: ohne Suchfeld, Enter wählt die Markierung
click(dropdownButton("Mode A"))
expect("kurze Liste ohne Suche", Dropdown.State().searchable, false)
box = Dropdown.State().search
box._scripts.OnArrowPressed(box, "DOWN")
box._scripts.OnEnterPressed(box)
expect("kurze Liste gewählt", picked, "b")

-- Klick daneben (durchsichtige Fläche) und Verbergen des Knopfs schließen
click(dropdownButton("Mode A"))
local catcher = Dropdown.State().catcher
catcher._scripts.OnMouseDown(catcher)
expect("Klick daneben schließt", Dropdown.IsOpen(), false)
click(dropdownButton("Mode A"))
dropdownButton("Mode A"):Hide()
expect("Knopf verborgen schließt", Dropdown.IsOpen(), false)

-- Suche im Einstellungsfenster findet die Steuerelemente über ihre Beschriftung
SlashCmdList.LEVELTIMER("config")
local found = {}
for _, entry in ipairs(addon.OptionsWindow.Search(L.THEME_FONT)) do found[#found + 1] = entry.tipKey end
expectTrue("Schrift auffindbar", #found > 0)
