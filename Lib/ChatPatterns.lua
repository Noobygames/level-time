-- Chatmeldungen anhand der lokalisierten Formatstrings des Clients auswerten
-- (z.B. COMBATLOG_XPGAIN_FIRSTPERSON = "%s dies, you gain %d experience.").
local _, ns = ...

local ChatPatterns = {}
ns.ChatPatterns = ChatPatterns

-- Formatstring -> { pattern, positions }. Jeder Platzhalter wird zum Capture; positions[i] ist die
-- Argument-Nummer des i-ten Captures, damit auch umgestellte Platzhalter ("%2$d ... %1$s") passen.
-- Nur am Anfang verankert, damit auch Varianten mit Zusatz ("... (+10 exp Rested bonus)") passen.
-- Steht %s am Ende (z.B. Retail: "Ihr erhaltet Beute: %s" ohne Punkt), nimmt es den Rest der Zeile;
-- ein kurzes "(.-)" ohne folgenden Text würde sonst leer passen.
-- stringCapture ersetzt "(.-)" für %s, z.B. ChatPatterns.LINK für Gegenstandslinks.
local STRING_CAPTURE = "(.-)"
local TRAILING_STRING_CAPTURE = "(.+)"
ChatPatterns.LINK = "(|c.-|r)"  -- Link samt Farbe; Punkte im Namen beenden ihn nicht

function ChatPatterns.Compile(format, stringCapture)
  local positions = {}
  local pattern = format:gsub("[%(%)%.%+%-%*%?%[%]]", "%%%0")  -- Pattern-Sonderzeichen escapen
  pattern = pattern:gsub("%%(%d?)%$?([sd])", function(position, kind)
    table.insert(positions, tonumber(position) or #positions + 1)
    return kind == "s" and (stringCapture or STRING_CAPTURE) or "(%d+)"
  end)
  if not stringCapture and pattern:sub(-#STRING_CAPTURE) == STRING_CAPTURE then
    pattern = pattern:sub(1, -#STRING_CAPTURE - 1) .. TRAILING_STRING_CAPTURE
  end
  return { pattern = "^" .. pattern, positions = positions }
end

-- Formate aus globalen Namen kompilieren; Namen, die der Client nicht kennt, fallen weg
function ChatPatterns.CompileGlobals(globalNames, stringCapture)
  local compiled = {}
  for _, globalName in ipairs(globalNames) do
    local format = _G[globalName]
    if format then
      table.insert(compiled, ChatPatterns.Compile(format, stringCapture))
    end
  end
  return compiled
end

-- Meldung gegen ein Format prüfen; Rückgabe: Argumente in Format-Reihenfolge oder nil.
-- Die meisten Chatzeilen passen nicht (fremde Beute im Raid, Systemmeldungen): erst ohne Tabelle prüfen, ob das
-- verankerte Muster überhaupt passt, und nur bei einem Treffer die Captures einsammeln.
function ChatPatterns.Match(message, compiled)
  if not message:find(compiled.pattern) then return nil end
  local captures = { message:match(compiled.pattern) }
  if #captures == 0 then return nil end
  local args = {}
  for i, position in ipairs(compiled.positions) do
    args[position] = captures[i]
  end
  return args
end

-- Erstes passende Format einer Liste (Reihenfolge: speziellere Formate zuerst)
function ChatPatterns.MatchAny(message, compiledList)
  for _, compiled in ipairs(compiledList) do
    local args = ChatPatterns.Match(message, compiled)
    if args then return args end
  end
  return nil
end
