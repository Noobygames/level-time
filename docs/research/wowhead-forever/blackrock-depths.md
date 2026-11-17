# Blackrock Depths - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=35206 (brd)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/blackrock-depths


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/blackrock-depths

Journal: areaId (zone) 1584; level range from journal: 52-60; kind dungeon

Journal description: Once the capital city of the Dark Iron dwarves, this volcanic labyrinth now serves as the seat of power for Ragnaros the Firelord. Ragnaros has uncovered the secret to creating life from stone and plans to build an army of unstoppable golems to aid him in conquering the whole of Blackrock Mountain. Obsessed with defeating Nefarian and his draconic minions, Ragnaros will go to any extreme to achieve final victory.

### Journal quests (id, level as shown, side)
- Ribbly Screwspigot [quest=4136] level 53, both
- The Heart of the Mountain [quest=4123] level 55, both
- Attunement to the Core [quest=7848] level 60, both
- Dark Iron Legacy [quest=3802] level 52, both
- The Love Potion [quest=4201] level 54, both
- A Taste of Flame [quest=4024] level 58, both
- Overmaster Pyron [quest=4262] level 52, Alliance
- Incendius! [quest=4263] level 56, Alliance
- The Good Stuff [quest=4286] level 56, Alliance
- Hurley Blackbreath [quest=4126] level 55, Alliance
- Kharan Mighthammer [quest=4341] level 59, Alliance
- The Fate of the Kingdom [quest=4362] level 59, Alliance
- Marshal Windsor [quest=4241] level 54, Alliance
- Jail Break! [quest=4322] level 58, Alliance
- KILL ON SIGHT: Dark Iron Dwarves [quest=4081] level 52, Horde
- Lost Thunderbrew Recipe [quest=4134] level 55, Horde
- KILL ON SIGHT: High Ranking Dark Iron Officials [quest=4082] level 54, Horde
- The Rise of the Machines [quest=4063] level 58, Horde
- Disharmony of Flame [quest=3906] level 52, Horde
- Disharmony of Fire [quest=3907] level 56, Horde
- Commander Gor'shak [quest=3981] level 52, Horde
- The Last Element [quest=7201] level 54, Horde
- Operation: Death to Angerforge [quest=4132] level 58, Horde
- The Royal Rescue [quest=4003] level 59, 0

### Journal bosses

#### High Interrogator Gerstahn (NPC ids [9018])
Overview: Overall, the approach to beating her is fairly simple. Her use of Psychic Scream is the most challenging part of the encounter, as it can lead to other packs being pulled. Shamans should use Tremor Totem, and priests can use Fear Ward. Further, Warrior tanks can attempt Berserker Rage, but the inability to effectively time and predict the fear makes utilizing this more about luck than timing. As for other tank/healer combinations and for DPS, attempt to wedge yourself deeply in a corner to attempt to mitigate some of the fear effects. Apart from the fear, dispel Shadow Word: Pain and interrupt the Mana Burn.
- Psychic Scream [spell=13704]: Lets out a psychic scream, causing up to 5 nearby enemies to flee for 6 sec. | note: Shamans should use [spell=8143], and Priests [spell=6346] to help negate this.
- Shadow Shield [spell=12040]: Surrounds the caster with a shield woven of Shadow magic. The shield lasts 30 sec., absorbs up to 200 Physical or magical damage, and inflicts 10 damage to melee attackers. | note: This shield doesn't absorb much damage and can just be ignored.
- Mana Burn [spell=14033]: Hits an enemy with an anti-mana bolt. For each point of mana consumed by the bolt, the target takes 0.5 damage.
- Shadow Word: Pain [spell=14032]: Utters a word of darkness, inflicting Shadow damage to an enemy every 3 sec. for 18 sec.
Loot: Prison Cell Key [item=11140]

#### Lord Roccor (NPC ids [9025])
Overview: Lord Roccor is incredibly easy. There is nothing really to look out for. Earth Shock can interrupt casting, which is about the only real concern on this boss.
- Ground Tremor [spell=6524]: Stuns nearby enemies, rendering them unable to move or attack for 2 sec.
- Flame Shock [spell=13729]: Instantly burns an enemy, then inflicts additional Fire damage every 3 sec. for 12 sec.
- Earth Shock [spell=13728]: Shocks an enemy with concussive force, inflicting Nature damage and interrupting the spell being cast for 2 sec.
Loot: Formula: Smoking Heart of the Mountain [item=11813]

#### Houndmaster Grebmar (NPC ids [9319])
Overview: Houndmaster Grebmar patrols around the room between two packs of hounds. Kill the pack of hounds opposite his patrol path. Then, when he patrols back, kill the other pack. Once both packs are dead.
Role notes: tank: Clear the hounds from the room before pulling the boss.
- Demoralizing Shout [spell=13730]: Reduces the melee attack power of nearby enemies by 10 for 30 sec.
- Bloodlust [spell=21049]: Increases an ally's attack speed by 30% for 30 sec.
- Pummel [spell=15615]: Pummels an enemy for 45 damage and interrupts the spell being cast for 5 sec.

#### Ring of the Law (NPC ids [9027, 9028, 9029, 9030, 9031, 9032])
Overview: Ring of the Law is, potentially, the most difficult aspect of the first half of Blackrock Depths. The randomness of the encounter can cause issues if the group is not prepared for the possibilities. There are multiple possible bosses, which could be more optimal for some group compositions compared to others.
Stage Gorosh the Dervish: Gorosh the Dervish is like a warrior with Whirlwind and Mortal Strike. Maximize healing output outside of the Mortal Strike debuff. It is an easy fight as long as the healer can keep players up through Mortal Strike.
- Whirlwind [spell=15589] (npc=9027): 
- Mortal Strike [spell=15708] (npc=9027): Inflicts 300% weapon damage and leaves the target wounded, reducing the effectiveness of any healing by 50% for 5 sec.
- Bloodlust [spell=21049] (npc=9027): Increases an ally's attack speed by 30% for 30 sec.
Stage Grizzle: Grizzle is an easy boss, though he can deal a lot of damage once he enrages.
- Cleave [spell=15579]: Inflicts normal damage plus 40 to an enemy and its nearest allies, affecting up to 3 targets.
- Enrage [spell=8269] (npc=9028): Increases the caster's attack speed by 60% and the Physical damage it deals by 50 for 2 min. | note: The boss enrages at low health, increasing his attack speed and damage.
- Ground Tremor [spell=6524] (npc=9028): Stuns nearby enemies, rendering them unable to move or attack for 2 sec.
Stage Eviscerator: Eviscerator is more annoying than difficult. Shadow Bolt Volley can be rather annoying, but it shouldn't kill the group. That said, priests can utilize [spell=16874] to their advantage here. The additional shadow resistance makes the fight trivial.
- Anti-Magic Shield [spell=7121] (npc=9029): Creates an anti-magic shell around the caster, giving it magic immunity for 10 sec. | note: This grants complete immunity; don't waste mana casting into it.
- Shadow Bolt Volley [spell=28599] (npc=9029): Hurls missiles of dark magic, inflicting Shadow damage to nearby enemies.
- Vicious Rend [spell=16095] (npc=9029): Inflicts Physical damage to an enemy every 3 sec. for 15 sec.
Stage Ok'Thor the Breaker: Ok'thor the Breaker is the most difficult boss in Ring of the Law because of the number of abilities. He plays like a Mage, and bad Polymorph luck could lead to a wipe. The key is to dispel the Polymorph and have as many members stay at range as possible to minimize the effect of Arcane Explosion.
- Polymorph [spell=14621] (npc=9030): Transforms you into a sheep, forcing you to wander around for up to 20 sec. While wandering, you cannot attack or cast spells and any damage will transform you back into your normal form.
- Arcane Explosion [spell=26192] (npc=9030): Sends out a blast wave of magic, inflicting Arcane damage to nearby enemies.
- Arcane Bolt [spell=25055] (npc=9030): Hurls a magical bolt at an enemy, inflicting Arcane damage.
- Slow [spell=13747] (npc=9030): Increases the time between nearby enemies' attacks by 54% and slows their movement by 60% for 10 sec.
Stage Anub'Shiah: Anub'shiah is almost as difficult as Ok'thor the Breaker. Curse of Tongues and Enveloping Web both need an immediate dispel. These are the difficult mechanics. The rest aren't too tricky. No real strategy is needed other than the dispels.
- Shadow Bolt [spell=15472] (npc=9031): Hurls a bolt of dark magic at an enemy, inflicting Shadow damage.
- Curse of Tongues [spell=15470] (npc=9031): Forces nearby enemies to speak in Demonic, reducing their casting speed by 50% for 15 sec. Only one curse per warlock can be active on any one target.
- Curse of Weakness [spell=12493] (npc=9031): Reduces the Physical damage dealt by an enemy by 1 for 2 min. Only one curse per warlock can be active on any one target.
- Demon Armor [spell=13787] (npc=9031): Protects the caster, increasing armor by 210, Shadow resistance by 3, and health regeneration for 30 min.
- Enveloping Web [spell=15471] (npc=9031): Immobilizes an enemy, increases the time between its attacks by 100%, and prevents it from casting spells for 8 sec.
Stage Hedrum the Creeper: Hedrum the Creeper is a fairly straightforward boss. No real strategy is present outside of cleansing the poisons and dispelling the Immobilize.
- Baneful Poison [spell=15475] (npc=9032): Inflicts 600 Nature damage and an additional 2 damage every 5 sec. to nearby enemies for 2 min.
- Paralyzing Poison [spell=3609] (npc=9032): Stuns an enemy, rendering it unable to move or attack for 8 sec.
- Web Explosion [spell=15474] (npc=9032): Immobilizes nearby enemies for 10 sec.

#### Fineous Darkvire (NPC ids [9056])
Overview: Fineous Darkvire is a rather straightforward boss. He hits incredibly hard and has a healing mechanic. As such, it is important to interrupt the heal and for healers to pre-cast heals to keep up with the damage output. Further, when poorly geared, it is important to make sure all the adds along the pathway are killed to avoid an accidental aggro causing a wipe.
- Kick [spell=11978]: Kicks an enemy for 2 damage, interrupting the spell being cast for 6 sec.
- Devotion Aura [spell=8258]: Gives 20 additional armor to nearby party members for 4 min. Players may only have one aura on them per paladin at any one time.
- Holy Strike [spell=13953]: Consecrates the caster's weapon, inflicting 1 additional damage on its next attack. All damage inflicted is based on Holy magic.
- Seal of Reckoning [spell=15346]: Surrounds an ally with a seal that lasts 30 sec. Every time the sealed character strikes an enemy, the sealed character gains health.
- Holy Light [spell=15493]: Calls upon Holy magic to heal an ally.
Loot: Ironfel [item=10999]

#### Pyromancer Loregrain (NPC ids [9024])
Overview: Pyromancer Loregrain does not really warrant discussion of strategy outside of destroying to totem. Incredibly easy boss to kill.
- Scorching Totem [spell=15038]: Summons a Scorching Totem at the caster's feet. Totem lasts 35 sec. and attacks a nearby enemy every 2 sec.
- Fire Ward [spell=15041]: Surrounds the caster with a shield that lasts 1 min. and can absorb a fixed amount of Fire damage.
- Molten Blast [spell=15095]: Burns an enemy, inflicting Fire damage.
- Flame Shock [spell=15616]: Instantly burns an enemy, then inflicts additional Fire damage every 3 sec. for 12 sec.
Loot: Formula: Enchant Weapon - Fiery Weapon [item=11207]

#### Bael'gar (NPC ids [9016])
Overview: Bael'Gar spawns adds, which need to be killed. Also, tanks need to face Bael'Gar away from the group; Magma Splash is not a major concern if that is done. Outside of the tank taking a lot of damage, this fight is fairly easy.
Role notes: tank: Keep the boss facing away from your group.; damage: Prioritize killing adds when they spawn.
- Summon Spawn of Bael'Gar [spell=13895]: Summons 1 Spawn of Bael'Gar in a selected area to aid the caster in battle for 3 min. The violent summoning also inflicts 1500 Fire damage to enemies in the selected area. | note: DPS should switch to the Spawns whenever they are summoned.
- Magma Splash [spell=23379]: 

#### Lord Incendius (NPC ids [9017])
Overview: Lord Incendius is not difficult, but tanks and group members need to make sure they don't get knocked off the platform because there is no getting back up outside of dying.
- Mighty Blow [spell=14099]: Inflicts normal damage plus 25 to an enemy, knocking it back. | note: Position yourself so that if you get knocked back, you stay on the platform.
- Curse of the Elemental Lord [spell=26977]: 
- Fire Storm [spell=13899]: Calls down a pillar of flame, burning all enemies in a selected area for 350 Fire damage and an additional 200 damage every 3 sec. for 30 sec.
- Fiery Burst [spell=13900]: Inflicts Fire damage to all enemies in a selected area.
Loot: Tablet of Kurniya [item=11126]

