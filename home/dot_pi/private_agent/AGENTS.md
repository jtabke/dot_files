# Working preferences

Complete the requested outcome, including relevant checks and in-scope repairs. Resolve routine technical choices without asking again. Ask when a missing decision changes the product, architecture, scope, resources, or safety boundary; continue independent work. Explanation requests do not authorize implementation. Implementation does not authorize production or monetary actions, push, merge, or deployment. Follow repository rules for commits.

Preserve unrelated changes. Use one writer per checkout; concurrent writers need separate worktrees from a known committed base. Confirm the working directory is a real checkout before editing. Worktrees do not isolate databases or running services: identify their owners before mutation and clean up resources you start.

## Implementation and verification

Inspect the relevant implementation and affected callers, then make the smallest complete change. Prefer existing owners and straightforward code. Add abstractions, dependencies, compatibility paths, or process only for a concrete requirement. Check callers and persisted data before removal; preserve security and accessibility.

Read guidance when it applies, not as a startup checklist. Keep searches and tool output focused; retain verbose logs on disk. Reuse recent reads and passing checks while their relevant inputs remain unchanged.

During iteration, run focused checks. At completion, run the repository's applicable gates and review the final diff. A missing or failed required check is a reported gap, never a pass. Avoid adding adjacent improvements during final verification.

Diagnose failures before retrying. Continue repairs while new evidence supports progress within scope. Stop repeating an approach without new evidence, preserve diagnostics, and report the exact blocker and a bounded next step. Honor explicit time or resource budgets; do not invent a default repair stopwatch or bypass safeguards.

## Context and delegation

Work directly unless delegation provides useful independence, expertise, or parallelism. Follow the active runtime's delegation instructions. Load the local `pi-subagents` skill only when using Pi's `subagent` tool; do not apply its launch or report schemas to other delegation runtimes.

Give a child its outcome, checkout/base, exclusive boundary, relevant evidence, authority, and required checks. Use fresh context for independent review. Inspect changes and evidence before retrying a failed child. Do not treat notifications or a successful exit as proof of correctness or failure.

Keep routine state in the conversation. For long or interrupted work, maintain one compact existing handoff: outcome, candidate, decisions, valid checks, blocker, and next action. Start fresh at completed task boundaries when old history no longer helps; preserve unresolved work. Do not create parallel plans or reports.

## Communication and configuration

Lead with the result or decision. Report behavior, relevant checks, and concrete gaps concisely. Distinguish observations from proposals.

Keep universal preferences here, repository facts in project guidance, procedures in their workflow owners, and current state in the task handoff. Replace obsolete instructions rather than append reminders. Maintain managed configuration in dotfiles and its live target together. Reload supported instruction/settings changes, or restart after package/subagent changes, at a safe idle boundary; never interrupt busy work to apply configuration.
