#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=find-ghidra.sh
source "$repo_root/scripts/find-ghidra.sh"
skip_system=false
skip_ghidra=false
full=false

usage() {
  cat <<'EOF'
Usage: bash scripts/setup-wsl.sh [options]

Options:
  --full           Install larger optional apt tools (Wine, hashcat, FPGA/ARM tools)
  --skip-system    Do not install Ubuntu packages
  --skip-ghidra    Do not download Ghidra
  -h, --help       Show this help

Ghidra discovery:
  GHIDRA_INSTALL_DIR  Installation directory or path to ghidraRun
  GHIDRA_PATH         Installation directory or path to ghidraRun
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --full) full=true ;;
    --skip-system) skip_system=true ;;
    --skip-ghidra) skip_ghidra=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if ! grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  printf 'This setup script is intended for WSL2.\n' >&2
  exit 1
fi
if [[ "$EUID" -eq 0 ]]; then
  printf 'Run this script as your normal WSL user; it invokes sudo only for apt.\n' >&2
  exit 1
fi
if ! command -v uv >/dev/null 2>&1; then
  printf 'uv is required. Install it first: https://docs.astral.sh/uv/\n' >&2
  exit 1
fi

ghidra_install_dir=""
if [[ "$skip_ghidra" == false ]]; then
  if [[ -n "${GHIDRA_INSTALL_DIR:-}" ]]; then
    if ! ghidra_install_dir="$(_re_shell_resolve_ghidra_install_dir "$GHIDRA_INSTALL_DIR")"; then
      printf 'GHIDRA_INSTALL_DIR is not a valid Ghidra installation: %s\n' "$GHIDRA_INSTALL_DIR" >&2
      exit 1
    fi
  elif [[ -n "${GHIDRA_PATH:-}" ]]; then
    if ! ghidra_install_dir="$(_re_shell_resolve_ghidra_install_dir "$GHIDRA_PATH")"; then
      printf 'GHIDRA_PATH is not a valid Ghidra installation: %s\n' "$GHIDRA_PATH" >&2
      exit 1
    fi
  else
    ghidra_install_dir="$(_re_shell_find_ghidra_install_dir "$repo_root" || true)"
  fi
fi

base_packages=(
  build-essential pkg-config cmake libusb-1.0-0 libusb-1.0-0-dev
  nodejs npm default-jdk
  radare2 binwalk yara tshark nmap avahi-utils
  unzip p7zip-full binutils file curl jq sqlite3 openssl upx-ucl xxd
  libimage-exiftool-perl innoextract v4l-utils ddcutil i2c-tools usbutils
  apktool apksigner aapt adb fastboot
  cabextract msitools osslsigncode protobuf-compiler httpie
)
full_packages=(
  hashcat john yosys gcc-arm-none-eabi wine64 winetricks scrcpy
)

if [[ "$skip_system" == false ]]; then
  sudo apt-get update
  requested_packages=("${base_packages[@]}")
  if [[ "$full" == true ]]; then
    requested_packages+=("${full_packages[@]}")
  fi

  available_packages=()
  for package_name in "${requested_packages[@]}"; do
    if apt-cache show "$package_name" >/dev/null 2>&1; then
      available_packages+=("$package_name")
    else
      printf 'Warning: Ubuntu package is unavailable: %s\n' "$package_name" >&2
    fi
  done
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${available_packages[@]}"
fi

cd "$repo_root"
printf '\nSyncing Python %s environment...\n' "$(cat .python-version)"
uv sync --frozen --link-mode copy

if command -v npm >/dev/null 2>&1; then
  printf '\nInstalling locked Node.js dependencies...\n'
  npm ci
else
  printf 'npm is missing; rerun without --skip-system after fixing apt.\n' >&2
  exit 1
fi

if [[ "$skip_ghidra" == false ]]; then
  if [[ -n "$ghidra_install_dir" ]]; then
    GHIDRA_INSTALL_DIR="$ghidra_install_dir"
    export GHIDRA_INSTALL_DIR
    printf '\nUsing existing Ghidra installation: %s\n' "$GHIDRA_INSTALL_DIR"
  else
    bash "$repo_root/scripts/install-ghidra.sh"
  fi
fi

# shellcheck source=env.sh
source "$repo_root/scripts/env.sh"
printf '\nSetup complete. Enter the environment with:\n  source scripts/env.sh\n'
printf 'Or launch a configured subshell with:\n  bash scripts/enter.sh\n\n'
bash "$repo_root/scripts/doctor.sh"
