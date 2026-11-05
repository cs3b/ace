# Checkout recovery and acceptance restart — 2026-11-05

The previous worktree and its ignored local state were absent on resumption.
The Git branch survived at bc3c8e796d6f5a6edfea2ac5b8160fbaaa899f5e and was restored using ace-git-worktree.
The previous test processes no longer existed. Both previously registered UTM machines were stopped.
The old working VM B3F20591-D7E6-4C53-BB80-A8A977BC637F was inspected through QEMU guest execution: /opt/ace, /lab and /var/lib/ace-e2e were absent. It was stopped again and retained. No acceptance is inferred from the prior run.

The missing local state also included the operator SSH key and native artifact cache. A new base was built through the existing helper; old machines were not adopted or deleted.
New base: 2C545973-0B40-4AFF-806B-BABD53BCA155, ace-e2e-base-698aa19d002d42d3.
Base ready fingerprint: d6c6cf1fee24cc9077b03439bff56d3054d045b4cb673be8352746b2b7583f12.

Artifact reconstruction exposed a moving rustup URL. Official archived rustup 1.29.2 has the original pinned SHA a9c168dbea81a84671c6b7a5c1795cb0eb699020110d107ddfca427bd797e697. Commit aa7f835ca pins that archive URL; no expected bytes or checksum were relaxed. All 60 artifact inputs verified. The artifact test passed 4 tests / 19 assertions (report d50e06fa-b604-4891-807d-2c58a7d51af0).

TS-MONO-003 was started through bin/ace-test-e2e with runner and independent verifier, run 8y4mxlz-monorepo-e2e-ts003. It created working VM 83B56952-B5F1-474F-A73D-73DF473F3A8C, ace-e2e-work-bbf7c36fb8c1699d. At this checkpoint provisioning had completed apt dependencies and was compiling Ruby. This is a live setup checkpoint, not an acceptance result. TS004 and two complete clean pairs remain unproven.

## Native build failure and verified correction

TS003 setup failed after successfully compiling native Herdr: its SHA did not match the previously pinned diagnostic artifact. The produced binary embedded absolute cargo registry paths below the output directory. Owner fix f1af8006c supplies CARGO_ENCODED_RUSTFLAGS with a staging-prefix remap. Full ace-herdr fast suite passed 632 tests / 2618 assertions (11203302-1638-4761-9fc0-38d9b5939f95). Independent read-only review found no confirmed defect and required real different-directory builds because host build scripts and Zig are separate paths.

Installed diagnostic gem ace-herdr 0.10.1.pre.utm98 was built from f1af8006c62b3e2829c9fed1be15fc48a5570d94. Two owner-CLI builds in /home/lab-operator/repro98-a and /home/lab-operator/repro98-longer-second-location both produced 28348632-byte artifact SHA f349835e623887463ecc17d8edf825bc4ed1d5c44716fa6929305c7b1610ef6a and provenance SHA 6954b1b1f60dce1bd63311ab7ba209f10002910f4ae5e4b191d7509735e60ae4. The first artifact no longer contained /home/lab-operator strings. Native source selection is unchanged. Verified bytes were copied to the host artifact cache; the manifest now pins the corrected builder gem and artifact. This proves the tested path-independence case, not full autonomous acceptance. A new clean E2E run is required.

## First real Pi startup and premature readiness

After fixes 19bdcf25a (UTM malformed result polling), df21cd655 (fixture config parent) and 343263ad5 (runner file-artifact parents), run 8y4o52e-monorepo-e2e-ts003 completed setup. Working VM C3C8E647-F3A0-4DF7-827D-00E69E238B12, fixture 660a1ba936f24622, started isolated Lab Overseer in terminal term_65f89c908ba902 / w1:p2. The receipt records prompt_delivered and ready:false. This is not a successful first turn.

Read-only terminal capture showed “Startup is still in progress”, both first-turn instructions and bootstrap goal left in the editor, and zero model context use. Installed Pi renders before ensureTool(fd/rg), then installs the submit handler before rebindCurrentSession emits session_start. Native Herdr promoted screen Idle to Active during the earlier startup window. Manual Enter was not sent; the failed run was not repaired by the test operator.

