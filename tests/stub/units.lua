-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Einheiten: Stufe, Klasse, Kampf, Auren, Gruppe, Bedrohung, Profiler-Uhr, Fehler-Handler, gesendete Chat-Nachrichten.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state

-- Andere Einheiten: units[unit].level, sonst die Stufe des Spielers
function UnitLevel(unit)
  local other = unit and unit ~= "player" and state.units[unit]
  if other and other.level then return other.level end
  return state.level
end
function UnitXP() return state.xp end
function UnitXPMax() return state.xpMax end
function GetMaxPlayerLevel() return state.maxLevel end
function GetXPExhaustion() return state.rested > 0 and state.rested or nil end
function GetMoney() return state.money end
function GetTime() return state.now end
-- Profiler-Uhr in Millisekunden: läuft mit GetTime; wow.profileMs schiebt sie zusätzlich vor (teurer Handler)
wow.profileMs = 0
function debugprofilestop() return state.now * 1000 + wow.profileMs end
-- Aufrufstapel wie im Client ("Datei.lua:Zeile: in function ...", ab dem Aufrufer), aus gopher-luas traceback
function debugstack()
  local trace = debug and debug.traceback and debug.traceback() or ""
  return (trace:gsub("^stack traceback:%s*[^\n]*\n", ""))
end
-- Geheime Werte (Retail/Forever): Tests setzen wow.SECRET als Rückgabe einer API
wow.SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
function issecretvalue(value) return value == wow.SECRET end
-- xpcall wie im WoW-Client (reicht Argumente durch) für Szenarien native_xpcall_*; sonst Lua 5.1 wie gopher-lua
if (SCENARIO or ""):match("^native_xpcall") then
  local luaXpcall = xpcall
  function xpcall(fn, handler, ...)
    local count, args = select("#", ...), { ... }
    return luaXpcall(function() return fn(unpack(args, 1, count)) end, handler)
  end
end
-- Fehler-Handler des Clients: merkt sich Fehler, statt sie anzuzeigen
wow.errors = {}
function geterrorhandler() return function(message) table.insert(wow.errors, message) end end
function GetCursorPosition() return state.cursorX, state.cursorY end
function UnitGUID(unit)
  if state.units[unit] and state.units[unit].guid then return state.units[unit].guid end
  return state.guid
end
function GetZoneText() return state.zone end
-- Nur die C_CombatLog-Variante: das globale CombatLogGetCurrentEventInfo ist im Client ein
-- Kompatibilitäts-Alias, der ohne CVar loadDeprecationFallbacks fehlt
C_CombatLog = { GetCurrentEventInfo = function() return unpack(state.combatLog) end }
function time(dateTable)
  if dateTable then return os.time(dateTable) end
  return state.clock
end
function UnitName(unit)
  if unit == nil or unit == "player" then return state.name end
  return state.units[unit] and state.units[unit].name
end
function UnitExists(unit) return unit == "player" or state.units[unit] ~= nil end
function UnitIsPlayer(unit) return unit == "player" or (state.units[unit] and state.units[unit].isPlayer) or false end
function UnitClassification(unit) return state.units[unit] and state.units[unit].classification or "normal" end
function GetRealmName() return state.realm end
-- Andere Einheiten: units[unit].class, sonst die Klasse des Spielers
function UnitClass(unit)
  local other = unit and unit ~= "player" and state.units[unit]
  local class = other and other.class or state.class
  return class, class
end
function UnitIsUnit(a, b) return a == b or (state.units[a] ~= nil and state.units[a] == state.units[b]) end
-- Reaktionsfarbe (UnitSelectionColor): units[unit].selection oder gelb
function UnitSelectionColor(unit)
  local color = state.units[unit] and state.units[unit].selection or { 1, 1, 0 }
  return color[1], color[2], color[3]
end
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
function UnitRace() return state.race[1], state.race[2], state.race[3] end
-- Spieler: state.dead/health; andere Einheiten: units[unit].dead/health (sonst wie der Spieler)
local function otherUnit(unit)
  return unit and unit ~= "player" and state.units[unit] or nil
end
function UnitIsDeadOrGhost(unit)
  local other = otherUnit(unit)
  if other then return other.dead == true end
  return state.dead
end
function UnitHealth(unit)
  local other = otherUnit(unit)
  return other and other.health or state.health
end
function IsInGuild() return state.inGuild end
function GetBuildInfo() return "12.1.5", "1", "2026-01-01", state.interface end
-- Spieler: state.inCombat; andere Einheiten: state.units[unit].combat
function UnitAffectingCombat(unit)
  if unit == nil or unit == "player" then return state.inCombat end
  return state.units[unit] ~= nil and state.units[unit].combat == true
