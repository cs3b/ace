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

## Candidate104 live bootstrap and autonomy failure

Run `8y4ul83-monorepo-e2e-ts003`, fixture `fa56db32e90fa582`, VM
`74A8B633-0AC7-4936-A03A-8E8609E3C728` reached actual delegated bootstrap:
manager `8y4.t.wnf`, executable task `8y4.t.wnz`, worker `8y4wor`, verifier
`8y4wor1`, reports `8y4wy0` and `8y4x58`. Project terminal
`term_65f8eb7db34926` ran its first turn and armed eyes. Lab subsequently
confirmed readiness and closed all three direct children and manager.

This is NOT clean acceptance: during confirmation the lab coordinator read
implementation files to discover the supported readiness procedure. TC002
then produced HITL `8y4xon` requesting a human forge handoff despite the
configured `e2e-overseer` session profile, and incorrectly sought main push
access for the coordinator. No issue integration, TS004 or clean pair passed.
Worker reports also persisted and were observed while their adapter delivery
leg failed without routes; local reporting/resume semantics remain unresolved.

After recording the concrete blocker, the diagnostic executor PID12113 was
interrupted deliberately; runner26037 exited1. Its generic report labels the
interruption Pi AuthenticationError, which is NOT evidence of provider credential
failure. The actual stop reason is recorded in local candidate104-stop.json.
The owned VM was gracefully stopped and preserved, not reset or deleted.

Local fix makes isolated-start output and bootstrap workflow explain bounded,
event-driven repeated reconciliation; no duplicate prompt/session is sent.
Start workflow describes the real auth request/exec/status/revoke interface,
public profile metadata, coordination-only assignment and separate executor
leases. Existing independent reviewer review_native_repro found no blocker;
its coordination-only clarification was incorporated.

Regression red40aff922-bfed-4b94-a9bb-8d604468d011; green9/35
c97281ce-bfb1-4149-8685-d9a703ff28eb. Full Overseer fast549/2511, zero failures,
one skip:6b9cad7d-f50d-456c-a857-0eede79e96c0. These fixes are not deployed to
the stopped candidate104 and require new immutable artifacts and clean reruns.

## Explicit local publication contract

Coworker reporting now supports explicit delivery=observe alongside adapter.
Preset/default mode is serialized into start configurations and briefs. Observe
creates the canonical HITL event and verifies its exact ID/type/task/assignment/
outcome through the HITL owner projection for the configured recipient. It says
published for observation, acceptance pending; coordinator acceptance is separate.
Prepare readiness/conflict reports follow the same configured mode. The fixture
selects observe in project configuration; no missing-route auto-detection.

Resume revalidates publication, including archive via observe --in all; normal
eyes retains the default next folder. Changed recipient/mode cannot reuse a
previous publication as successful delivery. --no-send remains deferred.
Independent review caught transient observation failure being treated as absence
and creating duplicate reports. Read errors, invalid schema/rows and ambiguity
now raise without creating or replacing the recorded event. Follow-up review
confirmed both findings closed. No new state store or transport adapter added.

Owner HITL fast406/2096 zero failures5skips (0cd4e4b5-54be-458a-b454-d857c39e5f0e),
final public CLI archive check4/28 (dc033135-9d83-4d96-a0f9-9940acb28444).
Report retry preservation19/120 (605be839-e186-4c26-9dd0-d843f89e3121), helper3/12
(d7a3c3e4-998f-4b71-b6dc-ecca1608be04), resume8/38
(56b452e9-2940-4144-9603-4b15aafbe23d), prepare25/187
(3d38c4e2-98d6-466c-a4e3-560c679e898b), fixture4/5
(d9241fba-f3de-44d2-b893-752e01da9d4e). Full coworker rerun required after
updating expected serialized default mode in roles_commission_test; previous
full run failed that assertion (0fc482cf-4321-423a-b1c1-13c8fe70be95).

TC002 runner instruction explicitly keeps fixture receipts private to the
harness and supplies actual issue URLs to the tested agent, without auth or
execution guidance. Live autonomy and two clean acceptance pairs remain unproven.

Final coworker fast418/1968 passed with no failures/errors: e4de6b46-0ef6-4fb8-9405-35dce51d8f96. Owned VM and base confirmed stopped; base configuration matches;176GiB free.

