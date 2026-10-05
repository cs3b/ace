# Controlled cleanup lifecycle verification

Final source: `c2f43b0ca8d5da614525ab0ae5a3baea242b97ca`, based on `8b01f992b`. Worktree: `.ace-wt/codex-lq8-cleanup-evidence`, branch `codex/lq8-cleanup-evidence`. Task remains in progress; root owns criterion acceptance, completion and integration. No production source, configuration, public API or timeout changed. The delivered a656b47 repair was retained.

## Exact historical failure and scope of diagnosis

Read archived R1 `.ace-tasks/_archive/8x/v/8x0.t.ig2-persist-review-campaigns-independently-of/reports/test-failure-analysis.md`, and original immutable failures/report at `.ace-wt/codex-t-ig2-review-campaigns/.ace-local/test/reports/llm-providers-cli/8x0w2x/`. Generated 2026-10-01 22:23:16, 388 tests/1012 assertions, two failures, no errors:

- `test_success_cleanup_terminates_background_descendants`, original line 289: `refute process_alive?(child_pid)`; PID 20787, `background child PID 20787 should be terminated (process status unavailable)`.
- `test_deadline_cleanup_terminates_background_descendants`, original line 310: same immediate predicate; PID 20769, `timed-out child PID 20769 should be terminated (process status unavailable)`.

The archive identifies macOS, unavailable `/proc` diagnostics, subsequent absence of both PIDs, unmodified isolated pass and non-child ECHILD reaping semantics. Original source was inspected at a656b47's parent. Signal delivery plus immediate kill(0) absence is not a lifecycle completion guarantee. These observations support the archive's confidence-qualified observation-race diagnosis; they do not prove a host-load threshold or reconstruct the precise historical orphan-reaping schedule. Current host is Darwin 25.6.0 arm64.

The new controlled test uses one real owned child: atomic pipe readiness, positively observed STOP via bounded WUNTRACED|WNOHANG, the actual macOS SafeCapture TERM/KILL sequence, positive `ps` Z evidence, original kill(0) predicate still true, existing bounded absence helper rejecting while the owned reaper is withheld behind a pipe, then explicit barrier release, waitpid/reaping, bounded absence and exact KILL termination status. Thus the old immediate assertion is demonstrably false for a killed-but-unreaped process; live and unreaped states both remain detectable. This is controlled lifecycle contention, without CPU burn, guessed load, arbitrary sleep-based acceptance or product changes. The five-second natural exit cannot satisfy the specifically checked KILL status.

Signals are disabled before the only final-reaping barrier opens; failure cleanup signals while that barrier remains closed, then releases/joins/reaps with bounded observation. A terminal result in the initial owned wait retires signaling before assertions. This preserves PID ownership rather than sending KILL after a reap.

## Executed checks at final frozen source

| Command/check | Result | Immutable receipt under worktree |
|---|---|---|
| `bin/ace-test ace-llm-providers-cli test/fast/molecules/safe_capture_test.rb` | PASS 25 tests/86 assertions, no failures/errors/skips, 4.16s | `.ace-local/test/reports/llm-providers-cli/8x4bog/` |
| `bin/ace-test ace-llm-providers-cli all` | PASS 401 tests/1053 assertions, no failures/errors/skips, 6.65s | `.ace-local/test/reports/llm-providers-cli/8x4bp7/` |
| Independent corrected-source focused execution | PASS 25/86, no failures/errors/skips, 4.56s | `.ace-local/test/reports/llm-providers-cli/8x4bq1/` |
| `bin/ace-test-suite --timeout 300` | Exit 0, all 51 configured package entries pass, 24 skips, 140.03s. Actual executed receipt reconciliation: 11203 passed tests/34177 assertions. Printed aggregate undercounts; see below. | Provider fast `.ace-local/test/reports/llm-providers-cli/8x4bpl/` (390/1025); Assign `.ace-local/test/reports/assign/8x4brj/` (806/2960, 137.10s); full stable inventory `suite-receipts-2026-10-05.json` |

The suite invocation retains the same default fast targets and uses the explicitly authorized invocation-only 300-second ceiling. Assign's unchanged fast slice took 137.10 seconds; this does not certify the configured 120-second invocation green. No suite configuration was increased. Lab appears twice in the existing 51-entry configuration and was retained twice.

## Aggregate discrepancy accounted for

The final terminal says 10838 passed tests/33238 assertions, 24 skipped, 51 passed packages. The package progress and unique `8x4bpl` receipt show the provider's executed fast slice was 390/1025. The independent focused check later wrote `8x4bq1` (25/86) and replaced the moving provider `latest` pointer before suite aggregation. `ResultAggregator#collect_results` rereads that pointer instead of preserving the executed package receipt. Substituting 390/1025 for 25/86 restores 365 tests/939 assertions, giving 11203/34177. The JSON inventory enumerates each selected package and its actual immutable receipt/file list; its direct sums agree. No broader coverage was dropped.

Prior canonical result suite receipts gave 11202/34165 with provider 389/1013: one added test/twelve assertions explains the genuine source delta. The apparent baseline deficit of 364/927 is the moving-latest artifact, not a Lab selection change. Prior Lab `8x4b8d` and current `8x4bq7`, `8x4bq8` each contain the same 28 files, 199 total/198 passed/one skipped/697 assertions. Root owns any separate reporter diagnosis; no reporter repair is included in this small task.

## Criterion mapping for independent acceptance

| Criterion | Evidence and limit |
|---|---|
| SC1 | Exact original failure/assertion/platform retained; controlled readiness and killed-but-unreaped lifecycle reproduce the observation hazard. Historical scheduling cause remains qualified. No load-average claim. |
| SC2 | Existing a656b47 bounded helper unchanged. New control refuses unreaped PID; existing five-second live child refuses short observation. No assertion hidden, unrelated PID signaled, retry acceptance or global timeout increase. |
| SC3 | Existing success/deadline SafeCapture assertions and live negative control execute in targeted, all and suite-fast receipts. New owned fixture cleans up behind an explicit reaping barrier on failure. |
| SC4 | Final all-target and default-fast executions above, controlled lifecycle evidence, independent source APPROVE for c2f43b0ca. Aggregate defect and invocation ceiling limit retained. Root independently accepts exact receipt coverage and closes criteria. |

Independent report: root's `.ace-local/review/lq8-controlled-lifecycle-source-review.md`: initial 38bf46206 REQUEST CHANGES for post-reap signal ownership and unbounded readiness/stop observation; corrected c2f43b0ca **APPROVE**, zero unresolved findings, criterion mapping accepted subject to exact broader gates. The two findings were corrected before final gates. Initial 38bf targeted 25/86 (`8x4bkd`), all 401/1053 (`8x4bl0`), and initial suite exit 0/140.09s remain pre-correction evidence only, never promoted as final-source receipts.

## Workflow limitations retained

Task-aware worktree creation failed with private `commit_scoped` on TaskCommitter and wrote inaccurate worktree frontmatter despite no-status/no-commit flags. Root removed exactly the six generated lines; the authorized fallback created this native Git worktree. Plan generation failed with Codex CLI exit 1; the loaded test/task workflows informed `test-plan-2026-10-05.md`. Initial project bundle compression stalled and was interrupted; `bin/ace-bundle project --compressor off` succeeded and the printed project bundle was read. No tooling repair, publication, native/security/VM/OS permission probe or additional agent delegation was performed.
