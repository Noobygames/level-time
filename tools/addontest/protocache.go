package addontest

import (
	"bufio"
	"os"
	"sync"

	lua "github.com/yuin/gopher-lua"
	"github.com/yuin/gopher-lua/parse"
)

// compiled: Ergebnis des einmaligen Kompilierens einer Datei (Bytecode oder Fehlertext wie bei loadfile)
type compiled struct {
	proto *lua.FunctionProto
	err   string
}

// protoCache: Pfad -> *compiled, gemeinsam für alle Szenarien. FunctionProto ist nach dem Kompilieren
// unveränderlich und darf von mehreren Lua-Zuständen genutzt werden (gopher-lua: NewFunctionFromProto).
var protoCache sync.Map

func compileFile(path string) *compiled {
	if cached, ok := protoCache.Load(path); ok {
		return cached.(*compiled)
	}
	result := &compiled{}
	file, err := os.Open(path)
	if err != nil {
		result.err = "cannot open " + path
	} else {
		chunk, parseErr := parse.Parse(bufio.NewReader(file), path)
		file.Close()
		if parseErr != nil {
			result.err = parseErr.Error()
		} else if proto, compileErr := lua.Compile(chunk, path); compileErr != nil {
			result.err = compileErr.Error()
		} else {
			result.proto = proto
		}
	}
	actual, _ := protoCache.LoadOrStore(path, result)
	return actual.(*compiled)
}

// useProtoCache ersetzt loadfile und dofile des Zustands durch Varianten mit dem gemeinsamen Bytecode-Cache
// (gleiches Verhalten wie Lua 5.1: loadfile liefert Funktion oder nil, Fehlertext; dofile wirft den Fehler).
func useProtoCache(L *lua.LState) {
	L.SetGlobal("loadfile", L.NewFunction(func(L *lua.LState) int {
		result := compileFile(L.CheckString(1))
		if result.proto == nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(result.err))
			return 2
		}
		L.Push(L.NewFunctionFromProto(result.proto))
		return 1
	}))
	L.SetGlobal("dofile", L.NewFunction(func(L *lua.LState) int {
		result := compileFile(L.CheckString(1))
		if result.proto == nil {
			L.RaiseError("%s", result.err)
		}
		top := L.GetTop()
		L.Push(L.NewFunctionFromProto(result.proto))
		L.Call(0, lua.MultRet)
		return L.GetTop() - top
	}))
}

// doFile führt eine Datei aus dem Cache im Zustand aus (Ersatz für L.DoFile)
func doFile(L *lua.LState, path string) error {
	result := compileFile(path)
	if result.proto == nil {
		return &lua.ApiError{Type: lua.ApiErrorSyntax, Object: lua.LString(result.err)}
	}
	L.Push(L.NewFunctionFromProto(result.proto))
	return L.PCall(0, lua.MultRet, nil)
}
