---
description: Render a self-contained fresh-context worker contract
---
Goal
{{goal}}

Target
- cwd/repository: {{cwd}}
- files or source seam: {{target}}
- governing plan, diff, or evidence: {{evidence}}

Approved decisions and constraints
{{decisions}}

Non-goals and behavior to preserve
{{nonGoals}}

Authority
{{authority}}

Success criteria
{{success}}

Focused validation
{{validation}}

Edit discipline
Re-read the target slice immediately before editing. Use small, unique, non-overlapping replacements. After one failed edit, re-read before retrying; do not repeatedly guess replacement text.

Checkpoint boundary
Implement one coherent, independently testable checkpoint. If the requested work contains multiple independent seams or cannot safely finish within the run, stop at a durable boundary and report the exact remaining checkpoints.

Required handoff
Return a checked handoff with exact changed file paths and implemented behavior; each exact command with its exit code and result; validation output; residual risks; remaining work; and staging/commit state. Do not claim checked acceptance when any item is missing.

Stop and escalation rules
{{stopRules}}
Do not broaden scope or invent product, architecture, API, release, merge, or safety decisions. Use contact_supervisor when an unapproved decision is required.
