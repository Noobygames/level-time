-- Fenster verschieben ("Move Anything"): die Standardfenster des Spiels (Charakter, Zauberbuch, Händler, Quests, ...)
-- lassen sich mit der linken Maustaste an eine andere Stelle ziehen. Die Position wird gemerkt und beim
-- nächsten Öffnen wiederhergestellt (Einstellung moveFrames im Reiter "Komfort", aus).
-- Im Kampf wird nichts verschoben: geschützte Fenster dürfen dann nicht angefasst werden.
-- Fenster, die ein Blizzard-Addon erst später lädt (Talente, Auktionshaus, Flugkarte FlightMapFrame in
-- Retail/Forever, ...), kommen über ADDON_LOADED dazu. Die Classic-Flugkarte (TaxiFrame) ist von Anfang an da.
-- Größe (Roadmap 266, wie BlizzMove): Strg+Mausrad skaliert ein verschobenes Fenster in SCALE_STEP-Schritten,
-- Strg+Rechtsklick setzt es auf 1 zurück; gemerkt in movedFrameScales und beim Öffnen wie die Position gesetzt.
-- Geschützte Fenster (IsProtected) werden im Kampf nicht skaliert.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    moveFrames = false,
  },
})
local L = ns.L

local MoveFrames = {}
ns.MoveFrames = MoveFrames

-- Globale Namen; was ein Client nicht kennt, wird übersprungen
MoveFrames.FRAME_NAMES = {
  "CharacterFrame", "SpellBookFrame", "PlayerTalentFrame", "TalentFrame", "QuestLogFrame", "FriendsFrame",
  "MerchantFrame", "GossipFrame", "QuestFrame", "TradeFrame", "MailFrame", "BankFrame", "ClassTrainerFrame",
  "TradeSkillFrame", "CraftFrame", "AuctionFrame", "AuctionHouseFrame", "InspectFrame", "LootFrame",
  "GuildFrame", "PVEFrame", "LFGParentFrame", "CollectionsJournal", "ProfessionsFrame", "PetStableFrame",
  "TaxiFrame", "FlightMapFrame", "TabardFrame", "MacroFrame", "ItemTextFrame",
}

MoveFrames.MIN_SCALE = 0.5
MoveFrames.MAX_SCALE = 2
MoveFrames.SCALE_STEP = 0.1

local attached = {}  -- [Name] = true, sobald die Griffe eingehängt sind

local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

local function isEnabled()
  return ns.db and ns.db.moveFrames
end

-- Gespeicherte Position nur benutzen, wenn sie vollständig ist (beschädigte Daten würden bei jedem Öffnen Fehler werfen)
local function validPosition(pos)
  return type(pos) == "table" and type(pos[1]) == "string" and type(pos[2]) == "string"
    and type(pos[3]) == "number" and type(pos[4]) == "number"
end

local function savedScale(name)
  local scale = ns.db and ns.db.movedFrameScales and ns.db.movedFrameScales[name]
  if type(scale) ~= "number" then return nil end
  return math.max(MoveFrames.MIN_SCALE, math.min(MoveFrames.MAX_SCALE, scale))
end

local function restore(frame, name)
  if not isEnabled() or inCombat() then return end
  local scale = savedScale(name)
  if scale then frame:SetScale(scale) end
  local pos = ns.db and ns.db.movedFrames and ns.db.movedFrames[name]
  if not validPosition(pos) then return end
  frame:ClearAllPoints()
  frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

-- Geschützte Fenster dürfen im Kampf weder skaliert noch bewegt werden
local function canScale(frame)
  return not (inCombat() and frame.IsProtected and frame:IsProtected())
end

local function setScale(frame, name, scale)
  scale = math.max(MoveFrames.MIN_SCALE, math.min(MoveFrames.MAX_SCALE, scale))
  -- auf eine Nachkommastelle runden, damit sich die Schritte nicht verschieben
  scale = math.floor(scale * 10 + 0.5) / 10
  frame:SetScale(scale)
  ns.db.movedFrameScales = ns.db.movedFrameScales or {}
  ns.db.movedFrameScales[name] = scale ~= 1 and scale or nil
  ns.Debug("moveframes", "%s scale %s", name, scale)
end

