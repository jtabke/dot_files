/** Mark this Pi pane in tmux when the agent is waiting for the user. */
import { execFileSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const pane = process.env.TMUX_PANE;

function tmux(...args: string[]): void {
	if (!pane) return;
	try {
		execFileSync("tmux", args, { stdio: "ignore" });
	} catch {
		// A status indicator must never interrupt Pi.
	}
}

function clearAttention(): void {
	tmux("set-option", "-wu", "-t", pane!, "@agent_attention");
}

function requestAttention(): void {
	try {
		const active = execFileSync("tmux", ["display-message", "-p", "-t", pane!, "#{window_active}"], {
			encoding: "utf8",
		}).trim();
		if (active === "1") {
			clearAttention();
			return;
		}
	} catch {
		return;
	}

	tmux("set-option", "-w", "-t", pane!, "@agent_attention", "pi");
	tmux("refresh-client", "-S");
}

export default function (pi: ExtensionAPI) {
	pi.on("agent_start", async () => clearAttention());
	pi.on("agent_settled", async () => requestAttention());
	pi.on("ui_prompt_start", async () => requestAttention());
	pi.on("session_shutdown", async () => clearAttention());
}
