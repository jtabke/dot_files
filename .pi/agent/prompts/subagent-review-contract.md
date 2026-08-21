---
description: Render a self-contained fresh-context independent review contract
---
Review goal and angle
{{goal}}

Target
- cwd/repository: {{cwd}}
- diff, plan, files, or source seam: {{target}}
- intended behavior and governing evidence: {{evidence}}

Constraints and non-goals
{{constraints}}

Authority
Read-only review. Do not modify project/source files, stage, commit, push, publish, or expand scope.

Validation expectations
{{validation}}

Required output
Return only evidence-backed findings, ordered by severity, with file/line references and the smallest safe fix. Separate blockers and fixes worth doing now from optional suggestions. State explicitly when there are no findings, and name residual validation gaps.

Stop rules
{{stopRules}}
Stop after the assigned angle has enough evidence; do not continue into broad codebase reconnaissance or optional polish.
