# Clickdummy: Reiter, Unterreiter und Spalten des Verlaufsfensters aus dem Code (deutsche Texte) nach project/history-data.json.
# Aufruf aus dem Repo-Hauptordner: python docs/clickdummy/gen/history.py . docs/clickdummy/project/history-data.json
import re, json, sys, os
root = sys.argv[1]
loc = {}
for m in re.finditer(r'^\s+([A-Z][A-Z0-9_]+) = "((?:[^"\\]|\\.)*)",?\s*$', open(os.path.join(root, 'Locales/deDE.lua'), encoding='utf-8').read(), re.M):
    loc[m.group(1)] = m.group(2).replace('\\"', '"')
T = lambda k: loc.get(k, k)
HELPER = {'durationColumn': 'HISTORY_TIME', 'xpRateColumn': 'HISTORY_XP_RATE', 'goldColumn': 'HISTORY_GOLD', 'levelColumn': 'HISTORY_LEVEL',
          'zoneColumn': 'HISTORY_ZONE', 'whenColumn': 'HISTORY_WHEN', 'sessionStartColumn': 'HISTORY_START', 'levelRangeColumn': 'HISTORY_LEVEL',
          'nameColumn': 'HISTORY_NAME'}
FILES = ['UI/HistoryTables.lua', 'UI/QuestViews.lua', 'Speedrun/SpeedrunViews.lua']
columns = {}
src = {f: open(os.path.join(root, f), encoding='utf-8').read() for f in FILES}
for f, text in src.items():
    for m in re.finditer(r'^local (\w+_COLUMNS) = \{\n(.*?)^\}', text, re.M | re.S):
        heads = []
        for line in m.group(2).split('\n'):
            s = line.strip()
            if s.startswith('--') or not s:
                continue
            h = re.match(r'(\w+)Column\(\s*(?:"(\w+)")?', s)
            if h and (h.group(1) + 'Column') in HELPER and not h.group(2):
                heads.append(T(HELPER[h.group(1) + 'Column'])); continue
            if h and h.group(2):
                heads.append(T(h.group(2))); continue
            h = re.search(r'header = "(\w+)"', s)
            if h:
                heads.append(T(h.group(1)))
        columns[m.group(1)] = heads
    for m in re.finditer(r'^local (\w+_COLUMNS) = (HistoryTables\.\w+|ns\.HistoryTables\.\w+)', text, re.M):
        columns[m.group(1)] = m.group(2)
for k, v in list(columns.items()):
    if isinstance(v, str):
        columns[k] = columns.get(v.split('.')[-1], [])
columns['HistoryTables.PERSONAL_RECORD_COLUMNS'] = columns.get('PERSONAL_RECORD_COLUMNS', [])
views = []
GROUPS = {'LEVELS': 'HISTORY_GROUP_LEVELS', 'SESSIONS': 'HISTORY_GROUP_SESSIONS', 'JOURNAL': 'HISTORY_GROUP_JOURNAL', 'ANALYSIS': 'HISTORY_GROUP_ANALYSIS'}
# Registrierungsreihenfolge = Reihenfolge der Unterreiter
found = [(m.start(), GROUPS[m.group(2)], m.group(1), m.group(3)) for m in re.finditer(r'^addTable\("(\w+)", (\w+), (\w+)', src['UI/HistoryTables.lua'], re.M)]
found += [(m.start(), 'HISTORY_GROUP_JOURNAL', m.group(1), m.group(2)) for m in re.finditer(r'^addJournalTable\("(\w+)", (\w+)', src['UI/HistoryTables.lua'], re.M)]
views += [v[1:] for v in sorted(found)]
for f, group in [('UI/QuestViews.lua', 'HISTORY_GROUP_ANALYSIS'), ('Speedrun/SpeedrunViews.lua', 'HISTORY_GROUP_SPEEDRUN')]:
    for m in re.finditer(r'tab = "(\w+)",\s*\n\s*group = GROUP,(?:\s*\n[^\n]*?)*?\s*columns = ([\w.]+)', src[f]):
        views.append((group, m.group(1), m.group(2)))
views.append(('HISTORY_TAB_COMPARE', 'HISTORY_TAB_COMPARE', 'COMPARE_COLUMNS'))
charts = re.findall(r'createChartView\("(\w+)"', open(os.path.join(root, 'UI/HistoryCharts.lua'), encoding='utf-8').read())
ORDER = ['HISTORY_GROUP_LEVELS', 'HISTORY_GROUP_SESSIONS', 'HISTORY_GROUP_JOURNAL', 'HISTORY_GROUP_ANALYSIS', 'HISTORY_TAB_CHARTS', 'HISTORY_GROUP_SPEEDRUN', 'HISTORY_TAB_COMPARE']
out = []
for g in ORDER:
    if g == 'HISTORY_TAB_CHARTS':
        out.append({'label': T(g), 'chart': 1, 'subs': [{'label': T(c), 'cols': []} for c in charts if c in loc]})
        continue
    out.append({'label': T(g), 'subs': [{'label': T(t), 'cols': columns.get(c.split('.')[-1], [])} for gg, t, c in views if gg == g]})
json.dump(out, open(sys.argv[2], 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
for g in out:
    print(g['label'], [(s['label'], len(s['cols'])) for s in g['subs']])
