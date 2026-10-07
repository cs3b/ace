# Bounded maintenance exclusion checkpoint

Implements the independently approved sibling amendment. Optional absolute `deadline:` propagates through the existing complete slot owner, authority mutex and retained Inbox inventory/event owners. Nonblocking contention or expiry refuses without consumer effect; partial locks and thread-local context unwind. Ordinary callers remain blocking. Finite Integer/Float deadlines only. No deadline increase, sleeps, Thread Timeout or new lock/ledger.

Executed controlled gates:
- LifecycleExclusion full file: 12 tests / 35 assertions PASS, `675df842-88d5-47a2-a4e4-350a427585bf`, 454.27ms. Real slot contention, partial unwind and invalid/expired deadline plus existing ordinary shared/exclusive behavior.
- DeliveryRecordStore full file: 19 / 43 PASS, `1e757b60-1ba2-4df1-8782-f724aeffca51`; report 0ms is not timing proof. Real inventory/event contention, release of earlier event and inventory, expired/invalid deadline and maintained persistence tests.
- Actual Inbox retained inventory: 1 / 6 PASS, `1be7a8fb-c39b-40c3-89f1-0b933df97dde`, 4.96ms; retained queued record event contention then success, empty thread-local lock projections after unwind.
- Actual maintenance snapshot and normal admission lock contention (`deployment_test.rb:580`): 1 / 21 PASS, `821a7331-f4ed-4ca5-b501-94ed5e245d87`, 467.69ms. Real canonical Git snapshot, contended authority mutex and slot, successful bounded maintenance, ordinary blocked start resumes, canonical ref advance refuses, missing ref refuses.

Retained attempts: mixed-package path invocation `99d83891` and unqualified Herdr path `508099ef` selected zero tests due missing test_helper; corrected explicit package invocation. Initial actual maintenance `3b70b162` selected 1 / 11 and failed fixture protection before contended second owner could reach lock; second fixture authority now uses the same injected protected-root boundary as existing maintenance owner. No production authentication relaxed. Earlier lifecycle `4e287fbb` and store `8b8f0ecd` green receipts precede final finite-type validation.

No native/root/systemd/installed/process-identity probes or broad/default suite. This bounds contention, not preemption of Git/filesystem work. SAME Installer preview must pass its original accepted-at deadline and preserve remaining budget in bounded reads; Lab source remains wave412-owned. No physical preview/cleanup or task closure is claimed. Independent source verdict pending.