#### General Angerforge (NPC ids [9033])
Overview: General Angerforge is straightforward. He behaves like a warrior, and then calls adds during the encounter. Just burn him and AoE the adds when they come. They have fairly low health, so they die fairly easily.
Role notes: damage: AoE adds when they appear.
- Sunder Armor [spell=15572]: Hacks at an enemy's armor, reducing it by 0 per Sunder Armor. Can be applied up to 5 times. Lasts 30 sec.
Loot: Marshal Windsor's Lost Information [item=11464]

#### Golem Lord Argelmach (NPC ids [8983])
Overview: Golem Lord Argelmach is a difficult fight because of Chain Lightning. It is an unrelenting amount of damage if your group is stacked too close together. As such, the real key to this fight is remaining spread out so that Chain Lightning doesn't freely bounce from target to target, which is the major killing mechanic in this fight.
- Chain Lightning [spell=15305]: Strikes an enemy with a lightning bolt that arcs to another nearby enemy. The spell affects up to 5 targets, inflicting greater Nature damage to each successive target. | note: Keep your distance from other players to reduce the damage this deals.
- Lightning Shield [spell=15507]: Surrounds the caster with 3 balls of lightning that have 50% chance of striking melee or ranged attackers for 4 damage. Each time the lightning shield strikes, a ball of lightning dissipates. Thus, the shield expires after 10 min. or after it has struck 3 times.
- Shock [spell=15605]: Instantly throws a bolt of lightning at an enemy, inflicting Nature damage.
Loot: Marshal Windsor's Lost Information [item=11464], Head of Argelmach [item=11268]

#### Phalanx (NPC ids [9502])
Overview: To get through the room quickly, buy 6x [item=11325] from [npc=9499] to give to [npc=9503]. After three turn-ins, he will start to rage. This action causes Phalanx to activate to stop Private Rocknot. The door to the remainder of the dungeon is smashed open during the scuffle. Phalanx hits fairly hard with Mighty Blow, but the encounter is trivial. Be careful to avoid accidentally hitting nearby patrons.
- Mighty Blow [spell=14099]: Inflicts normal damage plus 25 to an enemy, knocking it back.
- Thunderclap [spell=15588]: Inflicts 71 to 79 Nature damage to nearby enemies, increasing the time between their attacks by 33% and slowing their movement by 40% for 10 sec.
- Fireball Volley [spell=15285]: Inflicts Fire damage to nearby enemies.

#### Hurley Blackbreath (NPC ids [9537])
Overview: To spawn Hurley, you must break the three kegs in the Grim Guzzler storage room. CC the adds if you can, and kill Hurley. Be careful not to aggro patrons in the bar outside.
- Drunken Rage [spell=14872]: Increases the caster's attack speed by 50% and increases the Physical damage it deals by 50 for 15 sec.
- Flame Breath [spell=9573]: Inflicts 10 Fire damage to enemies in a cone in front of the caster.
Loot: Lost Thunderbrew Recipe [item=11312]

#### Ambassador Flamelash (NPC ids [9156])
Overview: Ambassador Flamelash is a DPS race, in a sense. There are adds that spawn and rush to the boss. If they reach the boss, he gets a buff. However, these adds can easily be killed before reaching him. As such, the way to beat him is to kill the adds before they reach him and increase his damage beyond what the healer can heal. Keep his stacks low, and this is an incredibly easy fight.
Role notes: damage: Focus on killing the adds before they reach the boss.
- Burning Spirit [spell=14744]: Increases the damage dealt by the caster by 30 for 3 min.

#### Chest of the Seven (NPC ids [9034, 9035, 9036, 9037, 9038, 9039, 9040])
Overview: No real strategy other than killing each quickly. They will possess one or two abilities of their specific class, but in a weakened state. Try to kill them quickly to avoid fighting two or more at a time.
Stage Hate'rel: 
- Mana Burn [spell=14033] (npc=9034): Hits an enemy with an anti-mana bolt. For each point of mana consumed by the bolt, the target takes 0.5 damage.
- Shadow Bolt [spell=15232] (npc=9034): Hurls a bolt of dark magic at an enemy, inflicting Shadow damage.
- Shadow Shield [spell=12040] (npc=9034): Surrounds the caster with a shield woven of Shadow magic. The shield lasts 30 sec., absorbs up to 200 Physical or magical damage, and inflicts 10 damage to melee attackers.
Stage Anger'rel: 
- Shield Block [spell=12169] (npc=9035): Increases the caster's chance to block by 75% for 5 sec., but will only block 1 attack.
- Shield Wall [spell=15062] (npc=9035): Reduces the Physical and magical damage taken by the caster by 75% for 10 sec.
- Sunder Armor [spell=11971] (npc=9035): Hacks at an enemy's armor, reducing it by 0 per Sunder Armor. Can be applied up to 5 times. Lasts 30 sec.
Stage Vile'rel: 
- Heal [spell=15586] (npc=9036): Calls upon Holy magic to heal an ally.
- Mind Blast [spell=15587] (npc=9036): Inflicts Shadow damage to an enemy, but causes a high amount of threat.
- Power Word: Shield [spell=11974] (npc=9036): Wraps an ally in a shield that lasts up to 30 sec., absorbing a maximum of 137 Physical or magical damage. While the shield holds, spells will not be interrupted by Physical attacks.
Stage Gloom'rel: 
- Cleave [spell=15584] (npc=9037): Inflicts normal damage plus 30 to an enemy and its nearest allies, affecting up to 3 targets.
- Hamstring [spell=9080] (npc=9037): Inflicts weapon damage plus 1 to an enemy, reducing its movement speed by 60% for 10 sec.
- Mortal Strike [spell=13737] (npc=9037): Inflicts 130% weapon damage and leaves the target wounded, reducing the effectiveness of any healing by 50% for 5 sec.
- Recklessness [spell=13847] (npc=9037): 
Stage Seeth'rel: 
- Cone of Cold [spell=15244] (npc=9038): Inflicts Frost damage to enemies in a cone in front of the caster, reducing their movement speed for 8 sec.
- Frost Armor [spell=12544] (npc=9038): Encases the caster in a layer of frost that lasts 30 min. The thick ice increases armor by 12, slows melee attackers' movement to 25%, and increases the time between their attacks by 30%.
- Frost Nova [spell=12674] (npc=9038): Inflicts Frost damage to nearby enemies, immobilizing them for up to 8 sec.
- Frost Ward [spell=15044] (npc=9038): Surrounds the caster with a shield that lasts 1 min. and can absorb a fixed amount of Frost damage.
- Frostbolt [spell=12675] (npc=9038): Inflicts Frost damage to an enemy and reduces its movement speed for 4 sec.
Stage Doom'rel: 
- Banish [spell=8994] (npc=9039): Banishes an enemy, preventing all action but making it invulnerable for up to 15 sec. Only one target can be banished at a time.
- Curse of Weakness [spell=12493] (npc=9039): Reduces the Physical damage dealt by an enemy by 1 for 2 min. Only one curse per warlock can be active on any one target.
- Demon Armor [spell=13787] (npc=9039): Protects the caster, increasing armor by 210, Shadow resistance by 3, and health regeneration for 30 min.
- Immolate [spell=12742] (npc=9039): Burns an enemy, then inflicts additional Fire damage every 3 sec. for 21 sec.
- Shadow Bolt Volley [spell=15245] (npc=9039): Hurls missiles of dark magic, inflicting Shadow damage to nearby enemies.
- Summon Voidwalkers [spell=15092] (npc=9039): 
Stage Dope'rel: 
- Backstab [spell=15582]: Inflicts normal damage plus 30 to an enemy, but only if attacking from behind.
- Evasion [spell=15087]: Increases the rogue's chance to dodge by 50% for 15 sec.
- Gouge [spell=12540]: Inflicts 20 damage to an enemy and stuns it for up to 4 sec. You will automatically stop attacking. Target must be facing you. Any damage received by the stunned target will revive it.
- Rupture [spell=15583]: Inflicts Physical damage to an enemy every 2 sec. for 10 sec.
- Sinister Strike [spell=15581]: Inflicts normal damage plus 3 to an enemy.

#### Magmus (NPC ids [9938])
Overview: Magmus stands at the end of a long chamber. Within the chamber, there are two rows of fire-belching golems. This fire is brutal and will kill you rapidly. As such, it is on the tank to put Magmus in a good position so that the flames aren't an issue. Outside of the flames on the sides of the chamber, the fight is fairly easy. This fight is all about positioning the boss correctly.
Role notes: tank: Position the boss so that your group can safely attack them.
- Fiery Burst [spell=13900]: Inflicts Fire damage to all enemies in a selected area.
- War Stomp [spell=24375]: Inflicts normal damage plus 500 to nearby enemies, knocking them back and stunning them for 5 sec.

#### Emperor Dagran Thaurissan (NPC ids [9019, 8929])
Overview: Groups can proceed in one of two directions. Either they can choose to save Princess Moira Bronzebeard and kill Emperor Dagran Thaurissan, or they can choose to kill both. Most groups will save Princess Moira Bronzebeard to complete the quest and then kill her each time afterwards because she has good drops. If you are choosing to save Princess Moira Bronzebeard, then your strategy is to keep her occupied with an off-tank, or someone who can interrupt her casts because she can be fairly squishy. Further, she assists Emperor Dagran Thaurissan within the fight, so you can't allow her to simply free-cast the entire encounter. As soon as Emperor Dagran Thaurissan dies, she breaks free from the mind control she was under to become friendly. However, if your intention is to kill Princess Moira Bronzebeard, then you burn her before killing Emperor Dagran Thaurissan. Make sure you have some form of interrupt because she can do a fair amount of damage, which can be hard to heal through, coupled with the damage output of Emperor Dagran Thaurissan.
- Hand of Thaurissan [spell=17492] (npc=9019): Inflicts Fire damage to an enemy, stunning it for 5 sec.
- Avatar of Flame [spell=15636] (npc=9019): Surrounds the caster in flames for 10 sec., giving the caster magic immunity and the ability to inflict 200 Fire damage to an enemy on attack.
- Ironfoe [spell=15642] (npc=9019): 
- Heal [spell=15586] (npc=8929): Calls upon Holy magic to heal an ally.
- Renew [spell=10929] (npc=8929): Heals the target of 670 damage over 15 sec.
- Power Word: Shield [spell=10901] (npc=8929): Draws on the soul of the party member to shield them, absorbing 950 damage. Lasts 30 sec. While the shield holds, spellcasting will not be interrupted by damage. Once shielded, the target cannot be shielded again for 15 sec.
- Mind Blast [spell=15587] (npc=8929): Inflicts Shadow damage to an enemy, but causes a high amount of threat.
- Shadow Word: Pain [spell=15654] (npc=8929): Utters a word of darkness, inflicting Shadow damage to an enemy every 3 sec. for 18 sec.
- Smite [spell=10934] (npc=8929): Smite an enemy for 167 to 186 Holy damage.
- Shadow Bolt [spell=15537] (npc=8929): Hurls a bolt of dark magic at an enemy, inflicting Shadow damage.

#### Warder Stilgiss & Verek (Rare) (NPC ids [9041, 9042])
Overview: Warder Stilgiss spawns with Verek. The fight is not difficult for a five man group. Just kill Warder Stilgiss first and then Verek next.
- Frost Armor [spell=12544]: Encases the caster in a layer of frost that lasts 30 min. The thick ice increases armor by 12, slows melee attackers' movement to 25%, and increases the time between their attacks by 30%.
- Frost Nova [spell=12674]: Inflicts Frost damage to nearby enemies, immobilizing them for up to 8 sec.
- Frost Ward [spell=15044]: Surrounds the caster with a shield that lasts 1 min. and can absorb a fixed amount of Frost damage.
- Frostbolt [spell=12675]: Inflicts Frost damage to an enemy and reduces its movement speed for 4 sec.
- Curse of Blood [spell=15042]: Increases the Physical damage taken by an enemy by 1 for 10 min.

#### Panzor the Invincible (Rare) (NPC ids [8923])
Overview: Panzor the Invincible is not a mob that will be encountered often. When encountered, the biggest thing is for casters to watch out for Spell Reflection. Other than that, it is an easy encounter.
- Spell Reflection [spell=9941]:  | note: Casters should not cast spells on the boss while this is up.

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Lord Roccor: npcs[Lord Roccor updated] spells[] newSpells[] loot[]
- Ring of the Law: npcs[] spells[Baneful Poison updated: Numbers and wording changed] newSpells[] loot[]
- Pyromancer Loregrain: npcs[Pyromancer Loregrain updated] spells[] newSpells[] loot[]
- Bael'gar: npcs[] spells[Summon Spawn of Bael'Gar updated: Numbers and wording changed] newSpells[] loot[]
- Lord Incendius: npcs[] spells[Fire Storm updated: Numbers and wording changed] newSpells[] loot[]
- Hurley Blackbreath: npcs[Hurley Blackbreath updated] spells[] newSpells[] loot[]
- Emperor Dagran Thaurissan: npcs[Princess Moira Bronzebeard updated] spells[Power Word: Shield updated: Value increased by 0.8%; Renew updated: Value decreased by 17.3%; Smite updated: Values decreased by 56.5% and 56.6%; Avatar of Flame updated: Numbers and wording changed] newSpells[] loot[]
- Warder Stilgiss & Verek (Rare): npcs[Warder Stilgiss updated; Verek updated] spells[] newSpells[] loot[]