Candidate105 pins Overseer0.28.2.pre.utm105, coworker0.8.1.pre.utm105 and HITL0.25.1.pre.utm105 from5c4fe32aab57ebddeb850eaa033d436494898521. Each built twice with identical bytes; SHA256 pins are in manifest. Fetcher verified60 cached artifacts, graph55gems/7roots. Monorepo E2E fast103/366 passed3d479a68-6998-4270-bb1e-75c49880e5d3. Manifest SHA256:9e3f77dad7cdfeea1599ce58bba33212f4ba7a152ccf3cadfe33f41070bb2fa4. Next run uses standard fresh setup/export/reset, not the preserved diagnostic guest.

## Candidate105 provisioning failure (not an ACE acceptance result)

Run8y4y1hg-monorepo-e2e-ts003 failed before runtime installation or agent start.
Kernel evidence on VM A5A1DEB0-6B06-4855-93F4-6700CB1396CB: apt-get926
was OOM-killed with anon-rss7961896kB. The QGA service failed as a consequence;
its service memory peak must not be attributed to qemu-ga itself. Runner exited1
and the helper stopped/preserved the VM. It was restarted solely for diagnosis.

Debian report1152704 describes an apt3.0.3 delayed-retry warning accumulation
under slow downloads; this matches the symptom but is not yet a proven local
causal reproduction. A bounded diagnostic with Acquire::Retries=0 and
APT::Update::Error-Mode=any passed with existing indexes (242.5MB peak).
A separate empty-list download is in progress under a768MiB/300s systemd limit.
Runtime provisioning now disables internal acquisition retries and refuses any
failed index download. This does not change package pins or signature checks.
No fresh acceptance has passed; two clean pairs remain required.

Empty-list diagnostic terminated with apt exit100 after snapshot HTTP503/504
and fallback404 for security Packages; peak236.7MB, no OOM. The no-retry diagnostic exited without OOM; its explicit memory/time limits
mean this does not prove a general resource bound, network
reliability or complete provisioning. A second diagnostic attempts the missing
index. Shell syntax passed; monorepo fast103/366 zero failures/errors:
462b24a7-ae43-4644-9239-41960b156360.

Independent review found no actionable blocker; resource-bound wording corrected
to distinguish the observed result from a general guarantee.

## Fresh run8y4yean: setup passed, harness deadline failed

After APT fix c8de943fc5f01aeaa9359e9df97008d606526e50, clean VM
16C84293-3C75-41D6-9D93-16E95CA528A5 completed runtime, native Herdr,
installed-path checks, Forgejo seed and isolated-session fixture convergence.
Fixture ef61b5025ad13ffa is ready; runtime fingerprint
d4120149b05bc3dfdadb893fc4775c8d5e23bd2e5a328b38dddddb020e034974.
Lab terminal term_65f90470728032 received the goal, armed healthy eyes, read
owner state and created private manager8y5.t.047 with children being created.
No bootstrap acceptance: runner failed at2026-11-06T00:04:04Z with explicit
Pi CLI600s deadline. Prior run8y4ul83 had10800s. This invocation omitted the
CLI override; the scenario itself lacked the required budget. Both VM scenarios
now declare timeout10800, preserving individual case deadlines and all checks.
The failed run cannot count toward two clean acceptance pairs.

Timeout fix: fast103/366 passed (f998b619-1895-4f3d-9cf1-193cac6645bc).
Independent reviewer confirmed loader/orchestrator/executor propagation and no
actionable findings. Failed-run VM gracefully stopped and preserved.

## Run8y505iy: package download failure and setup diagnostics

Fresh VM89BA8069-414A-4091-8AA6-16153DF7BC9C passed index update but failed
during package installation before Ruby build. Runner66208 exited1 and helper
stopped/preserved VM. It was restarted only for diagnosis. Original detailed
stdout was discarded by SetupExecutor on failure; exact original error cannot
be recovered from that report. No OOM evidence in previous kernel journal and
no new installation entry in APT history. A bounded download-only diagnostic
reproduced HTTP504 for libbinutils2.44-3 from the pinned snapshot, with only
662kB of98.7MB archives still missing. This supports transient archive download
failure; it is not a recovered original transcript.

