#!/bin/bash
set -euo pipefail
puffpuff_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
puffpuff_tests="$(mktemp -d "${TMPDIR:-/tmp}/puffpuff-trail-check.XXXXXX")"
xcrun swiftc -D DEBUG -O -g \
  -module-cache-path "$puffpuff_tests/modules" \
  "$puffpuff_root/puffpuff/Game/CoralPuzzle.swift" \
  "$puffpuff_root/puffpuff/Game/FirstReef.swift" \
  "$puffpuff_root/puffpuff/Game/ReefMiniChallenge.swift" \
  "$puffpuff_root/puffpuff/Game/ReefCove.swift" \
  "$puffpuff_root/puffpuff/Game/ReefSaveFile.swift" \
  "$puffpuff_root/puffpuff/Game/ReefStore.swift" \
  "$puffpuff_root/Tests/TrailRules.swift" -o "$puffpuff_tests/TrailRules"
cp "$puffpuff_root/puffpuff/Resources/BloomLevels.json" "$puffpuff_tests/BloomLevels.json"
# Optional first argument is a read-only v15 save fixture; otherwise create one.
"$puffpuff_tests/TrailRules" "$puffpuff_tests/fixtures" "$@"
printf 'Checks and isolated saves retained in %s\n' "$puffpuff_tests"
