# Code Review — SIGCHLD disposition hardening + review-evidence retention (fbf5e48f…47466eb0)

## Summary & Verdict

**✅ Approve with follow-ups.** The production change (`Signal.trap("CHLD", "DEFAULT")` in `OwnedChildScope`) is a correct, minimal, fail-closed fix for a real defect class, and the loosened kernel-test assertion remains discriminating. No Critical/High code findings. One Medium process gap: this delta ships **no attached executed-test evidence**, which the disposition file itself acknowledges ("requires fresh R6 checks and independent Pi delta before integration") — under the repo's merge gate (executed tests + independent reviewer verdict) this commit is not yet mergeable as-is.

## Deep Diff Analysis

**1. `ace-runtime/lib/ace/runtime/molecules/owned_child_scope.rb:20-23` — SIGCHLD reset (the core fix)**
- **Intent:** An inherited `SIG_IGN`/custom CHLD disposition in the helper process would auto-reap or steal the wait status of the command leader, unpinning its PID and breaking both `cleanup!`'s `owned.include?(leader)` invariant and the executor's `waitpid2(child)`. Verified real: without the reset, `sigchld_ignored` ends in `Errno::ECHILD`/`CleanupUncertain` and `sigchld_reaper` steals the leader's status.
- **Ordering verified correct:** sole-thread check → empty-children assertion → trap reset → subreaper `prctl(36)` → (back in `command_executor.rb#launch`) `fork`. The reset precedes the leader fork, so the leader is born under `SIG_DFL` and remains a zombie until the executor reaps it. `SIG_DFL` for CHLD is kernel-ignore-with-zombie — exactly what `waitpid2`/`waitpid(WNOHANG)` loops require; it cannot cause `EINTR`.
- **Fail-closed:** if `Signal.trap` were to raise, the constructor aborts before any fork — no child is spawned, no partial state.
- **Containment verified:** `OwnedChildScope` has exactly one production consumer (`command_executor.rb:49`), the ephemeral sole-thread executor helper; grep confirms no other includer/caller. The process-global, non-restored mutation is acceptable *within that contract* (see Refactoring for the residual note).

**2. `ace-lab/test/support/command_executor_probe.rb:147-156` — new fixture modes**
- Both traps are installed **inside the forked helper only** (after `client.close`/`result_read.close`, before `CommandExecutor#run`); the minitest parent process and its `Process.waitpid(helper)` are unaffected. Good containment.
- The custom-reaper block (`waitpid(-1, WNOHANG)` loop, `rescue Errno::ECHILD`) is a faithful stand-in for a foreign in-process reaper. Between registration and the constructor's reset, the helper has no children, so the handler cannot distort the pre-fix baseline.
- Both modes correctly fall through to the generic `else` python program (`sys.exit(17)`) and non-tty pipes mode.

**3. `ace-lab/test/feat/command_executor_kernel_test.rb:21-30` — new tests + loosened assertion**
- New tests assert exactly the discriminating outcome: no error + `exit_status == 17`. Both are red-by-construction against the pre-fix molecule.
- The loosened `assert_includes %w[IOError Errno::EPIPE Errno::ECONNRESET], result["error"]` was validated against the actual error surfaces: `pump`'s `read_nonblock` EOF → `IOError` (`command_executor.rb` "command client disconnected"); `send_frame` → `ProtectedSocket.write`'s `write_nonblock` — `exception: false` suppresses only wait-writable, so hard `Errno::EPIPE` still propagates. `Errno::ECONNRESET` is defensive (AF_UNIX rarely yields it) but harmless. The assertion stays tight: `nil` (silent canonical success) fails it, and the companion assertions `assert_nil result["result"]` + `refute survived_cleanup` are unchanged. This is a targeted loosening, not a blanket accept — deadline/`RuntimeUnavailableError` classes are still rejected.
- `result["error"]` is recorded as `exception.class.name` in the probe, so string comparison against the class-name list is correct.

**4. Evidence/dispositions files** — all manifest-referenced files exist (verified for both manifests); the two APPROVE reviews cover the *prior frozen heads* (`45927f8`, `f6d6f51`), i.e., the pre-delta freezes, not this delta. The dispositions file is internally consistent with the review reports and the code changes made in response.

## Code Quality Assessment

- Complexity delta is minimal: one constructor line + 4-line comment in the molecule; probe additions are linear mode branches matching the existing style.
- Consistency: new tests follow the file's established `probe(mode)` / `assert_nil result["error"]` / `dig("result", …)` patterns exactly.
- Minor (Low, non-blocking): both `pi-response.json` files end without a trailing newline; `review-dispositions.md` has a few missing spaces around SHAs ("cleanup45927f853", "is766", "at most5 seconds") — cosmetic only.

