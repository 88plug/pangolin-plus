#!/bin/sh
# Behavioral smoke for get-plus-*.sh (no network required for core paths).
# Invoked by: make plus-install-scripts-selftest
#
# Covers:
#   - sh -n syntax
#   - FreeBSD olm fails closed (clear message, no download)
#   - gerbil non-linux fails closed
#   - SHA256SUMS verify success + fail (mirrors install-script logic)

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
pass() { printf '%b[PASS]%b %s\n' "${GREEN}" "${NC}" "$1"; }
fail() { printf '%b[FAIL]%b %s\n' "${RED}" "${NC}" "$1"; exit 1; }

# --- 1) syntax ---
for s in scripts/get-plus-newt.sh scripts/get-plus-olm.sh scripts/get-plus-gerbil.sh; do
	test -f "$s" || fail "missing $s"
	sh -n "$s" || fail "sh -n $s"
	pass "sh -n $s"
done

# --- 2) FreeBSD olm fails closed (before network) ---
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM
printf '#!/bin/sh\ncase "$1" in -s) echo FreeBSD;; -m) echo amd64;; *) echo x;; esac\n' >"$tmpdir/uname"
chmod +x "$tmpdir/uname"
out=$(PATH="$tmpdir:$PATH" sh scripts/get-plus-olm.sh 2>&1) && fail "olm FreeBSD should exit non-zero" || true
printf '%s\n' "$out" | grep -q 'no FreeBSD release assets' \
	|| fail "olm FreeBSD message missing: $out"
printf '%s\n' "$out" | grep -qi 'curl\|Downloading' \
	&& fail "olm FreeBSD must not download" || true
pass "olm FreeBSD fails closed"

# --- 3) gerbil non-linux fails closed ---
printf '#!/bin/sh\ncase "$1" in -s) echo Darwin;; -m) echo arm64;; *) echo x;; esac\n' >"$tmpdir/uname"
out=$(PATH="$tmpdir:$PATH" sh scripts/get-plus-gerbil.sh 2>&1) && fail "gerbil Darwin should exit non-zero" || true
printf '%s\n' "$out" | grep -q 'linux-only' \
	|| fail "gerbil non-linux message missing: $out"
pass "gerbil non-linux fails closed"

# --- 4) SHA256 verify success/fail (same recipe as get-plus-*.sh) ---
ckdir=$(mktemp -d)
printf 'plus-fake-asset\n' >"$ckdir/newt_linux_amd64"
(
	cd "$ckdir"
	sha256sum newt_linux_amd64 >SHA256SUMS
)
# success
(
	cd "$ckdir"
	grep -E '[[:space:]]newt_linux_amd64$' SHA256SUMS | sha256sum -c -
) >/dev/null || fail "checksum success path failed"
pass "checksum verify success"

# fail: corrupt asset
printf 'tampered\n' >"$ckdir/newt_linux_amd64"
if (
	cd "$ckdir"
	grep -E '[[:space:]]newt_linux_amd64$' SHA256SUMS | sha256sum -c -
) >/dev/null 2>&1; then
	fail "checksum fail path should not pass"
fi
pass "checksum verify detects mismatch"

# missing entry
printf 'other\n' >"$ckdir/other_bin"
if grep -E '[[:space:]]missing_asset$' "$ckdir/SHA256SUMS" >/dev/null 2>&1; then
	fail "unexpected entry"
fi
pass "checksum missing-entry guard (no match)"

# --- 5) install scripts refuse SKIP_CHECKSUM default (grep for hard fail message) ---
grep -q 'refuse to install without checksums' scripts/get-plus-newt.sh \
	|| fail "newt missing checksum refuse message"
grep -q 'refuse to install without checksums' scripts/get-plus-olm.sh \
	|| fail "olm missing checksum refuse message"
grep -q 'refuse to install without checksums' scripts/get-plus-gerbil.sh \
	|| fail "gerbil missing checksum refuse message"
pass "checksum refuse messaging present"

# --- 6) install dir alignment ---
grep -q '/usr/local/bin' scripts/get-plus-newt.sh || fail "newt install dir"
grep -q '/usr/local/bin' scripts/get-plus-olm.sh || fail "olm install dir"
grep -q '/usr/local/bin' scripts/get-plus-gerbil.sh || fail "gerbil install dir"
pass "install dir alignment"

echo ""
echo "plus-install-scripts-selftest: PASS"