## Guide text
Source: https://www.wowhead.com/forever/guide=35206

Blackrock Depths [zone=1584] is located in Blackrock Mountain which can be accessed from both Searing Gorge and Burning Steppes. This guide provides tips and strategies for completing Blackrock Depths, including everything you need before and during the dungeon, quests to complete inside, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## Blackrock Depths Overview in World of Warcraft: Forever

Once the capital city of the Dark Iron dwarves, this volcanic labyrinth now serves as the seat of power for Ragnaros the Firelord. Ragnaros has uncovered the secret to creating life from stone and plans to build an army of unstoppable golems to aid him in conquering the whole of Blackrock Mountain. Obsessed with defeating Nefarian and his draconic minions, Ragnaros will go to any extreme to achieve final victory.

The recommended level for Blackrock Depths is between 52 and 60. In-game players usually refer to Blackrock Depths as "BRD." 

## Location of Blackrock Depths in World of Warcraft: Forever

Blackrock Depths is located within Blackrock Mountain [zone=25]. Alliance players will fly to Thorium Point in Searing Gorge or Morgan’s Vigil in Burning Steppes. Horde players will fly into Kargath in Badlands, to Thorium Point in Searing Gorge, or to Flame Crest in Burning Steppes.

When entering from Searing Gorge [zone=51], follow the path into the Molten Span. To the East, there is a long chain that leads down into a central platform. From Burning Steppes [zone=46], follow the path up to the left into the Molten Span. This path will run straight into the long chain leading down to the middle platform ledge.

First Chain Leading to Center Platform

Second Chain to Lower Platform

Run down the chain and follow the path through Forgewright’s Tomb. After you make it through the Tomb, follow the path around the middle platform and run down the next chain leading to the small landing at the bottom. From here, there is a doorway leading into The Grinding Quarry. Travel Northwest through the Quarry until you reach the straight path heading North into The Masonary. From here, just run straight until you reach the instance portal.

Doorway to The Grinding Quarry

The Grinding Quarry

The Masonary Pathway

As with many World of Warcraft: Forever Dungeons, wiping (the entire group dying) in Blackrock Depths can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. Druids only have an in-combat resurrection spell and are unlikely to train it before Blackrock Depths.

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer as a ghost. You collect your body when you enter the instance.

## Every Quest in Blackrock Depths in World of Warcraft: Forever

Hard: Level 50 | Medium: Level 52 | At Level: Level 55 | Easy: Level 60

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

Ribbly Screwspigot [quest=4136] | 50 | - |  |   | Burning Steppes, Flame Crest - Yuka Screwspigot [npc=9544] /way 66 21
Can pick up breadcrumbYuka Screwspigot [quest=4324] in Steamwheedle Port for easy XP | 

The Heart of the Mountain [quest=4123] | 50 | - |  |   | Burning Steppes, Flame Crest - Maxwort Uberglint [npc=9536] /way 65 23 | 

Attunement to the Core [quest=7848] | 55 | - |  |   | Blackrock Mountain, Lothos Riftwaker [npc=14387] | 

Dark Iron Legacy [quest=3802] | 48 | - |  | Pre  | Blackrock Mountain, Structure in middle - Franclorn Forgewright [npc=8888] 
NPC is only visible if you are dead
CompleteDark Iron Legacy [quest=3801] first  | 

The Love Potion [quest=4201] | 50 | - |  |   | Blackrock Depths, Grim Guzzler - Mistress Nagmara [npc=9500] | 

A Taste of Flame [quest=4024] | 52 | - |  |   | Burning Steppes, Cave in NE - Cyrus Therepentous [npc=9459] /way 95 31
Complete 11 quests first, starting withDivine Retribution [quest=3441] | 

Quest | Level | Side | Effort | Share? | Starts | 

Overmaster Pyron [quest=4262] | 48 |  |  |   | Burning Steppes, Morgan's Vigil - Jalinda Sprig [npc=9561] /way 85 70 | 

Incendius! [quest=4263] | 48 |  |  |   | Burning Steppes, Morgan's Vigil - Jalinda Sprig [npc=9561] /way 85 70
CompleteOvermaster Pyron [quest=4262] first | 

The Good Stuff [quest=4286] | 50 |  |  |   | Burning Steppes, Morgan's Vigil - Oralius [npc=9177] /way 84 68 | 

Hurley Blackbreath [quest=4126] | 50 |  |  |   | Dun Morogh, Kharanos - Ragnar Thunderbrew [npc=1267] /way 46 52 | 

Kharan Mighthammer [quest=4341] | 50 |  |  | Pre | Ironforge, Throne Room - King Magni Bronzebeard [npc=2784] /way 39 56
Complete 2 quests first, starting withThe Smoldering Ruins of Thaurissan [quest=3702] | 

The Fate of the Kingdom [quest=4362] | 50 |  |  | Pre  | Ironforge, Throne Room - King Magni Bronzebeard [npc=2784] /way 39 56
Complete 2 quests first, starting withKharan Mighthammer [quest=4341] | 

Marshal Windsor [quest=4241] | 48 |  |  | Pre  | Burning Steppes, Morgan's Vigil- Marshal Maxwell [npc=9560] /way 84 68
Complete 2 quests first, starting withDragonkin Menace [quest=4182] | 

Jail Break! [quest=4322] | 50 |  |  | Pre  | Blackrock Depths , Prison Cell - Marshal Windsor [npc=9023] 
Complete 6 quests first, starting withDragonkin Menace [quest=4182] and moving throughMarshal Windsor [quest=4241] untilA Shred of Hope [quest=4282] | 

Quest | Level | Side | Effort | Share? | Starts | 

KILL ON SIGHT: Dark Iron Dwarves [quest=4081] | 48 |  |  |   | Badlands, Kargath - WANTED [object=164867] poster /way 4 47 | 

Lost Thunderbrew Recipe [quest=4134] | 50 |  |  |   | Badlands, Kargath - Shadowmage Vivian Lagrave [npc=9078] /way 3 48
BreadcrumbVivian Lagrave [quest=4133] in Undercity for easy XP | 

KILL ON SIGHT: High Ranking Dark Iron Officials [quest=4082] | 50 |  |  | Pre  | Badlands, Kargath - WANTED [object=164867] poster /way 4 47
CompleteKILL ON SIGHT: Dark Iron Dwarves [quest=4081] first  | 

The Rise of the Machines [quest=4063] | 52 |  |  | Pre | Badlands, Eastern - Lotwil Veriatus [npc=2921] /way 25 44
Complete 2 quests first, starting withThe Rise of the Machines [quest=4061] | 

Disharmony of Flame [quest=3906] | 48 |  |  |   | Badlands, Kargath - Thunderheart [npc=9084] /way 3.6 48.0 | 

Disharmony of Fire [quest=3907] | 48 |  |  | Pre | Badlands, Kargath - Thunderheart [npc=9084] /way 3.6 48.0
Opens after completingDisharmony of Flame [quest=3906] | 

Commander Gor'shak [quest=3981] | 48 |  |  | Pre | Badlands, Kargath - Galamav the Marksman [npc=9081] /way 6 47
Opens after completingDisharmony of Flame [quest=3906] | 

The Last Element [quest=7201] | 48 |  |  | Pre | Badlands, Kargath - Shadowmage Vivian Lagrave [npc=9078] /way 3 48
Opens after completingDisharmony of Flame [quest=3906] | 

Operation: Death to Angerforge [quest=4132] | 52 |  |  |   | Badlands, Kargath - Warlord Goretooth [npc=9077] /way 6 47
Complete 3 quests first, starting withKILL ON SIGHT: Dark Iron Dwarves [quest=4081]. This includes Grark Lorkrub [quest=4122], a long escort quest. | 

The Royal Rescue [quest=4003] | 48 |  |  |   | Orgrimmar, Valley of Wisdom - Thrall [npc=4949] /way 32 38
Complete 4 quests first, starting withCommander Gor'shak [quest=3981] | 

Completing Dungeon Quests in World of Warcraft: Forever is a great way to gain some extra experience and gear. You will find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

The quests below include where to collect them, any prerequisites you need to complete first, and what you need to do inside or around Blackrock Depths.

A Taste of Flame [quest=4024]
Faction: Both
Quest Starts: Cyrus Therepentous [npc=9459], Burning Steppes [zone=46], /way 95.0 31.4
Level Required: 52
Rewards:

- 
- Shaleskin Cape [item=12066], Wyrmhide Spaulders [item=12082] or Valconian Sash [item=12083]
- 6,200 experience

This is part of a chain of quests, starting from Velarok Windblade [npc=8479] in Searing Gorge [zone=51].

Velarok Windblade [npc=8479]

- Divine Retribution [quest=3441]
- The Flawless Flame [quest=3442]
- Forging the Shaft [quest=3443]
- The Flame's Casing [quest=3452]
- The Torch of Retribution [quest=3453]
- The Torch of Retribution [quest=3454]

Then, from Squire Maltrake [npc=8509] right beside him:

- Squire Maltrake [quest=3462]
- Set Them Ablaze! [quest=3463]
- Trinkets... [quest=3481]: Open the nearby chest to receive Hoard of the Black Dragonflight [item=10569].

Open Hoard of the Black Dragonflight [item=10569]. You will receive several items, one of which is Black Dragonflight Molt [item=10575]. Take the Black Dragonflight Molt [item=10575] to Cyrus Therepentous [npc=9459] in Burning Steppes [zone=46].

A Taste of Flame [quest=4023]: Speak with Cyrus Therepentous [npc=9459]. To prove your worth further, he follows up with A Taste of Flame [quest=4024], asking you to travel to Blackrock Depths [zone=1584] and slay Bael'Gar [npc=9016]. After he is slain, use Altered Black Dragonflight Molt [item=11231] on the corpse of Bael'Gar [npc=9016]. You will receive Encased Fiery Essence [item=11230]. Return it to Cyrus Therepentous [npc=9459] to complete the quest.

The Heart of the Mountain [quest=4123]
Faction: Both
Quest Starts: Maxwort Uberglint [npc=9536], Burning Steppes [zone=46], /way 65.2 23.8
Level Required: 50
Rewards:

- 
- 5,650 experience

Maxwort Uberglint [npc=9536]

He asks you to retrieve The Heart of the Mountain [item=11309] from Blackrock Depths [zone=1584]. After you kill Watchman Doomgrip [npc=9476] inside the Black Vault, The Heart of the Mountain [item=11309] will spawn in the back of the vault.

Dark Iron Legacy [quest=3802]
Faction: Both
Quest Starts: Franclorn Forgewright [npc=8888], Burning Steppes [zone=46] (Only visible when you are dead), /way 20.6 28.8
Level Required: 48
Rewards:

- 
- Shadowforge Key [item=11000]
- 5,100 experience

You can only start this quest while you are dead. The quest giver, Franclorn Forgewright [npc=8888], is located inside the building that is suspended over the giant lava pit in Molten Span. If you enter from Searing Gorge [zone=51], the first chain to the left has a rock ramp that you can use to get on the chain. Once on, run across the chain to the building. Go downstairs and you should see the ghost of Franclorn Forgewright [npc=8888]. Talk to him twice and you'll receive the follow-up, Dark Iron Legacy [quest=3802].

Dark Iron Legacy [quest=3802]: Slay Fineous Darkvire [npc=9056] and collect Ironfel [item=10999] from him. Take Ironfel [item=10999] and place it on the Monument of Franclorn Forgewright [object=164689], located in the Ruins of Thaurissan section of Blackrock Depths [zone=1584].

Ribbly Screwspigot [quest=4136]
Faction: Both
Quest starts (Part 1): Yorba Screwspigot [npc=9706], Tanaris [zone=440], /way 67.0 24.0
Quest starts (Part 2): Yuka Screwspigot [npc=9544], Burning Steppes [zone=46], /way 66.0 22.0
Level Required: 48
Rewards:

- 
- Rancor Boots [item=11865], Penance Spaulders [item=11963] or Splintsteel Armor [item=12049]
- 2,650 experience

1. Yuka Screwspigot [quest=4324]: Yorba Screwspigot [npc=9706] in Steamwheedle Port, Tanaris, asks you to speak to Yuka Screwspigot [npc=9544].

Yorba Screwspigot [npc=9706]

