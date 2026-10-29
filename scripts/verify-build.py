#!/usr/bin/env python3
"""Verify local bundle integrity and reject dangerous signing exceptions."""
import pathlib
import plistlib
import subprocess
import sys

app = pathlib.Path(sys.argv[1])
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
details = subprocess.run(["codesign", "-dvv", str(app)], capture_output=True, text=True, check=True).stderr
if "runtime" not in details:
    raise SystemExit("Hardened runtime is missing")
result = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(app)], capture_output=True, check=True)
entitlements = plistlib.loads(result.stdout) if result.stdout.strip() else {}
# Allow only the explicit non-App-Sandbox setting required by Accessibility.
unexpected = {k: v for k, v in entitlements.items()
              if k != "com.apple.security.app-sandbox" or v is not False}
if unexpected:
    raise SystemExit(f"Unexpected entitlements: {unexpected}")
with (app / "Contents/Info.plist").open("rb") as file:
    info = plistlib.load(file)
if info["CFBundleIdentifier"] != "io.github.jvnbt.tabbed":
    raise SystemExit("Unexpected app identity")
binary = app / "Contents/MacOS" / info["CFBundleExecutable"]
links = subprocess.check_output(["xcrun", "otool", "-L", str(binary)], text=True)
for line in links.splitlines()[1:]:
    library = line.strip().split(" (", 1)[0]
    if not library.startswith(("/System/Library/", "/usr/lib/")):
        raise SystemExit(f"Unexpected dynamic library: {library}")
print("Verified: signature, hardened runtime, restricted entitlements, app identity, system-only linked libraries")
