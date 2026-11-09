-- Chat-Befehle /lt und /leveltimer
local _, ns = ...
local L = ns.L

-- Hilfe (UX S25): /lt help nur die Alltagsbefehle (L.HELP), /lt help all alle, eine Zeile je Gruppe (L.HELP_ALL)
local function printLines(text)
  for line in text:gmatch("[^\n]+") do ns.Print(line) end
end

local function printHelp(argument)
  printLines((argument or ""):lower() == "all" and L.HELP_ALL or L.HELP)
end

-- Unbekannter Befehl oder unpassendes Argument: eine Zeile mit dem Verweis auf die Hilfe statt der ganzen Liste
local function printUnknown(name)
  ns.Print(string.format(L.COMMAND_UNKNOWN, name))
end

-- Schalter umlegen und den neuen Zustand melden
local function toggleSetting(key, onText, offText)
  ns.Set(key, not ns.db[key])
  ns.Print(L[ns.db[key] and onText or offText])
end

-- Anordnung des Hauptfensters umschalten: zum Layout hin, beim zweiten Aufruf zurück zur Tabelle
local function toggleLayout(layout, onText, offText)
  local enable = ns.db.windowLayout ~= layout
  ns.Set("windowLayout", enable and layout or ns.WindowLayouts.DEFAULT)
  ns.Print(L[enable and onText or offText])
end

