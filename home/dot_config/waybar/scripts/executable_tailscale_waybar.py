#!/usr/bin/env python3
"""Waybar status and interactive controls for Tailscale."""

from __future__ import annotations

import html
import json
import math
import os
import re
import shutil
import subprocess
from datetime import datetime, timezone
from urllib.parse import quote, urlparse

ICON = "󰖂"
ADMIN_URL = "https://login.tailscale.com/admin/machines"
WAYBAR_SIGNAL = "-RTMIN+8"


def notify(message: str) -> None:
    if not shutil.which("notify-send"):
        return
    try:
        subprocess.run(
            ["notify-send", "Tailscale", sanitize(message)[:1000]],
            check=False,
            timeout=3,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass


def sanitize(value: object) -> str:
    """Keep external names safe for Wofi labels and notifications."""
    return re.sub(r"[\x00-\x1f\x7f]+", " ", str(value or "")).strip()


def markup(value: object) -> str:
    """Escape external values before Waybar treats the tooltip as Pango markup."""
    return html.escape(sanitize(value), quote=False)


def run(command: list[str], timeout: float = 8) -> subprocess.CompletedProcess[str] | None:
    try:
        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return None
    except OSError as error:
        return subprocess.CompletedProcess(command, 126, "", str(error))


def get_status() -> tuple[dict, str]:
    result = run(["tailscale", "status", "--json"], timeout=4)
    if result is None:
        return {}, "Tailscale status timed out or is unavailable"
    if result.returncode != 0:
        return {}, result.stderr.strip() or "Tailscale daemon is unavailable"
    try:
        return json.loads(result.stdout), ""
    except json.JSONDecodeError:
        return {}, "Could not parse Tailscale status"


def waybar_output(text: str, tooltip: str, css_class: str) -> None:
    print(
        json.dumps(
            {"text": text, "tooltip": tooltip, "class": css_class},
            ensure_ascii=False,
        )
    )


def ipv4_for(node: dict) -> str:
    addresses = node.get("TailscaleIPs") or node.get("Addrs") or []
    return next((str(ip) for ip in addresses if ":" not in str(ip)), "")


def dns_name(node: dict) -> str:
    return sanitize(node.get("DNSName", "")).rstrip(".")


def node_name(node: dict) -> str:
    return sanitize(node.get("HostName")) or dns_name(node) or "Unknown"


def connection_label(peer: dict) -> str:
    if not peer.get("Active"):
        return "idle"
    current_address = sanitize(peer.get("CurAddr"))
    if current_address:
        return f"direct {current_address}"
    relay = sanitize(peer.get("Relay"))
    return f"relay {relay}" if relay else "active"


def key_expiry(status: dict) -> tuple[str, int | None]:
    raw = sanitize((status.get("Self") or {}).get("KeyExpiry"))
    if not raw or raw.startswith("0001-"):
        return "", None
    try:
        expiry = datetime.fromisoformat(raw.replace("Z", "+00:00"))
        days = math.ceil((expiry - datetime.now(timezone.utc)).total_seconds() / 86400)
    except ValueError:
        return raw, None
    if days < 0:
        return "expired", days
    return f"{days} days", days


def selected_exit_node(status: dict) -> dict | None:
    return next(
        (peer for peer in (status.get("Peer") or {}).values() if peer.get("ExitNode")),
        None,
    )


def status_command() -> None:
    if not shutil.which("tailscale"):
        waybar_output(ICON, "Tailscale is not installed", "error")
        return

    status, error = get_status()
    if error:
        waybar_output(ICON, markup(error), "error")
        return

    state = sanitize(status.get("BackendState")) or "Unknown"
    if state != "Running":
        hint = "Click to connect"
        if status.get("AuthURL") or state == "NeedsLogin":
            hint = "Click to authenticate"
        waybar_output(f"{ICON} !", f"Tailscale: {markup(state)}\n{hint}", "needs-login" if state == "NeedsLogin" else "stopped")
        return

    own = status.get("Self") or {}
    own_ips = status.get("TailscaleIPs") or own.get("TailscaleIPs") or own.get("Addrs") or []
    own_ipv4 = next((str(ip) for ip in own_ips if ":" not in str(ip)), "n/a")
    own_ipv6 = next((str(ip) for ip in own_ips if ":" in str(ip)), "n/a")
    peers = list((status.get("Peer") or {}).values())
    online = [peer for peer in peers if peer.get("Online")]
    direct = [peer for peer in online if peer.get("Active") and peer.get("CurAddr")]
    relayed = [peer for peer in online if peer.get("Active") and not peer.get("CurAddr") and peer.get("Relay")]
    idle_count = len(online) - len(direct) - len(relayed)
    tailnet = sanitize((status.get("CurrentTailnet") or {}).get("Name")) or "unknown"
    exit_node = selected_exit_node(status)
    expiry_text, expiry_days = key_expiry(status)

    lines = [
        f"Tailnet: {markup(tailnet)}",
        f"Device: {markup(node_name(own))}",
        f"MagicDNS: {markup(dns_name(own) or 'n/a')}",
        f"IPv4: {markup(own_ipv4)}",
        f"IPv6: {markup(own_ipv6)}",
        f"Peers: {len(online)}/{len(peers)} online · {len(direct)} direct · {len(relayed)} relayed · {idle_count} idle",
    ]
    if exit_node:
        lines.append(f"Exit node: {markup(node_name(exit_node))}")
    else:
        lines.append("Exit node: none")
    if expiry_text:
        warning = " ⚠" if expiry_days is not None and expiry_days <= 30 else ""
        lines.append(f"Key expiry: {markup(expiry_text)}{warning}")

    if online:
        lines.extend(["", "Online peers:"])
        for peer in sorted(online, key=lambda item: node_name(item).casefold()):
            peer_ip = ipv4_for(peer) or "n/a"
            lines.append(
                f"{markup(node_name(peer))}: {markup(peer_ip)} · {markup(connection_label(peer))}"
            )

    text = f"{ICON} {len(online)}"
    css_class = "connected"
    if exit_node:
        text += " E"
        css_class = "exit-node"
    if expiry_days is not None and expiry_days <= 30:
        css_class = "expiring"
    waybar_output(text, "\n".join(lines), css_class)


def choose(prompt: str, labels: list[str]) -> str:
    if not labels or not shutil.which("fuzzel"):
        if not shutil.which("fuzzel"):
            notify("Fuzzel is required for the interactive menu")
        return ""
    try:
        selected = subprocess.run(
            ["fuzzel", "--dmenu", "--prompt", f"{prompt}: "],
            input="\n".join(labels),
            capture_output=True,
            text=True,
            timeout=300,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return selected.stdout.strip()


def safe_auth_url(value: object) -> str:
    """Accept only HTTPS URLs hosted by Tailscale's login infrastructure."""
    candidate = sanitize(value)
    try:
        parsed = urlparse(candidate)
    except ValueError:
        return ""
    host = (parsed.hostname or "").casefold()
    if parsed.scheme != "https" or not (host == "login.tailscale.com" or host.endswith(".tailscale.com")):
        return ""
    return candidate


def open_url(url: str) -> None:
    opener = shutil.which("xdg-open")
    if not opener:
        notify("xdg-open is not installed")
        return
    try:
        subprocess.Popen(
            [opener, url],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as error:
        notify(f"Could not open browser: {error}")


def refresh_waybar() -> None:
    if shutil.which("pkill"):
        run(["pkill", WAYBAR_SIGNAL, "waybar"], timeout=3)


def command_error(result: subprocess.CompletedProcess[str] | None, action: str) -> str:
    if result is None:
        return f"{action} timed out"
    message = result.stderr.strip() or result.stdout.strip() or f"{action} failed"
    permission_markers = ("permission", "access denied", "not permitted", "unauthorized", "must be root")
    if any(marker in message.casefold() for marker in permission_markers):
        message += f"\nGrant access with: sudo tailscale set --operator={os.environ.get('USER', '$USER')}"
    return message


def run_tailscale_action(args: list[str], action: str, timeout: float = 20) -> bool:
    result = run(["tailscale", *args], timeout=timeout)
    refresh_waybar()
    if result is not None and result.returncode == 0:
        return True
    notify(command_error(result, action))
    return False


def authenticate(status: dict) -> None:
    raw_auth_url = status.get("AuthURL")
    auth_url = safe_auth_url(raw_auth_url)
    if auth_url:
        open_url(auth_url)
        return
    if raw_auth_url:
        notify("Refused an unexpected Tailscale authentication URL")

    result = run(["tailscale", "up"], timeout=20)
    refresh_waybar()
    output = ""
    if result is not None:
        output = f"{result.stdout}\n{result.stderr}"
    match = re.search(r"https://\S+", output)
    if not match:
        refreshed, _ = get_status()
        auth_url = safe_auth_url(refreshed.get("AuthURL"))
    else:
        auth_url = safe_auth_url(match.group(0).rstrip(".,)"))
    if auth_url:
        open_url(auth_url)
        notify("Finish signing in to Tailscale in your browser")
    elif result is None or result.returncode != 0:
        notify(command_error(result, "Connecting to Tailscale"))


def copy_text(value: str) -> None:
    commands = []
    if shutil.which("wl-copy"):
        commands.append(["wl-copy"])
    if shutil.which("xclip"):
        commands.append(["xclip", "-selection", "clipboard"])
    if shutil.which("xsel"):
        commands.append(["xsel", "--clipboard", "--input"])
    if not commands:
        notify("Install wl-clipboard, xclip, or xsel to copy addresses")
        return
    try:
        subprocess.run(commands[0], input=value, text=True, check=True, timeout=3)
        notify(f"Copied {value}")
    except (subprocess.SubprocessError, OSError):
        notify("Could not copy to the clipboard")


def terminal_command(command: list[str]) -> None:
    terminal = ["ghostty"]
    if not terminal or not shutil.which(terminal[0]):
        notify("No terminal was found")
        return
    try:
        subprocess.Popen(
            [*terminal, "-e", *command],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as error:
        notify(f"Could not open terminal: {error}")


def ping_peer(peer: dict) -> None:
    target = ipv4_for(peer) or dns_name(peer) or node_name(peer)
    result = run(["tailscale", "ping", "--c", "3", "--timeout", "3s", target], timeout=15)
    if result is None or result.returncode != 0:
        notify(command_error(result, f"Pinging {node_name(peer)}"))
        return
    lines = [sanitize(line) for line in result.stdout.splitlines() if line.strip()]
    notify("\n".join(lines[-4:]) or f"{node_name(peer)} is reachable")


def open_machine(peer: dict) -> None:
    machine_id = sanitize(peer.get("ID"))
    open_url(f"{ADMIN_URL}/{quote(machine_id, safe='')}" if machine_id else ADMIN_URL)


def peer_menu(peer: dict) -> None:
    name = node_name(peer)
    ip = ipv4_for(peer)
    dns = dns_name(peer)
    actions: list[tuple[str, str]] = []
    if ip:
        actions.append((f"Copy IPv4  {sanitize(ip)}", "copy-ip"))
    if dns:
        actions.append((f"Copy MagicDNS  {sanitize(dns)}", "copy-dns"))
    actions.extend(
        [
            (f"Ping {sanitize(name)}", "ping"),
            (f"Tailscale SSH to {sanitize(name)}", "ssh"),
            ("Open machine in admin console", "admin"),
        ]
    )
    selection = choose(name, [label for label, _ in actions])
    action = next((action for label, action in actions if label == selection), "")
    if action == "copy-ip":
        copy_text(ip)
    elif action == "copy-dns":
        copy_text(dns)
    elif action == "ping":
        ping_peer(peer)
    elif action == "ssh":
        terminal_command(["tailscale", "ssh", dns or ip or name])
    elif action == "admin":
        open_machine(peer)


def exit_node_menu(status: dict) -> None:
    peers = [peer for peer in (status.get("Peer") or {}).values() if peer.get("ExitNodeOption")]
    active = selected_exit_node(status)
    actions: list[tuple[str, str]] = []
    if active:
        actions.append((f"Disable exit node (currently {sanitize(node_name(active))})", ""))
    else:
        actions.append(("No exit node (current)", ""))
    for peer in sorted(peers, key=lambda item: node_name(item).casefold()):
        target = ipv4_for(peer) or dns_name(peer)
        if not target:
            continue
        current = " (current)" if peer.get("ExitNode") else ""
        actions.append((f"Use {sanitize(node_name(peer))}{current}", target))

    selection = choose("Exit node", [label for label, _ in actions])
    if not selection:
        return
    target = next((target for label, target in actions if label == selection), None)
    if target is None:
        return
    if (active and target == (ipv4_for(active) or dns_name(active))) or (not active and not target):
        return
    confirmation = f"Confirm: {selection}"
    if choose("Change exit node?", ["Cancel", confirmation]) != confirmation:
        return
    run_tailscale_action(["set", f"--exit-node={target}"], "Changing exit node")


def confirm_disconnect() -> bool:
    return choose("Disconnect Tailscale?", ["Cancel", "Disconnect"]) == "Disconnect"


def menu_command() -> None:
    if not shutil.which("tailscale"):
        notify("Tailscale is not installed")
        return
    status, error = get_status()
    if error:
        notify(error)
        return

    state = sanitize(status.get("BackendState")) or "Unknown"
    running = state == "Running"
    actions: list[tuple[str, str, dict | None]] = []
    if running:
        actions.append(("Disconnect Tailscale…", "down", None))
    else:
        label = "Authenticate Tailscale…" if status.get("AuthURL") or state == "NeedsLogin" else "Connect Tailscale"
        actions.append((label, "up", None))
    actions.append(("Open admin console", "admin", None))

    if running:
        own = status.get("Self") or {}
        own_ip = ipv4_for({"TailscaleIPs": status.get("TailscaleIPs") or own.get("TailscaleIPs") or own.get("Addrs")})
        if own_ip:
            actions.append((f"Copy this device IP  {sanitize(own_ip)}", "copy-own", {"ip": own_ip}))
        active_exit = selected_exit_node(status)
        exit_label = f"Exit node: {sanitize(node_name(active_exit))}" if active_exit else "Exit node: none"
        actions.append((exit_label, "exit-node", None))

        online = [peer for peer in (status.get("Peer") or {}).values() if peer.get("Online")]
        for peer in sorted(online, key=lambda item: node_name(item).casefold()):
            ip = ipv4_for(peer) or "n/a"
            label = f"Peer: {sanitize(node_name(peer))}  {sanitize(ip)}  [{sanitize(connection_label(peer))}]"
            actions.append((label, "peer", peer))

    selection = choose("Tailscale", [label for label, _, _ in actions])
    match = next(((action, data) for label, action, data in actions if label == selection), None)
    if not match:
        return
    action, data = match
    if action == "down" and confirm_disconnect():
        run_tailscale_action(["down"], "Disconnecting Tailscale")
    elif action == "up":
        authenticate(status)
    elif action == "admin":
        open_url(ADMIN_URL)
    elif action == "copy-own" and data:
        copy_text(str(data["ip"]))
    elif action == "exit-node":
        exit_node_menu(status)
    elif action == "peer" and data:
        peer_menu(data)


def main() -> None:
    command = os.sys.argv[1] if len(os.sys.argv) > 1 else "status"
    if command == "status":
        status_command()
    elif command == "menu":
        menu_command()
    elif command == "admin":
        open_url(ADMIN_URL)
    else:
        raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
