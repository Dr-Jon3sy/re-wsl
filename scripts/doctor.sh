#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$repo_root"
# shellcheck source=env.sh
source "$repo_root/scripts/env.sh"

failures=0
check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf '[ok]   %-18s %s\n' "$name" "$(command -v "$name")"
  else
    printf '[miss] %-18s\n' "$name"
    failures=$((failures + 1))
  fi
}

check_optional_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1 && "$name" --version >/dev/null 2>&1; then
    printf '[ok]   %-18s %s (optional agent CLI)\n' "$name" "$(command -v "$name")"
  else
    printf '[info] %-18s optional; install inside WSL if CLI use is desired\n' "$name"
  fi
}

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  printf '[ok]   WSL                %s\n' "$(uname -r)"
else
  printf '[miss] WSL\n'
  failures=$((failures + 1))
fi

for command_name in uv python node npm java r2 binwalk yara tshark nmap adb apktool ghidraRun analyzeHeadless; do
  check_command "$command_name"
done

check_optional_command codex

if uv run --frozen python -c 'import capstone, cryptography, frida, numpy, pyghidra, scipy, usb.core, yara' >/dev/null 2>&1; then
  printf '[ok]   Python imports     core RE libraries\n'
else
  printf '[miss] Python imports     run: uv sync --frozen --link-mode copy\n'
  failures=$((failures + 1))
fi

if [[ -x node_modules/.bin/apk-mitm ]]; then
  printf '[ok]   apk-mitm           %s\n' "$repo_root/node_modules/.bin/apk-mitm"
else
  printf '[miss] apk-mitm           run: npm ci\n'
  failures=$((failures + 1))
fi

if [[ "$failures" -eq 0 ]]; then
  printf '\nEnvironment checks passed.\n'
else
  printf '\nEnvironment has %d missing required component(s).\n' "$failures" >&2
fi
exit "$failures"
