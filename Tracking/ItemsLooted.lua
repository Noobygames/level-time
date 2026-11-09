-- Zählt eigene Beute aller Qualitäten nach Anzahl (ein Stapel aus 5 zählt 5) als Zähler itemsLooted für Level,
-- Session und Instanz-Lauf (Gegenstände/h, Roadmap 382). Quelle sind die eigenen Beute-Zeilen aus Loot.lua (geheime
-- Zeilen fallen dort schon weg, fremde Beute passt auf keins der Formate). "Ihr erhaltet einen Gegenstand" (pushed)
-- kommt auch bei Käufen beim Händler: solche Zeilen zählen nicht, solange ein Händler offen ist und kurz danach.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showItemsLooted = false,
  },
  counters = {
    itemsLooted = 0,
  },
})
local Stats = ns.Stats

local MERCHANT_GRACE = 2  -- Sekunden nach dem Schließen, in denen eine erhaltene Ware noch als Kauf gilt

local merchantOpen = false
local merchantClosedAt

local function buying()
  return merchantOpen or (merchantClosedAt ~= nil and GetTime() - merchantClosedAt <= MERCHANT_GRACE)
end

ns.RegisterEvent("MERCHANT_SHOW", function() merchantOpen = true end)
ns.RegisterEvent("MERCHANT_CLOSED", function()
  merchantOpen = false
  merchantClosedAt = GetTime()
end)

ns.Loot.OnSelfLoot(function(_, quantity, pushed)
  if pushed and buying() then
    ns.Debug("loot", "received item while buying, not counted as loot")
    return
  end
  Stats.Increment(Stats.ITEMS_LOOTED, quantity)
end)
