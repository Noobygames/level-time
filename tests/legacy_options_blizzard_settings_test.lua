-- Roadmap 403: Client ohne Settings-API (nur InterfaceOptions_AddCategory): Rückfall mit frame.name
expect("Settings fehlt", Settings, nil)
expect("eine Seite über InterfaceOptions", #wow.interfaceOptions, 1)
expect("Name am Frame", wow.interfaceOptions[1].name, addon.DISPLAY_NAME)
wow.login()
expect("keine Fehler", #wow.errors, 0)
