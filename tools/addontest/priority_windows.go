package addontest

import "syscall"

// lowerPriority: Testprozess unter normale Priorität, damit Spiel und Stream Vorrang haben.
func lowerPriority() {
	const belowNormal = 0x00004000
	proc := syscall.NewLazyDLL("kernel32.dll").NewProc("SetPriorityClass")
	handle, _ := syscall.GetCurrentProcess()
	proc.Call(uintptr(handle), belowNormal)
}
