#!/usr/bin/env bash

# Source this file from Bash: source scripts/env.sh
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  _re_shell_script="${BASH_SOURCE[0]}"
else
  _re_shell_script="$0"
fi

RE_SHELL_ROOT="$(cd "$(dirname "$_re_shell_script")/.." && pwd -P)"
export RE_SHELL_ROOT

_re_shell_prepend_path() {
  local entry="$1"
  [[ -d "$entry" ]] || return 0
  case ":$PATH:" in
    *":$entry:"*) ;;
    *) PATH="$entry:$PATH" ;;
  esac
}

_re_shell_prepend_path "$RE_SHELL_ROOT/.venv/bin"
_re_shell_prepend_path "$RE_SHELL_ROOT/node_modules/.bin"
_re_shell_prepend_path "$RE_SHELL_ROOT/.tools/bin"

if [[ -d "$RE_SHELL_ROOT/.venv" ]]; then
  export VIRTUAL_ENV="$RE_SHELL_ROOT/.venv"
fi

if [[ -z "${GHIDRA_INSTALL_DIR:-}" ]]; then
  for _re_shell_ghidra in \
    "$RE_SHELL_ROOT/.tools/ghidra/current" \
    /opt/ghidra \
    /usr/share/ghidra; do
    if [[ -x "$_re_shell_ghidra/ghidraRun" ]]; then
      GHIDRA_INSTALL_DIR="$_re_shell_ghidra"
      export GHIDRA_INSTALL_DIR
      break
    fi
  done
fi

if [[ -n "${GHIDRA_INSTALL_DIR:-}" ]]; then
  _re_shell_prepend_path "$GHIDRA_INSTALL_DIR"
  _re_shell_prepend_path "$GHIDRA_INSTALL_DIR/support"
fi

if [[ -z "${GHIDRA_JAVA_HOME:-}" ]] && command -v java >/dev/null 2>&1; then
  _re_shell_java="$(readlink -f "$(command -v java)")"
  GHIDRA_JAVA_HOME="${_re_shell_java%/bin/java}"
  export GHIDRA_JAVA_HOME
fi

if [[ -z "${LIBUSB1_SO:-}" ]] && command -v ldconfig >/dev/null 2>&1; then
  LIBUSB1_SO="$(ldconfig -p 2>/dev/null | awk '/libusb-1\.0\.so\.0 .*x86-64/ {path=$NF} END {print path}')"
  if [[ -n "$LIBUSB1_SO" ]]; then
    export LIBUSB1_SO
  fi
fi

if [[ -z "${PICO_SDK_PATH:-}" && -d /opt/pico-sdk ]]; then
  export PICO_SDK_PATH=/opt/pico-sdk
fi

mkdir -p "$RE_SHELL_ROOT/tmp/jtmp"
case "${_JAVA_OPTIONS:-}" in
  *-Djava.io.tmpdir=*) ;;
  *) export _JAVA_OPTIONS="-Djava.io.tmpdir=$RE_SHELL_ROOT/tmp/jtmp${_JAVA_OPTIONS:+ $_JAVA_OPTIONS}" ;;
esac

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"
export PATH

unset _re_shell_script _re_shell_ghidra _re_shell_java
unset -f _re_shell_prepend_path
