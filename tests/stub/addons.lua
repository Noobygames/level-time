-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Load-on-Demand-Addons, Addon-Nachrichten, Screenshots, Chat-Sperre.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state
local ADDON_DIR = stub.ADDON_DIR

-- Load-on-Demand-Addons (LevelTimer_Archive): LoadAddOn führt die Dateien der .toc aus und meldet ADDON_LOADED.
-- state.addOnsUnavailable[name] = true wie ein fehlendes oder ausgeschaltetes Addon; wow.addOnLoads zählt Ladevorgänge.
wow.addOnLoads = {}
local loadedAddOns = {}
C_AddOns = {
  IsAddOnLoaded = function(name) return loadedAddOns[name] == true end,
  LoadAddOn = function(name)
    if loadedAddOns[name] then return true end
    if (state.addOnsUnavailable or {})[name] then return false, "DISABLED" end
    local toc = io.open(ADDON_DIR .. "/" .. name .. "/" .. name .. ".toc")
    if not toc then return false, "MISSING" end
    local namespace = {}
    for line in toc:lines() do
      line = line:gsub("\r", ""):gsub("\\", "/")
      if line ~= "" and not line:match("^#") then
        local chunk, err = loadfile(ADDON_DIR .. "/" .. name .. "/" .. line)
        if not chunk then error(err, 0) end
        chunk(name, namespace)
      end
    end
    toc:close()
    loadedAddOns[name] = true
    wow.addOnLoads[name] = (wow.addOnLoads[name] or 0) + 1
    wow.fire("ADDON_LOADED", name)
    return true
  end,
}

-- Addon-Nachrichten: wow.addonMessages = { { prefix, message, chatType, target } }, wow.addonPrefixes
wow.addonMessages = {}
wow.addonPrefixes = {}
function NotifyInspect() end
-- Screenshot(): wow.screenshots zählt die Aufnahmen
wow.screenshots = 0
function Screenshot() wow.screenshots = wow.screenshots + 1 end
function GetUnitName(unit, showServer)
  local name = UnitName(unit)
  local realm = state.units[unit] and state.units[unit].realm
  if showServer and name and realm then return name .. "-" .. realm end
  return name
end
C_ChatInfo = {
  RegisterAddonMessagePrefix = function(prefix) wow.addonPrefixes[prefix] = true; return 0 end,
  SendAddonMessage = function(prefix, message, chatType, target)
    table.insert(wow.addonMessages, { prefix = prefix, message = message, chatType = chatType, target = target })
    return 0
  end,
  SendChatMessage = function(message, chatType) table.insert(wow.sentChat, { message = message, chatType = chatType }) end,
  InChatMessagingLockdown = function() return state.chatLockdown end,
}
