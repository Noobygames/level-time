# Zul'Farrak - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=35196 (zulfarrak)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/zulfarrak


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/zulfarrak

Journal: areaId (zone) 1176; level range from journal: 46-56; kind dungeon

Journal description: Zul'Farrak is a troll city located in northwestern Tanaris. Due to its massive size, players can use mounts in the zone. While the bosses can be defeated in any order, the instance comes to a climax when players are able to rescue a band of mercenaries trapped in cages by the Sandfury trolls. This is particularly notable as it was one of World of Warcraft's first scripted events.

### Journal quests (id, level as shown, side)
- The Spider God [quest=2936] level 45, Horde
- Nekrum's Medallion [quest=2991] level 47, Alliance
- Divino-matic Rod [quest=2768] level 47, both
- Scarab Shells [quest=2865] level 45, both
- Troll Temper [quest=3042] level 45, both
- Tiara of the Deep [quest=2846] level 46, both
- Gahz'rilla [quest=2770] level 50, both
- The Prophecy of Mosh'aru [quest=3527] level 47, both

### Journal bosses

#### Antu'sul (NPC ids [8127])
Overview: Antu'sul is a difficult boss due to his ability to summon [npc=8138] and [npc=8156] during the encounter. When this happens, all DPS should immediately AoE down the additional mobs and prioritize them over the boss. The tank should be ready to interrupt the healing abilities, and melee DPS should prioritize totems as soon as they're up. This boss is quite mechanically intensive for a dungeon boss and requires all parties to fulfil their roles for a successful attempt.
Role notes: damage: Focus on killing adds before the boss.
- Antu'sul's Minion [spell=11894]: 
- Healing Wave of Antu'sul [spell=11895]: Heal your target for 2400.
- Earthgrab Totem [spell=8376]: Summons an Earthgrab Totem that lasts 30 sec. and periodically immobilizes nearby enemies.
- Flash Heal [spell=10915]: Heals a friendly target for 480 to 567.
- Chain Lightning [spell=2860]: Hurls a lightning bolt at the enemy, dealing 417 to 466 Nature damage and then jumping to additional nearby enemies. Each jump reduces the damage by 30%. Affects 3 total targets. | note: Spread out to reduce the damage this deals.
- Earth Shock [spell=10413]: Instantly shocks the target with concussive force, causing 380 to 402 Nature damage. It also interrupts spellcasting and prevents any spell in that school from being cast for 2 sec. Causes a high amount of threat.

#### Theka the Martyr (NPC ids [7272])
Overview: Theka is a quest-related mini-boss that can be found in the Scarab room of Zul'Farrak. At 30%, he becomes immune to physical damage and shadow damage for 30 seconds, making Mages a valuable asset in the dungeon. He is a simple tank and spank, but once he becomes immune, nearby scarabs will aid him in battle. Focus down Theka first before finishing off the scarabs.
- Fevered Plague [spell=8600]: Inflicts 250 Nature damage to an enemy, then an additional 11 damage every 5 sec. for 3 min.
Loot: First Mosh'aru Tablet [item=10660]

#### Witch Doctor Zum'rah (NPC ids [7271])
Overview: Zum'rah is a challenging boss that is quite demanding on the healers. Interrupts are paramount during this fight in order to prevent unnecessary damage from his shadow bolt volley. Throughout the engagement, Zum'rah will summon zombies from nearby graves to attack your group. Make sure to switch over to the zombies immediately as they are summoned and burn them down fast. Whenever Zum'rah spawns a totem, prioritize it as well. This is a chaotic fight, but if the totem and adds are prioritized, it shouldn't be too difficult.
Role notes: damage: Prioritize killing adds and totems when they spawn.
- Shadow Bolt Volley [spell=15245]: Hurls missiles of dark magic, inflicting Shadow damage to nearby enemies. | note: Prioritize using interrupts on this cast.
- Ward of Zum'rah [spell=11086]: Casts a Ward of Zum'rah totem, which lasts 20 sec. and periodically summons a Skeleton of Zum'rah. Each Skeleton lasts 20 sec. | note: Kill the summoned totem as quickly as possible.
- Healing Wave [spell=12491]: Calls upon Nature magic to heal an ally.
- Shadow Bolt [spell=12739]: Hurls a bolt of dark magic at an enemy, inflicting Shadow damage.

