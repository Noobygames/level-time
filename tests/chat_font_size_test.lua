-- Eigene Chat-Schriftgröße (chatFontOverride/chatFontSize): alle Fenster, Originale je Charakter gemerkt, auch nach
-- /reload, aus = vorherige Größen
wow.chatWindowSizes = { [1] = 14, [2] = 12 }
wow.login()

addon.Set("chatFontSize", 22)
expect("Schalter aus: Größe bleibt", wow.chatWindowSizes[1], 14)
addon.Set("chatFontOverride", true)
expect("an: Fenster 1", wow.chatWindowSizes[1], 22)
expect("an: Fenster 2", wow.chatWindowSizes[2], 22)
expect("Originale je Charakter gemerkt", addon.character.chatFontOriginals[2], 12)
addon.Set("chatFontSize", 99)
expect("Größe begrenzt", wow.chatWindowSizes[1], addon.ChatFontSize.MAX)

wow.logout()
wow.login()
expect("nach Reload weiter eigene Größe", wow.chatWindowSizes[1], addon.ChatFontSize.MAX)
addon.Set("chatFontOverride", false)
expect("aus: Fenster 1 zurück", wow.chatWindowSizes[1], 14)
expect("aus: Fenster 2 zurück", wow.chatWindowSizes[2], 12)
expect("Originale vergessen", addon.character.chatFontOriginals, nil)
