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

## Live candidate99 delegation and discovered task allocator race

Run 8y4p4qd-monorepo-e2e-ts003 prepared fresh VM 5699474C-6433-4BEE-BC0C-041329993BCE, fixture b8f946af922f93a4, source 3e1ed1f7715a795d3401e4ab3f31d8fa42339a2f. Installed readiness correction worked: terminal term_65f8a589f0ebf2 / w1:p2 accepted input and executed the first turn. Eyes became active. Lab Overseer created private manager 8y4.t.pfi and project task 8y4.t.phj, commissioned worker assignment 8y4pk7 in separate pane w1:p3 / /lab/ace/.ace-wt/ace-t.phj, and retained verifier assignment 8y4pk71 for later handoff. The lab Overseer ended its turn with eyes pending:0 while the worker continued. These are component observations, not completed bootstrap or acceptance.

The live run also reproduced duplicate child ID 8y4.t.pfi.0 from parallel ace-task create calls. The Overseer repaired its own private metadata before delegation; this run is therefore diagnostic and cannot replace a clean acceptance of the corrected product. Owner source has scan-then-write allocation without exclusion. A four-process same-title regression reproduced 4 expected distinct IDs versus 1 actual (b0e4d145-9664-4f96-87fd-804b8a3611de).

The proposed owner fix locks the parent directory inode across scan, creation/move and spec publication/load. Creator, demotion and orchestrator conversion use the same guard; the latter refuses existing children. No task-store lock file or new state registry is added. Aliases share the inode; a waiting writer checks that the path still identifies that inode. CLI create already has authoritative actual-path ignore validation and rollback. Update's older preview-only ignore race remains a separate pre-existing concern, not a newly introduced allocation behavior.

Regression set passed 27 tests / 128 assertions (7e0bd070-eead-4eca-923c-d7c7915c8bd7), including creator-versus-demoter contention, aliases, process death and incomplete slot preservation. Full ace-task fast suite passed 544 tests / 1741 assertions, with two skips (ea44308b-6c25-4d78-8d0d-4525e0a307b0); feature suite passed 5 / 56 (d7670de5-e808-486e-92b2-c40b0e504edf). Independent source review found no introduced blocker. Linux installed-artifact validation and a new clean manifest run remain required.


## Installed task allocator and role-scoped readiness fixes

Task allocator commit bc4191520cb4770e2e7e75de47690d0b1f135e8d was built as ace-task 0.41.1.pre.utm100, SHA 836b876287d38907e047cf489748eff2f5dfecaad2c86ce226a262d0e83730c9. In a separate diagnostic GEM_HOME on the ARM64 guest, eight concurrent public CLI creates under parent 8y4.t.pul produced distinct children .0 through .7. The operational runtime was not changed. The manifest still needs to include this candidate before clean acceptance.

The live worker encountered intentionally inaccessible private Overseer metadata. EventObservation now degrades overseer_tasks when manager enumeration fails, retains reports pending, and preserves other source statuses. Enumeration remains all-scopes to preserve archived-manager settlement. Regression failed before the change (f190c173-c9e4-4e38-8687-1bb932cc1baa); full Overseer fast suite passed 543 tests / 2490 assertions, one skip (fd5ce7ef-4e51-47b4-9925-708b0bb5ce2b). Independent review found no blocker. Bootstrap guidance now confines worker/verifier acceptance to their accessible evidence; authorized confirm-start still proves full observation.

The worker subsequently reported a runtime NameError during denied systemd readiness inspection. Fresh-process regressions reproduced missing typed-error dependencies in protected_socket, protected_linux and systemd_scope_manager (80b708e0-4038-4e0b-a147-3d3658645654). Each component now explicitly loads its error definitions. Full runtime fast suite passed 309 tests / 1245 assertions (d2ce93f7-a7d4-40ee-8d50-5a5638111683). Isolation and permissions are unchanged. The current VM remains diagnostic; no full acceptance is claimed.