#### Nekrum Gutchewer & Shadowpriest Sezz'ziz (NPC ids [7796, 7275])
Overview: Nekrum Gutchewer and Shadowpriest Sezz'ziz who spawn as the last wave of the stairs event in Zul'Farrak. The best strategy to deal with these two is to burn down Nekrum first. He has fewer abilities and is lower level, meaning less chance to dodge/miss/resist spells. Make sure one of your melee interrupts Sezz'ziz's heal in the meantime.
Role notes: damage: Kill Nekrum first.
- Fevered Plague [spell=8600]: Inflicts 250 Nature damage to an enemy, then an additional 11 damage every 5 sec. for 3 min.
- Psychic Scream [spell=13704]: Lets out a psychic scream, causing up to 5 nearby enemies to flee for 6 sec.
- Renew [spell=8362]: Heals an ally for 5 damage every 3 sec. for 20 sec.
- Shadow Bolt [spell=15537]: Hurls a bolt of dark magic at an enemy, inflicting Shadow damage.
- Heal [spell=12039]: Calls upon Holy magic to heal an ally. | note: Prioritize using interrupts when Shadowpriest Sezz'ziz casts this.
Loot: Nekrum's Medallion [item=9471]

#### Sergeant Bly (NPC ids [7604])
Overview: Sergeant Bly is accompanied by [npc=7606] and [npc=7608]. Between Oro's AoE and Murta's healing, this fight can be quite challenging. Prioritize Oro and Murta before switching to Bly.
Role notes: damage: Kill Oro and Murta first.
- Shield Bash [spell=11972]: Bashes an enemy with the caster's shield, inflicting Physical damage and interrupting the spell being cast for 8 sec.
- Revenge [spell=12170]: Instantly counterattack an enemy for 16 to 20 damage. Revenge must follow a block, dodge, or parry.
Loot: Divino-matic Rod [item=8548]

#### Hydromancer Velratha (NPC ids [7795])
Overview: Velratha is a simple tank and spank, but tests a group's situational awareness. Velratha patrols around the room, which is riddled with elite Sandfury. Make sure that you pull her ALONE; otherwise, a wipe is likely. Once you've pulled her safely, interrupt her casts, and you should be fine.
Role notes: tank: Be very careful when pulling the boss to avoid aggroing surrounding elite mobs.
- Healing Wave [spell=12491]: Calls upon Nature magic to heal an ally.
- Shadow Bolt [spell=12739]: Hurls a bolt of dark magic at an enemy, inflicting Shadow damage.
- Shadow Bolt Volley [spell=15245]: Hurls missiles of dark magic, inflicting Shadow damage to nearby enemies.
- Ward of Zum'rah [spell=11086]: Casts a Ward of Zum'rah totem, which lasts 20 sec. and periodically summons a Skeleton of Zum'rah. Each Skeleton lasts 20 sec.
Loot: Tiara of the Deep [item=9234], Second Mosh'aru Tablet [item=10661]

#### Chief Ukorz Sandscalp (NPC ids [7267, 7797])
Overview: Make sure to face these two away from the group. Melee should stay behind them to avoid the cleave. Kill Ruuzlu first.
Role notes: tank: Face the Chief and Ruuzlu away from your group.; damage: Focus on killing Ruuzlu first.
- Wide Slash [spell=11837]: Inflicts normal damage plus 3 to enemies in a cone in front of the caster.
- Cleave [spell=15496]: Inflicts weapon damage plus 10 to an enemy and its nearest ally.
- Berserker Stance [spell=7366]: Assumes an aggressive stance that generates rage when the warrior strikes an opponent. Lasts 4 min.

