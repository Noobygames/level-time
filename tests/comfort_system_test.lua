-- Komfort, System (Roadmap 329, Schritt 5): Bildschirmeffekte, Wetter, Namensplaketten im Kampf, Emotes beim
-- Ausruhen, stumme Töne, Schlachtzug-Beschränkung, Addon-Liste, eine Gruppenfarbe. Alles aus, bis eingeschaltet;
-- ausgeschaltet kommen die Werte des Spielers zurück.

-- Client-Funktionen, die der Stub nicht kennt
local mutedFiles = {}
MuteSoundFile = function(file) mutedFiles[file] = true end
UnmuteSoundFile = function(file) mutedFiles[file] = nil end

local lowLevelRaid = false
GetAllowLowLevelRaid = function() return lowLevelRaid end
SetAllowLowLevelRaid = function(allow) lowLevelRaid = allow end

-- Chatfarben: ChangeChatColor meldet die Farbe wie der Client per UPDATE_CHAT_COLOR, Blizzards Chatfenster tragen sie
-- in ChatTypeInfo ein (hier der Test selbst)
ChatTypeInfo = {
  PARTY = { r = 0.67, g = 0.67, b = 1 }, PARTY_LEADER = { r = 0.46, g = 0.78, b = 1 },
  RAID = { r = 1, g = 0.5, b = 0 }, RAID_LEADER = { r = 1, g = 0.28, b = 0.04 },
  INSTANCE_CHAT = { r = 1, g = 0.5, b = 0 }, INSTANCE_CHAT_LEADER = { r = 1, g = 0.28, b = 0.04 },
}
local colorChanges = 0
ChangeChatColor = function(chatType, r, g, b)
  colorChanges = colorChanges + 1
  local info = ChatTypeInfo[chatType]
  info.r, info.g, info.b = r, g, b
  wow.fire("UPDATE_CHAT_COLOR", chatType, r, g, b)
end

wow.state.cvars = {
  ffxGlow = "1", ffxDeath = "1", ffxNether = "1", weatherDensity = "2", RAIDweatherDensity = "1",
  nameplateShowEnemies = "1", Sound_EnableEmoteSounds = "1",
}
local cvars = wow.state.cvars

wow.login({ level = 20 })

local untouched = {}
for name, value in pairs(cvars) do untouched[name] = value end
for name, value in pairs(untouched) do expect("aus: " .. name .. " unberührt", cvars[name], value) end
expect("aus: nichts gemerkt", LevelTimerDB.cvarOriginals, nil)
expect("aus: nichts stumm", next(mutedFiles), nil)
expect("aus: Beschränkung unberührt", lowLevelRaid, false)
expect("aus: keine Farbe geändert", colorChanges, 0)

---------------------------------------------------------------------------
-- Bildschirmeffekte und Wetter
---------------------------------------------------------------------------
addon.Set("noDrunkenHaze", true)
expect("Rausch-Schleier aus", cvars.ffxGlow, "0")
addon.Set("noScreenEffects", true)
expect("Geist grau aus", cvars.ffxDeath, "0")
expect("Nether aus", cvars.ffxNether, "0")
addon.Set("noDrunkenHaze", false)
expect("Glanz zurück", cvars.ffxGlow, "1")
expect("Effekte bleiben aus", cvars.ffxDeath, "0")
addon.Set("noScreenEffects", false)
expect("Geist grau zurück", cvars.ffxDeath, "1")
expect("Nether zurück", cvars.ffxNether, "1")

addon.Set("weatherDensity", 0)
expect("Regler allein ändert nichts", cvars.weatherDensity, "2")
addon.Set("setWeatherDensity", true)
expect("Wetter aus", cvars.weatherDensity, "0")
expect("Wetter im Schlachtzug aus", cvars.RAIDweatherDensity, "0")
addon.Set("weatherDensity", 3)
expect("Regler wirkt sofort", cvars.weatherDensity, "3")
-- /reload: Originale überleben (gespeichert), nach dem Ausschalten kommt der Wert von vor dem Einschalten zurück
wow.logout()
wow.login({ level = 20 })
expect("nach /reload noch gesetzt", cvars.weatherDensity, "3")
addon.Set("setWeatherDensity", false)
expect("Wetter zurück", cvars.weatherDensity, "2")
expect("Schlachtzug-Wetter zurück", cvars.RAIDweatherDensity, "1")
expect("nichts mehr gemerkt", LevelTimerDB.cvarOriginals, nil)

