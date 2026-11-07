-- Roadmap 201: Schalt-Befehle melden ihren neuen Zustand, /lt sync nennt die Antwort des Servers.
local L = addon.L

wow.login({ level = 12 })
local function lt(input) SlashCmdList.LEVELTIMER(input) end
local function lastLine() return wow.printed[#wow.printed] or "" end
local function said(text) return lastLine():find(text, 1, true) ~= nil end

lt("hide")
expect("hide schaltet", LevelTimerDB.showTimer, false)
expectTrue("hide meldet", said(L.CMD_HIDDEN))
lt("show")
expectTrue("show meldet", said(L.CMD_SHOWN))

lt("compact")
expect("compact an", LevelTimerDB.windowLayout, "compact")
expectTrue("compact meldet an", said(L.CMD_COMPACT_ON))
lt("compact")
expectTrue("compact meldet aus", said(L.CMD_COMPACT_OFF))

lt("bar")
expectTrue("bar meldet an", said(L.CMD_BAR_ON))
lt("bar")
expectTrue("bar meldet aus", said(L.CMD_BAR_OFF))

local splitsBefore = LevelTimerDB.showSplitList
lt("splits")
expectTrue("splits meldet", said(splitsBefore and L.CMD_SPLITS_OFF or L.CMD_SPLITS_ON))
lt("splits")
expect("splits zurück", LevelTimerDB.showSplitList, splitsBefore)

lt("minimap")
expectTrue("minimap aus meldet", said(L.MINIMAP_HIDDEN))
lt("minimap")
expectTrue("minimap an meldet", said(L.CMD_MINIMAP_ON))

lt("sync")
expectTrue("sync meldet Abfrage", said(L.CMD_SYNC))
wow.fire("TIME_PLAYED_MSG", 7200, 600)
expectTrue("sync meldet Antwort", said(string.format(L.CMD_SYNCED, addon.Format.Duration(7200), addon.Format.Duration(600))))
local count = #wow.printed
wow.fire("TIME_PLAYED_MSG", 7300, 700)
expect("nur einmal gemeldet", #wow.printed, count)
