# Ruins of Lordaeron - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=34931 (ruins-of-lordaeron)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/ruins-of-lordaeron


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/ruins-of-lordaeron

Journal: areaId (zone) 16611; level range from journal: None-None; kind dungeon

Journal description: The Ruins of Lordaeron holds remnants of the Scourge from the story of Warcraft III that still haunt the Forsaken in their home of Tirisfal Glades. Players must venture into this scourge-infested territory to push back the Lich King's army away from Lordaeron.

### Journal quests (id, level as shown, side)
- The Wrath of Rath'mael [quest=92422] level 22, Horde
- A Frightened Request [quest=92401] level 22, Horde
- Light's Justice [quest=92421] level 22, Horde
- The New Plague [quest=95216] level 22, Horde
- Unending Torment [quest=97288] level 21, Horde
- Crest of Lordaeron [quest=95204] level 22, Horde
- Abominable Creatures [quest=95250] level 21, Alliance
- Bloodied Insignia [quest=95195] level 22, Alliance
- Remember That I Love You [quest=92415] level 22, Alliance
- Crest of Lordaeron [quest=95189] level 22, Alliance

### Journal bosses

#### Witherfang (NPC ids [250483])
Overview: Witherfang patrols King's Alley and is a simple tank-and-spank fight. They're accompanied by two spider mobs, and those should be taken down asap. Use stuns to make this fight easier and cleanse the Leech Poison debuff off of the tank when applied.
Role notes: tank: Kill the adds first.; healer: Dispel Leech Poison if you can.; damage: Kill the adds first.
- Leech Poison [spell=3358]: Drains 15 health from an enemy every 5 sec. over 40 sec., transferring it to the caster. | note: Deals damage and heals Witherfang; dispel it if you can.
Loot: Highly Toxic Strain [item=275443], Segmented Spider Leg [item=271203], Witherbite Bracers [item=271202], Atrophic Girdle [item=271201]

#### The Baron (NPC ids [250660])
Overview: The Baron is a hard-hitting boss with one main ability, Knockout. This deals high instant damage and has a threat drop in it. If your tank is not at full HP, this ability can kill the tank. Use stuns to keep the boss from casting this.
Role notes: healer: Keep the tank's health high at all times.; damage: Try to save stuns for when the boss casts Knockout.
- Knockout [spell=17307]: Inflicts normal damage plus 300 to an enemy, knocking it back and stunning it for 6 sec. | note: Use stuns to stop the boss from casting this.
Loot: Abominable Head [item=280438], Head of the Baron [item=268518], Leftover Abomination Skin [item=271206], Meathook Slicer [item=271204], Abomination Bones [item=271205]

#### Viktor The Vile (NPC ids [256035])
Overview: Viktor the Vile is found when players activate the fire in the chimney located in the building to the southwest in Lordamere Overlook, by the Lordaeron Graveyard. Players must clear 5 waves of adds before fighting Viktor. He only has powerful melee swings and the same Leech Poison ability as Witherfang, so make sure you let the tank get aggro first
Role notes: healer: Dispel Leech Poison if you can.
- Leech Poison [spell=3358]: Drains 15 health from an enemy every 5 sec. over 40 sec., transferring it to the caster. | note: Deals damage and heals Witherfang; dispel it if you can.
Loot: Vilewalkers [item=271211], Bloodied Chestwraps [item=271212], Vileblood Scimitar [item=271218]

#### The Abandoned (NPC ids [250631])
Overview: The Abandoned will be found as soon as you enter Market Street from Lordamere Overlook. The statue in this area will trigger 3 waves of adds before The Abandoned comes out. He will Frost Nova players, apply a chill effect to those who physically hit him, and cast Drain Life on the tank.
- Chilled [spell=6136]: Movement slowed by 30% and time between attacks increased by 25%. | note: Applied to players who melee the boss.
- Life Drain [spell=1266011]: Drains 50 health, transferring it to the caster.
- Frost Nova [spell=1220855]: Inflicts Frost damage to nearby enemies, immobilizing them for up to 8 sec.
Loot: Rotmender's Leggings [item=271207], Scepter of the Abandoned [item=271216], Grip of Fear [item=271208]

#### Bjork (NPC ids [256097])
Overview: Bjork only has one ability: a very short Anti-Magic Shield . It goes away pretty fast, so this boss is a very quick tank and spank.
- Anti-Magic Shield [spell=1301635]: Creates an anti-magic shell around you granting magic immunity for 3 sec. | note: Grants the boss complete immunity to magic; don't waste mana casting into it.
Loot: Tuskwrap Belt [item=271210], Corpse Chopper [item=271217], Bonerust Leggings [item=271209]

