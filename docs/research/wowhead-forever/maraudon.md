# Maraudon - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=35197 (maraudon)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/maraudon


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/maraudon

Journal: areaId (zone) 2100; level range from journal: 42-52; kind dungeon

Journal description: Protected by the fierce Maraudine centaur, Maraudon is one of the most sacred sites within Desolace. The great temple/cavern is the burial place of Zaetar, one of two immortal sons born to the demigod, Cenarius. Legend holds that Zaetar and the earth elemental princess, Theradras, sired the misbegotten centaur race. It is said that upon their emergence, the barbaric centaur turned on their father and killed him. Some believe that Theradras, in her grief, trapped Zaetar's spirit within the winding cavern - used its energies for some malign purpose. The subterranean tunnels are populated by the vicious, long-dead ghosts of the Centaur Khans, as well as Theradras' own raging, elemental minions.

### Journal quests (id, level as shown, side)
- Shadowshard Fragments [quest=7068] level 42, Horde
- Vyletongue Corruption [quest=7029] level 47, Horde
- Corruption of Earth and Seed [quest=7064] level 51, Horde
- Shadowshard Fragments [quest=7070] level 42, Alliance
- Vyletongue Corruption [quest=7041] level 47, Alliance
- Corruption of Earth and Seed [quest=7065] level 51, Alliance
- Twisted Evils [quest=7028] level 47, both
- Legends of Maraudon [quest=7044] level 49, both
- Seed of Life [quest=7066] level 51, both
- The Pariah's Instructions [quest=7067] level 48, both
- The Scepter of Celebras [quest=7046] level 49, both

### Journal bosses

#### Lord Vyletongue (NPC ids [12236])
Overview: If the entire group stacks on Lord Vyletongue, you negate his ability to use Auto Shot & Multi-Shot, so have everyone stack close together on the tank. He'll use Blink to get away, so make sure you are quick to stack up again whenever he does so. Most groups DPS Lord Vyletongue down first since he is mobile and can move around the room. Once he's down, finish off his two guards.
Role notes: damage: Kill Lord Vyletongue first, before switching to the adds.
- Multi-Shot [spell=14443]: Fires a volley of missiles at an enemy and its nearby allies, striking up to 3 targets for normal damage plus 50. | note: Lord Vyletongue can't use this if everyone is stacked close to him.
- Blink [spell=1953]: Teleports the caster 20 yards forward, unless something is in the way. Also frees the caster from Stuns and Immobilizes.
- Smoke Bomb [spell=7964]: Casts a smoke bomb, stunning nearby enemies for 4 sec.

#### Noxxion (NPC ids [13282])
Overview: Noxxion has an AoE Toxic Volley ability as well as a knockback called Uppercut. After a little while, Noxxion will split into smaller versions of himself. Once they're all defeated, Noxxion will reform, and the fight will continue. Some groups opt to pull him out of the pool, to make killing the adds easier.
- Summon Noxxion's Spawns [spell=21707]:  | note: Noxxion splits into multiple [npc=13456], which need to be killed before he reforms and you can finish killing the boss.
- Toxic Volley [spell=21687]: Inflicts Nature damage to an enemy.
- Uppercut [spell=10966]: Inflicts normal damage plus 50 to an enemy, knocking it back.
Loot: Celebrian Rod [item=17702]

#### Razorlash (NPC ids [12258])
Overview: Razorlash's Puncture inflicts a painful 10-second DoT and an AoE Cleave ability on those in melee range. Therefore, casters should stand at range while burning him down.
- Cleave [spell=11427]: Inflicts normal damage plus 10 to an enemy and its nearest allies, affecting up to 3 targets. | note: Hits Razorlash's target and nearby group members, so avoid standing near the tank if you aren't melee.
- Puncture [spell=15976]: Inflicts Physical damage to an enemy every 2 sec. for 10 sec.

#### Celebras the Cursed (NPC ids [12225])
Overview: Celebras the Cursed has Druid-like abilities and summons non-elite [npc=13743] throughout the encounter. He will most often use his Wrath spell, which can be interrupted, so make sure it's getting interrupted as often as possible. If one of his Corrupt Force of Nature falls, he will summon another one. Focus down Celebras the Cursed first, then polish off the remaining Corrupt Force of Nature. After defeating Celebras the Cursed, you may now complete your quest to create [item=17191]. This item is very significant, allowing players to create a portal outside the instance to teleport them directly to Earth Song Falls, the next section of the dungeon.
Role notes: damage: Ignore the adds until the boss is dead.
- Wrath [spell=9739]: Hurls a bolt of lightning at an enemy, inflicting Nature damage. | note: Interrupt this as frequently as possible to reduce his damage output.
- Force of Nature [spell=6913]: Summons 3 Forces of Nature to aid the caster in battle for 1 min.
- Entangling Roots [spell=12747]: Entangles an enemy in roots, inflicting Nature damage every 3 sec. and immobilizing it for up to 10 sec.
- Twisted Tranquility [spell=21793]: Deals nature damage to enemies in an area over 10 sec, slowing their movement by 70% and increasing the time between their attacks by 300%.

