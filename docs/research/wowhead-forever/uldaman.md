# Uldaman - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=34966 (uldaman)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/uldaman


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/uldaman

Journal: areaId (zone) 1337; level range from journal: 42-52; kind dungeon

Journal description: Uldaman is an ancient Titan vault that has laid buried deep within the earth since the world's creation. Dwarven excavations have recently penetrated this forgotten city, releasing the Titans' first failed creations: the Troggs. Legends say that the Titans created troggs from stone. When they deemed the experiment a failure, the Titans locked the troggs away and tried again - resulting in the creation of the dwarven race. The secrets of the dwarves' creation are recorded on the fabled Discs of Norgannon - massive Titan artifacts that lie at the very bottom of the ancient city. Recently, the Dark Iron dwarves have launched a series of incursions into Uldaman, hoping to claim the discs for their fiery master, Ragnaros. However, protecting the buried city are several guardians - giant constructs of living stone that crush any hapless intruders they find. The Discs themselves are guarded by a massive, sapient Stonekeeper called Archaedas. Some rumors even suggest that the dwarves' stone-skinned ancestors, the earthen, still dwell deep within the city's hidden recesses.

### Journal quests (id, level as shown, side)
- Reclaimed Treasures [quest=2342] level 43, Horde
- Uldaman Reagent Run [quest=2202] level 42, Horde
- Necklace Recovery [quest=2283] level 41, Horde
- Reclaimed Treasures [quest=1360] level 43, Alliance
- The Lost Dwarves [quest=2398] level 40, Alliance
- The Hidden Chamber [quest=2240] level 40, Alliance
- Uldaman Reagent Run [quest=17] level 42, Alliance
- Agmond's Fate [quest=704] level 38, Alliance
- The Lost Tablets of Will [quest=1139] level 45, Alliance
- The Shattered Necklace [quest=2198] level 41, Alliance
- Power Stones [quest=2418] level 36, both
- Solution to Doom [quest=709] level 40, both
- The Platinum Discs [quest=2278] level 47, both
- Power in Uldaman [quest=1956] level 40, both

### Journal bosses

#### The Lost Dwarves (NPC ids [6906, 6907, 6908])
Overview: Baelog, Eric "The Swift", and Olaf make up The Lost Dwarves. They are friendly to the Alliance, but hostile to the Horde. Most groups tend to crowd control Baelog, have their tank pick up Olaf, and burst down Eric "The Swift" as he can cast Intercept on party members, which results in a pesky stun. Once Eric "The Swift" is done for, move on to Olaf while keeping Baelog CC'd. As long as the room is clear and there aren't any additional adds during the encounter, you shouldn't have much trouble with The Lost Dwarves.
Role notes: tank: Clear the room before starting the boss encounter.; damage: CC Baelog and kill Eric, then Olaf, then Baelog.
- Intercept [spell=20252]: Charge an enemy, causing 25 damage and stunning it for 3 sec.
- Shield Slam [spell=8242]: Inflicts 20 damage to an enemy, stunning it for 2 sec.
Loot: Worn Running Boots [item=9398], Battered Viking Shield [item=9403], Baelog's Shortbow [item=9400], Olaf's All Purpose Shield [item=9404], Nordic Longshank [item=9401], Horned Viking Helmet [item=9394]

#### Revelosh (NPC ids [6910])
Overview: Revelosh is linked with two [npc=4851], so when you pull him, they will also join the battle. You could try to CC one of the Stonevault Rockchewers if you can. Otherwise, try to burn down Revelosh as quickly as possible. His Chain Lightning can deal a lot of damage to your party, so take priority in interrupting whenever he gets ready to cast it.
Role notes: damage: CC the Rockchewers if you can and focus on Revelosh.
- Chain Lightning [spell=16033]: Strikes an enemy with a lightning bolt that arcs to another nearby enemy. The spell affects up to 20 targets, inflicting greater Nature damage to each successive target. | note: Spread out and interrupt this to reduce the damage Revelosh deals.
- Lightning Bolt [spell=9532]: Blasts an enemy with lightning, inflicting Nature damage.
Loot: The Shaft of Tsol [item=7741], Revelosh's Gloves [item=9390], Revelosh's Boots [item=9387], Revelosh's Spaulders [item=9389], Revelosh's Armguards [item=9388]

#### Ironaya (NPC ids [7228])
Overview: Ironaya is a level 40 giant found in Uldaman. To summon her, you need to combine [item=7740] from the chest behind The Lost Dwarves and [item=7741], a drop from Revelosh. Designate one player to loot and combine the two pieces to form the [item=7733] and place it in the model of a city-looking keystone within the next room. Ironaya has high armor, lots of HP, is immune to damage-over-time (DoT) effects, and can knock players back. Have your tank pick her up and face her away from the rest of the group to avoid her Arcing Smash. Ranged, spread out. Keeping her abilities in mind, it's a fairly straightforward tank & spank type fight.
Role notes: tank: Face the boss away from your group.
- Arcing Smash [spell=8374]: Lashes out in a vicious arc, inflicting damage to enemies in a cone in front of the caster.
- War Stomp [spell=45]: Knocks nearby enemies back.
- Knock Away [spell=18670]: Inflicts normal damage plus 30 to an enemy and knocks it back.
Loot: Ironshod Bludgeon [item=9408], Stoneweaver Leggings [item=9407], Ironaya's Bracers [item=9409]

#### Obsidian Sentinel (NPC ids [7023])
Overview: Similar to the [npc=4860] mobs that you fought on your way to [npc=7206], he's got high armor, high HP, and DoT immunity. At 66% and 33% health, he will spawn two non-elite [npc=7209]. Groups typically kill the two Shards first, then return to the boss.
Role notes: damage: Kill the Shards when they spawn.
- Splintered Obsidian [spell=10072]: 
- Summon Obsidian Shard [spell=10061]:  | note: Obsidian Shards spawn when the boss hits 66% and 33% health.

