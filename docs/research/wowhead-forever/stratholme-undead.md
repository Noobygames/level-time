# Stratholme Undead - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=35324 (strat-undead)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/stratholme-undead


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/stratholme-undead

Journal: areaId (zone) 2017; level range from journal: 48-58; kind dungeon

Journal description: Once the jewel of northern Lordaeron, the city of Stratholme is where Prince Arthas turned against his mentor, Uther Lightbringer, and slaughtered hundreds of his own subjects who were believed to have contracted the dreaded plague of undeath. Arthas' downward spiral and ultimate surrender to the Lich King soon followed. The broken city is now inhabited by the undead Scourge -- led by the powerful lich, Kel'Thuzad. A contingent of Scarlet Crusaders, led by Grand Crusader Dathrohan, also holds a portion of the ravaged city. The two sides are locked in constant, violent combat. Those adventurers brave (or foolish) enough to enter Stratholme will be forced to contend with both factions before long. It is said that the city is guarded by three massive watchtowers, as well as powerful necromancers, banshees, and abominations. There have also been reports of a malefic Death Knight riding atop an unholy steed, dispensing indiscriminate wrath on all those who venture within the realm of the Scourge.

### Journal quests (id, level as shown, side)
- Ramstein [quest=6163] level 60, Horde
- The Flesh Does Not Lie [quest=5212] level 60, both
- Above and Beyond [quest=5263] level 60, both
- Houses of the Holy [quest=5243] level 60, both
- Aurius' Reckoning [quest=5125] level 60, both
- Menethil's Gift [quest=5463] level 60, both
- Dead Man's Plea [quest=8945] level 60, both

### Journal bosses

#### Magistrate Barthilas (NPC ids [10435])
Overview: The main ability you need to be aware of, especially while tanking, is Mighty Blow, as it will knock you back a few yards, potentially into more mobs, making the fight harder for you and your group. To counter this, the tank should keep their back to a wall, and they will be knocked straight upwards rather than backward.
- Draining Blow [spell=16793]: Drains 250 health from an enemy, transferring it to the caster.
- Crowd Pummel [spell=10887]: Pummels nearby enemies for normal damage plus 10 and interrupts any spell being cast 75% of the time for 5 sec.
- Furious Anger [spell=16791]: 
- Mighty Blow [spell=14099]: Inflicts normal damage plus 25 to an enemy, knocking it back.
Loot: Key to the City [item=12382]

#### Nerub'enkan (NPC ids [10437])
Overview: AoE down the adds that are summoned. The healer and tank should watch for Pierce Armor and coordinate small defensive abilities and some more focused healing on the tank, but apart from that, it is a simple fight.
- Raise Undead Scarab [spell=17235]: 
- Encasing Webs [spell=4962]: Immobilizes an enemy and increases the time between its attacks by 100% for 6 sec.
- Pierce Armor [spell=6016]: Reduces an enemy's armor by 50% for 20 sec. | note: The tank will take much more damage while this debuff is up, so be ready to use cooldowns if needed.

#### Baroness Anastari (NPC ids [10436])
Overview: When a player gets possessed, DPS them down to 50% to remove it. The healer and casters should try to keep their distance from the boss to avoid being silenced.
- Possess [spell=17244]: Takes control of a humanoid enemy up to level 100 for 2 min. and increases its maximum health by 2000%. | note: This mind-control effect is removed when the target is reduced to 50%. Be careful not to accidentally kill them.
- Banshee Wail [spell=16565]: Wails with anguish, inflicting Shadow damage to an enemy.
- Banshee Curse [spell=16867]: Reduces nearby enemies' chance to hit with attacks by 10% for 12 sec.

#### Maleki the Pallid (NPC ids [10438])
Overview: The only mechanic you need to worry about in this encounter is Ice Tomb. Maleki will stun his target, usually the tank, for 10 seconds. When this happens, DPS will need to be careful with threat, and the healer will have to heal more.
- Ice Tomb [spell=16869]: Stuns an enemy, rendering it unable to move or attack for 10 sec.
- Drain Life [spell=17620]: Drains 240 health from an enemy over 5 sec., transferring it to the caster.
- Frostbolt [spell=13322]: Inflicts Frost damage to an enemy and reduces its movement speed for 2 sec.

