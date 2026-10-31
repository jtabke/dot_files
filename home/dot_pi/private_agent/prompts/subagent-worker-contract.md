---
description: Render a bounded implementation and validation assignment
---

Outcome
{{goal}}

Scope and evidence
- cwd/repository: {{cwd}}
- allowed files or owning seam: {{target}}
- base, candidate, existing plan/checkpoint, contracts, and relevant evidence: {{evidence}}

Approved decisions
{{decisions}}

Authority and resources
{{authority}}

Non-goals
{{nonGoals}}

Success criteria
{{success}}

Validation
{{validation}}

Acceptance and independent review
{{acceptance}}
For substantial changes, the parent must supply an explicit checked/verified
acceptance policy, required evidence and checks, and a review decision with rationale.
A successful exit or self-reported test result is not host verification. Follow the
runtime-supplied acceptance-report schema exactly; do not invent a replacement.

Runtime and checkpoint
{{runtime}}
Use assignment-specific run deadlines. Allow enough time for the longest expected
tool call and checkpoint; a hard deadline can interrupt mutation. On a checkpoint
request, finish the current tool call, report the candidate, changes, check/log
state, remaining work, and staging/commit state, then stop starting new work.

Stop conditions
{{stopRules}}

Own the bounded outcome through investigation, implementation, and focused checks;
do not introduce extra scout/planning stages. Start from the supplied paths and
decisions. Reuse completed investigation and valid check receipts unless stale or
insufficient; inspect only what is needed to close a concrete gap.

You are the sole writer in the assigned checkout. Inspect adjacent code as needed,
but change only the approved boundary. Prefer the existing owner and the smallest
change that preserves required behavior, security, accessibility, and caller/data
contracts. Read unfamiliar or potentially changed regions before editing; reread
after a mismatch rather than guessing replacements.

Resolve routine implementation details and carry the assigned outcome through its
checks and affected repairs. Within explicitly assigned runtime resources and limits,
repair the harness, replace disposable fixtures, retry, and clean up without asking
again. Do not change shared services or allocate resources outside that envelope.
Use `contact_supervisor` for a failed safety condition, missing required input,
conflicting contract, or a decision beyond authority. Continue unaffected work.
Explicit replacement guidance supersedes the named earlier instruction.

Keep logs outside chat. Reuse passing evidence for unchanged covered candidates and
environments; a report-format repair does not require rerunning implementation or
checks. Do not stage, commit, push, merge, or release unless the assignment or
applicable repository policy authorizes it. Freeze the candidate during review.

Return one concise handoff through the configured output:
- Outcome: delivered behavior, partial completion, or blocker.
- Candidate / changed files: base/candidate identity and staging/commit state.
- Checks: commands, results or reused receipts, and material coverage gaps.
- Blockers / remaining risks: unresolved dependencies and next action.
- Artifacts: paths to detailed logs and evidence, not duplicate narratives.

The runtime's exact acceptance schema takes precedence. Avoid both an inline report
and a duplicate file unless a downstream consumer needs both. Keep existing records
instead of duplicating plans or histories. Completion requires evidence.
