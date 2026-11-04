# Native isolated delegation — component evidence, 2026-11-04

This is diagnostic VM evidence, **not TS-MONO-003/004 acceptance**. No clean reset or Forgejo task/merge cycle was performed in this slice. Eyes remained off. Task remains in progress.

## Implemented boundary

The singleton issuer authenticates the original DynamicUser session before authorizing project/role selection. It forwards a closed native start request; native reserves the stable agent name and owns terminal adoption. Scoped list/get project only permitted agents and minimal status fields. Prompts resolve the immutable terminal, capture native guarded process origin, require a dynamic UID, and submit with `expected_origin`. Native checks the incarnation before writing. `pane.process_info` now resolves exact terminal IDs without alias fallback. `pane.current` returns only the authenticated caller's terminal and configured root.

A real CLI attempt against candidate 82 exposed the protocol handshake: native CLI sends `ping` before its requested operation. The issuer previously rejected this with a lease-style error envelope, yielding a native `WireResponse` parse error. Host inventory confirmed that no worker was created. Candidate 83 adds authenticated protocol/version negotiation with narrowed capabilities and native error envelopes. This was a product fix, not a test prompt workaround.

## Artifacts actually exercised

- VM: `FA8EFE78-E054-408F-AFF7-6A151C043435` (preserved diagnostic VM).
- Candidate 82 source: `1effc28f83026e3e1311d3a85cd3c49db112336c`.
- Candidate 83 ace-lab source: `f225fec35c4f822d1b839b9bb83acf7538ee3068`.
- ace-lab `0.14.2.pre.utm83`: SHA-256 `548afb0afcc2a4fec9d2aeb5143f4e2a281fb1adf8de7dad28846dbeb449c633`.
- ace-herdr `0.10.1.pre.utm82`: SHA-256 `89de599ab055e453b3c3646b88ab49a7b70c1c16acc12bfdb21cb59bce895c42`.
- Native source: `9010381bc6f1ffd31018694fbe999b0a81fe414b`, tree `3c61c6af70551b0027ca438e243f42f791d6841c` (patch replay produced exact commit).
- Native ARM64 musl artifact: SHA-256 `718025cda9bdb5284e70f9ca3c60db5ccddc9af86ec60d381f1a232cb69822d2`.
- Native provenance: SHA-256 `fb51937106b316550671ba7352da65dcbab024e1edbf54f979cbb8e2585efb02`.
- Installed gem home: `/opt/ace/diagnostic/utm83/gems`; native binary `/opt/ace/diagnostic/native82/herdr`.
- Native service: `ace-e2e-herdr82.service`, invocation `c5a42f6923844913ac38f440a23a3d7a`, socket `/run/lab/herdr82/herdr.sock` owned by `mo` beneath its private endpoint directory.

The current source includes later changes not in this diagnostic artifact set. These hashes cannot stand in for final candidate acceptance.

## Real model-driven probe

Host launched configured `project-overseer` named `overseer83`, terminal `term_65f6b272f886c3`, pane `w1:p3`, runtime `/run/ace-auth-e96e05beff1db2c4`.

One explicit component-probe prompt asked it to run native `herdr agent start-isolated probe-worker83 --workspace w1 --project ace --role worker`, inspect the list once and end its turn. It did so. The root issuer authenticated its original session and authorized the native launch. The new worker was `term_65f6b28ef08964`, pane `w1:p4`, runtime `/run/ace-auth-94aa5efccbdfe641`. No project installation or editing occurred.

A second component-probe prompt asked the same overseer to submit one role-confirmation prompt to the existing worker without waiting or retrying. The native command returned `agent_prompted`, `submission: submitted`. The worker's pane showed the exact delivered prompt and its reply confirming `coworker-worker`; it ran no commands and edited no files. Its loaded workflow was the installed `ace-coworker` worker document, with protected `ace-wake` and `herdr-agent-state.ts` extensions.

This proves delegated native launch and guarded delivery between real isolated Pi sessions. It does not prove spontaneous task decomposition, task/assignment integration, eyes wakeups, bootstrap completion, independent review or merges.

## Verification and review

