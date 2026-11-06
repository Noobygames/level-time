-- Kompakte Speicherform für viele gleich gebaute Einträge (Journal-Archiv): ein Eintrag wird eine Textzeile mit den
-- Feldern in fester Reihenfolge, getrennt durch SEPARATOR; fehlende Felder bleiben leer. Felder der Art "value"
-- (Namen, Zonen, Links, ...) stehen nur als Nummer in der Zeile, der Wert selbst einmal im Wörterbuch (Dictionary).
-- Eine Kill-Zeile braucht so rund 30 Byte statt 100-150 als Lua-Tabelle in den SavedVariables.
--   local codec = RecordCodec.New({ { path = "time" }, { path = "name", kind = "value" }, { path = "counters.kills" } })
--   local dict = RecordCodec.NewDictionary(savedValues)   -- savedValues = Liste, die gespeichert wird
--   local line = codec.Encode(entry, dict)                -- "1730900000\t3\t12"
--   local entry = codec.Decode(line, dict)
-- Felder: path ("a" oder "a.b" für eine Ebene tiefer), kind = "number" (Standard) oder "value" (Text oder Zahl,
-- über das Wörterbuch). Felder, die nicht in der Liste stehen, gehen verloren: neue Felder nur hinten anhängen.
local _, ns = ...

local RecordCodec = {}
ns.RecordCodec = RecordCodec

local SEPARATOR = "\t"
local KIND_VALUE = "value"

-- values = gespeicherte Liste (wird erweitert); der Index Wert -> Nummer lebt nur im Speicher
function RecordCodec.NewDictionary(values)
  local index = {}
  for number, value in ipairs(values) do index[value] = number end
  local dict = { values = values }

  function dict.NumberOf(value)
    local number = index[value]
    if not number then
      number = #values + 1
      values[number] = value
      index[value] = number
    end
    return number
  end

  function dict.ValueOf(number)
    return values[number]
  end

  return dict
end

local function splitPath(path)
  local outer, inner = path:match("^([^%.]+)%.(.+)$")
  return outer or path, inner
end

local function read(entry, field)
  local value = entry[field.outer]
  if field.inner then
    value = type(value) == "table" and value[field.inner] or nil
  end
  return value
end

local function assign(entry, field, value)
  if not field.inner then
    entry[field.outer] = value
    return
  end
  entry[field.outer] = entry[field.outer] or {}
  entry[field.outer][field.inner] = value
end

function RecordCodec.New(fieldList)
  local fields = {}
  for i, spec in ipairs(fieldList) do
    local outer, inner = splitPath(spec.path)
    fields[i] = { outer = outer, inner = inner, isValue = spec.kind == KIND_VALUE }
  end
  local codec = {}

  function codec.Encode(entry, dict)
    local parts = {}
    for i, field in ipairs(fields) do
      local value = read(entry, field)
      if value == nil then
        parts[i] = ""
      elseif field.isValue then
        parts[i] = tostring(dict.NumberOf(value))
      else
        parts[i] = tostring(value)
      end
    end
    return table.concat(parts, SEPARATOR)
  end

  function codec.Decode(line, dict)
    local entry, i = {}, 0
    for part in (line .. SEPARATOR):gmatch("(.-)" .. SEPARATOR) do
      i = i + 1
      local field = fields[i]
      if not field then break end
      if part ~= "" then
        local number = tonumber(part)
        assign(entry, field, field.isValue and dict.ValueOf(number) or number)
      end
    end
    return entry
  end

  return codec
end
