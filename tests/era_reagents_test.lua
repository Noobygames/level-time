-- Reagenzien für Buffs und Wiederbelebung (Roadmap 488): Bestand je Klasse nur für bekannte Zauber, Warnung bei
-- knappem Vorrat (GearWarnings), Chathinweis beim Händler, der ein knappes Reagenz verkauft
local Reagents = addon.Reagents
local GearWarnings = addon.GearWarnings
local L = addon.L

local ANKH, HOLY_CANDLE, SACRED_CANDLE = 17030, 17028, 17029

local function count(message)
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find(message, 1, true) then found = found + 1 end
  end
  return found
end

wow.state.class = "PRIEST"
wow.state.knownSpells = { [21562] = true }  -- Gebet der Seelenstärke Rang 1
wow.state.itemCounts = { [HOLY_CANDLE] = 3, [SACRED_CANDLE] = 0 }
wow.login({ level = 50 })

expectTrue("Priester: verfügbar", Reagents.IsAvailable())
local tracked = Reagents.Tracked()
expect("Rang 1: Heilige Kerze", tracked[1] and tracked[1].item, HOLY_CANDLE)
expect("ein Bedarf", #tracked, 1)

-- Höherer Rang bekannt: Hochheilige Kerze statt Heiliger
wow.state.knownSpells[21564] = true
expect("Rang 2: Hochheilige Kerze", Reagents.Tracked()[1].item, SACRED_CANDLE)
expect("knapp mit Bestand", Reagents.LowText(), string.format(L.REAGENT_STOCK, "Item " .. SACRED_CANDLE, 0))

-- Warnung nur mit Einstellung, einmal bis zum Auffüllen
GearWarnings.Check()
expect("aus: still", count(L.WARN_REAGENTS), 0)
addon.Set("warnReagents", true)
GearWarnings.Check()
expect("Warnung", count(L.WARN_REAGENTS), 1)
expect("Karte: Titel", LevelTimerNotice.title:GetText(), L.NOTICE_REAGENTS)
GearWarnings.Check()
expect("nur einmal", count(L.WARN_REAGENTS), 1)
wow.state.itemCounts[SACRED_CANDLE] = 20
GearWarnings.Check()
expect("aufgefüllt: nichts knapp", #Reagents.Low(), 0)
wow.state.itemCounts[SACRED_CANDLE] = 2
GearWarnings.Check()
expect("wieder knapp: neue Warnung", count(L.WARN_REAGENTS), 2)

-- Händler: Hinweis nur, wenn er das knappe Reagenz verkauft
wow.state.merchant.items = { 159 }
wow.fire("MERCHANT_SHOW")
expect("Händler ohne Kerzen: still", count(string.format(L.REAGENTS_AT_MERCHANT, "")), 0)
wow.state.merchant.items = { 159, SACRED_CANDLE }
wow.fire("MERCHANT_SHOW")
expect("Händler mit Kerzen", count(string.format(L.REAGENTS_AT_MERCHANT,
  string.format(L.REAGENT_STOCK, "Item " .. SACRED_CANDLE, 2))), 1)

-- Regler: Grenze anteilig (Kerzen = Hälfte, gerundet, mindestens 1)
expect("Standard: Kerzen unter 5", Reagents.Tracked()[1].low, 5)
addon.Set("reagentLow", 2)
expect("Regler 2: Kerzen unter 1", Reagents.Tracked()[1].low, 1)
expect("2 Kerzen nicht mehr knapp", #Reagents.Low(), 0)

-- Ohne bekannten Zauber nichts; Klasse ohne Reagenzien: Einstellung versteckt
wow.state.knownSpells = {}
expect("ohne Zauber: nichts", #Reagents.Tracked(), 0)
wow.state.class = "WARRIOR"
expectTrue("Krieger: nicht verfügbar", not Reagents.IsAvailable())
