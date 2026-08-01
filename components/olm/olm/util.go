package olm

import (
	"context"
	"time"

	"github.com/fosrl/olm/peers"
)

// waitForHolePunchSettle waits up to d, returning false if ctx is cancelled
// or tunnelRunning becomes false (interruptible alternative to time.Sleep).
func waitForHolePunchSettle(ctx context.Context, tunnelRunning *bool, d time.Duration) bool {
	if ctx == nil {
		timer := time.NewTimer(d)
		defer timer.Stop()
		<-timer.C
		return tunnelRunning != nil && *tunnelRunning
	}
	timer := time.NewTimer(d)
	defer timer.Stop()
	select {
	case <-timer.C:
		return tunnelRunning != nil && *tunnelRunning
	case <-ctx.Done():
		return false
	}
}

// slicesEqual compares two string slices for equality (order-independent)
func slicesEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	// Create a map to count occurrences in slice a
	counts := make(map[string]int)
	for _, v := range a {
		counts[v]++
	}
	// Check if slice b has the same elements
	for _, v := range b {
		counts[v]--
		if counts[v] < 0 {
			return false
		}
	}
	return true
}

// aliasesEqual compares two Alias slices for equality (order-independent)
func aliasesEqual(a, b []peers.Alias) bool {
	if len(a) != len(b) {
		return false
	}
	// Create a map to count occurrences in slice a (using alias+address as key)
	counts := make(map[string]int)
	for _, v := range a {
		key := v.Alias + "|" + v.AliasAddress
		counts[key]++
	}
	// Check if slice b has the same elements
	for _, v := range b {
		key := v.Alias + "|" + v.AliasAddress
		counts[key]--
		if counts[key] < 0 {
			return false
		}
	}
	return true
}