#### Rath'Mael (NPC ids [250657])
Overview: Rath'mael has one ability: Flamestrike. Move out of it as soon as he channels the cast, as it's always cast where the tank was when the cast started. You can also stun him to prevent him from casting it altogether.
Role notes: tank: Stun the boss or move away when they cast Flamestrike.; healer: Keep your distance from the boss.; damage: Stun the boss or move away when they cast Flamestrike. Ranged should keep their distance from the boss.
- Flamestrike [spell=18399]: Calls down a pillar of flame, burning all enemies in a selected area and inflicting additional damage every 2 sec. for 8 sec. | note: This is an AoE damaging ability that lands wherever Rath'mael's target was standing when he started casting.
Loot: Mirror of Rath'mael [item=271213], Coldspire Staff [item=271215], Rotmender's Treads [item=271214], Blueprint: Fermenter [item=273085], Blueprint: Arcane Salvager [item=273103]

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Witherfang: npcs[Witherfang new] spells[] newSpells[] loot[Atrophic Girdle new; Witherbite Bracers new; Segmented Spider Leg new; Highly Toxic Strain new]
- The Baron: npcs[The Baron new] spells[] newSpells[] loot[Head of the Baron new; Meathook Slicer new; Abomination Bones new; Leftover Abomination Skin new; Abominable Head new]
- Viktor The Vile: npcs[Viktor the Vile new] spells[] newSpells[] loot[Vilewalkers new; Bloodied Chestwraps new; Vileblood Scimitar new]
- The Abandoned: npcs[The Abandoned new] spells[Chilled updated: Numbers and wording changed; Life Drain new] newSpells[1266011] loot[Rotmender's Leggings new; Grip of Fear new; Scepter of the Abandoned new]
- Bjork: npcs[Bjork new] spells[Anti-Magic Shield new] newSpells[1301635] loot[Bonerust Leggings new; Tuskwrap Belt new; Corpse Chopper new]
- Rath'Mael: npcs[Rath'mael new] spells[] newSpells[] loot[Mirror of Rath'mael new; Rotmender's Treads new; Coldspire Staff new; Blueprint: Fermenter new; Blueprint: Arcane Salvager new]


## Guide text
Source: https://www.wowhead.com/forever/guide=34931

Ruins of Lordaeron [zone=16611], situated above the Forsaken Capital of the Undercity, deep within Horde territory, is one of the first or second dungeons most players will encounter in World of Warcraft Forever.

If you are new to WoW, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## The Ruins of Lordaeron Overview in WoW Forever

The Ruins of Lordaeron holds remnants of the Scourge from the story of Warcraft III that still haunt the Forsaken in their home of Tirisfal Glades. Players must venture into this scourge-infested territory to push back the Lich King's army away from Lordaeron.

The recommended level for The Ruins of Lordaeron is between 16 and 22, and it has started developing the nickname of "RoL". 

## Location of The Ruins of Lordaeron in WoW Forever

The Ruins of Lordaeron is easy to get into, especially for Horde players. Horde: find the portal above the Undercity, in the non-instanced Ruins of Lordaeron, where they can enter from Tirisfal Glades south of Brill.

Horde  players can simply go to the uninstanced Ruins of Lordaeron above the Undercity to find the dungeon entrance

Entrance to Ruins of Lordaeron

Getting to Ruins of Lordaeron as Alliance will be a bit of a trek. Alliance Skyborne can skip to Step 6 as they have a portal from the Stormwind City Mage Tower to Dalaran.

- Take the boat to Auberdine from Stormwind Harbor 
- Once the boat lands in Auberdine, go to the opposite side of the port to take the boat to Menethil Harbor
- Stay on this Boat until it takes you to Southshore in Hillsbrad Foothills
- Follow the road from Southshore to the Hillsbrad Fields
- Continue North and pass around Dalaran
- Swim North through Lordamere Lake of Silverpine Forest to Tirisfal Glades
- Follow the road to the Ruins of Lordaeron entrance from Tirisfal Glades

Port to Auberdine

Southshore Port
Dalaran

Dalaran
Tirisfal

Dungeon Entrance

As with many World of Warcraft Forever Dungeons, wiping (the entire group dying) in The Ruins of Lordaeron can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Priests, Druids, and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it. 

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer as a ghost. The Ruins of Lordaerons Spirit Healer is located immediately outside the dungeon, so wiping here will not be as frustrating as other dungeons.

