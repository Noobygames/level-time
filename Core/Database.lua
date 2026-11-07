-- Gespeicherte Daten:
--   LevelTimerDB       Account: Einstellungen
--   LevelTimerStatsDB  Account: Statistiken, je Charakter ("Name-Realm") getrennt
--   LevelTimerCharDB   veraltet (pro Charakter); wird beim Login in LevelTimerStatsDB übernommen
local _, ns = ...

local Database = {}
ns.Database = Database

local SETTINGS_DEFAULTS = {
  language = ns.DefaultLanguage(),
  bgAlpha = 0.8,
  windowBackground = "default",  -- "default", "green" oder "magenta" (Chroma-Key, siehe TimerWindow.lua)
  locked = false,  -- Anzeigen nur im Edit-Modus verschieben und skalieren (Lib/Frames.lua)
  editGrid = true,  -- Raster im Edit-Modus (UI/EditMode.lua), daran rastet das Ziehen ein
  editModeWithBlizzard = true,  -- Edit-Modus zusammen mit Blizzards Bearbeitungsmodus (Retail, WoW Forever)
  -- Aussehen aller Anzeigen (siehe Theme.lua)
  theme = "classic",     -- "classic", "flat", "minimal" oder "colorblind"
  themeAccent = "",      -- "" = Akzent des Presets, sonst Theme.ACCENTS oder "class"
  themeFont = "",        -- "" = Schrift des Clients, sonst Name aus Theme.FontChoices
  themeFontSize = 0,     -- Versatz in Punkten auf alle Schriften der Anzeigen
  themeOutline = "none", -- "none", "outline" oder "thick"
  showTimer = true,
  showXpBar = true,
  compactMode = false,  -- nur Zeit, XP-Balken und XP/h (siehe TimerWindow.lua)
  horizontalLayout = false,  -- Fenster als Info-Leiste: alles in einer Zeile (siehe TimerWindow.lua)
  autoInstanceTab = false,  -- beim Betreten einer Instanz zum Reiter Instanz wechseln, beim Verlassen zurück
  historyTab = "",  -- zuletzt gewählter Reiter der Historie (siehe HistoryWindow.lua)
  windowScope = "level",  -- "level", "session" oder "instance" (siehe Stats.lua)
  -- Stat-Zeilen im Fenster (siehe StatLines.lua)
  showXpRate = true,
  showRecentXpRate = false,  -- XP/h der letzten 15 min (siehe RecentXpRate.lua)
  showXpGained = true,  -- gewonnene XP im Bereich
  showLevelEta = true,
  showKillsToLevel = false,   -- Kills bis zum Level-Up
  showQuestsToLevel = false,  -- Quests bis zum Level-Up
  toLevelSamples = 20,  -- Kills/Quests bis Level-Up: Schnitt der letzten N (0 = ganzes Level, Experience.CountToLevel)
  showQuestLogXp = false,  -- XP der Quests im Questlog, fertig und offen (siehe QuestLogXp.lua)
  questXpOnBar = false,    -- XP der fertigen Quests als eigenes Stück auf dem XP-Balken
  showMaxLevelEta = false,
  showSplits = false,  -- Splits gegen einen Vergleich (siehe Splits.lua)
  splitComparison = "best",  -- "best", "pb" oder "run" (db.splitReference, siehe Splits.lua)
  showSplitList = false,  -- eigene Anzeige mit den letzten Leveln (siehe SplitList.lua)
  splitListRows = 5,
  splitListShowTotal = true,   -- Zeile "Gesamt" in der Split-Liste
  splitListShowPlayed = true,  -- Zeile "/played" in der Split-Liste
  questSplitNotice = false,
  friendRace = false,
  milestoneScreenshots = false,    -- Screenshot alle 5 Level und beim Max-Level (MilestoneScreenshots.lua)
  screenshotFirstDungeon = false,  -- Screenshot beim ersten Dungeon des Charakters
  screenshotEpicLoot = false,      -- Screenshot bei epischer Beute  -- Level-Zeiten per Addon-Nachricht mit anderen Level-Time-Nutzern tauschen (FriendRace.lua)  -- Chatzeile mit Dauer und Abweichung bei jeder Quest-Abgabe (QuestSplits.lua)
  splitListShowCustom = true,  -- die letzten eigenen Splits (/lt split) in der Split-Liste
  splitListShowForecast = false,  -- Prognose des nächsten Abschnitts gegen PB, Bestzeiten und Rekord (BracketForecast.lua)
  showWorldRecords = true,  -- Speedrun-Rekorde in der Split-Liste (siehe WorldRecords.lua)
  showRecordsAge = true,    -- Stand der Rekord-Daten in der Split-Liste
  recordBrackets = {},      -- [Abschnitt] = false blendet ihn in der Split-Liste aus
  worldRecordScope = "class",  -- "overall" oder "class"
  goldSplitNotice = false,
  ssfCategory = "off",  -- SSF-Regelhelfer: "off", "1-20" oder "1-60" (SsfRules.lua), nur Anzeige
  splitTolerancePercent = 0,  -- Toleranzband der Splits in Prozent der Vergleichszeit, 0 = aus (Splits.lua)
  pbSameClass = false,  -- Vergleich "pb" nur gegen eigene Charaktere derselben Klasse  -- Gold-Split (neue Bestzeit je Level) beim Level-Up mit Chatzeile und Ton melden
  showGoal = false,  -- Session-Ziel (siehe Goal.lua); /lt goal schaltet die Zeile ein
  streamerPrivacy = false,  -- Realm und andere Charaktere in der Historie verbergen (siehe History.DisplayName)
  -- Große Einblendungen (siehe Alerts.lua), für Streams gedacht und daher aus
  alertLevelUp = false,
  alertRareKill = false,
  alertEliteKill = false,
  alertEpicLoot = false,
  alertNearDeath = false,
  alertRareSpotted = false,     -- seltener Gegner gesichtet (RareAlert.lua)
  alertRareFlash = false,       -- dabei das WoW-Symbol blinken lassen
  alertQuestComplete = false,   -- Quest abgabebereit (QuestCompleteAlert.lua)
  alertQuestObjective = false,  -- einzelnes Questziel erfüllt
  alertStyle = "banner",  -- "text" oder "banner" (siehe Alerts.lua)
  alertDuration = 3,      -- Sekunden voll sichtbar
  alertSound = false,
  -- Lagerfeuer in WoW Forever (siehe CampFire.lua, CampDisplay.lua)
  campCountdown = true,  -- Countdown beim einladenden Lagerfeuer
  campHint = true,       -- Hinweis, wenn ein Feuer in der Nähe ist und die Lagervorteile fehlen
  campHintPause = 5,     -- Minuten, bevor der Lagerfeuer-Hinweis wieder erscheinen darf
  campSound = false,     -- Ton, wenn die Lagervorteile da sind
  foodTimer = true,      -- Essen-Timer (FoodTimer.lua): Restzeit beim Essen, danach "Satt aktiv"
  foodSound = false,     -- Ton, wenn "Satt" da ist
  flightTimer = false,   -- Flugzeiten (FlightTimer.lua): eigene Messung, Restzeit im Flug
  flightSound = false,   -- Ton bei der Landung
  remindFood = false,  -- Hinweis, wenn beim Leveln "Satt" fehlt (siehe BuffReminder.lua)
  remindCamp = false,  -- Hinweis, wenn beim Leveln der Camp-Buff fehlt (WoW Forever)
  remindCharged = false,  -- Hinweis, wenn Himmelsgeborenen beim Leveln "Aufgeladen" fehlt (WoW Forever)
  -- Klassen-Hinweise (ClassBuffs.lua), je einer; nur für die eigene Klasse in den Einstellungen
  remindMageArmor = false, remindArcaneIntellect = false, remindFortitude = false, remindInnerFire = false,
  remindShadowform = false, remindDemonArmor = false, remindWarlockPet = false, remindMarkOfTheWild = false,
  remindThorns = false, remindOmenOfClarity = false, remindShamanShield = false, remindShamanWeapon = false,
  remindBlessing = false, remindPaladinAura = false, remindRighteousFury = false, remindAspect = false,
  remindHunterPet = false, remindPoisons = false, remindBattleShout = false, remindBronzeBlessing = false,
  remindBreak = false,  -- Pausen-Erinnerung nach breakMinutes Spielzeit ohne Pause (BreakReminder.lua)
  breakMinutes = 60,
  reminderInterval = 5,  -- Minuten zwischen zwei Hinweisen auf denselben fehlenden Buff
  warnBagsFull = false,  -- Hinweis bei fast vollen Taschen (siehe GearWarnings.lua)
  warnDurability = false,  -- Hinweis bei niedriger Haltbarkeit
  remindTrainer = false,   -- Hinweis auf neue Zauber beim Lehrer (TrainerReminder.lua, nicht Retail)
  warnAmmo = false,        -- Jäger: Munition knapp (GearWarnings.lua, nicht Retail)
  ammoLow = 200,           -- Schuss, ab denen die Munitionswarnung kommt
  ammoCritical = 50,       -- Schuss, ab denen "fast leer" kommt (0 = aus)
  ammoRepeat = 5,          -- Minuten zwischen Wiederholungen der Munitionswarnung (0 = einmalig)
  announceControlLoss = false,  -- Heiler: Kontrollverlust an die Gruppe (ControlCallout.lua)
  announceControlOver = false,  -- Heiler: Entwarnung, wenn der Kontrollverlust vorbei ist
  announceQuestProgress = false,  -- Questfortschritt an die Gruppe (QuestProgress.lua)
  announceInstanceReport = false,  -- Bericht des Instanz-Laufs beim Verlassen an die Gruppe (InstanceReport.lua)
  announceHealerAggro = false,  -- Heiler: Aggro über 2 s an die Gruppe (AggroWarning.lua)
  announceLowMana = false,  -- Heiler: wenig Mana an die Gruppe (ManaCallout.lua)
  lowManaPercent = 25,      -- ab diesem Mana-Anteil (Prozent) wird angesagt
  warnAggro = false,  -- Hinweis bei Aggro in einer Gruppe (AggroWarning.lua)
  warnBreath = false,      -- Atem und Erschöpfung knapp (BreathWarning.lua)
  breathWarnSeconds = 15,  -- ab so vielen Sekunden Rest
  warnInstanceLimit = false,  -- Hinweis beim Betreten der vorletzten und letzten erlaubten Instanz (InstanceLimit.lua)
  -- Komfort beim Leveln (siehe Comfort.lua), alles aus
  -- Komfort wie Leatrix Plus (Roadmap 329): AutoAccept.lua, Looting.lua, ScreenText.lua, Camera.lua
  autoAcceptSummon = false, autoAcceptResurrect = false, autoReleasePvP = false,
  fasterLoot = false, skipLootConfirm = false, hideErrors = false, hideZoneText = false, maxCameraZoom = false,
  easyDelete = false, fasterMovieSkip = false,  -- SkipDialogs.lua
  trainAllButton = false,  -- TrainAll.lua
  -- System (Roadmap 329, Schritt 5): ScreenEffects.lua, CombatPlates.lua, Sounds.lua, RaidRestrictions.lua,
  -- AddonList.lua; CVars werden umkehrbar über CVars.lua gesetzt
  noDrunkenHaze = false, noScreenEffects = false, setWeatherDensity = false,
  weatherDensity = 3,  -- 0 (kein Wetter) bis 3, nur mit setWeatherDensity
  combatPlates = false, silenceRestedEmotes = false, muteFizzle = false, muteBells = false, muteMechastrider = false,
  noRaidRestrictions = false, sortAddonList = false,
  universalGroupColor = false,  -- Chat: Schlachtzug und Instanz in der Gruppenfarbe (ChatColors.lua)
  autoRepair = false,       -- beim Händler reparieren (Merchant.lua)
  autoRepairGuild = false,  -- zuerst aus der Gildenbank
  autoSellJunk = false,     -- graue Gegenstände verkaufen
  autoAcceptQuests = false, -- Quests annehmen (QuestAutomation.lua)
  autoAcceptShared = false, -- geteilte Quests und Eskorten bestätigen
  autoTurnIn = false,       -- fertige Quests abgeben
  autoChooseReward = false, -- bei mehreren Belohnungen die mit dem höchsten Verkaufswert
  skipGossip = false,       -- Gespräche mit nur einer Option überspringen
  questExclude = "",        -- eigene Sperrliste der Quest-Automatik: IDs und Namen (QuestBlocklist.lua)
  declineTrades = false,    -- Handel ablehnen (Declines.lua)
  declineGroupInvites = false,
  declineGuildInvites = false,
  declineDuels = false,
  -- Sozial (Social.lua): geteilte Quests ablehnen, Freundschaftsanfragen blocken, Einladungen von Freunden/Gilde
  -- annehmen, per Flüster-Stichwort einladen
  declineSharedQuests = false, blockFriendRequests = false, acceptFriendInvites = false, inviteFromWhisper = false,
  inviteKeyword = "inv",
  inviteInfo = false,  -- Chatzeile mit Level, Rasse und Klasse bei Gruppeneinladungen (InviteInfo.lua)
  chatCopyButton = false,   -- Button zum Kopieren an jedem Chatfenster (ChatCopy.lua)
  -- Chatfenster (ChatWindows.lua), letzter Chat nach /reload (ChatHistory.lua), Spam-Filter (ChatFilter.lua)
  hideCombatLogTab = false, hideChatButtons = false, chatEditBoxTop = false, chatArrowKeys = false, noChatFade = false,
  restoreChat = false, filterDrunkSpam = false, filterSpellLinks = false,
  moveFrames = false,       -- Standardfenster des Spiels verschiebbar machen (MoveFrames.lua)
  questMarks = false,       -- Symbol über Gegnern und NPCs einer aktiven Quest (QuestMarks.lua)
  questMarkScale = 1,
  questCleanupButton = false, -- Knopf "Graue Quests" am Questlog (QuestCleanup.lua)
  warnQuestLogFull = false,   -- Hinweis bei fast vollem Questlog
  rewardHint = false,         -- Goldmünze und Itemlevel-Gewinn auf Questbelohnungen (RewardHint.lua)
  questEfficiencyTooltip = false, -- "Bisher: Ø Dauer, XP/min" an Quest-Links (QuestEfficiency.lua)
  questItemTooltip = false,   -- Item-Tooltip nennt die Quest des Gegenstands (QuestItemTooltip.lua)
  questMap = false,           -- gelernte Abgabe-NPCs und Zielorte auf der Weltkarte (QuestMap.lua)
  corpseArrow = false,        -- als Geist Pfeil und Entfernung zur Leiche (CorpseArrow.lua)
  questLeftovers = false,     -- Gegenstände erledigter Quests als Verkaufsvorschlag (QuestLeftovers.lua)
  questLearning = false,    -- Questgegner und Quest-Gegenstände lernen, accountweit (QuestMobs.lua)
  questMarkProgress = false, -- Zielstand ("3/8") neben dem Quest-Symbol (QuestMarks.lua, Lib/QuestTooltip.lua)
  -- Beute-Glitzer (LootSparkles.lua): Quest-Gegenstände (CVar, nur Forever), beim Annähern Erz, Kräuter,
  -- Quest-Objekte und Leichen mit Beute (Soft-Targeting), Größe der Funken
  lootSparkleQuestItems = false, lootSparkleOre = false, lootSparkleHerbs = false, lootSparkleQuestObjects = false,
  lootSparkleCorpses = false, lootSparkleScale = 1,
  -- Beute-Würfe (LootRolls.lua, LootRollDisplay.lua, LootRollReport.lua): Zähler am Würfelfenster, Namen im Tooltip,
  -- Chatzeile mit Ergebnis, Ergebnis im Beute-Journal
  lootRollCounts = false, lootRollNames = false, lootRollSummary = false, lootRollJournal = false,
  questLevels = false,      -- "[12]" vor Questnamen in Log, Gesprächen und Tracker (QuestLevels.lua)
  questItemButton = false,   -- sicherer Knopf für das Quest-Item der nächsten Quest (QuestItemButton.lua)
  questTargetButton = false, -- Knopf "/targetexact" für Questgegner (Namensplaketten und gelernte Namen)
  questTargetMarker = false, -- derselbe Knopf setzt den Totenkopf auf das Ziel ("/tm !8")
  questButtonsZoneOnly = true, -- beide Knöpfe nur für Quests der aktuellen Zone (QuestLog.ZoneStatus)
  mapCoordinates = false,    -- Koordinaten von Spieler und Mauszeiger auf der Weltkarte (MapCoordinates.lua)
  emergencyHighlight = false,  -- wenig Leben: Notfall-Knöpfe markieren, Bildschirmrand rot (Emergency.lua)
  -- Oberfläche (Roadmap 329, Schritt 4): Aktionsleisten (ActionBars.lua), Blizzard-Einblendungen (HideFrames.lua)
  hideKeybindText = false, hideMacroText = false, rangeColor = false,
  hideBossBanner = false, hideEventToasts = false, hideAlerts = false, hideStanceBar = false,
  hideRestAnimation = false, hidePortraitNumbers = false,
  hideBlizzardXpBar = false, hideBlizzardRepBar = false,  -- Blizzards Erfahrungs- und Rufleiste (HideFrames.lua)
  characterDurability = false, characterVolume = false,  -- Charakterfenster (CharacterFrame.lua)
  classColorFrames = false,  -- Klassenfarbe im Namenshintergrund von Ziel und Fokus (ClassColors.lua)
  tooltipClassColors = false, tooltipTarget = false, tooltipHideInCombat = false, tooltipKillsToLevel = false,  -- Tooltip.lua
  deathMap = false,  -- Todespunkte auf der Weltkarte (DeathMap.lua)
  minimapWheelZoom = false, minimapHideZoomButtons = false, minimapHideCalendar = false,  -- MinimapTweaks.lua
  levelUpSummary = true,
  levelUpWindow = true,  -- eigenes Level-Up-Fenster statt Blizzards Banner (siehe LevelUpWindow.lua)
  levelUpHideBlizzard = true,
  levelUpTheme = "modern",  -- "modern", "alliance" oder "horde"
  levelUpCompact = false,
  levelUpSound = true,
  levelUpDuration = 8,
  announceRecords = false,  -- Einblendung und Chatzeile bei einem neuen persönlichen Rekord (PersonalRecords.lua)
  sessionCompareLogin = true,  -- Chatzeile zur letzten Session beim Login (siehe SessionCompare.lua)
  restedAltNotice = true,  -- Chatzeile beim Login, wenn ein Twink voll ausgeruht ist (siehe RestedEstimate.lua)
  levelUpGains = true,  -- Zuwachs (Leben, Mana, Werte) in Chat und Level-Up-Karte (siehe LevelGains.lua)
  levelUpAnnounce = "off",  -- Level-Up-Zusammenfassung an "party" oder "guild" (siehe LevelUpSummary.lua)
  showPveKills = true,
  showPvpKills = false,
  showSpecialKills = false,
  showDeaths = true,
  showKillsPerDeath = false,
  showNearDeaths = false,
  showDeathless = false,
  highlightDeaths = true,  -- Tode im Fenster rot (siehe StatLines.lua)  -- Hardcore: Zeit seit dem letzten Tod
  showXpSources = false,
  showXpContext = false,  -- XP nach Ort: Welt, Dungeon, Schlachtzug, Schlachtfeld (XpSources.lua)
  showRested = false,
  showRestedLeft = false,  -- verbleibende Erholt-XP (GetXPExhaustion)
  showTimeBreakdown = false,  -- Zeit in Kampf, Flug, AFK und Rest (siehe TimeBreakdown.lua)
  xpRateWithoutAfk = false,   -- XP/h und Prognosen ohne AFK-Zeit (siehe Experience.RateSeconds)
  idleMinutes = 0,  -- so lange ohne XP-Gewinn und Kampf, danach zählt Leerlauf (0 = aus, TimeBreakdown.lua)
  showInstanceRun = false,  -- laufender Dungeon-/Raid-Lauf (siehe Instances.lua)
  showInstanceLimit = false,   -- neue Instanzen in der letzten Stunde (siehe InstanceLimit.lua)
  showInstancesToday = false,  -- neue Instanzen seit Mitternacht
  showQuests = false,
  showMoney = false,
  showSpending = false,  -- Ausgaben nach Art und Schrott-Erlös (siehe MoneyCounter.lua)
  showIncome = false,    -- Einnahmen nach Art und Gold/h (siehe MoneyCounter.lua)
  showReputation = false,  -- Rufgewinn und Ruf/h (siehe Reputation.lua)
  minimap = { hide = false, angle = 225 },
}

