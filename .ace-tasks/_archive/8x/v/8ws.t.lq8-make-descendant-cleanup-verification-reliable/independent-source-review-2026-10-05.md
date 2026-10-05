# Independent lq8 controlled lifecycle source review

Candidate: `38bf46206076e25d20457149ad6e564cf7666492`
Base: `8b01f992b`
Host: Darwin 25.6.0 arm64.
Initial verdict: REQUEST CHANGES at `38bf46206076e25d20457149ad6e564cf7666492`; corrected source rereview follows below.

## Verified findings

1. **P2 — Never signal a PID after its child ownership has ended.** `ace-llm-providers-cli/test/fast/molecules/safe_capture_test.rb:364-366` unconditionally sends KILL in ensure. On the ordinary success path the reaper has already returned from wait2 and its value has been checked at lines 358-361. The PID is therefore reusable and no longer identifies an owned child. On failure, closing reap_writer first also releases the reaper, so a boolean updated after wait2 would leave the same race. Coordinate reaping and signaling so KILL can occur only while ownership is positively retained; no post-reap signal. This violates the explicit no-unrelated-kill criterion. No unrelated process was killed to demonstrate this finding.

2. **P2 — Bound readiness completion, not only its first byte.** Lines 339-341 perform blocking `ready_reader.read` followed by blocking `Process.wait2(pid, Process::WUNTRACED)`. The 0.5-second `wait_readable` covers only the availability of the pipe's first bytes; it does not bound EOF or the stopped-status observation. A child descheduled after writing readiness can leave either call waiting beyond the declared bounded fixture period, until the outer package timeout. Poll owned stopped status with WNOHANG under a monotonic deadline and use a bounded exact readiness read. The fixture specifically exists to eliminate assumed scheduler progress, so its controlled readiness phase should have the same bounded guarantee as its later observer.

## Evidence and criterion mapping

Actual TERM/KILL, positively observed Z state, kill(0) still reporting the unreaped PID, refusal by the bounded observer before pipe release, then waitpid and successful absence are meaningful controlled observation evidence. The unchanged success/deadline product tests and live five-second negative control remain present; no production implementation or timeout was changed. The new child's sleep cannot create a false pass: the child is stopped and the observed final status must specifically report KILL.

Read the archived `.ace-tasks/_archive/8x/v/8x0.t.ig2-persist-review-campaigns-independently-of/reports/test-failure-analysis.md`. It records the historical success assertion at line 289 on macOS and later success/deadline kill(0) failures under the parallel suite, followed by both PIDs absent and unmodified standalone passes. Its cause classification is explicitly confidence-qualified. The new controlled owned-reaper fixture demonstrates the observation hazard; it does not reconstruct or prove the exact historical orphan/scheduler cause. The test plan states that distinction honestly.

Once the ownership and bounded-readiness findings are repaired and exact-candidate package/default suite gates pass, this controlled contention evidence can satisfy remaining SC1/4 as interpreted by the reviewed readiness scope. The current candidate cannot yet close those criteria, and standalone success is not a fix receipt.

Independent focused execution: `bin/ace-test ace-llm-providers-cli ace-llm-providers-cli/test/fast/molecules/safe_capture_test.rb`, exit 0, 25 tests / 86 assertions, zero failures/errors, 4.44 seconds. Receipt directory: `/Users/mc/Ps/ace/.ace-wt/codex-lq8-cleanup-evidence/.ace-local/test/reports/llm-providers-cli/8x4bmc/`. This passing run does not disprove the source-level ownership/time-bound findings.

No candidate/source edits, agent delegation, host-load burn, native 09j/VM/OS security probes, push or publication. Waiting for corrected freeze; old evidence remains attached only to the SHA above.

## Corrected frozen source rereview

Candidate: `c2f43b0ca8d5da614525ab0ae5a3baea242b97ca`, same base `8b01f992b`.
Verdict: **APPROVE source; zero unresolved verified findings.** Final SC4 completion remains subject to root checking the exact-candidate package/default-suite receipts and their selected coverage.

Both P2 findings are resolved in the actual correction delta. Readiness uses an exact nonblocking five-byte pipe read after the bounded readability check; the stopped-child helper polls WUNTRACED|WNOHANG under a monotonic deadline. If that wait returns terminal status, signaling permission is retired immediately before assertions. The reaper cannot perform its final wait until the pipe gate opens; signaling permission is retired before opening that gate. On earlier failure, ensure sends KILL while the gate remains closed, then closes the gate and joins/reaps. Thus the boolean is not a post-waitpid race: ownership is structurally preserved until signaling has been disabled. No post-reap KILL remains.

The test still positively observes stopped readiness, actual KILL termination/Z, the immediate predicate's false absence, bounded rejection while unreaped, and exact signaled KILL status after controlled waitpid. Existing live-negative, success and deadline tests are unchanged. No sleep supplies passing evidence; short polling intervals are bounded by monotonic deadlines, and the child's five-second sleep cannot satisfy the checked killed status. This is acceptable bounded controlled lifecycle contention evidence for remaining SC1/4, while retaining the explicit historical-cause confidence limit.

Independent corrected-candidate focused execution: same bin/ace-test command, exit 0, 25 tests / 86 assertions, zero failures/errors/skips, 4.56 seconds. Report read and verified at `/Users/mc/Ps/ace/.ace-wt/codex-lq8-cleanup-evidence/.ace-local/test/reports/llm-providers-cli/8x4bq1/report.md`. Earlier passing receipt and REQUEST CHANGES verdict are preserved for their original SHA and are not promoted as corrected-source evidence. Broader author gates are running and are not independently certified by this report.
