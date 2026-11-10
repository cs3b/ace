# Local final-delta review: supporting packages and auth simplification

Date: 2026-11-10. Reviewer: review_simplification, delegated independently of the launch-pipeline author. No VM or provider/model calls.

## Scope and verdict boundary

Reviewed full retained diff against `origin/main`, not only the most recent fixes. Base: `51dd5d6ba14b97aacd8c442056940b66465a3b9a`; checkout HEAD at review: `1031127cace3c04cedccb62c3b199619c570978f` plus the uncommitted simplification delta. This is **not an exact-final-HEAD merge verdict**; the final committed diff and release metadata still need reconciliation.

No additional confirmed release blocker was found in the supporting-package scope below after the Darwin readiness correction. Local tests establish component behavior only; autonomous UTM/Forgejo acceptance remains unexecuted.

The reviewer authored the ace-lab simplification and Darwin eyes correction. Those changes require a different reviewer; their implementation/test evidence below must not be treated as independent approval. Core overseer/coworker/herdr launch and E2E behavior are separately assigned to the other reviewers.

## Findings and resolution

1. **Confirmed readiness blocker: Darwin could never become ready.** Wake emitted no process binding outside Linux; the Ruby reader and validation accepted only Linux birth IDs. Fixed by caching a bounded Darwin probe of the existing `ProcessIdentity.native_birth` owner and accepting exact Darwin birth IDs. Linux stays on direct `/proc` reads. Real Node process birth agrees with Ruby, live session is accepted, exited process rejected. Missing Ruby/runtime produces no valid evidence. This correction needs independent review by another reviewer.
2. **Obsolete issuer entry point:** `EyesDescriptorEvaluator` and `libexec/eyes-ready` had no remaining consumers after issuer deletion. Removed those files and only the dedicated evaluator test, preserving local session-reader tests.
3. **Runtime cleanup map:** `protected_linux`, `protected_socket`, and systemd manager existed before this branch and have retained native Herdr consumers: do not delete the modules. New `CgroupObservation#retired?`, `Files#descriptor_path`, and `RemainAfterExit` signature were issuer-only additions without remaining production consumers; parent notified to remove just that unused delta. Keep explicit shared error requires and standalone dependency-loading tests.

## Review coverage

| Package | Behavior inspected | Verification responsibility |
|---|---|---|
| ace-assign | Explicit config roots and assignment discovery/list inventory | Discovery/list regression assertions inspected |
| ace-git / ace-git-forgejo | PR author identity; bounded UTF-8 body input; scoped formal reviewer; issue pagination; body and label content | Existing and added provider/PR tests inspected; parent reports executed 197 tests for final body/labels fix |
| ace-git-worktree | Deferred setup at create, explicit branch handling, hooks postponed to installed executor | Manager and task orchestration regressions inspected |
| ace-handbook-integration-pi | Continue-work/task CLI instructions | Static instruction review |
| ace-hitl | Strict observation and inclusion of completed/archive cases | Event observation regression assertions inspected |
| ace-llm-providers-cli | Concurrent stdin/stdout/stderr draining, Pi prompt via stdin, no-response failure evidence | Real subprocess capture and Pi client tests inspected; no model invoked |
| ace-review | Structured/fenced JSON feedback extraction | Feedback synthesizer regressions inspected |
| ace-runtime | Standalone typed-error loading and obsolete issuer-only additions | Consumer inventory; dependency-loading tests inspected |
| ace-support-config | Start-path forwarding to root-aware resolver | Resolver tests inspected |
| ace-support-items / ace-task | Accessible-only scan; create/reparent numbering locks; manager propagation | Scanner and create/reparent/task-manager tests inspected |
| ace-test-runner | Installed child invocation outside checkout bundle; default targets and evidence | Process-monitor and integration assertion deltas inspected |
| ace-test-runner-e2e | Exact fixture copying and setup command failure evidence | Sandbox and setup executor tests inspected |
| ace-wake | Eyes state/evidence lifecycle, cadence and budgets, stale/failed observation, installed imports and Pi acceptance | JS assertions inspected; complete wrapper suite executed after Darwin correction |

