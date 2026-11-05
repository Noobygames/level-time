-- Instanzlimit: 5 neue Instanzen pro Stunde für alle Charaktere eines Realms (Retail 10).
local InstanceLimit = addon.InstanceLimit
local L = addon.L

local function enter(name, instanceType)
  wow.state.instance = name and { name = name, type = instanceType or "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function warnings()
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find(L.INSTANCE_LIMIT_WARNING:match("^[^:]+"), 1, true) then found = found + 1 end
  end
  return found
end

local function row(setting)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == setting then return line.rows[1].value() end
  end
end

wow.state.interface = 11509  -- Classic Era
wow.state.clock = os.time({ year = 2026, month = 10, day = 2, hour = 12 })  -- Mittag: kein Tageswechsel im Test
wow.login()
addon.Set("warnInstanceLimit", true)
expect("Classic: 5 pro Stunde", InstanceLimit.GetLimit(), 5)
expect("ohne Instanzen", row("showInstanceLimit"), string.format(L.INSTANCE_LIMIT_VALUE, 0, 5))

-- Betreten zählt; /reload in der Instanz und kurzes Verlassen nicht
enter("Die Todesminen")
local firstEntered = time()
expect("erste Instanz", InstanceLimit.GetHourCount(), 1)
wow.logout()
wow.advance(20)
wow.login()
enter("Die Todesminen")
expect("Reload: gleiche Instanz", InstanceLimit.GetHourCount(), 1)
enter(nil)
wow.advance(300)
enter("Die Todesminen")
expect("kurz draußen: gleiche Instanz", InstanceLimit.GetHourCount(), 1)

-- Reset-Meldung: nächstes Betreten ist eine neue Instanz
enter(nil)
wow.fire("CHAT_MSG_SYSTEM", "'Die Todesminen' wurde zurückgesetzt.")
enter("Die Todesminen")
expect("nach Reset neu", InstanceLimit.GetHourCount(), 2)

-- Schlachtfelder zählen nicht, ein anderer Dungeon schon
enter("Warsongschlucht", "pvp")
expect("Schlachtfeld zählt nicht", InstanceLimit.GetHourCount(), 2)
wow.advance(600)
enter("Burg Schattenfang")
expect("anderer Dungeon", InstanceLimit.GetHourCount(), 3)
expect("noch keine Warnung", warnings(), 0)

-- Anderer Charakter auf demselben Realm zählt mit; ab 4/5 kommt ein Hinweis
enter(nil)
wow.logout()
wow.login({ name = "Zweitchar" })
enter("Die Todesminen")
expect("Zweitchar: eigene Instanz", InstanceLimit.GetHourCount(), 4)
expect("Hinweis bei 4/5", warnings(), 1)
expectTrue("Hinweis nennt den Stand", wow.printed[#wow.printed]:find("4/5", 1, true) ~= nil)
enter(nil)
wow.advance(1801)
enter("Die Todesminen")
expect("nach 30 min Pause neu", InstanceLimit.GetHourCount(), 5)
expect("Hinweis bei 5/5", warnings(), 2)

-- Älteste Instanz fällt eine Stunde nach dem Betreten heraus
local wait = firstEntered + InstanceLimit.WINDOW - time()
expect("nächste frei", InstanceLimit.GetSecondsUntilNextFree(), wait)
expect("Zeile mit Wartezeit", row("showInstanceLimit"),
  string.format(L.INSTANCE_LIMIT_NEXT, 5, 5, addon.Format.Duration(wait)))
wow.advance(wait)
expect("Platz frei", InstanceLimit.GetHourCount(), 4)
expect("heute alle", row("showInstancesToday"), "5")

-- Anderer Realm zählt getrennt
enter(nil)
wow.logout()
wow.login({ name = "Testchar", realm = "Andererrealm" })
expect("anderer Realm", InstanceLimit.GetHourCount(), 0)

-- Gegner zeigen die Kopie: korrigiert die Schätzung in beide Richtungen
local npcCounter = 0
local function seeCopy(zoneUID)
  for _ = 1, 2 do
    npcCounter = npcCounter + 1
    wow.state.units.target = { name = "Gegner",
      guid = string.format("Creature-0-1-33-%d-%d-00000000%02d", zoneUID, 500 + npcCounter, npcCounter) }
    wow.fire("PLAYER_TARGET_CHANGED")
  end
end
enter("Burg Schattenfang")
seeCopy(10)
enter(nil)
wow.advance(60)
enter("Burg Schattenfang")
expect("geschätzt dieselbe", InstanceLimit.GetHourCount(), 1)
seeCopy(11)
expect("andere Kopie: nachgezählt", InstanceLimit.GetHourCount(), 2)
enter(nil)
wow.advance(31 * 60)
enter("Burg Schattenfang")
expect("lange Pause: geschätzt neu", InstanceLimit.GetHourCount(), 3)
seeCopy(11)
expect("doch dieselbe Kopie: wieder entfernt", InstanceLimit.GetHourCount(), 2)

-- Server weist ab: Stand laut Addon dazu
local printed = #wow.printed
wow.fire("CHAT_MSG_SYSTEM", TRANSFER_ABORT_TOO_MANY_INSTANCES)
expectTrue("Abweisung mit Stand", wow.printed[printed + 1]:find("2/5", 1, true) ~= nil)

-- Retail erlaubt 10
wow.state.interface = 120105
expect("Retail: 10 pro Stunde", InstanceLimit.GetLimit(), 10)