SetupExecutor now includes both labelled output streams and the exit code in
its error. Real-shell regression uses separate fixture files so assertions
cannot pass by matching the command text, and verifies later steps never run.
Red45tests1failure e6dfd9ef-8209-4124-8699-6ffa210c99dd; green45/145
a9b99b12-e725-4aef-841d-57012e3fcf43. Full runner fast654/2212 passed
32c0254d-f058-4040-818e-ed593dfc8707. Independent review: no actionable finding.
Next: bounded whole-process acquisition retry, then install only complete
archives; internal APT retries remain disabled. No acceptance pair completed.

## Snapshot acquisition recovery

New install-system-packages.sh retries index acquisition and download-only at
most three separate apt processes on exit100, then installs once with
--no-download. Internal retries remain0; snapshot/signature/checksum validation
is unchanged. Helper is included in runtime fingerprint, transfer and guest
SHA verification. Five shell-boundary tests cover transient recovery, exhausted
indexes/downloads, fresh processes and no install retry (5/36;
1097c215-9360-47be-9446-3fd6edf898da). Full monorepo fast108/402 passed
f565f2f5-3ba6-41ed-9ebc-35d7b3da3abe; independent review found no blocker.

Real diagnostic unit ace-e2e-apt-recovery-diagnostic on preserved VM89BA...
failed first acquisition of cpp-14, logged fresh-process retry at00:14:08,
completed archive download at00:14:18, then installed offline successfully
at2026-11-06T00:14:58Z (Result=success, ExecMainStatus=0). This was explicitly
diagnostic, under768MiB/600s limits, not acceptance. A new clean run is required.


## UTM105 live bootstrap: false executor readiness (2026-11-06)

Run `8y50e5a-monorepo-e2e-ts003`, fixture `06abda525a5b4380`, installed candidate unchanged at source `31371192de9a6e6965b075432a66f1e96cba7f08`: lab manager `8y5.t.26n`, executable task `8y5.t.270`, worker `8y529b`, verifier `8y529b1`. Real worker dispatch, worker report `8y52ob`, lab wake/receipt and separate verifier dispatch were observed. These are component evidence, not full acceptance.

The lab commissioned a canonical coworker config as generic project readiness. The worker copied a worktree assignment identity into the canonical checkout; `status` returned ready despite missing local assignment. The verifier accepted absence of the words "not ready" despite the real assignment error. Lab also resolved worktree-relative start configs against the canonical root; both executors corrected the supplied path themselves. A required `prepare --dry-run` conflicted with the running worker's own assignment.

Owner fix: `StatusOrchestrator` returns NotReady for missing/mismatched assignment and typed status probe failures; remove the contradictory Ready/probe_error presentation. The status query still renders states without treating exit zero as readiness. Documentation distinguishes executor readiness from project readiness. Bootstrap workflow forbids the copied-config check and active prepare acceptance loop, and explicitly resolves start configs relative to the returned worktree. No guest patch or prompt was injected; these edits require a new built candidate and fresh acceptance.

Verification: baseline 17 tests/44 assertions (`3f51fc51-16cb-491f-b0cd-ebad1427bf38`); regression red 18 tests/2 failures (`4cb9cc0f-5936-41f9-9694-5bcb521b8fd9`); green 18/50 (`30055036-ede7-4d2e-b8f7-375972c6ec1d`); coworker fast 419/1974, zero failures (`c63f60e0-b775-4d23-98dc-63a11536c459`). Independent review `review_native_repro`: no blocker; narrowed documentation to typed status probe failures because raw filesystem errors still fail the CLI rather than rendering readiness. Guide review: no actionable finding. Overseer fast: 549 tests/2511 assertions, zero failures/errors, one skip (`0471a655-69fc-45c1-864a-e52a7f848928`). Acceptance remains 0/2.

### TC-002: authenticated runtime lost at lease execution (2026-11-06)

Candidate105 run `8y50e5a-monorepo-e2e-ts003` remains live on its unchanged manifest. Project Overseer independently created coordination task `8y5.t.3xn` and assignment `8y53y3`, requested a lease, and invoked `fj`. The bare executable returned 127 with cleanup revoked; the absolute `/opt/ace/runtime/bin/fj` executed (initial argument syntax returned 2; corrected invocation read actual issue content). No operator repair was applied to the VM.

