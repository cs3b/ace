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