#### Landslide (NPC ids [12203])
Overview: Landslide has many similar abilities to the [npc=12206] that you fought on the way to his alcove. Keep him near the area in which he stands. Tank him with your back to a wall. Ranged should stay at max distance to avoid any knockback or stun from the [npc=11783], which despawns once Landslide dies.
Role notes: tank: Keep your back to a wall to avoid being knocked back.
- Summon Shardlings [spell=21808]: Summons Theradrim Shardlings every 2 seconds and stuns enemies in an area for 8 sec. | note: Around halfway through the encounter, the boss stuns the group and summons Shardlings, which need to be picked up by the tank or AoE'd down.
- Trample [spell=5568]: Inflicts normal damage plus 8 to nearby enemies.
- Knock Away [spell=18670]: Inflicts normal damage plus 30 to an enemy and knocks it back.

#### Princess Theradras (NPC ids [12201])
Overview: Although considered the final boss of Maraudon, most groups will head to Princess Theradras after killing [npc=12203], and then jump down to kill [npc=13596] and [npc=13601]. Princess Theradras is not an easy fight, so understanding her mechanics is vital to your success. Groups tend to engage her towards the back of her cavern to allow for more space. Also, be aware that there are non-aggressive turtles in the area around her cavern. If they get hit with a spell, they will aggro on you, so be mindful of your surroundings.
Role notes: tank: Position the boss towards the back of the cavern, as far away from your ranged as possible, allowing you time to recover aggro if you get feared.; healer: This boss deals very high damage, so keep the tank's health high.; damage: Be careful with aggro, especially if the tank gets feared.
- Repulsive Gaze [spell=21869]: Roars at an enemy, paralyzing it with terror for 8 sec. and causing all other nearby enemies to flee in fear. | note: Use abilities like [spell=6346] and [spell=8143] to help deal with this AoE fear.
- Dust Field [spell=21909]:  | note: This knocks nearby players back and deals damage. At max range, non-melee players should be able to avoid this.
- Boulder [spell=21832]: Hurls a boulder at an enemy.

#### Rotgrip (NPC ids [13596])
Overview: Rotgrip hits hard! Make sure your tank has proper aggro before everyone else engages. Healers, try your best to keep your tank and other party members topped off. Rotgrip can dish out devastating damage quickly using his two abilities: Puncture, a physical damage-over-time, and Fatal Bite.
Role notes: tank: Clear the area before pulling the boss.; healer: Keep your group healthy, as Rotgrip can hit very hard.
- Puncture [spell=15976]: Inflicts Physical damage to an enemy every 2 sec. for 10 sec.
- Fatal Bite [spell=16495]: Drains 100 health from an enemy, healing the caster for up to twice that amount.

#### Tinkerer Gizlock (NPC ids [13601])
Overview: Tinkerer Gizlock has some engineering tricks up his sleeve. Tanks, face him away from the group to prevent group damage from his Goblin Dragon Gun. Everyone else - stack close together in melee range. This will prevent Tinkerer Gizlock from using his ranged abilities. With this strategy in mind, he shouldn't be difficult to burn down.
Role notes: tank: Face the boss away from your group.
- Goblin Dragon Gun [spell=13183]: Deals 66 to 74 Fire damage for 10 sec to all targets in a cone in front of the Engineer. Deals 2 times as much damage to Beasts. That is unless it explodes.....
- Shoot [spell=6660]: Shoots at an enemy, inflicting Physical damage.
- Bomb [spell=8858]: Bombs all enemies in a selected area, inflicting Fire damage.

#### Meshlok the Harvester (Rare) (NPC ids [12237])
Overview: Meshlok the Harvester isn't very challenging. Tanks, tank him away from the group. Ranged and healers should spread out if possible to avoid his War Stomp, and be aware that he can interrupt your spellcasting with Earth Shock.
Role notes: tank: Face the boss away from your group.
- War Stomp [spell=11876]: Inflicts normal damage plus 23 to nearby enemies, knocking them back and stunning them for 5 sec.
- Earth Shock [spell=15501]: Shocks an enemy with concussive force, inflicting Nature damage and interrupting the spell being cast for 2 sec.
- Strike [spell=13446]: Strikes at an enemy, inflicting increased melee damage.

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Lord Vyletongue: npcs[] spells[Blink updated: Wording changed] newSpells[] loot[]
- Tinkerer Gizlock: npcs[] spells[Goblin Dragon Gun updated: Numbers and wording changed] newSpells[] loot[]


## Guide text
Source: https://www.wowhead.com/forever/guide=35197

