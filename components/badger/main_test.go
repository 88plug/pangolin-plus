package badger

import (
	"net"
	"net/http"
	"testing"
)

func TestFirstValidIP(t *testing.T) {
	tests := []struct {
		name  string
		in    string
		want  string
	}{
		{"empty", "", ""},
		{"single", "203.0.113.1", "203.0.113.1"},
		{"xff list", "203.0.113.1, 10.0.0.1, 10.0.0.2", "203.0.113.1"},
		{"skip invalid", "not-an-ip, 203.0.113.2", "203.0.113.2"},
		{"with port", "203.0.113.3:443", "203.0.113.3"},
		{"ipv6", "2001:db8::1", "2001:db8::1"},
		{"all invalid", "nope, still-nope", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := firstValidIP(tt.in); got != tt.want {
				t.Fatalf("firstValidIP(%q)=%q want %q", tt.in, got, tt.want)
			}
		})
	}
}

func TestGetRealIP(t *testing.T) {
	_, trustNet, err := net.ParseCIDR("10.0.0.0/8")
	if err != nil {
		t.Fatal(err)
	}

	tests := []struct {
		name       string
		remoteAddr string
		headers    map[string]string
		customHdr  string
		trust      []*net.IPNet
		want       string
	}{
		{
			name:       "untrusted uses remote",
			remoteAddr: "203.0.113.100:12345",
			headers:    map[string]string{"X-Forwarded-For": "192.168.1.1"},
			want:       "203.0.113.100",
		},
		{
			name:       "trusted CF first",
			remoteAddr: "10.0.0.1:12345",
			headers: map[string]string{
				"CF-Connecting-IP": "203.0.113.3",
				"X-Real-Ip":        "203.0.113.2",
				"X-Forwarded-For":  "203.0.113.1",
			},
			trust: []*net.IPNet{trustNet},
			want:  "203.0.113.3",
		},
		{
			name:       "trusted X-Real-IP when no CF",
			remoteAddr: "10.0.0.1:12345",
			headers: map[string]string{
				"X-Real-Ip":       "203.0.113.2",
				"X-Forwarded-For": "203.0.113.1, 10.0.0.1",
			},
			trust: []*net.IPNet{trustNet},
			want:  "203.0.113.2",
		},
		{
			name:       "trusted XFF fallback",
			remoteAddr: "10.0.0.1:12345",
			headers: map[string]string{
				"X-Forwarded-For": "203.0.113.1, 10.0.0.1",
			},
			trust: []*net.IPNet{trustNet},
			want:  "203.0.113.1",
		},
		{
			name:       "custom header wins when set",
			remoteAddr: "10.0.0.1:12345",
			headers: map[string]string{
				"True-Client-IP":   "198.51.100.9",
				"CF-Connecting-IP": "203.0.113.3",
			},
			customHdr: "True-Client-IP",
			trust:     []*net.IPNet{trustNet},
			want:      "198.51.100.9",
		},
		{
			name:       "no port on remote",
			remoteAddr: "203.0.113.50",
			headers:    map[string]string{},
			want:       "203.0.113.50",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := &Badger{
				trustIP:        tt.trust,
				customIPHeader: tt.customHdr,
			}
			req, err := http.NewRequest(http.MethodGet, "http://example/", nil)
			if err != nil {
				t.Fatal(err)
			}
			req.RemoteAddr = tt.remoteAddr
			for k, v := range tt.headers {
				req.Header.Set(k, v)
			}
			if got := p.getRealIP(req); got != tt.want {
				t.Fatalf("getRealIP()=%q want %q", got, tt.want)
			}
		})
	}
}
