-- Optionen, Reiter Profile: benannt speichern, je Charakter wählen, teilen.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local Widgets = ns.Widgets
local Builder = ns.OptionsBuilder
local builder, addPage, finishPage, addSection, addButton, addHint, localized = O.builder, O.addPage, O.finishPage, O.addSection, O.addButton, O.addHint, O.localized

local MAX_PROFILE_ROWS = 6     -- so viele Profile listet der Reiter "Profile"
local ROW_PROFILE = 20
local PROFILE_NAME_WIDTH = 160
local PROFILE_SAVE_WIDTH = 120
local PROFILE_LABEL_OFFSET = 4  -- Beschriftung "Neues Profil:" mittig zur Höhe des Felds
local PROFILE_BOX_BORDER = 6    -- InputBoxTemplate zeichnet seinen Rand links außerhalb
local DELETE_PROFILE_POPUP = ns.PopupKey("DELETE_PROFILE")

-- Profile: Liste (Klick wechselt, Rechtsklick löscht), Name + Speichern, Export und Import
local confirmProfileDelete = Widgets.ConfirmPopup(DELETE_PROFILE_POPUP, "PROFILE_DELETE_CONFIRM", function(name)
  if ns.Profiles.Delete(name) then ns.Print(string.format(L.PROFILE_DELETED, ns.Profiles.DisplayName(name))) end
  ns.ApplySettings()
end)

-- Profil nach Rückfrage löschen (Rechtsklick in der Liste und /lt profile delete); nicht löschbare melden sich sofort
function ns.ConfirmProfileDelete(name)
  if not ns.Profiles.CanDelete(name) then
    ns.Print(L.PROFILE_NOT_DELETED)
    return
  end
  confirmProfileDelete(ns.Profiles.DisplayName(name), name)
end

local OVERWRITE_PROFILE_POPUP = ns.PopupKey("OVERWRITE_PROFILE")
local onProfileSaved  -- Rückruf des laufenden Speicherns (leert z.B. das Namensfeld)

local function saveProfile(name)
  if ns.Profiles.SaveAs(name) then
    ns.Print(string.format(L.PROFILE_SAVED, name))
    if onProfileSaved then onProfileSaved() end
    ns.ApplySettings()
  end
end

local confirmOverwrite = Widgets.ConfirmPopup(OVERWRITE_PROFILE_POPUP, "PROFILE_OVERWRITE_CONFIRM", saveProfile)

-- Einstellungen als Profil speichern (Button und /lt profile save); leerer Name meldet sich, ein vorhandenes
-- Profil wird erst nach Rückfrage überschrieben. onSaved läuft nach dem Speichern.
function ns.ConfirmProfileSave(name, onSaved)
  name = strtrim(name or "")
  onProfileSaved = onSaved
  if name == "" then
    ns.Print(L.PROFILE_NAME_EMPTY)
  elseif ns.Profiles.Exists(name) then
    confirmOverwrite(name, name)
  else
    saveProfile(name)
  end
end

