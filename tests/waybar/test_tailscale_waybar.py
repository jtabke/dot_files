#!/usr/bin/env python3
import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import tailscale_waybar as module


class TailscaleWaybarTests(unittest.TestCase):
    def test_external_text_is_sanitized_and_markup_escaped(self):
        self.assertEqual(module.sanitize("peer\nname\t"), "peer name")
        self.assertEqual(module.markup("<peer & friend>"), "&lt;peer &amp; friend&gt;")

    def test_auth_url_allowlist(self):
        self.assertEqual(
            module.safe_auth_url("https://login.tailscale.com/a/example"),
            "https://login.tailscale.com/a/example",
        )
        self.assertEqual(module.safe_auth_url("http://login.tailscale.com/a/example"), "")
        self.assertEqual(module.safe_auth_url("file:///tmp/example"), "")
        self.assertEqual(module.safe_auth_url("https://tailscale.com.evil.test/a/example"), "")

    def test_run_converts_oserror_to_a_result(self):
        with mock.patch.object(module.subprocess, "run", side_effect=PermissionError("denied")):
            result = module.run(["tailscale", "status"])
        self.assertIsNotNone(result)
        self.assertEqual(result.returncode, 126)
        self.assertIn("denied", result.stderr)

    def test_connection_labels_distinguish_idle_direct_and_relay(self):
        self.assertEqual(module.connection_label({"Online": True, "Active": False, "Relay": "lax"}), "idle")
        self.assertEqual(
            module.connection_label({"Active": True, "CurAddr": "192.0.2.1:123", "Relay": "lax"}),
            "direct 192.0.2.1:123",
        )
        self.assertEqual(module.connection_label({"Active": True, "CurAddr": "", "Relay": "lax"}), "relay lax")

    def test_minimal_running_status_produces_json(self):
        status = {
            "BackendState": "Running",
            "TailscaleIPs": ["100.64.0.1"],
            "Self": {"HostName": "local"},
            "Peer": {},
        }
        output = io.StringIO()
        with mock.patch.object(module.shutil, "which", return_value="/usr/bin/tailscale"), mock.patch.object(
            module, "get_status", return_value=(status, "")
        ), redirect_stdout(output):
            module.status_command()
        payload = json.loads(output.getvalue())
        self.assertEqual(payload["class"], "connected")
        self.assertIn("0/0 online", payload["tooltip"])

    def test_exit_node_change_requires_confirmation(self):
        peer = {
            "HostName": "exit",
            "TailscaleIPs": ["100.64.0.2"],
            "ExitNodeOption": True,
            "ExitNode": False,
        }
        status = {"Peer": {"peer-key": peer}}
        with mock.patch.object(module, "choose", side_effect=["Use exit", "Cancel"]), mock.patch.object(
            module, "run_tailscale_action"
        ) as action:
            module.exit_node_menu(status)
            action.assert_not_called()

        with mock.patch.object(
            module, "choose", side_effect=["Use exit", "Confirm: Use exit"]
        ), mock.patch.object(module, "run_tailscale_action") as action:
            module.exit_node_menu(status)
            action.assert_called_once_with(
                ["set", "--exit-node=100.64.0.2"], "Changing exit node"
            )

    def test_operator_hint_handles_not_permitted(self):
        result = module.subprocess.CompletedProcess([], 1, "", "operation not permitted")
        self.assertIn("tailscale set --operator=", module.command_error(result, "Changing settings"))


if __name__ == "__main__":
    unittest.main()
