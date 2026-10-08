# Recover original completed cleanup through inspection

Candidate for independent readiness review. No wire/source implementation or whole SC4 acceptance follows. The same Installer remains the physical owner; no new RPC, journal, privilege, result ledger or effect retry.

## Verified existing boundaries

ProtectedCleanupOwnerClient#inspect! currently accepts only kind inspection with inspection_ref. ProtectedCleanupOwner#inspection requires the original operation owner to equal its current observed self, so executor restart is supported but root-owner restart is blocked. ProtectedServiceReceiver#recover_no_effect always turns cleanup inspection into failed evidence and complete_no_effect. A genuine retained successful removal therefore cannot be imported through this path.

Existing complete_service already admits a fresh installed executor of the recorded UID, checks the original claim/project/assignment/attempt/head/candidate tuple, and never replaces executor_process_binding. A replacement birth is a fresh authenticated inspector, not the original executor. ServiceCleanupEvidence authenticates the original complete success pair, protected held result bytes at pending import, original dispatch lineage and immutable imported bytes for later consumers.

claim_service_settlement preserves uncertain/failed state while adding a canonical challenge. Challenged uncertain→succeeded is already allowed. The protected atomic service update treats failed as terminal and currently forbids failed→succeeded. A cleanup-only positive recovery exception must be reviewed explicitly; generic terminal rules remain unchanged.

## Closed disjoint response

The existing inspect request, challenge admission and original request/input/claim/request-event/dispatch-event/operation-owner digests stay unchanged. The response is exactly one of:

- Existing no-effect: {schema,kind: inspection,request_id,input_digest,inspection_ref}, existing bounded no-effect bytes.
- Completed success: {schema,kind: completed-result,request_id,input_digest,receipt_ref}, exact original retained success receipt bytes.

Both use the existing root-selected endpoint identity and TransferCodec artifacts framing. References have exactly path/bytes/sha256; receipt bytes remain 1..65536 and must match the declared digest/size. Unknown kind, extra fields, mixed receipt/inspection refs or ambiguous internal Installer kind refuse. The internal inspected success result is tagged as succeeded; no-effect is tagged failed-no-effect. No caller supplies the outcome and no branch calls execute_cleanup!.

The receiver selects the success branch before constructing failed/no-effect evidence. It constructs the SAME original root-success selection {schema: ace.protected-workspace-prune-root-selection/v1,request_id,input_digest,operation_owner_binding_digest,receipt_ref} and pairs it with the returned unchanged receipt bytes. It builds the existing terminal receipt from context.request, outcome succeeded and the ordered two artifact hashes. Existing complete_service receives the original claim, head and candidate plus this pair, using one stable completion mutation derived from the original recovery mutation. Lost completion reply uses canonical status/exact replay only; no new inspection effect or cleanup execution is authorized. Succeeded canonical status is authenticated by the existing collection reader before returning success.

## Original success provenance and restart

Executor restart may inspect with fresh installed UID/GID/groups/OS birth. Root-owner restart may return ONLY positively retained success: the current fixed root owner is an authenticated readback owner, not evidence that the old lifetime exclusion remains held. The original canonical operation_owner_binding stays unchanged in receipt selection/provenance. Current root identity is separately captured/rechecked by the existing observer around inspection and returned transfer. The original-owner equality requirement remains mandatory for no-effect; replacement root cannot manufacture an absence proof.

The SAME Installer must derive the original capture/result selection from the authenticated canonical request/input/owner-binding/dispatch tuple, verify original installed publication/history/config associations, open protected nofollow regular held immutable result bytes, and authenticate the complete retained manifest/member hashes plus original positive removal/fence evidence. Missing, partial, replaced or corrupt retention is unavailable; workspace absence alone is insufficient. It never reconstructs a successful receipt from current state and never reexecutes removal. Original success retention/publishing is still Lab-owned missing source: wave412 reports no implemented execute/inspect or retained success pair yet. His proposed fixed private capture is keyed by SHA256(request_id,input_digest,original_owner_binding_digest,dispatch_digest), with immutable completed receipt under the existing authority result root. Exact publication and held verification API must be frozen with that producer before claiming this restart capability.

## Canonical transition precision

The lower existing atomic update may admit failed→succeeded ONLY in protected mode, operation prune-preserved-workspace, original dispatch_started, pending operation complete_service, absent original completion_digest, same immutable original record/claim/input/candidate/owner bindings, and a fully authenticated original successful root pair under ServiceCleanupEvidence. Existing authorizer and terminal collection validation remain mandatory before CAS; no flag or mere shape permits the transition. Succeeded and failed-settled remain immutable, conflicting completion digests refuse, generic failures remain terminal, and historical validation rechecks the same pair. The existing failure event remains historical uncertainty/failure evidence; a later canonical positive retained result does not erase it. The current recovery challenge cannot become no-effect evidence for this success branch.

