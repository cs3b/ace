# Source implementation and verification

Source candidate before this evidence-only report: `467c68b59452d6153fe3101751a1339f9f2835ae`, based on main `7ebb11c3fda2178a399786fac76e60edb02eb79a`. Worktree: `.ace-wt/codex-wave4-hitl-integration`; branch: `codex/wave4-hitl-integration`.

The pure `ace.hitl.managed/v1` codec and shared examples ship in the existing dependency leaf. Requests bind assignment/attempt, kernel-attributed requester, incarnation and exact runtime reverse. DaemonBinding, CompositeBinding, Work validation/forms and managed folder projection waiting are removed. The explicit LiveClient owns in-process delivery/watch and authenticated pane-less consumption. Registered Hermes transport publication completes the request-to-question source path without a hidden watcher or second poll owner.

Herdr Inbox preserves the managed envelope and owns durable submission plus the existing signed verifier. Assign owns accepted binding/reconciliation journal events and the read-only runtime binding accessor. Native queue acceptance/wake, signed actual consumption and service business callback receipts remain separate. OTP bytes/hash never enter the managed envelope or native inbox; protected operation-scoped IPC remains the answer path. No timer establishes success or authorizes uncertain resend.

Executed receipts (under `.ace-local/test/reports/<package>/<id>/`):

- HITL all: `8x40f3`, 193 tests / 1081 assertions, zero failures/errors, one existing multi-UID skip.
- Assign all: `8x40j2`, 807 / 3152, zero failures/errors, two existing installed-boundary skips; 9m38s including real journal feature coverage.
- Herdr all: `8x40br`, 456 / 1474, zero failures/errors. Retain earlier `8x40ah`: existing bounded-process post-launch cleanup race failed under concurrent package load, passed in full serial rerun.
- Contract all: `8x40jw`, 19 / 891, zero failures/errors, one normal opt-in installed test skip. Explicit configured clean-install run `8x40jf`: 1 / 67, zero failures/errors.
- Hermes all: `8x40kp`, 112 / 642, zero failures/errors, including built installed OTP CLI proof.
- Hermes shared envelope/ingress consumer tests: `8x40dn`, 31 / 133; registered pending producer `8x408b`, 3 / 18; all green.
- Default concurrent suite: retain its executed failure receipt: 50/51 packages passed, 10284 passing tests / 30636 assertions; Assign exceeded unchanged 120-second package limit while full Assign all was concurrently executing. A two-worker rerun also hit the unchanged Assign limit under concurrent load. The independent executed full Assign receipt is green; no global timeout is changed and no further unrelated suite rerun is claimed.

The leaf install fixture explicitly clears BUNDLER_SETUP as well as BUNDLE/RUBY fields, skips archives only for this Ruby's default gems, and selects empty GEM_HOME/GEM_PATH without RubyGems `--install-dir` (which ignores default gems). Retained successful graph artifacts: `.ace-local/install/vs2-isolated`; failed original fixture artifacts remain in `.ace-local/install/vs2-current`. Hermes local installed executable/plugin proof artifacts remain in `.ace-local/test/artifacts/hitl-hermes/`; they explicitly report live_telegram=false and lab_gad2=false.

Acceptance limits: SC2 and lab-config:gad.2/.8/.b remain open. No real Telegram destination was used; native adapter/coordinator fixtures are labelled and cannot prove native consumption. Actual signer/private-key installation, requester/signer OS users, native observation and Lab death/recovery must be executed separately. The new protected-authority task's later source integration must preserve/recheck these public interfaces. This report does not mark the task done, approve source, merge, push, publish or bump versions; an independent exact-head reviewer is still required.

## Independent review repair — 2026-10-05

Independent reviewer rejected candidate `5afccf58add072057524486bc6b5cb3f84282e0f`
with four reproduced findings (feedback `8x40w57g`, `8x40w57h`, `8x40w57i`,
`8x40w57j`). The persisted reviewer verdict and Sol6.1 report live under
`/tmp/ace-wave5-vs2-review/.ace-local/review/`. Reviewer fail-before receipts:
HITL `8x40wo` (12 tests / 75 assertions, three expected safety regressions),
Hermes `8x40wp` (4 / 19, one expected outage regression), and original native
incarnation probe `8x40sq` (10 / 74). These are evidence of defects, not passing
acceptance. No findings are omitted or silently deferred.

Repair worktree: `/Users/mc/Ps/ace-wave5-vs2-repair`, branch
`codex/wave5-vs2-repair`. LiveClient captures the accepted owner's full native
session/terminal/agent identity before consumption and passes it to Inbox.
Managed enqueue requires that original target and compares live observation
under the existing event lock. Immutable `origin_target` survives duplicate
admission and verified signed replacement of the current target; delivery still
rechecks the target and submits only its fixed native thread ID. Drift before
admission refuses without an inbox record, leaving the consumed native claim
visible for recovery; drift after observation/persistence retains the original
binding and becomes uncertain without submission. Incomplete owners refuse
before consuming the answer. Existing expected-registration and signed receipt
verification remain under the same event lock.