-- Unbekannte CVar (anderer Client): kein Fehler, nichts gemerkt
cvars.ffxNether = nil
addon.Set("noScreenEffects", true)
expect("fehlende CVar nicht angelegt", cvars.ffxNether, nil)
expect("fehlende CVar nicht gemerkt", LevelTimerDB.cvarOriginals.ffxNether, nil)
addon.Set("noScreenEffects", false)
cvars.ffxNether = "1"

-- Profilwechsel behält die gemerkten Originale (gehören zum Account, nicht zum Profil)
addon.Profiles.SaveAs("Ohne")
addon.Profiles.SaveAs("Mit")
addon.Set("noDrunkenHaze", true)
addon.Profiles.Switch("Ohne")
expect("Original nicht im Profil", LevelTimerDB.profiles.Mit.cvarOriginals, nil)
expect("Profil ohne: Glanz zurück", cvars.ffxGlow, "1")
addon.Profiles.Switch("Mit")
expect("Profil mit: Glanz aus", cvars.ffxGlow, "0")
addon.Profiles.Switch("Ohne")

---------------------------------------------------------------------------
-- Namensplaketten nur im Kampf
---------------------------------------------------------------------------
addon.Set("combatPlates", true)
expect("außerhalb des Kampfs aus", cvars.nameplateShowEnemies, "0")
wow.fire("PLAYER_REGEN_DISABLED")
expect("Kampfbeginn: an", cvars.nameplateShowEnemies, "1")
wow.fire("PLAYER_REGEN_ENABLED")
expect("Kampfende: aus", cvars.nameplateShowEnemies, "0")
-- Im Kampf ausgeschaltet: geschützt, nach dem Kampf nachgeholt
wow.fire("PLAYER_REGEN_DISABLED")
wow.state.combatLockdown = true
addon.Set("combatPlates", false)
expect("im Kampf nicht angefasst", cvars.nameplateShowEnemies, "1")
wow.state.combatLockdown = false
cvars.nameplateShowEnemies = "0"  -- Stand nach unserem Kampfende wäre egal: das Original zählt
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf Wert des Spielers", cvars.nameplateShowEnemies, "1")
wow.fire("PLAYER_REGEN_DISABLED")
cvars.nameplateShowEnemies = "0"
wow.fire("PLAYER_REGEN_DISABLED")
expect("aus: Kampf ändert nichts", cvars.nameplateShowEnemies, "0")
cvars.nameplateShowEnemies = "1"

-- Classic Era speichert die CVar je Charakter: Original dann in den Charakterdaten
local retailInterface = wow.state.interface
wow.state.interface = 11508
addon.Set("combatPlates", true)
expect("Classic: Original je Charakter", addon.character.cvarOriginals.nameplateShowEnemies, "1")
expect("Classic: nicht im Account", (LevelTimerDB.cvarOriginals or {}).nameplateShowEnemies, nil)
addon.Set("combatPlates", false)
expect("Classic: zurück", cvars.nameplateShowEnemies, "1")
wow.state.interface = retailInterface

---------------------------------------------------------------------------
-- Emotes beim Ausruhen, stumme Töne
---------------------------------------------------------------------------
addon.Set("silenceRestedEmotes", true)
expect("unterwegs: Emotes an", cvars.Sound_EnableEmoteSounds, "1")
wow.state.resting = true
wow.fire("PLAYER_UPDATE_RESTING")
expect("ausruhen: Emotes stumm", cvars.Sound_EnableEmoteSounds, "0")
wow.state.resting = false
wow.fire("PLAYER_UPDATE_RESTING")
expect("weiter: Emotes zurück", cvars.Sound_EnableEmoteSounds, "1")
wow.state.resting = true
wow.fire("PLAYER_UPDATE_RESTING")
addon.Set("silenceRestedEmotes", false)
expect("ausgeschaltet: Emotes zurück", cvars.Sound_EnableEmoteSounds, "1")
wow.state.resting = false

