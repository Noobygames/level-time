-- Umkehrbares Überschreiben von Werten an Blizzard-Objekten (Komfort-Einstellungen ohne /reload).
-- Overrides.New(read, write) liefert set(object, enabled, ...):
--   enabled = true   merkt beim ersten Mal den Originalzustand (read(object) -> Werteliste) und ruft write(object, ...)
--   enabled = false  stellt das gemerkte Original her (write(object, original...)) und vergisst es
-- Fehlende Objekte (nil, z.B. Frames, die es im Client nicht gibt) werden übergangen.
local _, ns = ...

local Overrides = {}
ns.Overrides = Overrides

function Overrides.New(read, write)
  local originals = {}
  return function(object, enabled, ...)
    if not object then return end
    if enabled then
      if originals[object] == nil then originals[object] = { read(object) } end
      write(object, ...)
    elseif originals[object] then
      write(object, unpack(originals[object]))
      originals[object] = nil
    end
  end
end

-- Häufige Fälle
Overrides.Alpha = function()
  return Overrides.New(
    function(object) return object:GetAlpha() end,
    function(object, alpha) object:SetAlpha(alpha) end)
end

Overrides.Parent = function()
  return Overrides.New(
    function(frame) return frame:GetParent() end,
    function(frame, parent) frame:SetParent(parent) end)
end

-- Versteckter Rahmen als Elternteil zum Ausblenden: Blizzard kann das Kind weiter zeigen, es bleibt unsichtbar
local hiddenParent
function Overrides.HiddenParent()
  if not hiddenParent then
    hiddenParent = CreateFrame("Frame")
    hiddenParent:Hide()
  end
  return hiddenParent
end
