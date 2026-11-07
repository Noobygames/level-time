-- ns.RegisterUnitEvent: Unit-Events nur für die angemeldeten Einheiten; ns.UnregisterEvent und Event-Gruppen.
-- no_unit_events_test.lua führt dieselben Prüfungen ohne Frame:RegisterUnitEvent aus (Rückfall: selbst filtern).
-- Zähler stehen in einer Tabelle: nach einem pcall-Fehler (unbekanntes Event) schließt gopher-lua offene Upvalues
-- des Hauptblocks zu früh, Zahlen-Locals in Handlern würden dann nicht mehr hochgezählt.
local count = { other = 0, group = 0 }
wow.state.interface = 11509  -- Classic Era: Leben lesbar, Beinahe-Tod und Notfall verfügbar
wow.login()

local seen = {}
local function onAura(unit, info) table.insert(seen, unit .. ":" .. tostring(info)) end
expect("angemeldet", addon.RegisterUnitEvent("UNIT_AURA", "player", onAura), true)
wow.fire("UNIT_AURA", "party1", "a")
wow.fire("UNIT_AURA", "nameplate3", "b")
wow.fire("UNIT_AURA", "player", "c")
expect("nur der Spieler", #seen, 1)
expect("Argumente wie bei RegisterEvent", seen[1], "player:c")

-- Zwei Einheiten
local pets = {}
addon.RegisterUnitEvent("UNIT_HEALTH", { "player", "pet" }, function(unit) table.insert(pets, unit) end)
wow.fire("UNIT_HEALTH", "pet")
wow.fire("UNIT_HEALTH", "target")
wow.fire("UNIT_HEALTH", "player")
expect("Spieler und Begleiter", table.concat(pets, ","), "pet,player")

-- Unbekanntes Event: false statt Fehler
expect("unbekanntes Event", addon.RegisterUnitEvent(wow.UNKNOWN_EVENT, "player", onAura), false)

-- Abmelden: der Handler bekommt nichts mehr, andere Handler desselben Events schon
local function onOther() count.other = count.other + 1 end
addon.RegisterUnitEvent("UNIT_AURA", "player", onOther)
expect("abgemeldet", addon.UnregisterEvent("UNIT_AURA", onAura), true)
expect("zweimal abmelden", addon.UnregisterEvent("UNIT_AURA", onAura), false)
wow.fire("UNIT_AURA", "player", "d")
expect("abgemeldeter Handler still", #seen, 1)
expect("anderer Handler läuft", count.other, 1)
addon.UnregisterEvent("UNIT_AURA", onOther)
addon.RegisterUnitEvent("UNIT_AURA", "player", onAura)
wow.fire("UNIT_AURA", "player", "e")
expect("wieder angemeldet", seen[#seen], "player:e")

-- Normales Event abmelden, auch während der Verteilung (die laufende Verteilung endet mit der alten Liste)
local calls = {}
local function second() table.insert(calls, "second") end
local function first()
  table.insert(calls, "first")
  addon.UnregisterEvent("PLAYER_REGEN_ENABLED", second)
end
addon.RegisterEvent("PLAYER_REGEN_ENABLED", first)
addon.RegisterEvent("PLAYER_REGEN_ENABLED", second)
wow.fire("PLAYER_REGEN_ENABLED")
expect("laufende Verteilung unverändert", table.concat(calls, ","), "first,second")
wow.fire("PLAYER_REGEN_ENABLED")
expect("danach ohne den abgemeldeten", table.concat(calls, ","), "first,second,first")

-- Event-Gruppe: an/aus, unbekannte Events beim Anmelden
local group = addon.NewEventGroup()
local function onGroup() count.group = count.group + 1 end
group.Add("UNIT_SPELLCAST_SUCCEEDED", "player", onGroup)
group.Add("PLAYER_TARGET_CHANGED", nil, onGroup)
group.Add(wow.UNKNOWN_EVENT, nil, onGroup)
wow.fire("PLAYER_TARGET_CHANGED")
expect("Gruppe aus: nichts", count.group, 0)
local unknown = group.SetActive(true)
expect("unbekanntes Event gemeldet", unknown[1], wow.UNKNOWN_EVENT)
wow.fire("PLAYER_TARGET_CHANGED")
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "party2", "x", 1)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 1)
expect("Gruppe an", count.group, 2)
group.SetActive(false)
wow.fire("PLAYER_TARGET_CHANGED")
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 1)
expect("Gruppe wieder aus", count.group, 2)

-- Beinahe-Tod und Notfall hören nur auf den Spieler: Leben eines Gruppenmitglieds zählt nicht
addon.Set("emergencyHighlight", true)
wow.state.health = 50
wow.fire("UNIT_HEALTH", "party1")
expect("party1 erreicht den Notfall nicht", addon.Emergency.IsActive(), false)
wow.fire("UNIT_HEALTH", "player")
expect("Spieler schon", addon.Emergency.IsActive(), true)
addon.Set("emergencyHighlight", false)
expect("aus mit der Einstellung", addon.Emergency.IsActive(), false)
wow.state.health = 1000
wow.fire("UNIT_HEALTH", "player")

-- Retail/Forever: Leben immer geheim, die Handler sind gar nicht angemeldet
local nearDeaths = addon.Stats.Get(addon.Stats.LEVEL, addon.Stats.NEAR_DEATHS)
expect("Classic: der Spieler-Tiefpunkt oben war ein Beinahe-Tod", nearDeaths, 1)
wow.state.interface = 16001
addon.ApplySettings()
wow.state.health = 50
wow.fire("UNIT_HEALTH", "player")
wow.state.health = 1000
wow.fire("UNIT_HEALTH", "player")
expect("Forever: kein weiterer Beinahe-Tod", addon.Stats.Get(addon.Stats.LEVEL, addon.Stats.NEAR_DEATHS), nearDeaths)