### Exact retained file inventory

The following is the changed-file coverage inventory for this review pass; package release-version changes added afterward are outside this snapshot.


#### ace-assign

- `ace-assign/CHANGELOG.md`
- `ace-assign/ace-assign.gemspec`
- `ace-assign/docs/usage.md`
- `ace-assign/lib/ace/assign.rb`
- `ace-assign/lib/ace/assign/cli/commands/list.rb`
- `ace-assign/lib/ace/assign/molecules/assignment_discoverer.rb`
- `ace-assign/lib/ace/assign/version.rb`
- `ace-assign/test/fast/commands/list_command_test.rb`
- `ace-assign/test/fast/molecules/assignment_discoverer_test.rb`

#### ace-git

- `ace-git/lib/ace/git/cli/commands/pr.rb`
- `ace-git/lib/ace/git/organisms/pull_request_lifecycle.rb`
- `ace-git/lib/ace/git/providers/evidence.rb`
- `ace-git/lib/ace/git/providers/formal_approval.rb`
- `ace-git/test/fast/commands/pr_test.rb`
- `ace-git/test/fast/organisms/pull_request_lifecycle_test.rb`

#### ace-git-forgejo

- `ace-git-forgejo/CHANGELOG.md`
- `ace-git-forgejo/lib/ace/git/forgejo/issue_api.rb`
- `ace-git-forgejo/lib/ace/git/forgejo/provider.rb`
- `ace-git-forgejo/test/fast/molecules/formal_approval_provider_test.rb`
- `ace-git-forgejo/test/fast/molecules/issue_api_test.rb`

#### ace-git-worktree

- `ace-git-worktree/CHANGELOG.md`
- `ace-git-worktree/lib/ace/git/worktree/organisms/task_worktree_orchestrator.rb`
- `ace-git-worktree/lib/ace/git/worktree/organisms/worktree_manager.rb`
- `ace-git-worktree/test/fast/organisms/task_worktree_orchestrator_test.rb`
- `ace-git-worktree/test/fast/organisms/worktree_manager_test.rb`

#### ace-handbook-integration-pi

- `ace-handbook-integration-pi/CHANGELOG.md`
- `ace-handbook-integration-pi/docs/usage.md`
- `ace-handbook-integration-pi/handbook/prompts/continue-work.md`
- `ace-handbook-integration-pi/test/fast/pi_test.rb`

#### ace-hitl

- `ace-hitl/CHANGELOG.md`
- `ace-hitl/lib/ace/hitl/cli/commands/observe.rb`
- `ace-hitl/lib/ace/hitl/molecules/event_observation.rb`
- `ace-hitl/lib/ace/hitl/organisms/hitl_manager.rb`
- `ace-hitl/test/fast/organisms/event_observation_test.rb`

#### ace-llm-providers-cli

- `ace-llm-providers-cli/lib/ace/llm/providers/cli/molecules/safe_capture.rb`
- `ace-llm-providers-cli/lib/ace/llm/providers/cli/pi_client.rb`
- `ace-llm-providers-cli/test/fast/molecules/pi_client_test.rb`
- `ace-llm-providers-cli/test/fast/molecules/safe_capture_test.rb`

#### ace-review

- `ace-review/lib/ace/review/molecules/feedback_synthesizer.rb`
- `ace-review/test/fast/molecules/feedback_synthesizer_test.rb`

#### ace-runtime

- `ace-runtime/CHANGELOG.md`
- `ace-runtime/lib/ace/runtime/molecules/cgroup_observation.rb`
- `ace-runtime/lib/ace/runtime/molecules/protected_linux.rb`
- `ace-runtime/lib/ace/runtime/molecules/protected_socket.rb`
- `ace-runtime/lib/ace/runtime/molecules/systemd_scope_manager.rb`
- `ace-runtime/test/molecules/cgroup_observation_test.rb`
- `ace-runtime/test/molecules/protected_dependency_loading_test.rb`
- `ace-runtime/test/molecules/systemd_scope_manager_test.rb`

