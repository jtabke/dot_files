#!/usr/bin/env python3
"""Confirmed session and power actions for Waybar."""

from __future__ import annotations

import os
import shutil
import subprocess
import time
from pathlib import Path

ACTIONS = {
    "Lock": "lock",
    "Suspend": "suspend",
    "Log out": "logout",
    "Reboot": "reboot",
    "Shut down": "poweroff",
}


def run(args: list[str], timeout: float = 10) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(args, 124, "", "command timed out")
    except OSError as error:
        return subprocess.CompletedProcess(args, 126, "", str(error))


def notify(message: str) -> None:
    if shutil.which("notify-send"):
        run(["notify-send", "Power", message[:1000]], timeout=3)


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


def lock_session() -> bool:
    if run(["pgrep", "-x", "hyprlock"], timeout=3).returncode == 0:
        return True
    if not shutil.which("hyprlock"):
        notify("hyprlock is not installed")
        return False

    config = Path.home() / ".config/hypr/hyprlock.conf"
    command = ["hyprlock", "--grace", "0", "--immediate-render"]
    if config.exists():
        command.extend(["--config", str(config)])
    log_path = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "hyprlock.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with log_path.open("ab") as log:
            process = subprocess.Popen(
                command,
                stdout=log,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
    except OSError as error:
        notify(f"Could not start hyprlock: {error}")
        return False

    time.sleep(0.75)
    if process.poll() is None:
        return True
    try:
        details = log_path.read_text(errors="replace").splitlines()[-1]
    except (OSError, IndexError):
        details = "hyprlock exited immediately"
    notify(details)
    return False


def perform(action: str) -> None:
    if action == "lock":
        lock_session()
        return
    if action == "suspend":
        if not lock_session():
            return
        time.sleep(0.5)
        command = ["systemctl", "suspend"]
    elif action == "logout":
        command = ["hyprctl", "dispatch", "exit"]
    elif action == "reboot":
        command = ["systemctl", "reboot"]
    elif action == "poweroff":
        command = ["systemctl", "poweroff"]
    else:
        return

    result = run(command, timeout=15)
    if result.returncode != 0:
        notify(result.stderr.strip() or result.stdout.strip() or f"Could not {action}")


def menu() -> None:
    selection = choose("Session", list(ACTIONS))
    if not selection:
        return
    action = ACTIONS.get(selection)
    if not action:
        return
    if action != "lock":
        confirmation = f"Confirm {selection.lower()}"
        if choose("Are you sure?", ["Cancel", confirmation]) != confirmation:
            return
    perform(action)


def main() -> None:
    command = os.sys.argv[1] if len(os.sys.argv) > 1 else "menu"
    if command == "menu":
        menu()
    elif command == "lock":
        perform("lock")
    else:
        raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