Runtime feature tests also passed 23 tests / 143 assertions (6720c73a-4458-4323-850d-43f77beccd4a); independent review found no actionable findings. Fix commit be2e2ae1ab9be0c4c14820df1e14c25052966911 produced ace-runtime 0.4.2.pre.utm100 (SHA 16a6a836307bdcc4933732456af790ef90f80bb424074bc90e52a997dadaf42c) and ace-overseer 0.28.2.pre.utm100 (SHA 66fd81046bb5fdb3707029adb9ca7865e330a5adbaa663f610334573611787c8). Together with the verified task candidate, they are staged in private candidate100-release-manifest.json, SHA cbd44cc11911f577bf68875c02bab05c38464c68052df22a27fdd6bf50dc08e3. The active manifest remains unchanged while runner 8y4p4qd is live.

Current diagnostic coordinator consumed real error report 8y4q2s, kept preparation open, held verifier assignment 8y4pk71 and project start, and created local HITL 8y4q4v. It then ended its turn with eyes observing. This confirms observed error handling, not successful bootstrap or five-minute quiet acceptance. No answer or host-permission workaround was injected.


Pre-reset dependent validation at be2e2ae1a source: Overseer feature suite passed 10 tests / 67 assertions (ee8f7734-944a-41b7-8ee6-89260208e25b). Full ace-lab fast suite passed 1005 tests / 4692 assertions with 16 skips (73474a42-2158-49cf-8e11-55d84ddc1e2d). These are component/dependent checks; they do not replace the required two clean autonomous acceptance pairs.


Run 8y4p4qd was explicitly aborted after observed blocked bootstrap: real error report 8y4q2s and pending HITL 8y4q4v prevented verifier/project start. This is not a completed runner verdict, timeout-derived failure or acceptance. Confirmed owned host process groups 52538 and 55307 were terminated, and runner handle returned exit 143. No live VM repair or HITL answer was injected. The next fresh setup must export the old VM before reset. Candidate100 now replaces the manifest for that next clean run.


## Candidate100 reset and discovered prerelease bootstrap gap

Run 8y4qke3-monorepo-e2e-ts003 reset through the standard helper. Prior VM 5699474C-6433-4BEE-BC0C-041329993BCE was exported, then fresh VM 40F070E3-3558-42D7-ABB8-3EBD17A7742B booted with SSH and started runtime compilation. Host runner remains active; no bootstrap goal has yet been delivered.

Source inspection found that adding the pinned ace-task prerelease exposes the old hand-maintained bootstrap list: RubyGems local dependency discovery does not select an otherwise satisfying transitive prerelease. A fresh-process real-gem regression reproduced the missing dependency (eeacd60d-8bcc-4e05-8db4-302048e54f5b); adding --prerelease did not resolve it and was not retained. The fixture now validates the complete graph and uses RubyGems DependencyList.tsort. Bootstrap installs only the ace-lab/index-tool closure from exact archives with Gem::Installer and ordinary dependency checks; every remaining pin is installed by ace-lab in dependency order. No network resolver or custom topological sorter was added. Existing ace-lab install/verify and exact final gemset verification remain, with explicit activation checks expanded to every pin. Manual prerelease special cases were removed.

Independent review caught and corrected an acceptance weakness in the first implementation, which preinstalled every gem before ace-lab. The final regression proves an unrelated operational gem remains absent after bootstrap. The real-gem regression and cycle rejection pass; full fixture fast suite passed 101 tests / 357 assertions (e62251e6-79e8-4675-a460-9c4083044350), before the additional dependency-plan ordering regression. Current VM contains the original installer; changed fixture inputs require a new clean reset, not an in-place repair or acceptance claim.


Final fixture suite passed 102 tests / 359 assertions (e01ec546-e839-48cd-a8af-7b1d4df3e78e). Independent re-review confirmed the ownership finding resolved and found no new blocker. Live installation remains unproven. Run 8y4qke3 is being stopped diagnostically because its copied bootstrap script has the reproduced prerelease resolution defect; it has not delivered a Lab Overseer goal and will not count as acceptance. Preserve its owned VM on the next helper reset.


