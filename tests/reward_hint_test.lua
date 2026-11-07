-- Belohnungsempfehlung (Roadmap 346): Goldmünze auf der wertvollsten Wahl, "+N" auf dem größten Itemlevel-Gewinn
-- einer benutzbaren Wahl; nur Anzeige, unbekannte Werte werden später neu bewertet.
local function link(id) return "|cff1eff00|Hitem:" .. id .. "::::|h[Item " .. id .. "]|h|r" end

wow.state.questChoices = { link(1), link(2), link(3) }
wow.state.sellPrices = { [link(1)] = 500, [link(2)] = 100, [link(3)] = 200 }
wow.state.itemIcons = { [1] = 1, [2] = 2, [3] = 3, [9] = 9 }
wow.state.equipLocs = { [1] = "INVTYPE_HEAD", [2] = "INVTYPE_FEET", [3] = "INVTYPE_FINGER", [9] = "INVTYPE_FEET" }
wow.state.itemLevels = { [1] = 30, [2] = 25, [3] = 28, [9] = 20 }
wow.state.equipped = { [1] = link(1), [8] = link(9) }  -- Kopf gleichwertig, Füße schwächer, Ringe leer
wow.state.questChoiceUnusable = { [3] = true }

-- Questfenster wie Blizzards QuestInfo: Knöpfe mit type "choice" und GetID
local buttons = {}
for index = 1, 3 do
  local button = CreateFrame("Button")
  button.type = "choice"
  button.GetID = function() return index end
  buttons[index] = button
end
QuestInfoFrame = { rewardsFrame = { RewardButtons = buttons }, questLog = false }
local displays = { count = 0 }
function QuestInfo_Display() displays.count = displays.count + 1 end

-- Kind-Texturen und -Texte der Knöpfe abfangen
local children = {}
for index, button in ipairs(buttons) do
  children[index] = {}
  button.CreateTexture = function() local t = CreateFrame("Frame"); children[index].coin = t; return t end
  button.CreateFontString = function() local t = CreateFrame("Frame"); children[index].upgrade = t; return t end
end

wow.login({ level = 20 })
QuestInfo_Display()
expect("aus: keine Symbole", children[1].coin, nil)

addon.Set("rewardHint", true)
QuestInfo_Display()
expect("Original läuft", displays.count, 2)
expect("Goldmünze auf der teuersten", children[1].coin:IsShown(), true)
expect("keine Münze sonst", children[2].coin:IsShown(), false)
expect("Upgrade: Füße +5", children[2].upgrade:GetText(), "+5")
expect("Upgrade sichtbar", children[2].upgrade:IsShown(), true)
expect("nicht benutzbarer Ring zählt nicht", children[3].upgrade:IsShown(), false)
expect("Kopf gleichwertig: kein Upgrade", children[1].upgrade:IsShown(), false)

-- Unbekannter Preis: erst nichts, nach dem Laden gesetzt
wow.state.sellPrices[link(3)] = nil
wow.timers = {}
QuestInfo_Display()
expect("unbekannt: keine Münze", children[1].coin:IsShown(), false)
wow.state.sellPrices[link(3)] = 900
wow.runTimers()
expect("nachgeladen: Münze auf der dritten", children[3].coin:IsShown(), true)

-- Ausschalten blendet aus
addon.Set("rewardHint", false)
expect("aus: Münze weg", children[3].coin:IsShown(), false)
expect("Fehler?", #wow.errors, 0)
