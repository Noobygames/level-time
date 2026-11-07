-- Roadmap 205: In WoW Forever ist das Leben geheim, Beinahe-Tode bleiben immer leer: kein Unterreiter dafür.
local L = addon.L
wow.login({ level = 20 })
expect("Forever ohne Beinahe-Tode", addon.NearDeath.IsAvailable(), false)
SlashCmdList.LEVELTIMER("history")
expectTrue("Journal-Reiter da", wow.click(L.HISTORY_GROUP_JOURNAL or L.HISTORY_TAB_KILLS))
expectTrue("Kills-Unterreiter da", wow.click(L.HISTORY_TAB_KILLS))
expect("kein Beinahe-Tode-Unterreiter", wow.click(L.HISTORY_TAB_NEAR_DEATHS), false)
