-- Klassen-Hinweise: Selbst-Buffs, Begleiter und Waffen-Verzauberungen, die beim Leveln dauerhaft aktiv sein sollten
-- (Rüstung des Magiers, Schild des Schamanen, Aspekt des Jägers, ...). Jeder Hinweis ist eine eigene Einstellung
-- (aus); die Schalter erscheinen nur für die eigene Klasse. Geprüft und gezeigt wie die übrigen Buff-Hinweise
-- (BuffReminder.lua: nur beim Leveln, außerhalb von Kampf und Ruhegebiet, Abstand reminderInterval).
--   buff    erinnert, wenn keiner der Buffs aktiv ist. Erkannt am Namen, den der Client für die Zauber-IDs in seiner
--           Sprache liefert: so zählen alle Ränge und Buffs von anderen (z.B. Seelenstärke eines anderen Priesters).
--   pet     erinnert, wenn kein lebender Begleiter da ist (nicht beim Fliegen).
--   weapon  erinnert, wenn die Haupthand keine temporäre Verzauberung hat (Gift, Waffenverzauberung des Schamanen);
--           ein Buff aus poisonBuffs (Retail-Gifte sind Buffs) zählt auch.
-- Erinnert wird nur, wenn der Charakter einen der Zauber aus known kennt (IsPlayerSpell; Classic hat je Rang eine
-- eigene ID, Rang 1 reicht, weil gelernte Ränge bekannt bleiben). Talente sind damit abgedeckt: Erdschild oder
-- Schattengestalt kennt nur, wer sie geskillt hat. Die Listen enthalten Classic- (Rang 1) und Retail-IDs; IDs, die es
-- in einem Client nicht gibt, liefern keinen Namen und zählen dort einfach nicht.
local _, ns = ...
local L = ns.L

local ClassBuffs = {}
ns.ClassBuffs = ClassBuffs

local BUFF, PET, WEAPON = "buff", "pet", "weapon"
local MAX_LABEL_NAMES = 2   -- so viele Zaubernamen stehen in der Beschriftung, danach "..."

-- spells = Buffs, die zählen; known = Zauber, von denen einer bekannt sein muss (Standard: spells)
ClassBuffs.REMINDERS = {
  { class = "MAGE", setting = "remindMageArmor", kind = BUFF,
    spells = { 168, 7302, 6117, 30482 } },                                -- Frost-, Eis-, Magier-, Glührüstung
  { class = "MAGE", setting = "remindArcaneIntellect", kind = BUFF,
    spells = { 1459, 23028 } },                                           -- Arkane Intelligenz, Arkane Brillanz
  { class = "PRIEST", setting = "remindFortitude", kind = BUFF,
    spells = { 1243, 21562 } },                                           -- Machtwort: Seelenstärke, Gebet der S.
  { class = "PRIEST", setting = "remindInnerFire", kind = BUFF, spells = { 588 } },
  { class = "PRIEST", setting = "remindShadowform", kind = BUFF, spells = { 15473, 232698 } },  -- Talent
  { class = "WARLOCK", setting = "remindDemonArmor", kind = BUFF,
    spells = { 687, 706, 28176 } },                                       -- Dämonenhaut, Dämonenrüstung, Teufelsrüstung
  { class = "WARLOCK", setting = "remindWarlockPet", kind = PET, known = { 688, 697 } },  -- Wichtel, Leerwandler
  { class = "DRUID", setting = "remindMarkOfTheWild", kind = BUFF,
    spells = { 1126, 21849 } },                                           -- Mal der Wildnis, Gabe der Wildnis
  { class = "DRUID", setting = "remindThorns", kind = BUFF, spells = { 467 } },
  { class = "DRUID", setting = "remindOmenOfClarity", kind = BUFF, spells = { 16864 } },  -- Talent (Classic)
  { class = "SHAMAN", setting = "remindShamanShield", kind = BUFF,
    spells = { 324, 24398, 408510, 974, 192106, 52127 } },                -- Blitzschlag-, Wasser- (TBC, Forever), Erdschild
  { class = "SHAMAN", setting = "remindShamanWeapon", kind = WEAPON,
    known = { 8017, 8024, 8033, 8232, 318038, 33757 } },                  -- Felsbeißer, Flammenzunge, Frostbrand, Windzorn
  { class = "PALADIN", setting = "remindBlessing", kind = BUFF,
    spells = { 19740, 19742, 20217, 1038, 19977, 20911, 25782, 25894, 25898, 25895, 25890, 25899 } },
  { class = "PALADIN", setting = "remindPaladinAura", kind = BUFF,
    spells = { 465, 7294, 19746, 19876, 19888, 19891, 20218, 32223, 183435, 317920 } },
  { class = "PALADIN", setting = "remindRighteousFury", kind = BUFF, spells = { 25780 } },
  { class = "HUNTER", setting = "remindAspect", kind = BUFF,
    spells = { 13165, 13163, 5118, 13159, 20043, 13161, 34074, 61846 } }, -- Falke, Affe, Gepard, Rudel, Wildnis, ...
  { class = "HUNTER", setting = "remindHunterPet", kind = PET, known = { 883 } },  -- Tier rufen
  { class = "ROGUE", setting = "remindPoisons", kind = WEAPON, known = { 8681, 315584, 2823 },
    poisonBuffs = { 315584, 2823, 8679, 3408, 5761, 381637 } },          -- Sofort-, Tödliches, Wund-, ... Gift
  { class = "WARRIOR", setting = "remindBattleShout", kind = BUFF, spells = { 6673 } },
  { class = "EVOKER", setting = "remindBronzeBlessing", kind = BUFF, spells = { 364342 } },
}

