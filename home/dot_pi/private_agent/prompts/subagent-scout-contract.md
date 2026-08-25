---
description: Render a focused local reconnaissance contract
---
Question or decision this reconnaissance must unlock
{{goal}}

Target
- cwd/repository: {{cwd}}
- starting files, symbols, or owning seam: {{target}}
- known evidence: {{evidence}}

Boundaries
{{boundaries}}
Read-only reconnaissance. Do not modify project/source files, stage, commit, push, or publish. Do not redesign the system or map unrelated areas.

Required output
Return the minimum evidence the parent needs to make the named decision or write a bounded worker contract:
- current owning boundary and relevant callers;
- exact file/line ranges and observed data flow;
- existing mechanism that can be reused, modified, removed, or replaced;
- required behavior and invariants visible in source;
- smallest independently testable implementation seam;
- focused validation commands;
- unresolved questions that require a decision.
Distinguish observed facts from inference. Do not propose optional improvements or generalized architecture. Report an adjacent observation only when it is evidence of a concrete current risk to the named decision.

Stop rules
{{stopRules}}
Stop when the named decision has enough evidence. Do not continue searching to make the report comprehensive.
