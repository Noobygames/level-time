# The Hall of Thanes - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=34887 (hall-of-thanes)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/the-hall-of-thanes


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/the-hall-of-thanes

Journal: areaId (zone) 16919; level range from journal: None-None; kind dungeon

Journal description: Hidden beneath the High Seat of Ironforge, the Hall of Thanes is part of the legendary "Old Ironforge", forever incapable of access in Classic Azeroth until WoW: Forever. The Hall of Thanes is the resting place of the Legendary Dwarves of the Eastern Kingdoms, but has recently been invaded by the hostile Dark Iron Dwarves

### Journal quests (id, level as shown, side)
- An Ancient Grudge [quest=96395] level 15, 0
- The Restless Dead [quest=96394] level 15, Alliance
- Important Heirlooms [quest=96403] level 15, Alliance
- Old Ironforge Incursion [quest=96393] level 16, Alliance
- The Treaty of Understanding [quest=98423] level 16, Alliance

### Journal bosses

#### Faldrim Anvilmar (NPC ids [261306])
Overview: Faldrim Anvilmar patrols the center of Anvilmar's Rest and is a simple tank-and-spank fight. The main concern from this is accidentally pulling the boss with any trash should it patrol too close to your party. Clear out a section of the room, wait for him to patrol to your side, then pull. He will auto-attack and cast Mind Blast, and will apply a 10-minute Curse of Anvilmar to the tank.
Role notes: tank: Clear out a section of the room, wait for him to patrol to your side, then pull.
- Anvilmar's Curse [spell=1292602]: Anvilmar causes the target's skin to become like stone, reducing attack speed and casting speed by 20% but also making them immune to Poison and Bleed effects for 10 min. | note: Although Anvilmar's Curse makes the target immune to Poison and Bleed, it reduces attack speed and casting speed, so it should usually be dispelled if possible.
- Mind Blast [spell=13860]: Inflicts Shadow damage to an enemy, but causes a high amount of threat. | note: Mind Blast casts will cause small spikes of damage.
Loot: Spiritwraith Drape [item=271097], Ephemeral Choker [item=270227], Aetherwisp Bracers [item=271096]

#### Magmatus (NPC ids [261316])
Overview: Magmatus is accompanied by a Dark Iron Summoner and has a couple of abilities that really put a focus on healing. On pull, the tank should pull the boss away from the rest of the party, focusing down the Summoner, as the boss will cast a Fire Nova-like ability every so often. After the Summoner is taken down, focus the boss down. Magmatus will also cast Combust on a random player
Role notes: tank: On pull, take the boss away from the rest of the party.; healer: Magmatus will cast Combust on random players; this is a dispellable magic DoT.; damage: Kill the Dark Iron Summoner first.
- Combust [spell=1293228]: Magmatus ignites the target, inflicting 20 Fire damage and additional Fire damage every 2 sec for 12 sec.
- Fire Nova [spell=11970]: Inflicts Fire damage to nearby enemies. | note: Try to outrange the Fire Nova to avoid damage.
Loot: Kindlegem Girdle [item=270230], Fang of Magmatus [item=271095], Flamefist Grips [item=270231]

#### Plunder (NPC ids [261311])
Overview: Plunder patrols his hallway and only has one ability: a Knockback. All you need to do is pull this boss into a safe area where you won't get knocked into any other mobs. Have everyone positioned against a wall or corner to add additional mitigation to this mechanic.
Role notes: tank: Pull to a safe area where you won't get knocked into other mobs.; healer: Try to position yourself with your back to a wall or corner.; damage: Try to position yourself with your back to a wall or corner.
- Knock Away [spell=11130]: Inflicts normal damage plus 30 to nearby enemies and knocks them back. | note: Knocks his target back; avoid having ledges or other mobs positioned behind you.
Loot: Treads of the Protector Golem [item=270229], Golemheart Stave [item=270228], Golemguard Chest [item=271098]