-- Zähler für Level und Session gleichermaßen. Schlüssel siehe Stats.lua.
local COUNTER_DEFAULTS = {
  pveKills = 0,
  pvpKills = 0,
  deaths = 0,
  deadSeconds = 0,
  quests = 0,
  xpGained = 0,
  xpKills = 0,
  xpQuests = 0,
  xpRested = 0,
  xpExplore = 0,
  xpGather = 0,
  xpWorld = 0,
  xpDungeon = 0,
  xpRaid = 0,
  xpBattleground = 0,
  moneyEarned = 0,
  eliteKills = 0,
  rareKills = 0,
  nearDeaths = 0,
  combatSeconds = 0,
  taxiSeconds = 0,
  afkSeconds = 0,
  idleSeconds = 0,
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
  reputation = 0,
}

local CHARACTER_DEFAULTS = {
  currentLevel = {
    level = 0,    -- Level, auf das sich die Zähler beziehen
    seconds = 0,  -- letzte bekannte Spielzeit auf dem Level (für die Anzeige anderer Charaktere)
    xp = 0,       -- letzte bekannte XP auf dem Level
    counters = COUNTER_DEFAULTS,
  },
  currentSession = {
    seconds = 0,  -- gespielte Zeit bis zum letzten Logout; startedAt fehlt, solange keine Session lief
    counters = COUNTER_DEFAULTS,
  },
  levelHistory = {},    -- abgeschlossene Level, Schlüssel = Level
  sessionHistory = {},  -- beendete Sessions, älteste zuerst
  killLog = {},         -- getötete Kreaturen und Spieler, älteste zuerst (siehe Journal.lua)
  deathLog = {},        -- eigene Tode mit Ursache, älteste zuerst (siehe Journal.lua)
  questLog = {},        -- abgegebene Quests, älteste zuerst (siehe Journal.lua)
  instanceLog = {},     -- beendete Instanz-Läufe, älteste zuerst (siehe Instances.lua)
  instanceVisits = {},  -- zuletzt betretene Instanz-Kopie je Name: { zoneUID, leftAt } (siehe InstanceCopy.lua)
  lootLog = {},         -- seltene und bessere Beute, älteste zuerst (siehe Loot.lua)
  nearDeathLog = {},    -- Beinahe-Tode, älteste zuerst (siehe NearDeath.lua)
  zoneStats = {},       -- Spielzeit, XP, Kills und Tode je Zone (siehe Zones.lua)
  questStarts = {},     -- /played bei Annahme je Quest-ID, bis zur Abgabe (QuestSplits.lua)
  customSplits = {},    -- eigene Splits { name, played, time, level }, älteste zuerst (CustomSplits.lua)
  ssfLogouts = 0,       -- echte Logouts seit Beginn der Aufzeichnung (SSF-Regelhelfer, SsfRules.lua)
  dailyStats = {},      -- Tageswerte, Schlüssel "JJJJ-MM-TT" (siehe Daily.lua)
}