#### Ramstein the Gorger (NPC ids [10439])
Overview: Ramstein spawns after killing all of the patchwork mobs in the area. The entry gate locks when Ramstein spawns, so make sure the group is inside. The encounter itself is largely tank-and-spank; just be aware that when he casts Knockout on the tank, he will often switch aggro to a DPS until the tank can recover.
- Knockout [spell=17307]: Inflicts normal damage plus 300 to an enemy, knocking it back and stunning it for 6 sec.
- Trample [spell=5568]: Inflicts normal damage plus 8 to nearby enemies.
- Flurry [spell=17687]: 
Loot: Frayed Abomination Stitching [item=12735], Head of Ramstein the Gorger [item=15880]

#### Baron Rivendare (NPC ids [10440])
Overview: This is the hardest encounter in Strat Undead. He is able to reduce healing on the tank, deal consistent AoE damage to nearby players with his aura, and cleave. He will also summon skeleton mobs throughout the fight, which can be cleaved down quite easily, but if they are left unchecked, they will cause havoc in the group. The tank should pull Baron to one side of the room, and the ranged DPS and healer should go to the opposite side to out-distance his Unholy Aura. DPS should kill the adds as they spawn; the tank can ignore them as they don't deal much damage.
Role notes: tank: Pull the boss to one side of the room and let the DPS deal with the summoned skeletons.; healer: Run to the opposite side of the room from the tank and be ready to heal through a lot of AoE damage.; damage: Switch to the adds when they are summoned. Ranged DPS should be on the opposite side of the room from the tank, and melee should be behind the boss.
- Mortal Strike [spell=16856]: Inflicts 200% weapon damage and leaves the target wounded, reducing the effectiveness of any healing by 50% for 5 sec.
- Cleave [spell=15496]: Inflicts weapon damage plus 10 to an enemy and its nearest ally.
- Unholy Aura [spell=17467]: Causes the caster to automatically inflict 150 Shadow damage every 2 sec. to nearby enemies. The aura lasts until cancelled.
- Shadow Bolt [spell=17393]: Hurls a bolt of dark magic at an enemy, inflicting Shadow damage.

#### Stonespine (Rare) (NPC ids [10809])
Overview: This encounter has no mechanics; simply tank and kill him.
- Vicious Rend [spell=14331]: Inflicts Physical damage to an enemy every 3 sec. for 15 sec.

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Baroness Anastari: npcs[] spells[Banshee Curse updated: Wording changed] newSpells[] loot[]


## Guide text
Source: https://www.wowhead.com/forever/guide=35324

Stratholme [zone=2017] is located in Eastern Plaguelands. This guide provides tips and strategies for completing the Live Side of the Stratholme dungeon, including everything you need before and during the dungeon, quests to complete inside, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## Stratholme Undead Side Overview in World of Warcraft: Forever

Once the jewel of northern Lordaeron, the city of Stratholme is where Prince Arthas turned against his mentor, Uther Lightbringer, and slaughtered hundreds of his own subjects who were believed to have contracted the dreaded plague of undeath. Arthas' downward spiral and ultimate surrender to the Lich King soon followed. The broken city is now inhabited by the undead Scourge -- led by the powerful lich, Kel'Thuzad. A contingent of Scarlet Crusaders, led by Grand Crusader Dathrohan, also holds a portion of the ravaged city. The two sides are locked in constant, violent combat. Those adventurers brave (or foolish) enough to enter Stratholme will be forced to contend with both factions before long. It is said that the city is guarded by three massive watchtowers, as well as powerful necromancers, banshees and abominations. There have also been reports of a malefic Death Knight riding atop an unholy steed, dispensing indiscriminate wrath on all those who venture within the realm of the Scourge.

The recommended level for Stratholme Undead Side is between 55 and 60. In-game players usually refer to Stratholme Undead Side as "Strat Undead." 

