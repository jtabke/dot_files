---
description: Render a fresh-context scope, necessity, and correctness review contract
---
Review goal and assigned angle
{{goal}}

Target
- cwd/repository: {{cwd}}
- diff, plan, files, or owning seam: {{target}}
- approved behavior and governing evidence: {{evidence}}

Constraints and non-goals
{{constraints}}

Authority
Read-only review. Do not modify project/source files, stage, commit, push, publish, or expand scope.

Review tests
- Correctness: does the target satisfy the approved behavior and preserve required invariants?
- Scope: does every changed file and behavior support approved behavior or an invariant?
- Necessity: does every new maintenance obligation have evidence that reuse, modification, removal, or consolidation was insufficient?
- Ownership: does the change use one existing owner, or does it create a parallel mechanism or hidden coupling?
- Simplicity: can code, states, branches, wrappers, fixtures, or compatibility be removed without losing approved behavior or violating an invariant?
- Clarity: do names express domain intent, and does each changed unit have one coherent purpose without mechanical fragmentation?
A maintenance obligation is behavior, an interface, state, dependency, configuration, persisted data, abstraction, compatibility path, ownership boundary, background process, or fixture family that future contributors must maintain.

Validation expectations
{{validation}}

Required output
Return only evidence-backed current findings, ordered by severity, with file/line references, the violated criterion, and the narrowest owning-boundary correction. Classify each finding as correctness, scope, necessity, ownership, or clarity. Do not propose optional improvements. Every finding must identify a concrete current risk to approved behavior, an invariant, or the scope envelope. State explicitly when there are no findings and name residual validation gaps.

Stop rules
{{stopRules}}
Stop when the assigned angle has enough evidence. Do not continue into broad reconnaissance, redesign, or optional polish.