## Clean run after bootstrap dependency-order correction

Run 8y4qke3 was explicitly stopped: only confirmed owned host group 63711 was terminated, and its runner handle returned 143. This was a diagnostic abort based on the reproduced old-bootstrap defect, not a completed scenario verdict. New run 8y4r2j1-monorepo-e2e-ts003 starts from source 6642eb0eb3008f93d363952108e18398e1e4383a with the same candidate100 gem manifest. The helper exported VM 40F070E3-3558-42D7-ABB8-3EBD17A7742B and created A36E4051-BEF2-4AA0-A839-6C7C78A1F608. SSH and live compiler processes confirm the new guest is progressing through runtime build.

Read-only inspection of the live QEMULauncher arguments confirmed the exact owned UUID plus -accel hvf, -smp cpus=4,sockets=1,cores=4,threads=1 and -m 8192. This proves those running fixture settings, not a completed runtime installation or autonomous acceptance. No goal has yet been delivered in this run.


## Candidate100 live autonomous bootstrap observations

Run `8y4r2j1-monorepo-e2e-ts003`, fixture `a6cb4098ebf92486`, completed fresh runtime and fixture setup. All 55 exact gem specifications and runtime-ready fingerprint `a693011b4f8a4fff47122ff09093fefe66d15e39554e4fea51c536ed366a9e8d` were verified. Manifest remains `cbd44cc11911f577bf68875c02bab05c38464c68052df22a27fdd6bf50dc08e3`. The single goal was delivered to terminal `term_65f8c6f060d642` (`w1:p2`); a real first turn and `eyes observing` were observed. This is not project readiness or full acceptance.

The coordinator created private manager `8y4.t.t8e` and direct children `.0`, `.1`, `.2`, plus executable project task `8y4.t.t92`. Initial coworker preparation created its worktree but returned `Required preparation phase failed`, categorized as `mismatched_worktree` with an empty preserved-path field (HITL `8y4ta8`). A subsequent coordinator retry reused the worktree and returned worker assignment `8y4tb3` and verifier assignment `8y4tb31`. Source inspection shows the worktree owner runs required mise trust by default; the reuse decision only checks task association. The exact failed phase still needs direct confirmation; reuse must not be treated as proof that a previously failed required preparation passed. No operator repair or HITL answer was injected.

A separate observed defect: isolated `ace-herdr status` invokes native `tab.list`, absent from the issuer's allowed method schemas, and returns the generic issuer error. Read-only root diagnostics authenticated the actual coordinator main process through SessionPeer, then successfully performed SessionNativeTransport workspace.list and SessionWorkspaces projection. Thus those probes do not support a blanket claim that authentication or native transport is broken. The public status/list contract needs correction without exposing other sessions.

The coordinator recorded the real assignment IDs and issued public `ace-herdr dispatch` for worker `8y4tb3`; its result was not yet observed at this checkpoint. Runner handle remains live. No full scenario or clean pair has passed.


Worker dispatch succeeded: assignment `8y4tb3`, terminal `term_65f8c911592b83`, normalized agent `worker-8y4tb3-97e729b5`, pane `w1:p3`, isolated role worker. Its first turn confirmed installed CLI paths under `/opt/ace/runtime/gems/bin`. It reproduced an ace-task lookup failure when canonical task discovery entered the intentionally inaccessible private `_overseer` directory. Source fix adds opt-in accessible descendant discovery at the shared DirectoryScanner owner and uses it only for task-reference resolution; strict full scans are unchanged. Actual chmod000 task regression failed before forwarding the option (5956bc39-2c48-4c36-98ff-b3e9ab182dc2), then passed (424e8c98-c528-45c4-a3af-7b95a759ded8). Support-items fast: 346/650 (5b38e215-d05e-41a4-9954-af00a306f3e8); task fast: 545/1744, two skips (2c520828-f4e8-411a-a9f4-dbd727bf4c61); task feat: 5/56 (d08c6526-3cc1-4681-b1bd-c90a60e0f741). Independent review requested. This patch is not installed in the running candidate; no hot repair or acceptance credit.

