---
name: pi-subagents
description: Launch or recover child agents using Pi's subagent tool. Does not apply to T3 or other delegation runtimes.
---

# Pi delegation

Use this skill only for Pi's `subagent` tool. Work directly when briefing and review would cost more than doing the task. Use one worker for a bounded implementation; add a scout only for a question that changes the assignment. Children do not fan out without authorization.

Supply outcome, cwd/base, exclusive boundary, relevant evidence, authority/resources and focused checks. Reuse completed investigation and valid checks. Workers, reviewers and oracles default to fresh context. Select a fork explicitly only for historical consistency: it includes the parent prompt, skills and transcript even when inheritance flags are false. Concurrent writers need separate worktrees, and shared services still need a single mutation owner.

## Launch and acceptance

Read only the installed reference section needed for the actual call; tool schemas are authoritative:

- [Tool reference](../../npm/node_modules/pi-subagents/docs/tool-reference.md): launch fields, acceptance, reports, resume and steering.
- [Workflows](../../npm/node_modules/pi-subagents/docs/workflows.md): actual sequencing or parallel work, not a mandatory wrapper for simple tasks.
- [Agents](../../npm/node_modules/pi-subagents/docs/agents.md): tools, context and skill inheritance.
- [Configuration](../../npm/node_modules/pi-subagents/docs/configuration.md): limits, notifications and optional features.
- [Worktree lanes](../../npm/node_modules/pi-subagents/skills/pi-subagents/references/orchestration.md): isolation and cleanup.
- [Missions](../../npm/node_modules/pi-subagents/docs/missions.md): only when durable mission tracking is requested or an existing mission needs recovery.

For substantial writer tasks, supply explicit acceptance through the supported schema, required evidence/checks and whether independent review is needed. Inferred acceptance does not fail a run on a failed gate; explicit acceptance does. A successful child exit is not verification. Use task-specific deadlines with enough time for the longest tool call and cleanup. Async single runs request a checkpoint five minutes before deadline; adjust it for the task so it leaves room for the longest tool call and cleanup. A checkpoint is disarmed when its lead time reaches the run deadline.

Parallelize independent assignments when useful. The configured child limit applies per workflow and the active-run limit per session, not machine-wide. Serialize shared database mutations and expensive runtime setup through their existing ownership/lease controls; independent source work does not need that serialization.

Background completion notifies the parent. Continue independent work, then yield rather than poll. Treat attention notices as observations, not proof of a stall. Keep models and concurrency at configured defaults unless task difficulty or evidence justifies changing them.

## Review and recovery

Return outcome, changed files/candidate, checks, blockers and artifact paths once through the runtime's required report schema. Avoid duplicate file and inline reports. The read-only reviewer has no shell; provide diffs and check evidence. Freeze the candidate during independent review, then rerun checks affected by fixes.

After failure, inspect changes and receipts before resuming. Resume an eligible worker for the same outcome; if resume fails before startup, verify no changes and use a smaller fresh assignment. A report-format repair does not invalidate passed implementation checks. Preserve authority, isolation and cleanup boundaries; do not retry without new evidence.

Use `node ~/.pi/agent/scripts/lint-subagent-sessions.mjs --days 7` only to investigate setup, acceptance or timeout failures. Counts are diagnostic, not a measure of productivity. Restart Pi at an idle boundary after package/subagent configuration changes; preserve active work and its handoff.
