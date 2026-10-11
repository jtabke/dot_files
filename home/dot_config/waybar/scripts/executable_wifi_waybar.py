#!/usr/bin/env python3
"""Reliable iwd status and controls for Waybar."""

from __future__ import annotations

import html
import json
import re
import shutil
import subprocess
import sys

ICON = ""
WAYBAR_SIGNAL = "-RTMIN+6"


def sanitize(value: object) -> str:
    return re.sub(r"[\x00-\x1f\x7f]+", " ", str(value or "")).strip()


def markup(value: object) -> str:
    return html.escape(sanitize(value), quote=False)


def output(text: str, tooltip: str, css_class: str) -> None:
    print(json.dumps({"text": text, "tooltip": tooltip, "class": css_class}, ensure_ascii=False))


def run(args: list[str], timeout: float = 4) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(args, 124, "", "command timed out")
    except OSError as error:
        return subprocess.CompletedProcess(args, 126, "", str(error))


def busctl(*args: str) -> str:
    result = run(["busctl", "--system", *args])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "iwd is unavailable")
    return result.stdout.strip()


def parse_value(value: str) -> str:
    parts = value.strip().split(None, 1)
    if not parts:
        return ""
    if len(parts) == 1:
        return parts[0]
    rest = parts[1].strip()
    match = re.fullmatch(r'"(.*)"', rest)
    return match.group(1) if match else rest


def device_path() -> str:
    for line in busctl("tree", "net.connman.iwd").splitlines():
        fields = line.strip().split()
        if not fields:
            continue
        path = fields[-1]
        if not re.fullmatch(r"/net/connman/iwd/\d+/\d+", path):
            continue
        try:
            mode = parse_value(
                busctl("get-property", "net.connman.iwd", path, "net.connman.iwd.Device", "Mode")
            )
        except RuntimeError:
            continue
        if mode == "station":
            return path
    return ""


def property_value(path: str, interface: str, name: str) -> str:
    return parse_value(busctl("get-property", "net.connman.iwd", path, interface, name))


def ordered_networks(path: str) -> list[tuple[str, int]]:
    tokens = busctl(
        "call", "net.connman.iwd", path, "net.connman.iwd.Station", "GetOrderedNetworks"
    ).split()
    if len(tokens) < 2:
        return []
    try:
        count = int(tokens[1])
    except ValueError:
        return []
    networks = []
    for index in range(count):
        offset = 2 + index * 2
        if offset + 1 >= len(tokens):
            break
        try:
            networks.append((tokens[offset].strip('"'), int(tokens[offset + 1])))
        except ValueError:
            continue
    return networks


def ipv4_for(interface: str) -> str:
    result = run(["ip", "-4", "-brief", "address", "show", "dev", interface])
    if result.returncode != 0:
        return "n/a"
    match = re.search(r"\b(\d+\.\d+\.\d+\.\d+)/", result.stdout)
    return match.group(1) if match else "n/a"


def signal_text(raw: int) -> str:
    return f"{round(raw / 100)} dBm"


def notify(message: str) -> None:
    if shutil.which("notify-send"):
        run(["notify-send", "Wi-Fi", sanitize(message)], timeout=3)


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
    return result.stdout.strip()


def refresh() -> None:
    if shutil.which("pkill"):
        run(["pkill", WAYBAR_SIGNAL, "waybar"], timeout=3)


def status() -> None:
    if not shutil.which("busctl"):
        output(ICON, "busctl is not installed", "error")
        return
    try:
        path = device_path()
        if not path:
            output(f"{ICON} ?", "No iwd Wi-Fi device found", "error")
            return
        powered = property_value(path, "net.connman.iwd.Device", "Powered")
        if powered != "true":
            output(f"{ICON} off", "Wi-Fi is off", "off")
            return
        state = property_value(path, "net.connman.iwd.Station", "State")
        if state != "connected":
            output(ICON, f"Wi-Fi: {markup(state or 'unknown')}", "disconnected")
            return

        connected_path = property_value(path, "net.connman.iwd.Station", "ConnectedNetwork")
        ssid = "Wi-Fi"
        if connected_path:
            try:
                ssid = property_value(connected_path, "net.connman.iwd.Network", "Name") or ssid
            except RuntimeError:
                pass
        interface = property_value(path, "net.connman.iwd.Device", "Name")
        networks = []
        connected_signal = "n/a"
        for network_path, raw_signal in ordered_networks(path):
            try:
                name = property_value(network_path, "net.connman.iwd.Network", "Name")
            except RuntimeError:
                continue
            if network_path == connected_path:
                connected_signal = signal_text(raw_signal)
            elif name:
                networks.append((name, raw_signal))

        lines = [
            f"Connected: {markup(ssid)}",
            f"IPv4: {markup(ipv4_for(interface))}",
            f"Signal: {markup(connected_signal)}",
            f"Nearby networks: {len(networks)}",
        ]
        if networks:
            lines.extend(["", "Strongest nearby:"])
            for name, raw_signal in networks[:5]:
                lines.append(f"{markup(name)} · {markup(signal_text(raw_signal))}")
        output(f"{ICON} {markup(ssid)}", "\n".join(lines), "connected")
    except (RuntimeError, IndexError, ValueError) as error:
        output(f"{ICON} !", markup(error), "error")


def toggle() -> None:
    try:
        path = device_path()
        if not path:
            notify("No iwd Wi-Fi device found")
            return
        powered = property_value(path, "net.connman.iwd.Device", "Powered")
        turning_on = powered != "true"
        action = "Turn Wi-Fi on" if turning_on else "Turn Wi-Fi off"
        if choose("Wi-Fi power", ["Cancel", action]) != action:
            return
        busctl(
            "set-property",
            "net.connman.iwd",
            path,
            "net.connman.iwd.Device",
            "Powered",
            "b",
            "true" if turning_on else "false",
        )
    except RuntimeError as error:
        notify(str(error))
    finally:
        refresh()


def main() -> None:
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "status":
        status()
    elif command == "toggle":
        toggle()
    else:
        raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
