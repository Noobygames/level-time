-- Widgets.SetTextIfChanged: SetText nur bei geändertem Text; ChatPatterns.Match ohne Treffer bleibt nil.
local Widgets = addon.Widgets
wow.login()

local label = CreateFrame("Frame"):CreateFontString()
local calls = { count = 0 }
local setText = label.SetText
label.SetText = function(self, text)
  calls.count = calls.count + 1
  setText(self, text)
end
expect("neu: gesetzt", Widgets.SetTextIfChanged(label, "42 s"), true)
expect("gleich: nicht gesetzt", Widgets.SetTextIfChanged(label, "42 s"), false)
expect("ein SetText", calls.count, 1)
expect("anders: gesetzt", Widgets.SetTextIfChanged(label, "41 s"), true)
expect("Text", label:GetText(), "41 s")

-- Chatmuster: Treffer liefert die Argumente, ein Fehlschlag nil
local compiled = addon.ChatPatterns.Compile(COMBATLOG_XPGAIN_FIRSTPERSON)
local args = addon.ChatPatterns.Match("Wolf stirbt, Ihr bekommt 100 Erfahrung.", compiled)
expect("Treffer: Name", args and args[1], "Wolf")
expect("Treffer: XP", args and args[2], "100")
expect("kein Treffer", addon.ChatPatterns.Match("Hogger sagt: Grrr!", compiled), nil)
