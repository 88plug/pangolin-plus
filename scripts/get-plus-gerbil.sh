#!/bin/sh
# Optional: install plus gerbil host binary from 88plug/pangolin-plus GitHub Releases.
#
# Gerbil is **container-first** on the controller edge (compose / GHCR image).
# Prefer:
#   docker pull ghcr.io/88plug/pangolin-plus/gerbil:TAG
#   # or compose.plus.yaml GERBIL_IMAGE=…
#
# Host binary is linux-only (amd64/arm64) for rare bare-metal edge cases.
#
# Usage:
#   VERSION=v1.21.1-plus sh get-plus-gerbil.sh
#   curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/scripts/get-plus-gerbil.sh | sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO="${REPO:-88plug/pangolin-plus}"
GITHUB_API_URL="https://api.github.com/repos/${REPO}/releases/latest"
COMPONENT=gerbil

print_status()  { printf '%b[INFO]%b %s\n'  "${GREEN}"  "${NC}" "$1"; }
print_warning() { printf '%b[WARN]%b %s\n'  "${YELLOW}" "${NC}" "$1" >&2; }
print_error()   { printf '%b[ERROR]%b %s\n' "${RED}"    "${NC}" "$1" >&2; }

http_get() {
    url="$1"
    out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$out"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$out"
    else
        print_error "Neither curl nor wget is available."
        exit 1
    fi
}

http_head_ok() {
    url="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSIL "$url" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget --spider -q "$url" 2>/dev/null
    else
        return 1
    fi
}

get_latest_tag() {
    tmp=$(mktemp)
    http_get "$GITHUB_API_URL" "$tmp"
    tag=$(grep '"tag_name"' "$tmp" | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    rm -f "$tmp"
    if [ -z "$tag" ]; then
        print_error "Could not parse tag_name from ${REPO} latest release"
        exit 1
    fi
    printf '%s' "$tag"
}

resolve_tag() {
    if [ -z "${VERSION:-}" ]; then
        get_latest_tag
        return
    fi
    pin="$VERSION"
    for candidate in "$pin" "v${pin#v}" "${pin#v}"; do
        [ -n "$candidate" ] || continue
        sums_url="https://github.com/${REPO}/releases/download/${candidate}/SHA256SUMS"
        if http_head_ok "$sums_url"; then
            printf '%s' "$candidate"
            return
        fi
        asset_url="https://github.com/${REPO}/releases/download/${candidate}/${COMPONENT}_linux_amd64"
        if http_head_ok "$asset_url"; then
            printf '%s' "$candidate"
            return
        fi
    done
    print_error "No release found for VERSION=${pin} on ${REPO}"
    exit 1
}

detect_platform() {
    case "$(uname -s)" in
        Linux*) ;;
        *)
            print_error "plus gerbil host binary is linux-only (use the container image on other OS)."
            print_error "  docker pull ghcr.io/88plug/pangolin-plus/gerbil:TAG"
            exit 1
            ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *)
            print_error "Unsupported architecture for gerbil binary: $(uname -m) (amd64/arm64 only)"
            exit 1
            ;;
    esac
    printf 'linux_%s' "$arch"
}

get_install_dir() {
    printf '%s' "/usr/local/bin"
}

needs_sudo() {
    install_dir="$1"
    if [ -w "$install_dir" ] 2>/dev/null; then return 1; else return 0; fi
}

get_sudo_cmd() {
    install_dir="$1"
    if needs_sudo "$install_dir"; then
        if command -v sudo >/dev/null 2>&1; then
            printf 'sudo'
        else
            print_error "Cannot write to ${install_dir} and sudo is not available."
            exit 1
        fi
    else
        printf ''
    fi
}

verify_sha256() {
    binary_name="$1"
    workdir="$2"
    sums_url="${BASE_URL}/SHA256SUMS"
    sums_file="${workdir}/SHA256SUMS"
    print_status "Fetching checksums from ${sums_url}"
    if ! http_get "$sums_url" "$sums_file" 2>/dev/null; then
        print_error "SHA256SUMS missing for release ${TAG} — refuse to install without checksums."
        if [ "${SKIP_CHECKSUM:-}" = "1" ]; then
            print_warning "SKIP_CHECKSUM=1 set — installing without verification"
            return 0
        fi
        exit 1
    fi
    if ! grep -E "[[:space:]]${binary_name}\$" "$sums_file" >/dev/null 2>&1; then
        print_error "No SHA256SUMS entry for ${binary_name}"
        exit 1
    fi
    print_status "Verifying SHA256 of ${binary_name}"
    (
        cd "$workdir" || exit 1
        if command -v sha256sum >/dev/null 2>&1; then
            grep -E "[[:space:]]${binary_name}\$" SHA256SUMS | sha256sum -c -
        elif command -v shasum >/dev/null 2>&1; then
            expected=$(grep -E "[[:space:]]${binary_name}\$" SHA256SUMS | awk '{print $1}')
            actual=$(shasum -a 256 "$binary_name" | awk '{print $1}')
            if [ "$expected" != "$actual" ]; then
                print_error "Checksum mismatch for ${binary_name}"
                exit 1
            fi
            printf '%s: OK\n' "$binary_name"
        else
            print_error "Neither sha256sum nor shasum available"
            exit 1
        fi
    )
}

main() {
    print_warning "gerbil is container-first — prefer ghcr.io/88plug/pangolin-plus/gerbil"
    print_status "Installing optional plus gerbil host binary from ${REPO}..."
    PLATFORM=$(detect_platform) || exit 1
    print_status "Detected platform: ${PLATFORM}"
    TAG=$(resolve_tag) || exit 1
    print_status "Release tag: ${TAG}"
    BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
    binary_name="gerbil_${PLATFORM}"
    INSTALL_DIR=$(get_install_dir)
    SUDO_CMD=$(get_sudo_cmd "$INSTALL_DIR") || exit 1
    workdir=$(mktemp -d)
    trap 'rm -rf "$workdir"' EXIT INT TERM
    temp_file="${workdir}/${binary_name}"
    print_status "Downloading from ${BASE_URL}/${binary_name}"
    http_get "${BASE_URL}/${binary_name}" "$temp_file"
    verify_sha256 "$binary_name" "$workdir"
    chmod +x "$temp_file"
    final_path="${INSTALL_DIR}/gerbil"
    if [ -n "$SUDO_CMD" ]; then
        $SUDO_CMD mkdir -p "$INSTALL_DIR"
        $SUDO_CMD mv "$temp_file" "$final_path"
    else
        mkdir -p "$INSTALL_DIR"
        mv "$temp_file" "$final_path"
    fi
    trap - EXIT INT TERM
    rm -rf "$workdir"
    print_status "gerbil installed to ${final_path}"
    print_status "For controller edge, prefer the container image over this host binary."
}

main "$@"
