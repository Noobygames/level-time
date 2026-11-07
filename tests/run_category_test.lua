-- Run-Kategorie automatisch: SSF -> Solo (Handel/Post/AH) -> Gruppe -> Geboostet, nie zurück.
local RunCategory = addon.RunCategory
local Runs = addon.Runs

-- Älterer Charakter (schon Level): unbekannt
wow.login({ name = "Alt", level = 20, playedSeconds = 0 })
expect("alter Charakter unbekannt", addon.character.runCategory, nil)
expect("Anzeige unbekannt", RunCategory.Label(nil), "-")
wow.fire("MAIL_SHOW")
expect("unbekannt -> Solo", addon.character.runCategory, "solo")
wow.logout()

-- Neuer Charakter: SSF
wow.login({ name = "Neu", level = 1, playedSeconds = 0 })
expect("neu = SSF", addon.character.runCategory, "ssf")
expect("im Lauf", Runs.Get(addon.characterKey).category, "ssf")

wow.fire("AUCTION_HOUSE_SHOW")
expect("AH -> Solo", addon.character.runCategory, "solo")

wow.state.inGroup = true
wow.fire("GROUP_ROSTER_UPDATE")
expect("Gruppe", addon.character.runCategory, "group")

-- Hohes Gruppenmitglied, Level erst später lesbar: Prüfung alle 5 s
wow.state.units.party1 = { name = "Booster", level = 60 }
wow.update(6)
expect("Geboostet", addon.character.runCategory, "boosted")

-- Nie zurück
wow.state.inGroup = false
wow.fire("TRADE_SHOW")
expect("bleibt geboostet", addon.character.runCategory, "boosted")

-- Export und Import tragen die Kategorie, ungültige wird verworfen
local decoded = addon.Serializer.Decode("run", Runs.Export(Runs.Get(addon.characterKey)))
expect("im Export", decoded.category, "boosted")
decoded.name, decoded.times = "Fremd", { [1] = 100 }
Runs.Import(addon.Serializer.Encode("run", decoded))
expect("importiert", Runs.FindByName("Fremd").category, "boosted")
decoded.name, decoded.category = "Komisch", "cheater"
Runs.Import(addon.Serializer.Encode("run", decoded))
expect("ungültige Kategorie verworfen", Runs.FindByName("Komisch").category, nil)
expect("Anzeige", RunCategory.Label("boosted"), addon.L.RUN_CATEGORY_BOOSTED)
