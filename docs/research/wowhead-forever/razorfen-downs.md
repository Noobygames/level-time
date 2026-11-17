# Razorfen Downs - Wowhead WoW Forever research

Raw findings (fetched 2026-11-17). Sources:
- Guide: https://www.wowhead.com/forever/guide=34945 (razorfen-downs)
- Dungeon journal: https://www.wowhead.com/forever/dungeon-journal/razorfen-downs


Note: text below is our extraction of Wowhead page data (HTML converted to text; [npc=ID]/[spell=ID]/[quest=ID]/[item=ID] added from page links). Statements are Wowhead claims; unclear points are marked unverified.

## Dungeon journal data
Source: https://www.wowhead.com/forever/dungeon-journal/razorfen-downs

Journal: areaId (zone) 722; level range from journal: 37-47; kind dungeon

Journal description: Crafted from the same mighty vines as Razorfen Kraul, Razorfen Downs is the traditional capital city of the quillboar race. The sprawling, thorn-ridden labyrinth houses a veritable army of loyal quillboar as well as their high priests - the Death's Head tribe. Recently, however, a looming shadow has fallen over the crude den. Agents of the undead Scourge - led by the lich, Amnennar the Coldbringer - have taken control over the quillboar race and turned the maze of thorns into a bastion of undead might. Now the quillboar fight a desperate battle to reclaim their beloved city before Amnennar spreads his control across the Barrens.

### Journal quests (id, level as shown, side)
- An Unholy Alliance [quest=6521] level 36, Horde
- Bring the End [quest=3341] level 42, Horde
- Bring the Light [quest=3636] level 42, Alliance
- A Host of Evil [quest=6626] level 35, both
- Scourge of the Downs [quest=3523] level 37, both
- Extinguishing the Idol [quest=3525] level 37, both

### Journal bosses

#### Tuten'kash (NPC ids [7355])
Overview: Tuten'kash is summoned through the spider gong event in RFD. Before you engage him, you will first have to clear a few waves of spiders. After each wave is finished, ring the gong again to summon the next wave. The waves are simple and straightforward, as is Tuten'kash. The tank should face him away from the group to avoid unnecessary web spray, but his other abilities are negligible.
Role notes: tank: Face the boss away from your group.
- Curse of Tuten'kash [spell=12255]: Reduces the casting speed of nearby enemies by 15%, and increases the time between their attacks by 18%. Lasts 15 min.
- Web Spray [spell=12252]: Immobilizes enemies in a cone in front of the caster for 10 sec.
- Virulent Poison [spell=12251]: 
Loot: Silky Spider Cape [item=10776], Carapace of Tuten'kash [item=10775], Arachnid Gloves [item=10777]

#### Mordresh Fire Eye (NPC ids [7357])
Overview: Mordresh Fire Eye is a low-armor boss that can be bursted down easily by melee DPS. Before you engage him, make sure to clear all of the skeletons dancing beside the bone pile. The last pack of skeletons will pull the boss, so make sure to AoE them down quickly to prevent a wipe. Interrupt Mordresh's hard-hitting fireball when you can, and this should be an easy win.
- Fire Nova [spell=12470]: Inflicts Fire damage to nearby enemies.
- Fireball [spell=12466]: Inflicts Fire damage to an enemy.
Loot: Deathmage Sash [item=10771], Mordresh's Lifeless Skull [item=10770], Glowing Eye of Mordresh [item=10769]

#### Glutton (NPC ids [8567])
Overview: Glutton is a simple tank-and-spank. Make sure to stay out of his Disease Clouds and be prepared to heal the tank through significant amounts of damage when the boss casts Enrage.
- Disease Cloud [spell=12627]: A cloud of noxious gas inflicts 105 Nature damage every 3 sec to players within 5 yards. | note: Move out of these clouds as quickly as possible.
- Enrage [spell=12795]: 
Loot: Glutton's Cleaver [item=10772], Fleshhide Shoulders [item=10774]

