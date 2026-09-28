# Suite-context failure analysis (handoff from 8wq.t.1w4 delivery, 2026-09-28; revised 2026-09-29)

The 1w4 delivery ran the full `ace-test-suite` on its branch and on clean
`origin/main` (60b14b78a). The same failures reproduce on both, so they are
pre-existing and owned here (this is the 1w2 hermetic-environment consumer
fallout). Revised 2026-09-29 after reproduction probes against current main
(5fe35ce88): the ace-review item is fixed (e7986bff4), the "flaky" pair is
reclassified as deterministic, and the shared root cause is identified.

## Shared root cause (confirmed by probes)

`Ace::Support::Fs::Molecules::ProjectRootFinder` honors
`ENV["PROJECT_ROOT_PATH"]` before marker walking. In developer shells the
repo-root `mise.toml` injects `PROJECT_ROOT_PATH=/Users/mc/Ps/ace` (verified
via `printenv`), so standalone `ace-test` runs resolve the workspace root.
The suite's hermetic policy (`Models::EnvironmentPolicy.PRESERVED_KEYS`)
strips the variable, so children fall back to marker walking from the
package cwd — and stop at the package's own `Rakefile` (ace-assign has no
`.git`/`Gemfile`). Project root silently collapses to the package dir.

Reproduction: `ProjectRootFinder.find_or_current` returns
`/Users/mc/Ps/ace` ambient vs `/Users/mc/Ps/ace/ace-assign` under
`env -i HOME=<fixture>`; identical divergence inside
`SkillAssignSourceResolver` (`workflow_paths` collapses; configured
relative paths expand into `ace-assign/ace-task/...`).

## Per-failure decisions

### 1. ace-assign — 3 failures, 2 errors

- failure_identifier: `SkillAssignSourceResolver` discovery —
  `test_start_review_split_subtree_children_do_not_inherit_fork_context`
  (E), `test_create_task_mode_creates_assignment_and_step_files_end_to_end`
  (E), `test_add_batch_with_sub_steps_expands_parent_and_children` (F),
  `test_producers_of_pull_request` (F),
  `test_load_all_each_step_has_description` (F)
- category: test_defect (ambient `PROJECT_ROOT_PATH` dependence)
- evidence: hermetic probe collapses `workflow_paths` to
  `ace-assign/handbook/workflow-instructions`; error "Could not resolve
  workflow binding 'wfi://onboard'... Searched: <ace-assign dir only>";
  catalog canonical merge loses description/producers because
  `skill_paths` no longer reaches `ace-git/handbook/skills`
- fix_target: pin the workspace root deterministically in the package
  test_helper instead of inheriting mise-injected ambient state
- fix_target_layer: test (test_helper environment declaration)
- primary_candidate_files: `ace-assign/test/test_helper.rb`
- do_not_touch_boundaries: resolver/product code; EnvironmentPolicy
  preserved keys (must not re-add ambient coupling); no test deletions
- confidence: high (divergence reproduced under `env -i`)

### 2. ace-hitl — 3 errors (LabProviderTest)

- failure_identifier: `test_ask_creates_event_and_relay_request_and_persists_contract_fields`,
  `test_ask_title_defaults_to_question_and_effect_declared_is_persisted`,
  `test_store_failure_raises_provider_unavailable_with_orphan_event_id`
  (`NoMethodError: undefined method '[]' for nil` — `HitlManager#show`
  returns nil)
- category: test_defect (ambient worktree/config discovery; also leaks
  events into the real repo: fixture events `8wqfc*-ship-without-tests`,
  `-proceed-with-deploy`, `-orphaned` found in `/Users/mc/Ps/ace/.ace-local/hitl`)
- evidence: `Providers::Lab#build_manager` constructs `HitlManager.new`
  with no root; root resolution goes through `HitlConfigLoader.root_dir`
  → `ProjectRootFinder` (env-var stripped in suite → package dir), while
  the test's reading manager scans worktree-root-joined `.ace-local/hitl`
  roots. Standalone both sides agree on the repo root (masking the leak);
  in suite they diverge and `show` finds nothing.
- fix_target: inject a fully pinned manager (`root_dir:` tmp + absolute
  `config["hitl"]["root_dir"]` = tmp) into the provider and the reading
  managers so ask/create/show are tmp-only in every environment
- fix_target_layer: test (fixture injection via existing `manager:` seam)
- primary_candidate_files: `ace-hitl/test/fast/providers/lab_provider_test.rb`
- do_not_touch_boundaries: `Providers::Lab`, `HitlManager`,
  `WorktreeScopeResolver` product behavior; `make_store`/lifecycle fixtures
