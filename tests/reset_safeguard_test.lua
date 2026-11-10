-- Tests für Roadmap 448 (Instanz-Reset-Ansage) und Roadmap 449 (Wildnis-Logout- & Sturzschutz)
local L = addon.L
local InstanceLimit = addon.InstanceLimit

local function sent() return wow.sentChat end

local function printedCount(pattern)
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find(pattern, 1, true) then found = found + 1 end
  end
  return found
end

---------------------------------------------------------------------------
-- Roadmap 448: Instanz-Reset-Ansage an die Gruppe
---------------------------------------------------------------------------
wow.login({ level = 60 })
wow.state.inGroup = true
wow.sentChat = {}

-- Aus: ResetInstances führt Original aus, sendet aber keinen Chat
expect("Standardwert announceInstanceReset ist false", addon.Database.SettingDefault("announceInstanceReset"), false)
ResetInstances()
expect("aus: kein Chat gesendet", #sent(), 0)
expect("ResetInstances Originalzähler erhöht", wow.state.instancesResetCount, 1)

-- An: ResetInstances sendet Nachricht mit Lockout-Zahlen an Gruppenchat
addon.Set("announceInstanceReset", true)
ResetInstances()
expect("an: ein Chat gesendet", #sent(), 1)
expect("ResetInstances Originalzähler erneut erhöht", wow.state.instancesResetCount, 2)
local limit = InstanceLimit.GetLimit()
local hourCount = InstanceLimit.GetHourCount()
local remaining = math.max(0, limit - hourCount)
local expectedText = string.format(L.INSTANCE_RESET_ANNOUNCEMENT, remaining, limit)
expect("Nachrichtentext", sent()[1].message, "Level Time: " .. expectedText)
expect("Chat-Kanal ist PARTY", sent()[1].chatType, "PARTY")

-- Ohne Gruppe: kein Chat
wow.sentChat = {}
wow.state.inGroup = false
ResetInstances()
expect("ohne Gruppe: kein Chat", #sent(), 0)
wow.state.inGroup = true

-- Bei Chat-Lockdown: kein Chat
wow.sentChat = {}
wow.state.chatLockdown = true
ResetInstances()
expect("bei Lockdown: kein Chat", #sent(), 0)
wow.state.chatLockdown = false

---------------------------------------------------------------------------
-- Roadmap 449: Wildnis-Logout-Warnung
---------------------------------------------------------------------------
expect("Standardwert warnWildernessLogout ist false", addon.Database.SettingDefault("warnWildernessLogout"), false)
wow.printed = {}
wow.state.resting = false
wow.fire("PLAYER_CAMPING")
expect("aus: keine Warnung", #wow.printed, 0)

addon.Set("warnWildernessLogout", true)

-- In Ruhezone: keine Warnung
wow.state.resting = true
wow.printed = {}
wow.fire("PLAYER_CAMPING")
expect("in Ruhezone: keine Warnung", #wow.printed, 0)

-- Außerhalb Ruhezone: Warnung erscheint
wow.state.resting = false
wow.printed = {}
wow.fire("PLAYER_CAMPING")
expectTrue("in Wildnis: Warnung gedruckt", printedCount(L.WARN_WILDERNESS_LOGOUT_TEXT) > 0)
expect("Notice-Titel", LevelTimerNotice.title:GetText(), L.WARN_WILDERNESS_LOGOUT_TITLE)
expect("Notice-Text", LevelTimerNotice.body:GetText(), L.WARN_WILDERNESS_LOGOUT_TEXT)

-- Auf Taxi: keine Warnung
wow.state.onTaxi = true
wow.printed = {}
wow.advance(10)
wow.fire("PLAYER_CAMPING")
expect("auf Taxi: keine Warnung", #wow.printed, 0)
wow.state.onTaxi = false

-- Als Geist/Tot: keine Warnung
wow.state.dead = true
wow.printed = {}
wow.advance(10)
wow.fire("PLAYER_CAMPING")
expect("tot: keine Warnung", #wow.printed, 0)
wow.state.dead = false

---------------------------------------------------------------------------
-- Roadmap 449: Sturz-Warnung (freier Fall >= 2.5 Sekunden)
---------------------------------------------------------------------------
expect("Standardwert warnFalling ist false", addon.Database.SettingDefault("warnFalling"), false)

-- Aus: Fallen löst nach 3 Sekunden nichts aus
wow.state.falling = true
wow.printed = {}
for _ = 1, 6 do
  wow.advance(0.5)
  wow.update(0.5)
end
expect("aus: kein Sturz-Hinweis", #wow.printed, 0)

-- An: Warnung nach >= 2.5 Sekunden Dauerfall
addon.Set("warnFalling", true)
wow.state.falling = false
wow.advance(1)
wow.update(1)

-- Fall beginnt: unter 2.5s noch still
wow.state.falling = true
wow.printed = {}
for _ = 1, 4 do
  wow.advance(0.5)
  wow.update(0.5)
end
expect("unter 2.5s Fall: noch keine Warnung", #wow.printed, 0)

-- Erreicht 3 Sekunden: Warnung wird ausgelöst
for _ = 1, 2 do
  wow.advance(0.5)
  wow.update(0.5)
end
expectTrue("nach 3s Fall: Warnung ausgelöst", printedCount(L.WARN_FALLING_TEXT) > 0)
expect("Notice-Titel für Sturz", LevelTimerNotice.title:GetText(), L.WARN_FALLING_TITLE)
expect("Notice-Text für Sturz", LevelTimerNotice.body:GetText(), L.WARN_FALLING_TEXT)

-- Fall beendet: Timer setzt sofort zurück
wow.state.falling = false
wow.advance(0.5)
wow.update(0.5)
wow.printed = {}

-- Dauerhüpfen auf ebener Strecke: je Sprung ~0,7 s in der Luft, dazwischen ein Bild Bodenkontakt; zusammen
-- weit über 2,5 s, aber kein langer Fall (Fehlalarm aus dem Debug-Log 2026-11-10)
wow.advance(11)   -- Sperre nach der letzten Warnung abgelaufen
wow.update(0)
wow.printed = {}
for _ = 1, 8 do
  wow.state.falling = true
  for _ = 1, 7 do
    wow.advance(0.1)
    wow.update(0.1)
  end
  wow.state.falling = false
  wow.advance(0.02)
  wow.update(0.02)
end
expect("Hüpfen: keine Sturzwarnung", printedCount(L.WARN_FALLING_TEXT), 0)

-- Kurzer Fall (1s) löst keine neue Warnung aus
wow.state.falling = true
for _ = 1, 2 do
  wow.advance(0.5)
  wow.update(0.5)
end
expect("kurzer Fall nach Reset: keine Warnung", #wow.printed, 0)
wow.state.falling = false
wow.advance(0.5)
wow.update(0.5)
