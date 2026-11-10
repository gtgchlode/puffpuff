#!/bin/bash
set -euo pipefail
puffpuff_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
puffpuff_checks="$(mktemp -d "${TMPDIR:-/tmp}/puffpuff-glow-path.XXXXXX")"
xcrun swiftc -D DEBUG -O -module-cache-path "$puffpuff_checks/modules" \
  "$puffpuff_root/puffpuff/Game/CoralPuzzle.swift" \
  "$puffpuff_root/puffpuff/Game/FirstReef.swift" \
  "$puffpuff_root/puffpuff/Game/ReefMiniChallenge.swift" \
  "$puffpuff_root/puffpuff/Game/ReefCove.swift" \
  "$puffpuff_root/puffpuff/Game/ReefSaveFile.swift" \
  "$puffpuff_root/puffpuff/Game/ReefStore.swift" \
  "$puffpuff_root/Tests/GlowPath.swift" -o "$puffpuff_checks/GlowPath"
cp "$puffpuff_root/puffpuff/Resources/BloomLevels.json" "$puffpuff_checks/BloomLevels.json"
"$puffpuff_checks/GlowPath" "$puffpuff_checks/fixtures" "$@"
printf 'Checks and isolated saves retained in %s\n' "$puffpuff_checks"