- confidence: high (leak observed on disk; nil-show reproduced in suite run)

### 3. ace-test-runner-e2e — 1 failure

- failure_identifier: `SkillPromptBuilderTest#test_cli_provider_resolves_role_references`
  (`role:e2e-runner should resolve to a CLI provider`)
- category: test_defect (ambient `PROJECT_ROOT_PATH` dependence)
- evidence: role mapping lives in the repo project config
  (`.ace/llm/config.yml:61`); resolution goes through the ace-llm config
  cascade → `ace-support-config` → `ProjectRootFinder`; suite child
  resolves project root as the package dir and never finds the repo
  `.ace/llm/config.yml`, so the role parses as invalid
- fix_target: pin `ENV["PROJECT_ROOT_PATH"]` to the workspace root in the
  package test_helper (sibling-lib unshifts already present there)
- fix_target_layer: test (test_helper environment declaration)
- primary_candidate_files: `ace-test-runner-e2e/test/test_helper.rb`
- do_not_touch_boundaries: `ProviderModelParser`, `SkillPromptBuilder`,
  ace-llm config cascade
- confidence: high

### 4. ace-support-markdown — 3 errors (load error)

- failure_identifier: all three test files abort at load:
  "You have already activated ace-support-cli 0.6.7, but your Gemfile
  requires ace-support-cli 0.6.8"
- category: test_infrastructure (bundler/setup in test_helper conflicts
  with gems the ace-test process already activated)
- evidence: workspace `ace-support-cli` is 0.6.8 (bumped, unpublished);
  only 0.6.7 is installed. The suite child boots `exe/ace-test`, whose own
  requires activate installed ace-support-cli 0.6.7; the package
  test_helper then runs `require "bundler/setup"`, whose lockfile
  (workspace, 0.6.8) rejects the activated spec. Reproduces standalone on
  current main (ace-test ace-support-markdown: 0 tests, smoke target
  fails) — the 2026-09-28 "flaky" classification is obsolete; the version
  skew moved in with the unpublished bumps.
- fix_target: remove `require "bundler/setup"` from the package
  test_helper (repo-standard helpers like ace-hitl/ace-herdr load without
  bundler); dependencies resolve via installed gems / own-lib unshift
- fix_target_layer: test infrastructure (test_helper)
- primary_candidate_files: `ace-support-markdown/test/test_helper.rb`
- do_not_touch_boundaries: root Gemfile/Gemfile.lock; gem versions; runner
  child invocation; no re-publishing of gems in this task
- confidence: high (skew verified on disk; error text names the mechanism)

### 5. ace-handbook-integration-pi — 1 error (load-time NameError)

- failure_identifier: `PiTest#test_loop_template_projects_through_handbook_sync` —
  `NameError: uninitialized constant Ace::Handbook::Organisms::PromptTemplateInventory`
- category: test_infrastructure (test depends on a workspace-only
  ace-handbook class while require resolves installed gems)
- evidence: `PromptTemplateInventory` exists in workspace
  `ace-handbook/lib` but the newest installed ace-handbook is 0.31.0,
  which lacks it; pi's test_helper unshifts only its own lib, so
  `require "ace/handbook/integration/pi"` activates installed
  ace-handbook and the constant is missing. Deterministic (not flaky).
- fix_target: unshift the workspace sibling lib following the ace-herdr
  test_helper pattern (`%w[ace-handbook]` + `Dir.exist?` guard) before the
  require
- fix_target_layer: test infrastructure (test_helper)
- primary_candidate_files: `ace-handbook-integration-pi/test/test_helper.rb`
- do_not_touch_boundaries: ace-handbook product code; gem versions;
  runner child invocation
- confidence: high (constant present in workspace, absent in installed
  0.31.0)

## Suggested sequencing

1. ace-support-markdown test_helper (unblocks load)
2. ace-handbook-integration-pi test_helper (unblocks load)
3. ace-assign test_helper env pin
4. ace-test-runner-e2e test_helper env pin
5. ace-hitl provider/manager injection
6. Verify: targeted failing tests → related packages → full
   `ace-test-suite` twice back-to-back

## Follow-ups (out of scope here)

- The published-gem release batch will shrink the workspace/installed
  skew, but the contract is that children must not depend on installed
  gem state at all; runner-level workspace-first LOAD_PATH is the
  longer-term direction and is deliberately not attempted here.
- Clean leaked fixture events from `.ace-local/hitl` (disposable scratch;
  left untouched by this task).
