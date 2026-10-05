# Native readiness evidence addendum — 2026-10-05

Read-only source/retained-evidence audit at ACE `9d25c5e80d0eb084a67c1e587f4429cf5c86db67`. No native probe, launcher, privilege, memory or identity action was executed. This addendum preserves `readiness-review-2026-10-05.md` as the independent verdict on its exact reviewed head; it is evidence reconciliation, not another approval. xza.0/xza.1/xza.2 remain draft/needs_review, with success criteria unchecked.

## Retained capability versus installed acceptance

| Question | Retained evidence | Remaining acceptance |
|---|---|---|
| Codex exact completed-turn correlation | `evidence/codex-live-observation.json`: Codex 0.159.3 completed user item retains submitted client ID. | Actual Herdr producer must persist event/attempt/generation/digest/client ID before add and retain queued ID after acknowledgement; actual observer must verify that binding and transient payload digest. |
| Codex restart history | `evidence/codex-restart-observation.json`: exact completed item survives disposable app-server restart. | Authenticated actual-runtime successor mapping, old process retirement, endpoint ownership and protected provenance. Reading the same home from an independent server is insufficient. |
| Codex busy/equal-text managed queue | `evidence/codex-endpoint-ws-observation.json`: first turn inProgress; two equal-text followups have distinct client IDs; independent connection sees exact second ID in a completed turn. | Same scenarios through actual Herdr delivery; unrelated user-typed equal text and stale generation must never match a managed delivery. The fixture does not establish every duplicate/reorder case. |
| Codex discarded producer reply | Same Unix WebSocket artifact: producer reply discarded and connection closed; independent connection observes the exact client ID once. | Actual persisted submission-intent recovery across owner/runtime failures without resubmission; protected mapping and signer verification. |
| Codex transport | Same artifact and `evidence/README.md`: two connections to one dedicated Unix WebSocket server, directory0700/socket0600. `codex-endpoint-observation.json` retains the preceding proxy-initialize timeout. | Choose and independently review actual deployed runtime connection/ownership/succession. Proxy control socket interchangeability is unproved. Fixture permissions are not distinct-user acceptance. |
| Codex supersession | Retained live and Unix endpoint artifacts contain exact `deleted:true` cases. | Atomic deletion versus dequeue must exclude later execution of that exact ID. Absence, deleted:false, not-found and interrupted turns remain insufficient. |
| Pi identity/consumption | `native-interface-research.md` and authority contract retain installed 0.87.1 SDK inspection only. | Provider-owned exact TUI enqueue/dequeue identity, two equal payloads plus typed equal text, restart/fork/reload and target GPT-6.1 Sol configuration. No positive native Pi proof exists here. |
| Pi supersession | No positive retained native cancellation/retirement proof. | Independent Pi cancellation/dequeue race or positive exact old-runtime retirement; cannot borrow Codex proof. |
| Protected observation/signing | Proposed schemas and ownership in `observation-authority-contract.md`. | Real observer/signer/assignment-authority/inbox-owner identities, endpoint/key ancestry, exact signed-byte transfer, stale/forged/conflicting refusal and crash replay. |

The endpoint fixture's equal text is managed followup text, not unrelated typed text. Its completed turns prove processing capability, not assignment/business success. Fixture artifacts are not authority-issued imported observations and must not be treated as signed production evidence.

## Source boundary and dependency ownership

Current `ace-herdr/lib/ace/herdr/molecules/native_queue_executor.rb:56-87` submits Codex with thread/message argv and returns raw native output, without a client correlation ID or structured queued ID. `ace-herdr/lib/ace/herdr/organisms/inbox.rb:202-226` already persists intent and the accepted receipt; this existing Inbox record is the delivery state owner. No additional queue journal/controller is implied.

`ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb:655-700` already supplies exact signed bytes and canonical expected_registration to Herdr and records the verified consumer fact; its receipt-file input still needs the protected owner projection/bytes path described in the proposed contract. `ace-assign/lib/ace/assign/authority/deployment.rb:46-49` lacks the proposed observation-role/context fields. Its native launch mapping at line225 identifies Herdr control, not an accepted Codex endpoint architecture.

xz9.0 owns generic protected authority transport and receiver work. xza.0 owns the consumer-driven observation schema, Codex submission/observation and shared signer-to-consumer integration, dependent on xz9.0 and xza.3. xza.1 owns Pi provider identity/instrumentation and consumes xza.0. xza.2 owns separate native supersession proofs after both providers. gad.8/gad.b own actual installation/UID/endpoint/key/signing evidence; R2/R3 remain downstream acceptance. This addendum does not choose a new endpoint design or complete any dependency.

Next readiness work must resolve the missing actual-runtime and protected-path evidence under separately authorized execution. The previously blocked launcher probes remain excluded; their unknown filter trigger is not investigated or reassigned by this audit.