#### Gahz'rilla (NPC ids [7273])
Overview: Gahz'rilla is summoned by using the [item=9240] on the gong near the aqueduct. Make sure to clear the mobs around the room first. Tank him with the tank's back against a wall and stack on the tank to prevent being thrown up into the air. The rest of the fight is a tank and spank.
Role notes: tank: Clear the mobs before starting the encounter. Keep your back to a wall to prevent being knocked back.
- Icicle [spell=11131]: Shoots a bolt of ice, inflicting 375 Frost damage to an enemy and slowing its movement by 50% for 10 sec.
- Freeze Solid [spell=11836]: Stuns an enemy and inflicts 100 Frost damage every 3 sec. for 10 sec.
- Gahz'rilla Slam [spell=11902]: Inflicts normal damage plus 50 to nearby enemies and knocks them back.
Loot: Gahz'rilla's Electrified Scale [item=8707]

#### Zerillis (Rare) (NPC ids [10082])
Overview: Pull him into melee range immediately (you might need to LoS). Simple tank and spank.
- Net [spell=6533]: Immobilizes an enemy for 10 sec.
- Frost Shot [spell=12551]: Shoots at an enemy, inflicting 0 additional Frost damage and slowing its movement by 60% for 10 sec.

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Antu'sul: npcs[] spells[Chain Lightning updated: Costs 425 Mana instead of 490 Mana; Values increased by 6.6% and 6.4%; Earth Shock updated: Values increased by 2.2% and 2%; Flash Heal updated: Values decreased by 10.1% and 10.4%; Healing Wave of Antu'sul updated: Numbers and wording changed] newSpells[] loot[]
- Gahz'rilla: npcs[] spells[Icicle updated: Numbers and wording changed; Freeze Solid updated: Numbers and wording changed] newSpells[] loot[]


## Guide text
Source: https://www.wowhead.com/forever/guide=35196

Zul'Farrak [zone=1176] is located in Tanaris. This guide provides tips and strategies for completing Zul'Farrak, including everything you need before and during the dungeon, related quests, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## Zul'Farrak Overview in World of Warcraft: Forever

The recommended level for Zul'Farrak is between 44 and 54. In-game players usually refer to Zul'Farrak as "Farrak."

## Location of Zul'Farrak in World of Warcraft: Forever

The entrance to Zul'Farrak is in Tanaris [zone=440]. Both factions typically fly in to Gadgetzan {/forever/faction=369/gadgetzan}, then head west to Zul'Farrak.

Entrance to Zul'Farrak

As with many World of Warcraft Forever Dungeons, wiping (the entire group dying) in Zul'Farrak can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. 

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer (marked on the map below) as a ghost. You collect your body when you enter the instance.

## Every Quest in Zul'Farrak in World of Warcraft: Forever

Hard: Level 40 | Medium: Level 42 | At Level: Level 44 | Easy: Level 50

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

The Spider God [quest=2936] | 40 |  |  | Pre  | Durotar, Sen'jin Village - Master Gadrin [npc=3188] /way 56 74
Complete 3 quests first, starting withVenom Bottles [quest=2933]  | 

NEW Zum'rah's Head [quest=96775] | 42 |  |  |   | Mulgore, Skywatcher Plateau - Mazu'kon [npc=264074] /way 32 21 | 

Nekrum's Medallion [quest=2991] | 40 |  |  | Pre  | Blasted Lands, Nethergarde Keep - Thadius Grimshade [npc=8022] /way 66 19
Complete 3 quests first, starting withWitherbark Cages [quest=2988] | 

Divino-matic Rod [quest=2768] | 40 | - |  |   | Tanaris, Gadgetzan - Chief Engineer Bilgewhizzle [npc=7407] /way 52 28 | 

Scarab Shells [quest=2865] | 40 | - |  |   | Tanaris, Gadgetzan - Tran'rek [npc=7876] /way 51 26 | 

