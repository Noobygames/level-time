-- Numerische Bedrohungsanzeige (Reiter Komfort, System; threatShowNumeric, Standard aus; Roadmap 443).
-- Setzt die CVar threatShowNumeric auf 1, umkehrbar über Lib/CVars.lua.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    threatShowNumeric = false,
  },
})

local ThreatDisplay = {}
ns.ThreatDisplay = ThreatDisplay

local CVAR = "threatShowNumeric"

local function apply(db)
  db = db or ns.db
  if not db then return end
  if db.threatShowNumeric == true then
    ns.CVars.Override(CVAR, "1")
  else
    ns.CVars.Restore(CVAR)
  end
end

ThreatDisplay.Apply = apply
ns.RegisterApply(apply)
