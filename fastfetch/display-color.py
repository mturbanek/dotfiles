#!/usr/bin/env python3
"""Print HDR / WCG / VRR state of the primary KDE Wayland output for fastfetch."""
import json
import subprocess

try:
    data = json.loads(subprocess.run(["kscreen-doctor", "-j"], capture_output=True,
                                     text=True, timeout=2).stdout)
except Exception:
    raise SystemExit(0)

outputs = [o for o in data.get("outputs", []) if o.get("enabled")]
if not outputs:
    raise SystemExit(0)
o = min(outputs, key=lambda x: x.get("priority") or 99)

onoff = lambda b: "on" if b else "off"
vrr = {0: "off", 1: "always", 2: "auto"}.get(o.get("vrrPolicy"), "?")
parts = [f"HDR {onoff(o.get('hdr'))}", f"WCG {onoff(o.get('wcg'))}", f"VRR {vrr}"]
if o.get("hdr") and o.get("sdr-brightness"):
    parts.append(f"SDR {o['sdr-brightness']} nits")
print(" · ".join(parts))