Root cause: `Service#preserve_installed_runtime!` selected the issuer environment, whose unit PATH excludes the session runtime bin directory. The source fix carries only ACE_TOOLCHAIN/PATH/GEM_HOME/GEM_PATH from the authenticated root-created systemd unit, rejects missing/ambiguous bindings, freezes the selection, and reapplies it after provider environment projection. Client-supplied paths do not establish runtime identity.

Baseline: 115 tests/415 assertions (`8211f930-b7af-428b-b49b-cdec7d8ae615`). Regression before fix: missing identity runtime and accepted missing/duplicate PATH (`fa020c9e-f5ea-400a-aa42-4fa725cd0c02`, one failure/one error). Focused after fix: 118 tests/425 assertions (`8882fabc-bf90-4ba3-a3e5-5a06e1820020`). Full lab fast suite: 1008 tests/4702 assertions, zero failures/errors, 16 skips (`35cc31ca-1200-44c5-b8c7-80fc5dd528c9`). Independent reviewer `review_native_repro` found no actionable issue and explicitly requires rebuilt-candidate bare `fj` execution plus cleanup evidence. Not installed into the running VM; fresh candidate/reset still required. Acceptance remains 0/2.

### TC-002: project standing guide selected local work-on (2026-11-06)

The live project Overseer prepared base task `8y5.t.429` (assignments `8y5475`, `8y54751`, `8y54752`) and docs `8y5.t.432` (`8y5473`, `8y54731`, `8y54732`). It followed the project guide's `work-on` recommendation: auto failed with no selected terminal runtime; explicit herdr failed with “not inside a herdr workspace”. It then discovered `ace-herdr dispatch` autonomously; the runner observed worker terminal `term_65f92adec789b7` launch pending. No intervention in the guest.

Updated the project standing guide with the existing isolated dispatch contract already present in the bootstrap guide: returned worktree/config/assignment identity, host worker/verifier/integrator roles, acceptance-before-next-leg and turn completion. Independent reviewer confirmed CLI compatibility. Reviewer also identified an OPEN owner-level gap: `ReportProcessor#continue_queue` still reaches local `WorkOnOrchestrator` without a family worktree, and handoff also ensures a local terminal. Isolated report continuation must be handled explicitly and tested; this documentation change alone does not close that flow. Current candidate107 artifacts predate this documentation change and are not final acceptance artifacts.

### Isolated report continuation owner fix (2026-11-06)

Closed the owner-level continuation gap identified above: `ReportProcessor` accepts the report through the existing task owner, then in isolated sessions returns a coordinator action instead of calling local `WorkOnOrchestrator`. For an existing family worktree it executes the complete handoff gate with `dry_run: true`, preserves exact next-leg/worktree/config evidence, and does not claim a terminal or executor started. Gate refusal remains blocked; sequence completion does not close remaining coordination; repeated reports recheck state without dispatching. The coordinator still performs authenticated dispatch from recorded allocation.

Baseline: 19 tests/144 assertions (`94d43335-0765-427d-b032-a17112223e82`). Regression red: two failures demonstrating local work-on and non-dry-run handoff (`824cdaab-2c66-4e3c-bb7b-1f8c51ddaf87`). Full overseer fast suite after fix: 552 tests/2546 assertions, zero failures/errors, one skip (`fe15f749-21b4-4146-b1b1-c44a10809eeb`). Independent reviewer `review_native_repro`: finding resolved, no new actionable finding. Documentation reflects coordinator responsibility and pending-state semantics.

The unchanged candidate105 VM independently launched both workers (base terminal `term_65f92adec789b7`, docs agent `worker-8y5-t-432-23bf6aee`); both were observed working. This is live diagnostic progress, not accepted candidate coverage. Final clean acceptance remains 0/2.


## 2026-11-06 — live project delivery routing and suite runtime

Run `8y50e5a-monorepo-e2e-ts003` remains live; no prompts or repairs injected.
Project Overseer created base/CLI/docs/release tasks and dispatched base/docs workers.
Base worker reported PR #5 and assignment completion; this is not yet independently
verified merge evidence. Read-only inspection confirms the project eyes recipient is
`overseer`, while the prepared base worker config names `lab-overseer`. The project
start guide now requires explicit `prepare --to` matching armed eyes, resolving the
configured HITL address and checking every returned leg before dispatch. Existing
prepare owner tests pass: 25 tests / 187 assertions, report
`7c0b05d5-88f1-452a-9d2e-80aad3e48ab1`. Live acceptance of the guide is pending.

