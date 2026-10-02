#!/bin/bash
set -euo pipefail

# This test removes app data. Run it only on a disposable hosted runner.
test "${GITHUB_ACTIONS:-}" = true
test "${RUNNER_ENVIRONMENT:-}" = github-hosted
test "$(uname -m)" = "$EXPECTED_ARCH"

cask=antiburn/tap/antiburn
app=/Applications/antiburn.app
data="$HOME/Library/Application Support/ai.antiburn.desktop"
database="$data/antiburn.sqlite3"
logs="$HOME/Library/Logs/antiburn"
test ! -e "$app"
test ! -e "$data"
set -x

brew install --cask "$cask"
test "$(lipo -archs "$app/Contents/MacOS/antiburn")" = "$EXPECTED_ARCH"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" = ai.antiburn.desktop
version=$(brew info --cask --json=v2 "$cask" | python3 -c 'import json, sys; print(json.load(sys.stdin)["casks"][0]["version"])')
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$version"
test "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$app/Contents/Info.plist")" = 13.0
codesign --verify --deep --strict "$app"
spctl --assess --type execute "$app"
xcrun stapler validate "$app"

ANTIBURN_ANALYTICS_ENABLED=false "$app/Contents/MacOS/antiburn" &
app_pid=$!
for _ in {1..60}; do
  if test -f "$database"; then break; fi
  sleep 1
done
test -f "$database"
test -d "$logs"
swift scripts/check-window.swift
kill -TERM "$app_pid"
for _ in {1..30}; do
  if ! pgrep -x antiburn >/dev/null; then break; fi
  sleep 1
done
if pgrep -x antiburn >/dev/null; then
  printf '%s\n' 'antiburn did not quit' >&2
  exit 1
fi

# Seed completed setup to exercise the packaged app's startup registration.
sqlite3 "$database" "INSERT OR REPLACE INTO setting (key, value) VALUES
  ('onboardingCompleted', 'true'), ('launchAtLogin', 'true'),
  ('autoUpdate', 'false'), ('liveUsageEnabled', 'false'),
  ('notificationsEnabled', 'false'), ('discoveryPaused', 'true');"
ANTIBURN_ANALYTICS_ENABLED=false "$app/Contents/MacOS/antiburn" &
sleep 5
swift scripts/check-window.swift
sfltool dumpbtm | python3 -c '
import sys
dump = sys.stdin.read()
assert "ai.antiburn.desktop" in dump, "Login-item registration is missing"
print("Login-item record is present")
'

brew uninstall --cask "$cask"
test ! -e "$app"
if pgrep -x antiburn >/dev/null; then
  printf '%s\n' 'antiburn is still running after uninstall' >&2
  exit 1
fi
test -f "$database"
test "$(sqlite3 "$database" "SELECT value FROM setting WHERE key = 'onboardingCompleted';")" = true
test -d "$logs"

# These synthetic files prove that zap stays inside app-owned paths.
mkdir -p "$HOME/.claude/projects/homebrew-test" "$HOME/homebrew-test-project"
printf '%s\n' 'synthetic transcript' > "$HOME/.claude/projects/homebrew-test/session.jsonl"
printf '%s\n' 'synthetic credentials' > "$HOME/.claude/.credentials.json"
printf '%s\n' 'synthetic configuration' > "$HOME/.claude/settings.json"
printf '%s\n' 'synthetic project' > "$HOME/homebrew-test-project/README.md"

brew install --cask "$cask"
brew uninstall --cask --zap "$cask"
test ! -e "$app"
for path in \
  "$data" \
  "$logs" \
  "$HOME/Library/Caches/ai.antiburn.desktop" \
  "$HOME/Library/Preferences/ai.antiburn.desktop.plist" \
  "$HOME/Library/Saved Application State/ai.antiburn.desktop.savedState" \
  "$HOME/Library/WebKit/ai.antiburn.desktop"; do
  test ! -e "$path"
done
test "$(< "$HOME/.claude/projects/homebrew-test/session.jsonl")" = 'synthetic transcript'
test "$(< "$HOME/.claude/.credentials.json")" = 'synthetic credentials'
test "$(< "$HOME/.claude/settings.json")" = 'synthetic configuration'
test "$(< "$HOME/homebrew-test-project/README.md")" = 'synthetic project'
printf '%s\n' 'Install, launch, normal uninstall, and zap checks passed'
