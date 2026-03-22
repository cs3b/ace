---
id: 8qlwu2
title: task-8ql-t-tt6-0-yaml-demo-spike
type: standard
tags: [ace-demo, yaml, sandbox]
created_at: "2026-03-22 21:53:24"
status: active
task_ref: 8ql.t.tt6.0
---

# task-8ql-t-tt6-0-yaml-demo-spike

## What Went Well

- Kept the spike additive: legacy `.tape` and inline recording paths remained intact while `.tape.yml` support was introduced behind targeted routing.
- Reused proven setup patterns from `ace-test-runner-e2e` to implement sandbox setup/teardown behavior quickly and safely.
- Added focused tests at each layer (atoms, molecules, organisms, CLI), which kept iteration fast and prevented regressions.
- End-to-end validation succeeded in real execution (`ace-demo record ace-task/docs/demo/ace-task-getting-started.tape.yml`) and produced the expected GIF artifact.

## What Could Be Improved

- `ace-task plan --content` stalled in this environment; planning had to fall back to path-mode/manual synthesis. This should be stabilized in tooling.
- Release workflow coordination produced multiple scope commits via `ace-git-commit`; for release steps that require a single coordinated commit, a dedicated mode or explicit guidance would reduce ambiguity.
- Pre-commit native review detection lacked explicit provider metadata in assignment session files, causing a graceful skip. Improving session metadata consistency would make review gating more deterministic.

## Key Learnings

- The YAML demo pipeline fits the existing ATOM layering well when responsibilities are strict:
  - parser/compiler in atoms
  - setup orchestration in molecule
  - end-to-end flow in organism
- Running VHS in sandbox requires cwd control (`chdir:`), not just tape generation. Adding this to `VhsExecutor` is a low-friction extension with high leverage.
- Task-scoped artifacts (concept inventory, validation evidence) are easier to maintain when they live in the task folder and are updated during execution rather than post-hoc.

## Action Items

- Add a follow-up task to diagnose and fix intermittent `ace-task plan --content` stalls.
- Add assignment/session metadata normalization so provider detection for native review is always explicit.
- Evaluate whether `ace-git-commit` needs an option to force a single coordinated commit for release workflows.
