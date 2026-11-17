# Scholomance - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=35270 (scholomance)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/scholomance


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/scholomance

Journal: areaId (zone) 2057; level range from journal: 55-60; kind dungeon

Journal description: The Scholomance is housed within a series of crypts that lie beneath the ruined keep of Caer Darrow. Once owned by the noble Barov family, Caer Darrow fell to ruin following the Second War. As the wizard Kel'thuzad enlisted followers for his Cult of the Damned he would often promise immortality in exchange for serving his Lich King. The Barov family fell to Kel'thuzad's charismatic influence and donated the keep and its crypts to the Scourge. The cultists then killed the Barovs and turned the ancient crypts into a school for necromancy known as the Scholomance. Though Kel'thuzad no longer resides in the crypts, devoted cultists and instructors still remain. The powerful lich, Ras Frostwhisper, rules over the site and guards it in the Scourge's name - while the mortal necromancer, Darkmaster Gandling, serves as the school's insidious headmaster.

### Journal quests (id, level as shown, side)
- Barov Family Fortune [quest=5341] level 60, Horde
- The Darkreaver Menace [quest=7668] level 60, Horde
- Barov Family Fortune [quest=5343] level 60, Alliance
- Plagued Hatchlings [quest=5529] level 58, both
- Healthy Dragon Scale [quest=5582] level 58, both
- Doctor Theolen Krastinov, the Butcher [quest=5382] level 60, both
- Krastinov's Bag of Horrors [quest=5515] level 60, both
- Kirtonos the Herald [quest=5384] level 60, both
- Dawn's Gambit [quest=4771] level 60, both
- The Lich, Ras Frostwhisper [quest=5466] level 60, both

### Journal bosses

#### Blood Steward of Kirtonos (NPC ids [14861])
Overview: She has a few curses that can be dispelled by Mages or Druids. If you can, dispel Paralyzing Poison, as it stuns the target for 8 seconds. With those two things in mind, DPS her down!
- Paralyzing Poison [spell=3609]: Stuns an enemy, rendering it unable to move or attack for 8 sec.
- Curse of Impotence [spell=22371]: Decreases the Magical damage dealt by the target by 1 for 2 min.
- Curse of Weakness [spell=11708]: Physical damage caused by the target is reduced by 37 for 2 min. Only one Curse per Warlock can be active on any one target.
Loot: Blood of Innocents [item=13523]

#### Kirtonos the Herald (NPC ids [10506])
Overview: Kirtonos can only be summoned if a person in your group has [item=13523]. Kirtonos the Herald has two different forms, each having a strategy. The tank should take aggro and keep their back to a wall to prevent knockback. In human form, Kirtonos the Herald uses his caster abilities. If you can, dispel Curse of Tongues from casters in your group. When Kirtonos the Herald transforms into his gargoyle form, it becomes a simple tank-and-spank fight.
Role notes: tank: Keep your back to a wall.
- Curse of Tongues [spell=12889]: Forces nearby enemies to speak in Demonic, reducing their casting speed by 50% for 15 sec. Only one curse per warlock can be active on any one target. | note: This reduces casting speed significantly, so dispel it from casters if you can. If melee are affected by this, it can be ignored.
- Disarm [spell=8379]: Disarms an enemy, forcing it to stop wielding its weapon for 10 sec.
- Dominate Mind [spell=14515]: Takes control of a humanoid enemy up to level 25 for 15 sec. | note: CC mind-controlled players until it wears off.
- Pierce Armor [spell=6016]: Reduces an enemy's armor by 50% for 20 sec.
- Shadow Bolt Volley [spell=17228]: Hurls missiles of dark magic, inflicting Shadow damage to nearby enemies.
- Swoop [spell=18144]: Inflicts normal damage plus 54 to enemies in a cone in front of the caster, stunning them for 2 sec. | note: This deals damage and stuns in a cone in front of the boss. Face the boss away from the group when tanking.
- Wing Flap [spell=12882]: Strikes enemies in a cone in front of the caster, knocking them back. | note: The tank should keep their back to a wall to prevent being knocked back.

#### Jandice Barov (NPC ids [10503])
Overview: Jandice Barov will create several copies of herself that spread throughout the room. You can't AoE them down, so you must target them down individually. Some parties opt to ignore the adds and just focus down Jandice herself. Mages and Druids should dispel Curse of Blood to reduce the damage your group takes.
- Summon Illusions [spell=17773]: Summons 15 illusions to aid the caster in combat and distract the enemy. Illusions last 30 sec.
- Curse of Blood [spell=16098]: Increases the Physical damage taken by nearby enemies by 2 for 10 min.
- Banish [spell=8994]: Banishes an enemy, preventing all action but making it invulnerable for up to 15 sec. Only one target can be banished at a time.
Loot: Krastinov's Bag of Horrors [item=13725], Blood of Innocents [item=13523]

#### Rattlegore (NPC ids [11622])
Overview: Pull Rattlegore once your surrounding area is clear. His abilities are melee-focused, and he hits like a truck! Ranged should keep back as far as possible. Tank Rattlegore facing away from the group.
- Knock Away [spell=10101]: Inflicts normal damage plus 30 to an enemy and knocks it back.
- War Stomp [spell=11876]: Inflicts normal damage plus 23 to nearby enemies, knocking them back and stunning them for 5 sec.
- Strike [spell=18368]: Strikes at an enemy, inflicting increased melee damage.
Loot: Viewing Room Key [item=13873]

#### Marduk Blackpool (NPC ids [10433])
Overview: Tanks should hold Marduk Blackpool in place while ranged stand back, ensuring they are not affected by his Defiling Aura. Melee, watch out for his Shadow Shield - it deals damage each time you attack it as long as it's active. Other than those two factors, he's pretty easy to burn down.
- Cleave [spell=11609]: A sweeping attack that does your weapon damage plus 32 to the target and a second nearby enemy.
- Defiling Aura [spell=17695]: Surrounds the caster with an aura that periodically reduces the Shadow resistance of nearby enemies by 100. The aura lasts until cancelled. | note: As the fight continues, nearby players will have their Shadow resistance reduced more and more. Non-melee can keep their distance to avoid stacking this.
- Shadow Shield [spell=12040]: Surrounds the caster with a shield woven of Shadow magic. The shield lasts 30 sec., absorbs up to 200 Physical or magical damage, and inflicts 10 damage to melee attackers.

#### Vectus (NPC ids [10432])
Overview: Vectus is a pretty squishy target with fire-based spells. Watch out for his AoE abilities, don't stand in fire, and you'll DPS him down pretty quickly.
- Blast Wave [spell=13021]: A wave of flame radiates outward from the caster, damaging all enemies caught within the blast for 464 to 545 Fire damage, and Dazing them for 50% reduced movement speed for 6 sec. | note: Keep your distance if you aren't melee.
- Flamestrike [spell=10216]: Calls down a pillar of fire, burning all enemies within the area for 384 to 468 Fire damage and an additional 332 Fire damage over 8 sec. Only one Flamestrike can be active per Mage at a time. | note: Move out of the AoE effect as soon as possible.

#### Ras Frostwhisper (NPC ids [10508])
Overview: Make sure the entire area surrounding Ras Frostwhisper is clear before engaging in the fight. He has several Frost-type magic spells and abilities. Tank, face him away from the group, watch out for his Fear, and plan an interrupt rotation to minimize his spellcasting.
- Fear [spell=12096]: Strikes fear in an enemy, causing it to flee in terror for up to 8 sec. Only 1 target can be feared at a time. | note: Prioritize interrupting this.
- Chill Nova [spell=18099]: Blasts nearby enemies for Frost damage, knocking them back and reducing their movement speed for up to 10 sec.
- Frost Armor [spell=18100]: Encases the caster in a layer of frost that lasts 30 min. The thick ice increases armor by 12, slows melee attackers' movement to 40%, and increases the time between their attacks by 100%.
- Frostbolt Volley [spell=8398]: Inflicts 1321 to 1403 Frost damage to nearby enemies, reducing their movement speed by 50% for 8 sec.
- Freeze [spell=18763]: Stuns an enemy and inflicts Frost damage every 3 sec. for 15 sec.
- Knock Away [spell=11130]: Inflicts normal damage plus 30 to nearby enemies and knocks them back.

#### Kormok (NPC ids [16118])
Overview: Kormok can be summoned in Ras Frostwhisper's room with the [item=22052] provided by one of the quests to kill him. If you don't get any of the quests that require you to kill him (as you receive two out of four random quests), you will be able to summon him in the future after completing the questline with the [item=22057] gifted to you at the end of the questline. The boss will summon adds throughout the fight. The tank should gather them up and DPS AoE them down when there are a few of them gathered.
- Summon Bone Mages [spell=27695]: 
- Summon Bone Minions [spell=27687]: 
- Bone Shield [spell=27688]:  | note: Can be dispelled or simply DPS through it.
- Enrage [spell=8269]: Increases the caster's attack speed by 60% and the Physical damage it deals by 50 for 2 min.
Loot: Left Piece of Lord Valthalak's Amulet [item=21984], Right Piece of Lord Valthalak's Amulet [item=22046]

