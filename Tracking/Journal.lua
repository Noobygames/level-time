-- Journal: einzelne Kills, Tode, Quests, Beute, Instanz-Läufe und Beinahe-Tode des eingeloggten Charakters mit Zeitpunkt und Umständen.
--
-- Kill-Eintrag: { time, kind = "pve"|"pvp", name, classification, level, zone, xp, rested, mobLevel }
--   xp: XP des Kills samt Erholungsbonus, rested: Bonus darin (beide nil bei PvP und älteren Einträgen)
--   mobLevel: zuletzt gesehene Stufe des Gegners (Classification.lua), nil wenn unbekannt
-- Tod-Eintrag:  { time, level, zone, killer, spell, environment, mapID, x, y, lastWords }
--   killer/spell: Verursacher und Zauber des letzten Treffers, environment: Umgebungsschaden
--   (z.B. "FALLING"); alle drei nil, wenn die Ursache nicht bekannt ist.
--   mapID/x/y: Ort auf der Karte (nil in Instanzen), lastWords: letzte eigene Chatzeile (DeathPlace.lua)
-- Quest-Eintrag: { time, level, zone, questID, name, xp, money, duration, delta }
--   duration: /played-Sekunden von Annahme bis Abgabe, delta: Abweichung zur bisherigen Bestzeit (QuestSplits.lua)
-- Instanz-Lauf: { time, name, instanceType, seconds, level, xp, counters = { kills, deaths, reputation }, zoneUID }
-- Beute:        { time, level, zone, link, name, quality, quantity, source }
-- Beinahe-Tod:  { time, level, zone, lowestPercent, killer, spell, environment }
--
-- Speicher in zwei Teilen (Roadmap 252):
--   Eingang  ns.character[logName] in LevelTimerStatsDB: die neuesten Einträge als Tabellen; alle laufenden Module
--            (Beute-Quelle, Todesursache nachtragen, Lauf zusammenführen, Recap) arbeiten nur hier.
--   Archiv   ältere Einträge kompakt im Load-on-Demand-Addon LevelTimer_Archive (JournalArchive.lua), nur geladen,
--            wenn sie gebraucht werden. Journal.GetEntries liefert beides zusammen.
-- MAX_* begrenzt das Archiv, INBOX_LIMIT den Eingang, falls das Archiv nicht geladen werden kann (Addon fehlt/aus).
local _, ns = ...

local Journal = {}
ns.Journal = Journal

Journal.PVE = "pve"
Journal.PVP = "pvp"

Journal.MAX_KILLS = 250000
Journal.MAX_DEATHS = 50000
Journal.MAX_QUESTS = 50000
Journal.MAX_INSTANCE_RUNS = 20000
Journal.MAX_LOOT = 100000
Journal.MAX_NEAR_DEATHS = 50000
Journal.INBOX_LIMIT = 20000
Journal.INBOX_SLACK = 1000  -- so viele Einträge darf der Eingang über INBOX_LIMIT wachsen, dann wird in einem Zug gekürzt

-- Die Logs mit Archiv-Grenze und Feldern für die kompakte Form (RecordCodec; neue Felder nur hinten anhängen)
local VALUE = "value"
Journal.LOGS = {
  killLog = { max = Journal.MAX_KILLS, fields = {
    { path = "time" }, { path = "kind", kind = VALUE }, { path = "name", kind = VALUE },
    { path = "classification", kind = VALUE }, { path = "level" }, { path = "zone", kind = VALUE },
    { path = "xp" }, { path = "rested" }, { path = "mobLevel" } } },
  deathLog = { max = Journal.MAX_DEATHS, fields = {
    { path = "time" }, { path = "level" }, { path = "zone", kind = VALUE }, { path = "killer", kind = VALUE },
    { path = "spell", kind = VALUE }, { path = "environment", kind = VALUE }, { path = "mapID" }, { path = "x" },
    { path = "y" }, { path = "lastWords", kind = VALUE } } },
  questLog = { max = Journal.MAX_QUESTS, fields = {
    { path = "time" }, { path = "level" }, { path = "zone", kind = VALUE }, { path = "questID" },
    { path = "name", kind = VALUE }, { path = "xp" }, { path = "money" }, { path = "duration" }, { path = "delta" } } },
  instanceLog = { max = Journal.MAX_INSTANCE_RUNS, fields = {
    { path = "time" }, { path = "name", kind = VALUE }, { path = "instanceType", kind = VALUE }, { path = "seconds" },
    { path = "level" }, { path = "xp" }, { path = "counters.kills" }, { path = "counters.deaths" },
    { path = "zoneUID" }, { path = "counters.reputation" } } },
  lootLog = { max = Journal.MAX_LOOT, fields = {
    { path = "time" }, { path = "level" }, { path = "zone", kind = VALUE }, { path = "link", kind = VALUE },
    { path = "name", kind = VALUE }, { path = "quality" }, { path = "quantity" }, { path = "source", kind = VALUE } } },
  nearDeathLog = { max = Journal.MAX_NEAR_DEATHS, fields = {
    { path = "time" }, { path = "level" }, { path = "zone", kind = VALUE }, { path = "lowestPercent" },
    { path = "killer", kind = VALUE }, { path = "spell", kind = VALUE }, { path = "environment", kind = VALUE } } },
}

