---
name: pi-subagents
description: Launch or supervise authorized Pi child agents with bounded assignments, validation evidence, and recovery.
---

# Pi delegation

Work directly by default. Delegation must be authorized by the user request or
applicable instructions and earn its coordination cost. The parent owns decisions
and final acceptance. Children do not fan out unless explicitly authorized.

## Choose the smallest shape

- Work directly when briefing, waiting, and reviewing would cost more than doing
  the task. Delegate only for a clear ownership, parallelism, or expertise benefit.
- Default to one worker owning investigation, implementation, and focused validation.
  Add a scout only for a named uncertainty whose answer changes the assignment;
  do not impose scout → planner → worker → reviewer stages.
- One task: `subagent({agent:"worker",task:"...",cwd:"...",context:"fresh"})`.
- Use a workflow only for actual sequencing, branching, or parallelism. Await every
  child operation. Read the relevant syntax in the [workflow guide](../../npm/node_modules/pi-subagents/docs/workflows.md).
- Start new assignments and independent reviews fresh. Resume an eligible worker
  for a small repair to its own candidate, with only the changed requirements and
  evidence. Use a forked oracle for historical consistency, not independent review.
- Background runs notify the parent on completion. Keep independent work moving,
  then yield when only children remain. Inspect FleetView for progress; do not poll
  status or call `bg_wait` merely because a normal async child is active.

Each assignment needs its outcome, cwd/base, owning boundary, relevant evidence,
authority/resources, success criteria, focused checks, output, and stop conditions.
Use the matching local role contract without repeating its generic instructions.
Send exact paths, decisions, evidence, and success criteria, not the parent's whole
investigation. Mark completed investigation and still-valid checks so children
reuse them unless stale or insufficient. Do not make a child rediscover its brief.

Before fanout, name each child's distinct question or exclusive implementation
boundary, its dependencies, and the result that blocks the parent. Launch independent
work together and keep useful parent work moving; avoid duplicated investigation.
Overlapping implementation belongs to one writer. Concurrent writers use isolated
worktrees from a committed base. Worktrees do not isolate shared services.

Default handoffs contain Outcome; Candidate / changed files; Checks; Blockers /
remaining risks; Artifacts. Keep detailed logs in artifacts and return their paths,
not duplicate inline and file narratives. A required acceptance or review schema
takes precedence. Use focused checks first and broader gates only when required.

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
| Call fields, acceptance, output, resume, or steering | [Tool reference](../../npm/node_modules/pi-subagents/docs/tool-reference.md) |
| Workflow syntax and orchestration | [Workflows](../../npm/node_modules/pi-subagents/docs/workflows.md) |
| Role tools, context, model, and skill inheritance | [Agents](../../npm/node_modules/pi-subagents/docs/agents.md) |
| Feature flags, concurrency, timeouts, or notifications | [Configuration](../../npm/node_modules/pi-subagents/docs/configuration.md) |
| Isolated lanes and worktree lifecycle | [Lane reference](../../npm/node_modules/pi-subagents/skills/pi-subagents/references/orchestration.md) |
| Mission state or an explicit schedule request | [Missions](../../npm/node_modules/pi-subagents/docs/missions.md) |

Exact tool acceptance schemas and launch contracts take priority over informal
examples. Select high effort for difficult financial, migration, concurrency, or
harness work rather than adding more instructions to a routine model profile.

## Evidence and recovery

For substantial writer tasks, make acceptance explicit: checked/verified evidence,
required checks, and whether independent review is required, with a rationale.
Direct calls put acceptance in `options.acceptance`; workflow child items use
`acceptance`. Set `review: { required: true, agent: "reviewer" }` when needed,
or `review: { required: false }` when focused verification is sufficient. Supply
supported evidence kinds (changed-files, commands-run, validation-output,
residual-risks, no-staged-files) and use `acceptance.verify` for host-run checks.
Read the acceptance-gates reference before composing the exact policy/report.
Inferred writer acceptance is observable but does not fail the run on a failed
gate; explicit acceptance does. Neither a successful exit nor child prose is proof.

Keep validation logs in artifacts; return behavior, candidate identity, check
results, material gaps, and next action. Give fresh reviewers the exact base and
candidate, a diff artifact, approved behavior, validation commands/results and
receipt paths, and remaining gaps. The read-only reviewer has no shell; the parent
runs missing checks and supplies committed-range diffs. Freeze the candidate during
review and rerun only checks invalidated by accepted fixes.

Do not impose a global hard tool timeout on builds/tests. Set task-specific run
deadlines with margin for the longest tool call and checkpoint. Async single-agent
runs get a best-effort checkpoint request ten minutes before their deadline; shorter
runs need an explicit smaller `options.checkpointBeforeDeadlineMs`. A steer cannot
interrupt an open tool safely. Composite workflows need child deadlines and manual
checkpoint steering as needed. Session reopen/reload does not auto-resume workflows;
inspect retained state and authority before an explicit resume.

For the next few substantive tasks, use existing receipts/transcripts to compare
elapsed time and usage, repeated investigation, handoffs, and repair cycles—not just
completion. Note material observations in the existing task handoff; do not create
a separate dashboard or mandatory reporting stage. Keep models and concurrency
unchanged unless a demonstrated pattern justifies tuning.
Run `node ~/.pi/agent/scripts/lint-subagent-sessions.mjs --days 7` when investigating
setup failures, missing acceptance, timeouts, or output collisions. Lint counts
cannot judge context-read necessity or overall efficiency; inspect focused traces.
Observations are not permission to retry or proof that a child stalled.

After failure, inspect existing changes and receipts before retrying. Use a retained
resume only when eligible; if it fails before startup, verify no changes and use a
smaller fresh same-role fallback. Do not silently switch execution modes or bypass
capability ceilings. A report-format failure does not justify repeating passed checks.
Treat attention notices as observations, not proof of a stall. Restart Pi at an idle
boundary after settings or package changes, preserving the session and handoff.