#### ace-support-config

- `ace-support-config/CHANGELOG.md`
- `ace-support-config/lib/ace/support/config.rb`
- `ace-support-config/lib/ace/support/config/organisms/config_resolver.rb`
- `ace-support-config/lib/ace/support/config/version.rb`
- `ace-support-config/test/fast/organisms/config_resolver_test.rb`

#### ace-support-items

- `ace-support-items/CHANGELOG.md`
- `ace-support-items/lib/ace/support/items/molecules/directory_scanner.rb`
- `ace-support-items/test/fast/molecules/directory_scanner_test.rb`

#### ace-task

- `ace-task/CHANGELOG.md`
- `ace-task/README.md`
- `ace-task/docs/usage.md`
- `ace-task/lib/ace/task/molecules/subtask_allocation_lock.rb`
- `ace-task/lib/ace/task/molecules/subtask_creator.rb`
- `ace-task/lib/ace/task/molecules/task_reparenter.rb`
- `ace-task/lib/ace/task/molecules/task_scanner.rb`
- `ace-task/lib/ace/task/organisms/task_manager.rb`
- `ace-task/test/fast/molecules/subtask_creator_test.rb`
- `ace-task/test/fast/molecules/task_reparenter_test.rb`
- `ace-task/test/fast/organisms/task_manager_test.rb`

#### ace-test-runner

- `ace-test-runner/CHANGELOG.md`
- `ace-test-runner/lib/ace/test_runner/suite/process_monitor.rb`
- `ace-test-runner/test/feat/default_target_selection_cli_test.rb`
- `ace-test-runner/test/feat/execution_verdict_cli_test.rb`
- `ace-test-runner/test/feat/hermetic_environment_test.rb`
- `ace-test-runner/test/feat/suite/execution_evidence_test.rb`
- `ace-test-runner/test/feat/suite/process_monitor_test.rb`
- `ace-test-runner/test/test_helper.rb`

#### ace-test-runner-e2e

- `ace-test-runner-e2e/docs/usage.md`
- `ace-test-runner-e2e/handbook/guides/scenario-yml-reference.g.md`
- `ace-test-runner-e2e/lib/ace/test/end_to_end_runner/molecules/pipeline_sandbox_builder.rb`
- `ace-test-runner-e2e/lib/ace/test/end_to_end_runner/molecules/setup_executor.rb`
- `ace-test-runner-e2e/test/fast/molecules/pipeline_sandbox_builder_test.rb`
- `ace-test-runner-e2e/test/fast/molecules/setup_executor_test.rb`

#### ace-wake

- `ace-wake/CHANGELOG.md`
- `ace-wake/README.md`
- `ace-wake/ace-wake.gemspec`
- `ace-wake/handbook/extensions/ace-wake/wake/eyes-runtime.js`
- `ace-wake/handbook/extensions/ace-wake/wake/eyes.js`
- `ace-wake/test/acceptance/pi-sdk-acceptance.test.mjs`
- `ace-wake/test/eyes-runtime.test.mjs`
- `ace-wake/test/eyes.test.mjs`
- `ace-wake/test/installed-wake-extension.test.mjs`

## Auth implementation evidence (requires separate reviewer)

The simplified ace-lab keeps existing Service/providers/LeaseStore, atomic correlation and execution locks, scope validation, deadline handling, explicit uncertain outcomes and private credential files. Default execution is an ordinary subprocess group. Installer/verify no longer require a system issuer or root session launcher. SessionConfiguration is a passive project/role selector; project-specific environment_files map to private JSON maps; existing credentials remains Pi auth JSON.