#### Amnennar the Coldbringer (NPC ids [7358])
Overview: Amnennar the Coldbringer is a challenging dungeon boss that should be tanked facing the tent where he stands to neutralize Amnennar's Wrath. Have your group stack on the tank to reduce the severity of Frost Nova, and switch to the spirit that he summons as soon as it spawns. Interrupt Frostbolt and prioritize proper positioning.
Role notes: tank: Keep your back to a surface to avoid being knocked back.; damage: Switch to adds whenever they spawn.
- Amnennar's Wrath [spell=13009]: Knocks an enemy back.
- Summon Frost Spectres [spell=12642]: 
- Frost Nova [spell=15531]: Inflicts Frost damage to nearby enemies, immobilizing them for up to 8 sec.
- Frostbolt [spell=15530]: Inflicts Frost damage to an enemy and reduces its movement speed for 4 sec.
Loot: Robes of the Lich [item=10762], Icemetal Barbute [item=10763]

#### Plaguemaw the Rotting Event (NPC ids [7356])
Overview: Plaguemaw the Rotting is the final boss of an optional escort event. When [npc=8516] begins his ritual, focus down mobs that spawn one at a time, preferably with an off-tank pulling adds off Belnistrasz. Plaguemaw is a straightforward tank-and-spank.
- Putrid Stench [spell=12946]: Reduces nearby enemies' Strength by 50 and Agility by 50 for 10 sec., as well as preventing them from casting spells.
- Withered Touch [spell=11442]: Diseases an enemy, inflicting 2 Shadow damage every 10 sec. and draining 2 mana every 10 sec., transferring it to the caster. Lasts 3 min.

#### Ragglesnout (Rare) (NPC ids [7354])
Overview: Ragglesnout's Dominate Mind is by far the most important ability in this encounter. If your tank or healer gets MCed, make sure to have your hybrids fill in where needed. Interrupt his heal to prevent a longer encounter, and interrupt his Shadow Bolts to minimize incoming damage.
- Dominate Mind [spell=7645]: Takes control of a humanoid enemy up to level 25 for 10 sec., but increases the time between its attacks by 100%. | note: If a player gets mind-controlled, CC them.
- Shadow Word: Pain [spell=10892]: A word of darkness that causes 426 Shadow damage over 18 sec.
- Shadow Bolt [spell=11659]: Sends a shadowy bolt at the enemy, causing 140 to 156 Shadow damage.
- Heal [spell=12039]: Calls upon Holy magic to heal an ally.

