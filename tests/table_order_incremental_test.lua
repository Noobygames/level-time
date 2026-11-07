-- Roadmap 339: Journal-Tabellen inkrementell. TableOrder.NewAppendOnly liefert nach beliebigen Anhängen, Sortierungen
-- und Filtern dieselbe Reihenfolge wie die volle Neuberechnung (FilterAndSort über die umgedrehte Liste);
-- Journal.GetEntries hängt an dieselbe Liste an, statt sie zu kopieren.
local TableOrder = addon.TableOrder
local Journal = addon.Journal
local L = addon.L

-- Spalten wie im Journal: Text, Zahl mit Lücken, gleiche Werte (stabile Reihenfolge), Text mit Farbcodes
local COLUMNS = {
  { header = "A", value = function(r) return r.name end },
  { header = "B", value = function(r) return r.level or "" end, sort = function(r) return r.level end },
  { header = "C", value = function(r) return r.group end },
  { header = "D", value = function(r) return "|cffff0000" .. r.zone .. "|r" end },
}
local NAMES = { "Wolf", "wolfsrudel", "Eber", "Bär", "Defias", "Ghul", "Murloc" }
local ZONES = { "Westfall", "Wald", "Dämmerwald" }
local FILTERS = { "", "w", "wo", "wol", "e", "wald", "x", "1", "" }

