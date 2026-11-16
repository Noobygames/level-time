-- Bibliotheksbücher (LT-255): gelesene Bücher accountweit merken, nur einmal melden, Einstellung beachten.
wow.login()
local state = wow.state

state.itemTextName = "Buch der Weisheit"
wow.fire("ITEM_TEXT_BEGIN")
expect("Anzahl Bücher", addon.LibraryBooks.Count(), 1)
expectTrue("Leser gemerkt", addon.LibraryBooks.All()["Buch der Weisheit"].by ~= nil)

wow.fire("ITEM_TEXT_BEGIN")
expect("Anzahl Bücher", addon.LibraryBooks.Count(), 1)

state.itemTextName = "Zweites Buch"
addon.Set("libraryBooks", false)
wow.fire("ITEM_TEXT_BEGIN")
expect("Anzahl Bücher", addon.LibraryBooks.Count(), 1)

addon.Set("libraryBooks", true)
wow.fire("ITEM_TEXT_BEGIN")
expect("Anzahl Bücher", addon.LibraryBooks.Count(), 2)