Independent review of the accessible-task lookup patch found no actionable blocker: default/full inventories remain strict, requested-root access errors propagate, and public resolution does not expose denied private content. Reviewer inspected source and real-permission regression read-only. Rebuilt-candidate acceptance remains outstanding.


The live lab coordinator recorded dispatch identities, reconciled owner state, and ended its turn with `eyes observing pending:0` while the worker continued. This proves dispatch/turn yielding for this observation, not the five-minute quiescence requirement or worker completion.

Isolated Herdr layout fix uses existing issuer-filtered agent.list in the Ruby control surface instead of forbidden raw host pane/tab lists. Agent workspace IDs supplement configured spaces for the coordinator's real lab workspace; existing workspace metadata stays intact. No issuer permission or native method was added. Red adapter regressions: 014b21d0-5f7d-46b0-9547-87675064fa99. Full fast suite passed634/2628 (5408f859-373f-4209-82c8-510625988cb6); independent review found no blocker and requested three focused cases. Those were added: shared tab, existing workspace preservation, malformed member/error envelope; organism suite passed332/1416 (e071fd04-7c2d-4952-8794-b19b091f049b). No separate feat tests exist in ace-herdr (runner reported no files); this is not additional feature coverage. Running VM remains on candidate100.


## Delegated checkout versus project setup

Read-only guest check confirmed mise absent (`command -v` exit127); tracked project worktree config contains an after-create mise hook and defaults require mise trust. Coworker preparation was therefore running project setup as coordinator before dispatch, then reporting the required-phase failure as an occupied-worktree conflict. Fix uses the worktree owner's internal defer_setup option before hooks/trust/bootstrap. Coworker passes it for fresh creation, retry and stale surviving-branch reattachment, and reports project_setup:delegated on creation/reuse/dry-run. Worker instructions explicitly own the required project setup and distinguish bootstrap from after-create hooks. Normal worktree creation retains hook execution. No new state store or installed-runtime fallback was introduced.

Real CLI marker regression failed before fix (e90f40f1-6003-4f4d-b89a-abe99ccf877c). Coworker fast passed408/1916 (9232d1a5-6b4a-4afe-9147-44dd7d7512f7). Worktree fast passed681/2148,16skips (a0ca13d9-3c05-4d8f-8a71-c1f7069d71ab). Independent review found no live-path blocker, identified branch reattachment and owner dry-run parity; both are covered. Final owner organism tests passed62/235 (9ab285a3-1540-4cbd-8694-721e30c1fe47). Removed conflicting bootstrap-worker guidance that required full private-tree observation; the authorized coordinator owns that check. Generic nondelegated worktree reuse was not redesigned or claimed as runtime readiness evidence.

Live candidate100 worker8y4tb3 ended its turn and reported via event8y4tni. The lab coordinator subsequently invoked public dispatch of independent verifier8y4tb31, without operator prompting. Verifier outcome and project start remain unconfirmed. These fixes are not hot-installed into the ongoing run.


## Next candidate staging, current run unchanged

Verifier assignment8y4tb31 is observed working in separate pane w1:p4; lab coordinator and worker ended their turns. Runner80205 remains live. No verifier verdict, project start or full scenario acceptance yet.

Source007e4ba026e58020d93527fd811ece74600984a3 aligns bootstrap-verifier scope with the reviewed worker contract; independent review found no weakened acceptance. Dependent Overseer fast suite passed543/2490,1skip (d8c0b2e3-3295-4743-90a4-01d0f5e7d96f).

