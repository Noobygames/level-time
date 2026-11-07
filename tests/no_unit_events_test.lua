-- Wie unit_events_test.lua, aber in einem Client ohne Frame:RegisterUnitEvent (wow_stub.lua, Szenarien
-- no_unit_events_*): der Kern meldet das Event normal an und filtert selbst nach der Einheit.
dofile(wow.ADDON_DIR .. "/tests/unit_events_test.lua")
expect("ohne RegisterUnitEvent", wow.unitEventRegistrations, nil)
