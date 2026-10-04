# Listener ownership implementation evidence — 2026-10-04

Code source: `0d49927f42e5401ec2e5e5e2722b74b4ba02ff0e`; baseline: `b06d0aee92d58eb03b6603c202993b0152ba7138`.

Before the fix, the public `Service#run` regression in `scoped_service_test.rb` failed: **refused startup removed the active endpoint**. Command: `bin/ace-test ace-hitl test/fast/lifecycle/scoped_service_test.rb`; 12 tests, 52 assertions, one failure. Local receipt: `.ace-local/test/reports/hitl/8x3vsf/`.

The service holds a protected stable endpoint lock throughout its lifetime, records the bound socket device/inode, and only removes that matching socket on shutdown. Lock files are deliberately retained so every starter uses the same inode. Stale recovery requires a service-owned protected socket and an explicit refused connection. Other probe failures, files, symlinks and unsafe locks fail closed. Store, peer authentication and OTP behavior stay on their existing paths.

Executed on the code source above:

- `bin/ace-test ace-hitl all`: **222 tests, 1128 assertions, zero failures/errors, one skip**, exit 0 (47.19s); receipt `.ace-local/test/reports/hitl/8x3vzo/`.
- `bin/ace-test ace-hitl test/edge/lifecycle/multi_uid_boundary_test.rb`: one root-required skip, zero assertions; receipt `.ace-local/test/reports/hitl/8x3vz0/`. This is not real installed multi-UID proof.
- `bin/ace-test ace-hitl test/fast/lifecycle/lifecycle_overseer_test.rb`: 9 tests, 63 assertions, zero failures/errors; receipt `.ace-local/test/reports/hitl/8x3vw0/` (same code, before commit).
- `git diff --check`: passed.

The public endpoint tests exercise unchanged identity after second-start refusal, authenticated ping/create/read/deliver/consume, unsafe directory/file/symlink/lock refusal, failure after bind, stale recovery, normal shutdown/restart, reachable replacement after old shutdown, and two starts synchronized immediately before acquisition. They use real UNIX endpoints and kernel same-UID peer authentication; concurrency uses independent file descriptors and the OS flock, with Queue barriers rather than sleeps deciding the winner. macOS has a 104-byte UNIX path limit, so the disposable directory is explicitly rooted in `/tmp`.

Planning: loaded as-task-work and as-task-plan workflows; first `bin/ace-task plan 8x3.t.vft` was stopped after over three minutes without output. One path-mode retry completed with `.ace-local/task/8x3.t.vft/8x3vxu-plan.md`; read and reconciled with current implementation and prior baseline reproduction. Its ownership, safety, public-lifecycle and verification steps match the executed approach.

SC1–SC3 are verified. SC4 remains unchecked pending independent exact-head review. Task remains in-progress. Lab installed multi-UID acceptance remains separately owned; no merge, push, release or deployment was performed.
