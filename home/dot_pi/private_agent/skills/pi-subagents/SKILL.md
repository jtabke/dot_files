---
name: pi-subagents
description: Launch or supervise authorized Pi child agents with bounded assignments, validation evidence, and recovery.
---

# Pi delegation

Work directly by default. Delegation must be authorized by the user request or
applicable instructions and earn its coordination cost. The parent owns decisions
and final acceptance. Children do not fan out unless explicitly authorized.

## Choose the smallest shape

- One task: `subagent({agent:"worker",task:"...",cwd:"...",context:"fresh"})`.
- Use a workflow only for actual sequencing, branching, or parallelism. Await every
  child operation. Read the relevant syntax in the [workflow guide](../../git/github.com/nicobailon/pi-subagents/docs/workflows.md).
- Use fresh scouts/workers/reviewers. A forked oracle checks decisions against prior
  history; it is not an independent fresh review.
- Background runs notify the parent on completion. Keep independent work moving,
  then yield when only children remain. Inspect FleetView for progress; do not poll
  status or call `bg_wait` merely because a normal async child is active.

Each assignment needs its outcome, cwd/base, owning boundary, relevant evidence,
authority/resources, success criteria, focused checks, output, and stop conditions.
Use the matching local role contract without repeating its generic instructions.
One writer owns each checkout. Concurrent writers use isolated worktrees from a
committed base. Worktrees do not isolate shared services.

Authorize repair and retry within concrete runtime limits, isolation, and cleanup
conditions. Escalate failed safety conditions or expanded authority, not routine
technical choices. Preserve production, monetary, publication, and release boundaries.

## Look up only what the call needs

The installed package remains the API source of truth. These references are large:
locate the relevant heading or parameter with a bounded search, then read that section.
Do not load every reference for a complex task or request the entire tool guide for
a simple launch. Load more only when an unresolved field or procedure requires it.

| Need | Reference |
| --- | --- |
| Call fields, acceptance, output, resume, or steering | [Tool reference](../../git/github.com/nicobailon/pi-subagents/docs/tool-reference.md) |
| Workflow syntax and orchestration | [Workflows](../../git/github.com/nicobailon/pi-subagents/docs/workflows.md) |
| Role tools, context, model, and skill inheritance | [Agents](../../git/github.com/nicobailon/pi-subagents/docs/agents.md) |
| Feature flags, concurrency, timeouts, or notifications | [Configuration](../../git/github.com/nicobailon/pi-subagents/docs/configuration.md) |
| Isolated lanes and worktree lifecycle | [Lane reference](../../git/github.com/nicobailon/pi-subagents/skills/pi-subagents/references/multi-lane-orchestration.md) |
| Mission state or an explicit schedule request | [Missions](../../git/github.com/nicobailon/pi-subagents/docs/missions.md) |

Exact tool acceptance schemas and launch contracts take priority over informal
examples. Select high effort for difficult financial, migration, concurrency, or
harness work rather than adding more instructions to a routine model profile.

## Evidence and recovery

Require checked evidence from mutation children. Keep validation logs in artifacts;
return behavior, candidate identity, check results, material gaps, and next action.
Use independent review only when required by policy or the task's risk. Freeze the
candidate during review and rerun only checks invalidated by accepted fixes.

After failure, inspect existing changes and receipts before retrying. Use a retained
resume only when eligible; if it fails before startup, verify no changes and use a
smaller fresh same-role fallback. Do not silently switch execution modes or bypass
capability ceilings. A report-format failure does not justify repeating passed checks.
Treat attention notices as observations, not proof of a stall. Restart Pi at an idle
boundary after settings or package changes, preserving the session and handoff.
