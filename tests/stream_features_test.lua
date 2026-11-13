-- Tests für Stream-Features & Gruppenbeitritt (Roadmap 313, 314, 315, 316, 317)
local L = addon.L
local ObsSignal = addon.ObsSignal
local RecapWindow = addon.RecapWindow
local StreamLink = addon.StreamLink
local SpellHistory = addon.SpellHistory
local GroupJoinStats = addon.GroupJoinStats

wow.login({ level = 10, xp = 100, xpMax = 1000 })
wow.runTimers()

---------------------------------------------------------------------------
-- 1. Roadmap 313: OBS-Signalfeld (UI/ObsSignal.lua)
---------------------------------------------------------------------------
expect("ObsSignal Default aus", addon.db.obsSignal, false)
expect("ObsSignal Default Größe", addon.db.obsSignalSize, 16)
expect("ObsSignal Frame initial versteckt", ObsSignal.frame:IsShown(), false)

-- Bei deaktiviertem Setting bleibt Trigger wirkungslos
ObsSignal.Trigger("levelup")
expect("Kein Signal wenn aus", ObsSignal.CurrentSignal(), nil)
expect("Frame bleibt versteckt", ObsSignal.frame:IsShown(), false)

-- Mit aktiviertem Setting ist der Frame sichtbar (schwarz)
addon.Set("obsSignal", true)
expect("Frame sichtbar mit Setting an", ObsSignal.frame:IsShown(), true)
expect("Kein aktives Signal", ObsSignal.CurrentSignal(), nil)

-- Signal manuell auslösen
ObsSignal.Trigger("levelup")
expect("Aktives Signal levelup", ObsSignal.CurrentSignal(), "levelup")

-- Nach Ablauf der Dauer (1.5 s) geht es zurück zu idle
wow.update(ObsSignal.DURATION + 0.1)
expect("Signal beendet", ObsSignal.CurrentSignal(), nil)
expect("Frame bleibt sichtbar (idle schwarz)", ObsSignal.frame:IsShown(), true)

-- Tod löst Rotsignal aus
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.state.dead = false
expect("Signal nach Tod ist death", ObsSignal.CurrentSignal(), "death")
wow.update(ObsSignal.DURATION + 0.1)
expect("Signal nach Tod beendet", ObsSignal.CurrentSignal(), nil)

-- Goal trigger
ObsSignal.Trigger("goal")
expect("Signal goal", ObsSignal.CurrentSignal(), "goal")
wow.update(ObsSignal.DURATION + 0.1)
expect("Signal goal beendet", ObsSignal.CurrentSignal(), nil)

addon.Set("obsSignal", false)
expect("Frame wieder versteckt", ObsSignal.frame:IsShown(), false)

---------------------------------------------------------------------------
-- 2. Roadmap 315: Stream-Link (Assist/StreamLink.lua)
---------------------------------------------------------------------------
expect("StreamLink Default leer", addon.db.streamLink, "")
expect("StreamLink Default Kanal aus", addon.db.streamLinkChannel, "off")
expect("StreamLink Default Minuten", addon.db.streamLinkMinutes, 30)