Troll Temper [quest=3042] | 40 | - |  |   | Tanaris, Gadgetzan - Trenton Lighthammer [npc=7804] /way 51 28 | 

Tiara of the Deep [quest=2846] | 40 | - |  |   | Dustwallow Marsh, N. of Stonemaul Ruins - Tabetha [npc=6546] /way 46 57 | 

Gahz'rilla [quest=2770] | 40 | - |  |   | Thousand Needles, Shimmering Flats - Wizzle Brassbolts [npc=4453] /way 78 77
One group member must have Mallet of Zul'Farrak [item=9240] to summon Gahz'rilla - drop from Qiaga the Keeper [npc=7996] in The Hinterlands | 

The Prophecy of Mosh'aru [quest=3527] | 40 | - |  | Pre  | Tanaris, Steamwheedle Port - Yeh'kinya [npc=8579] /way 67 22
CompleteScreecher Spirits [quest=3520] first  | 

Completing Dungeon Quests in World of Warcraft: Forever is a great way to gain some extra experience and gear. You will, though, find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

Faction: Neutral
Level Required: 40
Rewards: 
- Experience and Silver

Troll Temper [quest=3042] is picked up from Trenton Lighthammer [npc=7804] in Gadgetzan. 

The quest requires you to loot 20 Troll Temper [item=9523] from Sandury Trolls inside Zul'Farrak. The trolls can be found throughout the instance. 

The quest will be tagged as "Complete" when you have looted 20 tempers. 

Faction: Neutral
Level Required: 40
Rewards: 
- Experience and Silver

Scarab Shells [quest=2865] is picked up from Tran'rek [npc=7876] in Gadgetzan. In order to qualify for the quest, you must first have completed Tran'rek [quest=2864], which begins in Booty Bay. 

The quest requires you to loot 5 Uncracked Scarab Shell [item=9238] from Scarab [npc=7269] inside Zul'Farrak. 

The quest will be tagged as "Complete" once all 5 shells have been looted. 

Faction: Neutral
Level Required: 40
Rewards (choose one):
- Spellshifter Rod [item=9527]
- Gemshale Pauldrons [item=9531]

Tiara of the Deep [quest=2846] is picked up from Tabetha [npc=6546] in Dustwallow Marsh. 

The quest requires you to loot Tiara of the Deep [item=9234] from Hydromancer Velratha [npc=7795] inside Zul'Farrak. 

The quest will be tagged as "Complete" once the tiara has been looted.

Faction: Neutral
Level Required: 40
Rewards: 
- Experience and Silver

The Prophecy of Mosh'aru [quest=3527] is picked up from Yeh'kinya [npc=8579] in Steamwheedel Port in Tanaris. The quest's prerequisite, Screecher Spirits [quest=3520], is picked up from the same NPC. 

The quest requires you to loot the First Mosh'aru Tablet [item=10660] and the Second Mosh'aru Tablet [item=10661] from Zul'farrak. They drop from Hydromancer Velratha [npc=7795] and Theka the Martyr [npc=7272] inside ZF. 

The quest will be tagged as "Complete" once the tablets have been looted. 

Faction: Neutral
Level Required: 40
Rewards (choose one):
- Masons Fraternity Ring [item=9533]
- Engineer's Guild Headpiece [item=9534]

Divino-matic Rod [quest=2768] is picked up from Chief Engineer Bilgewhizzle [npc=7407] in Gadgetzan. 

The quest requires you to loot the Divino-matic Rod [item=8548] from Sergeant Bly [npc=7604] in Zul'Farrak. Sergeant Bly is the final boss of the stairs event. 

The quest will be tagged as "Complete" once the rod has been looted. 

Faction: Neutral
Level Required: 40
Rewards: 
- Carrot on a Stick [item=11122]

Gahz'rilla [quest=2770] is picked up from Wizzle Brassbolts [npc=4453] in The Shimmering Flats. 

The quest requires you to loot Gahz'rilla's Electrified Scale [item=8707] from Gahz'rilla [npc=7273] in Zul'Farrak. Summoning Gahz'rilla requires the Mallet of Zul'Farrak [item=9240], an outdoor item that is assembled through a series of objectives explained in the section below. 

