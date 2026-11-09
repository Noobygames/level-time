-- Level Time Goals, Roadmap 439: Momente, die das Spiel erkennt (Rare sehen, tief fallen, Spieler grüßen, vor einem NPC
-- tanzen, schwimmen, andere heilen/wiederbeleben, Quest-Belohnung verkaufen, Item zurückkaufen), und die Bingo-Texte,
-- die jetzt diese Arten nutzen.
local Goals = streamGoal.Goals
local Moments = streamGoal.Moments
local Pool = streamGoal.Pool
local L = streamGoal.L

local units = wow.state.units

wow.login({ level = 20 })

local function add(command)
  SlashCmdList.STREAMGOAL("add moment " .. command)
  local active = Goals.Active()
  return active[#active]
end

local function tick(seconds, step)
  step = step or 0.1
  for _ = 1, math.floor(seconds / step + 0.5) do
    wow.advance(step)
    wow.update(step)
  end
end

---------------------------------------------------------------------------
-- Art und Befehl
---------------------------------------------------------------------------
local modes = table.concat(Moments.MODES, ",")
expect("alle Modi im Retail-Stub", modes, "rare,fall,greet,dance,swim,heal,sellreward,buyback")
local rare = add("rare 2")
expect("Modus", rare.params.mode, "rare")
expect("Titel Mehrzahl", Goals.Title(rare), string.format(L.SG_GOAL_MOMENT_RARE, 2))
SlashCmdList.STREAMGOAL("add moment nichts")
expect("unbekannter Modus legt nichts an", #Goals.Active(), 1)
expectTrue("Fehler nennt die Modi", wow.printed[#wow.printed]:find("sellreward", 1, true) ~= nil)

---------------------------------------------------------------------------
-- Rare sehen: lebend, je Rare einmal
---------------------------------------------------------------------------
units.target = { name = "Rotkamm", classification = "rare", guid = "Creature-0-1-500" }
wow.fire("PLAYER_TARGET_CHANGED")
expect("Rare gesehen", rare.progress, 1)
wow.fire("PLAYER_TARGET_CHANGED")
expect("derselbe Rare zählt einmal", rare.progress, 1)
units.mouseover = { name = "Wolf", classification = "normal", guid = "Creature-0-1-501" }
wow.fire("UPDATE_MOUSEOVER_UNIT")
expect("normaler Gegner zählt nicht", rare.progress, 1)
units.nameplate1 = { name = "Toter Rare", classification = "rareelite", guid = "Creature-0-1-502", dead = true }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("toter Rare zählt nicht", rare.progress, 1)
units.nameplate1 = { name = "Tethis", classification = "rareelite", guid = "Creature-0-1-503" }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("zweiter Rare erledigt das Ziel", rare.status, Goals.DONE)
units.target, units.mouseover, units.nameplate1 = nil, nil, nil

---------------------------------------------------------------------------
-- Tief fallen: mindestens 1,5 s im freien Fall, nicht auf Flugrouten
---------------------------------------------------------------------------
local fall = add("fall 3")
wow.state.falling = true
tick(0.8)
wow.state.falling = false
tick(0.2)
expect("Sprung zählt nicht", fall.progress, 0)
wow.state.falling = true
tick(2)
expect("zählt erst bei der Landung", fall.progress, 0)
wow.state.falling = false
tick(0.2)
expect("Klippe", fall.progress, 1)
wow.state.onTaxi, wow.state.falling = true, true
tick(3)
wow.state.falling = false
tick(0.2)
wow.state.onTaxi = false
expect("Flugroute zählt nicht", fall.progress, 1)
Goals.Cancel(fall.id)

---------------------------------------------------------------------------
-- Schwimmen: mindestens 3 s am Stück, je Bad einmal
---------------------------------------------------------------------------
local swim = add("swim 2")
wow.state.swimming = true
tick(2, 1)
expect("kurz im Wasser", swim.progress, 0)
tick(3, 1)
expect("geschwommen", swim.progress, 1)
tick(10, 1)
expect("dasselbe Bad einmal", swim.progress, 1)
wow.state.swimming = false
tick(1, 1)
wow.state.swimming = true
tick(4, 1)
expect("zweites Bad", swim.status, Goals.DONE)
wow.state.swimming = false

---------------------------------------------------------------------------
-- Emotes: Spieler grüßen, vor einem NPC tanzen
---------------------------------------------------------------------------
local greet = add("greet 2")
local dance = add("dance")
units.target = { name = "Bob", isPlayer = true, guid = "Player-1-0002" }
C_ChatInfo.PerformEmote("WAVE", "")
expect("Spieler gegrüßt", greet.progress, 1)
C_ChatInfo.PerformEmote("HELLO")
expect("derselbe Spieler zählt einmal", greet.progress, 1)
C_ChatInfo.PerformEmote("DANCE", "")
expect("Tanzen vor einem Spieler zählt nicht", dance.progress, 0)
units.target = { name = "Gastwirtin", guid = "Creature-0-1-600" }
C_ChatInfo.PerformEmote("WAVE", "")
expect("NPC grüßen zählt nicht", greet.progress, 1)
C_ChatInfo.PerformEmote("DANCE", "")
expect("vor dem NPC getanzt", dance.status, Goals.DONE)
-- Client liefert für NPCs nil statt false (Classic-Stil): zählt trotzdem
local dance2 = add("dance")
local isPlayer, controlled = UnitIsPlayer, UnitPlayerControlled
UnitIsPlayer = function(unit) if isPlayer(unit) then return true end return nil end
UnitPlayerControlled = function() return nil end
units.target = { name = "Schmied", guid = "Creature-0-1-601" }
C_ChatInfo.PerformEmote("DANCE", "")
expect("nil statt false: NPC erkannt", dance2.status, Goals.DONE)
UnitIsPlayer, UnitPlayerControlled = isPlayer, controlled
units.target = nil
units.party1 = { name = "Alice", isPlayer = true, guid = "Player-1-0003" }
C_ChatInfo.PerformEmote("GREET", "alice")
expect("Gruppenmitglied per Name", greet.status, Goals.DONE)
units.party1 = nil

---------------------------------------------------------------------------
-- Heilen und Wiederbeleben anderer Spieler
---------------------------------------------------------------------------
local heal = add("heal 3")
wow.state.helpfulSpells = { [2050] = true, [2006] = true }
units.target = { name = "Bob", isPlayer = true, friendly = true, guid = "Player-1-0002", health = 50, healthMax = 100 }
wow.fire("UNIT_SPELLCAST_SENT", "player", "Bob", "Cast-1", 2050)
expect("erst beim Gelingen", heal.progress, 0)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 2050)
expect("geheilt", heal.progress, 1)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 2050)
expect("derselbe Zauber einmal", heal.progress, 1)
units.target.health = 100
wow.fire("UNIT_SPELLCAST_SENT", "player", "Bob", "Cast-2", 2050)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 2050)
expect("volles Leben zählt nicht", heal.progress, 1)
wow.fire("UNIT_SPELLCAST_SENT", "player", "Bob", "Cast-3", 133)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3", 133)
expect("schädlicher Zauber zählt nicht", heal.progress, 1)
wow.fire("UNIT_SPELLCAST_SENT", "player", "Testchar", "Cast-4", 2050)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-4", 2050)
expect("sich selbst heilen zählt nicht", heal.progress, 1)
units.target.dead = true
wow.fire("UNIT_SPELLCAST_SENT", "player", "Bob", "Cast-5", 2006)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-5", 2006)
expect("wiederbelebt", heal.progress, 2)
units.target = nil
units.party2 = { name = "Carla", isPlayer = true, friendly = true, guid = "Player-1-0004", health = 10, healthMax = 100 }
wow.fire("UNIT_SPELLCAST_SENT", "player", "Carla", "Cast-6", 2050)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-6", 2050)
expect("Gruppenmitglied ohne Ziel geheilt", heal.status, Goals.DONE)
units.party2 = nil

---------------------------------------------------------------------------
-- Quest-Belohnung verkaufen und zurückkaufen
---------------------------------------------------------------------------
local sell = add("sellreward")
local buyback = add("buyback")
local LINK = "|cff1eff00|Hitem:%d::::::::|h[Belohnung]|h|r"
wow.fire("QUEST_TURNED_IN", 100, 500, 0)
wow.fire("CHAT_MSG_LOOT", string.format(LOOT_ITEM_PUSHED_SELF, string.format(LINK, 4711)))
wow.fire("CHAT_MSG_LOOT", string.format(LOOT_ITEM_PUSHED_SELF, string.format(LINK, 4712)))
wow.advance(60)
wow.fire("CHAT_MSG_LOOT", string.format(LOOT_ITEM_PUSHED_SELF, string.format(LINK, 9999)))  -- später gekauft
expectTrue("Belohnung gemerkt", streamGoal.MerchantMoments.IsReward(4711))
expect("Kauf ist keine Belohnung", streamGoal.MerchantMoments.IsReward(9999), false)
wow.state.bags[0] = {
  { itemID = 9999, quality = 1, stackCount = 1 },
  { itemID = 4711, quality = 2, stackCount = 1 },
}
wow.fire("MERCHANT_SHOW")
C_Container.UseContainerItem(0, 1)
wow.fire("BAG_UPDATE_DELAYED")
expect("anderes Item verkauft", sell.progress, 0)
C_Container.UseContainerItem(0, 2)
wow.fire("MERCHANT_UPDATE")
expect("Belohnung verkauft", sell.status, Goals.DONE)
expect("verkaufte Belohnung vergessen", streamGoal.MerchantMoments.IsReward(4711), false)
BuybackItem(1)
expect("zurückgekauft", buyback.status, Goals.DONE)
wow.fire("MERCHANT_CLOSED")
wow.runTimers()

---------------------------------------------------------------------------
-- Bingo-Texte: erkennbare werden zu Arten, die übrigen bleiben Freitext
---------------------------------------------------------------------------
local AUTO = { text1 = "moment", text2 = "moment", text3 = "moment", text4 = "moment", text5 = "escape",
  text9 = "moment", text11 = "moment", text12 = "moment", text13 = "moment" }
for key, kind in pairs(AUTO) do
  expect(key .. " erkannt", Pool.Get("p:" .. key).kind, kind)
end
expect("Witz bleibt Freitext", Pool.Get("p:text6").kind, "custom")
expect("Weglaufen-Titel wie der Text", Pool.Title(Pool.Get("p:text5")), L.SG_GOAL_ESCAPE_ONE)
expect("Klippe", Pool.Title(Pool.Get("p:text2")), L.SG_GOAL_MOMENT_FALL_ONE)
-- Ohne den Modus im Client: Text zum Abhaken
local premade = Pool.PREMADE
for _, entry in ipairs(premade) do
  if entry.key == "text11" then entry.params = { mode = "unbekannt" } end
end
local fallback = Pool.Get("p:text11")
expect("Rückfall auf Freitext", fallback.kind, "custom")
expect("Rückfall-Text", fallback.params.text, L.SG_BINGO_TEXT_11)
for _, entry in ipairs(premade) do
  if entry.key == "text11" then entry.params = { mode = "swim" } end
end
expect("keine Lua-Fehler", #wow.errors, 0)