The docs worker exposed suite worker runtime loss during Bundler version switching.
The source fix uses the toolchain owner's installed launcher/environment and
`bundle exec` for development workers; actual test child environments stay hermetic.
Focused checks: process monitor 7/39, hermetic environment 4/32, fast 204/656 green.
Full feat is not green: modified 96 tests, 11 failures + 3 errors
(`bea20f82-a5b9-4fe3-8640-901706373637`); HEAD baseline 95 tests, 15 failures + 3 errors
(`acc8a46a-e196-4618-994e-ac79a30ffc68`). All 14 modified failing test names also fail
on baseline; four fixture setup failures are removed. Remaining failures include
missing websocket-driver in hermetic fixture setup and consequential subprocess
failures/timeouts. This comparison does not prove a clean full suite. Exact edited
files were restored after baseline testing and their SHA-256 hashes verified.

Acceptance remains 0/2. The running manifest is unchanged; rebuilt candidate and
clean reset acceptance are still required.


### Runner feature-suite follow-up

The remaining fixture failures were traced to temporary projects evaluating the
checkout Gemfile without its configured dependency directory. A shared test-only
`configure_fixture_bundle` now writes that directory to each fixture’s local
Bundler configuration; environment isolation and verdict/evidence assertions are
unchanged. Independent reviewer found no actionable issue. Focused tests: 3/30
(`bf1e5969-00b6-4f3c-a034-986c7803abc5`) and 23/474
(`927fe2e4-deaa-4cc8-9767-61b49ac61450`). Full feat now passes **96 tests / 803
assertions / 0 failures / 0 errors** (`828549da-181a-4f8a-9198-c598c5f24987`).
This supersedes the local baseline-failure limitation above, not the outstanding
live installed-runtime acceptance. Candidate109 artifacts were reproducibly built
from eee6b426645b61783bc97397e6c3531973457562; this subsequent test-only change is
not included in that source SHA. The active VM manifest remains unchanged.


### Candidate109 staging check

Artifact inventory now accepts pinned local ace-test-runner builds, matching the
build helper. Regression was red before the allowlist change (b32f74ea-d868-4251-b88b-236914d21ed4),
green after (4/19, 451d94f2-2c26-4ef4-95fe-504017dcd828). Full monorepo-e2e
package tests pass 108/402 (643dca31-5d79-4c91-90a8-dc822d39fcbb).
A next-run manifest is staged only in local analysis/candidate109-manifest.json;
the live tracked manifest has not changed. Existing gem-graph validation confirms
55 exact gem artifacts satisfy all 7 installation roots. Staging and component
tests do not establish installed E2E acceptance.


## Project observation timeout — owner API integration

Live candidate105 lab projection degraded project:ace with Timeout::Error, while
an unrestricted direct project observation returned healthy sources and report
8y551c. Read-only guest profiling: require ace/overseer 4.513s, project tasks
0.019s, private tasks 0.011s, worktrees 0.036s, coworkers 19.990s across four
worktrees. Repeated ace-assign process startup exceeded the 20s project budget.
No VM mutation or tested-agent prompt was made.

Source change: optional start_path in the config owner; explicit-root assignment
discovery in ace-assign; coworker probe uses that installed owner API, with no
checkout runtime loading, cwd mutation or second state store. Independent review
caught a CLI relative CACHE_BASE regression; fixed by resolving its existing
cache once for inventory and current selection. A nested-cwd regression now
passes. Reviewer found no further actionable issue. Runtime floors updated for
ace-assign 0.73.2 and ace-support-config 0.18.4; no publication performed.

Executed full package tests: config325/863 (d744164a-86ac-4e93-b611-799de248f6f5),
assign643/2531 with2skip (c1908ff8-12e4-4b57-893a-76628f723221), coworker418/1974
(a7e04826-30df-491f-a49b-9df919564d12), overseer562/2613 with1skip
(fe900a27-bd0a-4404-866e-95cfa7432072); all zero failures/errors. Installed VM timing
and end-to-end correctness remain unverified until a fresh candidate run.
Candidate109 lacks this optimization and is superseded for acceptance; do not
activate its staged manifest. Active run remains candidate105, acceptance0/2.