Executed `bin/ace-test ace-lab`: **784 tests, 3708 assertions, 0 failures, 0 errors, 4 skips**. Report: `.ace-local/test/reports/lab/bdfc8140-4db9-47e6-abdf-43305a9d26e7/`. Skips are existing capability-dependent tests, none auth. LocalCommand specifically executes real processes, enforces deadline, removes inherited environment, cleans descendants and handles TERM. Hard-crash ambiguity remains visibly blocked rather than claiming a background service will clean it.

Executed `bin/ace-test ace-wake`: **2 wrapper tests, 7 assertions, no errors/failures**, includes complete JavaScript suite. Report: `.ace-local/test/reports/wake/68b84405-0cd7-421d-a41b-f17012f473a3/`.

Executed `bin/ace-test ace-overseer test/fast/molecules/eyes_session_evidence_test.rb test/fast/molecules/eyes_evidence_test.rb`: **18 tests, 45 assertions, no errors/failures**. Report: `.ace-local/test/reports/overseer/a4db08d4-347e-4461-85c6-a87d0beb7efd/`.

Earlier failing local probes exposed test path/cleanup issues and a Darwin process-group zombie cleanup edge; fixes were followed by the green runs above. No VM acceptance has been credited.

## Extended independent review: orchestration and coworker delta

This pass also inspected the full retained `ace-overseer` and `ace-coworker` production diff, plus Herdr Dispatcher, HerdrExecutor and Dispatch CLI environment-file bridge. It checked their changed test assertions and role instructions against the ordinary process contract. SessionEnvironment, CoworkerLauncher, ExecutionBinding, WorkOn and Handoff have their own independent reviewer; observations were forwarded to that owner rather than edited concurrently.

Confirmed findings fixed in this pass:

- **Report cleanup retry:** recorded error duplicates bypassed retirement, leaving a failed cleanup unrecoverable through normal report replay. Every non-dry-run recorded report now retries retirement; only recorded success can continue the queue. Regression proves no extra task write or dispatch on repeated error.
- **Coordinator failed-start cleanup:** native start timeout/error may leave a process. Close the new pane before removing copied auth; failed closure is explicitly blocked and preserves auth. Evidence/session directory remains available. Parent owns cleanup after a successfully started coordinator exits.
- **Lab initialization deadlock:** same-turn bootstrap dispatch conflicted with readiness requiring a completed first turn. The lab guide now arms healthy eyes and settles; pending changes wake it for bootstrap dispatch afterward. A contract test covers this order and existing readiness tests reject incomplete first turns.
- **Wrong eyes config path:** launcher recipient lookup used `.ace/overseer/eyes.json`, conflicting with canonical `.ace-local/overseer/eyes.json`. The independent launcher reviewer confirmed and fixed the mismatch.
- **Contradictory role documentation:** reviewer required leases for every forge command; bootstrap claimed OS private-tree masking; project guide banned credential files. Corrected to configured project access, conditional temporary auth, private credential files, and role responsibility without a same-user OS boundary.

The launcher's potential cross-config dispatch race was examined with its reviewer. Public WorkOn/Handoff already serialize via the existing `LifecycleExclusion` delegate lock, so no new lock/state layer was requested. Per-project observation now selects that project's configured read environment rather than inheriting the lab token. Current body/label revisions, report owner filtering, assignment-outcome matching, no-source runtime selection, and exact-head approval gates were inspected without another confirmed blocker.

Local verification after these fixes:

- `bin/ace-test ace-runtime`: **307 tests / 1235 assertions / 0 failures**; report `runtime/0d138bd1-ca26-4df6-8848-c3bd486082df`. Only unconsumed retirement/RemainAfterExit additions were removed; retained native runtime modules remain.
- `bin/ace-test ace-lab test/fast/auth/local_command_test.rb`: **7 tests / 13 assertions / 0 failures**; report `lab/4983b408-625a-45f2-8045-cd5bf7a79b68`. Independent reviewer found and rechecked ECHILD/trap-setup cleanup fixes.
- `bin/ace-test ace-overseer test/fast/organisms/start_orchestrator_test.rb test/fast/organisms/report_processor_test.rb`: **60 tests / 361 assertions / 0 failures / 1 existing skip**; report `overseer/8957ade1-7af0-4c5c-b14f-4809a1d9738e`.
- `bin/ace-test ace-overseer test/fast/atoms/start_contract_test.rb test/fast/molecules/eyes_evidence_test.rb`: **21 tests / 63 assertions / 0 failures**; report `overseer/aec73989-5c18-4a83-882a-2820b588326a`.

