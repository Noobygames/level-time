-- Mana-Ansage für Heiler: unter 25 % einmal an die Gruppe, wieder scharf ab 40 %; wartet bei gesperrtem Chat;
-- gesperrtes Mana (WoW Forever): nur "Kein Mana mehr!" bei der Fehlermeldung
local L = addon.L
local ManaCallout = addon.ManaCallout

local function sent(text)
  local count = 0
  for _, message in ipairs(wow.sentChat) do
    if message.message:find(text, 1, true) then count = count + 1 end
  end
  return count
end

local function mana(percent)
  wow.state.power = percent * 10
  ManaCallout.Check()
end

wow.login({ level = 30 })
wow.state.powerMax = 1000
wow.state.inGroup, wow.state.role = true, "HEALER"
wow.state.instance = { name = "Die Todesminen", type = "party" }

mana(20)
expect("aus: nichts", #wow.sentChat, 0)
addon.Set("announceLowMana", true)
mana(60)
mana(24)
expect("unter 25 %: Ansage", sent(string.format(L.LOW_MANA_ANNOUNCE, 24)), 1)
expect("an die Gruppe", wow.sentChat[#wow.sentChat].chatType, "PARTY")
mana(20)
mana(30)
mana(10)
expect("ohne Erholung keine zweite", #wow.sentChat, 1)
mana(45)
wow.state.chatLockdown = true
mana(15)
expect("Chat gesperrt: wartet", #wow.sentChat, 1)
wow.state.chatLockdown = false
mana(12)
expect("Chat frei: aktueller Wert", sent(string.format(L.LOW_MANA_ANNOUNCE, 12)), 1)

-- Nicht Heiler oder nicht im Dungeon: nichts
mana(50)
wow.state.role = "DAMAGER"
mana(10)
wow.state.role = "HEALER"
mana(50)
wow.state.instance = nil
mana(10)
expect("DD oder offene Welt: nichts", #wow.sentChat, 2)
wow.state.instance = { name = "Die Todesminen", type = "party" }

-- Gesperrtes Mana (WoW Forever): Fehlermeldung als Notlösung, höchstens alle 30 s
wow.state.power = wow.SECRET
ManaCallout.Check()
expect("geheim: keine Prozent-Ansage", #wow.sentChat, 2)
wow.fire("UI_ERROR_MESSAGE", 52, ERR_OUT_OF_MANA)
expect("kein Mana: Ansage", sent(L.OUT_OF_MANA_ANNOUNCE), 1)
wow.fire("UI_ERROR_MESSAGE", 52, ERR_OUT_OF_MANA)
expect("gleich danach nicht nochmal", sent(L.OUT_OF_MANA_ANNOUNCE), 1)
wow.advance(31)
wow.fire("UI_ERROR_MESSAGE", 52, ERR_OUT_OF_MANA)
expect("später wieder", sent(L.OUT_OF_MANA_ANNOUNCE), 2)
expect("keine Fehler", #wow.errors, 0)
