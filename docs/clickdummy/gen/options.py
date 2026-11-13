# Clickdummy: alle Reiter, Unterseiten und Steuerelemente der Einstellungen aus UI/Options/*.lua (deutsche Texte, Tooltips,
# Standardwerte) nach project/options-data.json. Eintrag: [Art, Text, Tooltip, nur erweitert, Standard an].
# Aufruf aus dem Repo-Hauptordner: python docs/clickdummy/gen/options.py . docs/clickdummy/project/options-data.json
import re, json, glob, sys, os
root = sys.argv[1]
loc = {}
for m in re.finditer(r'^\s+([A-Z][A-Z0-9_]+) = "((?:[^"\\]|\\.)*)",?\s*$', open(os.path.join(root, 'Locales/deDE.lua'), encoding='utf-8').read(), re.M):
    loc[m.group(1)] = m.group(2).replace('\\"', '"').replace('\\n', ' ')
defaults_true = set()
for f in glob.glob(os.path.join(root, '**/*.lua'), recursive=True):
    if 'tests' in f or 'Locales' in f:
        continue
    for m in re.finditer(r'^\s+(\w+) = true,', open(f, encoding='utf-8', errors='ignore').read(), re.M):
        defaults_true.add(m.group(1))


def T(k):
    return loc.get(k, k)


def tip(k):
    return loc.get(k + '_TIP', '')


SPECIAL = {
    'addTimerDisplayControls': 'Anzeige-Steuerung (anzeigen, fixieren, Größe)',
    'addVisibilityDropdown': 'Sichtbarkeit (Auswahl)',
    'addPreviewCycle': 'Vorschau durchschalten',
    'addOutlineChooser': 'Textumriss (Auswahl)',
    'addWorldRecordScopeChooser': 'Weltrekord-Bereich (Auswahl)',
    'addVisibilitySection': 'Sichtbarkeit des Hauptfensters',
    'addThemeSection': 'Farbschema mit Farbwählern',
    'addStreamLayoutChooser': 'Stream-Layout (Auswahl)',
    'addSsfCategoryChooser': 'SSF-Kategorie (Auswahl)',
    'addSplitComparisonChooser': 'Split-Vergleich mit (Auswahl)',
    'addRowOrderSection': 'Reihenfolge: Zeile wählen, Nach oben / Nach unten / Zurücksetzen',
    'addProfileUsage': 'Welche Charaktere welches Profil nutzen',
    'addProfileSaver': 'Profil speichern unter (Name)',
    'addProfileList': 'Profil-Liste (laden, kopieren, löschen)',
    'addLanguageChooser': 'Sprache (Auswahl)',
    'addDisplaySection': 'Layout-Wahl: Tabelle, Leiste, Kompakt, Text, Uhr, XP-Balken, Kacheln',
    'addBlizzardHideGroups': 'Blizzard-Rahmen ausblenden (Gruppen von Schaltern)',
    'addBlizzardMessages': 'Blizzard-Meldungen ausblenden (Schalter)',
}
STATS = {}
for m in re.finditer(r'setting = "(\w+)", group = "(\w+)", label = "(\w+)"', open(os.path.join(root, 'UI/StatLines.lua'), encoding='utf-8').read()):
    STATS.setdefault(m.group(2), []).append(['check', T(m.group(3)), tip(m.group(3)), 0, 1 if m.group(1) in defaults_true else 0])
GROUP_PAGE = [('STAT_GROUP_XP', 'OPTIONS_PAGE_STAT_XP'), ('STAT_GROUP_PROGRESS', 'OPTIONS_PAGE_STAT_PROGRESS'),
              ('STAT_GROUP_COMBAT', 'OPTIONS_PAGE_STAT_COMBAT'), ('STAT_GROUP_LOOT', 'OPTIONS_PAGE_STAT_LOOT'),
              ('STAT_GROUP_INSTANCE', 'OPTIONS_PAGE_STAT_INSTANCE'), ('STAT_GROUP_TIME_MONEY', 'OPTIONS_PAGE_STAT_TIME_MONEY')]