#### Ancient Stone Keeper (NPC ids [7206])
Overview: Similar to the [npc=7206] boss fight and [npc=4860] mobs that you fought along your way, he's also got high armor, high HP, DoT immunity, and a nasty AoE slow & silence ability: Sand Storms.
- Sand Storms [spell=10094]: Summons 1 Sand Storm to aid the caster in battle for 30 sec.
- Harsh Winds [spell=10093] (npc=7226):  | note: Casters and healers should stay away from the boss to avoid being silenced by the summoned Sand Storm.
Loot: Rockshard Pauldrons [item=9411], Cragfists [item=9410]

#### Galgann Firehammer (NPC ids [7291])
Overview: Galgann Firehammer awaits you with two [npc=7030] by his side. Between these 3 NPCs, there's a lot of AoE magic damage flying around. Tanks, pick up Galgann Firehammer and separate him from the group, keeping him facing away. CC one Geologist, kill the other one, then kill the one that was CC'd. Once both are dead, focus on Galgann Firehammer. His range of fire attacks can be devastating. If able to, dispel the debuffs that he'll cast on your party as they will amplify his fire damage.
Role notes: healer: Dispel the magical debuffs he applies if you can.; damage: CC or kill the Geologists first, before focusing on Galgann.
- Amplify Flames [spell=9482]: Increases the Fire damage taken by an enemy by 100 for 30 sec.
- Fire Nova [spell=11969]: Inflicts Fire damage to nearby enemies.
- Flame Shock [spell=8053]: Instantly sears the target with fire, causing 101 Fire damage immediately and 96 Fire damage over 12 sec.
- Flame Lash [spell=3356]: Burns an enemy for 28 to 32 damage and reduces its Fire resistance by 10 for 45 sec.
Loot: Emberscale Cape [item=11311], Galgann's Firehammer [item=9419], Galgann's Fireblaster [item=9412], Flameseer Mantle [item=11310]

#### Grimlok (NPC ids [4854])
Overview: Grimlok comes with a [npc=4853], [npc=4855], and a [npc=4863] grouped together. Many groups will opt to burn down Grimlok as quickly as possible, while CCing one of the adds. Killing Grimlok quickly can result in him dying before being able to cast his group Shrink. After he dies, focus on the Stonevault Geomancer next, and then finish off the remaining 2 adds.
Role notes: damage: CC any adds that you can and focus the boss first.
- Shrink [spell=7289]: Reduces an enemy's Strength by 1 and Stamina by 1 for 2 min.
- Lightning Bolt [spell=9532]: Blasts an enemy with lightning, inflicting Nature damage.
- Chain Bolt [spell=8292]: Strikes an enemy with a lightning bolt that arcs to another nearby enemy. The spell affects up to 3 targets, causing 147 Nature damage to each. | note: Spread out to reduce the damage this deals.
- Bloodlust [spell=6742]: Increases an ally's attack speed by 30% for 30 sec.
Loot: Grimlok's Tribal Vestments [item=9415], Oilskin Leggings [item=9414], Grimlok's Charge [item=9416]

