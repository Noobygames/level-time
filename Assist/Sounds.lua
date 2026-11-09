-- Töne (Reiter Komfort, System), je Einstellung, Standard aus:
--   silenceRestedEmotes  Emote-Töne (CVar Sound_EnableEmoteSounds, Blizzards Audio-Einstellungen) aus, solange der
--                        Charakter ausruht (IsResting, PLAYER_UPDATE_RESTING); danach kommt der Wert des Spielers
--                        zurück (CVars.lua).
--   mute*                Gruppen von Spieldateien stummschalten (MuteSoundFile/UnmuteSoundFile, ab 8.2.0 bzw. Classic
--                        1.13; Stummschaltung hält bis zum Neustart des Clients, nicht über ihn hinaus). Ausschalten
--                        gibt nur die selbst stummgeschalteten Dateien frei.
-- Datei-IDs (FileDataID) aus der Community-Listfile von wowdev (github.com/wowdev/wow-listfile), selbst nachgeschlagen:
--   Zauber-Fehlschlag    sound/spells/fizzle/fizzle{holy,fire,nature,frost,shadow}a.ogg
--   Stadtglocken         sound/doodad/belltoll{horde,tribal,nightelf,alliance}.ogg, kharazahnbelltoll.ogg
--   Roboschreiter        sound/creature/mechastrider/*.ogg (Laufgeräusch, Angriff, Treffer, Tod)
-- Im Client fehlende IDs sind harmlos (nichts zu stummen).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    silenceRestedEmotes = false,
    muteFizzle = false,
    muteBells = false,
    muteMechastrider = false,
  },
})

local Sounds = {}
ns.Sounds = Sounds

local EMOTE_CVAR = "Sound_EnableEmoteSounds"
local EMOTES_OFF = 0

Sounds.MUTE_GROUPS = {
  { setting = "muteFizzle", label = "MUTE_FIZZLE", files = { 569772, 569773, 569774, 569775, 569776 } },
  { setting = "muteBells", label = "MUTE_BELLS", files = { 565853, 566027, 566254, 566558, 566564 } },
  { setting = "muteMechastrider", label = "MUTE_MECHASTRIDER", files = {
    555123, 555124, 555125, 555126, 555127, 555128, 555129, 555130, 555131, 555132, 555133,
  } },
}

function Sounds.CanMute()
  return MuteSoundFile ~= nil and UnmuteSoundFile ~= nil
end

local function updateRestedEmotes()
  if ns.db.silenceRestedEmotes == true and IsResting() then
    ns.CVars.Override(EMOTE_CVAR, EMOTES_OFF)
  else
    ns.CVars.Restore(EMOTE_CVAR)
  end
end

local muted = {}  -- Einstellung -> true, wenn ihre Dateien von uns stummgeschaltet sind

local function updateMuteGroups(db)
  if not Sounds.CanMute() then return end
  for _, group in ipairs(Sounds.MUTE_GROUPS) do
    local wanted = db[group.setting] == true
    if wanted ~= (muted[group.setting] == true) then
      local apply = wanted and MuteSoundFile or UnmuteSoundFile
      for _, file in ipairs(group.files) do apply(file) end
      muted[group.setting] = wanted or nil
      ns.Debug("comfort", "sound group %s muted %s", group.setting, wanted)
    end
  end
end

ns.RegisterApply(function(db)
  updateRestedEmotes()
  updateMuteGroups(db)
end)

ns.RegisterEvent("PLAYER_UPDATE_RESTING", function()
  if ns.db then updateRestedEmotes() end
end)
