-- Optionen, Reiter Statistiken: Voreinstellungen, Stat-Gruppen, Reihenfolge, Berechnung.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local builder, addPage, finishPage, addSection, addSlider, addToggles, addButton, addSubPage, finishSubPages, toggle, advanced = O.builder, O.addPage, O.finishPage, O.addSection, O.addSlider, O.addToggles, O.addButton, O.addSubPage, O.finishSubPages, O.toggle, O.advanced

-- Reihenfolge der Stat-Zeilen (rowOrder): Stat wählen (nur eingeschaltete), dann nach oben oder unten
local function addRowOrderSection()
  local WindowModel = ns.WindowModel
  local selected  -- gewählte Stat-Einstellung; ohne Wahl die erste eingeschaltete
  local function current(db)
    local shown = WindowModel.ShownStats(db)
    for _, stat in ipairs(shown) do
      if stat.setting == selected then return selected end
    end
    return shown[1] and shown[1].setting or ""
  end
  addSection("SECTION_ROW_ORDER", { advanced = true })
  builder.AddCycleButton({
    label = "ROW_ORDER_STAT",
    advanced = true,
    setting = "rowOrder",
    choices = function()
      local list = {}
      for i, stat in ipairs(WindowModel.ShownStats(ns.db)) do list[i] = { key = stat.setting, label = stat.label } end
      if #list == 0 then list[1] = { key = "" } end
      return list
    end,
    get = current,
    set = function(key)
      selected = key
      builder.Refresh(ns.db)
    end,
    nameOf = function(key)
      for _, stat in ipairs(ns.STAT_LINES) do
        if stat.setting == key then return L[stat.label] end
      end
      return L.ROW_ORDER_NONE
    end,
  })
  local function move(delta)
    return function()
      selected = current(ns.db)
      if selected ~= "" then WindowModel.MoveStat(ns.db, selected, delta) end
    end
  end
  builder.AddButtonRow({
    { label = "ROW_ORDER_UP", onClick = move(-1) },
    { label = "ROW_ORDER_DOWN", onClick = move(1) },
    { label = "ROW_ORDER_RESET", onClick = function() ns.Set("rowOrder", "") end },
  }, { advanced = true })
end

-- Statistiken: Voreinstellungen über allen Kategorien, dann je Stat-Gruppe eine Unterseite mit einem Schalter je
-- Stat-Zeile direkt aus ns.STAT_LINES; Reihenfolge und Berechnung eigene Unterseiten
local STAT_GROUP_PAGES = {
  STAT_GROUP_XP = "OPTIONS_PAGE_STAT_XP",
  STAT_GROUP_PROGRESS = "OPTIONS_PAGE_STAT_PROGRESS",
  STAT_GROUP_COMBAT = "OPTIONS_PAGE_STAT_COMBAT",
  STAT_GROUP_LOOT = "OPTIONS_PAGE_STAT_LOOT",
  STAT_GROUP_INSTANCE = "OPTIONS_PAGE_STAT_INSTANCE",
  STAT_GROUP_TIME_MONEY = "OPTIONS_PAGE_STAT_TIME_MONEY",
}
addPage("STATISTICS")
addSection("SECTION_STAT_PRESETS")
local presetButtons = {}
for i, preset in ipairs(ns.STAT_PRESETS) do
  presetButtons[i] = { label = preset.label, onClick = function() ns.ApplyStatPreset(preset) end }
end
table.insert(presetButtons, { label = "PRESET_UNDO", onClick = function() ns.UndoStatPreset() end })
builder.AddButtonRow(presetButtons)
for _, group in ipairs(ns.STAT_GROUPS) do
  addSubPage(STAT_GROUP_PAGES[group] or group)  -- neue Gruppe ohne eigenen Kurznamen: Gruppenname
  local statToggles = {}
  for _, line in ipairs(ns.STAT_LINES) do
    if line.group == group then table.insert(statToggles, toggle(line.label, line.setting, line.available)) end
  end
  addToggles(statToggles)
  if group == "STAT_GROUP_INSTANCE" then
    addButton("INSTANCE_RESET", function() ns.Instances.ConfirmReset() end)
  end
end
addSubPage("OPTIONS_PAGE_ROW_ORDER")
addRowOrderSection()
addSubPage("OPTIONS_PAGE_CALCULATION")
addToggles({ advanced(toggle("XP_RATE_WITHOUT_AFK", "xpRateWithoutAfk")) })
addSlider({
  label = "IDLE_LIMIT",
  advanced = true,
  setting = "idleMinutes",
  min = ns.TimeBreakdown.MIN_IDLE_MINUTES,
  max = ns.TimeBreakdown.MAX_IDLE_MINUTES,
  step = 1,
  get = function(db) return db.idleMinutes end,
  set = function(value) ns.SetDeferred("idleMinutes", value) end,
  format = function(value) return value == 0 and L.IDLE_LIMIT_OFF or string.format(L.MINUTES, value) end,
})
addSlider({
  label = "TO_LEVEL_SAMPLES",
  advanced = true,
  setting = "toLevelSamples",
  min = ns.Experience.MIN_TO_LEVEL_SAMPLES,
  max = ns.Experience.MAX_TO_LEVEL_SAMPLES,
  step = 5,
  get = function(db) return db.toLevelSamples end,
  set = function(value) ns.SetDeferred("toLevelSamples", value) end,
  format = function(value)
    return value == 0 and L.TO_LEVEL_SAMPLES_LEVEL or string.format(L.TO_LEVEL_SAMPLES_VALUE, value)
  end,
})
finishSubPages()
finishPage()