## Location of Stratholme Undead Side in World of Warcraft: Forever

Stratholme is divided into two sections, commonly referred to as Strat Undead and Strat Live, based on the mobs present in each half. It is located in the northwest of Eastern Plaguelands [zone=139]. To get there as either Horde or Alliance, fly to Lights Hope Chapel and run northwest. The entrance for Strat Undead is east of the entrance to Strat Live.

Stratholme Live Entrance
Stratholme Undead Entrance

As with many World of Warcraft: Forever Dungeons, wiping (the entire group dying) in Stratholme Undead Side can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. Druids only have an in-combat resurrection spell and are unlikely to train it before Stratholme Undead Side.

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer as a ghost. You collect your body when you enter the instance.

## Every Quest in Stratholme Undead Side in World of Warcraft: Forever

Hard: Level 54 | Medium: Level 56 | At Level: Level 60

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

Ramstein [quest=6163] | 56 |  |  | Pre | Eastern Plaguelands, Marris Stead - Nathanos Blightcaller [npc=11878] /way 26 74
Complete 4 quests, starting withThe Ranger Lord's Behest [quest=6133] andTo Kill With Purpose [quest=6022] | 

Houses of the Holy [quest=5243] | 55 | - |  |   | Eastern Plaguelands, Light's Hope Chapel - Leonid Barthalomew the Revered [npc=11036] /way 81 57 | 

The Flesh Does Not Lie [quest=5212] | 55 | - |  | Pre | Eastern Plaguelands, Light's Hope Chapel - Betina Bigglezink [npc=11035] /way 81 59 | 

The Active Agent [quest=5213] | 55 | - |  |   | Eastern Plaguelands, Light's Hope Chapel - Betina Bigglezink [npc=11035] /way 81 59
CompleteThe Flesh Does Not Lie [quest=5212] first | 

Aurius' Reckoning [quest=5125] | 55 | - |  | Pre  | Stratholme, Undead Side - Aurius [npc=10917] in chapel at beginning
CompleteThe Medallion of Faith [quest=5122] first | 

Above and Beyond [quest=5263] | 55 | - |  | Pre  | Eastern Plaguelands, Light's Hope Chapel - Duke Nicholas Zverenhoff [npc=11039] /way 81 59
Complete 2 quests staring withThe Archivist [quest=5251] | 

Menethil's Gift [quest=5463] | 57 | - |  | Pre  | Eastern Plaguelands, Light's Hope Chapel - Leonid Barthalomew the Revered [npc=11036] /way 81 57
Complete 5 quests, starting withDoctor Theolen Krastinov, the Butcher [quest=5382] first | 

Dead Man's Plea [quest=8945] | 58 | - |  | Pre  | Eastern Plaguelands, Stratholme Main Entrance - Anthion Harmon [npc=16016] /way 30 16
Complete 9 quests, starting withA Supernatural Device [quest=8923] /A Supernatural Device [quest=8922]. Requires Extra-Dimensional Ghost Revealer [item=22115] to see quest NPC | 

Completing Dungeon Quests in World of Warcraft: Forever is a great way to gain some extra experience and gear. You will find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

The quests below include where to collect them, any prerequisites you need to complete first, and what you need to do inside or around Stratholme Undead Side.

Faction: Alliance and Horde
Level Required: 55
Rewards:

- 6,600 experience
- 100 reputation with Argent Dawn {/forever/faction=529/argent-dawn}

This quest can be picked up from Betina Bigglezink [npc=11035] at Lights Hope Chapel. It requires you to loot 20xPlagued Flesh Sample [item=13174] from undead NPCs, these can even drop off bosses though because there are so many required may take you a few runs to finish. It leads into a follow up quest The Active Agent [quest=5213].

Betina Bigglezink [npc=11035]

Faction: Alliance and Horde
Level Required: 55
Rewards:

- 6,600 experience
- 100 reputation with Argent Dawn {/forever/faction=529/argent-dawn}
- Rune of the Dawn [item=19812] or Seal of the Dawn [item=13209]