Maraudon [zone=2100] is located in Desolace. This guide provides tips and strategies for completing Maraudon, including everything you need before and during the dungeon, quests to complete inside, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## Maraudon Overview in World of Warcraft: Forever

Protected by the fierce Maraudine centaur, Maraudon is one of the most sacred sites within Desolace. The great temple/cavern is the burial place of Zaetar, one of two immortal sons born to the demigod, Cenarius. Legend holds that Zaetar and the earth elemental princess, Theradras, sired the misbegotten centaur race. It is said that upon their emergence, the barbaric centaur turned on their father and killed him. Some believe that Theradras, in her grief, trapped Zaetar's spirit within the winding cavern - used its energies for some malign purpose. The subterranean tunnels are populated by the vicious, long-dead ghosts of the Centaur Khans, as well as Theradras' own raging, elemental minions.

The recommended level for Maraudon is between 45 and 52. 

## Location of Maraudon in World of Warcraft: Forever

Maraudon is located in the Valley of Spears north of Shadowprey Village and west of the Kodo Graveyard in Desolace [zone=405]. You’ll see large stone doors, marking the entrance, and centaurs guard the path leading in, so make sure to group up before entering.

Entrance to Maraudon

There are two separate entrances to the instance itself. 

The Ambershard pathway is lined with orange crystals, and is populated with plants. All of the boss drops in this section include Nature Resistance gear.

The Shadowshard is pathway lined with purple crystals. Most of the mobs on this side are demons.

The entire instance can be accessed once you are inside. Once you're able to acquire a Scepter of Celebras [item=17191], you'll be able to create a portal that leads to the base of Earth Song Falls, another section of Maraudon.

Once you pass through the massive stone doors, the path is pretty straightforward. 

As with many World of Warcraft: Forever Dungeons, wiping (the entire group dying) in Maraudon can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. 

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer as a ghost. You collect your body when you enter the instance.

## Every Quest in Maraudon in World of Warcraft: Forever

Hard: Level 41 | Medium: Level 44 | At Level: Level 46 | Easy: Level 50

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

NEW Shadowshard Fragments [quest=7068] | 43 |  |  |   | Mulgore, Skywatcher's Plateau - Olana Brighthoof [npc=268557] /way 32.6 24 | 

Shadowshard Fragments [quest=7068] | 39 |  |  |   | Orgrimmar, Valley of Spirits - Uthel'nay [npc=7311] /way 39 86 | 

Vyletongue Corruption [quest=7029] | 41 |  |  |   | Desolace, Shadowprey Village - Vark Battlescar [npc=11823] /way 23 70 | 

Corruption of Earth and Seed [quest=7064] | 45 |  |  |   | Desolace, S. of Shadowprey Village - Selendra [npc=13699] /way 26 77 | 

Shadowshard Fragments [quest=7070] | 39 |  |  |   | Dustwallow Marsh, Theramore - Archmage Tervosh [npc=4967] /way 66 49 | 

Vyletongue Corruption [quest=7041] | 41 |  |  |   | Desolace, Nijel's Point - Talendria [npc=11715] /way 68 8 | 

Corruption of Earth and Seed [quest=7065] | 45 |  |  |   | Desolace, Nijel's Point - Keeper Marandis [npc=13698] /way 63 10 | 

NEW Twisted Evils [quest=7028] | 35 | - |  |   | Shen'dralas Woodwyrd [npc=254674] /way 60 72
Starts with Strange Pylons [quest=92914] | 

Twisted Evils [quest=7028] | 41 | - |  |   | Desolace, SE of Thunderaxe Fortress- Willow [npc=13656] /way 62 39 | 

The Pariah's Instructions [quest=7067] | 39 | - |  |   | Desolace, South of Mannoroc Coven - Centaur Pariah [npc=13717] patrols around /way 48.4, 87.0 | 

Legends of Maraudon [quest=7044] | 41 | - |  |   | Maraudon, Orange side, outside instance - Cavindra [npc=13697] | 

The Scepter of Celebras [quest=7046] | 41 | - |  | Pre  | Maraudon, Purple side - Celebras the Redeemed [npc=13716]
CompleteLegends of Maraudon [quest=7044] first | 

Seed of Life [quest=7066] | 39 | - |  |   | Maraudon, Zaetar's Spirit [npc=12238] in middle of ring after killing Princess Theradras [npc=12201]  | 

Completing Dungeon Quests in World of Warcraft: Forever is a great way to gain some extra experience and gear. You will find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

The quests below include where to collect them, any prerequisites you need to complete first, and what you need to do inside or around Maraudon.

Faction: Both
Level Required: 39
Rewards:

- 
- 6,100 experience
- 150 reputation with Cenarion Circle {/forever/faction=609/cenarion-circle}