- Complete auth files before handshake addition: 299 tests, 1228 assertions, zero failures/errors, 9 skipped (`11402a49-cc6a-44ab-afbd-c1b5708b3901`).
- Handshake/control/issuer regression: 25 tests, 121 assertions, zero failures/errors (`4ee7ac45-335e-4e7b-914d-6ede8258bef8`).
- Native isolated tests: 15 passed (`40975f91-8e71-40c0-b521-8999212a99e8`); generated schema test passed.
- Native package selection/builder tests: 22 tests, 101 assertions, zero failures/errors (`d7b15b76-0660-48b2-bc99-6b9492e3a8df`).
- Independent reviewer found the exact-terminal process-info mismatch; corrected and verified. Scoped authorization/origin-binding and subsequent handshake/current-pane reviews reported no remaining actionable blocker.

## Remaining integration work

1. Keep readiness evaluation in ace-overseer; use a bounded installed owner subprocess, not an undeclared reverse gem dependency. Root issuer authenticates target unit/invocation, opens only the target session file under its UID, and passes a read-only descriptor. Preserve original branch, process, foreground, freshness and before/after checks. Return no transcript content.
2. Wire standard project/lab start and coworker dispatch to this launch path. Resolve lab coordinator root separately from project topology; preserve worktree execution scope without changing the configured runtime or mount authority.
3. Finish role/configuration mapping, real task/assignment/report/eyes loop and local Forgejo role leases. Provide pinned rg/fd instead of Pi downloading session-local binaries.
4. Register and execute TS-MONO-003/004 only through those real product paths, then run both scenarios twice with a clean reset and identical final manifest.

## Readiness prerequisite — private descriptor reader

Subsequent source work adds root-only `SessionPeer.authenticate_process` using the same full systemd policy as socket authentication, exact native process birth comparison and MainPID equality. Review found no actionable flaw; 41 peer/launch-peer/issuer tests passed (135 assertions).

`SessionEvidenceFile` is a fixed non-executing fork which drops groups/capabilities/UID/GID, re-arms Linux parent-death protection after credential changes, closes unrelated application descriptors without flushing inherited buffers, opens the private session path through no-follow directory descriptors and transfers one read-only regular bounded file descriptor. Its caller must authenticate and recheck target lifetime before/after; the reader itself does not replace those checks. Privilege restriction is shared with SessionRunner. EyesSessionEvidence now accepts an injected opener and retains its existing evidence validation, with no fallback after injected opener failure.

The new reader's four tests ran through installed ace-test on the diagnostic Linux VM against a separate development test package: **4 tests, 14 assertions, zero failures/errors, no skips**, report `86e2e328-20db-405b-9e7a-4c1cb6783c42`. These include actual root-to-session UID drop and refusal of a root-owned private file, read-only FD transfer, and symlink/FIFO refusal. The test checkout is not the agents' operational runtime. Early failed probes exposed descriptor cleanup against RubyVM-reserved FDs and inherited-output buffer flushing; both were corrected before the passing run. Independent review reported no blocking issue in the reader slice.

The bounded installed ace-overseer evaluator subprocess and authenticated readiness endpoint are **not yet connected**. The deployed operational runtime remains candidate 83; these reader changes have not been substituted into its installed gems.

### Candidate 84: real readiness refusal and fixes

Candidate `b459c08b28fac370d4a029acc4a3c3c6fe8da7b1` launched `overseer84` through native Herdr into `term_65f6b91ca5d4e5`. The installed Pi session loaded candidate84 instructions and protected extensions. A single explicit diagnostic readiness query from that session exposed two defects: the standalone client referenced `Refusal` defined only by Service, and the evidence reader requested directory read permission on the actual root-owned 0711 runtime directory. Neither is an acceptance pass.

`Refusal` now belongs to the shared auth error module, verified in a fresh Ruby process without Service. Directory anchoring now uses Linux `O_PATH|O_DIRECTORY|O_NOFOLLOW`, retaining the final read-only/no-follow file open and target-UID permissions. The Linux regression fixture now matches the root-owned 0711 boundary. A separate development test package on the diagnostic VM passed **4 tests / 15 assertions, no skips**, report `39acb389-b44d-4424-9c56-628a0f5d838f`. Local affected tests passed 10/20 with the three Linux-only cases skipped. The operational candidate84 installation was not modified in place; a rebuilt candidate is required for the live retest.