Staged immutable gem artifacts (not installed, current manifest unchanged):
- ace-task0.41.1.pre.utm101, source783edcc5ee70f24af58a9b1d9a01c18950b5e068, SHA256929559b838ba9082786b13092da2ff8d6288263656ca8032923b7b4ef8d54011.
- ace-herdr0.10.1.pre.utm101, same source, SHA256bfb58afb67167ea514e098f76e8acef5768578f4628a41a34215fa943058b653.
- ace-coworker0.8.1.pre.utm102, source007e4ba026e58020d93527fd811ece74600984a3, SHA2567a26f3a566f8220968c9e84a42aa729d6bedc86b835ae7c4741b6b55b0fff385. Earlier coworkerutm101 lacks the verifier instruction correction and is not the next selection.

Next candidate still requires ace-support-items and ace-git-worktree artifacts. The builder/fetcher allowlists need these two owner packages; those scripts are runtime fingerprint inputs, so they have not been changed under the running scenario. Stage that change after this run's outcome is preserved, then update the manifest and reset.


## Independent verification and first project turn observed

Verifier report8y4tyo was accepted by lab coordinator against assignment8y4tb31 and its evidence commits841b70f/08011c1 (guest task branch IDs as observed, not source candidate IDs). Coordinator invoked ace-overseer start --reconcile itself. Project session overseer-ace, terminalterm_65f8cf22d0aa96, pane w2:p2, role project-overseer, cwd/lab/ace started and executed a real first turn. Its eyes later displayed observing/pending12. Coordinator correctly kept confirm-start open pending completed first-turn/eyes evidence and ended its own turn; no repeated prompt or operator assistance. Full bootstrap acceptance still unproven.

Project first turn exposed ambiguous instruction ordering: extensive repeated reasoning over reconcile-first versus degraded-observation/end-turn. Source StartContract and project guide now give one ordered protocol: arm/validate observation; on unavailable/degraded source record exact blocker/end without accepting reports or ack; only after healthy observation reconcile commissioned work, then dispatch/end. Lab guide distinguishes observed project failure from required-source failure. Independent review found no blocker; reviewer identified the lab-guide clarification, now applied. Atoms76/265 (2ca536b6-f661-4dcb-ac69-d06252296bf6), feat10/67 (8b8b08b3-5d33-42fd-8195-162f009fb3ac) pass. No model-behavior acceptance is claimed for the new instructions before a clean candidate run.

The new project sees bootstrap reports accepted by the lab's private manager as unmatched against its own empty private tree. Observe how it settles this ownership boundary; no duplicate dispatch or correct handling has yet been asserted.


## Bootstrap report routing diagnosis (live read-only inspection)

At 20:10–20:13 UTC, runner PID67409/session80205 remained live; no terminal scenario result. Project Overseer remained in its first turn with eyes observing/pending12, considering integration of the bootstrap evidence branch and commissioning repairs. Lab remained idle with confirm-start open. No intervention was sent to either agent.

Public `ace-hitl show 8y4tni` from /lab/ace resolves the worker-owned report in /lab/ace/.ace-wt/ace-t.t92/.ace-local/hitl. Its recipient is `utm-e2e/.ace-local/hitl/8y4tni`. Both lab fixture configuration and actual canonical project configuration use the same relative folder address for `overseer` and `captain`. Therefore the same configured owner string does not distinguish lab coordination from project coordination.

Two distinct paths must be addressed together before claiming scoped report consumption: HITL EventObservation filters by the resolved recipient address, while Overseer HitlInbox currently lists all reports in the current scope without a recipient filter. ProjectObservations forwards the lab observer owner name into each project configuration. Bootstrap delegation currently selects the target project's configured overseer recipient even though the lab owns the commission. Merely filtering HitlInbox would not fix this fixture because both coordinators resolve to the same address. Merely closing/ignoring unmatched reports would risk hiding unaccepted work.

Next change must use existing HITL address/routing ownership to distinguish the commissioning coordinator, propagate that identity through preparation and observation, and exercise lab/project isolation plus restart/duplicate handling. No new receipt registry or task-state copy is warranted. These are confirmed source/config observations, not a claimed fix or a passed acceptance.


## Diagnostic run stopped on observed role violation