#### Instructor Malicia (NPC ids [10505])
Overview: Instructor Malicia has a few heals at her disposal, so be sure to sort out an interrupt rotation to minimize her casting. Decurse Call of the Grave if you can.
- Slow [spell=13747]: Increases the time between nearby enemies' attacks by 54% and slows their movement by 60% for 10 sec.
- Corruption [spell=18376]: Corrupts nearby enemies, inflicting Shadow damage every 3 sec. for 24 sec.
- Renew [spell=8362]: Heals an ally for 5 damage every 3 sec. for 20 sec.
- Heal [spell=6064]: Heal your target for 634 to 713.
- Call of the Grave [spell=5137]: Inflicts 10 Shadow damage to an enemy after 60 sec.

#### Doctor Theolen Krastinov (NPC ids [11261])
Overview: Have your tank pull Doctor Theolen Krastinov and keep their back to a wall. He enrages at 50%, so be ready to use defensive and healing cooldowns. He has melee-only abilities, so keep the tank alive and burn him down.
Role notes: tank: Keep your back to a wall.
- Enrage [spell=8269]: Increases the caster's attack speed by 60% and the Physical damage it deals by 50 for 2 min. | note: The boss enrages at 50%, so save cooldowns for this.
- Rend [spell=11574]: Wounds the target causing them to bleed for 147 damage over 21 sec.
- Knock Away [spell=11130]: Inflicts normal damage plus 30 to nearby enemies and knocks them back.
Loot: Blood of Innocents [item=13523]

#### Lorekeeper Polkelt (NPC ids [10901])
Overview: Lorekeeper Polkelt has several toxic AoE abilities that are damaging when nearby. One strategy, an attempt to keep him at max range, is to have someone in your party pull Lorekeeper Polkelt and jump off the upper-level railing, and as Lorekeeper Polkelt runs around the stairs, your tank can pick him up on the lower level. The rest of the party, remaining on the upper level, can range attack him safely without having to worry about his AoE abilities. If anyone is infected with his Volatile Infection, make sure they spread out from the rest of the group.
- Volatile Infection [spell=18149]: Infects an enemy for 2 min., causing it to inflict 9 Nature damage to its nearby allies every 15 sec. | note: This periodically deals damage to all nearby allies. If you aren't able to remove it, the afflicted player should try to stay away from other group members.
- Corrosive Acid [spell=8245]: Reduces the armor of nearby enemies by 16 for 5 min.
- Noxious Catalyst [spell=5413]: Reduces an enemy's Nature resistance by 3 for 2 min.

#### The Ravenian (NPC ids [10507])
Overview: The Ravenian should be tanked against a wall, facing away from the rest of the group. It's a melee-centric fight, and he hits pretty hard and fast. Watch out for his AoE abilities and ensure that the tank has generated enough threat before engaging him in combat.
Role notes: tank: Tank the boss facing away from your group and with your back to the wall.
- Trample [spell=15550]: Inflicts Physical damage to nearby enemies.
- Sundering Cleave [spell=17963]: Hacks at the armor of an enemy and its nearby allies, affecting up to 3 targets. A target's armor is reduced by 24 per Sunder Armor. Can be applied up to 5 times. Lasts 30 sec.
- Knock Away [spell=11130]: Inflicts normal damage plus 30 to nearby enemies and knocks them back.
- Cleave [spell=20569]: A sweeping attack that does your weapon damage plus 50 to the target and a second nearby enemy.

#### Lord Alexei Barov (NPC ids [10504])
Overview: Lord Alexei Barov is considered one of the toughest bosses in Scholomance. Two skeletal bodyguards accompany him. In addition to that, the room he's in has toxic green liquid on the floor that you must not stand in. His bodyguards hit pretty hard, but they can be CC'd with [spell=10955] or [spell=10326], for example. His Unholy Aura constantly deals damage to nearby players. Tanks must pull Alexei back at max range, so the aura does not afflict the rest of the group. He will afflict players with a healing-reducing curse, Veil of Shadow, which is a high priority to decurse if you can. If you cannot cleanse the curse, healers, be sure to keep the tank topped off to the best of your ability, because when Veil of Shadow strikes, you'll have a lot of difficulty healing your tank for 15 seconds.
- Veil of Shadow [spell=17820]: Reduces healing effects for nearby enemies by 75% for 15 sec. | note: This significantly reduces the effectiveness of healing, and it's important to decurse this if you can. If your group can't remove this, be ready to use cooldowns to survive the duration.
- Unholy Aura [spell=17467]: Causes the caster to automatically inflict 150 Shadow damage every 2 sec. to nearby enemies. The aura lasts until cancelled. | note: Non-melee should stay far away to avoid taking damage from this.
- Immolate [spell=25309]: Burns the enemy for [169.5 * (((1)))] Fire damage and then an additional 275 Fire damage over 15 sec.

#### Lady Illucia Barov (NPC ids [10502])
Overview: The biggest concern with fighting Lady Illucia Barov is her ability to Dominate Mind, which is a Mind Control mechanic. Be sure to stun or CC whoever is afflicted with Dominate Mind. She can also cast an AoE Silence and Fear, so be sure her entire area is clear before engaging in combat.
Role notes: tank: Clear the area before pulling the boss.
- Dominate Mind [spell=14515]: Takes control of a humanoid enemy up to level 25 for 15 sec. | note: CC players who are mind-controlled until it wears off.
- Fear [spell=12542]: Strikes fear in an enemy, causing it to flee in terror for 4 sec. Only 1 target can be feared at a time.
- Silence [spell=12528]: Silences nearby enemies, preventing them from casting spells for 10 sec.
- Curse of Agony [spell=18671]: Curses nearby enemies with agony, inflicting Shadow damage every 3 sec. for 30 sec. Only one curse per warlock can be active on any one target.
- Shadow Shock [spell=17289]: Instantly lashes an enemy with dark magic, inflicting Shadow damage.

#### Darkmaster Gandling (NPC ids [1853])
Overview: Many tanks will keep Darkmaster Gandling in the center where he spawns, while the ranged will stay atop the stairs to keep a distance. He'll periodically teleport a player to an adjacent room, where they will be locked in until they defeat the enemies inside. Be aware and make plans in the event your tank or healer gets teleported. An interrupt order works nicely for when he casts Arcane Missiles.
- Shadow Portal [spell=17950]: Teleports an enemy to one of 6 locations within Scholomance. | note: Players will be randomly teleported to a nearby room with a few mobs in it. The player has to kill these mobs to unlock the door and return to the fight.
- Curse of the Darkmaster [spell=18702]: Reduces an enemy's Strength by 50 and Stamina by 50 for 1 min.
- Shadow Shield [spell=12040]: Surrounds the caster with a shield woven of Shadow magic. The shield lasts 30 sec., absorbs up to 200 Physical or magical damage, and inflicts 10 damage to melee attackers.
- Arcane Missiles [spell=25346]: Launches an Arcane Missile at the enemy, causing 213 Arcane damage.

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Blood Steward of Kirtonos: npcs[] spells[Curse of Weakness updated: Value increased by 19.4%; Wording changed] newSpells[] loot[]
- Marduk Blackpool: npcs[] spells[Cleave updated: Wording changed] newSpells[] loot[]
- Vectus: npcs[] spells[Flamestrike updated: Values increased by 0.8% and 0.4%, value decreased by 2.4%; Wording changed; Blast Wave updated: Numbers and wording changed] newSpells[] loot[]
- Ras Frostwhisper: npcs[] spells[Frostbolt Volley updated: Values increased by 484.5% and 484.6%] newSpells[] loot[]
- Instructor Malicia: npcs[] spells[Heal updated: Values decreased by 13.6% and 13.8%] newSpells[] loot[]
- Lorekeeper Polkelt: npcs[] spells[Noxious Catalyst updated: Value decreased by 93.3%] newSpells[] loot[]
- The Ravenian: npcs[] spells[Cleave updated: Wording changed] newSpells[] loot[]
- Lord Alexei Barov: npcs[] spells[Immolate updated: Values decreased by 39.2% and 46.1%] newSpells[] loot[]
- Darkmaster Gandling: npcs[] spells[Arcane Missiles updated: Value decreased by 7.4%] newSpells[] loot[]


## Guide text
Source: https://www.wowhead.com/forever/guide=35270

