-- Level Time Goals: eigener Minimap-Button (Lib/MinimapButton.lua von Level Time). Standardmäßig an, ausblenden per
-- Einstellung und /sg minimap, Klicks (Fenster, Historie, Einstellungen, Edit-Modus), Tooltip mit laufenden Zielen,
-- Winkel beim Ziehen in StreamGoalDB.settings.
local Goals = streamGoal.Goals
local Manager = streamGoal.Manager
local MinimapButton = streamGoal.MinimapButton
local L = streamGoal.L
local builder = streamGoal.Options.builder

local button = StreamGoalMinimapButton
local function click(mouseButton, shift)
  wow.state.shiftDown = shift or false
  button._scripts.OnClick(button, mouseButton)
  wow.state.shiftDown = false
end
local function tooltipHas(text)
  for _, line in ipairs(GameTooltip._lines or {}) do
    if line == text then return true end
  end
  return false
end
-- Schalter im Einstellungsfenster von Goals anklicken (wow.clickOption sucht im Fenster von Level Time)
local function clickOption(labelKey)
  for _, entry in ipairs(builder.Search(L[labelKey])) do
    local onClick = entry.tipKey == labelKey .. "_TIP" and entry.left._scripts.OnClick
    if onClick then
      entry.left:SetChecked(not entry.left:GetChecked())  -- wie der Client: Klick schaltet erst um
      onClick(entry.left, "LeftButton")
      return true
    end
  end
  return false
end
local function printedContains(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

wow.login({ name = "Kartenleger", level = 10 })
expectTrue("Button existiert", button ~= nil)
expect("standardmäßig sichtbar", button:IsShown(), true)
expect("Standard in den Einstellungen", StreamGoalDB.settings.minimapButton, true)
expect("eigenes Icon", MinimapButton.ICON, "Interface\\AddOns\\StreamGoal\\Media\\Icon")
expectTrue("nicht der Button von Level Time", button ~= LevelTimerMinimapButton)

---------------------------------------------------------------------------
-- Tooltip: ohne Ziele, dann mit Zielen und Stand
---------------------------------------------------------------------------
button._scripts.OnEnter(button)
expect("Titel", GameTooltip._lines[1], "Level Time Goals")
expectTrue("ohne Ziele", tooltipHas(L.SG_LIST_EMPTY))
expectTrue("Linksklick", tooltipHas(L.SG_MINIMAP_TIP_LEFT))
expectTrue("Rechtsklick", tooltipHas(L.SG_MINIMAP_TIP_RIGHT))
expectTrue("Shift-Rechtsklick", tooltipHas(L.TOOLTIP_SHIFT_RIGHT))
expectTrue("Ziehen", tooltipHas(L.TOOLTIP_DRAG))
button._scripts.OnLeave(button)

SlashCmdList.STREAMGOAL("add kills 10")
for i = 1, MinimapButton.MAX_TOOLTIP_GOALS + 1 do SlashCmdList.STREAMGOAL("add custom Ziel " .. i) end
local kills = Goals.Active()[1]
expect("Kill-Ziel zuerst", kills.kind, "kills")
button._scripts.OnEnter(button)
local listed = #Goals.Active()
expectTrue("Zahl der Ziele", tooltipHas(string.format(L.SG_MINIMAP_ACTIVE, listed)))
expectTrue("Stand des Kill-Ziels", tooltipHas(Goals.Title(kills) .. "  " .. Goals.CountText(kills)))
expectTrue("weitere Ziele", tooltipHas(string.format(L.SG_MORE_GOALS, listed - MinimapButton.MAX_TOOLTIP_GOALS)))
button._scripts.OnLeave(button)

---------------------------------------------------------------------------
-- Klicks: links Fenster an/aus, Shift+links Historie, rechts Einstellungen, Shift+rechts Edit-Modus
---------------------------------------------------------------------------
click("LeftButton")
expect("Fenster offen", StreamGoalWindow:IsShown(), true)
click("LeftButton")
expect("Fenster zu", StreamGoalWindow:IsShown(), false)
click("LeftButton", true)
expect("Historie", Manager.ShownPage(), "history")
StreamGoalWindow:Hide()
click("RightButton")
expect("Einstellungen offen", StreamGoalOptions:IsShown(), true)
click("RightButton")
expect("Einstellungen zu", StreamGoalOptions:IsShown(), false)
click("RightButton", true)
expect("Edit-Modus", addon.EditMode.IsActive(), true)
addon.EditMode.Toggle()
expect("Edit-Modus aus", addon.EditMode.IsActive(), false)

---------------------------------------------------------------------------
-- Ziehen: Winkel aus der Cursorposition (Minimap-Mitte im Stub bei 0,0), bleibt nach dem Neuladen
---------------------------------------------------------------------------
wow.state.cursorX, wow.state.cursorY = 0, 50
button._scripts.OnDragStart(button)
wow.update(0.1)
button._scripts.OnDragStop(button)
expectNear("Winkel oben", StreamGoalDB.settings.minimapAngle, 90, 0.01)
wow.logout()
wow.login({ name = "Kartenleger", level = 10 })
expectNear("Winkel bleibt", StreamGoalDB.settings.minimapAngle, 90, 0.01)
StreamGoalDB.settings.minimapAngle = "kaputt"
wow.logout()
wow.login({ name = "Kartenleger", level = 10 })
expect("kaputter Winkel = Standard", StreamGoalDB.settings.minimapAngle, streamGoal.SettingDefault("minimapAngle"))

---------------------------------------------------------------------------
-- Ausblenden: /sg minimap (mit Hinweis), Einstellung, bleibt nach dem Neuladen
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("minimap")
expect("ausgeblendet", button:IsShown(), false)
expectTrue("Hinweis", printedContains(L.SG_MINIMAP_HIDDEN))
wow.logout()
wow.login({ name = "Kartenleger", level = 10 })
expect("bleibt aus", button:IsShown(), false)
SlashCmdList.STREAMGOAL("minimap")
expect("wieder da", button:IsShown(), true)

streamGoal.Options.Show(streamGoal.SETTINGS_PAGES.TRACKER)
expect("Schalter in den Einstellungen", clickOption("SG_SHOW_MINIMAP"), true)
expect("per Einstellung aus", button:IsShown(), false)
expect("gespeichert", StreamGoalDB.settings.minimapButton, false)
clickOption("SG_SHOW_MINIMAP")
expect("per Einstellung an", button:IsShown(), true)
expectTrue("auffindbar per Suche", #builder.Search(L.SG_SHOW_MINIMAP) > 0)
StreamGoalOptions:Hide()
