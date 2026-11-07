-- Gleitendes Zeitfenster über Ereignisse (z.B. Kills der letzten 15 Minuten): Ringpuffer aus Zeitpunkt und Menge mit
-- laufender Summe. Add und Count sind amortisiert O(1): Count verwirft nur abgelaufene Einträge am Anfang und prüft
-- sonst eine Zahl. Zwei Zahlen-Arrays statt einer Tabelle je Ereignis; bei vollem Puffer verdoppelt er sich.
local _, ns = ...

local RecentCounter = {}
ns.RecentCounter = RecentCounter

local INITIAL_CAPACITY = 64

local Counter = {}
Counter.__index = Counter

-- window = Länge des Fensters in Sekunden (Zeitpunkte z.B. aus GetTime())
function RecentCounter.New(window)
  local counter = setmetatable({ window = window }, Counter)
  counter:Reset()
  return counter
end

function Counter:Reset()
  self.times, self.amounts = {}, {}
  self.capacity = INITIAL_CAPACITY
  self.head, self.size, self.total = 1, 0, 0
end

local function slot(self, offset)
  return (self.head + offset - 1) % self.capacity + 1
end

-- Einträge (älteste zuerst) in einen doppelt so großen Puffer umziehen
local function grow(self)
  local times, amounts = {}, {}
  for offset = 0, self.size - 1 do
    local index = slot(self, offset)
    times[offset + 1], amounts[offset + 1] = self.times[index], self.amounts[index]
  end
  self.times, self.amounts = times, amounts
  self.capacity = self.capacity * 2
  self.head = 1
end

-- Alles verwerfen, was window oder mehr Sekunden zurückliegt
local function expire(self, now)
  local limit = now - self.window
  while self.size > 0 and self.times[self.head] <= limit do
    self.total = self.total - self.amounts[self.head]
    self.head = self.head % self.capacity + 1
    self.size = self.size - 1
  end
end

function Counter:Add(now, amount)
  amount = amount or 1
  expire(self, now)
  if self.size == self.capacity then grow(self) end
  local index = slot(self, self.size)
  self.times[index], self.amounts[index] = now, amount
  self.size = self.size + 1
  self.total = self.total + amount
end

-- Summe der Mengen der letzten window Sekunden
function Counter:Count(now)
  expire(self, now)
  return self.total
end
