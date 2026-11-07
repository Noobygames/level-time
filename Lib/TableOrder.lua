-- Reihenfolge der Zeilen einer Tabelle (TableView.lua): Sortierschlüssel, Filter und Sortierung.
--   FilterAndSort       gefilterte und sortierte Kopie einer Liste (kleine Tabellen, jedes Mal vollständig)
--   NewAppendOnly       für Listen, die nur hinten wachsen (Journale, älteste zuerst, angezeigt neueste zuerst):
--                       merkt Sortierschlüssel und Suchtext je Eintrag, liest die Liste über den Index statt sie
--                       umzudrehen, sortiert neue Einträge in die vorhandene Reihenfolge ein und sucht bei
--                       verlängertem Suchtext nur in den bisherigen Treffern. Ergebnis wie FilterAndSort über die
--                       umgedrehte Liste.
-- Spalten: value(record) = Zellentext, sort(record) optional = Sortierschlüssel, volatile = true, wenn der Wert
-- einer Zeile sich ohne neuen Eintrag ändern kann (z.B. Bestzeit über alle Einträge): nie zwischengespeichert.
local _, ns = ...
local Format = ns.Format

local TableOrder = {}
ns.TableOrder = TableOrder

local plainText = Format.PlainText
local NIL_KEY = {}             -- Platzhalter im Schlüssel-Zwischenspeicher für "kein Wert"
local COLUMN_SEPARATOR = "\1"  -- trennt die Spalten im Suchtext, damit kein Treffer über eine Spaltengrenze reicht
local INSERT_LIMIT = 64        -- mehr neue Treffer auf einmal: neu sortieren statt einzeln einsortieren

-- Sortierschlüssel einer Zeile: Zahlen bleiben Zahlen, Text ohne Farbcodes und Groß-/Kleinschreibung,
-- leere Werte = nil
function TableOrder.SortKey(column, record)
  local key
  if column.sort then key = column.sort(record) else key = column.value(record) end
  if key == nil or key == "" or type(key) == "number" then return key ~= "" and key or nil end
  return plainText(key):lower()
end
local sortKey = TableOrder.SortKey

-- Fehlende Werte immer ans Ende; Zahlen vor Text, damit gemischte Spalten eine feste Ordnung haben
function TableOrder.CompareKeys(a, b, descending)
  if a == nil then return false end
  if b == nil then return true end
  local aIsNumber, bIsNumber = type(a) == "number", type(b) == "number"
  if aIsNumber ~= bIsNumber then return aIsNumber end
  if descending then return a > b end
  return a < b
end
local compareKeys = TableOrder.CompareKeys

local function cellText(column, record)
  return plainText(column.value(record)):lower()
end

-- Enthält eine Zelle der Zeile den Suchtext (schon klein geschrieben)?
local function matchesColumns(columns, record, filterText)
  for _, column in ipairs(columns) do
    if cellText(column, record):find(filterText, 1, true) then return true end
  end
  return false
end

-- Gefilterte und sortierte Kopie; sort = { column, descending } oder nil
function TableOrder.FilterAndSort(columns, records, filterText, sort)
  local result = {}
  for index, record in ipairs(records) do
    if filterText == "" or matchesColumns(columns, record, filterText) then
      table.insert(result, { record = record, index = index, key = sort and sortKey(sort.column, record) })
    end
  end

  if sort then
    table.sort(result, function(a, b)
      if a.key == b.key then return a.index < b.index end  -- gleiche Werte: ursprüngliche Reihenfolge
      return compareKeys(a.key, b.key, sort.descending)
    end)
  end

  for i, entry in ipairs(result) do
    result[i] = entry.record
  end
  return result
end

---------------------------------------------------------------------------
-- Nur hinten wachsende Liste (älteste zuerst), angezeigt neueste zuerst
---------------------------------------------------------------------------

