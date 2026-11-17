package addontest

import (
	"os"
	"runtime"
	"runtime/debug"
	"strconv"
	"strings"
	"sync"
)

// scenarioLimit: gleichzeitige Szenarien. Standard: 4, damit nebenbei WoW und OBS laufen.
// LT_TEST_PARALLEL=<n> überschreibt (make test-fast setzt alle Kerne).
func scenarioLimit() int {
	if n, err := strconv.Atoi(os.Getenv("LT_TEST_PARALLEL")); err == nil && n > 0 {
		return min(n, runtime.NumCPU())
	}
	return min(4, runtime.NumCPU())
}

// limitMemory: weiches Speicherlimit für den Go-Heap (MiB, Standard 7168 = Ziel max. ~8 GB Arbeitsspeicher; LT_TEST_MEMLIMIT überschreibt).
// Ohne Limit wächst der Heap bei 4 Szenarien auf mehrere GB, obwohl das meiste Müll ist (gemessen: kein Verlust über Szenarien hinweg).
func limitMemory() {
	mib := 7168
	if n, err := strconv.Atoi(os.Getenv("LT_TEST_MEMLIMIT")); err == nil && n > 0 {
		mib = n
	}
	debug.SetMemoryLimit(int64(mib) << 20)
}

// scenarioWeight: Forever-Szenarien laden die großen Datenbanken in ihren Lua-Zustand (gemessen ~1 GB live je Zustand),
// alle anderen brauchen deutlich weniger. Sie belegen darum zwei Plätze.
func scenarioWeight(name string) int {
	if strings.HasPrefix(name, "forever_") {
		return 2
	}
	return 1
}

// acquire belegt weight Plätze und gibt die Freigabefunktion zurück. Das Belegen läuft unter einem Mutex, damit zwei
// Szenarien mit je halb belegten Plätzen sich nicht gegenseitig blockieren.
func acquire(slots chan struct{}, weight int) func() {
	weight = min(weight, cap(slots))
	acquireLock.Lock()
	for i := 0; i < weight; i++ {
		slots <- struct{}{}
	}
	acquireLock.Unlock()
	return func() {
		for i := 0; i < weight; i++ {
			<-slots
		}
	}
}

var acquireLock sync.Mutex