local function spellName(spellId)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellId) end
  return GetSpellInfo and (GetSpellInfo(spellId)) or nil
end

local function knowsSpell(spellId)
  if IsPlayerSpell then return IsPlayerSpell(spellId) == true end
  return IsSpellKnown ~= nil and IsSpellKnown(spellId) == true
end

local function playerClass()
  return select(2, UnitClass("player"))
end

-- Erster bekannter Zauber der Liste; nil, wenn keiner bekannt ist
local function firstKnown(spellIds)
  for _, spellId in ipairs(spellIds) do
    if knowsSpell(spellId) and spellName(spellId) then return spellId end
  end
  return nil
end

local function buffNames(spellIds)
  local names = {}
  for _, spellId in ipairs(spellIds or {}) do
    local name = spellName(spellId)
    if name then names[name] = true end
  end
  return names
end

-- true, wenn einer der Buffs aktiv ist; nil, wenn sich das nicht feststellen lässt (Auren gesperrt)
local lastLogged = {}  -- gesuchte Namen -> zuletzt geloggte vorhandene Buffs

-- Namen einer Menge als Text für das Debug-Log ("Blitzschlagschild, Wasserschild")
local function joinNames(names)
  local list = {}
  for name in pairs(names) do list[#list + 1] = name end
  table.sort(list)
  return table.concat(list, ", ")
end

-- Spell-IDs zum Nachsehen per ID (wenn die Buff-Liste gesperrt ist): die Liste plus der höchste gelernte Rang je
-- Name (C_Spell.GetSpellInfo(Name) liefert in Classic-Clients den höchsten bekannten Rang)
local function spellIdsWithRanks(spellIds, names)
  local ids, seen = {}, {}
  local function add(spellId)
    if type(spellId) == "number" and not ns.IsSecret(spellId) and not seen[spellId] then
      seen[spellId] = true
      ids[#ids + 1] = spellId
    end
  end
  for _, spellId in ipairs(spellIds) do add(spellId) end
  if C_Spell and C_Spell.GetSpellInfo then
    for name in pairs(names) do
      local ok, info = pcall(C_Spell.GetSpellInfo, name)
      if ok and type(info) == "table" then add(info.spellID) end
    end
  end
  return ids
end

local function hasAnyBuff(spellIds)
  local names = buffNames(spellIds)
  if not next(names) then return false end
  local active = ns.Auras.Has(function(aura) return names[aura.name] == true end)
  -- Buff-Liste gesperrt (im Kampf, Retail/Forever): einzeln per Spell-ID, soweit Blizzard sie freigibt
  if active == nil then return ns.Auras.HasPlayerSpell(spellIdsWithRanks(spellIds, names)) end
  if active == false then
    -- Fehlt laut Prüfung: gesuchte Namen und vorhandene Buffs, um falsche Zauber-IDs oder Namen zu erkennen
    local present = {}
    ns.Auras.ForEachBuff(function(aura) if aura.name then present[aura.name] = true end end)
    local wanted, buffs = joinNames(names), joinNames(present)
    if lastLogged[wanted] ~= buffs then  -- nur bei Änderung, die Prüfung läuft alle paar Sekunden
      lastLogged[wanted] = buffs
      ns.Debug("reminder", "missing: looking for %s, buffs %s", wanted, buffs)
    end
  end
  return active
end

local function hasLivingPet()
  return UnitExists("pet") and not UnitIsDead("pet")
end

local function hasMainHandEnchant()
  if not GetWeaponEnchantInfo then return nil end
  local hasMainHand = GetWeaponEnchantInfo()
  if ns.IsSecret(hasMainHand) then return nil end
  return hasMainHand == true or hasMainHand == 1
end

local CHECKS = {
  [BUFF] = function(reminder)
    local active = hasAnyBuff(reminder.spells)
    if active == nil then return nil end
    return not active
  end,
  [PET] = function()
    if UnitOnTaxi("player") then return nil end
    return not hasLivingPet()
  end,
  [WEAPON] = function(reminder)
    local enchanted = hasMainHandEnchant()
    if enchanted == nil then return nil end
    if enchanted then return false end
    local poisoned = hasAnyBuff(reminder.poisonBuffs)
    if poisoned == nil then return nil end
    return not poisoned
  end,
}

-- Zauber, an denen der Hinweis hängt (bekannt sein muss mindestens einer)
local function knownList(reminder)
  return reminder.known or reminder.spells
end

-- true = fehlt (erinnern), false = alles da, nil = nicht feststellbar oder nicht zutreffend (andere Klasse, Zauber
-- unbekannt, Auren gesperrt)
function ClassBuffs.IsMissing(reminder)
  if reminder.class ~= playerClass() or not firstKnown(knownList(reminder)) then return nil end
  return CHECKS[reminder.kind](reminder)
end

-- Name für Hinweis und Beschriftung: die bekannten Zauber (bzw. alle, solange keiner bekannt ist)
local function displayNames(reminder)
  local names, seen = {}, {}
  local list = knownList(reminder)
  local onlyKnown = firstKnown(list) ~= nil
  for _, spellId in ipairs(list) do
    local name = spellName(spellId)
    if name and not seen[name] and (not onlyKnown or knowsSpell(spellId)) then
      seen[name] = true
      names[#names + 1] = name
    end
  end
  return names
end

-- Bekannte Namen kurz: "Frostrüstung / Eisrüstung", ab MAX_LABEL_NAMES mit "..."
local function namesText(reminder)
  local names = displayNames(reminder)
  if #names == 0 then return "?" end
  local shown = {}
  for i = 1, math.min(#names, MAX_LABEL_NAMES) do shown[i] = names[i] end
  local text = table.concat(shown, " / ")
  if #names > MAX_LABEL_NAMES then text = text .. " ..." end
  return text
end

function ClassBuffs.Label(reminder)
  if reminder.kind == PET then return L.REMIND_PET_TOGGLE end
  if reminder.kind == WEAPON then return L.REMIND_WEAPON_ENCHANT_TOGGLE end
  return string.format(L.REMIND_CLASS_TOGGLE, namesText(reminder))
end

function ClassBuffs.TipKey(reminder)
  if reminder.kind == PET then return "REMIND_PET_TOGGLE_TIP" end
  if reminder.kind == WEAPON then return "REMIND_WEAPON_ENCHANT_TOGGLE_TIP" end
  return "REMIND_CLASS_TOGGLE_TIP"
end

function ClassBuffs.Message(reminder)
  if reminder.kind == PET then return L.REMIND_PET end
  if reminder.kind == WEAPON then return L.REMIND_WEAPON_ENCHANT end
  return string.format(L.REMIND_CLASS_BUFF, namesText(reminder))
end

-- Symbol: der erste bekannte Zauber (Spell-ID, siehe Lib/Card.lua)
function ClassBuffs.Icon(reminder)
  return firstKnown(knownList(reminder)) or knownList(reminder)[1]
end

-- Hinweise der eigenen Klasse (für die Einstellungen); leer bei Klassen ohne solche Buffs
function ClassBuffs.ForPlayerClass()
  local list = {}
  for _, reminder in ipairs(ClassBuffs.REMINDERS) do
    if reminder.class == playerClass() then list[#list + 1] = reminder end
  end
  return list
end

-- Selbst-Buffs (Schilde, Rüstungen) sind wichtig: auch im Kampf, in Instanzen und auf Maximallevel, und sofort,
-- wenn der Buff wegfällt (remindOnLoss), statt erst nach der Pause
for _, reminder in ipairs(ClassBuffs.REMINDERS) do
  local isBuff = reminder.kind == BUFF
  ns.BuffReminder.Register({
    inCombat = isBuff, anyLevel = true, remindOnLoss = isBuff,
    setting = reminder.setting,
    isMissing = function() return ClassBuffs.IsMissing(reminder) end,
    message = function() return ClassBuffs.Message(reminder) end,
    icon = function() return ClassBuffs.Icon(reminder) end,
  })
end
