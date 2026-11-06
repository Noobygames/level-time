-- Aggro-Hinweis: nur eingeschaltet, nur in einer Gruppe, nicht als Tank; einmal beim Wechsel zu Aggro
local L = addon.L

local function shown()
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(L.WARN_AGGRO, 1, true) then count = count + 1 end
  end
  return count
end

local function threat(situation)
  wow.state.threat = situation
  wow.fire("UNIT_THREAT_SITUATION_UPDATE", "player")
end

local function endCombat()
  threat(0)
  wow.fire("PLAYER_REGEN_ENABLED")
  wow.advance(10)
end

wow.login({ level = 20 })
wow.state.inGroup = true

threat(3)
expect("aus: still", shown(), 0)
endCombat()

addon.Set("warnAggro", true)
threat(1)
expect("nur höhere Bedrohung: still", shown(), 0)
threat(3)
expect("Aggro: Hinweis", shown(), 1)
expect("als Karte", LevelTimerNotice.body:GetText(), L.WARN_AGGRO)
threat(3)
threat(2)
expect("bleibt Aggro: kein zweiter", shown(), 1)
threat(1)
threat(3)
expect("hin und her: nicht sofort wieder", shown(), 1)
wow.advance(6)
threat(1)
threat(2)
expect("später wieder gezogen", shown(), 2)
endCombat()

wow.state.role = "TANK"
threat(3)
expect("Tank: still", shown(), 2)
endCombat()
wow.state.role = nil

wow.state.inGroup = false
threat(3)
expect("allein: still", shown(), 2)
endCombat()

wow.state.inGroup = true
wow.state.threat = wow.SECRET
wow.fire("UNIT_THREAT_SITUATION_UPDATE", "player")
expect("geheim: still", shown(), 2)
expect("keine Fehler", #wow.errors, 0)
