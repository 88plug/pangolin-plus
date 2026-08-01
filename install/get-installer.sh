#!/bin/bash
# Get pangolin-plus installer binary from 88plug GitHub Releases.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/88plug/pangolin-plus/main/install/get-installer.sh | sh
# Pin:
#   VERSION=v1.21.2-plus sh get-installer.sh
#
# Stock upstream installer (no plus images):
#   curl -fsSL https://raw.githubusercontent.com/fosrl/installer/main/get-installer.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO="${REPO:-88plug/pangolin-plus}"
GITHUB_API_URL="https://api.github.com/repos/${REPO}/releases/latest"

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

http_get() {
	local url="$1" out="$2"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$url" -o "$out"
	elif command -v wget >/dev/null 2>&1; then
		wget -qO "$out" "$url"
	else
		print_error "Need curl or wget"
		exit 1
	fi
}

# Resolve release tag: VERSION env (with or without v) or latest from API.
resolve_tag() {
	local pin="${VERSION:-}"
	if [ -n "$pin" ]; then
		for try in "$pin" "v${pin#v}" "${pin#v}"; do
			code=$(curl -fsSL -o /dev/null -w "%{http_code}" "https://github.com/${REPO}/releases/tag/${try}" 2>/dev/null || echo "000")
			if [ "$code" = "200" ]; then
				echo "$try"
				return 0
			fi
		done
		# Prefer v-prefixed plus tags even if HEAD fails offline
		case "$pin" in
			v*) echo "$pin" ;;
			*) echo "v${pin}" ;;
		esac
		return 0
	fi
	local latest_info tmp
	tmp=$(mktemp)
	if ! http_get "$GITHUB_API_URL" "$tmp" 2>/dev/null; then
		rm -f "$tmp"
		print_error "Failed to fetch latest release from ${REPO}"
		print_error "Build from monorepo: cd install && make go-build-release && ./bin/installer_linux_\$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"
		exit 1
	fi
	local version
	version=$(grep '"tag_name"' "$tmp" | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
	rm -f "$tmp"
	if [ -z "$version" ]; then
		print_error "Could not parse tag_name from GitHub API"
		exit 1
	fi
	echo "$version"
}

detect_platform() {
	local os arch
	case "$(uname -s)" in
		Linux*) os="linux" ;;
		*)
			print_error "Unsupported OS: $(uname -s). Only Linux is supported."
			exit 1
			;;
	esac
	case "$(uname -m)" in
		x86_64|amd64) arch="amd64" ;;
		arm64|aarch64) arch="arm64" ;;
		*)
			print_error "Unsupported arch: $(uname -m). Only amd64 and arm64."
			exit 1
			;;
	esac
	echo "${os}_${arch}"
}

main() {
	print_status "Installing pangolin-plus installer from ${REPO}..."
	TAG=$(resolve_tag)
	print_status "Release tag: ${TAG}"
	PLATFORM=$(detect_platform)
	print_status "Platform: ${PLATFORM}"

	local binary_name="installer_${PLATFORM}"
	local download_url="https://github.com/${REPO}/releases/download/${TAG}/${binary_name}"
	local install_dir
	install_dir="$(pwd)"
	local final_path="${install_dir}/installer"
	local temp_file
	temp_file=$(mktemp)

	print_status "Downloading ${download_url}"
	if ! http_get "$download_url" "$temp_file"; then
		rm -f "$temp_file"
		print_error "Download failed. Is installer_${PLATFORM} on release ${TAG}?"
		print_error "From monorepo: cd install && make go-build-release && cp bin/installer_${PLATFORM} ./installer"
		exit 1
	fi
	mv "$temp_file" "$final_path"
	chmod +x "$final_path"
	print_status "Installer ready: ${final_path}"
	print_status "Run: ./installer   # writes compose with ghcr.io/88plug/pangolin-plus/* images"
}

main "$@"