local function onMouseWheel(frame, name, delta)
  if not isEnabled() or not IsControlKeyDown() or not canScale(frame) then return end
  local current = frame:GetScale() or 1
  setScale(frame, name, current + (delta > 0 and MoveFrames.SCALE_STEP or -MoveFrames.SCALE_STEP))
end

local function onMouseUp(frame, name, button)
  if button ~= "RightButton" or not isEnabled() or not IsControlKeyDown() or not canScale(frame) then return end
  setScale(frame, name, 1)
end

-- Gemerkt wird nur, was am Bildschirm hängt (nach StopMovingOrSizing immer der Fall)
local function save(frame, name)
  local point, relativeTo, relativePoint, x, y = frame:GetPoint()
  if not point or not x or not y then return end
  if relativeTo ~= nil and relativeTo ~= UIParent then return end
  ns.db.movedFrames = ns.db.movedFrames or {}
  ns.db.movedFrames[name] = { point, relativePoint or point, x, y }
end

-- Retail-Unterbau (Retail, WoW Forever): Fenster in UIPanelWindows ordnet der UIParentPanelManager selbst an und
-- berechnet daraus auch die Plätze von Aktionsleisten und Castbar. Setzen wir dort Positionen, verschwinden Leisten
-- (gemeldet: Controller-Leiste weg, Castbar oben links). Diese Fenster bleiben unangetastet.
local function isManagedByClient(name)
  if not (ns.Client.IsForever() or ns.Client.IsRetail()) then return false end
  return type(UIPanelWindows) == "table" and UIPanelWindows[name] ~= nil
end

-- Die Griffe bleiben auch nach dem Ausschalten am Fenster (Verschieben, Maus, Bildschirmrand); nur das Ziehen
-- und Wiederherstellen prüft die Einstellung.
local function attach(name)
  local frame = _G[name]
  if attached[name] or type(frame) ~= "table" or not frame.HookScript then return end
  attached[name] = true
  if isManagedByClient(name) then
    ns.Debug("moveframes", "skipped %s (managed by the client)", name)
    return
  end
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  -- Mausrad nur am Fenster selbst; Listen darin (Scrollrahmen) liegen darüber und bekommen es weiter zuerst
  frame:EnableMouseWheel(true)
  frame:HookScript("OnMouseWheel", function(self, delta) ns.SafeCall(onMouseWheel, self, name, delta) end)
  frame:HookScript("OnMouseUp", function(self, button) ns.SafeCall(onMouseUp, self, name, button) end)
  local dragging = false  -- nur ein Ziehen, das wirklich begonnen hat, wird gespeichert
  frame:HookScript("OnDragStart", function(self)
    if not isEnabled() or inCombat() then return end
    dragging = true
    self:StartMoving()
  end)
  frame:HookScript("OnDragStop", function(self)
    if not dragging then return end
    dragging = false
    self:StopMovingOrSizing()
    if isEnabled() then ns.SafeCall(save, self, name) end
  end)
  -- Blizzard setzt verwaltete Fenster beim Öffnen selbst: nach deren Anordnung noch einmal überschreiben
  frame:HookScript("OnShow", function(self)
    ns.SafeCall(restore, self, name)
    C_Timer.After(0, function() ns.SafeCall(restore, self, name) end)
  end)
  ns.Debug("moveframes", "attached to %s", name)
end

-- Im Kampf nicht anfassen; PLAYER_REGEN_ENABLED holt es nach
local function attachAll()
  if not isEnabled() or inCombat() then return end
  for _, name in ipairs(MoveFrames.FRAME_NAMES) do
    ns.SafeCall(attach, name)
  end
end

-- Gemerkte Positionen vergessen; die Fenster stehen wieder an ihrer Standardstelle, sobald das Spiel sie neu anordnet
function MoveFrames.Reset()
  ns.db.movedFrames = nil
  -- Größen sofort zurück, aber nur bei Fenstern, die wir skaliert haben
  for name in pairs(ns.db.movedFrameScales or {}) do
    local frame = _G[name]
    if type(frame) == "table" and frame.SetScale and canScale(frame) then frame:SetScale(1) end
  end
  ns.db.movedFrameScales = nil
  ns.Print(L.MOVE_FRAMES_RESET_DONE)
end

ns.RegisterEvent("ADDON_LOADED", attachAll)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", attachAll)
ns.RegisterApply(attachAll)
