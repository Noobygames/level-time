-- Tests für Roadmap 443 (threatShowNumeric) und Roadmap 446 (cooldownNumbers / OmniCC Light).
local ThreatDisplay = addon.ThreatDisplay
local CooldownNumbers = addon.CooldownNumbers

wow.login()

---------------------------------------------------------------------------
-- 1. ThreatDisplay: CVar threatShowNumeric
---------------------------------------------------------------------------
expect("threatShowNumeric default false", addon.Database.SettingDefault("threatShowNumeric"), false)
expect("threatShowNumeric db initial false", LevelTimerDB.threatShowNumeric, false)

SetCVar("threatShowNumeric", "0")
addon.ApplySettings()
expect("aus: CVar unberuehrt", GetCVar("threatShowNumeric"), "0")

addon.Set("threatShowNumeric", true)
expect("threatShowNumeric CVar auf 1 gesetzt", GetCVar("threatShowNumeric"), "1")
expect("Original gemerkt", LevelTimerDB.cvarOriginals.threatShowNumeric, "0")

addon.Set("threatShowNumeric", false)
expect("threatShowNumeric CVar auf Original 0 restauriert", GetCVar("threatShowNumeric"), "0")
expect("Original vergessen", LevelTimerDB.cvarOriginals, nil)

-- Vorher schon 1 gewesen
SetCVar("threatShowNumeric", "1")
addon.Set("threatShowNumeric", true)
addon.Set("threatShowNumeric", false)
expect("vorheriges 1 wiederhergestellt", GetCVar("threatShowNumeric"), "1")

---------------------------------------------------------------------------
-- 1b. ThreatDisplay: Ziel-Abzeichen (Solo / Forever) & Namensplaketten
---------------------------------------------------------------------------
addon.Set("threatShowNumeric", true)
wow.state.inCombat = true
wow.state.units.target = {
  name = "Silithidsucher",
  hostile = true,
  combat = true,
  tanking = true,
  threatStatus = 3,
  threatPercent = 100,
  threatRawPercent = 255,
  threatValue = 1427,
}
wow.fire("PLAYER_TARGET_CHANGED")
expect("Ziel-Abzeichen sichtbar bei Solo-Aggro", ThreatDisplay.BadgeFrame():IsShown(), true)
expect("Ziel-Abzeichen zeigt 100%", ThreatDisplay.BadgeText(), "100%")
expect("Status 3: kein Oranger Leuchtrahmen", ThreatDisplay.IsGlowShown(), false)

-- Status 2 (kurz vor Aggro / Verlust): Orange + Glow
wow.state.units.target.threatStatus = 2
wow.state.units.target.threatPercent = 88
wow.fire("UNIT_THREAT_LIST_UPDATE", "target")
expect("Status 2 zeigt 88%", ThreatDisplay.BadgeText(), "88%")
expect("Status 2 zeigt Leuchtrahmen", ThreatDisplay.IsGlowShown(), true)

-- Namensplaketten-Färbung im Kampf
local plateBar = CreateFrame("StatusBar")
plateBar:SetStatusBarColor(0.8, 0.1, 0.1)
local plate = { UnitFrame = { healthBar = plateBar } }
local origNamePlate = C_NamePlate
C_NamePlate = { GetNamePlateForUnit = function(u) return u == "nameplate1" and plate or nil end }
wow.state.units.nameplate1 = {
  name = "Silithidsucher",
  hostile = true,
  combat = true,
  threatStatus = 1,
}
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
local pr, pg, pb = plateBar:GetStatusBarColor()
expect("Plakette Status 1 Gelb R", pr, 1.00)
expect("Plakette Status 1 Gelb G", pg, 1.00)
expect("Plakette Status 1 Gelb B", pb, 0.47)

