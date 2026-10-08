# Source integration checkpoint — 2026-10-08

This is implementation progress, not a completion verdict, main delivery or installed Lab acceptance.

## Joined source

ACE integration branch `codex/protected-pr-integration` joins protected PR operations, scoped publication, explicit HITL project routing, R2 parent/child registration and canonical round/export/results. Ready/merge carry their exact operation into the current campaign gate at claim, authorization, dispatch and journal CAS; draft creation/update retain the Captain-approved ordering. Commits through `09a40c053` include bounded per-operation immutable journal inventory reuse; the existing 30s candidate Git deadline is unchanged.

Lab integration branch `codex/lab-source-integration` joins coldboot, selected network producer, physical cleanup and static Codex composition through `5bbf15b`. The latter installs/authenticates original static fragments and inventories; actual attempt-owned runtime admission and producer startup attachment remain in implementation. It does not establish a working native launch by itself.

## Executed evidence

- Canonical recovery cleanup: retained success with replaced root, 1/16 PASS (`8ca78686`); lost completion reply recovered from canonical status, 1/19 PASS (`203cdb90`). No deadline changed.
- R2/service boundary join: 9/65 PASS (`ce81533a`); manager/canonical compact evidence: 46/345 PASS (`8c7e7ff0`); execution/transfer/prepared-input/receipt checks: 39/218 PASS (`30813b64`).
- Integrated operation-local inventory isolation and service gates: 18/131 PASS (`ba19098a`). Actual Git scan-reuse proof retained from the producer: 1/27 PASS (`ca38b565`), fresh operation revalidates.
- Actual static Lab composer, Codex artifacts, coldboot and publication: 10 Python tests PASS after source join. Before adding static Codex composition, the four metadata/installer-boundary modules passed 7 tests after fixture correction.
- Removed obsolete 417-line fake full-installer case and historical worktree dependency; retained direct mandatory-composition refusal and actual static metadata generator. Ownership and retained coverage are documented in lab-config task `gad.b/test-environment-source-cleanup.md`.

## Remaining implementation and delivery gates

- [ ] R2 full canonical parent-result flow: prior `5dd1b0fc` timeout remains unaccepted; narrow reuse corrections are not a substitute for confirming this flow. Older broad compatibility run `309ad430` contains 13 errors, not a pass.
- [ ] R3 (`ig4`): integrate bounded execution, phases, escalation and public modes with the same R2 manager/receipts.
- [ ] Lab Codex attempt-owned startup: original LaunchLifecycle attachment, exact producer/socket lifetime and whole-slice retirement/recovery. Literal startup input handoff remains unresolved; no new latest-session lookup or empty-scope exception is accepted.
- [ ] `qkc`: executable acceptance assets and classified coupling inventory. Installed execution belongs only to lab-config `gad.2`.
- [ ] One independent review of the final joined source, plus appropriate local unit/integration verification.
- [ ] Integrate main, synchronize repositories and prepare fresh gem artifacts. Publication remains the Captain's interactive OTP step; actual installed task/observation remains `gad.2`.
