# Implementation evidence

Root independently approved the repaired behavioral spec on 2026-10-06 before CLI promotion to pending, then progress. The worktree base is `2e94277111276bb0864076735028a1864e3fe02b`; branch `codex/wave-412` is isolated from the primary checkout.

Automatic and explicit allocations share a permanent exclusive claim. Atomic mkdir refuses automatic candidates that already exist; an explicit contender claiming a newly created automatic directory causes the automatic invocation to retry elsewhere. Existing empty explicit paths admit one owner. Allocation failures return an actionable failure before extraction or model calls. Both allocators retain claimed state after interruption.

Release exports copy into a private temporary file, then atomically publish with nonreplacing hard links on the same filesystem. Equal clocks/models preserve separate complete reports. Failed copy tests leave the original session readable and publish no partial report. Successful single-model output now exposes and prints its session path. Feedback create discovers `review.md` in the exact selected session.

## Verification

- `bin/ace-test ace-review all`: 955 tests, 3063 assertions, zero failures/errors, four existing opt-in performance skips. Receipt `.ace-local/test/reports/review/6a896500-d22d-43a5-bbe2-4c702839c48e/`. This executed the final production source and existing campaign/delta/evidence coverage; the final additional CLI/provenance test assertions are covered by the later targeted receipt below.

- `bin/ace-test ace-review fast test/fast/organisms/review_session_allocation_test.rb test/fast/commands/feedback/create_test.rb`: 18 tests, 45 assertions, zero failures/errors. Receipt `.ace-local/test/reports/review/461d12a1-2264-4ecc-a259-504b7899bb5e/`.
- `bin/ace-test ace-review feat test/feat/review_session_concurrency_test.rb`: 6 tests, 100 assertions, zero failures/errors. Receipt `.ace-local/test/reports/review/ef950129-3256-49c7-b68d-de13c132e968/`. Includes process-level automatic and explicit races, interrupted ownership, fixed-clock prompt/metadata and checkout SHA identity, controlled model completion in both orders, actual feedback Create/List with exact paths, and a real CLI refusal.
- Documentation lint exited zero; both usage documents are clean. Changelog has 638 warnings in historical content outside the new entry. Receipt `.ace-local/lint/8x5xvj/`.
- `git diff --check` passes.

The generated implementation plan is `.ace-local/task/8x4.t.412/8x5xtd-plan.md`. Readiness/task-work/worktree-create/test-plan/commit/usage/changelog workflows were loaded and followed within authorized scope. No versions or historical review artifacts were changed.

Independent final source review and root integration remain delivery gates. Task status stays progress for root-owned closure. Opt-in performance tests remain opt-in; no live paid reviewer is needed by these regression tests. Temporary interrupted export staging files can remain after process kill; they are private `.tmp` files and never appear as completed release reports.
