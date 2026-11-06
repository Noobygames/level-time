-- Charakterfenster: Gesamthaltbarkeit in Prozent und Lautstärkeregler (Roadmap 329, Schritt 2d und 4)
PaperDollFrame = CreateFrame("Frame", nil, UIParent)
CharacterMainHandSlot = CreateFrame("Button", nil, PaperDollFrame)
CharacterSecondaryHandSlot = CreateFrame("Button", nil, PaperDollFrame)
wow.state.cvars = { Sound_MasterVolume = "0.5" }
wow.state.durability = { [1] = { 30, 60 }, [5] = { 90, 100 }, [16] = { 0, 40 } }

wow.login()
local Extras = addon.CharacterFrameExtras
expect("aus: nichts angelegt", (Extras.Widgets()), nil)

-- Gesamthaltbarkeit: (30 + 90 + 0) / (60 + 100 + 40) = 60 %
expectNear("Gesamthaltbarkeit", addon.GearWarnings.GetOverallDurability(), 0.6)
addon.Set("characterDurability", true)
local value = Extras.Widgets()
expect("Prozent im Fenster", value:GetText(), "60%")
expectTrue("sichtbar", value:IsShown())
-- Reparatur: Ereignis aktualisiert
wow.state.durability = { [1] = { 60, 60 } }
wow.fire("UPDATE_INVENTORY_DURABILITY")
expect("nach Reparatur", value:GetText(), "100%")
-- Ohne Gegenstände mit Haltbarkeit: keine Anzeige
wow.state.durability = {}
wow.fire("UPDATE_INVENTORY_DURABILITY")
expect("ohne Haltbarkeit versteckt", value:IsShown(), false)
addon.Set("characterDurability", false)
wow.state.durability = { [1] = { 10, 60 } }
wow.fire("UPDATE_INVENTORY_DURABILITY")
expect("aus: versteckt", value:IsShown(), false)
expect("Farbe rot unter 20 %", Extras.DurabilityColor(0.1)[2], 0.2)

-- Lautstärke: Regler zeigt die CVar, Ziehen setzt sie
local _, volume = Extras.Widgets()
expect("aus: Regler versteckt", volume:IsShown(), false)
addon.Set("characterVolume", true)
expectTrue("Regler sichtbar", volume:IsShown())
expect("Wert aus der CVar", volume.valueText:GetText(), "50 %")
volume.slider._scripts.OnValueChanged(volume.slider, 35)
expect("CVar gesetzt", tonumber(wow.state.cvars.Sound_MasterVolume), 0.35)
expect("Anzeige", volume.valueText:GetText(), "35 %")
