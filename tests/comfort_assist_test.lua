-- Komfort wie Leatrix Plus (Roadmap 329, Schritt 2): Beschwörung, Wiederbelebung, Freilassen im Schlachtfeld,
-- schneller plündern, Beute ohne Rückfrage, Fehlermeldungen und Zonentext, Kamera-Zoom. Alles aus, bis eingeschaltet.
local L = addon.L

local function actions(kind)
  local found = {}
  for _, action in ipairs(wow.comfortActions) do
    if action[1] == kind then table.insert(found, action) end
  end
  return found
end

local function printed(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

wow.login({ level = 20 })

---------------------------------------------------------------------------
-- Beschwörung: angekündigt, nach 10 s angenommen; Umschalt oder ein anderer Beschwörer verhindern es
---------------------------------------------------------------------------
wow.state.summon = { summoner = "Gnomi", area = "Brachland" }
wow.fire("CONFIRM_SUMMON")
wow.runTimers()
expect("aus: nicht angenommen", #actions("confirmSummon"), 0)

addon.Set("autoAcceptSummon", true)
wow.fire("CONFIRM_SUMMON")
expectTrue("angekündigt", printed(string.format(L.SUMMON_ACCEPT_IN, "Gnomi", "Brachland", 10)))
wow.runTimers()
expect("angenommen", #actions("confirmSummon"), 1)

wow.fire("CONFIRM_SUMMON")
wow.state.shiftDown = true
wow.runTimers()
wow.state.shiftDown = false
expect("Umschalt: nicht angenommen", #actions("confirmSummon"), 1)
expectTrue("Umschalt: gemeldet", printed(L.SUMMON_NOT_ACCEPTED))

wow.fire("CONFIRM_SUMMON")
wow.state.summon = { summoner = "Anderer", area = "Brachland" }
wow.runTimers()
expect("anderer Beschwörer: nicht angenommen", #actions("confirmSummon"), 1)

wow.state.inCombat = true
wow.fire("CONFIRM_SUMMON")
wow.runTimers()
wow.state.inCombat = false
expect("im Kampf: nicht angenommen", #actions("confirmSummon"), 1)

---------------------------------------------------------------------------
-- Wiederbelebung: sofort, nicht von kämpfenden oder toten Helfern
---------------------------------------------------------------------------
wow.state.units.Heiler = { name = "Heiler" }
wow.fire("RESURRECT_REQUEST", "Heiler")
expect("aus: keine Wiederbelebung", #actions("acceptResurrect"), 0)
addon.Set("autoAcceptResurrect", true)
wow.fire("RESURRECT_REQUEST", "Heiler")
expect("angenommen", #actions("acceptResurrect"), 1)
wow.state.units.Heiler.combat = true
wow.fire("RESURRECT_REQUEST", "Heiler")
expect("Kampf-Wiederbelebung: nicht", #actions("acceptResurrect"), 1)
wow.state.units.Heiler.combat, wow.state.units.Heiler.dead = false, true
wow.fire("RESURRECT_REQUEST", "Heiler")
expect("toter Helfer: nicht", #actions("acceptResurrect"), 1)

---------------------------------------------------------------------------
-- Freilassen: nur im Schlachtfeld, nicht mit Seelenstein
---------------------------------------------------------------------------
addon.Set("autoReleasePvP", true)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.runTimers()
expect("offene Welt: nicht freigelassen", #actions("repop"), 0)
wow.state.instance = { name = "Warsongschlucht", type = "pvp" }
wow.state.selfResurrect = { { name = "Seelenstein" } }
wow.fire("PLAYER_DEAD")
wow.runTimers()
expect("Seelenstein: nicht freigelassen", #actions("repop"), 0)
wow.state.selfResurrect = nil
wow.fire("PLAYER_DEAD")
wow.runTimers()
expect("Schlachtfeld: freigelassen", #actions("repop"), 1)
wow.state.dead, wow.state.instance = false, nil

---------------------------------------------------------------------------
-- Plündern: alle Plätze sofort, nur mit automatischem Plündern
---------------------------------------------------------------------------
wow.state.lootSlots = 3
addon.Set("fasterLoot", true)
wow.fire("LOOT_READY")
expect("ohne Autoloot: nichts", #actions("loot"), 0)
SetCVar("autoLootDefault", "1")
wow.fire("LOOT_READY")
expect("alle Plätze", #actions("loot"), 3)
expect("von hinten", actions("loot")[1][2], 3)
wow.state.modifiedClick = true
wow.fire("LOOT_READY")
wow.state.modifiedClick = false
expect("Plündern-Taste gedrückt: nichts", #actions("loot"), 3)

addon.Set("skipLootConfirm", true)
wow.fire("LOOT_BIND_CONFIRM", 2)
wow.fire("CONFIRM_LOOT_ROLL", 77, 1)
expect("seelengebunden bestätigt", actions("confirmBind")[1][2], 2)
expect("Würfeln bestätigt", actions("confirmRoll")[1][3], 1)

---------------------------------------------------------------------------
-- Fehlermeldungen: Fenster hört nicht mehr zu, wichtige zeigen wir selbst; aus = wie vorher
---------------------------------------------------------------------------
addon.Set("hideErrors", true)
expect("Fehlerfenster ohne Event", UIErrorsFrame:IsEventRegistered("UI_ERROR_MESSAGE"), false)
wow.fire("UI_ERROR_MESSAGE", 51, "Nicht genug Mana")
wow.fire("UI_ERROR_MESSAGE", 2, ERR_INV_FULL)
expect("nur die wichtige", #UIErrorsFrame._messages, 1)
expect("wichtige gezeigt", UIErrorsFrame._messages[1], ERR_INV_FULL)
addon.Set("hideErrors", false)
expect("aus: Event zurück", UIErrorsFrame:IsEventRegistered("UI_ERROR_MESSAGE"), true)

addon.Set("hideZoneText", true)
ZoneTextFrame:Show()
ZoneTextFrame._scripts.OnShow(ZoneTextFrame)
expect("Zonentext versteckt", ZoneTextFrame:IsShown(), false)

---------------------------------------------------------------------------
-- Kamera: nur beim Umschalten gesetzt
---------------------------------------------------------------------------
expect("aus: CVar unberührt", GetCVar("cameraDistanceMaxZoomFactor"), nil)
addon.Set("maxCameraZoom", true)
expect("weiter raus", GetCVar("cameraDistanceMaxZoomFactor"), "2.6")
addon.Set("maxCameraZoom", false)
expect("Standard zurück", GetCVar("cameraDistanceMaxZoomFactor"), "1.9")
expect("keine Fehler", #wow.errors, 0)