Seed of Life [quest=7066] - starts with Zaetar's Spirit [npc=12238] who appears once Princess Theradras [npc=12201] has been killed. He gives to you Seed of Life [item=17760] and asks you to give it to Keeper Remulos [npc=11832] in Moonglade [zone=493].

Keeper Remulos [npc=11832]

To get to Moonglade [zone=493] as a non-Druid {/forever/class=11/druid}, travel north through Timbermaw Hold, which is accessible through Felwood [zone=361] or Winterspring [zone=618]. You must be at least Unfriendly with Timbermaw Hold {/forever/faction=576/timbermaw-hold} for the furbolgs to not attack you. Feel free to check out my Timbermaw Hold Reputation Guide to learn more!

Druid {/forever/class=11/druid} can simply use Teleport: Moonglade [spell=18960].

Faction: Both
Level Required: 41
Rewards:

- Acumen Robes [item=17775], Sprightring Helm [item=17776], Relentless Chain [item=17777] or Hulkstone Pauldrons [item=17779]
- 5,250 experience

Twisted Evils [quest=7028] - starts with Willow [npc=13656] in Desolace [zone=405]:

Willow [npc=13656]

She asks you to collect 25 Theradric Crystal Carving [item=17684], which drop from various mobs within Maraudon [zone=2100]. The drop rate is pretty high, and if you do a full Maraudon [zone=2100] run, you shouldn't have a problem completing this quest. Return to Willow [npc=13656] once complete.

Faction: Both
Level Required: 39
Rewards:

- Mark of the Chosen [item=17774]
- 5,450 experience

The Pariah's Instructions [quest=7067] - starts with Centaur Pariah [npc=13717] who patrols around the pin on the map below, in Desolace [zone=405]:

Centaur Pariah [npc=13717]

He will provide you with The Pariah's Instructions [item=17781]. Venture into the gates of Maraudon [zone=2100] and your first objective is to look for The Nameless Prophet [npc=13718], who drops Amulet of Spirits [item=17757] for you. He wanders around in the area near the giant stone door entrance. 

The Nameless Prophet [npc=13718] drops Amulet of Spirits [item=17757].

Once you have Amulet of Spirits [item=17757], you must locate 5 Kahn Centaurs, and use Amulet of Spirits [item=17757] on them to make them hostile:

- Kolk [npc=13742], The First Kahn, is located just outside the little room where you create the portal to Inner Maraudon (middle part)
- Gelk [npc=13741], The Second Kahn, is located outside the portal of the purple side, hanging with the rock elementals
- Magra [npc=13740], The Third Kahn, is located outside the portal of the orange path, in the stairs area
- Maraudos [npc=13739], The Fourth Kahn, is located inside the purple instance, wandering not too far away from the entrance
- Veng [npc=13738], The Fifth Kahn, is located inside the orange path, wandering by the end

Each Kahn drops a gem and once you collect all 5, combine them with your Amulet of Spirits [item=17757] to create Amulet of Union [item=17758]:
Gem of the First Khan [item=17761], Gem of the First Khan [item=17761], Gem of the Third Khan [item=17763], Gem of the Fourth Khan [item=17764], Gem of the Fifth Khan [item=17765]

Return to Centaur Pariah [npc=13717] to complete your quest.

Faction: Both
Level Required: 41
Rewards:

- 3,400 experience

Legends of Maraudon [quest=7044] - starts with Cavindra [npc=13697], who you'll find on your way to the orange side of Maraudon [zone=2100].

Cavindra [npc=13697]

She asks you to collect:
Celebrian Diamond [item=17703] - drops from Lord Vyletongue [npc=12236] in the purple side
Celebrian Rod [item=17702] - drops from Noxxion [npc=13282] in the orange side

Once you have both items, defeat Celebras the Cursed [npc=12225] in Poison Falls. He will continue with The Scepter of Celebras [quest=7046].

Faction: Both
Level Required: 41
Rewards:

- Scepter of Celebras [item=17191]
- 5,700 experience

The Scepter of Celebras [quest=7046] - Assist Celebras the Redeemed [npc=13716] while he creates the Scepter of Celebras [item=17191]. Simply speak to Celebras the Redeemed [npc=13716] to proceed with the quest and assist him with his ritual. You'll receive Scepter of Celebras [item=17191], once finished.

Faction: Alliance
Level Required: 39
Rewards:

- Zealous Shadowshard Pendant [item=17772] or Prodigious Shadowshard Pendant [item=17773]
- 3,450 experience
- 150 reputation with Stormwind {/forever/faction=72/stormwind}

Shadowshard Fragments [quest=7070] - starts with Archmage Tervosh [npc=4967] in Dustwallow Marsh [zone=15]:

Archmage Tervosh [npc=4967]

He asks you to collect 10 Shadowshard Fragment [item=17756] and return to him when complete. These drop from Shadowshard Smasher [npc=11778] OUTSIDE the entrance to The Shadowshard Side (or purple) side. The drop rate is very high and the drops are shared with anyone else in your party who has the quest.

