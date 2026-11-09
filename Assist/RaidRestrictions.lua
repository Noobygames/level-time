-- Schlachtzug-Beschränkung aufheben (Reiter Komfort, System; noRaidRestrictions, Standard aus): erlaubt, dass dieser
-- Charakter auch mit niedrigem Level in einen Schlachtzug kommt bzw. die Gruppe trotzdem umgewandelt werden kann.
-- SetAllowLowLevelRaid(allow) und GetAllowLowLevelRaid() stehen in Blizzards API-Doku (PlayerScriptDocumentation)
-- aller Clients. Es zählt die Einstellung jedes niedrigen Mitglieds, nicht die des Leiters. Der Wert vor dem
-- Einschalten wird je Charakter gemerkt (character.lowLevelRaidOriginal) und beim Ausschalten wiederhergestellt;
-- solange die Einstellung aus ist, wird nichts gesetzt.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    noRaidRestrictions = false,
  },
})

local RaidRestrictions = {}
ns.RaidRestrictions = RaidRestrictions

function RaidRestrictions.IsAvailable()
  return SetAllowLowLevelRaid ~= nil and GetAllowLowLevelRaid ~= nil
end

ns.RegisterApply(function(db)
  local character = ns.character
  if not RaidRestrictions.IsAvailable() or not character then return end
  if db.noRaidRestrictions == true then
    if character.lowLevelRaidOriginal == nil then character.lowLevelRaidOriginal = GetAllowLowLevelRaid() == true end
    if GetAllowLowLevelRaid() ~= true then
      SetAllowLowLevelRaid(true)
      ns.Debug("comfort", "low level raid allowed")
    end
  elseif character.lowLevelRaidOriginal ~= nil then
    SetAllowLowLevelRaid(character.lowLevelRaidOriginal)
    ns.Debug("comfort", "low level raid restored to %s", character.lowLevelRaidOriginal)
    character.lowLevelRaidOriginal = nil
  end
end)
