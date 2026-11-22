-- GENERIERT von tools/mechanics ("make mechanics"), nicht von Hand bearbeiten.
-- Quelle: Guide-Recherche docs/research/mechanics/*.json (je Instanz eine Datei), siehe sources.md.
-- ns.Mechanics = { [npcID] = { { spellID, Typ, Text deDE, Text enUS, Kennung }, ... } }
--   Kennung: "c" nur Classic Era, "f" nur Forever, "v" beide und für Forever bestätigt, ohne = beide, für Forever
--   nur aus Classic übernommen. Der Schluss der Datei entfernt die Zeilen des anderen Flavors.
--   spellID 0 = keine passende Zauber-ID (Zeile ohne Zaubersymbol), Typ: avoid, interrupt, dispel, tank, survive, adds,
--   positioning. Deutsche Clients lesen den deutschen Text, alle anderen (auch frFR/esES) den englischen; die Texte
--   laufen bewusst nicht über Locales (Spieldaten, kein UI-Text). Leser: Assist/Mechanics.lua.
local _, ns = ...
-- Nur Classic Era und Forever: klassische Instanzen, Retail hat andere Fähigkeiten an denselben NPCs.
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

ns.Mechanics = {
  [622] = { -- Goblin Engineer (The Deadmines)
    { 3605, "adds", "Beschwört einen Golem: Ingenieur schnell töten", "Summons a golem helper: kill the engineer quickly", "v" },
    { 853, "survive", "Betäubt einen Spieler: auf den Heiler achten", "Stuns a player: watch the healer", "v" },
  },
  [636] = { -- Defias Blackguard (The Deadmines)
    { 6408, "adds", "Getarnte Elite: auf versteckte Gegner bei Bossen achten", "Stealthed elites: watch for hidden pulls near bosses" },
  },
  [639] = { -- Edwin VanCleef (The Deadmines)
    { 5200, "adds", "Ruft bei wenig Leben zwei Schwarzwachen: kontrollieren oder töten", "Calls two Blackguards at low health: control or kill them", "v" },
    { 3391, "tank", "Erhält Extraangriffe: Schadensspitzen auf dem Tank", "Gains extra attacks: burst damage on the tank", "v" },
  },
  [642] = { -- Sneed's Shredder (The Deadmines)
    { 7399, "survive", "Furcht 4 Sek. lang: nicht in weitere Gegner laufen", "Fears a player for 4 sec: avoid running into extra mobs", "v" },
    { 3603, "survive", "Verlangsamt Zauber um 35 %: mit längeren Zaubern rechnen", "Slows a caster's casting by 35%: plan longer casts", "v" },
    { 5141, "adds", "Sneed springt beim Tod des Schredders heraus: als Nächstes töten", "Sneed jumps out when the shredder dies: kill him next" },
  },
  [643] = { -- Sneed (The Deadmines)
    { 6713, "tank", "Entwaffnet den Tank: kurz weniger Bedrohung einplanen", "Disarms the tank: expect lower threat for a few seconds", "v" },
  },
  [644] = { -- Rhahk'Zor (The Deadmines)
    { 6304, "tank", "Hieb betäubt den Tank 3 Sek. lang: Tank voll geheilt halten", "Slam stuns the tank for 3 sec: keep the tank topped up", "v" },
  },
  [645] = { -- Cookie (The Deadmines)
    { 6306, "avoid", "Naturschaden um ihn 30 Sek. lang: Fernkämpfer halten Abstand", "Nature damage around him for 30 sec: ranged keep away", "v" },
    { 5174, "interrupt", "Heilt sich selbst: Kochen unterbrechen", "Heals himself: interrupt the cooking", "v" },
  },
  [646] = { -- Mr. Smite (The Deadmines)
    { 6432, "survive", "Betäubt bei 75 % und 50 % die Gruppe: vorher hochheilen", "Stuns the whole group at 75% and 50%: heal up before", "v" },
    { 6435, "tank", "Hieb betäubt den Tank: Tank voll geheilt halten", "Slam stuns the tank: keep the tank topped up", "v" },
    { 3391, "tank", "Gibt ihm ab und zu zwei Zusatzangriffe: Schadensspitzen auf dem Tank", "Gives him two extra attacks now and then: expect bursts on the tank", "v" },
    { 6264, "tank", "Pariert 8 Sek. lang deutlich öfter: Angriffe misslingen häufiger, gleichmäßig heilen", "Parries much more for 8 sec: hits on him fail more often, keep healing steady", "v" },
    { 0, "adds", "Getarnte Wachen an der Rampe vor dem Pull beseitigen", "Clear the stealthed guards at the ramp before the pull" },
  },
  [647] = { -- Captain Greenskin (The Deadmines)
    { 5208, "dispel", "Vergiftet einen Spieler per Harpune: Gift heilen", "Poisons a player with his harpoon: cure poison", "v" },
    { 15496, "positioning", "Spaltet nach vorne: nur der Tank steht vor ihm", "Cleaves in front: only the tank faces him", "v" },
  },
  [1663] = { -- Dextren Ward (The Stockade)
    { 5246, "survive", "Schrei lässt Spieler fliehen: Furchtschutz nutzen", "Shout fears nearby players: use fear protection", "v" },
    { 11976, "tank", "Harte Waffenschläge auf den Tank: gleichmäßig heilen", "Hard weapon strikes on the tank: keep healing steady", "v" },
    { 19134, "survive", "**Furchterregender Ruf**: 6 Sek. lang Furcht für Spieler in der Nähe; Zusatzpulls vermeiden", "Frightening Shout fears nearby players for 6 sec; avoid extra pulls" },
  },
  [1666] = { -- Kam Deepfury (The Stockade)
    { 8242, "tank", "**Schildschlag** betäubt den Tank 2 Sek. lang", "Shield Slam stuns the tank for 2 sec", "v" },
    { 7164, "tank", "Verteidigungshaltung: er hält mehr aus, der Kampf dauert länger", "Defensive stance: he takes longer to bring down, expect a longer fight", "v" },
    { 3419, "tank", "Blockt 6 Sek. lang deutlich öfter: Treffer auf ihn werden teils geblockt", "Blocks much more for 6 sec: hits on him are partly blocked", "v" },
    { 871, "survive", "**Schildwall** senkt 12 Sek. lang den erlittenen Schaden um 60 %; Burst-Schaden aufheben", "Shield Wall cuts his damage taken by 60% for 12 sec; hold burst" },
  },
  [1696] = { -- Targorr the Dread (The Stockade)
    { 3391, "tank", "**Dreschen** gibt Extraangriffe; Tankschaden kommt in Spitzen", "Thrash grants extra attacks; spiky tank damage", "v" },
    { 8599, "tank", "**Wutanfall** erhöht Schaden und Tempo; Tank stärker heilen", "Enrage raises his damage and attack speed; heal the tank harder", "v" },
  },
  [1706] = { -- Defias Prisoner (The Stockade)
    { 6713, "tank", "Entwaffnet den Tank: kurz weniger Bedrohung einplanen", "Disarms the tank: expect less threat for a few seconds", "v" },
  },
  [1715] = { -- Defias Insurgent (The Stockade)
    { 13730, "tank", "Rufe stärken Verbündete und schwächen euch; Aufständische früh töten", "Shouts buff allies and weaken you; kill insurgents early" },
  },
  [1716] = { -- Bazil Thredd (The Stockade)
    { 7964, "avoid", "**Rauchbombe** betäubt alle in seiner Nähe 4 Sek. lang", "Smoke Bomb stuns everyone near him for 4 sec", "v" },
    { 9128, "tank", "**Schlachtruf** erhöht die Angriffskraft naher Verbündeter", "Battle Shout boosts nearby allies' attack power", "v" },
  },
  [1717] = { -- Hamhock (The Stockade)
    { 421, "interrupt", "**Kettenblitz** unterbrechen, springt auf drei Spieler", "Interrupt Chain Lightning, it jumps to three players", "v" },
    { 6742, "dispel", "**Kampfrausch** von ihm oder Verbündeten reinigen", "Purge Bloodlust from him or his allies", "v" },
  },
  [1729] = { -- Defias Evoker (The Deadmines)
    { 11829, "avoid", "**Flammensäule** am Boden: herausgehen, Beschwörer zuerst töten", "Fire pillar on the ground: step out, kill evokers first" },
    { 12544, "tank", "**Frostrüstung** verlangsamt Nahkämpfer", "Frost armor slows melee attackers" },
  },
  [1763] = { -- Gilnid (The Deadmines)
    { 5213, "dispel", "Verbrennt und verlangsamt einen Spieler: gegenheilen", "Burns and slows a player: heal through it", "v" },
    { 5159, "avoid", "Geschmolzenes Erz auf Spielern in der Nähe stapelt sich: Fernkämpfer bleiben hinten", "Molten ore on nearby players stacks: ranged stay back" },
  },
  [1853] = { -- Darkmaster Gandling (Scholomance)
    { 18702, "dispel", "Seinen Fluch entfernen", "Remove his curse", "v" },
    { 12040, "tank", "Schirmt sich ab; Nahkämpfer halten Aggro, Fernkämpfer auf Treppe", "Shields himself; melee keep threat, ranged on stairs", "v" },
    { 25346, "interrupt", "**Arkane Geschosse** auf Spieler: Kanalisierung unterbrechen", "**Arcane missiles** on a player: interrupt the channel", "v" },
    { 17950, "adds", "Teleportiert Spieler in Nebenräume mit Adds; freikämpfen", "Ports players into side rooms with adds; fight out" },
  },
  [2529] = { -- Son of Arugal (Shadowfang Keep)
    { 7124, "survive", "Starker Schattentreffer jede Minute, 5 Min. lang: Heiler aufpassen", "Big shadow hit every minute for 5 min: healers watch it" },
  },
  [2748] = { -- Archaedas (Uldaman)
    { 6524, "survive", "**Erdbeben** betäubt alle Spieler in der Nähe", "**Ground Tremor** stuns all nearby players", "v" },
    { 10252, "adds", "Erweckt irdene Wächter: Begleiter tanken und töten", "Awakens earthen guardians: tank and kill the adds", "v" },
    { 10258, "adds", "Erweckt Gewölbewächter: weg von Zauberern tanken", "Awakens vault warders: tank them away from casters", "v" },
    { 0, "adds", "Weckt alle 10 Sek. einen Irdenen; flächig töten oder abtanken", "Wakes an Earthen Custodian every 10 sec; AoE or off-tank" },
    { 0, "adds", "Bei 66 % erwachen sechs Wächter mit Wirbelwind; Boss fokussieren", "At 66% six Guardians wake and whirlwind; burn the boss" },
  },
  [3586] = { -- Miner Johnson (The Deadmines)
    { 12097, "tank", "Rüstung durchstechen senkt Tankrüstung: stärker heilen", "Pierce armor lowers the tank's armor: heal more", "v" },
  },
  [3654] = { -- Mutanus the Devourer (Wailing Caverns)
    { 7967, "survive", "Schläfert einen Spieler bis zu 15 Sek. lang ein: Treffer weckt auf", "Sleeps one player up to 15 sec: hit them to wake them", "v" },
    { 7399, "survive", "Furcht auf ein Ziel, 4 Sek. lang: auf zusätzliche Gegner achten", "Fears a target for 4 sec: watch for extra pulls", "v" },
    { 8150, "avoid", "Naturstoß betäubt Spieler in der Nähe: Fernkämpfer bleiben auf Distanz", "Nature blast stuns nearby players: ranged stay at range", "v" },
  },
  [3669] = { -- Lord Cobrahn (Wailing Caverns)
    { 7965, "tank", "Wird zur Schlange und schlägt im Nahkampf härter zu", "Turns into a serpent and hits harder in melee", "v" },
    { 8040, "interrupt", "Schläfert Spieler ein: Zauber unterbrechen", "Sleeps a player: interrupt the cast", "v" },
    { 9532, "interrupt", "Blitzschlag auf Spieler: wenn möglich unterbrechen", "Lightning bolt on a player: interrupt when possible", "v" },
    { 5187, "interrupt", "Heilt sich selbst: Unterbrechung für die Heilung aufheben", "Heals himself: save an interrupt for the heal", "v" },
    { 744, "dispel", "Vergiftet in Schlangengestalt: Gift heilen", "Poisons in serpent form: cure poison" },
  },
  [3670] = { -- Lord Pythas (Wailing Caverns)
    { 8147, "avoid", "Naturstoß im 10-m-Umkreis verlangsamt: Fernkämpfer halten Abstand", "Nature blast within 10 yd slows: ranged keep their distance", "v" },
    { 700, "interrupt", "Schläfert Spieler bis zu 20 Sek. lang ein: Zauber unterbrechen", "Sleeps a player for up to 20 sec: interrupt the cast", "v" },
    { 5187, "interrupt", "Heilt sich selbst: Heilung unterbrechen", "Heals himself: interrupt the heal", "v" },
    { 9532, "interrupt", "Blitzschlag auf Spieler: wenn möglich unterbrechen", "Lightning bolt on a player: interrupt when possible", "v" },
  },
  [3671] = { -- Lady Anacondra (Wailing Caverns)
    { 700, "interrupt", "Schläfert Spieler bis zu 20 Sek. lang ein: Zauber unterbrechen", "Sleeps a player for up to 20 sec: interrupt the cast", "v" },
    { 5187, "interrupt", "Heilt sich selbst: Unterbrechung für die Heilung aufheben", "Heals herself: save an interrupt for the heal", "v" },
    { 8148, "survive", "Dornen verletzen Nahkämpfer: Heiler achten auf Nahkämpfer", "Thorns hurt melee attackers: healers watch melee health", "v" },
    { 9532, "interrupt", "Blitzschlag auf Spieler: wenn möglich unterbrechen", "Lightning bolt on a player: interrupt when possible", "v" },
  },
  [3673] = { -- Lord Serpentis (Wailing Caverns)
    { 700, "interrupt", "Schlaf bis zu 20 Sek. lang: unterbrechen, Schaden weckt auf", "Sleeps a player up to 20 sec: interrupt, damage wakes", "v" },
    { 5187, "interrupt", "Große Selbstheilung: immer unterbrechen", "Large self heal: always interrupt", "v" },
    { 9532, "interrupt", "Blitzschlag auf Spieler: wenn möglich unterbrechen", "Lightning bolt on a player: interrupt when possible", "v" },
  },
  [3674] = { -- Skum (Wailing Caverns)
    { 6254, "interrupt", "Blitz springt auf bis zu 3 Spieler: unterbrechen", "Bolt jumps to up to 3 players: interrupt it", "v" },
    { 13496, "tank", "Verlangsamt sein Ziel 10 Sek. lang um die Hälfte: nur lästig, weiter tanken", "Slows his target by half for 10 sec: only a nuisance, keep tanking", "v" },
  },
  [3840] = { -- Druid of the Fang (Wailing Caverns)
    { 8041, "tank", "Wird zur Schlange und schlägt härter: schnell aufnehmen", "Turns into a serpent and hits harder: pick it up fast", "v" },
  },
  [3853] = { -- Shadowfang Moonwalker (Shadowfang Keep)
    { 24021, "tank", "Zeitweise immun gegen Magie: physischen Schaden nutzen", "Immune to magic for a while: use physical damage", "v" },
  },
  [3855] = { -- Shadowfang Darksoul (Shadowfang Keep)
    { 8140, "dispel", "Halbiert 15 Sek. lang das Zaubertempo: bei Heilern bannen", "Halves casting speed for 15 sec: dispel healers" },
    { 970, "dispel", "Schattenschaden über Zeit: bannen oder gegenheilen", "Shadow damage over time: dispel or heal through" },
  },
  [3864] = { -- Fel Steed (Shadowfang Keep)
    { 7139, "avoid", "Stampfen betäubt Spieler in der Nähe 3 Sek. lang: Fernkämpfer bleiben hinten", "Stomp stuns nearby players for 3 sec: ranged stay back", "v" },
  },
  [3865] = { -- Shadow Charger (Shadowfang Keep)
    { 7139, "avoid", "Stampfen betäubt Spieler in der Nähe 3 Sek. lang: Fernkämpfer bleiben hinten", "Stomp stuns nearby players for 3 sec: ranged stay back", "v" },
  },
  [3866] = { -- Vile Bat (Shadowfang Keep)
    { 6713, "survive", "Entwaffnet einen Spieler 6 Sek. lang: Nahkämpfer abwarten oder Ziel wechseln", "Disarms a player for 6 sec: melee wait it out or switch target", "v" },
    { 7145, "avoid", "**Sturzflug** trifft das Ziel und bis zu 2 Nachbarn: vom Tank etwas Abstand halten", "Sweep hits the target and up to 2 neighbours: stand apart from the tank", "v" },
  },
  [3872] = { -- Deathsworn Captain (Shadowfang Keep)
    { 15496, "positioning", "Spaltet nach vorn: nur der Tank steht vorne", "Cleaves the front: only the tank stands in front", "v" },
    { 9080, "survive", "Kniesehne verlangsamt sein Ziel 10 Sek. um 60%: danach neu positionieren", "Hamstring slows his target by 60% for 10 sec: reposition after it ends", "v" },
  },
  [3873] = { -- Tormented Officer (Shadowfang Keep)
    { 7054, "dispel", "Fluch senkt immer wieder eine Fertigkeit: Fluch entfernen", "Curse keeps lowering a skill: remove the curse" },
  },
  [3875] = { -- Haunted Servitor (Shadowfang Keep)
    { 7057, "dispel", "Fluch ruft Geister auf das Ziel: schnell entfernen", "Curse that spawns ghosts on the target: remove it fast" },
  },
  [3877] = { -- Wailing Guardsman (Shadowfang Keep)
    { 7074, "survive", "Flächenstille für einige Sek. lang: Zauberer halten Abstand", "Area silence for a few seconds: casters stay out of range", "v" },
  },
  [3886] = { -- Razorclaw the Butcher (Shadowfang Keep)
    { 7485, "survive", "Saugt einem Spieler Leben ab: Ziel heilen", "Drains life from a player: heal the target", "v" },
  },
  [3887] = { -- Baron Silverlaine (Shadowfang Keep)
    { 7068, "dispel", "Senkt 15 Sek. lang die erhaltene Heilung um 75 %: Fluch entfernen", "Cuts healing taken by 75% for 15 sec: remove the curse", "v" },
  },
  [3914] = { -- Rethilgore (Shadowfang Keep)
    { 7295, "survive", "Fesselt einen Spieler 10 Sek. lang und saugt Leben: gegenheilen", "Roots a player for 10 sec and drains health: heal them", "v" },
  },
  [3927] = { -- Wolf Master Nandos (Shadowfang Keep)
    { 7487, "adds", "Ruft Worgs und einen Wolfsschrecken: Adds tanken und töten", "Calls worgs and a Lupine Horror: tank and kill the adds", "v" },
    { 7489, "adds", "Ruft einen Wolfsschrecken: Begleiter töten oder kontrollieren", "Calls a lupine horror: kill or control the add", "v" },
    { 7488, "adds", "Ruft einen geifernden Worg: Begleiter töten oder kontrollieren", "Calls a slavering worg: kill or control the add", "v" },
  },
  [3974] = { -- Houndmaster Loksey (Scarlet Monastery: Library)
    { 6742, "adds", "Kommt mit Hunden und beschleunigt sie; Hunde AoE oder CC", "Comes with hounds and speeds them up; AoE or CC the dogs", "v" },
    { 11549, "tank", "Ruf erhöht seinen Nahkampfschaden; Tank mit Abklingzeiten", "Shout raises his melee damage; tank with cooldowns", "v" },
  },
  [3975] = { -- Herod (Scarlet Monastery: Armory)
    { 8989, "avoid", "Wirbelt magieimmun; alle außer dem Tank weglaufen", "Spins with magic immunity; everyone but tank runs away", "v" },
    { 8269, "tank", "Bei wenig Leben schnellere Angriffe; Tank-Abklingzeiten sparen", "Attack speed jumps at low health; save tank cooldowns", "v" },
    { 22540, "positioning", "Spaltet den Tank und Spieler daneben: nur der Tank steht vorne", "Cleaves the tank and a neighbour: only the tank stands in front", "v" },
    { 8260, "survive", "Stürmt schnell heran und trifft zuerst hart: Tank rechnet mit einer Spitze", "Charges with a speed burst and a hard first hit: tank expects a spike", "v" },
    { 0, "adds", "Nach dem Tod 20 schwache Rekruten; AoE nutzen", "Twenty weak trainees spawn on death; use AoE" },
  },
  [3976] = { -- Scarlet Commander Mograine (Scarlet Monastery: Cathedral)
    { 853, "survive", "Betäubt Spieler; Heiler nicht lange ausfallen lassen", "Stuns a player; healer must not be locked out long", "v" },
    { 642, "tank", "**Gottesschild** bei wenig Leben; weitertanken", "Bubbles at low health; keep tanking, swap to Whitemane", "v" },
    { 9257, "survive", "Nach der Wiederbelebung heilt er Weißkrähe voll", "After Whitemane revives him he fully heals her", "v" },
    { 14518, "tank", "**Kreuzfahrerstoß** trifft den Tank hart: gleichmäßig heilen", "**Crusader strike** hits the tank hard: heal steadily", "v" },
    { 8990, "survive", "Aura verletzt Nahkämpfer: Heiler achten auf Nahkämpfer", "Aura hurts melee attackers: healers watch melee health", "v" },
  },
  [3977] = { -- High Inquisitor Whitemane (Scarlet Monastery: Cathedral)
    { 9256, "survive", "Bei halbem Leben schläft die ganze Gruppe 8 Sek. lang", "At half health she sleeps the whole party for 8 sec", "v" },
    { 9232, "survive", "Belebt Mograine im Schlaf; beide kommen voll zurück", "Revives Mograine while you sleep; both return full", "v" },
    { 9481, "interrupt", "Heiliges Feuer auf Spieler: unterbrechen", "Holy smite on a player: interrupt it", "v" },
    { 22187, "dispel", "Schützt sich mit einem Schild: Schild bannen", "Shields herself: dispel the shield", "v" },
    { 12039, "interrupt", "Heilt sich und Verbündete: Unterbrechung dafür aufheben", "Heals herself and her allies: save an interrupt for it", "v" },
    { 0, "dispel", "Kann Spieler übernehmen; bannen oder kontrollieren", "Can mind control a player; dispel or CC them" },
  },
  [3983] = { -- Interrogator Vishas (Scarlet Monastery: Graveyard)
    { 9034, "dispel", "Feuer-DoT auf Spieler; bannen oder gegenheilen", "Fire DoT on a player; dispel or heal through it" },
    { 14032, "dispel", "Schatten-DoT; Magiebannung entfernt ihn", "Shadow DoT; magic dispel removes it" },
  },
  [4274] = { -- Fenrus the Devourer (Shadowfang Keep)
    { 7125, "dispel", "Gift entzieht Mana und verursacht Naturschaden: Gift entfernen", "Poison drains mana and deals nature damage: cure poison", "v" },
  },
  [4275] = { -- Archmage Arugal (Shadowfang Keep)
    { 7621, "survive", "Verwandelt einen Spieler 10 Sek. lang in einen Worgen: nicht angreifen", "Turns a player into a worgen for 10 sec: avoid hitting them", "v" },
    { 7803, "avoid", "Naturstoß betäubt Spieler in der Nähe: Abstand halten", "Nature burst stuns nearby players: keep distance", "v" },
    { 22709, "interrupt", "Starker Schattenblitz: unterbrechen oder Ziel heilen", "Heavy shadow bolt: interrupt or heal the target", "v" },
    { 7587, "positioning", "Teleportiert sich im Raum: nachrücken und in Reichweite bleiben", "Teleports around the room: move to keep him in range", "v" },
  },
  [4278] = { -- Commander Springvale (Shadowfang Keep)
    { 1026, "interrupt", "Heilt sich mit **Heiligem Licht**: unterbrechen", "Heals himself with Holy Light: interrupt it", "v" },
    { 5588, "survive", "Betäubt einen Spieler 4 Sek. lang", "Stuns a player for 4 sec", "v" },
  },
  [4279] = { -- Odo the Blindwatcher (Shadowfang Keep)
    { 7481, "tank", "Schaden steigt mit jedem Heulen: schnell töten", "Damage rises with each howl: burn him down fast", "v" },
  },
  [4287] = { -- Scarlet Gallant (Scarlet Monastery: Library)
    { 77787, "survive", "Betäubt einen Spieler; Heiler im Blick behalten", "Stuns a player; watch healer health", "c" },
  },
  [4288] = { -- Scarlet Beastmaster (Scarlet Monastery: Library)
    { 7896, "positioning", "Feuerschuss trifft Ziel und Umstehende; verteilen", "Fire shot hits the target and nearby players; spread" },
  },
  [4291] = { -- Scarlet Diviner (Scarlet Monastery: Library)
    { 11981, "interrupt", "Verbrennt Heilermana; unterbrechen oder betäuben", "Burns healer mana; interrupt or stun it" },
  },
  [4292] = { -- Scarlet Protector (Scarlet Monastery: Armory)
    { 31713, "interrupt", "Heilt Verbündete; **Heiliges Licht** unterbrechen", "Heals allies; interrupt Holy Light", "c" },
  },
  [4293] = { -- Scarlet Scryer (Scarlet Monastery: Graveyard)
    { 9613, "interrupt", "Zauberer; **Schattenblitz** unterbrechen", "Caster; interrupt **Shadow Bolt**" },
    { 77773, "dispel", "Schläfert einen Spieler ein; Opfer bannen", "Puts a player to sleep; dispel the victim", "c" },
  },
  [4294] = { -- Scarlet Sorcerer (Scarlet Monastery: Cathedral)
    { 8364, "avoid", "Frost-Flächenschaden am Boden; heraustreten", "Frost AoE on the ground; step out" },
  },
  [4295] = { -- Scarlet Myrmidon (Scarlet Monastery: Armory)
    { 8269, "tank", "Wird bei wenig Leben wütend; schnell töten", "Enrages at low health; burst it down" },
  },
  [4296] = { -- Scarlet Adept (Scarlet Monastery: Library)
    { 11642, "interrupt", "Wirkt Heilzauber; jede Heilung unterbrechen", "Healer; interrupt every Heal cast" },
  },
  [4297] = { -- Scarlet Conjuror (Scarlet Monastery: Armory)
    { 8985, "adds", "Beschwört Feuerelementar; Beschwörer zuerst töten", "Summons a fire elemental pet; kill the caster first" },
  },
  [4299] = { -- Scarlet Chaplain (Scarlet Monastery: Library)
    { 22187, "interrupt", "Schützt und heilt Verbündete; zuerst töten", "Shields and renews allies; kill it first" },
    { 25058, "dispel", "Heilung über Zeit auf einem Verbündeten; reinigen oder wegschlagen", "HoT on allies; purge it or burst through" },
  },
  [4300] = { -- Scarlet Wizard (Scarlet Monastery: Cathedral)
    { 1449, "positioning", "Wirkt ständig Flächenschaden bei Gruppen; verteilt bekämpfen", "Spams AoE when players stack; fight it spread", "v" },
  },
  [4302] = { -- Scarlet Champion (Scarlet Monastery: Cathedral)
    { 17284, "tank", "Harte Heiligschläge auf den Tank; schlimmer mit Abt", "Hard holy hits on the tank; worse with an Abbot", "v" },
  },
  [4303] = { -- Scarlet Abbot (Scarlet Monastery: Cathedral)
    { 2054, "interrupt", "Heilt andere, wird wütend; zuerst töten, unterbrechen", "Heals others and enrages low; kill and interrupt first", "v" },
    { 139, "dispel", "**Erneuerung** heilt über Zeit: reinigen oder nächsten Zauber unterbrechen", "**Renew** heals over time: purge it or interrupt the next cast", "v" },
  },
  [4306] = { -- Scarlet Torturer (Scarlet Monastery: Graveyard)
    { 9275, "dispel", "Feuer-DoT auf Spieler; wenn möglich bannen", "Fire DoT on players; dispel when possible" },
  },
  [4418] = { -- Defias Wizard (The Deadmines)
    { 9053, "interrupt", "Feuerbälle treffen hart: unterbrechen oder Sichtlinie brechen", "Fireballs hit hard: interrupt or line of sight" },
    { 4979, "dispel", "Macht Verbündete feuerimmun: Zauber wechseln oder reinigen", "Makes an ally immune to fire: switch spells or purge" },
  },
  [4420] = { -- Overlord Ramtusk (Razorfen Kraul)
    { 15548, "survive", "**Donnerknall** schadet und verlangsamt Spieler in der Nähe; Nahkämpfer heilen", "Thunderclap damages and slows everyone close; melee heal up", "v" },
    { 9128, "tank", "**Schlachtruf** erhöht die Angriffskraft seiner Gruppe", "Battle Shout raises his group's attack power" },
  },
  [4421] = { -- Charlga Razorflank (Razorfen Kraul)
    { 8292, "interrupt", "Kettenblitz unterbrechen, springt zwischen Spielern", "Interrupt Chain Bolt, it jumps between players", "v" },
    { 6077, "dispel", "Erneuerung bei ihr reinigen", "Purge Renew from her", "v" },
    { 8361, "survive", "2 Sek. lang immun gegen alles: Schaden bis zum Ende zurückhalten", "Immune to everything for 2 sec: hold your damage until it ends", "v" },
    { 8358, "survive", "Stellt ihr Mana wieder her: sie lässt sich nicht leer ziehen", "Restores her mana: she cannot be run out of mana", "v" },
  },
  [4422] = { -- Agathelos the Raging (Razorfen Kraul)
    { 8269, "tank", "Raserei verstärkt seine Angriffe; Tank spart Abklingzeiten dafür", "Frenzy boosts his attacks; tank saves cooldowns for it", "v" },
    { 8260, "positioning", "Stürmt auf einen zufälligen Spieler: nah am Tank bleiben", "Charges a random player: stay near the tank", "v" },
  },
  [4424] = { -- Aggem Thorncurse (Razorfen Kraul)
    { 14900, "interrupt", "Kettenheilung unterbrechen", "Interrupt Chain Heal", "v" },
    { 8286, "adds", "Ruft einen Ebergeist als Add", "Summons a Boar Spirit add", "v" },
    { 6192, "tank", "**Schlachtruf** erhöht die Angriffskraft seiner Gruppe", "Battle Shout raises his group's attack power", "v" },
  },
  [4425] = { -- Blind Hunter (Razorfen Kraul)
    { 8281, "interrupt", "Schallexplosion bringt Zauberer zum Schweigen: Abstand halten", "Sonic burst silences nearby casters: keep range", "v" },
    { 3242, "tank", "Verheeren trifft den Tank hart: gleichmäßig heilen", "Ravage hits the tank hard: keep healing steady", "v" },
  },
  [4428] = { -- Death Speaker Jargba (Razorfen Kraul)
    { 14515, "dispel", "Übernimmt einen Spieler; bannen oder kontrollieren", "Mind controls a player; dispel or crowd-control them", "v" },
    { 9613, "interrupt", "Schattenblitz unterbrechen", "Interrupt Shadow Bolt", "v" },
  },
  [4438] = { -- Razorfen Spearhide (Razorfen Kraul)
    { 8259, "avoid", "Trifft alle in der Nähe: Heiler und Fernkämpfer halten Abstand", "Hits everyone close around it: healers and ranged keep distance", "v" },
  },
  [4440] = { -- Razorfen Totemic (Razorfen Kraul)
    { 8376, "positioning", "**Totem des Erdgriffs** wurzelt Spieler in der Nähe fest; Totem zerstören", "Earthgrab Totem roots nearby players; kill the totem", "v" },
    { 4971, "adds", "Stellt einen Heilungszauberschutz auf; zerstören", "Drops a Healing Ward; destroy it" },
  },
  [4516] = { -- Death's Head Adept (Razorfen Kraul)
    { 113, "dispel", "Eisketten verlangsamen einen Spieler: bei Bedarf bannen", "Chains of ice slow a player: dispel if needed", "v" },
  },
  [4517] = { -- Death's Head Priest (Razorfen Kraul)
    { 12039, "interrupt", "Heilt Verbündete; Heilen unterbrechen", "Heals allies; interrupt Heal" },
  },
  [4519] = { -- Death's Head Seer (Razorfen Kraul)
    { 4971, "adds", "Stellt einen Heilungszauberschutz auf; zerstören", "Drops a Healing Ward; destroy it" },
    { 8264, "avoid", "**Lavafontänentotem** verbrennt Spieler in der Nähe; ausweichen oder zerstören", "Lava Spout Totem burns players near it; move or kill it" },
  },
  [4520] = { -- Razorfen Geomancer (Razorfen Kraul)
    { 8270, "adds", "Ruft einen Steingrollen; Beschwörer zuerst töten", "Summons a Stone Rumbler; kill the caster first" },
  },
  [4522] = { -- Razorfen Dustweaver (Razorfen Kraul)
    { 6728, "dispel", "Winde betäuben einen Spieler: Magie bannen", "Winds stun a player: dispel magic", "v" },
  },
  [4540] = { -- Scarlet Monk (Scarlet Monastery: Library)
    { 3391, "tank", "Schubweise Extra-Angriffe auf den Tank", "Bursts of extra attacks on the tank" },
  },
  [4542] = { -- High Inquisitor Fairbanks (Scarlet Monastery: Cathedral)
    { 12039, "interrupt", "Heilt sich selbst; Heilung unterbrechen", "Heals himself; interrupt his Heal", "v" },
    { 8282, "dispel", "Fluch erhöht erlittenen Schaden; entfluchen", "Curse adds physical damage taken; decurse", "v" },
    { 11647, "dispel", "Schützt sich mit einem Schild: Schild bannen", "Shields himself: dispel the shield", "v" },
    { 8399, "dispel", "Schläfert einen Spieler ein: Magie bannen", "Puts a player to sleep: dispel magic", "v" },
    { 22678, "survive", "Furcht auf Spieler; nicht in weitere Gruppen laufen", "Fears a player; avoid running into extra pulls" },
  },
  [4543] = { -- Bloodmage Thalnos (Scarlet Monastery: Graveyard)
    { 12470, "positioning", "**Feuerstoß** um ihn; Fernkampf und Heiler halten Abstand", "Fire burst around him; ranged and healer keep distance", "v" },
    { 23038, "survive", "Sofortiger Feuertreffer mit Brand auf sein Ziel", "Instant fire hit plus burn on his target" },
    { 9613, "interrupt", "Wirkt **Schattenblitz**; unterbrechen spart Schaden", "Casts **Shadow Bolt**; kick it to cut damage" },
    { 8814, "avoid", "Feuersäule auf einem Bereich mit Brand; aus der Fläche treten", "Fire pillar on an area with a burn; step out of it" },
  },
  [4799] = { -- Fallenroot Hellcaller (Blackfathom Deeps)
    { 20817, "interrupt", "Verbrennt Mana von Zauberern: unterbrechen oder früh töten", "Burns mana from casters: interrupt or kill it early", "v" },
  },
  [4802] = { -- Blackfathom Tide Priestess (Blackfathom Deeps)
    { 11642, "interrupt", "Heilt andere Naga; Heilen unterbrechen", "Heals other naga; interrupt Heal" },
  },
  [4803] = { -- Blackfathom Oracle (Blackfathom Deeps)
    { 0, "interrupt", "Heilt Verbündete mit Welle der Heilung; unterbrechen", "Heals allies with Healing Wave; interrupt it" },
  },
  [4811] = { -- Twilight Aquamancer (Blackfathom Deeps)
    { 8372, "adds", "Ruft einen Wasserwächter; Beschwörer zuerst töten", "Summons an Aqua Guardian; kill the caster first" },
  },
  [4813] = { -- Twilight Shadowmage (Blackfathom Deeps)
    { 7645, "dispel", "Übernimmt einen Spieler; bannen oder kontrollieren", "Mind controls a player; dispel or crowd-control" },
    { 12746, "adds", "Ruft Leerwandler; Zauberer zuerst um die Ecke ziehen", "Summons a voidwalker; pull casters out of sight first" },
  },
  [4829] = { -- Aku'mai (Blackfathom Deeps)
    { 3815, "avoid", "**Giftwolke** verursacht Naturschaden um sie herum; Gift entfernen", "Poison Cloud ticks nature damage around her; cure poison", "v" },
    { 3490, "tank", "**Rasende Wut** erhöht ihr Angriffstempo stark; Tank nutzt Abklingzeiten", "Frenzied Rage speeds her attacks a lot; tank uses cooldowns", "v" },
  },
  [4830] = { -- Old Serra'kis (Blackfathom Deeps)
    { 8433, "survive", "Unterwasserkampf: **Blutegelpuls** entzieht allen Spielern in der Nähe Leben; Atem beachten", "Underwater fight: Leech Pulse drains everyone near him; watch breath" },
  },
  [4831] = { -- Lady Sarevess (Blackfathom Deeps)
    { 865, "avoid", "**Frostnova** friert Spieler in der Nähe ein; Fernkämpfer und Heiler halten Abstand", "Frost Nova roots everyone close; ranged and healers keep range", "v" },
    { 8435, "avoid", "**Gabelblitz** trifft mehrere Spieler vor ihr: dahinter stehen oder verteilen", "Forked lightning hits several players in front: stand behind or spread", "v" },
    { 246, "dispel", "Verlangsamt einen Spieler: Magie bannen, falls nötig", "Slows a player's movement: dispel magic if needed", "v" },
    { 6660, "survive", "Schießt aus der Ferne auf einen Spieler: gegenheilen", "Shoots a player from range: heal through it", "v" },
  },
  [4832] = { -- Twilight Lord Kelris (Blackfathom Deeps)
    { 8399, "positioning", "Schlaf trifft Spieler im 5-m-Radius; Heiler und Fernkämpfer weiter weg", "Sleep hits players within 5 yd; healer and ranged stand farther", "v" },
    { 15587, "interrupt", "Gedankenschlag unterbrechen", "Interrupt Mind Blast", "v" },
  },
  [4842] = { -- Earthcaller Halmgar (Razorfen Kraul)
    { 2484, "positioning", "**Totem der Erdbindung** verlangsamt; Totem zerstören", "Earthbind Totem slows everyone; destroy the totem", "v" },
    { 8270, "adds", "Ruft einen Steingrollen als Add", "Summons a Stone Rumbler add", "v" },
    { 9532, "interrupt", "Naturblitz auf einen Spieler: wenn möglich unterbrechen", "Nature bolt on a player: interrupt when possible", "v" },
  },
  [4848] = { -- Shadowforge Darkcaster (Uldaman)
    { 11981, "interrupt", "**Manabrand** unterbrechen, bevor Heiler leer sind", "Interrupt **Mana Burn** before it drains healers" },
    { 9081, "interrupt", "**Schattenblitzsalve** trifft alle; unterbrechen", "**Shadow Bolt Volley** hits the whole group; kick it" },
  },
  [4852] = { -- Stonevault Oracle (Uldaman)
    { 5605, "adds", "Stellt Heilungszauberschutz auf; zerstören oder wegziehen", "Drops a Healing Ward; destroy it or pull mobs away" },
    { 8005, "interrupt", "**Welle der Heilung** unterbrechen", "Interrupt **Healing Wave**" },
  },
  [4853] = { -- Stonevault Geomancer (Uldaman)
    { 10452, "interrupt", "**Flammenpuffer** erhöht Feuerschaden; unterbrechen", "**Flame Buffet** raises fire damage taken; interrupt" },
  },
  [4854] = { -- Grimlok (Uldaman)
    { 7289, "dispel", "**Schrumpfen** ist ein Fluch, der schwächt; entfluchen", "**Shrink** is a curse that weakens a player; decurse it", "v" },
    { 8292, "interrupt", "**Kettenblitz** und **Blitzschlag** unterbrechen", "Interrupt his **Chain Bolt** and Lightning Bolt casts", "v" },
    { 9532, "interrupt", "**Blitzschlag** unterbrechen, um den Schaden zu senken", "Interrupt his **Lightning Bolt** to cut his damage", "v" },
    { 6742, "dispel", "**Kampfrausch** von ihm oder seinem Basilisken bannen", "Purge **Bloodlust** from him or his basilisk", "v" },
  },
  [4863] = { -- Jadespine Basilisk (Uldaman)
    { 3636, "interrupt", "**Kristallschlummer** betäubt 3 Sek. lang; unterbrechen", "**Crystalline Slumber** stuns 3 sec; interrupt it" },
    { 9906, "avoid", "Nicht zaubern, solange **Reflexion** aktiv ist", "Stop casting while **Reflection** is up" },
  },
  [4887] = { -- Ghamoo-ra (Blackfathom Deeps)
    { 5568, "positioning", "Trampeln trifft auch Spieler neben dem Tank; Nahkämpfer verteilen", "Trample also hits players next to the tank; melee spread a bit", "v" },
  },
  [5259] = { -- Atal'ai Witch Doctor (Sunken Temple)
    { 11641, "dispel", "**Verhexung** schaltet einen Spieler aus; bannen", "**Hex** disables a player; dispel" },
    { 11986, "interrupt", "Heilt Verbündete; unterbrechen", "Heals allies; interrupt" },
  },
  [5269] = { -- Atal'ai Priest (Sunken Temple)
    { 12039, "interrupt", "Heilt Verbündete; unterbrechen", "Heals allies; interrupt" },
  },
  [5270] = { -- Atal'ai Corpse Eater (Sunken Temple)
    { 12134, "survive", "Frisst Leichen zur Erholung; schnell töten", "Feeds on corpses to recover; burst it down" },
  },
  [5271] = { -- Atal'ai Deathwalker (Sunken Temple)
    { 12095, "avoid", "Hinterlässt beim Tod einen immunen Geist; weglaufen bis er vergeht", "On death leaves an immune spirit; run until it fades" },
    { 12096, "survive", "Lässt einen Spieler fliehen", "Fears a player" },
  },
  [5273] = { -- Atal'ai High Priest (Sunken Temple)
    { 12039, "interrupt", "Heilt Verbündete; unterbrechen", "Heals allies; interrupt" },
    { 12151, "adds", "Erweckt Skelette", "Raises skeleton adds" },
  },
  [5280] = { -- Nightmare Wyrmkin (Sunken Temple)
    { 12098, "dispel", "Schläfert einen Spieler ein; Magie bannen", "Puts a player to sleep; dispel magic" },
  },
  [5291] = { -- Hakkari Frostwing (Sunken Temple)
    { 8398, "interrupt", "**Frostblitzsalve** trifft die Gruppe; unterbrechen", "**Frostbolt Volley** hits the group; interrupt" },
    { 9915, "survive", "**Frostnova** friert Spieler in der Nähe ein", "**Frost Nova** freezes players nearby" },
  },
  [5648] = { -- Sandfury Shadowcaster (Zul'Farrak)
    { 12471, "interrupt", "**Schattenblitz** unterbrechen", "Interrupt **Shadow Bolt**" },
    { 18396, "positioning", "Stößt Spieler zurück; auf Position achten", "Knocks players back; mind where you stand" },
  },
  [5650] = { -- Sandfury Witch Doctor (Zul'Farrak)
    { 17843, "interrupt", "**Blitzheilung** unterbrechen", "Interrupt **Flash Heal**" },
    { 11899, "adds", "Heilungszauberschutz zerstören oder Gegner wegziehen", "Destroy the Healing Ward or pull mobs off it" },
  },
  [5708] = { -- Spawn of Hakkar (Sunken Temple)
    { 12280, "survive", "Spuckt **Säure Hakkars** auf Spieler; durchheilen", "Spits **Acid of Hakkar** on players; heal through" },
  },
  [5709] = { -- Shade of Eranikus (Sunken Temple)
    { 12890, "survive", "**Tiefer Schlummer** schläfert Spieler ein; Heiler verteilen", "**Deep Slumber** puts players to sleep; keep healers spread", "v" },
    { 16740, "survive", "**Kriegsdonner** betäubt alle in der Nähe", "**War Stomp** stuns everyone close", "v" },
    { 3391, "tank", "Extraschläge: schwere Treffer auf dem Tank", "Extra swings: heavy hits on the tank", "v" },
    { 12891, "avoid", "**Säureatem** im Kegel; Tank dreht ihn weg", "**Acid Breath** cone; tank turns him away" },
  },
  [5710] = { -- Jammal'an the Prophet (Sunken Temple)
    { 8376, "adds", "**Totem des Erdgriffs** wurzelt fest; zerstören", "**Earthgrab Totem** roots players; destroy it", "v" },
    { 20296, "avoid", "**Flammenstoß** brennt ein Gebiet mehrere Sekunden lang nieder; aus dem Feuer treten", "**Flamestrike** burns an area for several seconds; step out of the fire", "v" },
    { 12480, "dispel", "**Verhexung** wendet einen Spieler gegen die Gruppe; bannen oder kontrollieren", "Hex turns a player against the group; dispel or CC" },
    { 12492, "interrupt", "Heilt mit **Welle der Heilung**; unterbrechen", "Heals with **Healing Wave**; interrupt" },
  },
  [5711] = { -- Ogom the Wretched (Sunken Temple)
    { 11660, "interrupt", "Wirkt **Schattenblitze**; unterbrechen", "Casts Shadow Bolts; interrupt", "v" },
    { 11708, "dispel", "**Fluch der Schwäche** auf Nahkämpfern; entfluchen", "**Curse of Weakness** on melee; decurse", "v" },
    { 23952, "dispel", "Schattenschaden über Zeit: Magie auf dem Ziel bannen", "Shadow damage over time: dispel magic on the target", "v" },
  },
  [5712] = { -- Zolo (Sunken Temple)
    { 12058, "interrupt", "**Kettenblitz** springt zwischen Spielern; unterbrechen", "**Chain Lightning** jumps between players; interrupt it" },
    { 12506, "adds", "Stellt ein Skeletttotem; zerstören", "Drops a skeleton totem; destroy it" },
  },
  [5713] = { -- Gasher (Sunken Temple)
    { 15580, "tank", "Harte Nahkampfschläge auf den Tank", "Heavy melee strikes on the tank" },
  },
  [5714] = { -- Loro (Sunken Temple)
    { 8242, "tank", "**Schildschlag** trifft den Tank hart", "**Shield Slam** hits the tank hard", "v" },
    { 12782, "tank", "Stachelschild verletzt Nahkämpfer; beim Tanken mit Mehrschaden rechnen", "Spiked shield hurts melee attackers; expect extra damage while tanking", "v" },
    { 9205, "tank", "Setzt seine Bedrohung zurück; Tank schnell zurückspotten", "Wipes his threat list; tank must taunt back fast" },
  },
  [5715] = { -- Hukku (Sunken Temple)
    { 12790, "adds", "Beschwört Dämonen; Begleiter töten", "Summons demon pets; kill the pets" },
    { 9081, "interrupt", "**Schattenblitzsalve** trifft die Gruppe; unterbrechen", "**Shadow Bolt Volley** hits the group; interrupt" },
    { 12279, "dispel", "**Fluch des Blutes** erhöht erlittenen Schaden; entfluchen", "**Curse of Blood** raises damage taken; decurse" },
  },
  [5716] = { -- Zul'Lor (Sunken Temple)
    { 15584, "positioning", "Spaltet nach vorn; nur der Tank steht vor ihm", "Cleaves in front; only the tank faces him" },
    { 12530, "dispel", "**Gebrechlichkeit** schwächt Spieler; entfluchen", "**Frailty** curse weakens players; decurse" },
  },
  [5717] = { -- Mijan (Sunken Temple)
    { 8362, "dispel", "**Erneuerung** heilt über Zeit; Magie vom Ziel bannen", "**Renew** heals over time; dispel magic from the target", "v" },
    { 8148, "survive", "**Dornenaura** schadet Nahkämpfern; durchheilen", "**Thorns Aura** hurts melee attackers; heal through", "v" },
    { 11899, "adds", "Stellt einen Heilungszauberschutz; sofort zerstören", "Drops a Healing Ward; destroy it right away" },
    { 12492, "interrupt", "Heilt mit **Welle der Heilung**; unterbrechen", "Heals with **Healing Wave**; interrupt" },
  },
  [5719] = { -- Morphaz (Sunken Temple)
    { 12884, "avoid", "**Säureatem** im Kegel; Tank dreht den Drachen weg", "**Acid Breath** cone; tank turns the dragon away" },
    { 12882, "positioning", "**Flügelschlag** stößt zurück; Tank an einer Wand", "**Wing Flap** knocks players back; tank near a wall" },
  },
  [5720] = { -- Weaver (Sunken Temple)
    { 12533, "avoid", "**Säureatem** im Kegel; Tank dreht den Drachen weg", "**Acid Breath** cone; tank turns the dragon away", "v" },
    { 12882, "positioning", "**Flügelschlag** stößt zurück; Tank an einer Wand", "**Wing Flap** knocks players back; tank near a wall", "v" },
  },
  [5721] = { -- Dreamscythe (Sunken Temple)
    { 12533, "avoid", "**Säureatem** im Kegel; Tank dreht den Drachen weg", "**Acid Breath** cone; tank turns the dragon away", "v" },
    { 12882, "positioning", "**Flügelschlag** stößt zurück; Tank an einer Wand", "**Wing Flap** knocks players back; tank near a wall", "v" },
  },
  [5722] = { -- Hazzas (Sunken Temple)
    { 12884, "avoid", "**Säureatem** im Kegel; Tank dreht den Drachen weg", "**Acid Breath** cone; tank turns the dragon away" },
    { 12882, "positioning", "**Flügelschlag** stößt zurück; Tank an einer Wand", "**Wing Flap** knocks players back; tank near a wall" },
  },
  [5761] = { -- Deviate Shambler (Wailing Caverns)
    { 7948, "dispel", "Heilt sich 20 Sek. lang: reinigen oder schnell töten", "Heals itself over 20 sec: purge it or burst it down" },
  },
  [5775] = { -- Verdan the Everliving (Wailing Caverns)
    { 8142, "positioning", "Ranken werfen Spieler in der Nähe um und fesseln sie: Fernkämpfer bleiben hinten", "Vines root and knock down nearby players: ranged stay back", "v" },
  },
  [6168] = { -- Roogug (Razorfen Kraul)
    { 8270, "adds", "Ruft einen Steingrollen; tanken oder töten", "Summons a Stone Rumbler; tank or kill it", "v" },
    { 9532, "interrupt", "Blitzschlag unterbrechen", "Interrupt Lightning Bolt", "v" },
  },
  [6207] = { -- Caverndeep Ambusher (Gnomeregan)
    { 7159, "positioning", "Meucheln von hinten: Gegner zum Tank drehen", "Backstabs players behind it: face it toward the tank", "v" },
  },
  [6212] = { -- Dark Iron Agent (Gnomeregan)
    { 11802, "avoid", "Legt Landminen (~450 Schaden); sofort töten, Minen meiden", "Drops land mines for ~450 damage; kill it at once, avoid mines" },
  },
  [6224] = { -- Leprous Machinesmith (Gnomeregan)
    { 10732, "adds", "**Überladung** beschleunigt nahe Bots; Schmied zuerst töten", "Supercharge speeds up nearby bots; kill the smith first" },
  },
  [6228] = { -- Dark Iron Ambassador (Gnomeregan)
    { 9053, "interrupt", "Feuerball unterbrechen", "Interrupt Fireball", "v" },
    { 10870, "adds", "Ruft brennende Diener; abfangen oder töten", "Summons fire servants; pick them up or kill them", "v" },
    { 184, "survive", "Feuerschild verletzt Nahkämpfer: Heiler achten auf Nahkämpfer", "Fire shield hurts melee attackers: healers watch melee health", "v" },
  },
  [6229] = { -- Crowd Pummeler 9-60 (Gnomeregan)
    { 8374, "positioning", "**Bogenschmettern** trifft vorne; nur der Tank steht davor", "Arcing Smash cleaves in front; only the tank faces him", "v" },
    { 10887, "avoid", "**Massenprügel** trifft alle in der Nähe; Fernkämpfer bleiben weg", "Crowd Pummel hits all nearby players; ranged stay out", "v" },
    { 5568, "positioning", "Trampeln trifft Spieler neben dem Tank: Nahkämpfer verteilen", "Trample hits players next to the tank: melee spread a bit", "v" },
  },
  [6232] = { -- Arcane Nullifier X-21 (Gnomeregan)
    { 10831, "avoid", "**Reflexionsfeld** wirft Zauber zurück; nicht zaubern, bis es verschwindet", "Reflection Field bounces spells back; stop casting until it fades" },
  },
  [6235] = { -- Electrocutioner 6000 (Gnomeregan)
    { 11085, "positioning", "Kettenblitz springt zwischen Spielern; verteilt stehen", "Chain Bolt jumps between players; spread out", "v" },
    { 11082, "survive", "**Megavolt** verursacht hohen Naturschaden; Leben hoch halten", "Megavolt deals heavy nature damage; keep health high", "v" },
    { 11084, "interrupt", "Schock auf einen Spieler: wenn möglich unterbrechen", "Shock on a player: interrupt when possible", "v" },
  },
  [6243] = { -- Gelihast (Blackfathom Deeps)
    { 6533, "tank", "Netz hält 2 Sek. lang fest; fliehende Murlocs laufen zu ihm, verlangsamen", "Nets a player for 2 sec; fleeing murlocs run to him, snare them", "v" },
  },
  [6329] = { -- Irradiated Pillager (Gnomeregan)
    { 9771, "interrupt", "**Strahlungsblitz** auf einen Spieler: unterbrechen", "Radiation bolt on a player: interrupt it", "v" },
    { 9798, "survive", "**Strahlung** schadet Spielern in der Nähe; gegenheilen oder wegziehen", "Radiation damages players near it; heal through or kite" },
  },
  [6426] = { -- Anguished Dead (Scarlet Monastery: Graveyard)
    { 7068, "dispel", "Fluch senkt erhaltene Heilung; Tank entfluchen", "Curse that cuts healing taken; decurse the tank" },
  },
  [6427] = { -- Haunting Phantasm (Scarlet Monastery: Graveyard)
    { 8986, "adds", "Beschwört Phantasmen; den Beschwörer schnell töten", "Spawns phantasm copies; kill the caster fast" },
  },
  [6487] = { -- Arcanist Doan (Scarlet Monastery: Library)
    { 9435, "avoid", "Bei halbem Leben Blase, dann **Detonation**; Sichtlinie brechen", "At half health he bubbles, then detonates; break line of sight", "v" },
    { 13323, "dispel", "Verwandelt Spieler in ein Schaf; Magie bannen", "Sheeps a player; dispel magic to free them", "v" },
    { 8988, "survive", "Flächenstille sperrt Zauberer; vorher heilen", "Area silence locks casters; heal before it lands", "v" },
    { 9438, "survive", "Macht ihn kurz immun: Schaden bis zum Ende zurückhalten", "Makes him immune for a moment: hold damage until it ends", "v" },
    { 9433, "avoid", "**Arkane Druckwelle** trifft alle in der Nähe: Nahkämpfer treten raus oder gegenheilen", "Arcane blast hits everyone close: melee step out or heal through", "v" },
  },
  [6906] = { -- The Lost Dwarves (Uldaman)
    { 15620, "adds", "Drei Zwerge zugleich; Baelog beschießt auch Fernkämpfer", "Three dwarves at once; Baelog also shoots casters at range", "v" },
    { 20252, "tank", "Erics **Abfangen** stürmt auf einen Spieler und betäubt 3 Sek.; ihn zuerst töten", "Eric's **Intercept** charges a player and stuns for 3 sec; kill him first", "v" },
    { 6268, "tank", "Eric stürmt auf einen Spieler, sein nächster Schlag trifft härter", "Eric charges a player and his next hit lands harder" },
    { 8242, "tank", "Olaf betäubt sein Ziel mit **Schildschlag** 2 Sek. lang", "Olaf stuns his target for 2 sec with **Shield Slam**" },
  },
  [6910] = { -- Revelosh (Uldaman)
    { 16033, "interrupt", "**Kettenblitz** unterbrechen, er springt zwischen nahen Spielern", "Kick his **Chain Lightning**, it jumps between grouped players", "v" },
    { 9532, "interrupt", "**Blitzschlag** unterbrechen, um den Schaden zu senken", "Interrupt **Lightning Bolt** to cut his damage", "v" },
  },
  [7022] = { -- Venomlash Scorpid (Uldaman)
    { 8257, "dispel", "**Giftstachel** wirkt 15 Sek. lang; Gift entfernen", "**Venom Sting** is a poison over 15 sec; cure poison" },
  },
  [7023] = { -- Obsidian Sentinel (Uldaman)
    { 10072, "adds", "Spaltet Obsidiansplitter ab; töten, jeder schwächt ihn", "Splits off Obsidian Shards; kill them, each one weakens him", "v" },
    { 10061, "adds", "Beschwört Obsidiansplitter: Begleiter schnell töten", "Summons obsidian shards: kill the adds quickly", "v" },
    { 9941, "avoid", "Kann Zauber zurückwerfen; Zauberer achten auf Schaden", "Can reflect spells; casters watch their damage" },
  },
  [7079] = { -- Viscous Fallout (Gnomeregan)
    { 21687, "dispel", "**Toxische Salve** vergiftet die Gruppe; Gift entfernen", "Toxic Volley poisons the whole group; cure poison" },
  },
  [7206] = { -- Ancient Stone Keeper (Uldaman)
    { 10094, "adds", "Beschwört 30 Sek. lang **Sandstürme**; aus dem Weg gehen", "Summons **Sand Storms** that fight for 30 sec; move away", "v" },
    { 10093, "avoid", "Der beschworene Sandsturm verstummt Spieler in der Nähe; Zauberer und Heiler halten Abstand", "The summoned Sand Storm silences nearby players; casters and healers keep their distance", "v" },
  },
  [7228] = { -- Ironaya (Uldaman)
    { 45, "survive", "**Kriegsdonner** betäubt alle in ihrer Nähe", "**War Stomp** stuns everyone close to her", "v" },
    { 8374, "positioning", "**Bogenschlag** trifft vorne; nur der Tank steht vor ihr", "**Arcing Smash** hits in front of her; only the tank faces her", "v" },
    { 18670, "tank", "**Wegschlagen** wirft den Tank zurück und senkt Bedrohung", "**Knock Away** throws the tank back and lowers threat", "v" },
  },
  [7246] = { -- Sandfury Shadowhunter (Zul'Farrak)
    { 11641, "dispel", "**Verhexen** verwandelt einen Spieler 6 Sek. lang in einen Frosch; bannen", "**Hex** turns a player into a frog for 6 sec; dispel", "v" },
  },
  [7247] = { -- Sandfury Soul Eater (Zul'Farrak)
    { 7154, "interrupt", "**Dunkle Opfergabe** heilt Verbündete; unterbrechen", "**Dark Offering** heals allies; interrupt it" },
    { 11016, "survive", "**Seelenbiss** entzieht Leben und Mana", "**Soul Bite** drains health and mana" },
  },
  [7267] = { -- Chief Ukorz Sandscalp (Zul'Farrak)
    { 11837, "positioning", "**Weiter Hieb** trifft vorne im Kegel; nur der Tank vorne", "**Wide Slash** hits a frontal cone; only the tank in front", "v" },
    { 15496, "positioning", "Spaltet; Nahkämpfer hinter ihm", "Cleaves; melee stay behind him", "v" },
    { 7366, "tank", "Er nimmt die **Berserkerhaltung** ein; härtere Treffer", "He takes **Berserker Stance**; expect harder hits", "v" },
    { 8269, "tank", "**Raserei** erhöht Angriffstempo und Schaden", "**Frenzy** raises his attack speed and damage" },
  },
  [7271] = { -- Witch Doctor Zum'rah (Zul'Farrak)
    { 11086, "adds", "Zauberschutz zerstören, er ruft alle 5 Sek. ein Skelett", "Destroy his ward, it spawns a skeleton every 5 sec", "v" },
    { 15245, "interrupt", "**Schattenblitzsalve** und **Welle der Heilung** unterbrechen", "Interrupt **Shadow Bolt Volley** and Healing Wave", "v" },
    { 12491, "interrupt", "Er heilt sich auch mit **Welle der Heilung**", "He also heals himself with **Healing Wave**", "v" },
    { 12739, "interrupt", "**Schattenblitz** wenn möglich unterbrechen", "Interrupt **Shadow Bolt** when possible", "v" },
    { 0, "adds", "Erweckt Zombies aus Gräbern; von den Gräbern wegziehen", "Raises zombies from graves; pull him away from them" },
  },
  [7272] = { -- Theka the Martyr (Zul'Farrak)
    { 8600, "dispel", "**Fiebrige Seuche** ist eine Krankheit; heilen oder unterbrechen", "**Fevered Plague** is a disease; cure it or interrupt", "v" },
    { 11089, "survive", "Bei wenig Leben immun gegen Körper- und Schattenschaden", "Low on health he turns immune to physical and shadow", "v" },
  },
  [7273] = { -- Gahz'rilla (Zul'Farrak)
    { 11902, "positioning", "Schlag stößt Spieler in der Nähe zurück; nicht am Rand stehen", "Slam knocks nearby players back; avoid ledges", "v" },
    { 11836, "survive", "**Festfrieren** betäubt und verursacht 6 Sek. lang Frostschaden", "**Freeze Solid** stuns and deals frost damage over 6 sec", "v" },
    { 11131, "survive", "**Eiszapfen** verlangsamt 10 Sek. lang um 50 %", "**Icicle** hits and slows by 50% for 10 sec", "v" },
  },
  [7274] = { -- Sandfury Executioner (Zul'Farrak)
    { 15496, "positioning", "Spaltet; Gruppe hinter ihm halten", "Cleaves; keep the group behind him" },
  },
  [7275] = { -- Shadowpriest Sezz'ziz (Zul'Farrak)
    { 12739, "interrupt", "**Schattenblitz** unterbrechen, wenn er nicht heilt", "Kick **Shadow Bolt** when no heal is being cast", "v" },
    { 8362, "dispel", "Seine **Erneuerung** bannen", "Dispel his **Renew** heal over time", "v" },
    { 13704, "survive", "**Psychischer Schrei** versetzt bis zu 5 Spieler in Furcht; keine Adds ziehen", "**Psychic Scream** fears up to 5 players; avoid pulling more" },
    { 12039, "interrupt", "Heilen unterbrechen; **Erneuerung** bannen", "Interrupt **Heal**; dispel his Renew" },
  },
  [7291] = { -- Galgann Firehammer (Uldaman)
    { 11970, "survive", "**Feuernova** trifft alle um ihn; Nahkämpfer brauchen Heilung", "**Fire Nova** burns everyone around him; melee needs heals", "v" },
    { 3356, "dispel", "**Flammenpeitsche** stapelt erhöhten Feuerschaden; heilen", "**Flame Lash** stacks fire damage taken; tank swap or heal", "v" },
    { 15039, "dispel", "**Flammenschock** brennt einen Spieler: bannen oder gegenheilen", "**Flame shock** burns a player: dispel or heal through", "v" },
    { 9482, "dispel", "**Flammen verstärken** erhöht Feuerschaden: Magie bannen", "**Amplify flames** raises fire damage taken: dispel magic", "v" },
    { 0, "interrupt", "**Flammenstachel** der Geologen-Wachen unterbrechen", "Interrupt his Geologist guards' **Flame Spike**" },
  },
  [7328] = { -- Withered Reaver (Razorfen Downs)
    { 11427, "positioning", "Spaltet; nur der Tank vorne", "Cleaves; only the tank in front" },
  },
  [7332] = { -- Withered Spearhide (Razorfen Downs)
    { 11397, "dispel", "**Krankheitsschuss** auf Spieler: Krankheit heilen", "Diseased shot on a player: cure the disease", "v" },
  },
  [7335] = { -- Death's Head Geomancer (Razorfen Downs)
    { 9053, "interrupt", "Zauberer mit **Feuerball** und Verlangsamen; unterbrechen", "Caster with **Fireball** and Slow; interrupt" },
  },
  [7337] = { -- Death's Head Necromancer (Razorfen Downs)
    { 12420, "adds", "Beschwört Skelett; Beschwörer zuerst töten", "Summons a skeleton; kill the caster first", "v" },
    { 11443, "dispel", "Fluch verlangsamt und schwächt; entfluchen", "Curse slows and weakens; decurse", "v" },
  },
  [7341] = { -- Skeletal Frostweaver (Razorfen Downs)
    { 15043, "interrupt", "**Frostblitz** auf einen Spieler: unterbrechen", "**Frostbolt** on a player: interrupt it", "v" },
  },
  [7342] = { -- Skeletal Summoner (Razorfen Downs)
    { 0, "interrupt", "Unterbrechen, sonst kommen Schattenwirker", "Interrupt or it summons shadowcaster adds" },
  },
  [7351] = { -- Tomb Reaver (Razorfen Downs)
    { 745, "dispel", "Fesselt einen Spieler in einem Netz: bannen oder schnell töten", "Webs a player in place: dispel or kill quickly", "v" },
  },
  [7352] = { -- Frozen Soul (Razorfen Downs)
    { 12528, "survive", "Banshee bringt Zauberer zum Schweigen; schnell töten", "Banshee that silences casters; kill fast" },
  },
  [7353] = { -- Freezing Spirit (Razorfen Downs)
    { 15532, "avoid", "**Frostnova** friert Spieler in der Nähe ein: Fernkämpfer auf Abstand", "**Frost nova** roots nearby players: ranged keep distance", "v" },
  },
  [7355] = { -- Tuten'kash (Razorfen Downs)
    { 12252, "survive", "Fesselt Spieler im Netz; Heiler auf Abstand", "Webs players in place; healer keep range", "v" },
    { 12251, "dispel", "Gift-DoT; Gift entfernen", "Poison DoT; cure poison", "v" },
    { 12255, "dispel", "Fluch auf Spielern; entfluchen", "Curse on players; decurse it", "v" },
  },
  [7356] = { -- Plaguemaw the Rotting (Razorfen Downs)
    { 12946, "survive", "Gestankaura schadet der Gruppe; schnell töten", "Stench aura hurts the group; burn him fast", "v" },
    { 11442, "dispel", "Krankheit schwächt Spieler; Krankheit heilen", "Disease weakens players; cure disease" },
  },
  [7357] = { -- Mordresh Fire Eye (Razorfen Downs)
    { 12466, "interrupt", "Starker **Feuerball**; unterbrechen", "Hard-hitting **Fireball**; interrupt it", "v" },
    { 12470, "positioning", "**Feuerstoß** in seiner Nähe; Zauberer bleiben weg", "Fire burst near him; casters stay back", "v" },
  },
  [7358] = { -- Amnennar the Coldbringer (Razorfen Downs)
    { 13009, "survive", "Frost-Flächenpuls auf Gruppe; gegenheilen", "Frost AoE pulse on the group; heal through it", "v" },
    { 12642, "adds", "Beschwört Frostgespenster; AoE oder tanken", "Summons frost spectres; AoE or tank them", "v" },
    { 15531, "survive", "Friert Nahkämpfer fest; vorbereitet sein", "Roots nearby players; melee stay ready", "v" },
    { 15530, "interrupt", "**Frostblitz** auf einen Spieler: wenn möglich unterbrechen", "**Frostbolt** on a player: interrupt when possible", "v" },
  },
  [7361] = { -- Grubbis (Gnomeregan)
    { 12057, "tank", "Stoß verursacht Tankschaden; Chomper kämpft an seiner Seite", "Strike adds burst damage on the tank; Chomper fights beside him" },
  },
  [7604] = { -- Sergeant Bly (Zul'Farrak)
    { 11972, "interrupt", "**Schildhieb** unterbricht Zauberer: aus der Distanz heilen", "**Shield bash** interrupts casters: heal from range", "v" },
    { 12170, "tank", "**Rache** folgt auf Blocken, Ausweichen oder Parieren; kleiner Tankschaden", "**Revenge** follows a block, dodge or parry; tank takes small hits", "v" },
  },
  [7795] = { -- Hydromancer Velratha (Zul'Farrak)
    { 12491, "interrupt", "**Welle der Heilung** unterbrechen", "Interrupt **Healing Wave**", "v" },
    { 12739, "interrupt", "**Schattenblitz** unterbrechen", "Interrupt **Shadow Bolt**", "v" },
    { 15245, "interrupt", "**Schattenblitzsalve** unterbrechen", "Interrupt **Shadow Bolt Volley**", "v" },
    { 11086, "adds", "Zauberschutz zerstören, er ruft Skelette", "Destroy her ward, it spawns skeletons", "v" },
    { 0, "interrupt", "**Wasserblitz** unterbrechen, um Frostschaden zu senken", "Interrupt **Water Bolt** to reduce frost damage" },
  },
  [7796] = { -- Nekrum Gutchewer (Zul'Farrak)
    { 8600, "dispel", "**Fiebrige Seuche**; Krankheit heilen oder unterbrechen", "**Fevered Plague** disease; cure it or interrupt", "v" },
    { 15537, "interrupt", "Wirkt **Schattenblitz**; unterbrechen", "Casts **Shadow Bolt**; interrupt it", "v" },
  },
  [7797] = { -- Ruuzlu (Zul'Farrak)
    { 0, "positioning", "Spaltet auch Nachbarn des Tanks; hinter ihm stehen", "Cleaves the tank's neighbour; stand behind" },
    { 0, "tank", "**Hinrichten** unter 20 % Leben; Tank voll halten", "Executes targets under 20% health; keep the tank topped" },
  },
  [7800] = { -- Mekgineer Thermaplugg (Gnomeregan)
    { 11130, "tank", "Schlägt den Tank weg: mit dem Rücken zur Wand tanken", "Knocks the tank away: tank with the back to a wall", "v" },
    { 0, "adds", "Bombenmaschinen schicken Laufbomben; Knöpfe drücken stoppt sie", "Bomb machines send homing bombs; press their buttons to stop them" },
  },
  [7849] = { -- Mobile Alert System (Gnomeregan)
    { 0, "adds", "Ruft Elite-Wächter, wenn es nicht schnell zerstört wird", "Calls elite Mechanized Guardians if not destroyed fast" },
  },
  [8095] = { -- Sul'lithuz Sandcrawler (Zul'Farrak)
    { 11020, "survive", "**Versteinern** betäubt einen Spieler 3 Sek. lang", "**Petrify** stuns a player for 3 sec" },
  },
  [8127] = { -- Antu'sul (Zul'Farrak)
    { 11894, "adds", "Bei 75 % und 25 % kommen Basilisken, die versteinern", "At 75% and 25% basilisk servants join; they petrify", "v" },
    { 11895, "interrupt", "Seine Selbstheilung unterbrechen", "Interrupt his self heal", "v" },
    { 8376, "adds", "Das Totem hält Spieler in der Nähe fest; Nahkämpfer zerstören es", "The totem roots nearby players; melee burn it down", "v" },
    { 10915, "interrupt", "Seine **Blitzheilung** unterbrechen", "Interrupt his **Flash Heal**", "v" },
    { 2860, "positioning", "**Kettenblitzschlag** springt zwischen Spielern; verteilen", "**Chain Lightning** jumps between players; spread out", "v" },
    { 10413, "interrupt", "**Erdschock** sperrt eine Zauberschule; Zauberwirker nicht bündeln", "**Earth Shock** locks a spell school; keep casters apart", "v" },
    { 0, "adds", "Heilungszauberschutz und Erdgriff-Totem schnell zerstören", "Kill his Healing Ward and Earthgrab Totem fast" },
  },
  [8336] = { -- Hakkari Sapper (Sunken Temple)
    { 11981, "interrupt", "**Manabrand** entzieht Zauberern Mana; unterbrechen", "**Mana Burn** drains casters; interrupt" },
  },
  [8443] = { -- Avatar of Hakkar (Sunken Temple)
    { 12888, "survive", "**Wahnsinn verursachen** übernimmt einen Spieler; kontrollieren", "**Cause Insanity** takes control of a player; CC them", "v" },
    { 12889, "dispel", "**Fluch der Sprachen** verlangsamt Zauber; entfluchen", "**Curse of Tongues** slows casting; decurse", "v" },
    { 25852, "positioning", "**Peitschen** schleudert zurück: an der Wand tanken", "**Lash** knocks players back: tank against a wall", "v" },
  },
  [8497] = { -- Nightmare Suppressor (Sunken Temple)
    { 11672, "dispel", "**Verderbnis** als Schaden über Zeit; bannen", "**Corruption** damage over time; dispel" },
  },
  [8567] = { -- Glutton (Razorfen Downs)
    { 12795, "tank", "Raserei bei wenig Leben; Tank-Abklingzeiten bereit", "Frenzies at low health; tank cooldowns ready", "v" },
    { 12627, "survive", "Krankheitswolke um ihn; Krankheit heilen", "Disease cloud around him; cure disease", "v" },
  },
  [8580] = { -- Atal'alarion (Sunken Temple)
    { 12887, "positioning", "**Fegender Schlag** stößt Spieler vor ihm zurück; Nahkampf hinter ihn", "**Sweeping Slam** knocks back players in front; melee behind", "v" },
    { 6524, "survive", "**Erdbeben** betäubt Spieler in seiner Nähe", "**Ground Tremor** stuns players close to him" },
  },
  [8894] = { -- Anvilrage Medic (Blackrock Depths)
    { 0, "interrupt", "Heilt einzelne Ziele und Gruppen; unterbrechen, zuerst töten", "Heals single targets and groups; interrupt and kill first" },
  },
  [8900] = { -- Doomforge Arcanasmith (Blackrock Depths)
    { 13745, "avoid", "Arkanstoß auf alle in Nahkampfreichweite", "Arcane burst on everyone in melee range" },
  },
  [8906] = { -- Ragereaver Golem (Blackrock Depths)
    { 12795, "tank", "Raserei: mehr Schaden und Angriffstempo", "Frenzies for more damage and attack speed" },
  },
  [8908] = { -- Molten War Golem (Blackrock Depths)
    { 15570, "dispel", "Feuerschaden über Zeit; Magie bannen", "Fire damage over time; dispel magic" },
  },
  [8911] = { -- Fireguard Destroyer (Blackrock Depths)
    { 0, "survive", "Feuersalve trifft alle in der Nähe; Feuerwiderstand hilft", "Fire volley hits everyone nearby; fire resist helps" },
  },
  [8912] = { -- Twilight's Hammer Torturer (Blackrock Depths)
    { 14032, "dispel", "18 Sek. lang Schattenschaden; Magie bannen", "Shadow damage over 18 sec; dispel magic", "v" },
    { 13619, "dispel", "Schmerzhafter Schaden über Zeit; entfernen", "Painful damage over time; remove it" },
  },
  [8913] = { -- Twilight Emissary (Blackrock Depths)
    { 15063, "positioning", "Fesselt Spieler in der Nähe", "Roots nearby players in place" },
    { 15288, "interrupt", "Starker Feuerzauber; unterbrechen", "Strong fire spell; interrupt it" },
  },
  [8922] = { -- Bloodhound Mastiff (Blackrock Depths)
    { 15608, "adds", "Hunde kommen im Rudel und patrouillieren; vorsichtig ziehen", "Hounds come in packs and patrol; pull carefully" },
    { 7140, "tank", "Senkt die Rüstung des Ziels", "Lowers the target's armor" },
  },
  [8923] = { -- Panzor the Invincible (Blackrock Depths)
    { 9941, "positioning", "Schild kann Zauber zurückwerfen; Zauberer aufpassen", "Shield that can reflect spells; casters be careful", "v" },
  },
  [8929] = { -- Princess Moira Bronzebeard (Blackrock Depths)
    { 15586, "interrupt", "Heilt den Imperator; unterbrechen oder kontrollieren", "Heals the emperor; interrupt or crowd control her", "v" },
    { 15587, "survive", "Schattenzauber auf einen Spieler", "Shadow nuke on one player", "v" },
    { 10929, "dispel", "Heilung über Zeit auf den Imperator; bannen", "Heal over time on the emperor; dispel it", "v" },
    { 10901, "dispel", "Schild auf einen Verbündeten absorbiert Schaden; reinigen", "Shield on an ally that absorbs damage; purge it", "v" },
    { 15654, "dispel", "18 Sek. lang Schattenschaden auf einem Spieler; Magie bannen", "Shadow damage over 18 sec on one player; dispel magic", "v" },
    { 10934, "survive", "Heiligschaden auf einen Spieler", "Holy damage on one player", "v" },
    { 15537, "interrupt", "Schattenblitz auf einen Spieler; wenn möglich unterbrechen", "Shadow bolt on one player; interrupt when you can", "v" },
  },
  [8983] = { -- Golem Lord Argelmach (Blackrock Depths)
    { 15305, "interrupt", "Blitz springt auf bis zu 5 Spieler; verteilen, unterbrechen", "Lightning jumps up to 5 players; spread and interrupt", "v" },
    { 15507, "positioning", "**Blitzschlagschild** schadet Nahkämpfern: Nahkämpfer auf ihr Leben achten", "**Lightning shield** hurts melee attackers: melee watch their health", "v" },
    { 15605, "interrupt", "Schock auf einen Spieler: wenn möglich unterbrechen", "Shock on a player: interrupt when possible", "v" },
    { 0, "adds", "Zwei Golemwachen helfen; er läuft und zieht Gegner mit", "Two golem guards join; he runs and pulls uncleared mobs" },
  },
  [9016] = { -- Bael'Gar (Blackrock Depths)
    { 13895, "adds", "Ruft Feuerbrut mit Feuerstoß herbei", "Summons fire spawns with a burst of fire damage", "v" },
    { 13880, "tank", "Feuertreffer, danach 24 Sek. lang Brennschaden am Ziel", "Fire hit plus a burn over 24 sec on the target", "v" },
  },
  [9017] = { -- Lord Incendius (Blackrock Depths)
    { 13899, "avoid", "**Flammensäule** hinterlässt 30 Sek. Feuerboden; rausgehen", "Flame pillar leaves burning ground for 30 sec; move out", "v" },
    { 14099, "positioning", "Stößt den Tank zurück; Rücken nicht zur Lava", "Knocks the tank back; keep his back away from lava", "v" },
    { 13900, "avoid", "Feuerstoß auf ein Gebiet; herausgehen", "Fire burst on a marked area; step out", "v" },
    { 26977, "dispel", "Senkt den Feuerwiderstand 1 Min. lang um 100; entfluchen", "Cuts fire resistance by 100 for 1 min; decurse", "v" },
  },
  [9018] = { -- High Interrogator Gerstahn (Blackrock Depths)
    { 13704, "survive", "Versetzt bis zu 5 Spieler in der Nähe 6 Sek. lang in Furcht; Zusatzgruppen meiden", "Fears up to 5 nearby players for 6 sec; watch for extra pulls", "v" },
    { 14033, "interrupt", "Verbrennt viel Mana eines Zauberers; unterbrechen", "Burns a lot of mana from one caster; interrupt it", "v" },
    { 12040, "dispel", "Schild absorbiert Schaden; reinigen oder wegschlagen", "Self shield that absorbs damage; purge or burn it down", "v" },
    { 14032, "dispel", "18 Sek. lang Schattenschaden auf einem Spieler; Magie bannen", "Shadow damage over 18 sec on one player; dispel magic", "v" },
  },
  [9019] = { -- Emperor Dagran Thaurissan (Blackrock Depths)
    { 15636, "survive", "10 Sek. lang immun gegen Magie; Treffer verursachen Feuerschaden", "Immune to magic for 10 sec, melee hits add fire", "v" },
    { 17492, "dispel", "Feuertreffer betäubt einen Spieler 5 Sek. lang", "Fire hit that stuns a player for 5 sec", "v" },
    { 15642, "tank", "Beschwört eine Waffe, die dem Tank zusätzliche Schläge zufügt", "Summons a weapon that adds extra strikes on the tank", "v" },
    { 0, "positioning", "Ob Moira verschont wird, ändert die Belohnung", "Keep Moira alive (or not) - killing her changes rewards" },
  },
  [9024] = { -- Pyromancer Loregrain (Blackrock Depths)
    { 15038, "adds", "Setzt ein Feuertotem, das angreift; schnell zerstören", "Drops a fire totem that attacks; kill it quickly", "v" },
    { 15041, "dispel", "Schild absorbiert 1 Min. lang Feuerschaden; reinigen", "Shield that absorbs fire damage for 1 min; purge it", "v" },
    { 15095, "interrupt", "Feuerzauber auf einen Spieler; unterbrechen", "Fire nuke on one player; interrupt it", "v" },
    { 15616, "dispel", "Feuerschock mit Brand auf einem Spieler: bannen oder gegenheilen", "Fire shock plus burn on a player: dispel or heal through", "v" },
  },
  [9025] = { -- Lord Roccor (Blackrock Depths)
    { 6524, "positioning", "Betäubt alle im 20-m-Umkreis 2 Sek. lang; Fernkämpfer auf Abstand", "Stuns everyone within 20 yards for 2 sec; ranged stay at distance", "v" },
    { 13729, "dispel", "Feuertreffer, danach 12 Sek. lang Brennschaden auf einem Spieler", "Fire hit plus a burn over 12 sec on one player", "v" },
    { 13728, "interrupt", "Naturschock auf einen Spieler: wenn möglich unterbrechen", "Nature shock on a player: interrupt when you can", "v" },
  },
  [9027] = { -- Gorosh the Dervish (Blackrock Depths)
    { 16856, "tank", "**Harter Schlag**, halbiert 5 Sek. lang die Heilung am Tank", "Heavy hit that halves healing on the tank for 5 sec", "v" },
    { 21049, "dispel", "Erhöht 30 Sek. lang sein Angriffstempo; reinigen", "Speeds up his attacks for 30 sec; purge it", "v" },
    { 13736, "avoid", "Wirbelt und trifft alle in 8 m; Nahkämpfer raus", "Spins and hits all within 8 yards; melee step out" },
  },
  [9028] = { -- Grizzle (Blackrock Depths)
    { 8269, "tank", "Greift unter 50 % Leben viel schneller an", "Attacks much faster below 50% health", "v" },
    { 15579, "tank", "Trifft den Tank und bis zu zwei weitere Ziele daneben; verteilen", "Hits the tank and up to two more targets next to him; spread out", "v" },
    { 6524, "positioning", "Kurze Flächenbetäubung im 20-m-Umkreis", "Short AoE stun within 20 yards" },
  },
  [9029] = { -- Eviscerator (Blackrock Depths)
    { 7121, "positioning", "6 Sek. lang immun gegen Magie; Zauberer warten, Nahkampf weiter", "Immune to magic for 6 sec; casters pause, melee keep going", "v" },
    { 15245, "survive", "Schattenschaden auf alle im 30-m-Umkreis", "Shadow damage on everyone within 30 yards", "v" },
    { 16095, "dispel", "15 Sek. lang Blutung auf einem Spieler; gegenheilen", "Bleed on one player for 15 sec; heal through it", "v" },
  },
  [9030] = { -- Ok'thor the Breaker (Blackrock Depths)
    { 13747, "dispel", "Verlangsamt Angriffs-, Zauber- und Lauftempo im 20-m-Umkreis", "Slows attacks, casts and movement within 20 yards", "v" },
    { 15453, "avoid", "Arkanstoß auf alle im 30-m-Umkreis", "Arcane burst on everyone within 30 yards", "v" },
    { 25055, "interrupt", "Arkanblitz auf einen Spieler; unterbrechen", "Arcane bolt on one player; interrupt it", "v" },
    { 13323, "dispel", "Verwandelt einen Spieler 6 Sek. lang in ein Schaf", "Turns a player into a sheep for 6 sec" },
  },
  [9031] = { -- Anub'shiah (Blackrock Depths)
    { 15470, "dispel", "Zauberer im 30-m-Umkreis wirken 50 % langsamer; entfluchen", "Casters in 30 yards cast 50% slower; decurse", "v" },
    { 15471, "survive", "Wurzelt einen Spieler und bringt ihn 4 Sek. lang zum Schweigen", "Roots and silences one player for 4 sec", "v" },
    { 8994, "survive", "Nimmt einen Spieler eine Weile aus dem Kampf", "Removes one player from the fight for a while", "v" },
    { 15472, "interrupt", "Schattenblitz auf einen Spieler; wenn möglich unterbrechen", "Shadow bolt on one player; interrupt when you can", "v" },
    { 12493, "dispel", "Senkt 2 Min. lang den körperlichen Schaden eines Spielers; entfluchen", "Cuts a player's physical damage for 2 min; decurse", "v" },
    { 13787, "dispel", "Rüstungsbonus auf sich selbst, 30 Min.; reinigen", "Self armor buff for 30 min; purge it", "v" },
  },
  [9032] = { -- Hedrum the Creeper (Blackrock Depths)
    { 3609, "dispel", "Gift betäubt einen Spieler; Gift entfernen", "Poison that stuns one player; cure poison", "v" },
    { 15474, "survive", "Fesselt alle im 30-m-Umkreis 5 Sek. lang", "Roots everyone within 30 yards for 5 sec", "v" },
    { 15475, "dispel", "Gift auf Spieler in der Nähe, 2 Min.; Gift entfernen", "Poison on nearby players for 2 min; cure it", "v" },
  },
  [9033] = { -- General Angerforge (Blackrock Depths)
    { 15572, "tank", "Stapelt Rüstungsverringerung auf dem Tank", "Stacks armor reduction on the tank", "v" },
    { 0, "adds", "Ruft bei ca. 40 % Leben Wachen und Sanitäter", "Calls a wave of guards and medics at about 40% health" },
  },
  [9034] = { -- Hate'rel (Blackrock Depths)
    { 14033, "interrupt", "Verbrennt Mana eines Zauberers; unterbrechen", "Burns mana from one caster; interrupt it", "v" },
    { 15232, "interrupt", "Schattenblitz auf einen Spieler; wenn möglich unterbrechen", "Shadow bolt on one player; interrupt when you can", "v" },
    { 12040, "dispel", "Schwacher Schadensschild; reinigen oder ignorieren", "Weak damage shield; purge or ignore", "v" },
  },
  [9035] = { -- Anger'rel (Blackrock Depths)
    { 12169, "tank", "Blockt kurz einen Angriff", "Briefly blocks one attack", "v" },
    { 15062, "tank", "Erleidet 10 Sek. lang 75 % weniger Schaden; abwarten", "Takes 75% less damage for 10 sec; wait it out", "v" },
    { 11971, "tank", "Stapelt Rüstungsverringerung auf dem Tank", "Stacks armor reduction on the tank", "v" },
  },
  [9036] = { -- Vile'rel (Blackrock Depths)
    { 15586, "interrupt", "Heilt einen Verbündeten; unterbrechen", "Heals an ally; interrupt it", "v" },
    { 15587, "survive", "Schattenzauber auf einen Spieler", "Shadow nuke on one player", "v" },
    { 11974, "dispel", "Schild auf einen Verbündeten absorbiert Schaden; reinigen", "Shield on an ally that absorbs damage; purge it", "v" },
  },
  [9037] = { -- Gloom'rel (Blackrock Depths)
    { 15584, "tank", "Trifft den Tank und bis zu zwei weitere Ziele daneben", "Hits the tank and up to two more targets next to him", "v" },
    { 9080, "dispel", "Verlangsamt einen Spieler 10 Sek. lang um 60 %", "Slows one player by 60% for 10 sec", "v" },
    { 13737, "tank", "Harter Schlag, halbiert 5 Sek. lang die Heilung am Tank", "Heavy hit that halves healing on the tank for 5 sec", "v" },
    { 13847, "tank", "Kämpft eine Weile rücksichtslos; Tank gleichmäßig heilen", "Fights recklessly for a while; heal the tank steadily", "v" },
  },
  [9038] = { -- Seeth'rel (Blackrock Depths)
    { 15244, "avoid", "Frostkegel vor ihm, verlangsamt; nicht hineinstehen", "Frost cone in front of him that slows; stay out of it", "v" },
    { 12544, "dispel", "Frostrüstung verlangsamt Nahkämpfer; reinigen", "Frost armor slows melee attackers; purge it", "v" },
    { 12674, "positioning", "Frostschaden und fesselt Spieler in der Nähe bis zu 8 Sek.", "Frost damage and roots nearby players up to 8 sec", "v" },
    { 15044, "dispel", "Schild absorbiert 1 Min. lang Frostschaden; reinigen", "Shield that absorbs frost damage for 1 min; purge it", "v" },
    { 12675, "interrupt", "Frostblitz mit Verlangsamung; unterbrechen", "Frost bolt that slows; interrupt", "v" },
  },
  [9039] = { -- The Seven (Blackrock Depths)
    { 15245, "interrupt", "Doom'rel wirkt Schattensalve und ruft Leerwandler", "Doom'rel casts a shadow volley and summons voidwalkers", "v" },
    { 15092, "adds", "Ruft Leerwandler zu Hilfe; töten", "Calls voidwalkers to help; kill them", "v" },
    { 8994, "survive", "Nimmt einen Spieler bis zu 15 Sek. aus dem Kampf", "Removes one player from the fight for up to 15 sec", "v" },
    { 12742, "dispel", "21 Sek. lang Feuerschaden; Magie bannen", "Fire damage over 21 sec; dispel magic", "v" },
    { 12493, "dispel", "Senkt 2 Min. lang den körperlichen Schaden; entfluchen", "Cuts physical damage for 2 min; decurse", "v" },
    { 13787, "dispel", "Rüstungsbonus auf sich selbst; reinigen", "Self armor buff; purge it", "v" },
    { 0, "adds", "Sieben Zwerge greifen nacheinander an; zuletzt Doom'rel", "Seven dwarves attack one after another; last one is Doom'rel" },
  },
  [9040] = { -- Dope'rel (Blackrock Depths)
    { 15582, "tank", "Trifft von hinten hart; ihn zum Tank gedreht halten", "Hits hard from behind; keep him facing the tank", "v" },
    { 15087, "tank", "Weicht 15 Sek. lang häufiger aus", "Dodges more attacks for 15 sec", "v" },
    { 12540, "survive", "Betäubt das Ziel bis zu 4 Sek.", "Stuns the target up to 4 sec", "v" },
    { 15583, "dispel", "10 Sek. lang Blutung; gegenheilen", "Bleed over 10 sec; heal through it", "v" },
    { 15581, "tank", "Zusätzlicher Nahkampftreffer auf den Tank", "Extra melee hit on the tank", "v" },
  },
  [9041] = { -- Warder Stilgiss (Blackrock Depths)
    { 12674, "positioning", "Verursacht Frostschaden und fesselt Spieler in der Nähe bis zu 8 Sek. lang", "Frost damage and roots nearby players up to 8 sec", "v" },
    { 12675, "interrupt", "Frostblitz mit Verlangsamung; unterbrechen", "Frost bolt that slows; interrupt", "v" },
    { 12544, "dispel", "Frostrüstung verlangsamt Nahkämpfer; reinigen", "Frost armor slows melee attackers; purge it", "v" },
    { 15044, "dispel", "Schild absorbiert 1 Min. lang Frostschaden; reinigen", "Shield that absorbs frost damage for 1 min; purge it", "v" },
    { 15042, "dispel", "Sein Hund Verek verflucht: mehr erlittener körperlicher Schaden", "His dog Verek curses targets to take more physical damage" },
  },
  [9042] = { -- Verek (Blackrock Depths)
    { 15042, "dispel", "Verflucht ein Ziel: mehr erlittener körperlicher Schaden; entfluchen", "Curses a target to take more physical damage; decurse", "v" },
  },
  [9056] = { -- Fineous Darkvire (Blackrock Depths)
    { 15493, "interrupt", "Heilt sich oder Verbündete; Zauber unterbrechen", "Heals himself or allies; interrupt the cast", "v" },
    { 13953, "tank", "**Heiliger Stoß** trifft den Tank hart: gleichmäßig heilen", "**Holy strike** hits the tank hard: keep healing steady", "v" },
    { 8258, "dispel", "Rüstungsaura auf ihn und Verbündete; reinigen", "Armor aura on himself and allies; purge it", "v" },
    { 15346, "dispel", "Siegel, das den Träger bei jedem Treffer heilt; bannen", "Seal that heals the bearer on each strike; dispel it", "v" },
    { 11978, "tank", "Tritt Zauberer neben ihm: Heiler halten Abstand", "Kicks casters next to him: healers keep their distance", "v" },
    { 0, "adds", "Wenig Schaden, viel Leben; zuerst seine Helfer töten", "Low damage, lots of health; kill his helpers first" },
  },
  [9096] = { -- Rage Talon Dragonspawn (Upper Blackrock Spire)
    { 12021, "positioning", "Fixiert einen zufälligen Spieler: dieser läuft weg, Rest tötet ihn", "Fixates a random player: that player kites, others kill it", "v" },
  },
  [9098] = { -- Scarshield Spellbinder (Lower Blackrock Spire)
    { 14033, "interrupt", "Verbrennt Mana; unterbrechen", "Burns mana of casters; interrupt" },
  },
  [9156] = { -- Ambassador Flamelash (Blackrock Depths)
    { 13489, "adds", "Geister laufen von den Runen zu ihm und stärken ihn; töten", "Spirits run to him from the runes; each one buffs him, kill them", "v" },
  },
  [9196] = { -- Highlord Omokk (Lower Blackrock Spire)
    { 18945, "positioning", "Tank mit dem Rücken zur Wand, sonst wird er in Adds geschleudert", "Tank with back to a wall to avoid being knocked into adds", "v" },
    { 8269, "tank", "Wütend: schlägt viel härter; Abklingzeiten aufheben", "Hits much harder when enraged; save cooldowns", "v" },
    { 5532, "positioning", "Spaltet nach vorn: nur der Tank steht vorne", "Cleaves the front: only the tank stands in front", "v" },
  },
  [9198] = { -- Spirestone Mystic (Lower Blackrock Spire)
    { 15982, "interrupt", "Heilt andere Oger; unterbrechen oder zuerst töten", "Heals other ogres; interrupt or kill first" },
  },
  [9201] = { -- Spirestone Ogre Magus (Lower Blackrock Spire)
    { 15979, "interrupt", "Arkansalve trifft die Gruppe; unterbrechen", "Arcane volley hits the group; interrupt" },
  },
  [9217] = { -- Spirestone Lord Magus (Lower Blackrock Spire)
    { 13323, "dispel", "Verwandelt Spieler in ein Schaf; Verwandlung bannen", "Sheeps a player; dispel the polymorph" },
    { 16170, "dispel", "Beschleunigt einen Oger; reinigen oder Magus zuerst töten", "Hastes an ally ogre; purge or kill him first" },
  },
  [9236] = { -- Shadow Hunter Vosh'gajin (Lower Blackrock Spire)
    { 22566, "dispel", "Verwandelt Spieler in der Nähe in Frösche; bannen", "Turns nearby players into frogs; dispel or wait it out", "v" },
    { 8282, "dispel", "Fluch erhöht erlittenen Schaden; Tank entfluchen", "Curse raises physical damage taken; decurse the tank", "v" },
  },
  [9237] = { -- War Master Voone (Lower Blackrock Spire)
    { 5532, "positioning", "Frontaler Spalter; nur der Tank steht vor ihm", "Frontal cleave; only the tank in front of him", "v" },
    { 16075, "survive", "Wirft eine Axt auf einen zufälligen Spieler, kurze Betäubung", "Throws an axe at a random player and stuns briefly", "v" },
    { 15708, "tank", "Halbiert kurz die Heilung am Tank; durchheilen", "Cuts healing on the tank by half for a few seconds; heal through it", "v" },
    { 10966, "positioning", "Harter Treffer mit Rückstoß; Tank mit dem Rücken zur Wand", "Hard hit that knocks the target back; tank with back to a wall", "v" },
    { 15618, "survive", "Kurze Betäubung seines Ziels", "Short stun on his target", "v" },
    { 15615, "survive", "Unterbricht einen Zauber; Zauberer außer Reichweite", "Interrupts a spell; casters stay out of his reach", "v" },
    { 3391, "tank", "Extra-Angriffe; Schadensspitzen am Tank", "Gains extra attacks; damage spikes on the tank", "v" },
  },
  [9240] = { -- Smolderthorn Shadow Priest (Lower Blackrock Spire)
    { 11641, "dispel", "Verwandelt Spieler in einen Frosch; bannen", "Turns a player into a frog; dispel" },
    { 14033, "interrupt", "Entzieht Mana; unterbrechen", "Drains caster mana; interrupt" },
  },
  [9257] = { -- Scarshield Warlock (Lower Blackrock Spire)
    { 15125, "interrupt", "Öffnet Portal mit Dämonen; schnell töten", "Opens a portal that spawns demons; kill or stop him" },
  },
  [9258] = { -- Scarshield Raider (Lower Blackrock Spire)
    { 14030, "survive", "Fesselt Spieler 3 Sek. lang im Netz", "Roots a player in a net for 3 sec" },
  },
  [9262] = { -- Firebrand Invoker (Lower Blackrock Spire)
    { 11921, "interrupt", "Starker Feuerball; unterbrechen oder kontrolliert halten", "Strong fire bolt; interrupt or keep him crowd controlled", "v" },
    { 11829, "avoid", "Flächenfeuer an einer Stelle; aus den Flammen laufen", "Fire area damage at a spot; step out of the flames", "v" },
    { 15128, "survive", "Markiert Ziele für mehr Feuerschaden", "Marks targets to take more fire damage", "v" },
  },
  [9263] = { -- Firebrand Dreadweaver (Lower Blackrock Spire)
    { 16071, "dispel", "Fluch mit Feuerschaden; entfluchen", "Fire damage curse; decurse" },
  },
  [9264] = { -- Firebrand Pyromancer (Lower Blackrock Spire)
    { 15128, "survive", "Markiert Ziele für mehr Feuerschaden", "Marks targets to take more fire damage", "v" },
  },
  [9266] = { -- Smolderthorn Witch Doctor (Lower Blackrock Spire)
    { 15869, "adds", "Stellt Heilzauberschutz auf; Totem zerstören", "Drops a healing ward; destroy the totem" },
  },
  [9319] = { -- Houndmaster Grebmar (Blackrock Depths)
    { 13730, "tank", "Senkt die Angriffskraft von Spielern in der Nähe; kommt mit zwei Hunden", "Lowers melee attack power nearby; comes with two hounds", "v" },
    { 21049, "dispel", "**Kampfrausch** beschleunigt ihn: reinigen oder Tank stärker heilen", "**Bloodlust** speeds him up: purge it or slow the tank damage", "v" },
    { 15615, "tank", "**Zuschlagen** unterbricht Zauberer im Nahkampf: Heiler auf Abstand", "**Pummel** interrupts casters in melee: healers stay at range", "v" },
    { 0, "positioning", "Flieht bei 15 % Leben; aufhalten, bevor er weitere Gegner holt", "Flees at 15% health; stop him before he pulls more mobs" },
  },
  [9476] = { -- Watchman Doomgrip (Blackrock Depths)
    { 11971, "tank", "Stapelt Rüstungsverringerung auf dem Tank", "Stacks armor reduction on the tank" },
    { 15504, "survive", "Trinkt einen Heiltrank; Schaden bündeln", "Drinks a potion to heal himself; burst him" },
  },
  [9499] = { -- Plugger Spazzring (Blackrock Depths)
    { 0, "survive", "Hexer: verbannt, verflucht; Ärger zieht die ganze Bar", "Warlock: banishes and curses; angering him pulls the bar" },
  },
  [9502] = { -- Phalanx (Blackrock Depths)
    { 14099, "positioning", "Stößt Spieler zurück; mit Wand im Rücken kämpfen", "Knocks players back; fight with walls behind you", "v" },
    { 15588, "survive", "Naturschaden in der Nähe; verlangsamt Angriffe und Bewegung", "Nature damage nearby; slows attacks and movement", "v" },
    { 15285, "survive", "Feuersalve auf alle in der Nähe", "Fire volley on everyone nearby", "v" },
  },
  [9537] = { -- Hurley Blackbreath (Blackrock Depths)
    { 14872, "tank", "Raserei: 15 Sek. lang schnellere, härtere Nahkampfschläge", "Enrages: much faster and harder melee for 15 sec" },
    { 9573, "positioning", "Feueratem im Frontkegel; vom Trupp wegdrehen", "Fire breath in a frontal cone; face him away" },
  },
  [9568] = { -- Overlord Wyrmthalak (Lower Blackrock Spire)
    { 25322, "positioning", "Kegel mit Rückstoß; Nahkampf hinter ihm", "Cone knockback; melee stand behind him", "v" },
    { 19983, "positioning", "Frontaler Spalter trifft bis zu zwei weitere", "Frontal cleave hits up to two others", "v" },
    { 23511, "survive", "Senkt die Nahkampf-Angriffskraft von Spielern in der Nähe", "Lowers melee attack power of nearby players for a while", "v" },
    { 0, "adds", "Bei 50 % kommen zwei Wachen; abtanken oder kontrollieren", "At 50% two guards join; off-tank or control them" },
  },
  [9596] = { -- Bannok Grimaxe (Lower Blackrock Spire)
    { 13737, "tank", "Senkt Heilung am Tank; gegen den Debuff anheilen", "Cuts healing on the tank; heal through the debuff" },
    { 15128, "survive", "Markiert ein Ziel: es erleidet mehr Feuerschaden", "Marks a target to take more fire damage" },
  },
  [9693] = { -- Bloodaxe Evoker (Lower Blackrock Spire)
    { 15743, "avoid", "Feuer-Rückstoß um den Zauberer; Abstand halten", "Fire knockback around the caster; stay at range" },
  },
  [9717] = { -- Bloodaxe Summoner (Lower Blackrock Spire)
    { 15734, "positioning", "Zieht Spieler zu sich; abseits anderer Gruppen kämpfen", "Pulls a player to the caster; fight away from packs" },
  },
  [9718] = { -- Ghok Bashguud (Lower Blackrock Spire)
    { 11972, "survive", "Unterbricht Zauber; Heiler außerhalb der Nahkampfreichweite", "Interrupts casters; healers stay out of melee" },
    { 8269, "tank", "Angriffstempo steigt; Tank-Abklingzeiten aufheben", "Attack speed boost; save tank cooldowns" },
  },
  [9736] = { -- Quartermaster Zigris (Lower Blackrock Spire)
    { 15609, "survive", "Fesselt Spieler in der Nähe etwa 10 Sek. lang in einem Netz; Befreiungseffekte helfen", "Nets nearby players in place for about 10 sec; escape effects free you", "v" },
    { 16497, "avoid", "Bombe betäubt im kleinen Bereich; verteilen", "Fire bomb stuns players in a small area; spread out" },
    { 15504, "interrupt", "Trinkt Heiltrank; schnell Schaden oder betäuben", "Drinks a healing potion; burst or stun him" },
  },
  [9816] = { -- Pyroguard Emberseer (Upper Blackrock Spire)
    { 16536, "survive", "Stapelnder Feuer-Debuff; Feuerresistenz hilft", "Stacking fire damage taken debuff; fire resist helps", "v" },
    { 0, "adds", "Zuerst die Kerkermeister töten; sie betäuben Spieler", "Kill the Incarcerators first; they stun random players" },
    { 17366, "avoid", "**Feuernova** trifft Nahkampf; Fernkampf auf Abstand", "**Fire nova** hits melee; ranged keep distance" },
  },
  [9817] = { -- Blackhand Dreadweaver (Upper Blackrock Spire)
    { 6909, "dispel", "Fluch schadet beim Angreifen; entfluchen", "Curse deals damage when the victim attacks; decurse", "v" },
    { 7068, "dispel", "Senkt erhaltene Heilung um 75 %; bannen", "Cuts healing received by 75%; dispel", "v" },
    { 25307, "interrupt", "**Schattenblitz** auf Spieler: unterbrechen", "**Shadow bolt** on a player: interrupt it", "v" },
  },
  [9818] = { -- Blackhand Summoner (Upper Blackrock Spire)
    { 25306, "interrupt", "**Feuerball** auf Spieler: unterbrechen", "**Fireball** on a player: interrupt it", "v" },
    { 122, "avoid", "**Frostnova** friert Spieler in der Nähe ein: Fernkämpfer auf Abstand", "**Frost nova** roots nearby players: ranged keep distance", "v" },
    { 15794, "interrupt", "Beschwört weitere Orcs; unterbrechen oder zuerst töten", "Summons more orcs; interrupt or kill first" },
  },
  [9819] = { -- Blackhand Veteran (Upper Blackrock Spire)
    { 11972, "survive", "Unterbricht Zauberer im Nahkampf", "Interrupts casters in melee range", "v" },
  },
  [9938] = { -- Magmus (Blackrock Depths)
    { 24375, "positioning", "Rückstoß und lange Betäubung für Spieler in der Nähe", "Knockback and long stun on players near him", "v" },
    { 13900, "avoid", "**Feuerstoß** auf ein Gebiet; Wandstatuen speien Flammen", "Fire burst on an area; wall statues also shoot flames", "v" },
  },
  [10082] = { -- Zerillis (Zul'Farrak)
    { 12551, "dispel", "Frostschuss verlangsamt Spieler: bei Bedarf bannen", "Frost shot slows a player: dispel if needed", "v" },
    { 6533, "dispel", "Wirft ein Netz auf Spieler: bannen oder befreien", "Nets a player in place: dispel or free them", "v" },
  },
  [10083] = { -- Rage Talon Flamescale (Upper Blackrock Spire)
    { 16102, "avoid", "**Feuersäule** am Boden; herausgehen", "Fire pillar on the ground; move out" },
  },
  [10184] = { -- Onyxia (Onyxia's Lair)
    { 18435, "positioning", "**Feueratem** nach vorn; nur der Tank steht am Kopf", "Frontal fire breath; only the tank stands at her head" },
    { 15847, "positioning", "Schwanz schleudert Spieler hinter ihr; von der Seite angreifen", "Tail knocks back players behind her; attack from the sides" },
    { 17086, "avoid", "Phase 2: **Tiefer Atem** quer durch den Raum; Bahn verlassen", "Phase 2 Deep **Breath** across the room; leave its path" },
    { 18431, "survive", "Phase 3: Raidfurcht; Furchtzauberschutz oder Erdstoßtotem", "Phase 3 raid fear; Fear Ward or Tremor Totem help", "c" },
  },
  [10220] = { -- Halycon (Lower Blackrock Spire)
    { 13443, "tank", "Blutung am Tank; durchheilen", "Bleed on the tank; heal through it", "v" },
    { 3391, "tank", "Extra-Angriffe; Schadensspitzen am Tank", "Gains extra attacks; damage spikes on the tank", "v" },
  },
  [10263] = { -- Burning Felguard (Lower Blackrock Spire)
    { 16046, "avoid", "Feuerwelle um ihn verlangsamt Spieler; Zauberer auf Abstand", "Fire blast around him slows; casters keep distance" },
    { 15548, "tank", "Flächenschlag verlangsamt Angriffs- und Lauftempo im Nahkampf", "AoE slows attack and movement of melee nearby" },
  },
  [10264] = { -- Solakar Flamewreath (Upper Blackrock Spire)
    { 0, "adds", "Fünf Wellen Drachkin; zuerst die Brüter töten", "Five waves of dragonkin; kill Hatchers first" },
    { 0, "avoid", "Eier schlüpfen bei Nähe; nicht darüberlaufen", "Eggs hatch whelps when you walk near; stay off them" },
    { 16727, "positioning", "Flächenbetäubung um ihn; Fernkampf auf Abstand", "AoE stun near him; ranged stay away" },
  },
  [10268] = { -- Gizrul the Slavener (Lower Blackrock Spire)
    { 20539, "tank", "Saugt Leben ab und heilt sich selbst", "Drains health and heals himself", "v" },
    { 8269, "tank", "**Raserei**, schnellere Angriffe; besänftigen oder Abklingzeit", "Frenzies for faster attacks; soothe or cooldown", "v" },
    { 16128, "dispel", "Krankheit erhöht erlittenen Schaden; heilen", "Disease raises physical damage taken; cure it", "v" },
  },
  [10316] = { -- Blackhand Incarcerator (Upper Blackrock Spire)
    { 16045, "survive", "Lange Betäubung; schnell töten", "Long stun on a player; kill them fast" },
  },
  [10318] = { -- Blackhand Assassin (Upper Blackrock Spire)
    { 0, "positioning", "Getarnte Schurken überfallen Zauberer nahe der Bestie", "Stealthed rogues ambush casters in the Beast area" },
  },
  [10339] = { -- Gyth (Upper Blackrock Spire)
    { 20667, "positioning", "**Säureatem** senkt Rüstung; von der Gruppe weg", "Acid breath lowers armor; keep it off the group", "v" },
    { 18798, "avoid", "Frostkegel betäubt; nicht vor ihm stehen", "Frost cone stuns; avoid the front", "v" },
    { 9573, "positioning", "**Flammenatem** trifft nach vorn: nur der Tank steht vorne", "**Flame breath** hits the front: only the tank stands in front", "v" },
  },
  [10363] = { -- General Drakkisath (Upper Blackrock Spire)
    { 16805, "tank", "Verbrennt und lähmt ein Ziel; zweiter Tank spottet", "Burns and panics a target; second tank taunts", "v" },
    { 20569, "positioning", "Trifft Tank und einen weiteren Spieler; nicht vor ihm stehen", "Hits the tank and one more player; stay out of the front arc", "v" },
    { 9573, "positioning", "Feuerkegel nach vorn: von der Gruppe wegdrehen", "Fire cone in front: face him away from the group", "v" },
    { 8078, "avoid", "Naturschlag um ihn; verlangsamt Bewegung und Angriffe", "Nature slam around him; slows movement and attacks", "v" },
    { 0, "adds", "Zwei Elitewachen helfen; töten oder ihn wegziehen", "Two elite guards join; kill them or pull him away" },
    { 0, "avoid", "**Feuersäulen** am Boden; herausgehen", "Fire pillars on the ground; step out" },
  },
  [10371] = { -- Rage Talon Captain (Upper Blackrock Spire)
    { 15708, "tank", "Halbiert 5 Sek. lang die Heilung am Tank", "Healing on the tank halved for 5 sec" },
  },
  [10372] = { -- Rage Talon Fire Tongue (Upper Blackrock Spire)
    { 16635, "avoid", "**Feuernova** um ihn; Fernkampf auf Abstand", "**Fire nova** around it; ranged stay away" },
  },
  [10374] = { -- Spire Spider (Lower Blackrock Spire)
    { 16104, "positioning", "Kegel betäubt; von der Gruppe wegdrehen", "Cone stun; face it away from the group" },
  },
  [10376] = { -- Crystal Fang (Lower Blackrock Spire)
    { 16416, "adds", "Ruft kleine Spinnen; töten, bevor sie Heiler angreifen", "Calls spiderlings; kill them before they swarm healers" },
  },
  [10393] = { -- Skul (Stratholme)
    { 16799, "interrupt", "Rarer Zauberer: Frostblitz unterbrechen", "Rare caster: kick his Frostbolt casts", "v" },
    { 15499, "survive", "Frostschock verlangsamt und trifft hart, gegenheilen", "Instant Frost Shock slows and hurts, heal through it", "v" },
    { 15230, "interrupt", "Arkaner Blitz auf einen Spieler: wenn möglich unterbrechen", "Arcane bolt on a player: interrupt when possible", "v" },
  },
  [10398] = { -- Thuzadin Shadowcaster (Stratholme)
    { 16429, "dispel", "Durchbohrender Schatten erhöht Schattenschaden, bannen", "Piercing Shadow raises shadow damage taken, dispel" },
    { 11443, "dispel", "Verkrüppeln verlangsamt Angriff und Lauf, bannen", "Cripple slows attacks and movement, dispel" },
  },
  [10400] = { -- Thuzadin Necromancer (Stratholme)
    { 12420, "adds", "Beschwört Skelette, zuerst den Nekromanten töten", "Summons skeletons, kill the necromancer first" },
    { 16431, "interrupt", "Knochenrüstung absorbiert Schaden, Zauber unterbrechen", "Bone Armor absorbs damage, interrupt the cast" },
  },
  [10409] = { -- Rockwing Screecher (Stratholme)
    { 8715, "survive", "Heulen lässt Spieler fliehen, kann weitere Mobs ziehen", "Howl fears nearby players, may pull more mobs" },
  },
  [10414] = { -- Patchwork Horror (Stratholme)
    { 16345, "dispel", "Krankheitswolke infiziert Nahkämpfer, Krankheit heilen", "Disease Cloud infects melee, cure disease" },
  },
  [10417] = { -- Venom Belcher (Stratholme)
    { 7992, "dispel", "Verlangsamendes Gift, Gift heilen", "Slowing Poison, cure poison on affected players" },
  },
  [10422] = { -- Crimson Sorcerer (Stratholme)
    { 13323, "dispel", "Verwandelt Spieler in ein Schaf, bannen oder unterbrechen", "Polymorphs a player, dispel or interrupt the cast" },
  },
  [10423] = { -- Crimson Priest (Stratholme)
    { 15586, "interrupt", "Heilt andere Scharlachrote, unterbrechen oder zuerst töten", "Heals other Scarlets, interrupt or kill first" },
  },
  [10425] = { -- Crimson Battle Mage (Stratholme)
    { 15253, "avoid", "**Arkane Explosion** trifft alle in der Nähe, Zauberer auf Abstand", "Arcane Explosion hits all nearby, casters keep away" },
    { 26740, "survive", "Kann Spieler per Gnomen-Kappe kontrollieren", "Can mind-control a player with a gnomish cap" },
  },
  [10426] = { -- Crimson Inquisitor (Stratholme)
    { 17146, "dispel", "Schattenwort: Schmerz auf Spielern, Magie bannen", "Shadow Word: Pain on players, dispel magic" },
  },
  [10429] = { -- Warchief Rend Blackhand (Upper Blackrock Spire)
    { 13736, "avoid", "Rend wirbelt nach Absteigen; Nahkampf zurücktreten", "Rend whirlwinds after dismount; melee step back", "v" },
    { 15588, "avoid", "Naturschlag um ihn; verlangsamt Bewegung und Angriffe", "Nature slam around him; slows movement and attacks", "v" },
    { 20569, "positioning", "Trifft Tank und einen weiteren Spieler; nicht vor ihm stehen", "Hits the tank and one more player; stay out of the front arc", "v" },
    { 0, "adds", "Viele Wellen in der Arena, dann kommen Rend und Gyth", "Many add waves in the arena before Rend and Gyth jump in" },
    { 20712, "positioning", "Gyth speit Kegel; von der Gruppe wegdrehen", "Gyth breathes cones; face him away from the group" },
  },
  [10430] = { -- The Beast (Upper Blackrock Spire)
    { 16785, "positioning", "Rückstoß-Feuer; Tank mit Rücken zur Wand", "Knockback AoE; tank with back to a wall", "v" },
    { 14100, "survive", "Versetzt Spieler in Furcht; Fernkampf auf maximale Distanz", "Fears players nearby; ranged stay at max range", "v" },
    { 19471, "tank", "Stürmt einen zufälligen Spieler an; Tank holt Aggro zurück", "Charges a random player; tanks re-grab aggro", "v" },
    { 15570, "survive", "Feuerschaden über Zeit auf einen Spieler", "Fire damage over time on a player", "v" },
    { 16144, "survive", "Direkter Feuerschaden auf einen Spieler", "Direct fire hit on a player", "v" },
    { 16788, "survive", "Feuerball auf einen Spieler", "Fire bolt on a player", "v" },
  },
  [10432] = { -- Vectus (Scholomance)
    { 10216, "avoid", "**Flammenstoß**-Fläche sofort verlassen", "Leave the **Flamestrike** area at once", "v" },
    { 13021, "positioning", "Feuerwelle im Nahbereich; verteilen und Abstand halten", "Point-blank fire burst; spread out and stay at range", "v" },
  },
  [10433] = { -- Marduk Blackpool (Scholomance)
    { 12040, "positioning", "**Schattenschild** schadet Nahkämpfern; Fernkämpfer übernehmen", "**Shadow shield** hurts melee; let ranged do the work", "v" },
    { 17695, "positioning", "Aura schadet in der Nähe; Fernkämpfer auf Abstand", "Aura damages nearby players; ranged keep distance", "v" },
    { 11609, "positioning", "Spaltet nach vorn; nur der Tank steht vor ihm", "Cleaves in front; only the tank faces him", "v" },
  },
  [10435] = { -- Magistrate Barthilas (Stratholme)
    { 10887, "positioning", "Massenschlag stößt alle Nahkämpfer um ihn zurück", "Crowd Pummel knocks back all melee around him", "v" },
    { 14099, "tank", "Mächtiger Stoß ist ein schwerer Treffer auf den Tank", "Mighty Blow is a heavy tank hit", "v" },
    { 16793, "tank", "Entkräftender Schlag schwächt den Tank: gleichmäßig heilen", "Draining blow saps the tank: keep healing steady", "v" },
    { 16791, "tank", "Wütender Zorn erhöht seinen Schaden: Abklingzeiten fürs Ende", "Furious anger raises his damage: save cooldowns for the end", "v" },
  },
  [10436] = { -- Baroness Anastari (Stratholme)
    { 16867, "dispel", "Bansheefluch lässt Angriffe verfehlen, Fluch entfernen", "Banshee Curse makes you miss attacks, decurse it", "v" },
    { 16868, "interrupt", "Bansheekreischen trifft die Gruppe: unterbrechen", "Banshee shriek hits the group: interrupt it", "v" },
    { 17244, "survive", "Übernimmt einen Spieler: übernommenen Spieler kontrollieren", "Possesses a player: crowd control the possessed player", "v" },
    { 18327, "dispel", "Bringt einen Spieler zum Schweigen: zuerst bei Heilern bannen", "Silences a player: dispel magic on healers first", "v" },
    { 16565, "interrupt", "Schattenklage auf einen Spieler: wenn möglich unterbrechen", "Shadow wail on a player: interrupt when possible", "v" },
  },
  [10437] = { -- Nerub'enkan (Stratholme)
    { 17235, "adds", "Erweckt untote Skarabäen, mit Flächenschaden töten", "Raises undead scarabs, AoE them down", "v" },
    { 4962, "survive", "Umhüllende Netze fesseln Spieler an Ort und Stelle", "Encasing Webs roots players in place", "v" },
    { 6016, "tank", "Rüstung durchstechen senkt die Rüstung des Tanks", "Pierce Armor lowers the tank's armor", "v" },
    { 16418, "adds", "Erzeugt Gruftskarabäen: mit Flächenschaden töten", "Spawns crypt scarabs: kill them with area damage", "v" },
  },
  [10438] = { -- Maleki the Pallid (Stratholme)
    { 13322, "interrupt", "Seine Frostblitze unterbrechen", "Interrupt his Frostbolts", "v" },
    { 16869, "dispel", "Eisgrab friert einen Spieler ein, bannen", "Ice Tomb freezes a player solid, dispel it", "v" },
    { 17620, "interrupt", "Lebensentzug heilt ihn: Kanalisierung unterbrechen", "Drain life heals him: interrupt the channel", "v" },
    { 17243, "survive", "Entzieht Zauberern Mana, Heilermana im Blick behalten", "Drains mana from casters, watch healer mana" },
  },
  [10439] = { -- Ramstein the Gorger (Stratholme)
    { 5568, "positioning", "Trampeln trifft alle vor ihm, nur der Tank davor", "Trample hits everyone in front, only the tank faces him", "v" },
    { 17307, "tank", "Niederschlag betäubt den Tank, Ersatz bereithalten", "Knockout stuns the tank, off-tank may need to pick up", "v" },
    { 17687, "tank", "Raserei beschleunigt seine Angriffe eine Weile: mehr Schaden auf dem Tank", "Flurry speeds up his attacks for a while: expect more damage on the tank", "v" },
  },
  [10440] = { -- Baron Rivendare (Stratholme)
    { 17467, "survive", "Unheilige Aura macht dauerhaft Schattenschaden an allen", "Unholy Aura deals shadow damage to the group nonstop", "v" },
    { 16856, "tank", "Tödlicher Stoß senkt die Heilung auf dem Tank", "Mortal Strike cuts healing on the tank", "v" },
    { 15496, "positioning", "Spalten trifft Spieler neben dem Tank, hinten stehen", "Cleave hits players beside the tank, stand behind", "v" },
    { 17393, "interrupt", "Schattenblitz auf Spieler: wenn möglich unterbrechen", "Shadow bolt on a player: interrupt when possible", "v" },
  },
  [10463] = { -- Shrieking Banshee (Stratholme)
    { 3589, "survive", "Kreischen bringt Zauberer in der Nähe zum Schweigen", "Screech silences casters nearby" },
  },
  [10464] = { -- Wailing Banshee (Stratholme)
    { 17105, "dispel", "Fluch lässt Angriffe verfehlen, Fluch entfernen", "Curse makes you miss attacks, decurse" },
    { 19645, "survive", "Antimagieschild blockt Zauber, Nahkampf nutzen", "Anti-Magic Shield blocks spells, use melee" },
  },
  [10469] = { -- Scholomance Adept (Scholomance)
    { 15244, "positioning", "**Kältekegel** verlangsamt; nicht davor stehen", "Frost cone slows; do not stand in front" },
  },
  [10472] = { -- Scholomance Occultist (Scholomance)
    { 17228, "interrupt", "Salven unterbrechen; wird zum Schatten, immun gegen Physisch", "Interrupt volleys; turns into a shade immune to physical" },
  },
  [10477] = { -- Scholomance Necromancer (Scholomance)
    { 17616, "avoid", "Lässt Leichen explodieren; weg von Leichen", "Blows up corpses; move away from bodies" },
    { 14887, "interrupt", "**Schattenblitzsalve** unterbrechen", "Interrupt the **shadow bolt volley**" },
  },
  [10485] = { -- Risen Aberration (Scholomance)
    { 12021, "adds", "Fixiert einen Spieler; nur Heiligmagie schadet ihm", "Fixates a player; only holy magic hurts them" },
  },
  [10495] = { -- Diseased Ghoul (Scholomance)
    { 3436, "dispel", "Ansteckende Krankheit; heilen und Abstand halten", "Spreading disease; cure it and stand apart" },
    { 17742, "avoid", "Leiche hinterlässt Seuchenwolke; heraustreten", "Corpse leaves a disease cloud; step out" },
  },
  [10498] = { -- Spectral Tutor (Scholomance)
    { 17651, "adds", "Wird unangreifbar, Abbilder heilen ihn; schnell töten", "Goes untouchable and spawns images that heal it; kill fast" },
    { 17630, "interrupt", "Verbrennt Mana; unterbrechen oder Zauberer fernhalten", "Burns mana; interrupt or keep casters away" },
  },
  [10502] = { -- Lady Illucia Barov (Scholomance)
    { 14515, "interrupt", "Gedankenkontrolle auf Spieler; unterbrechen oder kontrollieren", "Mind control on a player; interrupt or crowd-control", "v" },
    { 6215, "survive", "Furcht auf einen Spieler; Schattenwiderstand hilft", "Fears a player; shadow resistance helps", "v" },
    { 12528, "positioning", "Flächenstille; Zauberer verteilen sich", "AoE silence; casters spread out", "v" },
    { 11713, "dispel", "**Fluch der Pein** wächst an: Fluch entfernen", "**Bane of agony** grows over time: remove the curse", "v" },
    { 17289, "interrupt", "**Schattenschock** auf Spieler: wenn möglich unterbrechen", "**Shadow shock** on a player: interrupt when possible", "v" },
  },
  [10503] = { -- Jandice Barov (Scholomance)
    { 8282, "dispel", "Fluch erhöht erlittenen körperlichen Schaden; entfernen", "Curse raises physical damage taken; remove it", "v" },
    { 8994, "survive", "Verbannt einen Spieler kurz; abwarten", "Banishes one player for a short time; wait it out", "v" },
    { 17773, "adds", "Beschwört viele Trugbilder; echte Jandice markieren und angreifen", "Spawns many illusions; mark and focus the real Jandice" },
  },
  [10504] = { -- Lord Alexei Barov (Scholomance)
    { 28340, "survive", "Schattenaura trifft die Gruppe; Heiler brauchen Mana", "Group-wide shadow aura; healers need mana for it", "v" },
    { 17820, "dispel", "Fluch senkt erhaltene Heilung; zuerst entfluchen", "Curse cuts healing taken; decurse it first", "v" },
    { 25309, "dispel", "Feuerschaden über Zeit auf Spieler: bannen oder gegenheilen", "Fire damage over time on a player: dispel or heal through", "v" },
    { 0, "adds", "Zwei Adds kommen mit; eins fesseln, Alexei zuerst", "Two adds join; shackle one and kill Alexei first" },
  },
  [10505] = { -- Instructor Malicia (Scholomance)
    { 6146, "dispel", "**Verlangsamung** senkt Angriffs- und Lauftempo; bannen", "**Slow** cuts attack and move speed; dispel it", "v" },
    { 5137, "adds", "Ruft untote Helfer: Begleiter töten", "Calls undead helpers: kill the adds", "v" },
    { 25311, "dispel", "**Verderbnis** auf einem Spieler: Magie bannen", "**Corruption** on a player: dispel magic", "v" },
    { 6064, "interrupt", "Heilt sich selbst: Zauber unterbrechen", "Heals herself: interrupt the cast", "v" },
    { 25315, "dispel", "**Erneuerung** heilt sie über Zeit: reinigen", "**Renew** heals her over time: purge it", "v" },
    { 17843, "interrupt", "Heilt sich selbst; Heilungen unterbrechen", "Heals herself; interrupt her heals" },
  },
  [10506] = { -- Kirtonos the Herald (Scholomance)
    { 11708, "dispel", "Fluch senkt Nahkampfschaden: Fluch entfernen", "Curse lowers melee damage: remove the curse", "v" },
    { 8379, "tank", "Entwaffnet den Tank kurz; weniger Bedrohung einplanen", "Disarms the tank for a few seconds; expect less threat", "v" },
    { 14515, "interrupt", "Kann einen Spieler übernehmen; unterbrechen oder kontrollieren", "Can take over a player; interrupt or crowd-control", "v" },
    { 6016, "tank", "Senkt die Rüstung des Tanks eine Weile; Heiler achten auf den Tank", "Strips the tank armor for a while; healers watch the tank", "v" },
    { 17228, "interrupt", "Schattensalve trifft die Gruppe; unterbrechen", "Shadow volley hits the group; interrupt it", "v" },
    { 18144, "positioning", "Gargoylegestalt: nicht vor ihm stehen, Kegel betäubt", "Gargoyle form: stay out of the frontal stun cone" },
    { 12882, "positioning", "Tank an die Wand, damit der Rückstoß nicht wegschleudert", "Tank against a wall so the knockback does not throw him" },
    { 12889, "dispel", "Menschengestalt verflucht; Zauberer schnell entfluchen", "Human form casts curses; decurse casters fast" },
  },
  [10507] = { -- The Ravenian (Scholomance)
    { 11130, "positioning", "Rückstoß kann Spieler in nicht geräumte Gegner werfen", "Knockback can throw players into uncleared trash", "v" },
    { 25174, "positioning", "**Spaltangriff** nach vorn; hinter ihm stehen", "Frontal cleave; stand behind him", "v" },
    { 20569, "positioning", "Spaltet nach vorn: nur der Tank steht vorne", "Cleaves the front: only the tank stands in front", "v" },
    { 5568, "positioning", "**Trampeln** trifft Spieler neben dem Tank: Nahkämpfer verteilen", "**Trample** hits players next to the tank: melee spread a bit", "v" },
  },
  [10508] = { -- Ras Frostwhisper (Scholomance)
    { 6215, "survive", "Furcht auf Spieler; vorher Adds töten, sonst Zusatzpulls", "Fears players; clear his adds first so no extra pulls", "v" },
    { 18099, "positioning", "**Frostnova** wurzelt Nahkämpfer; Fernkämpfer auf Maximaldistanz", "Frost nova roots melee; ranged stay at max range", "v" },
    { 8398, "interrupt", "**Frostblitzsalven** unterbrechen", "Interrupt the frostbolt volleys", "v" },
    { 16350, "dispel", "Friert einen Spieler ein: Magie bannen", "Freezes a player in place: dispel magic", "v" },
    { 18100, "dispel", "Frostrüstung verlangsamt Nahkämpfer; bannen oder reinigen", "Frost armor slows melee attackers; dispel or purge it", "v" },
  },
  [10509] = { -- Jed Runewatcher (Upper Blackrock Spire)
    { 15749, "tank", "Stürmt einen Spieler an und stößt ihn zurück; Tank hält ihn an der Wand", "Charges a player and knocks them back; tank keeps him at a wall", "v" },
    { 11972, "interrupt", "Schlägt zu und unterbricht Zauberer; Zauberer auf Abstand", "Bashes and silences a caster; keep casters at range", "v" },
    { 14516, "tank", "Kräftiger Nahkampfschlag auf den Tank", "Heavy melee strike on the tank", "v" },
  },
  [10516] = { -- The Unforgiven (Stratholme)
    { 14907, "positioning", "Frostnova fesselt Nahkämpfer, Fernkämpfer auf Abstand", "Frost Nova roots melee in place, ranged keep distance" },
  },
  [10558] = { -- Hearthsinger Forresten (Stratholme)
    { 16798, "dispel", "Schlaflied lässt Spieler einschlafen, Magie bannen", "Lullaby puts players to sleep, dispel the magic effect", "v" },
    { 14443, "positioning", "Mehrfachschuss trifft mehrere Ziele, nicht stapeln", "Multi-Shot hits several targets, do not stack", "v" },
  },
  [10584] = { -- Urok Doomhowl (Lower Blackrock Spire)
    { 16508, "survive", "Versetzt Spieler 8 Sek. lang in Furcht; Furchtschutz nutzen", "Fears nearby players for 8 sec; use fear wards", "v" },
    { 13443, "tank", "**Verwunden** lässt den Tank bluten: gleichmäßig heilen", "**Rend** bleeds the tank: keep healing steady", "v" },
    { 13446, "tank", "Harter Nahkampfschlag auf den Tank", "Hard melee strike on the tank", "v" },
    { 0, "adds", "Oger-Wellen vor Urok; die aufgestellte Pike tötet alle 30 Sek. einen Oger, den Rest kontrollieren", "Ogre waves come before Urok; the placed pike kills one ogre every 30 sec, crowd control the rest" },
  },
  [10596] = { -- Mother Smolderweb (Lower Blackrock Spire)
    { 16468, "dispel", "Gift fesselt Spieler; Gift schnell entfernen", "Poison roots players; cure poison quickly", "v" },
    { 16104, "survive", "Betäubt Spieler einige Sek. lang", "Stuns players for a few seconds", "v" },
    { 16103, "adds", "Setzt beim Tod kleine Spinnen frei; mit Flächenschaden töten", "Releases spiderlings on death; AoE them down" },
  },
  [10678] = { -- Plagued Hatchling (Scholomance)
    { 17745, "adds", "Großer Schwarm im Beinhaus; Flächenschaden nutzen", "Big swarm in the ossuary; use AoE" },
  },
  [10683] = { -- Rookery Hatcher (Upper Blackrock Spire)
    { 15746, "adds", "Lässt Welpen schlüpfen; Brüter zuerst töten", "Hatches whelps from eggs; kill hatchers first" },
  },
  [10742] = { -- Blackhand Dragon Handler (Upper Blackrock Spire)
    { 0, "interrupt", "Heilt Drachen in der Nähe; Treiber zuerst töten", "Heals nearby dragons; kill the handler first" },
  },
  [10808] = { -- Timmy the Cruel (Stratholme)
    { 17470, "tank", "Gieriger Klauenhieb trifft den Tank hart, Heilung halten", "Ravenous Claw hits the tank hard, keep heals on him", "v" },
    { 8599, "survive", "Wird bei wenig Leben wütend, schnell herunterbrennen", "Enrages at low health, burn him down fast", "v" },
  },
  [10809] = { -- Stonespine (Stratholme)
    { 14331, "tank", "Bösartiges Zerfleischen lässt den Tank bluten, gegenheilen", "Vicious Rend bleeds the tank, heal the damage over time", "v" },
  },
  [10811] = { -- Archivist Galford (Stratholme)
    { 17366, "avoid", "**Feuernova** verbrennt alle in der Nähe, Zauberer auf Abstand", "Fire Nova burns everyone close, casters stay back", "v" },
    { 17293, "survive", "Brennende Winde verursachen Feuerschaden über Zeit", "Burning Winds deals fire damage over time to the group", "v" },
  },
  [10813] = { -- Balnazzar (Stratholme)
    { 17405, "survive", "Übernimmt Spieler per Gedankenkontrolle, kontrollieren", "Mind-controls a player, crowd-control them, do not kill", "v" },
    { 13704, "positioning", "**Psychischer Schrei** lässt Spieler in der Nähe fliehen, verteilt stehen", "Psychic Scream fears nearby players, ranged spread out", "v" },
    { 15587, "interrupt", "Gedankenschlag auf Heiler unterbrechen", "Interrupt Mind Blast casts on healers", "v" },
    { 17399, "interrupt", "Schattenschock auf Spieler: wenn möglich unterbrechen", "Shadow shock on a player: interrupt when possible", "v" },
    { 15970, "dispel", "Schläfert einen Spieler ein: Magie bannen", "Puts a player to sleep: dispel magic", "v" },
    { 17286, "avoid", "Betäubt alle in der Nähe 4 Sek. lang: Tank vorher hochheilen", "Stuns everyone close for 4 sec: heal up the tank beforehand", "v" },
    { 18647, "survive", "Verbannt ein Ziel bis zu 30 Sek. lang: es kann nicht handeln, abwarten", "Banishes a target for up to 30 sec: it cannot act, wait it out", "v" },
  },
  [10814] = { -- Chromatic Elite Guard (Upper Blackrock Spire)
    { 16790, "tank", "Betäubt den Tank und Spieler daneben", "Stuns the tank and nearby players" },
  },
  [10899] = { -- Goraluk Anvilcrack (Upper Blackrock Spire)
    { 6253, "tank", "Betäubt den Tank; Zweittank spottet währenddessen", "Stuns the tank; off-tank taunts during the stun", "v" },
    { 3148, "tank", "Senkt die Ausdauer des Tanks für einige Zeit", "Lowers the tank's stamina for a while", "v" },
    { 25710, "tank", "Harter Nahkampfschlag mit erhöhter Bedrohung", "Hard melee hit that builds extra threat", "v" },
  },
  [10901] = { -- Lorekeeper Polkelt (Scholomance)
    { 3586, "positioning", "Infizierter schadet Verbündeten in der Nähe; weggehen", "Infected player hurts nearby allies; move away", "v" },
    { 8245, "tank", "Säure senkt Rüstung; Zombie-Adds explodieren beim Tod", "Acid lowers armor; zombie adds explode on death", "v" },
    { 5413, "survive", "Senkt Naturwiderstand; Naturschaden gering halten", "Lowers nature resistance; keep nature damage low", "v" },
  },
  [10997] = { -- Cannon Master Willey (Stratholme)
    { 17279, "adds", "Ruft Scharlachrote Schützen, töten oder separat tanken", "Calls Crimson Riflemen, kill or off-tank them" },
    { 10101, "tank", "Wegschlagen schleudert den Tank weg und senkt Bedrohung", "Knock Away throws the tank back and drops threat" },
  },
  [11032] = { -- Malor the Zealous (Stratholme)
    { 12734, "avoid", "**Bodenschlag** trifft Spieler in der Nähe und betäubt 3 Sek. lang: Fernkämpfer bleiben hinten", "Ground smash hits nearby players and stuns them 3 sec: ranged stay back", "v" },
    { 15493, "interrupt", "Seine Selbstheilung Heiliges Licht unterbrechen", "Interrupt his Holy Light self-heal" },
    { 17233, "survive", "Heilt sich einmal per Handauflegung voll, Burst aufheben", "Can fully heal once with Lay on Hands, save burst" },
  },
  [11043] = { -- Crimson Monk (Stratholme)
    { 11978, "survive", "Tritt Zauberer und sperrt ihre Zauberschule", "Kicks casters and locks their spell school" },
  },
  [11058] = { -- Ezra Grimm (Stratholme)
    { 17294, "avoid", "Feuerkegel vor ihm: nur der Tank steht vorne", "Fire cone in front of him: only the tank stands in front", "v" },
    { 7964, "avoid", "Betäubt alle in der Nähe 4 Sek. lang: etwas verteilt stehen", "Stuns everyone close for 4 sec: spread out a little", "v" },
  },
  [11143] = { -- Postmaster Malown (Stratholme)
    { 12741, "dispel", "Fluch der Schwäche von Nahkämpfern entfernen", "Remove his Curse of Weakness from melee", "v" },
    { 7713, "survive", "Klagen lässt Spieler fliehen: Furchtschutz nutzen", "Wailing fears nearby players: use fear protection", "v" },
    { 6253, "tank", "Rückhand betäubt den Tank: Tank voll geheilt halten", "Backhand stuns the tank: keep the tank topped up", "v" },
    { 13338, "dispel", "Fluch verlangsamt Zauber: Fluch bei Zauberern entfernen", "Curse slows casting: remove the curse from casters", "v" },
    { 12542, "survive", "Furcht auf Spieler: nicht in weitere Gegner laufen", "Fears a player: avoid running into other packs", "v" },
  },
  [11261] = { -- Doctor Theolen Krastinov (Scholomance)
    { 11574, "survive", "Blutung auf dem Tank; Spieler mit wenig Rüstung Abstand halten", "Bleed on the tank; low-armor players keep away", "v" },
    { 11130, "tank", "Schlägt den Tank weg: mit dem Rücken zur Wand tanken", "Knocks the tank away: tank with the back to a wall", "v" },
    { 8269, "tank", "**Raserei** bei 50 %; schnell töten, Tank nutzt Abklingzeiten", "Enrages at 50 percent; burn fast, tank uses cooldowns" },
  },
  [11319] = { -- Ragefire Shaman (Ragefire Chasm)
    { 11986, "interrupt", "Heilt andere Troggs: Zauber unterbrechen oder zuerst töten", "Heals other troggs: interrupt the cast or kill it first", "v" },
    { 9532, "interrupt", "Naturblitz auf Spieler: wenn möglich unterbrechen", "Nature bolt on a player: interrupt when possible", "v" },
  },
  [11324] = { -- Searing Blade Warlock (Ragefire Chasm)
    { 20791, "interrupt", "Schattenblitze treffen Stoffträger: unterbrechen oder Sichtlinie brechen", "Shadow bolts hurt casters: interrupt or line of sight", "v" },
    { 12746, "adds", "Beschwört Leerwandler: Hexer töten, bevor er fertig ist", "Summons a Voidwalker: kill the warlock before it finishes" },
  },
  [11338] = { -- Hakkari Shadowcaster (Zul'Gurub)
    { 20741, "interrupt", "**Schattenblitzsalve** auf Gruppe; unterbrechen", "**Shadow bolt volley** on the group; interrupt" },
    { 22947, "survive", "Verbrennt das Mana eines Zauberers", "Burns a caster's mana" },
  },
  [11350] = { -- Gurubashi Axe Thrower (Zul'Gurub)
    { 24018, "survive", "Wirft Äxte um sich; viel Gruppenschaden", "Throws axes around; heavy group damage" },
  },
  [11352] = { -- Gurubashi Berserker (Zul'Gurub)
    { 11130, "tank", "Schlägt den Tank weg, Bedrohung sinkt", "Knocks the tank away and drops threat" },
    { 15588, "positioning", "Flächenschaden und Verlangsamung um ihn", "AoE slow and damage around it" },
    { 8269, "survive", "Wütet bei wenig Leben; schnell töten", "Enrages at low health; burn it down" },
  },
  [11353] = { -- Gurubashi Blood Drinker (Zul'Gurub)
    { 24435, "interrupt", "Saugt Leben ab; unterbrechen", "Drains life; interrupt" },
  },
  [11380] = { -- Jin'do the Hexxer (Zul'Gurub)
    { 24262, "adds", "Totem übernimmt einen Spieler; schnell zerstören", "Totem mind-controls a player; destroy it fast" },
    { 24309, "adds", "Schutz heilt Jin'do; sofort töten", "Ward heals Jin'do; kill it at once" },
    { 24306, "dispel", "Fluch zeigt Schemen; Schemen töten, dann entfluchen", "Curse lets you see shades; kill shades, then decurse" },
    { 17172, "dispel", "Verhext den Tank; Magie bannen", "Hexes the tank; dispel magic" },
  },
  [11382] = { -- Bloodlord Mandokir (Zul'Gurub)
    { 24314, "avoid", "Ziel des Blicks darf nichts tun, bis er endet", "Gaze target must not act or move until it ends" },
    { 24318, "tank", "Wird mit Toden stärker; Tode vermeiden", "Grows stronger after kills; avoid deaths" },
    { 16856, "tank", "**Harter Schlag** senkt Heilung am Tank", "Big hit that cuts healing on the tank" },
  },
  [11444] = { -- Gordok Mage-Lord (Dire Maul)
    { 13323, "dispel", "Verwandelt einen Spieler in ein Schaf; bannen", "Sheeps a player; dispel it" },
    { 18399, "avoid", "Flammensäule brennt eine Fläche über Zeit", "Fire pillar burns an area over time" },
    { 16170, "dispel", "Beschleunigt Angriffe eines Verbündeten um 60 %; reinigen", "Speeds an ally's attacks by 60%; purge it" },
  },
  [11448] = { -- Gordok Warlock (Dire Maul)
    { 22865, "adds", "Beschwört eine Verdammniswache; töten oder verbannen", "Summons a Doomguard pet; kill or banish it" },
    { 13338, "dispel", "Fluch halbiert Zaubertempo", "Curse halves casting speed" },
  },
  [11456] = { -- Wildspawn Shadowstalker (Dire Maul)
    { 22766, "positioning", "Getarnter Satyr greift aus dem Hinterhalt an; auf Verstecktes achten", "Stealthed satyr ambushes; watch for hidden packs" },
    { 7992, "dispel", "Gift verlangsamt Angriffe und Bewegung", "Poison slows attacks and movement" },
  },
  [11457] = { -- Wildspawn Hellcaller (Dire Maul)
    { 31598, "avoid", "Feuerregen auf einer Fläche; verlassen", "Fire rain on an area; leave it", "c" },
  },
  [11459] = { -- Ironbark Protector (Dire Maul)
    { 0, "tank", "Rückstoß halbiert Bedrohung; hilft Tendris, falls lebendig", "Knockback that halves threat; joins Tendris if alive" },
  },
  [11464] = { -- Warpwood Tangler (Dire Maul)
    { 22415, "dispel", "Wurzelt ein Ziel fest, Naturschaden", "Roots a target with nature damage" },
  },
  [11466] = { -- Highborne Summoner (Dire Maul)
    { 15063, "positioning", "Wurzelt Spieler in der Nähe bis zu 8 Sek. lang fest", "Roots nearby players for up to 8 sec" },
  },
  [11467] = { -- Tsu'zee (Dire Maul)
    { 21060, "dispel", "Blendet einen Spieler bis zu 10 Sek. lang; bannen", "Blinds a player for up to 10 sec; dispel it", "v" },
    { 12540, "survive", "Betäubt das Ziel bis zu 4 Sek. lang: Tank muss sie halten", "Stuns the target for up to 4 sec: tank must hold her attention", "v" },
    { 15657, "positioning", "Trifft von hinten hart: sie auf den Tank ausgerichtet halten", "Hits hard from behind: keep her facing the tank", "v" },
    { 15667, "survive", "Nahkampfschlag mit Zusatzschaden auf das Ziel: durchheilen", "Extra-damage melee strike on the target: heal through", "v" },
  },
  [11470] = { -- Eldreth Sorcerer (Dire Maul)
    { 0, "dispel", "Verwandelt einen Spieler in ein Schaf; bannen", "Turns a player into a sheep; dispel it" },
    { 0, "interrupt", "Blitz springt auf bis zu 3 Spieler", "Lightning jumps between up to 3 players" },
  },
  [11480] = { -- Arcane Aberration (Dire Maul)
    { 51725, "avoid", "Arkanexplosion um sich; Zauberer Abstand halten", "Arcane burst around it; casters keep distance", "c" },
  },
  [11486] = { -- Prince Tortheldrin (Dire Maul)
    { 15589, "avoid", "Wirbelt, trifft alle im 8-m-Umkreis; Nahkämpfer zurück", "Spins hitting everyone within 8 yards; melee step back", "v" },
    { 20537, "survive", "Sperrt einen Zauberer 15 Sek. lang; Heilung aufteilen", "Locks out a caster for 15 sec; spread healer duty", "v" },
    { 22920, "positioning", "Arkantreffer mit Rückstoß; Tank mit Rücken zur Wand", "Arcane hit with knockback; tank with back to a wall", "v" },
    { 22995, "adds", "Holt einen Spieler zu sich: Heiler bereit halten", "Summons a player to him: healers stay ready", "v" },
  },
  [11487] = { -- Magister Kalendris (Dire Maul)
    { 7645, "survive", "Übernimmt einen Spieler 10 Sek. lang; diesen kontrollieren", "Mind-controls a player for 10 sec; crowd control them", "v" },
    { 15654, "dispel", "Schattenschaden über Zeit auf einem Spieler; Magie bannen", "Shadow damage over time on a player; dispel magic", "v" },
    { 22917, "survive", "Ab 50 % steigt sein Schattenschaden um 40 %; schnell töten", "At 50% his shadow damage rises 40%; burn him fast", "v" },
    { 15587, "interrupt", "Gedankenschlag auf einen Spieler: unterbrechen", "Mind blast on a player: interrupt it", "v" },
    { 22919, "interrupt", "Gedankenschinden verlangsamt und schadet: Kanalisierung unterbrechen", "Mind flay slows and hurts a player: interrupt the channel", "v" },
  },
  [11488] = { -- Illyanna Ravenoak (Dire Maul)
    { 22908, "avoid", "Arkaner Regen auf eine Fläche, 6 Sek. lang; herausgehen", "Arcane rain over an area for 6 sec; move out", "v" },
    { 22910, "avoid", "Legt Feuerfallen; nicht darüberlaufen", "Lays fire traps; do not walk over them", "v" },
    { 20904, "survive", "Gezielter Schuss trifft hart: Ziel heilen", "Aimed shot hits a player hard: heal the target", "v" },
    { 22914, "positioning", "Halbiert das Lauftempo eines Spielers 3 Sek. lang; im Nahkampf bleiben", "Slows a player's movement by half for 3 sec; stay in melee range of her", "v" },
    { 0, "adds", "Ihr Bär Ferra stürmt und betäubt; separat tanken", "Her bear Ferra charges and stuns; tank it separately" },
  },
  [11489] = { -- Tendris Warpwood (Dire Maul)
    { 22924, "avoid", "Wirft Spieler in der Nähe um und wurzelt sie 10 Sek. lang fest", "Knocks down and roots nearby players for 10 sec", "v" },
    { 22994, "dispel", "Wurzelt ein Ziel fest, Naturschaden über Zeit", "Roots one target with nature damage over time", "v" },
    { 5568, "positioning", "Trampeln trifft Spieler neben dem Tank: Nahkämpfer verteilen", "Trample hits players next to the tank: melee spread a bit", "v" },
    { 22916, "tank", "Aufwärtshaken schleudert den Tank zurück: an der Wand tanken", "Uppercut knocks the tank back: tank against a wall", "v" },
    { 0, "adds", "Ruft lebende Eisenborkenbeschützer; diese vor dem Pull töten", "Calls living Ironbark Protectors; kill them before the pull" },
  },
  [11490] = { -- Zevrim Thornhoof (Dire Maul)
    { 22651, "survive", "Holt einen Spieler auf den Altar und saugt Leben ab; durchheilen", "Ports a player to the altar and drains health; heal them through it", "v" },
    { 22478, "survive", "Schattenschaden über Zeit auf alle im 20-m-Umkreis", "Shadow damage over time on everyone within 20 yards", "v" },
    { 10894, "dispel", "Schattenschaden über Zeit: Magie auf dem Ziel bannen", "Shadow damage over time: dispel magic on the target", "v" },
  },
  [11492] = { -- Alzzin the Wildshaper (Dire Maul)
    { 22662, "dispel", "Naturschaden über Zeit, senkt Stärke", "Nature damage over time that lowers strength", "v" },
    { 22689, "tank", "Wolfsform: Schaden über Zeit und 50 % Verlangsamung am Tank", "Wolf form: bleed-like damage and 50% slow on the tank", "v" },
    { 22661, "survive", "Entkräften saugt einen Spieler aus: Ziel heilen", "Enervate drains a player: heal the target", "v" },
    { 10101, "tank", "Schlägt den Tank weg: mit dem Rücken zur Wand tanken", "Knocks the tank away: tank with the back to a wall", "v" },
    { 22660, "tank", "Wird zum Wolf mit schnelleren Schlägen: Tank stärker heilen", "Turns into a wolf with faster hits: heal the tank harder", "v" },
    { 22128, "survive", "Er stärkt sich mit Dornen: Nahkämpfer erleiden bei jedem Schlag Naturschaden", "He buffs himself with thorns: melee take nature damage per hit", "v" },
    { 22691, "tank", "Entwaffnet den Tank für einige Sekunden: weniger Tankschaden einplanen", "Disarms the tank for a few seconds: expect lower tank damage", "v" },
    { 7948, "survive", "Heilt sich in Wolfsform über Zeit: Schaden hochhalten", "Heals himself over time in wolf form: keep up damage", "v" },
    { 19319, "tank", "Biss trifft den Tank mit physischem Schaden: durchheilen", "Bite hits the tank for physical damage: heal through", "v" },
    { 0, "adds", "Mitten im Kampf bricht die Wand, Wichtel strömen herein; flächig töten", "Midway the wall breaks and imps swarm in; AoE them down" },
  },
  [11496] = { -- Immol'thar (Dire Maul)
    { 22950, "tank", "Teleportiert einen zufälligen Spieler; Bedrohung halten, ggf. spotten", "Teleports a random player and drops threat; keep him taunted", "v" },
    { 16128, "tank", "Naturschaden über Zeit, erhöht erlittenen physischen Schaden", "Nature damage over time and more physical damage taken", "v" },
    { 22899, "adds", "Augen erscheinen und verlangsamen einen Spieler; schnell töten", "Eyes spawn and slow a player's actions; kill them quickly", "v" },
    { 5568, "positioning", "Trampeln trifft Spieler neben dem Tank: Nahkämpfer verteilen", "Trample hits players next to the tank: melee spread a bit", "v" },
    { 8269, "survive", "Bei 50 % Leben schlägt er 2 Min. lang 60 % schneller: Heilercooldowns aufheben", "At 50% health he attacks 60% faster for 2 min: save healing cooldowns", "v" },
  },
  [11501] = { -- King Gordok (Dire Maul)
    { 22886, "survive", "Stürmt auf einen zufälligen Spieler und schleudert ihn hoch", "Charges a random player and tosses them up", "v" },
    { 15708, "tank", "Starker Schlag, halbiert Heilung am Tank", "Big hit that halves healing on the tank", "v" },
    { 16727, "avoid", "Betäubt alle im 5-m-Umkreis 4 Sek. lang", "Stuns all within 5 yards for 4 sec", "v" },
    { 15572, "tank", "Rüstung zerreißen senkt Tankrüstung: wechseln oder stärker heilen", "Sunder stacks lower the tank's armor: swap or heal harder", "v" },
  },
  [11502] = { -- Ragnaros (Molten Core)
    { 20566, "positioning", "Stößt Nahkampf zurück; Bedrohung kann wechseln, Zweittank bereit", "Knocks melee back; tank can lose threat, second tank ready" },
    { 20565, "tank", "Trifft Fernkämpfer, wenn keiner im Nahkampf ist; Nahkampf halten", "Hits ranged hard when nobody is in melee range; keep melee up" },
    { 20564, "tank", "Feuerschaden über Zeit auf sein Nahkampfziel", "Fire damage over time on his melee target" },
  },
  [11517] = { -- Oggleflint (Ragefire Chasm)
    { 15496, "positioning", "Spaltet den Tank und Spieler daneben: nur der Tank steht vorne", "Cleaves the tank and a neighbour: only the tank stands in front", "v" },
  },
  [11518] = { -- Jergosh the Invoker (Ragefire Chasm)
    { 20800, "dispel", "Feuerschaden über Zeit auf Spieler: gegenheilen oder bannen", "Fire damage over time on a player: heal through or dispel", "v" },
    { 18267, "dispel", "Fluch senkt Nahkampfschaden: Fluch vom Tank entfernen", "Curse lowers melee damage: remove the curse from the tank", "v" },
  },
  [11519] = { -- Bazzalan (Ragefire Chasm)
    { 744, "dispel", "Naturgift wirkt 15 Sek. lang: Gift beim Tank entfernen", "Nature poison ticks for 15 sec: cure poison on the tank", "v" },
    { 14873, "tank", "Schnelle harte Schläge auf den Tank: gleichmäßig heilen", "Quick hard strikes on the tank: keep healing steady", "v" },
    { 2818, "dispel", "**Tödliches Gift** auf dem Tank: Gift entfernen", "Deadly poison on the tank: cure poison", "v" },
  },
  [11520] = { -- Taragaman the Hungerer (Ragefire Chasm)
    { 18072, "positioning", "**Aufwärtshaken** schleudert Ziele zurück: Tank mit dem Rücken zur Wand, weg von der Lava", "Uppercut knocks targets back: tank with your back to a wall, away from lava", "v" },
    { 11970, "avoid", "**Feuerstoß** um ihn herum: Begleiter und Fernkämpfer auf Abstand halten", "Fire burst around him: keep pets and ranged out of melee range", "v" },
  },
  [11551] = { -- Necrofiend (Scholomance)
    { 15474, "survive", "Wurzelt alle in der Nähe; Gift entfernen", "Roots everyone nearby; poison needs curing" },
  },
  [11582] = { -- Scholomance Dark Summoner (Scholomance)
    { 17618, "interrupt", "Beschwört Skelette; unterbrechen und zuerst töten", "Summons skeletons; interrupt and kill first" },
    { 12279, "dispel", "Fluch erhöht körperlichen Schaden; entfluchen", "Curse raises physical damage taken; decurse" },
  },
  [11583] = { -- Nefarian (Blackwing Lair)
    { 22539, "tank", "**Schattenflamme** nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
    { 22686, "survive", "Furcht auf den ganzen Raid; Furchtzauberschutz oder Erdstoßtotem", "Raid fear; Fear Ward or Tremor Totem" },
    { 22687, "dispel", "Fluch senkt Heilung am Tank; entfluchen", "Curse cuts healing on the tank; decurse" },
    { 23401, "survive", "Priester-Ruf: Heilungen schaden; Priester pausieren", "Priest class call: their heals hurt; priests stop healing" },
  },
  [11622] = { -- Rattlegore (Scholomance)
    { 11876, "survive", "Flächenbetäubung um ihn; Nahkämpfer brauchen Heilung", "AoE stun around him; melee need heals ready", "v" },
    { 18945, "tank", "Schlägt den Tank weg; lässt den Schlüssel zum Sichtraum fallen", "Knocks the tank back; drops the Viewing Room Key", "v" },
    { 18368, "tank", "Härterer Nahkampftreffer auf den Tank; vorausheilen", "Harder melee hit on the tank; heal ahead", "v" },
  },
  [11658] = { -- Molten Giant (Molten Core)
    { 18944, "positioning", "Schwerer Flächenschlag; Nicht-Tanks halten Abstand", "Heavy AoE hit around it; non-tanks keep distance" },
    { 18945, "tank", "Stößt den Tank zurück und senkt Bedrohung", "Knocks the tank back and lowers threat" },
  },
  [11659] = { -- Molten Destroyer (Molten Core)
    { 19129, "positioning", "Starkes Beben um ihn; Nahkampf tritt heraus", "Strong quake around it; melee step out" },
    { 20276, "tank", "Wirft den Tank kurz zu Boden", "Knocks the tank down for a short stun" },
  },
  [11666] = { -- Firewalker (Molten Core)
    { 19635, "survive", "Feuer-AoE über den ganzen Bereich", "Fire AoE that hits the whole area" },
    { 19636, "avoid", "Feuerstöße auf Spieler; verteilen", "Fire bursts on players; spread out" },
  },
  [11667] = { -- Flameguard (Molten Core)
    { 19630, "positioning", "**Feuerkegel** nach vorn; nur der Tank steht davor", "Fire cone in front; only the tank faces it" },
    { 19631, "tank", "Senkt die Rüstung des Tanks", "Reduces the tank's armor" },
  },
  [11668] = { -- Firelord (Molten Core)
    { 19392, "adds", "Ruft Lavabrut, die sich teilt; schnell töten", "Spawns Lava Spawns that split if left alive; kill fast" },
    { 19393, "dispel", "Magie-Debuff, der Mana verbrennt; bannen", "Magic debuff that burns mana; dispel it" },
  },
  [11671] = { -- Core Hound (Molten Core)
    { 19771, "tank", "Fünferrudel; blutender Biss, alle möglichst gleichzeitig töten", "Packs of five; bleeding bite, kill all close together" },
  },
  [11673] = { -- Ancient Core Hound (Molten Core)
    { 19272, "avoid", "Feueratem nach vorn; Raid hinter oder neben ihm", "Fire breath in front; keep the raid behind or at its side" },
    { 19365, "survive", "Nutzt je Spawn eine zufällige Debuff-Aura; prüfen welche", "Uses one random debuff aura per spawn; check which one" },
    { 19364, "survive", "Stampfen betäubt Spieler in der Nähe", "Stomp that stuns nearby players" },
  },
  [11784] = { -- Theradrim Guardian (Maraudon)
    { 21057, "adds", "Ruft Theradrimsplitter herbei; per AoE töten", "Spawns shardling adds; AoE them down" },
  },
  [11785] = { -- Ambereye Basilisk (Maraudon)
    { 11020, "survive", "**Versteinern** macht einen Spieler kurz handlungsunfähig", "**Petrify** turns a player to stone for a short time" },
  },
  [11790] = { -- Putridus Satyr (Maraudon)
    { 12540, "tank", "**Solarplexus** trifft den Tank; zweiter Spieler mit Bedrohung hilft", "Gouges the tank; a second player with threat picks it up" },
  },
  [11791] = { -- Putridus Trickster (Maraudon)
    { 15657, "positioning", "**Meucheln** von hinten; zum Tank gedreht halten", "Backstabs from behind; keep it facing the tank" },
  },
  [11792] = { -- Putridus Shadowstalker (Maraudon)
    { 22766, "positioning", "Getarnt um Vyletongue; vorsichtig vorrücken", "Stealthed around Vyletongue; move carefully" },
  },
  [11793] = { -- Celebrian Dryad (Maraudon)
    { 7992, "dispel", "Verlangsamendes Gift auf Spielern; Gift entfernen", "Slowing Poison on players; cure poison" },
    { 17201, "survive", "Entfernt Stärkungszauber der Gruppe", "Strips buffs from the group" },
  },
  [11831] = { -- Hakkari Witch Doctor (Zul'Gurub)
    { 24053, "dispel", "Verhext einen Spieler; bannen", "Hexes a player; dispel" },
    { 24054, "dispel", "Schrumpft Spieler, senkt Schaden; bannen", "Shrinks a player and lowers damage; dispel" },
  },
  [11981] = { -- Flamegor (Blackwing Lair)
    { 23342, "tank", "**Raserei**; Jäger entfernen sie per **Einlullender Schuss**", "**Frenzy**; hunters remove it with Tranquilizing Shot" },
    { 22539, "tank", "**Schattenflamme** nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
    { 23339, "tank", "Rückstoß senkt Bedrohung", "Knocks back and drops threat" },
  },
  [11982] = { -- Magmadar (Molten Core)
    { 19451, "tank", "Gerät oft in **Raserei**; Jäger entfernen sie per **Einlullender Schuss**", "Frenzies often; hunters must remove it with Tranquilizing Shot" },
    { 19408, "survive", "Raidweite Furcht; Furchtzauberschutz oder Totem des Erdstoßes für den Tank", "Raid-wide fear; Fear Ward or Tremor Totem on the tank" },
    { 19411, "avoid", "Hinterlässt brennende Lavapfützen am Boden; heraustreten", "Leaves burning lava patches on the floor; step out" },
  },
  [11983] = { -- Firemaw (Blackwing Lair)
    { 23341, "positioning", "Stapelnder Feuer-Debuff; Sichtlinie brechen", "Stacking fire debuff on the raid; break line of sight" },
    { 23339, "tank", "Rückstoß senkt Bedrohung; Tanks wechseln", "Knocks back and drops threat; tanks swap" },
    { 22539, "tank", "**Schattenflamme** nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
  },
  [11988] = { -- Golemagg the Incinerator (Molten Core)
    { 20553, "positioning", "Kernwüter in seiner Nähe werden stärker; Hunde weg tanken", "Core Ragers near him get stronger; tank the dogs away" },
    { 13880, "tank", "Stapelnder Rüstungs- und Feuer-Debuff auf dem Tank", "Stacking armor and fire debuff on the tank" },
    { 19798, "survive", "Unter 10 % Leben **Erdbeben** gegen Nahkämpfer; schnell töten", "Below 10% health quakes hurt all melee; burn him fast" },
  },
  [12017] = { -- Broodlord Lashlayer (Blackwing Lair)
    { 24573, "tank", "**Harter Schlag** senkt Heilung am Tank", "Big hit that cuts healing on the tank" },
    { 23331, "positioning", "Feuerschaden im Umkreis um ihn; Zauberer auf Abstand", "Fire AoE around him; casters keep range" },
    { 18670, "tank", "Stößt Tank zurück, senkt Bedrohung; Ersatztank bereit", "Knocks the tank back and cuts threat; keep a backup tank" },
  },
  [12018] = { -- Majordomo Executus (Molten Core)
    { 20619, "avoid", "Adds reflektieren Zauber; Zauberer pausieren", "Adds reflect spells while active; casters stop casting" },
    { 21075, "avoid", "Adds schaden Nahkämpfern; Nahkampf pausiert", "Adds hurt melee attackers while active; melee stop" },
    { 20534, "tank", "Schickt einen zufälligen Spieler in die Lavagrube; heilen", "Sends a random player into the lava pit; heal them out" },
  },
  [12056] = { -- Baron Geddon (Molten Core)
    { 20475, "positioning", "Ziel explodiert nach Sekunden; vom Raid weglaufen", "Target explodes after a few seconds; run away from the raid" },
    { 19659, "dispel", "Verbrennt Mana mit Schaden; Magie bei Zauberern bannen", "Burns mana and deals damage; dispel magic on casters" },
    { 19695, "avoid", "Pulsierendes Feuer um ihn; Nahkampf weicht aus", "Pulsing fire around him; melee back away while it lasts" },
  },
  [12057] = { -- Garr (Molten Core)
    { 19492, "survive", "Puls entfernt Magie-Buffs naher Spieler; danach neu buffen", "Pulse strips magic buffs from nearby players; rebuff after" },
    { 19496, "positioning", "Verlangsamt Spieler in der Nähe; Fernkämpfer und Heiler verteilen", "Slows nearby players; keep ranged and healers spread out" },
    { 19516, "adds", "Wird pro getötetem Feuergeschworenen stärker; Adds getrennt halten", "Gains damage per Firesworn killed; tank or banish adds apart" },
  },
  [12098] = { -- Sulfuron Harbinger (Molten Core)
    { 19775, "interrupt", "Flammenschuppen-Priester heilen; jeden Zauber unterbrechen", "Flamewaker Priests heal allies; interrupt every cast" },
    { 19780, "survive", "Betäubt und stößt Spieler in seiner Nähe zurück", "Stuns and knocks back players near him" },
    { 19779, "tank", "Beschleunigt Angriffe naher Adds; Adds von ihm wegziehen", "Boosts attack speed of nearby adds; tank adds away from him" },
  },
  [12118] = { -- Lucifron (Molten Core)
    { 19702, "dispel", "Fluch, der beim Ablauf Schattenschaden macht; Flüche schnell entfernen", "Curse that deals shadow damage when it expires; remove curses fast" },
    { 19703, "dispel", "Fluch verdoppelt Mana- und Wutkosten; Raid entfluchen", "Curse doubles mana and rage costs; decurse the raid" },
    { 20604, "dispel", "Übernimmt einen Spieler; bannen oder kontrollieren", "Mind-controls a player; dispel or crowd-control the victim" },
  },
  [12119] = { -- Flamewaker Protector (Molten Core)
    { 20604, "dispel", "Übernimmt einen Spieler; bannen oder kontrollieren", "Mind-controls a player; dispel or crowd-control" },
  },
  [12129] = { -- Onyxian Warder (Onyxia's Lair)
    { 20203, "positioning", "**Feuernova** um ihn; Zauberer und Heiler auf Abstand", "**Fire nova** around it; casters and healers keep range" },
    { 18958, "tank", "**Flammenpeitsche** auf sein Ziel", "Fire lash on its target" },
    { 12097, "tank", "Senkt die Rüstung des Tanks", "Lowers the tank's armor" },
  },
  [12201] = { -- Princess Theradras (Maraudon)
    { 21869, "survive", "**Abstoßender Blick** lässt Spieler fliehen; Furchtschutz oder Erdstoß", "**Repulsive Gaze** fears nearby players; Fear Ward or Tremor", "v" },
    { 21868, "avoid", "**Staubfeld** schadet in ihrer Nähe; Nahkampf kurz raus", "**Dust Field** hurts players close to her; melee step out", "v" },
    { 9483, "survive", "Wirft Felsbrocken auf Spieler auf Distanz", "Throws boulders at players at range", "v" },
  },
  [12203] = { -- Landslide (Maraudon)
    { 10101, "tank", "Schlägt den Tank weg und senkt Bedrohung; Ersatztank bereit", "Knocks the tank back and drops threat; second tank ready", "v" },
    { 5568, "positioning", "**Trampeln** trifft Spieler neben dem Tank: Nahkämpfer verteilen", "**Trample** hits players next to the tank: melee spread a bit", "v" },
    { 21808, "adds", "Ruft Felssplitter; sie sterben mit ihm, notfalls AoE", "Calls rock shardlings; they die with him, AoE if needed" },
  },
  [12206] = { -- Primordial Behemoth (Maraudon)
    { 21071, "survive", "Wirft Felsbrocken auf Distanz; um die Ecke ziehen", "Hurls boulders at range; pull it around a corner" },
  },
  [12225] = { -- Celebras the Cursed (Maraudon)
    { 21793, "interrupt", "Kanalisiert **Verderbte Gelassenheit**; Kanalisierung unterbrechen", "Channels **Twisted Tranquility**; interrupt the channel", "v" },
    { 12747, "dispel", "Wurzelt Spieler fest; Magie bannen", "Roots players in place; dispel magic", "v" },
    { 9739, "interrupt", "**Zorn** auf einen Spieler: unterbrechen", "**Wrath** on a player: interrupt it", "v" },
    { 6913, "adds", "Beschwört Treants: Begleiter tanken und töten", "Summons treants: tank and kill the adds", "v" },
    { 21968, "adds", "Ruft verderbte Pflanzen herbei; aufnehmen und töten", "Summons corrupted plant adds; tank and kill them" },
  },
  [12236] = { -- Lord Vyletongue (Maraudon)
    { 1953, "positioning", "Teleportiert sich weg und schießt; Tank und Nahkampf folgen", "Blinks away and shoots; tank and melee chase him", "v" },
    { 7964, "survive", "**Rauchbombe** betäubt Spieler in seiner Nähe", "**Smoke Bomb** stuns players near him", "v" },
    { 14443, "avoid", "**Mehrfachschuss** trifft mehrere Spieler: verteilen", "**Multi-shot** hits several players: spread out", "v" },
  },
  [12237] = { -- Meshlok the Harvester (Maraudon)
    { 11876, "survive", "**Kriegsdonner** betäubt alle in der Nähe; Zauberer Abstand halten", "**War Stomp** stuns everyone close; casters stay at range", "v" },
    { 15501, "interrupt", "**Erdschock** auf einen Spieler: wenn möglich unterbrechen", "**Earth shock** on a player: interrupt when you can", "v" },
    { 13446, "tank", "Trifft den Tank mit einem härteren Nahkampfschlag; abseits der Gruppe tanken", "Hits the tank with a heavier melee strike; tank him away from the group", "v" },
  },
  [12258] = { -- Razorlash (Maraudon)
    { 15284, "positioning", "Spaltet nach vorn; nur der Tank steht vor ihm", "Cleaves in front; only the tank faces him", "v" },
    { 15976, "tank", "**Durchbohren** senkt die Tank-Rüstung; Tank gut heilen", "**Puncture** shreds tank armor; heal the tank up", "v" },
  },
  [12259] = { -- Gehennas (Molten Core)
    { 19716, "dispel", "Fluch senkt erhaltene Heilung um 75 %; schnell entfluchen", "Curse cuts healing taken by 75%; decurse quickly" },
    { 19717, "avoid", "**Feuerregen** auf Spielergruppe; sofort herauslaufen", "Fire rain on a group of players; move out at once" },
  },
  [12264] = { -- Shazzrah (Molten Core)
    { 19712, "positioning", "Starke Arkan-AoE um ihn; nur Nahkampf und Tank stehen nah", "Heavy arcane AoE around him; only melee and tank stay close" },
    { 23138, "tank", "Teleportiert zu einem zufälligen Spieler, Bedrohung weg; Tanks holen ihn", "Blinks to a random player and wipes threat; tanks re-pick him" },
    { 19713, "dispel", "Fluch verdoppelt erlittenen Magieschaden; entfluchen", "Curse doubles magic damage taken; decurse" },
    { 19714, "dispel", "Selbstbuff halbiert Magieschaden; reinigen oder bannen", "Self buff halves magic damage; purge or dispel it" },
  },
  [12435] = { -- Razorgore the Untamed (Blackwing Lair)
    { 19873, "adds", "Phase 1: gesteuerter Boss zerstört Eier, Raid hält die Adds", "Phase 1: mind-controlled boss breaks eggs while raid holds adds" },
    { 22425, "avoid", "In Phase 2 **Feuerballsalve**; hinter Säulen verstecken", "Phase 2 **fireball volley**; hide behind pillars" },
    { 23023, "tank", "Desorientiert den Tank mit Feuer; anderer Tank übernimmt", "Disorients the tank with fire; another tank takes over" },
  },
  [12457] = { -- Blackwing Spellbinder (Blackwing Lair)
    { 22274, "dispel", "Verwandelt einen Spieler; Magie bannen", "Polymorphs a player; dispel magic" },
    { 22275, "avoid", "**Flammenstoß** am Boden; heraustreten", "**Flamestrike** on the ground; step out" },
  },
  [12458] = { -- Blackwing Taskmaster (Blackwing Lair)
    { 22458, "interrupt", "Heilt nahe Goblins; Zauber unterbrechen", "Heals nearby goblins; interrupt the cast" },
  },
  [12459] = { -- Blackwing Warlock (Blackwing Lair)
    { 22372, "adds", "Öffnet Portal mit Teufelswachen; töten oder verbannen", "Opens a portal that summons felguards; kill or banish them" },
  },
  [12460] = { -- Death Talon Wyrmguard (Blackwing Lair)
    { 22277, "survive", "Gegen die meisten Schulen immun; Schwäche finden", "Immune to most schools; find the one it is weak to" },
    { 24375, "survive", "Betäubt Spieler in seiner Nähe", "Stuns players close to it" },
  },
  [12461] = { -- Death Talon Overseer (Blackwing Lair)
    { 22277, "survive", "Gegen die meisten Schulen immun; Schwachstelle finden", "Immune to most schools; find its weak school" },
    { 15754, "positioning", "Spaltet nach vorn; nur der Tank steht davor", "Cleaves in front; only the tank faces it" },
  },
  [12464] = { -- Death Talon Seether (Blackwing Lair)
    { 22428, "tank", "**Raserei**; per **Einlullender Schuss** entfernen", "**Frenzy**; remove with Tranquilizing Shot" },
    { 22433, "survive", "Stapelnder Feuer-Debuff auf dem Raid", "Stacking fire debuff on the raid" },
  },
  [12467] = { -- Death Talon Captain (Blackwing Lair)
    { 22438, "positioning", "Markierte Spieler explodieren bei Treffern; verteilen", "Marked players explode when hit; spread out" },
    { 22436, "survive", "Feueraura stärkt die Gruppe; Hauptmann zuerst", "Fire aura buffs the pack; kill the captain first" },
    { 22440, "survive", "Ruf stärkt nahe Verbündete", "Shout that boosts nearby allies" },
  },
  [12876] = { -- Baron Aquanis (Blackfathom Deeps)
    { 15043, "interrupt", "Frostblitz unterbrechen, trifft hart und verlangsamt", "Interrupt Frostbolt, it hits hard and slows", "v" },
    { 15531, "avoid", "**Frostnova** friert Spieler in der Nähe ein; Fernkämpfer bleiben zurück", "Frost Nova roots players nearby; ranged stay back", "v" },
  },
  [12902] = { -- Lorgus Jett (Blackfathom Deeps)
    { 12550, "dispel", "**Blitzschlagschild** reinigen, sonst werden Nahkämpfer beim Treffen geschockt", "Purge his Lightning Shield or melee get zapped on every hit", "v" },
    { 12167, "interrupt", "Blitzschlag unterbrechen", "Interrupt Lightning Bolt", "v" },
  },
  [13020] = { -- Vaelastrasz the Corrupt (Blackwing Lair)
    { 18173, "positioning", "Ziel stirbt nach kurzer Zeit; vor der Explosion raus", "Target dies after a while; leave the raid before exploding" },
    { 23461, "positioning", "Atem nach vorn; nur der Tank steht davor", "Frontal breath; only the tank stands in front" },
    { 15847, "positioning", "Schwanz trifft Spieler hinter ihm; seitlich stehen", "Tail hits players behind him; stand at the sides" },
    { 23513, "survive", "Raid erhält Mana und Energie; schnell töten", "Raid gets free mana and energy; burn him fast" },
  },
  [13141] = { -- Deeprot Stomper (Maraudon)
    { 45, "survive", "**Kriegsdonner** betäubt alle in der Nähe", "**War Stomp** stuns everyone close", "v" },
  },
  [13142] = { -- Deeprot Tangler (Maraudon)
    { 12747, "dispel", "Wurzelt Spieler fest; Magie bannen", "Roots players in place; dispel magic", "v" },
  },
  [13280] = { -- Hydrospawn (Dire Maul)
    { 22419, "positioning", "Rückstoß mit kurzer Entwaffnung; Rücken zur Wand, vorher Trash räumen", "Knockback with short disarm; keep your back to a wall, clear trash first", "v" },
    { 22714, "adds", "Zwei Hydrolinge bei 50 %; ihre Treffer stoßen zurück und löschen Bedrohung", "Two Hydrolings at 50%; their hits knock back and wipe threat", "v" },
    { 22420, "positioning", "Taucht ab und wandert: bereit sein, ihn wieder aufzunehmen", "Submerges and moves: be ready to pick him up again", "v" },
    { 22421, "avoid", "Geysir schleudert Spieler hoch: verteilt stehen, Fall gegenheilen", "Geyser throws players up: stay spread and heal the fall", "v" },
    { 22715, "positioning", "Stößt Spieler in der Nähe weg und verlangsamt sie: mit dem Rücken zur Wand stehen", "Pushes nearby players away and slows them: stand with your back to a wall", "v" },
  },
  [13282] = { -- Noxxion (Maraudon)
    { 21687, "dispel", "**Giftsalve** trifft die Gruppe; Gifte entfernen", "Poison volley hits the whole group; cure poisons", "v" },
    { 18072, "tank", "**Aufwärtshaken** schleudert den Tank zurück: an der Wand tanken", "**Uppercut** knocks the tank back: tank against a wall", "v" },
    { 21707, "adds", "Teilt sich in kleine Brut auf und ist unangreifbar; Brut per AoE töten", "Splits into small spawns while untouchable; AoE them" },
  },
  [13323] = { -- Subterranean Diemetradon (Maraudon)
    { 8281, "survive", "**Schallexplosion** bringt Spieler in der Nähe zum Schweigen", "**Sonic Burst** silences players nearby" },
  },
  [13533] = { -- Spewed Larva (Maraudon)
    { 21862, "avoid", "**Strahlungsaura** schadet in der Nähe; auf Distanz töten", "**Radiation** aura hurts nearby players; kill from range" },
  },
  [13596] = { -- Rotgrip (Maraudon)
    { 16495, "tank", "**Tödlicher Biss** trifft den Tank sehr hart; durchheilen", "**Fatal Bite** hits the tank very hard; heal through it", "v" },
  },
  [13601] = { -- Tinkerer Gizlock (Maraudon)
    { 13183, "avoid", "Feuerkegel vor ihm; aus dem Kegel gehen", "Fire cone in front of him; step out of it", "v" },
    { 8858, "survive", "Wirft Bomben mit Flächenschaden", "Throws bombs that hit players in an area", "v" },
    { 6660, "survive", "Beschießt einen Spieler auf Distanz mit einem normalen Fernangriff", "Shoots a player at range with a normal ranged attack", "v" },
  },
  [13996] = { -- Blackwing Technician (Blackwing Lair)
    { 22334, "avoid", "Wirft Bomben auf den Raid; aus der Explosion gehen", "Throws bombs at the raid; step out of the blast" },
  },
  [14020] = { -- Chromaggus (Blackwing Lair)
    { 23310, "avoid", "Einer von zwei Zufallsatems; hinter Torwänden verstecken", "One of two random breaths; hide behind the gate walls" },
    { 23170, "dispel", "Betäubt zufällig; nur Stundenglassand entfernt es", "Stuns randomly; only Hourglass Sand removes it" },
    { 23174, "dispel", "Fünf Gebrechen machen Spieler feindlich; früh reinigen", "Five afflictions turn a player hostile; cleanse early" },
    { 23128, "tank", "**Raserei**; per **Einlullender Schuss** entfernen", "**Frenzy**; remove with Tranquilizing Shot" },
  },
  [14321] = { -- Guard Fengus (Dire Maul)
    { 15749, "positioning", "Zufälliger Ansturm mit Rückstoß in andere Gruppen", "Random charge with knockback into other packs", "v" },
    { 10101, "tank", "Schlägt den Tank weg: mit dem Rücken zur Wand tanken", "Knocks the tank away: tank with the back to a wall", "v" },
    { 8269, "tank", "Wut beschleunigt seine Angriffe: Tank braucht gleichmäßige Heilung", "Enrage speeds up his attacks: tank needs steady healing", "v" },
    { 11972, "interrupt", "Schildschlag unterbricht einen Zauber: Zauberer Abstand halten oder Zauber abpassen", "Shield bash interrupts a cast: casters keep distance or time casts", "v" },
    { 0, "adds", "Raserei und Hilferuf bei 50 %", "Frenzies and calls help at 50%" },
  },
  [14322] = { -- Stomper Kreeg (Dire Maul)
    { 22833, "positioning", "Kegel nach vorn senkt Trefferchance um 75 %; nur Tank vorne", "Frontal cone cuts hit chance by 75%; only the tank in front", "v" },
    { 15577, "avoid", "Wirbelt, trifft alle im 8-m-Umkreis", "Spins hitting all within 8 yards", "v" },
    { 22835, "tank", "Ab 50 % setzt jeder Treffer die Bedrohung zurück; er wandert", "From 50% his threat resets on each hit; he roams", "v" },
    { 16740, "positioning", "Kriegsdonner betäubt Spieler in der Nähe: Fernkämpfer bleiben hinten", "War stomp stuns nearby players: ranged stay back", "v" },
    { 8269, "tank", "Wut beschleunigt seine Angriffe: Tank braucht gleichmäßige Heilung", "Enrage speeds up his attacks: tank needs steady healing", "v" },
  },
  [14323] = { -- Guard Slip'kik (Dire Maul)
    { 15749, "positioning", "Ansturm mit Rückstoß; mit Frostöl in der Falle umgehbar", "Charge with knockback; skip him with frost oil in the trap", "v" },
    { 8269, "tank", "Bei 50 % Leben 60 % schnellere Angriffe und Hilferuf", "At 50% attacks 60% faster and calls help", "v" },
    { 10101, "tank", "Schlägt den Tank weg: mit dem Rücken zur Wand tanken", "Knocks the tank away: tank with the back to a wall", "v" },
    { 11972, "interrupt", "Schildschlag unterbricht einen Zauber: Zauberer Abstand halten oder Zauber abpassen", "Shield bash interrupts a cast: casters keep distance or time casts", "v" },
  },
  [14324] = { -- Cho'Rush the Observer (Dire Maul)
    { 11642, "interrupt", "Heilt sich und König Gordok; unterbrechen, zuerst töten", "Heals himself and King Gordok; interrupt and kill him first", "v" },
    { 22884, "survive", "Furcht auf Spieler im 8-m-Umkreis", "Fears players within 8 yards", "v" },
    { 17194, "interrupt", "Gedankenschlag auf einen Spieler: wenn möglich unterbrechen", "Mind blast on a player: interrupt when possible", "v" },
    { 17139, "dispel", "Schildet sich selbst: Schild bannen", "Shields himself: dispel the shield", "v" },
  },
  [14325] = { -- Captain Kromcrush (Dire Maul)
    { 22857, "tank", "Ab 25 % 8 Sek. lang Vergeltung gegen Nahkämpfer; Nahkämpfer pausieren", "At 25% strikes back at melee for 8 sec; melee pause", "v" },
    { 22860, "adds", "Ruft Plünderer zur Hilfe: Begleiter töten oder kontrollieren", "Calls reavers as helpers: kill or control the adds", "v" },
    { 8599, "tank", "Wütet bei wenig Leben: Abklingzeiten fürs Ende aufheben", "Enrages at low health: save cooldowns for the end", "v" },
    { 19134, "survive", "Schrei lässt Spieler fliehen: Furchtschutz nutzen", "Shout fears nearby players: use fear protection", "v" },
    { 22859, "tank", "Tödliches Spalten trifft den Tank und senkt Heilung: Tank beobachten", "Mortal cleave hits the tank and reduces healing: watch the tank", "v" },
    { 0, "survive", "Lässt Spieler in der Nähe 6 Sek. lang fliehen", "Fears nearby players for 6 sec" },
    { 0, "adds", "Ruft zwei Gordok-Häscher; kontrollieren oder schnell töten", "Summons two Gordok Reavers; crowd control or kill fast" },
  },
  [14326] = { -- Guard Mol'dar (Dire Maul)
    { 11972, "survive", "Unterbricht Zauberer im Nahkampf 3 Sek. lang", "Interrupts casters in melee range for 3 sec", "v" },
    { 10101, "tank", "Schlägt den Tank weg: mit dem Rücken zur Wand tanken", "Knocks the tank away: tank with the back to a wall", "v" },
    { 15749, "positioning", "Schildansturm betäubt einen Spieler: nah am Tank bleiben", "Shield charge stuns a player: stay close to the tank", "v" },
    { 22818, "survive", "Erhöht seine Ausdauer um 15 % für die ganze Wächtergruppe", "Raises his stamina by 15% for the whole group of guards", "v" },
    { 8269, "tank", "Wut beschleunigt seine Angriffe: Tank braucht gleichmäßige Heilung", "Enrage speeds up his attacks: tank needs steady healing", "v" },
    { 0, "adds", "Bei 50 % Raserei, ruft Hunde in der Nähe; diese vorher räumen", "At 50% frenzies and calls nearby dogs; clear them first" },
  },
  [14327] = { -- Lethtendris (Dire Maul)
    { 22709, "interrupt", "Starker Schattenblitz auf ein Ziel; unterbrechen", "Heavy shadow bolt on one target; interrupt it", "v" },
    { 13338, "dispel", "Fluch halbiert Zaubertempo; bei Zauberern und Heilern entfluchen", "Curse halves casting speed; decurse casters and healers", "v" },
    { 22710, "adds", "Stärkt ihren Wichtel Pimgib; den schwachen Wichtel zuerst töten", "Buffs her imp Pimgib; kill the frail imp first", "v" },
    { 14887, "survive", "Schattensalve trifft die ganze Gruppe: Heiler alle voll halten", "Shadow volley hits the whole group: healers top everyone off", "v" },
    { 20787, "dispel", "Feuerschaden über Zeit auf Spieler: bannen oder gegenheilen", "Fire damage over time on a player: dispel or heal through", "v" },
    { 16247, "dispel", "Fluch verletzt Angreifer zeitweise: Betroffene entfluchen", "Curse makes attackers take damage sometimes: decurse the affected", "v" },
  },
  [14354] = { -- Pusillin (Dire Maul)
    { 17145, "avoid", "Feuernova um ihn verlangsamt Spieler; Fernkämpfer nicht in Nahkampfreichweite", "Fire nova around him slows; ranged stay out of melee range", "v" },
    { 22735, "survive", "Wächst am Ende und reflektiert Zauber; Nahkampf und physischer Schaden sicherer", "Grows and reflects spells at the end; melee and physical damage are safer", "v" },
    { 14145, "interrupt", "Feuerschlag auf einen Spieler: wenn möglich unterbrechen", "Fire blast on a player: interrupt when you can", "v" },
    { 15242, "interrupt", "Feuerball auf einen Spieler: unterbrechen", "Fireball on a player: interrupt it", "v" },
  },
  [14386] = { -- Wandering Eye of Kilrogg (Dire Maul)
    { 22876, "adds", "Entdeckt Eindringlinge, ruft Netherwandler; meiden oder schnell töten", "Spots intruders and summons Netherwalkers; avoid or kill fast" },
  },
  [14506] = { -- Lord Hel'nurath (Dire Maul)
    { 20812, "dispel", "Halbiert Stärke und Bewegung eines Spielers und verlangsamt Angriffe 15 Sek. lang", "Halves a player's strength and movement and slows attacks for 15 sec", "v" },
    { 22665, "survive", "Schattenblitze treffen alle in der Nähe: Gruppe heilen", "Shadow bolts hit everyone nearby: heal the group", "v" },
  },
  [14507] = { -- High Priest Venoxis (Zul'Gurub)
    { 23860, "interrupt", "**Heiliges Feuer** auf Spieler; unterbrechen oder bannen", "**Holy Fire** on a player; interrupt or dispel" },
    { 23861, "avoid", "Schlangenphase Giftwolken; herausgehen", "Snake phase poison clouds; move out" },
    { 23865, "adds", "Kleine Schlangen greifen an; per AoE töten", "Small snakes attack players; AoE them down" },
  },
  [14509] = { -- High Priest Thekal (Zul'Gurub)
    { 24208, "interrupt", "Heilt; unterbrechen. Alle drei Priester fast gleichzeitig töten", "Heals; interrupt; kill all three priests near together" },
    { 24183, "adds", "Tigerphase ruft Wächter; weg tanken", "Tiger phase calls guardians; tank them away" },
    { 21060, "survive", "Blendet einen Spieler eine Zeit lang", "Blinds a player for a while" },
  },
  [14510] = { -- High Priestess Mar'li (Zul'Gurub)
    { 24083, "adds", "Brütet Spinneneier aus; Spinnen vor dem Wachsen töten", "Hatches spider eggs; kill spiders before they grow" },
    { 24111, "dispel", "Gift auf Spielern; Gift entfernen", "Poison on players; cure poison" },
    { 24300, "interrupt", "Saugt einem Spieler Leben ab; unterbrechen", "Drains life from a player; interrupt" },
  },
  [14515] = { -- High Priestess Arlokk (Zul'Gurub)
    { 24210, "adds", "Panther jagen den Markierten; schützen oder kiten", "Panthers hunt the marked player; protect or kite" },
    { 24212, "dispel", "Schatten-DoT; Magie bannen", "Shadow DoT; dispel magic" },
  },
  [14516] = { -- Death Knight Darkreaver (Scholomance)
    { 0, "adds", "Beschwörung: Geisterwellen töten, bevor er erscheint", "Summoning event: kill the spirit waves before he appears" },
    { 7645, "interrupt", "Kann Spieler übernehmen; unterbrechen oder kontrollieren", "Can mind-control a player; interrupt or crowd-control" },
  },
  [14517] = { -- High Priestess Jeklik (Zul'Gurub)
    { 23954, "interrupt", "Heilt sich selbst; jeden Zauber unterbrechen", "Heals herself; interrupt every cast" },
    { 23918, "survive", "Flächenstille um sie herum", "AoE silence around her" },
    { 22884, "survive", "Versetzt Spieler in ihrer Nähe in Furcht", "Fears players close to her" },
  },
  [14601] = { -- Ebonroc (Blackwing Lair)
    { 23340, "tank", "Heilt ihn bei Treffern auf verfluchten Tank; Tanks wechseln", "Heals him when he hits the cursed tank; swap tanks" },
    { 22539, "tank", "**Schattenflamme** nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
    { 23339, "tank", "Rückstoß senkt Bedrohung", "Knocks back and drops threat" },
  },
  [14834] = { -- Hakkar (Zul'Gurub)
    { 24324, "survive", "Saugt den Raid aus; Giftblut verhindert seine Heilung", "Drains the raid; carry Poisonous Blood to avoid it healing" },
    { 24328, "positioning", "Sich ausbreitender Blut-DoT; verteilt stehen", "Spreading blood DoT; stay spread out" },
    { 24327, "dispel", "Übernimmt einen Spieler; kontrollieren oder bannen", "Mind-controls a player; crowd-control or dispel" },
  },
  [14861] = { -- Blood Steward of Kirtonos (Scholomance)
    { 22371, "dispel", "Flüche entfernen; er lässt das Blut der Unschuldigen fallen", "Remove his curses; he drops the Blood of Innocents", "v" },
    { 3609, "survive", "Gift betäubt einen Spieler kurz; Heiler überbrücken", "Poison stuns a player for a few seconds; healers cover the gap", "v" },
    { 11708, "dispel", "Fluch senkt Nahkampfschaden: entfernen", "Curse lowers melee damage: remove it", "v" },
  },
  [15082] = { -- Gri'lek (Zul'Gurub)
    { 24646, "positioning", "Wächst und jagt einen zufälligen Spieler; dieser kitet", "Grows and chases a random player; that player kites" },
    { 24648, "dispel", "Wurzelt Spieler fest; Magie bannen", "Roots players; dispel magic" },
  },
  [15083] = { -- Hazza'rah (Zul'Gurub)
    { 24728, "adds", "Illusionen erscheinen; schnell töten", "Illusions spawn; kill them quickly" },
    { 24664, "dispel", "Schläfert Spieler ein; Magie bannen", "Puts players to sleep; dispel magic" },
    { 24684, "survive", "**Kettenmanabrand** auf Zauberer", "Chained mana burn on casters" },
  },
  [15084] = { -- Renataki (Zul'Gurub)
    { 24699, "tank", "Verschwindet, taucht bei jemandem auf; Tank holt ihn", "Vanishes and reappears on someone; tank re-picks him" },
    { 24649, "survive", "**Klingenwirbel** auf nahe Spieler", "Blade flurry on nearby players" },
  },
  [15085] = { -- Wushoolay (Zul'Gurub)
    { 24683, "avoid", "**Blitzwolke** am Boden; heraustreten", "**Lightning cloud** on the ground; step out" },
    { 24680, "positioning", "**Kettenblitz** springt; verteilen", "**Chain lightning** jumps; spread out" },
  },
  [15114] = { -- Gahz'ranka (Zul'Gurub)
    { 22421, "survive", "Schleudert Spieler hoch; Fallschaden", "Throws players into the air; fall damage hurts" },
    { 16099, "positioning", "**Frostatem** nach vorn; seitlich stehen", "Frontal **frost breath**; stand at his sides" },
  },
  [15233] = { -- Vekniss Guardian (Temple of Ahn'Qiraj)
    { 26025, "survive", "**Aufspießen** verursacht Schaden über Zeit; Ziel heilen", "**Impale** deals bleeding damage over time; heal the target" },
    { 8599, "tank", "Rast bei wenig Leben; schnell töten", "Enrages at low health; burn it down" },
  },
  [15246] = { -- Qiraji Mindslayer (Temple of Ahn'Qiraj)
    { 26079, "dispel", "Übernimmt einen Spieler; Opfer kontrollieren", "Mind-controls a player; crowd-control the victim" },
    { 0, "interrupt", "Verbrennt Mana; unterbrechen oder betäuben", "Burns mana; interrupt or stun it" },
  },
  [15250] = { -- Qiraji Slayer (Temple of Ahn'Qiraj)
    { 18327, "survive", "Bringt nahe Spieler zum Schweigen; Zauberer Abstand halten", "Silences nearby players; casters keep distance" },
    { 26041, "tank", "Wut beschleunigt Angriffe; Tank-Abklingzeiten bereithalten", "Enrage speeds up its attacks; save tank cooldowns" },
    { 10101, "tank", "Schlägt den Tank zurück; an einer Wand tanken", "Knocks the tank back; tank against a wall" },
  },
  [15252] = { -- Qiraji Champion (Temple of Ahn'Qiraj)
    { 19134, "survive", "Furcht auf nahe Spieler; Furchtschutz nutzen", "Fears nearby players; use fear protection" },
    { 11130, "tank", "Schlägt Spieler zurück; an einer Wand tanken", "Knocks players back; tank against a wall" },
    { 25164, "tank", "Wird schneller in Angriff und Bewegung; fest abtanken", "Gains attack and movement speed; keep it tanked" },
  },
  [15262] = { -- Obsidian Eradicator (Temple of Ahn'Qiraj)
    { 26458, "survive", "Schlägt bei vollem Mana auf den Raid ein; Mana schnell entziehen", "Blasts the raid at full mana; drain its mana fast" },
    { 0, "survive", "Entzieht Heilern und Zauberern Mana, um sich zu füllen", "Drains mana from healers and casters to fill itself" },
  },
  [15263] = { -- The Prophet Skeram (Temple of Ahn'Qiraj)
    { 26192, "interrupt", "**Arkane Explosion** bei Skeram und jedem Abbild unterbrechen", "Interrupt **Arcane Explosion** on Skeram and on each image" },
    { 785, "dispel", "Übernimmt einen Spieler mit Schadensbonus; Opfer kontrollieren", "Mind-controls a player with buffed damage; crowd-control the victim" },
    { 747, "adds", "Teilt sich bei Lebensschwellen in Abbilder; alle tanken, echten finden", "Splits into images at health thresholds; tank all and find the real one" },
    { 26194, "tank", "**Erdschock** trifft, wer nicht im Nahkampf steht; immer einen Tank dran", "Earth Shocks whoever is not in melee range; keep a tank on him" },
  },
  [15264] = { -- Anubisath Sentinel (Temple of Ahn'Qiraj)
    { 0, "positioning", "Kommen in Gruppen; jeder Tod gibt Fähigkeiten weiter, trennen", "Pulled in groups; each death passes its abilities on, pull apart" },
    { 0, "avoid", "Manche reflektieren Magieschulen; Zauberer vorher prüfen", "Some reflect schools of magic; casters check before nuking" },
  },
  [15275] = { -- Emperor Vek'nilash (Temple of Ahn'Qiraj)
    { 26613, "tank", "Schwerer Schlag senkt Verteidigung; nur ein starker Tank vorne", "Heavy strike lowers defense; only a geared tank faces him" },
    { 7393, "positioning", "Zwillinge heilen sich nah beieinander; weit getrennt halten", "Twins heal each other when close; keep them far apart" },
    { 800, "tank", "Nach jedem Tausch folgen Nahkämpfer, Tanks spotten schnell", "After each swap, melee follow him and tanks taunt quickly" },
  },
  [15276] = { -- Emperor Vek'lor (Temple of Ahn'Qiraj)
    { 7393, "positioning", "Zwillinge heilen sich nah beieinander; weit getrennt halten", "Twins heal each other when close; keep them far apart" },
    { 800, "tank", "Zwillinge tauschen Plätze, Bedrohung weg; Tanks sofort übernehmen", "Twins swap places and wipe threat; tanks pick them up at once" },
    { 568, "positioning", "**Arkanstoß** trifft Nahkämpfer; auf Distanz mit Hexer-Tank kämpfen", "**Arcane Burst** blasts melee; fight him at range with a warlock tank" },
    { 804, "avoid", "Lässt einen Käfer explodieren; von leuchtenden Käfern weg", "Makes a bug explode; run away from glowing bugs" },
  },
  [15277] = { -- Anubisath Defender (Temple of Ahn'Qiraj)
    { 26558, "positioning", "**Meteor**schaden wird geteilt; Raid zusammen stehen", "**Meteor** damage is split; stack the raid to share it" },
    { 26556, "positioning", "Seuche trifft Umstehende; Infizierte laufen raus", "Plague hurts nearby allies; infected players run out" },
    { 26555, "positioning", "Schattenblitze treffen Spieler auf Distanz; nah heran", "Shadow bolts hit players at range; stand in close" },
    { 25698, "avoid", "Explodiert kurz vor dem Tod; alle weglaufen", "Explodes near death; everyone runs away" },
  },
  [15299] = { -- Viscidus (Temple of Ahn'Qiraj)
    { 25991, "dispel", "Naturgeschosse auf den Raid mit Gift-DoT; Gift entfernen", "Raid-wide nature volley with a poison DoT; cure poisons" },
    { 25993, "positioning", "Naturschlag im 15-m-Umkreis; nur Nahkämpfer nah dran", "Nature blast within 15 yards; only melee stand close" },
    { 25989, "avoid", "Giftwolken verlangsamen und schaden; heraustreten", "Toxin clouds slow and hurt; move out of them" },
    { 0, "adds", "Mit Frost einfrieren, zerschlagen, dann die Kleckse töten", "Freeze him with frost, shatter him, then kill the globs" },
  },
  [15311] = { -- Anubisath Warder (Temple of Ahn'Qiraj)
    { 26073, "survive", "**Feuernova** trifft alle in der Nähe; Heiler aufmerksam", "**Fire Nova** hits everyone close; healers stay alert" },
    { 26070, "survive", "Furcht auf viele Spieler; Furchtschutz nutzen", "Fears many players; use fear protection" },
    { 26071, "survive", "Wurzelt viele Spieler fest; befreien oder schnell töten", "Roots many players in place; free them or kill fast" },
  },
  [15335] = { -- Flesh Hunter (Ruins of Ahn'Qiraj)
    { 25371, "survive", "Verschlingt einen Spieler, macht Naturschaden und heilt sich", "Swallows a player, dealing nature damage and healing itself" },
    { 25424, "dispel", "Naturgeschoss mit Gift über Zeit; Gift entfernen", "Nature bolt with a poison over time; cure poison" },
  },
  [15338] = { -- Obsidian Destroyer (Ruins of Ahn'Qiraj)
    { 0, "survive", "Entzieht Mana und explodiert, wenn voll; Manaklassen fernhalten", "Drains raid mana and explodes when full; keep mana users away" },
  },
  [15339] = { -- Ossirian the Unscarred (Ruins of Ahn'Qiraj)
    { 25176, "positioning", "Riesiger Schadensbuff; ihn zu einem Kristall ziehen, um ihn zu entfernen", "Huge damage buff; pull him onto a crystal to remove it" },
    { 25189, "tank", "Hüllt den Tank in einen Wirbelwind; zweiter Tank muss übernehmen", "Stuns the tank in a cyclone; a second tank must take over" },
    { 25160, "avoid", "Wandernde Tornados machen hohen Schaden; ausweichen", "Roaming tornadoes deal heavy damage; stay out of them" },
    { 25195, "dispel", "Fluch verlangsamt Zauber stark; Zauberwirker schnell entfluchen", "Curse slows casting heavily; decurse casters fast" },
  },
  [15340] = { -- Moam (Ruins of Ahn'Qiraj)
    { 25671, "dispel", "Entzieht Spielern Mana für sich; Jäger entziehen ihm Mana zurück", "Drains mana from players to fill his own; hunters drain him back" },
    { 25672, "survive", "Bei vollem Mana trifft er den ganzen Raid; sein Mana niedrig halten", "At full mana he blasts the raid; keep his mana low" },
    { 25684, "adds", "Versteinert sich und ruft drei Manateufel; töten oder verbannen", "Turns to stone and summons three Mana Fiends; kill or banish them" },
    { 25685, "survive", "Gewinnt in versteinertem Zustand schnell Mana; Steinphase rasch beenden", "Gains mana fast while petrified; end the stone phase quickly" },
  },
  [15341] = { -- General Rajaxx (Ruins of Ahn'Qiraj)
    { 0, "adds", "Wellen von Qiraji mit Anführern; Andorov am Leben halten", "Waves of Qiraji led by named officers; keep Andorov alive" },
    { 25599, "survive", "Halbiert das Leben aller und stößt zurück; vor dem nächsten hochheilen", "Halves everyone's health and knocks back; heal up before the next" },
  },
  [15348] = { -- Kurinnaxx (Ruins of Ahn'Qiraj)
    { 25646, "tank", "Stapelnde Heilungsminderung auf dem Tank; bei vielen Stapeln Tank wechseln", "Stacking healing reduction on the tank; swap tanks at high stacks" },
    { 25656, "avoid", "**Sandfalle** senkt Trefferchance und bringt zum Schweigen; schnell raus", "**Sand trap** blinds and silences players nearby; step out quickly" },
    { 25814, "positioning", "**Kegelhieb** nach vorne; nur der Tank steht vor ihm", "Frontal cone slash; only the tank stands in front" },
    { 26527, "survive", "**Raserei** bei wenig Leben; schnell niederbrennen", "Frenzies at low health; burn him down fast" },
  },
  [15355] = { -- Anubisath Guardian (Ruins of Ahn'Qiraj)
    { 24340, "positioning", "Meteorschaden wird auf Getroffene verteilt; zusammenstehen", "Meteor damage is split among players hit; stack to share it" },
    { 22997, "positioning", "Nicht bannbare Seuche trifft Umstehende; Opfer läuft raus", "Undispellable plague hurts nearby allies; victim runs out" },
    { 26546, "positioning", "Schattenblitze treffen Spieler auf 25-45 m; nah dran stehen", "Shadow bolts hit players 25-45 yards away; stand close" },
    { 25698, "avoid", "Explodiert bei etwa 10 % Leben; Abstand nehmen", "Explodes near 10% health; move away from it" },
  },
  [15369] = { -- Ayamiss the Hunter (Ruins of Ahn'Qiraj)
    { 25748, "tank", "Stapelndes Gift auf dem Bedrohungsersten im Flug; nur Fernkampf", "Stacking poison on top threat while she flies; ranged only" },
    { 25749, "survive", "Naturschaden am ganzen Raid; Naturwiderstand hilft", "Nature damage on the whole raid; nature resistance helps" },
    { 25725, "adds", "Opfer am Altar; Larve töten, bevor sie ankommt", "Victim on the altar; kill the larva before it arrives" },
  },
  [15370] = { -- Buru the Gorger (Ruins of Ahn'Qiraj)
    { 0, "positioning", "Ihn über Eier ziehen und diese zerstören, um ihn zu schädigen", "Kite him over eggs and break them to damage him and slow him" },
    { 96, "avoid", "Stapelnde Blutung auf seinem Ziel; weiter weglaufen", "Stacking bleed on his chase target; keep kiting away" },
    { 25640, "survive", "Dornenaura schädigt Nahkämpfer", "Thorns aura hurts melee attackers" },
    { 20512, "survive", "Unter 20 % steigender Naturschaden am Raid; schnell töten", "Below 20% the raid takes rising nature damage; burn fast" },
  },
  [15509] = { -- Princess Huhuran (Temple of Ahn'Qiraj)
    { 26180, "survive", "Versetzt Nahkämpfer in Schlaf; Bannen verursacht Schaden, vorher heilen", "Sleeps melee; dispelling it deals damage, so heal before cleansing" },
    { 26053, "positioning", "Natur-DoT mit Stille, springt über; Fernkämpfer verteilen", "Nature DoT and silence that splashes; ranged stay spread out" },
    { 26051, "tank", "**Raserei** erhöht Nahkampfschaden; Jäger nutzen **Einlullenden Schuss**", "**Frenzy** boosts melee damage; hunters remove it with Tranquilizing Shot" },
    { 26068, "survive", "Berserker bei 30 %: Giftblitze auf nahe Spieler; schnell töten", "Berserk at 30%: poison bolts hit the closest players; burn her" },
  },
  [15510] = { -- Fankriss the Unyielding (Temple of Ahn'Qiraj)
    { 0, "tank", "Stapelnde Heilungsminderung auf dem Tank; Tanks wechseln", "Stacking healing reduction on the tank; swap tanks" },
    { 0, "adds", "Ruft Brut von Fankriss; töten, bevor sie rasen", "Spawns Spawn of Fankriss worms; kill them before they enrage" },
  },
  [15511] = { -- Lord Kri (Temple of Ahn'Qiraj)
    { 25812, "dispel", "Naturgeschosse auf den Raid mit stapelndem Gift; Gift entfernen", "Raid-wide nature volley with a stacking poison; cure poisons" },
    { 0, "avoid", "Hinterlässt beim Tod eine tödliche Giftwolke; abseits töten", "Leaves a deadly poison cloud on death; kill him away from the raid" },
  },
  [15516] = { -- Battleguard Sartura (Temple of Ahn'Qiraj)
    { 26083, "avoid", "**Wirbelwind** 15 Sek. lang; alle raus aus dem 10-m-Umkreis", "Whirlwinds for 15 sec; melee and casters stay out of 10 yards" },
    { 25174, "tank", "**Spalten** erhöht erlittenen Schaden; nur Tanks vorne", "Cleave raises damage taken; only tanks stand in front" },
    { 8269, "survive", "Rast bei wenig Leben; mit Abklingzeiten schnell töten", "Frenzies at low health; burn her down with cooldowns" },
  },
  [15517] = { -- Ouro (Temple of Ahn'Qiraj)
    { 26103, "positioning", "**Fegen** schleudert nahe Spieler weg; Nahkämpfer darauf gefasst sein", "**Sweep** knocks back nearby players; melee expect to be thrown" },
    { 26102, "positioning", "Frontale Betäubung, die Bedrohung löscht; nur Tanks vorne", "Frontal stun that wipes threat; only tanks stand in front" },
    { 0, "avoid", "Gräbt sich ein und taucht unter Spielern auf; von Erdhügeln weg", "Burrows and reappears below players; move off the dirt mounds" },
    { 0, "adds", "Nach dem Auftauchen kommen Skarabäen; flächig töten", "Scarabs swarm after he surfaces; AoE them down" },
  },
  [15543] = { -- Princess Yauj (Temple of Ahn'Qiraj)
    { 25807, "interrupt", "Heilt sich oder die anderen Käfer; **Große Heilung** immer unterbrechen", "Heals herself or the other bugs; always interrupt **Great Heal**" },
    { 0, "tank", "Flächenfurcht löscht Bedrohung; schnell zurückspotten", "Area fear wipes threat; taunt her back quickly" },
    { 0, "adds", "Bei ihrem Tod erscheinen kleine Käfer; flächig töten oder kontrollieren", "Small bugs spawn on her death; AoE or crowd-control them" },
  },
  [15544] = { -- Vem (Temple of Ahn'Qiraj)
    { 26561, "positioning", "Stürmt auf zufällige Spieler; Raid vom Tank verteilt halten", "Charges random players; keep the raid spread from his tank" },
    { 26027, "tank", "Schlägt Spieler zurück; an einer Wand tanken", "Knocks players back; tank him against a wall" },
    { 0, "survive", "Sein Tod lässt die anderen Käfer rasen; zuletzt töten", "His death enrages the other bugs; kill him last" },
  },
  [15727] = { -- C'Thun (Temple of Ahn'Qiraj)
    { 26134, "positioning", "**Augenstrahl** springt zwischen nahen Spielern; mit 10 m Abstand verteilen", "**Eye Beam** chains between close players; spread out 10 yards" },
    { 26029, "avoid", "Roter Strahl fegt durch den halben Raum; vor ihm herlaufen", "Red beam sweeps half the room; run around ahead of it" },
    { 26156, "adds", "99 % weniger Schaden, bis die Fleischtentakel im Magen tot sind", "Takes 99% less damage until the Flesh Tentacles in the stomach die" },
    { 26476, "survive", "Stapelnde Säure im Magen; bei hohen Stapeln über den Ausgang raus", "Stacking acid in the stomach; leave via the exit when stacks get high" },
  },
  [15928] = { -- Thaddius (Naxxramas)
    { 28089, "positioning", "Spieler erhalten Plus- oder Minusladung; zur gleichen Ladung stellen", "Players get plus or minus charge; stand with the same charge" },
    { 28167, "survive", "**Kettenblitz** springt durch den Raid; verteilen und heilen", "**Chain Lightning** jumps through the raid; spread and heal" },
    { 27680, "survive", "Berserker nach einigen Minuten; schnell töten", "Berserk after a few minutes; kill him quickly" },
    { 22839, "tank", "Stalagg und Feugen tauschen Tanks; beide nah zusammen töten", "Stalagg and Feugen swap tanks; kill both close together", "c" },
  },
  [15931] = { -- Grobbulus (Naxxramas)
    { 28169, "positioning", "Injizierte laufen vor dem Platzen aus dem Raid", "Injected players run out of the raid before it bursts" },
    { 28240, "avoid", "Hinterlässt wachsende Giftwolken; Tank zieht ihn am Rand entlang", "Leaves growing poison clouds; tank moves him along the edge" },
    { 28157, "positioning", "Frontales Spray erzeugt Schleime; vom Raid wegdrehen", "Frontal spray spawns slimes; face him away from the raid" },
  },
  [15932] = { -- Gluth (Naxxramas)
    { 28374, "adds", "Senkt das Leben aller auf 5 %; Zombies kiten und töten, bevor er sie frisst", "Drops everyone to 5%; kite and kill zombies before he eats them" },
    { 25646, "tank", "Stapelnde Heilungsminderung am Tank; Tanks wechseln", "Stacking healing cut on the tank; swap tanks" },
    { 29685, "survive", "Flächenfurcht; Furchtzauberschutz oder Erdstoß nutzen", "Area fear; use fear ward or tremor" },
  },
  [15936] = { -- Heigan the Unclean (Naxxramas)
    { 29371, "avoid", "Bodenzonen brechen nacheinander aus; in die sichere Zone tanzen", "Floor sections erupt in turns; dance to the safe zone" },
    { 29998, "dispel", "Krankheit senkt maximales Leben; Krankheit heilen", "Disease lowers max health; cure disease" },
    { 29310, "positioning", "**Manabrand** in der Nähe; Zauberer halten Abstand", "Burns mana nearby; casters stay out of range" },
  },
  [15952] = { -- Maexxna (Naxxramas)
    { 28622, "adds", "**Netzwickel** spinnt Spieler an der Wand ein; Fernkämpfer befreien sie", "**Web Wrap** cocoons players on the wall; ranged break them free" },
    { 29484, "survive", "**Netzspray** betäubt den Raid alle 40 Sek.; vorher hochheilen", "**Web Spray** stuns the raid every 40 sec; top up health before" },
    { 28776, "dispel", "**Nekrotisches Gift** senkt Heilung am Tank; entgiften", "**Necrotic Poison** cuts healing on the tank; cure it" },
    { 28747, "tank", "**Wutanfall** bei 30 % Leben; Abklingzeiten fürs Ende aufheben", "Enrages at 30% health; save cooldowns for the end" },
  },
  [15953] = { -- Grand Widow Faerlina (Naxxramas)
    { 28796, "dispel", "**Giftblitzsalve** auf mehrere Spieler; Gift schnell entfernen", "Poison volley on several players; cure poison quickly" },
    { 28794, "avoid", "**Feuerregen**-Flächen sofort verlassen", "Leave **Rain of Fire** areas at once" },
    { 28798, "tank", "**Wutanfall** erhöht ihren Schaden; Anbeter opfern, um ihn zu entfernen", "**Enrage** boosts her damage; sacrifice a Worshipper to remove it" },
  },
  [15954] = { -- Noth the Plaguebringer (Naxxramas)
    { 29213, "dispel", "Fluch verbreitet Schaden, wenn er ausläuft; schnell entfluchen", "Curse spreads damage to allies if it expires; decurse fast" },
    { 29211, "tank", "**Blinzeln** setzt Bedrohung zurück; Tanks ihn neu aufnehmen", "**Blink** resets his threat; tanks pick him up again" },
    { 29212, "survive", "**Verkrüppeln** verlangsamt Spieler in der Nähe und ihre Angriffe", "**Cripple** slows nearby players and their attacks" },
    { 0, "adds", "Skelettwellen erscheinen, mehr in der Balkonphase; flächig töten", "Waves of skeletons spawn, more on his balcony phase; AoE them" },
  },
  [15956] = { -- Anub'Rekhan (Naxxramas)
    { 28785, "avoid", "**Heuschreckenschwarm** bringt Spieler in der Nähe zum Schweigen und verletzt sie; Boss wegziehen (kiten)", "**Locust Swarm** silences and hurts nearby players; kite him away" },
    { 28783, "positioning", "**Aufspießen** trifft eine Linie und schleudert hoch; verteilen", "**Impale** hits a line and knocks players up; spread out" },
    { 28969, "adds", "Gruftwächter spucken Säure, hinterlassen Skarabäen; separat tanken", "Crypt Guards spit acid and spawn scarabs on death; off-tank them" },
  },
  [15976] = { -- Venom Stalker (Naxxramas)
    { 28431, "dispel", "**Ansturm** vergiftet alle im 10-m-Umkreis; entgiften", "Charge poisons all within 10 yards; cure poison" },
  },
  [15989] = { -- Sapphiron (Naxxramas)
    { 28531, "survive", "Ständiger Frostschaden am Raid; Frostresistenz nötig", "Constant raid frost damage; frost resistance gear needed" },
    { 28522, "positioning", "Flugphase: Spieler werden zu Eis; hinter Eisblöcken verstecken", "Air phase: players turn to ice; hide behind the ice blocks" },
    { 28524, "avoid", "**Frostatem** tötet jeden ohne Deckung hinter einem Eisblock", "**Frost Breath** kills anyone not behind an ice block" },
    { 28542, "dispel", "**Lebensentzug**-Fluch heilt ihn; schnell entfluchen", "**Life Drain** curse heals him; decurse fast" },
  },
  [15990] = { -- Kel'Thuzad (Naxxramas)
    { 28410, "dispel", "Übernimmt Spieler; kontrollieren oder Bezauberung brechen", "Mind-controls players; crowd-control or break the charm" },
    { 27808, "survive", "**Frostschlag** friert ein und springt auf Spieler in der Nähe über; schnell heilen", "**Frost Blast** freezes and chains to nearby players; heal fast" },
    { 27810, "avoid", "**Schattenspalt** sofort verlassen", "Move out of a **Shadow Fissure** immediately" },
    { 28478, "interrupt", "Seinen **Frostblitz** auf den Tank unterbrechen", "Interrupt his single-target **Frostbolt** on the tank" },
  },
  [16011] = { -- Loatheb (Naxxramas)
    { 29185, "survive", "Jeder Heiler darf nur einmal pro Minute heilen; Heiler rotieren", "Each healer can heal only once per minute; rotate healers" },
    { 29204, "survive", "Großer Schattenschaden in immer kürzeren Abständen; Schattenschutz nutzen", "Huge shadow damage that speeds up; use shadow protection" },
    { 29234, "adds", "Sporen bei der eigenen Gruppe töten für Kritbonus", "Kill spores near your group for a crit buff" },
  },
  [16017] = { -- Patchwork Golem (Naxxramas)
    { 27793, "positioning", "Krankheitsaura um ihn; Fernkämpfer bleiben weg", "Disease aura around it; ranged stay away" },
    { 27794, "positioning", "**Spalten** trifft Spieler neben dem Tank", "**Cleave** hits players beside the tank" },
  },
  [16018] = { -- Bile Retcher (Naxxramas)
    { 27807, "positioning", "Frontaler Naturkegel; vom Raid wegdrehen", "Frontal nature cone; face it away from the raid" },
  },
  [16021] = { -- Living Monstrosity (Naxxramas)
    { 28293, "interrupt", "**Kettenblitz** unterbrechen", "Interrupt its **Chain Lightning**" },
    { 28294, "adds", "Blitzschlagtotem sofort zerstören", "Kill its Lightning Totem at once" },
  },
  [16028] = { -- Patchwerk (Naxxramas)
    { 28308, "tank", "Trifft den gesündesten Nahkämpfer; weitere Tanks fangen ihn ab", "Hits the healthiest melee near him; extra tanks soak it" },
    { 0, "survive", "**Wutanfall** bei 5 % Leben; schnell töten", "Enrages at 5% health; burn him down" },
  },
  [16042] = { -- Lord Valthalak (Upper Blackrock Spire)
    { 0, "adds", "Geister-Attentäter sofort töten, sonst verwandeln sie", "Kill the spectral assassins at once or they turn players" },
    { 0, "survive", "Springender Entzug wird stärker; verteilen", "Chaining drain gains damage per jump; spread out" },
    { 27383, "survive", "Ab 40 % **Schattenblitzsalven**; schnell töten", "From 40% he volleys shadow bolts; burn him fast" },
  },
  [16060] = { -- Gothik the Harvester (Naxxramas)
    { 0, "adds", "Lebende Gegner kommen auf einer Seite, werden auf der anderen zu Geistern", "Living adds arrive on one side, become spirits on the other side" },
    { 28679, "survive", "Stapelnder Werteverlust, sobald er eingreift; schnell töten", "Stacking stat loss once he joins; kill him fast" },
    { 29317, "survive", "Schattenblitze auf zufällige Spieler, wenn er herabkommt", "Shadow Bolts on random players after he comes down" },
  },
  [16061] = { -- Instructor Razuvious (Naxxramas)
    { 26613, "tank", "Trifft Spieler viel zu hart; mit übernommenen Schülern tanken", "Hits players far too hard; tank him with mind-controlled students" },
    { 29107, "positioning", "Verbrennt Mana aller in Reichweite; Zauberer halten Abstand", "Burns mana of everyone in range; casters keep distance" },
    { 29061, "tank", "Schüler nutzen **Schildwall** und Spott zum Tankwechsel", "Students use **Shield Wall** and Taunt to swap tanking" },
  },
  [16062] = { -- The Four Horsemen (Naxxramas)
    { 28834, "tank", "Jeder Reiter markiert; Stapel schmerzen, Tanks rotieren", "Each Horseman marks; stacking marks hurt, tanks rotate" },
    { 28863, "avoid", "Lady Blaumeux setzt Leerenzonen; heraustreten", "Lady Blaumeux places void zones; step out" },
    { 28884, "positioning", "**Meteor** von Korth'azz wird aufgeteilt; zusammenstehen", "Korth'azz's **Meteor** is split among nearby players; stack" },
    { 28883, "positioning", "**Heiliger Zorn** von Zeliek springt; um ihn verteilen", "Zeliek's **Holy Wrath** chains; spread out around him" },
  },
  [16080] = { -- Mor Grayhoof (Lower Blackrock Spire)
    { 27530, "avoid", "Kanalisierter Sturm um ihn; herauslaufen", "Channeled storm around him; move out of it", "v" },
    { 27543, "tank", "Wird zum Bären mit mehr Rüstung und Leben; tanken und durchheilen", "Turns into a bear with more armor and health; tank him and keep healing", "v" },
    { 27545, "survive", "Wird zur Katze mit schnellen Blutungsangriffen; Leben des Ziels beobachten", "Turns into a cat with fast bleeding strikes; watch the target's health", "v" },
    { 27546, "survive", "Wechselt in die Feendrachen-Gestalt; Wirkung nicht bestätigt", "Changes into a faerie dragon; effect not confirmed", "v" },
    { 27527, "interrupt", "Große Selbstheilung; immer unterbrechen", "Big self heal; always interrupt it" },
    { 27532, "dispel", "Seine Heilung über Zeit reinigen", "Purge his heal-over-time buff" },
  },
  [16097] = { -- Isalien (Dire Maul)
    { 27639, "adds", "Ruft ein Tier: Add töten, dann zurück auf Isalien", "Summons a pet: kill the add, then switch back to Isalien", "v" },
    { 14443, "survive", "Salve trifft bis zu drei Spieler: heilen", "Volley hits up to three players: heal them", "v" },
    { 12024, "dispel", "Wurzelt einen Spieler 5 Sek. lang", "Roots a player for 5 sec", "v" },
    { 27637, "interrupt", "Heilt sich selbst: Zauber unterbrechen", "Heals herself: interrupt the cast", "v" },
    { 27636, "survive", "Arkanschaden über 6 Sek. auf einen Spieler: durchheilen", "Arcane damage over 6 sec on a player: heal through", "v" },
    { 25164, "survive", "Erhöht ihr Angriffs- und Lauftempo: schnell töten", "Raises her attack and movement speed: burst her down", "v" },
  },
  [16118] = { -- Kormok (Scholomance)
    { 27687, "adds", "Beschwört Skelettdiener und -magier; töten", "Summons skeleton minions and mages; kill them", "v" },
    { 27695, "adds", "Ruft auch Skelettmagier; zuerst töten", "Calls skeleton mages as well; kill them first", "v" },
    { 8269, "tank", "Beschleunigt seine Angriffe eine Weile; Tank nutzt Abklingzeiten", "Speeds up his attacks for a while; tank uses cooldowns", "v" },
    { 27688, "positioning", "**Knochenschild** wirft Schaden auf Nahkämpfer zurück; pausieren", "**Bone shield** reflects damage to melee; melee pause" },
  },
  [16145] = { -- Death Knight Captain (Naxxramas)
    { 28335, "positioning", "**Wirbelwind** trifft alle Nahkämpfer; Zauberer Abstand halten", "**Whirlwind** hits all melee; casters keep distance" },
  },
  [16163] = { -- Death Knight Cavalier (Naxxramas)
    { 28413, "dispel", "Schattenfluch über Zeit; entfluchen", "Shadow curse over time; decurse" },
  },
  [16164] = { -- Shade of Naxxramas (Naxxramas)
    { 28383, "adds", "Beschwört Dämonen bis zum Tod; schnell töten", "Summons demons until killed; burn it fast" },
    { 28407, "survive", "**Schattensalve** auf den Raid; Schattenschutz hilft", "Shadow volley on the raid; shadow protection helps" },
  },
  [16165] = { -- Necro Knight (Naxxramas)
    { 30094, "positioning", "**Frostnova** wurzelt Spieler in der Nähe fest", "**Frost Nova** roots players nearby" },
    { 30091, "avoid", "**Flammenstoß**- und **Blizzard**-Flächen verlassen", "Leave **Flamestrike** and Blizzard areas" },
    { 30095, "positioning", "**Kältekegel** nach vorn; nur der Tank steht davor", "**Cone of Cold** in front; only the tank faces it" },
  },
  [16168] = { -- Stoneskin Gargoyle (Naxxramas)
    { 28995, "interrupt", "Wird bei wenig Leben zu Stein und heilt; betäuben oder unterbrechen", "Turns to stone to heal at low health; stun or interrupt" },
    { 29325, "survive", "**Säurebolzen** mit Schaden über Zeit; durchheilen", "Acid bolts with damage over time; heal through" },
  },
  [16446] = { -- Plagued Gargoyle (Naxxramas)
    { 29325, "survive", "**Säuresalve** trifft mehrere Spieler mit Schaden über Zeit", "**Acid volley** hits several players with damage over time" },
  },
  [245999] = { -- Arcane Anomaly (City of Dalaran)
    { 1241501, "avoid", "**Fokussierter Schlag**: 3 Sek. Zauberzeit, dann Strahl nach vorne; aus der Bahn gehen", "**Focal Blast**: 3 sec cast, then a beam in front; leave its path", "f" },
    { 15230, "interrupt", "**Arkanblitz** auf einen Spieler: unterbrechen", "**Arcane bolt** on a player: interrupt it", "f" },
  },
  [246003] = { -- Fel Ancient (City of Dalaran)
    { 1240706, "avoid", "**Teufelsholz** hinterlässt Giftschwaden: rausgehen", "**Fel Timbers** leaves poison fumes: move out", "f" },
    { 22994, "dispel", "**Umschlingen** wurzelt bis zu zwei Spieler fest: bannen", "**Entangle** roots up to two players: dispel", "f" },
    { 1240687, "positioning", "**Trampeln** trifft Spieler neben ihm: nur der Tank steht nah", "**Trample** hits players next to him: only the tank stays close", "f" },
  },
  [246008] = { -- Mana Devourer (City of Dalaran)
    { 1240738, "dispel", "**Vitalität entziehen** auf dem Tank: Magie bannen", "**Drain Vitality** on the tank: dispel the magic", "f" },
    { 1240750, "survive", "**Entkräften** entzieht Mana im 45-m-Umkreis: Zauberer aufs Mana achten", "**Debilitate** drains mana within 45 yd: casters watch their mana", "f" },
    { 0, "adds", "Übrige Gegner im Raum helfen mit: vorher räumen", "Creatures left in his room join in: clear it first", "f" },
  },
  [246016] = { -- Arcanic Enigma (City of Dalaran)
    { 1240869, "dispel", "**Manamorpher** verwandelt Spieler 8 Sek. lang in ein Tier: bannen", "**Manamorph** turns a player into an animal for 8 sec: dispel", "f" },
    { 1224125, "positioning", "10 Sek. lang Stille: Heiler halten Abstand", "Silences for 10 sec: healers keep their distance", "f" },
    { 0, "adds", "Ruft **Arkane Manalinge**: Flächenschaden nutzen", "Calls **Arcane Manalings**: use area damage", "f" },
    { 1304455, "adds", "Beschwört Manalinge: töten, bevor sie Zauberer erreichen", "Summons manalings: kill them before they reach casters", "f" },
  },
  [246017] = { -- Unstable Sentinel (City of Dalaran)
    { 1241329, "avoid", "**Fehlfunktion**: nach 2 Sek. Zauberzeit Arkanpulse im 25-m-Umkreis; rausgehen", "**Malfunction**: after a 2 sec cast, arcane pulses within 25 yd; get out", "f" },
    { 0, "adds", "Wütende Folianten auf dem Weg: vor dem Pull töten", "Angry Tomes on the way: kill them before the pull", "f" },
    { 16169, "avoid", "**Bogenschlag** trifft einen Kegel vor ihm: von der Gruppe wegdrehen", "**Arcing Smash** hits a cone in front of him: face him away from the group", "f" },
    { 1241325, "avoid", "**Arkanexplosion** pulsiert um ihn: Abstand halten", "**Arcane Explosion** pulses around him: stay out of range", "f" },
  },
  [246020] = { -- Shade of the Archmage (City of Dalaran)
    { 0, "survive", "Verlässt ein Spieler den Raum, hat der Boss wieder volles Leben", "Leaving the room resets him to full health", "f" },
    { 1241515, "positioning", "**Begrenzendes Mana** fliegt zu einem Spieler und zurück: nicht dazwischen stehen", "**Bounding Mana** flies to a player and back: don't stand in between", "f" },
    { 1303598, "survive", "Ohne Mana: verwandelt die Gruppe 8 Sek. lang, dann füllt er auf", "Out of mana: polymorphs the group for 8 sec, then refills", "f" },
    { 1303599, "interrupt", "**Hervorrufung** füllt sein Mana: unterbrechen oder schnell Schaden machen", "**Evocation** refills his mana: interrupt or burst him down", "f" },
    { 15230, "interrupt", "**Arkanblitz** auf einen Spieler: unterbrechen", "**Arcane bolt** on a player: interrupt it", "f" },
    { 28450, "avoid", "**Arkanexplosion** um ihn: Fernkämpfer halten Abstand", "Arcane burst around him: ranged keep their distance", "f" },
    { 1303350, "survive", "**Verlangsamen** senkt Angriffs-, Lauf- und Zaubertempo 3 Sek. lang: einplanen", "**Slow** cuts attack, move and cast speed for 3 sec: expect it", "f" },
  },
  [247001] = { -- Saturated Remnant (City of Dalaran)
    { 1449, "avoid", "**Arkanexplosion** um ihn: Fernkämpfer bleiben aus dem Nahkampf", "Arcane burst around it: ranged stay out of melee range", "f" },
    { 2139, "positioning", "**Gegenzauber** auf Zauberer: Sichtlinie brechen und heranziehen", "Counterspells casters: break line of sight to pull it in", "f" },
  },
  [247032] = { -- Lyn the Ignored (City of Dalaran)
    { 1304473, "dispel", "**Dornenfluch**: Fluch entfernen", "**Curse of Thorns**: remove the curse", "f" },
    { 17228, "survive", "**Schattenblitzsalve** trifft alle im 30-m-Umkreis", "**Shadow Bolt Volley** hits everyone within 30 yd", "f" },
    { 1303266, "adds", "**Tote erwecken** ruft zwei Skelette: töten", "**Raise Dead** summons two skeletons: kill them", "f" },
  },
  [247126] = { -- Atrexis the Grave Knight (City of Dalaran)
    { 1303264, "dispel", "**Unheilige Raserei**: +75 % Angriffstempo 20 Sek. lang, reinigen", "**Unholy Frenzy**: +75% attack speed for 20 sec, purge it", "f" },
    { 1303266, "adds", "Skelette erheben sich laufend: sofort töten", "Skeletons keep rising: kill them as they come", "f" },
    { 3391, "tank", "Extraschläge: schwere Treffer auf dem Tank", "Extra swings: heavy hits on the tank", "f" },
    { 6713, "tank", "Entwaffnet den Tank: kurz weniger Bedrohung einplanen", "Disarms the tank: expect less threat for a few seconds", "f" },
    { 12057, "tank", "Einfache Waffenschläge: Schild bereithalten", "Plain weapon strikes: keep the shield up", "f" },
  },
  [247195] = { -- Withermaw (Blackmaw Hold)
    { 0, "positioning", "Der faulende Bär hinterlässt Lavapfützen: Kampf davon wegziehen", "Rotting bear leaves lava pools: drag the fight away from them", "f" },
  },
  [247209] = { -- Elder Shaman Bloodmane (Blackmaw Hold)
    { 0, "interrupt", "Zauberer: seine Zauber unterbrechen", "Caster: interrupt his spells", "f" },
  },
  [250483] = { -- Witherfang (Ruins of Lordaeron)
    { 0, "adds", "Spinnen im Hof helfen mit: zuerst räumen", "Courtyard spiders join the fight: clear them first", "f" },
    { 3358, "dispel", "**Egelgift** saugt einen Spieler aus: Gift entfernen", "Leech poison drains a player: cure poison", "f" },
  },
  [250617] = { -- Shrieking Banshee (Ruins of Lordaeron)
    { 853, "survive", "Betäubt einen Spieler: auf den Heiler achten", "Stuns a player: watch out for the healer", "f" },
  },
  [250631] = { -- The Abandoned (Ruins of Lordaeron)
    { 1220855, "survive", "**Frostnova** trifft die ganze Gruppe: Heiler Mana einteilen", "Frost Nova hits the whole group: healers pace their mana", "f" },
    { 1266011, "interrupt", "**Lebensentzug** heilt ihn: Kanalisierung unterbrechen", "Life drain heals him: interrupt the channel", "f" },
    { 6136, "survive", "Nahkämpfer werden um 30 % verlangsamt und schlagen langsamer: gegenheilen", "Melee hitters get slowed 30% and attack slower: heal through it", "v" },
  },
  [250657] = { -- Rath'mael (Ruins of Lordaeron)
    { 1279983, "interrupt", "**Flammenstoß** ist sein Hauptzauber: jeden Zauber unterbrechen oder betäuben", "Flamestrike is his main spell: interrupt or stun every cast", "f" },
  },
  [250660] = { -- The Baron (Ruins of Lordaeron)
    { 0, "tank", "Wirft den Tank hoch und betäubt ihn 5 Sek. lang: Schadensverursacher auf Bedrohung achten", "Tosses the tank up, 5 sec stun: damage dealers watch threat", "f" },
    { 0, "positioning", "Eine Patrouille kommt vorbei: Raum vor dem Pull räumen", "A patrol passes his room: clear it before the pull", "f" },
    { 17307, "tank", "**K.O.-Schlag** betäubt den Tank: Tank voll geheilt halten", "Knockout stuns the tank: keep the tank topped up", "f" },
  },
  [253201] = { -- Titanosaur (Shaper's Terrace)
    { 0, "survive", "Furcht auf der Gruppe: Furchtzauberschutz oder Erdungstotem helfen", "Fears the group: Fear Ward or Tremor Totem help", "f" },
    { 0, "positioning", "Schwanz schleudert zurück: nicht hinter ihm stehen", "Tail knocks back: stay away from his rear", "f" },
  },
  [255262] = { -- Alcaz Chaplain (Alcaz Prison)
    { 15586, "interrupt", "**Heilen** auf sich oder Verbündete: Kaplane zuerst töten oder unterbrechen", "**Heal** on himself or allies: kill or interrupt chaplains first", "f" },
  },
  [255271] = { -- Defias Truthfinder (Alcaz Prison)
    { 14032, "dispel", "**Schattenwort: Schmerz** auf Spielern: reinigen", "**Shadow Word: Pain** on players: dispel it", "f" },
    { 17165, "dispel", "**Gedankenschinden** auf einem Spieler: reinigen oder unterbrechen", "**Mind Flay** channels on a player: dispel or interrupt it", "f" },
  },
  [255364] = { -- Renegade Conjurer (Alcaz Prison)
    { 14034, "interrupt", "**Feuerball** schmerzt: unterbrechen, besonders wenn keine Kaplane da sind", "**Fireball** hurts: interrupt it, especially if no chaplains are around", "f" },
  },
  [255373] = { -- Strashaz Enchantress (Alcaz Prison)
    { 13323, "interrupt", "**Verwandlung** auf zufälligen Spielern: unterbrechen oder das Schaf entzaubern", "**Polymorph** on random players: interrupt it or dispel the sheep", "f" },
    { 12737, "interrupt", "**Frostblitzsalve** trifft die Gruppe: unterbrechen", "**Frostbolt Volley** hits the group: interrupt it", "f" },
  },
  [255391] = { -- Overseer Wrex (Alcaz Prison)
    { 0, "adds", "Zieht alle Wärter seines Raums mit: im Gang bekämpfen", "Pulls every jailer of his room: fight him out in the corridor", "f" },
    { 16856, "tank", "**Tödlicher Stoß** trifft den Tank hart und halbiert 5 Sek. lang die Heilung auf ihm: Abklingzeiten nutzen", "**Mortal Strike** hits the tank hard and halves healing on him for 5 sec: use cooldowns", "f" },
    { 9128, "tank", "**Schlachtruf** stärkt ihn und seine Verbündeten zu Kampfbeginn", "**Battle Shout** buffs him and his allies at the start of the fight", "f" },
  },
  [255702] = { -- Blazeroar (Alcaz Prison)
    { 1271604, "avoid", "Wird zum Drachen mit brennenden Schuppen: kein Feuerschaden", "Turns into a dragon with burning scales: bring non-fire damage", "f" },
    { 18399, "avoid", "**Flammenstoß** in Phase 1: Feuer verlassen", "**Flamestrike** in the first phase: leave the fire", "f" },
    { 12466, "avoid", "**Feuerball** in Phase 1: Nahkämpfer müssen ihn eventuell aushalten", "**Fireball** in the first phase: melee may have to take it", "f" },
    { 1275847, "survive", "**Wahre Gestalt** bei etwa 30 % verwandelt sie in den Drachen mit voller Gesundheit: Abklingzeiten aufsparen", "**Reveal Form** at about 30% turns her into the dragon with full health: save cooldowns", "f" },
    { 9573, "tank", "**Flammenatem** verursacht hohen Feuerschaden am Tank: Verteidigungs-Abklingzeit oder Trank", "**Flame Breath** deals heavy fire damage to the tank: defensive cooldown or potion", "f" },
    { 1271593, "survive", "**Furcht** trifft alle außer dem Tank: Erdungstotem oder Furchtzauberschutz", "**Fear** hits everyone but the tank: Tremor Totem or Fear Ward", "f" },
    { 3391, "tank", "**Dreschen** lässt sie den Tank mehrfach auf einmal treffen", "**Thrash** lets her hit the tank several times at once", "f" },
  },
  [255995] = { -- Strashaz Soldier (Alcaz Prison)
    { 1270802, "positioning", "**Berserkeransturm** zielt auf alle ab 8 m Entfernung: nah am Pack bleiben", "**Berserker Charge** targets anyone 8 yd or more away: stay close to the pack", "f" },
  },
  [255997] = { -- Tidemistress Ca'zass (Alcaz Prison)
    { 0, "interrupt", "Ihre Naga-Helfer verwandeln Spieler und wirken Salven: unterbrechen und kontrollieren", "Her naga adds polymorph players and cast volleys: interrupt and control them", "f" },
    { 1271375, "avoid", "**Eissturm** auf der Gruppe: aus dem Schnee treten", "**Blizzard** on the group: step out of the snow", "f" },
    { 15532, "dispel", "**Frostnova** hält Spieler fest: schnell reinigen, damit niemand im Eissturm festsitzt", "**Frost Nova** roots players: dispel them quickly so nobody is stuck in the Blizzard", "f" },
    { 8398, "interrupt", "**Frostblitzsalve** trifft die ganze Gruppe: unterbrechen oder durchheilen", "**Frostbolt Volley** hits the whole group: interrupt it or heal through it", "f" },
  },
  [256035] = { -- Viktor the Vile (Ruins of Lordaeron)
    { 0, "dispel", "Vergiftet sein Ziel: Gift entfernen, Leben im Blick behalten", "Poisons his target: cure poison, watch health bars", "f" },
    { 0, "tank", "Schlägt hart zu: Tank gesund halten", "Hits hard: keep the tank healthy", "f" },
    { 3358, "dispel", "**Egelgift** saugt einen Spieler aus: Gift entfernen", "Leech poison drains a player: cure poison", "f" },
  },
  [256097] = { -- Bjork (Ruins of Lordaeron)
    { 0, "positioning", "Stößt Spieler zurück: Gruppen um ihn vorher räumen", "Knocks players back: clear the packs around him first", "f" },
    { 0, "tank", "Schlägt hart zu: Tank voll geheilt halten", "Hits hard: keep the tank topped up", "f" },
    { 1301635, "dispel", "Schild blockt Zauber: reinigen oder körperlichen Schaden nutzen", "Shield blocks spells: purge it or use physical damage", "f" },
  },
  [256236] = { -- The Questioner (Alcaz Prison)
    { 17620, "interrupt", "**Lebensentzug** heilt ihn: unterbrechen und seine zwei Zauberer töten", "**Drain Life** heals him: interrupt it and kill his two casters", "f" },
    { 12054, "survive", "**Wunden** lässt den Tank bluten: gegenheilen", "**Rend** makes the tank bleed: heal through it", "f" },
  },
  [257016] = { -- Katerina the Cleaner (Alcaz Prison)
    { 0, "positioning", "Teleportiert sich hinter Fernkämpfer und sticht zu: diese heilen", "Teleports behind ranged players and stabs them: heal them up", "f" },
    { 1271761, "survive", "**Garrotte** lässt einen zufälligen Spieler bluten, bis er über 90 % geheilt ist: schnell hochheilen", "**Grievous Garrote** makes a random player bleed until healed above 90%: top them up fast", "f" },
    { 3583, "dispel", "**Tödliches Gift** auf dem Hauptziel: sofort entgiften", "**Deadly Poison** on the main target: dispel it at once", "f" },
  },
  [257885] = { -- Krol'dok Centurion (Krol'dok Stronghold)
    { 16856, "tank", "**Tödlicher Stoß** senkt die Heilung auf dem Tank, dazu **Donnerknall** und **Demoralisierender Ruf** auf alle im Nahkampf", "**Mortal Strike** cuts healing on the tank, plus **Thunderclap** and **Demoralizing Shout** on everyone in melee range", "f" },
  },
  [257888] = { -- Krol'dok Shaman (Krol'dok Stronghold)
    { 6742, "adds", "**Kampfrausch** beschleunigt den Schamanen und seine Verbündeten: Schamanen vor den Zenturios töten", "**Bloodlust** speeds up the shaman and its allies after Lightning Bolts: kill shamans before the centurions", "f" },
  },
  [258042] = { -- Twilight Grunt (Krol'dok Stronghold)
    { 1307066, "positioning", "**Klingensturm** trifft alle im 8-m-Umkreis: Heiler und Fernkämpfer auf Abstand, Gruppenheilung nötig", "**Bladestorm** hits everyone within 8 yd: healers and ranged keep distance, group healing needed", "f" },
    { 15572, "tank", "**Rüstung zerreißen** erhöht den Schaden auf dem Tank: Tank am Leben halten", "**Sunder Armor** increases damage taken by the tank: keep the tank alive", "f" },
  },
  [258102] = { -- Twilight Outrider (Krol'dok Stronghold)
    { 14030, "tank", "**Hakennetz** hält den Tank 10 Sek. fest, sie patrouillieren zu dritt: per Sichtlinie wegziehen, ein Paladin kann den Tank befreien", "**Hooked Net** roots the tank for 10 sec and they patrol in packs of three: pull them away with line of sight, a Paladin can free the tank", "f" },
  },
  [258905] = { -- Zul'Alai (The Drowned City)
    { 1282504, "avoid", "**Monströser Schlag** betäubt alle neben ihm 3 Sek. lang: Nahkämpfer treten während des Zaubers weg, er bewegt sich dabei nicht", "**Monstrous Slam** stuns everyone next to him for 3 sec: melee step away while he casts, he stands still", "f" },
    { 1282519, "dispel", "**Verfaulter Schlag** verlangsamt Bewegung und Angriffstempo naher Spieler: zuerst den Tank entfluchen", "**Rotted Strike** slows movement and attack speed of nearby players: dispel the tank first", "f" },
    { 1282511, "survive", "**Unsterblicher Schwur** unter 30 % Leben: schnellere Angriffe und er heilt sich, Abklingzeiten aufsparen", "**Undying Oath** below 30% health: faster attacks and he heals himself, save cooldowns", "f" },
  },
  [258924] = { -- Var'Taka (The Drowned City)
    { 1282615, "survive", "**Harpune** spießt einen zufälligen Spieler auf und zieht ihn heran", "**Harpoon** spears a random player and pulls them to him", "f" },
    { 15284, "positioning", "**Spalten** trifft vor ihm: nur der Tank steht dort, ihn von der Gruppe wegdrehen", "**Cleave** hits in front of him: only the tank stands there, face him away from the group", "f" },
    { 0, "adds", "Zwei Priesterinnen heilen ihn und wirken Frostblitz: zuerst kontrollieren oder töten", "Two priestesses heal him and cast Frostbolt: control or kill them first", "f" },
  },
  [258964] = { -- Nar'gurk (Krol'dok Stronghold)
    { 1280259, "survive", "**Bekehren** übernimmt einen Spieler, bis er auf die Hälfte seiner Gesundheit gefallen ist: festhalten oder auf 50 % herunterbringen, nie töten", "**Convert** takes over a player until they are down to half health: control or cleave them down to 50% to break it, never kill them", "f" },
    { 1280356, "interrupt", "**Schattenblitzsalve** trifft die ganze Gruppe: unterbrechen", "**Shadow Bolt Volley** hits the whole group: interrupt it", "f" },
    { 0, "tank", "Lädt seinen Stab mit Schattenschaden: mehr Schaden auf dem Tank", "Charges his staff with shadow damage: more damage on the tank", "f" },
  },
  [258966] = { -- Slavecrusher Grox (Krol'dok Stronghold)
    { 1280085, "adds", "Ruft Gefangene in der Nähe zu Hilfe: mittanken und mit Flächenschaden erledigen", "**Force Compliance** calls nearby prisoners to help: tank them and cleave them down", "f" },
    { 21049, "tank", "**Kampfrausch** erhöht 30 Sek. lang sein Angriffstempo um 30 %", "**Bloodlust** raises his attack speed by 30% for 30 sec", "f" },
    { 11428, "tank", "Wirft den Tank 2 Sek. lang zu Boden", "**Knockdown** stuns the tank for 2 sec", "f" },
  },
  [258968] = { -- Overlord Mugg (Krol'dok Stronghold)
    { 1282393, "tank", "Wechselt zu **Keulensatz** und später zu **Hammersatz**, der seinen Schaden um 50 % erhöht: seine Gesundheit nicht herunterbringen, bevor die Helfer tot sind", "Swaps to **Set of Maces** and later **Set of Mauls**, which raises his damage by 50%: do not push his health before the adds are dead", "f" },
    { 1282387, "tank", "Jeder Treffer beschleunigt seine Angriffe bis zum Waffenwechsel", "Each hit speeds up his attacks until he swaps weapons", "f" },
    { 0, "adds", "Zwei Zenturio-Helfer setzen **Tödlicher Stoß** ein (weniger Heilung auf dem Tank): zuerst töten, danach ist viel Heilung nötig", "Two Centurion adds use **Mortal Strike** (less healing on the tank): kill them first, then a lot of healing is needed", "f" },
    { 1282397, "positioning", "Springt mit **Zerschmetternder Schlag** auf zufällige Spieler und schleudert alle in der Nähe zurück: Heiler im Blick auf alle, nicht nur auf den Tank", "Leaps onto random players with **Crushing Slam**, hurting and knocking back everyone near the landing: healers watch everyone, not just the tank", "f" },
  },
  [258972] = { -- Twilight Commander Zarmok (Krol'dok Stronghold)
    { 0, "positioning", "Mehrere Gegner patrouillieren um ihn herum: vor dem Pull freiräumen", "Several mobs patrol around him: clear them before the pull", "f" },
    { 1280011, "survive", "**Verwundender Wirbel** verursacht starke Blutung: gegenheilen, wenn möglich reinigen", "**Rending Whirl** causes a strong bleed: heal through it, cleanse if possible", "f" },
    { 0, "tank", "**Rüstung zerreißen** erhöht den Schaden auf dem Tank: Tank am Leben halten", "**Sunder Armor** increases damage taken by the tank: keep the tank alive", "f" },
    { 8599, "survive", "**Wutanfall** lässt ihn härter zuschlagen: Abklingzeiten nutzen und schnell besiegen", "**Enrage** makes him hit harder: use cooldowns and finish him quickly", "f" },
  },
  [259281] = { -- War Handler Ashka (Krol'dok Stronghold)
    { 0, "adds", "Kämpft mit zwei Wölfen: zuerst die Wölfe töten", "Fights alongside two wolves: kill the wolves first", "f" },
    { 0, "survive", "Ihr Wolf Terrorheuler versetzt die Gruppe mit Heulen in Furcht: Totem des Erdstoßes, Heulen wenn möglich unterbrechen, Umgebung vor dem Pull freiräumen", "Her wolf Terrorhowl fears the group with a howl: Tremor Totem, interrupt the howl if possible, clear the area before the pull", "f" },
    { 1282076, "tank", "Ihr zweiter Wolf Fletschfang fokussiert mit **Befehl: Töten** einen Spieler und ist nicht spottbar: mit Kontrolleffekten abfangen oder schnell töten", "Her second wolf focuses one player with **Kill Command** and cannot be taunted: peel it with crowd control or kill it fast", "f" },
  },
  [259285] = { -- Terrorhowl (Krol'dok Stronghold)
    { 0, "survive", "Heulen versetzt in Furcht: Totem des Erdstoßes, wenn möglich unterbrechen, Umgebung vor dem Pull freiräumen", "Howl fears the group: Tremor Totem, interrupt if possible, clear the area before the pull", "f" },
  },
  [260042] = { -- Captain Dreadrise (The Drowned City)
    { 1282842, "survive", "**Einsalzen** sperrt einen zufälligen Spieler (auch den Tank) in eine Blase: zerstören, bevor er ertrinkt", "**Embrine** traps a random player (the tank too) in a bubble: break it before they drown", "f" },
    { 1282860, "interrupt", "**Wasserblitzsalve** schadet der ganzen Gruppe: unterbrechen", "**Waterbolt Volley** damages the whole group: interrupt it", "f" },
  },
  [260274] = { -- Min'loth the Serpent (The Drowned City)
    { 1283250, "tank", "**Durchnässen** (Trollform) trifft den Tank hart", "**Drench** (troll form) hits the tank hard", "f" },
    { 1283233, "survive", "**Sintflut** ist ein Kanalzauber, der der ganzen Gruppe schadet: gegenheilen", "**Deluge** is a channel that damages the whole group: heal through it", "f" },
    { 0, "survive", "Bei 0 % Leben kehrt er als Schlange mit vollem Leben zurück: Abklingzeiten für Phase 2 aufsparen", "At 0% health he returns at full health as a serpent: save cooldowns for phase 2", "f" },
    { 1283313, "dispel", "**Giftblitzsalve** (Schlangenform) vergiftet die Gruppe: schnell reinigen", "**Poison Bolt Volley** (serpent form) poisons the group: cleanse it quickly", "f" },
    { 1313471, "avoid", "**Furcht** (Schlangenform) trifft einen zufälligen Spieler: Abstand zu anderen Gegnern halten", "**Fear** (serpent form) hits a random player: stay clear of other groups", "f" },
  },
  [260322] = { -- Saltspine (Excavation Site: Wetlands)
    { 0, "positioning", "Läuft zwischen Elite-Krokilisken: diese räumen oder ihn weglocken", "Roams among elite crocolisks: clear them or pull him away", "f" },
    { 3604, "tank", "**Sehnenriss** verlangsamt den Tank: weniger laufen, mehr heilen", "**Tendon rip** slows the tank: kite less, heal more", "f" },
    { 1316382, "avoid", "**Staubsturm** um ihn: Fernkämpfer raus aus dem Sturm", "**Dust storm** around him: ranged move out of it", "f" },
  },
  [260325] = { -- Shadetooth (Excavation Site: Wetlands)
    { 0, "adds", "Raptorwelle vor seiner Ankunft töten", "Kill the raptor wave before he arrives", "f" },
    { 0, "survive", "Versetzt den Tank mehrfach in Furcht: Totem des Erdstoßes hilft", "Fears the tank repeatedly: a Tremor Totem helps", "f" },
    { 3427, "dispel", "Seine zwei Dickichtjäger wirken **Infizierte Wunde**, die erlittenen physischen Schaden erhöht: schnell bannen (ungeprüft)", "His two Thicket Hunters apply **Infected Wound**, raising physical damage taken: dispel it quickly (unverified)", "f" },
    { 12054, "tank", "**Verwunden** lässt den Tank bluten: gleichmäßig heilen", "**Rend** bleeds the tank: keep healing steady", "f" },
    { 14100, "survive", "Gebrüll lässt Spieler fliehen: Furchtschutz nutzen", "Roar fears nearby players: use fear protection", "f" },
    { 18501, "tank", "Wütet bei wenig Leben: Abklingzeiten fürs Ende aufheben", "Enrages at low health: save cooldowns for the end", "f" },
  },
  [260326] = { -- Relic Guardian (Excavation Site: Wetlands)
    { 0, "tank", "Setzt Bedrohung zurück und wechselt Ziel: Schaden drosseln, Tank holt ihn zurück", "Drops threat and swaps targets: damage slows down, tank takes him back", "f" },
    { 15588, "positioning", "**Donnerknall** verlangsamt Spieler in der Nähe: Fernkämpfer auf Abstand", "**Thunderclap** slows nearby players: ranged keep distance", "f" },
    { 8374, "positioning", "**Bogenschlag** trifft einen Kegel vor ihm: Tank steht abseits der Gruppe", "**Arcing Smash** hits a cone in front of him: tank stands apart from the group", "f" },
    { 10101, "tank", "**Wegschlagen** schleudert den Tank zurück: Nahkontakt geht kurz verloren", "**Knock Away** throws the tank back: expect to lose melee contact", "f" },
    { 11876, "survive", "**Kriegsdonner** betäubt und stößt Spieler in der Nähe 5 Sekunden zurück: Heilung bereithalten", "**War Stomp** stuns and knocks back nearby players for 5 seconds: save stun breaks and healing", "f" },
  },
  [260808] = { -- Highland Horror (Excavation Site: Wetlands)
    { 0, "dispel", "Wurzelt einen Spieler: bannen oder befreien", "Roots a player: dispel or free them", "f" },
    { 0, "survive", "Regeneriert Leben: Schaden gleichmäßig halten", "Regenerates health: keep damage steady", "f" },
  },
  [261306] = { -- Faldrim Anvilmar (Hall of Thanes)
    { 1292602, "dispel", "Langer Fluch auf dem Tank: entfluchen", "Long curse on the tank: decurse it", "f" },
    { 26048, "survive", "Patrouilliert, wirkt **Gedankenschlag**: ohne Trash pullen", "Patrols and casts Mind Blast: pull him away from trash", "f" },
  },
  [261311] = { -- Plunder (Hall of Thanes)
    { 10101, "positioning", "Schleudert zurück: an der Wand tanken, weg von anderen Gruppen", "Knocks players back: tank against a wall, away from other packs", "f" },
  },
  [261316] = { -- Magmatus (Hall of Thanes)
    { 0, "adds", "Kommt mit Dunkeleisenbeschwörer: Beschwörer zuerst töten", "Comes with a Dark Iron Summoner: kill the summoner first", "f" },
    { 1293228, "survive", "Verbrennen und Feuernova: wegtanken, durchheilen", "Combust and a fire nova burn the group: tank him away, heal through", "f" },
    { 11970, "avoid", "**Feuerstoß** um ihn herum: Fernkämpfer und Begleiter auf Abstand halten", "Fire burst around him: ranged and pets stay out of melee range", "v" },
  },
  [261319] = { -- Durgen Dirgehammer (Hall of Thanes)
    { 0, "adds", "Zwei Steingolems: erst Plünderer räumen, Golems einzeln töten", "Two stone golems join: clear the looters first, kill golems one by one", "f" },
    { 26070, "survive", "Furcht auf die Gruppe: Raum vorher räumen", "Fears the group: clear the room first", "f" },
    { 12054, "tank", "**Verwunden** lässt den Tank bluten: viel Schaden, Betäubungen nutzen", "Rend bleeds the tank: heavy damage, use stuns", "f" },
    { 19134, "avoid", "Schrei lässt Spieler in der Nähe fliehen: Fernkämpfer bleiben weg", "Shout fears nearby players: ranged stay away from him", "v" },
  },
  [261809] = { -- Nanaya (Shaper's Terrace)
    { 0, "survive", "**Bodenschlag** betäubt alle in der Nähe", "**Ground slam** stuns everyone close by", "f" },
    { 0, "avoid", "Wechselt alle 25 % Leben das Element: Resistenzen anpassen", "Changes element every 25% health: swap resistances", "f" },
  },
  [261812] = { -- Thunderhoof (Shaper's Terrace)
    { 0, "interrupt", "Blitzzauber ist unterbrechbar: Reihenfolge der Unterbrecher planen", "Lightning cast can be interrupted: plan a kick order", "f" },
  },
  [261813] = { -- Venomridge (Shaper's Terrace)
    { 0, "dispel", "**Giftsalve** und **Stampfen**: Gift entfernen, leicht verteilen", "**Poison volley** and stomp: cure poison, spread slightly", "f" },
  },
  [261974] = { -- Cinder (Shaper's Terrace)
    { 0, "avoid", "Feuerschaden: Feuerresistenz mitbringen, Flammen meiden", "Fire damage: bring fire resistance, stay out of flames", "f" },
  },
  [262081] = { -- Bolt (Shaper's Terrace)
    { 0, "positioning", "**Kettenblitz** springt: nicht stapeln; immun gegen Natur", "**Chain lightning** jumps: do not stack; immune to nature", "f" },
  },
  [262127] = { -- Direhorn Matriarch (Shaper's Terrace)
    { 0, "tank", "**Durchbohren** lässt den Tank bluten: mehr Heilung", "**Puncture** bleeds the tank: extra healing", "f" },
    { 0, "positioning", "**Schwanzpeitsche** und **Sturmangriff** auf Ferne: an ihren Flanken stehen", "**Tail lash** and charge at distant players: stay at her flanks", "f" },
  },
  [262297] = { -- Snowtalon (Shaper's Terrace)
    { 0, "avoid", "**Kältekegel**, **Frostnova** und Wurzeln: Frostresistenz, fern der blauen Kristalle kämpfen", "Cone of cold, **frost nova** and root: bring frost resistance, fight away from the blue crystals", "f" },
  },
  [263396] = { -- Dark Iron Looter (Hall of Thanes)
    { 0, "tank", "Schnelle Dolchtreffer: wenige pullen, Plünderer zuerst", "Fast dagger hits: pull few, kill looters first", "f" },
  },
  [263397] = { -- Dark Iron Engineer (Hall of Thanes)
    { 0, "avoid", "Wirft Bomben auf eine Stelle: rausgehen, komplett vermeidbar", "Throws bombs at a spot: step out, fully avoidable", "f" },
  },
  [263438] = { -- Dark Iron Summoner (Hall of Thanes)
    { 1291218, "adds", "Feuerball und Feuerhelfer: Sichtlinie brechen, damit er herankommt", "Casts Fireball and summons a fire add: break line of sight to pull him", "f" },
  },
  [263466] = { -- Lesser Stone Golem (Hall of Thanes)
    { 0, "tank", "Schlägt hart, schnell: einzeln, Betäubung und Kontrolle nutzen", "Hits hard and moves fast: one at a time, use stuns and crowd control", "f" },
  },
  [264177] = { -- Gill (The Drowned City)
    { 1291692, "tank", "**Dynamit werfen** trifft das Hauptziel: nicht zusammen mit Gegnern in der Nähe ziehen", "**Throw Dynamite** hits the main target: don't pull him together with nearby trash", "f" },
  },
  [264773] = { -- Bossman Toof (Krol'dok Stronghold)
    { 16856, "tank", "**Tödlicher Stoß** senkt die Heilung auf dem Tank um 50 %: Abklingzeiten bereithalten, vorausheilen", "**Mortal Strike** cuts healing on the tank by 50%: save cooldowns, heal ahead", "f" },
    { 15548, "positioning", "**Donnerknall** trifft und verlangsamt Spieler in der Nähe: Fernkämpfer auf Abstand", "**Thunderclap** hits and slows players close by: ranged keep distance", "f" },
    { 16244, "tank", "**Demoralisierender Ruf** senkt die Angriffskraft von Spielern in der Nähe", "**Demoralizing Shout** lowers the attack power of nearby players", "f" },
  },
  [269475] = { -- Mana Phantom (City of Dalaran)
    { 20817, "interrupt", "Verbrennt Mana von Zauberern: unterbrechen oder zuerst töten", "Burns mana from casters: interrupt or kill it first", "f" },
  },
  [270885] = { -- Deathless Marrow (The Drowned City)
    { 1283034, "survive", "**Blutblitz** schadet der ganzen Gruppe", "**Bloodbolt** damages the whole group", "f" },
    { 0, "adds", "Immer neue Wächter und Zauberer: mit Flächenschaden vom Boss mitnehmen, Wächter zuerst", "Waves of guardians and sorcerers keep coming: cleave them off the boss, kill guardians first", "f" },
    { 1283081, "adds", "Wächter betäuben Spieler mit **Schildschlag**: zuerst erledigen", "Guardians stun players with **Shield Slam**: kill them first", "f" },
  },
  [270887] = { -- Primeval Elemental (The Drowned City)
    { 1290978, "tank", "**Wasserblitz** trifft das Hauptziel: wenn möglich unterbrechen", "**Waterbolt** hits the main target: interrupt if possible", "f" },
    { 1290983, "survive", "**Wasser gefrieren** schadet der Gruppe: unter Wasser auf die Atemluft achten und rechtzeitig auftauchen", "**Freeze Water** damages the group: watch your breath underwater and surface in time", "f" },
  },
  [271784] = { -- Alcaz Jailer (Alcaz Prison)
    { 15496, "tank", "**Spalten** trifft alle vor ihm: vom Rest der Gruppe wegdrehen", "**Cleave** hits everyone in front: face him away from the group", "f" },
  },
  [277611] = { -- Twilight Peon (Krol'dok Stronghold)
    { 0, "adds", "Läuft los, um Hilfe zu holen: betäuben, verlangsamen oder schnell töten", "Runs off to fetch help: stun, slow or kill quickly", "f" },
  },
}

-- Zeilen des anderen Flavors entfernen, NPCs ohne Zeile ganz
local otherTag = flavor == "forever" and "c" or "f"
for npcID, list in pairs(ns.Mechanics) do
  for index = #list, 1, -1 do
    if list[index][5] == otherTag then table.remove(list, index) end
  end
  if #list == 0 then ns.Mechanics[npcID] = nil end
end

-- Dungeon Guide: ns.MechanicGuide = { [Karten-ID] = { bosses = { { NPC-ID, Name }, ... }, trash = { ... } } }
ns.MechanicGuide = {
  [33] = {
    bosses = { { 3914, "Rethilgore" }, { 3886, "Razorclaw the Butcher" }, { 3887, "Baron Silverlaine" }, { 4278, "Commander Springvale" }, { 4279, "Odo the Blindwatcher" }, { 4274, "Fenrus the Devourer" }, { 3927, "Wolf Master Nandos" }, { 4275, "Archmage Arugal" }, },
    trash = { { 3872, "Deathsworn Captain" }, { 2529, "Son of Arugal" }, { 3875, "Haunted Servitor" }, { 3855, "Shadowfang Darksoul" }, { 3853, "Shadowfang Moonwalker" }, { 3873, "Tormented Officer" }, { 3877, "Wailing Guardsman" }, { 3864, "Fel Steed" }, { 3865, "Shadow Charger" }, { 3866, "Vile Bat" }, },
  },
  [34] = {
    bosses = { { 1696, "Targorr the Dread" }, { 1666, "Kam Deepfury" }, { 1717, "Hamhock" }, { 1716, "Bazil Thredd" }, { 1663, "Dextren Ward" }, },
    trash = { { 1715, "Defias Insurgent" }, { 1706, "Defias Prisoner" }, },
  },
  [36] = {
    bosses = { { 644, "Rhahk'Zor" }, { 642, "Sneed's Shredder" }, { 643, "Sneed" }, { 1763, "Gilnid" }, { 646, "Mr. Smite" }, { 647, "Captain Greenskin" }, { 639, "Edwin VanCleef" }, { 645, "Cookie" }, },
    trash = { { 3586, "Miner Johnson" }, { 1729, "Defias Evoker" }, { 4418, "Defias Wizard" }, { 622, "Goblin Engineer" }, { 636, "Defias Blackguard" }, },
  },
  [43] = {
    bosses = { { 3671, "Lady Anacondra" }, { 3669, "Lord Cobrahn" }, { 3670, "Lord Pythas" }, { 3673, "Lord Serpentis" }, { 3674, "Skum" }, { 5775, "Verdan the Everliving" }, { 3654, "Mutanus the Devourer" }, },
    trash = { { 5761, "Deviate Shambler" }, { 3840, "Druid of the Fang" }, },
  },
  [47] = {
    bosses = { { 6168, "Roogug" }, { 4424, "Aggem Thorncurse" }, { 4428, "Death Speaker Jargba" }, { 4420, "Overlord Ramtusk" }, { 4422, "Agathelos the Raging" }, { 4421, "Charlga Razorflank" }, },
    trash = { { 4842, "Earthcaller Halmgar" }, { 4425, "Blind Hunter" }, { 4517, "Death's Head Priest" }, { 4519, "Death's Head Seer" }, { 4440, "Razorfen Totemic" }, { 4520, "Razorfen Geomancer" }, { 4522, "Razorfen Dustweaver" }, { 4516, "Death's Head Adept" }, { 4438, "Razorfen Spearhide" }, },
  },
  [48] = {
    bosses = { { 4887, "Ghamoo-ra" }, { 4831, "Lady Sarevess" }, { 6243, "Gelihast" }, { 12902, "Lorgus Jett" }, { 12876, "Baron Aquanis" }, { 4830, "Old Serra'kis" }, { 4832, "Twilight Lord Kelris" }, { 4829, "Aku'mai" }, },
    trash = { { 4802, "Blackfathom Tide Priestess" }, { 4803, "Blackfathom Oracle" }, { 4813, "Twilight Shadowmage" }, { 4811, "Twilight Aquamancer" }, { 4799, "Fallenroot Hellcaller" }, },
  },
  [70] = {
    bosses = { { 6910, "Revelosh" }, { 6906, "The Lost Dwarves" }, { 7228, "Ironaya" }, { 7023, "Obsidian Sentinel" }, { 7206, "Ancient Stone Keeper" }, { 7291, "Galgann Firehammer" }, { 4854, "Grimlok" }, { 2748, "Archaedas" }, },
    trash = { { 4852, "Stonevault Oracle" }, { 4848, "Shadowforge Darkcaster" }, { 4853, "Stonevault Geomancer" }, { 4863, "Jadespine Basilisk" }, { 7022, "Venomlash Scorpid" }, },
  },
  [90] = {
    bosses = { { 7079, "Viscous Fallout" }, { 7361, "Grubbis" }, { 6235, "Electrocutioner 6000" }, { 6229, "Crowd Pummeler 9-60" }, { 7800, "Mekgineer Thermaplugg" }, },
    trash = { { 6228, "Dark Iron Ambassador" }, { 6232, "Arcane Nullifier X-21" }, { 6212, "Dark Iron Agent" }, { 7849, "Mobile Alert System" }, { 6224, "Leprous Machinesmith" }, { 6329, "Irradiated Pillager" }, { 6207, "Caverndeep Ambusher" }, },
  },
  [109] = {
    bosses = { { 8580, "Atal'alarion" }, { 5712, "Zolo" }, { 5713, "Gasher" }, { 5714, "Loro" }, { 5715, "Hukku" }, { 5716, "Zul'Lor" }, { 5717, "Mijan" }, { 5710, "Jammal'an the Prophet" }, { 5711, "Ogom the Wretched" }, { 5721, "Dreamscythe" }, { 5720, "Weaver" }, { 5719, "Morphaz" }, { 5722, "Hazzas" }, { 8443, "Avatar of Hakkar" }, { 5709, "Shade of Eranikus" }, },
    trash = { { 5271, "Atal'ai Deathwalker" }, { 5273, "Atal'ai High Priest" }, { 5259, "Atal'ai Witch Doctor" }, { 5269, "Atal'ai Priest" }, { 5270, "Atal'ai Corpse Eater" }, { 8497, "Nightmare Suppressor" }, { 5280, "Nightmare Wyrmkin" }, { 8336, "Hakkari Sapper" }, { 5291, "Hakkari Frostwing" }, { 5708, "Spawn of Hakkar" }, },
  },
  [129] = {
    bosses = { { 7355, "Tuten'kash" }, { 7356, "Plaguemaw the Rotting" }, { 7357, "Mordresh Fire Eye" }, { 8567, "Glutton" }, { 7358, "Amnennar the Coldbringer" }, },
    trash = { { 7335, "Death's Head Geomancer" }, { 7337, "Death's Head Necromancer" }, { 7342, "Skeletal Summoner" }, { 7352, "Frozen Soul" }, { 7328, "Withered Reaver" }, { 7332, "Withered Spearhide" }, { 7351, "Tomb Reaver" }, { 7353, "Freezing Spirit" }, { 7341, "Skeletal Frostweaver" }, },
  },
  [189] = {
    bosses = { { 3975, "Herod" }, { 4542, "High Inquisitor Fairbanks" }, { 3976, "Scarlet Commander Mograine" }, { 3977, "High Inquisitor Whitemane" }, { 3983, "Interrogator Vishas" }, { 4543, "Bloodmage Thalnos" }, { 3974, "Houndmaster Loksey" }, { 6487, "Arcanist Doan" }, },
    trash = { { 4297, "Scarlet Conjuror" }, { 4292, "Scarlet Protector" }, { 4295, "Scarlet Myrmidon" }, { 4303, "Scarlet Abbot" }, { 4294, "Scarlet Sorcerer" }, { 4300, "Scarlet Wizard" }, { 4302, "Scarlet Champion" }, { 6427, "Haunting Phantasm" }, { 6426, "Anguished Dead" }, { 4306, "Scarlet Torturer" }, { 4293, "Scarlet Scryer" }, { 4299, "Scarlet Chaplain" }, { 4296, "Scarlet Adept" }, { 4291, "Scarlet Diviner" }, { 4288, "Scarlet Beastmaster" }, { 4287, "Scarlet Gallant" }, { 4540, "Scarlet Monk" }, },
  },
  [209] = {
    bosses = { { 8127, "Antu'sul" }, { 7272, "Theka the Martyr" }, { 7271, "Witch Doctor Zum'rah" }, { 7274, "Sandfury Executioner" }, { 7796, "Nekrum Gutchewer" }, { 7275, "Shadowpriest Sezz'ziz" }, { 7273, "Gahz'rilla" }, { 7795, "Hydromancer Velratha" }, { 7797, "Ruuzlu" }, { 7267, "Chief Ukorz Sandscalp" }, { 7604, "Sergeant Bly" }, },
    trash = { { 10082, "Zerillis" }, { 5650, "Sandfury Witch Doctor" }, { 5648, "Sandfury Shadowcaster" }, { 7247, "Sandfury Soul Eater" }, { 7246, "Sandfury Shadowhunter" }, { 8095, "Sul'lithuz Sandcrawler" }, },
  },
  [229] = {
    bosses = { { 9196, "Highlord Omokk" }, { 9236, "Shadow Hunter Vosh'gajin" }, { 9237, "War Master Voone" }, { 16080, "Mor Grayhoof" }, { 10596, "Mother Smolderweb" }, { 10584, "Urok Doomhowl" }, { 9736, "Quartermaster Zigris" }, { 10220, "Halycon" }, { 10268, "Gizrul the Slavener" }, { 9568, "Overlord Wyrmthalak" }, { 9816, "Pyroguard Emberseer" }, { 10264, "Solakar Flamewreath" }, { 10899, "Goraluk Anvilcrack" }, { 10429, "Warchief Rend Blackhand" }, { 10339, "Gyth" }, { 10430, "The Beast" }, { 16042, "Lord Valthalak" }, { 10363, "General Drakkisath" }, },
    trash = { { 9217, "Spirestone Lord Magus" }, { 10263, "Burning Felguard" }, { 9596, "Bannok Grimaxe" }, { 10376, "Crystal Fang" }, { 9718, "Ghok Bashguud" }, { 9257, "Scarshield Warlock" }, { 9098, "Scarshield Spellbinder" }, { 9258, "Scarshield Raider" }, { 9240, "Smolderthorn Shadow Priest" }, { 9266, "Smolderthorn Witch Doctor" }, { 9263, "Firebrand Dreadweaver" }, { 9262, "Firebrand Invoker" }, { 9264, "Firebrand Pyromancer" }, { 9693, "Bloodaxe Evoker" }, { 9717, "Bloodaxe Summoner" }, { 9198, "Spirestone Mystic" }, { 9201, "Spirestone Ogre Magus" }, { 10374, "Spire Spider" }, { 10509, "Jed Runewatcher" }, { 9818, "Blackhand Summoner" }, { 9817, "Blackhand Dreadweaver" }, { 9819, "Blackhand Veteran" }, { 10316, "Blackhand Incarcerator" }, { 10318, "Blackhand Assassin" }, { 10742, "Blackhand Dragon Handler" }, { 10372, "Rage Talon Fire Tongue" }, { 10083, "Rage Talon Flamescale" }, { 10371, "Rage Talon Captain" }, { 10683, "Rookery Hatcher" }, { 10814, "Chromatic Elite Guard" }, { 9096, "Rage Talon Dragonspawn" }, },
  },
  [230] = {
    bosses = { { 9025, "Lord Roccor" }, { 9018, "High Interrogator Gerstahn" }, { 9319, "Houndmaster Grebmar" }, { 9027, "Gorosh the Dervish" }, { 9028, "Grizzle" }, { 9029, "Eviscerator" }, { 9030, "Ok'thor the Breaker" }, { 9031, "Anub'shiah" }, { 9032, "Hedrum the Creeper" }, { 9024, "Pyromancer Loregrain" }, { 9041, "Warder Stilgiss" }, { 9476, "Watchman Doomgrip" }, { 9056, "Fineous Darkvire" }, { 9017, "Lord Incendius" }, { 9016, "Bael'Gar" }, { 9033, "General Angerforge" }, { 8983, "Golem Lord Argelmach" }, { 9537, "Hurley Blackbreath" }, { 9502, "Phalanx" }, { 9499, "Plugger Spazzring" }, { 9156, "Ambassador Flamelash" }, { 9039, "The Seven" }, { 9938, "Magmus" }, { 8929, "Princess Moira Bronzebeard" }, { 9019, "Emperor Dagran Thaurissan" }, },
    trash = { { 8923, "Panzor the Invincible" }, { 8894, "Anvilrage Medic" }, { 8900, "Doomforge Arcanasmith" }, { 8911, "Fireguard Destroyer" }, { 8913, "Twilight Emissary" }, { 8912, "Twilight's Hammer Torturer" }, { 8922, "Bloodhound Mastiff" }, { 8908, "Molten War Golem" }, { 8906, "Ragereaver Golem" }, { 9034, "Hate'rel" }, { 9035, "Anger'rel" }, { 9036, "Vile'rel" }, { 9037, "Gloom'rel" }, { 9038, "Seeth'rel" }, { 9040, "Dope'rel" }, { 9042, "Verek" }, },
  },
  [249] = {
    bosses = { { 10184, "Onyxia" }, },
    trash = { { 12129, "Onyxian Warder" }, },
  },
  [289] = {
    bosses = { { 14861, "Blood Steward of Kirtonos" }, { 10506, "Kirtonos the Herald" }, { 10503, "Jandice Barov" }, { 11622, "Rattlegore" }, { 14516, "Death Knight Darkreaver" }, { 10433, "Marduk Blackpool" }, { 10432, "Vectus" }, { 10508, "Ras Frostwhisper" }, { 16118, "Kormok" }, { 10505, "Instructor Malicia" }, { 11261, "Doctor Theolen Krastinov" }, { 10901, "Lorekeeper Polkelt" }, { 10507, "The Ravenian" }, { 10504, "Lord Alexei Barov" }, { 10502, "Lady Illucia Barov" }, { 1853, "Darkmaster Gandling" }, },
    trash = { { 10477, "Scholomance Necromancer" }, { 10472, "Scholomance Occultist" }, { 11582, "Scholomance Dark Summoner" }, { 10469, "Scholomance Adept" }, { 10498, "Spectral Tutor" }, { 10485, "Risen Aberration" }, { 10495, "Diseased Ghoul" }, { 11551, "Necrofiend" }, { 10678, "Plagued Hatchling" }, },
  },
  [309] = {
    bosses = { { 14517, "High Priestess Jeklik" }, { 14507, "High Priest Venoxis" }, { 14510, "High Priestess Mar'li" }, { 14509, "High Priest Thekal" }, { 14515, "High Priestess Arlokk" }, { 11382, "Bloodlord Mandokir" }, { 11380, "Jin'do the Hexxer" }, { 14834, "Hakkar" }, { 15114, "Gahz'ranka" }, { 15082, "Gri'lek" }, { 15083, "Hazza'rah" }, { 15084, "Renataki" }, { 15085, "Wushoolay" }, },
    trash = { { 11352, "Gurubashi Berserker" }, { 11350, "Gurubashi Axe Thrower" }, { 11338, "Hakkari Shadowcaster" }, { 11353, "Gurubashi Blood Drinker" }, { 11831, "Hakkari Witch Doctor" }, },
  },
  [329] = {
    bosses = { { 10516, "The Unforgiven" }, { 10808, "Timmy the Cruel" }, { 11032, "Malor the Zealous" }, { 10997, "Cannon Master Willey" }, { 10811, "Archivist Galford" }, { 10813, "Balnazzar" }, { 11143, "Postmaster Malown" }, { 10435, "Magistrate Barthilas" }, { 10436, "Baroness Anastari" }, { 10437, "Nerub'enkan" }, { 10438, "Maleki the Pallid" }, { 10439, "Ramstein the Gorger" }, { 10440, "Baron Rivendare" }, { 11058, "Ezra Grimm" }, },
    trash = { { 10393, "Skul" }, { 10558, "Hearthsinger Forresten" }, { 10809, "Stonespine" }, { 10423, "Crimson Priest" }, { 10422, "Crimson Sorcerer" }, { 10425, "Crimson Battle Mage" }, { 10426, "Crimson Inquisitor" }, { 11043, "Crimson Monk" }, { 10400, "Thuzadin Necromancer" }, { 10398, "Thuzadin Shadowcaster" }, { 10463, "Shrieking Banshee" }, { 10464, "Wailing Banshee" }, { 10417, "Venom Belcher" }, { 10409, "Rockwing Screecher" }, { 10414, "Patchwork Horror" }, },
  },
  [349] = {
    bosses = { { 13282, "Noxxion" }, { 12258, "Razorlash" }, { 12236, "Lord Vyletongue" }, { 12225, "Celebras the Cursed" }, { 12203, "Landslide" }, { 13601, "Tinkerer Gizlock" }, { 13596, "Rotgrip" }, { 12201, "Princess Theradras" }, },
    trash = { { 12237, "Meshlok the Harvester" }, { 11790, "Putridus Satyr" }, { 11791, "Putridus Trickster" }, { 11792, "Putridus Shadowstalker" }, { 12206, "Primordial Behemoth" }, { 11793, "Celebrian Dryad" }, { 13141, "Deeprot Stomper" }, { 13142, "Deeprot Tangler" }, { 13323, "Subterranean Diemetradon" }, { 11785, "Ambereye Basilisk" }, { 11784, "Theradrim Guardian" }, { 13533, "Spewed Larva" }, },
  },
  [389] = {
    bosses = { { 11517, "Oggleflint" }, { 11520, "Taragaman the Hungerer" }, { 11518, "Jergosh the Invoker" }, { 11519, "Bazzalan" }, },
    trash = { { 11319, "Ragefire Shaman" }, { 11324, "Searing Blade Warlock" }, },
  },
  [409] = {
    bosses = { { 12118, "Lucifron" }, { 11982, "Magmadar" }, { 12259, "Gehennas" }, { 12057, "Garr" }, { 12264, "Shazzrah" }, { 12056, "Baron Geddon" }, { 12098, "Sulfuron Harbinger" }, { 11988, "Golemagg the Incinerator" }, { 12018, "Majordomo Executus" }, { 11502, "Ragnaros" }, },
    trash = { { 11671, "Core Hound" }, { 11673, "Ancient Core Hound" }, { 11668, "Firelord" }, { 11658, "Molten Giant" }, { 11659, "Molten Destroyer" }, { 11667, "Flameguard" }, { 11666, "Firewalker" }, { 12119, "Flamewaker Protector" }, },
  },
  [429] = {
    bosses = { { 14354, "Pusillin" }, { 11490, "Zevrim Thornhoof" }, { 13280, "Hydrospawn" }, { 14327, "Lethtendris" }, { 11492, "Alzzin the Wildshaper" }, { 16097, "Isalien" }, { 11489, "Tendris Warpwood" }, { 11488, "Illyanna Ravenoak" }, { 11487, "Magister Kalendris" }, { 11496, "Immol'thar" }, { 11486, "Prince Tortheldrin" }, { 14326, "Guard Mol'dar" }, { 14322, "Stomper Kreeg" }, { 14321, "Guard Fengus" }, { 14323, "Guard Slip'kik" }, { 14325, "Captain Kromcrush" }, { 14324, "Cho'Rush the Observer" }, { 11501, "King Gordok" }, },
    trash = { { 11467, "Tsu'zee" }, { 14506, "Lord Hel'nurath" }, { 11457, "Wildspawn Hellcaller" }, { 11456, "Wildspawn Shadowstalker" }, { 11464, "Warpwood Tangler" }, { 11459, "Ironbark Protector" }, { 11480, "Arcane Aberration" }, { 11470, "Eldreth Sorcerer" }, { 11466, "Highborne Summoner" }, { 11444, "Gordok Mage-Lord" }, { 11448, "Gordok Warlock" }, { 14386, "Wandering Eye of Kilrogg" }, },
  },
  [469] = {
    bosses = { { 12435, "Razorgore the Untamed" }, { 13020, "Vaelastrasz the Corrupt" }, { 12017, "Broodlord Lashlayer" }, { 11983, "Firemaw" }, { 14601, "Ebonroc" }, { 11981, "Flamegor" }, { 14020, "Chromaggus" }, { 11583, "Nefarian" }, },
    trash = { { 12460, "Death Talon Wyrmguard" }, { 12461, "Death Talon Overseer" }, { 12467, "Death Talon Captain" }, { 13996, "Blackwing Technician" }, { 12457, "Blackwing Spellbinder" }, { 12459, "Blackwing Warlock" }, { 12458, "Blackwing Taskmaster" }, { 12464, "Death Talon Seether" }, },
  },
  [509] = {
    bosses = { { 15348, "Kurinnaxx" }, { 15341, "General Rajaxx" }, { 15340, "Moam" }, { 15370, "Buru the Gorger" }, { 15369, "Ayamiss the Hunter" }, { 15339, "Ossirian the Unscarred" }, },
    trash = { { 15355, "Anubisath Guardian" }, { 15338, "Obsidian Destroyer" }, { 15335, "Flesh Hunter" }, },
  },
  [531] = {
    bosses = { { 15263, "The Prophet Skeram" }, { 15511, "Lord Kri" }, { 15543, "Princess Yauj" }, { 15544, "Vem" }, { 15516, "Battleguard Sartura" }, { 15510, "Fankriss the Unyielding" }, { 15299, "Viscidus" }, { 15509, "Princess Huhuran" }, { 15276, "Emperor Vek'lor" }, { 15275, "Emperor Vek'nilash" }, { 15517, "Ouro" }, { 15727, "C'Thun" }, },
    trash = { { 15264, "Anubisath Sentinel" }, { 15277, "Anubisath Defender" }, { 15311, "Anubisath Warder" }, { 15252, "Qiraji Champion" }, { 15250, "Qiraji Slayer" }, { 15246, "Qiraji Mindslayer" }, { 15262, "Obsidian Eradicator" }, { 15233, "Vekniss Guardian" }, },
  },
  [533] = {
    bosses = { { 15956, "Anub'Rekhan" }, { 15953, "Grand Widow Faerlina" }, { 15952, "Maexxna" }, { 15954, "Noth the Plaguebringer" }, { 15936, "Heigan the Unclean" }, { 16011, "Loatheb" }, { 16061, "Instructor Razuvious" }, { 16060, "Gothik the Harvester" }, { 16062, "The Four Horsemen" }, { 16028, "Patchwerk" }, { 15931, "Grobbulus" }, { 15932, "Gluth" }, { 15928, "Thaddius" }, { 15989, "Sapphiron" }, { 15990, "Kel'Thuzad" }, },
    trash = { { 16168, "Stoneskin Gargoyle" }, { 16446, "Plagued Gargoyle" }, { 16021, "Living Monstrosity" }, { 16145, "Death Knight Captain" }, { 16165, "Necro Knight" }, { 15976, "Venom Stalker" }, { 16017, "Patchwork Golem" }, { 16018, "Bile Retcher" }, { 16164, "Shade of Naxxramas" }, { 16163, "Death Knight Cavalier" }, },
  },
}