math.randomseed(42)
local function newEntry(i)
  return { name = NAMES[math.random(#NAMES)] .. (math.random(3) == 1 and " " .. i or ""),
    level = math.random(4) > 1 and math.random(10) or nil, group = math.random(3), zone = ZONES[math.random(#ZONES)] }
end

local function reversed(list)
  local result = {}
  for i = #list, 1, -1 do result[#result + 1] = list[i] end
  return result
end

local function same(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do if a[i] ~= b[i] then return false end end
  return true
end

local list, view = {}, TableOrder.NewAppendOnly(COLUMNS)
local mismatches = { count = 0, first = nil }
for step = 1, 120 do
  local roll = math.random(10)
  if roll <= 5 then
    for _ = 1, math.random(roll == 1 and 40 or 3) do list[#list + 1] = newEntry(#list + 1) end
  end
  local sort
  if math.random(3) > 1 then
    local column = COLUMNS[math.random(#COLUMNS)]
    sort = { column = column, descending = math.random(2) == 1 }
  end
  -- Suchtexte oft verlängert (Eingabe), manchmal gekürzt oder gewechselt
  local filter = FILTERS[math.random(#FILTERS)]
  for _ = 1, 3 do
    view:Update(list, filter, sort, "de")
    local expected = TableOrder.FilterAndSort(COLUMNS, reversed(list), filter, sort)
    if not same(view:List(), expected) or view:Count() ~= #expected then
      mismatches.count = mismatches.count + 1
      mismatches.first = mismatches.first or step
    end
    if math.random(2) == 1 then list[#list + 1] = newEntry(#list + 1) end
  end
end
expect("inkrementell = vollständig (Schritt " .. tostring(mismatches.first) .. ")", mismatches.count, 0)
expectTrue("viele Einträge geprüft", #list > 150)

-- Neue Liste (Archiv-Umzug, gekürzter Eingang): kompletter Neuaufbau
local shorter = {}
for i = 10, #list do shorter[#shorter + 1] = list[i] end
view:Update(shorter, "w", { column = COLUMNS[2], descending = true }, "de")
expect("neue Liste", same(view:List(), TableOrder.FilterAndSort(COLUMNS, reversed(shorter), "w",
  { column = COLUMNS[2], descending = true })), true)

-- Geänderter Eintrag zählt erst mit neuem Stand (epoch): z.B. nachgetragene Todesursache
local sortByName = { column = COLUMNS[1], descending = false }
view:Update(shorter, "", sortByName, "de")
shorter[1].name = "Aaa zuerst"
view:Update(shorter, "", sortByName, "de:1")
expect("neuer Stand: neu sortiert", view:At(1), shorter[1])

-- Anhängen rechnet nur die neuen Einträge: Schlüssel und Suchtext je Eintrag einmal
local calls = { sort = 0, value = 0 }
local counted = {
  { header = "N", value = function(r) calls.value = calls.value + 1 return r.name end,
    sort = function(r) calls.sort = calls.sort + 1 return r.level end },
}
local growing, counting = {}, TableOrder.NewAppendOnly(counted)
for i = 1, 200 do growing[i] = newEntry(i) end
local byLevel = { column = counted[1], descending = true }
counting:Update(growing, "", byLevel, "de")
expect("erste Sortierung: ein Schlüssel je Eintrag", calls.sort, 200)
growing[201] = newEntry(201)
counting:Update(growing, "", byLevel, "de")
expect("neuer Eintrag: nur sein Schlüssel", calls.sort, 201)
counting:Update(growing, "w", byLevel, "de")
local afterFilter = calls.value
counting:Update(growing, "wo", byLevel, "de")
counting:Update(growing, "w", byLevel, "de")
expect("Suchtext je Eintrag nur einmal gebaut", calls.value, afterFilter)
expect("gleiche Sortierung wie voll", same(counting:List(), TableOrder.FilterAndSort(counted, reversed(growing), "w",
  byLevel)), true)

---------------------------------------------------------------------------
-- Journal.GetEntries: dieselbe Liste wächst; Kürzen des Eingangs gibt eine neue Liste
---------------------------------------------------------------------------
wow.login({ level = 20, xp = 0, xpMax = 1000 })
local key = addon.characterKey
for i = 1, 5 do Journal.AddKill(Journal.PVE, "Wolf " .. i) end
local entries = Journal.GetEntries(key, "killLog")
expect("fünf Kills", #entries, 5)
Journal.AddKill(Journal.PVE, "Eber")
expect("dieselbe Liste", Journal.GetEntries(key, "killLog"), entries)
expect("angehängt", entries[6].name, "Eber")
table.remove(addon.character.killLog, 1)
local trimmed = Journal.GetEntries(key, "killLog")
expectTrue("gekürzt: neue Liste", trimmed ~= entries)
expect("gekürzt: Inhalt", trimmed[1].name, "Wolf 2")
expect("alte Liste unverändert", #entries, 6)
expect("History neueste zuerst", addon.History.GetKillLog(key)[1].name, "Eber")
Journal.AddKill(Journal.PVE, "Bär")
expect("History nach Anhängen", addon.History.GetKillLog(key)[1].name, "Bär")

---------------------------------------------------------------------------
-- Kill-Tabelle: sortiert und gefiltert, neue Kills landen an der richtigen Stelle; Todesursache nachgetragen
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("history")
wow.click(L.HISTORY_GROUP_JOURNAL)
wow.click(L.HISTORY_TAB_KILLS)
local kills = wow.shownTable()
kills:SortBy(2)  -- Name A-Z
local function names()
  local result = {}
  for _, record in ipairs(kills:GetVisibleRecords()) do result[#result + 1] = record.name end
  return table.concat(result, ",")
end
expect("Name A-Z", names(), "Bär,Eber,Wolf 2,Wolf 3,Wolf 4,Wolf 5")
Journal.AddKill(Journal.PVE, "Defias")
wow.advance(6)
wow.update(1.1)
expect("neuer Kill einsortiert", names(), "Bär,Defias,Eber,Wolf 2,Wolf 3,Wolf 4,Wolf 5")
kills:SetFilter("wo")
kills:SetFilter("wolf 4")
expect("verlängerter Filter", names(), "Wolf 4")
kills:SetFilter("wolf")
expect("gekürzter Filter", names(), "Wolf 2,Wolf 3,Wolf 4,Wolf 5")
kills:SetFilter("")
expect("Summenzeile zählt", wow.findFrame(function(frame)
  return rawget(frame, "_text") == string.format(L.HISTORY_COUNT, 7)
end) ~= nil, true)

wow.click(L.HISTORY_TAB_DEATHS)
local deaths = wow.shownTable()
local death = Journal.AddDeath({})
wow.advance(6)
wow.update(1.1)
deaths:SetFilter("wolf")
expect("ohne Ursache kein Treffer", #deaths:GetVisibleRecords(), 0)
Journal.SetDeathCause(death, { killer = "Wolf" })
wow.advance(6)
wow.update(1.1)
expect("nachgetragene Ursache gefunden", #deaths:GetVisibleRecords(), 1)
