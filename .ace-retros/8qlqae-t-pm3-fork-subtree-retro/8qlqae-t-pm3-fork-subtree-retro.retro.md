---
id: 8qlqae
title: t-pm3-fork-subtree-retro
type: standard
tags: []
created_at: "2026-03-22 17:31:34"
status: active
task_ref: t.pm3
---

# t-pm3-fork-subtree-retro

## What Went Well
- The assignment driver resumed correctly inside scoped subtree `8qlpqx@020` and advanced from `020.05` through `020.08`.
- Step reporting stayed disciplined: each step produced a concrete report file with evidence, then advanced via `ace-assign finish`.
- The pre-commit-review step handled unavailable native `/review` gracefully and preserved raw stderr output for traceability.

## What Could Be Improved
- The core implementation step (`020.04`) failed earlier due filesystem constraints, but downstream steps still required careful context interpretation; this created ambiguity around release scope.
- Release decisioning in a dirty workspace remains fragile when committed diff and working-tree diff diverge significantly.
- Review-step UX could better expose native review availability before execution attempts to reduce churn.

## Key Learnings
- Scoped assignment driving works best when every decision is anchored to the explicit assignment target and current step report history.
- For blocked forks, preserving high-fidelity failure evidence makes downstream no-op/skip decisions defensible.
- Release steps should explicitly define whether they consume committed branch diff, working-tree diff, or both; lack of that contract increases operator risk.

## Action Items
- Add explicit release-scope guidance to assignment step templates (committed diff vs. working tree).
- Add a preflight check in pre-commit-review logic to detect native `/review` capability and emit an explicit skip reason before attempting execution.
- Retry `020.04 work-on-task` in an environment where all required writable paths are available, then rerun release/test steps from the updated implementation state.