-- Liste der Profile: MAX_PROFILE_ROWS Zeilen; mehr Profile per Mausrad oder Scrollleiste erreichbar
local function addProfileList()
  local Profiles = ns.Profiles
  local page = builder.Page()
  local listOffset = 0
  local scrollBar

  local function maxOffset()
    return math.max(0, #Profiles.GetNames() - MAX_PROFILE_ROWS)
  end

  local function scrollTo(offset)
    listOffset = Widgets.ClampOffset(offset, #Profiles.GetNames(), MAX_PROFILE_ROWS)
    builder.Refresh(ns.db)
  end

  scrollBar = Widgets.CreateScrollBar(page, scrollTo)
  scrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -Builder.MARGIN, builder.RowY())
  scrollBar:SetHeight(MAX_PROFILE_ROWS * ROW_PROFILE)
  builder.OnRefresh(function()
    listOffset = math.min(listOffset, maxOffset())
    scrollBar:SetRange(maxOffset())
    scrollBar:SetOffsetSilently(listOffset)
  end)

  for index = 1, MAX_PROFILE_ROWS do
    local tab = Widgets.CreateTab(builder.Page(), "GameFontHighlight", function(self, mouseButton)
      local name = self.profileName
      if mouseButton == "RightButton" then
        ns.ConfirmProfileDelete(name)
      else
        Profiles.Switch(name)
      end
    end)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tab:EnableMouseWheel(true)
    tab:SetScript("OnMouseWheel", function(_, delta) scrollTo(listOffset - delta) end)
    builder.AddRow(tab, ROW_PROFILE)
    builder.AddTooltip(tab, "PROFILE_LIST_TIP", function() return Profiles.DisplayName(tab.profileName) end)
    builder.OnRefresh(function()
      local name = Profiles.GetNames()[listOffset + index]
      tab.profileName = name
      tab:SetShown(name ~= nil)
      if name then
        tab:SetLabel(Profiles.DisplayName(name))
        tab:SetActive(name == Profiles.GetActive())
      end
    end)
  end
end

-- Import-Fenster für Profile (auch /lt profile import); das neue Profil wird nicht sofort aktiv
function ns.ShowProfileImport()
  ns.Export.ShowImport(L.PROFILE_IMPORT, function(text)
    local name = ns.Profiles.Import(text)
    if not name then return L.PROFILE_IMPORT_INVALID, false end
    ns.ApplySettings()
    return string.format(L.PROFILE_IMPORTED, name), true
  end)
end

-- Wer das aktive Profil nutzt (UX S28): "Aktiv: Name (genutzt von N Charakteren)", die Namen im Tooltip
local MAX_PROFILE_USER_NAMES = 15  -- mehr Namen im Tooltip nur als Anzahl

local function profileUsageText()
  local Profiles = ns.Profiles
  local active = Profiles.GetActive()
  local count = #Profiles.CharactersOf(active)
  return string.format(count == 1 and L.PROFILE_ACTIVE_USED_ONE or L.PROFILE_ACTIVE_USED, Profiles.DisplayName(active), count)
end

local function profileUsersTip()
  local keys = ns.Profiles.CharactersOf(ns.Profiles.GetActive())
  local names = {}
  for i = 1, math.min(#keys, MAX_PROFILE_USER_NAMES) do names[i] = ns.History.DisplayName(keys[i]) end
  if #keys > MAX_PROFILE_USER_NAMES then
    table.insert(names, string.format(L.PROFILE_USERS_MORE, #keys - MAX_PROFILE_USER_NAMES))
  end
  return L.PROFILE_ACTIVE_TIP .. (#names > 0 and "\n\n" .. table.concat(names, "\n") or "")
end

local function addProfileUsage()
  local page = builder.Page()
  local line = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  line:SetJustifyH("LEFT")
  builder.AddRow(line, ROW_PROFILE, true)
  -- Tooltip braucht eine Mausfläche über der Zeile
  local hover = CreateFrame("Frame", nil, page)
  hover:SetAllPoints(line)
  hover:EnableMouse(true)
  Widgets.AttachTooltip(hover, profileUsageText, profileUsersTip)
  builder.OnRefresh(function() line:SetText(profileUsageText()) end)
  builder.profileUsage = line  -- Tests
end

-- Name + Speichern: Beschriftung vor dem Feld, Knopf erst mit Namen bedienbar (UX S28)
local function addProfileSaver()
  local page = builder.Page()
  local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", Builder.MARGIN, builder.RowY() - PROFILE_LABEL_OFFSET)
  local nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
  nameBox:SetSize(PROFILE_NAME_WIDTH, Builder.BUTTON_HEIGHT)
  nameBox:SetAutoFocus(false)
  nameBox:SetPoint("LEFT", label, "RIGHT", Builder.CHOOSER_TAB_GAP + PROFILE_BOX_BORDER, 0)  -- Rand links außerhalb
  local saveButton = Widgets.CreateButton(page, PROFILE_SAVE_WIDTH, Builder.BUTTON_HEIGHT, function()
    ns.ConfirmProfileSave(nameBox:GetText(), function() nameBox:SetText("") end)
  end)
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", Builder.CHOOSER_TAB_GAP, 0)
  builder.AddTooltip(saveButton, "PROFILE_SAVE_TIP", localized("PROFILE_SAVE"))
  builder.AddTooltip(nameBox, "PROFILE_NEW_NAME_TIP", localized("PROFILE_NEW_NAME"))
  local function updateSaveButton()
    saveButton:SetEnabled(strtrim(nameBox:GetText() or "") ~= "")
  end
  nameBox:SetScript("OnTextChanged", updateSaveButton)
  nameBox:SetScript("OnEnterPressed", function() saveButton:Click() end)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  builder.Advance(Builder.ROW_BUTTON)
  builder.OnRefresh(function()
    label:SetText(L.PROFILE_NEW_NAME)
    Widgets.SetButtonText(saveButton, L.PROFILE_SAVE, PROFILE_SAVE_WIDTH)
    updateSaveButton()
  end)
  builder.profileNameBox, builder.profileSaveButton = nameBox, saveButton  -- Tests
end

-- Profile: Einstellungen benannt speichern, je Charakter wählen, als Text teilen
addPage("OPTIONS_TAB_PROFILES")
addSection("SECTION_PROFILES")
addProfileUsage()
addProfileList()
addProfileSaver()
addButton("PROFILE_EXPORT", function()
  local Profiles = ns.Profiles
  ns.Export.Show(Profiles.DisplayName(Profiles.GetActive()), Profiles.Export(Profiles.GetActive()))
end)
addButton("PROFILE_IMPORT", function() ns.ShowProfileImport() end)
addHint("PROFILE_HINT")
finishPage()