-- Migrationen für die Daten eines Charakters, Schlüssel = Zielversion.
-- Laufen auch für frische (leere) Daten und müssen daher fehlende Felder vertragen.
Database.CHARACTER_SCHEMA_VERSION = 5
local characterMigrations = {
  [2] = function(data)  -- kills (nur PvE) -> counters.pveKills
    data.counters = data.counters or {}
    data.counters.pveKills = data.kills
    data.kills = nil
  end,
  [3] = function(data)  -- flache Level-Daten -> currentLevel + levelHistory (Sessions sind neu)
    data.currentLevel = { level = data.level, counters = data.counters }
    data.levelHistory = data.history
    data.level, data.counters, data.history = nil, nil, nil
  end,
  [4] = function(data)  -- Tageswerte neu: Spielzeit bisheriger Sessions ihrem Starttag zuordnen
    data.dailyStats = data.dailyStats or {}
    for _, session in ipairs(data.sessionHistory or {}) do
      if session.startedAt and session.seconds then
        local entry = ns.Daily.Entry(data.dailyStats, session.startedAt)
        entry.seconds = entry.seconds + session.seconds
      end
    end
  end,
  [5] = function(data)  -- Tageswerte zählen Kills und Tode: aus dem vorhandenen Journal übernehmen
    data.dailyStats = data.dailyStats or {}
    for _, kill in ipairs(data.killLog or {}) do
      local entry = ns.Daily.Entry(data.dailyStats, kill.time)
      entry.kills = entry.kills + 1
    end
    for _, death in ipairs(data.deathLog or {}) do
      local entry = ns.Daily.Entry(data.dailyStats, death.time)
      entry.deaths = entry.deaths + 1
    end
  end,
}

