# Protected HITL attempt syntax checkpoint

Root independently confirmed and approved this narrow correction: LaunchLifecycle emits exact `launch-<24 lowercase hexadecimal>` attempts; HITL Store and shared ManagedEnvelope previously rejected those original IDs. Assignment IDs remain compact. Attempt syntax alone grants no authority; current binding, original attempt liveness, proposal admission, and exact expected-string correlation remain required. ManagedEnvelope owns the one protected-attempt pattern and Kinds reuses it.

Selected source tests passed: Store exact-binding/malformed/boundary/assignment negatives 1/9, HITL receipt `770abb37-5f51-4de0-9a67-5fb836e9fe74`; shared envelope JSON round-trip/foreign exact-binding/malformed/boundary/assignment negatives 1/9, contract receipt `e10f9e12-c6d3-499d-95d4-aca7cfd441be`. Both use injected binding/OS owners and real maintained serializers; no native, installed or provider network probes.

The actual SC5 feature WIP (separate from this narrow freeze) uses the real original protected attempt, HITL Store create/ack/reconcile, canonical ProposalJournal resolver and existing registered merge/import/worker consumer. It passed 1/74, 68.34s, Git receipt `7b7845ea-88f8-41b2-86d7-9df54495da67`; direct and standing decisions passed 1/71 each, `50b72985-1a3b-4eb1-825f-904cf0701814` and `c0a90982-69e4-40f0-b9a2-32f79e2b1dd2`. These are supporting composition evidence, not acceptance of the still-uncommitted complete SC5 test matrix. Missing/out-of-scope scenarios remain pending execution.

Preserved failures: `15bc6511-ccd1-4622-9c78-3341593c860d` exposed Store rejection; `8c167183-a751-4a8d-938d-d5d429f87c27` exposed the additional envelope guard. `dacd5bcf-b1c8-4c70-98a3-a8e10f49e2ce` reached real canonical approval then exposed stale fixture generation captured before proposal mutations; the fixture now captures generation after decision preparation, without automatic retry or changed deadlines.

No task closure, authorization-policy change, OTP-on-merge requirement or installed acceptance is claimed. Independent source review remains required.