This quest is a follow up to The Flesh Does Not Lie [quest=5212] which you can get from Betina Bigglezink [npc=11035] at Lights Hope Chapel. You will need to find some Scourge Data [item=13176] which can spawn in 1 out of the 3 ziggurats inside the instance. It is in a small metal container and you can simply loot this and return to Betina.

Betina Bigglezink [npc=11035]

Faction: Alliance and Horde
Level Required: 55
Rewards:

- 8,300 experience
- 150 reputation with Argent Dawn {/forever/faction=529/argent-dawn}

Above and Beyond [quest=5263] can be picked up from Duke Nicholas Zverenhoff [npc=11039] at Lights Hope Chapel. It requires you to loot Head of Baron Rivendare [item=13251] from Baron Rivendare [npc=10440] which is the last boss in the dungeon. It has a prerequisite The Truth Comes Crashing Down [quest=5262] which can be found in the Stratholme Living side. 

Duke Nicholas Zverenhoff [npc=11039]

Faction: Alliance and Horde
Level Required: 55
Rewards:

- 6,600 experience
- Crown of the Penitent [item=13216], Band of the Penitent [item=13217] and both 5xSuperior Healing Potion [item=3928]/Greater Mana Potion [item=6149]
- 100 reputation with Argent Dawn {/forever/faction=529/argent-dawn}

Houses of the Holy [quest=5243] can be picked up from Leonid Barthalomew the Revered [npc=11036] at Lights Hope Chapel. It requires you to loot Stratholme Holy Water [item=13180] from wooden crates located throughout the dungeon. These crates also have a chance to be empty, only spawning aggressive rats.

Leonid Barthalomew the Revered [npc=11036]

Faction: Alliance and Horde
Level Required: 55
Rewards:
This quest has no rewards but unlocks the quest Aurius' Reckoning [quest=5125] which does have rewards.

The Medallion of Faith [quest=5122] requires you to bring a Medallion of Faith [item=12845] to Aurius [npc=10917]. You will find him at the beginning of the UD side entrance in the burning chapel. The item Medallion of Faith [item=12845] is found in the living side of Stratholme [zone=2017] in a chest behind the boss Malor the Zealous [npc=11032]. You may have already looted this if you have done the living side prior.

Faction: Alliance and Horde
Level Required: 55
Rewards:

- 9,950 experience
- Will of the Martyr [item=17044] or Blood of the Martyr [item=17045]

Aurius' Reckoning [quest=5125] requires you to have completed The Medallion of Faith [quest=5122] which requires you to bring a Medallion of Faith [item=12845] to Aurius [npc=10917]. You will find him at the beginning of the UD side entrance in the burning chapel. The item Medallion of Faith [item=12845] is found in the living side of Stratholme [zone=2017] in a chest behind the boss Malor the Zealous [npc=11032]. Aurius' Reckoning [quest=5125] requires you to kill the last boss Baron Rivendare [npc=10440]. Once you have completed it Aurius [npc=10917] will appear at the end of the dungeon and offer the turn in and rewards.

Faction: Horde
Level Required: 56
Rewards:

- 6,600 experience
- Royal Seal of Alexis [item=18022] or Elemental Circle [item=17001]
- 100 reputation with Undercity {/forever/faction=68/undercity}

Nathanos Blightcaller [npc=11878]

Ramstein [quest=6163] is a Horde only quest which starts with Nathanos Blightcaller [npc=11878] at his house located at 26.5, 74.7 in Eastern Plaguelands [zone=139]. You will need to complete a few pre-quests to unlock this which are: The Ranger Lord's Behest [quest=6133] and Duskwing, Oh How I Hate Thee... [quest=6135]. 

1. The Ranger Lord's Behest [quest=6133] requires you to 8x Pathstrider [npc=8565], Ranger [npc=8564], Woodsman [npc=8563] and loot the Quel'Thalas Registry [item=15847]. You will find the registry as you enter the lodge on your right. It is a small book sitting on a table.

Pathstrider [npc=8565]
Quel'Thalas Registry

