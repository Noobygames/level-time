-- Regressionen aus Review D: Zahlenformat, Einladungs-GUID
local Format = addon.Format
expect("999.960 -> Million", Format.Number(999960), "1.0M")
expect("999.940 bleibt k", Format.Number(999940), "999.9k")
expect("12.300", Format.Number(12300), "12.3k")

local Social = addon.Social
expect("GUID ohne isCrossShard", Social.InviterGUID(false, false, false, true, true, "Player-1-A", false), "Player-1-A")
expect("GUID mit isCrossShard", Social.InviterGUID(false, false, false, true, false, true, "Player-1-B", false), "Player-1-B")