The quest will be tagged as "Complete" once the scale has been looted. 

The Mallet of Zul'Farrak [item=9240] is a special item required to summon the final hidden boss of Zul'Farrak, Gahz'rilla [npc=7273]. 

To obtain the mallet, you will first need to loot the Sacred Mallet [item=9241] which drops off of Qiaga the Keeper [npc=7996] at the Altar of Zul in The Hinterlands. This expedition will require a group to complete, as Qiaga and the surrounding trolls are all elites.

Once the Sacred Mallet [item=9241] has been looted, you will need to scale Jintha'Alor in The Hinterlands and use the sacred mallet at the Altar of Jintha'Alor, which is located at the top of the temple. Scaling the temple will require a full group of level 46+ friends at least, as the temple is full of elite trolls. Once you have reaced the top, use the scared mallet at the altar, which will then transform into the Mallet of Zul'Farrak [item=9240].

With the mallet now in hand, head into Zul'Farrak and right-click the gong in front of the aqueduct to summon Gahz'rilla. Only 1 person per group will need a mallet to summon the beast. 

Faction: Alliance
Level Required: 40
Rewards: 
- Experience and Silver

Nekrum's Medallion [quest=2991] is the 4th step in a quest chain that is picked up from Thadius Grimshade [npc=8022] in Nethergarde Keep of the Blasted Lands. 

The quest chain itself begins at Gryphon Master Talonaxe [npc=5636] inside Aerie Peak. The first quest of the chain, Witherbark Cages [quest=2988], will require you to check several cages inside the Witherbark Villages. 

Eventually, you will reach the 4th step, Nekrum's Medallion [quest=2991], which requires you to loot Nekrum's Medallion [item=9471] from Nekrum Gutchewer [npc=7796], who spawns during the final wave of the ZF stairs event. 

The quest will be tagged as "Complete" once the medallion has been looted. 

Faction: Horde
Level Required: 40
Rewards: 
- Experience and Silver

The Spider God [quest=2936] is the 4th step in a quest chain that is picked up from Master Gadrin [npc=3188] in Sen'jin Village, Durotar. 

The quest chain itself begins one of the troll villages in The Hinterlands. To pick up the first quest in the chain, Venom Bottles [quest=2933], simply pick up one of the bright green venom bottles found at any of the troll villages.

Once you've picked up the quest, head to Apothecary Lydon [npc=2216] in Tarren Mill. He will send you on a few other quests before you can pick up The Spider God [quest=2936] from Sen'Jin.

The Spider God [quest=2936] portion of the chain requires you to head into Zul'Farrak and click on Tablet of Theka [object=142715], which is located in near Theka the Martyr [npc=7272] in the scarab room of Zul'Farrak.

The quest will be tagged as complete once the tablet has been read. 

### Best Quest Rewards

Type | Item | Quest | 

Trinket |  Carrot on a Stick [item=11122] |   Gahz'rilla
One of the most highly desired quest items in the game, due to it increasing mount speed. | 

## Noteworthy Trash Mobs

### Sandfury Shadowhunter

The Sandfury Shadowhunter [npc=7246] is a Sandfury Troll located inside Zul'Farrak

Strategy: Hex [spell=11641] is the key ability of the Shadowhunters, and if not dealt with properly, will result in a wipe for the group. It should be noted that the Hex ability causes all mobs to drop aggro on the hexxed target, meaning that if the target is the tank, all nearby enemies will begin attacking the remaining members of the group. In order to deal with a Hexxed tank, you must have a priest instantly dispel the effect from the tank. Alternatively, if you have a mage in your group, you can polymorph the Shadowhunter, clear out the remainder of the pack, and deal with the Shadowhunter alone. Either way, you have to be on your game, otherwise a wipe will be inevitable. 

## Bosses

Antu'sul [npc=8127] is a level 48 elite Sandury Troll located inside Zul'Farrak.

