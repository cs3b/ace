---
id: 8reiu8
title: "Retro: 8rd.t.bzp.o e2e suite rewrite"
type: standard
tags: [ace-task, e2e, migration]
created_at: "2026-04-15 12:33:36"
status: active
---

# Retro: 8rd.t.bzp.o e2e suite rewrite

## What Went Well
- Rewrote `TS-TASK-001` smoke runners/verifiers to use deterministic ref handoff artifacts, which removed flaky ref parsing paths.
- Added `TS-TASK-002` auxiliary journeys (`status`, `plan`) with clear runner/verifier contracts and got full suite green (`6/6` cases).
- Kept scope discipline through assignment sub-steps and produced clean release artifacts (`ace-task v0.35.5`) with a clean working tree at closeout.

## What Could Be Improved
- Planning inputs referenced `.ace-local/e2e-migration/ace-task/{review,plan}.md` that were missing in this checkout; that forced inference from task spec + existing suite files.
- `ace-task plan` command behavior depends on environment presets/provider availability; auxiliary E2E coverage had to encode explicit diagnostic expectations for unavailable dependencies.
- Pre-commit review fallback required multiple lint cleanups after implementation; running lint earlier in the edit loop would reduce rework.

## Action Items
- Add/restore missing migration context artifacts before future package rewrites so planning can anchor to canonical review/plan docs.
- Consider adding machine-readable task ref output modes (or stable parse hints) in `ace-task create` to reduce runner-side parsing ambiguity.
- Add an explicit preflight check pattern for `ace-task plan` dependency readiness (`project` preset + planner model availability) in E2E journey guidance.
