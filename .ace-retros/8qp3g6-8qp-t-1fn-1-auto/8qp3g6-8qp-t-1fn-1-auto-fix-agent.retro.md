---
id: 8qp3g6
title: 8qp-t-1fn-1-auto-fix-agent-flags
type: standard
tags: [ace-lint, assignment]
created_at: "2026-03-26 02:17:59"
status: active
---

# 8qp-t-1fn-1-auto-fix-agent-flags

## What Went Well

- The assignment sub-steps (`onboard -> task-load -> plan-task -> work-on-task`) gave a reliable execution frame and kept scope tight to `ace-lint`.
- Introducing command-level tests early (`test/commands/lint_command_test.rb`) prevented regressions while expanding CLI behavior and exit semantics.
- Keeping commits scoped per concern made review and release steps straightforward, with a clean tree at each gate.
- Release automation was predictable once package detection was constrained to actual changed package paths (`ace-lint/**`).

## What Could Be Improved

- The release workflow's `origin/main...HEAD` package detection can over-select on long-lived branches; add a branch-window or assignment-window detection mode to reduce false positives.
- The pre-commit review step depends on `/review` availability but runs in environments where slash commands are unavailable; a first-class non-slash fallback mode should be explicit.
- Validation criteria in the task spec were initially only partially checked; adding a checklist-to-command mapping earlier would reduce end-of-task reconciliation time.

## Key Learnings

- For lint workflows, dry-run behavior and exit-code semantics must be tested together. A passing fix flow can still violate contract expectations if warning-only remainders return the wrong exit code.
- Agent-assisted flows are easiest to verify with deterministic failing models (`invalid:model`) on disposable fixtures; this confirms launch path and model pass-through without external provider dependency.
- Updating task checkboxes incrementally during implementation keeps task status transitions (`in-progress` -> `done`) consistent with evidence and reduces cleanup work.

## Action Items

- Continue: Add command-level tests when introducing new CLI flags or contract changes.
- Start: Add an assignment-aware package detection helper for release workflows that can optionally scope to commits made during the active assignment.
- Stop: Deferring task-spec checkbox updates until the end of implementation.
