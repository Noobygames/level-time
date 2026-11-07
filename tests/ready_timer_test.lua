-- Bereit-Timer (readyTimer): Restzeit bei Bereitschaftscheck und Schlachtfeld-Einladung, nur wenn eingeschaltet
local L = addon.L
local battlefields = {}
function GetMaxBattlefieldID() return 2 end
function GetBattlefieldStatus(index) return (battlefields[index] or {}).status or "none" end
function GetBattlefieldPortExpiration(index) return (battlefields[index] or {}).seconds or 0 end

wow.login()
wow.fire("READY_CHECK", "Anführer", 30)
expect("aus: kein Rahmen", addon.ReadyTimer.Frame(), nil)

addon.Set("readyTimer", true)
wow.fire("READY_CHECK", "Anführer", 30)
expectTrue("Rahmen sichtbar", addon.ReadyTimer.Frame():IsShown())
expect("Restzeit", addon.ReadyTimer.TextLine(), string.format(L.READY_TIMER_CHECK, 30))
wow.advance(10)
wow.update(1)
expect("zählt herunter", addon.ReadyTimer.TextLine(), string.format(L.READY_TIMER_CHECK, 20))
wow.fire("READY_CHECK_FINISHED")
expect("Check vorbei: versteckt", addon.ReadyTimer.Frame():IsShown(), false)

battlefields[2] = { status = "confirm", seconds = 85 }
wow.fire("UPDATE_BATTLEFIELD_STATUS", 2)
expect("Schlachtfeld", addon.ReadyTimer.TextLine(),
  string.format(L.READY_TIMER_BATTLEFIELD, addon.Format.Duration(85)))
battlefields[2] = { status = "active" }
wow.fire("UPDATE_BATTLEFIELD_STATUS", 2)
expect("betreten: versteckt", addon.ReadyTimer.Frame():IsShown(), false)

addon.Set("readyTimer", false)
wow.fire("READY_CHECK", "Anführer", 30)
expect("aus: bleibt versteckt", addon.ReadyTimer.Frame():IsShown(), false)