#### Archaedas (NPC ids [2748])
Overview: Archaedas has a lot of HP and summons non-elite adds throughout the encounter. Make sure your group burns the adds down as quickly as possible. At 20%, he will summon 4 elite adds, who die when he dies. At this point in the fight, many groups opt to burn Archaedas down as quickly as possible. This is a long fight and will require the entire group to perform in order to defeat it. Remember to use potions, bandages, cooldowns, and everything you've got!
Role notes: damage: Kill the summoned adds throughout the fight until he summons four elite adds at 20%; ignore these and focus on killing Archaedas as quickly as possible.
- Ground Tremor [spell=6524]: Stuns nearby enemies, rendering them unable to move or attack for 2 sec.
- Awaken Earthen Guardians [spell=10252]: 
- Awaken Vault Warder [spell=10258]: 
Loot: Archaedic Stone [item=11118]

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- The Lost Dwarves: npcs[] spells[] newSpells[] loot[Worn Running Boots updated; Baelog's Shortbow updated; Battered Viking Shield updated]
- Revelosh: npcs[] spells[Chain Lightning updated: Value increased by 100%] newSpells[] loot[Revelosh's Boots updated; Revelosh's Armguards updated; Revelosh's Spaulders updated; Revelosh's Gloves updated]
- Ironaya: npcs[] spells[] newSpells[] loot[Stoneweaver Leggings updated; Ironaya's Bracers updated]
- Ancient Stone Keeper: npcs[] spells[] newSpells[] loot[Cragfists updated; Rockshard Pauldrons updated]
- Galgann Firehammer: npcs[] spells[Flame Shock updated: Value increased by 6.3%] newSpells[] loot[Galgann's Fireblaster updated; Galgann's Firehammer updated; Emberscale Cape updated]
- Grimlok: npcs[] spells[Chain Bolt updated: Numbers and wording changed] newSpells[] loot[Oilskin Leggings updated; Grimlok's Tribal Vestments updated]
- Archaedas: npcs[] spells[] newSpells[] loot[Archaedic Stone updated]


## Guide text
Source: https://www.wowhead.com/forever/guide=34966

Uldaman [zone=1337] is located in Badlands [zone=3]. This guide provides tips and strategies for completing Uldaman, including everything you need before and during the dungeon, quests to complete inside, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## Uldaman Overview in World of Warcraft: Forever

Uldaman is an ancient Titan vault that has lain buried deep within the earth since the world's creation. Dwarven excavations have recently penetrated this forgotten city, releasing the Titans' first failed creations: the Troggs. Legends say that the Titans created troggs from stone. When they deemed the experiment a failure, the Titans locked the troggs away and tried again - resulting in the creation of the dwarven race. The secrets of the dwarves' creation are recorded on the fabled Discs of Norgannon - massive Titan artifacts that lie at the very bottom of the ancient city. Recently, the Dark Iron dwarves have launched a series of incursions into Uldaman, hoping to claim the discs for their fiery master, Ragnaros. However, protecting the buried city are several guardians - giant constructs of living stone that crush any hapless intruders they find. The Discs themselves are guarded by a massive, sapient Stonekeeper called Archaedas. Some rumors even suggest that the dwarves' stone-skinned ancestors, the earthen, still dwell deep within the city's hidden recesses.

The recommended level for Uldaman is between 40 and 45. In-game players usually refer to Uldaman as Ulda.

## Location of Uldaman in World of Warcraft: Forever
There are two separate entrances to the Uldaman instance: the primary entrance and a back entrance.

Primary Entrance to Uldaman
Back Entrance to Uldaman

The primary entrance to Uldaman is just a bit south of the border between Loch Modan [zone=38] and Badlands. You'll know you're in the right spot when you start to see Shadowforge Dwarves in the area. 

The back entrance is a tunnel in Dustwind Gulch, east of Hammertoe's Digsite, northwest of Lethlor Ravine.

 Alliance players can fly to Thelsamar in Loch Modan [zone=38] and travel south into Badlands.

Horde players can fly to Kargath in Badlands and run over from there. If you don't have the Kargath flight point, head to Hammerfall in Arathi Highlands [zone=45], travel south through Wetlands [zone=11] and Loch Modan [zone=38] until you get to Badlands.

As with many World of Warcraft: Forever Dungeons, wiping (the entire group dying) in Uldaman can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. Druids only have an in-combat resurrection spell and are unlikely to train it before Uldaman.

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer (marked on the map below) as a ghost. You collect your body when you enter the instance.

## Every Quest in Uldaman in World of Warcraft: Forever

Hard: Level 37 | Medium: Level 40| At Level: Level 42| Easy: Level 47

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

Reclaimed Treasures [quest=2342] | 33 |  |  |   | Undercity, Center - Patrick Garrett [npc=5651] /way 62 48 | 

Uldaman Reagent Run [quest=2202] | 36 |  |  | Pre  | Badlands, Kargath - Jarkal Mossmeld [npc=6868] /way 3 46
CompleteBadlands Reagent Run [quest=2258] first | 

Necklace Recovery [quest=2283] | 37 |  |  |   | Badlands, Outside Uldaman instance - Shattered Necklace [item=7666] drop from Shadowforge or Shadowvault mobs | 

Reclaimed Treasures [quest=1360] | 33  |  |  |   | Ironforge, Hall of Explorers - Krom Stoutarm [npc=6294] /way 74 9 | 

The Lost Dwarves [quest=2398] | 35 |  |  |   | Ironforge, Hall of Explorers - Prospector Stormpike [npc=1356] /way 75 12 | 

The Hidden Chamber [quest=2240] | 35 |  |  | Pre | Uldaman, Lost Dwarves area - Baelog's Journal [object=123463]
CompleteThe Lost Dwarves [quest=2398] first | 

Uldaman Reagent Run [quest=17] | 38 |  |  | Pre | Loch Modan, Thelsamar - Ghak Healtouch [npc=1470] /way 37 49
CompleteBadlands Reagent Run [quest=2500] first | 

Agmond's Fate [quest=704] | 33 |  |  | Pre | Loch Modan, Ironband's Excavation Site - Prospector Ironband [npc=1344] /way 65 65
Complete 3 quests, starting with Ironband Wants You! [quest=707] first | 

The Lost Tablets of Will [quest=1139] | 30 |  |  | Pre | Ironforge, Hall of Explorers - Advisor Belgrum [npc=2918] /way 77 9
Complete 8 quests, starting with A Sign of Hope [quest=720] first | 

The Shattered Necklace [quest=2198] | 37 |  |  |   | Badlands, Outside Uldaman instance - Shattered Necklace [item=7666] drop from Shadowforge or Shadowvault mobs | 

Power Stones [quest=2418] | 30 | - |  |   | Badlands, Central - Rigglefuzz [npc=2817] /way 42 52 | 

Solution to Doom [quest=709] | 30 | - |  |   | Badlands, Southern - Theldurin the Lost [npc=2785] /way 51 76 | 

The Platinum Discs [quest=2278] | 40 | - |  |   | Uldaman, room after Archaedas [npc=2748] - The Discs of Norgannon [object=131474] | 

Power in Uldaman [quest=1956] | 35 | - |  | Pre  | Mage Only - Dustwallow Marsh, N. of Stonemaul Ruins - Tabetha [npc=6546] /way 46 57
Complete 3 quests, starting with Return to the Marsh [quest=1953] first | 

Completing Dungeon Quests in World of Warcraft: Forever is a great way to gain some extra experience and gear. You will find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

The quests below include where to collect them, any prerequisites you need to complete first, and what you need to do inside or around Uldaman.

Faction: Both
Level Required: 30
Rewards:

- Doomsayer's Robe [item=4746]
- 3,150 experience

Solution to Doom [quest=709] starts with Theldurin the Lost [npc=2785] in Badlands.

He asks you to loot Tablet of Ryun'eh [item=4631], found inside the Ancient Chest within the Sealed Hall. The Sealed Hall is located outside the instance at 53, 61, left of the first dig site. Take note that the quest reward: Doomsayer's Robe [item=4746] has negative stamina!

Theldurin the Lost [npc=2785]

Faction: Both
Level Required: 40
Rewards:

- 4,200 experience

The Platinum Discs [quest=2278] starts at The Discs of Norgannon [object=131474] after defeating the final boss, Archaedas [npc=2748]. Read through all of the lore, and you'll eventually receive a follow-up quest The Platinum Discs [quest=2439] / The Platinum Discs [quest=2440], which will reward you with Superior Healing Potion [item=3928] (5) or Greater Mana Potion [item=6149] (5) and Thawpelt Sack [item=9587] - a very nice, 14 slot bag!

Faction: Both
Level Required: 28
Rewards:

- 3,500 experience
- Rewards: Energized Stone Circle [item=9522], Duracin Bracers [item=10358] or Everlast Boots [item=10359]
-  Reputation with Booty Bay {/forever/faction=21/booty-bay}

Power Stones [quest=2418] starts with Rigglefuzz [npc=2817] in the Badlands.

He asks you to loot Power Stones from Shadowforge Dwarves in the Uldaman dig site, outside the instance entrance:

- Dentrium Power Stone [item=8009] (8)
- An'Alleum Power Stone [item=8052] (8)

Rigglefuzz [npc=2817]

Class: Mage {/forever/class=8/mage}
Level Required: 35
Rewards:

- 3,900 experience
- Rewards: Experience
- reputation with Booty Bay {/forever/faction=21/booty-bay}

Power in Uldaman [quest=1956] is part of a quest series starting from Return to the Marsh [quest=1953], given by Mage Trainers to send you to Tabetha [npc=6546] in Dustwallow Marsh. 

Tabetha [npc=6546]

Tabetha [npc=6546] will follow up with The Infernal Orb [quest=1954], to collect Infernal Orb [item=7291]. This item drops off Burning Blade Summoner [npc=4668] in Desolace [zone=405].

Burning Blade Summoner [npc=4668]

Return Infernal Orb [item=7291] to Tabetha [npc=6546] and she'll follow up with The Exorcism [quest=1955]. Demon of the Orb [npc=6549] will be summoned right outside that you must kill.

After doing so, speak to Tabetha [npc=6546] again to complete. She will now follow-up with Power in Uldaman [quest=1956], to retrieve an Obsidian Power Source [item=8053] from Obsidian Sentinel [npc=7023] inside Uldaman.

Obsidian Sentinel [npc=7023] is a level 44 elite golem found in Uldaman [zone=1337], right by the Back Entrance.

Return to Tabetha [npc=6546] to complete the quest.

Faction: Alliance
Level Required: 33
Rewards:

- 
- 3,600 experience
- reputation with Ironforge {/forever/faction=47/ironforge}

Reclaimed Treasures [quest=1360]: Speak with Krom Stoutarm [npc=6294] in the Hall of Explorers (74, 9) of Ironforge.

Krom Stoutarm [npc=6294]

Reclaim Krom Stoutarm's Treasure [item=8027] from the North Common Hall of Uldaman. This is OUTSIDE the instance. From the outside entrance, head to the bottom leftmost room to find the North Common Hall at 53, 61. You'll find a group of Troggs in the room, surrounding the treasure. Loot the box:

The quest will be tagged as "Complete" when Krom Stoutarm's Treasure [item=8027] has been looted.

Faction: Alliance
Level Required: 35
Rewards:

- 3,150 experience
- reputation with Ironforge {/forever/faction=47/ironforge}

Amulet of Secrets [quest=722] is part of a chain quest. Pre-requesitie quest begins with A Sign of Hope [quest=720] - start by finding Crumpled Map [object=2868] in Badlands [zone=3].

Crumpled Map [object=2868]

Now head to Prospector Ryedol [npc=2910] just a bit to the south:

Prospector Ryedol [npc=2910]

Speak to Prospector Ryedol [npc=2910] & he'll ask you to locate Hammertoe Grez [npc=2909] in Uldaman. Hammertoe Grez [npc=2909] is OUTSIDE the instance entrance at 54, 58 of the caverns leading to the portal.

 | 

As you enter the Uldaman cave, you'd normally proceed to Dig One in order to jump from a cliff there to find yourself directly in front of the Uldaman instance entrance. Just before you make it to the cliff where people usually jump to enter the instance (perhaps 50-100 yards back), you will note a small camp, a campfire, and a kneeling bald dwarf with a flame-colored beard barricaded behind some boxes. It is the elusive Hammertoe Grez [npc=2909].

 | 

Hammertoe Grez [npc=2909] | 

Prospector Ryedol [npc=2910] will now give you Amulet of Secrets [quest=722] & ask you to find Hammertoe's Amulet [item=4635]. The amulet drops off the named mob, Magregan Deepshadow [npc=2932].

 | 

Prospector Ryedol [npc=2910] is located in the cavern outside of the Uldaman instance portal. On your minimap, he will be West of the instance entrance in The Sealed Hall, patrolling the caves of Dark Iron Dwarves and troggs.

 | 

Prospector Ryedol [npc=2910] | 

Loot Hammertoe's Amulet [item=4635] from Prospector Ryedol [npc=2910] & return back to Hammertoe Grez [npc=2909] to complete the quest. You'll receive Prospect of Faith [quest=723] as a follow up. Return to Prospector Ryedol [npc=2910] in Badlands [zone=3].

Prospector Ryedol [npc=2910]

Finally, Prospector Ryedol [npc=2910] will grant you one more follow-up quest, Prospect of Faith [quest=724], to bring Hammertoe's Amulet [item=4635] to Historian Karnik [npc=2916] in Ironforge [zone=1537].

Historian Karnik [npc=2916]

You've now completed this quest chain!

Faction: Alliance
Level Required: 35
Rewards:

- Dwarven Charge [item=9626] or Explorer's League Lodestar [item=9627]
- 3,900 experience
- reputation with Ironforge {/forever/faction=47/ironforge}

The Hidden Chamber [quest=2240] is shareable if the prerequisite quest The Lost Dwarves [quest=2398] (acquired from Prospector Stormpike [npc=1356] in the Hall of Explorers of Ironforge) is completed by another player. Baelog [npc=6906] is found inside the Uldaman instance.

Acquire Gni'kiv Medallion [item=7740] from a chest on the table behind Baelog [npc=6906]. Move onward in the dungeon, and acquire The Shaft of Tsol [item=7741] from Revelosh [npc=6910]. Make sure the same player receives both pieces of loot to combine into Staff of Prehistoria [item=7733], which allows you to access the hidden chamber, behind Ironaya [npc=7228].

To complete the quest, simply walk into the chamber once Ironaya [npc=7228] has been defeated.

Faction: Alliance
Level Required: 38
Rewards:

- 
- Restorative Potion [item=9030]
- 3,450 experience
- reputation with Ironforge {/forever/faction=47/ironforge}

Uldaman Reagent Run [quest=17] is shareable if the prerequisite quest Badlands Reagent Run [quest=2500] is completed by another player. Speak to Ghak Healtouch [npc=1470] in Thelsamar to acquire these quests.

Ghak Healtouch [npc=1470]

Badlands Reagent Run [quest=2500]
Buzzard Gizzard [item=7847] (5)
Crag Coyote Fang [item=7846] (10)
Rock Elemental Shard [item=7848] (5)
...all collected from mobs within Badlands [zone=3]

Return to Ghak Healtouch [npc=1470] in Thelsamar to complete & pick up the following quest:

Uldaman Reagent Run [quest=17]
Collect Magenta Fungus Cap [item=8047] from inside & outside the caverns within the Uldaman instance.

Alchemists will receive a follow-up quest, Badlands Reagent Run II [quest=2501], which teaches you how to make Restorative Potion [spell=11452].

Faction: Alliance
Level Required: 30
Rewards:

- Prospector Gloves [item=4980]
- 2,850 experience
- reputation with Ironforge {/forever/faction=47/ironforge}

Agmond's Fate [quest=704] is shareable if the prerequisite quest Ironband Wants You! [quest=707] is completed by other party members. Start with Prospector Ironband [npc=1344] in Ironforge to pick up Ironband Wants You! [quest=707]

Prospector Stormpike [npc=1356]

Now, find Prospector Ironband [npc=1344] in Loch Modan [zone=38]:

Prospector Stormpike [npc=1356]

Speak with Prospector Stormpike [npc=1356] and he will follow up with Find Agmond [quest=738]. You will now head to the following location in Badlands [zone=3]:

Prospector Stormpike [npc=1356]

You'll find Agmond's skeletal remains, right-click on them to interact and complete Find Agmond [quest=738]:

Now, you'll receive Murdaloc [quest=739], asking you to kill:

- Murdaloc [npc=2945] (1)
- Stonevault Bonesnapper [npc=2893] (12)

These troggs are located in the area surrounding Agmond's remains. Upon completion, you'll receive Rock Pulverizer [item=4983], and the follow-up quest Agmond's Fate [quest=704], to collect Carved Stone Urn [item=4610] (4) outside the entrance of the Uldaman instance:

Collect all 4 Carved Stone Urn [item=4610] and return to Prospector Ironband [npc=1344] in Thelsamar, Loch Modan [zone=38] to complete.

Faction: Alliance
Level Required: 35
Rewards:

- Medal of Courage [item=6723]
- 5,850 experience
- reputation with Ironforge {/forever/faction=47/ironforge}

The Lost Tablets of Will [quest=1139] is part of a chain quest, starting with Historian Karnik [npc=2916] in Ironforge [zone=1537]. You must have already completed Amulet of Secrets [quest=722] (detailed above) to acquire this quest from Historian Karnik [npc=2916].

Historian Karnik [npc=2916]

Pick up Passing Word of a Threat [quest=725] from Historian Karnik [npc=2916] to find Advisor Belgrum [npc=2918] and give him Sealed Note to Advisor Belgrum [item=4622] (provided). Advisor Belgrum [npc=2918] is located right next to Historian Karnik [npc=2916] in the Hall of Explorers in Ironforge. He will give you another follow-up, Passing Word of a Threat [quest=726], to return right back to Historian Karnik [npc=2916]. You'll now receive another quest, An Ambassador of Evil [quest=762] to kill Ambassador Infernus [npc=2745] and loot Ambassador Infernus' Bracer [item=4621]:

Ambassador Infernus [npc=2745]

Ambassador Infernus [npc=2745] is a fire elemental, located in the Angor Fortress of the Badlands.

Loot the Ambassador Infernus' Bracer [item=4621] and return to Advisor Belgrum [npc=2918]. You'll receive Dwarf Captain's Sword [item=4987] as a reward and unlock The Lost Tablets of Will [quest=1139].

To complete The Lost Tablets of Will [quest=1139], loot Tablet of Will [item=5824] located in the same room as the boss inside Uldaman, Galgann Firehammer [npc=7291].

Faction: Alliance
Level Required: 37
Rewards:

- Talvash's Enhancing Necklace [item=7673]
- 5,600 experience
- reputation with Gnomeregan Exiles {/forever/faction=54/gnomeregan-exiles}

Restoring the Necklace [quest=2204] starts from Shattered Necklace [item=7666] dropped by Shadowforge or Shadowvault mobs inside the Uldaman instance. Upon looting it, right click to begin the quest The Shattered Necklace [quest=2198]. Head to Talvash del Kissel [npc=6826] in Ironforge [zone=1537] to complete the quest:

Talvash del Kissel [npc=6826]

Talvash del Kissel [npc=6826] will now give you the quest Lore for a Price [quest=2199] to bring him Silver Bar [item=2842] (5) to proceed. Collect the Silver Bar [item=2842]s and speak to Talvash del Kissel [npc=6826], and he'll follow-up with Back to Uldaman [quest=2200], providing you with Talvash's Phial of Scrying [item=7667]:

Return back inside Uldaman and search for remains of the lost paladin. He's very close to the instance entrance. Once inside, defeat the boss Revelosh [npc=6910], and you'll find the remains in the room behind him:

Use Talvash's Phial of Scrying [item=7667] to contact Talvash del Kissel [npc=6826] to proceed. He'll now give you the quest Find the Gems [quest=2201], providing Bloodstained Journal [item=7668] to find:

- Shattered Necklace Ruby [item=7669] - found in a cache inside Galgann Firehammer [npc=7291]'s room
- Shattered Necklace Sapphire [item=7670] - dropped by the boss, Grimlok [npc=4854]
- Shattered Necklace Topaz [item=7671] - located in an urn in Dig Two, the same room that Baelog [npc=6906] is in

Once you've collected all of the gems, use Talvash's Phial of Scrying [item=7667] to contact Talvash del Kissel [npc=6826] again. He'll now give you the final part of this quest, Restoring the Necklace [quest=2204], to loot Shattered Necklace Power Source [item=7672] from Archaedas [npc=2748], the final boss of Uldaman.

Return to Talvash del Kissel [npc=6826] to complete the chest, and you'll receive Talvash's Enhancing Necklace [item=7673].

Faction: Horde
Level Required: 33
Rewards:

- 
- 3,600 experience
- reputation with Undercity {/forever/faction=68/undercity}

Reclaimed Treasures [quest=2342]: Speak with Patrick Garrett [npc=5651] in the Undercity [zone=1497] (62, 48).

Patrick Garrett [npc=5651]

Reclaim Garrett Family Treasure [item=8026] from the South Common Hall of Uldaman. This is OUTSIDE the instance. If you are facing the front entrance of the Uldaman instance portal, this Hall is to your left, populated by Troggs surrounding the treasure. Loot the box:

The quest will be tagged as "Complete" when Garrett Family Treasure [item=8026] has been looted.

Faction: Horde
Level Required: 36
Rewards:

- 
- Restorative Potion [item=9030]
- 3,450 experience
- reputation with Darkspear Trolls {/forever/faction=530/darkspear-trolls}

Uldaman Reagent Run [quest=2202] is shareable if the prerequisite quest Badlands Reagent Run [quest=2258] is completed by other player. Speak to Jarkal Mossmeld [npc=6868] in Kargath, Badlands to acquire these quests:

Jarkal Mossmeld [npc=6868]

Badlands Reagent Run [quest=2258]
Buzzard Gizzard [item=7847] (5)
Crag Coyote Fang [item=7846] (10)
Rock Elemental Shard [item=7848] (5)
...all collected from mobs within Badlands [zone=3]

Return to Jarkal Mossmeld [npc=6868] in Kargath, Badlands to complete & pick up the following quest:

Uldaman Reagent Run [quest=2202]
Collect Magenta Fungus Cap [item=8047] from inside & outside the caverns within the Uldaman instance.

Alchemists will receive a follow-up quest, Badlands Reagent Run II [quest=2203], which teaches you how to make Restorative Potion [spell=11452].

Faction: Horde
Level Required: 37
Rewards:

- Jarkal's Enhancing Necklace [item=7888]
- 5,600 experience
- reputation with Darkspear Trolls {/forever/faction=530/darkspear-trolls}

Necklace Recovery, Take 3 [quest=2341] starts from Shattered Necklace [item=7666] dropped by Shadowforge or Shadowvault mobs inside the Uldaman instance. Upon looting it, head to Dran Droffers [npc=6986] in Orgrimmar [zone=1637] to complete the quest Necklace Recovery [quest=2283]:

Dran Droffers [npc=6986]

Find Dran Droffers [npc=6986] and hand in Necklace Recovery [quest=2283]. Now accept the follow-up, Necklace Recovery, Take 2 [quest=2284].

Return back inside Uldaman and search for remains of the lost paladin. He's very close to the instance entrance. Once inside, defeat the boss Revelosh [npc=6910], and you'll find the remains in the room behind him:

Loot the corpse to receive Untranslated Journal [item=7886]. Now return to Jarkal Mossmeld [npc=6868] in Kargath, Badlands. He'll follow up with another quest: Find the Gems and Power Source [quest=2339], loot the following:

- Shattered Necklace Ruby [item=7669] - found in a cache inside Galgann Firehammer [npc=7291]'s room
- Shattered Necklace Sapphire [item=7670] - dropped by the boss, Grimlok [npc=4854]
- Shattered Necklace Topaz [item=7671] - located in an urn in Dig Two, the same room that Baelog [npc=6906] is in
- Shattered Necklace Power Source [item=7672] - dropped from Archaedas [npc=2748], the final boss of Uldaman.

Return to Jarkal Mossmeld [npc=6868] to complete the quest and you'll receive Deliver the Gems [quest=2340] to return to Dran Droffers [npc=6986] in Orgrimmar [zone=1637]. Accept  [quest=2431], to return back to Jarkal Mossmeld [npc=6868] to receive your Jarkal's Enhancing Necklace [item=7888].

### Best Quest Rewards

Type | Item | Quest | 

14 slot bag |  Thawpelt Sack [item=9587] |  The Platinum Discs [quest=2439]
The Platinum Discs [quest=2440] | 

## Noteworthy Uldaman Trash Mobs in World of Warcraft: Forever
Trash tips:

- Many of the pulls in Uldaman [zone=1337] will contain groups of enemies. Utilizing crowd control abilities such as Polymorph [spell=118], Sap [spell=6770] and others will make things a lot easier!
- Since many of the tunnels are long and winding, use it to your advantage when pulling casters. Hiding behind a wall or corner, or using Line-of-Sight (LoS), will force the caster to run to you as they will have no visible way to attack you otherwise.
- Most enemies will run away for help at low health. Great time for a Warrior {/forever/class=1/warrior} to keep up Hamstring [spell=26141] or a Rogue {/forever/class=4/rogue} to use Crippling Poison [item=3775] to slow them down.
- As you venture deeper into Uldaman [zone=1337], many mobs will cast AoE spells such as Flamestrike [spell=11829]. Be careful where you're standing - move out of the fire after this has been cast!
- Shadowforge Darkcaster [npc=4848] cast a Spell Bomb, where for 10 seconds, it inflicts 300+ damage to a target every time they cast a spell. Treat this as a silence, and cease all casting until this wears off.
- When you reach the packs of Earthen Mobs towards the end, you'll see they're in packs of 5 or greater. Burn down the casters first as they usually have less armor and HP and die quickly.

### Digmaster Shovelphlange (Rare)
Digmaster Shovelphlange [npc=7057] is a level 38 elite goblin that patrols the caverns outside of Uldaman [zone=1337], in the South Common Hall, before you zone in.

Abilities:

- Defensive Stance [spell=71]
- Sunder Armor [spell=8380]

Strategy:
Digmaster Shovelphlange [npc=7057] can hit hard, especially for cloth wearers. Make sure the tank picks him up and has aggro before you begin DPSing. Other than a fast attack speed, and a couple of Warrior {/forever/class=1/warrior} abilities: Defensive Stance [spell=71] & Sunder Armor [spell=8380], so long as you don't pull any additional mobs, you should be able to burn him down with ease.

Loot:

- Expert Goldminer's Helmet [item=9375] - Leather Helm with +Axe Skill
- Shovelphlange's Mining Axe [item=9378] - 1H Axe

### Master Enchanter Annora
Annora [npc=11073] is the Artisan trainer for Enchanting. She is located between the Map Chamber and Temple Hall, and easier to get to from the Back Entrance of Uldaman [zone=1337]. She's also surrounded by scorpids, so be prepared to clear the area before talking with her.

You can train Artisan Enchanting from her at level 35 with 200 Enchanting Skill.

As traveling to Uldaman may be a pain at low levels, you may want to come prepared with enough reagents to skill up to 250, at which point you can learn her top recipes Enchant Gloves - Minor Haste [spell=13948], Enchanted Leather [spell=17181], and Enchanted Thorium [spell=17180] so you never have to return. 

## Uldaman Bosses in World of Warcraft: Forever

Baelog [npc=6906] a level 41 elite, Eric "The Swift" [npc=6907] a level 40 elite and Olaf [npc=6908] a level 40 elite, make up The Lost Dwarves. They are friendly to Alliance, but hostile to the Horde.

Lost Dwarves Abilities
Baelog's Abilities

- Ranged Attack

Eric's Abilities

- Intercept [spell=20252]

Olaf's Abilities

- Shield Slam [spell=8242]

Lost Dwarves Strategy

Most groups tend to crowd control Baelog [npc=6906], have their tank pick up Olaf [npc=6908], and burst down Eric "The Swift" [npc=6907] as he can cast Intercept [spell=20252] on party members, which results in a pesky stun. Once Eric "The Swift" [npc=6907] is done for, move on to Olaf [npc=6908] while keeping Baelog [npc=6906] CC'd. As long as the room is clear and there aren't any additional adds during the encounter, you shouldn't have much trouble with The Lost Dwarves.

Revelosh [npc=6910] is a level 40 elite trogg found in Uldaman [zone=1337].

Revelosh Abilities

- Chain Lightning [spell=16033]
- Lightning Bolt [spell=9532]

Revelosh Strategy

Revelosh [npc=6910] is linked with two Stonevault Rockchewer [npc=4851], so when you pull him, they will also join the battle. You could try to CC one of the Stonevault Rockchewer [npc=4851] if you've got it. Otherwise, try to burn down Revelosh [npc=6910] as quickly as possible. His Chain Lightning [spell=16033] can deal a lot of damage to your party, so take priority in interrupting whenever he gets ready to cast it.

Ironaya [npc=7228] is a level 40 giant found in Uldaman [zone=1337]. To summon her, you need to combine Gni'kiv Medallion [item=7740] from the chest behind The Lost Dwarves, and The Shaft of Tsol [item=7741], a drop from Revelosh [npc=6910]. Designate one player to loot and combine the two pieces together to form the Staff of Prehistoria [item=7733] and place it in the model of a city-looking keystone within the next room.

Ironaya Abilities

- Arcing Smash [spell=8374]
- War Stomp [spell=45]
- Knock Away [spell=18670]

Ironaya Strategy

Ironaya [npc=7228] has high armor, lots of HP, is immune to damage-over-time (DoT) effects and can knock players back. Have your tank pick her up and face her away from the rest of the group to avoid her Arcing Smash [spell=8374]. Ranged, spread out. Keeping her abilities in mind, it's a fairly straightforward tank & spank type fight.

Obsidian Sentinel [npc=7023] is a level 44 elite golem found in Uldaman [zone=1337], right by the Back Entrance.

Obsidian Sentinel Abilities

- Splintered Obsidian [spell=10072]
- Summon Obsidian Shard [spell=10061]

Obsidian Sentinel Strategy

Similar to the Stone Steward [npc=4860] mobs that you fought on your way to Ancient Stone Keeper [npc=7206], he's got high armor, high HP, and DoT immunity. At 66% and 33% health, he will spawn two non-elite Obsidian Shard [npc=7209]. Groups typically kill the two Obsidian Shard [npc=7209] first, then return back to the boss. 

Ancient Stone Keeper [npc=7206] is a level 44 elite golem found in Uldaman [zone=1337].

Ancient Stone Keeper Abilities

- Sand Storms [spell=10094]

Ancient Stone Keeper Strategy

Similar to the Ancient Stone Keeper [npc=7206] boss fight and Stone Steward [npc=4860] mobs that you fought along your way, he's also got high armor, high HP, DoT immunity and a nasty AoE slow & silence ability: Sand Storms [spell=10094].

Galgann Firehammer [npc=7291] is a level 44 elite Dark Iron Dwarf found in Uldaman [zone=1337].

Galgann Firehammer Abilities

- Flame Shock [spell=15039]
- Amplify Flames [spell=9482]
- Flame Lash [spell=3356]
- Fire Nova [spell=11970]

Galgann Firehammer Strategy

Galgann Firehammer [npc=7291] awaits you with two Shadowforge Geologist [npc=7030] by his side. Between these 3 NPCs, there's a lot of AoE magic damage flying around. Tanks, pick up Galgann Firehammer [npc=7291] and separate him from the group, keeping him faced away. CC one Shadowforge Geologist [npc=7030], kill the other one, then kill the one that was CC'd. Once both are dead, focus on Galgann Firehammer [npc=7291].

His range of fire attacks can be devastating. If able to, dispel any of his fire buffs that he'll cast on your party as they will amplify his fire damage. 

Grimlok [npc=4854] is a level 44 elite trogg found in Uldaman [zone=1337].

Grimlok Abilities

- AoE Shrink [spell=7289]
- Lightning Bolt [spell=9532]
- Chain Bolt [spell=8292]
- Bloodlust [spell=6742]

Grimlok Strategy

Grimlok [npc=4854] comes with a Stonevault Geomancer [npc=4853], Stonevault Brawler [npc=4855] and a Jadespine Basilisk [npc=4863] all grouped up together. Many groups will opt to burn down Grimlok [npc=4854] as quickly as possible, while CCing one of the adds. Killing Grimlok [npc=4854] quickly can result in him dying before being able to cast his group Shrink [spell=7289]. After he dies, focus on the Stonevault Geomancer [npc=4853] next, and then finish off the remaining 2 adds.

Archaedas [npc=2748] is a level 47 elite giant found in Uldaman [zone=1337].

Archaedas Abilities

- Ground Tremor [spell=6524]
- Awaken Earthen Guardians [spell=10252]
- Awaken Vault Warder [spell=10258]

Archaedas Strategy

Archaedas [npc=2748] has a lot of HP and summons non-elite adds throughout the encounter. Make sure your group burns the adds down as quickly as possible. At 20%, he will summon 4 elite adds, who die when he dies. At this point in the fight, many groups opt to burn Archaedas [npc=2748] down as quickly as possible. This is a long fight and will require the entire group to perform in order to defeat. Remember to use potions, bandages, cooldowns, and everything you've got!

## Uldaman Loot in World of Warcraft: Forever

Item | Type | 

Nordic Longshank [item=9401] | 1H Sword | 

Precision Arrow [item=9399] | Arrows | 

Baelog's Shortbow [item=9400] | Bow | 

Horned Viking Helmet [item=9394] | Plate Helm that works similarly to Goblin Rocket Helmet [item=10588].
Great for PvP to take out an opponent for 30 seconds. | 

Worn Running Boots [item=9398] | Leather Boots | 

Swiftness Potion [item=2459] | consumable that increases run speed | 

Olaf's All Purpose Shield [item=9404] | Shield which reduces fall damage | 

Battered Viking Shield [item=9403] | Shield | 

Oil of Olaf [item=1177] | consumable that increases armor | 

Item | Type | 

Revelosh's Armguards [item=9388] | Mail Wrist | 

Revelosh's Boots [item=9387] | Plate Feet | 

Revelosh's Gloves [item=9390] | Cloth Hands | 

Revelosh's Spaulders [item=9389] | Leather Shoulder | 

Item | Type | 

Ironaya's Bracers [item=9409] | Plate Bracers with random suffixes | 

Ironshod Bludgeon [item=9408] | Staff | 

Stoneweaver Leggings [item=9407] | Cloth legs | 

Item | Type | 

Obsidian Power Source [item=8053] | for the Mage quest | 

Item | Type | 

Cragfists [item=9410] | Plate Gloves with Defense and random suffixes | 

Rockshard Pauldrons [item=9411] | Mail Shoulders | 

Item | Type | 

Flameseer Mantle [item=11310] | Fire Damage Cloth Shoulders | 

Galgann's Fireblaster [item=9412] | Gun | 

Emberscale Cape [item=11311] | Cloak | 

Galgann's Firehammer [item=9419] | 1H Mace | 

Item | Type | 

Grimlok's Charge [item=9416] | Polearm | 

Grimlok's Tribal Vestments [item=9415] | Cloth Chest | 

Oilskin Leggings [item=9414] | Leather Legs | 

Item | Type | 

Archaedic Stone [item=11118] | Ring with random suffixes | 

Stoneslayer [item=9418] | 2H sword, great for leveling Warriors and Paladins | 

The Rockpounder [item=9413] | 2H mace, great for leveling Warriors, Shaman, and Paladins | 

There are several powerful, unique, and attractive BoEs to be found in Uldaman. With its slow speed and large proc, Pendulum of Doom [item=9425] is an excellent 2h weapon, especially for 39 twink characters. Other notable BoEs include:

Type | Item | 

Cloth Healing Helm | Papal Fez [item=9431] | 

Mail Legs | Legguards of the Vault [item=9396] | 

Healing Offhand | Beacon of Hope [item=9393] | 

1H Mace, looks like a bone | Stonevault Bonebreaker [item=9427] | 

1H Sword, sheaths on your back | Ginn-su Sword [item=9424] | 

Gun | Shadowforge Bushmaster [item=9422] | 

There are also several BoEs, that while not as powerful, have distinctive looks for RP, such as the mining hat Miner's Hat of the Deep [item=9429], mining pick Digmaster 5000 [item=9465], shovel The Shoveler [item=9391], and fire stick Excavator's Brand [item=9386].

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/uldaman und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **The Lost Dwarves** [6906, 6907, 6908]: Intercept (20252)
- **Ancient Stone Keeper** [7206]: Harsh Winds (10093)
- **Galgann Firehammer** [7291]: Fire Nova (11969), Flame Shock (8053)
- **Grimlok** [4854]: Lightning Bolt (9532)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: 2203, 2431, 2439, 2440, 2501

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist
