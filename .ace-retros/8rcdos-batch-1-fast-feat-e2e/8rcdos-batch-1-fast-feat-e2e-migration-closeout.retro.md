---
id: 8rcdos
title: batch-1-fast-feat-e2e-migration-closeout
type: standard
tags: [testing, migration, assignment]
created_at: "2026-04-13 09:07:32"
status: active
---

# batch-1-fast-feat-e2e-migration-closeout

## What Went Well

- Batch 1 packages were migrated through the fast, feat, and E2E model with the assignment completing package-by-package instead of blocking on one large change set.
- The assignment-drive workflow was tightened to use scoped assignment status as the source of truth for fork completion, which removed repeated stalls caused by waiting on quiet terminal sessions.
- The E2E fix workflow was corrected to bootstrap failure analysis when missing, which matches the intended operator contract and reduced manual intervention.
- Release and PR closeout still progressed even after review-provider instability because the work was decomposed into independent steps with explicit reports.
- Demo capture was recovered quickly once the tape problem was isolated to a hardcoded worktree path.

## What Could Be Improved

- Explicit operator-directed skips, especially test or review skips, should be captured earlier in step reports so later review cycles do not surface the same expected gap as fresh feedback.
- Review automation did not degrade gracefully on large PRs. One cycle produced useful findings, but later cycles failed on prompt-size and provider-capacity limits.
- `reorganize-commits` remains too fragile when message generation blocks after a soft reset. The workflow needs a safer recovery path or a preflight check before rewriting branch state.
- Demo tapes should not embed machine- or worktree-specific absolute paths. That failure mode is preventable and should be caught before recording.
- The assignment driver still depends on periodic polling by the active agent session. It can resume from status correctly now, but it still cannot self-wake without an active turn.

## Key Learnings

- Fix workflows need to be self-bootstrapping. Requiring callers to know hidden prerequisites breaks assignment driving and increases recovery churn.
- Forked assignment progress should be determined from assignment state and reports, not from terminal silence or output timing.
- Coordinated release workflows must document real commit behavior. A release can be logically coordinated across multiple commits, and the workflow text should not imply a single literal commit.
- Portable demo assets matter. Test and documentation artifacts should be authored to survive worktree changes and cloned environments.

### Review Cycle Analysis

- `040 code-valid` produced two feedback items. One item identified a real workflow-contract bug and led to a handbook fix. The other reflected an intentionally skipped E2E verification step and was archived with operator rationale.
- `070 code-fit` failed entirely because `review-codex` exceeded prompt limits and `review-gemini` returned a capacity error. That cycle produced no actionable signal.
- The practical result was that early review provided some value, but later cycles were dominated by tool limits rather than code quality findings.

## Action Items

- Make review workflows chunk or trim large PR context before sending it to provider-specific reviewers.
- Add a preflight safety check or recovery helper for `reorganize-commits` before any soft reset changes branch state.
- Enforce portable path conventions for demo tapes and add a validation rule that rejects worktree-specific absolute paths.
- Capture operator-approved verification or review skips explicitly in assignment closeout artifacts and PR context.
- Continue pushing fix workflows toward self-contained behavior when they depend on prerequisite analysis.
