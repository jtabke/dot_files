---
description: Render an independent review of a specified candidate
---

Review question
{{goal}}

Target
- cwd/repository: {{cwd}}
- exact candidate commit/patch, base, files, or owning seam: {{target}}
- approved behavior, contracts, and governing evidence: {{evidence}}

Constraints
{{constraints}}

Validation
{{validation}}

Stop conditions
{{stopRules}}

Review read-only. Verify candidate identity before reviewing; report a mismatch
instead of substituting another revision. Do not modify source, stage, commit,
publish, or mutate shared services. Use only explicitly assigned validation resources.

Check correctness, contract preservation, scope, and necessity. Identify new states,
dependencies, compatibility paths, or abstractions without a required outcome, and
parallel owners or hidden coupling that create a concrete current risk. Keep the
review focused on the assigned behavior; do not turn it into redesign or polish.

Return the candidate identity and evidence-backed findings by severity with file/line
references, impact, and the narrowest correction. State when there are no findings.
Name material validation gaps and unresolved assumptions. Re-review only accepted
fixes and affected areas after a change; a clean review is not proof of pending
integration checks. Stop when the assigned question has enough evidence.