Scholomance [zone=2057] is located in Western Plaguelands. This guide provides tips and strategies for completing Scholomance, including everything you need before and during the dungeon, quests to complete inside, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## Scholomance Overview in World of Warcraft: Forever

The Scholomance is housed within a series of crypts that lie beneath the ruined keep of Caer Darrow. Once owned by the noble Barov family, Caer Darrow fell to ruin following the Second War. As the wizard Kel'thuzad enlisted followers for his Cult of the Damned he would often promise immortality in exchange for serving his Lich King. The Barov family fell to Kel'thuzad's charismatic influence and donated the keep and its crypts to the Scourge. The cultists then killed the Barovs and turned the ancient crypts into a school for necromancy known as the Scholomance. Though Kel'thuzad no longer resides in the crypts, devoted cultists and instructors still remain. The powerful lich, Ras Frostwhisper, rules over the site and guards it in the Scourge's name - while the mortal necromancer, Darkmaster Gandling, serves as the school's insidious headmaster.

The recommended level for Scholomance is between 55 and 60. 

## Location of Scholomance in World of Warcraft: Forever

Scholomance [zone=2057] is located in the southeastern part of the Western Plaguelands [zone=28], on an island named Caer’Darrow. It houses mostly humanoid and undead enemies. 

Scholomance
from Light's Hope Chapel
from Aerie Peak
Chillwind Camp
from Tarren Mill
from Undercity

Alliance players can fly to Chillwind Camp, or travel from Light’s Hope Chapel in the Eastern Plaguelands or from Aerie Peak in the Hinterlands to the south. 

Horde players can travel from Undercity in Tirisfal Glades to the west or from Tarren Mill in Hillsbrad Foothills through Alterec Mountains in the south. 

The entrance to the instance is located behind a locked gate, with three ways to get in:

- A party member with Skeleton Key [item=13704]
- A party member with Powerful Seaforium Charge [item=18594], requires Engineering 275.
- A rogue with Lockpicking {/forever/skill=633/lockpicking} 280 or higher
- Someone on the other side can use the torch to open the gate

Another alternative to getting in would be to have someone in your group kill themselves right before the gate, and resurrect on the other side. 

### The Key to Scholomance Questline
The Key to Scholomance quest line rewards you with Skeleton Key [item=13704], so you can enter Scholomance without needing someone to blow up the door, lock pick it, or open it from the other side. 

1. Scholomance [quest=5533] / Scholomance [quest=838] 
2. Skeletal Fragments [quest=5537] / Skeletal Fragments [quest=964]
3. Mold Rhymes With... [quest=5538] / Mold Rhymes With... [quest=5514]
4. Fire Plume Forged [quest=5801] / Fire Plume Forged [quest=5802]
5. Araj's Scarab [quest=5803] / Araj's Scarab [quest=5804]

First, if you haven’t already, pick up: A Call to Arms: The Plaguelands! [quest=5066] from any of the criers in your main city. This will lead you to Chillwind Camp in Alterac Mountains [zone=36] and have you speak to Commander Ashlam Valorfist [npc=10838], who will then proceed to give you Clear the Way [quest=5092].

Kill 10 Skeletal Flayer [npc=1783] & 10 Slavering Ghoul [npc=1791] in Sorrow Hill, a graveyard northeast of Chillwind Camp. After turning in that quest, you’ll then receive a follow-up quest, All Along the Watchtowers [quest=5097].

Using the Beacon Torch [item=12815], mark each tower in Andorhal; you will need to stand in the doorway of the tower to successfully mark it. Commander Ashlam Valorfist [npc=10838] will provide you with the beacon torch to light the doorways with. 

Proceed to Andorhal, a ghost town northwest of Chillwind Camp and find the four towers. This can get a bit tricky if you are solo, as elite mobs are guarding each tower, so I advise you to take a few friends with you.

- Tower 1 - 40, 71
- Tower 2 - 42, 66
- Tower 3 - 44, 63
- Tower 4 - 46, 71

Tower 1
Tower 2
Tower 3
Tower 4

Finally, upon completion, Commander Ashlam Valorfist [npc=10838] will give you Scholomance [quest=5533] to speak to Alchemist Arbington [npc=11056], who is standing a just few feet away.

Next up, you’ll receive Skeletal Fragments [quest=5537], asking you to kill undead skeletons around Andorhal and Sorrow Hill and loot them for the Skeletal Fragments [item=14619]. After collecting 15, return to the Alchemist Arbington [npc=11056] for the next quest.

Mold Rhymes With... [quest=5538] - now you must bring the Imbued Skeletal Fragments [item=14628] (provided to you) to Krinkle Goodsteel [npc=5411] in  [zone=369].

Krinkle Goodsteel [npc=5411] will follow up with the quest: Fire Plume Forged [quest=5801]. Take the Skeleton Key Mold [item=14644] & 2 Thorium Bar [item=12359] to the top of Fire Plume Ridge in Un'Goro Crater [zone=490]. Use the Skeleton Key Mold [item=14644] by the lava lake to forge the Unfinished Skeleton Key [item=14645]. Now return to Alchemist Arbington [npc=11056] at Chillwind Camp in Western Plaguelands [zone=28].

He follows up with Araj's Scarab [quest=5803]. Kill Araj the Summoner [npc=1852] and bring Araj's Scarab [item=14610] to Alchemist Arbington [npc=11056] at Chillwind Camp in Western Plaguelands [zone=28].
Araj's is located in the middle of Andorhal at 45, 69, east of the Town Hall, surrounded by a lot of undead. It can be a tough fight because of the sheer number of mobs, so be sure to bring a group of friends with you! Here is his location on the map:

Araj the Summoner [npc=1852]

The quest will be completed once you've looted Araj's Scarab [item=14610]. Return to Alchemist Arbington [npc=11056] who will give you one final follow-up quest, The Key to Scholomance [quest=5505]. Congratulations, you are now the owner of Skeleton Key [item=13704], the key to Scholomance [zone=2057]!

First, if you haven’t already, pick up: A Call to Arms: The Plaguelands! [quest=5093] from any of the criers in your main city. This will lead you to The Bulwark in Alterac Mountains [zone=36] and have you speak to High Executor Derrington [npc=10837], who will then proceed to give you Scarlet Diversions [quest=5096].

Proceed to the Scarlet Crusade’s base camp between Felstone Field and Dalson’s Tears, destroy their command tent and plant the Scourge Banner [item=12807] afterward. After turning in that quest, you’ll receive Flame in a Bottle [item=12814] and then a follow-up quest, All Along the Watchtowers [quest=5098].

Using the Beacon Torch [item=12815], mark each tower in Andorhal; you will need to stand in the doorway of the tower to successfully mark it. You will be provided with the beacon torch to light the doorways with.

Proceed to Andorhal, a ghost town northwest of Chillwind Camp and find the four towers. This can get a bit tricky if you are solo, as elite mobs are guarding each tower, so I advise you to take a few friends with you.

- Tower 1 - 40, 71
- Tower 2 - 42, 66
- Tower 3 - 44, 63
- Tower 4 - 46, 71

Tower 1
Tower 2
Tower 3
Tower 4

Finally, upon completion, High Executor Derrington [npc=10837] will give you Scholomance [quest=838] to speak to Apothecary Dithers [npc=11057], who is standing a just few feet away.

Next up, you’ll receive Skeletal Fragments [quest=964], asking you to kill undead skeletons around Andorhal and Sorrow Hill and loot them for the Skeletal Fragments [item=14619]. After collecting 15, return to the Apothecary Dithers [npc=11057] for the next quest.

Mold Rhymes With... [quest=5514] - now you must bring the Imbued Skeletal Fragments [item=14628] (provided to you) to Krinkle Goodsteel [npc=5411] in  [zone=369].

Krinkle Goodsteel [npc=5411] will follow up with the quest: Fire Plume Forged [quest=5802]. Take the Skeleton Key Mold [item=14644] & 2 Thorium Bar [item=12359] to the top of Fire Plume Ridge in Un'Goro Crater [zone=490]. Use the Skeleton Key Mold [item=14644] by the lava lake to forge the Unfinished Skeleton Key [item=14645]. Now return to Apothecary Dithers [npc=11057] at The Bulwark in Western Plaguelands [zone=28].

He follows up with Araj's Scarab [quest=5804]. Kill Araj the Summoner [npc=1852] and bring Araj's Scarab [item=14610] to Apothecary Dithers [npc=11057] at The Bulwark in Western Plaguelands [zone=28].

Araj the Summoner [npc=1852] is located in the middle of Andorhal at 45, 69, east of the Town Hall, surrounded by a lot of undead. It can be a tough fight because of the sheer number of mobs, so be sure to bring a group of friends with you! Here is his location on the map:

