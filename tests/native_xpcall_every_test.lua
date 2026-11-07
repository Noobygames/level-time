-- Wie every_test.lua, aber mit xpcall wie im WoW-Client (reicht Argumente durch, siehe wow_stub.lua):
-- ns.SafeCall nimmt dann xpcall direkt statt der Argument-Plätze.
dofile(wow.ADDON_DIR .. "/tests/every_test.lua")