2. Duskwing, Oh How I Hate Thee... [quest=6135] requires you to kill Duskwing [npc=11897] and loot Patch of Duskwing's Fur [item=15850] from him. You may need a few other players to be able to do this quest. He roams around the area you pick the quest up from.

Duskwing [npc=11897]
Duskwing

3. Once you have completed this quest you will be able to pick up Ramstein [quest=6163] which simply requires you to go into Strathholme and kill Ramstein the Gorger [npc=10439] and loot Head of Ramstein the Gorger [item=15880]. He is the 2nd last boss and will spawn once you have killed all of the other Abominations outside of Baron Rivendare's keep.

Faction: Alliance and Horde
Level Required: 57
Rewards:

- Penelope's Rose [item=15805] or Mirah's Song [item=15806] and Spectral Essence [item=13544] (from quests along the way)
- 9,950 experience

Menethil's Gift [quest=5463] is a few quests into a quest chain which starts with Eva Sarkhoff [npc=11216] in Western Plaguelands [zone=28]. The quest is Doctor Theolen Krastinov, the Butcher [quest=5382] and will send you on a long quest chain to which ends at The Lich, Ras Frostwhisper [quest=5466] which rewards some nice items depending on your class. To complete Menethil's Gift [quest=5463] once you are at that step, you simply use Keepsake of Remembrance [item=13585] on the orange symbol on the floor near Baron Rivendare [npc=10440]. 

Eva Sarkhoff [npc=11216]

1. She will not offer any quests until you have listened to her story, so speak with her and go through all the options. After that she will offer Doctor Theolen Krastinov, the Butcher [quest=5382] which sends you into the dungeon Scholomance to slay Doctor Theolen Krastinov [npc=11261] and burn Remains of Eva Sarkhoff [object=176544] and Remains of Lucien Sarkhoff [object=176545]. 
2. With the quest complete you can return to Eva and pick up Krastinov's Bag of Horrors [quest=5515] which sends you back into Scholomance to obtain Krastinov's Bag of Horrors [item=13725] which drops from Jandice Barov [npc=10503].
3. With that quest complete you can pick up Kirtonos the Herald [quest=5384] from Eva. You will need to loot Blood of Innocents [item=13523] which can drop from Blood Steward of Kirtonos [npc=14861], Blood Steward of Kirtonos [npc=14861] and Jandice Barov [npc=10503] then use that item to summon Kirtonos the Herald [npc=10506].
4. Completing these 3 quests will give you Spectral Essence [item=13544] which allows you to see ghosts in certain zones which allows you to pick up the next quest in this chain The Human, Ras Frostwhisper [quest=5461]. You can pick this up from Magistrate Marduke [npc=11286] which can be found in the same town outside of Scholomance. This quest sends you to Arathi Highlands [zone=45] to retrieve Keepsake of Remembrance [item=13585] which can spawn in any of the houses in Stormguard Keep. It has a higher chance to spawn in the houses with a fireplace.

Magistrate Marduke [npc=11286]

5. Once you have the book you can return to Magistrate Marduke [npc=11286] to get the follow up The Dying, Ras Frostwhisper [quest=5462] which will send you to Lights Hope Chapel to speak with Leonid Barthalomew the Revered [npc=11036]. He will give you the quest for the Stratholme dungeon Menethil's Gift [quest=5463].

Leonid Barthalomew the Revered [npc=11036]

6. To complete Menethil's Gift [quest=5463] once you are at that step, you simply use Keepsake of Remembrance [item=13585] on the orange symbol on the floor near Baron Rivendare [npc=10440]. 
7. Once you have completed Menethil's Gift [quest=5463] you will get Menethil's Gift [quest=5464] from the orange circle which will send you back to Leonid Barthalomew the Revered [npc=11036].

### Best Quest Rewards

Item | Type | Quest | 

Crown of the Penitent [item=13216] |  Cloth Head |  Houses of the Holy | 

## Stratholme Undead Side Layout in World of Warcraft: Forever
You will enter at B and be inside a corridor with a locked gate. This is usually where everyone buffs up and get ready as it is a safe spot until the gate is opened.

## Stratholme Undead Side Bosses in World of Warcraft: Forever

