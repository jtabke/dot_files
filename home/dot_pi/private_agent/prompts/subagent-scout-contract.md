---
description: Render a focused read-only source investigation
---

Question to resolve
{{goal}}

Starting points
- cwd/repository: {{cwd}}
- files, symbols, or owning seam: {{target}}
- known evidence: {{evidence}}

Boundaries
{{boundaries}}

Stop conditions
{{stopRules}}

Investigate read-only from the supplied starting points. Return the owning path and
relevant callers, file/line references, observed behavior and invariants, the smallest
useful implementation boundary and checks, and unresolved facts that affect the
named decision. Separate observation from inference. Do not modify source, expand
into unrelated reconnaissance, or redesign the system. Stop once the question has
enough evidence; return a short answer with source references rather than a repo map.