Auth, Darwin evidence, report replay and failed-start fixes authored here require another reviewer's verdict. This document is a coverage/finding record, not self-approval of those edits or a claim of autonomous VM success. Final-head gate still awaits the committed candidate and consolidated independent verdict.

### Extended changed-file inventory

- `ace-coworker/.ace-defaults/coworker/sequences/reviewer.yml`
- `ace-coworker/.ace-defaults/coworker/sequences/worker.yml`
- `ace-coworker/CHANGELOG.md`
- `ace-coworker/README.md`
- `ace-coworker/ace-coworker.gemspec`
- `ace-coworker/docs/usage.md`
- `ace-coworker/handbook/workflow-instructions/coworker/bootstrap-verifier.wf.md`
- `ace-coworker/handbook/workflow-instructions/coworker/bootstrap-worker.wf.md`
- `ace-coworker/handbook/workflow-instructions/coworker/integrator.wf.md`
- `ace-coworker/handbook/workflow-instructions/coworker/reviewer.wf.md`
- `ace-coworker/handbook/workflow-instructions/coworker/worker.wf.md`
- `ace-coworker/lib/ace/coworker/atoms/brief_formatter.rb`
- `ace-coworker/lib/ace/coworker/atoms/config_schema.rb`
- `ace-coworker/lib/ace/coworker/atoms/integration_gate.rb`
- `ace-coworker/lib/ace/coworker/atoms/resume_planner.rb`
- `ace-coworker/lib/ace/coworker/atoms/role_preset_schema.rb`
- `ace-coworker/lib/ace/coworker/cli/commands/gate.rb`
- `ace-coworker/lib/ace/coworker/cli/commands/prepare.rb`
- `ace-coworker/lib/ace/coworker/cli/commands/status.rb`
- `ace-coworker/lib/ace/coworker/models/brief.rb`
- `ace-coworker/lib/ace/coworker/models/config.rb`
- `ace-coworker/lib/ace/coworker/models/outcome.rb`
- `ace-coworker/lib/ace/coworker/molecules/config_loader.rb`
- `ace-coworker/lib/ace/coworker/molecules/execution_binding.rb`
- `ace-coworker/lib/ace/coworker/molecules/hitl_reporter.rb`
- `ace-coworker/lib/ace/coworker/molecules/worktree_executor_probe.rb`
- `ace-coworker/lib/ace/coworker/molecules/worktree_provision_probe.rb`
- `ace-coworker/lib/ace/coworker/organisms/commission_orchestrator.rb`
- `ace-coworker/lib/ace/coworker/organisms/prepare_orchestrator.rb`
- `ace-coworker/lib/ace/coworker/organisms/report_orchestrator.rb`
- `ace-coworker/lib/ace/coworker/organisms/resume_orchestrator.rb`
- `ace-coworker/lib/ace/coworker/organisms/start_config_writer.rb`
- `ace-coworker/lib/ace/coworker/organisms/status_orchestrator.rb`
- `ace-coworker/lib/ace/coworker/version.rb`
- `ace-coworker/test/atoms/resume_planner_test.rb`
- `ace-coworker/test/commands/gate_test.rb`
- `ace-coworker/test/commands/prepare_integration_test.rb`
- `ace-coworker/test/commands/roles_commission_test.rb`
- `ace-coworker/test/commands/start_status_test.rb`
- `ace-coworker/test/molecules/hitl_publication_test.rb`
- `ace-coworker/test/molecules/role_sequence_composer_test.rb`
- `ace-coworker/test/molecules/worktree_executor_probe_test.rb`
- `ace-coworker/test/molecules/worktree_probes_test.rb`
- `ace-coworker/test/organisms/commission_orchestrator_test.rb`
- `ace-coworker/test/organisms/prepare_orchestrator_test.rb`
- `ace-coworker/test/organisms/report_orchestrator_test.rb`
- `ace-coworker/test/organisms/resume_orchestrator_test.rb`
- `ace-coworker/test/organisms/start_config_writer_test.rb`
- `ace-coworker/test/organisms/start_orchestrator_test.rb`
- `ace-coworker/test/organisms/status_orchestrator_test.rb`
- `ace-overseer/CHANGELOG.md`
- `ace-overseer/README.md`
- `ace-overseer/ace-overseer.gemspec`
- `ace-overseer/docs/getting-started.md`
- `ace-overseer/docs/usage.md`
- `ace-overseer/handbook/workflow-instructions/overseer/bootstrap-delegation.wf.md`
- `ace-overseer/handbook/workflow-instructions/overseer/lab-start.wf.md`
- `ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md`
- `ace-overseer/handbook/workflow-instructions/overseer/start.wf.md`
- `ace-overseer/lib/ace/overseer.rb`
- `ace-overseer/lib/ace/overseer/atoms/observation_sources.rb`
- `ace-overseer/lib/ace/overseer/atoms/start_contract.rb`
- `ace-overseer/lib/ace/overseer/cli.rb`
- `ace-overseer/lib/ace/overseer/cli/commands/handoff.rb`
- `ace-overseer/lib/ace/overseer/cli/commands/process_reports.rb`
- `ace-overseer/lib/ace/overseer/cli/commands/start.rb`
- `ace-overseer/lib/ace/overseer/cli/commands/work_on.rb`
- `ace-overseer/lib/ace/overseer/molecules/coworker_launcher.rb`
- `ace-overseer/lib/ace/overseer/molecules/event_observation.rb`
- `ace-overseer/lib/ace/overseer/molecules/eyes_evidence.rb`
- `ace-overseer/lib/ace/overseer/molecules/eyes_readiness.rb`
- `ace-overseer/lib/ace/overseer/molecules/eyes_session_evidence.rb`
- `ace-overseer/lib/ace/overseer/molecules/hitl_inbox.rb`
- `ace-overseer/lib/ace/overseer/molecules/local_sources.rb`
- `ace-overseer/lib/ace/overseer/molecules/project_bundle.rb`
- `ace-overseer/lib/ace/overseer/molecules/project_observations.rb`
- `ace-overseer/lib/ace/overseer/molecules/project_sessions.rb`
- `ace-overseer/lib/ace/overseer/molecules/remote_sources.rb`
- `ace-overseer/lib/ace/overseer/molecules/session_environment.rb`
- `ace-overseer/lib/ace/overseer/organisms/handoff_orchestrator.rb`
- `ace-overseer/lib/ace/overseer/organisms/report_processor.rb`
- `ace-overseer/lib/ace/overseer/organisms/start_orchestrator.rb`
- `ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb`
- `ace-overseer/lib/ace/overseer/version.rb`
- `ace-overseer/test/fast/atoms/start_contract_test.rb`
- `ace-overseer/test/fast/commands/cli_test.rb`
- `ace-overseer/test/fast/commands/start_command_test.rb`
- `ace-overseer/test/fast/molecules/coworker_launcher_test.rb`
- `ace-overseer/test/fast/molecules/eyes_evidence_test.rb`
- `ace-overseer/test/fast/molecules/eyes_readiness_test.rb`
- `ace-overseer/test/fast/molecules/eyes_session_evidence_test.rb`
- `ace-overseer/test/fast/molecules/hitl_inbox_test.rb`
- `ace-overseer/test/fast/molecules/local_sources_test.rb`
- `ace-overseer/test/fast/molecules/project_bundle_test.rb`
- `ace-overseer/test/fast/molecules/project_observations_test.rb`
- `ace-overseer/test/fast/molecules/project_sessions_test.rb`
- `ace-overseer/test/fast/molecules/remote_sources_test.rb`
- `ace-overseer/test/fast/molecules/session_environment_test.rb`
- `ace-overseer/test/fast/organisms/event_observation_test.rb`
- `ace-overseer/test/fast/organisms/lab_start_test.rb`
- `ace-overseer/test/fast/organisms/report_processor_test.rb`
- `ace-overseer/test/fast/organisms/start_orchestrator_test.rb`
- `ace-overseer/test/fast/organisms/work_on_orchestrator_test.rb`

