---
id: 8rblp7
title: 8r9.t.i05.i ace-sim fast-feat-e2e migration
type: standard
tags: [testing, migration, ace-sim]
created_at: "2026-04-12 14:28:01"
status: done
---

# 8r9.t.i05.i ace-sim fast-feat-e2e migration

## What Went Well
- Deterministic test migration was low-risk: moving `commands/molecules/models/organisms` tests into `test/fast` only required path-fix updates and kept all assertions intact.
- `ace-test ace-sim` and `ace-test ace-sim all` passed immediately after relocation, confirming no regression in deterministic lanes.
- E2E coverage stayed workflow-focused and a concrete decision record was added (`e2e-decision-record.md`) with explicit KEEP/MODIFY outcomes.
- Package release flow was smooth after implementation: semver bump to `0.14.0`, package/root changelog updates, and clean scoped release commits.

## What Could Be Improved
- `ace-task plan 8r9.t.i05.i` path-content mode stalled and required manual plan synthesis from task/context files.
- `ace-test-e2e` artifact declaration behavior is brittle when TC runner/verify docs use wildcard artifact names (`run.*`) or conditionally produced files; this caused repeated false-negative failures until runner/verifier contracts were tightened.
- Scenario setup using only `$PROJECT_ROOT_PATH` is fragile in sandbox modes where source roots are externalized; `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}` was required for robust `mise.toml` bootstrap.

## Action Items
- Add/standardize an E2E authoring rule: never declare wildcard artifact paths in runner/verify docs; always use explicit `*.stdout/*.stderr/*.exit` files.
- Add an E2E verifier contract rule that conditional artifacts must either be always materialized (placeholder allowed) or excluded from strict required-artifact extraction.
- Investigate and fix `ace-task plan --content` hanging behavior for directory-style context entries (e.g., `ace-sim/test/e2e`) to avoid manual plan fallback.
