-- Große Einblendungen: nur eingeschaltete Arten, aus Journal und Level-Up, blenden nach Zeit aus.
local L = addon.L
local Journal = addon.Journal
local alert = LevelTimerAlert

local function shownText()
  if LevelTimerNotice:IsShown() then return LevelTimerNotice.title:GetText() end  -- Banner = Karte
  return alert:IsShown() and alert.text:GetText() or nil
end

wow.login({ level = 10 })
addon.Set("levelUpWindow", false)  -- sonst ersetzt das Fenster die Level-Up-Einblendung
expect("startet versteckt", shownText(), nil)

-- Standard: alles aus
wow.levelUp(11)
addon.Alerts.Clear()
Journal.AddKill(Journal.PVE, "Seuchenbiss", "rare")
expect("ohne Einstellung keine Einblendung", shownText(), nil)

addon.Set("alertLevelUp", true)
addon.Set("alertRareKill", true)
addon.Set("alertEpicLoot", true)
addon.Set("alertNearDeath", true)

addon.Alerts.Clear()
wow.levelUp(12)
expect("Level-Up", shownText(), string.format(L.ALERT_LEVEL_UP, 12))

addon.Alerts.Clear()
Journal.AddKill(Journal.PVE, "Seuchenbiss", "rare")
expect("Rare-Kill", shownText(), string.format(L.ALERT_RARE_KILL, "Seuchenbiss"))

-- Elite ist getrennt schaltbar (in Dungeons sehr häufig)
addon.Alerts.Clear()
Journal.AddKill(Journal.PVE, "Wächter", "elite")
expect("Elite aus: keine Einblendung", shownText(), nil)
addon.Set("alertEliteKill", true)
addon.Alerts.Clear()
Journal.AddKill(Journal.PVE, "Wächter", "elite")
expect("Elite-Kill", shownText(), string.format(L.ALERT_ELITE_KILL, "Wächter"))

-- In Dungeons und Raids keine Elite-Einblendung (dort ist fast alles Elite)
for _, kind in ipairs({ "party", "raid" }) do
  wow.state.instance = { name = "Todesminen", type = kind }
  addon.Alerts.Clear()
  Journal.AddKill(Journal.PVE, "Minenarbeiter", "elite")
  expect("keine Elite in " .. kind, shownText(), nil)
end
wow.state.instance = nil

-- Dieselbe Gegnerart allein höchstens alle 5 Minuten, andere Art sofort
addon.Alerts.Clear()
Journal.AddKill(Journal.PVE, "Wächter", "elite")
expect("gleiche Art gleich danach: keine Einblendung", shownText(), nil)
Journal.AddKill(Journal.PVE, "Berserker", "elite")
expect("andere Art", shownText(), string.format(L.ALERT_ELITE_KILL, "Berserker"))
wow.advance(301)
addon.Alerts.Clear()
Journal.AddKill(Journal.PVE, "Wächter", "elite")
expect("nach 5 Minuten wieder", shownText(), string.format(L.ALERT_ELITE_KILL, "Wächter"))

-- In einer Gruppe keine Elite-Einblendung (Elitegebiete in der offenen Welt)
wow.state.inGroup = true
wow.advance(301)
addon.Alerts.Clear()
Journal.AddKill(Journal.PVE, "Späher", "elite")
expect("in der Gruppe keine Elite", shownText(), nil)
wow.state.inGroup = nil

-- Nur epische Beute, seltene nicht
addon.Alerts.Clear()
Journal.AddLoot({ link = "[Blauer Ring]", quality = 3 })
expect("seltene Beute ohne Einblendung", shownText(), nil)
addon.Alerts.Clear()
Journal.AddLoot({ link = "[Lila Schwert]", quality = 4 })
expect("epische Beute", shownText(), string.format(L.ALERT_EPIC_LOOT, "[Lila Schwert]"))

-- Im Raid ist epische Beute normal: keine Einblendung; im Dungeon schon
wow.state.instance = { name = "Geschmolzener Kern", type = "raid" }
addon.Alerts.Clear()
Journal.AddLoot({ link = "[Raid-Helm]", quality = 4 })
expect("keine Beute im Raid", shownText(), nil)
wow.state.instance = { name = "Todesminen", type = "party" }
addon.Alerts.Clear()
Journal.AddLoot({ link = "[Dungeon-Helm]", quality = 4 })
expect("Beute im Dungeon", shownText(), string.format(L.ALERT_EPIC_LOOT, "[Dungeon-Helm]"))
wow.state.instance = nil

addon.Alerts.Clear()
Journal.AddNearDeath(4, {})
expect("Beinahe-Tod", shownText(), string.format(L.ALERT_NEAR_DEATH, 4))

-- Ausblenden: erst nach Haltezeit durchsichtiger, dann weg
local card = LevelTimerNotice
wow.advance(3.5)
card._scripts.OnUpdate(card, 0.1)
expect("blendet aus, noch sichtbar", card:IsShown(), true)
wow.advance(1)
card._scripts.OnUpdate(card, 0.1)
expect("nach Ablauf versteckt", card:IsShown(), false)