-- Kampfende stellt Originalfarbe wieder her
wow.state.inCombat = false
wow.state.units.nameplate1.combat = false
wow.fire("PLAYER_REGEN_ENABLED")
local orR, orG, orB = plateBar:GetStatusBarColor()
expect("Plakette Original R wiederhergestellt", orR, 0.8)
expect("Plakette Original G wiederhergestellt", orG, 0.1)
expect("Plakette Original B wiederhergestellt", orB, 0.1)

C_NamePlate = origNamePlate
wow.state.units.target = nil
wow.state.units.nameplate1 = nil
addon.Set("threatShowNumeric", false)
expect("Abzeichen ausgeblendet wenn Option aus", ThreatDisplay.BadgeFrame():IsShown(), false)

---------------------------------------------------------------------------
-- 2. CooldownNumbers: CVar countdownForCooldowns
---------------------------------------------------------------------------
expect("cooldownNumbers default false", addon.Database.SettingDefault("cooldownNumbers"), false)
expect("cooldownNumbers db initial false", LevelTimerDB.cooldownNumbers, false)

SetCVar("countdownForCooldowns", "0")
addon.ApplySettings()
expect("aus: CVar unberuehrt", GetCVar("countdownForCooldowns"), "0")

addon.Set("cooldownNumbers", true)
expect("countdownForCooldowns CVar auf 1 gesetzt", GetCVar("countdownForCooldowns"), "1")
expect("Original gemerkt", LevelTimerDB.cvarOriginals.countdownForCooldowns, "0")

addon.Set("cooldownNumbers", false)
expect("countdownForCooldowns CVar restauriert", GetCVar("countdownForCooldowns"), "0")
expect("Original vergessen", LevelTimerDB.cvarOriginals, nil)

---------------------------------------------------------------------------
-- 3. CooldownNumbers.FormatRemaining: Format & Farben
---------------------------------------------------------------------------
-- Sub-3s: Rot (1, 0.2, 0.2), Nachkommastelle
local textSub, rSub, gSub, bSub, keySub = CooldownNumbers.FormatRemaining(0.5)
expect("sub-3s text 0.5", textSub, "0.5")
expect("sub-3s red r", rSub, 1)
expect("sub-3s red g", gSub, 0.2)
expect("sub-3s red b", bSub, 0.2)
expect("sub-3s key", keySub, "red")

local textSub2, rSub2, gSub2, bSub2 = CooldownNumbers.FormatRemaining(2.9)
expect("sub-3s text 2.9", textSub2, "2.9")
expect("sub-3s 2.9 red r", rSub2, 1)

-- Sekunden (< 60s): Gelb (1, 0.85, 0.2), aufgerundet
local textSec1, rSec1, gSec1, bSec1, keySec1 = CooldownNumbers.FormatRemaining(3.0)
expect("seconds text 3", textSec1, "3")
expect("seconds yellow r", rSec1, 1)
expect("seconds yellow g", gSec1, 0.85)
expect("seconds yellow b", bSec1, 0.2)
expect("seconds key", keySec1, "yellow")

local textSec2 = CooldownNumbers.FormatRemaining(15.2)
expect("seconds text 16", textSec2, "16")

local textSec3 = CooldownNumbers.FormatRemaining(59.0)
expect("seconds text 59", textSec3, "59")

-- Minuten (< 3600s): Weiss (1, 1, 1), mit m
local textMin1, rMin1, gMin1, bMin1, keyMin1 = CooldownNumbers.FormatRemaining(60.0)
expect("minutes text 1m", textMin1, "1m")
expect("minutes white r", rMin1, 1)
expect("minutes white g", gMin1, 1)
expect("minutes white b", bMin1, 1)
expect("minutes key", keyMin1, "white")

local textMin2 = CooldownNumbers.FormatRemaining(125)
expect("minutes text 3m", textMin2, "3m")

local textMin3 = CooldownNumbers.FormatRemaining(3599)
expect("minutes text 60m", textMin3, "60m")