Native owner correction requires effective protected herdr:pi/pi Idle authority with a session reference for isolated Pi Pending/Blocked promotion. Ordinary non-isolated readiness is unchanged. Fresh isolated creation/restore uses a fresh TerminalState; existing hook routing owns stale session and process-exit suppression. Readiness only proves input availability, not first-turn completion or eyes.

Regression failed before correction (nextest a608ee7f-a13a-422b-858b-f39c91f763d5). Corrected test passed (b4c14c84-23ba-44d6-a2e0-1c2659426e45). All 105 terminal-state tests passed (fde40ab7-0b3c-41c3-80bd-dcccc2f442fa), including a non-vacuous accepted Idle hook followed by process exit and delayed old hook. Independent read-only review found no blocker.

Full native checks exposed earlier integration omissions: generated API schema lacked optional cwd, and Unix/test platform dispatch plus guarded-prompt helpers failed clippy. The schema was regenerated with only that six-line field addition; behavior-preserving lint corrections were independently reviewed. Full checks are being rerun; no native candidate or acceptance is claimed at this checkpoint.

Native correction committed as 554ba05e537fa908c503745a35dfee176ad1c820. Packaged mbox replay reproduced the exact commit from the pinned baseline; patch SHA 932a07e37971ec2cb3fba87a8d630c68145db430173d6e5fc21eea34b2a639a8. Native clippy passed and nextest cfd90004-908e-4991-be23-8f0537943c69 passed 3736 tests (12 configured skips). Maintenance 149, workflow 5, hot-path architecture 6, integration assets 22+9+28, docs 7 tests passed. Full just check stopped at Windows cross-check because this host lacks the Windows SDK; no Windows qualification is claimed. The selected artifact targets Linux ARM64 and still requires a built-artifact live retest.

ACE native-source/builder tests passed 22 tests / 104 assertions (2efeccba-be23-4cd5-8357-255850dcbf57). Earlier broad wrapper suite attempts had short process-start timeout failures; isolated bounded-observation/executor tests subsequently passed 55 tests / 99 assertions (469f7e18-7304-4f20-956a-7d22adbe29e5). Broad suite rerun remains required; do not infer a green package suite from the targeted result.

Subsequent full ace-herdr fast suite passed 632 tests / 2618 assertions (11f1b046-7a65-4901-870e-206d8fdbcf61). ACE integration commit 22912128490a48ea0cbcf2c337a941481a3683f8 produced diagnostic ace-herdr 0.10.1.pre.utm99, gem SHA c7075e4c84bed726b179a552d25176afd31a1d120fa052bfe22a943efe77b70d. Installed in the diagnostic VM under /home/lab-operator/diagnostic99-gems with existing installed dependencies, without changing operational /opt/ace. The installed owner CLI is building /home/lab-operator/herdr-build99 from /home/lab-operator/herdr-source99. The acceptance manifest still pins utm98 until new artifact/provenance verification; no clean acceptance has passed.

## Candidate99 artifact and clean acceptance restart

Installed native owner build completed successfully on ARM64. Artifact size 28286144, SHA 6943769804c704fd21f9a942e50f8f1772f70b8aaef839fd8f614044f01ce253; provenance SHA c7d7a20957556fcb3aca7224ac0f748615c99d1bc515379381b496e368abb5f0; selection SHA 108bf67cec09a9458b338ecc24fbe64e5ea7eaef9df01e6900e667b9d34e5bc5. Host owner verification accepted copied artifacts against the packaged selection. Manifest now pins utm99 and these exact bytes. All 60 inputs verified; cache/artifact tests passed 10 tests / 32 assertions (df454121-6180-4671-bcdc-de32e60f1e87).

Run 8y4o52e was explicitly aborted after the reproduced startup defect, not counted as a completed verifier failure or acceptance. Only its confirmed host process groups (runner, Pi runner, owned sleep command) were terminated; their absence was verified. The VM reset helper was then invoked to preserve/export the owned failed VM before recreating the work clone. No manual prompt repair or successful task/report fabrication occurred.