-- Migrationen für die Einstellungen, Schlüssel = Zielversion
local SETTINGS_SCHEMA_VERSION = 6
local OLD_DEFAULT_FONT_SIZE = 16

-- Wendet fn auf die Einstellungen und alle darin gespeicherten Kopien an (Profile, Stream-Sicherung)
local function forEachSettingsCopy(settings, fn)
  fn(settings)
  for _, profile in pairs(settings.profiles or {}) do
    if type(profile) == "table" then fn(profile) end
  end
  if type(settings.streamBackup) == "table" then fn(settings.streamBackup) end
end

local settingsMigrations = {
  [2] = function(settings)  -- feste Schriftgröße der Zeitanzeige -> Skalierung des ganzen Fensters
    forEachSettingsCopy(settings, function(values)
      if values.fontSize then
        values.scale = values.fontSize / OLD_DEFAULT_FONT_SIZE
      end
      values.fontSize = nil
    end)
  end,
  -- Zeilen mit mehreren Werten wurden aufgeteilt; neue Schalter übernehmen den alten Zustand:
  -- Kills -> PvE + PvP, XP/h -> + Zeit bis Level-Up, Tode -> + Kills pro Tod
  [3] = function(settings)
    forEachSettingsCopy(settings, function(values)
      if values.showKills ~= nil then
        values.showPveKills = values.showKills
        values.showPvpKills = values.showKills
      end
      if values.showXpRate ~= nil then
        values.showLevelEta = values.showXpRate
      end
      if values.showDeaths ~= nil then
        values.showKillsPerDeath = values.showDeaths
      end
      values.showKills = nil
    end)
  end,
  -- Level-Up-Ansage in /sagen entfernt (kam außerhalb von Instanzen nicht an): aus, auch in Profilen
  [4] = function(settings)
    forEachSettingsCopy(settings, function(values)
      if values.levelUpAnnounce == "say" then values.levelUpAnnounce = "off" end
    end)
  end,
  -- "Kills/Quests bis Level-Up" aufgeteilt (wer keine Quests macht, will die Zeile nicht sehen): beide übernehmen den alten Zustand
  [5] = function(settings)
    forEachSettingsCopy(settings, function(values)
      if values.showCountToLevel ~= nil then
        values.showKillsToLevel = values.showCountToLevel
        values.showQuestsToLevel = values.showCountToLevel
      end
      values.showCountToLevel = nil
    end)
  end,
  -- Ein Positionssystem (Lib/Frames.lua): xxxPos/xxxScale je Anzeige -> frames[id]. Die Stream-Sicherung verliert
  -- sie nur (ältere Versionen sicherten dort die Größe; zurückgespielt würde frames sonst alle Positionen ersetzen)
  [6] = function(settings)
    forEachSettingsCopy(settings, function(values)
      Database.MoveLegacyFrameKeys(values)
      if values == settings.streamBackup then values.frames = nil end
    end)
  end,
}

