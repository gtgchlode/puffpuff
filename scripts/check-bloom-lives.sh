#!/bin/bash
set -euo pipefail
puffpuff_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
puffpuff_test_dir="$(mktemp -d "${TMPDIR:-/tmp}/puffpuff-life-check.XXXXXX")"
xcrun swiftc -module-cache-path "$puffpuff_test_dir/modules" \
  "$puffpuff_root/puffpuff/Game/CoralPuzzle.swift" \
  "$puffpuff_root/puffpuff/Game/FirstReef.swift" \
  "$puffpuff_root/puffpuff/Game/ReefMiniChallenge.swift" \
  "$puffpuff_root/puffpuff/Game/ReefCove.swift" \
  "$puffpuff_root/puffpuff/Game/ReefSaveFile.swift" \
  "$puffpuff_root/puffpuff/Game/ReefStore.swift" \
  "$puffpuff_root/Tests/BloomLives.swift" -o "$puffpuff_test_dir/BloomLives"
cp "$puffpuff_root/puffpuff/Resources/BloomLevels.json" "$puffpuff_test_dir/BloomLevels.json"
"$puffpuff_test_dir/BloomLives" "$puffpuff_test_dir/fixture"
printf 'Isolated checks retained in %s\n' "$puffpuff_test_dir"
