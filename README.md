# antiburn Homebrew tap

Install the [antiburn](https://antiburn.com) desktop app on macOS 13 or later.
Native packages are available for Apple silicon and Intel.

```sh
brew install --cask antiburn/tap/antiburn
```

The cask downloads the signed, notarized DMG from a stable
[desktop release](https://github.com/antiburn/antiburn/releases) and verifies its
SHA-256 checksum. It installs `/Applications/antiburn.app` by default.

## Updates

antiburn can update itself. The cask declares `auto_updates true`. Homebrew
upgrade behavior can depend on its version and settings. To request a Homebrew
update explicitly:

```sh
brew update
brew upgrade --cask antiburn/tap/antiburn
```

After an in-app update, `brew info` can still show the previous Homebrew
installation receipt. When the tap catches up, an explicit cask upgrade can
reinstall the current app and update that receipt. Native tests with Homebrew
6.0.18 and 6.0.22 verified the 0.7.3-to-0.9.0 transition. While the tap still
described 0.7.3, normal bulk, explicit, and `--greedy` cask upgrades preserved the
newer 0.9.0 app. Explicit and greedy upgrades reported that the latest version
was already installed. After the tap advanced to 0.9.0, an explicit cask
upgrade reconciled Homebrew's receipt to 0.9.0. This result is limited to that
tested transition and those Homebrew versions. See the [support guide](https://github.com/antiburn/antiburn/blob/main/docs/support.md#installation-and-updates).

## Remove the app

```sh
brew uninstall --cask antiburn/tap/antiburn
```

This preserves local app data. To remove the app and its local data, logs,
preferences, and webview state:

```sh
brew uninstall --cask --zap antiburn/tap/antiburn
```

Zap does not remove coding-agent transcripts, provider credentials, projects,
or configuration changes you made to coding agents. macOS manages its own
permission and login-item records.

## Validation

CI checks the cask on native Apple silicon and Intel macOS runners. It checks
style, online audit, livecheck, signing, notarization, launch, and removal.
Installation and cleanup tests run only on disposable GitHub-hosted runners.

```sh
brew style --cask antiburn/tap/antiburn
brew audit --cask --strict --online antiburn/tap/antiburn
brew livecheck --cask antiburn/tap/antiburn
```

Use Conventional Commits and include a DCO sign-off (`git commit -s`).
