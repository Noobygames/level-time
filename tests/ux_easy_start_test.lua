-- UX-Review Paket 3 (leichter Einstieg, Auffindbarkeit): Modus „Einfach“ für neue Installationen (S1), weniger
-- Feinregler im Modus „Einfach“ (S2, S3), Willkommenskarte mit Tooltips, aktiver Wahl, Stream und Fuß (S23, S24),
-- Profil-Reiter mit Beschriftung und Nutzern (S28), Bedienhinweis an den Anzeigen (W22), Tooltips der
-- Historien-Reiter (W23), Edit-Modus-Hinweis in zwei Zeilen (W34), XP-Balken breit genug für seine Texte (W20).
local L = addon.L
local options = addon.OptionsWindow

wow.login({ level = 10, xp = 0, xpMax = 1000 })

---------------------------------------------------------------------------
-- S1: neue Installation einfach, bestehende Einstellungen ohne Schlüssel behalten „alle Optionen“
---------------------------------------------------------------------------
expect("neu: einfach", LevelTimerDB.optionsAdvanced, false)
expect("Beschriftung", L.OPTIONS_ADVANCED, addon.locales.deDE.OPTIONS_ADVANCED)
expect("deDE: Alle Optionen zeigen", addon.locales.deDE.OPTIONS_ADVANCED, "Alle Optionen zeigen")
wow.logout()
-- Stand aus einer älteren Version: Einstellungen und Profile ohne optionsAdvanced
LevelTimerDB.optionsAdvanced = nil
for _, profile in pairs(LevelTimerDB.profiles) do profile.optionsAdvanced = nil end
LevelTimerDB.profiles.Alt = { scale = 1 }
wow.login()
expect("bestehend: alle Optionen", LevelTimerDB.optionsAdvanced, true)
expect("Profil ohne Schlüssel: alle Optionen", LevelTimerDB.profiles.Alt.optionsAdvanced, true)
-- Gespeichertes "einfach" bleibt
addon.Set("optionsAdvanced", false)
wow.logout()
wow.login()
expect("gespeichert einfach bleibt", LevelTimerDB.optionsAdvanced, false)

---------------------------------------------------------------------------
-- S2/S3: im Modus „Einfach“ Feinregler verborgen, Hauptschalter sichtbar
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("config")
local function entryOf(labelKey)
  for _, entry in ipairs(options.Search(L[labelKey])) do
    if entry.tipKey == labelKey .. "_TIP" then return entry end
  end
end
local HIDDEN = { "SCREEN_BORDER_TOP", "SCREEN_BORDER_SIDES", "TOOLTIP_SCALE", "TOOLTIP_ANCHOR", "CHAT_EDIT_BOX_TOP",
  "UNCLAMP_CHAT", "INVITE_KEYWORD", "QUEST_EXCLUDE", "THEME_MIN_FONT_SIZE", "THEME_BAR_TEXTURE", "VALUE_COLORS",
  "AUTO_RELEASE_PVP", "FLIGHT_SCALE" }
local SHOWN = { "SCREEN_BORDERS", "HIDE_ERRORS", "AUTO_REPAIR", "AUTO_ACCEPT_QUESTS", "THEME_OUTLINE", "THEME_FONT_SIZE",
  "INVITE_FROM_WHISPER", "FLIGHT_TIMER_TOGGLE", "FLIGHT_PREVIEW" }
for _, key in ipairs(HIDDEN) do
  local entry = entryOf(key)
  expectTrue("Eintrag " .. key, entry ~= nil)
  if entry then expect("einfach: " .. key .. " verborgen", options.IsEntryShown(entry), false) end
end
for _, key in ipairs(SHOWN) do
  local entry = entryOf(key)
  expectTrue("Eintrag " .. key, entry ~= nil)
  if entry then expect("einfach: " .. key .. " sichtbar", options.IsEntryShown(entry), true) end
end
-- Jede Seite der Seitenleiste, die im Modus „Einfach“ bleibt, zeigt mindestens einen Baustein
options.ShowPage("COMFORT_PAGE_INTERFACE")
expectTrue("Oberfläche: Hauptschalter sichtbar", entryOf("SCREEN_BORDERS").left:IsVisible())
addon.Set("optionsAdvanced", true)
options.ShowPage("COMFORT_PAGE_INTERFACE")
expect("alle Optionen: Ränder-Regler da", options.IsEntryShown(entryOf("SCREEN_BORDER_TOP")), true)
LevelTimerOptions:Hide()

