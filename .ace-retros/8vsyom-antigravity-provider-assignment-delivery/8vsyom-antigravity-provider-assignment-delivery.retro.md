---
id: 8vsyom
title: antigravity-provider-assignment-delivery
type: standard
tags: [assignment, review, forgejo, agy]
created_at: "2026-08-29 23:07:21"
status: active
---

# antigravity-provider-assignment-delivery

## What Went Well

- The durable assignment state made continuation reliable: the completed implementation subtree could be audited through reports and resumed at the parent test step without repeating task creation, planning, or release work.
- Public-contract uncertainty stayed explicit. The implementation used fake `agy` fixtures and never authenticated, invoked a real dangerous-permissions path, published a gem, or mutated GitHub.
- Valid, fit, and shine reviews found different layers of the same integration and each produced concrete improvements: prompt-size guarding, byte-accurate limits, honest auth semantics, and a separate callable-readiness signal.
- Re-running package and monorepo verification after all review fixes caught the final state rather than relying only on pre-review evidence: 334 provider tests and 9,200 repository tests passed with zero failures.
- The Lab Forgejo workflow kept the external boundary narrow: only the builder branch was pushed, the PR stayed open, and its description includes the complete grouped diff and exact head.

## What Could Be Improved

- The generic `review-pr` child still assumes GitHub PR discovery through `gh`, conflicting with the Lab preset's immutable local-diff contract. Valid and fit needed child-scoped recovery, and shine needed an explicit override.
- Review preset model aliases were stale (`review-geminie`) or passed unsupported Codex flags (`--full-auto`). Every successful review required explicit `codex:gpt-5.4` model and feedback-model overrides.
- The assignment orders PR-description update before task archival and batch retro creation. Those later commits invalidate the supposedly final PR SHA and require an extra push/update pass outside the nominal queue.
- The retained E2E scenario could not run through the Linux sandbox because `bwrap` was absent, and no supported recording binary was installed. Direct stub smoke and deterministic suites were sufficient for correctness but not for a recorded artifact.

## Key Learnings

### Review Cycle Analysis

- All five medium-or-higher findings across the three successful review sessions were verified, implemented, and resolved; none was dismissed as a false positive.
- The valid cycle caught operational failure modes (argv limits and readiness false negatives), the fit cycle refined correctness at boundaries (multibyte byte size and auth wording), and the shine cycle exposed the missing distinction between authentication and readiness across CLI output and retained smoke coverage.
- The recurrence of readiness/auth findings across all three cycles shows the initial provider boundary was underspecified. Future CLI-provider work should define `installed`, `authenticated`, and `ready` semantics before implementation rather than deriving them during review.
- Using the same explicit model for review and feedback synthesis made the three sessions reproducible when configured role aliases were unavailable.

### Delivery Workflow

- Persisted assignment reports are the right continuation boundary; terminal pane output alone is insufficient, particularly when a recovered subtree retains an original failed child for evidence.
- An explicit force-with-lease expectation SHA is more robust than relying on an absent or stale remote-tracking ref in Lab worktrees.

## Action Items

- **Start:** make Lab review child instructions natively use `upstream/main..HEAD`, disable PR comments, and pass working explicit review/feedback models.
- **Start:** add provider-contract guidance requiring separate installed/authenticated/ready semantics and byte-based argv limit analysis.
- **Start:** move task archival and final retro before the final push/PR-description step, or add a canonical final-sync step after them.
- **Continue:** require post-review package and monorepo verification whenever review cycles modify code.
- **Continue:** keep demos fixture-only for external CLIs and treat recorder/sandbox availability as an explicit evidence limitation.
- **Stop:** treating a recovered subtree's retained failed child as evidence that the successful recovery work did not complete.
