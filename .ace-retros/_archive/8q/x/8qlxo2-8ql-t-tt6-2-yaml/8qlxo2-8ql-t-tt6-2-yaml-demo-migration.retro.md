---
id: 8qlxo2
title: 8ql-t-tt6-2-yaml-demo-migration
type: standard
tags: [demo, migration, yaml]
created_at: "2026-03-22 22:26:45"
status: active
task_ref: 8ql.t.tt6.2
---

# 8ql-t-tt6-2-yaml-demo-migration

## What Went Well
- Bulk migration strategy worked: scripted conversion removed repetitive manual edits across 23 package demos.
- End-to-end validation was strong: all 23 `.tape.yml` files parsed and recorded successfully in one batch run.
- Safety checks caught regressions early (hardcoded live ID scan, remaining `.tape` scan, and repeated `ace-demo list` checks).
- Assignment loop discipline kept progress visible: each sub-step produced report artifacts and explicit evidence.

## What Could Be Improved
- The first fixture-heavy setup template included `git-init` and failed in one environment due hook-template copy conflicts.
- Demo execution created side-effect task/idea artifacts from command scenes; these had to be cleaned after verification.
- Pre-commit native review invocation was ambiguous for shell execution (`/review` not directly available), causing a skip instead of analysis.
- Release-minor instructions conflicted with docs/demo-only scope; clearer policy for no-op release cases would reduce uncertainty.

## Key Learnings
- For YAML demo migrations, prefer minimal deterministic setup first (`sandbox`, `copy-fixtures` only where needed), then add commands incrementally.
- Batch record validation is essential for migration tasks at this scale; per-file spot checks are insufficient.
- Task specs should explicitly separate “content migration” from “package release requirement” to prevent unnecessary version churn.
- Demo command design should avoid writing persistent repo artifacts unless intentionally part of the demo scenario.

## Action Items
- Update demo migration guidance to discourage unconditional `git-init` in fixture setups; document known sandbox edge cases.
- Add a cleanup guard to demo verification workflow to detect and remove side-effect artifacts automatically.
- Add a documented fallback for pre-commit review when native `/review` is unavailable (for example, use `ace-review --preset code --subject diff:HEAD~1..HEAD --dry-run`).
- Propose a release workflow note: allow explicit no-op release path for demo/docs-only subtrees with evidence.