Shadowshard Smasher [npc=11778], outside the purple instance entrance

Faction: Alliance
Level Required: 41
Rewards:

- Woodseed Hoop [item=17768], Sagebrush Girdle [item=17778], or Branchclaw Gauntlets [item=17770]
- 5,250 experience

Vyletongue Corruption [quest=7041] - starts with Talendria [npc=11715] in Nijel's Point, Desolace [zone=405]:

Talendria [npc=11715]

She provides you with Coated Cerulean Vial [item=17693]. Now head to the orange side of Maraudon until you see a large orange-colored lake outside the instance entrance. Here is where you fill your Coated Cerulean Vial [item=17693], which will turn into Filled Cerulean Vial [item=17696]. Next, head inside the orange instance to proceed with the quest. Look for corrupted plants, pictured below, to use your vial on:

Several elemental mobs will spawn, once they're killed you'll receive quest credit. Repeat until 8 have been healed and return to Talendria [npc=11715] to turn in the quest.

Faction: Alliance
Level Required: 45
Rewards:

- Thrash Blade [item=17705], Verdant Keeper's Aim [item=17753], Resurgence Rod [item=17743]
- 6,100 experience
- 150 reputation with Cenarion Circle {/forever/faction=609/cenarion-circle}

Vyletongue Corruption [quest=7041] - starts with Keeper Marandis [npc=13698] in Nijel's Point, Desolace [zone=405]:

Keeper Marandis [npc=13698]

Corruption of Earth and Seed [quest=7065] - slay Princess Theradras [npc=12201] in Maraudon [zone=2100], then return to Keeper Marandis [npc=13698] to collect your prize.

## Horde Maraudon Quests

- Shadowshard Fragments [quest=7068]: Requires level 39, Shareable. Starts and ends with Uthel'nay [npc=7311] (39, 86), located in Valley of Spirits, Orgrimmar. Shadowshard Fragment [item=17756] drop from Shadowshard Rumbler [npc=11777] and Shadowshard Smasher [npc=11778] located on the Purple side outside of the instance. 
- Vyletongue Corruption [quest=7029]: Requires level 41, not shareable. Starts with Vark Battlescar [npc=11823] (23, 70) located in Shadowprey Villiage, on the west shore of Desolace. Requires you to fill the Coated Cerulean Vial [item=17693] outside of the Orange side of the instance, and then go inside to spawn the Noxxious Scion [npc=13696]. 
- Corruption of Earth and Seed [quest=7064]: Requires level 45, Shareable. Starts and ends with Selendra [npc=13699] (26, 77), located just south of Shadowprey Village, Desolace. You have to kill Princess Theradras [npc=12201], who is the last boss in the instance. 

Faction: Horde
Level Required: 39
Rewards:

- Zealous Shadowshard Pendant [item=17772] or Prodigious Shadowshard Pendant [item=17773]
- 3,450 experience
- 150 reputation with Darkspear Trolls {/forever/faction=530/darkspear-trolls}

Shadowshard Fragments [quest=7068] - starts with Uthel'nay [npc=7311] in Orgrimmar [zone=1637]:

Uthel'nay [npc=7311]

He asks you to collect 10 Shadowshard Fragment [item=17756] and return to him when complete. These drop from Shadowshard Smasher [npc=11778] OUTSIDE the entrance to The Shadowshard Side (or purple) side. The drop rate is very high and the drops are shared with anyone else in your party who has the quest.

Shadowshard Smasher [npc=11778], outside the purple instance entrance

Faction: Horde
Level Required: 41
Rewards:

- Woodseed Hoop [item=17768], Sagebrush Girdle [item=17778], or Branchclaw Gauntlets [item=17770]
- 5,250 experience

Corruption of Earth and Seed [quest=7064] - starts with Vark Battlescar [npc=11823] in Shadowprey Village, Desolace [zone=405]:

Vark Battlescar [npc=11823]

Vark provides you with Coated Cerulean Vial [item=17693]. Now, head to the orange side of Maraudon until you see a large orange-colored lake outside the instance entrance. Here is where you fill your Coated Cerulean Vial [item=17693], which will turn into Filled Cerulean Vial [item=17696]. Now, head inside the orange instance to proceed with the quest. Look for corrupted plants, pictured below, to use your vial on:

Several elemental mobs will spawn, once they're killed you'll receive quest credit. Repeat until 8 have been healed and return to Vark Battlescar [npc=11823] to turn in the quest.

Faction: Horde
Level Required: 45
Rewards:

- Thrash Blade [item=17705], Verdant Keeper's Aim [item=17753], Resurgence Rod [item=17743]
- 6,100 experience
- 150 reputation with Cenarion Circle {/forever/faction=609/cenarion-circle}