---------------------------------------------------------------------------
-- S23/S24: Willkommenskarte
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("welcome")
local card = addon.WelcomeCard.Widgets()
local minimal = card.presets[1]
expect("erste Voreinstellung", minimal.item.label, "PRESET_MINIMAL")
minimal._scripts.OnEnter(minimal)
expect("Tooltip Titel", GameTooltip._text, L.PRESET_MINIMAL)
expect("Tooltip sagt, was sie tut", GameTooltip._lines[1], L.PRESET_MINIMAL_TIP)
minimal._scripts.OnLeave(minimal)
minimal._scripts.OnClick(minimal)
expect("Voreinstellung angewendet", addon.ActiveStatPreset(addon.db), addon.STAT_PRESETS[1])
expect("aktiv hervorgehoben", minimal.underline:IsShown(), true)
expect("andere nicht", card.presets[2].underline:IsShown(), false)
addon.Set("showDeaths", true)
expect("eigene Auswahl: keine aktiv", addon.ActiveStatPreset(addon.db), nil)
expect("Hervorhebung weg", minimal.underline:IsShown(), false)

for _, tab in ipairs(card.layouts) do
  local labelKey = addon.WindowLayouts.Get(tab.item).label
  tab._scripts.OnEnter(tab)
  expect("Layout-Tooltip " .. labelKey, GameTooltip._lines[1], L[labelKey .. "_TIP"])
  tab._scripts.OnLeave(tab)
end

expect("Stream aus", card.stream:GetChecked(), false)
card.stream:SetChecked(true)
card.stream._scripts.OnClick(card.stream)
expect("Stream-Modus an", addon.StreamMode.IsEnabled(), true)
card.stream:SetChecked(false)
card.stream._scripts.OnClick(card.stream)
expect("Stream-Modus aus", addon.StreamMode.IsEnabled(), false)
expect("Fuß nennt /lt welcome", card.footer:GetText(), L.WELCOME_FOOTER)
expectTrue("Fußtext mit /lt welcome", L.WELCOME_FOOTER:find("/lt welcome", 1, true) ~= nil)
wow.click(L.WELCOME_DONE, true)

---------------------------------------------------------------------------
-- S28: Profil-Reiter
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("config")
options.ShowPage("OPTIONS_TAB_PROFILES")
expect("Aktiv-Zeile", options.profileUsage:GetText(), string.format(L.PROFILE_ACTIVE_USED_ONE, L.PROFILE_DEFAULT, 1))
LevelTimerStatsDB.characters["Zweiter-Realm"] = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Zweiter",
  realm = "Realm", currentLevel = { level = 5 } }
