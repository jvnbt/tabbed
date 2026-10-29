#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Compile repository source only; no downloads or security overrides.
xcodegen generate
xcodebuild -project Tabbed.xcodeproj -scheme Tabbed -configuration Release \
  -derivedDataPath .build/DerivedData \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  ENABLE_HARDENED_RUNTIME=YES build

app_path=".build/DerivedData/Build/Products/Release/Tabbed Local.app"
python3 scripts/verify-build.py "$app_path"
echo "Built: $app_path"