Antu'sul Abilities

- Earthgrab Totem [spell=8376]
- Healing Ward [spell=11899]
- Antu'sul's Minion [spell=11894]
- Healing Wave of Antu'sul [spell=11895]

Antu'sul Strategy
Antu'sul is a difficult boss due to his ability to summon Sul'lithuz Broodling [npc=8138] and Servant of Antu'sul [npc=8156] during the encounter. When this happens, all dps should immediately AOE down the additional mobs and prioritize them over the boss. The tank should be ready to interrupt the healing abilities, and melee dps should prioritize totems as soon as they're up. This boss is quite mechanically intensive for a dungeon boss in Vanilla, and requires all parties fulfilling their roles for a successful attempt. 

Theka the Martyr [npc=7272] is a level 46 elite Sandury Troll located inside Zul'Farrak. 

Theka the Martyr Abilities

- Fevered Plague [spell=8600]
- Theka Transform [spell=11089]

Theka the Martyr Strategy

Theka is a quest-related mini-boss that can be found in the Scarab room of Zul'Farrak. At 30%, he becomes immune to physical damage and shadow damage for 30 seconds, making Mages a valuable asset in the dungeon. He is a simple tank and spank, but once he goes immune, he will being aggroing nearby scarabs to aide him in battle. Focus down Theka first before finishing off the scarabs. 

Witch Doctor Zum'rah [npc=7271] is a level 46 elite Sandury Troll located inside Zul'Farrak. 

Witch Doctor Zum'rah Abilities

- Healing Wave [spell=12491]
- Shadow Bolt [spell=12739]
- Shadow Bolt Volley [spell=15245]
- Ward of Zum'rah [spell=11086]

Witch Doctor Zum'rah Strategy

Zum'rah is a challenging boss that is quite intensive on the healers. Interrupts are paramount during this fight in order to prevent unnecessary damage from his shadow bolt volley. Throughout the engagement, Zum'rah will summon zombies from nearby graves to attack your group. Make sure to switch over to the zombies immediately as they are summoned and burn them down fast. Whenever Zum'rah spawns a totem, prioritize it as well. This is a chaotic fight but if the totem and adds are prioritized, it shouldn't be too difficult. 

Nekrum Gutchewer [npc=7796] and Shadowpriest Sezz'ziz [npc=7275] are level 46 and 47 elite Sandury Trolls who spawn as the last wave of the stairs event in Zul'Farrak. 

Stairs Event Abilities

- Heal [spell=12039]
- Psychic Scream [spell=13704]
- Renew [spell=8362]
- Shadow Bolt [spell=15537]

Stairs Event Strategy

The best strategy to deal with these two is to burn down Nekrum first. He has fewer abilities and is lower level, meaning less chance to dodge/miss/resist spells. Make sure one of your melee interrupts Sezz'ziz's heal in the meantime. 

Sergeant Bly [npc=7604] is a level 45 elite human who is engaged after the stairs event in Zul'Farrak. He is accompanied by several other elite mobs. 

Sergeant Bly Abilities

- Revenge [spell=12170]
- Shield Bash [spell=11972]

Sergeant Bly Strategy

Sergeant Bly is accompanied by a few escorts, namely Oro Eyegouge [npc=7606] and Murta Grimgut [npc=7608]. Between Oro's AOE and Murta's healing, this fight can be quite challenging. Prioritze Oro and Murta before switching to Bly. 

Hydromancer Velratha [npc=7795] is a level 46 elite Sandfury Troll located near the end of Zul'Farrak. 

Hydromancer Velratha Abilities

- Healing Wave [spell=12491]
- Shadow Bolt [spell=12739]
- Shadow Bolt Volley [spell=15245]
- Ward of Zum'rah [spell=11086]

Hydromancer Velratha Strategy

Velratha is a simple tank and spank, but tests a groups situational awareness. Velratha patrols around the room, which is riddled with elite Sandfury. Make sure that you pull her ALONE, otherwise a wipe is likely. Once you've pulled her safely, interrupt here casts and you should be fine. 