-- Die Version wird nie gesenkt: nach einem Downgrade (ältere Addon-Version) liefen nicht wiederholbare
-- Migrationen beim nächsten Upgrade sonst ein zweites Mal
local function migrate(data, migrations, targetVersion)
  local version = data.schemaVersion or 1
  if version >= targetVersion then return end
  for nextVersion = version + 1, targetVersion do
    if migrations[nextVersion] then
      migrations[nextVersion](data)
    end
  end
  data.schemaVersion = targetVersion
end

-- Fehlende Werte aus den Defaults ergänzen (auch verschachtelt)
local function applyDefaults(data, defaults)
  for key, value in pairs(defaults) do
    if type(value) == "table" then
      if type(data[key]) ~= "table" then data[key] = {} end
      applyDefaults(data[key], value)
    elseif data[key] == nil then
      data[key] = value
    end
  end
  return data
end

local function isFiniteNumber(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Gültige Ankerpunkte (FramePoint): SetPoint mit etwas anderem wirft bei jedem Anwenden einen Fehler
local FRAME_POINTS = {
  TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
  BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

-- Einstellungen ohne Default, mit Prüfung ihrer Form
local function isPosition(value)
  return type(value) == "table" and FRAME_POINTS[value[1]] == true and FRAME_POINTS[value[2]] == true
    and isFiniteNumber(value[3]) and isFiniteNumber(value[4])
end

local function isLevelTimes(value)
  if type(value) ~= "table" then return false end
  for level, seconds in pairs(value) do
    if type(level) ~= "number" or not isFiniteNumber(seconds) or seconds <= 0 then return false end
  end
  return true
end

-- Erlaubte Bereiche von Zahlen-Einstellungen (wie die Regler und Fenster sie vorgeben); Importe werden begrenzt
local SETTING_RANGES = {
  bgAlpha = { 0, 1 },
  themeFontSize = { -4, 8 },
  splitListRows = { 3, 15 },
  splitTolerancePercent = { 0, 10 },
  reminderInterval = { 1, 30 },
  ammoLow = { 20, 1000 },
  lowManaPercent = { 5, 60 },
  breakMinutes = { 15, 240 },
  toLevelSamples = { 0, 50 },
  idleMinutes = { 0, 30 },
  breathWarnSeconds = { 5, 30 },
  ammoCritical = { 0, 500 },
  ammoRepeat = { 0, 30 },
  alertDuration = { 1, 10 },
  levelUpDuration = { 3, 20 },
  campHintPause = { 1, 30 },
  questMarkScale = { 0.5, 2 },
  lootSparkleScale = { 0.5, 2 },
  weatherDensity = { 0, 3 },
}

local OPTIONAL_SETTINGS = {
  frames = function(value)  -- Position und Größe je Anzeige (Lib/Frames.lua), Id -> Eintrag
    if type(value) ~= "table" then return false end
    for id, entry in pairs(value) do  -- ungültige Einträge einzeln entfernen, gültige behalten
      value[id] = type(id) == "string" and Database.SanitizeFrameEntry(entry) or nil
    end
    return true
  end,
  movedFrames = function(value)  -- gemerkte Fensterpositionen (MoveFrames.lua), Name -> Position
    if type(value) ~= "table" then return false end
    for name, pos in pairs(value) do  -- ungültige Einträge einzeln entfernen, gültige behalten
      if type(name) ~= "string" or not isPosition(pos) then value[name] = nil end
    end
    return true
  end,
  movedFrameScales = function(value)  -- gemerkte Fenstergrößen (MoveFrames.lua), Name -> Faktor
    if type(value) ~= "table" then return false end
    for name, scale in pairs(value) do
      if type(name) ~= "string" or not isFiniteNumber(scale) or scale <= 0 then value[name] = nil end
    end
    return true
  end,
  presetBackup = function(value)  -- Zeilen vor der letzten Voreinstellung (StatLines.lua), Einstellung -> an/aus
    if type(value) ~= "table" then return false end
    for key, on in pairs(value) do
      if type(key) ~= "string" or type(on) ~= "boolean" then value[key] = nil end
    end
    return true
  end,
  splitReference = function(value)  -- fester Vergleichslauf (Splits.lua)
    return type(value) == "table" and type(value.name) == "string" and isLevelTimes(value.times)
  end,
}

local sanitizeSettings

-- Ein Eintrag von db.frames: { point, relPoint, x, y, scale }; Position nur vollständig und gültig, Größe begrenzt.
-- nil, wenn nichts Gültiges bleibt
local FRAME_SCALE_RANGE = { 0.5, 2 }  -- wie Frames.MIN_SCALE/MAX_SCALE (Lib/Frames.lua lädt später)

function Database.SanitizeFrameEntry(entry)
  if type(entry) ~= "table" then return nil end
  local clean = {}
  if FRAME_POINTS[entry.point] and FRAME_POINTS[entry.relPoint] and isFiniteNumber(entry.x) and isFiniteNumber(entry.y) then
    clean.point, clean.relPoint, clean.x, clean.y = entry.point, entry.relPoint, entry.x, entry.y
  end
  if isFiniteNumber(entry.scale) then
    clean.scale = math.max(FRAME_SCALE_RANGE[1], math.min(FRAME_SCALE_RANGE[2], entry.scale))
  end
  return next(clean) and clean or nil
end

-- Frühere Schlüssel je Anzeige (Position als { Punkt, Bezugspunkt, x, y } und eigene Größe) -> frames[id]
local LEGACY_FRAME_KEYS = {
  { id = "main", pos = "pos", scale = "scale" },
  { id = "splitList", pos = "splitListPos", scale = "splitListScale" },
  { id = "alert", pos = "alertPos", scale = "alertScale" },
  { id = "levelUp", pos = "levelUpPos", scale = "levelUpScale" },
  { id = "camp", pos = "campPos", scale = "campScale" },
  { id = "food", pos = "foodPos", scale = "foodScale" },
  { id = "flight", pos = "flightPos", scale = "flightScale" },
  { id = "questItem", pos = "questItemPos" },
}

-- Alte Schlüssel einmal lesen und löschen; ein schon vorhandener Eintrag in frames gewinnt. Läuft in der Migration
-- (auch für Profile und die Stream-Sicherung), beim Import und beim Laden eines Profils.
function Database.MoveLegacyFrameKeys(values)
  for _, legacy in ipairs(LEGACY_FRAME_KEYS) do
    local pos, scale = values[legacy.pos], legacy.scale and values[legacy.scale]
    if pos ~= nil or scale ~= nil then
      local frames = type(values.frames) == "table" and values.frames or {}
      local existing = frames[legacy.id]
      local entry = type(existing) == "table" and existing or {}
      if isPosition(pos) and entry.point == nil then
        entry.point, entry.relPoint, entry.x, entry.y = pos[1], pos[2], pos[3], pos[4]
      end
      if entry.scale == nil then entry.scale = scale end
      frames[legacy.id] = Database.SanitizeFrameEntry(entry)
      if next(frames) then values.frames = frames end
    end
    values[legacy.pos] = nil
    if legacy.scale then values[legacy.scale] = nil end
  end
end

-- Ein Wert passt, wenn er den Typ des Defaults hat (verschachtelt geprüft) bzw. die Form einer
-- optionalen Einstellung
local function sanitizeValue(key, value)
  local default = SETTINGS_DEFAULTS[key]
  if default == nil then
    if key == "streamBackup" then  -- frühere Werte der Stream-Einstellungen (StreamMode.lua), nie Positionen
      if type(value) ~= "table" then return nil end
      local backup = sanitizeSettings(value)
      backup.frames = nil
      return backup
    end
    local check = OPTIONAL_SETTINGS[key]
    if not (check and check(value)) then return nil end
    local range = SETTING_RANGES[key]
    if range and type(value) == "number" then return math.max(range[1], math.min(range[2], value)) end
    return value
  end
  if type(value) ~= type(default) then return nil end
  if type(value) == "number" then
    if not isFiniteNumber(value) then return nil end
    local range = SETTING_RANGES[key]
    if range then return math.max(range[1], math.min(range[2], value)) end
  end
  if type(default) == "table" and next(default) ~= nil then
    local copy = {}
    for innerKey, innerDefault in pairs(default) do
      local inner = value[innerKey]
      if type(inner) == type(innerDefault) then copy[innerKey] = inner end
    end
    return copy
  end
  return value
end

-- Nur bekannte Einstellungen mit passendem Typ, z.B. aus einem importierten Profil
function sanitizeSettings(settings)
  local source = {}  -- Kopie: alte Positions-Schlüssel (Profile älterer Versionen) ziehen nach frames um
  for key, value in pairs(settings) do source[key] = value end
  Database.MoveLegacyFrameKeys(source)
  local clean = {}
  for key, value in pairs(source) do
    if type(key) == "string" then clean[key] = sanitizeValue(key, value) end
  end
  return clean
end
Database.SanitizeSettings = sanitizeSettings

-- Fehlende Einstellungen mit Defaults füllen (z.B. nach dem Laden eines Profils)
function Database.ApplySettingDefaults(settings)
  return applyDefaults(settings, SETTINGS_DEFAULTS)
end

function Database.NewCounters()
  return applyDefaults({}, COUNTER_DEFAULTS)
end

function Database.CharacterKey(name, realm)
  return name .. "-" .. realm
end

-- Neu erstellter Charakter mit dem Namen eines gelöschten: gespeichertes Level höher als das aktuelle
-- (Level sinken nie). Zuhörer (Runs.lua, JournalArchive.lua) bekommen Daten und Schlüssel: sichern den alten
-- Versuch bzw. löschen sein Archiv, dann beginnen die Daten neu.
local replacedListeners = {}

function Database.OnCharacterReplaced(listener)
  table.insert(replacedListeners, listener)
end

local function isReplacedCharacter(data)
  local savedLevel = data.currentLevel and data.currentLevel.level
  return savedLevel ~= nil and savedLevel > UnitLevel("player")
end

-- Daten des eingeloggten Charakters holen oder anlegen. Alte Daten aus
-- LevelTimerCharDB werden dabei einmalig übernommen und durchlaufen dieselben Migrationen.
local function loadCharacter(stats)
  local name, realm = UnitName("player"), GetRealmName()
  local key = Database.CharacterKey(name, realm)

  local data = stats.characters[key]
  if data and isReplacedCharacter(data) then
    for _, listener in ipairs(replacedListeners) do
      ns.SafeCall(listener, data, key)
    end
    data = nil
  end
  if not data then
    data = LevelTimerCharDB or {}
    stats.characters[key] = data
  end
  LevelTimerCharDB = nil

  migrate(data, characterMigrations, Database.CHARACTER_SCHEMA_VERSION)
  applyDefaults(data, CHARACTER_DEFAULTS)

  data.name, data.realm = name, realm
  data.class = select(2, UnitClass("player"))
  return key, data
end

-- Erst ab PLAYER_LOGIN aufrufen, vorher hat der Client die SavedVariables nicht geladen.
-- Rückgabe: Einstellungen, Schlüssel und Daten des eingeloggten Charakters.
function Database.Load()
  LevelTimerDB = LevelTimerDB or {}
  migrate(LevelTimerDB, settingsMigrations, SETTINGS_SCHEMA_VERSION)
  applyDefaults(LevelTimerDB, SETTINGS_DEFAULTS)
  LevelTimerStatsDB = applyDefaults(LevelTimerStatsDB or {}, { characters = {} })
  -- Auch andere Charaktere auf den aktuellen Stand bringen: die Historie zeigt sie, und Daten aus
  -- älteren Versionen haben sonst Lücken (z.B. fehlende Journale)
  -- Ein defekter Eintrag darf nicht alle Module lahmlegen: Fehler melden, Charakter überspringen
  for _, data in pairs(LevelTimerStatsDB.characters) do
    xpcall(function()
      migrate(data, characterMigrations, Database.CHARACTER_SCHEMA_VERSION)
      applyDefaults(data, CHARACTER_DEFAULTS)
    end, geterrorhandler())
  end
  local characterKey, character = loadCharacter(LevelTimerStatsDB)
  return LevelTimerDB, characterKey, character
end

function Database.GetCharacters()
  return LevelTimerStatsDB.characters
end

-- Entfernt alle Statistiken eines Charakters (Einstellungen bleiben unberührt)
-- Zuhörer (JournalArchive.lua) löschen, was sie zu dem Charakter außerhalb von LevelTimerStatsDB speichern
local deletedListeners = {}

function Database.OnCharacterDeleted(listener)
  table.insert(deletedListeners, listener)
end

function Database.DeleteCharacter(characterKey)
  LevelTimerStatsDB.characters[characterKey] = nil
  for _, listener in ipairs(deletedListeners) do
    ns.SafeCall(listener, characterKey)
  end
end
