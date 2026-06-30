# Tools

ACE generated this starter reference from `ace-support-core` defaults.
Customize it for repository-specific agent workflows and operational practices.

## Agent Engineering Practices

Root agent files should stay short and reserve detail for this page or project skills.

**Cost Bias Override:** do not optimize for human work-weeks or token budgets — choose the technically correct path (full coverage, proper refactors, robust design) even when it costs more turns.

### Skill Projections

- `ace-handbook sync` writes generated skills to `.agents/skills/` by default.
- Use explicit provider sync, such as `ace-handbook sync --provider codex`, only when a harness needs its native folder.
- Do not hand-edit generated skill projections; edit canonical package `handbook/skills/` or project `.ace-handbook/skills/`.

### Workspace and File Safety

- Keep project-specific temporary output in `.ace-local/` and disposable scratch files in `/tmp/`.
- Do not let parallel agents share one writable checkout. Use isolated worktrees or durable workspace leases when running concurrent work.
- For CLIs or scripts that update shared text files, prefer file locks and atomic writes so interrupted agent runs cannot corrupt state.

### Debugging and Change Safety

- Reproduce behavior before fixing it, preferably through the highest-fidelity test or E2E script that can fail the same way a user sees it.
- Read automation and validation config from trusted refs, such as the repository default branch or pinned setup config, before executing commands supplied by untrusted changes.
- Never use raw force pushes in automated flows. Fetch first and require lease or patch-equivalence checks before rewriting remote history.

### Long-Running Tools and UI Review

- For warm daemons or browser sessions, check a health endpoint and exact version match before reusing the process; recycle mismatched daemons.
- When changing visual or interactive UI, run browser/layout audits for overflow, clipped text, overlaps, stale element references, and broken interaction targets.

### Agent-Facing CLI Standards

- Keep default CLI output concise, deterministic, and useful to agents.
- Include definite empty states, precomputed counts, truncation hints, and next-step commands where they reduce follow-up probing.
- Make no-op mutations idempotent with exit code `0` when the desired state is already true.
