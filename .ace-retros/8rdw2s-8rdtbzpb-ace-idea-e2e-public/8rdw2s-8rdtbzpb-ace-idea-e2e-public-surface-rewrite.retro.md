---
id: 8rdw2s
title: 8rd.t.bzp.b - ace-idea e2e public-surface rewrite
type: standard
tags: [assignment, ace-idea, e2e]
created_at: "2026-04-14 21:23:07"
status: active
---

# 8rd.t.bzp.b - ace-idea e2e public-surface rewrite

## What Went Well
- Rewrote `TS-IDEA-001` lifecycle runner flow to use public command output (`Idea created: <id>`) instead of hidden frontmatter ID extraction recipes.
- Reduced duplicate list assertions by narrowing TC-002 verification scope and keeping move/archive checks focused on state transitions.
- Added scenario freshness metadata (`last-verified` and maintenance policy) to make future drift visible.
- Verification remained stable: `ace-test-e2e ace-idea TS-IDEA-001` passed 4/4 cases; `ace-test all --profile 6` passed in `ace-idea` (269 tests, 0 failures).
- Release coordination completed cleanly with package version/changelog updates and clean working tree.

## What Could Be Improved
- The task referenced migration context files under `.ace-local/e2e-migration/ace-idea/` that were missing, requiring fallback to task spec + local scenario sources.
- `ace-task plan 8rd.t.bzp.b` stalled after warnings and required guard-based fallback; this needs a reliability follow-up.
- Pre-commit review fallback (`ace-lint`) reported style warnings (em-dash and blank-line formatting) that should be standardized earlier in scenario authoring.
- RubyGems propagation proof run (`TS-MONO-001`) returned PARTIAL due TC-003 runner timeout/exit `143` even though classification output was `SAFE`.

## Action Items
- Create follow-up to restore/validate expected `.ace-local/e2e-migration/ace-idea/` planning artifacts for assignment-driven planning freshness.
- Create follow-up to investigate `ace-task plan` stall behavior in this environment and improve timeout/retry handling.
- Create follow-up lint cleanup task for remaining low-severity formatting warnings in `TS-IDEA-001` docs.
- Create follow-up investigation for `ace-monorepo-e2e` TC-003 full-index install instability (exit `143`) to ensure propagation proof reliability.
