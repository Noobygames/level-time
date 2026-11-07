-- Level Time Goals: Item-Ziele zeigen das Symbol und den Tooltip des Items und zählen auch Hergestelltes.
local Goals = streamGoal.Goals

local BOOTS_ID, BOOTS_ICON = 2315, 132539
local boots = "|cff1eff00|Hitem:2315::::::::20:::::|h[Dunkle Lederstiefel]|h|r"

wow.state.itemIcons[BOOTS_ID] = BOOTS_ICON
wow.login({ level = 20, zone = "Orgrimmar" })

SlashCmdList.STREAMGOAL("add item " .. boots .. " 2")
local goal = Goals.Active()[1]
local def = Goals.GetKind("item")
expect("Symbol des Items", def.texture(goal), BOOTS_ICON)
expect("unbekanntes Item: kein eigenes Symbol", def.texture({ params = { itemId = 999999 } }), nil)

-- Überfahren der Karte zeigt den Item-Tooltip mit dem gespeicherten Link
local card = StreamGoalCard1
card._scripts.OnEnter(card)
expect("Item-Tooltip", GameTooltip._hyperlink, "item:2315::::::::20:::::")
card._scripts.OnLeave(card)
GameTooltip._hyperlink = nil
def.tooltip({ params = { itemId = 42 } }, GameTooltip)
expect("ohne Link: nur die ID", GameTooltip._hyperlink, "item:42")

-- Klick auf eine Item-Karte zählt nicht (nur selbst gezählte Ziele)
card._scripts.OnMouseUp(card, "LeftButton")
expect("Klick zählt nicht", goal.progress, 0)

-- Hergestellt zählt wie Beute, auch mehrere auf einmal
wow.fire("CHAT_MSG_LOOT", "Ihr stellt her: " .. boots .. ".")
expect("hergestellt zählt", goal.progress, 1)
wow.fire("CHAT_MSG_LOOT", "Ihr stellt her: " .. boots .. "x2.")
expect("Ziel erreicht", goal.status, Goals.DONE)
