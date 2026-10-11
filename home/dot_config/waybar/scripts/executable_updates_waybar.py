#!/usr/bin/env python3
"""Non-blocking Arch update status and updater launcher for Waybar."""

from __future__ import annotations

import html
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

SIGNAL = "-RTMIN+9"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "waybar"
CACHE_FILE = CACHE_DIR / "updates.json"
LOCK_FILE = CACHE_DIR / "updates.lock"
MAX_AGE = 3600


def sanitize(value: object) -> str:
    return re.sub(r"[\x00-\x1f\x7f]+", " ", str(value or "")).strip()


def output(text: str, tooltip: str, css_class: str) -> None:
    print(json.dumps({"text": text, "tooltip": tooltip, "class": css_class}, ensure_ascii=False))


def read_cache() -> dict:
    try:
        data = json.loads(CACHE_FILE.read_text())
        return data if isinstance(data, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def write_cache(data: dict) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    temporary = CACHE_FILE.with_suffix(".tmp")
    temporary.write_text(json.dumps(data))
    temporary.replace(CACHE_FILE)


def signal_waybar() -> None:
    subprocess.run(
        ["pkill", SIGNAL, "waybar"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def render(data: dict) -> None:
    packages = [sanitize(package) for package in data.get("packages", []) if sanitize(package)]
    error = sanitize(data.get("error"))
    if not data:
        output("󰏖 …", "Checking for updates…", "checking")
        return
    if error and not packages:
        output("󰏖 !", html.escape(error, quote=False), "error")
        return
    if not packages:
        output("󰏖", "System is up to date", "none")
        return
    preview = packages[:12]
    tooltip = f"{len(packages)} updates available:\n" + "\n".join(
        html.escape(package, quote=False) for package in preview
    )
    if len(packages) > len(preview):
        tooltip += f"\n…and {len(packages) - len(preview)} more"
    if error:
        tooltip += f"\n\nLast refresh error: {html.escape(error, quote=False)}"
    tooltip += "\n\nClick to update · right-click to refresh"
    output(f"󰏖 {len(packages)}", tooltip, "updates")


def launch_refresh() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    if LOCK_FILE.exists():
        try:
            if time.time() - LOCK_FILE.stat().st_mtime < 600:
                return
            LOCK_FILE.unlink()
        except OSError:
            return
    try:
        subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve()), "refresh"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        return


def status() -> None:
    data = read_cache()
    checked = float(data.get("checked", 0) or 0)
    if time.time() - checked >= MAX_AGE:
        launch_refresh()
    render(data)


def refresh() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        descriptor = os.open(LOCK_FILE, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        os.close(descriptor)
    except FileExistsError:
        return
    old = read_cache()
    try:
        if not shutil.which("checkupdates"):
            data = {"checked": time.time(), "packages": [], "error": "checkupdates is not installed"}
        else:
            try:
                result = subprocess.run(
                    ["checkupdates", "--nocolor"],
                    capture_output=True,
                    text=True,
                    timeout=180,
                    check=False,
                )
                if result.returncode in {0, 2}:
                    packages = [line.split()[0] for line in result.stdout.splitlines() if line.strip()]
                    data = {"checked": time.time(), "packages": packages, "error": ""}
                else:
                    data = {
                        "checked": time.time(),
                        "packages": old.get("packages", []),
                        "error": result.stderr.strip() or "Could not check for updates",
                    }
            except (OSError, subprocess.TimeoutExpired) as error:
                data = {
                    "checked": time.time(),
                    "packages": old.get("packages", []),
                    "error": str(error),
                }
        write_cache(data)
    finally:
        try:
            LOCK_FILE.unlink()
        except OSError:
            pass
        signal_waybar()


def upgrade() -> None:
    terminal = ["ghostty"]
    if not terminal or not shutil.which(terminal[0]):
        return
    script = shlex.quote(str(Path(__file__).resolve()))
    shell_command = (
        "sudo pacman -Syu; result=$?; "
        f"{script} launch-refresh; "
        "printf '\\nPress Enter to close…'; read -r; exit $result"
    )
    try:
        subprocess.Popen(
            [*terminal, "-e", "bash", "-lc", shell_command],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        return


def main() -> None:
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "status":
        status()
    elif command == "launch-refresh":
        launch_refresh()
    elif command == "refresh":
        refresh()
    elif command == "upgrade":
        upgrade()
    else:
        raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