The first boss you may encounter is Magistrate Barthilas [npc=10435]. He has a chance to spawn both at the church near the start and not despawn, or he will be alerted and run to his second spot near the end of the instance. He is number 12 on the map.

He has four key abilities:

- Draining Blow [spell=16793]
- Crowd Pummel [spell=10887]
- Furious Anger [spell=16791]
- Mighty Blow [spell=14099]

The main ability you need to be aware of, especially while tanking is Mighty Blow [spell=14099] as it will knock you back a few yards potentially into more mobs, making the fight harder for you and your group. To counter this simply face your back to a wall and you will be knocked straight upwards rather than backward.

Stonespine [npc=10809] is a rare spawn NPC that spawns at 14 on the map and paths and and down that section. He has no real notable mechanics or abilities apart from Vicious Rend [spell=14331]. Though he does drop some decent gear.

Nerub'enkan [npc=10437] spawns at number 16 on the map, north west of where you enter the gauntlet. Generally you will make your way to this boss first. He has a few annoying abilities:

- Crypt Scarabs [spell=16418]
- Encasing Webs [spell=4962]
- Pierce Armor [spell=6016]
- Raise Undead Scarab [spell=17235]

As a DPS cleave down the extra mobs he spawns, they wont do much damage and you will likely pull aggro due to the tank being snared or already under pressure. Healers/tanks should watch for Pierce Armor [spell=6016] and coordinate small defensive abilities and some more focused healing on the tank but apart from that it is a simple fight. 

When you have killed him make your way into the room behind him filled with Thuzadin Acolyte [npc=10399]s, make sure you kill them all as this unlocks a gate later on in the dungeon.

Black Guard Swordsmith [npc=11121] is a mini boss that can be summoned by clicking on the blacksmithing plans on the ground right of Baroness Anastari [npc=10436]. He doesn't have any mechanics or drop any unique loot apart from Bottom Half of Advanced Armorsmithing: Volume III [item=18783] for Blacksmiths.

Baroness Anastari [npc=10436] spawns at number 15 on the map and is the next boss you will face. She doesn't do a lot of damage herself but with her annoying kit of abilities it can make the fight quite a nuisance. Her abilities are:

- Banshee Curse [spell=16867]
- Banshee Wail [spell=16868]
- Possess [spell=17244]
- Silence [spell=18327]

She will cast Possess [spell=17244] on players throughout the fight which can be broken by getting the possessed player to 50% health. She will also silence casters and put a curse on players to reduce their hit chance. 

When you have killed her make your way into the room behind her filled with Thuzadin Acolyte [npc=10399]s, make sure you kill them all as this unlocks a gate later on in the dungeon.

Maleki the Pallid [npc=10438] is down the path north of Baroness Anastari [npc=10436] he is located at 17 on the map and has a few annoying abilities:

- Drain Life [spell=17620]
- Frostbolt [spell=13322]
- Ice Tomb [spell=16869]

Generally he will entomb the tank in the Ice Tomb [spell=16869] which lasts for 6 seconds, during this time healers and DPS should be aware of pulling aggro and play. That is the only mechanic you need to worry about on this fight. 

When you have killed him make your way into the room behind him filled with Thuzadin Acolyte [npc=10399]s, make sure you kill them all as this unlocks a gate later on in the dungeon.

The next boss Ramstein the Gorger [npc=10439] is located at 18 on the map and will spawn after you kill all the patchwork mobs in this room who can drop Frayed Abomination Stitching [item=12735]. If you are tanking this, I would advise letting your group know you to get past the gate that leads into the room because it will lock when you start to pull these mobs. Also, it is best to only pull one of these at a time as they can deal a decent amount of damage and spawn extra mobs themselves.

Once you have cleared the room of all the patchwork mobs you will spawn Ramstein the Gorger [npc=10439]. He is basically a tank and spank with aggro swap mechanics. These are his abilities:

- Flurry [spell=17687]
- Knockout [spell=17307]
- Trample [spell=5568]

