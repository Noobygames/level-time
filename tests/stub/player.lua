-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Spieler: Klassenlehrer, Mana, Spiegel-Leisten, Kontrollverlust, Werte, Aktionsplätze, CVars.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state

-- Klassenlehrer: state.trainer.services = { { name, serviceType, texture, reqLevel, subText } }
-- Forever liefert name, serviceType, texture, reqLevel, subText; Era/TBC name, subText, serviceType und Level/Symbol einzeln
function GetNumTrainerServices() return #state.trainer.services end
function GetTrainerServiceInfo(index)
  local service = state.trainer.services[index]
  if state.interface == 16001 then
    return service.name, service.serviceType, service.texture, service.reqLevel, service.subText
  end
  return service.name, service.subText, service.serviceType, false
end
function GetTrainerServiceLevelReq(index) return state.trainer.services[index].reqLevel end
function GetTrainerServiceIcon(index) return state.trainer.services[index].texture end
function IsTradeskillTrainer() return state.trainer.tradeskill or false end
-- Kosten je Zeile (service.cost); gekaufte Zeilen in wow.trained (Nummer)
wow.trained = {}
function GetTrainerServiceCost(index) return state.trainer.services[index].cost or 0 end
function BuyTrainerService(index) table.insert(wow.trained, index) end
function UnitHealthMax() return state.healthMax end
function UnitPowerMax() return state.powerMax end
-- Mana: state.power (aktuell), state.powerMax
function UnitPower() return state.power or 0 end
-- Spiegel-Leisten (Atem, Erschöpfung): state.mirrorProgress[timer] = Rest in ms; Blinken zählt wow.flashes
function GetMirrorTimerProgress(timer) return (state.mirrorProgress or {})[timer] end
wow.flashes = 0
function FlashClientIcon() wow.flashes = wow.flashes + 1 end
ERR_OUT_OF_MANA = "Nicht genug Mana"
-- Kontrollverlust: state.lossOfControl = { { locType, displayText, timeRemaining, displayType }, ... }
C_LossOfControl = {
  GetActiveLossOfControlDataCount = function() return #(state.lossOfControl or {}) end,
  GetActiveLossOfControlData = function(index) return (state.lossOfControl or {})[index] end,
}

-- UnitStat: Basiswert, Gesamtwert, positive und negative Buffs
function UnitStat(_, index)
  local value = state.stats[index] or 0
  local buff = state.statBuffs[index] or 0
  return value, value + buff, math.max(buff, 0), math.min(buff, 0)
end
function GetPVPSessionStats() return state.honorableKills end
function IsShiftKeyDown() return state.shiftDown end
function IsControlKeyDown() return state.controlDown == true end
-- Aktionsplätze: state.actions[platz] = { "item"/"spell"/"macro", id } (GetActionInfo)
function GetActionInfo(slot)
  local action = (state.actions or {})[slot]
  if action then return action[1], action[2] end
end
function IsModifiedClick() return state.modifiedClick == true end
-- CVars: state.cvars[name] (Text); GetCVarBool wie im Client "1" = true
function GetCVar(name) return (state.cvars or {})[name] end
function SetCVar(name, value) state.cvars = state.cvars or {}; state.cvars[name] = tostring(value) end
function GetCVarBool(name) return GetCVar(name) == "1" end
