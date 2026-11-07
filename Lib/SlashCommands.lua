-- Verteiler für Chat-Befehle: erstes Wort = Befehl (ohne Groß-/Kleinschreibung), der Rest geht als Argument an den
-- Befehl (z.B. "/lt goal 30" -> commands.goal("30")). Die Befehle selbst liefert das Addon.
local _, ns = ...

local SlashCommands = {}
ns.SlashCommands = SlashCommands

-- options = { id = Schlüssel in SlashCmdList (z.B. "LEVELTIMER"), names = { "/leveltimer", "/lt" },
--             commands = { [name] = function(argument) }, ([""] = ohne Befehl),
--             onUnknown(name) = unbekannter oder fehlender Befehl (z.B. Hilfe zeigen) }
function SlashCommands.Register(options)
  for index, name in ipairs(options.names) do
    _G["SLASH_" .. options.id .. index] = name
  end
  SlashCmdList[options.id] = function(input)
    local name, argument = strtrim(input or ""):match("^(%S*)%s*(.-)$")
    local command = options.commands[name:lower()]
    if command then
      command(argument)
    else
      options.onUnknown(name)
    end
  end
end