Corruption of Earth and Seed [quest=7064] - starts with Selendra [npc=13699] in Shadowprey Village, Desolace [zone=405]:

Selendra [npc=13699]

Corruption of Earth and Seed [quest=7064] - slay Princess Theradras [npc=12201] in Maraudon [zone=2100], then return to Selendra [npc=13699] to collect your prize.

### Best Quest Rewards

Type | Item | Quest | 

Trinket |  Mark of the Chosen [item=17774] |  The Pariah's Instructions
Pre-raid Best in Slot trinket option for Feral Druid Tanks, Warrior Tanks, Feral DPS, and Paladin Tanks. | 

Teleport Item |  Scepter of Celebras [item=17191] |  The Scepter of Celebras
Allows you to teleport approximately halfway through the Maraudon dungeon. | 

## Noteworthy Maraudon Trash Mobs in World of Warcraft: Forever

###  Shadowshard Side
The Wicked Grotto is the first area you'll discover once zoning in. You'll encounter an elite Putridus Satyr [npc=11790] and/or Putridus Trickster [npc=11791] mixed in with packs of non-elite Poison Sprite [npc=12216] who usually attack with ranged abilities. Putridus Shadowstalker [npc=11792] usually patrol areas in stealth, so keep an eye out for them!

Elementals that roam the area are Deeprot Stomper [npc=13141] who use War Stomp [spell=45] and Deeprot Tangler [npc=13142] who cast Entangling Roots [spell=12747]. The path leading up to Lord Vyletongue [npc=12236] is pretty straightforward. The biggest concern for you will be to not pull any unnecessary additional mobs, such as Putridus Shadowstalker [npc=11792] while fighting your way there.

###  Ambershard Side
Foulspore Cavern is the first area if you zone in from the entrance. You'll encounter elite mobs such as Barbed Lasher [npc=12219] and Constrictor Vine [npc=12220] mixed in with packs of non-elite Vile Larva [npc=12218] mixed in. A Hunter {/forever/class=3/hunter}'s Freezing Trap [spell=14310] works nicely here to help Crowd Control the elites.

As you make your way through the cavern, look for the Larva Spewer to click on to cease the arrival of more larvae, and you'll find Noxxion [npc=13282] waiting for you in a pool towards the end.

### Earth Song Falls

- Thessala Hydra [npc=12207] wander around and cast a knockback that could throw you into additional mobs. Be aware of your surroundings before engaging one.
- Subterranean Diemetradon [npc=13323] come in linked groups and cannot be pulled one at a time. Casters - STAND BACK! They have a nasty AoE silence that could jeopardize your group.
- Theradrim Guardian [npc=11784] patrol areas and split into smaller Theradrim Shardling [npc=11783] when killed. Some of them patrol with Theradrim Shardling [npc=11783] already spawned, trailing close behind. Be aware of this patrol as you wouldn't want to aggro one while already in combat with a different mob.
- Primordial Behemoth [npc=12206] are giants who hit hard and are, preferably, pulled one at a time. Make sure your tank maintains aggro on these guys as they can cause massive damage to cloth wearing friends.

Follow the path up to the highest point of the hill to the West, and you'll encounter the first boss of Earth Song Falls, Landslide [npc=12203].

## Maraudon Bosses in World of Warcraft: Forever

Lord Vyletongue [npc=12236] is a level 49 elite accompanied by two stealthed Putridus Shadowstalker [npc=11792] guards. 

Lord Vyletongue Abilities

- Auto Shot
- Multi-Shot [spell=14443]
- Smoke Bomb [spell=7964]
- Blink [spell=1953]

Lord Vyletongue Strategy

If the entire group stacks on Lord Vyletongue [npc=12236], you negate his ability to use Auto Shot & Multi-Shot [spell=14443], so have everyone stack close together on the tank. He'll use Blink [spell=1953] to get away, so make sure you are quick to stack up again whenever he does so. Most groups DPS Lord Vyletongue [npc=12236] down first since he is mobile and can move around the room. Once he's down, finish off his two guards.

Noxxion [npc=13282] is a level 48 elite and the first boss found in the Ambershard Side.

Noxxion Abilities

- Toxic Volley [spell=21687]
- Uppercut [spell=18072]
- Spawns smaller versions of self

Noxxion Strategy

Noxxion [npc=13282] has an AoE Toxic Volley [spell=21687] ability as well as a knockback called Uppercut [spell=18072]. After a little while, Noxxion [npc=13282] will split into smaller versions of himself. Once they're all defeated, Noxxion [npc=13282] will reform, and the fight will continue. Some groups opt to pull him out of the pool, to make killing the adds easier.

Continue down Foulspore Cavern and you'll run into Razorlash [npc=12258]. Some groups opt to skip this boss encounter, as it isn't mandatory to kill him to advance forward.

Razorlash [npc=12258] is a level 48 elite and the second boss found in the Ambershard Side.

