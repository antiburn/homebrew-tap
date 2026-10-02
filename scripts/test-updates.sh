#!/bin/bash
set -euo pipefail

# This test installs older packages and removes app data on disposable runners.
test "${GITHUB_ACTIONS:-}" = true
test "${RUNNER_ENVIRONMENT:-}" = github-hosted
test "$(uname -m)" = "$EXPECTED_ARCH"
test ! -e /Applications/antiburn.app
test ! -e "$HOME/Library/Application Support/ai.antiburn.desktop"
set -x

cask=antiburn/tap/antiburn
app=/Applications/antiburn.app
database="$HOME/Library/Application Support/ai.antiburn.desktop/antiburn.sqlite3"
logs="$HOME/Library/Logs/antiburn"
updater=product/scripts/update-homebrew-cask.mjs
brew --version
brew tap --custom-remote antiburn/tap "$GITHUB_WORKSPACE"
cask_path="$(brew --repository antiburn/tap)/Casks/antiburn.rb"

node --input-type=module -e '
  import { versionFromTag } from "./product/scripts/update-homebrew-cask.mjs";
  versionFromTag(process.env.FROM_TAG);
  versionFromTag(process.env.TO_TAG);
'
from_version=${FROM_TAG#antiburn-v}
to_version=${TO_TAG#antiburn-v}
test "$from_version" != "$to_version"
live_version=$(curl -fsSL --max-time 30 https://github.com/antiburn/antiburn/releases/latest/download/latest.json |
  python3 -c 'import json, sys; print(json.load(sys.stdin)["version"])')
test "$live_version" = "$to_version"

bundle_version() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist"
}

prepare_old_cask() {
  node --input-type=module - "$cask_path" <<'JS'
import { readFileSync, writeFileSync } from "node:fs";
import { caskVersion } from "./product/scripts/update-homebrew-cask.mjs";
const file = process.argv[2];
const contents = readFileSync(file, "utf8");
caskVersion(contents);
writeFileSync(file, contents.replace(/^  version "\d+\.\d+\.\d+"$/m, '  version "0.0.0"'));
JS
  node "$updater" "$FROM_TAG" "$cask_path"
}

prepare_old_cask
brew install --cask "$cask"
test "$(bundle_version)" = "$from_version"
node "$updater" "$TO_TAG" "$cask_path"
brew outdated --cask
brew outdated --greedy --cask "$cask"
brew upgrade --cask "$cask"
test "$(bundle_version)" = "$to_version"
brew uninstall --cask "$cask"

prepare_old_cask
brew install --cask "$cask"
ANTIBURN_ANALYTICS_ENABLED=false "$app/Contents/MacOS/antiburn" &
app_pid=$!
for _ in {1..30}; do
  if test -f "$database"; then break; fi
  sleep 1
done
test -f "$database"
kill -TERM "$app_pid"
for _ in {1..30}; do
  if ! pgrep -x antiburn >/dev/null; then break; fi
  sleep 1
done
if pgrep -x antiburn >/dev/null; then exit 1; fi
sqlite3 "$database" "INSERT OR REPLACE INTO setting (key, value) VALUES
  ('onboardingCompleted', 'true'), ('launchAtLogin', 'false'),
  ('autoUpdate', 'true'), ('notifyAutoUpdate', 'false'),
  ('liveUsageEnabled', 'false'), ('notificationsEnabled', 'false'),
  ('discoveryPaused', 'true');"
ANTIBURN_ANALYTICS_ENABLED=false "$app/Contents/MacOS/antiburn" &
for _ in {1..120}; do
  if test "$(bundle_version)" = "$to_version"; then break; fi
  sleep 2
done
test "$(bundle_version)" = "$to_version"
sleep 5
python3 - "$logs" "$to_version" <<'PY'
from pathlib import Path
import sys
marker = '"event":"app_started","version":"' + sys.argv[2] + '"'
assert any(marker in log.read_text() for log in Path(sys.argv[1]).glob("*.log")), "Updated app did not restart"
print("Signed in-app update and restart passed")
PY
codesign --verify --deep --strict "$app"
spctl --assess --type execute "$app"
swift scripts/check-window.swift

printf '%s\n' 'Stale tap after in-app update:'
brew info --cask "$cask"
brew outdated --cask
brew outdated --greedy --cask "$cask"
brew upgrade --cask "$cask"
printf 'Bundle after explicit stale-tap upgrade: %s\n' "$(bundle_version)"
brew upgrade --greedy --cask "$cask"
printf 'Bundle after greedy stale-tap upgrade: %s\n' "$(bundle_version)"

node "$updater" "$TO_TAG" "$cask_path"
brew upgrade --cask "$cask"
test "$(bundle_version)" = "$to_version"
brew info --cask "$cask"
brew uninstall --cask --zap "$cask"
test ! -e "$app"
test ! -e "$database"
printf '%s\n' 'Homebrew upgrade and updater interaction checks passed'
