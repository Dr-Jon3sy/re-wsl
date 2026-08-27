#!/usr/bin/env bash

# Source this file from Bash: source scripts/env.sh
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  _re_shell_script="${BASH_SOURCE[0]}"
else
  _re_shell_script="$0"
fi

RE_SHELL_ROOT="$(cd "$(dirname "$_re_shell_script")/.." && pwd -P)"
export RE_SHELL_ROOT

# shellcheck source=find-ghidra.sh
source "$RE_SHELL_ROOT/scripts/find-ghidra.sh"

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

if [[ -n "${GHIDRA_INSTALL_DIR:-}" ]] && \
   ! _re_shell_resolve_ghidra_install_dir "$GHIDRA_INSTALL_DIR" >/dev/null; then
  printf 'Warning: ignoring invalid GHIDRA_INSTALL_DIR: %s\n' "$GHIDRA_INSTALL_DIR" >&2
elif [[ -z "${GHIDRA_INSTALL_DIR:-}" && -n "${GHIDRA_PATH:-}" ]] && \
     ! _re_shell_resolve_ghidra_install_dir "$GHIDRA_PATH" >/dev/null; then
  printf 'Warning: ignoring invalid GHIDRA_PATH: %s\n' "$GHIDRA_PATH" >&2
fi

if _re_shell_ghidra="$(_re_shell_find_ghidra_install_dir "$RE_SHELL_ROOT")"; then
  GHIDRA_INSTALL_DIR="$_re_shell_ghidra"
  export GHIDRA_INSTALL_DIR
else
  unset GHIDRA_INSTALL_DIR
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

if [[ -z "${LIBUSB1_SO:-}" ]]; then
  if command -v ldconfig >/dev/null 2>&1; then
    LIBUSB1_SO="$(ldconfig -p 2>/dev/null | awk '/libusb-1\.0\.so\.0/ {print $NF; exit}')"
  fi
  if [[ -z "${LIBUSB1_SO:-}" ]]; then
    for _re_shell_libusb in \
      /lib/x86_64-linux-gnu/libusb-1.0.so.0 \
      /lib/aarch64-linux-gnu/libusb-1.0.so.0; do
      if [[ -e "$_re_shell_libusb" ]]; then
        LIBUSB1_SO="$_re_shell_libusb"
        break
      fi
    done
  fi
  if [[ -n "${LIBUSB1_SO:-}" ]]; then
    export LIBUSB1_SO
  fi
fi

mkdir -p "$RE_SHELL_ROOT/tmp/jtmp"
case "${_JAVA_OPTIONS:-}" in
  *-Djava.io.tmpdir=*) ;;
  *) export _JAVA_OPTIONS="-Djava.io.tmpdir=$RE_SHELL_ROOT/tmp/jtmp${_JAVA_OPTIONS:+ $_JAVA_OPTIONS}" ;;
esac

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"
export PATH

unset _re_shell_script _re_shell_ghidra _re_shell_java _re_shell_libusb
unset -f _re_shell_prepend_path
unset -f _re_shell_resolve_ghidra_install_dir _re_shell_find_ghidra_install_dir