## Architectural Analysis

- **Pattern compliance:** the signal reset lives in the runtime molecule (not the lab organism), keeping the reaping invariant next to the ownership/subreaper contract it protects. Correct layer.
- **Component boundaries:** no interface changes; `cleanup!`/`children`/`zombie?` signatures untouched. The one production consumer is unchanged.
- **Dependency changes:** none.

## Documentation Impact Assessment

- The constructor comment explains *why* the reset must precede the empty-set/fork window — good.
- `command-run-design.md` is referenced by evidence but not updated for the SIGCHLD disposition rule; the dispositions file carries the rationale instead. Suggestion: fold the "incoming SIGCHLD must be DEFAULT in the sole helper" contract into the design doc's OwnedChildScope section when R6 lands.
- No API changes; no migration notes needed (pre-1.0, ADR-024).

## Quality Assurance Requirements

- **⚠ Medium — no executed evidence for this delta.** The only executed runs cited anywhere (R5 kernel 7/64, domain 40, runtime 300/1220) predate these changes; the dispositions file itself defers "fresh R6 checks and independent Pi delta before integration." Action item: execute `bin/ace-test` root kernel fixture (now 9 scenarios) + the independent delta review before merge, per the merge gate.
- **Suggestion — molecule-level coverage gap:** `ace-runtime/test/molecules/owned_child_scope_test.rb` uses `allocate` and bypasses the constructor entirely, so the new trap reset has zero unit coverage and is only exercised by root-only fixtures that skip on macOS dev hosts. On Linux CI (non-root) `OwnedChildScope.new` succeeds — a small unit test asserting `Signal.trap` receives `("CHLD", "DEFAULT")` (via `Signal.singleton_class.stub`) and that it raises on non-Linux/multi-thread would pin the contract cheaply.
- Re-run the full `detached`/`detached_disconnect` pair together: the loosened assertion and the trap reset interact only through cleanup ordering, but both touch the same scenario.

## Security Review

- **Attack surface:** unchanged or reduced. Resetting to `SIG_DFL` cannot expand privilege; it restores zombie-pinning, which is the security-relevant invariant (PID-reuse cannot redirect a kill at a foreign process). The reset runs pre-fork with an asserted-empty child set, so no existing child's status can be discarded by the transition itself.
- **No data-flow changes:** no secrets, no new paths read; the molecule still touches only `/proc/self/task/<self>/children`, `/proc/<pid>/stat`.
- **Fail-closed preserved:** every uncertain outcome still raises `CleanupUncertain`; the disconnect path still cannot produce canonical success (`assert_nil result["result"]` retained).

## Refactoring Opportunities

- **Future consideration (not an action item):** `Signal.trap("CHLD", "DEFAULT")` discards the previous disposition with no restore and no check that the previous handler wasn't a *custom* one. Within the documented "sole ephemeral helper" contract this is fine (and the dispositions record production labd observation), but if the scope is ever hosted in a longer-lived process, a custom-handler previous-disposition should arguably raise `CleanupUncertain` (someone else claims reaping ownership) rather than silently clobber it. Capture-and-raise would make the contract self-enforcing instead of convention-enforced.
- **Future consideration:** the `zombie?` implementations differ cosmetically between executor (`split(")").last`) and scope (`rpartition(")").last`) — already noted as INFO in the retained review; leave for a later pass.

## Findings Summary

| # | Severity | Location | Finding | Type |
|---|----------|----------|---------|------|
| 1 | Medium | whole delta (process) | No executed R6 evidence attached for the new trap reset, new scenarios, and loosened assertion; dispositions itself requires it "before integration." Merge gate (executed tests + independent verdict) not yet satisfied for this delta. | Finding |
| 2 | Low | `ace-runtime/test/molecules/owned_child_scope_test.rb` | Constructor behavior (trap reset, ordering) has no unit coverage; only covered by root-only Linux fixtures that skip on macOS. | Suggestion |
| 3 | Low | `evidence/*/pi-response.json`, `review-dispositions.md` | Missing trailing newline; spacing typos around SHAs/counts. | Suggestion |
| 4 | Info | manifests / dispositions | Per-file digests, the 766-vs-767 manifest count, and the `ace-review` slash-validation friction claim are not recomputable with read-only tools — unable to verify, noted as documented author dispositions. | Note |

**Strengths worth keeping:** the fix is four comment lines + one code line and closes a genuine PID-unpinning defect class fail-closed; the trap fixtures are cleanly contained inside the forked helper; the loosened assertion was widened by exactly the verified disconnect classes while keeping every anti-success assertion intact; dispositions explicitly refuse to overclaim (R6 pending, release cut still open).