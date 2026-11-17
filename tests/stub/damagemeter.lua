-- Schadensmesser des Clients (C_DamageMeter, Retail und WoW Forever): nur auf Anfrage eines Tests, damit Classic Era
-- ihn wie der echte Client nicht hat.
--   wow.installDamageMeter({ { id = 1, name = "Rhahk'Zor", sources = { [Enum.DamageMeterType.DamageDone] = { { name, classFilename,
--     totalAmount, isLocalPlayer, sourceGUID } } }, spells = { [guid] = { { creatureName, totalAmount } } } } })
-- sources = Quellen je Messwert (Enum.DamageMeterType), spells = Zauber je Quelle für DamageTaken

Enum = Enum or {}
Enum.DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, Hps = 3, Absorbs = 4, Interrupts = 5, Dispels = 6,
  DamageTaken = 7, AvoidableDamageTaken = 8, Deaths = 9, EnemyDamageTaken = 10 }

function wow.installDamageMeter(sessions, available)
  local byID = {}
  for _, session in ipairs(sessions) do byID[session.id] = session end
  C_DamageMeter = {
    IsDamageMeterAvailable = function() return available ~= false, "" end,
    GetAvailableCombatSessions = function()
      local list = {}
      for _, session in ipairs(sessions) do
        list[#list + 1] = { sessionID = session.id, name = session.name, durationSeconds = 60 }
      end
      return list
    end,
    GetCombatSessionFromID = function(id, meterType)
      local session = byID[id]
      return { combatSources = session and session.sources[meterType] or {}, maxAmount = 0, totalAmount = 0 }
    end,
    GetCombatSessionSourceFromID = function(id, _, guid)
      local session = byID[id]
      return { combatSpells = session and session.spells and session.spells[guid] or {}, maxAmount = 0, totalAmount = 0 }
    end,
  }
end

-- Porträt eines Einheiten-Symbols: im Test nur merken, welche Einheit gezeigt wird
function SetPortraitTexture(texture, unit) texture._portraitUnit = unit end
CLASS_ICON_TCOORDS = { WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 }, PRIEST = { 0.5, 0.75, 0.25, 0.5 } }
