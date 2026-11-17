# City of Dalaran - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=34964 (city-of-dalaran)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/city-of-dalaran


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/city-of-dalaran

Journal: areaId (zone) 16560; level range from journal: None-None; kind dungeon

Journal description: The City of Dalaran features us clearing out the threats that have overrun the beloved city of mages after the Magic barrier surrounding the city was cleared. Dalaran was one of the original cities in Azeroth and was ruled by the Kirin Tor, a council of wizards who housed some of the most impressive libraries and research facilities in all of Azeroth within the Dalaran walls. During the Third War, Arthas, the Prince who succumbed to the influence of Ner'zhul, laid siege to the city and killed many of its citizens and leaders. Kel'Thuzad then summoned Archimonde, a leader of the Burning Legion, who destroyed the city. Surviving wizards have since been rebuilding the city, and the reconstruction is finally done, and we now get to see Dalaran in its full glory for the first time in Classic World of Warcraft.

### Journal quests (id, level as shown, side)
- The Grave Knight [quest=96986] level 33, Horde
- Source of Power [quest=96988] level 33, Horde
- Opportunistic Education [quest=96987] level 33, Horde
- Heart of Disruption [quest=96984] level 33, Horde
- Power Overwhelming [quest=92489] level 33, Alliance
- Heart of Disruption [quest=92458] level 33, Alliance
- A Green Sample [quest=92456] level 33, Alliance
- Starving Arcane [quest=92457] level 33, Alliance

### Journal bosses

#### Atrexis the Grave Knight (NPC ids [247126])
Overview: You will encounter Atrexis the Grave Knight very early in the dungeon, and as a consequence, he's a very easy tank-and-spank style boss. His primary mechanic is summoning Skeletons, non-elite mobs, that need to be killed. They don't have any time-sensitive mechanics, and the only way you die during this encounter is if you use heavy AoE before the tank has established threat, so be careful. This boss is essentially designed to test the strength of your tank with abilities like Unholy Frenzy, Thrash, and Strike. Make sure to put on a shield for this encounter. The boss will also periodically use Disarm on the tank.
Role notes: damage: Prioritize killing the adds, but be careful, as the tank will need some time to generate threat first.
- Disarm [spell=6713]: Disarms an enemy, forcing it to stop wielding its weapon for 6 sec.
- Raise Dead [spell=1303266]: 
- Unholy Frenzy [spell=1303264]: Increases an ally's attack speed by 75% for 20 sec, but also inflicts 2 Nature damage to that ally every 2 sec.
- Thrash [spell=3391]: Gives the caster 2 extra attacks.
- Strike [spell=12057]: Strikes at an enemy, inflicting weapon damage plus 8.
Loot: Graveweave Bindings [item=273036], Bonebinder's Signet [item=273032], Gravespike Repeater [item=273033]

#### Arcane Anomaly (NPC ids [245999])
Overview: Arcane Anomaly is one of the bosses you can kill after exiting the sewers and has a core defining mechanic that will kill you if mishandled. Focal Blast is an arcane slicer that cuts across the room and rotates counterclockwise. This is a mechanic many raiders will be familiar with if they played WoW before picking up Forever and can be seen in bosses like C'thun, Halion, and Norushen. Make sure to avoid this ability, or you will die. Another thing to keep in mind is that the boss spawns small adds at the edge of the room when you engage it, so make sure to stay within the circle on the platform to avoid pulling them into the boss. The boss will periodically cast Arcane Bolt in addition to its normal melee attacks.
- Arcane Bolt [spell=1240682]: Hurls a magical bolt at an enemy, inflicting Arcane damage.
- Focal Blast [spell=1241501]: Channels energy forward dealing damage to any targets caught within the blast. | note: This ability cuts across the room and rotates counterclockwise; avoid being hit by it, or you will die.
Loot: Runemender's Seal [item=273031], Ephemeral Grips [item=273034], Mana-Warped Chain Shirt [item=273035]