Razorlash Abilities

- Cleave [spell=15284]
- Puncture [spell=15976]

Razorlash Strategy

Razorlash [npc=12258]'s Puncture [spell=15976] causes a painful DoT (damage over time) tick for 10 seconds, and an AoE Cleave [spell=15284] ability for those in melee range. Therefore, casters should stand at max range while burning him down.

After you kill Razorlash [npc=12258], continue forward to enter Poison Falls.

Meshlok the Harvester [npc=12237] is a level 48 elite, rare spawn inside Poison Falls who patrols the waters near the beginning and looks very similar to either a Cavern Lurker [npc=12223] or Cavern Shambler [npc=12224], so make sure you hover your mouse or use a /tar Meshlok macro to check to see if he is spawned. If he is not, Cavern Shambler [npc=12224] will patrol in his place.

Meshlok the Harvester Abilities

- War Stomp [spell=11876]
- Earth Shock [spell=15501]
- Strike [spell=13446]

Meshlok the Harvester ]Strategy

Meshlok the Harvester [npc=12237] isn't very challenging. Tanks, tank him away from the group. Ranged, spread out if possible to avoid his War Stomp [spell=11876] and healers, be aware that he can interrupt your spell casting with Earth Shock [spell=15501].

Celebras the Cursed [npc=12225] is a level 49 elite found at the end of Poison Falls.

Celebras the Cursed Abilities

- Wrath [spell=9739]
- Force of Nature [spell=6913]
- Entangling Roots [spell=12747]
- Twisted Tranquility [spell=21793]

Celebras the Cursed Strategy

Celebras the Cursed [npc=12225] has Druid {/forever/class=11/druid}-like abilities and summons non-elite Corrupt Force of Nature [npc=13743] to constantly spawn during the encounter. He will most often use his Wrath [spell=9739] spell, which can be interrupted, so make sure it's getting interrupted as often as possible. If one of his Corrupt Force of Nature [npc=13743] falls, he will summon another one. Focus down Celebras the Cursed [npc=12225] first, then polish off the remaining Corrupt Force of Nature [npc=13743].

After defeating Celebras the Cursed [npc=12225], you may now complete your quest to create Scepter of Celebras [item=17191]. This item is very significant, allowing players to create a portal outside the instance to teleport them directly to Earth Song Falls, the next section of the dungeon.

Landslide [npc=12203] is a level 50 elite Behemoth found in Poison Falls.

Landslide Abilities

- Trample [spell=5568]
- Knock Away [spell=10101]
- Summon Theradrim Shardling [npc=11783]

Landslide Strategy

Landslide [npc=12203] has many similar abilities to the Primordial Behemoth [npc=12206] that you fought on the way to his alcove. Keep him near the area in which he stands. Tanks, tank him with your back to a wall. Ranged, stay at max distance to avoid any knockback or stun from the Theradrim Shardling [npc=11783], who despawn once Landslide [npc=12203] dies.

Although considered the final boss of Maraudon [zone=2100], most groups will head to Princess Theradras [npc=12201] after killing Landslide [npc=12203], and then jump down to kill Rotgrip [npc=13596] and Tinkerer Gizlock [npc=13601] after. You'll fight more groups of Primordial Behemoth [npc=12206] before encountering Princess Theradras [npc=12201], this time in packs of 2. Make sure you focus down one at a time.

Princess Theradras [npc=12201] is a level 51 elite in Poison Falls.

Princess Theradras Abilities

- Dust Field [spell=21868]
- Repulsive Gaze [spell=21869]
- Boulder [spell=9483]

Princess Theradras Strategy

Princess Theradras [npc=12201] is not an easy fight, so understanding her mechanics is vital to your success. Groups tend to engage her towards the back of her cavern to allow for more space. She has a group of Fear called Repulsive Gaze [spell=21869]. Fear Ward [spell=6346], Berserker Rage [spell=18499] & Tremor Totem [spell=8143] are all spells to help with this effect.

She also has a pesky group knockback ability, Dust Field [spell=21868] which not only pushes you back, but damages as well. At max range, non-melee players should be able to avoid this. Also, be aware that there are non-aggressive turtles in the area around her cavern. If they get hit with a spell, they will aggro on you, so be mindful of your surroundings.

For max level players, the Princess can be stealth-run with a full group of Druids and Rogues.

Rotgrip [npc=13596] is a giant level 50 white crocolisk elite found in Poison Falls. He patrols in the water of Zaetar's Cave - the area in which you just defeated Princess Theradras [npc=12201]. Drop down into the water to engage him. Be sure the surrounding area is clear, as there are also lingering Hydra in the water.

Rotgrip Abilities

- Puncture [spell=15976]
- Fatal Bite [spell=16495]

Rotgrip Strategy

