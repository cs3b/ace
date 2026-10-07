# Shared multi-assignment provenance checkpoint

This additive source checkpoint changes only the existing EvidenceJournal reader, its actual temporary-Git tests and changelog. Inventory and Overseer activation remain separate WIP; qk0.0 stays in progress.

`event_commits_for_assignments!(selectors:, commit:)` authenticates one full fixed first-parent history, each selected assignment's complete event chains and the actual file OIDs. It returns a deep-frozen introduction map and keeps no owner or cross-operation cache. Existing singleton/batched-per-assignment queries delegate to this owner. Tree argv and raw-blob transfers stay bounded; disappearance/reappearance, ambiguous selectors, chain corruption and changed serialization remain refusals.

Executed unchanged final reader source: `bin/ace-test ace-assign ace-assign/test/fast/molecules/evidence_journal_test.rb --timeout 180`: **20 tests / 90 assertions**, no failures/errors, 15.93s, receipt `d3226d71-c4e0-46c6-8083-48b3a9db5d61`. The real multi-assignment regression proves one traversal, reauthentication on a new operation, and refusal when the second assignment disappears/reappears, changes raw bytes or contains an invalid chain. Earlier singleton reader regression was **19/79**, `a83910ce-0634-4f05-9bf1-cb5fa72308e8`.

The still-uncommitted actual inventory consumer uses this result for exact accepted registration/reservation introductions. Its genuine registration/raw-Git checks passed **2/54**, `babf7a64-59f3-4083-8873-6fa48c25d4e9`. Its corrected 35-registration frame/cursor check passed **1/10**, `5684e4b1-f7a1-4176-8b26-330d0e78a875` (121s overall). Separate monotonic fixture metrics: setup 101.479s; first inventory read 4.823s, versus prior 101.745s setup / 56.348s read. This is measured registration-only query improvement, not a completed-work latency guarantee; terminal/release provenance propagation still needs inspection and realistic measurement.

Failed evidence preserved: invalid oversized registration fixture `37c577b4-62a2-41a7-865d-68aef37fd859`; derived definition-ID fixture `ef1103c4-9381-48f8-9ddb-4dcf39711af4`; actual 180s timeouts `a06d22b1-c3c0-45c4-a4dc-4049a5e3fd91`, `0c279897-af13-45bf-800b-e653a62b6acc`, `5f6f4334-b1c2-4a3d-8570-10717b7be28a`. Timeout cleanup required terminating only each owned test child; none is a success. No timeout increase or product validation weakening.

Root reviewed the operation-local batching direction and WIP source with no weakening found. Exact frozen commit independent verdict remains required before integration. All checks are selected controlled source tests with ordinary temporary Git; no native/installed probes and no unfiltered-suite claim. `git diff --check` passed.

## Independent integration verdict

Root reviewed frozen `4a0ce9479036991aacafd0c35e0794f166c90cbb`, integrated as `6a5f15147` on main base `afe6e2433`. APPROVE the shared reader slice: complete per-assignment chains, immutable prefix walk and exact raw blob proofs remain required. A changelog append conflict was resolved retaining both entries; source was unchanged.

Independent executed `bin/ace-test ace-assign fast test/fast/molecules/evidence_journal_test.rb --timeout 180`: PASS20/90, zero failures/errors, 16.09s, receipt `751b4bec-c17f-4582-b981-265625bca95d`. Inventory/Overseer integration and completed-work latency still require their own evidence; no qk0.0 completion claim.