Chief Ukorz Sandscalp [npc=7267] is a level 48 elite Sandury Troll, and is accompanied by a level 46 elite Ruuzlu [npc=7797].

Chief Ukorz Sandscalp Abilities

- Wide Slash [spell=11837]
- Cleave [spell=15496]
- Berserker Stance [spell=7366]

Chief Ukorz Sandscalp Strategy

Make sure to face these two away from the group. Melee should stay behind them to avoid the cleave. Kill Ruuzlu first.

Zerillis [npc=10082] is a level 45 rare-elite Sandury Troll that patrols throughout Zul'Farrak. 

Zerillis Abilities

- Frost Shot [spell=12551]
- Net [spell=6533]
- Shoot [spell=15547]

Zerillis Strategy

Pull him into melee range immediately (you might need to LoS). Simple tank and spank. 

Gahz'rilla [npc=7273] is a level 46 elite Hydra located at the end of Zul'Farrak. He is summoned by used the Mallet of Zul'Farrak [item=9240] on the gong near the aqueduct. 

Gahz'rilla Abilities

- Freeze Solid [spell=11836]
- Gahz'rilla Slam [spell=11902]
- Icicle [spell=11131]

Gahz'rilla Strategy

Make sure to clear out the room where Gahz'rilla is summoned from. Tank him with the tank's back against a wall and stack on the tank to prevent being thrown up into the air. The rest of the fight is a tank and spank. 

## Zul'Farrak Loot in World of Warcraft: Forever

Item | Type | 

Vice Grips [item=9640] | Plate Hands | 

Lifeblood Amulet [item=9641] | Neck | 

The Hand of Antu'sul [item=9639] | 1H Mace with Proc | 

Sang'thraze the Deflector [item=9379] | 1H Sword | 

Item | Type | 

Troll Sweat [item=1520] | 

Item | Type | 

Jumanza Grips [item=18083] | Cloth Hands | 

Zum'rah's Vexing Cane [item=18082] | Staff with Spell Damage | 

Item | Type | 

Bad Mojo Mask [item=9470] | Cloth Helm | 

Jinxed Hoodoo Skin [item=9473] | Leather Chest | 

Jinxed Hoodoo Kilt [item=9474] | Leather Legs | 

Diabolic Skiver [item=9475] | Polearm | 

Item | Type | 

Troll Sweat [item=1520] | 

Item | Type | 

Big Bad Pauldrons [item=9476] | Plate Shoulder | 

The Chief's Enforcer [item=9477] | Staff that Stuns | 

Ripsaw [item=9478] | 1H Axe | 

Embrace of the Lycan [item=9479] | Leather Helm | 

Jang'thraze the Protector [item=11086] (Rare) | 1H Sword | 

Item | Type | 

Sandstalker Ankleguards [item=12470] | Leather Feet | 

Item | Type | 

Gahz'rilla Fang [item=9467] | 1H Dagger | 

Gahz'rilla Scale Armor [item=9469] | Mail Chest | 

Several attractive, unique, and well-statted Bind-on-Equip items only drop in Zul'Farrak. 

Item | Type | 

Flaming Incinerator [item=9483] | Ranged Wand | 

Brainlash [item=6440] | Unique Finger | 

Runed Ring [item=862] | Finger | 

Bloodletter Scalpel [item=9511] | One-Handed Sword | 

The Minotaur [item=9481] | Two-Handed Axe | 

Witch Doctor's Cane [item=9482] | Two-Handed Staff | 

Gutwrencher [item=5616] | One-Handed Dagger | 

Blackmetal Cape [item=9512] | Back | 

Spellshock Leggings [item=9484] | Cloth Legs | 

Troll Protector [item=2040] | Off-Hand Shield | 

