# Independent recovery source review — 2026-10-05

Reviewer: separate GPT-6.1 Sol agent, own frozen review worktrees. Original candidate `ded081ca63316f7d5670bab6aa75d0460fff1966`: **REJECT**. Replacement `dab0dbeea3b294d2363fe7512df29bea01537869`: **APPROVE**, no remaining verified blockers.

Verified repairs: binary/newline-safe Linux process birth parsing; expected journal registration checked inside the Herdr settlement event lock; explicit Fiddle dependency for installed consumers. Original regressions fail against the old source and pass against the replacement, including attempt/payload/key substitution under the actual event lock.

Independent replacement receipts under `.ace-wt/codex-wave4-review-recovery-fixed/.ace-local/test/reports/`:

- Runtime full: 165 tests / 440 assertions, `runtime/8x3z8r`.
- Herdr full: 454 / 1464, `herdr/8x3z8w`.
- Signed recovery: 11 / 135, `assign/8x3z99`.
- Original attribution race: 1 / 8, `assign/8x3z8r`.
- Payload/key races: 2 / 18, `assign/8x3zap`.
- Linux birth contract: 3 / 3, `runtime/8x3z98`.

All pass. Original full assignment suite separately passed 802 / 3111 with two skips; that result belongs to the original SHA. Root replacement full assignment run remains pending at this checkpoint. The original UTF-8 fixture overrequired unknown: the corrected contract accepts exact birth or unknown; both fixture versions remain retained.

This verdict accepts source integration, not installed Herdr/Pi consumption, compaction, process-tree closure, multi-UID authority or full Lab readiness. Those remain explicit domain gates; task stays in-progress.

Integration completed: replacement full assignment suite passed **803 tests / 3120 assertions**, zero failures/errors, two existing skips (`.ace-wt/codex-wave4-recovery-repair/.ace-local/test/reports/assign/8x3zcb/`). Source merged to main `3dda44055`. Post-merge signed recovery passed **11 / 135** (`.ace-local/test/reports/assign/8x3zd5/`). Installed Lab gates above remain open.
