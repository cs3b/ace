# Retro: t-ilo batch delivery

## Context
- Assignment: `8r6rat`
- PR: `#281`
- Branch: `ilo-add-soft-github-issue-integration-for-ace-task`
- Scope: linked GitHub issue sync across `ace-task`, `ace-git`, workflow/docs, review cycles, release/demo/PR delivery

## What Went Well
- The three review cycles increased signal instead of repeating the same feedback: `code-valid` surfaced correctness gaps, `code-fit` tightened failure handling and cleanup behavior, and `code-shine` found the final UX/doc polish.
- Review feedback translated into concrete shipped improvements: non-zero incomplete `github-sync`, `.s.md` task links, stale sticky-comment cleanup, surfaced create-time sync warnings, and branch-agnostic `blob/HEAD` links.
- Coordinated release steps stayed scoped to the packages that actually changed in each cycle, and the branch was successfully reorganized back down to a clean three-commit history before final push.
- The demo step produced a reusable deterministic artifact by stubbing `gh` in a tape fixture instead of depending on live GitHub state.

## What Could Be Improved
- The drive loop still required active supervision during fork waits. The assignment no longer stopped incorrectly after subtree completion, but the operating model is still fragile because a quiet fork can look stalled for several minutes.
- The shine cycle exposed review-system noise: one reviewer role was misnamed (`review-geminie`), and two of four synthesized findings were false positives. That means late-cycle polish reviews still need strong verification discipline.
- Demo discovery was weak. The task spec had usage examples, but no dedicated demo scenario or existing feature-specific tape, so the demo step required fresh design work late in the delivery tail.

## Key Learnings
- Review cycles are most effective when treated as different filters rather than interchangeable retries.
  - `code-valid`: caught correctness and behavior problems that materially changed implementation.
  - `code-fit`: focused on architecture/quality and produced cleanup-oriented fixes.
  - `code-shine`: mostly polish; its findings benefited from stronger skepticism and code verification.
- Delivery artifacts should be committed before entering any forked subtree. The new demo tape and fixture had to be committed before `150 update-pr-desc` could run safely.
- A deterministic fake for external tools is the fastest path to a stable CLI demo when the feature normally talks to remote services.

### Review Cycle Analysis
- `040 code-valid`: 5 findings, all validated, all required follow-up work.
- `070 code-fit`: 3 findings, all valid, all resolved in code.
- `100 code-shine`: 4 findings, 2 invalid, 2 resolved in code.
- Pattern: severity and usefulness dropped as the review moved later in the cycle; later passes found narrower UX/polish issues and introduced more false-positive risk.
- Recurring theme across cycles: GitHub sync behavior needed to be explicit and operator-visible, especially around failures, path accuracy, and cleanup of stale tracking artifacts.

## Action Items
- Add a supervisor-oriented helper or stronger polling convention for long-running `fork-run` steps so quiet subtrees do not require manual interpretation.
- Add a feature-specific demo scenario reference to the task spec or package docs earlier in the workflow so `record-demo` is not a late-stage design task.
- Audit reviewer role/config names used by `ace-review` presets so typo-level model routing failures are caught before a review cycle runs.
- Keep using deterministic CLI fixtures for demos of network-backed commands.
