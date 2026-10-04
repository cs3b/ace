# Verification record — 8ws.t.ibk

- **Exact SHA reviewed and tested:** `644d851e4b9011f12e5eda74be10a4895f020821` (branch `t.ibk-isolate-status-evidence-tests`, base `0324c43eb`)
- **Commits:** `906e97753` test isolation (fixtures + seam + sentinel + matrix), `fffb3b300` task in-progress, `1416abafe` CHANGELOG, `644d851e4` review-finding hardening (File.realpath)

## Executed tests

- `bin/ace-test ace-assign all` (standalone, hermetic): **772 tests, 2880 assertions, 0 failures, 0 errors** (8m 41s), report `.ace-local/test/reports/assign/8x30da/`.
- `bin/ace-test-suite` (monorepo, quiet machine): **50/50 packages passed, 10,876 tests, 0 failures**; ace-assign slice 760 tests / 2756 asserts / 0 fail in 99.75s (suite.yml ceiling 120s).
- Note: a first suite invocation reported an ace-assign timeout — caused by running it concurrently with the standalone package run and the LLM review on the same machine, not by this change; the quiet re-run above is the valid SC4 evidence.

## Independent review

- Session: `.ace-local/review/sessions/review-8x30g0/review-report-review-default.md` (preset `code-valid`, subject `diff:0324c43eb`).
- Verdict: **Approve** — no Critical/High/Medium findings.
- Findings disposition: Low #1 (worktree-path canonicalization) **applied** as `644d851e4` exactly as recommended (verified empirically: git registers the symlink-resolved `/private/var/...` form under macOS TMPDIR); Low #2 (snapshot failure ergonomics) and Low #3 (process-global seam note) **accepted, no action** — cosmetic/observational per reviewer.

## Success-criteria mapping

- **SC1** — `test_status_json_evidence_reflects_the_displayed_assignment`: test-owned repo with real journaled evidence; exact displayed attempt, base head, evidence ref, journal commit; other assignment's attempt/receipt excluded (`review_receipt` stays `missing`); other assignment's own query returns its own evidence.
- **SC2** — `test_status_json_leaves_ambient_repository_evidence_state_untouched`: sentinel repo with pre-existing evidence ref, registered detached worktree, tracked+untracked files; snapshot (ref SHA, `worktree list --porcelain`, recursive file digests) identical before/after the status flow while the sentinel is the ambient repository.
- **SC3** — fixture ref absent, seed-only, and stale-checkout cases; stale-checkout rebuild asserted confined to the fixture repository; ambient env/cwd restored in `ensure`; tests clean only the class temp dir.
- **SC4** — package + suite results above at SHA `644d851e4`; independent review verdict recorded in this file.
