-- Versionierte Migrationen und Standardwerte für gespeicherte Tabellen (SavedVariables), ohne Fachwissen:
-- Database.lua nutzt sie für Einstellungen und Charakterdaten, ein weiteres Addon kann sie genauso nutzen.
local _, ns = ...

local Migrate = {}
ns.Migrate = Migrate

-- migrations[Zielversion](data) für jede Version nach data.schemaVersion (fehlend = 1) bis targetVersion.
-- Die Version wird nie gesenkt: nach einem Downgrade (ältere Addon-Version) liefen nicht wiederholbare
-- Migrationen beim nächsten Upgrade sonst ein zweites Mal
function Migrate.Run(data, migrations, targetVersion)
  local version = data.schemaVersion or 1
  if version >= targetVersion then return end
  for nextVersion = version + 1, targetVersion do
    if migrations[nextVersion] then
      migrations[nextVersion](data)
    end
  end
  data.schemaVersion = targetVersion
end

-- Fehlende Werte aus den Defaults ergänzen (auch verschachtelt); gibt data zurück
function Migrate.ApplyDefaults(data, defaults)
  for key, value in pairs(defaults) do
    if type(value) == "table" then
      if type(data[key]) ~= "table" then data[key] = {} end
      Migrate.ApplyDefaults(data[key], value)
    elseif data[key] == nil then
      data[key] = value
    end
  end
  return data
end
