# Protected launch source review, round 3

Independent reviewer session `09j-9cbf-source-round3` reviewed exact `9cbf39550` and returned APPROVE with zero feedback. Parent inspected the report; independent lifecycle 21/165 and ProtectedLinux 6/28 passed. Round-2 feedback `8x44lo5s` and `8x44lo5t` was valid and is resolved by this source repair.

Actual pidfd support is probed before admitting launch; the launcher handle is acquired after pure plan validation and before reservation staging/CAS, retained only on the actual fresh winner and closed on replay/refusal. Status reports retained exact-child exit as uncertain recovery and preserves ownership. Fail-before receipts: runtime `8x44p0`, lifecycle `8x44qc`; repaired runtime `8x44u3` 173/469 and lifecycle/journal `8x44xh` 33/323 passed.

Combined source `e2d3dad3e3c93247e0d741ddaef3cf07cddaa46f` merges the accepted repair with qjz main `3d2ffcdd46615eb8bfb2d4d73407f960e6951e69`. Frozen full Assign run `49490`, receipt `8x45dm`: 888 tests, 3961 assertions, zero failures/errors, two existing skips, 14m57s. Report: `.ace-local/test/reports/assign/8x45dm/summary.json` in the final worktree. Subsequent `c3bdc29c0` changes only the public termination diagnostic string; parent independently approved that exact one-line delta, with no broad rerun required.

The final amended fixed-container specification independently passed `09j-5549-fixed-container-readiness` with zero feedback. `needs_review=false` records that specification verdict; status remains in-progress.

Installed protected acceptance remains OPEN. Actual separate QEMU Debian kernel 6.1.0-53-arm64 enforced Yama 2 and denied hostile worker ptrace/process_vm_readv, protected file access and UID escalation. Installed public launch currently reaches canonical registration/reservation then returns uncertain before recording its child. This is retained failing evidence, not successful launch acceptance. Fixture diagnostics are pending. Crash/replay/EOF/replacement cases and independent installed evidence review remain required. Actual Lab/gad.2 acceptance is separate and has not occurred.
