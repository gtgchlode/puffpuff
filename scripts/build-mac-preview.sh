#!/bin/bash
set -euo pipefail

# Keep generated signing inputs outside cloud-synced Documents folders.
# Finder/file-provider attributes there can cause CodeSign to fail.
puffpuff_project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
puffpuff_build_dir="$(mktemp -d "${TMPDIR:-/tmp}/puffpuff-preview.XXXXXX")"

# Local ad-hoc signing creates no certificate or Apple account. It is required
# to apply the project's sandbox entitlement and use the original Mac save.
# CODE_SIGNING_ALLOWED=NO is only appropriate for simulator compilation.
xcodebuild \
  -project "$puffpuff_project_dir/puffpuff.xcodeproj" \
  -scheme puffpuff -configuration Debug \
  -sdk macosx -destination 'platform=macOS' \
  -derivedDataPath "$puffpuff_build_dir" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  PRODUCT_BUNDLE_IDENTIFIER=com.puffpuffreef.prototype build

puffpuff_app="$puffpuff_build_dir/Build/Products/Debug/puffpuff.app"
/usr/bin/codesign --verify --strict "$puffpuff_app"
if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$puffpuff_app/Contents/Info.plist")" != com.puffpuffreef.prototype ]]; then
  printf '%s\n' 'Refusing to distribute a preview with a different save identity.' >&2
  exit 1
fi
/usr/bin/codesign --display --entitlements - --xml "$puffpuff_app" \
  > "$puffpuff_build_dir/entitlements.plist"
if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$puffpuff_build_dir/entitlements.plist")" != true ]]; then
  printf '%s\n' 'Refusing to distribute a Mac preview without its sandbox: that would use a different save.' >&2
  exit 1
fi

printf '\nSandboxed Mac preview built successfully:\n%s\n' "$puffpuff_app"
printf '%s\n' 'Quit the running preview before replacing it. Preserve the existing app and save files.'
