# Source integration checkpoint — 2026-10-08

## Current decision and delivery boundary

Captain cancelled message-read/consumed/superseded proofs, additional Codex
app-server services and duplicate terminal-state projections. This is not
postponement. `xza` is cancelled. Workers launch through the existing `ace-llm`
CLI in Herdr/tmux; overseers read live panel/process state. Terminal submission
means submitted to the original terminal, never read or task success. Unknown
sends remain uncertain and are not automatically repeated. Actual assignment,
result, review, privileged-effect history and protected stop/release remain.

The joined source implements canonical review campaign ownership and bounded
convergence, protected forge delivery and scoped publication. Protected Codex
Inbox now uses the existing expected-origin native write; the independent
review's one confirmed P1 race is repaired. Inbox keeps its existing 65536-byte
limit; no extra service or read signer was added. Removed API references and
fixture-only participant/proof assumptions were cleaned up. Fresh loading of
InboxContextStore explicitly imports its validation error definitions.

### Executed delivery checks

- Original-terminal Inbox: 61 tests / 486 assertions PASS (`a12281c2`).
- Native guarded control: 11 / 68 PASS (`46ea9e78`).
- Overseer: 279 / 1306 PASS (`c9b78e53`).
- Joined assignment recovery/consumers: 12 / 238 PASS (`69f98d88`).
- Fresh installed source/load checks: 3 / 144, zero failures/errors, one
  root-only test skipped (`2c9efd62`). Third-party dependencies come from
  already-resolved non-ACE gem directories; installed ACE remains isolated.
- Retained historical/transfer checks: 3 / 74 and 18 / 109 PASS (owner checks).
- Maintained Herdr loading/original-client fixtures: 5 / 43 PASS (`b4fed3de`).
- Maintained assignment participant/service-receipt fixtures: 2 / 44 PASS
  (`f33d6211`). Actual receipt validation and corrupt-result cache eviction
  remain; deleted reconciliation CLI is no longer tested.
- Generic service fixtures now select `verify-artifact`, not the special
  publication operation. Real publication/OTP checks are unchanged. Receiver
  10 / 46 PASS (`3daf8ad4`), expiry/recovery 2 / 48 PASS (`4e0d76ed`),
  boundary/listener 4 / 85 PASS (`b300aae9`), under existing deadlines.
- Clean committed lab-config source: seven Python tests PASS, at `ced5f99`.
  The primary Lab checkout's unrelated dirty network/legacy work is excluded.

The executed default suite reported **47 packages green, three red: 11894
passed, 22 failed, 33 skipped**. It began before final cleanup and is not a
frozen-tree green verdict. Its actual missing-import/dependency and obsolete
fixture failures are resolved by the focused checks above and the service
checks recorded below. No timeout was increased and no fake Lab was added.

### Release path and ownership

- [x] Join implementation and remove the rejected read-proof/app-server model.
- [x] Repair the original-terminal race through existing guarded native control.
- [x] Coordinate versions, changelogs, dependency floors and root lockfile.
- [x] Finish the remaining focused Lab service fixture checks.
- [ ] Final exact-head independent verdict in the same combined code review.
- [ ] Fast-forward ACE/Lab main and synchronize their authorized remotes.
- [ ] Build fresh artifacts using the repository publisher's prepare mode.
- [ ] Captain publishes interactively with OTP.
- [ ] Post-publication `TS-MONO-001` verifies installation propagation.
- [ ] `lab-config 8wl.t.gad.2` installs, launches and observes a real Lab task.

Publication/propagation/installed acceptance are not claimed by source review
or fixture success. Whole program tasks are not marked done by this checkpoint.
The historical sections below retain prior evidence only; their cancelled
native observation/startup requirements do not reopen the Captain's decision.

The sections below are historical implementation evidence. Any statement
requiring managed remote startup/native consumption is superseded here.

## Joined source

ACE integration branch `codex/protected-pr-integration` joins protected PR operations, scoped publication, explicit HITL project routing, R2 parent/child registration and canonical round/export/results. Ready/merge carry their exact operation into the current campaign gate at claim, authorization, dispatch and journal CAS; draft creation/update retain the Captain-approved ordering. Bounded per-operation immutable journal inventory reuse retains the existing 30s candidate Git deadline.

R3 is integrated at `49a57f4f5`: finite phases, durably reserved provider attempts, convergence limits, escalation and resume use the same campaign owner. `238074f43` makes the R2 result consumer use the compact snapshot yielded by the same held verification; it no longer opens a second campaign projection. `9b9d72d65` fixes the real typed-subject parser's rejection of Forgejo PR URLs, tracked as actual child `qkc.0`. `413b7b1a8` classifies the 57 active coupling matches, and `3f1a79911` installs three maintained acceptance scenarios using the existing E2E runner. Their discovery checks are not installed execution.

`31dabb87f` adds original Serve/lifecycle attachment and exact Codex admission/stop seams. These deliberately refuse an installed context without its original startup owner; the production Lab factory and actual client/producer ownership join remain absent. A typed callback seam is not a working native startup.

