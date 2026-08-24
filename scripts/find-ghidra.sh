# Shared Ghidra discovery for setup-wsl.sh and env.sh.

_re_shell_resolve_ghidra_install_dir() {
  local candidate="${1:-}"
  local resolved

  [[ -n "$candidate" ]] || return 1

  if [[ -f "$candidate" ]]; then
    [[ "$(basename -- "$candidate")" == ghidraRun ]] || return 1
    resolved="$(readlink -f -- "$candidate" 2>/dev/null)" || return 1
    candidate="$(dirname -- "$resolved")"
  else
    candidate="$(readlink -f -- "$candidate" 2>/dev/null)" || return 1
  fi

  if [[ -x "$candidate/ghidraRun" && -x "$candidate/support/analyzeHeadless" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  return 1
}

_re_shell_find_ghidra_install_dir() {
  local repo_root="${1:-}"
  local candidate
  local command_path
  local resolved

  for candidate in "${GHIDRA_INSTALL_DIR:-}" "${GHIDRA_PATH:-}"; do
    if resolved="$(_re_shell_resolve_ghidra_install_dir "$candidate")"; then
      printf '%s\n' "$resolved"
      return 0
    fi
  done

  if command_path="$(command -v ghidraRun 2>/dev/null)" && \
     resolved="$(_re_shell_resolve_ghidra_install_dir "$command_path")"; then
    printf '%s\n' "$resolved"
    return 0
  fi

  for candidate in \
    "$repo_root/.tools/ghidra/current" \
    /opt/ghidra \
    /usr/share/ghidra; do
    if resolved="$(_re_shell_resolve_ghidra_install_dir "$candidate")"; then
      printf '%s\n' "$resolved"
      return 0
    fi
  done

  return 1
}
