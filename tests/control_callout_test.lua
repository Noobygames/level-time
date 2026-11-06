-- Kontrollverlust-Ansage für Heiler: lesbare Art mit Dauer, geheime Art (WoW Forever) als "kann nicht heilen",
-- am Ende "wieder frei" mit gemessener Dauer
local L = addon.L

local function sent(text)
  local count = 0
  for _, message in ipairs(wow.sentChat) do
    if message.message:find(text, 1, true) then count = count + 1 end
  end
  return count
end

local function cc(entries)
  wow.state.lossOfControl = entries
  wow.fire("LOSS_OF_CONTROL_ADDED", "player", 1)
end

local function free()
  wow.state.lossOfControl = {}
  wow.fire("LOSS_OF_CONTROL_UPDATE", "player")
end

wow.login({ level = 30 })
wow.state.inGroup, wow.state.role = true, "HEALER"
wow.state.instance = { name = "Die Todesminen", type = "party" }

local sleep = { locType = "CONFUSE", displayText = "Schlafend", timeRemaining = 7.2, displayType = 2 }
cc({ sleep })
expect("aus: nichts", #wow.sentChat, 0)
free()

addon.Set("announceControlLoss", true)
cc({ sleep })
wow.advance(3)
free()
expect("ohne Entwarnung-Einstellung: kein Ende", sent(string.format(L.CC_ANNOUNCE_OVER, 3)), 0)
addon.Set("announceControlOver", true)
wow.advance(5)
cc({ sleep })
expect("Art und Dauer", sent(string.format(L.CC_ANNOUNCE, "Schlafend", 8)), 2)
wow.advance(7)
free()
expect("wieder frei mit Dauer", sent(string.format(L.CC_ANNOUNCE_OVER, 7)), 1)

-- Wurzeln hindern nicht am Heilen
wow.advance(5)
cc({ { locType = "ROOT", displayText = "Gewurzelt", timeRemaining = 5, displayType = 2 } })
expect("Wurzeln: nichts", #wow.sentChat, 3)
free()
expect("ohne CC kein Ende", #wow.sentChat, 3)

-- WoW Forever: Art geheim, große Anzeige
wow.advance(5)
cc({ { locType = wow.SECRET, displayText = wow.SECRET, timeRemaining = wow.SECRET, displayType = 2 } })
expect("geheim: kann nicht heilen", sent(L.CC_ANNOUNCE_GENERIC), 1)
wow.advance(15)
free()
expect("geheim: Ende gemessen", sent(string.format(L.CC_ANNOUNCE_OVER, 15)), 1)

-- Nicht Heiler: nichts
wow.state.role = "DAMAGER"
wow.advance(5)
cc({ sleep })
expect("DD: nichts", #wow.sentChat, 5)
expect("keine Fehler", #wow.errors, 0)
