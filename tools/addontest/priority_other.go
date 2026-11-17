//go:build !windows

package addontest

import "syscall"

// lowerPriority: Testprozess nett stellen, damit Spiel und Stream Vorrang haben.
func lowerPriority() {
	_ = syscall.Setpriority(syscall.PRIO_PROCESS, 0, 10)
}
