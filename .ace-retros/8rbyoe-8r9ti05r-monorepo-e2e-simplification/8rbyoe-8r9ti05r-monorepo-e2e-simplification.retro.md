---
id: 8rbyoe
title: 8r9.t.i05.r monorepo e2e simplification
type: standard
tags: [assignment, e2e, migration]
created_at: "2026-04-12 23:07:06"
status: active
---

# 8r9.t.i05.r monorepo e2e simplification

## What Went Well
- Completed the full review -> plan -> rewrite lifecycle with explicit TC-level decisions recorded in `ace-monorepo-e2e/test/e2e/e2e-change-plan.md`.
- Brought `ace-monorepo-e2e` scenarios back to green end-to-end (`ace-test-e2e ace-monorepo-e2e` => 2/2 scenarios, 8/8 test cases).
- Converted brittle scenario assumptions to current contracts (source-root setup fallback, modern `ace-task show` usage, resilient verifier expectations).
- Kept release discipline clean: task and package changes were committed in scoped commits with clear intent.

## What Could Be Improved
- `ace-task plan 8r9.t.i05.r` path-mode invocation stalled in this environment; workflow fallback was needed and should be more robust.
- Runner/verifier artifact declarations were too strict for conditional install paths, causing avoidable harness-level failures before behavior-level assertions.
- Quick-start task ID extraction depended on filename parsing; frontmatter ID should be used consistently across all similar scenarios.

## Action Items
- Add a follow-up task to harden plan generation against path-mode stalls in assignment execution contexts.
- Audit other E2E scenarios for `PROJECT_ROOT_PATH`-only setup commands and migrate to `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}` fallback where appropriate.
- Audit quick-start style scenarios for deprecated CLI flags (`--format`) and file-name-derived IDs; standardize on canonical IDs from frontmatter or command output.
