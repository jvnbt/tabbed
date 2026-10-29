# Tabbed Local

A local, offline fork of [ZimengXiong/tabbed](https://github.com/ZimengXiong/tabbed).
Group windows from different applications into a compact tab strip by holding
Command while dragging one window onto another.

This fork is built from source. It does not reuse, re-sign, or install the upstream
release executable. See [SECURITY_REVIEW.md](SECURITY_REVIEW.md) for review scope,
findings, and limitations. This is a focused source review, not a safety certification.

## Build and use

Requires macOS 14+, full Xcode with the macOS 26+ SDK, XcodeGen, and Python 3.
There are no third-party application dependencies. Once the source and build
tools are present, building and running require no internet connection.

```sh
bash scripts/build-local.sh
python3 scripts/test-network-policy.py
xcodebuild -project Tabbed.xcodeproj -scheme Tabbed -configuration Debug \
  -derivedDataPath .build/Tests -destination 'platform=macOS' \
  ENABLE_HARDENED_RUNTIME=NO test
```

The result is `.build/DerivedData/Build/Products/Release/Tabbed Local.app`.
Copy this locally built app into Applications and open it normally. Grant
**Tabbed Local** access in System Settings → Privacy & Security → Accessibility.
It detects the grant without requiring a relaunch.

The local build uses ad-hoc signing, a separate bundle ID (`io.github.jvnbt.tabbed`),
and hardened runtime without the debugger entitlement. It is not a notarized
download for distribution to other Macs. Do not remove quarantine attributes,
disable Gatekeeper/XProtect, or re-sign a rejected downloaded executable. Stop
and investigate if macOS reports a malware detection.

## Offline policy

Before AppKit or any input monitoring starts, the app applies an embedded Seatbelt
policy denying network operations, including TCP/UDP and loopback. It also denies
access to the background URL-session service. There is no runtime opt-out. If the
policy cannot be applied, the app exits. No updater, telemetry, license service,
or remote configuration is included.

Seatbelt's custom-profile API is deprecated and may change in a future macOS.
The app deliberately fails closed in that case. This is a network restriction,
not full App Sandbox isolation: cross-app window control still requires broad
Accessibility permission. The policy does not constrain independent applications
or macOS services acting on their own (for example, macOS certificate checks).

## Controls

- Command-drag windows together to group them.
- Option+1…9 selects a tab; Option+Tab cycles; Option+Shift+Tab cycles backward.
- Edit `~/.config/tabbed.toml`, then choose **Reload Configuration** from the menu.
- **Always Use Compact Mode** uses the compact corner strip.
- Quitting normally restores inactive windows to their group frame.

The original MIT license and attribution are retained. Upstream binary-release
automation was removed; this fork does not publish binaries or update a Homebrew tap.