Araj the Summoner [npc=1852]

The quest will be completed once you've looted Araj's Scarab [item=14610]. Return to Apothecary Dithers [npc=11057] who will give you one final follow-up quest, The Key to Scholomance [quest=5511]. Congratulations, you are now the owner of Skeleton Key [item=13704], the key to Scholomance [zone=2057]!

As with many World of Warcraft: Forever Dungeons, wiping (the entire group dying) in Scholomance can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. Druids only have an in-combat resurrection spell and are unlikely to train it before Scholomance.

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer (marked on the map below) as a ghost. You collect your body when you enter the instance.

## Every Quest in Scholomance in World of Warcraft: Forever

Hard: Level 54 | Medium: Level 56 | At Level: Level 60

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

Barov Family Fortune [quest=5341] | 52 |  |  |   | Tirisfal Glades, The Bulwark - Alexi Barov [npc=11022] /way 83 71
Alexi Barov may be dead due to Alliance kill quest; 30m spawn timer | 

The Darkreaver Menace [quest=7668] | 58 |  |  | Pre | Shaman Only - Orgrimmar, Valley of Wisdom - Sagorne Creststrider [npc=13417] /way 38 35
CompleteMaterial Assistance [quest=7667] first | 

Barov Family Fortune [quest=5343] | 52 |  |  |   | Western Plaguelands, Chillwind Camp - Weldon Barov [npc=11023] /way 43 83
Weldon Barov may be dead due to Horde kill quest; 30m spawn timer | 

Plagued Hatchlings [quest=5529] | 55 | - |  |   | Eastern Plaguelands, Light's Hope Chapel - Betina Bigglezink [npc=11035] /way 81 59 | 

Healthy Dragon Scale [quest=5582]
Repeatable
 | 55 | - |  | Pre
Drop  | Scholomance, Healthy Dragon Scale [item=13920], drops from Plagued Hatchling [npc=10678]s
CompletePlagued Hatchlings [quest=5529] first - repeatable for Argent Dawn rep | 

Doctor Theolen Krastinov, the Butcher [quest=5382] | 55 | - |  |   | Western Plaguelands, Caer Darrow - Eva Sarkhoff [npc=11216] /way 70 73 | 

Krastinov's Bag of Horrors [quest=5515] | 55 | - |  | Pre  | Western Plaguelands, Caer Darrow - Eva Sarkhoff [npc=11216] /way 70 73
CompleteDoctor Theolen Krastinov, the Butcher [quest=5382] first | 

Kirtonos the Herald [quest=5384] | 55 | - |  |   | Western Plaguelands, Caer Darrow - Eva Sarkhoff [npc=11216] /way 70 73
CompleteKrastinov's Bag of Horrors [quest=5515] first; save Spectral Essence [item=13544] reward item | 

Dawn's Gambit [quest=4771] | 57 | - |  | Pre  | Eastern Plaguelands, Light's Hope Chapel - Betina Bigglezink [npc=11035] /way 81 59
Complete 9 quests, starting withBroodling Essence [quest=4726] first | 

The Lich, Ras Frostwhisper [quest=5466] | 57 | - |  | Pre  | Western Plaguelands, Caer Darrow - Magistrate Marduke [npc=11286] /way 70 74
Complete 8 quests, starting withDoctor Theolen Krastinov, the Butcher [quest=5382] first
Must have Spectral Essence [item=13544] equipped to see Magistrate Marduke  | 

Completing Dungeon Quests in World of Warcraft: Forever is a great way to gain some extra experience and gear. You will find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

The quests below include where to collect them, any prerequisites you need to complete first, and what you need to do inside or around Scholomance.

Plagued Hatchlings [quest=5529]
Faction: Both
Required Level: 55
Start: Betina Bigglezink [npc=11035]
End: Betina Bigglezink [npc=11035]
Goal: Kill 20 Plagued Hatchling [npc=10678] inside Scholomance [zone=2057]
Reward: 

- 6,200 experience
- reputation with Argent Dawn {/forever/faction=529/argent-dawn}

Plagued Hatchlings [quest=5529] starts with Betina Bigglezink [npc=11035], located at Light's Hope Chapel, Eastern Plaguelands [zone=139]:

Betina Bigglezink [npc=11035]

She asks you to kill 20 Plagued Hatchling [npc=10678], located inside Rattlegore [npc=11622]'s room of Scholomance [zone=2057], as highlighted on the map below:

Return to Betina Bigglezink [npc=11035] once finished to complete the quest.

Healthy Dragon Scale [quest=5582]
Faction: Both
Required Level: 55
Start: Healthy Dragon Scale [item=13920]
End: Betina Bigglezink [npc=11035]
Goal: Return Healthy Dragon Scale [item=13920] to Betina Bigglezink [npc=11035]
Reward: 

- experience
- reputation with Argent Dawn {/forever/faction=529/argent-dawn}

IMPORTANT: The Healthy Dragon Scale [item=13920] will only drop from Plagued Hatchling [npc=10678] AFTER you've completed & turned in Plagued Hatchlings [quest=5529]. As a result, you would discover this on a 2nd trip to Scholomance [zone=2057] or later. 

Bring the Healthy Dragon Scale [item=13920] back to Betina Bigglezink [npc=11035] - the same NPC for Plagued Hatchlings [quest=5529].

Part 1 of 3:
1. Doctor Theolen Krastinov, the Butcher [quest=5382]
2. Krastinov's Bag of Horrors [quest=5515]
3. Kirtonos the Herald [quest=5384]

Faction: Both
Required Level: 55
Start: Eva Sarkhoff [npc=11216]
End: Eva Sarkhoff [npc=11216]
Goal: Slay Doctor Theolen Krastinov [npc=11261] and burn Remains of Eva Sarkhoff [object=176544] & Remains of Lucien Sarkhoff [object=176545]
Reward: 

- 
- 6,600 experience

Doctor Theolen Krastinov, the Butcher [quest=5382] starts and ends with Eva Sarkhoff [npc=11216] in Caer Darrow, Western Plaguelands [zone=28]:

Eva Sarkhoff [npc=11216]

She asks you to kill Doctor Theolen Krastinov [npc=11261] & burn the remains located inside Doctor Theolen Krastinov [npc=11261]'s room:

Part 2 of 3:
1. Doctor Theolen Krastinov, the Butcher [quest=5382]
2. Krastinov's Bag of Horrors [quest=5515]
3. Kirtonos the Herald [quest=5384]

Faction: Both
Required Level: 55
Start: Eva Sarkhoff [npc=11216]
End: Eva Sarkhoff [npc=11216]
Goal: Kill Jandice Barov [npc=10503] and loot Krastinov's Bag of Horrors [item=13725]

Reward: 

- 
- 6,600 experience

Now, Eva Sarkhoff [npc=11216] asks you to return to Western Plaguelands [zone=28], slay Jandice Barov [npc=10503] and loot Krastinov's Bag of Horrors [item=13725]. Eva Sarkhoff [npc=11216]'s location is marked below:

Return to back Eva Sarkhoff [npc=11216] to complete your quest.

Part 3 of 3:
1. Doctor Theolen Krastinov, the Butcher [quest=5382]
2. Krastinov's Bag of Horrors [quest=5515]
3. Kirtonos the Herald [quest=5384]

Faction: Both
Required Level: 55
Start: Eva Sarkhoff [npc=11216]
End: Eva Sarkhoff [npc=11216]
Goal: Kill Kirtonos the Herald [npc=10506]

Reward: 

- 
- Penelope's Rose [item=15805] or Mirah's Song [item=15806]
- and Spectral Essence [item=13544]
- 8,300 experience

Eva Sarkhoff [npc=11216] wants you to go back into Scholomance [zone=2057] with the Blood of Innocents [item=13523] (Provided) you found inside Krastinov's Bag of Horrors [item=13725]. Place it in the brazier on the balcony, pictured below, to summon Kirtonos the Herald [npc=10506]. 

Note that Kirtonos the Herald [npc=10506] is not present inside Scholomance [zone=2057] unless he is summoned. Return to Eva Sarkhoff [npc=11216] to complete the quest.

The Lich, Ras Frostwhisper [quest=5466]

Faction: Both
Required Level: 57
Start: Magistrate Marduke [npc=11286]
End: Magistrate Marduke [npc=11286]
Goal: Kill Ras Frostwhisper [npc=10508] and collect Human Head of Ras Frostwhisper [item=13626]
Reward: 

- 
- Warblade of Caer Darrow [item=13982], Crown of Caer Darrow [item=13986] or Darrowspike [item=13984]
- and Darrowshire Strongguard [item=14002]
- 9,950 experience

