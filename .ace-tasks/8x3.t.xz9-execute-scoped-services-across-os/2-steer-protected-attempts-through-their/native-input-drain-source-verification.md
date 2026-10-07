# Exact original actor input inhibition and drain — reviewed source contract

Base ACE03122b6fb; existing selected upstream source96f14b6d, baseline7b116c05. This closes xz9.2's lost native ACK recovery obligation using the existing native actor/write owner. No second ledger, listener, supervisor privilege, result receipt or worker termination is introduced. Prepared gems/artifacts remain immutable; no native/PTY/root/installed probes.

## Closed API and attribution

Add one native method `terminal.inhibit_input`, params exactly `{target, expected_origin}`. Target is the opaque original terminal ID; expected_origin is the existing closed GuardedPromptOrigin. No pane/agent alias, caller PID, arbitrary scope, text, mutation journal or timeout selector. Advertise an explicit `guarded_input_drain: true` capability only when an attached actor has the captured original origin and this owner supports inhibition.

Success is a bounded response for the ordinary request ID with result exactly `{type: "terminal_input_drained", origin: EXPECTED_ORIGIN, input_state: "inhibited", pending_input: 0}`. It proves only that this actual original actor can perform no further PTY-input writes and has no received/queued/active input (including terminal replies and pending input controls). It proves neither worker exit nor service/inbox settlement. ACE checks selected native build, server/socket incarnation and exact origin before accepting it. It remains mandatory to prove 9c2 scope cleanup independently.

Malformed shape => fixed `invalid_params`; absent/ambiguous/imported/handed-off/replaced actor => fixed `origin_unavailable` or `guard_mismatch`; actor channel failure => fixed `input_drain_unavailable`. There is no drained success based on absence, dead PID, empty queue snapshot, generic timeout or pane.close. Error body is closed `{code, phase: "unconfirmed"}` without raw message/text. Lost success ACK is unconfirmed, and the same exact operation can be repeated to read/finish the same one-way inhibited actor state without repeating input.

Inhibition compares the captured actor's immutable origin, including terminal ID/runtime incarnation/original child identity, with the supplied exact origin. It does not require that original child remain alive: an exited original child does not erase the actor's surviving PTY/write ownership. Destroyed or replaced actor refuses; a replacement never inherits the inhibited proof. Existing prompt admission still requires positive child liveness. No late caller can reopen input, hand off the inhibited actor, or admit a new prompt.

## Native write ownership and lock order

Extend the existing UserWriteGate with a separate monotonic scope-inhibited state. `accepting=false` alone is ambiguous with reversible initial quiescence/handoff; only this one-way state can yield drained proof. Inhibit is authenticated against the immutable actor origin, then closes admission under the SAME gate mutex currently held across actual guarded writes. Thus an already running write finishes before inhibition acquires the lock, and no subsequent generic or guarded write starts after it. Never acquire the actor/app lock while holding the gate; never wait for an actor completion while holding gate/app locks.

The existing actor control channel carries an input-drain barrier to its own runner. After admission closes, cancel all data_rx input commands, pending_writes and active_submission, including generic focus/text/Enter input, not only guarded requests. Resolve existing submission replies with their actual attribution: zero guarded writes can return not_issued; partial writes remain issued_or_unknown. Drop guarded admission permits only after gate lock is released. Reject future generic and guarded input at admission AND at actual flush; no unguarded else-branch write bypass. Do not drain terminal output or claim child termination.

Every generic and guarded admission enqueue synchronizes with that same gate, including generic data_rx send; a sender paused before enqueue cannot add unaccounted input after drained ACK. Actor completion returns drained only after all pending/active input has been canceled, in-flight write ownership is settled and guarded_pending is zero. Repeat operation against the same actor is idempotent and produces the same inhibited state; no per-request outcome ledger is needed. If a failed control send leaves inhibition installed but cannot confirm runner drain, return unavailable and keep inhibition. No recovery path restores accepting. Previously queued resume/quiesce/handoff commands must observe monotonic inhibition and cannot reopen admission or transfer the PTY. Handoff/replacement paths must reject this monotonic inhibited actor rather than move its live PTY to a new writer.

N2 must first seal canonical issuance and inhibit the outside-unit LaunchDriver dispatch loop. Native drain then covers submissions already delivered before launcher inhibition, including requests whose original ACK was lost. Authority restart recovers durable prompt_issued uncertainty and requires fresh authenticated original-actor drain before proof/release. New native endpoint/actor cannot satisfy old drain. The original launcher must still be proven inhibited/drained or exited; this operation is not a substitute for its lifetime barrier.

## Ownership and source delivery

wave5h5 owns upstream native schema/dispatcher/actor/runtime forwarding, pure/in-memory Rust tests, packaged patch and exact source-selection digest/revision updates. wave412 retains builder/installer owner; coordinate changed source selection and provenance without rewriting prior artifacts. wave_n0n owns N2 consumption and canonical closure/history joins. Regenerate the shipped combined patch against the existing pinned baseline and select the exact reviewed new source commit/tree, preserving Cargo.lock/toolchain identity unless actual source necessity emerges.

## Controlled test responsibility map

