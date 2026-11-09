-- Meilenstein-Screenshots (alle aus): Screenshot() kurz nach dem Ereignis, damit Level-Up-Effekt bzw. Beute im
-- Bild sind. Der Client speichert das Bild selbst im Ordner Screenshots.
--   milestoneScreenshots      alle SCREENSHOT_LEVEL_STEP Level und beim Max-Level (GetMaxPlayerLevel)
--   screenshotFirstDungeon    beim ersten Betreten einer Gruppen-Instanz (party) je Charakter
--                             (character.firstDungeonShot, InstanceCopy.OnEnter)
--   screenshotEpicLoot        bei epischer oder besserer Beute (Journal lootLog, Qualität >= 4)
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    milestoneScreenshots = false,
    screenshotFirstDungeon = false,
    screenshotEpicLoot = false,
  },
})

local MilestoneScreenshots = {
  LEVEL_STEP = 5,
  DELAY_SECONDS = 1,
}
ns.MilestoneScreenshots = MilestoneScreenshots

local EPIC_QUALITY = 4
local DUNGEON = "party"

function MilestoneScreenshots.IsMilestone(level)
  local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel()
  return level % MilestoneScreenshots.LEVEL_STEP == 0 or level == maxLevel
end

local function take(reason)
  if not Screenshot then return end
  ns.Debug("screenshot", "milestone %s", reason)
  C_Timer.After(MilestoneScreenshots.DELAY_SECONDS, function() Screenshot() end)
end

ns.OnLevelStarted(function(level)
  if ns.db.milestoneScreenshots and MilestoneScreenshots.IsMilestone(level) then take("level " .. level) end
end)

ns.InstanceCopy.OnEnter(function(name, instanceType)
  if not ns.db.screenshotFirstDungeon or instanceType ~= DUNGEON or ns.character.firstDungeonShot then return end
  ns.character.firstDungeonShot = true
  take("first dungeon " .. tostring(name))
end)

ns.Journal.OnAdd(function(logName, entry)
  if logName == "lootLog" and ns.db.screenshotEpicLoot and (entry.quality or 0) >= EPIC_QUALITY then
    take("epic loot")
  end
end)
