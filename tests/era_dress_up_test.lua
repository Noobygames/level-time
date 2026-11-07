-- Anprobe-Knöpfe in Classic: das Modell ist DressUpModelFrame (DressUpModel)
local calls = {}
DressUpFrame = CreateFrame("Frame", "DressUpFrame")
DressUpFrameResetButton = CreateFrame("Button", "DressUpFrameResetButton", DressUpFrame)
DressUpModelFrame = CreateFrame("Frame", "DressUpModelFrame", DressUpFrame)
function DressUpModelFrame:Undress() table.insert(calls, "all") end
function DressUpModelFrame:UndressSlot(slot) table.insert(calls, slot) end

wow.login()
addon.Set("dressUpButtons", true)
addon.DressUp.UndressAll()
addon.DressUp.UndressTabard()
expect("Classic-Modell ausgezogen", calls[1], "all")
expect("Classic-Wappenrock", calls[2], 19)