Native pure schema tests: exact success/error shapes; bad/missing/extra fields; opaque target/origin mismatch. Native in-memory actor tests reuse the current generic Write test seam, never real PTY/process capture: queued generic and guarded input canceled, partial write attribution, a paused in-flight write followed by inhibition has no subsequent write, paused generic enqueue before inhibition cannot append after ACK, received-before-issue command canceled, full queue/control failure remains inhibited/unconfirmed, repeated/lost-ACK operation returns same drained state, prequeued resume/quiesce/handoff cannot reopen or transfer, wrong/replaced/imported origin refuses without touching other actor, exited child with same retained actor can drain. Verify existing prompt submission and handoff tests still pass.

ACE deterministic package tests verify packaged patch/selection/provenance consistency and controlled response decoding once N2 consumes it. No native executable or installer is run. Full installed effectiveness belongs existing gad.2 and remains outstanding.

Completed source precision: terminal-response and resize/nudge admission also hold the same monotonic gate; the barrier clears SharedPtyControls responses/resize/nudge and read-generated replies are suppressed after inhibition. This closes queued state as well as actual writes; it adds no separate authority.

## Frozen source and executed evidence

This is the native source producer checkpoint, not completed N2 consumer, Lab activation or installed acceptance. Root and wave_n0n independently approved the design before implementation; frozen implementation review is still required.

- ACE base: `03122b6fbbfccbab317aa928295bb31f7657e692`. Existing N1 source/artifacts remain immutable.
- Pinned upstream baseline: `7b116c05bfda646af39d2524c54e70c751f57ee8`. New combined source: `70ee59844bccaec63e00140787bc95ff0d705ca6`; tree `28b4fcacf7d162ebf37da9329050579947e6429d`.
- Packaged patch SHA256: `1092eb5d6b909ef452fc4f08d9d39754a1fc7a529a126d118949db12c8585c90`. Cargo.lock/toolchain/native version/protocol unchanged.
- Controlled local `git am --committer-date-is-author-date` reconstruction from baseline produces the exact selected source commit and tree. No native build or executable invocation.
- `cargo +1.96.1 test --locked --bin herdr guarded_prompt_pure_tests`: final **28 passed**, 0 failures, 3502 filtered, 0.00s. Pure MemoryWriter/descriptor-sentinel fixtures; no PTY or kernel-origin observations.
- `cargo +1.96.1 test --locked --bin herdr input_drain_pure_tests`: **10 passed**, 0 failures (includes closed wire test).
- `cargo +1.96.1 test --locked --bin herdr api::schema::tests`: **44 passed**, 0 failures; includes generated protocol freshness and bundled reference validation. Regeneration performed separately via `HERDR_UPDATE_API_SCHEMA=1`.
- `cargo +1.96.1 check --locked --tests --target aarch64-unknown-linux-gnu`: **PASS**, 1m20s; static only. macOS test compilation and `cargo +1.96.1 fmt --all -- --check`: **PASS**.
- `bin/ace-test ace-herdr fast ace-herdr/test/fast/molecules/native_source_test.rb ace-herdr/test/fast/organisms/native_source_builder_test.rb --timeout 120`: **20 tests, 85 assertions, 0 failures/errors**, 3.02s, report `5667ac07-00c6-419e-bfbf-946935c21479`. Builder uses controlled command fixtures and never builds or runs native. Earlier report `1360376c-16d1-437c-ab2b-27d13c6ce679` failed only the stale hardcoded old source pin; repaired and rerun.
- Upstream diff-check is clean. Nonpatch ACE paths diff-check clean; generated unified patch has required single-space blank context rows reported as trailing whitespace by repository diff-check. They are patch framing, not source whitespace; exact reconstruction confirms integrity.

No installed edge tests, native/PTY/systemd/root/security/VM probes, prepared gem/artifact rebuild, publication or push occurred. This receipt makes no broad all-suite or installed-readiness claim.

## Automated review repair checkpoint

Automated review of ACE70e78 reported one valid medium and three valid low findings; root independently verified all four. This bounded repair resolves: `8x62aepx` absent terminal must not advertise captured-origin drain capability (retain Option, use is_some_and); `8x62aepy` documented parseable inconsistent origin refusal as guard_mismatch; `8x62aepz` named fixed five-second ACK deadline and fail-closed timeout semantics; `8x62aeq0` repeat/lost-ACK recovery only while the same original actor remains attached. No native App test harness or tautological Option test was added; existing compile, pure/schema and selected asset checks cover this narrow source delta. Final independent frozen-source verdict remains root-owned.

- Repaired selected upstream source `7a2e78b4e92d2b694bd8a06c1ef4943915c399b2`, tree `77d1f89f514731239c02b0966c49b9e5f30650da`; combined patch SHA256 `92971473f75c116181dc73de138d91f532e1cb62220c13eace2eb5cfd05fa811`. Original checkpoints above remain historical evidence.
- Exact controlled fresh baseline git-am reconstruction reproduces repaired commit and tree. Cargo/toolchain/version/protocol unchanged.
- Repaired source: cargo fmt --all and cargo +1.96.1 check --locked --tests PASS (19.04s static compile); input_drain_pure_tests PASS10/10 (0.01s); api::schema::tests PASS44/44 (0.04s). No PTY or native identity execution.
- Repaired selection: bin/ace-test ace-herdr fast ace-herdr/test/fast/molecules/native_source_test.rb ace-herdr/test/fast/organisms/native_source_builder_test.rb --timeout120 PASS20tests/85assertions, 0failures/errors, 2.7s; receipt `2f181ff7-71ba-4b76-b629-ca3d70ede2a7`.
- Upstream source diff-check clean; patch framing exception remains exactly as recorded above.
