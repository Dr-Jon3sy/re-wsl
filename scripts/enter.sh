#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$repo_root"

# shellcheck source=env.sh
source "$repo_root/scripts/env.sh"

printf 're-shell ready at %s\n' "$RE_SHELL_ROOT"
exec "${SHELL:-/bin/bash}" -i
