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
local function hasAnyBuff(spellIds)
  local names = buffNames(spellIds)
  if not next(names) then return false end
  return ns.Auras.Has(function(aura) return names[aura.name] == true end)
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

function ClassBuffs.Label(reminder)
  if reminder.kind == PET then return L.REMIND_PET_TOGGLE end
  if reminder.kind == WEAPON then return L.REMIND_WEAPON_ENCHANT_TOGGLE end
  local names = displayNames(reminder)
  local shown = {}
  for i = 1, math.min(#names, MAX_LABEL_NAMES) do shown[i] = names[i] end
  local text = table.concat(shown, " / ")
  if #names > MAX_LABEL_NAMES then text = text .. " ..." end
  return string.format(L.REMIND_CLASS_TOGGLE, text)
end

function ClassBuffs.TipKey(reminder)
  if reminder.kind == PET then return "REMIND_PET_TOGGLE_TIP" end
  if reminder.kind == WEAPON then return "REMIND_WEAPON_ENCHANT_TOGGLE_TIP" end
  return "REMIND_CLASS_TOGGLE_TIP"
end

function ClassBuffs.Message(reminder)
  if reminder.kind == PET then return L.REMIND_PET end
  if reminder.kind == WEAPON then return L.REMIND_WEAPON_ENCHANT end
  return string.format(L.REMIND_CLASS_BUFF, displayNames(reminder)[1] or "?")
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

for _, reminder in ipairs(ClassBuffs.REMINDERS) do
  ns.BuffReminder.Register({
    setting = reminder.setting,
    isMissing = function() return ClassBuffs.IsMissing(reminder) end,
    message = function() return ClassBuffs.Message(reminder) end,
    icon = function() return ClassBuffs.Icon(reminder) end,
  })
end
