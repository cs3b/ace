# R3 implementation and test responsibility map

Use the existing campaign record/store and R2 collection/result flows. No alternate execution engine, acceptance gate, ledger, provider probe or paid call is introduced.

| Behavior | Owner/layer | Verification |
|---|---|---|
| Discovery two-round export; delivery three rounds/two clean/five cap; stricter-policy conflicts | CampaignPolicy atom | Small deterministic policy tests |
| Initial plus two retries, terminal provider failures, unresolved launch after restart | CampaignPolicy + existing collection admission | Unit outcomes and maintained manager integration with controlled executor |
| Verified canonical defect identity, duplicate independent sources, severity correction and attempted-fix recurrence | Existing assessment/projection owner | Existing fixtures with explicit source assessments; no text-similarity dedup |
| Escalation and explicitly authorized finite next phase retain lifetime counters/history | CampaignManager and SAME CampaignStore | Durable temporary store, restart and replay tests |
| Before-call guard and attempt reservation/completion | Existing R2 flow/ReviewManager | Controlled external executor; zero calls beyond cap; pending failure remains stopped |
| Status/finish/dry-run parseable outcome and unchanged state | Existing campaign CLI | Actual public CLI in isolated temporary repository; no provider calls |

R2 owns the overlapping campaign manager/evidence/authority changes until frozen. Begin with pure policy and tests, then join the frozen R2 rather than patch stale R1. Final integrated review is parent-owned. Installed Lab acceptance is not claimed by this source work.