-- Module, die auf neue Einträge reagieren (z.B. Einblendungen): listener(logName, entry)
local addListeners = {}

function Journal.OnAdd(listener)
  ns.RememberSource(listener, "Journal.lua")
  table.insert(addListeners, listener)
end

-- Stand der Journale: steigt bei jeder Änderung (neuer Eintrag, nachgetragene Ursache, herausgenommener Lauf), einmal
-- gesamt und je Log, damit eine Tod-Ansicht nicht bei jedem Kill neu rechnet
local revision = 0
local logRevisions = {}   -- [logName] = Stand dieses Logs
local editRevisions = {}  -- [logName] = Zahl der Änderungen an schon vorhandenen Einträgen (nicht neue Einträge)

local function changed(logName)
  revision = revision + 1
  logRevisions[logName] = (logRevisions[logName] or 0) + 1
end

-- Ein vorhandener Eintrag wurde geändert (z.B. nachgetragene Todesursache): Ansichten, die Werte je Eintrag
-- zwischenspeichern (TableView appendOnly), rechnen dann neu
local function edited(logName)
  changed(logName)
  editRevisions[logName] = (editRevisions[logName] or 0) + 1
end

function Journal.EditRevision(logName)
  return editRevisions[logName] or 0
end

-- Stand eines Logs (logName) oder aller Logs (ohne Argument), jeweils mit dem Archiv-Stand
function Journal.Revision(logName)
  local own = revision
  if logName then own = logRevisions[logName] or 0 end
  return own .. ":" .. ns.JournalArchive.Version()
end

-- Funktion ohne Argument für TableView/Charts (revision = Journal.RevisionOf("killLog"))
function Journal.RevisionOf(logName)
  return function() return Journal.Revision(logName) end
end

-- list[1..count] verwerfen, der Rest rückt nach vorn: ein Durchlauf statt table.remove(list, 1) je Eintrag
function Journal.DropOldest(list, count)
  local size = #list
  for i = 1, size - count do list[i] = list[i + count] end
  for i = size, size - count + 1, -1 do list[i] = nil end
end