Lab integration branch `codex/lab-source-integration` joins coldboot, selected network producer, physical cleanup and static Codex composition through `5bbf15b`. The latter installs/authenticates original static fragments and inventories. `ad2bde6` records the official Codex endpoint incompatibility and removes the unsupported production-factory claim. ACE `35e0ba2ca` now validates the actual private daemon directory, hashed physical socket and advertised symlink; Lab `15fc868` supplies the actual native GID rather than the unrelated context control GID. These correct identity validation, but do not grant distinct-UID connectivity or establish a working native launch. The existing root-published 0755/0444 nonsecret output remains readable by the context; publishing from an unprivileged authority is not implemented.

`69c90f86c` documents the public protected round/export/submit-result handoff in the canonical workflows. `090d851f9` removes three unrelated eager configuration loads from the actual protected service/campaign entrypoints; the maintained loading test now checks five real entries. `a9e2fb57d` refuses missing literal Ruby file selectors before runner effects. `8c8bc11d1` repairs the HITL creation fixture to exercise actual competing threads after persistence under the held lifecycle lock.

## Executed evidence

- Canonical recovery cleanup: retained success with replaced root, 1/16 PASS (`8ca78686`); lost completion reply recovered from canonical status, 1/19 PASS (`203cdb90`). No deadline changed.
- R2/service boundary join: 9/65 PASS (`ce81533a`); manager/canonical compact evidence: 46/345 PASS (`8c7e7ff0`); execution/transfer/prepared-input/receipt checks: 39/218 PASS (`30813b64`).
- Integrated operation-local inventory isolation and service gates: 18/131 PASS (`ba19098a`). Actual Git scan-reuse proof retained from the producer: 1/27 PASS (`ca38b565`), fresh operation revalidates.
- R3 plus the typed PR subject and public CLI boundaries on joined source: 140/612 PASS (`ca315ed0`). Original lifecycle attachment/admission on joined source: 8/26 PASS (`3b14ab79`).
- Actual local Git, canonical imported result bytes and the same R1/R3 owner: 1/24 PASS in 23.82s (`d05538ec`). Held-snapshot Endcap boundary: 1/6 PASS in 2.41ms (`1236ae94`). These prove their specific source joins, not installed OS/native execution.
- Joined native endpoint/Inbox checks: 15/133 PASS (`b66a3a01`); joined missing-file parser/public CLI: 18/70 (`9a42a8f2`) and 1/7 (`f3b2a5a9`) PASS. Joined protected entry loading: 1/20 PASS (`400c8b67`). Lab native-GID producer fixture: 1 Python test PASS. These remain source checks, not distinct-UID/native acceptance.
- Full Forgejo package: 171/764 PASS (`ad4d4b2b`). The prior HITL package run (`df9da056`) had one fixture error before the lock correction; the correction has an exact 1/5 and confirmed-seed file 7/90 PASS from its owner. The joined full HITL run (`d74ff6d5`) then passed the lifecycle layer but exposed five errors in LiveClientTest: its old Native seam lacked current Codex prepare_submission. `a7d99490a` updates that maintained fixture to real correlated submission/receipt and signed reconciliation byte flow. Root corrected the fixture version to the actual `0.159.3` (the `rust-v` prefix belongs only to the source tag); joined focused LiveClient checks pass 11/94 (`46f3cd30`) in 259ms. No full package pass is inferred and no further broad rerun was made.
- Full Lab check before the eager-load correction failed its loading guard (`470a34eb`); the corrected owner run passed atoms60 and molecules105, then was deliberately interrupted in organisms (exit143). No full Lab pass is claimed. Root-owned Git all was deliberately stopped (exit143) after prolonged execution: completed source layers through core were green, feat/final result not obtained. No duplicate broad runs or deadlines were increased.
- Actual static Lab composer, Codex artifacts, coldboot and publication: 10 Python tests PASS after source join. Before adding static Codex composition, the four metadata/installer-boundary modules passed 7 tests after fixture correction.
- Removed obsolete 417-line fake full-installer case and historical worktree dependency; retained direct mandatory-composition refusal and actual static metadata generator. Ownership and retained coverage are documented in lab-config task `gad.b/test-environment-source-cleanup.md`.
- Removed the obsolete one-round protected campaign fixture: it violated the delivered R3 minimum and simulated three OS children. The smaller canonical-result join above replaces its local logic/byte-flow responsibility. Its original `5dd1b0fc` timeout remains retained; removal is not a claim that installed protected full-flow performance passed.

## Remaining implementation and delivery gates

- [x] R3 (`ig4`) source integration: bounded execution, phases, escalation and public modes share R2 manager/receipts. Whole-task completion awaits final review and delivery.
- [x] R2 canonical local byte/result join and same-held snapshot boundary verified. Actual protected parent-result performance and installed flow remain open centrally in `gad.2`; prior `5dd1b0fc` is not accepted. Older broad compatibility `309ad430` contains 13 errors, not a pass.
- [x] `qkc` executable source assets and classified coupling inventory integrated. Final source review remains open; installed execution belongs only to lab-config `gad.2`.
- [x] Codex read-only completed-turn query (`xza.0`) joined at `a275ee043`. The context owner now selects the retained claim and exposes an authenticated `observe_context` route, rechecking record/admission after the query. Root joined source checks: 117 tests/828 assertions PASS (`a2b1f3f0`), including actual record-to-WebSocket lost-reply flow and scoped socket admission; event-lock deadline check separately 7/41 PASS (`80fc1461`). Candidate observation never signs, imports, settles or resends. The initial new-module NameError is retained in `18e98e68`, corrected before these checks.
- [x] Public protected `inbox observe` CLI joined at `5407d873d`, using existing original-selection status and authenticated `observe_to_sign` admission, with candidate-only output. The final joined nine-file check passed 129 tests/1255 assertions (`fad9b8e3`) in 5.87s. Lab source Codex producer/static/transport compatibility check passed 4 Python tests in 1.60s; no native or installed probe. `xza.0` is now in-progress, still needs_review, with every whole-slice success criterion open.
- [x] Canonical observation import/fetch and distinct signer source are joined through `33b432e6c`. Public `inbox-observe` and `inbox-settle` adoption is committed at `ab5094864`; the actual journal/owner/signature/replay check is joined at `8deb2633b`. This closes the local producer/import/fetch/sign/reconcile path, not deployed permissions or whole-task acceptance.
- [x] Obsolete fake-native inbox E2E removed at `737c4ef79`; its scripts manufactured native acknowledgement and required the removed argv path. Source responsibility remains in maintained record/socket checks; installed requirements remain in gad.2. No replacement Lab emulation was added.
- [x] Existing provider CLI route restored at 0036003a6; the speculative managed remote consumer from e293dd435 was removed.
- [x] Remove obsolete native-observation/read-proof source and dedicated installation assumptions. Ordinary ace-llm launch source checks and terminal-submission checks are recorded above; real live runtime observation stays in gad.2. Dedicated Codex startup/ACL is cancelled, not a gate.
- [x] Canonical protected workflow source adoption: document and verify the actual round/export/submit-result public sequence, preserving ordinary/protected ownership and exact current candidate gates.
- [ ] One independent review of the final joined source, plus appropriate local unit/integration verification.
- [ ] Integrate main, synchronize repositories and prepare fresh gem artifacts. Publication remains the Captain's interactive OTP step; actual installed task/observation remains `gad.2`.

## Current query verification clarification

Exact native client/queue/runtime correlation is validated by the Inbox owner
against its private retained intent and receipt, then the CLI validates original
scope and candidate shape through the fixed authenticated endpoint. The direct
public status deliberately omits native receipts. A proposed duplicate CLI
check assumed those private fields were present and failed its regression
(`904c96c8`); that dead check and its assumed-field test were removed without
widening public status or changing the actual owner validation. The final joined
check above covers the delivered behavior. The Herdr query alone still does not
promote a candidate into a trusted evidence ID or signed proof. The separate
joined ACE Assign producer and signer below now perform that local source flow
through the existing canonical owner.

## Latest joined source verification

`8e4488183` makes the private protected context snapshot expose the retained Codex
submission and queue correlation, leaving ordinary public status unchanged.
Its focused Herdr checks passed 36 tests/245 assertions (`f737178d`). The authority
import/fetch, static trust and transfer owner executed 38 tests/263 assertions in
its worktree before source integration; that count is not a fresh root rerun.

The root joined check at `8deb2633b` plus the exact source subsequently committed
as `ab5094864` passed **24 tests/183 assertions in 38.67s** (`d41ba772`). It uses
the maintained real temporary Git journal, Inbox/context owner and RSA proof.
Native history, installed credentials and protected key-reader admission are
controlled source seams. Both lost import and lost reconciliation replies keep
admission; retries use identical original mutation/generation, one canonical
observation and one reconciliation, without message resend. Uncertain history
and wrong candidate association create no evidence. The preceding focused CLI,
key and context check passed 20/136 (`21f628f3`).

These checks found and fixed actual source errors: CLI relative loading,
mapping-record handoff and runtime target projection using the existing closed
`ObservationTrust::TARGET`. Held deployment/history references are now checked
again after the public workflow callback. Initial root loading failure remains
recorded as `1845b585`; the producer mismatch and fix are documented in the
child's `joined-observation-source-checkpoint.md`.

`ace-task doctor --check frontmatter --errors-only` scanned 795 records without
frontmatter errors; it still reports 465 warnings. This is not full doctor
scope/structure acceptance or repair of the historical backlog.

## Historical startup investigation — rejected design

The former Codex app-server startup/ACL investigation is superseded by the
Captain decision above. It is neither an unresolved approval nor a future
prerequisite. Historical source/test receipts retain their actual scope;
native-observation implementation is being removed, not accepted.