addon.Set("muteFizzle", true)
for _, file in ipairs(addon.Sounds.MUTE_GROUPS[1].files) do expect("stumm " .. file, mutedFiles[file], true) end
expect("Glocken nicht stumm", mutedFiles[addon.Sounds.MUTE_GROUPS[2].files[1]], nil)
addon.Set("muteBells", true)
expect("Glocken stumm", mutedFiles[addon.Sounds.MUTE_GROUPS[2].files[1]], true)
addon.Set("muteFizzle", false)
expect("Fehlschlag wieder hörbar", mutedFiles[addon.Sounds.MUTE_GROUPS[1].files[1]], nil)
addon.Set("muteBells", false)
expect("alles hörbar", next(mutedFiles), nil)

---------------------------------------------------------------------------
-- Schlachtzug-Beschränkung: Original je Charakter
---------------------------------------------------------------------------
addon.Set("noRaidRestrictions", true)
expect("erlaubt", lowLevelRaid, true)
expect("Original gemerkt", addon.character.lowLevelRaidOriginal, false)
addon.Set("noRaidRestrictions", false)
expect("Original zurück", lowLevelRaid, false)
expect("Original vergessen", addon.character.lowLevelRaidOriginal, nil)
lowLevelRaid = true
addon.Set("noRaidRestrictions", true)
addon.Set("noRaidRestrictions", false)
expect("schon erlaubt bleibt erlaubt", lowLevelRaid, true)

---------------------------------------------------------------------------
-- Addon-Liste: Blizzard_AddOnList lädt hier erst nach uns (ADDON_LOADED)
---------------------------------------------------------------------------
local titles = { "|cff00ff00Zeta|r", "alpha", "Beta" }
C_AddOns.GetAddOnTitle = function(index) return titles[index] end
C_AddOns.GetAddOnName = function(index) return "Addon" .. index end
local function node(data) return { GetData = function() return data end } end
local provider = { nodes = { node({ addonIndex = 1 }), node({ addonIndex = 2 }), node({ category = "Kampf" }),
  node({ addonIndex = 3 }) } }
function provider:SetSortComparator(compare) table.sort(self.nodes, compare) end
AddonList = CreateFrame("Frame")
AddonList.ScrollBox = { GetDataProvider = function() return provider end }
local blizzardUpdates = 0
AddonList_Update = function() blizzardUpdates = blizzardUpdates + 1 end
wow.fire("ADDON_LOADED", "Blizzard_AddOnList")

AddonList_Update()
expect("aus: Blizzards Reihenfolge", provider.nodes[1]:GetData().addonIndex, 1)
AddonList:Show()
addon.Set("sortAddonList", true)
expect("offene Liste neu aufgebaut", blizzardUpdates, 2)
local order = {}
for i, entry in ipairs(provider.nodes) do
  local data = entry:GetData()
  order[i] = data.category or titles[data.addonIndex]
end
expect("Kategorie zuerst", order[1], "Kampf")
expect("dann alpha", order[2], "alpha")
expect("dann Beta", order[3], "Beta")
expect("Farbcodes ignoriert", order[4], "|cff00ff00Zeta|r")
addon.ApplySettings()
expect("nur beim Umschalten neu aufgebaut", blizzardUpdates, 2)
addon.Set("sortAddonList", false)
expect("aus: Blizzard baut neu", blizzardUpdates, 3)

---------------------------------------------------------------------------
-- Eine Gruppenfarbe: Original je Charakter, folgt der Gruppenfarbe
---------------------------------------------------------------------------
addon.Set("universalGroupColor", true)
expect("Schlachtzug wie Gruppe", ChatTypeInfo.RAID.r, 0.67)
expect("Instanzleiter wie Gruppenleiter", ChatTypeInfo.INSTANCE_CHAT_LEADER.g, 0.78)
expect("Original gemerkt", addon.character.chatColorOriginals.RAID[1], 1)
local changes = colorChanges
expect("vier Farben geändert, keine Schleife", changes, 4)
ChangeChatColor("PARTY", 0.2, 0.4, 0.6)
expect("folgt der Gruppenfarbe", ChatTypeInfo.RAID.b, 0.6)
expect("Original bleibt", addon.character.chatColorOriginals.RAID[2], 0.5)
addon.Set("universalGroupColor", false)
expect("Schlachtzug zurück", ChatTypeInfo.RAID.g, 0.5)
expect("Instanzleiter zurück", ChatTypeInfo.INSTANCE_CHAT_LEADER.b, 0.04)
expect("Originale vergessen", addon.character.chatColorOriginals, nil)

expect("keine Fehler", #wow.errors, 0)