## The Ruins of Lordaeron Dungeon Map

While Classic Dungeons do not traditionally have maps, World of Warcraft Cartographer Santiago Reyes has created the map below and given us permission to use it. You can browse Santiago Reyes other work by clicking here.

Map created by Santiago Reyes.

## Every Quest for the Ruins of Lordaeron in WoW Forever

Hard: Level 15 | Medium: Level 17 | At Level: Level 18 | Easy: Level 24

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

The Wrath of Rath'mael [quest=92422] | 15 |   |  | Pre  | Tirisfal Glades - Rear Guard Patrol [quest=99156] Deathguard Linnea [npc=1495] /way 65.6 60.2 | 

A Frightened Request [quest=92401] | 15 |   |  |   | Silverpine Forest, The Sepulcher - Tabitha Heartweaver [npc=250686] /way 44.6 42.8 | 

Light's Justice [quest=92421] | 15 |   |  |   | Undercity, The Apothecarium - Morbin Lightbane [npc=266484] /way 57.8 89.8 | 

The New Plague [quest=95216] | 15 |   |  | Pre  | Silverpine Forest, A Recipe For Death [quest=451] - Apothecary Renferrel [npc=1937] /way 42.8 40.8 | 

Unending Torment [quest=97288] | 16 |   |  | Looted Item  | The Ruins of Lordaeron, King's Alley - The Baron [npc=250660] | 

Secret Quest: Crest of Lordaeron [quest=95204]/Crest of Lordaeron [quest=95189] | 14 | /  |  | Interactable Item  | The Ruins of Lordaeron, Multiple Spawn Points  | 

Abominable Creatures [quest=95250] | 16 |   |  |   | The Ruins of Lordaeron, Dungeon Entrance - Captain Truman [npc=265701]  | 

Bloodied Insignia [quest=95195] | 16 |   |  |   | The Ruins of Lordaeron, Drops from Undead Mobs  | 

Remember That I Love You [quest=92415] | 15 |  |  | Interactable Item  | The Ruins of Lordaeron, Located by Rath'mael [npc=250657]  | 

Completing Dungeon Quests in World of Warcraft Forever is a great way to gain some extra experience and gear. You will, though, find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

There are 6 quests for Horde players and 4 quests for Alliance players for the Ruins of Lordaeron. All Alliance quests are located inside the dungeon; Horde have 4 quests they have to pick up outside the dungeon, and will find 2 inside. 

### The Wrath of Rath'mael [quest=92422]

Starting Location
Tirisfal Glades - Deathguard Kristof [npc=251001] /way 65.2 60.2

What To Do
Kill Rath'mael in the Ruins of Lordaeron for Deathguard Kristof in Brill.

### A Frightened Request [quest=92401]

Starting Location
Silverpine Forest, The Sepulcher - Tabitha Heartweaver [npc=250686] /way 44.6 42.8

What To Do
Investigate the disappearance of Edward Heartweaver in the Ruins of Lordaeron.

You will find him by Rath'mael in Ruins of Lordaeron [zone=16611].

### The New Plague [quest=95216]

Starting Location
Undercity, The Apothecarium - Theodore Griffs [npc=11835] /way 47.0 72.6

What To Do
Loot Highly Toxic Strain [item=275443] from Witherfang [npc=250483] inside Ruins of Lordaeron [zone=16611].

### Light's Justice [quest=92421]

Starting Location
The Ruins of Lordaeron, Located in the Reliquary of Kings in a Vault

What to Do
Collect 25 Intact Limbs [item=268580] within The Ruins of Lordaeron for Morbin Lightbane in the Undercity.

### Crest of Lordaeron [quest=95204]/Crest of Lordaeron [quest=95189]

Starting Location
The Ruins of Lordaeron, Multiple Spawn Points - Crest of Lordaeron [item=268579]

What To Do
Find the Crest of Lordaeron [item=268579] and return it to either Stormwind City or the Undercity

Good to Know
The Crest of Lordaeron can spawn in multiple locations.

- Behind an interactable door near The Baron's boss area
- In a building near Bjork's patrolling pathway
- Along the walls where the Gargoyle mobs are located

### Abominable Creatures [quest=95250]

Starting Location
The Ruins of Lordaeron, Dungeon Entrance - Captain Truman [npc=265701]

What To Do
Collect the Head of the Baron [item=268518] in the Ruins of Lordaeron and bring it back to Captain Truman.