-- Neuen Eintrag an den Eingang character[logName] anhängen. Über INBOX_LIMIT + INBOX_SLACK (nur ohne Archiv) fallen
-- die ältesten bis auf INBOX_LIMIT weg: ein Kürzen je INBOX_SLACK Einträge statt ein Verschieben des ganzen Eingangs
-- bei jedem Kill
local function append(logName, entry)
  changed(logName)
  ns.Debug("journal", "%s: %s", logName, entry.name or entry.killer or entry.link or entry.environment or "-")
  local log = ns.character[logName]
  table.insert(log, entry)
  if #log > Journal.INBOX_LIMIT + Journal.INBOX_SLACK then
    Journal.DropOldest(log, #log - Journal.INBOX_LIMIT)
  end
  for _, listener in ipairs(addListeners) do
    ns.SafeCall(listener, logName, entry)
  end
end

local function baseEntry()
  return { time = time(), level = ns.level, zone = GetZoneText and GetZoneText() or nil }
end

-- name darf nil sein (z.B. wenn das Spiel den Namen verbirgt), classification, xp, rested und mobLevel ebenso
function Journal.AddKill(kind, name, classification, xp, rested, mobLevel)
  local entry = baseEntry()
  entry.kind = kind
  entry.name = name
  entry.classification = classification
  entry.xp = xp
  entry.rested = rested
  entry.mobLevel = mobLevel
  append("killLog", entry)
end

-- name darf nil sein, xp und money (Kupfer) ebenfalls
function Journal.AddQuest(questID, name, xp, money)
  local entry = baseEntry()
  entry.questID = questID
  entry.name = name
  entry.xp = xp
  entry.money = money
  append("questLog", entry)
end

-- lowestPercent = tiefster Lebensstand in Prozent, cause wie bei AddDeath
function Journal.AddNearDeath(lowestPercent, cause)
  local entry = baseEntry()
  entry.lowestPercent = lowestPercent
  entry.killer = cause.killer
  entry.spell = cause.spell
  entry.environment = cause.environment
  append("nearDeathLog", entry)
end

-- item = { link, name, quality, quantity, source }
function Journal.AddLoot(item)
  local entry = baseEntry()
  entry.link = item.link
  entry.name = item.name
  entry.quality = item.quality
  entry.quantity = item.quantity
  entry.source = item.source
  append("lootLog", entry)
end

-- Beendeter Instanz-Lauf (Form siehe Instances.lua); time = Betreten der Instanz
function Journal.AddInstanceRun(run)
  local record = ns.Instances.ToRecord(run)
  append("instanceLog", {
    time = run.startedAt,
    name = run.name,
    instanceType = run.instanceType,
    seconds = run.seconds,
    level = run.level,
    xp = record.xp,
    counters = record.counters,
    zoneUID = run.zoneUID,
  })
end

-- Letzten beendeten Instanz-Lauf wieder herausnehmen, wenn er zu dieser Instanz gehört
-- (Instances.lua führt ihn mit dem offenen Lauf zusammen); sonst nil
function Journal.TakeLastInstanceRun(name)
  local log = ns.character.instanceLog
  local last = log[#log]
  if not last or last.name ~= name then return nil end
  changed("instanceLog")
  return table.remove(log)
end

-- cause = { killer, spell, environment }, Felder dürfen fehlen.
-- Gibt den Eintrag zurück, damit eine später bekannte Ursache nachgetragen werden kann.
function Journal.AddDeath(cause)
  local entry = baseEntry()
  Journal.SetDeathCause(entry, cause)
  append("deathLog", entry)
  return entry
end

function Journal.SetDeathCause(entry, cause)
  edited("deathLog")
  entry.killer = cause.killer
  entry.spell = cause.spell
  entry.environment = cause.environment
end

---------------------------------------------------------------------------
-- Lesen: Archiv (lädt bei Bedarf) und Eingang zusammen, älteste zuerst. Das Ergebnis wird je Charakter und Log
-- zwischengespeichert; Aufrufer dürfen die Liste nicht verändern. Neue Einträge im Eingang werden an dieselbe Liste
-- angehängt (O(neue Einträge) statt einer Kopie je Kill); ändert sich das Archiv oder schrumpft der Eingang
-- (Kürzen, herausgenommener Lauf), gibt es eine neue Liste. Wer sich etwas je Liste merkt, prüft also auch #list.
---------------------------------------------------------------------------
local combined = {}  -- [characterKey .. "#" .. logName] = { version, inbox, count, last, archivedCount, list }
local NO_INBOX = {}

-- Liegt der Eingang noch so wie beim letzten Lesen vor, nur mit neuen Einträgen dahinter? Dann anhängen.
local function extend(cached, inbox, version)
  if cached.version ~= version or cached.inbox ~= inbox then return false end
  local had, count = cached.count, #inbox
  if count < had or (had > 0 and inbox[had] ~= cached.last) then return false end
  local list, offset = cached.list, cached.archivedCount
  for i = had + 1, count do list[offset + i] = inbox[i] end
  cached.count, cached.last = count, inbox[count]
  return true
end

function Journal.GetEntries(characterKey, logName)
  local character = LevelTimerStatsDB and LevelTimerStatsDB.characters[characterKey]
  local inbox = character and character[logName] or NO_INBOX
  local archived, version = ns.JournalArchive.Entries(characterKey, logName)
  local cacheKey = characterKey .. "#" .. logName
  local cached = combined[cacheKey]
  if cached and extend(cached, inbox, version) then return cached.list end
  local list = {}
  for i = 1, #archived do list[i] = archived[i] end
  for _, entry in ipairs(inbox) do list[#list + 1] = entry end
  combined[cacheKey] = { version = version, inbox = inbox, count = #inbox, last = inbox[#inbox],
    archivedCount = #archived, list = list }
  return list
end
