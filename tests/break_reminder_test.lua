-- Pausen-Erinnerung: nach N Minuten Spielzeit ohne Pause, nicht im Kampf/in Instanzen, AFK zählt als Pause
local L = addon.L
local BreakReminder = addon.BreakReminder

local function reminders()
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(L.BREAK_REMINDER:sub(1, 12), 1, true) then count = count + 1 end
  end
  return count
end

-- Zeit vergeht wie im Spiel: OnUpdate in kleinen Schritten
local function play(seconds)
  for _ = 1, seconds / 5 do
    wow.advance(5)
    wow.update(5)
  end
end

wow.login({ level = 20 })
play(3700)
expect("aus: nichts", reminders(), 0)

addon.Set("remindBreak", true)
addon.Set("breakMinutes", 60)
wow.update(5)
expect("nach 60 min: Erinnerung", reminders(), 1)
expect("Karte", LevelTimerNotice.title:GetText(), L.NOTICE_BREAK)
play(600)
expect("danach erst wieder nach 60 min", reminders(), 1)

-- Im Kampf und in Instanzen wartet sie
play(2950)
wow.state.inCombat = true
play(60)
expect("im Kampf: wartet", reminders(), 1)
wow.state.inCombat = false
wow.state.instance = { name = "Die Todesminen", type = "party" }
play(30)
expect("in der Instanz: wartet", reminders(), 1)
wow.state.instance = nil
play(5)
expect("danach: Erinnerung", reminders(), 2)

-- AFK zählt nicht mit; 5 Minuten AFK am Stück sind eine Pause
play(1800)
wow.state.afk = true
play(400)
wow.state.afk = false
expectTrue("AFK setzt zurück", BreakReminder.SecondsSinceBreak() < 60)
play(1800)
expect("ohne volle Stunde keine Erinnerung", reminders(), 2)

-- Übersteht /reload
local before = BreakReminder.SecondsSinceBreak()
wow.logout()
wow.login({ level = 20 })
expectNear("Stand nach /reload", BreakReminder.SecondsSinceBreak(), before, 10)