-- Zustand nach Update:
--   mode "all"     ohne Filter und Sortierung: Anzeige-Platz p = list[count - p + 1]
--   mode "matches" nur Filter: matches = Treffer-Indizes aufsteigend, Platz p = list[matches[#matches - p + 1]]
--   mode "sorted"  Sortierung (mit oder ohne Filter): order = Indizes in Anzeige-Reihenfolge
-- Gleiche Schlüssel: neuere Einträge zuerst (= ursprüngliche Anzeige-Reihenfolge, wie FilterAndSort).
function TableOrder.NewAppendOnly(columns)
  local view = {}
  local cachedColumns, volatileColumns = {}, {}
  for _, column in ipairs(columns) do
    table.insert(column.volatile and volatileColumns or cachedColumns, column)
  end

  local keyCache, haystacks = {}, {}  -- [Spalte] = { [Eintrag] = Schlüssel } bzw. [Eintrag] = Suchtext
  local epoch
  local list, count, filter, sortColumn, descending = nil, 0, "", nil, false
  local mode, matches, order, keys = "all", nil, nil, nil

  local function resetCaches()
    keyCache = {}
    haystacks = setmetatable({}, { __mode = "k" })
  end
  resetCaches()

  local function cachedKey(column, record)
    if column.volatile then return sortKey(column, record) end
    local cache = keyCache[column]
    if not cache then
      cache = setmetatable({}, { __mode = "k" })
      keyCache[column] = cache
    end
    local key = cache[record]
    if key == nil then
      key = sortKey(column, record)
      cache[record] = key == nil and NIL_KEY or key
      return key
    end
    if key == NIL_KEY then return nil end
    return key
  end

  local function haystack(record)
    local text = haystacks[record]
    if not text then
      local parts = {}
      for i, column in ipairs(cachedColumns) do parts[i] = cellText(column, record) end
      text = table.concat(parts, COLUMN_SEPARATOR)
      haystacks[record] = text
    end
    return text
  end

  local function isMatch(record, filterText)
    if haystack(record):find(filterText, 1, true) then return true end
    for _, column in ipairs(volatileColumns) do
      if cellText(column, record):find(filterText, 1, true) then return true end
    end
    return false
  end

  local function less(a, b)
    local ka, kb = keys[a], keys[b]
    if ka == kb then return a > b end
    return compareKeys(ka, kb, descending)
  end

  -- Einen Index per Binärsuche einsortieren: erster Platz, vor dem er stehen muss
  local function insertSorted(index)
    local low, high = 1, #order + 1
    while low < high do
      local middle = math.floor((low + high) / 2)
      if less(index, order[middle]) then high = middle else low = middle + 1 end
    end
    table.insert(order, low, index)
  end

  local function fullUpdate(filterText)
    local found = {}
    for index = 1, count do
      if filterText == "" or isMatch(list[index], filterText) then found[#found + 1] = index end
    end
    if not sortColumn then
      mode, matches, order, keys = "matches", found, nil, nil
      return
    end
    keys = {}
    for _, index in ipairs(found) do keys[index] = cachedKey(sortColumn, list[index]) end
    table.sort(found, less)
    mode, matches, order = "sorted", nil, found
  end

  -- Bisherige Treffer auf den längeren Suchtext beschränken (Reihenfolge bleibt)
  local function narrow(filterText)
    local source = mode == "sorted" and order or matches
    local kept = {}
    for _, index in ipairs(source) do
      if isMatch(list[index], filterText) then kept[#kept + 1] = index end
    end
    if mode == "sorted" then order = kept else matches = kept end
  end

  -- Neue Einträge (Indizes from..count) aufnehmen; false, wenn neu sortieren billiger ist
  local function addNew(from, filterText)
    local added = {}
    for index = from, count do
      if filterText == "" or isMatch(list[index], filterText) then added[#added + 1] = index end
    end
    if mode == "matches" then
      for _, index in ipairs(added) do matches[#matches + 1] = index end
      return true
    end
    if #added > INSERT_LIMIT then return false end
    for _, index in ipairs(added) do
      keys[index] = cachedKey(sortColumn, list[index])
      insertSorted(index)
    end
    return true
  end

  -- newList: älteste zuerst; sort = { column, descending } oder nil; newEpoch: ändert sich, wenn sich Texte oder
  -- Einträge an Ort und Stelle geändert haben (Sprache, nachgetragene Werte), dann wird alles neu berechnet
  function view:Update(newList, filterText, sort, newEpoch)
    if newEpoch ~= epoch then
      resetCaches()
      epoch = newEpoch
      list = nil
    end
    local newCount = #newList
    local newSortColumn = sort and sort.column
    local newDescending = sort and sort.descending or false
    local grown = newList == list and newCount >= count and mode ~= "all"
      and newSortColumn == sortColumn and newDescending == descending
      and not (newSortColumn and newSortColumn.volatile)
    local previousCount = count
    list, count, sortColumn, descending = newList, newCount, newSortColumn, newDescending

    if filterText == "" and not sortColumn then
      mode, matches, order, keys = "all", nil, nil, nil
    elseif grown and filterText == filter then
      if not addNew(previousCount + 1, filterText) then fullUpdate(filterText) end
    elseif grown and filterText:sub(1, #filter) == filter then
      narrow(filterText)
      if not addNew(previousCount + 1, filterText) then fullUpdate(filterText) end
    else
      fullUpdate(filterText)
    end
    filter = filterText
  end

  function view:Count()
    if mode == "all" then return count end
    if mode == "matches" then return #matches end
    return #order
  end

  function view:At(position)
    local index
    if mode == "all" then
      index = count - position + 1
    elseif mode == "matches" then
      index = matches[#matches - position + 1]
    else
      index = order[position]
    end
    return index and index >= 1 and list[index] or nil
  end

  -- Angezeigte Einträge als Liste (Export, Tests); baut eine neue Liste
  function view:List()
    local result = {}
    for position = 1, view:Count() do result[position] = view:At(position) end
    return result
  end

  return view
end