### Journal changes vs classic (non-unchanged npcs/spells/loot per boss)
- Tuten'kash: npcs[] spells[] newSpells[] loot[Silky Spider Cape updated]
- Mordresh Fire Eye: npcs[] spells[] newSpells[] loot[Glowing Eye of Mordresh updated; Mordresh's Lifeless Skull updated; Deathmage Sash updated]
- Glutton: npcs[] spells[Disease Cloud updated: Numbers and wording changed] newSpells[] loot[Glutton's Cleaver updated]
- Amnennar the Coldbringer: npcs[] spells[] newSpells[] loot[Robes of the Lich updated; Icemetal Barbute updated]
- Ragglesnout (Rare): npcs[] spells[Shadow Word: Pain updated: Value decreased by 16.5%; Shadow Bolt updated: Values decreased by 52.1% and 52.3%] newSpells[] loot[]


## Guide text
Source: https://www.wowhead.com/forever/guide=34945

Razorfen Downs [zone=722] is located in The Barrens. This guide provides tips and strategies for completing Razorfen Downs, including everything you need before and during the dungeon, quests to complete inside, boss strategies, loot, and more.

If you are new to WoW: Forever, please look out for this symbol throughout the guide for additional, beginner-friendly tips.

## Razorfen Downs Overview in World of Warcraft: Forever

Crafted from the same mighty vines as Razorfen Kraul, Razorfen Downs is the traditional capital city of the quillboar race. The sprawling, thorn-ridden labyrinth houses a veritable army of loyal quillboar as well as their high priests - the Death's Head tribe. Recently, however, a looming shadow has fallen over the crude den. Agents of the undead Scourge - led by the lich, Amnennar the Coldbringer - have taken control over the quillboar race and turned the maze of thorns into a bastion of undead might. Now the quillboar fight a desperate battle to reclaim their beloved city before Amnennar spreads his control across the Barrens.

The recommended level for Razorfen Downs is between 37 and 43. In-game players usually refer to Razorfen Downs as "RFD".

## Location of Razorfen Downs in World of Warcraft: Forever

Razorfen Downs is located in The Barrens [zone=17], at the southern border with Thousand Needles.

Entrance to Razorfen Downs
Ratchet
Camp Taurajo

Alliance players can take the boat from Booty Bay to Ratchet. From there, run to the southern part of the Barrens and turn east just before the Great Lift.

Horde players can fly to Camp Taurajo and then head to the southern part of the Barrens, turning east just before the Great Lift.

As with many World of Warcraft: Forever Dungeons, wiping (the entire group dying) in Razorfen Downs can be a frustrating time. 

Ideally, if the entire group is not dead, you should be able to get a rez (resurrection). This is a spell someone casts on you to bring your character back to life with a small amount of health and mana. Druids, Priests, and Shamans learn this early; Paladins need to complete a quest to learn resurrection and may not have it.

If you can't get a rez, click to release your spirit, then run back to the dungeon from the Spirit Healer (marked on the map below) as a ghost. You collect your body when you enter the instance.

## Every Quest in Razorfen Downs in World of Warcraft: Forever

Hard: Level 35| Medium: Level 37 | At Level: Level 39 | Easy: Level 41

### Quick Reference Table

Quest | Level | Side | Effort | Share? | Starts | 

An Unholy Alliance [quest=6521] | 
28 | 
 | 
 | 
Pre | 
Undercity, the Apothecarium - Varimathras [npc=2425] /way 56.6 92.6
Complete An Unholy Alliance [quest=6522] first | 

Bring the End [quest=3341] | 
37 | 
 | 
 | 
 | 
Undercity, the Magic Quarter - Andrew Brownell [npc=2308] /way 74.0 32.8 | 

The Coldbringer's Eye [quest=97196] | 
34 | 
 | 
 | 
 | 
Mulgore, north of Thunder Bluff - Sutara Plainstalker [npc=264078] /way 34.6 22.8 | 

Bring the Light [quest=3636] | 
39 | 
 | 
 | 
 | 
Stormwind City, Cathedral of Light - Archbishop Benedictus [npc=1284] /way 50.3 45.6 | 

The Coldbringer's Eye [quest=96773] | 
34 | 
 | 
 | 
 | 
Alterac Mountains, Dalaran - Archmage Lan'dalock [npc=20735] /way 15.6 73.6 | 

A Host of Evil [quest=6626] | 
28 | 
- | 
 | 
 | 
The Barrens, outside RFD entrance - Myriam Moonsinger [npc=12866] /way 49.0 94.8 | 

Scourge of the Downs [quest=3523] | 
32 | 
- | 
 | 
 | 
Razorfen Downs, cells near Mordresh Fire Eye - Belnistrasz [npc=8516]
Prerequisite for Extinguishing the Idol | 

Extinguishing the Idol [quest=3525] | 
32 | 
- | 
 | 
Esc | 
Once everyone has completed Scourge of the Downs, talk to Belnistrasz again to begin this escort quest | 

Completing Dungeon Quests in World of Warcraft: Forever is a great way to gain some extra experience and gear. You will, though, find that you need to do a bit of running around in order to pick up some dungeon quests. Check the rewards and see if they are worth it for you.

The quests below include where to collect them, any prerequisites you need to complete first, and what you need to do inside or around Razorfen Downs.

Faction: Neutral
Level Required: 32
Reward: Dragonclaw Ring [item=10710]

First, all party members should complete Scourge of the Downs [quest=3523] by simply talking twice to Belnistrasz [npc=8516] in RFD. Extinguishing the Idol [quest=3525] can then be started by talking to him a third time.

The quest requires you to protect Belnistrasz while he performs a ritual to shut down an idol in RFD. 

The quest will be tagged as "Complete" once the ritual is finished. Belnistrasz must stay alive. 

Faction: Neutral
Level Required: 31
Reward: Experience and Silver

A Host of Evil [quest=6626] is a "Kill Quest" that is picked up from Myriam Moonsinger [npc=12866] right outside the instance portal to RFD. 

The quest requires you to kill Death's Head Cultist [npc=7872], Razorfen Battleguard [npc=7873], and Razorfen Thornweaver [npc=7874], which are located throughout RFD. 

The quest will be tagged as "Complete" once all of the required mobs have been killed. 

Faction: Alliance
Level Required: 39
Rewards: Vanquisher's Sword [item=10823] and Amberglow Talisman [item=10824]

Bring the Light [quest=3636] is a single quest that is picked up from Archbishop Benedictus [npc=1284] in the Cathedral of Stormwind. 

The objective of this quest is to kill Amnennar the Coldbringer [npc=7358], the final boss of RFD. 

 | 

The quest will be tagged as "Complete" once Amnennar has been killed. 

Faction: Horde
Level Required: 37
Rewards: Vanquisher's Sword [item=10823] and Amberglow Talisman [item=10824]

Bring the End [quest=3341] is a single quest that can be picked up from Andrew Brownell [npc=2308] in The Undercity.

The quest requires you to loot the Skull of the Coldbringer [item=10420] from Amnennar the Coldbringer [npc=7358] in RFD. 

The quest will be completed once you've looted the skull.

Faction: Horde
Level Required: 28
Rewards (choose one):
Skullbreaker [item=17039]
Nail Spitter [item=17042]
Zealot's Robe [item=17043]

An Unholy Alliance [quest=6521] is a 2-part quest chain that begins by right-clicking the Small Scroll [item=17008] that drops from Charlga Razorflank [npc=4421] in Razorfen Kraul. 

The scroll will require you to speak to Varimathras [npc=2425] in The Undercity, who will give you the next portion of the quest, which requires you to kill Ambassador Malcin [npc=12865] and loot Ambassador Malcin's Head [item=17009] from him. 

The Ambassador is located just outside the instance of RFD and can spawn in several locations. 

The quest will be tagged as "Complete" when you have looted his head. 

Faction: Alliance and Horde
Level Required: 34
Reward: Experience and Silver

The Coldbringer's Eye [quest=96773] and The Coldbringer's Eye [quest=97196] are available to both Alliance and Horde; the only difference between them is the questgiver.

Alliance: Archmage Lan'dalock [npc=20735] /way 15.6 73.6

Horde: Sutara Plainstalker [npc=264078] /way 34.6 22.8

The Coldbringer's Eye [item=276916] is next to the final boss, Amnennar the Coldbringer [npc=7358]. The quest will be tagged as "Complete" when you have looted the eye. 

### Best Quest Rewards

Type | Item | Quest | 

One-Hand Sword |  Vanquisher's Sword [item=10823] |  Bring the Light [quest=3636] / Bring the End [quest=3341] | 

## Noteworthy Razorfen Downs Trash Mobs in World of Warcraft: Forever

### Withered Spearhide and Death's Head Necromancer
The first noteworthy trash mob you'll find in this dungeon is the Withered Spearhide [npc=7332], applying a very powerful Diseased Shot [spell=11397]. Make sure you have a class that can remove this disease, as that is a significant damage reduction to the target. The Death's Head Geomancer [npc=7335] is a powerful caster mob that will cast and Shadow Bolt [spell=9613] and Cripple [spell=11443] on players, while also being able to Summon Skeletal Servant [spell=12420]s.

### Tomb Reaver
Tomb Reaver [npc=7351]s are dangerous in that they will poison players with Virulent Poison [spell=12251] and Web [spell=745] in place for 10 seconds. Make sure to use Line-of-Sight areas to bring them to the party, as you may accidentally be rooted while patrolling mobs come by.

### Freezing Spirit and Skeletal Frostweaver

The Freezing Spirit [npc=7353] is an ethereal mob located throughout RFD that will Frost Nova [spell=15532] players around them. Skeletal Frostweaver [npc=7341]s accompany these mobs and will spam cast Frostbolt [spell=15043] on their primary threat target.

### Skeletal Summoner
Skeletal Summoner [npc=7342]s will Summon Shadowcaster [spell=12258]s to their aide while also casting Lightning Bolt [spell=9532] and Curse of Weakness [spell=11980]. This is the only curse in the dungeon, it's not incredibly threatening so you don't need to bring a Mage or Druid just to have that curse removal here. These mobs are also accompanied by non elite skeletal mobs and Splinterbone Centurion [npc=7346]s. Near the end of the dungeon, you can also find 1-2 Splinterbone Captain [npc=7345]s, who Backhand [spell=8208] their primary threat target, stunning them for 3 seconds.

## Razorfen Downs Bosses in World of Warcraft: Forever

Tuten'kash [npc=7355] is summoned through the spider gong event in RFD. Before you engage him, you will first have to clear a few waves of spiders. After each wave is finished, ring the gong again to summon the next wave. The waves are simple and straightforward, as is Tuten'kash. The tank should face him away from the group to avoid unnecessary web spray, but his other abilities are negligible.
Abilities | 

 Curse of Tuten'kash [spell=12255] Virulent Poison Proc [spell=12254]  | 

 Web Spray [spell=12252]  | 
 

Mordresh Fire Eye [npc=7357] is a low-armor boss that can be bursted down easily by melee DPS. Before you engage him, make sure to clear all of the skeletons dancing beside the bone pile. The last pack of skeletons will pull the boss, so make sure to AoE them down quickly to prevent a wipe. Interrupt Mordresh's hard-hitting fireball when you can, and this should be an easy win.
Abilities | 

 Fire Nova [spell=12470] Fireball [spell=12466]  | 
 

Glutton [npc=8567] is a simple tank and spank. Make sure to stay out of his Disease Clouds and be prepared to heal the tank through significant amounts of damage when the boss casts Enrage.
Abilities | 

 Disease Cloud [spell=12627] Enrage [spell=12795]  | 
 

Ragglesnout [npc=7354]'s Dominate Mind is by far the most important ability in this encounter. If your tank or healer gets MCed, make sure to have your hybrids fill in where needed. Interrupt his heal to prevent a longer encounter, and interrupt his Shadow Bolts to minimize incoming damage.
Abilities | 

 Shadow Word: Pain [spell=10892] Shadow Bolt [spell=11659]  | 

 Heal [spell=12039] Dominate Mind [spell=7645]  | 
 

Amnennar the Coldbringer [npc=7358] is a challenging dungeon boss that should be tanked facing the tent where he stands to neutralize Amnennar's Wrath. Have your group stack on the tank to reduce the severity of Frost Nova, and switch to the spirit that he summons as soon as it spawns. Interrupt Frostbolt and prioritize proper positioning.
Abilities | 

 Amnennar's Wrath [spell=13009] Frost Nova [spell=15531]  | 

 Frostbolt [spell=15530] Summon Frost Spectres [spell=12642]  | 
 

Plaguemaw the Rotting [npc=7356] is the final boss of an optional escort event. When Belnistrasz begins his ritual, focus down mobs that spawn one at a time, preferably with an off-tank pulling adds off Belnistrasz. Plaguemaw is a straightforward tank and spank.
Abilities | 

 Putrid Stench [spell=12946] Withered Touch [spell=12947]  | 
 

## Razorfen Downs Loot in World of Warcraft: Forever

Type | Item | Boss | 

Plate Chest |  Carapace of Tuten'kash [item=10775] |  Tuten'kash | 

Cloak |  Silky Spider Cape [item=10776] |  Tuten'kash | 

Leather Hands |  Arachnid Gloves [item=10777] |  Tuten'kash | 

Type | Item | Boss | 

Neck |  Glowing Eye of Mordresh [item=10769] |  Mordresh Fire Eye | 

Off-Hand |  Mordresh's Lifeless Skull [item=10770] |  Mordresh Fire Eye | 

Cloth Waist |  Deathmage Sash [item=10771] |  Mordresh Fire Eye | 

Type | Item | Boss | 

One-Hand Axe |  Glutton's Cleaver [item=10772] |  Glutton | 

Leather Shoulders |  Fleshhide Shoulders [item=10774] |  Glutton | 

Neck |  Abomination Chain [item=274385] |  Glutton | 

Type | Item | Boss | 

Shield |  Savage Boar's Guard [item=10767] |  Ragglesnout | 

Mail Waist |  Boar Champion's Belt [item=10768] |  Ragglesnout | 

Two-Hand Sword |  X'caliboar [item=10758] |  Ragglesnout | 

Type | Item | Boss | 

One-Hand Dagger |  Coldrage Dagger [item=10761] |  Amnennar the Coldbringer | 

Plate Helm |  Icemetal Barbute [item=10763] |  Amnennar the Coldbringer | 

Mail Chest |  Deathchill Armor [item=10764] |  Amnennar the Coldbringer | 

Cloth Chest |  Robes of the Lich [item=10762] |  Amnennar the Coldbringer | 

Two-Hand Staff |  Coldbringer Spine [item=274381] |  Amnennar the Coldbringer | 

Leather Hands |  Bonefingers [item=10765] |  Amnennar the Coldbringer | 

Type | Item | Boss | 

Leather Hands |  Swine Fists [item=10760] |  Plaguemaw the Rotting | 

Wand |  Plaguerot Sprig [item=10766] |  Plaguemaw the Rotting | 

Cloth Wrists |  Decaying Flesh Bands [item=274380] |  Plaguemaw the Rotting | 

Type | Item | 

Wand |  Freezing Shard [item=10572] | 

Two-Hand Axe |  Manslayer [item=10570] |

## Comparison vs shipped data (2026-11-17)


Quellen: https://www.wowhead.com/forever/dungeon-journal/razorfen-downs und Dungeon-Guide (URL in der Recherche-Datei).

## Bosse ohne Eintrag in `Assist/InstanceData/mechanics.lua`
- Ragglesnout (Rare) (NPC [7354]): 4 Faehigkeiten im Journal

## Faehigkeiten laut Journal, die bei uns fehlen (Spell-ID, Name, Wowhead-Beschreibung)
- **Ragglesnout (Rare)** [7354]: Dominate Mind (7645), Shadow Word: Pain (10892), Shadow Bolt (11659), Heal (12039)

## Quests
- Journal-Quests nicht in `dungeon_db.lua` questInfo: keine
- Guide-Quests (Tabelle "Every Quest") nicht in questInfo: keine

## Schritte
- Rohdaten durchsehen, fehlende Bosse/Faehigkeiten/Quests mit Eigenformulierung (nicht kopieren) in `docs/research/mechanics/*.json` bzw. `dungeon_db.lua` ergaenzen (`make mechanics`), Strategie-Tipps pruefen
- Spieler-relevante Aenderung: Changelog-Zeile in 4 Sprachen
- `sources.md` aktualisieren (Quelle/Stand)
- Wowhead-Aussagen als unverifiziert behandeln, wenn der Guide unklar ist

## Abilities from other sources (Bosse ohne Eintrag)

Quelle: warcraft.wiki.gg (CC BY-SA 3.0, paraphrasiert). **classic-source, unverified for Forever.**

| Boss (NPC) | Ability | Spell ID | Was es tut | Umgang | Confidence |
|---|---|---|---|---|---|
| Ragglesnout (7354) | Dominate Mind / Heal / Shadow Bolt / Shadow Word: Pain | 7645 / 12039 / 12471 / 11639 | Gedankenkontrolle bis Lvl 25 / Heilung / Schatten / DoT | Heal und Bolt kicken, SWP dispellen, Adds vorher raeumen | mittel |