Ordinary delivery/watch returns a signed-superseded queued state without retry;
only explicit verified `reconcile(..., retry_delivery: true)` resubmits. Managed
Inbox validates the actual payload's secret shape before persistence, including
no-message envelopes. Continuous Hermes publication catches only transient
lifecycle TransportError, reports the channel and error class, waits one second,
retains its actor lease and retries later. Single-pass errors remain visible.

Executed repair receipts under this worktree `.ace-local/test/reports/`:

- HITL baseline LiveClient `8x40v8`: 9 / 71 green; repair fail-before `8x40vn`:
  10 / 72, one expected incarnation-refusal failure.
- Hermes repair fail-before `8x40yl`: 5 / 25, one expected outage-recovery failure.
- Final focused LiveClient `8x4110`: 11 / 85 green; Inbox `8x40xy`: 40 / 233
  green; Hermes pending producer `8x4106`: 5 / 31 green.
- HITL all `8x40zx`: 194 / 1091 green, one existing multi-UID skip; an additional
  owner-refusal test was subsequently verified in the focused receipt above.
- Herdr all `8x40zg`: 459 / 1502 green.
- Hermes all `8x410t`: 114 / 655 green.

An initial test-only continuous-loop stop exception was wrapped by Poller as a
transport error, preventing the test from ending. Those owned test processes
were terminated; the test now uses control flow outside StandardError, and the
final focused/full Hermes receipts above verify actual outage recovery. No
product failure is hidden by that fixture correction. No unrelated monorepo
suite was repeated under concurrent load. `git diff --check` passes.

All four fixes require a fresh independent exact-head verdict. These source
receipts do not prove actual Telegram/native consumption, installed signer or
multi-UID boundaries, SC2, or gad.2/.8/.b. No task-done, version bump, publishing,
main merge or push is performed by this repair agent.

### Rebased source verification

Rebased the nine original source/repair commits onto main
`b12bb0659` without editing its independently accepted delivery behavior. The
only conflict was Assign CHANGELOG, resolved by retaining both Unreleased
entries. Range-diff shows all source/repair patches unchanged; that changelog
context is the sole patch difference. Consumer source trees (HITL, Herdr, Hermes
and the shared contract) exactly equal pre-rebase repair `45307127e`.
Rebase capture/proof lives in `.ace-local/git/wave5-vs2-rebase/`.

Post-rebase source head `aac199340661111c053540b403cc23586afeaf73`:
HITL all `8x4137`, **195 tests / 1095 assertions**, zero failures/errors, one
existing multi-UID skip; Assign runtime-binding consumer `8x412u`, **4 / 32**,
zero failures/errors. Herdr/Hermes full green receipts above remain applicable
because their source and tests are byte-identical across the rebase. The source
head has been handed to the independent reviewer; this report-only amendment
does not claim their verdict or installed acceptance.

## Joined LiveClient fixture contract repair — 2026-10-08

The joined HITL run at `090d851f9` reported 240 tests, 1364 assertions, and
five errors (`d74ff6d5-9b77-4ec2-b7e0-bebdac3c2e4b`). All five originated
from the maintained LiveClient integration fixture's obsolete Native adapter:
it lacked the current Inbox `prepare_submission` producer method. Its generic
acceptance response also omitted Codex submission correlation. The watcher
exception accounted for a subsequent 60-second wait; it is not native proof.

Repair scope at base `d772ea74a` is only `ace-hitl/test/feat/live_client_test.rb`:
provide explicit Codex producer/submission correlation in the named adapter seam
and keep the real Store, durable Inbox, signed receipt verifier, restart, key
rotation, uncertainty and watcher assertions. No production fallback, agent
substitution or installed/native acceptance claim is authorized. Verification
is limited to this relevant file; combined final review remains open.

Focused terminal verification: `bin/ace-test ace-hitl feat
ace-hitl/test/feat/live_client_test.rb` selected 1/26 files and passed **11 tests,
93 assertions, zero failures/errors, 254.38 ms**, report
`fb44aad4-520a-4f1e-a646-31d0fc621491`. Added assertions join the actual retained
Inbox receipt to the producer's event/attempt/generation/digest/client message
and queue UUID, and verify explicit supersession retry keeps the event while
advancing generation and allocating a distinct client message ID. Signed fixture
observations name that retained client message rather than an unrelated log token.
These fixture correlations do not authenticate an installed Codex endpoint or
prove native consumption. Existing installed SC2/gad obligations and combined
independent review remain open; no task status or production source was changed.
