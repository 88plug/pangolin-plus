package main

import "strings"

// sanitizeRemoteConfigURL strips known Pangolin path suffixes operators often
// paste as REMOTE_CONFIG (get-config / receive-bandwidth / trailing /gerbil).
// fosrl/gerbil#106 / #82 — without this, bandwidth reports hit a wrong path and 400.
func sanitizeRemoteConfigURL(url string) string {
	url = strings.TrimRight(url, "/")
	url = strings.TrimSuffix(url, "/gerbil/get-config")
	url = strings.TrimSuffix(url, "/gerbil/receive-bandwidth")
	url = strings.TrimSuffix(url, "/gerbil")
	return strings.TrimRight(url, "/")
}