Rotgrip [npc=13596] hits hard! Make sure your tank has proper aggro before everyone else engages. Healers, try your best to keep your tank, and other party members topped off. Rotgrip [npc=13596] can dish out devastating damage quickly using his two abilities: Puncture [spell=15976], a physical damage-over-time, and Fatal Bite [spell=16495].

Now that Rotgrip [npc=13596] is dead, it's time to move on to your final boss encounter Tinkerer Gizlock [npc=13601]. Exit the waters and head on the path back up to the lower bridge of Rotgrip [npc=13596]'s area. Once reaching a flat area of land, take the eastern path downward. Make sure all mobs and patrols are clear before engaging Tinkerer Gizlock [npc=13601].

Tinkerer Gizlock [npc=13601] is a level 50 elite goblin found in Poison Falls.

Tinkerer Gizlock Abilities

- Goblin Dragon Gun [spell=13183]
- Shoot [spell=6660]
- Bomb [spell=8858]

Tinkerer Gizlock Strategy

Tinkerer Gizlock [npc=13601] has some Engineering {/forever/skill=202/engineering} tricks up his sleeve. Tanks, face him away from the group to prevent group damage from his Goblin Dragon Gun [spell=13183]. Everyone else - stack close together in melee range. This will prevent Tinkerer Gizlock [npc=13601] from being able to use his ranged abilities. With this strategy in mind, he shouldn't be difficult to burn down.

## Maraudon Loot in World of Warcraft: Forever

Item | Type | 

Infernal Trickster Leggings [item=17754] | Mail Legs | 

Satyr's Lash [item=17752] | Dagger | 

Satyrmane Sash [item=17755] | Cloth Waist with Shadow Resistance | 

Item | Type | 

Heart of Noxxion [item=17744] | Nature Resistance Trinket | 

Noxious Shooter [item=17745] | Nature Resistance Wand | 

Noxxion's Shackles [item=17746] | Nature Resistance Plate Wrist | 

Item | Type | 

Phytoskin Spaulders [item=17749] | Nature Resistance Leather Shoulders | 

Vinerot Sandals [item=17748] | Nature Resistance Cloth Boots | 

Brusslehide Leggings [item=17751] | Nature Resistance Leather Legs | 

Chloromesh Girdle [item=17750] | Nature Resistance Cloth Waist | 

Item | Type | 

Bloomsprout Headpiece [item=17767] | Nature Resistance Mail Helm | 

Fungus Shroud Armor [item=17742] | Leather Chest | 

Nature's Embrace [item=17741] | Cloth Chest | 

Item | Type | 

Claw of Celebras [item=17738] | Fist Weapon | 

Grovekeeper's Drape [item=17739] | Nature Resistance Cloak | 

Soothsayer's Headdress [item=17740] | Leather Helm | 

Item | Type | 

Cloud Stone [item=17737] | Offhand | 

Fist of Stone [item=17943] | 1H Mace | 

Helm of the Mountain [item=17734] | Plate Helm | 

Rockgrip Gauntlets [item=17736] | Mail Hands | 

Item | Type | 

Blade of Eternal Darkness [item=17780] | Dagger with unique proc | 

Blackstone Ring [item=17713] | pre-raid Best in Slot ring for many melee due to the 1% hit it provides, including Feral DPS, Feral Tank, Hunter, Paladin DPS, Rogue, Enhancement Shaman, Warrior DPS, Warrior Tanks | 

Bracers of the Stone Princess [item=17714] | Mail Wrist | 

Charstone Dirk [item=17710] | Dagger | 

Elemental Rockridge Leggings [item=17711] | Plate Legs | 

Eye of Theradras [item=17715] | Cloth Helm | 

Gemshard Heart [item=17707] | Neck | 

Princess Theradras' Scepter [item=17766] | 2H mace, notable leveling weapon for Paladins, Shaman, and Warriors | 

Item | Type | 

Albino Crocscale Boots [item=17728] | Leather Boots | 

Gatorbite Axe [item=17730] | 2H Axe, notable leveling weapon for Paladins, Shaman, and Warriors | 

Rotgrip Mantle [item=17732] | Cloth Shoulders | 

Item | Type | 

Gizlock's Hypertech Buckler [item=17718] | Shield, pre-raid Best in Slot for Healing Shaman. | 

Inventor's Focal Sword [item=17719] | 1H Sword, pre-raid Best in Slot for Warlocks | 

Megashot Rifle [item=17717] | Gun |

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/maraudon und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **Noxxion** [13282]: Uppercut (10966)
- **Razorlash** [12258]: Cleave (11427)
- **Landslide** [12203]: Knock Away (18670)
- **Princess Theradras** [12201]: Dust Field (21909), Boulder (21832)
- **Rotgrip** [13596]: Puncture (15976)
- **Tinkerer Gizlock** [13601]: Shoot (6660)
- **Meshlok the Harvester (Rare)** [12237]: Strike (13446)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: keine

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist
