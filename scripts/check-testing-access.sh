#!/bin/bash
set -euo pipefail
puffpuff_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
puffpuff_tests="$(mktemp -d "${TMPDIR:-/tmp}/puffpuff-testing-access.XXXXXX")"
xcrun swiftc -module-cache-path "$puffpuff_tests/modules" \
  "$puffpuff_root/puffpuff/Game/CoralPuzzle.swift" \
  "$puffpuff_root/puffpuff/Game/FirstReef.swift" \
  "$puffpuff_root/puffpuff/Game/ReefMiniChallenge.swift" \
  "$puffpuff_root/puffpuff/Game/ReefCove.swift" \
  "$puffpuff_root/puffpuff/Game/ReefSaveFile.swift" \
  "$puffpuff_root/puffpuff/Game/ReefStore.swift" \
  "$puffpuff_root/Tests/TestingAccess.swift" -o "$puffpuff_tests/TestingAccess"
cp "$puffpuff_root/puffpuff/Resources/BloomLevels.json" "$puffpuff_tests/BloomLevels.json"
"$puffpuff_tests/TestingAccess" "$puffpuff_tests/fixtures"
printf 'Isolated testing-access and navigation checks retained in %s\n' "$puffpuff_tests"