#### Arcanic Enigma (NPC ids [246016])
Overview: Arcanic Enigma has 2x [npc=269475] accompanying him as you begin the fight. These should be burned down quickly, as they have a Mana Burn that is very taxing on whoever is targeted. Manamorph will occasionally CC a group member for 8 seconds and needs to be dispelled by someone with the ability to dispel Magic. Speaking of dispelling Magic, it may be a good idea for your healer to stand far away from the rest of your group, as the boss will cast an AoE Silence on targets close to the boss. The boss will continuously spawn small [npc=246893] throughout the fight, and they need to be cleaved down. These are not as much of a priority as Mana Phantoms, but the boss will not spawn additional Mana Phantoms during the encounter.
Role notes: healer: Keep your distance from the boss.; damage: Kill the Mana Phantoms first, and kill Arcane Manalings whenever they spawn.
- Silence [spell=1224125]: Silences an enemy, preventing it from casting spells for 10 sec. | note: The healer and casters should stay away from the boss to avoid being hit by this AoE silence.
- Manamorph [spell=1240869]: Transforms an enemy into an animal, forcing it to wander around for up to 8 sec. While wandering, the polymorph cannot attack or cast spells. | note: Players should dispel this magic debuff whenever someone is afflicted by it.
- Summon Manaling [spell=1304455]:  | note: Arcane Manaling are spawned throughout the fight, and should be killed.
Loot: Drape of Shifting Energy [item=273045], Wand of Mana Concentration [item=273043], Violet Sorcerer's Robes [item=273044]

#### Unstable Sentinel (NPC ids [246017])
Overview: Unstable Sentinel has one defining mechanic, and that is Malfunction. Malfunction will have a short wind-up before unleashing heavy AoE damage to anyone within 25 yards. Ranged players should stay at max range for the entire fight, and melee players should run out whenever you see the wind-up. Depending on your level and group composition, you could likely stay in as a melee, but being kind to the healer should be the baseline. [i]Note: Non-elite enemies called [npc=254856] will spawn from the buildings as you approach the boss. Kill these before engaging the fight to make things a little bit easier. [/i]
Role notes: tank: Face the boss away from your group.; healer: Stay at least 25 yards from the boss.; damage: Run, or stay, at least 25 yards away from the boss when they begin casting Malfunction.
- Malfunction [spell=1241329]: A malfunction has occurred. Every 2s arcane energy is released dealing damage to players in a nearby area. | note: After a short wind-up, Malfunction deals heavy AoE damage to players within 25 yards. Melee should run at least 25 yards away from the boss when this cast begins, and casters and healers should stay away from the boss at all times.
- Arcing Smash [spell=16169]: Lashes out in a vicious arc, inflicting normal damage plus 5 to enemies in a cone in front of the caster.
- Arcane Explosion [spell=1241325]: Sends out a blast wave of magic, inflicting 15 Arcane damage to nearby enemies.
Loot: Guardian's Dualblade [item=273046], Unstable Crystalline Shoulderpads [item=273047], Refractory Scaleguards [item=273048], Blueprint: Spinning Wheel [item=273099]

#### Mana Devourer (NPC ids [246008])
Overview: Mana Devourer resides by the entrance to Violet Hold and can be deceptively difficult. The boss will periodically cast Debilitate, which deals damage to everyone within 45 yards and drains 200 mana. Additionally, the boss will cast Drain Vitality on the current target, dealing arcane damage on impact and over a 10-second duration. This boss is essentially a rush against time, as the group will sooner or later run out of mana unless you defeat the boss quickly enough. The boss is also immune to arcane spells. [b]Note: Make sure to clear out all the trash in the boss area. They will join the fight after engaging the boss if they are still alive.[/b]
Role notes: tank: Clear all mobs in the area before pulling the boss.
- Debilitate [spell=1240750]: Hits an enemy with a bolt of draining arcane power that siphons up to 200 mana. | note: Players will periodically be drained of mana, so the boss needs to be killed as quickly as possible.
- Drain Vitality [spell=1240738]: Drains the vitality of the target, causing 24 to 26 Arcane damage and an additional 33 to 37 Arcane damage over 10 sec.
Loot: Slitherwrap Girdle [item=273041], Manascale Treads [item=273042], Spine of the Devourer [item=273040]