### Bloodied Insignia [quest=95195]

Starting Location
The Ruins of Lordaeron - Undead Mobs

What To Do
Collect 10 Bloodied Insignia [item=268540]s and take them to General Marcus Jonathan in Stormwind City.

### Remember That I Love You [quest=92415]

Starting Location
The Ruins of Lordaeron - Blood-Stained Letter [item=251522]

What To Do
Bring the Blood-Stained Letter [item=251522] to Orphan Matron Nightingale in Stormwind City.

### Best Quest Rewards

Type | Item | Quest | 

One-Hand Mace (Horde Only) |  The Stitcher [item=279874] |   Light's Justice [quest=92421]  | 

Staff |  Gnarled Necromancer's Staff [item=251534] |   The Wrath of Rath'mael [quest=92422]  | 

Ring |  Slain Baron's Signet [item=279867] |   Abominable Creatures [quest=95250] / Unending Torment [quest=97288] | 

Necklace (Alliance Only |  Tarnished Locket [item=279870] |   Remember That I Love You [quest=92415]  | 

## Noteworthy Trash Mobs

### The "Spider Wing"
The intro mobs are not too serious, and these spider mobs, Venom Lurker [npc=250735], Spider [npc=250484], Tarantula [npc=250488], are just grouped in packs and can patrol the area. 

Strategy: These packs are not too challenging in their individual status. The only issue players may have is accidentally pulling patrolling packs and overpulling. Be careful and keep an eye out as you're pulling these mobs, and pull them back.

###  Skeletal Soldiers and Banshees
Skeletal Soldier [npc=250626] are physical undead soldiers that patrol the area near The Baron, along with Shrieking Banshee [npc=250617]s near the area

 | 

Strategy: Banshees can silence, and the soldiers can hit hard in large packs. Use stuns like Hammer of Justice [spell=853] to make these packs easier.

### Flesh Golem
These Flesh Golem [npc=255109]s deal intense damage and have a threat-reducing Knock Away ability. 

 | ]

Strategy: Be careful when you pull them and avoid getting knocked into other packs. They patrol Lordamere Overlook, which has a healthy amount of trash around the area. 

### Ghouls and Ragged Ghouls
These Ghoul [npc=250627]s and Ragged Ghoul [npc=250622]s deal intense damage and come in packs of 3-4. They are in close quarters with other packs as well.

]

Strategy: Be careful when you pull them, as it's very easy to pull multiple packs by accident. They have powerful melee swings, so avoid overpulling, as it can be overwhelming for your tank and healer. 

## Ruins of Lordaeron Bosses in World of Warcraft: Forever

Strategy
Witherfang [npc=250483] patrols King's Alley and is a simple tank-and-spank fight. They're accompanied by two spider mobs, and those should be taken down asap. Use stuns to make this fight easier and cleanse the Leech Poison debuff off of the tank when applied.
Abilities | 

 Leech Poison [spell=3358]  | 
 

Strategy
The Baron [npc=250660] is a hard-hitting boss with one main ability, Knockout. This deals high instant damage and has a threat drop in it. If your tank is not at full HP, this ability can kill the tank. Use stuns to keep the boss from casting this.
Abilities | 

 Knockout [spell=17307]  | 
 

Strategy
Viktor the Vile [npc=256035] is found when players activate the fire in the chimney located in the building to the southwest in Lordamere Overlook by the Lordaeron Graveyard. Players must clear 5 waves of adds before fighting Viktor. He only has powerful melee swings and the same Leech Poison ability as Witherfang, so make sure you let the tank get aggro first 
Abilities | 

 Leech Poison [spell=3358]  | 
 

Strategy
The Abandoned [npc=250631] will be found as soon as you enter Market Street from Lordamere Overlook. The statue in this area will trigger 3 waves of adds before The Abandoned comes out. He will Frost Nova players, apply a chill effect to those who physically hit him, and cast Drain Life on the tank.
Abilities | 

 Frost Nova [spell=1220855] Life Drain [spell=1266011]  | 
 

Strategy
Bjork [npc=256097] only has one ability: a very short Anti-Magic Shield . It goes away pretty fast, so this boss is a very quick tank and spank.
Abilities | 

 Anti-Magic Shield [spell=1301635]  | 
 

Strategy
Rath'mael [npc=250657] has one ability: Flamestrike. Move out of it as soon as he channels the cast, as it's always cast where the tank was when the cast started. You can also stun him to prevent him from casting it altogether.
Abilities | 

 Flamestrike [spell=1279983]  | 
 

