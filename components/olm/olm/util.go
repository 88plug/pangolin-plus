package olm

import (
	"context"
	"time"

	"github.com/fosrl/olm/peers"
)

// waitForHolePunchSettle waits up to d, returning false if ctx is cancelled
// or tunnelRunning becomes false mid-wait (polls so stop does not block full d).
func waitForHolePunchSettle(ctx context.Context, tunnelRunning *bool, d time.Duration) bool {
	if tunnelRunning == nil || !*tunnelRunning {
		return false
	}
	const poll = 25 * time.Millisecond
	deadline := time.Now().Add(d)
	ticker := time.NewTicker(poll)
	defer ticker.Stop()

	for {
		if tunnelRunning == nil || !*tunnelRunning {
			return false
		}
		if !deadline.After(time.Now()) {
			return *tunnelRunning
		}
		if ctx != nil {
			select {
			case <-ctx.Done():
				return false
			case <-ticker.C:
			}
		} else {
			<-ticker.C
		}
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