2. Ribbly Screwspigot [quest=4136]: Begins and ends with Yuka Screwspigot [npc=9544] in Burning Steppes [zone=46].

Yuka Screwspigot [npc=9544]

Yuka Screwspigot [npc=9544] asks you to collect Ribbly's Head [item=11313] from Ribbly Screwspigot [npc=9543] inside Blackrock Depths [zone=1584]. Return to her when finished.

The Love Potion [quest=4201] 
Faction: Both
Quest Starts: Mistress Nagmara [npc=9500], Grim Guzzler, Blackrock Depths [zone=1584]
Level Required: 50
Rewards:

- Manacle Cuffs [item=11962] or Nagmara's Whipping Belt [item=11866]
- 5,450 experience

Starts with Mistress Nagmara [npc=9500] in the Grim Guzzler of Blackrock Depths [zone=1584].

She asks you to bring her:

- 4x Gromsblood [item=8846] - from Herbalism {/forever/skill=182/herbalism} / Auction House
- 10x Giant Silver Vein [item=11405] - located throughout Azshara [zone=16]
- Nagmara's Filled Vial [item=11413] (provided)

Return to Mistress Nagmara [npc=9500] once complete.

Attunement to the Core [quest=7848]
Faction: Both
Quest Starts: Lothos Riftwaker [npc=14387], Blackrock Mountain [zone=25]
Level Required: 55
Rewards:

- 
- 6,600 experience

Starts with Lothos Riftwaker [npc=14387] in Blackrock Mountain [zone=25].

Once the quest is accepted, you will be asked to venture deep into Blackrock Depths [zone=1584] to acquire the Core Fragment [item=18412], near the very end of the dungeon.

If your goal is simply to rush to the Core Fragment [item=18412] for attunement, your best bet is to find a group to do a "lava run", jumping off the platform Lord Incendius [npc=9017] is on:

Once in the lava, you and your team will need to hug the left side of the cavern, allowing the players to stand on a small sliver of land, avoiding the damage from the lava. 

Once this narrow path comes to an end, the party will have the bridge leading to the Core Fragment [item=18412]. To get there, the team must swim through lava. This is where a healer or fire-absorbing consumables may come into play!

Incendius! [quest=4263]
Faction: Alliance
Quest Starts: Jalinda Sprig [npc=9561], Burning Steppes [zone=46], /way 85.4 70.0
Level Required: 50
Rewards:

- 
- Sunborne Cape [item=12113], Nightfall Gloves [item=12114], Crypt Demon Bracers [item=12112] or Stalwart Clutch [item=12115]
- 5,800 experience
- 100 Reputation with Gnomeregan Exiles {/forever/faction=54/gnomeregan-exiles}

Part 2 of 2 of a quest chain from Jalinda Sprig [npc=9561] in Burning Steppes [zone=46].

Jalinda Sprig [npc=9561]

1. Overmaster Pyron [quest=4262]: Kill Overmaster Pyron [npc=9026], the fire elemental located right outside of Blackrock Depths [zone=1584].

2. Incendius! [quest=4263]: Kill Lord Incendius [npc=9017] inside Blackrock Depths [zone=1584], guarding The Black Anvil.

Return to Jalinda Sprig [npc=9561] once you've completed your quest.

The Good Stuff [quest=4286]
Faction: Alliance
Level Required: 50
Quest Starts: Jalinda Sprig [npc=9561], Burning Steppes [zone=46], /way 85.4 70.0
Rewards:

- 
- A Dingy Fanny Pack [item=11883]
- 5,800 experience
- Reputation with Ironforge {/forever/faction=47/ironforge}

This quest requires you to collect 20 Dark Iron Fanny Pack [item=11468] from Dark Iron Dwarves inside Blackrock Depths [zone=1584]. This quest starts and ends with Jalinda Sprig [npc=9561] in Burning Steppes [zone=46].

Jalinda Sprig [npc=9561]

Kharan Mighthammer [quest=4341]
Faction: Alliance
Quest Starts: King Magni Bronzebeard [npc=2784], Ironforge [zone=1537], /way 40.0 55.2
Level Required: 50
Rewards:

- 6,400 experience
- Reputation with Ironforge {/forever/faction=47/ironforge}

This quest is unlocked after you complete 2 quests from Royal Historian Archesonus [npc=8879] in Ironforge [zone=1537].

Royal Historian Archesonus [npc=8879]

1. The Smoldering Ruins of Thaurissan [quest=3702]: Listen to the Story of Thaurissan.
2. The Smoldering Ruins of Thaurissan [quest=3701]: Travel to the Ruins of Thaurissan in Burning Steppes [zone=46] and gather 12 Thaurissan Relic [object=153556].

Return to Royal Historian Archesonus [npc=8879] when finished. You will receive , Ring of the Aristocrat [item=12102], 5,450 experience, and unlock a new quest from King Magni Bronzebeard [npc=2784], located in Ironforge [zone=1537].

King Magni Bronzebeard [npc=2784]

Kharan Mighthammer [quest=4341]: The King asks you to travel to Blackrock Depths [zone=1584] and find Kharan Mighthammer [npc=9021], who is locked inside a cell in the Prison. When you enter the instance, his cell is to the right. You'll see a yellow dot on your mini-map of his exact location.

To unlock his cell, you need Prison Cell Key [item=11140], which drops from High Interrogator Gerstahn [npc=9018]. She only drops one, and it's Bind on Pickup. Head back to Kharan Mighthammer [npc=9021]'s cell to speak to him. He will follow up with 2 more quests:

Kharan's Tale [quest=4342]: Listen to Kharan Mighthammer [npc=9021]'s tale.
The Bearer of Bad News [quest=4361]: Return to Ironforge [zone=1537] and deliver the news to King Magni Bronzebeard [npc=2784].

The king will now offer the quest The Fate of the Kingdom [quest=4362].

-  Hurley Blackbreath [quest=4126]: Starts from Ragnar Thunderbrew [npc=1267] in Dun Morogh and requires level 50. Kill Hurley Blackbreath [npc=9537].
Rewards Swiftstrike Cudgel [item=11964], Limb Cleaver [item=12000]
 
 The Fate of the Kingdom [quest=4362]: The Kharan Mighthammer [quest=4341] questline continues, requiring you to defeat Emperor Dagran Thaurissan [npc=9019] but keep Moira alive. 

- The quest series rewards Magni's Will [item=12548] (note this is different than the Horde melee ring) and Songstone of Ironforge [item=12543].

Hurley Blackbreath [quest=4126]
Faction: Alliance
Quest Starts (Part 1): Enohar Thunderbrew [npc=9540], Blasted Lands [zone=4], /way 63.6 20.4
Quest Starts (Part 2): Ragnar Thunderbrew [npc=1267], Dun Morogh [zone=1], /way 46.8 52.4
Level Required: 50
Rewards:

- 
- Swiftstrike Cudgel [item=11964] or Limb Cleaver [item=12000]
- 10x Dark Dwarven Lager [item=12003]
- 7,050 experience

The first part of this quest, Ragnar Thunderbrew [quest=4128], is acquired from Enohar Thunderbrew [npc=9540], located in Blasted Lands [zone=4].

Enohar Thunderbrew [npc=9540]

Enohar Thunderbrew [npc=9540] asks you to locate Ragnar Thunderbrew [npc=1267]. He is in Kharanos, Dun Morogh [zone=1].

Ragnar Thunderbrew [npc=1267]

Ragnar Thunderbrew [npc=1267] asks you to return his Lost Thunderbrew Recipe [item=11312]. This drops from Hurley Blackbreath [npc=9537] within Blackrock Depths [zone=1584]. 

To spawn Hurley Blackbreath [npc=9537] inside the Grim Guzzler of Blackrock Depths [zone=1584], you must break all 3 kegs located within a small storage room inside the bar. He will spawn with 3 guards.

The Fate of the Kingdom [quest=4362]
Faction: Alliance
Quest Starts: King Magni Bronzebeard [npc=2784], Ironforge [zone=1537], /way 40.0 55.2
Level Required: 50
Rewards:

- 8,050 experience
- Reputation with Ironforge {/forever/faction=47/ironforge}

This quest is unlocked after you complete the earlier quest line up to, and including, Kharan Mighthammer [quest=4341] and leads to the reward of either Magni's Will [item=12548] or Songstone of Ironforge [item=12543].

King Magni Bronzebeard [npc=2784] wants you to kill Emperor Dagran Thaurissan [npc=9019] and rescue Princess Moira Bronzebeard [npc=8929] inside Blackrock Depths [zone=1584]. Speak with Princess Moira Bronzebeard [npc=8929] inside the instance to complete the quest. She will follow up with The Princess's Surprise [quest=4363].

The Princess's Surprise [quest=4363]: Return to Ironforge [zone=1537] and speak with King Magni Bronzebeard [npc=2784]. You will receive:

Rewards:

- 
- Magni's Will [item=12548] or Songstone of Ironforge [item=12543]
- 9,650 experience
- Reputation with Ironforge {/forever/faction=47/ironforge}

KILL ON SIGHT: Dark Iron Dwarves [quest=4081]
Faction: Horde
Quest Starts: KILL ON SIGHT [object=164868], Badlands [zone=3], /way 4.0 46.8
Level Required: 48
Rewards:

- 
- 5,100 experience
- Reputation with Orgrimmar {/forever/faction=76/orgrimmar}

Starts from a WANTED poster in Kargath and is returned to Warlord Goretooth [npc=9077].

Warlord Goretooth [npc=9077]

Venture into Blackrock Depths [zone=1584] and kill Dark Iron Dwarves:

- 15x Anvilrage Guardsman [npc=8891]
- 10x Anvilrage Warden [npc=8890]
- 5x Anvilrage Footman [npc=8892]

KILL ON SIGHT: High Ranking Dark Iron Officials [quest=4082]
Faction: Horde
Quest Starts: KILL ON SIGHT [object=164868], Badlands [zone=3], /way 4.0 46.8
Level Required: 50
Rewards:

- 
- 5,450 experience
- Reputation with Orgrimmar {/forever/faction=76/orgrimmar}

Starts from a WANTED poster in Kargath and is returned to Warlord Goretooth [npc=9077].

Warlord Goretooth [npc=9077]

Venture into Blackrock Depths [zone=1584] and kill Dark Iron Dwarves:

- 10x Anvilrage Medic [npc=8894]
- 10x Anvilrage Soldier [npc=8893]
- 10x Anvilrage Officer [npc=8895]

Disharmony of Flame [quest=3906] & Disharmony of Fire [quest=3907]
Faction: Horde
Quest Starts: Thunderheart [npc=9084], Badlands [zone=3], /way 3.6 48.0
Level Required: 48
Rewards:

- Gold
- Sunborne Cape [item=12113], Nightfall Gloves [item=12114], Crypt Demon Bracers [item=12112] or Stalwart Clutch [item=12115]
- Experience
- Reputation with Thunder Bluff {/forever/faction=81/thunder-bluff}

This is a two-part quest chain from Thunderheart [npc=9084] in Badlands [zone=3].

Thunderheart [npc=9084]

1. Disharmony of Flame [quest=3906]: Kill Overmaster Pyron [npc=9026], the fire elemental located right outside of Blackrock Depths [zone=1584].

2. Disharmony of Fire [quest=3907]: Kill Lord Incendius [npc=9017] inside Blackrock Depths [zone=1584], guarding The Black Anvil.

Return to Thunderheart [npc=9084] once you've completed your quest.

The Last Element [quest=7201]
Faction:Horde
Quest Starts: Shadowmage Vivian Lagrave [npc=9078], Badlands [zone=3], /way 3.0 47.6
Level Required: 48
Rewards:

- 
- Lagrave's Seal [item=12038]
- 5,450 experience
- Reputation with Undercity {/forever/faction=68/undercity}

Shadowmage Vivian Lagrave [npc=9078], in Kargath, Badlands [zone=3], asks you to travel to Blackrock Depths [zone=1584] and collect 10x Essence of the Elements [item=11129].

Shadowmage Vivian Lagrave [npc=9078]

Essence of the Elements [item=11129] drops from any elemental inside the instance.

Commander Gor'shak [quest=3981]
Faction: Horde
Quest Starts: Galamav the Marksman [npc=9081], Badlands [zone=3], /way 5.8 47.6
Level Required: 48
Rewards:

- 5,100 experience
- Reputation with Orgrimmar {/forever/faction=76/orgrimmar}

This is part of a chain quest, starting with Galamav the Marksman [npc=9081] in Kargath, Badlands [zone=3]. He asks you to find Commander Gor'shak [npc=9020] in Blackrock Depths [zone=1584].

Shadowmage Vivian Lagrave [npc=9078]

After you enter Blackrock Depths [zone=1584], walk forward into the main room, then look to your right. You will see three pathways. The outer two loop around back to each other in a big ring. Commander Gor'shak [npc=9020] is in a cell on the left side.