#### Durgen Dirgehammer (NPC ids [261319])
Overview: Durgen Dirgehammer is the final encounter here. This boss is accompanied by two Lesser Stone Golems, with Dark Iron Looters around the edge of the room. Before starting this encounter, take out all the looters, as the boss has an AoE Fear and a Rend. This is heavy damage on your tank, so take out each golem one by one and use stuns and fears to mitigate damage.
Role notes: tank: Clear the room before pulling the boss.; healer: There is heavy damage to start, which will reduce as your team kills the adds.; damage: Kill the golems first.
- Rend [spell=11977]: Inflicts Physical damage to an enemy every 3 sec. for 15 sec.
- Intimidating Shout [spell=19134]: Shouts at an enemy, paralyzing it with terror for 8 sec. and causing all other nearby enemies to flee in fear. | note: Fears nearby players; ranged should stay away from the boss.
Loot: Durgen Dirgehammer's Head [item=274286], Durgen's Crescent Axe [item=270256], Direhammer Leggings [item=270260], Robes of the Disgraced Thane [item=270261]

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Faldrim Anvilmar: npcs[Faldrim Anvilmar new] spells[Anvilmar's Curse new] newSpells[1292602] loot[Ephemeral Choker new; Aetherwisp Bracers new; Spiritwraith Drape new]
- Magmatus: npcs[Magmatus new] spells[Combust new] newSpells[1293228] loot[Kindlegem Girdle new; Flamefist Grips new; Fang of Magmatus new]
- Plunder: npcs[Plunder new] spells[] newSpells[] loot[Golemheart Stave new; Treads of the Protector Golem new; Golemguard Chest new]
- Durgen Dirgehammer: npcs[Durgen Dirgehammer new] spells[] newSpells[] loot[Durgen's Crescent Axe new; Direhammer Leggings new; Robes of the Disgraced Thane new; Durgen Dirgehammer's Head new]


## Guide text
Source: https://www.wowhead.com/forever/guide=34887

The Hall of Thanes [zone=16919], situated under the High Seat of Ironforge, deep within Alliance territory, is one of the first dungeons most players will encounter in World of Warcraft Forever.

If you are new to WoW, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## The Hall of Thanes Overview in WoW Forever

Hidden beneath the High Seat of Ironforge, the Hall of Thanes is part of the legendary "Old Ironforge", forever incapable of access in Classic Azeroth until WoW: Forever. The Hall of Thanes is the resting place of the Legendary Dwarves of the Eastern Kingdoms, but has recently been invaded by the hostile Dark Iron Dwarves

The recommended level for The Hall of Thanes is between 13 and 18, and it has started developing the nickname of "HoT". 

## Location of The Hall of Thanes in WoW Forever

The Hall of Thanes is easy to get into. Players can find the open door to Old Ironforge immediately to the left after entering the High Seat of Ironforge. Players will follow the path all the way to the bottom of Old Ironforge to find the portal

High Seat of Ironforge

Click the image to expand

Currently, Horde will have a long travel time to get here, as so far, there is no quick travel for the opposing faction of this dungeon to get here, and none have been discovered yet in-game. Horde will have to travel from Tarren Mill in Hillsbrad, venture through Arathi Highlands, Wetlands, and Loch Modan before arriving in Dun Morogh to make their way into the Dwarven capital of Ironforge. Horde players should probably remove their gear before getting close, as they'll more than likely meet their demise at the hands of the Ironforge guards several times before being able to zone in (for new players, removing gear prevents it from taking durability loss when you die).

As with many World of Warcraft Forever Dungeons, wiping (the entire group dying) in The Hall of Thanes can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests, Druids, and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. 

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer (marked on the map below) as a ghost. You collect your body when you enter the instance. Luckily, the Spirit Healer is not that far, as it's only located right outside the city.

## The Hall of Thanes Dungeon Map

While Classic Dungeons do not traditionally have maps, World of Warcraft Cartographer Santiago Reyes has created the map below and given us permission to use it. You can browse Santiago Reyes other work by clicking here.

Map created by Santiago Reyes.

## Every Quest for the Hall of Thanes in WoW Forever

Hard: Level 11 | Medium: Level 13 | At Level: Level 14 | Easy: Level 19

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

Important Heirlooms [quest=96403] | 10 | /  |  |   | Ironforge, Old Ironforge - Thom Filch [npc=265003] /way 32.6 44.6 | 

The Restless Dead [quest=96394] | 10 |   |  |   | Ironforge, Old Ironforge - Afadra Dunwall [npc=264943] /way 64.8 58.4 | 

Old Ironforge Incursion [quest=96393] | 9 |   |  |   | Dun Morogh, Gol'Golar Quarry - Earthseer Farsen [npc=264936] /way 64.8 58.4
Prerequisite to pick up Underground Map [quest=96391] from Dark Iron Map [item=274268] | 

The Treaty of Understanding [quest=98423] | 9 |   |  | Interactable Item  | The Hall of Thanes, Located in the Reliquary of Kings in a Vault | 

An Ancient Grudge [quest=96395] | 10 | /  |  |   | The Hall of Thanes, Anvilmar's Rest - Ghostly Attendant [npc=265002]  | 

Completing Dungeon Quests in World of Warcraft Forever is a great way to gain some extra experience and gear. You will, though, find that you need to do a bit of running around to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

 All Hall of Thanes quests are Alliance-exclusive with the exception of An Ancient Grudge and Important Heirlooms. The quests below include where to collect them, any prerequisites you need to complete first, and what you need to do inside or around The Hall of Thanes.

### Important Heirlooms [quest=96403]

Starting Location
Ironforge, Old Ironforge - Thom Filch [npc=265003] /way 32.6 44.6

What To Do
Collect 8 Dwarven Heirloom [item=274289] from the dungeon. You'll start seeing them after the first boss, but don't worry about supply; the vaults in the final room, Reliquary of Kings, have enough for all 5 members of the party to complete their quests.

### The Restless Dead [quest=96394]

Starting Location
Ironforge, Old Ironforge - Afadra Dunwall [npc=264943] /way 64.8 58.4

What To Do
Kill 15 Enraged Apparition [npc=263389]s and 10 Tormented Soul [npc=263390]s

You will find these mobs in the first 3 rooms of the dungeon.

### Old Ironforge Incursion [quest=96393]

Starting Location
Dun Morogh, Gol'Golar Quarry - Earthseer Farsen [npc=264936] /way 64.8 58.4
Prerequisite to pick up Underground Map [quest=96391] from Dark Iron Map [item=274268]

What To Do
Loot Durgen Dirgehammer's Head [item=274286] from Durgen Dirgehammer [npc=261319] inside The Hall of Thanes [zone=16919].

### The Treaty of Understanding [quest=98423]

Starting Location
The Hall of Thanes, Located in the Reliquary of Kings in a Vault

Good To Know
This quest item, Treaty of Understanding [item=281030] is located in one of the vaults in the final room, the Reliquary of Kings.

### An Ancient Grudge [quest=96395]

Starting Location
The Hall of Thanes, Anvilmar's Rest - Ghostly Attendant [npc=265002]

What To Do
Defeat Faldrim Anvilmar [npc=261306]

### Best Quest Rewards

Type | Item | Quest | 

Two-Hand Mace |  Ironforge Greathammer [item=279895] |   Old Ironforge Incursion [quest=96393]  | 

Wand |  Deepblaze [item=279896] |   Old Ironforge Incursion [quest=96393]  | 

Off-Hand |  Dwarven Tome [item=279898] |   Important Heirlooms [quest=96403]  | 

Cloak |  Catacomb Cloak [item=279899] |   An Ancient Grudge [quest=96395]  | 

## Noteworthy Trash Mobs

### Dark Iron Looter and Dark Iron Engineer
The intro mobs are not too serious, and the trash only gets challenging once you get to the Dark Iron side. The Dark Iron Looter [npc=263396]s deal rapid auto attacks with their daggers, and pulling too many at once can really drain your tank's health fast! The Dark Iron Engineer [npc=263397] will throw bombs at their target location.

Strategy: It is not too hard to take these mobs down; we just recommend not pulling too many at once, especially at lower levels since you are missing most of your toolkits at this level. You can dodge the Dark Iron Engineer [npc=263397]s bombs as they pick a location once they start the throw, so their bomb damage is 100% avoidable. With that being said, you should focus down the looters as their damage is rapid and can be deadly the more you pull.

### Dark Iron Summoner and Fiery Assistant
Dark Iron Summoner [npc=263438] is a caster-type mob that casts Fireballs and will summon a Summon Fiery Assistant [spell=1291218]

 | 

Strategy: Use any sort of pillar or wall to be out of line of sight of the Summoner, preventing them from casting and making them run towards the party. 

### Lesser Stone Golem
These Lesser Stone Golem [npc=263466]s deal intense damage and have increased movement speed. 

 | ]

