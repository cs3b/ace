# Verification evidence — 8wr.t.qk1.2 (2026-10-02)

Head tested: 8c89866f8e727f762ac8093cbed5c7868c996a24 (branch 8wr-t-qk1-2-named-forge-providers)

## Modified-package suites (all green, hermetic mode)

| Package | Tests | Failures | Notes |
|---|---|---|---|
| ace-git | 546 | 0 | includes new issue_tracking organisms/providers tests |
| ace-git-github | 69 | 0 | includes issue_tracking_provider contract tests |
| ace-git-forgejo | 93 | 0 | includes issue_api molecule tests |
| ace-task | 427 | 0 (2 skipped) | includes issue_link/issue_sync command + molecule tests |

Report roots: `.ace-local/test/reports/{git,git-github,git-forgejo,task}/8x116{r,l,m,n}/` (verify step 012 rerun; the subtree's verify-test run at the same head used report IDs under the same roots).

## Full suite (`ace-test-suite --target all`)

Result: 44/50 packages passed; 9168 tests passed, 10 failed, 54 skipped; 2 package timeouts. Failure classification (all independent of this branch's changes, proven as follows):

- ace-assign, ace-review — suite per-package timeout (120s budget); both PASS standalone (ace-assign 752 tests 0 fail / 8m07s; ace-review 1005 tests 0 fail / 2m49s). Slow packages, no failure.
- ace-llm-providers-cli (3), ace-support-config (1) — FAIL in suite, PASS standalone (400 / 324 tests, 0 fail). Parallel-load flakiness.
- ace-idea (1) — clipboard-dependent test (`test_creator_raises_argument_error_when_clipboard_empty`); reproduces identically on base commit 5bdc5c1f8 (scratch worktree /tmp/qk12-base-check: 270 tests, 1 fail).
- ace-test-runner (3) — worktree path assumptions (`process_monitor_test` expects main-checkout paths; fails in any non-main checkout) + hermetic env suite test; reproduce identically on base commit 5bdc5c1f8 (244 tests, 3 fail).

Conclusion: changed packages fully green; no consumer fallout from the named-forge issue sync change. Suite failures are pre-existing environment/flakiness debt, unchanged by this branch.

## Obsolete-surface scan (plan STEP-04 verification)

`rg -n 'github_issue|github_sync_pending|github-sync|GithubIssueSync' ace-task ace-git ace-git-github ace-git-forgejo` — remaining hits are deliberate rejection guards (tests asserting the old names are refused), changelog/history entries, fixture names, and archived task descriptions. No live code path, CLI command, docs example, or handbook reference uses the removed GitHub-only interfaces.
