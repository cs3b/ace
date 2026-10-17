All verification is complete. Compiling the final review.

---

# Independent Adversarial Review — R5 @ frozen head `45927f85326810ecb906b1fc6c8b15ec2dd056e0`

## VERDICT: APPROVE

The three prior LOWs are correctly fixed; the R5 nil-read fix is minimal and fail-closed; no incomplete-inventory, exception, disconnect, or lost-ACK path can produce canonical success. Findings below are LOW/INFO, none blocking.

## Frozen-head and lineage verification (independently performed)

- Worktree `ei9-command-cleanup` HEAD → `refs/heads/codex/ei9-command-cleanup` = `45927f8…` (info/refs + worktree reflog, last commit "fix(runtime): accept an empty owned child inventory"). R5 manifest `"head"` pins the same commit.
- Scoped worktree files byte-match the provided source (full reads of all six files).
- Snapshot lineage from retained exports (`kernel-r4-red` base `ee83e2b` → `kernel-r4` `89ac137` → `kernel-r5` `45927f8`):
  - **R4-red**: `cleanup_group(pid)` — group-only `TERM/KILL(-pid)`; a setsid double-fork descendant escapes the group and survives → the 2 RED failures. LOW #1 confirmed real and reproduced by design.
  - **R4-red guard**: `Process.uid.zero?` only (line 23) → LOW #2 confirmed; R4/R5 require `uid.zero? && euid.zero?` (line 24).
  - **R4**: `bytes = file.read(65_537)` without `|| ""` — exactly the diagnosed nil-read crash before fork (constructor's empty-children assertion reads an empty procfs file ⇒ `nil.split` NoMethodError ⇒ 6/7 GREEN failures).
  - **R5**: single-token fix `|| ""`; oversized/invalid inventories still refused; regression test added.
- `OwnedChildScope` has exactly one production consumer (`command_executor.rb:49`); legacy `cleanup_group` remains only in untouched protected/legacy paths — containment holds.

## Scope conformance (code-verified)

- **Owned-only signaling / PID-reuse safety** (`owned_child_scope.rb:19-43`): KILL targets only PIDs from `/proc/self/task/<self>/children` (kernel-guaranteed direct+adopted children). Unreaped children pin PIDs and this sole thread is the only reaper, reaping only after kill in the same iteration ⇒ a signaled PID can never refer to a foreign process. TERM is group-scoped to `-leader`; the leader setsid'd into a fresh session, so only command descendants can hold that pgid, and the unreaped leader pins the pgid value. Exit condition `remaining == [leader] && zombie?(leader)` is the **only** success return; every other inventory outcome raises `CleanupUncertain`.
- **Adoption closes the setsid/double-fork escape**: subreaper (`prctl 36`) enabled pre-fork in a sole-thread helper with asserted-empty children; orphans of killed children reparent into the next inventory read; a converged `[leader]`-zombie state proves no live owned descendant remains (dead processes cannot fork). Chain escapes converge via iteration.
- **Leader status preserved**: scope never waitpids the leader (`unless pid == leader`); executor's `waitpid2` gets the true status.
- **Deadline**: `timeout <= 5` enforced (finite/positive/NaN-excluded), default 5.
- **No broad scan / no privilege expansion**: reads limited to `/proc/self/task/<self>/children`, `/proc/<child>/stat`, `/proc/<pid>/status`, `/proc/<pid>/cwd`; no `kill(-1)`, no UID scan; child sets `no_new_privs` (prctl 38) and drops gid/uid/groups before signaling readiness — the witness binds post-drop facts with a boot-scoped birth (`ProcessIdentity`: `/proc` start-ticks + boot_id, double-observation, Z/X rejected).
- **No success before cleanup** (`command_executor.rb:101-113`): order is pump→`cleanup!`→`waitpid2`→`command_complete`→result frame→exit code. `pump` exits only after a zombie observation (or raises). Every exception path (CleanupUncertain, IOError disconnect, frame bounds, JSON errors, ProtectedSocket deadline) skips complete+result; ensure kills and bounded-reaps the child. Claim replay raises pre-fork; bind replay/lost-ACK raise post-fork with the gate never opened (child killed at the gate, ESRCH per receipt).
- **R5 nil-read fix**: `|| ""` normalizes only the EOF-nil; `bytesize > 65_536`, non-integer, duplicate, or non-positive inventories still refuse; `""` → `[]` valid empty set. The host regression redirects `File.open` from the exact procfs path to a real empty file, so `read(65_537) → nil` is exercised with real IO semantics.
- **Fixture integrity** (`command_executor_probe.rb:188-201`): `survived_cleanup` is recorded **before** any kill; kill happens only after exact birth match (stat field 19) and PPid == fixture subreaper; a PID-reused impostor fails the birth check (no foreign kill); a foreign-owner escapee raises; the post-recording kill cannot make the test pass. Never hides acceptance failure.
- **PTY Ctrl-D semantics documented** (`ace-lab/docs/usage.md`, "Project commands" end): interactive EOF = conventional Ctrl-D byte with raw-mode caveat; noninteractive EOF closes the pipe — matches `pending_input << "\x04" if interactive; input.close unless interactive` (`command_executor.rb:186-189`).
- **Policy env hardening (context)**: `CommandPolicy::ENV_KEY`/`RESERVED` prevent executor/service environment from overriding `PATH/HOME/...`; argv closed/bounded; grants exact.

## Findings

| # | Severity | File / line | Finding | Reproduction |
|---|----------|-------------|---------|--------------|
| 1 | LOW (test robustness only, non-blocking) | `ace-lab/test/support/command_executor_probe.rb:171` + `command_executor.rb:229` (`send_frame`) | In `detached_disconnect`, if the helper attempts a socket write in the window after `client.close` but before the read side observes EOF, `ProtectedSocket.write`'s `write_nonblock` raises `Errno::EPIPE` and the recorded error class becomes `Errno::EPIPE`, failing the `assert_equal "IOError"`. Product behavior (disconnect ⇒ failure, cleanup, no result) is identical for both classes. | Close the client socket while output frames are still pending in flight; race the helper's write against FIN delivery. Two retained root runs and the domain run show no occurrence. |
| 2 | INFO | `owned_child_scope.rb:51` | `/proc/<pid>/task/<tid>/children` requires `CONFIG_PROC_CHILDREN`. On a kernel without it, every command terminally fails as `CleanupUncertain` (fail-closed, availability only). Acceptable on the controlled Lab host; worth noting as a deployment constraint. | Run on a kernel built without `CONFIG_PROC_CHILDREN`; constructor raises before fork. |
| 3 | INFO | `.ace-local/ei9-command-cleanup/kernel-r5/manifest.json` | Manifest `files` block spans lines 4–770 = **767** entries; the supplied receipt says "766 source files". One-entry delta I cannot recompute (no shell). Head pin, scoped-file digests, and lineage are structurally verified; product code unaffected. | Count entry lines in the manifest `files` block. |
| 4 | INFO | `command_executor.rb:104-121` | Failure-path teardown can stack `cleanup!` (≤5s) + ensure-path bounded reap (≤5s) ≈ up to ~10s worst case; normal path is ≤5s plus pump's 1s post-zombie drain. The "deadline 5 seconds" requirement is honored per-cleanup stage; total teardown on failure paths marginally exceeds it. No safety impact (uncertainty preserved). | Kill -STOP the leader into D-state; both bounded loops elapse. |
| 5 | INFO (nit) | `command_executor.rb:203` vs `owned_child_scope.rb:67` | Executor's `zombie?` uses `split(")").last` while the scope uses `rpartition(")").last`. Equivalent for well-formed procfs lines (comm is always parenthesized); the scope's form is stricter on malformed input. Cosmetic inconsistency only. | Static comparison. |

## Tests actually executed by this reviewer

**None.** This review session has no command-execution capability (tools limited to read/grep/find/ls); I therefore did **not** run `bin/ace-test` and I do not claim any executed check. I state this explicitly rather than fabricate execution.

What I did instead (artifact-level verification on this host):
- Verified retained ace-test reports executed on this host (2026-10-16), matching the parent receipts exactly:
  - `runtime/latest` (`e63f58fb`): `owned_child_scope_test.rb` — 1 test / 2 assertions / 0 fail ("empty realIO regression 1/2 PASS").
  - `lab/7510ff1d`: `command_run_client_test.rb` + `command_executor_test.rb` — 7 tests / 23 assertions / 0 fail ("guard/client 7/23 PASS").
  - `lab/latest` and `lab/f1e62e2d`: guard PASS + **7 kernel SKIPs** on macOS — correctly **not** treated as Linux proof.
- Verified worktree/reflog head, scoped-file bytes, R4-red/R4/R5 export lineage, manifest structure, and single-consumer containment.

Parent-supplied independent Linux operator receipts (R4 RED 2 failures; R4 GREEN 6-fail nil.read; R5 kernel 7/64/0 in 3.17s; domain 40 PASS in 5.078s; owner PID 554643 unchanged; runtime fast 300/1220) are internally consistent with the code and the retained artifacts, but are **not** my own execution.

## Limitations

- Static review + artifact inspection only; no host or Linux-root test re-execution (no execution tool). Linux-only behaviors (subreaper adoption, TIOCSCTTY, procfs children semantics) are assessed by code reasoning plus the supplied receipts, not reproduced here.
- Manifest SHA `2d99598…` and per-file digests were not recomputed (no shell); verification was structural (head pin, byte-level file comparison of scoped files vs snapshots, lineage deltas).
- macOS host: kernel fixture skips are not installed-proof; nothing here asserts installed acceptance or autonomous publication — those, taskless secret/OTP/publication join, and the coordinated Lab/Runtime release cut (`ace-lab.gemspec` already declares `ace-runtime ~> 0.3`; a Runtime release carrying `owned_child_scope.rb` is still required for resolution — design doc correctly records "No versions bumped; task remains in-progress") remain OPEN and are not claimed delivered by this head.
- Mechanical publication extraction in another worktree: out of scope, not reviewed.
- I cannot write files; this response is the review report. If persistence is required, the operator should file it under `.ace-local/ei9-command-cleanup/review-459/`.
