---
id: 8rehzv
title: "Retro: 8rd.t.bzp.m public-surface E2E migration"
type: standard
tags: [assignment, 8rd.t.bzp.m, ace-support-models]
created_at: "2026-04-15 11:59:52"
status: active
---

# Retro: 8rd.t.bzp.m public-surface E2E migration

## What Went Well
- Migrated `ace-support-models` E2E scenario `TS-MODELS-001` to a public-surface flow with 6/6 goal passes.
- Added deterministic sync-fixture support (`ACE_MODELS_FIXTURE_JSON` and `ACE_MODELS_API_URL`) so provider/cache flows use `ace-models sync` rather than hand-seeded cache internals.
- Completed release + follower update cleanly with coordinated commits:
  - `ace-support-models v0.11.0`
  - `ace-llm v0.34.1` (dependency follower)
- Release-proof verification passed via `ace-test-e2e ace-monorepo-e2e TS-MONO-001` with classification `SAFE`.

## What Could Be Improved
- Initial E2E additions used `TC-new-*` filenames that violated runner filename constraints; enforcing numeric TC IDs up front would avoid one rerun.
- The `ace-task plan` invocation stalled in this environment; the workflow needed a manual fallback to direct plan construction from task + code context.
- `pre-commit-review` fallback lint produced markdown-parser warnings on mixed-format files; scoped lint presets for non-markdown files would reduce noise.

## Action Items
- Add a lightweight validator/checklist for E2E filename conventions before running `ace-test-e2e`.
- Add an automated stale/missing context file pre-check for task bundles (e.g., missing `.ace-local/e2e-migration/...` references).
- Track `ace-task plan --content` stall behavior as a follow-up reliability improvement in planner workflows.
