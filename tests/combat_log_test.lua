-- Kampflog (Classic): eigener Frame ohne Verteiler; nur Treffer auf den Spieler zählen als letzter Treffer.
local DeathCounter = addon.DeathCounter
local PLAYER = wow.state.guid
wow.login()

wow.combatLog("SWING_DAMAGE", "Wolf", "Creature-1-9999")
expect("Treffer auf andere zählen nicht", DeathCounter.PeekLastHit().killer, nil)
wow.combatLog("SPELL_DAMAGE", "Kobold", PLAYER, 133, "Feuerball", 4, 50)
expect("Treffer auf den Spieler", DeathCounter.PeekLastHit().killer, "Kobold")
expect("Zauber", DeathCounter.PeekLastHit().spell, "Feuerball")
wow.combatLog("ENVIRONMENTAL_DAMAGE", nil, PLAYER, "Falling", 100)
local hit = DeathCounter.PeekLastHit()
expect("Umgebung", hit.environment, "Falling")
expect("Umgebung ohne Verursacher", hit.killer, nil)
hit.killer = "verändert"
expect("Kopie: der gemerkte Treffer bleibt", DeathCounter.PeekLastHit().killer, nil)
wow.combatLog("SPELL_HEAL", "Priester", PLAYER, 2061, "Blitzheilung")
expect("Heilung ändert nichts", DeathCounter.PeekLastHit().environment, "Falling")

-- Geheime Ziel-GUID (Retail-Unterbau): still ignorieren, kein Fehler
wow.combatLog("SWING_DAMAGE", "Geist", wow.SECRET)
expect("geheim: ignoriert", DeathCounter.PeekLastHit().environment, "Falling")

-- Zu alt: keine Ursache mehr
wow.advance(11)
expect("veraltet", DeathCounter.PeekLastHit().environment, nil)

-- Der Profiler misst den Kampflog-Frame unter eigenem Schlüssel
addon.Profiler.SetEnabled(true)
wow.combatLog("SWING_DAMAGE", "Wolf", "Creature-1-9999")
local measured
for _, item in ipairs(addon.Profiler.Results()) do
  if item.key == "event COMBAT_LOG_EVENT_UNFILTERED DeathCounter" then measured = item.count end
end
expect("gemessen", measured, 1)
addon.Profiler.SetEnabled(false)