The Lich, Ras Frostwhisper [quest=5466] starts and ends with Magistrate Marduke [npc=11286], located in Caer Darrow, Western Plaguelands [zone=28]. You won't see him until you complete the previous quest series from Eva Sarkhoff [npc=11216].

Magistrate Marduke [npc=11286]

Use Soulbound Keepsake [item=13752] (provided) on Ras Frostwhisper [npc=10508] which will revert him to mortal form. Kill him and recover the Human Head of Ras Frostwhisper [item=13626]:

Barov Family Fortune [quest=5343] / Barov Family Fortune [quest=5341]

Faction: Both
Required Level: 57
Start: Alexi Barov [npc=11022] / Weldon Barov [npc=11023]
End: Magistrate Marduke [npc=11286]
Goal: Collect The Deed to Brill [item=13471], The Deed to Caer Darrow [item=13448]The Deed to Southshore [item=13450], The Deed to Tarren Mill [item=13451]
Reward: 

- 
- 6,600 experience

Alliance: Barov Family Fortune [quest=5343] is a single quest that is picked up from Weldon Barov [npc=11023] at Chillwind Camp in the Western Plaguelands [zone=28]:

Weldon Barov [npc=11023]

Horde: Barov Family Fortune [quest=5341] is picked up from Alexi Barov [npc=11022] at The Bulwark in Tirisfal Glades [zone=85]:

Alexi Barov [npc=11022]

The objective of this quest is to loot the The Deed to Brill [item=13471], The Deed to Caer Darrow [item=13448], The Deed to Southshore [item=13450] & The Deed to Tarren Mill [item=13451] from inside Scholomance [zone=2057].

- The Deed to Southshore [item=13450]: in the large room after you cross the bridge from the instance portal. It's in a small corner next to a bookshelf on top of a desk.
- The Deed to Tarren Mill [item=13451]: It's on a desk to the right corner of the room before Dragon whelps.
- The Deed to Brill [item=13471]: In the room where Ras Frostwhisper [npc=10508] is at. He is a Lich.
- The Deed to Caer Darrow [item=13448]: In the room where Alexi Barov [npc=11022] is. It is one of the Six room with mini bosses at the bottom side.

The quest will be tagged as "Complete" once all of the items have been looted. Return to your respective quest giver to hand in the quest.

The Darkreaver Menace [quest=8258] is a part of the Shaman {/forever/class=7/shaman} epic class quest to obtain Skyfury Helm [item=20134].

The prerequisite to this quest is Material Assistance [quest=7667]. Sagorne Creststrider [npc=13417] in Orgrimmar [zone=1637] is where you obtain the quest. Travel to Scholomance [zone=2057] and use the Divination Scryer [item=18746] in the middle of the Great Ossuary’s basement to summon the spirits required for the quest. Death Knight Darkreaver [npc=14516] will appear and attack you, after which you must defeat him and loot Darkreaver's Head [item=18880].

The quest will be tagged as Complete once the item has been looted.

### Best Quest Rewards

Item | Type | Quest | 

Mirah's Song [item=15806] |  Sword |  Kirtonos the Herald | 

Penelope's Rose [item=15805] |  Off-hand |  Kirtonos the Herald | 

Darrowshire Strongguard [item=14002] |  Shield |  The Lich, Ras Frostwhisper | 

Warblade of Caer Darrow [item=13982] |  Sword |  The Lich, Ras Frostwhisper | 

## Noteworthy Scholomance Trash Mobs in World of Warcraft: Forever

### Reaimated Corpse
The Reanimated Corpse [npc=10481] is a undead trash mob located inside Scholomance [zone=2057].

Note: Reanimated Corpse [npc=10481] arise from the dead about 10 seconds after they are originally "killed". Be prepared for them to pop back up and attack you again!

### Risen Aberration
The Risen Aberration [npc=10485] is a undead, skeletal trash mob located inside Scholomance [zone=2057].

Note: Risen Aberration [npc=10485] are immune to non-Holy magic.

### Plagued Ghoul
The Plagued Ghoul [npc=16447] is a undead trash mob located inside Scholomance [zone=2057].

Note: Plagued Ghoul [npc=16447] spews out a poison cloud when it dies that deals about 350 nature damage per second. Be sure to clear the area around its corpse after killing it. You'll know where a safe distance is because a poison cloud will appear over its corpse.

### Crowd Control Abilities for Trash
As many of the mobs inside Scholomance [zone=2057] are either humanoid or undead, you can use several different crowd control techniques for a smoother run:

- Mind Control [spell=10912] - Priest {/forever/class=5/priest} can use on humanoids in large packs
- Shackle Undead [spell=10955] - Priest {/forever/class=5/priest} can use on undead mobs
- Turn Undead [spell=10326] - essentially a Paladin {/forever/class=2/paladin} fear for undead mobs
- Polymorph [spell=13323] - Mage {/forever/class=8/mage} can use on humanoids

You are not limited to these. Sap [spell=11297] and Freezing Trap [spell=14311] are examples of other crowd control methods if executed properly.

## Scholomance Bosses in World of Warcraft: Forever

Blood Steward of Kirtonos [npc=14861] is a level 57 elite located in the Reliquary.

Blood Steward of Kirtonos Abilities

- Curse of Impotence [spell=22371]
- Curse of Weakness [spell=11708]
- Paralyzing Poison [spell=3609]

Blood Steward of Kirtonos Strategy

She has a few curses that can be dispelled by Mage {/forever/class=8/mage} & Druid {/forever/class=11/druid}. Watch out for her Paralyzing Poison [spell=3609] as it stuns the target for 8 seconds. With those two things in mind, DPS her down!

Kirtonos the Herald [npc=10506] is a level 60 elite located out on the porch. He can only be summoned if a person in your group has Blood of Innocents [item=13523].

Kirtonos the Herald Abilities

- Curse of Impotence [spell=22371]
- Curse of Weakness [spell=11708]
- Paralyzing Poison [spell=3609]

Kirtonos the Herald Strategy

Kirtonos the Herald [npc=10506] has two different forms, each having a strategy. Tank, grab aggro and keep your back to a wall to prevent knockback. In human form, Kirtonos the Herald [npc=10506] uses his caster abilities, and have a Mage {/forever/class=8/mage} & Druid {/forever/class=11/druid} dispel the curse, especially if it's on your healer.

When Kirtonos the Herald [npc=10506] transforms into his gargoyle form, where it becomes more of a tank and spank fight so long as your tank maintains aggro.

Jandice Barov [npc=10503] is a level 61 elite who is found by using a torch on the south wall, as seen by the map below:

Jandice Barov Abilities

- Summons illusions of herself
- Curse of Blood [spell=8282]
- Banish [spell=18647]

Jandice Barov Strategy

Jandice Barov [npc=10503] will create several copies of herself that spread throughout the room. You can't AoE them down, so you must target them down individually. Some parties opt to ignore the adds and just focus down Jandice herself. Remember to have a Mage {/forever/class=8/mage} & Druid {/forever/class=11/druid} dispel her Curse of Blood [spell=8282].

Rattlegore [npc=11622] is a level 61 elite located in the Great Ossuary's Basement.

Rattlegore Abilities

- Knock Away [spell=18945]
- Strike [spell=15580]
- War Stomp [spell=11876]

Rattlegore Strategy

Pull Rattlegore [npc=11622] once your surrounding area is clear. His abilities are melee focused, and he hits like a truck! Ranged, keep back as far as possible. Tank, face Rattlegore [npc=11622] away from the group. Armor reducing abilities such as Sunder Armor [spell=11597] or Expose Armor [spell=11198] can help your team take him down quicker. Once dead, Rattlegore [npc=11622] drops Viewing Room Key [item=13873].

Marduk Blackpool [npc=10433] is a level 58 elite located in the Viewing Room of Scholomance [zone=2057].

Marduk Blackpool Abilities

- Cleave [spell=11609]
- Defiling Aura [spell=17695]
- Shadow Shield [spell=12040]

Marduk Blackpool Strategy

Tanks should hold Marduk Blackpool [npc=10433] in place while ranged stand back, ensuring they are not affected by his Defiling Aura [spell=17695]. Melee, watch out for his Shadow Shield [spell=12040] - it deals damage each time you attack it as long as it's active. Other than those two factors, he's pretty easy to burn down.

Vectus [npc=10432] is a level 60 elite located in the Viewing Room of Scholomance [zone=2057].

Vectus Abilities

- Blast Wave [spell=13021]
- Flamestrike [spell=10216]

Vectus Strategy

Vectus [npc=10432] is a pretty squishy target with fire-based spells. Watch out for his AoE abilities: don't stand in fire & you'll DPS him down pretty quickly.

Ras Frostwhisper [npc=10508] is a level 60 elite located along the passage through the Viewing Room.

Ras Frostwhisper Abilities