#### Fel Ancient (NPC ids [246003])
Overview: Fel Ancient has two mechanics that are quite unforgiving. Entangle will occasionally root 2 targets and deal damage over time. This is not a big deal on its own, but when combined with his other mechanic, Fel Timbers, it can be quite deadly. Fel Timbers leaves a green pool on the ground that deals damage to anyone standing in it. If Entangle and Fel Timbers overlap, make sure to use effects like [spell=1044] or [spell=20589] to clear it. [i]Note: Fel Ancient can be accessed without killing previous bosses.[/i]
- Fel Timbers [spell=1240692]: The Fel Ancient sends noxious vines toward an enemy, inflicting 24 to 26 Nature damage to enemies within 5 yds and creating poisonous fumes at the location that deal 10 to 11 Nature damage every 1 sec for 10 sec. | note: Move out of the green pools that spawn as quickly as possible.
- Entangle [spell=1240688]: Entangles nearby enemies in roots, inflicting Nature damage every 3 sec. and immobilizing them for up to 6 sec. | note: Removing this is a high priority if the player is in the green pool created by Fel Timbers.
- Trample [spell=1240687]: Inflicts normal damage plus 15 to nearby enemies.
Loot: Garb of Fallen Felbark [item=273038], Blightleaf Rope [item=273039], Felbough Arm [item=273037]

#### Lyn the Ignored (NPC ids [247032])
Overview: Lyn the Ignored is a secret boss hiding away in the sewers. After summoning him, you'll have to deal with a surprisingly punishing encounter. Shadow Bolt Volley will be cast periodically and deals a surprising amount of shadow damage. On its own, it's not too difficult to handle, but when combined with damage from Curse of Thorns, things can get scary. This ability gives your attacks a chance to cause damage to yourself, which is bad news for melee classes, particularly Rogues. This is a curse, so make sure to dispel it if possible. The boss will also cast Raise Dead, which summons two non-elite skeletons, similar to Atrexis the Grave Knight.
Role notes: damage: Prioritize killing the summoned skeletons.
- Curse of Thorns [spell=1304473]: Curses an enemy for 3 min, giving it 50% chance to take 19 to 41 damage on attack. | note: Dispel this curse if you can, especially if it is cast on a melee class.
- Raise Dead [spell=1303266]: 
Loot: Cartilage Shapers [item=273054], Bonepile Gaze [item=273055], Tendonscraper Dagger [item=273053]