Strategy: If you can, pull one at a time, and when you pull multiple, focus one down, then the other; do not split damage up. The final pack has one Summoner, Looter, and Lesser Stone Golem. We recommend using crowd control like Polymorph [spell=118] to only make two active at the start of the encounter. Take out the Stone Golem first, then the Looter. Use stuns like Hammer of Justice [spell=853] to make this easier as well.

## Bosses

###  Faldrim Anvilmar 

Strategy
Faldrim Anvilmar [npc=261306] patrols the center of Anvilmar's Rest and is a simple tank-and-spank fight. The main concern from this is accidentally pulling the boss with any trash should it patrol too close to your party. Clear out a section of the room, wait for him to patrol to your side, then pull. He will auto-attack and cast Mind Blast, and will apply a 10-minute Curse of Anvilmar to the tank.
Abilities | 

 Mind Blast [spell=26048] Anvilmar's Curse [spell=1292602]  | 
 

### Magmatus

Strategy
Magmatus [npc=261316] is accompanied by a Dark Iron Summoner [npc=263438] and has a couple of abilities that really put a focus on healing. On pull, the tank should pull the boss away from the rest of the party, focusing down the Summoner, as the boss will cast a Fire Nova-like ability every so often. After the Summoner is taken down, focus the boss down. Magmatus will also cast Combust on a random player
Abilities | 

 Combust [spell=1293228]  | 
 

