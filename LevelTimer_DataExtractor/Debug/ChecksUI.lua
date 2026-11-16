-- Debug-Prüfungen für offene Spielprüfungen im Board (Oberfläche: Einstellungsfenster, Reiter, Tabellen, Fenster, Einblendungen, Tooltips):
-- Datenteil der Vikunja-Tasks „Prüfen: …“, damit im
-- Spiel nur noch das Sichtbare bleibt. Namen "LT<Index>.<Bereich>.<Was>" (Index = Task im Board). Lesen nur öffentliche
-- Funktionen der Module, ändern nichts, rufen keine geschützten Funktionen.
local _, X = ...
local ns = X.LT
if not ns then return end
local DebugLog = X.DebugLog
local Probe, H = DebugLog.Probe, DebugLog.Helpers
local call, safe = Probe.call, Probe.safe
local write = DebugLog.Write
local check = DebugLog.AddCheck
local chunked, method, frameState, frameName, readable = H.chunked, H.method, H.frameState, H.frameName, H.readable

local MAX_FRAMES = 500      -- Obergrenze beim Durchlaufen eines Fensters
local MAX_ITEMS = 40        -- Obergrenze je Liste im Log
local SLACK = 1             -- Pixel Toleranz bei Breitenvergleichen
local MAX_HEIGHT_SHARE = 0.9

local function number(value)
  value = readable(value)
  return type(value) == "number" and value or nil
end

local function settings(keys)
  local values = {}
  for _, key in ipairs(keys) do values[key] = ns.db and ns.db[key] end
  return values
end

-- Alle Rückgaben von object:name() als Liste (GetChildren, GetRegions); leer ohne die Methode
local function listOf(object, name)
  if type(object) ~= "table" or type(object[name]) ~= "function" then return {} end
  local packed = { pcall(object[name], object) }
  if not table.remove(packed, 1) then return {} end
  return packed
end