To unlock his cell, you need Prison Cell Key [item=11140], which drops from High Interrogator Gerstahn [npc=9018]. She only drops one, and it's Bind on Pickup. Head back to Commander Gor'shak [npc=9020]'s cell to speak to him. He will follow up with 2 more quests:

What Is Going On? [quest=3982]: Defend Commander Gor'shak [npc=9020] from the guard attack.

What Is Going On? [quest=4001]: Speak to Kharan Mighthammer [npc=9021] in a nearby cell, then report to Thrall [npc=4949] in Orgrimmar [zone=1637].

Thrall [npc=4949]

Thrall [npc=4949] will now offer the quest The Eastern Kingdoms [quest=4002]. Speak to Thrall [npc=4949] to complete it. He follows up with The Royal Rescue [quest=4003].

Lost Thunderbrew Recipe [quest=4134]
Faction: Horde
Quest Starts (Part 1): Apothecary Zinge [npc=5204], Undercity [zone=1497], /way 50.0 68.6
Quest Starts (Part 2): Shadowmage Vivian Lagrave [npc=9078], Badlands [zone=3], /way 3.0 47.6
Level Required: 50
Rewards:

- 
- Swiftstrike Cudgel [item=11964] or Limb Cleaver [item=12000]
- 5x Superior Healing Potion [item=3928], 5x Greater Mana Potion [item=6149]
- 5,650 experience

The first part of this quest, Vivian Lagrave [quest=4133], is acquired from Apothecary Zinge [npc=5204], located in Undercity [zone=1497].

Apothecary Zinge [npc=5204]

Apothecary Zinge [npc=5204] asks you to locate Shadowmage Vivian Lagrave [npc=9078]. He is in Kargath, Badlands [zone=3].

Shadowmage Vivian Lagrave [npc=9078]

Shadowmage Vivian Lagrave [npc=9078] asks you to return his Lost Thunderbrew Recipe [item=11312]. This drops from Hurley Blackbreath [npc=9537] within Blackrock Depths [zone=1584]. 

To spawn Hurley Blackbreath [npc=9537] inside the Grim Guzzler of Blackrock Depths [zone=1584], you must break all 3 kegs located within a small storage room inside the bar. He will spawn with 3 guards.

Operation: Death to Angerforge [quest=4132]
Faction: Horde
Quest Starts: Warlord Goretooth [npc=9077], Badlands [zone=3], /way 3.0 47.6
Level Required: 52
Rewards:

- 
- Conqueror's Medallion [item=12059]
- 7,750 experience
- Reputation with Orgrimmar {/forever/faction=76/orgrimmar}

This quest requires completion of the following:

- KILL ON SIGHT: Dark Iron Dwarves [quest=4081]
- KILL ON SIGHT: High Ranking Dark Iron Officials [quest=4082]
- Grark Lorkrub [quest=4122]
- Precarious Predicament [quest=4121]

Travel to Blackrock Depths [zone=1584] and slay General Angerforge [npc=9033]. Return to Warlord Goretooth [npc=9077] when the task is complete.

Warlord Goretooth [npc=9077]

The Rise of the Machines [quest=4063]
Faction: Horde
Quest Starts (Parts 1 and 2): Hierophant Theodora Mulvadania [npc=9079], Badlands [zone=3], /way 3.0 47.8
Quest Starts (Part 3): Lotwil Veriatus [npc=2921], Badlands [zone=3], /way 25.8 45.0
Level Required: 52
Rewards:

- Azure Moon Amice [item=12109], Raincaster Drape [item=12110], Basaltscale Armor [item=12108] or Lavaplate Gauntlets [item=12111]
- 
- 6,200 experience

This is a 3-quest chain, all with the same name.

1. The Rise of the Machines [quest=4061]: Acquired from Hierophant Theodora Mulvadania [npc=9079] in Kargath, Badlands [zone=3]:

Hierophant Theodora Mulvadania [npc=9079]

Venture into Burning Steppes [zone=46] and recover 10x Fractured Elemental Shard [item=11266]. These are dropped by War Reaver [npc=7039], Malfunctioning Reaver [npc=8981], Greater Obsidian Elemental [npc=7032]. Return to Hierophant Theodora Mulvadania [npc=9079] when complete.

2. The Rise of the Machines [quest=4062]: Take Elemental Shard Sample [item=11267] (provided) to Lotwil Veriatus [npc=2921] in the camp to the east.

Lotwil Veriatus [npc=2921]

3. The Rise of the Machines [quest=4063]: Find and slay Golem Lord Argelmach [npc=8983] inside Blackrock Depths [zone=1584] and collect Head of Argelmach [item=11268]. You must also collect 10x Intact Elemental Core [item=11269] from Warbringer Construct [npc=8905], Wrath Hammer Construct [npc=8907], Molten War Golem [npc=8908], and Ragereaver Golem [npc=8906] inside the instance.

Return to Lotwil Veriatus [npc=2921] to turn in your quest!

The Last Element [quest=7201]
Faction: Horde
Quest Starts: Shadowmage Vivian Lagrave [npc=9078], Badlands [zone=3], /way 3.0 47.6
Level Required: 48
Rewards:

- 
- Lagrave's Seal [item=12038]
- 5,450 experience
- Reputation with Undercity {/forever/faction=68/undercity}

Shadowmage Vivian Lagrave [npc=9078] in Kargath, Badlands [zone=3], asks you to travel to Blackrock Depths [zone=1584] and collect 10x Essence of the Elements [item=11129]. Return to him when finished.

Shadowmage Vivian Lagrave [npc=9078]

Essence of the Elements [item=11129] drops from any elemental inside the instance.

The Royal Rescue [quest=4003]
Faction: Horde
Quest Starts: Thrall [npc=4949], Orgrimmar [zone=1637], /way 32.0 37.8
Level Required: 48
Rewards:

- 8,050 experience
- Reputation with Orgrimmar {/forever/faction=76/orgrimmar}

This quest is unlocked after you complete the earlier quest line up to, and including, Commander Gor'shak [quest=3981] and leads to the reward of either Thrall's Resolve [item=12544] or Eye of Orgrimmar [item=12545].

Thrall [npc=4949] wants you to kill Emperor Dagran Thaurissan [npc=9019] and rescue Princess Moira Bronzebeard [npc=8929] inside Blackrock Depths [zone=1584]. Speak with Princess Moira Bronzebeard [npc=8929] inside the instance to complete the quest. She will follow up with The Princess Saved? [quest=4004].

The Princess Saved? [quest=4004] - return to Orgrimmar [zone=1637] and speak with Thrall [npc=4949]. You will receive:

Rewards

- 
- Thrall's Resolve [item=12544] or Eye of Orgrimmar [item=12545]
- 9,950 experience
- Reputation with Horde {/forever/faction=67/horde}

### Best Quest Rewards

Type | Item | Quest | 

Wyrmhide Spaulders [item=12082] | Leather Shoulders | A Taste of Flame | 

Magni's Will [item=12548] | A ring with Critical Strike and Strength. Good for DPS Warrior, Feral Druid, Hunter, Ret Paladin, Rogue, and Warrior Tank. |  The Princess's Surprise | 

Songstone of Ironforge [item=12543] | A ring with Intellect and Spell Power. Good for Balance Druid, Mage, Healing Priest, Shadow Priest, and Warlock. |  The Princess's Surprise | 

Eye of Orgrimmar [item=12545] | A ring with Intellect and Spell Power. Good for Balance Druid, Mage, Healing Priest, Shadow Priest, and Warlock. |  The Princess Saved? | 

Thrall's Resolve [item=12544] | A ring with Armor, Strength, and Stamina. Good for Feral Druid Tanks. |  The Princess Saved? | 

Shadowforge Key [item=11000] | A key that allows you to skip ahead in the dungeon to later bosses. | Dark Iron Legacy | 

Attunement | Rewards you with the ability to speak to Lothos Riftwaker [npc=14387] to teleport to Molten Core. | Attunement to the Core | 

## Blackrock Depths Layout and Navigation in World of Warcraft: Forever

 Once you have obtained the Shadowforge Key all subsequent runs may skip many of the bosses within the first half of the dungeon because there are side doors that can be opened with the key in order to progress into the back half to avoid the entire Detention Block and save an hour of time.

The goal of the first half of BRD is to complete the first round of several quest chains and to obtain the Shadowforge Key [item=11000] through the completion of Dark Iron Legacy [quest=3802]. Note: one member of the party must be dead in order to interact with Franclorn Forgewright [npc=8888] to accept the quest; however, once accepted the quest can be shared to other members of the party. 

 When entering Blackrock Depths [zone=1584], in the Detention Block, there are several bosses to kill in order to progress forward. The primary objective of the Detention Block is to complete Ring of the Law. That said, however, there are multiple optional bosses you will be killing along the way to complete quests. 

 First and foremost, you will clear the first ring to the right when you walk into the Detention Block. After clearing the outside ring, enter the path splitting the middle of the ring that contains the prison alcoves. Killing High Interrogator Gerstahn [npc=9018] grants the Prison Cell Key [item=11140], which is necessary to complete many of the quests within the first half as it opens the doors to the appropriate prison cells. 

 The First Ring

 The Second Ring 

 The Ring of the Law

 After completing the first ring, the second ring houses two optional bosses and Ring of the Law (RotL). Before entering the RotL, kill both Lord Roccor [npc=9025] and Houndmaster Grebmar [npc=9319]. Once both are dead, you can enter the arena within RotL. Note, this is a long fight, so be prepared before entering and starting the event. The event will consist of three stages two waves randomly spawned mobs and then a random boss mob wave after the mob stages.

 After completing the arena event, take the West Gate, which enters into the East Garrison. Immediately upon entering this room, turn to the right and go up the ramp leading into upper level of the arena. Once here, run around the edge of the arena and down into the hallway that leads to The Domicile. If you turn left, you run across the bridge into The Domicile. If you turn right, you reach the Shrine necessary to complete the quest to obtain the Shadowforge Key [item=11000].

 Once in The Domicile continue forward and down the ramp that is in the far corner of the room. Go down the ramp and turn into Shadowforge City.

 East Garrison Ramp Leading to Spectator Level

 The Hallway Leading to the Shrine

 Path to the Domicile

 The Domicile

 Once in Shadowforge City, skip The Black Vault (you will return to this once you have enough Dark Keeper Key [item=11197]) and run to the far right door that enters into the Hall of Crafting. Fight down to Fineous Darkvire [npc=9056] to obtain Ironfel to complete Dark Iron Legacy [quest=3802]. This fight is fairly straightforward, but if you don't clear out each Warbringer Construct [npc=8905] first, it can get quite challenging. From here, return through to The Domicile to The Shrine to complete Dark Iron Legacy [quest=3802].

 The Doorway to Fineous Darkvire

 The Shrine

 Now that you have the key, run back through The Domicile and back down through the room in which you fought Fineous Darkvire [npc=9056] to reach Lord Incendius [npc=9017]. Once slain, continue straight through to the Dark Iron Highway, which leads to Bael'Gar [npc=9016].

 Path to Lord Incendius - Bottom of The Hall of Crafting

 The Dark Iron Highway

Once Bael'Gar [npc=9016] is slain, return up the Dark Iron Highway and turn right at the fork, which leads back into the Detention Block and the Instance Portal.

 Using the Shadowforge Key [item=11000], you are able to open the two gates starting on your left and the subsequent East Garrison door. In this first room, the Shadowforge Lock must be released to close the gateway offering passage to the other side of Shadowforge City.

 The Shadowforge Lock

 East Garrison and the Left Hallway

 Once unlocked, go up the ramp and back through the East Garrison again, but this time instead of going up the ramp, take the left hallway. Follow this hallway until you reach the West Garrison. Clear all of the mobs on your way down the left ramp to General Angerforge [npc=9033]. This fight is quite difficult, so make sure every mob is killed before you engage this boss. Once it is slain, go back up the ramp and through to the next room to fight Golem Lord Argelmach [npc=8983]. This fight is also quite difficult, and will wipe groups who are lower geared.

 Ramp to General Angerforge

 Ramp to Golem Lord Argelmach

 After defeating Golem Lord Argelmach [npc=8983], you can progress towards The Grim Guzzler. This room can be quite tricky if not handled well. The primary objective to getting through it quickly is to buy 6 Dark Iron Ale Mug [item=11325] from Plugger Spazzring [npc=9499] to give to Private Rocknot [npc=9503]. After a few Dark Iron Ale Mug [item=11325] turn-ins to Private Rocknot [npc=9503], he will start to rage, which causes Phalanx [npc=9502] to activate to stop Private Rocknot [npc=9503]. In the process, the door to the remainder of the dungeon is smashed open. Before you can travel through it, Phalanx [npc=9502] must be defeated. This is a really easy fight, so it shouldn't cause much concern.

 The Grim Guzzler

 Plugger Spazzring

 Private Rocknot

 After this, you're basically in the home stretch of the dungeon. Take the first left and head down to Ambassador Flamelash [npc=9156], which is mostly a DPS race as a boss fight. Travel through the Mold Foundry to reach Chest of The Seven [object=169243], which consists of a seven wave event from one of seven dwarven spirits. After this, travel through the doorway into The Lyceum. Here, you must kill Shadowforge Flame Keeper [npc=9956] to obtain Shadowforge Torch [item=11885] to light one of two braziers to open the doors to fight Magmus [npc=9938]. 

 Within The Lyceum, however, be prepared for a difficult room. This is where AoE classes really shine. There are numerous packs of low HP mobs that must be killed, which have a really quick respawn timer. As such, speed is incredibly important. To reach Magmus [npc=9938], members must dodge the fire as they traverse through the room.

 Ramp to Ambassador Flamelash

 Mold Foundry

 Shadowforge Flame Keeper

 Brazier Platform in the Lyceum

 Room with Magmus

 The Imperial Seat

 At this point, the final encounter is to fight across The Imperial Seat and kill Emperor Dagran Thaurissan [npc=9019]. Some groups choose to kill Princess Moira Bronzebeard [npc=8929] as well for the loot, but this is not necessary to complete the dungeon as saving her is necessary to complete The Fate of the Kingdom [quest=4362] if you're Alliance and The Royal Rescue [quest=4003] if you're Horde.

