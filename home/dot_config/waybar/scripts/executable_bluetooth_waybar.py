#!/usr/bin/env python3
"""Reliable Bluetooth status and power controls for Waybar."""

from __future__ import annotations

import html
import json
import re
import shutil
import subprocess
import sys

ICON_ON = "󰂯"
ICON_CONNECTED = "󰂱"
ICON_OFF = "󰂲"
WAYBAR_SIGNAL = "-RTMIN+7"


def sanitize(value: object) -> str:
    return re.sub(r"[\x00-\x1f\x7f]+", " ", str(value or "")).strip()


def markup(value: object) -> str:
    return html.escape(sanitize(value), quote=False)


def output(text: str, tooltip: str, css_class: str) -> None:
    print(json.dumps({"text": text, "tooltip": tooltip, "class": css_class}, ensure_ascii=False))


def run(args: list[str], timeout: float = 5) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(args, 124, "", "command timed out")
    except OSError as error:
        return subprocess.CompletedProcess(args, 126, "", str(error))


def bluetoothctl(*args: str, timeout: float = 5) -> str:
    result = run(["bluetoothctl", *args], timeout=timeout)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Bluetooth is unavailable")
    return re.sub(r"\x1b\[[0-9;]*[mK]", "", result.stdout)


def devices(kind: str) -> list[tuple[str, str]]:
    found = []
    for line in bluetoothctl("devices", kind).splitlines():
        match = re.match(r"^Device\s+([0-9A-Fa-f:]{17})\s+(.*)$", line.strip())
        if match:
            found.append((match.group(1).upper(), sanitize(match.group(2)) or match.group(1).upper()))
    return found


def powered() -> bool:
    match = re.search(r"^\s*Powered:\s*(yes|no)\s*$", bluetoothctl("show"), re.MULTILINE)
    if not match:
        raise RuntimeError("No Bluetooth controller found")
    return match.group(1) == "yes"


def notify(message: str) -> None:
    if shutil.which("notify-send"):
        run(["notify-send", "Bluetooth", sanitize(message)], timeout=3)


def choose(prompt: str, options: list[str]) -> str:
    if not shutil.which("fuzzel"):
        notify("Fuzzel is required")
        return ""
    try:
        result = subprocess.run(
            ["fuzzel", "--dmenu", "--prompt", f"{prompt}: "],
            input="\n".join(options),
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def refresh() -> None:
    if shutil.which("pkill"):
        run(["pkill", WAYBAR_SIGNAL, "waybar"], timeout=3)


def status() -> None:
    if not shutil.which("bluetoothctl"):
        output(ICON_OFF, "bluetoothctl is not installed", "error")
        return
    try:
        if not powered():
            output(ICON_OFF, "Bluetooth is off", "off")
            return
        connected = devices("Connected")
        paired = devices("Paired")
        connected_addresses = {address for address, _ in connected}
        lines = [f"Connected devices: {len(connected)}", f"Paired devices: {len(paired)}"]
        if connected:
            lines.extend(["", "Connected:"])
            lines.extend(markup(name) for _, name in connected)
        disconnected_paired = [(address, name) for address, name in paired if address not in connected_addresses]
        if disconnected_paired:
            lines.extend(["", "Paired:"])
            lines.extend(markup(name) for _, name in disconnected_paired[:8])
            if len(disconnected_paired) > 8:
                lines.append(f"…and {len(disconnected_paired) - 8} more")
        text = f"{ICON_CONNECTED} {len(connected)}" if connected else ICON_ON
        output(text, "\n".join(lines), "connected" if connected else "on")
    except RuntimeError as error:
        output(f"{ICON_OFF} !", markup(error), "error")


def toggle() -> None:
    try:
        is_powered = powered()
        action = "Turn Bluetooth off" if is_powered else "Turn Bluetooth on"
        if choose("Bluetooth power", ["Cancel", action]) != action:
            return
        bluetoothctl("power", "off" if is_powered else "on")
    except RuntimeError as error:
        notify(str(error))
    finally:
        refresh()


def connect() -> None:
    """Choose and connect a paired device that is not already connected."""
    try:
        if not powered():
            notify("Bluetooth is off; right-click to turn it on")
            return
        paired = devices("Paired")
        connected_addresses = {address for address, _ in devices("Connected")}
        options = {
            f"{name} ({address})": (address, name)
            for address, name in paired
            if address not in connected_addresses
        }
        if not options:
            notify("No disconnected paired devices; use Bluetui to pair a new device")
            return
        selected = choose("Connect Bluetooth", list(options))
        if selected not in options:
            return
        address, name = options[selected]
        try:
            bluetoothctl("connect", address, timeout=30)
            if address in {addr for addr, _ in devices("Connected")}:
                notify(f"Connected to {name}")
            else:
                notify(f"Failed to connect to {name}")
        finally:
            refresh()
    except RuntimeError as error:
        notify(str(error))


def main() -> None:
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "status":
        status()
    elif command == "toggle":
        toggle()
    elif command == "connect":
        connect()
    else:
        raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
