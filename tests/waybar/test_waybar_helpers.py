#!/usr/bin/env python3
import importlib.util
import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

SCRIPT_DIR = Path(__file__).resolve().parent


def load(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPT_DIR / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


wifi = load("wifi_waybar")
bluetooth = load("bluetooth_waybar")
power = load("power_menu")
updates = load("updates_waybar")


class WaybarHelperTests(unittest.TestCase):
    def test_wifi_external_text_is_safe_for_pango(self):
        self.assertEqual(wifi.markup("<bad & ssid>\n"), "&lt;bad &amp; ssid&gt;")

    def test_bluetooth_multiline_device_output_remains_valid_json(self):
        responses = {
            ("show",): "Powered: yes\n",
            ("devices", "Connected"): (
                "Device AA:BB:CC:DD:EE:01 Headphones\n"
                "Device AA:BB:CC:DD:EE:02 Keyboard\n"
            ),
            ("devices", "Paired"): (
                "Device AA:BB:CC:DD:EE:01 Headphones\n"
                "Device AA:BB:CC:DD:EE:02 Keyboard\n"
            ),
        }
        stream = io.StringIO()
        with mock.patch.object(bluetooth, "bluetoothctl", side_effect=lambda *args: responses[args]), mock.patch.object(
            bluetooth.shutil, "which", return_value="/usr/bin/bluetoothctl"
        ), redirect_stdout(stream):
            bluetooth.status()
        payload = json.loads(stream.getvalue())
        self.assertEqual(payload["class"], "connected")
        self.assertIn("Headphones\nKeyboard", payload["tooltip"])

    def test_bluetooth_names_are_pango_escaped(self):
        self.assertEqual(bluetooth.markup("<device & name>"), "&lt;device &amp; name&gt;")

    def test_bluetooth_connect_picker_outcomes(self):
        address = "AA:BB:CC:DD:EE:01"
        other = "AA:BB:CC:DD:EE:02"
        label = f"Headphones ({address})"
        for outcome in ("success", "failure", "error", "cancel", "custom"):
            with self.subTest(outcome=outcome), mock.patch.object(
                bluetooth, "powered", return_value=True
            ), mock.patch.object(
                bluetooth, "devices",
                side_effect=[[(address, "Headphones"), (other, "Headphones")],
                             [(other, "Headphones")],
                             [(address, "Headphones")] if outcome == "success" else []],
            ), mock.patch.object(
                bluetooth, "choose", return_value="" if outcome == "cancel" else
                "unlisted address" if outcome == "custom" else label
            ) as choose, mock.patch.object(
                bluetooth, "bluetoothctl",
                side_effect=RuntimeError("Connection timed out") if outcome == "error" else None,
            ) as ctl, mock.patch.object(bluetooth, "notify") as notify, mock.patch.object(
                bluetooth, "refresh"
            ) as refresh:
                bluetooth.connect()
                choose.assert_called_once_with("Connect Bluetooth", [label])
                if outcome in ("cancel", "custom"):
                    ctl.assert_not_called()
                    refresh.assert_not_called()
                    notify.assert_not_called()
                else:
                    ctl.assert_called_once_with("connect", address, timeout=30)
                    refresh.assert_called_once_with()
                    expected = {"success": "Connected to Headphones",
                                "failure": "Failed to connect to Headphones",
                                "error": "Connection timed out"}[outcome]
                    notify.assert_called_once_with(expected)

    def test_bluetooth_connect_without_candidates(self):
        for powered, error in ((False, None), (True, None), (True, RuntimeError("No controller"))):
            with self.subTest(powered=powered, error=error), mock.patch.object(
                bluetooth, "powered", return_value=powered, side_effect=error
            ), mock.patch.object(bluetooth, "devices", return_value=[]), mock.patch.object(
                bluetooth, "choose"
            ) as choose, mock.patch.object(bluetooth, "bluetoothctl") as ctl, mock.patch.object(
                bluetooth, "notify"
            ) as notify:
                bluetooth.connect()
                choose.assert_not_called()
                ctl.assert_not_called()
                notify.assert_called_once()

    def test_bluetooth_picker_ignores_cancelled_process_output(self):
        import subprocess
        with mock.patch.object(bluetooth.shutil, "which", return_value="/usr/bin/fuzzel"), mock.patch.object(
            bluetooth.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "some device", "")
        ):
            self.assertEqual(bluetooth.choose("Connect", ["some device"]), "")

    def test_bluetooth_main_dispatches_connect(self):
        with mock.patch.object(sys, "argv", ["bluetooth_waybar.py", "connect"]), mock.patch.object(
            bluetooth, "connect"
        ) as connect:
            bluetooth.main()
            connect.assert_called_once_with()

    def test_power_actions_except_lock_require_confirmation(self):
        with mock.patch.object(power, "choose", side_effect=["Shut down", "Cancel"]), mock.patch.object(
            power, "perform"
        ) as perform:
            power.menu()
            perform.assert_not_called()
        with mock.patch.object(
            power, "choose", side_effect=["Shut down", "Confirm shut down"]
        ), mock.patch.object(power, "perform") as perform:
            power.menu()
            perform.assert_called_once_with("poweroff")

    def test_update_status_uses_cache_without_blocking(self):
        cached = {"checked": 10**20, "packages": ["linux", "waybar"], "error": ""}
        stream = io.StringIO()
        with mock.patch.object(updates, "read_cache", return_value=cached), mock.patch.object(
            updates, "launch_refresh"
        ) as launch, redirect_stdout(stream):
            updates.status()
        payload = json.loads(stream.getvalue())
        self.assertEqual(payload["class"], "updates")
        self.assertEqual(payload["text"], "󰏖 2")
        launch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
