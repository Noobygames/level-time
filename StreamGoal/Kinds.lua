-- Zielarten. Jede Art ist ein Eintrag mit:
--   color, icon        Farbe und Symbol der Karte (Alerts.ICONS von Level Time: Zahl = Spell-ID, sonst Pfad)
--   texture(goal)      (optional) eigenes Symbol des Ziels (Pfad oder Datei-ID, z.B. das Item), nil = icon
--   tooltip(goal, tt)  (optional) füllt den Tooltip beim Überfahren der Karte (tt = GameTooltip, schon verankert)
--   validate(params, target) -> Fehlertext oder nil
--   prepare(params, target) -> target  (optional) Ziel vor der Prüfung ergänzen, z.B. Standardwert
--   initial()          Startstand (nur wo er nicht 0 ist, z.B. das aktuelle Level)
--   manual             true = der Spieler zählt selbst (Goals.Step), kein Ereignis füttert die Art
--   hasCount(goal)     (optional) false = nur erledigt/offen, kein Zählerstand auf Karte und in Listen
--   title(goal)        Überschrift der Karte
--   body(goal)         zweite Zeile (optional)
-- Params je Art:
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

local Kinds = {}
ns.Kinds = Kinds

Kinds.ORDER = { "level", "kills", "item", "bgwin", "custom" }
Kinds.MAX_TEXT_LENGTH = 80  -- Zeichen eines eigenen Ziels (die Karte bricht längere Texte um)
Kinds.KILL_SOURCES = { "any", "pve", "pvp" }

local COLORS = {
  level = { 0.96, 0.79, 0.36 },
  kills = { 0.9, 0.3, 0.3 },
  item = { 0.64, 0.21, 0.93 },
  bgwin = { 0.3, 0.6, 1 },
  custom = { 0.4, 0.85, 0.75 },
}
local BGWIN_ICON = "Interface\\Icons\\INV_BannerPVP_02"
local CUSTOM_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local UNCOUNTED_TARGET = 1  -- eigenes Ziel ohne Zähler: ein Schritt = erledigt
local KILL_TITLES = { any = "SG_GOAL_KILLS_ANY", pve = "SG_GOAL_KILLS_PVE", pvp = "SG_GOAL_KILLS_PVP" }

local function validAmount(target)
  if type(target) ~= "number" or target < 1 or target ~= math.floor(target) then
    return L.SG_ERR_AMOUNT
  end
end

-- Item-ID und Link aus einem Link, "item:123..." oder einer Zahl; nil, wenn nichts Brauchbares darin steckt
function Kinds.ParseItem(text)
  text = text or ""
  local itemId = tonumber((text:match("item:(%d+)"))) or tonumber((text:match("^%s*(%d+)%s*$")))
  if not itemId then return nil end
  local link = text:match("|c.-|r")
  return itemId, link
end

-- Symbol des Items (Datei-ID) ohne Item-Cache; nil, wenn der Client die ID nicht kennt
local function itemTexture(itemId)
  local getInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not getInfoInstant then return nil end
  return (select(5, getInfoInstant(itemId)))
end

-- Hyperlink für den Tooltip: "item:..." aus dem gespeicherten Link (mit Werten wie Zufallsboni), sonst nur die ID
local function itemHyperlink(params)
  return params.link and params.link:match("|H(item:[^|]+)|h") or ("item:" .. params.itemId)
end

-- Anzeigename des Items: gespeicherter Link, sonst aus dem Client, sonst die ID
local function itemLabel(params)
  if params.link then return params.link end
  local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link
  if getItemInfo then name, link = getItemInfo(params.itemId) end
  return link or name or ("item:" .. params.itemId)
end

Goals.RegisterKind("level", {
  color = COLORS.level,
  icon = Alerts.ICONS.levelUp,
  validate = function(_, target)
    if type(target) ~= "number" or target <= LT.level then
      return string.format(L.SG_ERR_LEVEL, LT.level)
    end
  end,
  initial = function() return LT.level end,
  title = function(goal) return string.format(L.SG_GOAL_LEVEL, goal.target) end,
})

Goals.RegisterKind("kills", {
  color = COLORS.kills,
  icon = Alerts.ICONS.elite,
  validate = function(params, target)
    params.source = params.source or "any"
    if not KILL_TITLES[params.source] then return string.format(L.SG_ERR_UNKNOWN_KIND, params.source) end
    return validAmount(target)
  end,
  title = function(goal) return string.format(L[KILL_TITLES[goal.params.source]], goal.target) end,
  body = function(goal) return goal.params.battleground and L.SG_ONLY_BG or nil end,
})

Goals.RegisterKind("item", {
  color = COLORS.item,
  icon = Alerts.ICONS.loot,
  texture = function(goal) return itemTexture(goal.params.itemId) end,
  tooltip = function(goal, tooltip) tooltip:SetHyperlink(itemHyperlink(goal.params)) end,
  validate = function(params, target)
    if not params.itemId then return L.SG_ERR_ITEM end
    return validAmount(target)
  end,
  title = function(goal)
    local label = itemLabel(goal.params)
    if goal.target > 1 then return string.format(L.SG_GOAL_ITEM_COUNT, label, goal.target) end
    return string.format(L.SG_GOAL_ITEM, label)
  end,
  body = function(goal)
    return goal.params.boss and string.format(L.SG_SOURCE, goal.params.boss) or nil
  end,
})

Goals.RegisterKind("bgwin", {
  color = COLORS.bgwin,
  icon = BGWIN_ICON,
  validate = function(_, target) return validAmount(target) end,
  title = function(goal)
    local name = goal.params.battleground
    if name then return string.format(L.SG_GOAL_BGWIN_NAMED, name, goal.target) end
    return string.format(L.SG_GOAL_BGWIN_ANY, goal.target)
  end,
})

-- Länge in Zeichen (UTF-8, Umlaute zählen einfach); ohne strlenutf8 die Bytes
local function textLength(text)
  return strlenutf8 and strlenutf8(text) or #text
end

Goals.RegisterKind("custom", {
  color = COLORS.custom,
  icon = CUSTOM_ICON,
  manual = true,
  prepare = function(params, target)
    params.counted = target ~= nil
    return target or UNCOUNTED_TARGET
  end,
  validate = function(params, target)
    params.text = strtrim(params.text or "")
    if params.text == "" then return L.SG_ERR_TEXT end
    if textLength(params.text) > Kinds.MAX_TEXT_LENGTH then
      return string.format(L.SG_ERR_TEXT_LONG, Kinds.MAX_TEXT_LENGTH)
    end
    return validAmount(target)
  end,
  title = function(goal) return goal.params.text end,
  hasCount = function(goal) return goal.params.counted == true end,
})
