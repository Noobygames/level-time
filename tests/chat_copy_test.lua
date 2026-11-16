-- Chat kopieren: Zeilen eines Chatfensters als reiner Text im Kopierfenster.

wow.login()
ChatFrame1._messages = {
  "[2. Handel] |cffff0000Rot|r",
  "Beute: |cffa335ee|Hitem:1234::::|h[Zornklinge]|h|r",
  "|TInterface\\Icons\\INV_Misc_Coin_01:0|t 5 Gold",
  wow.SECRET,
}

-- Ohne Einstellung kein Button, /lt copy geht trotzdem
local function copyButton()
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == "C" and frame._points[1] and frame._points[1][2] == ChatFrame1
  end)
end
expect("aus: kein Button", copyButton(), nil)

local lines, hidden = addon.ChatCopy.Lines(ChatFrame1)
expect("älteste zuerst", lines[1], "[2. Handel] Rot")
expect("Link als Text", lines[2], "Beute: [Zornklinge]")
expect("Textur entfernt", lines[3], " 5 Gold")
expect("geheime Zeile gezählt", hidden, 1)

SlashCmdList.LEVELTIMER("copy")
expect("Kopierfenster offen", LevelTimerExport:IsShown(), true)

addon.Set("chatCopyButton", true)
local button = copyButton()
expectTrue("Button am Chatfenster", button ~= nil)
LevelTimerExport:Hide()
button._scripts.OnClick(button)
expect("Button öffnet Kopierfenster", LevelTimerExport:IsShown(), true)
addon.Set("chatCopyButton", false)
expect("wieder aus: Button weg", button:IsShown(), false)
