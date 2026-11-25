#!/usr/bin/env bash
set -euo pipefail

# Read-only example: list files under a caller-provided local directory.
# It performs no network requests and writes no files.
target_dir="${1:-.}"

if [[ ! -d "$target_dir" ]]; then
  printf 'Not a directory: %s\n' "$target_dir" >&2
  exit 2
fi

find "$target_dir" -maxdepth 3 -type f -print | sort