-- /lt streamlink ohne gesetzten Link: Meldung im Chat
wow.printed = {}
SlashCmdList.LEVELTIMER("streamlink")
expectTrue("Hinweis bei leerem Link", #wow.printed > 0)
expect("Export nicht geöffnet", LevelTimerExport:IsShown(), false)

-- /lt streamlink mit gesetztem Link: öffnet Export-Fenster
addon.Set("streamLink", "https://twitch.tv/mychannel")
SlashCmdList.LEVELTIMER("streamlink")
expectTrue("Export geöffnet mit Link", LevelTimerExport:IsShown())
LevelTimerExport:Hide()

-- /lt link Alias
SlashCmdList.LEVELTIMER("link")
expectTrue("Export geöffnet per Alias", LevelTimerExport:IsShown())
LevelTimerExport:Hide()

-- Zeitgesteuertes Senden in Gruppe
addon.Set("streamLinkChannel", "party")
wow.state.inGroup = true
wow.sentChat = {}

-- SendNow() sendet direkt
expectTrue("SendNow erfolgreich", StreamLink.SendNow())
expect("Eine Nachricht gesendet", #wow.sentChat, 1)
expect("An Party gesendet", wow.sentChat[1].chatType, "PARTY")
expectTrue("Link enthalten", wow.sentChat[1].message:find("twitch.tv/mychannel") ~= nil)

-- Lockdown verhindert Senden
wow.sentChat = {}
wow.state.chatLockdown = true
expect("Kein Senden bei Lockdown", StreamLink.SendNow(), false)
expect("Keine Chatnachricht", #wow.sentChat, 0)
wow.state.chatLockdown = false

-- Gildenkanal
addon.Set("streamLinkChannel", "guild")
wow.state.inGuild = true
wow.sentChat = {}
expectTrue("SendNow an Gilde", StreamLink.SendNow())
expect("An Gilde gesendet", wow.sentChat[1].chatType, "GUILD")

addon.Set("streamLinkChannel", "off")
wow.state.inGroup = false
wow.state.inGuild = false

---------------------------------------------------------------------------
-- 3. Roadmap 316: Zauberleiste für Zuschauer (UI/SpellHistory.lua)
---------------------------------------------------------------------------
expect("SpellHistory Default aus", addon.db.showSpellHistory, false)
expect("SpellHistory Default Anzahl", addon.db.spellHistoryCount, 5)
expect("SpellHistory Default Fade", addon.db.spellHistoryFadeSeconds, 10)
expect("SpellHistory Frame versteckt", SpellHistory.frame:IsShown(), false)

addon.Set("showSpellHistory", true)
SpellHistory.Clear()
expect("Historie leer", #SpellHistory.GetSpells(), 0)

-- Zauber wirken (UNIT_SPELLCAST_SUCCEEDED)
GetSpellTexture = function(spellID)
  return "Interface\\Icons\\Spell_Fire_Fireball02"
end

wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 133)
local spells = SpellHistory.GetSpells()
expect("Ein Zauber erfasst", #spells, 1)
expect("Zauber-ID", spells[1].spellID, 133)
expectTrue("Frame sichtbar nach Zauber", SpellHistory.frame:IsShown())

-- Duplizierte castGUID wird ignoriert
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 133)
expect("Duplikat ignoriert", #SpellHistory.GetSpells(), 1)

-- Weitere Zauber hinzufügen bis zur Maximalzahl
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-2", 134)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-3", 135)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-4", 136)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-5", 137)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-6", 138)
expect("Maximal 5 Zauber gehalten", #SpellHistory.GetSpells(), 5)
expect("Ältester entfernt (jetzt 134)", SpellHistory.GetSpells()[1].spellID, 134)

-- Rang (Roadmap 487): Zahl aus dem Untertext, Retail-Untertexte ohne Zahl zeigen nichts
C_Spell.GetSpellSubtext = function(spellID) return spellID == 140 and "Rank 3" or "Racial" end
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-7", 139)
expect("Kein Rang ohne Zahl im Untertext", SpellHistory.GetSpells()[5].rank, nil)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-8", 140)
expect("Rang aus dem Untertext", SpellHistory.GetSpells()[5].rank, "3")
C_Spell.GetSpellSubtext = nil

-- Fade: nach 10 Sekunden verblassen/entfernen
wow.advance(11)
wow.update(0.3)
expect("Zauber nach FadeSeconds abgelaufen", #SpellHistory.GetSpells(), 0)

addon.Set("showSpellHistory", false)
expect("Frame versteckt bei Setting aus", SpellHistory.frame:IsShown(), false)

---------------------------------------------------------------------------
-- 4. Roadmap 317: Statistik beim Gruppenbeitritt (Assist/GroupJoinStats.lua)
---------------------------------------------------------------------------
expect("GroupJoinStats Default aus", addon.db.announceGroupJoin, false)

-- Text() liefert formatierte Werte
local statsText = GroupJoinStats.Text()
expectTrue("Text enthält Level", statsText:find("Level 10") ~= nil)
expectTrue("Text enthält Tode", statsText:find("Tode") ~= nil or statsText:find("deaths") ~= nil)

-- Gruppenbeitritt prüfen wenn Setting aus -> kein Senden
wow.sentChat = {}
wow.state.inGroup = true
GroupJoinStats.CheckGroup()
expect("Keine Nachricht wenn deaktiviert", #wow.sentChat, 0)

-- Gruppenbeitritt mit aktiviertem Setting
addon.Set("announceGroupJoin", true)
wow.state.inGroup = false
GroupJoinStats.CheckGroup() -- merkt sich nicht in Gruppe

-- Jetzt Gruppe beitreten
wow.advance(GroupJoinStats.COOLDOWN + 1)
wow.state.inGroup = true
wow.sentChat = {}
expectTrue("CheckGroup meldet Erfolg beim Beitritt", GroupJoinStats.CheckGroup())
expect("Nachricht an Gruppe gesendet", #wow.sentChat, 1)
expect("Kanal ist PARTY", wow.sentChat[1].chatType, "PARTY")
expectTrue("Level enthalten", wow.sentChat[1].message:find("Level 10") ~= nil)

-- Zweiter Check innerhalb des Cooldowns sendet nicht noch einmal
expect("Cooldown sperrt erneutes Senden", GroupJoinStats.CheckGroup(), false)
expect("Keine zweite Nachricht", #wow.sentChat, 1)

addon.Set("announceGroupJoin", false)
