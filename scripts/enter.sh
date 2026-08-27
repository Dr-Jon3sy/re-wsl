#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$repo_root"

# shellcheck source=env.sh
source "$repo_root/scripts/env.sh"

printf 're-wsl ready at %s\n' "$RE_SHELL_ROOT"
# Avoid user startup files resetting the configured PATH. All exported values
# from env.sh are inherited by this clean interactive Bash session.
exec /bin/bash --norc -i