- Chill Nova [spell=18099]
- Frost Armor [spell=18100]
- Fear [spell=6215]
- Freeze [spell=16350]
- Frostbolt Volley [spell=8398]

Ras Frostwhisper Strategy

Make sure the entire area surrounding Ras Frostwhisper [npc=10508] is clear before engaging in the fight. He has several frost-type magic spells and abilities. Tank, face him away from the group, watch out for his Fear [spell=6215] and plan an interrupt rotation to minimize his spell casting.

There's an Alchemy Lab in Ras Frostwhisper [npc=10508]'s room. Here, you're able to create Flasks.

### Kormok
Kormok [npc=16118] can be summoned at Ras Frostwhisper [npc=10508]'s room in Scholomance with the Brazier of Beckoning [item=22052] provided by one of the quests to kill him. 

If you don't get any of the quests that require you to kill him (as you receive two out of four random quests), you will be able to summon him in the future after completing the questline with the Brazier of Invocation [item=22057] gifted to you at the end of the questline.

Instructor Malicia [npc=10505] is a level 60 elite located in the southern room on the upper floor of Scholomance [zone=2057].

Instructor Malicia Abilities

- Call of the Grave [spell=5137]
- Corruption [spell=25311]
- Heal [spell=6064]
- Renew [spell=25315]
- Slow [spell=6146]

Instructor Malicia Strategy
Instructor Malicia [npc=10505] has a few heals at her disposal, so be sure to sort out an interrupt rotation to minimize her casting. Have a Mage {/forever/class=8/mage} & Druid {/forever/class=11/druid} dispel her Call of the Grave [spell=5137] curse and DPS her down.

Doctor Theolen Krastinov [npc=11261] is a level 60 elite located in the Eastern room on the Upper Level, called The Hall of the Damned.

Doctor Theolen Krastinov Abilities

- Knock Away [spell=11130]
- Rend [spell=11574]
- Attack Speed increase at 50%

Doctor Theolen Krastinov Strategy
Have your tank pull Doctor Theolen Krastinov [npc=11261] and keep their back to a wall. At 50% health, his attack speed will dramatically increase. Great time to use defensive and healing cooldowns. He has melee-only abilities, so keep the tank alive and burn him down!

Lorekeeper Polkelt [npc=10901] is a level 60 elite located in the Northern room on the Upper Level.

Lorekeeper Polkelt Abilities

- Corrosive Acid [spell=8245]
- Noxious Catalyst [spell=5413]
- Volatile Infection [spell=3586]

Lorekeeper Polkelt Strategy
Lorekeeper Polkelt [npc=10901] has several toxic AoE abilities that are damaging when nearby. One strategy, an attempt to keep him at max range, is having someone in your party pull Lorekeeper Polkelt [npc=10901] and jump off the upper-level railing, and as Lorekeeper Polkelt [npc=10901] runs around the stairs, your tank can pick him up on the lower level. The rest of the party, remaining on the upper level, can range attack him safely without having to worry about his AoE abilities. If anyone is infected with his Volatile Infection [spell=3586], make sure they spread out from the rest of the group.

The Ravenian [npc=10507] is a level 60 elite located in the Southern room on the Lower Level (The Barov Family Vault).

The Ravenian Abilities

- Cleave [spell=20569]
- Knock Away [spell=11130]
- Sundering Cleave [spell=25174]
- Trample [spell=5568]

The Ravenian Strategy
The Ravenian [npc=10507] should be tanked against a wall, facing away from the rest of the group. It's a melee-centric fight, and he hits pretty hard and fast. Watch out for his AoE abilities and ensure that the tank has generated enough threat before engaging him in combat.

Lord Alexei Barov [npc=10504] is a level 60 elite located within the Eastern portion of the Lower Level (The Barov Family Vault).

Lord Alexei Barov Abilities

- Immolate [spell=25309]
- Unholy Aura [spell=28340]
- Veil of Shadow [spell=17820]

Lord Alexei Barov Strategy
Lord Alexei Barov [npc=10504] is considered one of the toughest bosses in Scholomance [zone=2057]. Two skeletal bodyguards accompany him. In addition to that, the room he's in has toxic green liquid on the floor that you must not stand in. His bodyguards hit pretty hard, but they can be CC'd with Shackle Undead [spell=10955] or Turn Undead [spell=10326], for example. 

His AoE aura, Unholy Aura [spell=28340], constantly ticks damage to anyone in range of it. Tanks must pull Alexei back at max range, so the aura does not afflict the rest of the group. His Veil of Shadow [spell=17820] can be detrimental to the group if not properly cleansed by a Mage {/forever/class=8/mage} & Druid {/forever/class=11/druid}. If you cannot cleanse the curse, healers, be sure to keep the tank topped off to the best of your ability, because when Veil of Shadow [spell=17820] strikes, you'll have a lot of difficulty healing your tank for 15 seconds.

Lady Illucia Barov [npc=10502] is a level 60 elite located within the Northern room of the Lower Level (The Barov Family Vault).

Lady Illucia Barov Abilities

- Bane of Agony [spell=11713]
- Dominate Mind [spell=14515]
- Fear [spell=6215]
- Silence [spell=12528]
- Shadow Shock [spell=17289]

Lady Illucia Barov Strategy
The biggest concern with fighting Lady Illucia Barov [npc=10502] is her ability to Dominate Mind [spell=14515], which is a Mind Control mechanic. Be sure to stun or CC whoever is afflicted with Dominate Mind [spell=14515]. She can also cast an AoE Silence [spell=12528] and Fear [spell=6215] and so be sure her entire area is clear before engaging in combat.

Darkmaster Gandling [npc=1853] is a level 61 elite located within the center of The Barov Family Vault, and spawns once you kill the final of the previous six bosses, so be sure you're not standing in the center to prematurely aggro him.

Darkmaster Gandling Abilities

- Arcane Missiles [spell=25346]
- Curse of the Darkmaster [spell=18702]
- Shadow Shield [spell=12040]
- Shadow Portal (periodically teleports player to an adjacent room)

Darkmaster Gandling Strategy
Many tanks will keep Darkmaster Gandling [npc=1853] in the center where he spawns, while the ranged will stay atop the stairs to keep a distance. He'll periodically teleport a player to an adjacent room, where they will be locked in until they defeat the enemies inside. Be aware and make plans in the event your tank or healer get teleported. An interrupt order works nicely for when he casts Arcane Missiles [spell=25346]. Have a Mage {/forever/class=8/mage} or Druid {/forever/class=11/druid} dispel  [spell=17802] as quickly as possible. Other than that, he has a lot of HP so properly execute the mechanics, and you'll be greatly rewarded for his defeat!

## Scholomance Loot in World of Warcraft: Forever

Item | Type | 

Blood of Innocents [item=13523] | needed to summon Kirtonos | 

Item | Type | 

Loomguard Armbraces [item=13969] | Mail Wrist | 

Heart of the Fiend [item=13960] | Amulet | 

Clutch of Andros [item=13956] | Cloth Waist | 

Stoneform Shoulders [item=13955] | Plate Shoulder | 

Frightalon [item=14024] | Dagger | 

Windreaver Greaves [item=13967] | Mail Feet | 

Gargoyle Slashers [item=13957] | Leather Hands | 

Gravestone War Axe [item=13983] | 2H Axe | 

Boots of Valor [item=16734] | T0 Warrior Set Boots | 

Corruptor's Scourgestone [item=12843] | Argent Dawn Rep | 

Item | Type | 

Wraithplate Leggings [item=18690] | Plate Legs | 

Phantasmal Cloak [item=18689] | Cloak | 

Royal Cap Spaulders [item=14548] | Mail Shoulder | 

Ghostloom Leggings [item=14545] | Leather Legs | 

 [item=14543] | Cloth Hands | 

Dreadmist Mantle [item=16701] | T0 Warlock Set Shoulders | 

Barovian Family Sword [item=14541] | 2H Sword | 

Staff of Metanoia [item=22394] | Staff | 

Blood of Innocents [item=13523] | Summons Kirtonos | 

Corruptor's Scourgestone [item=12843] | Argent Dawn reputation | 

Item | Type | 

Bone Golem Shoulders [item=18686] | Mail Shoulder | 

Bone Ring Helm [item=14539] | Leather Helm | 

Corpselight Greaves [item=14537] | Plate Feet | 

Deadwalker Mantle [item=14538] | Cloth Shoulder | 

Frightskull Shaft [item=14531] | 2H Mace | 

Rattlecage Buckler [item=14528] | Shield | 

Shadowcraft Boots [item=16711] | T0 Rogue Set Boots | 

Top Half of Advanced Armorsmithing: Volume II [item=18782] | Blacksmithing Plans | 

Viewing Room Key [item=13873] | Access to second part of instance | 