Run8y4r2j1-monorepo-e2e-ts003 was deliberately terminated after the project Overseer began implementation diagnosis (`grep -rn "unprocessed_report" /opt`, observed in pane w2:p2), contrary to the required coordinator role. Before that, the lab answered project HITL8y4ubk by directing the project Overseer to disable the herdr status source itself; it escalated the underlying defects as lab HITL8y4ud8. These are agent actions, not injected operator instructions. The test cannot pass the role-boundary criterion. This is not an observation-timeout inference.

Owned runner process group67405 was sent TERM; session80205 returned exit143. UTM working UUID A36E4051-BEF2-4AA0-A839-6C7C78A1F608 was requested to shut down and subsequently confirmed `stopped` by utmctl. Its disk is retained, not reset or deleted. No complete TS003/004 or clean acceptance pair passed.

## Shared recipient filtering and scope regression

HITL EventObservation now exposes its existing strict incoming-event selection to report consumers. HitlInbox uses that owner rule; process-reports accepts configured owner and optional current/all scope. Missing/unknown owners and invalid scopes fail explicitly. This removes the consumption/observation mismatch, but distinct lab/project address configuration remains necessary; no full routing fix is claimed yet.

The same-root coordinator separation regression failed before implementation (c391304e-8c20-443e-9645-9e41848ea362). Independent review found the initial adaptation accidentally narrowed canonical checkout scope to current. A real Git linked-worktree regression then failed with expected report versus empty inbox (2cd649cb-a904-4a7c-9a5f-5bc736273786). The fix preserves nil/default scope through HITL and allows explicit scope alignment; tests cover default/all/current and invalid scope. Re-review confirmed the scope finding resolved and no new actionable finding.

HITL fast405/2088,5skips (b5b9b942-3b7f-4877-a938-06b763f58cf6); final Overseer fast548/2503,1skip (64898459-6e5d-4785-87f7-aa0c3ce65245); Overseer feat10/67 before final scope-only adjustment (db78e26b-bcab-4833-b221-53aba5e17f7c). Full testing also caught a first-turn prompt contract regression: explicit ace_eyes action start/configPath was omitted in9550ffd60; restored without weakening the test.

Overseer0.28.2.pre.utm102 artifact from9550ffd60292ab90c1e79595128817a7bcdb4dd5 was built twice with identical SHA256 e6f6f0e289d24b8e6891a0cbfcded511e3a5bf7bf36f13342598fdbf6f513053. It is now superseded by subsequent prompt/routing edits and must not be selected as the final candidate. Builder/fetcher allowlists now include the changed owner packages ace-support-items, ace-git-worktree and ace-hitl, retaining immutable source/digest checks; no manifest changed yet.


## Candidate104 routing and artifact closure

Commit11a39f357 separates fixture lab and project addresses: lab eyes uses lab-overseer at /lab/.ace-local/hitl; project config supplies that same address plus its own overseer at /lab/ace/.ace-local/hitl. Bootstrap instructions distinguish the lab report return recipient from the project eyes recipient. Independent review found no actionable defect. Static fixture routing test1/7 passed6927d53d-9b39-437a-ae0f-da2747b4a224; this is configuration evidence, not live routing acceptance. Artifact fetcher test4/19 passed32aab37f-043f-45d9-aaff-f7dc2f20dc81.

Next manifest selects taskutm101, herdrutm101, coworkerutm102, support-itemsutm103, git-worktreeutm103, hitlutm103, overseerutm104. Source SHA and actual artifact SHA256 are in the manifest; other pins remain unchanged. The three newly supported owner gems and final overseer gem were each rebuilt and matched their existing bytes. Fetcher validated60 cached artifacts with no downloads; full dependency graph validated55 pinned gems across7 install roots. Overseerutm103 is superseded byutm104, which includes the distinct-recipient bootstrap instructions.

Manifest SHA256: a12f9bcc86dfb9ac48f6a231bac0acc8c9d0eb8a9ce9610d36db6fa15474d058

The previous VM is confirmed stopped and retained for the standard reset/export path. The next run must use a fresh clone, not this diagnostically modified guest. No new acceptance yet.
