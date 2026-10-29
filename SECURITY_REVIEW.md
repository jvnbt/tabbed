# Security review — Tabbed Local

Review date: 2026-10-28. Upstream revision:
`9481b628767921bd1af1b90c4d7448282c9757b6` (v0.1.2).

This is a focused source and packaging review with local build/runtime checks,
not an independent audit or a guarantee that the software is free of vulnerabilities.

## Findings

### Upstream signing certificate is revoked — confirmed locally

The cached upstream release archive has SHA-256:
`57b417f5bb2739be5e2865a3ef188cf60ec5119853b6f05a50b3a9ab0f2222b5`.
Its executable has SHA-256:
`b7f471a12e9465616a703c66269220b79f907722bc1ad7be65edbce05526354a`.

Without executing the release, `spctl --assess --type execute -vv` returned
`CSSMERR_TP_CERT_REVOKED`. After extracting with macOS `ditto` (which correctly
handles the ZIP's AppleDouble metadata), `codesign --verify --deep --strict`
confirmed that the bundle was intact. An initial Python ZIP extraction exposed
AppleDouble sidecar files as ordinary files and therefore failed resource-seal
verification; that extraction is not evidence of upstream bundle tampering.

The release is signed with an Apple Development certificate, team `W9C2P3N7Q2`,
and has both hardened runtime and `com.apple.security.get-task-allow = true`.

This independently corroborates the certificate-revocation finding in
[upstream issue 5](https://github.com/ZimengXiong/tabbed/issues/5#issuecomment-6249347634).
The reason for revocation is unknown. We did not establish source-to-binary
identity, identify a malware family, or prove the original release safe.
The fork does not reuse or re-sign that executable.

### Quarantine removal and insufficient distribution checks — removed

The original README and release workflow recommended/generated automatic removal
of the quarantine attribute. The workflow verified code-signature integrity, but
had no Developer ID notarization/stapling step. Integrity verification alone did
not detect the revoked trust status.

The fork removes those instructions and the upstream release/tap-publishing
workflow. The documented build compiles local source only. No command disables
Gatekeeper, XProtect, SIP, or quarantine. The local app has its own bundle ID and
name, so it does not inherit the original app's Accessibility grant.

### Debugger entitlement in distributed app — removed from local release

The fork explicitly disables Xcode's injected base entitlements. The verified
Release artifact has hardened runtime and only `com.apple.security.app-sandbox =
false`; it has no `get-task-allow`, JIT, unsigned executable-memory, or library
validation exceptions. A verification script rejects unexpected entitlements,
missing hardened runtime, a wrong bundle ID, or non-system linked libraries.

The Debug test command disables hardened runtime only for its separately built
XCTest host. That artifact is not installed. The installed app is the verified
Release artifact.

### Application behavior review

Reviewed all application source files, the bridging header, configuration parser,
existing tests, XcodeGen settings, Info.plist, entitlements, and release workflow.
No apparent credential collection, shell/process execution, network requests,
telemetry, remote configuration, self-updating code, embedded executable payloads,
or login-item/LaunchAgent persistence was found in the application source.
There are no third-party application dependencies or build-time package hooks.

The application reads window metadata and titles, observes window events, moves
and raises windows, and uses private WindowServer/Spaces APIs. Its global event
taps inspect mouse events and keyboard keycodes/modifiers to implement gestures
and shortcuts. No typed-text recording or transmission was found. Configuration
is read/written locally; two menu settings use UserDefaults. It opens its local
configuration file or the Accessibility settings URL only on menu actions.

Accessibility permission is still broad. Private window APIs may change across
macOS versions. This review does not make arbitrary future updates trustworthy.

### Offline requirement — enforced and tested

`Sources/Security/NetworkSandbox.c` embeds a Seatbelt policy denying `network*`
and access to `com.apple.nsurlsessiond`. The application applies it at entry,
before creating NSApplication or initializing configuration/event monitors. A
failure exits the application. There is no environment-variable or configuration
switch to bypass the policy. No policy file is loaded from disk.

`python3 scripts/test-network-policy.py` compiles the exact same C implementation
into a test-only probe. Four unsandboxed controls successfully contacted local
IPv4/IPv6 TCP/UDP endpoints; all four sandboxed counterparts failed with OS
permission denial (`EPERM`), rather than connection errors. No internet endpoint
was contacted by those tests. The test probe is not shipped in the app.

This uses Apple's deprecated custom Seatbelt profile API because normal App
Sandbox isolation is incompatible with the app's cross-application Accessibility
operations. A future OS may break this API; the app will refuse to start. This is
network isolation, not full filesystem/IPC isolation. It does not constrain other
independent apps or OS services, including macOS's own certificate checks, and is
not a proof against every possible IPC-assisted escape after arbitrary code
execution.

### Window restoration on normal quit — fixed

Upstream parks inactive windows off-screen and did not restore them on quit.
The fork stops input monitors/observers, cancels movement tracking, and restores
live grouped windows on normal termination. Queued grouping work checks running
state. A regression test verifies restoration, skips dead windows, clears groups,
and checks that repeated cleanup is harmless. Forced termination/crashes still
cannot guarantee window restoration.

## Validation

- Built Release locally with Xcode 27.1 / Swift 6.4 on macOS 27.2, Apple silicon.
- Release signature integrity, hardened runtime, entitlements, bundle identity,
  and system-only dynamic-library checks passed.
- All 10 XCTest tests passed, including the new cleanup regression test.
- Four positive and four negative network-policy checks passed.
- Installed from the local Release build as `Tabbed Local.app` and opened normally.
- Queried the installed running process with `sandbox_check`: outbound, inbound,
  and bind operations were denied; an unsandboxed control allowed all three.
  `lsof` showed no open internet sockets for the app at the time of inspection.
- `spctl` does not accept this ad-hoc build as a notarized distribution. Normal
  launch of a locally compiled app requires no quarantine or policy override;
  no claim of Apple notarization or malware certification is made.

The installed app's Accessibility/control permission was observed enabled in
System Settings. A live process sample showed the AppKit run loop servicing event
tap messages with the network policy active. The user subsequently confirmed
that grouping works with the installed fork. Automated interactive testing was
limited by menu-bar inspection timeouts and modifier-drag automation support;
tab switching and quit restoration were not separately verified through the UI.
The cleanup regression test covers restoration logic. These checks do not
establish compatibility with every app, full-screen mode, or monitor/Spaces
configuration.