## Blackrock Depths Bosses in World of Warcraft: Forever

High Interrogator Gerstahn [npc=9018] is the first boss many will face their first time in Blackrock Depths [zone=1584]! She is not exceedingly difficult overall, but can cause problems if you don't compensate for some of her mechanics. Killing her is necessary to obtain the Prison Cell Key [item=11140], which is used to complete quests in the Detention Block.

High Interrogator Gerstahn Strategy 
Overall, the approach to beating her is fairly simple. Her use of Psychic Scream [spell=13704] is the most challenging part of the encounter as it can lead to other packs being pulled. For Horde Shamans, use tremor to deal with the fear. For Alliance Dwarf Priests, use fear ward. 

Further, warrior tanks can attempt Berserker Rage [spell=18499], but the inability to effectively time and predict the fear makes utilizing this more about luck than timing. As for other tank/healer combinations and for DPS, attempt to wedge yourself deeply in a corner to attempt to mitigate some of the fear effects. 

Apart from the fear, dispel Shadow Word: Pain [spell=14032] and interrupt the Mana Burn [spell=14033]. 

High Interrogator Gerstahn Abilities 

-  Shadow Word: Pain [spell=14032] 
-  Mana Burn [spell=14033] 
-  Psychic Scream [spell=13704] 
-  Shadow Shield [spell=12040] 

Arguably, Lord Roccor [npc=9025] is one of the easiest bosses in Blackrock Depths [zone=1584]. Level 60 druids are able to solo this boss, which indicates just how easily he can be defeated.

Lord Roccor Strategy 
Lord Roccor [npc=9025] is incredibly easy. There is nothing really to look out for. Earth Shock [spell=13728] can interrupt casting, which is about the only real concern on this boss.

Lord Roccor Abilities 

-  Earth Shock [spell=13728]
-  Flame Shock [spell=13729]

Houndmaster Grebmar [npc=9319] is another fairly easy boss fight. He shouldn't cause issues as long as he is handled appropriate to his patrol path.

Houndmaster Grebmar Strategy 
Houndmaster Grebmar [npc=9319] pats around the room between two packs of hounds. Kill the pack of hounds opposite of his patrol path. Then, when he pats back, kill the other pack. Once both packs are dead.

Houndmaster Grebmar Abilities 

-  Bloodlust [spell=21049]
-  Demoralizing Shout [spell=13730]
-  Pummel [spell=15615]

Ring of the Law is, potentially, the most difficult aspect of the first half of Blackrock Depths [zone=1584]. The randomness of the encounter can cause issues if the group is not prepared for the possibilities. There are multiple possible bosses, which could be more optimal for some group compositions compared to others.

Gorosh the Dervish Strategy 
Gorosh the Dervish [npc=9027] is like a warrior with Whirlwind [spell=15589] and Mortal Strike [spell=15708]. Maximize healing output outside of the Mortal Strike [spell=15708] debuff. It is an easy fight as long as healer can sustain through the use Mortal Strike [spell=15708]. 

Gorosh the Dervish Abilities 

-  Whirlwind [spell=15589]
-  Mortal Strike [spell=15708]
-  Bloodlust [spell=21049]

Grizzle Strategy
Grizzle [npc=9028] is incredibly easy. There is nothing really to look out for. Earth Shock [spell=13728] can interrupt casting, which is about the only real concern on this boss.

Grizzle Abilities 

-  Ground Tremor [spell=6524]
-  Enrage [spell=8269]

Eviscerator Strategy
Eviscerator [npc=9029] is more annoying than difficult. Shadow Bolt Volley [spell=28599] can be rather annoying, but it shouldn't kill the group. That said, priests can utilize Shadow Protection [spell=16874] to their advantage here. The additional shadow resistance makes the fight trivial.

Eviscerator Abilities 

-  Anti-Magic Shield [spell=7121]
-  Shadow Bolt Volley [spell=28599]
-  Vicious Rend [spell=16095]

 Ok'Thor the Breaker Strategy
Ok'thor the Breaker [npc=9030] is the most difficult boss within Ring of the Law because of the number of abilities. He plays like a mage, and bad Polymorph [spell=14621] luck could lead to a wipe. The key is to dispel the Polymorph [spell=14621] and have as many members stay at range as possible to minimize the effect of Arcane Explosion [spell=26192]

Ok'Thor the Breaker Abilities 

-  Polymorph [spell=14621]
-  Arcane Explosion [spell=26192]
-  Arcane Bolt [spell=25055]
-  Slow [spell=13747]

 Anub'Shiah Strategy
Anub'shiah [npc=9031] is almost as difficult as Ok'thor the Breaker [npc=9030]. Curse of Tongues [spell=15470] and Enveloping Web [spell=15471] both need an immediate dispel. These are the difficult mechanics. The rest aren't too tricky. No real strategy needed other than the dispels.

Anub'Shiah Abilities 

-  Shadow Bolt [spell=15472]
-  Curse of Tongues [spell=15470]
-  Curse of Weakness [spell=12493]
-  Demon Armor [spell=13787]
-  Enveloping Web [spell=15471]

Hedrum the Creeper Strategy
Hedrum the Creeper [npc=9032] is a fairly straightforward boss. No real strategy is present outside of cleansing the poisons and dispel the Immobilize.

 Hedrum the Creeper Abilities 

-  Baneful Poison [spell=15475]
-  Paralyzing Poison [spell=3609]
-  Web Explosion [spell=15474]

Theldren
Theldren [npc=16059] can be summoned at the Ring of Law in Blackrock Depths by using the Banner of Provocation [item=21986] provided on the quest The Challenge [quest=9015]. This is part of the Tier 0.5 questline.

After completing this quest, you will receive another Banner of Provocation, allowing you to summon Theldren at any time you visit the Ring of the Law. 

Fineous Darkvire [npc=9056] is an optional boss once you complete the quest required to kill him. As such, many groups opt to avoid him because it is a pain trying to clear all of the adds to reach him.

Fineous Darkvire Strategy 
Fineous Darkvire [npc=9056] is a rather straightforward boss. He hits incredibly hard and has a healing mechanic. As such, it is important to interrupt the heal and for healers to pre-cast heals to keep up with the damage output. Further, when poorly geared, it is important to make sure all the adds along the pathway are killed to avoid an accidental aggro causing a wipe.

Fineous Darkvire Abilities 

-  Devotion Aura [spell=8258]
-  Holy Light [spell=15493]
-  Holy Strike [spell=13953]
-  Kick [spell=11978]
-  Seal of Reckoning [spell=15346]

Pyromancer Loregrain [npc=9024] is an optional boss that spawns near the Shrine. It is an incredibly easy fight. Skipped unless farming Formula: Enchant Weapon - Fiery Weapon [item=11207].

Pyromancer Loregrain Strategy 
Pyromancer Loregrain [npc=9024] does not really warrant discussion of strategy outside of destroying to totem. Incredibly easy boss to kill. 

Pyromancer Loregrain Abilities 

-  Scorching Totem [spell=15038]
-  Molten Blast [spell=15095]
-  Flame Shock [spell=15616]
-  Fire Ward [spell=15041]

Bael'Gar [npc=9016] is an optional boss that most groups skip because he is not important to the advancement of the dungeon.

Bael'gar Strategy 
Bael'Gar [npc=9016] spawns adds, which needs to be kill. Also, tanks need to face Bael'Gar [npc=9016] away from the group Magma Splash [spell=13880] is not a major concern if that is done. Outside of the tank taking a lot of damage, this fight is fairly easy. 

Bael'gar Abilities 

-  Summon Spawn of Bael'Gar [spell=13895]
-  Magma Splash [spell=13880]

Lord Incendius [npc=9017] is an optional boss, but most groups (even those doing Lava Runs) tend to grab him as he is an easy kill. He is also located by the Black Anvil, needed by Blacksmiths.

Lord Incendius Strategy 
Lord Incendius [npc=9017] is not difficult, but tanks and group members need to make sure they don't get knocked off the platform because there is no getting back up outside of dying. 

Lord Incendius Abilities 

-  Curse of the Elemental Lord [spell=26977]
-  Fiery Burst [spell=13900]
-  Fire Storm [spell=13899]
-  Mighty Blow [spell=14099]

The Vault is an interesting aspect of the dungeon. There are two things to remember about The Vault. Firstly, there is a placard on the wall indicating where the mob is to obtain the Dark Keeper Key [item=11197]. Secondly, if you open all of the coffers, a boss fight with Watchman Doomgrip [npc=9476] will begin. 

I won't write strategy or post loot from the random mob who holds Dark Keeper Key [item=11197] as there are multiple random mobs who are all incredibly easy to kill with virtually zero abilities. To that end, I will only focus on Warder Stilgiss for this guide. Another guide will be forthcoming on how to complete a Dark Iron Coffer run for the Burning Essence [item=11751].

Warder Stilgiss and Verek Strategy (Rare Spawn)
Warder Stilgiss [npc=9041] spawns with Verek [npc=9042]. The fight is not difficult for a five man group. Just kill Warder Stilgiss [npc=9041] first and then Verek [npc=9042] next. 

Warder Stilgiss Abilities 

-  Frostbolt [spell=12675]
-  Frost Ward [spell=15044]
-  Frost Nova [spell=12674]
-  Frost Armor [spell=12556]

Secret Safe
This lootable chest spawns upon opening all twelve Relic Coffer [object=160836] in Blackrock Depths. Once the final coffer has been opened, the stone guardians in the room will come alive and Watchman Doomgrip [npc=9476] will spawn. Upon defeating all enemies, a hidden door beneath the Dark Coffer [object=160845] will open allowing access to the Secret Safe [object=161495] as well as the Heart of the Mountain [object=165554].

 General Angerforge [npc=9033] is an optional boss, but a lot of players will want to farm it for Hand of Justice [item=11815] and Force of Will [item=11810]. Overall, the fight is fairly difficult because of the adds. If your group is lacking on AoE damage, the fight is harder than it would otherwise be. 

 General Angerforge Strategy 
 General Angerforge [npc=9033] is straightforward. He behaves like a warrior, and then calls adds during the encounter. Just burn him and AoE the adds when they come. They have fairly low health, so they die fairly easily. 

 General Angerforge Abilities 

 
-  Sunder Armor [spell=15572]

 Golem Lord Argelmach [npc=8983] is an another optional boss that most avoid after the first few runs. It is one of the more challenging fights in Blackrock Depths [zone=1584], which is one reason why many avoid the fight all together. The primary reason to enter this room is for the Schematic: Field Repair Bot 74A [object=179552], which is near Golem Lord Argelmach [npc=8983]. Every raid will want an engineer who is able to craft this item, so be prepared to visit a lot.

 Golem Lord Argelmach Strategy 
 Golem Lord Argelmach [npc=8983] is a difficult fight because of Chain Lightning [spell=15305]. It is an unrelenting amount of damage if you're group is stacked too close together. As such, the real key to this fight is remaining spread out so that Chain Lightning [spell=15305] doesn't freely bounce from target to target, which is the major killing mechanic on this fight.

 Golem Lord Argelmach Abilities 

 
