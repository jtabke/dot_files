#!/usr/bin/env python3
"""Setup regression tests: no real package manager, network, or live-home writes."""
import json
import os
import pty
import select
import shlex
import time
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
CHEZMOI = subprocess.check_output(["/bin/sh", "-c", "command -v chezmoi"], text=True).strip()


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.home = self.root / "home"
        self.home.mkdir()
        self.receipt = self.root / "manager.log"
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin),
                        RECEIPT=str(self.receipt), FIXTURE=str(self.root), SHELL="/bin/bash")
        for name in ("git", "vim", "stylua", "prettier", "zsh", "rg", "cc", "make", "curl", "unzip", "npm"):
            self.command(name)
        for name, version in {"nvim": "0.11.3", "tmux": "3.5a", "fzf": "0.48.0", "node": "v22.0.0"}.items():
            self.command(name, f"printf '%s\\n' '{version}'\n")
        self.command("sudo", 'exec "$@"\n')
        # Managers are all mocks, including brew to prevent absolute-path fallback.
        for name in ("brew", "apt-get", "pacman"):
            self.command(name, 'if [ "$1" = shellenv ]; then\n'
                         '  printf \'export PATH="%s:$PATH"\\n\' "${0%/*}"\n  exit 0\nfi\n'
                         + f'printf "%s\\n" "{name} $*" >> "$RECEIPT"\n/bin/cp "$FIXTURE/git-lfs" "$FIXTURE/bin/git-lfs"\n')
        (self.root / "git-lfs").write_text("#!/bin/sh\nexit 0\n")
        (self.root / "git-lfs").chmod(0o755)

    def command(self, name, body="exit 0\n"):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    def data(self, **extra):
        data = {"chezmoi": {"os": "linux", "kernel": {"osrelease": "6.1-WSL2"}},
                "role": "shell", "desktop": "none", "installPackages": True, "osReleaseID": "ubuntu"}
        data.update(extra)
        return data

    def render(self, data=None, target="home/dot_local/bin/executable_dotfiles-setup.tmpl"):
        return subprocess.check_output(
            [CHEZMOI, "--source", str(REPO), "--config", str(self.root / "config.toml"),
             "--cache", str(self.root / "cache"), "--persistent-state", str(self.root / "state"),
             "--no-tty", "--override-data", json.dumps(data or self.data()),
             "execute-template", "--file", str(REPO / target)], text=True)

    def run_setup(self, *args, data=None):
        script = self.root / "setup.sh"
        script.write_text(self.render(data))
        return subprocess.run(["/bin/bash", str(script), *args], env=self.env,
                              input="", text=True, capture_output=True)

    def test_plan_and_check_never_install(self):
        result = self.run_setup("--plan")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Missing packages: git-lfs", result.stdout)
        self.assertIn("WSL: true", result.stdout)
        self.assertFalse(self.receipt.exists())
        self.assertNotEqual(self.run_setup("--check").returncode, 0)
        self.assertFalse(self.receipt.exists())

    def run_guided(self, replies, install=True, fail_apply=False, fresh=False, revise=False):
        if not fresh:
            (self.root / "config.toml").write_text(
                '[data]\nrole="shell"\ndesktop="none"\ninstallPackages=' + str(install).lower()
                + '\nautoTmux=false\nisWSL=false\nosReleaseID="ubuntu"\n')
        for name in ("dirname", "mktemp", "rm"):
            (self.bin / name).symlink_to(shutil.which(name))
        self.command("chezmoi", 'printf "%s\\n" "$*" >> "$FIXTURE/chezmoi.log"\n'
                     + ('case " $* " in *" apply "*) exit 9 ;; esac\n' if fail_apply else '')
                     + f'exec "{CHEZMOI}" --destination "$HOME" --config "$FIXTURE/config.toml" '
                     '--cache "$FIXTURE/cache" --persistent-state "$FIXTURE/state" --no-tty "$@"\n')
        master, slave = pty.openpty()
        process = subprocess.Popen(["/bin/bash", str(REPO / "setup")], env=self.env, cwd=self.root,
                                   stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        output = ""
        pending = ([] if fresh else [("Change saved setup choices?", "y" if revise else "n")]) + list(replies)
        deadline = time.monotonic() + 30
        try:
            while time.monotonic() < deadline:
                ready, _, _ = select.select([master], [], [], 0.1)
                if ready:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError:
                        break  # PTY closes with EIO after the child exits.
                    if not chunk:
                        break
                    output += chunk.decode(errors="replace")
                    if pending and pending[0][0] in output:
                        _, answer = pending.pop(0)
                        os.write(master, (answer + "\n").encode())
                elif process.poll() is not None:
                    break
            self.assertIsNotNone(process.poll() if process.poll() is not None else process.wait(timeout=2), output[-3000:])
            self.assertFalse(pending, output[-3000:])
            return process.returncode, output
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)

    def test_guided_fresh_home_initializes_before_preview(self):
        replies = []
        kernel = os.uname().release.lower()
        if "wsl" not in kernel and "microsoft" not in kernel:
            replies.append(("Machine role", "shell"))
        replies += [("Install missing packages during apply?", "false"),
                    ("Automatically open or reconnect to tmux (including SSH)?", "false"),
                    ("Apply the configuration changes shown above?", "n")]
        status, output = self.run_guided(replies, fresh=True)
        self.assertEqual(status, 0, output[-3000:])
        self.assertIn('desktop = "none"', (self.root / "config.toml").read_text())
        self.assertIn("Review the setup plan", output)
        self.assertFalse((self.home / ".zshenv").exists())
        self.assertFalse(self.receipt.exists())

    def test_guided_can_revise_saved_choices(self):
        replies = []
        kernel = os.uname().release.lower()
        if "wsl" not in kernel and "microsoft" not in kernel:
            replies += [("Machine role", "workstation"), ("Desktop environment", "none")]
        replies += [("Install missing packages during apply?", "false"),
                    ("Automatically open or reconnect to tmux (including SSH)?", "true"),
                    ("Apply the configuration changes shown above?", "n")]
        status, output = self.run_guided(replies, revise=True)
        self.assertEqual(status, 0, output[-3000:])
        config = (self.root / "config.toml").read_text()
        self.assertIn("autoTmux = true", config)
        self.assertIn("installPackages = false", config)
        self.assertIn("init --prompt", (self.root / "chezmoi.log").read_text())
        self.assertFalse((self.home / ".zshenv").exists())
        self.assertFalse(self.receipt.exists())

    def test_guided_decline_config_never_applies_or_installs(self):
        status, output = self.run_guided([("Apply the configuration changes shown above?", "")])
        self.assertEqual(status, 0, output[-3000:])
        self.assertIn("Cancelled", output)
        self.assertFalse((self.home / ".zshenv").exists())
        self.assertFalse(self.receipt.exists())
        self.assertNotIn(" apply ", (self.root / "chezmoi.log").read_text())

    def test_guided_config_approval_does_not_approve_packages(self):
        status, output = self.run_guided([("Apply the configuration changes shown above?", "y"),
                                          ("Install these missing packages now?", "n")])
        self.assertEqual(status, 0, output[-3000:])
        self.assertTrue((self.home / ".zshenv").exists())
        self.assertTrue((self.home / ".local/bin/dotfiles-setup").exists())
        self.assertFalse(self.receipt.exists())
        self.assertIn("apply --exclude scripts", (self.root / "chezmoi.log").read_text())
        self.assertIn("Final checklist", output)
        self.assertIn("NEEDS ACTION", output)

    def test_guided_separate_package_approval(self):
        status, output = self.run_guided([("Apply the configuration changes shown above?", "yes"),
                                          ("Install these missing packages now?", "y")])
        self.assertEqual(status, 0, output[-3000:])
        self.assertTrue((self.home / ".zshenv").exists())
        commands = self.receipt.read_text().splitlines()
        self.assertEqual(len(commands), 1)
        self.assertIn(shlex.split(commands[0]), [
            ["brew", "install", "git-lfs"],
            ["apt-get", "install", "-y", "--no-install-recommends", "git-lfs"],
            ["pacman", "-S", "--needed", "--noconfirm", "--", "git-lfs"],
        ])
        self.assertIn("checked dependencies are ready", output)

    def test_guided_disabled_packages_skips_package_prompt(self):
        status, output = self.run_guided([("Apply the configuration changes shown above?", "y")], install=False)
        self.assertEqual(status, 0, output[-3000:])
        self.assertIn("Package installation is disabled", output)
        self.assertNotIn("Install these missing packages now?", output)
        self.assertFalse(self.receipt.exists())

    def test_guided_apply_failure_stops_before_packages(self):
        status, output = self.run_guided([("Apply the configuration changes shown above?", "y")], fail_apply=True)
        self.assertEqual(status, 9, output[-3000:])
        self.assertFalse(self.receipt.exists())
        self.assertNotIn("Install these missing packages now?", output)

    def test_guided_package_failure_reports_partial_setup(self):
        for name in ("brew", "apt-get", "pacman"):
            self.command(name, 'if [ "$1" = shellenv ]; then exit 0; fi\necho denied >&2\nexit 7\n')
        status, output = self.run_guided([("Apply the configuration changes shown above?", "y"),
                                          ("Install these missing packages now?", "y")])
        self.assertEqual(status, 7, output[-3000:])
        self.assertTrue((self.home / ".zshenv").exists())
        self.assertIn("Configs were already applied", output)

    def test_guided_noninteractive_refuses_before_init(self):
        self.command("chezmoi", 'echo called > "$FIXTURE/unexpected-init"\n')
        result = subprocess.run(["/bin/bash", str(REPO / "setup")], env=self.env, input="", text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("interactive terminal", result.stderr)
        self.assertFalse((self.root / "unexpected-init").exists())

    def test_guided_rejects_automatic_approval_before_init(self):
        self.command("chezmoi", 'echo called > "$FIXTURE/unexpected-init"\n')
        result = subprocess.run(["/bin/bash", str(REPO / "setup"), "--yes"], env=self.env, input="", text=True, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.root / "unexpected-init").exists())

    def test_repo_helper_works_before_applying(self):
        config = self.root / "config" / "chezmoi"
        config.mkdir(parents=True)
        (config / "chezmoi.toml").write_text('[data]\nrole="shell"\ndesktop="none"\ninstallPackages=false\nosReleaseID="ubuntu"\n')
        for name in ("dirname", "mktemp", "rm", "bash"):
            (self.bin / name).symlink_to(shutil.which(name))
        (self.bin / "chezmoi").symlink_to(CHEZMOI)
        env = dict(self.env, XDG_CONFIG_HOME=str(self.root / "config"), XDG_CACHE_HOME=str(self.root / "cache"))
        result = subprocess.run(["/bin/bash", str(REPO / "scripts/setup.sh"), "--plan"],
                                env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Package installation enabled: false", result.stdout)
        self.assertFalse(self.receipt.exists())

    def test_noninteractive_install_requires_explicit_approval(self):
        result = self.run_setup("--install")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("interactive approval", result.stderr)
        self.assertFalse(self.receipt.exists())

    def test_disabled_install_cannot_be_bypassed_by_yes(self):
        result = self.run_setup("--install", "--yes", data=self.data(installPackages=False))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("disabled", result.stderr)
        self.assertFalse(self.receipt.exists())

    def test_adapters_only_install_missing_packages(self):
        for os_name, distro, manager, flags in [("linux", "ubuntu", "apt-get", "install -y --no-install-recommends"),
                                                 ("linux", "arch", "pacman", "-S --needed --noconfirm --"),
                                                 ("darwin", "", "brew", "install")]:
            with self.subTest(manager=manager):
                (self.bin / "git-lfs").unlink(missing_ok=True)
                self.receipt.unlink(missing_ok=True)
                data = self.data(chezmoi={"os": os_name, "kernel": {"osrelease": "6.8"}}, osReleaseID=distro)
                result = self.run_setup("--install", "--yes", data=data)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(self.receipt.read_text().strip(), f"{manager} {flags} git-lfs")
                self.assertNotIn("fuzzel", self.receipt.read_text())

    def test_adapter_failure_propagates(self):
        self.command("apt-get", 'echo denied >&2\nexit 7\n')
        result = self.run_setup("--install", "--yes")
        self.assertEqual(result.returncode, 7, result.stderr)

    def test_old_and_unknown_versions_are_not_ready(self):
        self.command("git-lfs")
        for command, version in [("tmux", "3.4"), ("fzf", "0.47.0"),
                                 ("nvim", "0.10.4"), ("node", "v20.0.0"), ("tmux", "unknown")]:
            with self.subTest(command=command, version=version):
                original = (self.bin / command).read_text()
                self.command(command, f"echo '{version}'\n")
                result = self.run_setup("--check")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(f"NEEDS ACTION: {command} >=", result.stdout)
                (self.bin / command).write_text(original)
        self.assertFalse(self.receipt.exists())

    def test_linuxbrew_reports_missing_system_compiler(self):
        for name in ("cc", "apt-get", "pacman"):
            (self.bin / name).unlink()
        result = self.run_setup("--plan")
        self.assertIn("adapter: brew", result.stdout)
        self.assertIn("NEEDS ACTION: cc", result.stdout)
        self.assertFalse(self.receipt.exists())

    def test_homebrew_shellenv_discovers_off_path_tools(self):
        self.command("git-lfs")
        prefix = self.root / "brew prefix" / "bin"
        prefix.mkdir(parents=True)
        for command in ("brew", "nvim", "node", "npm", "vim", "stylua", "prettier"):
            (self.bin / command).rename(prefix / command)
        # An older command on the original PATH must not shadow the selected prefix.
        self.command("nvim", "echo 0.9.5\n")
        rendered = self.render(self.data(chezmoi={"os": "darwin", "kernel": {"osrelease": "24"}}))
        rendered = rendered.replace("/opt/homebrew/bin/brew", shlex.quote(str(prefix / "brew")))
        rendered = rendered.replace("/usr/local/bin/brew", shlex.quote(str(self.root / "no-intel-brew")))
        script = self.root / "off-path-brew.sh"
        script.write_text(rendered)
        result = subprocess.run(["/bin/bash", str(script), "--check"], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Missing packages: none", result.stdout)
        self.assertIn("OK: nvim 0.11.3", result.stdout)
        self.assertFalse(self.receipt.exists())

    def test_homebrew_shellenv_failure_stops_before_install(self):
        self.command("brew", "exit 13\n")
        result = self.run_setup("--install", "--yes", data=self.data(chezmoi={"os": "darwin", "kernel": {"osrelease": "24"}}))
        self.assertEqual(result.returncode, 13)
        self.assertFalse(self.receipt.exists())

    def test_arch_installs_vim_and_configured_formatters(self):
        self.command("git-lfs")
        for command in ("vim", "stylua", "prettier"):
            (self.bin / command).unlink()
        (self.root / "tool").write_text("#!/bin/sh\nexit 0\n")
        (self.root / "tool").chmod(0o755)
        self.command("pacman", 'printf "%s\\n" "$*" > "$RECEIPT"\n'
                     'for tool in vim stylua prettier; do /bin/cp "$FIXTURE/tool" "$FIXTURE/bin/$tool"; done\n')
        self.command("brew", "exit 99\n")  # Arch must not initialize an unrelated Homebrew.
        result = self.run_setup("--install", "--yes", data=self.data(osReleaseID="arch"))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.receipt.read_text().strip(), "-S --needed --noconfirm -- vim stylua prettier")

    def test_pi_https_extension_filter_preserves_wsl_behavior(self):
        source = self.root / "pi-source"
        templates = source / ".chezmoitemplates"
        templates.mkdir(parents=True)
        extensions = "git:github.com/jtabke/pi-extensions"
        companion = "git:github.com/jtabke/pi-companion"
        (templates / "pi-settings.json").write_text(json.dumps({"packages": [extensions, companion]}))
        for wsl in (False, True):
            override = {"isWSL": wsl, "chezmoi": {"stdin": json.dumps({"deviceId": "device-sentinel"})}}
            rendered = subprocess.check_output(
                [CHEZMOI, "--source", str(source), "--config", str(self.root / "pi-config.toml"),
                 "--cache", str(self.root / "pi-cache"), "--persistent-state", str(self.root / "pi-state"),
                 "--no-tty", "--override-data", json.dumps(override), "execute-template", "--file",
                 str(REPO / "home/dot_pi/private_agent/modify_settings.json")], text=True)
            settings = json.loads(rendered)
            expected = [{"source": extensions, "extensions": ["!extensions/ollama*/**"]}] if wsl else [extensions, companion]
            self.assertEqual(settings["packages"], expected)
            self.assertEqual(settings["deviceId"], "device-sentinel")

    def test_auto_tmux_preference_is_independent_of_machine_role(self):
        for role in ("shell", "workstation"):
            for enabled in (True, False):
                with self.subTest(role=role, enabled=enabled):
                    rendered = self.render(self.data(role=role, autoTmux=enabled), "home/dot_config/zsh/90-tmux.zsh.tmpl")
                    self.assertEqual("tmux new-session" in rendered, enabled)
                    if enabled:
                        for guard in ('-t 1', '-z "${TMUX-}"', '-z "${CI-}"'):
                            self.assertIn(guard, rendered)

    @unittest.skipUnless(shutil.which("zsh"), "zsh not installed")
    def test_editor_fallback_uses_real_programs_without_aliases(self):
        command = [shutil.which("zsh"), "-fc", 'source "$1"; print -r -- "$EDITOR"',
                   "--", str(REPO / "home/dot_zshenv")]
        env = dict(self.env)
        env.pop("EDITOR", None)
        self.assertEqual(subprocess.check_output(command, env=env, text=True).strip(), "nvim")
        (self.bin / "nvim").unlink()
        self.assertEqual(subprocess.check_output(command, env=env, text=True).strip(), "vim")
        (self.bin / "vim").unlink()
        self.assertEqual(subprocess.check_output(command, env=env, text=True).strip(), "vi")
        source = (REPO / "home/dot_config/zsh/30-platform.zsh").read_text()
        self.assertNotIn("alias vi=", source)
        self.assertNotIn("alias vim=", source)

    @unittest.skipUnless(shutil.which("nvim"), "Neovim not installed")
    def test_native_nvim_lsp_configuration_without_plugin_downloads(self):
        env = dict(os.environ, HOME=str(self.home), DOTFILES_REPO=str(REPO),
                   XDG_CONFIG_HOME=str(self.root / "config"), XDG_CACHE_HOME=str(self.root / "cache"),
                   XDG_DATA_HOME=str(self.root / "data"), XDG_STATE_HOME=str(self.root / "state"))
        result = subprocess.run([shutil.which("nvim"), "--headless", "-u", "NONE", "-i", "NONE", "-l",
                                 str(REPO / "tests/test-nvim-lsp.lua")], env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Native LSP configuration checks passed", result.stdout + result.stderr)

    def test_git_respects_editor_environment(self):
        env = dict(os.environ, HOME=str(self.home), GIT_CONFIG_NOSYSTEM="1", EDITOR="vim",
                   GIT_CONFIG_GLOBAL=str(REPO / "home/dot_gitconfig.tmpl"))
        env.pop("GIT_EDITOR", None)
        env.pop("VISUAL", None)
        result = subprocess.check_output([shutil.which("git"), "var", "GIT_EDITOR"],
                                         cwd=self.root, env=env, text=True)
        self.assertEqual(result.strip(), "vim")

    def test_no_missing_packages_does_not_ask_or_install(self):
        self.command("git-lfs")
        result = self.run_setup("--install")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.receipt.exists())

    def test_apply_disabled_is_advisory(self):
        script = self.root / "apply.sh"
        script.write_text(self.render(self.data(installPackages=False), "home/run_onchange_install-packages.sh.tmpl"))
        result = subprocess.run(["/bin/bash", str(script)], env=self.env, input="", text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Package installation enabled: false", result.stdout)
        self.assertFalse(self.receipt.exists())
        script.write_text(self.render(self.data(installPackages=False), "home/run_after_setup-readiness.sh.tmpl"))
        result = subprocess.run(["/bin/bash", str(script)], env=self.env, input="", text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Readiness:", result.stdout)
        self.assertFalse(self.receipt.exists())

    def test_desktop_dependencies_reported_not_installed(self):
        result = self.run_setup("--plan", data=self.data(
            chezmoi={"os": "linux", "kernel": {"osrelease": "6.8"}}, role="workstation", desktop="hyprland"))
        self.assertIn("fuzzel", result.stdout)
        self.assertIn("NEEDS ACTION: Hyprland", result.stdout)
        self.assertIn("NEEDS ACTION: busctl", result.stdout)
        self.assertIn("update actions are Arch-specific", result.stdout)
        self.assertFalse(self.receipt.exists())

    def test_declining_interactive_install_never_calls_manager(self):
        script = self.root / "interactive.sh"
        script.write_text(self.render())
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(["/bin/bash", str(script), "--install"], env=self.env,
                                       stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            os.write(master, b"n\n")
            stdout, stderr = process.communicate(timeout=15)
            self.assertNotEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("cancelled", stdout)
            self.assertFalse(self.receipt.exists())
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_duplicate_node_package_is_only_installed_once(self):
        (self.bin / "node").unlink()
        (self.bin / "npm").unlink()
        result = self.run_setup("--plan", data=self.data(chezmoi={"os": "darwin", "kernel": {"osrelease": "24"}}))
        self.assertIn("Missing packages: git-lfs node\n", result.stdout)
        self.assertFalse(self.receipt.exists())

    def test_unsupported_platform_does_not_install(self):
        result = self.run_setup("--install", "--yes", data=self.data(chezmoi={"os": "freebsd", "kernel": {"osrelease": "14"}}))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No supported", result.stderr)
        self.assertFalse(self.receipt.exists())

    @unittest.skipUnless(shutil.which("zsh"), "zsh not installed")
    def test_environment_preserves_user_choices_and_avoids_gui_defaults(self):
        command = [shutil.which("zsh"), "-fc", 'source "$1"; print -r -- "$EDITOR|${BROWSER-}|${TERMINAL-}"',
                   "--", str(REPO / "home/dot_zshenv")]
        env = dict(self.env, EDITOR="custom-editor", BROWSER="custom-browser", TERMINAL="custom-terminal")
        result = subprocess.check_output(command, env=env, text=True)
        self.assertEqual(result.strip(), "custom-editor|custom-browser|custom-terminal")
        for key in ("EDITOR", "BROWSER", "TERMINAL", "DISPLAY", "WAYLAND_DISPLAY"):
            env.pop(key, None)
        result = subprocess.check_output(command, env=env, text=True)
        self.assertNotIn("firefox", result)
        self.assertNotIn("ghostty", result)

    @unittest.skipUnless(shutil.which("tmux"), "tmux not installed")
    def test_tmux_config_loads_on_isolated_server(self):
        tmux = shutil.which("tmux")
        socket = str(self.root / "tmux.sock")
        args = [tmux, "-S", socket, "-f", str(REPO / "home/dot_tmux.conf")]
        try:
            result = subprocess.run(args + ["new-session", "-d", "-s", "setup-test", "/bin/sleep 20"],
                                    env=dict(os.environ, HOME=str(self.home)), text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stderr, "")
        finally:
            subprocess.run([tmux, "-S", socket, "kill-server"], capture_output=True)

    def test_init_only_asks_relevant_questions(self):
        for os_name, kernel, role, desktop in [("linux", "6.1-WSL2", None, None),
                                                ("linux", "5.15-MICROSOFT", None, None),
                                                ("linux", "6.8", "shell", None),
                                                ("darwin", "24", "workstation", "aerospace"),
                                                ("linux", "6.8", "workstation", "hyprland")]:
            with self.subTest(os=os_name, kernel=kernel, role=role):
                args = [CHEZMOI, "--source", str(REPO), "--config", str(self.root / "new.toml"),
                        "--cache", str(self.root / "cache"), "--persistent-state", str(self.root / "state"),
                        "--no-tty", "--override-data", json.dumps({"chezmoi": {"os": os_name, "kernel": {"osrelease": kernel}}}),
                        "execute-template", "--init", "--promptBool", "Install missing packages during apply?=false,Automatically open or reconnect to tmux (including SSH)?=false"]
                choices = []
                if role:
                    choices.append("Machine role=" + role)
                if desktop:
                    choices.append("Desktop environment=" + desktop)
                if choices:
                    args += ["--promptChoice", ",".join(choices)]
                args += ["--file", str(REPO / "home/.chezmoi.toml.tmpl")]
                result = subprocess.run(args, text=True, input="", capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f'role = "{role or "shell"}"', result.stdout)
                self.assertIn(f'desktop = "{desktop or "none"}"', result.stdout)


if __name__ == "__main__":
    unittest.main()