order = ['General', 'Statistics', 'Notifications', 'Alerts', 'Comfort', 'ComfortQuests', 'ComfortWorld', 'Speedrun', 'Profiles']
pages = []
state = {'page': None, 'sub': None}


def add(item):
    page = state['page']
    if page is None:
        return
    if state['sub'] is None:
        state['sub'] = {'label': '', 'items': []}
        page['subs'].append(state['sub'])
    state['sub']['items'].append(item)


for name in order:
    pending = None
    inrow = False
    for line in open(os.path.join(root, 'UI/Options', name + '.lua'), encoding='utf-8').read().split('\n'):
        s = line.strip()
        if s.startswith('--'):
            continue
        m = re.search(r'addPage\("(\w+)"', s)
        if m:
            state['page'] = {'label': T(m.group(1)), 'subs': []}
            pages.append(state['page'])
            state['sub'] = None
            continue
        if state['page'] is None:
            continue  # Hilfsfunktionen vor addPage; ihr Aufruf wird ein Spezial-Eintrag
        if 'addSubPage(STAT_GROUP_PAGES' in s:
            for g, p in GROUP_PAGE:
                state['sub'] = {'label': T(p), 'items': list(STATS.get(g, []))}
                state['page']['subs'].append(state['sub'])
            continue
        m = re.search(r'addSubPage\("(\w+)"', s)
        if m:
            state['sub'] = {'label': T(m.group(1)), 'items': []}
            state['page']['subs'].append(state['sub'])
            continue
        adv = 1 if ('advanced(' in s or 'advanced = true' in s) else 0
        m = re.search(r'addSection\("(\w+)"', s)
        if m:
            add(['sec', T(m.group(1)), '', adv, 0]); continue
        m = re.search(r'addHint\("(\w+)"', s)
        if m:
            add(['hint', T(m.group(1)), '', adv, 0]); continue
        m = re.search(r'toggle\("(\w+)",\s*"(\w+)"', s)
        if m:
            add(['check', T(m.group(1)), tip(m.group(1)), adv, 1 if m.group(2) in defaults_true else 0]); continue
        if 'AddButtonRow(' in s:
            inrow = not s.endswith(')'); pending = None
            if not inrow:
                add(['special', 'Knopfreihe', '', adv, 0])
            continue
        if inrow:
            m = re.search(r'label = "(\w+)"', s)
            if m:
                add(['button', T(m.group(1)), tip(m.group(1)), adv, 0])
            if s.startswith('}') and ')' in s:
                inrow = False
            continue
        m = re.search(r'\b(add\w+|builder\.Add\w+)\(\s*(?:"(\w+)")?', s)
        if m:
            fn = m.group(1).replace('builder.', '')
            if fn in SPECIAL:
                add(['special', SPECIAL[fn], '', adv, 0]); continue
            kind = ('slider' if 'Slider' in fn else 'select' if ('Chooser' in fn or 'Dropdown' in fn)
                    else 'button' if 'Button' in fn else 'text' if 'TextInput' in fn else None)
            if kind is None:
                continue
            if m.group(2):
                add([kind, T(m.group(2)), tip(m.group(2)), adv, 0])
            else:
                pending = [kind, None, '', adv, 0]
            continue
        if pending:
            m = re.search(r'label = "(\w+)"', s)
            if m:
                pending[1] = T(m.group(1)); pending[2] = tip(m.group(1)); pending[3] = pending[3] or adv
                add(pending); pending = None
for p in pages:
    p['subs'] = [u for u in p['subs'] if u['items']]
json.dump(pages, open(sys.argv[2], 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
for p in pages:
    print(p['label'], [(u['label'], len(u['items'])) for u in p['subs']])
