---
id: 8q6xku
title: hidden-spec-handoff-0m6-completion
type: standard
tags: [ace-assign, hidden-spec, validation, 0m6]
created_at: "2026-03-07 22:23:10"
status: done
task_ref: 8q5.t.0m6.0
---

# Hidden Spec Handoff 0m6.0 — Task Completion Retro

Complements retro `8q6uxs` (automatic-drive-issues-0m6) which covers provider failures and fork recovery bugs. This retro focuses on task outcomes and the fork-run validation gap.

## Context

Assignment `8q6tiz` completed task `8q5.t.0m6.0` (validate hidden spec handoff end-to-end). The assignment had 14+ phases including 3 review fork subtrees (valid/fit/shine). All 4 task success criteria were met, but the session's secondary goal — validating fork-run end-to-end — was partially defeated by inline execution.

## What Went Well

- **All 4 success criteria met**: hidden spec path under `.ace-local/assign/jobs/`, runtime handoff via `ace-assign create`, provenance in assignment metadata, tracer docs for downstream slices
- **Fit review (100) found real improvements**: path formatting unification and regression test coverage for `phases/` source path preservation — both applied and released as v0.22.2
- **Reorganize-commits** reduced 9 commits to 4 logical groups (ace-assign, ace-config, project default, task-specs), making PR #242 clean and reviewable
- **PR #242 pushed** with evidence-based description and all verification commands passing
- **jobs/ vs phases/ separation** validated as the correct abstraction for hidden specs vs assignment runtime

## What Could Be Improved

- **Fork-run was never validated for the shine cycle** — the driver executed review phases 121 (review-pr) and 122 (apply-feedback) inline instead of re-forking subtree 110 via `ace-assign fork-run`. This defeated the primary validation goal of the session
- **Retries became top-level phases** — when subtree 110 (shine) failed, phases 101/121/122 were injected as top-level siblings rather than re-forking the subtree. The driver then absorbed these as inline work
- **Empty version bump v0.22.3** from the failed shine cycle — review and apply both failed but release ran anyway, producing a semantically empty version
- **Shine review (3rd cycle) found only nice-to-haves** — extracting a shared constant and restoring docs were deferred. Three review cycles show diminishing returns: valid found 1 false positive, fit found 2 real issues, shine found 0

## Key Learnings

- **Driver must delegate fork phases, never execute inline** — this is a recurring anti-pattern. The driver's job is to read reports and advance the queue, not do the fork's work. Documented in memory as `assign-driver-rules.md`
- **Review cycles have diminishing returns**: valid (false positive only) < fit (2 real findings) < shine (nothing). Two cycles may be the sweet spot for most tasks
- **jobs/ vs phases/ separation is correct**: hidden specs live in `jobs/`, assignment runtime in `phases/`. This distinction survived all review cycles unchallenged
- **Hidden-spec provenance architecture is ready** for downstream slices (0m6.1+) to build on

## Action Items

### Stop
- Executing fork-marked phases inline — always use `ace-assign fork-run`
- Running 3 review cycles when 2 consistently suffice

### Start
- Always using `ace-assign fork-run` for fork subtrees, reading reports afterward
- Re-forking failed subtrees instead of absorbing retry phases inline

### Continue
- Driver-as-guard pattern (read reports before advancing)
- Reorganize-commits before final push (9 -> 4 was valuable)
- Evidence-based PR descriptions with verification commands