expect("zwei Nutzer", #addon.Profiles.CharactersOf(addon.Profiles.GetActive()), 2)
LevelTimerDB.characterProfiles["Zweiter-Realm"] = "Fehlt"  -- gelöschtes Profil = Standard
expect("gelöschtes Profil zählt zum Standard", #addon.Profiles.CharactersOf("Default"), 2)
addon.ApplySettings()
expect("Aktiv-Zeile mit 2", options.profileUsage:GetText(), string.format(L.PROFILE_ACTIVE_USED, L.PROFILE_DEFAULT, 2))
LevelTimerStatsDB.characters["Zweiter-Realm"] = nil  -- nur für die Zählung, keine vollständigen Daten
LevelTimerDB.characterProfiles["Zweiter-Realm"] = nil

local box, save = options.profileNameBox, options.profileSaveButton
expect("Knopf ohne Namen aus", save:IsEnabled(), false)
box:SetText("Raid")
box._scripts.OnTextChanged(box)
expect("Knopf mit Namen an", save:IsEnabled(), true)
box:SetText("  ")
box._scripts.OnTextChanged(box)
expect("nur Leerzeichen: aus", save:IsEnabled(), false)
LevelTimerOptions:Hide()

---------------------------------------------------------------------------
-- W22: Bedienhinweis an Hauptfenster, Zeit-Anzeige und Split-Liste
---------------------------------------------------------------------------
addon.Set("locked", false)
local window = LevelTimerFrame
window._scripts.OnEnter(window)
expect("Hauptfenster: Titel", GameTooltip._text, L.EDIT_FRAME_MAIN)
local mainTip = GameTooltip._lines[1]
for _, key in ipairs({ "FRAME_ACTION_SETTINGS", "FRAME_ACTION_DRAG", "FRAME_ACTION_RESIZE", "FRAME_ACTION_EDIT" }) do
  expectTrue("Hauptfenster: " .. key, mainTip:find(L[key], 1, true) ~= nil)
end
window._scripts.OnLeave(window)
addon.Set("locked", true)
expectTrue("fixiert: kein Ziehen", not addon.Frames.ActionsText("main"):find(L.FRAME_ACTION_DRAG, 1, true))
addon.Set("locked", false)

local flight = addon.Frames.Get("flight").frame
flight._scripts.OnEnter(flight)
expect("Flug-Anzeige: Titel", GameTooltip._text, L.EDIT_FRAME_FLIGHT)
expectTrue("Flug-Anzeige: Rechtsklick", GameTooltip._lines[1]:find(L.FRAME_ACTION_SETTINGS, 1, true) ~= nil)
expectTrue("Flug-Anzeige: ohne Ziehen", not GameTooltip._lines[1]:find(L.FRAME_ACTION_DRAG, 1, true))
flight._scripts.OnLeave(flight)

local splits = LevelTimerSplits
splits._scripts.OnEnter(splits)
expect("Split-Liste: Titel", GameTooltip._text, L.SPLIT_LIST_TITLE)
expectTrue("Split-Liste: Erklärung", GameTooltip._lines[1]:find(L.SPLIT_LIST_TIP:sub(1, 20), 1, true) == 1)
expectTrue("Split-Liste: Bedienung", GameTooltip._lines[1]:find(L.FRAME_ACTION_EDIT, 1, true) ~= nil)
splits._scripts.OnLeave(splits)

addon.EditMode.Enter()
GameTooltip._text = nil
window._scripts.OnEnter(window)
expect("Edit-Modus: kein Tooltip", rawget(GameTooltip, "_text"), nil)
-- W34: zwei Hinweiszeilen
expect("Hinweis Zeile 1", LevelTimerEditMode.hint:GetText(), L.EDIT_MODE_HINT_1)
expect("Hinweis Zeile 2", LevelTimerEditMode.hint2:GetText(), L.EDIT_MODE_HINT_2)
addon.EditMode.Leave()

---------------------------------------------------------------------------
-- W23: jeder Reiter und Unterreiter der Historie hat einen Tooltip
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("history")
for _, entry in ipairs(addon.HistoryWindow.Entries()) do
  local tip = addon.HistoryWindow.EntryTip(entry)
  expectTrue("Reiter " .. entry.tab .. " erklärt", tip ~= nil and tip ~= "")
  for _, view in ipairs(entry.members) do
    local viewTip = addon.HistoryWindow.ViewTip(view)
    expectTrue("Ansicht " .. view.tab .. " erklärt", viewTip ~= nil and viewTip ~= "")
  end
end
local first = addon.HistoryWindow.Entries()[1]
first.members[1].subtabButton._scripts.OnEnter(first.members[1].subtabButton)
expect("Unterreiter-Tooltip", GameTooltip._text, L[first.members[1].tab])
LevelTimerHistory:Hide()

---------------------------------------------------------------------------
-- W20: Layout „XP-Balken“ wächst mit seinen Texten statt sie überlappen zu lassen
---------------------------------------------------------------------------
addon.Set("xpbarWidth", addon.WindowLayouts.XpBar.MIN_WIDTH)
addon.Set("compactRows", "ROW_XP_RATE,ROW_LEVEL_ETA,ROW_PVE_KILLS")
addon.Set("windowLayout", "xpbar")
wow.update(1)
local fields = addon.TimerWindow.Elements().fields
local needed = fields[2]:GetStringWidth() + 2 * math.max(fields[1]:GetStringWidth(), fields[3]:GetStringWidth())
expectTrue("breit genug für drei Texte", window:GetWidth() >= needed)
addon.Set("xpbarText", "never")
expect("ohne Texte: eingestellte Breite", window:GetWidth(), addon.WindowLayouts.XpBar.MIN_WIDTH)
addon.Set("xpbarText", "always")
addon.Set("windowLayout", "table")

expect("keine Fehler", #wow.errors, 0)
