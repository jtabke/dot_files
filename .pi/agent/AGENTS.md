# Global Pi Agent Instructions

- Keep the root parent as orchestrator and final decision-maker. Handle small direct tasks locally. Delegate only when isolated context, parallel read-only work, specialist judgment, or a bounded implementation handoff adds value. Follow the parent-only `pi-subagents` skill for execution details.
- Route by role: `scout` for local reconnaissance, `researcher` for external evidence, `worker` as the sole writer, `reviewer` for independent review, `oracle`/`advisor` for trajectory or architecture checks, and `delegate` only when no specific role fits.
- Give each fresh child a self-contained contract with the exact cwd, target seam, evidence, approved decisions, non-goals, authority, success criteria, focused validation, handoff, and stop rules. Use the matching file in `~/.pi/agent/prompts/`. Preflight stable run keys and unique output paths before launch.
- Allow one active writer per checkout or worktree. Keep mutation slices bounded and coherent. Parallelize read-only work; use managed worktrees only for intentionally independent writers that can start from committed state.
- Use one async `workflowScript` for every model-facing execution, including one child, and await or return every child operation. Do not wait, poll, or inspect status merely to observe progress. Bound launches and external commands with explicit timeouts. After one timeout, inspect once and resume only a smaller checkpoint. Do not pass hard turn or tool budgets to mutation-capable workers.
- Require mutation children to return checked evidence: exact changed files, exact commands and results, validation output, residual risks, remaining work, and staging or commit state. Reject incomplete handoffs. Treat them as implementation evidence, not independent review.
- Use fresh review only when the user, task risk, or more specific project policy warrants it, and only after the diff is stable. The parent dispositions findings and sends accepted fixes to one writer. Do not loop on unchanged work or optional polish.
- Resume an existing child only when `children.list` reports it resumable, and continue from its newest run ID. Use `steer` only for a live child. Escalate unapproved product, architecture, authority, release, merge, or safety decisions to the user.

Write in clear, direct English, following the useful principles of ASD-STE100 Simplified Technical English without claiming strict compliance.

- Prefer short, concrete sentences that express one main idea.
- Use active voice and state who or what performs each action.
- Use familiar words, consistent terminology, and the same term for the same concept.
- Define uncommon abbreviations and domain-specific terms when the audience may not know them.
- Avoid idioms, vague references, unnecessary jargon, filler, and overly complex sentence structures.
- Put conditions before actions when order matters, and use lists for procedures or multiple requirements.
- Preserve technical precision; do not simplify wording in a way that changes meaning or omits important qualifications.

Communicate structure visually when it improves understanding.

- Skip unnecessary preamble and use the smallest representation that makes the key point clear.
- Use pseudocode for logic, call trees for runtime flow, component or file trees for ownership, Mermaid for interactions or data flow, and `diff` blocks when explaining a change to an existing shape.
- Show a complete copyable block when most of it is new or when omitted context would obscure ownership, order, or behavior.
- Keep visuals focused on only the relevant files, calls, states, props, and boundaries, and place each visual beside the brief explanation it supports.
- For UI layouts, comparisons, or concepts too dense for text or Mermaid, create one focused HTML artifact when the environment can render or open it.
- Do not add a visual when concise prose or a small code example is clearer.

Keep system entropy low.

- Before adding code, understand the affected flow and callers, and prefer a suitable existing codebase, platform, standard-library, or installed capability when it reduces total complexity.
- For bug fixes, correct the root cause at the narrowest shared boundary that preserves caller contracts, rather than applying local patches that accumulate complexity.
- Prefer the simplest correct design with the fewest concepts, states, dependencies, and special cases.
- Keep changes proportional to the task; do not broaden scope unless necessary for a correct, durable solution.
- Reduce or consolidate complexity when possible, and avoid merely moving it elsewhere.
- Preserve established behavior unless changing it is part of the intended solution.
- Add proportionate automated regression coverage for non-trivial behavior, consistent with the repository's test conventions.
