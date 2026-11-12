# Supervision continuation — 2026-11-12

Status: in-progress. Approved one preserved UTM/Forgejo/Pi-GLM run; no reset or reseed.

## Implementation and acceptance

- [ ] Native live handoff retains terminal identity and guarded origin; new terminals remain unique.
- [ ] Observation wakes the responsible owner only: lab commissions/project availability/escalations; project commissions/reports/failures/integration transitions. Routine progress is visible without waking.
- [ ] Exact revision acknowledgement, restart/replay idempotence and visible wake budget remain.
- [ ] Explicit role sequences; no implicit worker/reviewer/integrator for report-only commissions.
- [ ] One HITL case: advisor recommendation before Captain delivery, safe failure delivery, no forged consent; secrets bypass advisor.
- [ ] Report stage timings, one-pass owner reads, accepted-before-retired-before-continued recovery.
- [ ] Local tests, independent review, SHA-bound gems/native artifact installed locally.
- [ ] Preserved live run: bootstrap readiness, base/dependent/docs merges, release open, worker interruption/replay, real Captain choice, unthrottled five-minute idle.

## Evidence

Baseline main a84d2eae19a5395a57f6adb382d0f51d7d808c05. Published five gems are not assumed deployed. Earlier evidence remains in 2026-11-11-live-cycle-acceptance.md. Record stage durations and model usage only where measured; unknown otherwise.

### Local implementation evidence

Native source `84753e6b9955fac56a316e1e99d3cbe7219fad9b`, source tree
`e948aca926f1511806e03bbea4933c32630122b8`: schema 2 transfers terminal ID,
guarded origin and original Linux pidfd. Descriptor adoption is RAII and
CLOEXEC precedes shell restoration. Parent reparenting after handoff is expected;
birth and kernel handle remain authoritative. 58 handoff tests pass on macOS
(nextest 3635979c-278e-4a7a-a022-e24beabaf8f8). Linux-only probes and real live handoffs remain pending.
The old schema 1 VM needs a controlled first restart; it cannot export identity
it never recorded in its handoff payload.

ARM64 binary SHA256 `43e5390f4f8c7ffe9d18aef0ec29cfcdcf801db061695a4684671cae4f23f918`;
provenance SHA256 `d524bba67f31798263262f6cd644e75ec2e1fba293382e1e6ef71aa6cba25201`.

Package runs: overseer 600/2889 (one skip), HITL 411/2116 (six skips),
Herdr 629/2600, coworker 424/2012 and wake JS wrapper 2/7, all zero failures.
Latest additional guards: overseer targeted 43/284 (445a8a84-2bd8-45f2-a1e9-f3b03dd31ee7),
lab targeted 48/350 (5043b889-c1df-4d74-8ef3-1990e232a1a2), zero failures.
These are component evidence, not live autonomy acceptance.

Final component reruns after review corrections: overseer 593 tests / 2841
assertions, 0 failures/errors, 1 skip (e4de91c7-2850-46da-bfda-3231c3f661f1);
lab 771 / 3652, 0 failures/errors, 4 skips
(ea50e3c5-9b41-4403-8867-f003ca30a24e). Different overseer count reflects
replacing recursive projection tests, not a newly disabled suite. Independent
Ruby/workflow reviewer PASS binds to 87dc65e6ae1abfcb63e909cabb616b2f55c37d5a;
native reviewer found no remaining code blocker, with Linux acceptance pending.
