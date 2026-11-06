-- Klassen-Hinweise: Selbst-Buffs, Begleiter und Waffen-Verzauberungen der eigenen Klasse; nur eingeschaltet, nur mit
-- bekanntem Zauber, Buffs am Namen erkannt (alle Ränge, auch von anderen). Der Stub-Charakter ist Krieger.
local BuffReminder, ClassBuffs = addon.BuffReminder, addon.ClassBuffs
local L = addon.L

local BATTLE_SHOUT, FROST_ARMOR, ICE_ARMOR = 6673, 168, 7302
wow.state.spellNames[BATTLE_SHOUT] = "Schlachtruf"
wow.state.spellNames[FROST_ARMOR] = "Frostrüstung"
wow.state.spellNames[ICE_ARMOR] = "Eisrüstung"
wow.state.spellNames[883] = "Tier rufen"
wow.state.spellNames[8681] = "Sofortwirkendes Gift"

local function shown(text)
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then count = count + 1 end
  end
  return count
end

local function reminderOf(setting)
  for _, reminder in ipairs(ClassBuffs.REMINDERS) do
    if reminder.setting == setting then return reminder end
  end
end

wow.login({ level = 10 })

-- Einstellungen: nur die Schalter der eigenen Klasse, beschriftet mit dem Zaubernamen des Clients
expect("Krieger: ein Hinweis", #ClassBuffs.ForPlayerClass(), 1)
SlashCmdList.LEVELTIMER("")
expectTrue("Reiter Hinweise", wow.click(L.OPTIONS_TAB_NOTIFICATIONS))
expectTrue("Schalter Schlachtruf", wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == string.format(L.REMIND_CLASS_TOGGLE, "Schlachtruf")
end) ~= nil)
expect("kein Magier-Schalter", wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text and label._text:find("Frostrüstung", 1, true) ~= nil
end), nil)

-- Zauber unbekannt: kein Hinweis, auch eingeschaltet
addon.Set("remindBattleShout", true)
BuffReminder.Check()
expect("unbekannt: still", shown("Schlachtruf"), 0)

-- Bekannt und fehlt: Hinweis mit Name und Symbol des Zaubers
wow.state.knownSpells = { [BATTLE_SHOUT] = true }
BuffReminder.Check()
expect("Hinweis", shown(string.format(L.REMIND_CLASS_BUFF, "Schlachtruf")), 1)
expect("als Karte", LevelTimerNotice.body:GetText(), string.format(L.REMIND_CLASS_BUFF, "Schlachtruf"))

-- Buff aktiv (auch von einem anderen Krieger): still
wow.advance(301)
wow.state.buffs = { "Schlachtruf" }
BuffReminder.Check()
expect("Buff aktiv: still", shown(string.format(L.REMIND_CLASS_BUFF, "Schlachtruf")), 1)
wow.state.buffs = {}

-- Andere Klasse: nie
expect("Magier-Hinweis beim Krieger", ClassBuffs.IsMissing(reminderOf("remindMageArmor")), nil)

-- Magier: jeder Rang und jede Rüstung zählt, beschriftet mit den bekannten
wow.state.class = "MAGE"
wow.state.knownSpells = { [FROST_ARMOR] = true, [ICE_ARMOR] = true }
local armor = reminderOf("remindMageArmor")
expect("Rüstung fehlt", ClassBuffs.IsMissing(armor), true)
wow.state.buffs = { "Eisrüstung" }
expect("Eisrüstung zählt", ClassBuffs.IsMissing(armor), false)
wow.state.buffs = {}
expect("Beschriftung mit bekannten", ClassBuffs.Label(armor),
  string.format(L.REMIND_CLASS_TOGGLE, "Frostrüstung / Eisrüstung"))

-- Jäger: Begleiter fehlt oder ist tot, nicht beim Fliegen
wow.state.class = "HUNTER"
wow.state.knownSpells = { [883] = true }
local pet = reminderOf("remindHunterPet")
expect("ohne Begleiter", ClassBuffs.IsMissing(pet), true)
wow.state.units.pet = { name = "Wolf" }
expect("mit Begleiter", ClassBuffs.IsMissing(pet), false)
wow.state.units.pet.dead = true
expect("Begleiter tot", ClassBuffs.IsMissing(pet), true)
wow.state.onTaxi = true
expect("im Flug nicht", ClassBuffs.IsMissing(pet), nil)
wow.state.onTaxi, wow.state.units.pet = false, nil

-- Schurke: Gift auf der Waffe oder als Buff
wow.state.class = "ROGUE"
wow.state.knownSpells = { [8681] = true }
local poisons = reminderOf("remindPoisons")
expect("ohne Gift", ClassBuffs.IsMissing(poisons), true)
wow.state.mainHandEnchant = true
expect("Gift auf der Waffe", ClassBuffs.IsMissing(poisons), false)
wow.state.mainHandEnchant = false

-- Gesperrte Auren (Retail/Forever im Bosskampf): nicht feststellbar, kein Hinweis
wow.state.class = "MAGE"
wow.state.knownSpells = { [FROST_ARMOR] = true }
wow.state.aurasSecret = true
expect("Auren gesperrt", ClassBuffs.IsMissing(armor), nil)
wow.state.aurasSecret = false
expect("keine Fehler", #wow.errors, 0)
