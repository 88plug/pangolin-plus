package main

import "testing"

func TestSanitizeRemoteConfigURL(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"https://ex.com", "https://ex.com"},
		{"https://ex.com/", "https://ex.com"},
		{"https://ex.com/gerbil/get-config", "https://ex.com"},
		{"https://ex.com/gerbil/receive-bandwidth", "https://ex.com"},
		{"https://ex.com/gerbil", "https://ex.com"},
		{"https://ex.com/gerbil/get-config/", "https://ex.com"},
	}
	for _, c := range cases {
		if got := sanitizeRemoteConfigURL(c.in); got != c.want {
			t.Fatalf("sanitizeRemoteConfigURL(%q)=%q want %q", c.in, got, c.want)
		}
	}
}
