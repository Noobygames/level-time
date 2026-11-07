-- Formatierung von Zahlen, Zeiten und Geld für die Anzeige.
local _, ns = ...

local Format = {}
ns.Format = Format

local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400
local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000

local function splitDuration(totalSeconds)
  totalSeconds = math.floor(totalSeconds)
  return math.floor(totalSeconds / SECONDS_PER_DAY),
    math.floor(totalSeconds / SECONDS_PER_HOUR) % 24,
    math.floor(totalSeconds / SECONDS_PER_MINUTE) % 60,
    totalSeconds % 60
end

-- Einheiten in der eingestellten Sprache (UNIT_*_SHORT, z.B. "T" statt "d" auf Deutsch); erst beim Aufruf gelesen,
-- damit ein Sprachwechsel sofort gilt
local function unit(key)
  return ns.L[key]
end

-- Laufende Uhr mit Sekunden: "01h 02m 03s", ab einem Tag "1d 01h 02m 03s"
function Format.Clock(totalSeconds)
  local days, hours, minutes, seconds = splitDuration(totalSeconds)
  local clock = string.format("%02d%s %02d%s %02d%s", hours, unit("UNIT_HOUR_SHORT"), minutes, unit("UNIT_MINUTE_SHORT"),
    seconds, unit("UNIT_SECOND_SHORT"))
  if days > 0 then
    return string.format("%d%s %s", days, unit("UNIT_DAY_SHORT"), clock)
  end
  return clock
end

-- Kompakte Dauer mit den zwei größten Einheiten: "2d 3h", "1h 05m", "4m 10s", "35s"
function Format.Duration(totalSeconds)
  local days, hours, minutes, seconds = splitDuration(totalSeconds)
  if days > 0 then
    return string.format("%d%s %d%s", days, unit("UNIT_DAY_SHORT"), hours, unit("UNIT_HOUR_SHORT"))
  elseif hours > 0 then
    return string.format("%d%s %02d%s", hours, unit("UNIT_HOUR_SHORT"), minutes, unit("UNIT_MINUTE_SHORT"))
  elseif minutes > 0 then
    return string.format("%d%s %02d%s", minutes, unit("UNIT_MINUTE_SHORT"), seconds, unit("UNIT_SECOND_SHORT"))
  end
  return string.format("%d%s", seconds, unit("UNIT_SECOND_SHORT"))
end

-- Abweichung mit Vorzeichen: "+3m 12s", "-1m 05s" (Splits)
function Format.SignedDuration(seconds)
  local sign = seconds < 0 and "-" or "+"
  return sign .. Format.Duration(math.abs(seconds))
end

-- Farben aus Theme.lua: good = schneller, goodOnChroma = schneller auf grünem Chroma-Grund (OBS stanzt Grün aus),
-- bad = langsamer, best = Gold-Split (neue Bestzeit für das Level), neutral = innerhalb des Toleranzbands

-- Hervorhebungen einer Split-Abweichung statt grün/rot
Format.SPLIT_GOLD = "gold"
Format.SPLIT_EVEN = "even"
local STYLE_COLORS = { [Format.SPLIT_GOLD] = "best", [Format.SPLIT_EVEN] = "neutral" }

-- Split-Abweichung farbig: grün schneller, rot langsamer, style = Format.SPLIT_GOLD/SPLIT_EVEN hebt
-- hervor; "-" ohne Vergleichswert
function Format.SplitDelta(seconds, style)
  if not seconds then return "-" end
  local ahead = (ns.db and ns.db.windowBackground == "green") and "goodOnChroma" or "good"
  local color = STYLE_COLORS[style] or (seconds < 0 and ahead or "bad")
  return ns.Theme.Hex(color) .. Format.SignedDuration(seconds) .. "|r"
end

-- Große Zahlen kürzen: 950, 12.3k, 1.2M
function Format.Number(value)
  if value >= 1000000 then
    return string.format("%.1f%s", value / 1000000, unit("UNIT_MILLION_SHORT"))
  elseif value >= 1000 then
    return string.format("%.1f%s", value / 1000, unit("UNIT_THOUSAND_SHORT"))
  end
  return string.format("%d", value)
end

-- Ganze Zahl mit Tausender-Trennzeichen der Sprache (UNIT_THOUSANDS_SEPARATOR): "12.345" bzw. "12,345"
local THOUSANDS_GROUP = "^(-?%d+)(%d%d%d)"
function Format.Integer(value)
  local text = string.format("%d", math.floor(value + 0.5))
  local separator = unit("UNIT_THOUSANDS_SEPARATOR")
  local count
  repeat
    text, count = text:gsub(THOUSANDS_GROUP, "%1" .. separator:gsub("%%", "%%%%") .. "%2")
  until count == 0
  return text
end

-- Anteil in Prozent mit einer Nachkommastelle und dem Dezimalzeichen der Sprache: "38,9 %" bzw. "38.9%"
function Format.PercentPrecise(part, total)
  if total <= 0 then return "-" end
  local text = string.format("%.1f", part / total * 100)
  return string.format(unit("UNIT_PERCENT_FORMAT"), (text:gsub("%.", unit("UNIT_DECIMAL_SEPARATOR"))))
end

-- Anteil in Prozent, "-" wenn es keine Gesamtmenge gibt
function Format.Percent(part, total)
  if total <= 0 then return "-" end
  return string.format("%d%%", math.floor(part / total * 100 + 0.5))
end

-- Geld mit Münzsymbolen: C_CurrencyInfo.GetCoinTextureString in allen Clients; das globale
-- GetCoinTextureString ist nur ein Kompatibilitäts-Alias (CVar loadDeprecationFallbacks, in Forever nie)
function Format.Money(copper)
  copper = math.floor(copper)
  local coinString = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
  if coinString then
    return coinString(copper)
  end
  return Format.PlainMoney(copper)
end

-- Geld als reiner Text ("2g 30s 5c"), z.B. für Chat-Nachrichten an andere (Münzsymbole sind Texturcodes)
function Format.PlainMoney(copper)
  copper = math.floor(copper)
  return string.format("%d%s %d%s %d%s",
    math.floor(copper / COPPER_PER_GOLD), unit("UNIT_GOLD_SHORT"),
    math.floor(copper / COPPER_PER_SILVER) % 100, unit("UNIT_SILVER_SHORT"),
    copper % 100, unit("UNIT_COPPER_SHORT"))
end

-- Nur volles Gold, für schmale Tabellenspalten
function Format.Gold(copper)
  return string.format("%d%s", math.floor(copper / COPPER_PER_GOLD), unit("UNIT_GOLD_SHORT"))
end

-- Text ohne Farbcodes und Link-Markup (z.B. Item-Links), für Suche und Export
function Format.PlainText(value)
  local text = tostring(value or "")
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cnIQ%d+:", ""):gsub("|r", "")
  text = text:gsub("|H.-|h", ""):gsub("|h", "")
  return text
end