#### Shade of the Archmage (NPC ids [246020])
Overview: Shade of the Archmage is the final boss of the dungeon. The Archmage uses his mana pool to use his abilities, and once that mana pool is drained, he will use Mass Polymorph and Evocation to regenerate his mana to full. His primary damage ability on the tank is Arcane Bolt, which deals high steady damage. He'll also periodically use Arcane Explosion, which deals moderate damage to anyone within 20 yards. Occasionally, the Archmage will cast Bounding Mana, which deals high damage to anyone hit. This will target one individual player with an arcane boomerang projectile, and anyone standing in the projectile will take damage. Stay spread out to avoid spreading the damage from Bounding Mana, and casters stay at max range to avoid taking damage from Arcane Explosion. Casters who are looking to squeeze a bit more damage or healing out of the fight can hide behind the wall whenever the boss casts Mass Polymorph, but be careful, as if the boss leaves his room, he will fully reset.
- Bounding Mana [spell=1241515]: Launches a mana infused orb toward a random player that travels out and returns to its origin. Players hit are inflicted with 285 to 315 Arcane damage. | note: Stay spread out to reduce the damage this deals.
- Mass Polymorph [spell=1303598]: Transforms nearby enemies into an animal, forcing it to wander around for up to 8 sec. While wandering, they cannot attack or cast spells. | note: When low on mana, the boss will polymorph the whole group and cast Evocation. Casters can hide behind the wall when he casts this, but be careful, as if the boss leaves his room, he will fully reset.
- Arcane Explosion [spell=1304398]: Sends out a blast wave of magic, inflicting 9 to 11 Arcane damage to nearby enemies. | note: The healer and ranged should keep their distance to avoid taking damage from this.
- Arcane Bolt [spell=1241506]: Inflicts 15 to 19 Arcane damage to an enemy.
- Slow [spell=1303350]: Increases the time between nearby enemies' attacks by 30% and slows their movement and casting speed by 70% for 3 sec.
- Evocation [spell=1303599]: While channeling this spell, your mana regenerates at an accelerated rate.
Loot: Arcane Mote [item=251961], Violet Sorcerer's Mantle [item=273051], Ponderous Orb [item=273052], Archmagister's Faceted Pendant [item=273049], Blueprint: Arcane Salvager [item=273103]

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Atrexis the Grave Knight: npcs[Atrexis the Grave Knight new] spells[Unholy Frenzy new; Raise Dead new] newSpells[1303266, 1303264] loot[Bonebinder's Signet new; Gravespike Repeater new; Graveweave Bindings new]
- Arcane Anomaly: npcs[Arcane Anomaly new] spells[Arcane Bolt new; Focal Blast new] newSpells[1240682, 1241501] loot[Runemender's Seal new; Ephemeral Grips new; Mana-Warped Chain Shirt new]
- Arcanic Enigma: npcs[Arcanic Enigma new] spells[Manamorph new; Summon Manaling new] newSpells[1240869, 1304455] loot[Wand of Mana Concentration new; Violet Sorcerer's Robes new; Drape of Shifting Energy new]
- Unstable Sentinel: npcs[Unstable Sentinel new] spells[Arcane Explosion new; Malfunction new] newSpells[1241329, 1241325] loot[Guardian's Dualblade new; Unstable Crystalline Shoulderpads new; Refractory Scaleguards new; Blueprint: Spinning Wheel new]
- Mana Devourer: npcs[Mana Devourer new] spells[Drain Vitality new; Debilitate new] newSpells[1240750, 1240738] loot[Spine of the Devourer new; Slitherwrap Girdle new; Manascale Treads new]
- Fel Ancient: npcs[Fel Ancient new] spells[Trample new; Entangle new; Fel Timbers new] newSpells[1240692, 1240688, 1240687] loot[Felbough Arm new; Garb of Fallen Felbark new; Blightleaf Rope new]
- Lyn the Ignored: npcs[Lyn the Ignored new] spells[Raise Dead new; Curse of Thorns new] newSpells[1304473, 1303266] loot[Tendonscraper Dagger new; Cartilage Shapers new; Bonepile Gaze new]
- Shade of the Archmage: npcs[Shade of the Archmage new] spells[Arcane Bolt new; Bounding Mana new; Slow new; Mass Polymorph new; Evocation new; Arcane Explosion new] newSpells[1241515, 1303598, 1304398, 1241506, 1303350, 1303599] loot[Arcane Mote new; Archmagister's Faceted Pendant new; Violet Sorcerer's Mantle new; Ponderous Orb new; Blueprint: Arcane Salvager new]


## Guide text
Source: https://www.wowhead.com/forever/guide=34964

City of Dalaran [zone=16560] is located in the Alterac Mountains, Eastern Kingdoms. This guide provides tips and strategies for completing the City of Dalaran, including everything you need before and during the dungeon, quests to complete inside, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## City of Dalaran Overview in World of Warcraft: Forever

The City of Dalaran features us clearing out the threats that have overrun the beloved city of mages after the Magic barrier surrounding the city was cleared. Dalaran was one of the original cities in Azeroth and was ruled by the Kirin Tor, a council of wizards who housed some of the most impressive libraries and research facilities in all of Azeroth within the Dalaran walls. 

During the Third War, Arthas, the Prince who succumbed to the influence of Ner'zhul, laid siege to the city and killed many of its citizens and leaders. Kel'Thuzad then summoned Archimonde, a leader of the Burning Legion, who destroyed the city. Surviving wizards have since been rebuilding the city, and the reconstruction is finally done, and we now get to see Dalaran in its full glory for the first time in Classic World of Warcraft.

The recommended level for City of Dalaran is between 28 and 34. In-game players usually refer to City of Dalaran as "CoD."

## Unlocking the City of Dalaran in World of Warcraft: Forever

Horde players will need to complete a short quest chain to gain access to the City of Dalaran Dungeon, while Alliance players can just arrive at the sewer entrance and ask Image of Archmage Modera [npc=269127] for a key.

The questline begins in Tarren Mill, Hillsbrad Foothills [zone=267], and takes you to the outskirts of Dalaran to clear out patrols and traitors while searching for the key to the sewer systems. This is not technically an "attunement," as only one person needs to open the gate for other people to enter. This could be someone in your party or a friendly gatekeeper with some time to spare. But if you want to get a key of your own, you can find a complete step-by-step below. 

### Initial Quests to Accept

Quest | 
Start | 
Description | 

Prison Break In [quest=544] | 
Magus Wordeen Voidglare [npc=2410], Tarren Mill | 
Find the traitors and recover their artifacts, then return to Magus Voidglare in Tarren Mill. | 

Key to the City [quest=93680] | 
Magus Wordeen Voidglare [npc=2410], Tarren Mill | 
Acquire the Grimy Key for Magus Wordeen Voidglare. | 

### Hand in and accept next quests

Quest | 
Start | 
Description | 

Dalaran Patrols [quest=545] | 
Magus Wordeen Voidglare [npc=2410], Tarren Mill | 
Kill 6 Dalaran Summoners and 12 Elemental Slaves, then return to Magus Voidglare in Tarren Mill. | 

### Hand in and accept next quest

Quest | 
Start | 
Description | 

Blood in the Streets [quest=92434] | 
Magus Wordeen Voidglare [npc=2410] Tarren Mill | 
Hand this quest in to Image of Archmage Modera [npc=269127] outside Dalaran  | 

Heart of Disruption [quest=96984] | 
Image of Archmage Modera [npc=269127], Outside Dalaran | 
Enter the City of Dalaran and collect the Arcane Mote. Provides Dalaran Sewer Key [item=277507], allowing entry into the city. | 

You will end this series of quests with Heart of Disruption [quest=96984] in your quest log and the Dalaran Sewer Key [item=277507] in your keyring, ready for the City of Dalaran dungeon to become available.

## Location of City of Dalaran in World of Warcraft: Forever

City of Dalaran is located in Alterac Mountains [zone=36] and is a new installment in WoW: Forever. In previous Classic iterations, Dalaran was encased in a violet magical energy dome as the city was reconstructed following its destruction by Archimonde.

Entrance to City of Dalaran

Alliance players can access the dungeon through the sewers in Dalaran. The first time you visit the city, you will have to run from Hillsbrad Foothills to get to the city, which is a bit of a hike. 

Horde players have to enter through a special tunnel where the Image of Archmage Modera [npc=269127] grants us special access to help defend the city. To unlock the gate, at least one player needs to have access to Dalaran Sewer Key [item=277507]. You can easily reach the dungeon by swimming from Silverpine Forest [zone=130]. Once you land in The Sepulcher, it only takes a few minutes to reach the dungeon on foot. 

As with many World of Warcraft: Forever Dungeons, wiping (the entire group dying) in City of Dalaran can be a frustrating time due to the long run-back. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests, Druids, and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it.

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer (marked on the map below) as a ghost. You collect your body when you enter the instance.

## Every Quest in City of Dalaran in World of Warcraft: Forever

Hard: Level 26 | Medium: Level 29 | At Level: Level 31 | Easy: Level 34

Quest | Level | Side | Effort | Share? | Starts | 

The Grave Knight [quest=96986] | 24 |  |  |  |  Tarren Mill - Melisara [npc=2278] /way 62 21 | 

Source of Power [quest=96988] | 24 |  |  |  | Undercity, Apothecarium - Doctor Martin Felben [npc=11044] /way 46 74. | 

Opportunistic Education [quest=96987] | 24 |  |  |  | Inside Dungeon - Rexxie Copperclutch [npc=268743] on entry. | 

Heart of Disruption [quest=96984] | 24 |  |  | Pre | Starts with Prison Break In [quest=544] from Magus Wordeen Voidglare [npc=2410] in Hillsbrad Foothills /way 62 21.  | 

Power Overwhelming [quest=92489] | 24 |  |  |  | Stormwind, Magic Quarter - High Sorcerer Andromath [npc=5694] /way 49 88. | 

Heart of Disruption [quest=92458] | 30 |  |  | Pre | Starts with An Alarming Request [quest=92432] from Emissary Jacques [npc=247264] in Southshore /way 48 60. | 

A Green Sample [quest=92456] | 24 |  |  |  | Stormwind, The Park - Shylamiir [npc=5502] /way 32 63  | 

Starving Arcane [quest=92457] | 30 |  |  | Pre | Starts with An Alarming Request [quest=92432] from Emissary Jacques [npc=247264] in Southshore /way 48 60. | 

## Noteworthy City of Dalaran Trash Mobs in World of Warcraft: Forever

There is not a great deal of trash worth mentioning, but there are a few things to keep in mind: Mana Phantom [npc=269475]s have quite nasty Mana Burn [spell=20817] ability that should be interrupted. These mobs are non-elite and should be focused down. Speaking of mana, Saturated Remnant [npc=247001], once defeated, will leave behind an area that restores mana to whoever is inside it. Make sure to make use of that field. 

Almost every mob in this dungeon is immune to Arcane damage, so keep that in mind if you normally use spells like Arcane Explosion [spell=1449] or Arcane Shot [spell=3044] to deal damage, or Counterspell [spell=2139] to interrupt. 

## City of Dalaran Bosses in World of Warcraft: Forever

Step 1: Obtain the Black Tome in Shadowfang Keep

Enter Shadowfang Keep [zone=209] and clear your way to Archmage Arugal [npc=4275]. After defeating him, you'll be able to interact with a book on his table, which will grant you Black Tome [item=276561]. 

Step 2: Travel to Ambermill

Exit Shadowfang Keep and run over to the Dalaran-controlled town of Ambermill in Silverpine Forest [zone=130]. In the keep, you will find the Ambermill Leyline Focus, and if you interact with Black Tome [item=276561] while you're next to it, it will turn the Black Tome into Tome of Dalaran [item=275989]

Entrance to City of Dalaran

Step 3: Enter the City of Dalaran

At this point, you have all you need to summon Lyn the Ignored [npc=247032]. Clear the first boss Atrexis the Grave Knight [npc=247126], then continue through the sewer. Instead of heading right to get to the surface, continue straight forward into the tunnel leading to a purple rune on the ground. Interact with Tome of Dalaran [item=275989], and Lyn will appear after a short RP entrance with a nod to Ragnaros [npc=11502]. Too soon, you have awakened him too soon. 

Strategy
You will encounter Atrexis the Grave Knight [npc=247126] very early in the dungeon, and as a consequence, he's a very easy tank-and-spank style boss. His primary mechanic is summoning Skeletons, non-elite mobs, that need to be killed. They don't have any time-sensitive mechanics, and the only way you die during this encounter is if you use heavy AOE before the tank has established threat, so be careful. 

This boss is essentially designed to test the strength of your tank with abilities like Unholy Frenzy [spell=1303264], Thrash [spell=3391], and Strike [spell=12057]. Make sure to put on a shield for this encounter. The boss will also periodically use Disarm [spell=6713] on the tank.

Abilities | 

 Disarm [spell=6713] Raise Dead [spell=1303266] Unholy Frenzy [spell=1303264] Thrash [spell=3391] Strike [spell=12057] | 
 

Strategy
Arcane Anomaly [npc=245999] is one of the bosses you can kill after exiting the sewers and has a core defining mechanic that will kill you if mishandled. Focal Blast [spell=1241501] is an arcane slicer that cuts across the room and rotates counterclockwise. This is a mechanic many raiders will be familiar with if they played WoW before picking up Forever and can be seen in bosses like C'thun, Halion, and Norushen. Make sure to avoid this ability, or you will die. 

Another thing to keep in mind is that the boss spawns small adds at the edge of the room when you engage it, so make sure to stay within the circle on the platform to avoid pulling them into the boss. The boss will periodically cast Arcane Bolt [spell=15230] in addition to its normal melee attacks.

Abilities | 

 Focal Blast [spell=1241501] Arcane Bolt [spell=15230]  | 
 

Strategy
Arcanic Enigma [npc=246016] has 2x Mana Phantom [npc=269475] accompanying him as you begin the fight. These should be burned down quickly, as they have a Mana Burn that is very taxing on whoever is targeted. 

Manamorph [spell=1240869] will occasionally CC a group member for 8 seconds and needs to be dispelled by someone with the ability to dispel Magic. Speaking of dispelling Magic, it may be a good idea for your healer to stand far away from the rest of your group, as the boss will cast an AOE Silence [spell=1224125] on targets close to the boss. 

The boss will continuously spawn small Arcane Manaling [npc=246893] throughout the fight, and they need to be cleaved down. These are not as much of a priority as Mana Phantom [npc=269475], but the boss will not spawn additional Mana Phantoms during the encounter. 

Abilities | 

 Manamorph [spell=1240869] Silence [spell=1224125] Summon Manaling [spell=1304455]  | 
 

Strategy
Unstable Sentinel [npc=246017] has one defining mechanic, and that is Malfunction [spell=1241329]. Malfunction will have a short wind-up before unleashing heavy AOE damage to anyone within 25 yards. Ranged players should stay at max range for the entire fight, and melee players should run out whenever you see the wind-up. Depending on your level and group composition, you could likely stay in as a melee, but being kind to the healer should be the baseline. 

Note: Non-elite enemies called Angry Tome [npc=254856] will spawn from the buildings as you approach the boss. Kill these before engaging the fight to make things a little bit easier. 

Abilities | 

 Malfunction [spell=1241329]  | 
 

Strategy
Mana Devourer [npc=246008] resides by the entrance to Violet Hold and can be deceptively difficult. The boss will periodically cast Debilitate [spell=1240750], which deals damage to everyone within 45 yards and drains 200 mana. 

Additionally, the boss will cast Drain Vitality [spell=1240738] on the current target, dealing arcane damage on impact and over a 10-second duration.

This boss is essentially a rush against time, as the group will sooner or later run out of mana unless you defeat the boss quickly enough. The boss is also immune to arcane spells. 

Note: Make sure to clear out all the trash in the boss area. They will join the fight after engaging the boss if they are still alive.

Abilities | 

 Drain Vitality [spell=1240738] Debilitate [spell=1240750] | 
 

Strategy
Fel Ancient [npc=246003] has two mechanics that are quite unforgiving. Entangle [spell=22994] will occasionally root 2 targets and deal damage over time. This is not a big deal on its own, but when combined with his other mechanic Fel Timbers [spell=1240706], it can be quite deadly. Fel Timbers leaves a green pool on the ground that deals damage to anyone standing in it. If Entangle and Fel Timbers overlap, make sure to use effects like Blessing of Freedom [spell=1044] or Escape Artist [spell=20589] to clear it. 

Note: Fel Ancient [npc=246003] can be accessed without killing previous bosses.

Abilities | 

 Entangle [spell=22994] Fel Timbers [spell=1240706] | 
 

Strategy
Lyn the Ignored [npc=247032] is a secret boss hiding away in the sewers. After summoning him, you'll have to deal with a surprisingly punishing encounter. 

Shadow Bolt Volley [spell=17228] will be cast periodically and deals a surprising amount of shadow damage. On its own, it's not too difficult to handle, but when combined with damage from Curse of Thorns [spell=1304473], things can get scary. This ability gives your attacks a chance to cause damage to yourself, which is bad news for melee classes, particularly Rogues. This is a curse, so make sure to dispel it if possible.

The boss will also cast Raise Dead [spell=1303266], which summons two non-elite skeletons, similar to Atrexis the Grave Knight [npc=247126].

Abilities | 

 Shadow Bolt Volley [spell=17228] Curse of Thorns [spell=1304473] Raise Dead [spell=1303266] | 
 

Strategy
Shade of the Archmage [npc=246020] is the final boss of the dungeon. The Archmage uses his mana pool to use his abilities, and once that mana pool is drained, he will use Mass Polymorph [spell=1303598] and Evocation [spell=1303599] to regenerate his mana to full. 

His primary damage ability on the tank is Arcane Bolt [spell=15230], which deals high steady damage. He'll also periodically use Arcane Explosion [spell=28450], which deals moderate damage to anyone within 20 yards. Occasionally, the Archmage will cast Bounding Mana [spell=1241515], which deals high damage to anyone hit. This will target one individual player with an arcane boomerang projectile, and anyone standing in the projectile will take damage. 

Stay spread out to avoid spreading the damage from Bounding Mana, and casters stay at max range to avoid taking damage from Arcane Explosion. 

Casters who are looking to squeeze a bit more damage or healing out of the fight can hide behind the wall whenever the boss casts Mass Polymorph, but be careful, as if the boss leaves his room, he will fully reset. 

Abilities | 

 Mass Polymorph [spell=1303598] Evocation [spell=1303599] Arcane Bolt [spell=15230] Arcane Explosion [spell=28450] Bounding Mana [spell=1241515]  | 
 

## City of Dalaran Loot in World of Warcraft: Forever

Type | Item | 

 Cloth  |  Graveweave Bindings [item=273036] | 

 Ring  |  Bonebinder's Signet [item=273032]  | 
 
 Crossbow  |  Gravespike Repeater [item=273033]  | 
 

Type | Item | 

 Cloth  |  Ephemeral Grips [item=273034]  | 

 Ring  |  Runemender's Seal [item=273031]  | 

 Mail  |  Mana-Warped Chain Shirt [item=273035]  | 

Type | Item | 

 Cloth  |  Violet Sorcerer's Robes [item=273044]  | 

 Back  |  Drape of Shifting Energy [item=273045]  | 

 Wand  |  Wand of Mana Concentration [item=273043]  | 

Type | Item | 

 Axe  |  Guardian's Dualblade [item=273046]  | 
 
 Leather  |  Unstable Crystalline Shoulderpads [item=273047]  | 
 
 Mail  |  Refractory Scaleguards [item=273048]  | 
 
 Tailoring  |  Blueprint: Spinning Wheel [item=273099]  | 
 

Type | Item | 

 Leather  |  Slitherwrap Girdle [item=273041]  | 
 
 Mail  |  Manascale Treads [item=273042]  | 
 
 Staff  |  Spine of the Devourer [item=273040]  | 
 

Type | Item | 

 Polearm  |  Felbough Arm [item=273037]  | 
 
 Leather  |  Garb of Fallen Felbark [item=273038]  | 

 Cloth  |  Blightleaf Rope [item=273039]  | 

Type | Item | 

 Leather  |  Cartilage Shapers [item=273054]  | 
 
 Shield  |  Bonepile Gaze [item=273055]  | 

 Dagger  |  Tendonscraper Dagger [item=273053]  | 
 

Type | Item | 

 Neck  |  Archmagister's Faceted Pendant [item=273049]  | 
 
 Cloth  |  Violet Sorcerer's Mantle [item=273051]  | 
 
 Off-hand  |  Ponderous Orb [item=273052]  | 
 
 Enchanting  |  Blueprint: Arcane Salvager [item=273103]  |

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/city-of-dalaran und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **Atrexis the Grave Knight** [247126]: Strike (12057)
- **Arcane Anomaly** [245999]: Arcane Bolt (1240682)
- **Unstable Sentinel** [246017]: Arcing Smash (16169), Arcane Explosion (1241325)
- **Fel Ancient** [246003]: Fel Timbers (1240692), Entangle (1240688)
- **Lyn the Ignored** [247032]: Raise Dead (1303266)
- **Shade of the Archmage** [246020]: Arcane Explosion (1304398), Arcane Bolt (1241506), Slow (1303350)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: Opportunistic Education [96987] Stufe 33 (Horde)
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: 96987

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist

## Abilities from other sources

Quelle: Warcraft Tavern City-of-Dalaran-Guide (per Fetch), Suchzusammenfassung Icy Veins/GameSpot/Expcarry (paraphrasiert, keine Spell-IDs). **Forever-Community-Guides, Bossliste je nach Quelle verschieden (8 Bosse, Beta nennt Mana Elemental/Wraith).** URLs: https://www.warcrafttavern.com/forever/guides/city-of-dalaran/, https://www.icy-veins.com/wow-forever/city-of-dalaran-guide

| Boss | Ability | Spell ID | Was es tut | Umgang | Confidence |
|---|---|---|---|---|---|
| Atrexis the Grave Knight | Raise Dead, Disarm, Unholy Frenzy, Thrash, Strike | 12057 (Strike, Wowhead) / unbekannt | Skelette (nicht elite); Tank entwaffnet; Frenzy auf sich/Skelett | Patrouille mit 3 Kirin Tor Necromancers: einige vorher toeten, nicht ueberpullen | mittel |
| Lyn the Ignored (Geheimboss, Tome of Dalaran aus Shadowfang Keep) | Shadow Bolt Volley, Raise Dead, Curse of Thorns | 1303266 (Raise Dead, Wowhead) / unbekannt | Nicht unterbrechbare Volley; Skelette; Fluch auf Tank | Durchheilen, Fluch entfernen, Skelette aufnehmen, weg von Gruppe drehen | mittel |
| Arcane Anomaly | Focal Blast | 1240682 (Arcane Bolt, Wowhead) | Strahl nach vorn, kreist | Hinter dem Boss stapeln und mitkreisen | mittel |
| Mana Devourer | Debilitate, Drain Vitality | unbekannt | Gruppen-Manaentzug; DoT auf Tank | Violet Hold vorher raeumen, Heilercheck | mittel |
| Fel Ancient | Entangle, Fel Timbers | 1240688, 1240692 (Wowhead) | Wurzel auf 2 Zufallsspieler + Void-Zonen | Root-Breaker/Freedom, durchheilen | mittel |
| Arcanic Enigma | Manamorph, AoE Silence; Mana Phantoms (Mana Burn) | unbekannt | Polymorph; Silence | Phantoms zuerst, kicken, Fernkampf auf Abstand | mittel |
| Unstable Sentinel/Sentry | Malfunction | 1241325 (Arcane Explosion, Wowhead) / unbekannt | grosser AoE | Nahkampf (ausser Tank) wegtreten | mittel |
| Shade of the Archmage | Bounding Mana, Mass Polymorph + Evocation | 1241506 / 1304398 / 1303350 (Wowhead: Arcane Bolt/Explosion/Slow) | Abprallendes Projektil; Polymorph der Gruppe | Ausweichen, CC-Break | niedrig-mittel |
