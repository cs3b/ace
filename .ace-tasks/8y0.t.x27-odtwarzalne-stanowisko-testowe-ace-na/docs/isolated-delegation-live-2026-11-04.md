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

### Immutable target gap in native agent queries

Candidate85 (`ace-lab 0.14.2.pre.utm85`, SHA256 `334ba661e529ad69748ae1ab7b433382d01aec5709c18563af7079a8fdc5c46c`) successfully traversed the private evidence boundary in the root diagnostic; evaluation reached the final native identity reread. Native82 returned `agent_not_found` for exact terminal `term_65f6b9e5181a46` even though `agent get overseer85` succeeded. The agent-target resolver previously supported names and public pane IDs only. The native owner now resolves `term_*` exclusively through its immutable terminal lookup and requires an agent terminal, with no name fallback. Linux isolated tests passed **16/16**, run `241e4f91-8fa9-4383-9df8-31cc8b414271`; native-source package tests passed 13/42 after updating the pinned patch digest. Patch replay reproduces native commit `9bc62225f7c2049d34f7b7287901555852b80cf4` exactly. The replacement native artifact and live retest remain required.

### Candidate86 live negative readiness succeeded

Root-installed native86 SHA256 `acb9b64d93006118bb1daca42634f80897ac5f73030b6c1a21ee18bfccabba92`, provenance SHA256 `e0816a8efe5bfd807c2b5db4579b1e59398310a325c1cf43b53a4241a47b2410`, selection SHA256 `363818e36ad72b21b6b08a2cffe2e870443ca12f7b5cfc68c4845a95e92e82ef`. The root gem home is `/opt/ace/diagnostic/utm86/gems`; ace-herdr86 artifact SHA256 `aaa69ae7e12d4cf65b8342e03c6f8008d4fd4e04e4ef9b98f7beca232f7819cf`. IssuerInstaller installed the singleton units with normal readiness checks. Native unit `ace-e2e-herdr86.service` invocation `787e014380894ca2bf2843463310fe92` owns the new protected endpoint `/run/lab/herdr86/herdr.sock`.

Native launched overseer86 into `term_65f6bbcb5c43a2` / `w1:p2`. An actual Pi tool invocation of the installed IssuerClient returned `{"ready":false,"terminal_id":"term_65f6bbcb5c43a2","invocation_id":"a603c648bbd24fc183c358028d23d2b2","root":"/lab/ace","role":"project-overseer","type":"agent_readiness"}`. This is the expected negative result with eyes deliberately off. It proves the authenticated live transport and private descriptor/evaluator path, not a completed first turn or bootstrap acceptance. Both corrective commits received independent review without actionable findings. Additional native terminal-target tests passed 4/4, run `f3370369-3184-407c-811a-ce12d326ebbc`.

### Candidate87 coordinator mount diagnosis

Candidate87 installed ace-lab `0.14.2.pre.utm87` (SHA256 `72e58172e3e90f60e293958f8188fd45e1355e2e96ba9546aca41b5282c36381`) and ace-herdr `0.10.1.pre.utm87` (`dd505a1ca47f292a2f788a2998d2dd4a93d2342eef197c39b855fcc4fb1114d1`) from `a57c3ae79e010b42f191bfe838b379ccac48fe01`. Native87 SHA256 is `7128db42600b7cc110214719389b7877aced28210abb1651c0af69a77413640e`; provenance `b62a6faffb85848a43979a5bce64528c138beff46f4db0fc752160d070ac62b0`; selection `fcc961e5eba29f6d02e7a4e7d6fb6a688bedab3486bc66b6ff517c6f404c0056`. Native service invocation `6dacbbd6dec24cdc87fdb2421d4267bc` owns `/run/lab/herdr87/herdr.sock`. Protected coordinator `lab:/lab` and host/session grants are configured.

The first native lab-overseer launch failed at mount preparation with containment and cleanup confirmed. A bounded root diagnostic isolated `rmdir project-source: EBUSY`; actual namespace mountinfo showed the new `/lab` tmpfs propagated onto the staging source via shared mounts. Marking the staging bind private before covering `/lab` prevented this propagation; the subsequent actual namespace probe completed and showed the expected ext4 idmapped `/lab` mount. The product now performs this step for every source bind. A rebuilt gem and full native launch retest remain required; this diagnostic is not acceptance. The first diagnostic script had a local cleanup-variable scoping error; its already-exited unit was explicitly stopped, and later probes used confirmed cleanup. No runtime gem was edited in place.

Reference for the established propagation semantics: https://kernel.org/doc/html/v6.12/filesystems/sharedsubtree.html . Targeted regression 5/26 passed, report `8b5e9fa6-009c-424e-add8-a552ee4f862d`.

### Candidate88 live coordinator launch and readiness query

Built ace-lab `0.14.2.pre.utm88` from `84b17c2c91e206785a03f440cbbdb1c9d8dbf553`, SHA256 `9a736509b1e47b4e39cb2a03655f745e80124319d79f7de637f33cdeaaf856fe`. Installed into the separate root-owned `/opt/ace/diagnostic/utm88/gems` closure and installed the singleton units through normal IssuerInstaller checks. Native remains verified native87, endpoint `/run/lab/herdr87/herdr.sock`.

`herdr agent start-isolated lab-overseer88 --workspace w1 --project lab --role lab-overseer` succeeded: terminal `term_65f6bfa1dffeb3`, pane `w1:p2`, cwd `/lab`. Subsequent native observation reported actual Pi `interactive_ready: true`. Its single operator-requested component readiness query through installed IssuerClient returned `ready: false`, invocation `fce7223b384e43a39776f42415fe3102`, root `/lab`, role `lab-overseer`. Eyes was intentionally not armed. This confirms the full native coordinator mount/handoff and authenticated negative-readiness path, not autonomous bootstrap, positive eyes readiness or E2E acceptance. The staging-propagation correction received independent review without actionable findings. Task remains in progress.


