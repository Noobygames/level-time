-- Roadmap 212: Beute- und Quest-Zeilen der Historie zeigen den Spiel-Tooltip ihres Links.
local L = addon.L
local Journal = addon.Journal

wow.login({ level = 20 })
Journal.AddLoot({ link = "|cff0070dd|Hitem:6448:0:0:0|h[Schwanzpeitsche]|h|r", name = "Schwanzpeitsche", quality = 3 })
Journal.AddLoot({ name = "Ohne Link", quality = 3 })

local shown
GameTooltip.SetHyperlink = function(_, link) shown = link end
GameTooltip.Show = function() end

local function rowWithText(text)
  return wow.findFrame(function(frame)
    if not rawget(frame, "cells") or not frame._scripts.OnEnter then return false end
    for _, cell in ipairs(frame.cells) do
      if cell._text and cell._text:find(text, 1, true) then return true end
    end
    return false
  end)
end

SlashCmdList.LEVELTIMER("history")
wow.click(L.HISTORY_GROUP_JOURNAL)
expectTrue("Beute-Reiter", wow.click(L.HISTORY_TAB_LOOT))
local lootRow = rowWithText("Schwanzpeitsche")
expectTrue("Beute-Zeile mit Tooltip", lootRow ~= nil)
lootRow._scripts.OnEnter(lootRow)
expect("Gegenstands-Link", shown, "item:6448:0:0:0")
shown = nil
local plainRow = rowWithText("Ohne Link")
plainRow._scripts.OnEnter(plainRow)
expect("ohne Link kein Tooltip", shown, nil)

-- Quest: Link aus Quest-ID und Stufe
addon.character.questLog[#addon.character.questLog + 1] = { time = time(), level = 20, questID = 783, name = "Eine Bedrohung" }
expectTrue("Quest-Reiter", wow.click(L.HISTORY_TAB_QUESTS))
wow.update(6)  -- Tabelle baut bei geändertem Stand neu
local questRow = rowWithText("Eine Bedrohung")
expectTrue("Quest-Zeile mit Tooltip", questRow ~= nil)
questRow._scripts.OnEnter(questRow)
expect("Quest-Link", shown, "quest:783:20")

-- Unbekannte Link-Art im Client: kein Fehler
GameTooltip.SetHyperlink = function() error("Unknown link type") end
questRow._scripts.OnEnter(questRow)
expect("kein Lua-Fehler", #wow.errors, 0)