### Plunder

Strategy
Plunder [npc=261311] patrols his hallway and only has one ability: a Knockback. All you need to do is pull this boss into a safe area where you won't get knocked into any other mobs. Have everyone positioned against a wall or corner to add additional mitigation to this mechanic. 
Abilities | 

 Knock Away [spell=10101]  | 
 

### Dirgen Dirgehammer

Strategy
Durgen Dirgehammer [npc=261319] is the final encounter here. This boss is accompanied by two Lesser Stone Golem [npc=263466]s, with Dark Iron Looter [npc=263396]s around the edge of the room. Before starting this encounter, take out all the looters, as the boss has an AoE Fear and a Rend. This is heavy damage on your tank, so take out each golem one by one and use stuns and fears to mitigate damage. 
Abilities | 

 Fear [spell=26070] Rend [spell=12054]  | 
 

## The Hall of Thanes Loot

Type | Item | Boss | 

Cloak |  Spiritwraith Drape [item=271097] |   Faldrim Anvilmar  | 

Necklace |  Ephemeral Choker [item=270227] |   Faldrim Anvilmar  | 

Cloth Bracers |  Aetherwisp Bracers [item=271096] |   Faldrim Anvilmar  | 

Type | Item | Boss | 

Mail Belt |  Kindlegem Girdle [item=270230] |   Magmatus  | 

Leather Gloves |  Flamefist Grips [item=270231] |   Magmatus  | 

Dagger |  Fang of Magmatus [item=271095] |   Magmatus  | 

Type | Item | Boss | 

Staff |  Golemheart Stave [item=270228] |   Plunder | 

Mail Chest |  Golemguard Chest [item=271098] |   Plunder | 

MailBoots |  Treads of the Protector Golem [item=270229] |   Plunder | 

Type | Item | Boss | 

One-Hand Axe |  Durgen's Crescent Axe [item=270256] |   Dirgen Durgehammer  | 

Leather Legs |  Direhammer Leggings [item=270260] |   Dirgen Durgehammer  | 

Cloth Chest |  Robes of the Disgraced Thane [item=270261] |   Dirgen Durgehammer  | 

## Video Overview Guide for The Hall of Thanes

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/the-hall-of-thanes und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **Faldrim Anvilmar** [261306]: Mind Blast (13860)
- **Magmatus** [261316]: Fire Nova (11970)
- **Plunder** [261311]: Knock Away (11130)
- **Durgen Dirgehammer** [261319]: Rend (11977), Intimidating Shout (19134)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: keine

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist

## Abilities from other sources

Quelle: Zusammenfassung von Icy Veins/Mobalytics (Icy Veins per Fetch 403, nur Suchzusammenfassung). Keine Spell-IDs. **Forever-Community-Guides.** URLs: https://www.icy-veins.com/wow-forever/hall-of-thanes-guide, https://mobalytics.gg/wow-forever/dungeons/the-hall-of-thanes-dungeon-guide

| Boss | Ability | Spell ID | Was es tut | Umgang | Confidence |
|---|---|---|---|---|---|
| Faldrim Anvilmar | Mind Blast; Anvilmar's Curse | 13860 (Wowhead) / unbekannt | Schatten; Angriffstempo-Debuff auf Haupttank (Fluch) | Mind Blast kicken, Curse entfernen; vor Pull halben Raum raeumen | mittel |
| Magmatus | Fire Nova; Combustion | 11970 (Wowhead) / unbekannt | AoE; Feuer-DoT auf Zufallsspieler | Tank zieht ihn von der Gruppe weg; Dark Iron Summoner zuerst | mittel |
| Plunder | Knock Away | 11130 (Wowhead) | Rueckstoss | Patrouille: in vorigen Raum ziehen | mittel |
| Durgen Dirgehammer | Rend, Intimidating Shout (AoE-Furcht) | 11977, 19134 (Wowhead) | Blutung; Furcht | 2 Lesser Stone Golems zuerst | mittel |
