-- Anprobe-Knöpfe (dressUpButtons): Retail-Anprobe mit ModelScene-Darsteller, Ausziehen und Wappenrock
local calls = {}
local actor = {
  Undress = function() table.insert(calls, "all") end,
  UndressSlot = function(_, slot) table.insert(calls, slot) end,
}
DressUpFrame = CreateFrame("Frame", "DressUpFrame")
DressUpFrame.ModelScene = { GetPlayerActor = function() return actor end }
DressUpFrameResetButton = CreateFrame("Button", "DressUpFrameResetButton", DressUpFrame)

wow.login()
expect("aus: keine Knöpfe", addon.DressUp.Buttons(), nil)
addon.Set("dressUpButtons", true)
local buttons = addon.DressUp.Buttons()
expectTrue("Knöpfe sichtbar", buttons.undress:IsShown() and buttons.tabard:IsShown())
wow.click(addon.L.DRESS_UP_UNDRESS)
wow.click(addon.L.DRESS_UP_TABARD)
expect("alles ausgezogen", calls[1], "all")
expect("Wappenrock ab", calls[2], 19)
addon.Set("dressUpButtons", false)
expect("aus: versteckt", buttons.undress:IsShown(), false)