He will cast Knockout [spell=17307] on the tank and swap aggro also using Trample [spell=5568] along the way. You should just be wary of this and have some heals ready for your DPS'ers as a healer.

The final boss of Stratholme [zone=2017] undead is Baron Rivendare [npc=10440]. He can be fairly difficult if you don't have a good strategy to beat him. His abilities are:

- Cleave [spell=15496]
- Mortal Strike [spell=16856]
- Shadow Bolt [spell=17393]
- Unholy Aura [spell=17467]

With this kit, he is able to reduce healing on the tank, and deal consistent AoE damage to nearby players with his aura and cleave. He will also summon some skeleton mobs throughout the fight, which can be cleaved down quite easily but left unchecked will cause havoc in the group.

Being a tank that has done this fight numerous times, I would advise this strategy. Buff up outside, let everyone know you are about to run in, as the door will close when you pull Baron Rivendare [npc=10440]. As a tank, run to your right and pull him to the right side of the room, the melee will follow suit and the ranged DPS and healer will go to the left side of the room and stand on the bone piles. This will allow all your ranged to avoid the Unholy Aura [spell=17467], making the fight a lot easier on the healer. Melee should also be standing behind the boss to avoid his cleave. When the skeleton mobs spawn as a DPS, they are your primary focus; the tank shouldn't have to worry about picking all of these up as they die fairly quickly. Maintain the distance to avoid the aura as much as you can, and this fight is a lot easier.

## Stratholme Undead Side Loot in World of Warcraft: Forever

Item | Type | 

Idol of Brutality [item=23198] | Druid {/forever/class=11/druid} Relic  | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Peacemaker [item=18725] | Polearm | 

Magistrate's Cuffs [item=18726] | Leather Wrist | 

Death Grips [item=18722] | Plate Gloves | 

Crimson Felt Hat [item=18727] | Cloth Helm | 

Royal Tribunal Cloak [item=13376] | Cloak | 

Key to the City [item=12382] | Key | 

Item | Type | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Verdant Footpads [item=13954] | Leather Feet | 

Stoneskin Gargoyle Cape [item=13397] | Cloak | 

Gargoyle Shredder Talons [item=13399] | Fist Weapons | 

Item | Type | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Beaststalker's Boots [item=16675] | T0 Hunter Set Boots | 

Carapace Spine Crossbow [item=18738] | Crossbow | 

Chitinous Plate Legguards [item=18739] | Plate Legs | 

Husk of Nerub'enkan [item=13529] | Shield | 

Thuzadin Sash [item=18740] | Cloth Waist | 

Crypt Stalker Leggings [item=13531] | Leather Resistance Legs | 

Fangdrip Runners [item=13530] | Cloth Resistance Feet | 

Darkspinner Claws [item=13532] | Mail Resistance Gloves | 

Acid-etched Pauldrons [item=13533] | Plate Resistance Shoulders | 

Eye of Arachnida [item=13508] | Eye of Kilrogg | 

Item | Type | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Anastari Heirloom [item=18728] | Amulet | 

Banshee Finger [item=13534] | Wand | 

Dreadmist Sandals [item=16704] | T0 Warlock Set Feet | 

Screeching Bow [item=18729] | Bow | 

Shadowy Laced Handwraps [item=18730] | Cloth Hands | 

Windshrieker Pauldrons [item=13538] | Mail Resistance Shoulders | 

Banshee's Touch [item=13539] | Plate Resistance Hands | 

Wail of the Banshee [item=13514] | Item that reduces enemy chance to hit | 

Chillhide Bracers [item=13537] | Leather Resistance Wrists | 

Coldtouch Phantom Wraps [item=13535] | Cloth Resistance Chest | 

Item | Type | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Bone Slicing Hatchet [item=18737] | 1H Axe | 

Devout Sandals [item=16691] | T0 Priest Set Feet | 

Maleki's Footwraps [item=18735] | Cloth Feet | 

Pale Moon Cloak [item=18734] | Cloak | 

Plans: Hammer of the Titans [item=12833] | Blacksmithing Plan | 

Skull of Burning Shadows [item=13524] | Offhand | 

