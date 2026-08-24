#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
install_root="$repo_root/.tools/ghidra"
api_url="https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest"

for command_name in curl jq unzip sha256sum; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  fi
done

mkdir -p "$install_root"
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

release_json="$download_dir/release.json"
curl --fail --location --retry 3 --silent --show-error "$api_url" -o "$release_json"

tag="$(jq -er '.tag_name' "$release_json")"
asset="$(jq -cer '[.assets[] | select((.name | test("^ghidra_.*_PUBLIC_.*\\.zip$")) and ((.name | endswith("_src.zip")) | not))][0]' "$release_json")"
asset_name="$(jq -er '.name' <<<"$asset")"
asset_url="$(jq -er '.browser_download_url' <<<"$asset")"
asset_digest="$(jq -er '.digest // empty' <<<"$asset" 2>/dev/null || true)"
version_dir="$install_root/$tag"

if [[ -x "$version_dir/ghidraRun" ]]; then
  ln -sfn "$version_dir" "$install_root/current"
  printf 'Ghidra %s is already installed.\n' "$tag"
  exit 0
fi

archive="$download_dir/$asset_name"
printf 'Downloading Ghidra %s...\n' "$tag"
curl --fail --location --retry 3 --progress-bar "$asset_url" -o "$archive"

if [[ "$asset_digest" == sha256:* ]]; then
  expected="${asset_digest#sha256:}"
  actual="$(sha256sum "$archive" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Ghidra checksum mismatch.\n' >&2
    exit 1
  fi
else
  printf 'Warning: GitHub did not publish a SHA-256 digest for this asset.\n' >&2
fi

extract_dir="$download_dir/extracted"
mkdir -p "$extract_dir"
unzip -q "$archive" -d "$extract_dir"
mapfile -t extracted_entries < <(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d -print)
if [[ "${#extracted_entries[@]}" -ne 1 || ! -x "${extracted_entries[0]}/ghidraRun" ]]; then
  printf 'Unexpected Ghidra archive layout.\n' >&2
  exit 1
fi

mv -- "${extracted_entries[0]}" "$version_dir"
ln -sfn "$version_dir" "$install_root/current"
printf 'Installed Ghidra %s in %s\n' "$tag" "$version_dir"
