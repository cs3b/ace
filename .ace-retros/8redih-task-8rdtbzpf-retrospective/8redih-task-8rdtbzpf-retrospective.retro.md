---
id: 8redih
title: task 8rd.t.bzp.f retrospective
type: standard
tags: [e2e, migration, ace-monorepo-e2e]
created_at: "2026-04-15 09:00:33"
status: active
---

# task 8rd.t.bzp.f retrospective

## What Went Well
- Rewrote targeted E2E contracts (`TS-MONO-001` TC-002/003 and `TS-MONO-002` TC-004) to emphasize public-surface, impact-first evidence and removed internal resolver probing from config-cascade verification.
- Added missing user-facing documentation links and command-only verification guidance (`ace-monorepo-e2e/docs/release-install-verification.md`, `docs/quick-start.md`, and handbook proof docs).
- Completed full verification loop with passing targeted and package E2E runs:
  - `ace-test-e2e ace-monorepo-e2e TS-MONO-001`
  - `ace-test-e2e ace-monorepo-e2e TS-MONO-002`
  - `ace-test-e2e ace-monorepo-e2e`

## What Could Be Improved
- First TS-MONO-001 attempt failed because declared-artifact requirements were stricter than conditional runner branches; pre-creation discipline for declared artifacts should be applied earlier when rewriting scenario prompts.
- Task bundle referenced `.ace-local/e2e-migration/ace-monorepo-e2e/{plan,review}.md` paths that were unavailable in this checkout, requiring fallback to in-repo `e2e-change-plan.md`.
- Release-proof command style drift remains possible across docs because some surfaces still use positional test-id syntax while others prefer `--test-id` wording.

## Action Items
- Add a scenario-authoring checklist item in E2E rewrite flow: "every path referenced by verifier must always be emitted by runner (success and failure branches)."
- Add a lightweight validation check in migration planning to detect missing bundle file paths before implementation starts.
- Align `TS-MONO-001` invocation examples across docs with actual CLI support in this environment to avoid command-form drift.
