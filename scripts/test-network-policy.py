#!/usr/bin/env python3
"""Test the app's actual C policy against working local TCP/UDP endpoints."""
import pathlib
import socket
import subprocess

root = pathlib.Path(__file__).resolve().parent.parent
out = root / ".build/security-tests"
out.mkdir(parents=True, exist_ok=True)
probe = out / "network-probe"
subprocess.run(["xcrun", "clang", str(root / "SecurityTests/network_probe.c"),
                str(root / "Sources/Security/NetworkSandbox.c"), "-lsandbox", "-o", str(probe)], check=True)
for family, label, address in [(socket.AF_INET, "ipv4", "127.0.0.1"),
                               (socket.AF_INET6, "ipv6", "::1")]:
    for kind, protocol in [(socket.SOCK_STREAM, "tcp"), (socket.SOCK_DGRAM, "udp")]:
        with socket.socket(family, kind) as server:
            server.bind((address, 0))
            if kind == socket.SOCK_STREAM:
                server.listen(4)
            port = str(server.getsockname()[1])
            for mode in ("control", "blocked"):
                result = subprocess.run([str(probe), mode, label, protocol, port],
                                        capture_output=True, text=True, timeout=10, check=True)
                print(f"{label} {protocol} {mode}: {result.stdout.strip()}")
print("PASS: four working loopback controls; four OS-denied network attempts")
