# Result and fetch responsibility map

All authority and byte-integrity behaviors are high risk. Deterministic feature
tests use real Git event chains, refs, blobs, journal CAS and Client/Server Unix
transport. Injected kernel identities exercise source authorization only and
are not installed native proof. No protected native launch or security probes.

| Behavior | Layer | Owner |
| --- | --- | --- |
| Original/normalized digests, private event, failed zero artifacts | feat | endcap_results_test |
| Replay, changed ID, duplicate generation, stale candidate, CAS faults | feat | endcap_results_test |
| Worker lineage, reviewer purpose/reassignment, launcher/supervisor/executor, visibility | feat | endcap_results_test |
| Retained generation, corrupt event/import/blob, cache deletion/restart | feat | endcap_results_test |
| Receipt order/framing bounds and exact download descriptor | feat | authority/result_client_test plus existing receipt/transfer tests |
| Single status route and launch-only schema, guard stays closed | fast/feat | existing composition and launch tests plus result tests |

Focused changed tests run first; then ace-assign all and default monorepo fast
suite once candidate is ready. Retain runner reports and diagnosed failures.