Invader's Scourgestone [item=12841] | Argent Dawn Rep | 

Item | Type | 

Death Knight Sabatons [item=18692] | Plate Feet | 

Ebon Hilt of Marduk [item=14576] | 1H Sword | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Item | Type | 

Dark Advisor's Pendant [item=18691] | Neck | 

Skullsmoke Pants [item=14577] | Cloth Legs | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Item | Type | 

Alanna's Embrace [item=13314] | Cloth Chest | 

Bonechill Hammer [item=14487] | 1H Mace | 

Boneclenched Gauntlets [item=14525] | Plate Hands | 

Death's Clutch [item=14503] | Leather Shoulder | 

Freezing Lich Robes [item=14340] | Cloth Chest | 

Frostbite Girdle [item=14502] | Leather Waist | 

Iceblade Hacker [item=13952] | 1H Axe | 

Intricately Runed Shield [item=18696] | Shield | 

Maelstrom Leggings [item=14522] | Mail Legs | 

Magister's Mantle [item=16689] | T0 Mage Set Shoulder | 

Shadowy Mail Greaves [item=18694] | Mail Feet | 

Shivery Handwraps [item=18693] | Cloth Hands | 

Spellbound Tome [item=18695] | Offhand | 

Recipe: Flask of Supreme Power [item=13521] | Alchemy Recipe | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

### Kormok

Item | Type | 

Amalgam's Band [item=22326] | Mp5 Ring | 

Band of the Steadfast Hero [item=22331] | Defense Ring | 

Blade of Necromancy [item=22332] | Caster One-Handed Sword | 

Ironweave Pants [item=22303] | Cloth Legs | 

Item | Type | 

Libram of Divinity [item=23201] | Paladin {/forever/class=2/paladin} Relic  | 

Totem of Sustaining [item=23200] | Shaman {/forever/class=7/shaman} Relic  | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Skin of Shadow [item=12753] | Crafting Reagent | 

Dark Rune [item=20520] | Consumable and Crafting Reagent | 

Shadowcraft Bracers [item=16710] | T0 Rogue Set Bracers | 

Burial Shawl [item=18681] | Cloth Shoulders | 

Ancient Bone Bow [item=18680] | Bow | 

Ghoul Skin Leggings [item=18682] | Leather Leggings | 

Hammer of the Vesper [item=18683] | 1H Mace | 

Dimly Opalescent Ring [item=18684] | Resistance Ring | 

Necropile Raiment {/forever/item-set=122/necropile-raiment} | Cloth Set Items | 

Cadaverous Garb {/forever/item-set=121/cadaverous-garb} | Leather Set Items | 

Bloodmail Regalia {/forever/item-set=123/bloodmail-regalia} | Mail Set Items | 

Deathbone Guardian {/forever/item-set=124/deathbone-guardian} | Plate Set Items | 

Item | Type | 

Libram of Divinity [item=23201] | Paladin {/forever/class=2/paladin} Relic  | 

Totem of Sustaining [item=23200] | Shaman {/forever/class=7/shaman} Relic  | 

Magister's Gloves [item=16684] | T0 Mage Set Gloves | 

Sawbones Shirt [item=14617] | BoP Shirt | 

Blood of Innocents [item=13523] | Summons Kirtonos | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Skin of Shadow [item=12753] | Crafting Reagent | 

Burial Shawl [item=18681] | Cloth Shoulders | 

Ancient Bone Bow [item=18680] | Bow | 

Ghoul Skin Leggings [item=18682] | Leather Leggings | 

Hammer of the Vesper [item=18683] | 1H Mace | 

Dimly Opalescent Ring [item=18684] | Resistance Ring | 

Necropile Raiment {/forever/item-set=122/necropile-raiment} | Cloth Set Items | 

Cadaverous Garb {/forever/item-set=121/cadaverous-garb} | Leather Set Items | 

Bloodmail Regalia {/forever/item-set=123/bloodmail-regalia} | Mail Set Items | 

Deathbone Guardian {/forever/item-set=124/deathbone-guardian} | Plate Set Items | 

Item | Type | 

Libram of Divinity [item=23201] | Paladin {/forever/class=2/paladin} Relic  | 

Totem of Sustaining [item=23200] | Shaman {/forever/class=7/shaman} Relic  | 

Dreadmist Wraps [item=16705] | T0 Warlock Set Gloves | 

Invader's Scourgestone [item=12841] | Argent Dawn rep | 

Dark Rune [item=20520] | Consumable and Crafting Reagent | 

Skin of Shadow [item=12753] | Crafting Reagent | 

Burial Shawl [item=18681] | Cloth Shoulders | 

Ancient Bone Bow [item=18680] | Bow | 

Ghoul Skin Leggings [item=18682] | Leather Leggings | 

Hammer of the Vesper [item=18683] | 1H Mace | 

Dimly Opalescent Ring [item=18684] | Resistance Ring | 

Necropile Raiment {/forever/item-set=122/necropile-raiment} | Cloth Set Items | 

Cadaverous Garb {/forever/item-set=121/cadaverous-garb} | Leather Set Items | 

Bloodmail Regalia {/forever/item-set=123/bloodmail-regalia} | Mail Set Items | 

Deathbone Guardian {/forever/item-set=124/deathbone-guardian} | Plate Set Items | 

Item | Type | 

Libram of Divinity [item=23201] | Paladin {/forever/class=2/paladin} Relic  | 

Totem of Sustaining [item=23200] | Shaman {/forever/class=7/shaman} Relic  | 

Wildheart Belt [item=16716] | T0 Druid Set Belt | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Dark Rune [item=20520] | Consumable and Crafting Reagent | 

Skin of Shadow [item=12753] | Crafting Reagent | 

Burial Shawl [item=18681] | Cloth Shoulders | 

Ancient Bone Bow [item=18680] | Bow | 

Ghoul Skin Leggings [item=18682] | Leather Leggings | 

Hammer of the Vesper [item=18683] | 1H Mace | 

Dimly Opalescent Ring [item=18684] | Resistance Ring | 

Necropile Raiment {/forever/item-set=122/necropile-raiment} | Cloth Set Items | 

Cadaverous Garb {/forever/item-set=121/cadaverous-garb} | Leather Set Items | 

Bloodmail Regalia {/forever/item-set=123/bloodmail-regalia} | Mail Set Items | 

Deathbone Guardian {/forever/item-set=124/deathbone-guardian} | Plate Set Items | 

Item | Type | 

Libram of Divinity [item=23201] | Paladin {/forever/class=2/paladin} Relic  | 

Totem of Sustaining [item=23200] | Shaman {/forever/class=7/shaman} Relic  | 

Lightforge Bracers [item=16722] | T0 Paladin Set Bracers | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Skin of Shadow [item=12753] | Crafting Reagent | 

Burial Shawl [item=18681] | Cloth Shoulders | 

Ancient Bone Bow [item=18680] | Bow | 

Ghoul Skin Leggings [item=18682] | Leather Leggings | 

Hammer of the Vesper [item=18683] | 1H Mace | 

Dimly Opalescent Ring [item=18684] | Resistance Ring | 

Necropile Raiment {/forever/item-set=122/necropile-raiment} | Cloth Set Items | 

Cadaverous Garb {/forever/item-set=121/cadaverous-garb} | Leather Set Items | 

Bloodmail Regalia {/forever/item-set=123/bloodmail-regalia} | Mail Set Items | 

Deathbone Guardian {/forever/item-set=124/deathbone-guardian} | Plate Set Items | 

Item | Type | 

Libram of Divinity [item=23201] | Paladin {/forever/class=2/paladin} Relic  | 

Totem of Sustaining [item=23200] | Shaman {/forever/class=7/shaman} Relic  | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Dark Rune [item=20520] | Consumable and Crafting Reagent | 

Skin of Shadow [item=12753] | Crafting Reagent | 

Burial Shawl [item=18681] | Cloth Shoulders | 

Ancient Bone Bow [item=18680] | Bow | 

Ghoul Skin Leggings [item=18682] | Leather Leggings | 

Hammer of the Vesper [item=18683] | 1H Mace | 

Dimly Opalescent Ring [item=18684] | Resistance Ring | 

Necropile Raiment {/forever/item-set=122/necropile-raiment} | Cloth Set Items | 

Cadaverous Garb {/forever/item-set=121/cadaverous-garb} | Leather Set Items | 

Bloodmail Regalia {/forever/item-set=123/bloodmail-regalia} | Mail Set Items | 

Deathbone Guardian {/forever/item-set=124/deathbone-guardian} | Plate Set Items | 

Item | Type | 

Corruptor's Scourgestone [item=12843] | Argent Dawn rep | 

Don Mauricio's Band of Domination [item=22433] | Caster Ring  | 

