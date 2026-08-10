# Global Pi Agent Instructions

- In root parent sessions, keep the parent as the orchestrator. When the same delegated role needs follow-up work within the current parent session, prefer resuming its existing child session by run ID instead of launching a fresh child. Use `steer` for a live child and `resume` for a paused or completed child. Continue using fresh-context children when independence is intentional, especially for adversarial review and validation.
- Shape mutation delegation around one bounded, coherent outcome that can be validated before later work. When ownership or integration boundaries are unknown, separate read-only reconnaissance from mutation. Serialize implementation slices that share state or invariants instead of asking one child to discover the architecture, modify several coupled boundaries, reconcile behavior, and perform final validation in one run.
- Allow at most one active writer, including the parent, in a checkout or worktree. Read-only inspection may proceed concurrently. Work that depends on uncommitted changes stays with the sole writer in the existing checkout; use a managed worktree only for independent work that can begin from committed state.
- Bound every potentially blocking subprocess at the nearest layer and at the caller layer. Set the tool's timeout and, for nested `child_process`, shell `timeout`, browser CLI, network client, or daemon calls, set an inner timeout that expires first and leaves time to return diagnostics. Never use synchronous child-process APIs without a timeout around an external CLI.
- Give every subagent launch an explicit `timeoutMs` or `maxRuntimeMs`. Start with 5 minutes for read-only scouting/review and 10 minutes for a narrowly scoped writer; increase only when observed work requires it. Enable progress for background or multi-step runs. Do not apply hard turn or tool budgets to mutation-capable agents; for read-only agents, use bounded budgets when they reduce open-ended exploration.
- When a command times out or produces no progress, inspect its last output once and change the approach. Do not rerun the same unbounded command, poll repeatedly, or add sleep loops. For a stalled live child, inspect one transcript tail, then `steer` it toward the smallest useful handoff or `stop` it if it cannot recover.
- Require mutation children to return changed files, validation commands and results, unresolved risks, and staging or commit state. Treat that result as an implementation handoff, not independent review. Run fresh review separately when a milestone or final diff is stable enough for the review to remain valid.

Keep system entropy low.

- Solve problems at their underlying cause, not with local patches that accumulate complexity.
- Prefer the simplest correct design with the fewest concepts, states, dependencies, and special cases.
- Keep changes proportional to the task; do not broaden scope unless necessary for a correct, durable solution.
- Reduce or consolidate complexity when possible, and avoid merely moving it elsewhere.
- Preserve established behavior unless changing it is part of the intended solution.