Clutch of Foresight [item=13509] | Silence Item | 

Flamescarred Girdle [item=13526] | Leather Resistance Belt | 

Darkbind Fingers [item=13525] | Cloth Resistance Hands | 

Lavawalker Greaves [item=13527] | Plate Resistance Feet | 

Twilight Void Bracers [item=13528] | Mail Resistance Wrist | 

Item | Type | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Band of Flesh [item=13373] | Ring | 

Frayed Abomination Stitching [item=12735] | Needed for Arcanum of Protection [item=18331] | 

Animated Chain Necklace [item=18723] | Amulet | 

Crest of Retribution [item=13375] | Shield | 

Gauntlets of Valor [item=16737] | T0 Warrior Set Gloves | 

Ramstein's Lightning Bolts [item=13515] | Trinket | 

Slavedriver's Cane [item=13372] | Staff | 

Soulstealer Mantle [item=13374] | Cloth Shoulders | 

Item | Type | 

Thuzadin Mantle [item=22412] | Cloth Shoulder  | 

Tunic of the Crescent Moon [item=22409] | Leather Chest  | 

Gauntlets of Deftness [item=22410] | Mail Gloves  | 

Helm of the Executioner [item=22411] | Plate Helm  | 

Ritssyn's Wand of Bad Mojo [item=22408] | Wand  | 

Deathcharger's Reins [item=13335] | Mount | 

Runeblade of Baron Rivendare [item=13505] | 2H Sword | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Scepter of the Unholy [item=13349] | 1H Mace | 

Dracorian Gauntlets [item=13344] | Mail Gloves | 

Seal of Rivendare [item=13345] | Ring | 

Cape of the Black Baron [item=13340] | Cloak | 

Robes of the Exalted [item=13346] | Cloth Chest | 

Skullforge Reaver [item=13361] | 1H Sword | 

Bonescraper [item=13368] | Dagger | 

Wildheart Kilt [item=16719] | T0 Druid Set Legs | 

Beaststalker's Pants [item=16678] | T0 Hunter Set Legs | 

Magister's Leggings [item=16687] | T0 Mage Set Legs | 

Lightforge Legplates [item=16728] | T0 Paladin Set Legs | 

Devout Skirt [item=16694] | T0 Priest Set Legs | 

Shadowcraft Pants [item=16709] | T0 Rogue Set Legs | 

Kilt of Elements [item=16668] | T0 Shaman Set Legs | 

Dreadmist Leggings [item=16699] | T0 Warlock Set Legs | 

Legplates of Valor [item=16732] | T0 Warrior Set Legs | 

It is worth noting that the Bind-on-Equip items that drop can be found from trash mobs except for Gauntlets of Valor [item=16737] which drops from Ramstein the Gorger [npc=10439]. 

Item | Type | 

Wildheart Bracers [item=16714] | Leather Wrist | 

Bindings of Elements [item=16671] | Mail Wrist | 

Morlune's Bracer [item=18741] | Plate Wrist | 

Magister's Belt [item=16685] | Cloth Waist | 

Dreadmist Belt [item=16702] | Cloth Waist | 

Lightforge Belt [item=16723] | Plate Waist | 

Juno's Shadow [item=17061] | Back | 

Devout Bracers [item=16697] | Cloth Wrist | 

Shadowcraft Bracers [item=16710] | Leather Wrist | 

Beaststalker's Bindings [item=16681] | Mail Wrist | 

Belt of Valor [item=16736] | Plate Waist | 

Plaguebat Fur Gloves [item=18744] | Leather Hands | 

Sacred Cloth Leggings [item=18745] | Cloth Legs | 

Stratholme Militia Shoulderguard [item=18742] | Mail Shoulders | 

Gracious Cape [item=18743] | Back | 

Gauntlets of Valor [item=16737] | Plate Hands  | 
 
Plaguehound Leggings [item=18736] | Leather Legs |

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/stratholme-undead und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **Baroness Anastari** [10436]: Banshee Wail (16565)
- **Ramstein the Gorger** [10439]: Flurry (17687)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: keine

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist
