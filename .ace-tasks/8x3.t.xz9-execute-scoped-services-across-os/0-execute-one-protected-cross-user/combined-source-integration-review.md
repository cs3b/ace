# Protected Endcap source checkpoint — independent review and executed gates

Frozen source candidate: `3c6e5e94def884a9647df9b14cb19079a314ae30`.
Accepted main ancestry includes `9d25c5e80` and docs-only `2e539` through native conflict-free Git merges. Source integration is approved as a checkpoint, not as completed xz9.0, a deployable full-service composition or installed protected execution.

## Independent combined review

Root's read-only combined review inspected the candidate based on `9d25c5e80`, including shared EvidenceJournal/ProposalJournal ownership, Lab policy composition and receiver direction. Verdict: APPROVE conditional on the receiver repair verdict. The final cleanup review below satisfies that condition. Original report: `/Users/mc/Ps/ace/.ace-local/review/service-combined-integration-review.md`.

The same LaunchLifecycle/Router/Server and per-project EvidenceJournal remain authoritative. Lab owns ServiceInput, ServicePolicy and GrantResolver validation; canonical proposal resolution uses that same journal's ProposalJournal. No Assign-to-Lab dependency, alternate policy dialect, journal or controller was introduced. Shared `prepare_service_update` preserves lower proposal authorization and global authorization uniqueness under the existing lock/CAS. Pending import bytes, service update and mutation reply commit together. Receiver requires fresh created claim, fresh begin permission and final fresh authorization before invocation; replay grants no invocation permission. Completion-only generation records exact observed executor truth while all other mutations retain expected generation admission.

Root executed the following exact focused checks (reports under `/Users/mc/Ps/ace/.ace-local/review/service-combined-integration-tests/`):

| Scope | Actual result | Receipt |
|---|---|---|
| Assign atomic service, replay, canonical reader and completion | 24 tests / 239 assertions, no failures/errors | `8x48f1` |
| Lab composition, receiver and protected policy | 16 / 76, no failures/errors | `8x48e2` |
| Downstream HITL proposal lifecycle/shared claim owner | 23 / 161, no failures/errors | `8x48if` |

An initial downstream filter selected zero files; it is excluded from acceptance evidence. Independent completion/current visibility/retained native worker ownership review `b398d015e..ef76e05a9` also approved with 34/386 executed, no findings. Author independently passed 34/386 in `8x47jc`; visibility fail-before `8x46vy` and same-UID sibling fail-before `8x47dz` remain retained.

## Receiver review rounds

| Round / source | Verified decision and correction | Evidence |
|---|---|---|
| `receiver-a681-orchestration-round1`, source `a68186d1a` | REJECT high native RuntimeUnavailableError escaped classification; medium confirmed terminal completion retained staging. Fixed in `6f0457c82`. | Reviewer 6/27 plus three reproductions; author fail-before `8x489j`: 7 tests / 9 assertions, one failure and four errors. Fixed handler/receiver `8x48ay`: 11/44 PASS. |
| `receiver-6f045-exact-repair-round2`, exact `6f0457c82` | REJECT medium pathname replacement between identity check and deletion could delete another object. Fixed in `56e5edfd6`. | Reviewer 8/37 plus failing post-check replacement probe. Author maintained fail-before `8x48li`: 9/39, one failure. |
| `receiver-56e5-quarantine-round3`, exact `56e5edfd6` | APPROVE, zero findings. Atomic rename into fresh private quarantine precedes moved device/inode verification and deletion. Mismatches remain retained; only an empty quarantine container is removed. This addresses invocation ownership races, not isolation from malicious processes with arbitrary same-UID filesystem authority. | Reviewer 9/40 PASS. Author handler/receiver `8x48mo`: 12/47 PASS, including preserved replacement bytes in hidden quarantine. |

All three original reports remain under `/Users/mc/Ps/ace/.ace-local/review/sessions/` in the named session directories as `review-report-gpt-6.1-sol:high.md`. Verified feedback `8x47ya4f`, `8x47ya4g` and `8x48hj7a` was resolved with the corresponding commits and actual receipts. The intermediate `8x48m1` failure arose because a test glob omitted the hidden quarantine; the final assertion includes hidden entries and verifies preserved bytes. It is not counted as a pass.

## Executed broad gates and retained failure

| Frozen source | Runner | Actual result | Receipt |
|---|---|---|---|
| `3c8f968b6851ea8d3aac6876b749de6b4167dcf9` | `bin/ace-test ace-assign all` | 960 tests / 4474 assertions, zero failures/errors, two skips, 16m20s | `8x488p` |
| `2b3f26dc57fc194a923a637b20bacd8883bb002d` | `bin/ace-test ace-lab all` | 198 / 694, zero failures/errors, one skip | `8x48bw` |
| `3c6e5e94def884a9647df9b14cb19079a314ae30` | `bin/ace-test ace-lab all` after final cleanup repair | 199 / 697, zero failures/errors, one skip | `8x48nm` |

