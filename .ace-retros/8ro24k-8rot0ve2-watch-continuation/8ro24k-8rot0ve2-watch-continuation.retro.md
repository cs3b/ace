---
id: 8ro24k
title: 8ro.t.0ve.2 watch continuation
type: standard
tags: [ace-assign, watch, recovery]
created_at: "2026-04-25 01:25:04"
status: active
---

# 8ro.t.0ve.2 watch continuation

## What Went Well
- Extended `ace-assign watch` without replacing the scoped-target shell from the prior sibling task, so the new wait/recovery loop stayed aligned with the already-shipped public command surface.
- Added direct fast coverage for the new behavioral risks: live wait, stale-session recovery, `Errno::EPERM` as alive, sequential multi-root continuation, and scoped non-widening.
- Package-level verification exposed environment leakage from the forked assignment shell before release, which let the subtree document the clean-env verification path instead of shipping ambiguous test evidence.

## What Could Be Improved
- Package verification inside a scoped `/as-assign-drive` session inherits `ACE_ASSIGN_*` variables that can contaminate unrelated tmux/launcher tests; the verification workflow should clear fork-only env by default before running package suites.
- The `watch` implementation reused assignment-in-condition patterns that lint flagged late in the review step; keeping lint in the implementation loop earlier would have avoided two small follow-up style commits.
- The release step still arrived through the compatibility `wfi://release/publish` shim, which adds one extra read/translation hop during subtree closeout.

## Action Items
- Update assignment verification guidance or helpers so package-level test runs inside forked subtree sessions start from a neutral `ACE_ASSIGN_*` environment.
- Keep `ace-lint` in the implementation loop for command-layer Ruby changes before the pre-commit-review step to reduce style-only follow-up commits.
- Consider retiring assignment preset references to `wfi://release/publish` in favor of `wfi://release/local` directly so release steps expose the current workflow without the compatibility shim.