-- Alle Unterrahmen eines Fensters (Breitensuche, auch verborgene Seiten), höchstens MAX_FRAMES
local function descendants(root)
  local list, queue, index = {}, { root }, 1
  while queue[index] and #list < MAX_FRAMES do
    for _, child in ipairs(listOf(queue[index], "GetChildren")) do
      list[#list + 1] = child
      queue[#queue + 1] = child
    end
    index = index + 1
  end
  return list
end

-- Text eines FontStrings, wenn er abgeschnitten ist oder breiter als limit
local function textProblem(fontString, limit)
  local text, width = method(fontString, "GetText"), number(method(fontString, "GetStringWidth"))
  if type(text) ~= "string" or text == "" or not width then return nil end
  local truncated = method(fontString, "IsTruncated") == true
  if truncated or (limit and width > limit + SLACK) then
    return { text = text:sub(1, 40), textWidth = width, limit = limit, truncated = truncated }
  end
end

-- Knöpfe, deren Text nicht in den Knopf passt (abgeschnitten oder breiter), und Rahmen, die rechts über das Fenster ragen.
-- Misst auch verborgene Seiten (die Breite ist gesetzt, auch wenn OnSizeChanged dort nicht feuert).
local function fitReport(root)
  local frames = descendants(root)
  local rootRight = number(method(root, "GetRight"))
  local tooLong, overflow, texts = {}, {}, 0
  for _, frame in ipairs(frames) do
    local fontString = method(frame, "GetFontString")
    if type(fontString) == "table" then
      texts = texts + 1
      local problem = textProblem(fontString, number(method(frame, "GetWidth")))
      if problem and #tooLong < MAX_ITEMS then
        problem.frame = frameName(frame)
        tooLong[#tooLong + 1] = problem
      end
    end
    local right = number(method(frame, "GetRight"))
    if rootRight and right and right > rootRight + SLACK and method(frame, "IsShown") ~= false and #overflow < MAX_ITEMS then
      overflow[#overflow + 1] = { frame = frameName(frame), right = right }
    end
  end
  return { frames = #frames, buttonTexts = texts, width = number(method(root, "GetWidth")), right = rootRight,
    language = ns.db and ns.db.language, tooLong = tooLong, overflow = overflow }
end

---------------------------------------------------------------------------
-- Einstellungsfenster
---------------------------------------------------------------------------

-- LT81, LT82, LT102, LT162, LT163: Voreinstellungs-, Fußzeilen-, Reiter- und Seitenleisten-Knöpfe, deren Text nicht in
-- den Knopf passt, und Rahmen, die rechts über das Fenster ragen. Je Sprache einmal ausführen (Fenster offen oder zu).
check("LT81.options.textFit", function()
  return fitReport(ns.OptionsWindow.panel)
end)

-- LT80: Höhe des Fensters gegen 90 % des Bildschirms und Bildlauf je Seite (Bereich, Stellung, Mausrad). Bei kleiner
-- Auflösung oder großer UI-Skalierung wiederholen.
check("LT80.options.scroll", function()
  local panel, scrolls = ns.OptionsWindow.panel, {}
  for _, frame in ipairs(descendants(panel)) do
    local range = number(method(frame, "GetVerticalScrollRange"))
    if range and #scrolls < MAX_ITEMS then
      local child = method(frame, "GetScrollChild")
      scrolls[#scrolls + 1] = { shown = method(frame, "IsShown"), scroll = number(method(frame, "GetVerticalScroll")), range = range,
        height = number(method(frame, "GetHeight")), contentHeight = type(child) == "table" and number(method(child, "GetHeight")) or nil,
        wheel = method(frame, "IsMouseWheelEnabled") }
    end
  end
  local screen = number(method(UIParent, "GetHeight"))
  local tab, sub = ns.OptionsWindow.CurrentPage()
  return { panel = frameState(panel), screenHeight = screen, maxHeight = screen and screen * MAX_HEIGHT_SHARE,
    effectiveScale = number(method(panel, "GetEffectiveScale")), page = { tab, sub }, scrolls = chunked(scrolls) }
end)

-- LT102, LT189, LT247: alle Reiter und Unterseiten in Fensterreihenfolge (Key, Text, Zahl der Standard-Werte), Klasse
-- (Munition nur Jäger) und wo feste Suchbegriffe stehen (zeigt, auf welcher Seite ein Baustein jetzt liegt)
local PAGE_PROBES = { "Munition", "Lagerfeuer", "Level-Up", "Beute", "Blizzard", "Minimap", "Instanzbericht" }
check("LT189.options.pages", function()
  local builder, pages, hits = ns.OptionsWindow, {}, {}
  for index, page in ipairs(builder.PageKeys()) do
    pages[index] = { tab = page.tab, sub = page.sub, text = ns.L[page.sub or page.tab],
      resets = page.sub and builder.ResetCount(page.sub) or nil }
  end
  for _, term in ipairs(PAGE_PROBES) do
    hits[term] = {}
    for index, entry in ipairs(builder.Search(term)) do
      if index > 6 then break end
      hits[term][index] = builder.WhereOf(entry)
    end
  end
  return { class = select(2, UnitClass("player")), language = ns.db.language, tabsHidden = builder.TabsHidden(),
    advanced = ns.db.optionsAdvanced, pages = chunked(pages), hits = hits }
end)

-- LT210: feste Suchbegriffe: Trefferreihenfolge, Ort und Art (Beschriftung vor Tooltip)
local SEARCH_TERMS = { "Repar", "Atem", "Munition", "Gruppenchat", "repair", "ammo" }
check("LT210.options.search", function()
  local builder, terms = ns.OptionsWindow, {}
  for _, term in ipairs(SEARCH_TERMS) do
    terms[term] = {}
    for index, entry in ipairs(builder.Search(term)) do
      if index > 8 then break end
      local title = type(entry.title) == "function" and safe(entry.title) or nil
      local byLabel = type(title) == "string" and title:lower():find(term:lower(), 1, true) ~= nil
      terms[term][index] = { where = builder.WhereOf(entry), title = title, kind = byLabel and "label" or "tip",
        shown = builder.IsEntryShown(entry) }
    end
  end
  return { terms = terms, resultRows = #builder.SearchResultRows(), highlighted = builder.Highlighted() ~= nil }
end)

-- LT163: Modus Einfach/Erweitert und Profil-Kopfzeile (aktives Profil, Zahl der Charaktere)
check("LT163.options.profiles", function()
  local Profiles = ns.Profiles
  local active = Profiles.GetActive()
  return { advanced = ns.db.optionsAdvanced, active = active, display = Profiles.DisplayName(active),
    characters = #Profiles.CharactersOf(active), names = Profiles.GetNames() }
end)

-- LT223: offene Auswahlliste (Lib/Dropdown.lua): Zeilen, gewählter und hervorgehobener Eintrag, Suchtext. Liste offen lassen.
local MAX_DROPDOWN_ROWS = 12
check("LT223.dropdown.state", function()
  local state, rows = ns.Dropdown.State(), {}
  for index = 1, math.min(#state.rows, MAX_DROPDOWN_ROWS) do rows[index] = state.rows[index] end
  return { open = state.open, searchable = state.searchable, search = state.search, count = #state.rows, rows = rows }
end)

-- LT212, LT247: Rechtsklick auf eine Anzeige öffnet ihre Seite (ToggleOptionsPage); LT216: Standard und Rückgängig je Seite
if ns.ToggleOptionsPage then
  hooksecurefunc(ns, "ToggleOptionsPage", function(pageKey)
    if not DebugLog.IsEnabled() then return end
    local tab, sub = ns.OptionsWindow.CurrentPage()
    write({ area = "edit", event = "ui.optionsPage", extra = { requested = pageKey, tab = tab, sub = sub,
      open = method(ns.OptionsWindow.panel, "IsShown") } })
  end)
end
for _, name in ipairs({ "ResetPage", "UndoReset" }) do
  hooksecurefunc(ns.OptionsWindow, name, function(labelKey)
    if not DebugLog.IsEnabled() then return end
    write({ area = "settings", event = "ui.optionsReset", extra = { action = name, page = labelKey,
      resets = ns.OptionsWindow.ResetCount(labelKey) } })
  end)
end

-- LT81: Voreinstellung der Statistik-Zeilen: Name und danach gezeigte Zeilen
local function shownStats()
  local keys = {}
  for index, stat in ipairs(ns.WindowModel.ShownStats(ns.db)) do keys[index] = stat.setting end
  return keys
end
hooksecurefunc(ns, "ApplyStatPreset", function(preset)
  if DebugLog.IsEnabled() then
    write({ area = "settings", event = "ui.preset", extra = { action = "apply", preset = preset and preset.label, shown = shownStats() } })
  end
end)
hooksecurefunc(ns, "UndoStatPreset", function()
  if DebugLog.IsEnabled() then write({ area = "settings", event = "ui.preset", extra = { action = "undo", shown = shownStats() } }) end
end)

---------------------------------------------------------------------------
-- Fenster, Karten, Historie
---------------------------------------------------------------------------

-- LT147, LT159(LT315): Historienfenster (Haupt-/Unterreiter, Tabellen, Geldeinheiten) wie LT81 plus Breite der Hauptreiter
check("LT147.history.textFit", function()
  local panel = _G[ns.GlobalName("History")]
  local report = panel and fitReport(panel) or {}
  local tabs = {}
  for index, tab in ipairs(ns.HistoryWindow.MainTabs()) do tabs[index] = number(method(tab, "GetWidth")) end
  report.mainTabWidths, report.shown = tabs, panel and method(panel, "IsShown")
  return report
end)

-- LT165: Bedienhinweise: Tooltip je Anzeige mit actionsTip, je Historie-Reiter und Breitenbericht des Hauptfensters
check("LT165.window.hints", function()
  local actions, tabs = {}, {}
  for _, reg in ipairs(ns.Frames.All()) do
    if reg.actionsTip then actions[reg.id] = safe(ns.Frames.ActionsText, reg.id) end
  end
  for index, entry in ipairs(ns.HistoryWindow.Entries()) do
    tabs[index] = { tab = entry.tab, tip = safe(ns.HistoryWindow.EntryTip, entry) }
  end
  return { actions = actions, timer = _G.LevelTimerFrame and fitReport(_G.LevelTimerFrame) or nil, tabs = chunked(tabs) }
end)

-- LT212, LT247: je Anzeige Mausstatus (Einblendung klickdurchlässig; Timer-Anzeigen nur mit clickable), Zielseite des
-- Rechtsklicks und Esc-Liste (Changelog, Optionen, Historie)
check("LT212.frames.mouse", function()
  local list, special = {}, {}
  for _, reg in ipairs(ns.Frames.All()) do
    list[#list + 1] = { id = reg.id, page = reg.settingsPage, clickable = reg.clickable == true, protected = reg.protected == true,
      mouse = method(reg.frame, "IsMouseEnabled"), shown = method(reg.frame, "IsShown"),
      width = number(method(reg.frame, "GetWidth")), height = number(method(reg.frame, "GetHeight")) }
  end
  for _, name in ipairs({ ns.GlobalName("Changelog"), ns.GlobalName("Options"), ns.GlobalName("History") }) do
    special[name] = false
    for _, entry in ipairs(UISpecialFrames) do
      if entry == name then special[name] = true end
    end
  end
  return { frames = chunked(list), alertMouse = method(ns.Alerts.frame, "IsMouseEnabled"), escCloses = special }
end)

-- LT78: Texturen der Einblendung und der Karte (GetTexture/Atlas leer = unsichtbar), Stil; bei sichtbarer Vorschau ausführen
local function textureStates(frame)
  local list = {}
  for index, region in ipairs(listOf(frame, "GetRegions")) do
    if method(region, "GetObjectType") == "Texture" and #list < MAX_ITEMS then
      list[#list + 1] = { index = index, texture = method(region, "GetTexture"), atlas = method(region, "GetAtlas"),
        shown = method(region, "IsShown"), alpha = number(method(region, "GetAlpha")),
        width = number(method(region, "GetWidth")), height = number(method(region, "GetHeight")) }
    end
  end
  return list
end
check("LT78.alert.banner", function()
  local Alerts = ns.Alerts
  return { style = ns.db.alertStyle, banner = Alerts.IsBanner(), frame = frameState(Alerts.frame),
    text = method(Alerts.frame.text, "GetText"),
    frameTextures = chunked(textureStates(Alerts.frame)), card = frameState(Alerts.noticeFrame),
    cardTextures = chunked(textureStates(Alerts.noticeFrame)) }
end)

-- LT155, LT225: Einblendungen und Testen-Karten: Art, Text, Zweitzeile, Kampfstatus, Quest-XP des Questlogs (LT270.questLogXp)
local function alertLine(event, ...)
  if not DebugLog.IsEnabled() then return end
  write({ area = "alerts", event = event, extra = { args = { ... }, combat = readable(InCombatLockdown()),
    questXp = ns.QuestLogXp and ns.QuestLogXp.Get() } })
end
hooksecurefunc(ns.Alerts, "Raise", function(kind, value, body) alertLine("ui.alert.raise", kind, value, body) end)
hooksecurefunc(ns.Alerts, "ShowSampleMessage", function(message, _, _, sound) alertLine("ui.alert.sample", message, sound) end)

-- LT85: Einrichtungsassistent: sichtbar, Texte gegen die Fensterbreite (fr/es), Schritt und Layout
check("LT85.welcome.state", function()
  local SetupWizard = ns.SetupWizard
  local card = _G[ns.GlobalName("Setup")]
  local state = SetupWizard.State()
  return { shown = SetupWizard.IsShown(), report = type(card) == "table" and fitReport(card) or nil,
    cardWidth = number(method(card, "GetWidth")), step = state.step, steps = #state.steps, layout = ns.db.windowLayout }
end)
hooksecurefunc(ns.SetupWizard, "Show", function()
  if DebugLog.IsEnabled() then
    write({ area = "comfort", event = "ui.welcome",
      extra = { action = "show", setupWizardSeen = LevelTimerStatsDB and LevelTimerStatsDB.setupWizardSeen } })
  end
end)

---------------------------------------------------------------------------
-- Tooltips und Komfort-Anzeigen
---------------------------------------------------------------------------

-- LT129: Zielzeile, Ausblenden-Entscheidung (Kampf, Umschalt) und Farbe der ersten Zeile gegen die Klassenfarbe
check("LT129.tooltip.state", function()
  local Tooltip, units = ns.Tooltip, {}
  for _, unit in ipairs({ "target", "mouseover" }) do
    local _, class = UnitClass(unit)
    class = readable(class)
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    units[unit] = { target = safe(Tooltip.TargetLine, unit), class = class, classColor = color and { color.r, color.g, color.b } or nil }
  end
  local r, g, b = method(_G.GameTooltipTextLeft1, "GetTextColor")
  return { units = units, hide = safe(Tooltip.ShouldHide, GameTooltip), combatLockdown = readable(InCombatLockdown()),
    shift = IsShiftKeyDown(), line1 = { name = method(_G.GameTooltipTextLeft1, "GetText"), r = r, g = g, b = b },
    lines = method(GameTooltip, "NumLines"), scale = number(method(GameTooltip, "GetScale")),
    settings = settings({ "tooltipClassColors", "tooltipTarget", "tooltipHideInCombat", "tooltipAnchor", "tooltipScale",
      "tooltipGuildRank" }) }
end)

-- LT213: Anker (Besitzer der Welt-Tooltips), Größe je Tooltip und Gildenrang
hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
  if not DebugLog.IsEnabled() or tooltip ~= GameTooltip then return end
  write({ area = "tooltip", event = "ui.tooltip.anchor", extra = { owner = frameName(parent), world = parent == UIParent,
    setting = ns.db.tooltipAnchor, anchor = method(tooltip, "GetAnchorType") } })
end)
hooksecurefunc(ns.Tooltip, "ApplyScale", function(scale)
  if not DebugLog.IsEnabled() then return end
  local scales = {}
  for _, name in ipairs({ "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2" }) do
    scales[name] = number(method(_G[name], "GetScale"))
  end
  write({ area = "tooltip", event = "ui.tooltip.scale", extra = { factor = scale, scales = scales } })
end)
hooksecurefunc(ns.Tooltip, "AddGuildRank", function(_, unit)
  if not DebugLog.IsEnabled() then return end
  local guild, _, rank = GetGuildInfo(unit)
  write({ area = "tooltip", event = "ui.tooltip.guildRank", extra = { guild = readable(guild), rank = readable(rank) } })
end)

-- LT149: Spiel-Tooltip bei Beute und Quests (Zeilen im Journal der Historie): Methode, Argumente, Zeilen, Besitzer
local TOOLTIP_METHODS = { "SetHyperlink", "SetItemByID", "SetQuestLogItem", "SetQuestItem" }
for _, name in ipairs(TOOLTIP_METHODS) do
  if GameTooltip and type(GameTooltip[name]) == "function" then
    hooksecurefunc(GameTooltip, name, function(tooltip, ...)
      local history = _G[ns.GlobalName("History")]
      if not DebugLog.IsEnabled() or not (history and method(history, "IsShown")) then return end
      write({ area = "journal", event = "ui.tooltip.row", extra = { method = name, args = { ... }, lines = method(tooltip, "NumLines"),
        owner = frameName(method(tooltip, "GetOwner")), shown = method(tooltip, "IsShown") } })
    end)
  end
end
check("LT149.tooltip.api", function()
  local methods = {}
  for _, name in ipairs(TOOLTIP_METHODS) do methods[name] = GameTooltip ~= nil and type(GameTooltip[name]) == "function" end
  return { methods = methods, forever = ns.Client.IsForever(), classicEra = ns.Client.IsClassicEra and ns.Client.IsClassicEra() or nil }
end)

-- LT187: Blizzard-Oberfläche ausblenden: je Eintrag Maus-Zustand der Kinder (unsichtbare Symbole/Knöpfe dürfen nicht
-- klickbar sein). Vor und nach dem Ausblenden ausführen.
check("LT187.blizzardFrames.mouse", function()
  local BlizzardHide, entries = ns.BlizzardHide, {}
  for _, entry in ipairs(BlizzardHide.ENTRIES) do
    local first = BlizzardHide.Frames(entry)[1]
    if first and #entries < MAX_ITEMS then
      local children, clickable = descendants(first), 0
      for _, child in ipairs(children) do
        if readable(method(child, "IsMouseEnabled")) and readable(method(child, "IsShown")) then
          clickable = clickable + 1
        end
      end
      entries[#entries + 1] = { id = entry.id, hidden = BlizzardHide.IsHidden(entry.id), mouse = method(first, "IsMouseEnabled"),
        children = #children, clickableShown = clickable }
    end
  end
  return { pending = BlizzardHide.IsPending(), combat = readable(InCombatLockdown()), entries = chunked(entries) }
end)
hooksecurefunc(ns.BlizzardHide, "SetHidden", function(id, hidden)
  if not DebugLog.IsEnabled() then return end
  write({ area = "comfort", event = "ui.blizzardHide", extra = { id = id, hidden = hidden, combat = readable(InCombatLockdown()),
    pending = ns.BlizzardHide.IsPending(), applied = ns.BlizzardHide.IsApplied(id) } })
end)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if DebugLog.IsEnabled() then
    write({ area = "comfort", event = "ui.blizzardHide.afterCombat", extra = { pending = ns.BlizzardHide.IsPending() } })
  end
end)

-- LT215: eckige Minimap: Maske, Größe, Drehung, Rahmen
check("LT215.minimap.square", function()
  local Minimap = _G.Minimap
  return { can = ns.MinimapTweaks.CanSquare(), square = ns.MinimapTweaks.IsSquare(), setting = ns.db.minimapSquare,
    width = number(method(Minimap, "GetWidth")), height = number(method(Minimap, "GetHeight")),
    rotate = call("GetCVar", "rotateMinimap"), forever = ns.Client.IsForever(), border = method(_G.MinimapBorder, "IsShown") }
end)

-- LT217: Questtext-Größe: aktuelle Schriftgrößen der Quest-Schriften (Reglergröße, sonst Blizzards Original)
check("LT217.quests.textSize", function()
  local QuestTextSize, sizes = ns.QuestTextSize, {}
  for _, list in ipairs({ QuestTextSize.BODY_FONTS, QuestTextSize.TITLE_FONTS }) do
    for _, name in ipairs(list) do
      local _, size = method(_G[name], "GetFont")
      sizes[name] = number(size)
    end
  end
  return { available = QuestTextSize.IsAvailable(), settings = settings({ "questTextResize", "questTextSize" }), fonts = sizes }
end)

-- LT219: Bildschirmränder: Pixel je Seite, Strata/Ebene, Mausfang, Elternrahmen (UIParent: Alt+Z blendet mit aus)
check("LT219.screenBorders", function()
  local frame = ns.ScreenBorders.Frame()
  local parent = method(frame, "GetParent")
  return { edges = ns.ScreenBorders.Edges(),
    settings = settings({ "screenBorders", "screenBorderTop", "screenBorderBottom", "screenBorderSides" }),
    strata = method(frame, "GetFrameStrata"), level = method(frame, "GetFrameLevel"), mouse = method(frame, "IsMouseEnabled"),
    parent = frameName(parent), parentIsUIParent = parent == UIParent, state = frameState(frame) }
end)

-- LT86: Spielerrahmen in Classic: Namenshintergrund, Rahmen-Textur, Druiden-Manaleiste, Gestalt und Mana
check("LT86.classicPlayerFrame", function()
  local background, bar = ns.ClassColors.PlayerBackground(), ns.DruidManaBar.Bar()
  return { can = ns.ClassColors.CanColorPlayerFrame(), background = background and frameState(background) or nil,
    frameTexture = frameState(_G.PlayerFrameTexture), druidAvailable = ns.DruidManaBar.IsAvailable(),
    bar = bar and frameState(bar) or nil, form = call("GetShapeshiftFormID"), mana = call("UnitPower", "player", 0),
    manaMax = call("UnitPowerMax", "player", 0), settings = settings({ "classColorPlayerFrame", "druidManaBar" }) }
end)

-- LT87: Anprobe-Knöpfe (Anker, Größe, Sichtbarkeit), Modell und Aufrufe von Ausziehen/Wappenrock
check("LT87.dressUp", function()
  local buttons = {}
  for index, button in ipairs(ns.DressUp.Buttons() or {}) do buttons[index] = frameState(button) end
  return { available = ns.DressUp.IsAvailable(), model = ns.DressUp.Model() ~= nil, buttons = buttons, setting = ns.db.dressUpButtons,
    dressUpShown = method(_G.DressUpFrame, "IsShown") }
end)
for _, name in ipairs({ "UndressAll", "UndressTabard" }) do
  hooksecurefunc(ns.DressUp, name, function()
    if DebugLog.IsEnabled() then write({ area = "comfort", event = "ui.dressUp", extra = { action = name } }) end
  end)
end

-- LT89: Infokarte: erkanntes Ziel (Art, ID, Name), Text mit Link je Client; beim Überfahren eines Ziels ausführen
check("LT89.infoCard.subject", function()
  local subject = ns.InfoCard.Subject()
  return { enabled = ns.db.infoCards, subject = subject, text = subject and ns.InfoCard.Text(subject) or nil,
    forever = ns.Client.IsForever(), tooltipShown = method(GameTooltip, "IsShown") }
end)
hooksecurefunc(ns.InfoCard, "Show", function()
  if not DebugLog.IsEnabled() then return end
  local subject = ns.InfoCard.Subject()
  write({ area = "comfort", event = "ui.infoCard", extra = { subject = subject,
    url = subject and subject.id and ns.InfoCard.Url(subject.kind, subject.id) or nil } })
end)
