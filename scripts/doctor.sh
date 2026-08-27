#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
full=false

usage() {
  cat <<'EOF'
Usage: bash scripts/doctor.sh [--full]

  --full     Also require every package installed by setup-wsl.sh --full
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --full) full=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

cd "$repo_root"
# shellcheck source=env.sh
source "$repo_root/scripts/env.sh"

failures=0
check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf '[ok]   %-20s %s\n' "$name" "$(command -v "$name")"
  else
    printf '[miss] %-20s required command is unavailable\n' "$name"
    failures=$((failures + 1))
  fi
}

check_optional_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf '[ok]   %-20s %s (optional agent CLI)\n' "$name" "$(command -v "$name")"
  else
    printf '[info] %-20s optional agent CLI is not installed\n' "$name"
  fi
}

check_version_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1 && "$name" --version >/dev/null 2>&1; then
    printf '[ok]   %-20s %s\n' "$name" "$(command -v "$name")"
  else
    printf '[miss] %-20s command is missing or cannot run\n' "$name"
    failures=$((failures + 1))
  fi
}

kernel_release="$(uname -r)"
if [[ "$kernel_release" =~ [Mm]icrosoft-standard-WSL2 ]]; then
  printf '[ok]   %-20s %s\n' WSL2 "$kernel_release"
else
  printf '[miss] %-20s WSL2 is required\n' WSL2
  failures=$((failures + 1))
fi

required_commands=(
  uv python node npm java
  file exiftool r2 binwalk yara upx
  tshark nmap http protoc mitmproxy mitmdump mitmweb
  adb fastboot apktool aapt apksigner
  cabextract innoextract msiextract msiinfo osslsigncode
  frida frida-ps frida-trace
  jq sqlite3 openssl 7z
  lsusb i2cdetect ddcutil edid-decode v4l2-ctl
  ghidraRun analyzeHeadless
)
for command_name in "${required_commands[@]}"; do
  check_command "$command_name"
done
check_version_command rg

if command -v java >/dev/null 2>&1; then
  java_version_output="$(java -version 2>&1)"
  java_major="$(sed -nE 's/.*version "([0-9]+).*/\1/p' <<<"$java_version_output" | head -n 1)"
  if [[ "$java_major" == 21 ]]; then
    printf '[ok]   %-20s %s\n' 'Java major' "$java_major"
  else
    printf '[miss] %-20s expected 21; found %s\n' 'Java major' "${java_major:-unknown}"
    failures=$((failures + 1))
  fi
fi

if command -v node >/dev/null 2>&1; then
  node_major="$(node --version | sed -nE 's/^v([0-9]+).*/\1/p')"
  if [[ "$node_major" =~ ^[0-9]+$ && "$node_major" -ge 18 ]]; then
    printf '[ok]   %-20s %s\n' 'Node.js major' "$node_major"
  else
    printf '[miss] %-20s expected 18 or newer; found %s\n' 'Node.js major' "${node_major:-unknown}"
    failures=$((failures + 1))
  fi
fi

ghidra_properties="${GHIDRA_INSTALL_DIR:-}/Ghidra/application.properties"
if [[ -n "${GHIDRA_INSTALL_DIR:-}" && -f "$ghidra_properties" ]]; then
  ghidra_version="$(sed -n 's/^application.version=//p' "$ghidra_properties" | head -n 1)"
  ghidra_major="${ghidra_version%%.*}"
  if [[ "$ghidra_major" =~ ^[0-9]+$ && "$ghidra_major" -ge 12 ]]; then
    printf '[ok]   %-20s %s (%s)\n' 'Ghidra install' "$GHIDRA_INSTALL_DIR" "$ghidra_version"
  else
    printf '[miss] %-20s PyGhidra 3.0 requires Ghidra 12 or newer; found %s\n' \
      'Ghidra version' "${ghidra_version:-unknown}"
    failures=$((failures + 1))
  fi
else
  printf '[miss] %-20s GHIDRA_INSTALL_DIR does not identify a complete install\n' 'Ghidra install'
  failures=$((failures + 1))
fi

if [[ -n "${LIBUSB1_SO:-}" && -r "$LIBUSB1_SO" ]]; then
  printf '[ok]   %-20s %s\n' LIBUSB1_SO "$LIBUSB1_SO"
else
  printf '[miss] %-20s unable to resolve libusb-1.0.so.0\n' LIBUSB1_SO
  failures=$((failures + 1))
fi

check_optional_command codex
check_optional_command claude

if uv run --frozen python -c \
  'import capstone, cryptography, frida, numpy, pyghidra, scipy, usb.core, yara' \
  >/dev/null 2>&1; then
  pyghidra_version="$(uv run --frozen python -c \
    'from importlib.metadata import version; print(version("pyghidra"))')"
  printf '[ok]   %-20s core RE libraries (PyGhidra %s)\n' 'Python imports' "$pyghidra_version"
else
  printf '[miss] %-20s run: uv sync --frozen\n' 'Python imports'
  failures=$((failures + 1))
fi

if [[ -x node_modules/.bin/apk-mitm ]]; then
  printf '[ok]   %-20s %s\n' apk-mitm "$repo_root/node_modules/.bin/apk-mitm"
else
  printf '[miss] %-20s run: npm ci\n' apk-mitm
  failures=$((failures + 1))
fi

if [[ "$full" == true ]]; then
  full_commands=(hashcat john yosys arm-none-eabi-gcc scrcpy)
  if [[ "$(dpkg --print-architecture 2>/dev/null)" == amd64 ]]; then
    full_commands+=(wine winetricks)
  fi
  for command_name in "${full_commands[@]}"; do
    check_command "$command_name"
  done
fi

if [[ "$failures" -eq 0 ]]; then
  printf '\nEnvironment checks passed.\n'
else
  printf '\nEnvironment has %d missing required component(s).\n' "$failures" >&2
fi
exit "$failures"
