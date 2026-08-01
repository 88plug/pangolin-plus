#!/bin/sh
# Install plus newt (site connector) from 88plug/pangolin-plus GitHub Releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/scripts/get-plus-newt.sh | sh
#   VERSION=v1.21.1-plus sh get-plus-newt.sh
#   VERSION=1.21.1-plus ./scripts/get-plus-newt.sh --path /usr/local/bin/newt
#
# Stock fosrl (no plus deltas):
#   curl -fsSL https://raw.githubusercontent.com/fosrl/newt/main/get-newt.sh | sh
#   # or: REPO=fosrl/newt ./scripts/get-plus-newt.sh  (asset names match)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Product default — override REPO=fosrl/newt for stock upstream assets
REPO="${REPO:-88plug/pangolin-plus}"
GITHUB_API_URL="https://api.github.com/repos/${REPO}/releases/latest"

print_status()  { printf '%b[INFO]%b %s\n'  "${GREEN}"  "${NC}" "$1"; }
print_warning() { printf '%b[WARN]%b %s\n'  "${YELLOW}" "${NC}" "$1"; }
print_error()   { printf '%b[ERROR]%b %s\n' "${RED}"    "${NC}" "$1"; }

# Returns full tag_name (keep leading v — required for download URL)
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
        *) printf '%s' "/usr/local/bin" ;;
    esac
}

parse_path_arg() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --path)
                if [ -n "$2" ]; then printf '%s' "$2"; return; fi
                ;;
            --path=*)
                printf '%s' "${1#--path=}"
                return
                ;;
        esac
        shift
    done
}

detect_existing_binary() {
    existing=$(command -v newt 2>/dev/null || true)
    if [ -n "$existing" ]; then printf '%s' "$existing"; return; fi
    if command -v sudo >/dev/null 2>&1; then
        existing=$(sudo which newt 2>/dev/null || true)
        if [ -n "$existing" ]; then printf '%s' "$existing"; return; fi
    fi
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

install_newt() {
    platform="$1"
    install_dir="$2"
    sudo_cmd="$3"
    custom_path="$4"
    binary_name="newt_${platform}"
    final_name="newt"
    case "$platform" in
        *windows*)
            binary_name="${binary_name}.exe"
            final_name="newt.exe"
            ;;
    esac
    download_url="${BASE_URL}/${binary_name}"
    temp_file="/tmp/${final_name}.$$"
    if [ -n "$custom_path" ]; then
        final_path="$custom_path"
        install_dir=$(dirname "$final_path")
    else
        final_path="${install_dir}/${final_name}"
    fi
    print_status "Downloading plus newt from ${download_url}"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$download_url" -o "$temp_file"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$download_url" -O "$temp_file"
    else
        print_error "Neither curl nor wget is available."
        exit 1
    fi
    chmod +x "$temp_file"
    if [ -n "$sudo_cmd" ]; then
        $sudo_cmd mkdir -p "$install_dir"
        print_status "Using sudo to install to ${install_dir}"
        $sudo_cmd mv "$temp_file" "$final_path"
    else
        mkdir -p "$install_dir"
        mv "$temp_file" "$final_path"
    fi
    print_status "newt installed to ${final_path}"
    if ! printf '%s' "$PATH" | grep -q "$install_dir"; then
        print_warning "Install directory ${install_dir} is not in your PATH."
        print_warning "  export PATH=\"${install_dir}:\$PATH\""
    fi
}

verify_installation() {
    install_dir="$1"
    exe_suffix=""
    case "$PLATFORM" in *windows*) exe_suffix=".exe" ;; esac
    newt_path="${install_dir}/newt${exe_suffix}"
    if [ -x "$newt_path" ]; then
        print_status "Installation successful!"
        print_status "newt version: $("$newt_path" --version 2>/dev/null || printf 'unknown')"
        return 0
    fi
    print_error "Installation failed. Binary not found or not executable."
    return 1
}

main() {
    CUSTOM_PATH=$(parse_path_arg "$@")
    print_status "Installing plus newt from ${REPO}..."
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
    if [ -n "$CUSTOM_PATH" ]; then
        INSTALL_DIR=$(dirname "$CUSTOM_PATH")
    else
        EXISTING_BINARY=$(detect_existing_binary)
        if [ -n "$EXISTING_BINARY" ]; then
            print_status "Found existing newt at ${EXISTING_BINARY}"
            CUSTOM_PATH="$EXISTING_BINARY"
            INSTALL_DIR=$(dirname "$EXISTING_BINARY")
        else
            INSTALL_DIR=$(get_install_dir)
        fi
    fi
    print_status "Install directory: ${INSTALL_DIR}"
    SUDO_CMD=$(get_sudo_cmd "$INSTALL_DIR")
    install_newt "$PLATFORM" "$INSTALL_DIR" "$SUDO_CMD" "$CUSTOM_PATH"
    if [ -n "$CUSTOM_PATH" ]; then
        if [ -x "$CUSTOM_PATH" ]; then
            print_status "Installation successful!"
            print_status "newt version: $("$CUSTOM_PATH" --version 2>/dev/null || printf 'unknown')"
        else
            print_error "Installation failed at ${CUSTOM_PATH}"
            exit 1
        fi
    elif ! verify_installation "$INSTALL_DIR"; then
        exit 1
    fi
    print_status "plus newt is ready (stock fosrl binary would miss monorepo deltas)."
    print_status "Run 'newt --help' to get started."
}

main "$@"
