---
description: Render a bounded, low-entropy worker contract
---
Goal
{{goal}}

Target and closed scope envelope
- cwd/repository: {{cwd}}
- allowed files or exact source seam: {{target}}
- governing plan, diff, or evidence: {{evidence}}
Treat this file and behavior scope as closed. Inspect adjacent code only to understand contracts or verify callers. Do not edit outside the envelope without supervisor approval.

Approved decisions and allowed behavior changes
{{decisions}}
Implement only behavior required by the goal and success criteria. If a possible improvement is optional, report it without implementing it.

Forbidden changes, non-goals, and behavior to preserve
{{nonGoals}}
Do not add dependencies, public APIs, configuration, states, abstractions, compatibility layers, generalized helpers, adjacent cleanup, or unrelated tests unless a success criterion explicitly requires them.

Authority
{{authority}}

Success criteria
{{success}}

Focused validation
{{validation}}
Run only checks needed to prove this checkpoint while iterating. Do not run aggregate suites, security advisors, release checks, or unrelated broad gates unless the task explicitly assigns that one gate; the parent owns broad validation after the diff is stable.

Edit discipline
Re-read the target slice immediately before editing. Use small, unique, non-overlapping replacements. After one failed edit, re-read before retrying; do not repeatedly guess replacement text.

Entropy budget
Reuse the existing owning boundary and established concepts. Add the fewest new symbols, branches, states, fixtures, and special cases needed for correctness. Prefer deletion, consolidation, or a direct local change over a parallel mechanism. Do not move complexity to another layer or generalize for hypothetical future use.

Checkpoint boundary
Implement one coherent, independently testable checkpoint. If the requested work contains multiple independent seams or cannot safely finish within the run, stop at a durable boundary and report the exact remaining checkpoints. If correctness requires leaving the closed scope envelope, stop before the out-of-scope edit and use `contact_supervisor` with `reason: "need_decision"`.

Required handoff
Return a checked handoff with exact changed file paths and implemented behavior; scope-envelope compliance; concepts, dependencies, states, or abstractions added; each exact command with its exit code and result; validation output; optional improvements deliberately not implemented; residual risks; remaining work; and staging/commit state. Do not claim checked acceptance when any item is missing.

Stop and escalation rules
{{stopRules}}
Do not broaden scope or invent product, architecture, API, release, merge, or safety decisions. Use contact_supervisor when an unapproved decision is required.