## Controlled responsibility map

Actual root owner client/listener + receiver + real Server/journal/import must exercise executor restart, challenged uncertain completion, narrow failed recovery, root-owner replacement with genuine immutable success, unchanged original bindings, exact replay/lost reply and one canonical result. Inject only kernel/unit/root protection boundaries and a fixed Installer readback fixture until the actual Lab producer is composed. Assert no execute call for every inspection/replay. Reject missing/partial/tampered pair, wrong original owner/dispatch/input/head/candidate, forged refs, replacement-root no-effect, mixed outcome, later failed-settled, conflicting completed receipt and foreign fresh inspector. Failed import/CAS retains uncertainty and exact recovery selectors. Lab separately composes its actual retained-success producer/readback with the same contract; fake callback bytes alone do not close SC4. No native/root/systemd/installed probes.

## Independent source-design review

Root approved implementation direction on 2026-10-08. Replacement-root readback must never create or install original `input_inhibition` or a consumed invocation. Its only admissible result is positively authenticated retained success. No-effect inspection still requires the original owner and existing lifetime inhibition. The fixed Installer inspection return is closed `{kind: "succeeded" | "failed-no-effect", bytes:, receipt_ref:}`; execute retains its existing two-key return.

Failed-to-succeeded recovery is restricted to protected cleanup dispatch failure without an existing `completion_digest`. A completed failed receipt remains immutable; existing completion conflict and replay validation are unchanged. Unknown or partial retained success remains unavailable. Actual physical producer composition and SC4 completion remain open.

## Bounded implementation checkpoint

Base is `54df30910` (own isolated tree joined reviewed main). Owner inspection now admits disjoint result kinds with strict references and existing 65,536-byte reference cap. Original-self inspection retains the existing inhibition transaction; replacement-self inspection does not touch consumed state and refuses no-effect. Actual current readback actor and ingress receiver are authenticated independently of immutable original canonical bindings. Client decodes only the two exact wire shapes and returns closed kind/receipt_ref/bytes. Receiver uses the existing complete_service/import owner for positive retained success and existing complete_no_effect for positive absence. No receipt or outcome is inferred from transport failure.

Controlled responsibility/evidence (package cwd, direct `../bin/ace-test`, exact definition-line selections; outer 120 seconds for composed scenarios, 60 for the inspected Client file; no product deadline changes):

| Scenario / actual owner | Receipt | Executed result |
| --- | --- | --- |
| Original root inspection admission + wire | f509686b-b577-4fe0-bae5-0e3dbf0aeefa | 1 / 24, 17.52s |
| Replacement root retained pair → real Receiver/Server/import; original bindings and storage-free replay | d9cd9da9-98cb-4e2d-8506-5cb6ff2ac239 | 1 / 15, 18.49s |
| Actual canonical failed dispatch without completion digest → success | 0b4d1dba-fa7b-4df9-8516-f8d60873f85f | 1 / 17, 21.56s |
| Actual failed complete_service receipt/digest cannot be superseded | c33ab08e-3eaf-40cc-a37e-2c9da668f2cf | 1 / 12, 19.53s |
| Replacement root no-effect refuses; no consumed state/inhibition | 573e755f-a8eb-4b6c-8cc0-6d5e0b1a6af2 | 1 / 10, 15.02s |
| Existing actual no-effect inspection/import/storage-free replay | e839c9ee-ad2a-45e5-b125-784c659c5141 | 1 / 27, 25.18s |
| Accepted completion reply loss → uncertain, canonical status recovery, one success transition/no second readback | d49c181d-f02b-4adc-9e98-dcbb28bd6232 | 1 / 19, 20.35s |
| Strict Client whole inspected file: both kinds, unknown/mixed refs, input mismatch and bounds before body | e71e206f-6b51-4566-8801-2eedbbe351a9 | 8 / 62 |

All listed accepted runs have zero failures/errors/skips; reports are under this worktree `.ace-local/test/reports/lab/<receipt>/`. Retained failed receipts: 51d91c8f-5ba6-45e3-b5fe-d2a2f592de1d failed before readback because fixture incorrectly selected top-level pid instead of process_binding.pid; corrected exact nested replacement identity. 3552cda3-3bae-470f-bcf7-d8fcd21ec8a4 and f882ec2b-3cf7-42c9-9564-066fc718eb14 asserted SecurityError for invalid reference sizes, while the maintained shared reference validator correctly raises ArgumentError; assertions now use that existing owner classification, no validator weakening.

Kernel/unit/DAC observation and fixed Installer retained facts are explicitly injected. Git, original admission, sockets, transfer, collection verification, journal CAS and replay are real maintained source owners. This checkpoint does not implement physical retained capture/removal, prove success from callback bytes alone, close SC4, or claim installed/root/native acceptance. Lab's actual same-Installer producer/readback composition remains required. Independent source review of this checkpoint is pending.