end
function UnitIsGhost() return state.ghost == true end
function UnitOnTaxi() return state.onTaxi end
-- Kampfsperre für geschützte Frames (InCombatLockdown); unabhängig von inCombat, damit ältere Szenarien gleich bleiben
function InCombatLockdown() return state.combatLockdown == true end
-- Bewegung: state.moving; Tasten für Springen und Sitzen/Aufstehen (Bindings) tun nichts
function IsPlayerMoving() return state.moving == true end
function JumpOrAscendStart() end
function SitStandOrDescendStart() end
-- Bekannte Zauber (IsPlayerSpell): state.knownSpells[spellId] = true
function IsPlayerSpell(spellId) return (state.knownSpells or {})[spellId] == true end
function UnitIsDead(unit) return state.units[unit] ~= nil and state.units[unit].dead == true end
-- Temporäre Waffen-Verzauberung der Haupthand: state.mainHandEnchant = true
function GetWeaponEnchantInfo() return state.mainHandEnchant == true end
function GetInventoryItemCount(_, slot) return state.inventoryCounts[slot] or 0 end
function GetInventoryItemDurability(slot)
  local entry = state.durability[slot]
  if not entry then return nil end
  return entry[1], entry[2]
end
function UnitIsAFK() return state.afk end
function IsResting() return state.resting end
C_Spell = {
  GetSpellName = function(spellID) return state.spellNames[spellID] end,
  GetSpellTexture = function(spellID) return "Interface\Icons\Spell_" .. spellID end,
  -- Hilfreiche Zauber: state.helpfulSpells[spellID] = true
  IsSpellHelpful = function(spellID) return (state.helpfulSpells or {})[spellID] == true end,
}
-- Beschränkte Auren (Retail/Forever, z.B. Bosskampf): wie im Client bricht die Abfrage mit Fehler ab
-- Einzelne Auren per Spell-ID: state.secretSpellAuras[id] = true sperrt sie; aktiv ist eine Spell-ID, wenn ein Buff
-- in state.buffs sie trägt
C_Secrets = {
  ShouldAurasBeSecret = function() return state.aurasSecret == true end,
  ShouldSpellAuraBeSecret = function(spellId) return (state.secretSpellAuras or {})[spellId] == true end,
}
C_UnitAuras = {
  GetPlayerAuraBySpellID = function(spellId)
    for _, buff in ipairs(state.buffs) do
      if type(buff) == "table" and buff.spellId == spellId then return buff end
    end
    return nil
  end,
  GetAuraDataByIndex = function(_, index)
    if state.aurasSecret then
      error("GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'LevelTimer'")
    end
    local buff = state.buffs[index]
    if type(buff) == "string" then return { name = buff } end
    return buff
  end,
}
function IsInGroup() return state.inGroup end
-- Gruppengröße samt Spieler (state.groupSize), Schlachtzug (state.inRaid)
function GetNumGroupMembers() return state.groupSize or (state.inGroup and 2 or 0) end
function IsInRaid() return state.inRaid == true end
-- Bedrohung des Spielers (UnitThreatSituation): state.threat = 0..3 oder nil; Rolle: state.role
function UnitThreatSituation(unit) if unit == "player" then return state.threat end end
function UnitGroupRolesAssigned() return state.role or "NONE" end
-- Gegner: units[unit].hostile (UnitCanAttack), units[unit].tanking (1. Wert von UnitDetailedThreatSituation),
-- Ziel des Gegners als units[unit .. "target"]
function UnitCanAttack(_, unit) return state.units[unit] ~= nil and state.units[unit].hostile == true end
-- Von Spielern gesteuert (Begleiter): units[unit].playerControlled, Spieler selbst immer
function UnitPlayerControlled(unit)
  if unit == "player" then return true end
  local other = state.units[unit]
  return other ~= nil and (other.playerControlled == true or other.isPlayer == true)
end
-- Unterstützbar (befreundet): units[unit].friendly
function UnitCanAssist(_, unit) return unit == "player" or (state.units[unit] ~= nil and state.units[unit].friendly == true) end
function UnitDetailedThreatSituation(_, unit)
  local enemy = state.units[unit]
  if enemy == nil then return nil end
  return enemy.tanking
end
-- Gesendete Chat-Nachrichten landen in wow.sentChat als { message, chatType }
wow.sentChat = {}
