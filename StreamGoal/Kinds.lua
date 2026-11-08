-- Zielarten (Grundarten; weitere in Kinds/*.lua, je Datei Art, Formular, Befehl und Erfassung). Jede Art ist ein
-- Eintrag mit:
--   label              Locale-Key des Reiters im Fenster
--   group              Gruppe der Reiterzeile darüber (Goals.KIND_GROUPS: progress, combat, loot, quests, fun)
--   color, icon        Farbe (Theme-Token von Level Time) und Symbol der Karte (Alerts.ICONS: Zahl = Spell-ID, sonst Pfad)
--   texture(goal)      (optional) eigenes Symbol des Ziels (Pfad oder Datei-ID, z.B. das Item), nil = icon
--   tooltip(goal, tt)  (optional) füllt den Tooltip beim Überfahren der Karte (tt = GameTooltip, schon verankert)
--   form               Felder im Fenster (Window/GoalForm.lua: amount, fields)
--   inForm             false = kein Reiter im Formular des Reiters "Ziele" (Bingo hat einen eigenen Reiter)
--   parse(args, rest)  /sg add <Art> ...: Wörter und Rest der Eingabe -> params, target
--   usage              Locale-Key der Befehlszeile für /sg help
--   validate(params, target) -> Fehlertext oder nil
--   prepare(params, target) -> target  (optional) Ziel vor der Prüfung ergänzen, z.B. Standardwert
--   initial(params)    Startstand (nur wo er nicht 0 ist, z.B. das aktuelle Level)
--   deadlineSucceeds   true = Ablauf der Frist ist Erfolg statt Scheitern (Regeln: "bis dahin durchgehalten")
--   current(goal)      (optional) Stand beim Anlegen, wenn er ein Bestand ist (Gold, Items in den Taschen)
--   startAtCurrent     true = der Balken beginnt beim Stand zum Anlegen (current), nicht bei 0 (Rufwert)
--   manual             true = der Spieler zählt selbst (Goals.Step), kein Ereignis füttert die Art
--   step(goal, delta)  (optional, manual) neuer Stand für einen Klick (z.B. nächsten Punkt der Checkliste abhaken)
--   hasCount(goal)     (optional) false = nur erledigt/offen, kein Zählerstand auf Karte und in Listen
--   countText(goal)    (optional) Stand als Text statt "12 / 100" (z.B. Gold)
--   afterCreate(goal)  (optional) nach dem Anlegen, vor der Meldung "added" (Bingo legt seine Felder an)
--   title(goal)        Überschrift der Karte
--   body(goal)         zweite Zeile (optional)
-- Params der Grundarten:
--   level:  keine (target = Ziel-Level)
--   kills:  { source = "any"|"pve"|"pvp", battleground = true|nil }
--   item:   { itemId, link, name, boss } (boss = Anmerkung für die Karte, wird nicht geprüft)
--   bgwin:  { battleground = Name oder nil } (Teilstring des Schlachtfeld-Namens)
--   custom: { text, counted } (eigener Text; counted = mit Zähler bis target, sonst target 1 = einmal abhaken)
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L
local Alerts = LT.Alerts
local Theme = LT.Theme

local Kinds = {}
ns.Kinds = Kinds

Kinds.MAX_TEXT_LENGTH = 80  -- Zeichen eines eigenen Ziels (die Karte bricht längere Texte um)
Kinds.KILL_SOURCES = { "any", "pve", "pvp" }
Kinds.DEFAULT_AMOUNT = 1

-- Farben aus den Theme-Tokens von Level Time (dieselben Tabellen, ein Theme-Wechsel färbt die Karten mit um)
local COLORS = {
  level = Theme.COLORS.accent,
  kills = Theme.COLORS.bad,
  item = Theme.COLORS.best,
  bgwin = Theme.COLORS.info,
  custom = Theme.COLORS.success,
}
local BGWIN_ICON = "Interface\\Icons\\INV_BannerPVP_02"
local CUSTOM_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local UNCOUNTED_TARGET = 1  -- eigenes Ziel ohne Zähler: ein Schritt = erledigt
local KILL_TITLES = { any = "SG_GOAL_KILLS_ANY", pve = "SG_GOAL_KILLS_PVE", pvp = "SG_GOAL_KILLS_PVP" }
local SOURCE_LABELS = { any = "SG_FORM_SOURCE_ANY", pve = "SG_FORM_SOURCE_PVE", pvp = "SG_FORM_SOURCE_PVP" }

---------------------------------------------------------------------------
-- Gemeinsame Helfer der Zielarten
---------------------------------------------------------------------------
function Kinds.ValidAmount(target)
  if type(target) ~= "number" or target < 1 or target ~= math.floor(target) then
    return L.SG_ERR_AMOUNT
  end
end
local validAmount = Kinds.ValidAmount

-- Titel mit Anzahl in Einzahl oder Mehrzahl: bei count == 1 der Text <key>_ONE ("%d Gebiet entdecken"), sonst <key>
-- ("%d Gebiete entdecken"); weitere Werte nach count. Ziele sind nie 0, daher reicht "1 = Einzahl" in allen vier
-- Sprachen.
function Kinds.Counted(key, count, ...)
  local text = count == 1 and L[key .. "_ONE"] or L[key]
  return string.format(text, count, ...)
end

-- Wörter einer Eingabe
function Kinds.Words(text)
  local list = {}
  for word in (text or ""):gmatch("%S+") do table.insert(list, word) end
  return list
end

-- Länge in Zeichen (UTF-8, Umlaute zählen einfach); ohne strlenutf8 die Bytes
function Kinds.TextLength(text)
  return strlenutf8 and strlenutf8(text) or #text
end

-- Freitext prüfen und kürzen (strtrim); Rückgabe: Text oder nil und Fehlertext
function Kinds.CleanText(text, emptyError)
  text = strtrim(text or "")
  if text == "" then return nil, emptyError end
  if Kinds.TextLength(text) > Kinds.MAX_TEXT_LENGTH then
    return nil, string.format(L.SG_ERR_TEXT_LONG, Kinds.MAX_TEXT_LENGTH)
  end
  return text
end

-- Enthält name den gesuchten Teil (ohne Groß-/Kleinschreibung)? Ohne Suchtext passt alles.
function Kinds.Matches(name, wanted)
  if not wanted then return true end
  if type(name) ~= "string" or LT.IsSecret(name) then return false end
  return name:lower():find(wanted:lower(), 1, true) ~= nil
end

-- Item-ID und Link aus einem Link, "item:123..." oder einer Zahl; nil, wenn nichts Brauchbares darin steckt
function Kinds.ParseItem(text)
  text = text or ""
  local itemId = tonumber((text:match("item:(%d+)"))) or tonumber((text:match("^%s*(%d+)%s*$")))
  if not itemId then return nil end
  local link = text:match("|c.-|r")
  return itemId, link
end

-- /sg add item <Link oder ID> [Anzahl]: der Link enthält Leerzeichen im Namen ("|Hitem:123|h[Dunkle Klinge]|h"),
-- daher erst herauslösen, dann die Anzahl. Rückgabe: Item-Text, Rest der Wörter
function Kinds.SplitItemInput(rest)
  local link = rest:match("|c.-|r")
  local remainder = link and rest:gsub("|c.-|r", "", 1) or rest
  local words = Kinds.Words(remainder)
  if link then return link, words end
  return table.remove(words, 1), words
end

-- Symbol des Items (Datei-ID) ohne Item-Cache; nil, wenn der Client die ID nicht kennt
function Kinds.ItemTexture(itemId)
  local getInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not getInfoInstant then return nil end
  return (select(5, getInfoInstant(itemId)))
end

-- Hyperlink für den Tooltip: "item:..." aus dem gespeicherten Link (mit Werten wie Zufallsboni), sonst nur die ID
function Kinds.ItemHyperlink(params)
  return params.link and params.link:match("|H(item:[^|]+)|h") or ("item:" .. params.itemId)
end

-- Anzeigename des Items: gespeicherter Link, sonst aus dem Client, sonst die ID
function Kinds.ItemLabel(params)
  if params.link then return params.link end
  local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link
  if getItemInfo then name, link = getItemInfo(params.itemId) end
  return link or name or ("item:" .. params.itemId)
end

-- Formularfeld "item" (Text, Link per Shift-Klick) in itemId und link umsetzen
function Kinds.PrepareItem(params)
  if params.item then
    params.itemId, params.link = Kinds.ParseItem(params.item)
    params.item = nil
  end
end

---------------------------------------------------------------------------
-- Grundarten
---------------------------------------------------------------------------
Goals.RegisterKind("level", {
  label = "SG_KIND_LEVEL",
  group = "progress",
  usage = "SG_USAGE_LEVEL",
  color = COLORS.level,
  icon = Alerts.ICONS.levelUp,
  form = { amount = "SG_FORM_TARGET_LEVEL" },
  parse = function(args) return {}, tonumber(args[1]) end,
  validate = function(_, target)
    if type(target) ~= "number" or target <= LT.level then
      return string.format(L.SG_ERR_LEVEL, LT.level)
    end
  end,
  initial = function() return LT.level end,
  -- XP im laufenden Level, nur für den eigenen Charakter (andere haben keinen Live-Wert)
  partial = function(goal)
    if goal.character ~= LT.characterKey then return 0 end
    local xp, xpMax = UnitXP("player"), UnitXPMax("player")
    if LT.IsSecret(xp) or LT.IsSecret(xpMax) or not xp or not xpMax or xpMax <= 0 then return 0 end
    return math.max(0, math.min(1, xp / xpMax))
  end,
  title = function(goal) return string.format(L.SG_GOAL_LEVEL, goal.target) end,
})

Goals.RegisterKind("kills", {
  label = "SG_KIND_KILLS",
  group = "combat",
  usage = "SG_USAGE_KILLS",
  color = COLORS.kills,
  icon = Alerts.ICONS.elite,
  form = { amount = "SG_FORM_AMOUNT", fields = {
    { type = "choice", param = "source", label = "SG_FORM_SOURCE", values = Kinds.KILL_SOURCES, labels = SOURCE_LABELS },
    { type = "check", param = "battleground", label = "SG_FORM_ONLY_BG" },
  } },
  parse = function(args)
    local params = {}
    for _, word in ipairs(args) do
      word = word:lower()
      if KILL_TITLES[word] then params.source = word end
      if word == "bg" then params.battleground = true end
    end
    return params, tonumber(args[1])
  end,
  validate = function(params, target)
    params.source = params.source or "any"
    if not KILL_TITLES[params.source] then return string.format(L.SG_ERR_UNKNOWN_KIND, params.source) end
    return validAmount(target)
  end,
  title = function(goal) return Kinds.Counted(KILL_TITLES[goal.params.source], goal.target) end,
  body = function(goal) return goal.params.battleground and L.SG_ONLY_BG or nil end,
})

Goals.RegisterKind("item", {
  label = "SG_KIND_ITEM",
  group = "loot",
  usage = "SG_USAGE_ITEM",
  color = COLORS.item,
  icon = Alerts.ICONS.loot,
  texture = function(goal) return Kinds.ItemTexture(goal.params.itemId) end,
  tooltip = function(goal, tooltip) tooltip:SetHyperlink(Kinds.ItemHyperlink(goal.params)) end,
  form = { amount = "SG_FORM_AMOUNT", fields = {
    { type = "text", param = "item", label = "SG_FORM_ITEM", links = true },
    { type = "text", param = "boss", label = "SG_FORM_BOSS" },
  } },
  parse = function(_, rest)
    local item, words = Kinds.SplitItemInput(rest)
    return { item = item }, tonumber(words[1]) or Kinds.DEFAULT_AMOUNT
  end,
  prepare = function(params, target)
    Kinds.PrepareItem(params)
    return target or Kinds.DEFAULT_AMOUNT
  end,
  validate = function(params, target)
    if not params.itemId then return L.SG_ERR_ITEM end
    return validAmount(target)
  end,
  title = function(goal)
    local label = Kinds.ItemLabel(goal.params)
    if goal.target > 1 then return string.format(L.SG_GOAL_ITEM_COUNT, label, goal.target) end
    return string.format(L.SG_GOAL_ITEM, label)
  end,
  body = function(goal)
    return goal.params.boss and string.format(L.SG_SOURCE, goal.params.boss) or nil
  end,
})

Goals.RegisterKind("bgwin", {
  label = "SG_KIND_BGWIN",
  group = "combat",
  usage = "SG_USAGE_BGWIN",
  color = COLORS.bgwin,
  icon = BGWIN_ICON,
  form = { amount = "SG_FORM_AMOUNT", fields = { { type = "text", param = "battleground", label = "SG_FORM_BG" } } },
  parse = function(args)
    local name = table.concat(args, " ", 2)
    return { battleground = name ~= "" and name or nil }, tonumber(args[1]) or Kinds.DEFAULT_AMOUNT
  end,
  prepare = function(_, target) return target or Kinds.DEFAULT_AMOUNT end,
  validate = function(_, target) return validAmount(target) end,
  title = function(goal)
    local name = goal.params.battleground
    if name then return string.format(L.SG_GOAL_BGWIN_NAMED, name, goal.target) end
    return Kinds.Counted("SG_GOAL_BGWIN_ANY", goal.target)
  end,
})

Goals.RegisterKind("custom", {
  label = "SG_KIND_CUSTOM",
  group = "fun",
  usage = "SG_USAGE_CUSTOM",
  color = COLORS.custom,
  icon = CUSTOM_ICON,
  manual = true,
  form = { amount = "SG_FORM_COUNTER", fields = { { type = "text", param = "text", label = "SG_FORM_TEXT" } } },
  -- Eine führende Zahl ist der Zähler ("add custom 5 Alle Quests für RFC"), ohne Zahl ein Ziel zum Abhaken
  parse = function(args, rest)
    local counter = tonumber(args[1])
    local text = counter and rest:match("^%S+%s*(.*)$") or rest
    return { text = text }, counter
  end,
  prepare = function(params, target)
    params.counted = target ~= nil
    return target or UNCOUNTED_TARGET
  end,
  validate = function(params, target)
    local text, err = Kinds.CleanText(params.text, L.SG_ERR_TEXT)
    if not text then return err end
    params.text = text
    return validAmount(target)
  end,
  title = function(goal) return goal.params.text end,
  hasCount = function(goal) return goal.params.counted == true end,
})