-  Chain Lightning [spell=15305]
-  Lightning Shield [spell=15507]
-  Shock [spell=15605]

 There are a series of encounters in The Grim Guzzler that are covered in the Blackrock Depths Quest Guide, so I won't spend a great deal of time covering the minor encounters, such as Ribbly Screwspigot [quest=4136] and Lost Thunderbrew Recipe [quest=4134]. However, Phalanx [npc=9502] will be discussed as it is the primary encounter within The Grim Guzzler.

 The Grim Guzzler is a bar in Blackrock Depths featuring neutral patrons as well as the vendors Plugger Spazzring [npc=9499] and Lokhtos Darkbargainer [npc=12944]. However, you may want to get into barfights with the patrons to complete quests or kill bosses.

 Phalanx Strategy 
 To get through the room quickly just buy 6 Dark Iron Ale Mug [item=11325] from Plugger Spazzring [npc=9499] to give to Private Rocknot [npc=9503]. After three turn-ins of Dark Iron Ale Mug [item=11325] to Private Rocknot [npc=9503], he will start to rage. This action causes Phalanx [npc=9502] to activate to stop Private Rocknot [npc=9503]. The door to the remainder of the dungeon is smashed open during the scuffle. Phalanx [npc=9502] hit fairly hard with Mighty Blow [spell=14099], but this does not warrant a lengthy strategy discussion.

 The group may be tempted to throw these bottles at patrons as the tool tip explains, but refrain from doing this as they will become angry. 

 The other method to reach the next room past the Grim Guzzler is not as easy. This involves doing The Love Potion [quest=4201], which allows Nagmara to seduce Rocknot. 

 Phalanx Abilities
 
-  Thunderclap [spell=15588]
-  Mighty Blow [spell=14099]
-  Fireball Volley [spell=15285]

 Hurley Blackbreath
 To spawn Hurley, you must break the three kegs in the Grim Guzzler storage room. It is a much more difficult fight because of the adds accompanying Hurley Blackbreath [npc=9537]. That said, this is a completely avoidable fight, so I am not including major details about it. However, some basic strategy would be to utilize CC on the adds and burn Hurley. 

 Ribbly Screwspigot
 There is also a quest in the Grim Guzzler for Ribbly Screwspigot [npc=9543], which is an incredibly simple encounter. No strategy involved.

 Plugger Spazzring Strategy
 Plugger Spazzring [npc=9499] starts off neutral, but can quickly turn hostile, aggroing all the other patrons in the bar. It is advised to place Dark Iron Ale Mug [item=11325] down in the corner by Lokhtos Darkbargainer [npc=12944], so the Patrons walk over, get stunned, and can be killed easily. This helps clear the area so Plugger Spazzring [npc=9499] will not aggro nearly Patrons while engaged.

 Plugger Spazzring [npc=9499] will also turn hostile if you loot too many mugs on his table, or if a Rogue pickpockets him for Grim Guzzler Key [item=11602]. Make sure you pull him when he patrols closest towards Lokhtos Darkbargainer [npc=12944], near the area you previously cleared.

 Plugger Spazzring [npc=9499] is a fairly easy fight, and is often soloed by rogues for the powerful dagger. The main concern is his Shadow Bolt [spell=12739] which can be negated with a Greater Shadow Protection Potion [item=13459].

 Ambassador Flamelash [npc=9156] is a DPS race is some sense. There are adds that spawn which rush to the boss. If they reach the boss, he gets a buff. However, these adds can easily be killed before reaching him. As such, the way to beat him is to kill the adds before they reach him and increase his damage beyond which the healer is able to heal.

 Ambassador Flamelash Strategy 
 Ambassador Flamelash [npc=9156] summons adds continually throughout the encounter, which give him a buff if they reach him. As such, these adds need to be killed away from the boss. Keep his stacks low, and this is an incredibly easy fight.

 Ambassador Flamelash Abilities 

 
-  Burning Spirit [spell=13489]
-  Burning Spirit [spell=14744]

Rare Spawn
 Panzor the Invincible [npc=8923] is a rare boss spawn within The Mold Foundry. He is fairly annoying to casters because of Spell Reflection [spell=9941], but outside of that, he is a fairly easy encounter.

 Panzor the Invincible Strategy 
 Panzor the Invincible [npc=8923] is not a mob that will be encountered often. However, when encountered, the biggest thing is for casters to watch out for Spell Reflection [spell=9941]. other than that, it is an easy encounter.

 Panzor the Invincible Abilities 

 
-  Spell Reflection [spell=9941]

 Chest of The Seven [object=169243] is another fairly easy fight. This is a multistage encounter against 7 waves of dwarven spirits. Each spirit reflects a particular class (e.g., priest, warlock, and rogue); however, it isn't worth offering unique strategy for each. They are all quite easy to kill. The only concern is killing them too slowly, which might mean you get an additional dwarf before you've completely killed the one you're focusing as they are released on a set timer.

 Chest of the Seven Strategy 
 No real strategy other than killing each quickly. They will possess one or two abilities of their specific class, but in a weakened state. Try to kill them quickly to avoid fighting two or more at a time. The names of the seven dwarves are:
 
- Hate'rel [npc=9034]
- Anger'rel [npc=9035]
- Vile'rel [npc=9036]
- Gloom'rel [npc=9037]
- Seeth'rel [npc=9038]
- Doom'rel [npc=9039]
- Dope'rel [npc=9040]

 The Lyceum is not so much a boss encounter, but more so a gauntlet that has to be maneuvered quickly and efficiently. This is unavoidable, so groups need to master this.

 The Lyceum Strategy 
 Shadowforge Flame Keeper [npc=9956] randomly patrol within The Lyceum, and they drop Shadowforge Torch [item=11885], which are used to light each brazier. The goal is to aggro as few of the normal packs as possible and grab the two Shadowforge Flame Keeper [npc=9956] as quickly as possible before the normal mobs respawn. 

 The optimum strategy is to use s and s for immense AoE damage here to burn the normal packs as they crash down on the MT. A class like a is great for pulling the Shadowforge Flame Keeper [npc=9956] because they shoot instantly. Couple the AoE timing with the hunter timing, and you're going to breeze through the room.

 Magmus [npc=9938] is a tricky fight because of the fires coming from each side throughout the chamber.

 Magmus Strategy 
 Magmus [npc=9938] stands at the end of a long chamber. WIthin the chamber, there are two rows of fire belching golems. This fire is brutal and will kill you rapidly. As such, it is on the tank to put Magmus [npc=9938] in a good position, so that the flames aren't an issue. Outside of the flames from the sides of the chamber, the fight is fairly easy. This fight is all about positioning the boss correctly.

 Magmus Abilities 

 
-  Fiery Burst [spell=13900]
-  War Stomp [spell=24375]

 Save or Kill Princess Moira Bronzebeard
 This is the final boss encounter within BRD. Groups can proceed in one of two directions. Either they can choose to save Princess Moira Bronzebeard [npc=8929] and kill Emperor Dagran Thaurissan [npc=9019], or they can choose to kill both. Most groups will save Princess Moira Bronzebeard [npc=8929] to complete the quest and then kill her each time afterwards because she had good drops.

 Emperor Strategy 
 This is, unquestionably, the most difficult encounter of the dungeon, so be prepared for a fun fight. However, if you're a warrior tank or dps, get super comfortable, you'll live here while working on obtaining Ironfoe [item=11684].

 If you are choosing to save Princess Moira Bronzebeard [npc=8929], then your strategy is to keep her occupied with an off-tank, or someone who can interrupt her casts. because she can be fairly squishy. Further, she assists Emperor Dagran Thaurissan [npc=9019] within the fight, so you can't allow her to simply free cast the entire encounter. As soon as Emperor Dagran Thaurissan [npc=9019] dies, she breaks free from the mind control she was under to become friendly.

 However, if your intention is to kill Princess Moira Bronzebeard [npc=8929], then you burn her before killing Emperor Dagran Thaurissan [npc=9019]. Make sure you have some form of interrupt because she can do a fair amount of damage, which can be hard to heal through coupled with the damage output of Emperor Dagran Thaurissan [npc=9019].

 Looting Princess Moira Bronzebeard [npc=8929] can be buggy; make sure your group has completed the The Princess's Surprise [quest=4363]/The Princess Saved? [quest=4004] chain first.

 Emperor Dagran Thaurissan Abilities 

 
-  Hand of Thaurissan [spell=17492]
-  Avatar of Flame [spell=15636]
-  Ironfoe [spell=15642]

 Princess Moira Bronzebeard Abilities
 
-  Heal [spell=15586]
-  Renew [spell=10929]
-  Power Word: Shield [spell=10901]
-  Mind Blast [spell=15587]
-  Shadow Word: Pain [spell=15654]
-  Smite [spell=10934]
-  Shadow Bolt [spell=15537]
-  Princess Summons Portal [spell=13912]

## Blackrock Depths Loot in World of Warcraft: Forever

Item | Type | 

Greaves of Withering Despair [item=22240] | Mail Boots | 

Blackveil Cape [item=11626] | Cloak | 

Enthralled Sphere [item=11625] | Offhand | 

Kentic Amice [item=11624] | Cloth Shoulders | 

Item | Type | 

Idol of Ferocity [item=22397] | Druid {/forever/class=11/druid} Relic | 

Mantle of Lost Hope [item=22234] | Cloth Shoulder | 

Stoneshell Guard [item=11631] | Shield | 

Earthslag Shoulders [item=11632] | Plate Shoulders | 

Rockshard Pellets [item=11630] | Bullets | 

Formula: Smoking Heart of the Mountain [item=11813] | Enchanting Recipe | 

Item | Type | 

Spritecaster Cape [item=11623] | Spellpower Cloak | 

Houndmaster's Rifle [item=11629] | Gun | 

Houndmaster's Bow [item=11628] | Bow | 

Fleetfoot Greaves [item=11627] | Mail Feet | 

Gorosh the Dervish

Item | Type | 

Savage Gladiator Chain [item=11726] | Mail Chest | 

Leggings of Frenzied Magic [item=22271] | Leather Legs | 

Flarethorn [item=22266] | Caster Dagger | 

Bloodclot Band [item=22257] | Healing Ring | 

Grizzle

Item | Type | 

Entrenching Boots [item=22270] | Plate Boots  | 

Dregmetal Spaulders [item=11722] | Mail Shoulder  | 

Stonewall Girdle [item=11703] | Plate Belt | 

Grizzle's Skinner [item=11702] | MH Axe | 

Plans: Dark Iron Pulverizer [item=11610] | Blacksmith Weapon Pattern | 

 Eviscerator

Item | Type | 

Savage Gladiator Grips [item=11730] | Mail Gloves | 

Rubicund Armguards [item=11679] | Mail Wrist | 

Splinthide Shoulders [item=11685] | Leather Shoulders | 

Girdle of Beastial Fury [item=11686] | Leather Waist | 

Ok'Thor the Breaker

Item | Type | 

Savage Gladiator Leggings [item=11728] | Mail Legs | 

Ban'thok Sash [item=11662] | Cloth Waist | 

Ogreseer Fists [item=11665] | Leather Hands | 

Cyclopean Band [item=11824] | Ring | 

 Anub'Shiah

Item | Type | 

Savage Gladiator Greaves [item=11731] | Mail Feet | 

Shadefiend Boots [item=11675] | Leather Feet | 

Graverot Cape [item=11677] | Cloak | 

Carapace of Anub'shiah [item=11678] | Plate Chest | 

 Hedrum the Creeper

Item | Type | 

Savage Gladiator Helm [item=11729] | Mail Helm | 

Spiderfang Carapace [item=11633] | Plate Chest | 

Silkweb Gloves [item=11634] | Cloth Hands | 

Hookfang Shanker [item=11635] | Dagger | 

Theldren

Item | Type | 

Ironweave Mantle [item=22305] | Cloth Shoulders | 

Lefty's Brass Knuckle [item=22317] | Fist Weapon | 

Malgen's Long Bow [item=22318] | AP Bow | 

Shroud of Arcane Mastery [item=22330] | Intellect Cloak | 

Item | Type | 

Foreman's Head Protector [item=22223] | Plate Helm  | 

Chief Architect's Monocle [item=11839] | Cloth Helm | 

Senior Designer's Pantaloons [item=11841] | Cloth Legs | 

Lead Surveyor's Mantle [item=11842] | Mail Shoulder | 

Master Builder's Shirt [item=11840] | Shirt | 

Item | Type | 

Kindling Stave [item=11750] | Fire Resistance Staff | 

Searingscale Leggings [item=11749] | Mail Fire Resistance Legs | 

Pyric Caduceus [item=11748] | Wand | 

Flamestrider Robes [item=11747] | Leather Fire Resistance Chest | 

Formula: Enchant Weapon - Fiery Weapon [item=11207] | Enchanting Formula | 

Item | Type | 

Lavacrest Leggings [item=11802] | Plate Legs | 

Force of Magma [item=11803] | 2H Mace | 

Rubidium Hammer [item=11805] | MH Mace | 

Sash of the Burning Heart [item=11807] | Cloth Waist | 

Item | Type | 

Cinderhide Armsplints [item=11764] | Leather Wrist | 

Pyremail Wristguards [item=11765] | Mail Wrist | 

Flameweave Cuffs [item=11766] | Cloth Wrist | 