One default fast monorepo run, `bin/ace-test-suite --parallel 1`, on exact `2b3f26dc57fc194a923a637b20bacd8883bb002d` terminated **FAILED**: 50 package entries passed, one failed; 11196 tests passed, one failed, 24 skipped; 34124 assertions; 372.97s. Sole failure was Herdr `test_post_launch_io_error_kills_child_and_raises_post_launch_error` at bounded_process_test.rb:100 (ESRCH expected but nothing raised), receipt `8x48iu`. Herdr source had zero diff against accepted `9d25c5e80`; a focused file recheck passed 7/22 in `8x48lj`, which does not erase or classify the suite failure as pre-existing. Root assigned separate fixture diagnosis/repair. The failed broad gate remains explicit; a final suite after both reviewed repairs is still required before main integration. No timeout was increased and no full Assign rerun was used for Lab-only repairs.

## Product and installed gates still open

### Combined default suite after separate Herdr fixture repair

Native Git merges incorporated accepted main `c82ffc671` then the separate fixture candidate `b19890d49f72fb6914a23e32ffa631852c38e3db` without conflicts. The latter changes only the Herdr bounded-process test readiness fixture and its implementation evidence; production Herdr is unchanged. Frozen combined source was `1ba0181aa7e9b3df8bcc79ae1ec57c347e7125a5`.

Exactly one `bin/ace-test-suite --parallel 1` run (owned session 55411) completed exit 0: **51 package entries passed, zero failed; 11201 tests passed, zero failed, 24 skipped; 34160 assertions; 366.54 seconds**. Configured deadlines were unchanged. Representative actual package receipts: Assign `8x48xj` (806/2960 PASS), Herdr `8x48zq` (469/1456 PASS), Lab `8x490r` (199/697, one skip). The runner discovered Lab twice; the aggregate is reported as executed package entries, not a deduplicated claim. No full Assign/Lab repeat was introduced for this combined gate. The earlier failed suite and `8x48iu` remain retained above.

Root separately reported independent fixture review APPROVE with 9/52 executed (`8x48wh`). Any subsequent fixture-only assertion strengthening is a distinct exact delta with its own focused proof; this suite is tied to the source SHA above. Root owns final integration. This passing source gate does not close the following product/installed gaps.

Final fixture assertion-only delta `b020ef24712b176e1167cf0c81039a20c676cd9d` independently APPROVED with 10/57 PASS `8x490p`; original report is retained in the 8n0 task's independent-review.md. Native merge into this candidate was conflict-free, tested source `1e5340776df85a08311f6ee77b2aa1565561fbab`. Exact affected Herdr file on that combined tree passed 10/57 (`8x494y`). Production code is unchanged; no broad gate was repeated for the assertion-only delta, as explicitly directed by root. Current xz9.0 draft/needs_review metadata intentionally applies to the unresolved result/evidence/finish amendment, while this narrower source checkpoint is accepted. qjz is now delivered and independently installed-verified; historical readiness reviews remain retained.

Receiver tests use authority reply fixtures. Actual Git bundle materialization, fixed handler execution, evidence bytes and uncertainty/cleanup behavior are exercised, but protected distinct-UID Client/Server/Endcap receiving transport is not proven. AuthorityComposition deliberately refuses construction before journal/listener creation while result/finish, recovery, inbox and evidence operations are incomplete. Public receiver socket/CLI, full composition startup, installed source consumers, canonical historical corruption cases and installed OS proof remain open. No native launch probe, deployment or publication was executed by this lane. The accepted protected launch and receiver-map dependencies do not imply actual receiver bind readiness or LSM acceptance.

## Read-only next-slice outline

The smallest next source slice is canonical worker result import plus purpose-filtered evidence fetch and launcher/supervisor finish admission, followed by recovery projection. Reuse CanonicalEvidence, ReceiptTransfer, existing ReceiptVerifier and coordinator finish/lifecycle exclusion; extract an owner helper where necessary so result provenance, accepted receipt and terminal event share one journal CAS rather than accepting an intermediate imported result as completion. Result is attributed to the exact bound worker/native descendant; finish remains independently admitted by mapped launcher/supervisor against canonical candidate/review and pending service/inbox/cleanup truth. Expected generation and mutation identity remain strict. Missing no-effect or cleanup proof must return blocked/uncertain, never free ownership.

Dependencies: this reviewed source checkpoint must be integrated first; accepted 09j origin/map/kernel and qjz proposal owner must remain intact. Current lower coordinator recovery/inbox APIs are reusable owners, not new transport contracts. Subsequent bind/reconcile inbox routing additionally needs fixed installed inbox contexts, authenticated Herdr signer/consumer configuration, expected_registration and exact retained signed-proof replay; wire paths cannot select local Inbox objects or private files. Full composition and receiver socket/CLI follow only when every required operation is present. No new implementation is authorized by this outline, and no new code was added after the frozen review candidate.
