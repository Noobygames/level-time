-- FNV-1a (32 Bit) in reinem Lua 5.1 ohne Bit-Bibliothek: nur Ganzzahl-Arithmetik, die in Doubles exakt bleibt.
-- Fnv.Hash(text, seed) -> Zahl, Fnv.Hex(text, seed) -> 8 Hex-Zeichen; seed = vorheriger Hash (Verkettung).
local _, ns = ...

local Fnv = {}
ns.Fnv = Fnv

local OFFSET_BASIS = 2166136261
local MODULUS = 4294967296   -- 2^32
local BYTE = 256
local PRIME_HIGH = 16777216  -- FNV-Primzahl 16777619 = 2^24 + 403
local PRIME_LOW = 403

-- XOR zweier Bytes über ihre Bits
local function xorByte(a, b)
  local result, bitValue = 0, 1
  for _ = 1, 8 do
    local bitA, bitB = a % 2, b % 2
    if bitA ~= bitB then result = result + bitValue end
    a, b, bitValue = (a - bitA) / 2, (b - bitB) / 2, bitValue * 2
  end
  return result
end

-- h * Primzahl mod 2^32: h * 2^24 mod 2^32 hängt nur vom untersten Byte ab, h * 403 bleibt unter 2^41
local function multiply(h)
  return ((h % BYTE) * PRIME_HIGH + h * PRIME_LOW) % MODULUS
end

function Fnv.Hash(text, seed)
  local h = seed or OFFSET_BASIS
  for i = 1, #text do
    local low = h % BYTE
    h = multiply(h - low + xorByte(low, text:byte(i)))
  end
  return h
end

function Fnv.Hex(text, seed)
  return string.format("%08x", Fnv.Hash(text, seed))
end