Additional Herdr bridge files: `ace-herdr/lib/ace/herdr/organisms/dispatcher.rb`, `ace-herdr/lib/ace/herdr/molecules/herdr_executor.rb`, `ace-herdr/lib/ace/herdr/cli/commands/dispatch.rb`, `ace-herdr/lib/ace/herdr/molecules/installed_pi_extensions.rb`, and their affected tests. The native Rust patch/build is assigned separately.

## Monorepo failure reconciliation

The parent executed the deterministic monorepo suite and assigned its three remaining failures for investigation. Two Start CLI tests assumed the prior `exec` behavior. They now prove a real distinct child process receives the explicit environment, the caller resumes only afterward, auth is cleaned and transcript evidence retained. The real bare CLI test confirms original cwd and no Herdr invocation. `bin/ace-test ace-overseer test/fast/commands/start_command_test.rb`: **11 tests / 49 assertions / 0 failures**, report `overseer/8f3ee212-23f7-473b-958e-9614646a6c17`.

The unchanged origin/main Hermes test acknowledged only the first delivered item. New source-health markers are real additional revisions; their unacknowledged replay was correct behavior. The test now verifies exactly one target answered case, acknowledges the full handled batch and retains the unchanged-after-restart silence assertion. No Hermes production change. `bin/ace-test ace-hitl-hermes test/fast/organisms/native_sync_test.rb`: **12 tests / 79 assertions / 0 failures**, report `hitl-hermes/834bc3a2-f990-474e-96e7-d78beab7fb5d`.