### Candidate110 built-artifact rehearsal

Six changed gems (support-config, assign, lab, coworker, overseer, test-runner)
were each built twice from `0660169a0bb4f4ac38a0f94216b7def10c546f27`; all repeated
SHA-256 values matched. Local metadata: analysis/candidate110-build.json; staged
manifest: analysis/candidate110-manifest.json. The graph verifies55gems/7roots.
All55 artifacts installed into the private macOS rehearsal110/gems directory,
including native dependencies. An env-cleared ACE_TOOLCHAIN=installed probe
loaded the three new inventory libraries exclusively from that gem home and
read four real, independently configured project inventories (one record each),
with poisoned checkout Gemfiles. Inventory work took0.015472s on this host.
This is artifact-level evidence on macOS, not Linux timing or E2E acceptance.
The current candidate105 VM and tracked release manifest remain unchanged.


### Live review handoff and fixture PATH correction

The project Overseer independently continued after worker completion and launched
base reviewer8y54751 (term_65f938767dd3f9) and docs reviewer8y54731
(term_65f939544d0d1a). Both real PRs5/6 were independently read from Forgejo's
read-only database before handoff: open, unmerged, no reviews yet. This is new
progress beyond the earlier waiting snapshot, not a completed integration.

Base reviewer exposed missing Pi CLI in the isolated session PATH and itself
retried ace-review after adding the existing installed Pi bin directory. The
fixture's ordinary profile already included that directory, but session_runtime
path omitted it. Added /opt/ace/runtime/pi/node_modules/.bin to the trusted
fixture session PATH for future resets. Read-only guest stat confirms the
existing directory is root:root0755. No modification of the running VM or agent
instructions was made; review verdicts and merges remain pending.


### Next-run execution budget

The current candidate105 delivery phase reached two independent reviewer sessions
only after worker dependency installation and a real full-suite run; the base
review's first model execution then took roughly six minutes. No throughput SLA
is part of the requested acceptance. For future TS003 runs, delivery budget is
180 minutes and total runner budget18000s, accommodating bootstrap, the serial
base→CLI dependency chain, independent review/integration and idle verification.
All acceptance conditions remain unchanged, including five minutes with no model
turns after notifications drain. This changes only future scenario execution;
the current runner retains its recorded10800s timeout and its original case
instructions. Its outcome must be reported under those original limits.


### Full PR review range correction

Observed base reviewer subject:
`diff:ccb6b904d0b30fb4a1c403282c6e325287b31002..b75554543f8e1c57c4ca685ec033c20a0f3bb9ba`.
Read-only git evidence in /lab/ace: local main is ccb6b904d0b30fb4a1c403282c6e325287b31002;
origin/main and its merge-base with that candidate are both
167ebcbe63c2646809485fd0f782a7b97023f5fc. Thus this claimed full round excludes
coordination commits present in the actual PR. Reviewer instructions now require
forge-derived base/head and full-file coverage; TC002 verifier explicitly rejects
worker-only ranges presented as full review. The installed-mode reviewer boundary
also no longer unconditionally selects checkout binstubs. Live agents unchanged.
Candidate110 is superseded by this instruction change; build a new candidate before
acceptance. Scenario-contract check2/69 passes (faaaadd5-2812-47cb-aa94-38c3c6d89795).

## 2026-11-06 — candidate105 terminal and candidate111 activation

Run `8y50e5a-monorepo-e2e-ts003` terminated with `Ace::LLM::ProviderError`: runner exceeded its original 10800-second deadline at 04:16:55Z. No final acceptance verdict was produced; acceptance remains 0/2. Before termination the project Overseer independently consumed base reviewer report `8y56ct` and dispatched integrator assignment `8y54752`, terminal `term_65f93dcec2502b`, isolated session `35f933cd427f0953`. The integrator started its installed coworker brief; merge was not established. The reviewer ACCEPT is not full-delta proof because its local range omitted part of the Forgejo PR.

The terminated run permits activation of staged candidate111, built twice identically from `97123d7026fc44cfbf3c9ef16e4c0d1cca7cb8b7`. The helper reset is exporting the old owned VM before replacing it. All previous runtime observations remain component evidence, not clean acceptance.