Eyegouger [item=9480] | Two-Handed Polearm that replaces Ice Barbed Spear [item=19106] after reaching level 51. |

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/zulfarrak und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **Antu'sul** [8127]: Antu'sul's Minion (11894), Healing Wave of Antu'sul (11895), Earthgrab Totem (8376), Flash Heal (10915), Chain Lightning (2860), Earth Shock (10413)
- **Witch Doctor Zum'rah** [7271]: Healing Wave (12491), Shadow Bolt (12739)
- **Nekrum Gutchewer & Shadowpriest Sezz'ziz** [7796, 7275]: Renew (8362), Shadow Bolt (15537)
- **Sergeant Bly** [7604]: Revenge (12170)
- **Hydromancer Velratha** [7795]: Shadow Bolt (12739), Shadow Bolt Volley (15245), Ward of Zum'rah (11086)
- **Chief Ukorz Sandscalp** [7267, 7797]: Berserker Stance (7366)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: keine

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist

## Abilities from other sources

Quelle: warcraft.wiki.gg (CC BY-SA 3.0, paraphrasiert). **classic-source, unverified for Forever.** Viele Seiten ohne Spell-IDs (IDs aus Wowhead-Journal oben).

| Boss (NPC) | Ability | Spell ID | Was es tut | Umgang | Confidence |
|---|---|---|---|---|---|
| Antu'sul (8127) | Earthgrab Totem, Healing Ward, Healing Wave, Earth Shock, Chain Lightning, Servant of Antu'sul | 8376 / - / 11895 / 10413 / 2860 / 11894 (Wowhead) | Wurzel-Totem (4 s alle 5 s, 30 s) / Heiltotem / Heilung / Interrupt + Natur / Kettenblitz auf 3 / Basilisk-Add bei 75% und 25% (Petrify: 3 s Betaeubung) | Totems sofort zerstoeren (Schurke/Pet), Add vor dem Boss toeten sonst 3-4 Elites; Start: 6 Basilisken stapeln + AoE oder per Pet aus der Hoehle ziehen | mittel |
| Witch Doctor Zum'rah (7271) | Ward of Zum'rah, Awaken Zul'farrak Zombie, Healing Wave, Shadow Bolt | 11086 (Wowhead) / - / 12491 / 12739 | Totem 20 s spawnt alle 5 s Skelett / Zombie aus Grab / Heilung / Schatten | Totem zerstoeren, Heal und Bolts kicken, Gruppe kann Graeber vorher oeffnen; Zombies furchten | mittel |
| Nekrum Gutchewer & Shadowpriest Sezz'ziz (7796/7275) | Shadow Bolt, Renew, Heal, Psychic Scream | 12739, 8362, 12039, 13704 | Schatten; HoT; Heilung; Furcht bis 5 Ziele 6 s | Heals/Bolts kicken, Furcht dispellen, spreizen; Nekrum-Faehigkeiten nicht gefunden | mittel |
| Sergeant Bly (7604) | Revenge, Shield Bash, Improved Blocking | 12170, 11972, 3639 | Gegenschlag nach Block/Ausweichen; Interrupt; +85% Blockchance 6 s | Caster nach Bash staffeln | mittel |
| Chief Ukorz Sandscalp (7267/7797) | Berserker Stance, Wide Slash, Cleave, Frenzy | 7366, 11837, 15496, 8269 | Haerter zuschlagende Haltung; Frontalkegel; Cleave auf 2 Ziele; Frenzy 2 min | Nur Tank vorne, Nahkaempfer verteilt, Frenzy entfernen/Cooldowns | mittel |
| Hydromancer Velratha (7795) | - | - | Wiki-Seite ist Retail-Cata-Version (Water Bolt 38669, Crashing Wave 79539), nicht uebertragbar | Wowhead: Shadow Bolt 12739, Volley 15245, Ward of Zum'rah 11086 | - |

URLs: https://warcraft.wiki.gg/wiki/Antu%27sul, /Witch_Doctor_Zum%27rah, /Shadowpriest_Sezz%27ziz, /Sergeant_Bly, /Chief_Ukorz_Sandscalp