Emberplate Armguards [item=11767] | Plate Wrist | 

Warder Stilgiss

Item | Type | 

Dark Warder's Pauldrons [item=22241] | Leather Shoulder | 

Arbiter's Blade [item=11784] | MH Sword | 

Chillsteel Girdle [item=11783] | Mail Waist | 

Boreal Mantle [item=11782] | Cloth Shoulder | 

Verek

Item | Type | 

Verek's Leash [item=22242] | Mail Belt  | 

Verek's Collar [item=11755] | Amulet | 

Verek's Leash [item=22242] | Mail Waist | 

Secret Safe

Item | Type | 

Wand of Eternal Light [item=22254] | Wand | 

Deathdealer Breastplate [item=11926] | Mail Chest | 

Haunting Specter Leggings [item=11929] | Cloth Legs | 

Wraith Scythe [item=11920] | 1H Axe | 

The Hammer of Grace [item=11923] | 1H Healing Mace | 

Item | Type | 

 Angerforge's Battle Axe [item=11816] | 2H Axe | 

 Lord General's Sword [item=11817] | 1H Sword | 

 Royal Decorated Armor [item=11820] | Mail Chest | 

 Warstrife Leggings [item=11821] | Leather Legs | 

 Force of Will [item=11810] | Defense Trinket | 

Item | Type | 

Naglering [item=11669] | Defense Ring | 

Second Wind [item=11819] | Healing Trinket | 

Omnicast Boots [item=11822] | Cloth Feet | 

Luminary Kilt [item=11823] | Leather Legs | 

Phalanx

Item | Type | 

Golem Fitted Pauldrons [item=22212] | Mail Shoulder | 

Bloodfist [item=11744] | Fist Weapon | 

Fists of Phalanx [item=11745] | Plate Hands | 

 [item=11743] | Fist Weapon | 

Hurley Blackbreath

Item | Type | 

Firemoss Boots [item=22275] | Leather Boots  | 

Hurley's Tankard [item=18044] | 1H Mace | 

Coal Miner Boots [item=18043] | Leather Fire Resistance Boots | 

Ribbly Screwspigot

Item | Type | 

Plans: Dark Iron Plate [item=11612] | BoP Blacksmithing Plans | 

 Wayfarer's Knapsack [item=11742] | 16 Slot Bag | 

 Ribbly's Bandolier [item=2663] | Hunter Ammo Bag | 

 Ribbly's Quiver [item=2662] | Hunter Arrow Bag | 

 

Plugger Spazzring

Item | Type | 

Schematic: Goblin Jumper Cables XL [item=18653] | Engineering Schematic | 

Barman Shanker [item=12791] | Dagger | 

 Mixologist's Tunic [item=12793] | Leather Chest | 

Item | Type | 

Circle of Flame [item=11808] | Cloth Fire Resistance Helm | 

Flame Wrath [item=11809] | Polearm | 

Cape of the Fire Salamander [item=11812] | Fire Resistance Cloak | 

Molten Fists [item=11814] | Mail Fire Resistance Gloves | 

Burst of Knowledge [item=11832] | Spellpower Trinket | 

Item | Type | 

Soot Encrusted Footwear [item=22245] | Cloth Boots  | 

Rock Golem Bulwark [item=11785] | Shield | 

Shalehusk Boots [item=11787] | Plate Feet | 

Stone of the Earth [item=11786] | 2H Sword | 

Item | Type | 

Wraith Scythe [item=11920] | 1H Axe | 

Impervious Giant [item=11921] | 2H Mace | 

Blood-Etched Blade [item=11922] | Spellpower Dagger | 

The Hammer of Grace [item=11923] | Healing Mace | 

Ghostshroud [item=11925] | Leather Helm | 

Deathdealer Breastplate [item=11926] | Mail Chest | 

Legplates of the Eternal Guardian [item=11927] | Plate Defense Legs | 

Haunting Specter Leggings [item=11929] | Cloth Legs | 

Item | Type | 

Golem Skull Helm [item=11746] | Plate Helm | 

Libram of Truth [item=22400] | Paladin {/forever/class=2/paladin} Relic  | 

Totem of Rage [item=22395] | Shaman {/forever/class=7/shaman} Relic  | 

Lavastone Hammer [item=22208] | 2H Mace | 

Magmus Stone [item=11935] | Fire Resistance Offhand | 

Item | Type | 

Wristguards of Renown [item=22204] | Leather Bracer  | 

Sash of the Grand Hunt [item=22207] | Mail Belt  | 

Hand of Justice [item=11815] | Trinket | 

Ironfoe [item=11684] | Mace that grants extra attacks | 

Robes of the Royal Crown [item=11924] | Cloth Chest  | 

Thaurissan's Royal Scepter [item=11928] | Healing Offhand | 

Guiding Stave of Wisdom [item=11932] | Healing Staff | 

Emperor's Seal [item=11934] | Ring | 

 The Emperor's New Cape [item=11930] | Cloak | 

 Imperial Jewel [item=11933] | Attack Power Neck | 

Dreadforge Retaliator [item=11931] | 2H Axe | 

Princess Moira Bronzebeard

Item | Type | 

Swiftwalker Boots [item=12553] | Leather Feet | 

Hands of the Exalted Herald [item=12554] | Cloth Hands  | 

High Priestess Boots [item=12556] | Cloth Feet | 

Ebonsteel Spaulders [item=12557] | Plate Shoulders | 

Blackrock Depths is considered the first dungeon to drop Bind-on-Equip items that are Best-in-Slot items for raiding at level 60. Most of these items are fairly valuable on the auction house and weapons such as Ribsplitter [item=12527] and The Judge's Gavel [item=12528] are valued by level 49 twinks. 

Item | Type | 

Spire of the Stoneshaper [item=12532] | Two-Handed Staff | 

Braincage [item=12549] | Mail Helm | 

Funeral Pyre Vestment [item=12542] | Cloth Chest | 

Searing Needle [item=12531] | One-Handed Dagger | 

Doomforged Straightedge [item=12535] | One-Handed Sword | 

Blisterbane Wrap [item=12552] | Back | 

Mar Alom's Grip [item=12547] | Leather Hands | 

Ribsplitter [item=12527] | Main-Hand Axe | 

The Judge's Gavel [item=12528] | Two-Handed Mace | 

Stoneshield Cloak [item=12551] | Back | 

Aristocratic Cuffs [item=12546] | Cloth Wrist | 

Runed Golem Shackles [item=12550] | Plate Wrist | 

Battlechaser's Greaves [item=12555] | Plate Feet |

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/blackrock-depths und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **High Interrogator Gerstahn** [9018]: Shadow Word: Pain (14032)
- **Ring of the Law** [9027, 9028, 9029, 9030, 9031, 9032]: Whirlwind (15589), Mortal Strike (15708), Bloodlust (21049), Cleave (15579), Shadow Bolt Volley (28599), Vicious Rend (16095), Polymorph (14621), Arcane Explosion (26192), Arcane Bolt (25055), Shadow Bolt (15472), Curse of Weakness (12493), Demon Armor (13787), Baneful Poison (15475)
- **Fineous Darkvire** [9056]: Devotion Aura (8258), Seal of Reckoning (15346)
- **Pyromancer Loregrain** [9024]: Fire Ward (15041)
- **Bael'gar** [9016]: Magma Splash (23379)
- **Lord Incendius** [9017]: Fiery Burst (13900)
- **Phalanx** [9502]: Mighty Blow (14099), Thunderclap (15588), Fireball Volley (15285)
- **Ambassador Flamelash** [9156]: Burning Spirit (14744)
- **Chest of the Seven** [9034, 9035, 9036, 9037, 9038, 9039, 9040]: Mana Burn (14033), Shadow Bolt (15232), Shadow Shield (12040), Shield Block (12169), Shield Wall (15062), Sunder Armor (11971), Heal (15586), Mind Blast (15587), Power Word: Shield (11974), Cleave (15584), Hamstring (9080), Mortal Strike (13737), Recklessness (13847), Cone of Cold (15244), Frost Armor (12544), Frost Nova (12674), Frost Ward (15044), Frostbolt (12675), Banish (8994), Curse of Weakness (12493), Demon Armor (13787), Immolate (12742), Shadow Bolt Volley (15245), Summon Voidwalkers (15092), Backstab (15582), Evasion (15087), Gouge (12540), Rupture (15583), Sinister Strike (15581)
- **Emperor Dagran Thaurissan** [9019, 8929]: Ironfoe (15642), Renew (10929), Power Word: Shield (10901), Shadow Word: Pain (15654), Smite (10934), Shadow Bolt (15537)
- **Warder Stilgiss & Verek (Rare)** [9041, 9042]: Frost Armor (12544), Frost Ward (15044)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: keine

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist

## Abilities from other sources

Quelle: warcraft.wiki.gg (CC BY-SA 3.0, paraphrasiert). **classic-source, unverified for Forever.** Seiten nennen oft keine Spell-IDs (IDs dann aus Wowhead-Journal oben); einzelne Wiki-IDs sind Retail-IDs (markiert).

| Boss (NPC) | Ability | Spell ID | Was es tut | Umgang | Confidence |
|---|---|---|---|---|---|
| High Interrogator Gerstahn (9018) | Shadow Word: Pain / Mana Burn / Psychic Scream / Shadow Shield | 14032 / 14033 / 13704 / 12040 | Schatten-DoT 18 s / Mana-Entzug + Schaden / Furcht bis 5 Ziele 6 s / Schild 200 Absorb | SWP dispellen, Mana Burn kicken, Schild purgen, schnell toeten; Pull bringt 2 Elites + 3 Hunde | mittel |
| Lord Incendius (9017) | Fiery Burst / Fire Storm / Mighty Blow / Curse of the Elemental Lord | 13900 / 13899 / 14099 / 26977 | 510-690 Feuer im Zielgebiet / Feuersaeule + DoT 30 s / Treffer + Rueckstoss / Feuerresistenz -100 (Fluch, stapelbar) | Feuerresistenz (150-200), Fluch entfernen, Rueckstoss in Wandnischen/Lava beachten; immun gegen Betaeubung | mittel |
| Bael'gar (9016) | Magma Splash / Summon Spawn of Bael'gar | 23379 / 13895 | Feuer-DoT 24 s auf Tank / 3 min Add, Beschwoerung 1388-1612 Feuer im Gebiet | Aus dem Zielgebiet laufen, Add aufnehmen | mittel |
| Ambassador Flamelash (9156) | Burning Spirit | 14744 (Wowhead) | 7 Flammenrunen schicken Geister; jeder stapelt +5% Schaden/Groesse (bis 50) oder heilt ihn | AoE-Caster fuer Geister abstellen; alternativ ignorieren und durchbrennen | mittel |
| Fineous Darkvire (9056) | Devotion Aura / Seal of Reckoning / Holy Strike / Holy Light | 8258 (Wowhead) bzw. 17232 (Wiki) / 15346 / 13953 / (Wiki 343151 = Retail) | +Ruestung / Siegel / Zusatz-Heiligschaden / Heilung | Holy Light kicken, Siegel dispellen, vorher Adds raeumen (Patrouille auf Rampe) | niedrig (IDs widerspruechlich, Kick 283681 und Seal 284436 sind Retail) |
| Emperor Dagran Thaurissan (9019) + Moira (8929) | Avatar of Flame / Ironfoe / Hand of Thaurissan; Moira: Heal, Renew, Mind Blast | Wiki ohne IDs; Wowhead: Ironfoe 15642, Renew 10929, Shadow Word: Pain 15654 | 10 s magie-immun + Feuer-Treffer / Extra-Schlaege / Feuerschaden + 5 s Betaeubung | Waehrend Avatar physisch schaden, Moira-Heals kicken, Raum vorher raeumen | niedrig-mittel |
| Phalanx (9502) | Mighty Blow / Thunderclap / Fireball Volley | 14099 / 15588 / 15285 (Wowhead) | - | Wiki-Seite "Phalanx" ist Retail-Talent, keine Boss-Daten | - |
| Ring of the Law (9027-9032) | - | siehe Wowhead-Liste | Wiki: 2 Add-Wellen, dann zufaelliger Endgegner (Anub'shiah, Eviscerator, Gorosh, Grizzle, Hedrum, Ok'thor); Banner of Provocation ersetzt ihn durch Theldren-Gruppe (taunt-immun, CC empfohlen) | Keine Fahigkeiten auf der Seite | niedrig |

Nicht gefunden (Wiki 404/leer): Pyromancer Loregrain, Chest of the Seven (Doomrel & Co.), Warder Stilgiss/Verek.
URLs: https://warcraft.wiki.gg/wiki/High_Interrogator_Gerstahn, /Lord_Incendius, /Bael%27Gar, /Ambassador_Flamelash, /Fineous_Darkvire, /Emperor_Dagran_Thaurissan, /Ring_of_Law
