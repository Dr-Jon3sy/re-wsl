#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
install_root="$repo_root/.tools/ghidra"

# Keep this release, its asset, and pyghidra in pyproject.toml/uv.lock compatible.
ghidra_tag="Ghidra_12.1.3_build"
ghidra_asset="ghidra_12.1.3_PUBLIC_20260817.zip"
ghidra_sha256="93a5d11a9ad510622acaaf908c556a7b9b764d338e78a7567f3689bf5081fd54"
ghidra_url="https://github.com/NationalSecurityAgency/ghidra/releases/download/$ghidra_tag/$ghidra_asset"
release_api_url="https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/tags/$ghidra_tag"
minimum_free_kib=$((2 * 1024 * 1024))

for command_name in curl unzip sha256sum realpath; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  fi
done

mkdir -p "$install_root"
version_dir="$install_root/$ghidra_tag"
if [[ -x "$version_dir/ghidraRun" && -x "$version_dir/support/analyzeHeadless" ]]; then
  ln -sfn "$version_dir" "$install_root/current"
  printf 'Ghidra %s is already installed.\n' "$ghidra_tag"
  exit 0
fi

available_kib="$(df -Pk "$install_root" | awk 'NR == 2 {print $4}')"
if [[ ! "$available_kib" =~ ^[0-9]+$ || "$available_kib" -lt "$minimum_free_kib" ]]; then
  printf 'Ghidra installation needs at least 2 GiB free under %s.\n' "$install_root" >&2
  exit 1
fi

download_dir="$(mktemp -d "$install_root/.download.XXXXXXXX")"
cleanup() {
  local resolved
  resolved="$(realpath -m "$download_dir")"
  case "$resolved" in
    "$install_root"/.download.*) rm -rf -- "$resolved" ;;
    *) printf 'Refusing to clean unexpected path: %s\n' "$resolved" >&2 ;;
  esac
}
trap cleanup EXIT

archive="$download_dir/$ghidra_asset"
printf 'Downloading pinned Ghidra release %s...\n' "$ghidra_tag"
curl --fail --location --retry 3 --progress-bar "$ghidra_url" -o "$archive"

actual_sha256="$(sha256sum "$archive" | awk '{print $1}')"
if [[ "$actual_sha256" != "$ghidra_sha256" ]]; then
  printf 'Ghidra checksum mismatch: expected %s, got %s.\n' "$ghidra_sha256" "$actual_sha256" >&2
  exit 1
fi
printf 'Verified the pinned SHA-256 checksum.\n'

# GitHub's release digest is a secondary check. The pinned checksum above does
# not depend on API availability or the unauthenticated API rate limit.
if command -v jq >/dev/null 2>&1; then
  api_headers=()
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    api_headers=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi
  release_json="$download_dir/release.json"
  if curl --fail --location --retry 2 --silent --show-error \
    "${api_headers[@]}" "$release_api_url" -o "$release_json"; then
    published_digest="$(jq -er --arg name "$ghidra_asset" \
      '.assets[] | select(.name == $name) | .digest // empty' \
      "$release_json" 2>/dev/null || true)"
    if [[ -n "$published_digest" && "$published_digest" != "sha256:$ghidra_sha256" ]]; then
      printf 'GitHub release digest disagrees with the pinned checksum.\n' >&2
      exit 1
    fi
  else
    printf 'Info: GitHub release API unavailable; the pinned checksum was still verified.\n' >&2
  fi
fi

extract_dir="$download_dir/extracted"
mkdir -p "$extract_dir"
unzip -q "$archive" -d "$extract_dir"
mapfile -t extracted_entries < <(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d -print)
if [[ "${#extracted_entries[@]}" -ne 1 || \
      ! -x "${extracted_entries[0]}/ghidraRun" || \
      ! -x "${extracted_entries[0]}/support/analyzeHeadless" ]]; then
  printf 'Unexpected Ghidra archive layout.\n' >&2
  exit 1
fi

mv -- "${extracted_entries[0]}" "$version_dir"
ln -sfn "$version_dir" "$install_root/current"
printf 'Installed Ghidra %s in %s\n' "$ghidra_tag" "$version_dir"