local commands = {
  help = function(argument) printHelp(argument) end,
  [""] = function() ns.ToggleOptions() end,
  config = function() ns.ToggleOptions() end,
  history = function() ns.ToggleHistory() end,
  report = function() ns.InstanceReport.SendNow() end,
  lock = function()
    ns.Set("locked", true)
    ns.Print(L.LOCKED)
  end,
  unlock = function()
    ns.Set("locked", false)
    ns.Print(L.UNLOCKED)
  end,
  reset = function() ns.EditMode.ConfirmResetAll() end,  -- Position und Größe aller Anzeigen, nach Rückfrage
  edit = function() ns.EditMode.Toggle() end,
  welcome = function() ns.WelcomeCard.Show() end,  -- Willkommenskarte erneut (UI/WelcomeCard.lua)
  compact = function() toggleLayout("compact", "CMD_COMPACT_ON", "CMD_COMPACT_OFF") end,
  bar = function() toggleLayout("bar", "CMD_BAR_ON", "CMD_BAR_OFF") end,
  newsession = function() ns.StartNewSession() end,
  resetinstance = function() ns.Instances.ConfirmReset() end,
  recap = function() ns.ToggleRecap() end,
  -- /lt copy: Zeilen des aktuellen Chatfensters zum Kopieren (ChatCopy.lua)
  copy = function() ns.ChatCopy.ShowCurrent() end,
  stream = function() ns.StreamMode.Toggle() end,
  splits = function() toggleSetting("showSplitList", "CMD_SPLITS_ON", "CMD_SPLITS_OFF") end,
  -- /lt split [Name] | undo | template: eigene Splits (CustomSplits.lua)
  split = function(argument) ns.CustomSplits.Command(argument) end,
  -- /lt profile: Liste | <Name> wechseln | save <Name> | delete <Name> | export | import
  profile = function(argument)
    local Profiles = ns.Profiles
    local action, name = argument:match("^(%S*)%s*(.-)$")
    if argument == "" then
      local names = {}
      for i, profileName in ipairs(Profiles.GetNames()) do names[i] = Profiles.DisplayName(profileName) end
      ns.Print(string.format(L.PROFILE_LIST, Profiles.DisplayName(Profiles.GetActive()), table.concat(names, ", ")))
    elseif Profiles.Switch(argument) then
      return  -- der ganze Text ist ein Profilname, auch "save x" oder "export"
    elseif action == "save" then
      ns.ConfirmProfileSave(name)  -- vorhandenes Profil erst nach Rückfrage
    elseif action == "delete" then
      ns.ConfirmProfileDelete(name)
    elseif action == "export" then
      ns.Export.Show(Profiles.DisplayName(Profiles.GetActive()), Profiles.Export(Profiles.GetActive()))
    elseif action == "import" then
      ns.ShowProfileImport()
    else
      ns.Print(L.PROFILE_UNKNOWN)
    end
  end,
  -- /lt runs import | backup | verify | lss: Läufe einfügen, alle als Text sichern, Prüfcodes nachrechnen,
  -- Level-Splits als LiveSplit-Datei
  runs = function(argument)
    if argument == "import" then
      ns.ShowRunImport()
    elseif argument == "backup" then
      ns.Export.Show(L.RUNS_BACKUP, ns.Runs.ExportAll())
    elseif argument == "verify" then
      ns.RunCheck.PrintAll()
    elseif argument == "lss" then
      ns.LiveSplitExport.Show()
    else
      printUnknown(strtrim("runs " .. argument))
    end
  end,
  -- /lt compare best | pb | Name: Vergleich für die Splits
  compare = function(argument)
    local Splits = ns.Splits
    local mode = argument:lower()
    if mode == Splits.BEST or mode == Splits.PERSONAL_BEST then
      ns.Set("splitComparison", mode)
      ns.Print(L["COMPARE_" .. mode:upper()])
    elseif argument ~= "" and Splits.CompareWith(argument) then
      ns.Print(string.format(L.COMPARE_SET, Splits.GetReferenceName()))
    else
      ns.Print(L.COMPARE_USAGE)
    end
  end,
  -- /lt goal 30 setzt das Ziel-Level, /lt goal ohne Zahl entfernt es
  goal = function(argument)
    if argument == "" then  -- ohne Zahl nur den Stand zeigen, damit Nachschlagen nichts löscht
      local goal = ns.Goal.Get()
      ns.Print(goal and string.format(L.GOAL_STATUS, goal.level) or L.GOAL_NONE)
    elseif argument:lower() == "off" then
      ns.Goal.Clear()
      ns.Print(L.GOAL_CLEARED)
    elseif ns.Goal.Set(tonumber(argument)) then
      ns.Set("showGoal", true)
      ns.Print(string.format(L.GOAL_SET, ns.Goal.Get().level))
    else
      ns.Print(L.GOAL_INVALID)
    end
  end,
  -- /lt debug schaltet das erweiterte Logging, /lt debug <befehl> löst Testfunktionen aus (DebugTools.lua)
  debug = function(argument)
    if argument ~= "" then
      ns.DebugTools.Run(argument)
      return
    end
    ns.debug = not ns.debug  -- bewusst nicht gespeichert, gilt bis /reload
    ns.Print(ns.debug and L.DEBUG_ON or L.DEBUG_OFF)
  end,
  sync = function()
    ns.Print(L.CMD_SYNC)
    ns.PlayedTime.Sync(function(total, thisLevel)
      ns.Print(string.format(L.CMD_SYNCED, ns.Format.Duration(total), ns.Format.Duration(thisLevel)))
    end)
  end,
  show = function()
    ns.Set("showTimer", true)
    ns.Print(L.CMD_SHOWN)
  end,
  hide = function()
    ns.Set("showTimer", false)
    ns.Print(L.CMD_HIDDEN)
  end,
  minimap = function()
    local hide = not ns.db.minimap.hide
    ns.SetMinimapHidden(hide)  -- meldet das Ausblenden selbst (MINIMAP_HIDDEN)
    if not hide then ns.Print(L.CMD_MINIMAP_ON) end
  end,
}

-- Erstes Wort = Befehl, der Rest wird als Argument übergeben (z.B. "goal 30"; Lib/SlashCommands.lua)
ns.SlashCommands.Register({
  id = ns.ADDON_ID:upper(), names = { "/leveltimer", "/lt" }, commands = commands,
  onUnknown = function(name)
    if name == "" then printHelp() else printUnknown(name) end
  end,
})

-- Einmaliger Hinweis beim ersten Start (account-weit), damit man die Bedienung findet
ns.OnLogin(function()
  if ns.Database.TakeFirstStart() then ns.Print(L.INTRO) end
end)