## Real Pi SDK feature gate correction

Four real-SDK scripted cases had manually invoked scheduled observation without advancing their clock, so cadence enforcement correctly deferred acquisition. The cases now inject time and advance it by each configured scheduler interval. Their compaction, uncertain interception and busy/preflight assertions remain intact.

The fourth case additionally revealed that SDK command-context reload was an unbound no-op. The harness now binds actual `session.reload()`, exercising shutdown/replacement/start. Investigating the same-session path found a product defect: explicit resume retained the sent revision of an uncertain notification. `Eyes.resume` now clears delivery suppression only when explicitly reconciling `notification-unconfirmed`; confirmed deliveries remain suppressed. A new local regression proves no automatic retry, one retry after reconciliation and no repeat of confirmed work.

`bin/ace-test ace-handbook-integration-pi feat`: **13/13 scripted SDK cases**, Ruby wrapper **1 test / 6 assertions / 0 failures**, report `handbook-integration-pi/c0202546-1c90-4b10-99e6-66f8c2df7799`. `bin/ace-test ace-wake`: **2 wrapper tests / 7 assertions / 0 failures**, report `wake/2ecb73eb-5bb6-4f7b-bd77-431a77c950f2`. Neither invokes an external model or VM. Root independently reviewed the final correction and mixed-batch regression with no remaining blocker; sibling review also requested.

Independent parent review caught the initial overbroad reset: confirmed older pending batches must not be resent. The final fix records only the latest attempted delivery batch in ephemeral memory and releases its matching revisions. A mixed confirmed-A/uncertain-B regression proves only B is retried. Both reported targets were rerun after this correction.