## Standard start on candidate89 / overseer90

Source integration `fc108d8470b232fd5d314cf3dd2282393a1a0870`; standing-guide
correction `88048afca1cb762623bc06a1c4092d0c98045fa0`. Installed root runtime
`/opt/ace/diagnostic/utm89/gems` contains ace-lab 0.14.2.pre.utm89
(SHA256 `7274151de8bbeb43b5a532f5d7a8af86c3678373085a95c90f6978ae3ee76f4c`),
ace-herdr 0.10.1.pre.utm89
(`93da249d2bdbb37032a6428dcfe8a40b674b2702c8af202219645360572b59e3`),
ace-overseer 0.28.2.pre.utm90
(`425ddd7c1c97f1df092a4d55ad8eb215870809c37eccb5f676f9fc36c70207ed`).
This is a mixed diagnostic candidate, not a final acceptance manifest.
Native source `c17ef7290086f338dd33370ebc9304149c3fa9f4`, artifact
`1c4c8f0e197a68b00da08a63c32e938c8a90a6169a92af4c68d382ad5573b709`,
provenance `a39e20d0069d8907224af6bab3b55ed97898d57454c2b5b154f992e82400bf0a`,
selection `38179efff7d26782a3d8941f712fb7c64eab09d2b4df1f471e0b1058b456659c`.
Native service ace-e2e-herdr89 invocation `7427b22ce6874bc2bf6231b88cf97ca5`.

The actual public installed `ace-overseer start --scope lab --format json`,
run as mo from /lab, created workspace w1 and isolated coordinator
`term_65f6c6843de5f2` (w1:p2), unit
ace-auth-session-lab-overseer-3f48f3c7db2ab7f1.service, invocation
`a5d7aba9123f4611b3c64f4096088f6f`. It submitted the first prompt exactly once
and returned started/ready:false. Real Pi entered working state and called
ace_eyes. Repeating the public command reused the same terminal, returned
ready:false via the host authenticated evaluator, and submitted no new prompt.

This attempt FAILED full readiness and role acceptance. Eyes was enabled but
project_sessions was degraded because its old observer called forbidden
`herdr tab list`; HITL was degraded because the lab fixture lacked recipient
overseer. The coordinator then investigated host directories/transport instead
of ending the blocked turn. No positive eyes readiness is claimed. The session
was exported locally without auth.json and its exact unit stopped; no retry was
started. Evidence: `.ace-local/lab-vm/evidence/coordinator89-session.tar.gz`.

Product fix now uses authorized native project/role inventory and canonical
cwd in ProjectSessions; no tab fallback. Fixture supplies local HITL aliases.
The canonical first-turn contract explicitly ends the turn on degraded source
or unavailable blocker owner, without host/implementation diagnostics. These
corrections still require a new installed probe; instruction changes alone do
not prove role compliance.

Before these corrections, full package checks passed: overseer 533 tests,
2442 assertions, one platform skip (`b478396e-2d9e-4bfe-a07a-4786c803f568`);
lab 992 tests, 4631 assertions, 16 platform skips
(`c09176a7-2c2a-4002-b1ad-54a53d35fe0e`). Both had zero failures/errors.


### Candidate91 upgrade stopped by a verified lifecycle defect

Corrections committed at `ea7bbf5c3790ce0833bc9b66d923703e4edc13f3`.
Built and staged (not activated) ace-lab 0.14.2.pre.utm91 SHA256
`1996c31cc523d99caa5e38d4ac9f8925d63ecf3b434a625cd4c8a3b77bc0a886` and
ace-overseer 0.28.2.pre.utm91 SHA256
`d9f9c6588557dd8e96c3d920942ea4596ea9af5b1c101b3ee10733ef3e94166a`
in `/opt/ace/diagnostic/utm91/gems` (native/herdr89 reused).

Upgrade reached IssuerInstaller and refused because ace-lab-auth.service was
failed. Its journal identifies session_launch_failed at stage stop,
contained:false/cleaned:false after the operator stopped the exact coordinator
unit. Issuer ExecStopPost subsequently reported leases:[], but the failed
service status is deliberately not bypassed. SessionLauncher.stop currently
requires inspect_units with the original InvocationID even when an external
StopUnit has already garbage-collected the transient unit; inspect_units itself
requires LoadState=loaded. The original MainPID pidfd alone is insufficient
whole-cgroup proof, so do not simply treat that exception as success.

Current VM state: native89 runs; no coordinator from this attempt remains.
Issuer/socket/recovery unit files were moved by the upgrade to
`/opt/ace/diagnostic/utm91/previous-units` before installer refusal. Systemd shows
issuer LoadState=not-found/ActiveState=failed, socket and recovery not-found/
inactive. The protected manifest still selects utm89. Do not rerun the whole
upgrade script: it assumes the old unit files still exist. Correct the lifecycle
proof, recover the outstanding failed deployment through the normal installer,
then switch the protected manifest and run the new candidate. The local HITL
fixture file is committed and uploaded as `/home/lab-operator/lab-hitl-config.yml`
(SHA256 `0cc13bc40042bfa6acc1ac73ea8759891b364b0844b93341f209b759fa18175e`),
but not installed at /lab yet. This is not an external access blocker; product
work can continue. No clean E2E run has begun.
