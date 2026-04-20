---
id: 8rdnwl
title: 8rd.t.bzp.3 ace-compressor public-surface e2e rewrite
type: standard
tags: [8rd.t.bzp.3, ace-compressor, e2e]
created_at: "2026-04-14 15:56:13"
status: active
---

# 8rd.t.bzp.3 ace-compressor public-surface e2e rewrite

## What Went Well
- Preserved retained smoke coverage (help + per-source output) while adding missing public workflows for `--mode agent` and `benchmark`.
- Replaced brittle compact-refusal fixture dependency with a deterministic rule-heavy policy document that still validates refusal semantics.
- Completed full verification inside the subtree:
  - `ace-test-e2e ace-compressor` passed (`TS-COMP-001`, 6/6 cases).
  - `ace-test ace-compressor` and `cd ace-compressor && ace-test all --profile 6` passed.
- Completed release flow in the same execution path, including version bump to `ace-compressor v0.25.0`, package changelog update, root changelog entry, and lockfile refresh.

## What Could Be Improved
- The task bundle referenced `.ace-local/e2e-migration/ace-compressor/review.md` and `plan.md`, but neither file existed in the workspace, so planning relied on spec + live suite inspection.
- TC-004 initially failed after making fixture generation more flexible; refusal behavior required an explicit rule-heavy content shape to remain reliable.
- Pre-commit review fallback depended on `ace-lint` because conversation-native `/review` was unavailable in this execution context.

## Action Items
- Ensure migration planning artifacts referenced by task bundles are present and accessible before plan-task starts.
- Add a reusable rule-heavy compact-refusal fixture pattern for compressor-like suites to reduce first-run oracle misses during rewrites.
- Consider reducing non-actionable runtime warning noise in agent/benchmark stderr paths so verifier contracts can safely include stronger stderr assertions.