## The Ruins of Lordaeron Loot 

Type | Item | Boss | 

Mail Belt |  Atrophic Girdle [item=271201] |   Witherfang  | 

Staff |  Segmented Spider Leg [item=271203] |   Witherfang  | 

Leather Bracers |  Witherbite Bracers [item=271202] |   Witherfang  | 

Type | Item | Boss | 

Dagger |  Meathook Slicer [item=271204] |   The Baron  | 

Mail Chest |  Abomination Bones [item=271205] |   The Baron  | 

Cloth Chest |  Leftover Abomination Skin [item=271206] |   The Baron  | 

Type | Item | Boss | 

One-Hand Sword |  Vileblood Scimitar [item=271218] |   Viktor the Vile | 

leather Chest |  Bloodied Chestwraps [item=271212] |   Viktor the Vile | 

Mail Boots |  Vilewalkers [item=271211] |   Viktor the Vile | 

Type | Item | Boss | 

One-Hand Mace |  Scepter of the Abandoned [item=271216] |   The Abandoned  | 

Mail Gloves |  Grip of Fear [item=271208] |   The Abandonedr  | 

Cloth Legs |  Rotmender's Leggings [item=271207] |   The Abandoned  | 

Type | Item | Boss | 

Two-Hand Axe |  Corpse Chopper [item=271217] |   Bjork  | 

Mail Legs |  Bonerust Leggings [item=271209] |   Bjork  | 

Cloth Belt |  Tuskwrap Belt [item=271210] |   Bjork  | 

Type | Item | Boss | 

Shield |  Mirror of Rath'mael [item=271213] |   Rath'Mael  | 

Staff |  Coldspire Staff [item=271215] |   Rath'Mael  | 

Cloth Boots |  Rotmender's Treads [item=271214] |   Rath'Mael | 

## Video Overview Guide for Ruins of Lordaeron

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/ruins-of-lordaeron und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- keine

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **The Abandoned** [250631]: Chilled (6136)
- **Rath'Mael** [250657]: Flamestrike (18399)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: Abominable Creatures [95250] Stufe 21 (Alliance)
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: 95250

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist

## Abilities from other sources

Quelle: Suchzusammenfassung von method.gg, Icy Veins, Warcraft Tavern, GameSpot, wowforeverinfo.com (paraphrasiert; keine Spell-IDs). **Forever-Community-Guides.** URLs: https://www.method.gg/wow-forever/dungeons/ruins-of-lordaeron, https://www.warcrafttavern.com/forever/guides/the-ruins-of-lordaeron/, https://www.icy-veins.com/wow-forever/ruins-of-lordaeron-guide

| Boss | Ability | Spell ID | Was es tut | Umgang | Confidence |
|---|---|---|---|---|---|
| Witherfang | Leech Poison | unbekannt | Gift auf Tank | Patrouille: freie Stelle pullen, Boss vor Adds | mittel |
| The Baron | Knockout (Seramate: "Knock Away") | unbekannt | Fast halbes Tank-Leben, Rueckstoss, Betaeubung, Aggro-Verlust | Betaeubbar; DPS nach Knockout kurz pausieren; Flur vorher raeumen; Nahkampf hinten | mittel |
| Viktor the Vile (optional) | Leech Poison | unbekannt | harter Nahkampf; 5 Add-Wellen vorher | Tank hochheilen | mittel |
| The Abandoned (optional) | Frost Armor, Drain Life, Frost Nova, Chilled | 6136 (Chilled, Wowhead) | Angreifer verlangsamt; Drain unterbrechbar; Wurzel | Drain stunnen/kicken, Frost Nova vorher stunnen; erscheint nach 3 Add-Wellen | mittel |
| Bjork | Anti-Magic Shield | unbekannt | 3 s zaubeimmun | Caster pausieren | mittel |
| Rath'mael (final) | Flamestrike, AoE-Aura um ihn | 18399 (Wowhead) | Feuerzone; Schaden auf Nahkaempfer | Flamestrike kicken/stunnen (Seramate: nur ausweichen), Aura durchheilen | mittel |
| Lordaeron Captain (Horde-Rare) | - | - | erscheint im Westen nach allen 6 Bossen | - | niedrig |

Trash: Skeletal Mages Frost Armor (dispellen), Wailing Banshee Fluch (Trefferchance), Stone Watcher Stone Slumber (physisch immun, regeneriert).