-- Stunden (>= 3600s): Gedimmtes Grau (0.7, 0.7, 0.7), mit h
local textHr1, rHr1, gHr1, bHr1, keyHr1 = CooldownNumbers.FormatRemaining(3600)
expect("hours text 1h", textHr1, "1h")
expect("hours grey r", rHr1, 0.7)
expect("hours grey g", gHr1, 0.7)
expect("hours grey b", bHr1, 0.7)
expect("hours key", keyHr1, "grey")

local textHr2 = CooldownNumbers.FormatRemaining(7200)
expect("hours text 2h", textHr2, "2h")

---------------------------------------------------------------------------
-- 4. CooldownFrame_Set Hook Behavior & Overlay
---------------------------------------------------------------------------
-- Ausgeschaltet: Hook tut nichts
local inactiveCd = CreateFrame("Frame")
CooldownFrame_Set(inactiveCd, GetTime(), 20, 1)
expect("ausgeschaltet: kein Text-Overlay", rawget(inactiveCd, "_ltText"), nil)

-- Einschalten
addon.Set("cooldownNumbers", true)

-- GCD (<= 1.5s) wird ignoriert
local gcdCd = CreateFrame("Frame")
CooldownFrame_Set(gcdCd, GetTime(), 1.5, 1)
expect("GCD 1.5s: ignoriert", rawget(gcdCd, "_ltText"), nil)
CooldownFrame_Set(gcdCd, GetTime(), 1.0, 1)
expect("GCD 1.0s: ignoriert", rawget(gcdCd, "_ltText"), nil)

-- Geheime Werte werden ignoriert
local secretCd1 = CreateFrame("Frame")
CooldownFrame_Set(secretCd1, wow.SECRET, 10, 1)
expect("geheimer Start ignoriert", rawget(secretCd1, "_ltText"), nil)

local secretCd2 = CreateFrame("Frame")
CooldownFrame_Set(secretCd2, GetTime(), wow.SECRET, 1)
expect("geheime Dauer ignoriert", rawget(secretCd2, "_ltText"), nil)

-- Gueltiger Cooldown erzeugt Text-Overlay
local testCd = CreateFrame("Frame")
local now = GetTime()
CooldownFrame_Set(testCd, now, 10, 1)
expectTrue("gueltiger CD: Overlay erzeugt", testCd._ltText ~= nil)
expectTrue("Overlay sichtbar", testCd._ltText:IsShown())
expect("Overlay Text ist 10", testCd._ltText:GetText(), "10")
local col1R, col1G, col1B = unpack(testCd._ltText._textColor or {})
expect("Overlay Gelb r", col1R, 1)
expect("Overlay Gelb g", col1G, 0.85)
expect("Overlay Gelb b", col1B, 0.2)

-- Zeit vorstellen: nach 8 Sekunden sind noch 2.0s uebrig (< 3s -> Rot)
wow.advance(8)
wow.update(0.2)
expect("Overlay Text nach 8s", testCd._ltText:GetText(), "2.0")
local col2R, col2G, col2B = unpack(testCd._ltText._textColor or {})
expect("Overlay Rot r", col2R, 1)
expect("Overlay Rot g", col2G, 0.2)
expect("Overlay Rot b", col2B, 0.2)

-- Ablauf nach weiteren 3 Sekunden
wow.advance(3)
wow.update(0.2)
expect("Abgelaufen: Overlay ausgeblendet", testCd._ltText:IsShown(), false)

-- Ausschalten raeumt aktive Cooldowns ab
local activeCd = CreateFrame("Frame")
CooldownFrame_Set(activeCd, GetTime(), 30, 1)
expectTrue("aktiver CD gezeigt", activeCd._ltText:IsShown())
addon.Set("cooldownNumbers", false)
expect("ausgeschaltet: aktives Overlay ausgeblendet", activeCd._ltText:IsShown(), false)

expect("keine Fehler", #wow.errors, 0)
