-- Geld: Einnahmen und Ausgaben nach Art (Roadmap 276 für die Einnahmen).
-- Beide werden über das gerade offene Fenster zugeordnet (WINDOWS: Händler, Flugmeister, Lehrer, Beute, Quest-Abgabe,
-- Post, Auktionshaus, Handel); eine Reparatur erkennt der Hook auf RepairAllItems (unser Merchant.lua und Blizzards
-- Button). Kommt binnen REPAIR_GRACE Sekunden keine Abbuchung (z.B. zu wenig Gold), verfällt die Merke, damit spätere
-- Ausgaben nicht als Reparatur zählen. Der Flug wird erst nach dem Schließen der Karte bezahlt, daher gilt die Art
-- noch CLOSE_GRACE Sekunden nach dem Schließen; ebenso kommt Quest-Gold nach QUEST_TURNED_IN.
-- Geteilte Beute in der Gruppe (und jedes gelootete Gold) meldet CHAT_MSG_MONEY, vor oder nach PLAYER_MONEY; eine
-- Einnahme ohne Fenster wird daher erst nach MONEY_MESSAGE_WAIT eingeordnet (Beute, wenn die Meldung in der Nähe lag,
-- sonst Sonstiges). Erlöse aus dem Auktionshaus kommen per Post und zählen als Post.
-- MONEY_EARNED bleibt die Summe aller Einnahmen. Einnahmen werden nicht mit Ausgaben verrechnet.
-- Außerdem: character.money = aktuelles Gold (Login, jede Änderung), für "Gold aller Charaktere" (History/Money.lua).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showMoney = false,
    showSpending = false,
    showIncome = false,
  },
  counters = {
    moneyEarned = 0,
    moneyJunk = 0,
    spentRepair = 0,
    spentMerchant = 0,
    spentTaxi = 0,
    spentTrainer = 0,
    spentOther = 0,
    incomeLoot = 0,
    incomeQuest = 0,
    incomeMerchant = 0,
    incomeMail = 0,
    incomeAuction = 0,
    incomeTrade = 0,
    incomeOther = 0,
  },
})
local Stats = ns.Stats

local CLOSE_GRACE = 2          -- Sekunden, die eine Art nach dem Schließen ihres Fensters noch gilt
local REPAIR_GRACE = 3         -- Sekunden, in denen die Abbuchung einer Reparatur erwartet wird
local MONEY_MESSAGE_WAIT = 1   -- Sekunden Abstand zwischen CHAT_MSG_MONEY und der Einnahme, die als Beute gelten

-- Fenster: Ereignisse zum Öffnen/Schließen, Zähler für Ausgaben und Einnahmen darin (nil = Sonstiges)
local WINDOWS = {
  { open = "MERCHANT_SHOW", close = "MERCHANT_CLOSED", spent = Stats.SPENT_MERCHANT, income = Stats.INCOME_MERCHANT },
  { open = "TAXIMAP_OPENED", close = "TAXIMAP_CLOSED", spent = Stats.SPENT_TAXI },
  { open = "TRAINER_SHOW", close = "TRAINER_CLOSED", spent = Stats.SPENT_TRAINER },
  { open = "LOOT_OPENED", close = "LOOT_CLOSED", income = Stats.INCOME_LOOT },
  { open = "QUEST_COMPLETE", close = "QUEST_FINISHED", income = Stats.INCOME_QUEST },
  { open = "MAIL_SHOW", close = "MAIL_CLOSED", income = Stats.INCOME_MAIL },
  { open = "AUCTION_HOUSE_SHOW", close = "AUCTION_HOUSE_CLOSED", income = Stats.INCOME_AUCTION },
  { open = "TRADE_SHOW", close = "TRADE_CLOSED", income = Stats.INCOME_TRADE },
}
local QUEST_WINDOW = WINDOWS[5]

local lastMoney
local context        -- Eintrag aus WINDOWS des offenen Fensters
local contextUntil   -- GetTime(), bis zu der context nach dem Schließen gilt; nil = offen
local repairUntil    -- GetTime(), bis zu der eine Abbuchung als Reparatur gilt; nil = keine erwartet
local lastMoneyMessageAt  -- GetTime() der letzten CHAT_MSG_MONEY

local function openContext(window)
  context, contextUntil = window, nil
end

local function closeContext(window)
  if context == window then contextUntil = GetTime() + CLOSE_GRACE end
end

local function currentContext()
  if context and (not contextUntil or GetTime() <= contextUntil) then return context end
  return nil
end

local function spendingKind()
  if repairUntil and GetTime() <= repairUntil then
    repairUntil = nil
    return Stats.SPENT_REPAIR
  end
  repairUntil = nil
  local window = currentContext()
  return window and window.spent or Stats.SPENT_OTHER
end

local function nearMoneyMessage(at)
  return lastMoneyMessageAt ~= nil and math.abs(lastMoneyMessageAt - at) <= MONEY_MESSAGE_WAIT
end

-- Summe und Art immer gemeinsam, damit ein Level-Up dazwischen sie nicht auf zwei Level verteilt
local function addIncome(kind, amount)
  Stats.Increment(Stats.MONEY_EARNED, amount)
  Stats.Increment(kind, amount)
end

local function bookIncome(amount)
  local window = currentContext()
  if window and window.income then
    ns.Debug("money", "income %s from window %s", amount, window.open)
    addIncome(window.income, amount)
    return
  end
  local at = GetTime()
  if nearMoneyMessage(at) then
    ns.Debug("money", "income %s as loot (money message before)", amount)
    addIncome(Stats.INCOME_LOOT, amount)
    return
  end
  C_Timer.After(MONEY_MESSAGE_WAIT, function()
    local loot = nearMoneyMessage(at)
    ns.Debug("money", "income %s as %s (waited for a money message)", amount, loot and "loot" or "other")
    addIncome(loot and Stats.INCOME_LOOT or Stats.INCOME_OTHER, amount)
  end)
end

ns.OnLogin(function()
  lastMoney = GetMoney()
  ns.character.money = lastMoney
  context, contextUntil, repairUntil, lastMoneyMessageAt = nil, nil, nil, nil
end)

ns.RegisterEvent("PLAYER_MONEY", function()
  local current = GetMoney()
  if lastMoney and current > lastMoney then
    bookIncome(current - lastMoney)
  elseif lastMoney and current < lastMoney then
    local kind = spendingKind()
    ns.Debug("money", "spent %s as %s", lastMoney - current, kind)
    Stats.Increment(kind, lastMoney - current)
  end
  lastMoney = current
  ns.character.money = current
end)

-- Gildenbank-Reparaturen kosten den Charakter nichts
hooksecurefunc("RepairAllItems", function(useGuildBank)
  if not useGuildBank then repairUntil = GetTime() + REPAIR_GRACE end
end)

for _, window in ipairs(WINDOWS) do
  ns.RegisterEvent(window.open, function() openContext(window) end)
  ns.RegisterEvent(window.close, function() closeContext(window) end)
end

-- Quest-Gold kommt mit der Abgabe, auch ohne offenes Belohnungsfenster (automatische Abgaben)
ns.RegisterEvent("QUEST_TURNED_IN", function()
  context, contextUntil = QUEST_WINDOW, GetTime() + CLOSE_GRACE
end)

ns.RegisterEvent("CHAT_MSG_MONEY", function()
  lastMoneyMessageAt = GetTime()
end)
