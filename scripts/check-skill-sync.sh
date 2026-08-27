#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
agents_dir="$repo_root/.agents/skills"
claude_dir="$repo_root/.claude/skills"

if diff -ru "$agents_dir" "$claude_dir"; then
  printf 'Agent skill trees are synchronized.\n'
else
  printf 'Agent skill trees differ. Update both copies together.\n' >&2
  exit 1
fi
