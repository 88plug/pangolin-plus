#!/bin/sh
# Install plus olm (end-user client) from 88plug/pangolin-plus GitHub Releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/scripts/get-plus-olm.sh | sh
#   VERSION=v1.21.1-plus sh get-plus-olm.sh
#
# Stock fosrl (no plus deltas):
#   curl -fsSL https://raw.githubusercontent.com/fosrl/olm/main/get-olm.sh | bash
#   # or: REPO=fosrl/olm ./scripts/get-plus-olm.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO="${REPO:-88plug/pangolin-plus}"
GITHUB_API_URL="https://api.github.com/repos/${REPO}/releases/latest"

print_status()  { printf '%b[INFO]%b %s\n'  "${GREEN}"  "${NC}" "$1"; }
print_warning() { printf '%b[WARN]%b %s\n'  "${YELLOW}" "${NC}" "$1"; }
print_error()   { printf '%b[ERROR]%b %s\n' "${RED}"    "${NC}" "$1"; }

get_latest_tag() {
    latest_info=""
    if command -v curl >/dev/null 2>&1; then
        latest_info=$(curl -fsSL "$GITHUB_API_URL" 2>/dev/null)
    elif command -v wget >/dev/null 2>&1; then
        latest_info=$(wget -qO- "$GITHUB_API_URL" 2>/dev/null)
    else
        print_error "Neither curl nor wget is available."
        exit 1
    fi
    if [ -z "$latest_info" ]; then
        print_error "Failed to fetch latest release from ${REPO}"
        exit 1
    fi
    tag=$(printf '%s' "$latest_info" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    if [ -z "$tag" ]; then
        print_error "Could not parse tag_name from GitHub API response"
        exit 1
    fi
    printf '%s' "$tag"
}

detect_platform() {
    os=""
    arch=""
    case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="darwin" ;;
        MINGW*|MSYS*|CYGWIN*) os="windows" ;;
        FreeBSD*) os="freebsd" ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        armv7l) arch="arm32" ;;
        armv6l) arch="arm32v6" ;;
        riscv64)
            if [ "$os" != "linux" ]; then
                print_error "RISC-V only supported on Linux"
                exit 1
            fi
            arch="riscv64"
            ;;
        *)
            print_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    printf '%s_%s' "$os" "$arch"
}

get_install_dir() {
    case "$PLATFORM" in
        *windows*) printf '%s' "$HOME/bin" ;;
        *)
            if [ -d "/usr/local/bin" ]; then printf '%s' "/usr/local/bin"
            elif [ -d "/usr/bin" ]; then printf '%s' "/usr/bin"
            else printf '%s' "$HOME/.local/bin"
            fi
            ;;
    esac
}

needs_sudo() {
    install_dir="$1"
    case "$install_dir" in
        /usr/local/bin|/usr/bin)
            if [ ! -w "$install_dir" ] 2>/dev/null; then return 0; fi
            ;;
    esac
    return 1
}

install_olm() {
    platform="$1"
    install_dir="$2"
    binary_name="olm_${platform}"
    exe_suffix=""
    case "$platform" in
        *windows*)
            binary_name="${binary_name}.exe"
            exe_suffix=".exe"
            ;;
    esac
    download_url="${BASE_URL}/${binary_name}"
    temp_file="/tmp/olm${exe_suffix}.$$"
    final_path="${install_dir}/olm${exe_suffix}"
    print_status "Downloading plus olm from ${download_url}"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$download_url" -o "$temp_file"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$download_url" -O "$temp_file"
    else
        print_error "Neither curl nor wget is available."
        exit 1
    fi
    use_sudo=""
    if needs_sudo "$install_dir"; then
        print_status "Administrator privileges required for system-wide installation"
        if command -v sudo >/dev/null 2>&1; then
            use_sudo="sudo"
        else
            print_error "sudo is required for system-wide installation but not available"
            exit 1
        fi
    fi
    if [ -n "$use_sudo" ]; then
        $use_sudo mkdir -p "$install_dir"
        $use_sudo mv "$temp_file" "$final_path"
        $use_sudo chmod +x "$final_path"
    else
        mkdir -p "$install_dir"
        mv "$temp_file" "$final_path"
        chmod +x "$final_path"
    fi
    print_status "olm installed to ${final_path}"
    case "$install_dir" in
        /usr/local/bin|/usr/bin) ;;
        *)
            if ! printf '%s' "$PATH" | grep -q "$install_dir"; then
                print_warning "Install directory ${install_dir} is not in your PATH."
                print_warning "  export PATH=\"${install_dir}:\$PATH\""
            fi
            ;;
    esac
}

verify_installation() {
    install_dir="$1"
    exe_suffix=""
    case "$PLATFORM" in *windows*) exe_suffix=".exe" ;; esac
    olm_path="${install_dir}/olm${exe_suffix}"
    if [ -f "$olm_path" ] && [ -x "$olm_path" ]; then
        print_status "Installation successful!"
        print_status "olm version: $("$olm_path" --version 2>/dev/null || printf 'unknown')"
        return 0
    fi
    print_error "Installation failed. Binary not found or not executable."
    return 1
}

main() {
    print_status "Installing plus olm from ${REPO}..."
    if [ -n "${VERSION:-}" ]; then
        TAG="$VERSION"
        print_status "Pinned version: ${TAG}"
    else
        print_status "Fetching latest release..."
        TAG=$(get_latest_tag)
        print_status "Latest release: ${TAG}"
    fi
    BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
    PLATFORM=$(detect_platform)
    print_status "Detected platform: ${PLATFORM}"
    INSTALL_DIR=$(get_install_dir)
    print_status "Install directory: ${INSTALL_DIR}"
    install_olm "$PLATFORM" "$INSTALL_DIR"
    if ! verify_installation "$INSTALL_DIR"; then
        exit 1
    fi
    print_status "plus olm is ready (stock fosrl / pangolin.net apps miss monorepo deltas)."
    print_status "Run 'olm --help' to get started."
}

main "$@"
