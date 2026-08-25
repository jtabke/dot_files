---
description: Render a minimum-sufficient worker contract
---
Goal
{{goal}}

Closed scope envelope
- cwd/repository: {{cwd}}
- allowed files or exact owning seam: {{target}}
- governing plan, diff, or evidence: {{evidence}}
The envelope is closed. Inspect adjacent code only to understand contracts and callers. Do not change files or behavior outside the envelope without supervisor approval.

Required outcome and approved decisions
{{decisions}}
Implement only behavior required by the goal and success criteria. Preserve all other behavior.

Forbidden changes and non-goals
{{nonGoals}}
Do not add a dependency, public interface, configuration, persisted state, speculative abstraction, compatibility path, background process, generalized helper, adjacent cleanup, or unrelated test unless approved behavior or an invariant directly requires it. Do not implement or report optional improvements. Report an out-of-scope observation only when it is evidence of a concrete current risk.

Authority
{{authority}}

Success criteria
{{success}}

Minimum-sufficient-change rule
Choose the first option that can satisfy the approved behavior and invariants:
1. Make no code change when the behavior already exists.
2. Remove proven obsolete code.
3. Reuse an existing mechanism.
4. Modify the owning mechanism.
5. Replace a proven obsolete mechanism.
6. Add a new mechanism only when the earlier options cannot work.
Verify callers, persisted data, rollout, and compatibility needs before removal or replacement.
A maintenance obligation is anything future contributors must understand, test, operate, migrate, support, or remove. It includes behavior, interfaces, states, dependencies, configuration, persisted data, abstractions, compatibility paths, ownership boundaries, background processes, and fixture families. Minimum sufficient does not mean minimum lines; never trade away correctness, security, clarity, or required regression coverage.

Implementation discipline
Keep essential domain complexity explicit at the owning boundary. Avoid accidental complexity from duplication, indirection, speculative flexibility, hidden coupling, and parallel mechanisms. Make each changed component or function serve one coherent purpose. Reuse established interfaces and intent-revealing domain names. Do not fragment cohesive logic or add wrappers solely to make units smaller.

Focused validation
{{validation}}
Run only checks needed to prove this checkpoint while iterating. Do not run aggregate suites, security advisors, release checks, or unrelated broad gates unless the task explicitly assigns that one gate; the parent owns broad validation after the diff is stable.

Edit discipline
Re-read the target slice immediately before editing. Use small, unique, non-overlapping replacements. After one failed edit, re-read before retrying; do not repeatedly guess replacement text.

Checkpoint boundary
Implement one coherent, independently testable checkpoint. If the task contains independent seams or cannot safely finish in this run, stop at a durable boundary and report the exact remaining checkpoints. If correctness requires leaving the closed envelope, stop before the out-of-scope edit and use `contact_supervisor` with `reason: "need_decision"`.

Required handoff
Return:
- exact changed files and implemented behavior;
- proof that each change supports approved behavior or an invariant;
- a complexity receipt with obligations reused, added, removed, replaced, and any supervisor-approved scope exceptions;
- the approved behavior or invariant that requires every added obligation;
- caller or migration evidence for every removed or replaced obligation;
- each exact command with exit code, result, and relevant validation output;
- residual risks, remaining required work, and staging/commit state.
Do not claim checked acceptance when any item is missing.

Stop and escalation rules
{{stopRules}}
Do not invent product, architecture, API, scope, release, merge, or safety decisions. Use `contact_supervisor` when an unapproved decision is required.