Pattern: Robe of the Void [item=14514] | Tailoring Pattern | 

Headmaster's Charge [item=13937] | Staff which grants intellect | 

 [item=13950] | Mail Belt | 

Witchblade [item=13964] | Spell Dagger | 

Boots of the Shrieker [item=13398] | Leather Boots | 

Vigorsteel Vambraces [item=13951] | Plate Wrist | 

Bonecreeper Stylus [item=13938] | Wand | 

Silent Fang [item=13953] | Sword with Silence effect | 

Tombstone Breastplate [item=13944] | Leather Chest | 

Devout Crown [item=16693] | T0 Priest Set Helm | 

Dreadmist Mask [item=16698] | T0 Warlock Set Helm | 

Wildheart Cowl [item=16720] | T0 Druid Set Helm | 

Beaststalker's Cap [item=16677] | T0 Hunter Set Helm | 

Helm of Valor [item=16731] | T0 Warrior Set Helm | 

Magister's Crown [item=16686] | T0 Mage Set Helm | 

Shadowcraft Cap [item=16707] | T0 Rogue Set Helm | 

Lightforge Helm [item=16727] | T0 Paladin Set Helm | 

Coif of Elements [item=16667] | T0 Shaman Set Helm | 

It is worth noting that the Bind-on-Equip items that drop can be found from both trash mobs except for Magister's Gloves [item=16684] which drop from Doctor Theolen Krastinov [npc=11261] and Dreadmist Wraps [item=16705] from Lorekeeper Polkelt [npc=10901]. There are also items that drop from both trash mobs and dungeon bosses, such as Shadowcraft Bracers [item=16710] from Instructor Malicia [npc=10505], Wildheart Belt [item=16716] from The Ravenian [npc=10507] and Lightforge Bracers [item=16722] from Lord Alexei Barov [npc=10504]. 

Item | Type | 

Wildheart Bracers [item=16714] | Leather Wrist | 

Bindings of Elements [item=16671] | Mail Wrist | 

Lightforge Bracers [item=16722] | Plate Wrist | 

Magister's Belt [item=16685] | Cloth Waist | 

Dreadmist Belt [item=16702] | Cloth Waist | 

Wildheart Belt [item=16716] | Leather Waist | 

Icy Tomb Spaulders [item=18699] | Leather Shoulder | 

Dreadmist Wraps [item=16705] | Cloth Hands | 

Shadowcraft Bracers [item=16710] | Leather Wrist | 

Coldstone Slippers [item=18697] | Cloth Feet | 

Magister's Gloves [item=16684] | Cloth Hands | 

Tattered Leather Hood [item=18698] | Leather Helm | 

Bonebrace Hauberk [item=14536] | Mail Chest | 

Malefic Bracers [item=18700] | Leather Wrist | 

Belt of the Ordained [item=18702] | Plate Waist | 

Innervating Band [item=18701] | Unique Finger |

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/scholomance und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **Blood Steward of Kirtonos** [14861]: Paralyzing Poison (3609), Curse of Weakness (11708)
- **Kirtonos the Herald** [10506]: Disarm (8379), Dominate Mind (14515), Pierce Armor (6016), Shadow Bolt Volley (17228)
- **Jandice Barov** [10503]: Curse of Blood (16098), Banish (8994)
- **Rattlegore** [11622]: Knock Away (10101), Strike (18368)
- **Ras Frostwhisper** [10508]: Fear (12096), Frost Armor (18100), Freeze (18763), Knock Away (11130)
- **Kormok** [16118]: Summon Bone Mages (27695), Enrage (8269)
- **Instructor Malicia** [10505]: Slow (13747), Corruption (18376), Renew (8362)
- **Lorekeeper Polkelt** [10901]: Volatile Infection (18149), Noxious Catalyst (5413)
- **The Ravenian** [10507]: Trample (15550), Sundering Cleave (17963)
- **Lord Alexei Barov** [10504]: Unholy Aura (17467)
- **Lady Illucia Barov** [10502]: Fear (12542), Curse of Agony (18671)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: 5066, 5092, 5093, 5096, 5097, 5098, 5505, 5511

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist

## Abilities from other sources

Quelle: warcraft.wiki.gg (Seiten "<Boss>" / "<Boss> (Classic)", Lizenz CC BY-SA 3.0: Inhalt hier paraphrasiert, nur Fakten/IDs). Alle Klassik-Quellen: **classic-source, unverified for Forever**. Seiten mischen teils Retail-Legacy-Werte (Level 15-30) mit Classic.

| Boss (NPC) | Ability | Spell ID | Was es tut | Umgang | Confidence |
|---|---|---|---|---|---|
| Kirtonos the Herald (10506) | Disarm | 8379 | Waffe 10 s unbenutzbar | - | mittel |
| | Dominate Mind | 14515 | Uebernimmt Humanoiden bis Lvl 25 fuer 15 s | Opfer nicht burst-en | mittel |
| | Pierce Armor | 6016 | Ruestung -50% fuer 10 s | - | mittel |
| | Shadow Bolt Volley | 17228 | Schattenschaden an nahe Gegner | Heiler einplanen | mittel |
| | Swoop / Wing Flap | 18144 / 12882 | Frontalkegel mit 2 s Betaeubung / Frontal-Rueckstoss | Am Treppenende tanken, Rueckstoss aus dem Fenster = Zone raus | mittel |
| Jandice Barov (10503) | Curse of Blood | 16098 | Nahe Gegner nehmen mehr physischen Schaden (10 min) | - | mittel |
| | Summon Illusions | 17773 | 15 Kopien fuer 30 s | /focus auf die echte (halb leere Lebensleiste), Kick, burst | mittel |
| | Banish | 8994 | Ein Ziel bis 5 s handlungsunfaehig, unverwundbar | - | mittel |
| Rattlegore (11622) | Knock Away / Strike / War Stomp | 10101 / 18368 / 16727 | Rueckstoss / Zusatzschlag / 5 s Betaeubung im Umkreis | Patrouillen vorher raeumen, Adds shackeln | mittel |
| Ras Frostwhisper (10508) | Fear / Freeze / Frost Armor / Knock Away | 12096 / 18763 / 18100 / 11130 | Furcht 8 s / Betaeubung + Frost-DoT / verlangsamt Nahkaempfer / Rueckstoss | Lange Heilerphase; Chill Nova 18099 und Frostbolt Volley 8398 ebenfalls vorhanden | hoch |
| Instructor Malicia (10505) | Slow / Corruption / Renew | 13747 / 18376 / 8362 | Verlangsamt Gruppe / Schatten-DoT / Heal-ueber-Zeit | Mana entziehen, dann Nahkampf; weitere: Call of the Grave 17831, Flash Heal 17843, Heal 15586 | mittel |
| Lorekeeper Polkelt (10901) | Volatile Infection / Noxious Catalyst | 18149 / 18151 | Infiziertes Ziel schadet Nahen (2 min) / Naturresistenz -89 | Infizierten wegbewegen, dispellen; Corrosive Acid 8245 | mittel |
| The Ravenian (10507) | Trample / Sundering Cleave | 15550 / 17963 | Flaechenschaden / stapelnder Ruestungsabzug auf bis 3 Ziele | Tank-Heiler-Mana wird knapp; Knock Away 18670, Cleave 40504 | mittel |
| Lord Alexei Barov (10504) | Unholy Aura | 17467 | Dauerhafter Schattenschaden in Reichweite | Schattenresistenz/-aura, von Fernkaempfern wegtanken; Immolate 15570, Veil of Shadow 17820 (Heilung -75%) | hoch |
| Lady Illucia Barov (10502) | Fear / Curse of Agony | 12542 / 18671 | Furcht 4 s / Schatten-DoT | Schattenresistenz; Dominate Mind 14515, Shadow Shock 17289, Silence 12528 (Level-Bereich evtl. Retail-Legacy, unsicher) | niedrig |
| Kormok (16118) | Summon Bone Mages / Enrage | 27695 / 8269 | 2 Elite-Magier die Heiler jagen / +Angriffstempo | Magier sofort toeten oder kicken; Bone Shield 27688 dispellen; Bone Minions 27687, Bloodlust 27689 | mittel |

Offen: Blood Steward of Kirtonos (14861) - keine Quelle gefunden (Spells 3609, 11708 nur aus Wowhead-Journal).
Quelle-URLs: https://warcraft.wiki.gg/wiki/Kirtonos_the_Herald, /Jandice_Barov_(Classic), /Rattlegore_(Classic), /Ras_Frostwhisper, /Instructor_Malicia_(Classic), /Lorekeeper_Polkelt, /The_Ravenian_(Classic), /Lord_Alexei_Barov, /Lady_Illucia_Barov, /Kormok
