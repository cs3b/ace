# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Aligned the remaining E2E sandbox bootstrap to copy repo-root setup assets from `ACE_E2E_SOURCE_ROOT` instead of sandbox `PROJECT_ROOT_PATH`.
- Updated `TS-ASSIGN-002` hierarchy E2E coverage to match the current CLI error contract and require real step-file metadata evidence for audit-trail checks.
- Updated `TS-ASSIGN-002` auto-completion coverage to use the current cross-assignment `finish --assignment <id>` contract instead of positional step targeting.
- Updated `TS-ASSIGN-002` renumbering coverage to capture a real descendant-cascade renumber event with explicit before/after subtree listings and grandchild metadata evidence.


### Fixed
- Updated `TS-ASSIGN-001` E2E expectations to match the current assignment lifecycle, fork-status output, bundled prepare fixture shape, and drive-policy evidence surface.

## [0.44.3] - 2026-04-07

### Fixed
- Added missing `Bash(ace-bundle:*)` permissions to internal helper skills that execute `ace-bundle` workflows (`as-create-retro-internal`, `as-mark-task-done-internal`, `as-reflect-and-refactor-internal`).
- Restored required canonical skill metadata headers (`# bundle`, `# agent`) for internal helper skills `as-create-retro-internal` and `as-reflect-and-refactor-internal`.
- Added source-based canonical step-definition fallback in assignment step materialization so custom-named steps with explicit `source` preserve canonical metadata.

### Technical
- Added regression coverage for custom-named explicit-source step materialization preserving canonical fork metadata.

## [0.44.2] - 2026-04-07

### Fixed
- Preserved project-level `.ace/assign/catalog/steps/*.step.yml` overrides when canonical skill metadata is present by applying project definitions after canonical merge in assignment step catalog resolution.
- Restored canonical step metadata in `CatalogLoader.load_all` results for migrated public steps so direct catalog consumers retain description/prerequisite/artifact semantics, while keeping raw-YAML opt-out support via `canonical_steps: false`.

## [0.44.1] - 2026-04-07

### Fixed
- Preserved canonical step-level `assign.steps` presentation fields (`name` and `description`) when resolving skill-backed step rendering.

### Technical
- Added required canonical metadata headers (`# bundle`, `# agent`) to internal helper skills `as-task-load-internal` and `as-mark-task-done-internal`.
- Added regression coverage for step-level description preservation in `SkillAssignSourceResolver`.

## [0.44.0] - 2026-04-07

### Changed
- Migrated helper-step ownership for `task-load`, `mark-task-done`, `reflect-and-refactor`, and `create-retro` from permanent `skill: null` templates to internal canonical helper skills.
- Migrated public step metadata ownership for `onboard`, `plan-task`, `work-on-task`, `review-pr`, `create-pr`, and `verify-test-suite` into canonical skill `assign.steps`, with public workflow binding resolved from `skill.execution.workflow` (legacy `assign.source` fallback retained).
- Normalized runtime execution and materialization paths around canonical step `source` (`skill://...` and explicit `wfi://...`) while preserving legacy `skill`/`workflow` compatibility as migration fallback.
- Updated shipped assign compose/create/prepare workflow docs to use source-first step contract examples.

### Fixed
- Restricted public assign-step discovery to canonical skills with `user-invocable: true`, preventing internal helper skills from appearing in public assignment composition inventory.

### Technical
- Added internal helper workflows and skills under `ace-assign/handbook` to preserve helper execution contracts while keeping them non-discoverable.
- Marked `pre-commit-review` and `verify-test` helper templates as explicit transitional exceptions with migration metadata.

## [0.42.4] - 2026-04-05

### Fixed
- Scoped canonical `skill://` and `wfi://` source discovery to in-project defaults and explicitly registered external sources so ambient installed gems no longer leak into assign resolution.
- Preserved child `skill` metadata only for hand-authored explicit split sub-steps while keeping inferred and preset-expanded canonical sub-steps fully materialized.

## [0.42.3] - 2026-04-02

### Changed
- Updated HITL guidance wording in `ace-assign status` and assignment workflow/docs to use canonical "event" terminology (`Review event`, `HITL event`).

### Technical
- Refreshed status command test expectations for the updated HITL wording contract.

## [0.42.2] - 2026-04-02

### Technical
- Updated HITL stall-path fixture expectations in status command coverage from `.ace-hitl/...` to `.ace-local/hitl/...` to match the new default HITL root.

## [0.42.1] - 2026-04-02

### Changed
- Updated `wfi://assign/drive` HITL guidance to use per-item polling (`ace-hitl wait <id>`) as the default requester path and `ace-hitl update --resume` as fallback dispatch.

### Fixed
- Updated `ace-assign status` HITL operator guidance output to display polling-first and fallback resume commands aligned with the current HITL contract.

### Technical
- Refreshed command-level status tests for the new HITL guidance text contract.

## [0.42.0] - 2026-04-01

### Changed
- Added a dedicated HITL stall protocol to `wfi://assign/drive`, documenting `ace-hitl` create/list/show/update usage, canonical `ace-assign fail --message "HITL: <id> <path>"` formatting, and resume/archive flow without reintroducing gate-state mechanics.

### Fixed
- `ace-assign status` now detects HITL-formatted stall reasons and prints direct operator guidance for `ace-hitl show <id>` plus stored-path hints.

### Technical
- Added command-level status coverage for HITL and non-HITL stall reason rendering to prevent regressions in current-step guidance output.

## [0.41.12] - 2026-04-01

### Fixed
- Restored parent-only fork boundaries for generated split subtrees by preventing child steps from inheriting fork context defaults when the parent step is the fork root.
- Removed default fork context declarations from canonical `plan-task`, `work-on-task`, and `review-pr` catalog steps so only explicitly fork-root parent steps run in forked context.

### Technical
- Added regression coverage for symbolized/string fork-context normalization in child-step materialization paths.

## [0.41.11] - 2026-04-01

### Fixed
- Restored parent-only fork semantics for split-subtree execution by preventing canonical child-step `context: fork` defaults from being materialized onto generated subtree children (notably `plan-task` and `work-on-task`).
- Updated workflow-backed child-step rendering to strip inherited fork context/provider metadata when the child did not explicitly declare fork settings.

### Technical
- Added regression coverage for split-subtree child materialization and scoped status output to ensure child `plan-task` does not emit fork-execution guidance.

## [0.41.10] - 2026-03-31

### Changed
- Role-based assignment execution defaults.

## [0.41.9] - 2026-03-31

### Changed
- Updated task archival commands to persist task-state transitions during workflow execution using `--gc`/`--git-commit` modes in terminal task completion steps.

## [0.41.8] - 2026-03-30

### Fixed
- Clarified the shipped `wfi://release/publish` workflow release contract so root changelog updates consistently include package versions and RubyGems propagation proof guidance.

## [0.41.7] - 2026-03-30

### Fixed
- Made the shipped `wfi://release/publish` workflow verify modified packages with package-scoped `ace-test` execution derived from the resolved release set.

## [0.41.6] - 2026-03-29

### Added
- Added a shipped generic `wfi://release/publish` workflow under `ace-assign` so `work-on-task` release steps have a default resolvable path in plain projects.

### Fixed
- Aligned `assign.source` `wfi://` resolution with registered/default nav workflow sources by removing implicit workspace workflow-directory fallback behavior.
- Added resolver coverage for project-level `wfi://` workflow overrides and for unregistered-workflow failure behavior.

## [0.41.5] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.41.4] - 2026-03-29

### Technical
- Added `when_to_skip` entry for unreleased-mode branches to the `squash-changelog` catalog step.

## [0.41.3] - 2026-03-29

### Changed
- Reused one resolved provider value in `ace-assign fork-run` for both runtime display and launcher execution flow.

### Technical
- Clarified inline documentation of intentional fork-context merge semantics in `AssignmentExecutor` (`=` overwrite for generated children, `||=` default-preserve for materialized explicit steps).

## [0.41.2] - 2026-03-29

### Fixed
- Updated scoped `ace-assign status` output (text and JSON `current_step`) to show the effective fork provider inherited from the scoped fork root when the active child has no local provider.
- Removed unreachable symbol-key provider fallback in `Step#fork_provider` now that fork options are normalized to string keys.

### Technical
- Added scoped status regression tests covering fork-provider display/serialization for fork-root scope (`@010`) with active child steps.
- Documented intentional fork-context propagation semantics in `AssignmentExecutor` (generated child-step overwrite vs explicit-step default-preserve behavior).

## [0.41.1] - 2026-03-29

### Fixed
- Preserved catalog `context.fork` provider overrides for explicit `skill`-backed step materialization so step-level fork provider precedence is applied correctly.
- Kept fork child-step behavior stable by avoiding implicit fork-context propagation from canonical metadata when children do not explicitly declare fork context.

### Technical
- Added regression coverage for explicit `skill` and explicit `workflow` materialization paths to ensure catalog fork overrides are retained.

## [0.41.0] - 2026-03-28

### Added
- Added per-step fork provider overrides via step frontmatter `fork.provider`.
- Added `fork_provider` exposure in `ace-assign status` current-step output and `--format json` payloads.

### Changed
- Updated `ace-assign fork-run` provider precedence to: CLI `--provider` > step `fork.provider` > config `execution.provider` > default.
- Extended skill/catalog step materialization to carry `context.fork` options into generated step metadata.

### Technical
- Added coverage for step model/parser/scanner fork-option round-trip, fork-run provider precedence, status serialization/display, and executor composition behavior.
- Updated usage and fork-context docs with `fork.provider` examples and precedence rules.

## [0.40.4] - 2026-03-29

### Fixed
- Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.40.3] - 2026-03-27

### Fixed
- Corrected `ace-assign add` documentation examples to match the mutually exclusive add-mode contract (`--yaml`, `--step`, or `--task`).
- Replaced invalid preset-step examples in docs with preset-backed step names that resolve under the current `--step` behavior.

## [0.40.2] - 2026-03-27

### Fixed
- Validated preset names before file resolution to block invalid path-like preset inputs.
- Added `ace-assign add --task` task-reference existence validation before mutating assignment queues.
- Corrected `ace-assign add --task` insertion semantics to honor `--child`; explicit `--after` without `--child` now inserts as a sibling.
- Added explicit preset-step resolver errors when presets define no usable `steps` array.

### Technical
- Added regression coverage for preset-name validation and empty-preset-step diagnostics.
- Added `add --task` coverage for task-ref validation and sibling insertion with `--after` when `--child` is not set.
- Added end-to-end CLI coverage for `ace-assign create --task` assignment and step-file materialization.

## [0.40.1] - 2026-03-27

### Fixed
- Updated task-driven preset guard checks to evaluate active resolved refs after terminal filtering, preventing false single-task preset rejections on mixed terminal/non-terminal inputs.
- Preserved parent refs during taskref expansion when all subtasks are terminal, preventing empty expansion results from valid parent-task inputs.
- Normalized `detect_batch_parent` fallback return behavior to preserve nil semantics when no batch parent is found.

### Technical
- Made hidden task-driven job specs use unique filenames to preserve assignment source-config provenance across repeated create flows.
- Updated command coverage for randomized hidden job filename generation.

## [0.40.0] - 2026-03-27

### Added
- Added flags-only `ace-assign create --task ...` support for preset-based assignment creation from task refs, including multi-task input.
- Added a shared `TaskAssignmentCreator` path so direct `create --task` and `ace-overseer` launch use the same preset expansion and hidden job generation behavior.

### Changed
- Replaced positional `ace-assign create CONFIG` with explicit `--yaml` and `--task` modes.
- Updated `work-on-task` task-child expansion so generated `work-on-{{item}}` roots include the full `task/work` sub-step sequence, including `pre-commit-review`, `release-minor`, and `create-retro`.
- Refreshed docs and workflow wording to use the explicit `ace-assign create --yaml ...` contract.

### Technical
- Added command coverage for create-mode validation and task-driven creation edge cases.
- Added `ace-task` as a runtime dependency for task-ref-based creation.

## [0.39.1] - 2026-03-27

### Fixed
- Updated the `as-assign-add-task` workflow and related docs to use the current `ace-assign add --yaml` contract instead of removed `--from` usage.
- Refreshed preset step insertion name resolution to re-read queue names between insertions, preventing stale iteration-name collisions when canonical expansion adds additional steps.
- Added debug-time warnings for unexpanded `{{token}}` placeholders in `--task` preset templates.

### Technical
- Added regression coverage for preset insertion name-refresh behavior across canonical subtree expansion.
- Added regression coverage for unexpanded template-token warnings in debug `--task` mode.
- Normalized `detect_batch_parent` return semantics to always return a string value.

## [0.39.0] - 2026-03-27

### Added
- Added preset-aware `ace-assign add --step <name[,name...]>` mode with exact-first and base-name fallback resolution.
- Added preset-aware `ace-assign add --task <ref>` mode using preset `expansion.child-template` with automatic batch-parent detection.
- Added new preset insertion support modules: `PresetLoader`, `PresetStepResolver`, and `PresetInferrer`.

### Changed
- Replaced legacy `ace-assign add` insertion contract with exactly one required mode: `--yaml`, `--step`, or `--task`.
- Renamed YAML file insertion flag from `--from` to canonical `--yaml`.
- Removed positional `name` insertion mode in favor of explicit `--step`.

### Technical
- Expanded command and atom/molecule test coverage for mode validation, preset loading, step resolution, auto-iteration naming, and preset inference fallback behavior.

## [0.38.3] - 2026-03-27

### Added
- Added `ace-assign add --from <file>` to insert multiple steps from YAML, including nested `sub_steps` expansion.
- Added the `as-assign-add-task` skill and `wfi://assign/add-task` workflow for guided subtree insertion.

### Fixed
- Prevalidated full `add_batch` trees before mutating assignment queues, preventing partial insertion when later batch entries are invalid.
- Normalized nested batch child-depth overflow handling by converting `StepNumbering` depth `ArgumentError` into `Ace::Assign::Error`.
- Routed workflow/skill/sub-step batch insertions through canonical subtree expansion and materialization.
- Reworded executor-level child insertion validation to domain language so non-CLI callers are not coupled to CLI flag syntax.
- Removed stale add-task child-step hardcoding drift by relying on workflow `assign.sub-steps` resolution at insertion time.

### Changed
- Extended assignment insertion execution with batch insertion support and frontmatter passthrough for inserted steps.
- Unified dynamic step default instructions under a single `AssignmentExecutor::DEFAULT_DYNAMIC_STEP_INSTRUCTIONS` source.
- Limited canonical batch expansion to explicit `workflow`, `skill`, or declared `sub_steps` inputs, preserving prior numbering behavior for plain flat batch inserts.
- Updated usage, getting-started, and handbook docs to cover the new `add --from` workflow.
- Updated `record-demo` step instructions to require diagnosis before skipping on failure — agents must check config, available fonts, and spike findings before reporting a non-blocking skip.
- Added `decision_notes.non_blocking_policy` to `record-demo` step catalog entry clarifying that "non-blocking" means "diagnose and retry before skipping," not "skip on first failure."

### Technical
- Expanded command and executor coverage for `--from` validation, child rebalance behavior, and metadata preservation.
- Added regression tests for batch insertion validation, depth overflow, and workflow-backed inserts.
- Renamed add-command local boolean flags to predicate-style names (`name_given`, `from_given`) for readability.

## [0.38.2] - 2026-03-26

### Changed
- Updated `work-on-task` prepare/create filtering guidance to treat terminal task statuses (`done`, `skipped`, `cancelled`) as filtered refs and abort all-terminal requests before assignment creation.
- Updated no-op messaging and edge-case language across prepare/create workflow instructions and usage docs to match the terminal-status contract.

### Technical
- Replaced fragile done-filter workflow contract assertions with stronger section-scoped terminal-contract checks.
- Moved the contract test into the standard `test/organisms/` bucket and removed the nonstandard `test/workflows/` location.

## [0.38.1] - 2026-03-26

### Technical
- Added regression coverage for `work-on-task` done-task filtering contracts, including mixed done/non-done handling, all-done no-op behavior, and create-flow no hidden-spec/`ace-assign create` guard assertions.

## [0.38.0] - 2026-03-26

### Added
- Added explicit done-task filtering rules to `assign/prepare` so `work-on-task` requests resolve refs first, skip `status: done` refs, continue mixed sets, and abort all-done sets before queue generation.
- Added `record-demo` step to the assignment step catalog for recording and attaching terminal demos to PRs.
- Added composition rules positioning `record-demo` between `push-to-remote` and `update-pr-desc`.
- Added `record-demo` to the `implement-with-pr` recipe as an optional step.

### Changed
- Updated `assign/create` workflow guidance so Path B respects filtered taskrefs from prepare and skips hidden-spec render/`ace-assign create` when all requested refs are already done.
- Updated usage docs with `work-on-task` prepare/create filtering behavior and no-assignment outcomes for all-done inputs.
- Updated `work-on-task` preset with step 145 (`record-demo`) that reads demo scenarios from task specs, validates with dry-run, and records with proper fixture/sandbox patterns.

## [0.37.0] - 2026-03-23

### Changed
- Rewrote README with step/substep terminology, real `ace-assign status` output example, ace-overseer onboarding path, and links to step catalog, presets, and composition rules.
- Replaced residual "phases" terminology with "steps" in docs/handbook.md, docs/getting-started.md, and e2e fixture directories.
- Fixed broken "See Also" links in docs/exit-codes.md pointing to non-existent README anchors.

### Technical
- Normalized code formatting across 40+ lib and test files via StandardRB autofix (style-only, no behavior changes).

## [0.36.13] - 2026-03-23

### Changed
- Refreshed `README.md` to the current package layout pattern with logo/badges header, compatibility line, quick links, and use-case-oriented overview content.
- Updated README skill inventory to include `as-assign-recover-fork` and aligned the footer to the canonical ACE package format.

## [0.36.12] - 2026-03-22

### Fixed
- Unified assignment preset naming to `work-on-task` by removing `work-on-tasks` from defaults and fixtures.
- Restored single-task shorthand support by normalizing `--taskref` inputs to `taskrefs` during preset validation/expansion.

### Changed
- Updated assign prepare workflow/skill docs and E2E fixture expectations to treat `work-on-task` as the single canonical preset for single-task and batch flows.

## [0.36.11] - 2026-03-22

### Fixed
- Restored the `ace-assign` default fork timeout to `1800` in `ace-assign/.ace-defaults/assign/config.yml`.

### Changed
- Realigned assignment default provider/timeout guidance in `.ace/assign/config.yml` with package defaults for this release cycle.

## [0.36.10] - 2026-03-22

### Changed
- Documented assignment config provider/timeout default tuning in release notes for `.ace/assign/config.yml` and `ace-assign/.ace-defaults/assign/config.yml`.
- Restored missing trailing newline in `handbook/workflow-instructions/assign/run-in-batches.wf.md`.

## [0.36.9] - 2026-03-22

### Changed
- Remove `mise exec --` wrapper from test fixture strings to match updated command invocation style.
- Clarified release notes for this version to include shipped assignment default config tuning in `.ace/assign/config.yml` and `ace-assign/.ace-defaults/assign/config.yml` (provider/timeout defaults).

## [0.36.8] - 2026-03-22

### Fixed
- Mark task completion flows to archive tasks as well in both single-task and batch presets.
- Load task-done updates through the canonical `wfi://task/update` workflow and ensure parent-task closure updates are archived.

## [0.36.7] - 2026-03-22

### Fixed
- `mark-task-done` step now checks and closes parent tasks when all children are done, preventing status drift in task hierarchies.

## [0.36.6] - 2026-03-22

### Changed
- Add `create-retro` as the final child step in review-cycle fork subtrees, ensuring each review cycle captures its own retrospective.
- Add ordering rules (`retro-after-release`, `retro-after-apply-feedback`) to composition rules.
- Declare `review-sessions` as consumed input for the `create-retro` step.

## [0.36.5] - 2026-03-22

### Technical
- Clarified release notes to document the intentional `codex:gpt@yolo` assignment default required for current Codex CLI compatibility.

## [0.36.4] - 2026-03-22

### Fixed
- Clarified that assignment execution remains on `codex:gpt@yolo` because the current Codex CLI cannot combine `--full-auto` with `--dangerously-bypass-approvals-and-sandbox`.

## [0.36.3] - 2026-03-22

### Fixed
- Clarified the documented assignment execution default after docs drift described it as `codex:codex@yolo` instead of the intentional `codex:gpt@yolo`.

## [0.36.2] - 2026-03-22

### Fixed
- Remove trailing empty lines in code blocks across documentation files.

## [0.36.1] - 2026-03-22

### Fixed
- Include `docs/**/*` in gemspec so documentation ships with the gem.
- Remove piped command example from usage guide to align with command-integrity contract.

## [0.36.0] - 2026-03-22

### Added
- Added tutorial-style `docs/getting-started.md` and `docs/handbook.md` for clearer onboarding and package workflow discovery
- Added `docs/demo/ace-assign-getting-started.tape` and `docs/demo/ace-assign-getting-started.gif` demo artifacts

### Changed
- Rewrote `README.md` as a concise landing page with value-first messaging and documentation links
- Refreshed `docs/usage.md` to align with current CLI commands, scoped assignment examples, and command-integrity guidance
- Updated gemspec summary/description text to match the new README tagline and positioning

## [0.35.1] - 2026-03-21

### Added
- `mark-tasks-done` step (number 155) in `work-on-tasks` preset to mark parent/umbrella tasks as done after all subtask forks complete

## [0.35.0] - 2026-03-21

### Added
- `create-retro` step in `work-on-task` and `work-on-tasks` presets to capture process learnings after each assignment

### Changed
- `verify-e2e` step now runs E2E tests with fix loops (up to 3 cycles) instead of only reviewing coverage; runs in forked context
- `update-pr-desc` step now runs in forked context to prevent context-pressure truncation of grouped-stats output

## [0.34.1] - 2026-03-18

### Changed
- Added `unit-coverage-reviewed` decision evidence to `TS-ASSIGN-001` and `TS-ASSIGN-002` E2E scenarios to map coverage against related unit tests.

## [0.34.0] - 2026-03-18

### Changed
- Renamed "phases" to "steps" throughout the assignment system: models, atoms, molecules, organisms, CLI commands, config, catalog, and all user-facing strings
- Renamed file extension from `.ph.md` to `.st.md` for step files
- Renamed catalog directory from `catalog/phases/` to `catalog/steps/` and files from `*.phase.yml` to `*.step.yml`
- Renamed YAML keys: `sub-phases` → `sub-steps`, `sub_phases` → `sub_steps`

### Fixed
- `AssignmentExecutor.start` now reads `config["steps"]` matching what `AssignmentLauncher.write_job_file` writes (was reading `config["phases"]`, causing "No phases defined in config" error)

## [0.33.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.33.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.32.4] - 2026-03-15

### Technical
- Optimized test suite I/O: reuse one tmpdir per test class instead of creating/destroying per test method (~176 → ~16 tmpdir cycles)
- Removed 2 unnecessary `sleep(0.1)` calls in assignment manager tests (200ms saved)
- Converted bare `Dir.mktmpdir` calls to shared class-level tmpdir in fork session launcher tests

## [0.32.3] - 2026-03-15

### Fixed
- Release step catalog entry now references `wfi://release/publish` workflow
- Review cycle release instructions in work-on-task and work-on-tasks presets now point to `ace-bundle wfi://release/publish`

### Changed
- Drive workflow batch continuation rule prevents driver from pausing between child fork-runs
- Drive workflow adds transient network failure retry guidance (wait 30s, re-fork once)

## [0.32.2] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.32.1] - 2026-03-13

### Fixed
- Rendered `verify-test-suite` and `verify-e2e` assignment steps now use assignment-safe step templates instead of persisting the full broad audit workflow bodies.
- Cleaned assignment overlay serialization so generated child steps no longer leak nested `Assignment-specific context` / `Task context` headers or malformed double bullets.

### Technical
- Preserved local assignment render metadata when canonical step catalog entries merge with workflow-backed skill metadata.
- Added regression coverage for step-template rendering and structural assignment-overlay cleanup.

## [0.32.0] - 2026-03-13

### Changed
- Switched generated assignment artifacts for public steps to use workflow-backed execution references instead of generated `skill:` step contracts.
- Restored assignment-specific orchestration overlays for `work-on-task` and `work-on-tasks` while keeping canonical workflow bodies as the reusable execution source.

### Technical
- Promoted `workflow` to a first-class parsed/runtime step field across assignment status, queue scanning, and step persistence.
- Updated assign resolver, executor, presets, and regression fixtures to materialize public steps from canonical workflow bodies with provenance metadata.

## [0.31.5] - 2026-03-13

### Technical
- Completed canonical assign skill catalog composition and workflow-backed step metadata wiring for public assignments.

## [0.31.4] - 2026-03-13

### Changed
- Updated canonical assign skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.31.3] - 2026-03-13

### Added
- Added pre-flight prerequisite validation to `TC-005-no-skip-policy` fixture setup so scenario runs verify required workflow and skill files exist before policy checks execute.

### Technical
- Hardened `TS-ASSIGN-001` fixture setup and verification flow by capturing pre-flight exit status and output artifacts.

## [0.31.2] - 2026-03-12

### Changed
- Updated the prepare-workflow E2E fixtures to use the current top-level `steps:` schema for single-task and batch workflows.
- Refreshed hierarchy E2E guidance to capture copied auto-completion reports and to use the current fixture layout under `fixtures/*/jobs/`.

## [0.31.1] - 2026-03-10

### Fixed
- Restored canonical skill resolution to honor nav source priority while preserving package-default fallback discovery for local monorepo workflows and tests.

### Changed
- Added a runtime dependency on `ace-support-nav` so assignment skill discovery shares the same source registry semantics as `skill://` navigation.

### Technical
- Replaced invalid shell-tool allowances in canonical assignment skills with repo-approved tooling metadata and expanded resolver regression coverage for override precedence.

## [0.31.0] - 2026-03-09

### Changed
- Switched `SkillAssignSourceResolver` defaults to canonical `skill-sources` discovery and removed hardcoded provider-tree fallback paths as the primary model.
- Updated assign defaults and compose workflow guidance to describe compatibility catalog entries as non-authoritative inputs.

### Technical
- Updated resolver and assignment executor regression fixtures to register canonical skill sources (`handbook/skills`) instead of relying on `.claude/skills` defaults.
- Clarified vision documentation that canonical skills live in package `handbook/skills` and provider trees are generated projections.

## [0.30.0] - 2026-03-09

### Added
- Added canonical workflow skills for assignment operations: `as-assign-compose`, `as-assign-create`, `as-assign-drive`, `as-assign-prepare`, and `as-assign-run-in-batches` under `handbook/skills/`.

### Changed
- Expanded `skill://` canonical discovery coverage for `ace-assign` beyond the initial single-skill seed.


## [0.29.0] - 2026-03-09

### Added
- Canonical skill resolution in `SkillAssignSourceResolver` with assign-capable filtering by `skill.kind` and `assign.source`
- Step catalog reordering in `AssignmentExecutor` to prioritize canonical assign-capable skills over compatibility bridge entries

## [0.28.0] - 2026-03-09

### Added
- Added `skill-sources` gem defaults registration at `.ace-defaults/nav/protocols/skill-sources/ace-assign.yml` so `skill://` can discover canonical `handbook/skills` entries from `ace-assign`.

## [0.27.0] - 2026-03-09

### Added
- Added canonical orchestration skill example at `handbook/skills/as-assign-start/SKILL.md` for typed skill taxonomy tracing.
- Restored `assign/start` as a legacy compatibility workflow binding for canonical orchestration skill discovery.

### Changed
- Added projected provider-facing `.agent/skills/as-assign-start/SKILL.md` entry for representative orchestration skill parity.

## [0.26.2] - 2026-03-08

### Changed
- Clarified batch-parallel scheduling in `assign/drive` and `assign/run-in-batches`: `max_parallel` is a rolling in-flight concurrency cap (slot refill), not a fixed wave size.
- Added explicit rolling scheduler-loop guidance for parallel batch execution in `assign/drive`.
- Added user-document tracking frontmatter to `ace-assign` user docs (`README.md`, `docs/usage.md`).

### Technical
- Added missing guide frontmatter to `handbook/guides/fork-context.g.md` so package docs are consistently tracked by `ace-docs`.


## [0.26.1] - 2026-03-08

### Fixed
- `fork-run` now marks scoped leaf fork roots as `in_progress` before launching, preventing pending-state drift that could trigger repeated self-delegation loops in batch child execution.
- Scoped `status` output no longer shows fork execution guidance for already-completed fork steps.

### Changed
- Updated `assign/drive` workflow delegation rules to explicitly prevent calling `fork-run` again when already operating inside the same scoped fork boundary.

### Technical
- Added regressions for leaf-root fork activation and scoped done-step status guidance behavior.

## [0.26.0] - 2026-03-08

### Added
- Added batch scheduling metadata (`batch_parent`, `parallel`, `max_parallel`, `fork_retry_limit`) to step parsing/model/status JSON so assignment drivers can orchestrate controlled fork fan-out.
- Added `--max-parallel` guidance to run-in-batches workflow/skill contracts with default parallel cap semantics.

### Fixed
- Corrected status `FORK` column semantics to reflect `context: fork` instead of child presence, preventing non-fork batch parents from being misinterpreted as fork targets.

### Changed
- Updated run-in-batches guidance so `--sequential` now preserves per-item fork execution while switching scheduler mode to sequential metadata.
- Updated drive workflow delegation guidance to use fork-context signals and document retry-then-stop behavior for parallel child failures.

## [0.25.1] - 2026-03-08

### Changed
- Removed the legacy `as-assign-start` compatibility skill entrypoint.

### Technical
- Removed the `assign/start` legacy compatibility workflow file and retained `assign/create` as the public creation flow.

## [0.25.0] - 2026-03-08

### Added
- Added phrase-intent metadata (`intent.phrases`) for core compose targets: `work-on-task`, `verify-test-suite`, `reorganize-commits`, `push-to-remote`, `create-pr`, and `update-pr-desc`.
- Added new compose-target steps `squash-changelog` and `rebase-with-main` with skill mappings to `as-docs-squash-changelog` and `as-git-rebase`.

### Changed
- Reworked `assign/create` workflow to support preset input, explicit step-list intent, freeform high-level intent, and job-file passthrough while preserving deterministic `ace-assign create FILE` runtime boundary.
- Reworked `assign/compose` workflow with deterministic phrase matching, explicit-intent precedence, and named hard-rule reorder explanations.
- Extended composition hard-ordering guidance with `squash-before-rebase`, `rebase-before-push`, and `rebase-before-update-pr`.

### Technical
- Added workflow-level guidance clarifying that skill-backed step expansion stays runtime-owned via `assign.source` during `ace-assign create`.

## [0.24.0] - 2026-03-08

### Added
- Added `codex` to the default `subtree.native_review_clients` allow-list so subtree pre-commit review can use native `/review` in Codex runtimes.

### Technical
- Updated assignment-executor skill-source regression fixtures to the current `wfi://task/work` resolution path and `ace-task` workflow layout.

## [0.23.1] - 2026-03-08

### Fixed
- Updated assignment release guidance so `release*` child steps consistently route through `/as-release`, including suffixed review-cycle release steps.

### Changed
- Updated release step, preset, and fixture instructions to describe coordinated multi-package releases and both package and root changelog updates.

## [0.23.0] - 2026-03-08

### Changed
- Remove hardcoded `providers.cli_args` config; use ace-llm `@preset` suffixes for provider permission flags
- Reframed the public assignment UX around `as-assign-create` + `as-assign-drive`, including explicit `--run` create-to-drive handoff guidance in the create workflow.
- Reclassified `as-assign-start` and `as-assign-prepare` as legacy/internal compatibility skills (`user-invocable: false`) so they are no longer presented as primary public entrypoints.

### Technical
- Updated `assign/start` workflow positioning and fixture usage comments to stop teaching prepare/start as the recommended public flow.
- Expanded task usage documentation for this slice with explicit create-only, create-then-drive, and advanced `ace-assign create FILE` scenarios plus `--run` edge handling notes.

## [0.22.7] - 2026-03-08

### Technical
- Stabilized create-command path-relativity test setup by pinning `PROJECT_ROOT_PATH` to the temp workspace and clearing `ProjectRootFinder` cache around the test.

## [0.22.6] - 2026-03-08

### Fixed
- Rebalanced active step selection after `add --child` when injecting under the currently active step so execution moves into the newly created child subtree.

### Technical
- Added `StepWriter#mark_pending` to clear runtime-only step state when demoting blocked active parents.
- Added regression coverage for active-step rebalance behavior in parent/child/grandchild injection flows and for the new pending-state writer helper.
- Hardened TS-ASSIGN-002 Goal 5 artifacts to require JSON status oracles for scoped and unscoped assertions, reducing false positives from report synthesis drift.

## [0.22.5] - 2026-03-07

### Technical
- Updated create-command path-relativity test setup to run from the temporary cache directory so `Created:` output remains relative when expected.

## [0.22.4] - 2026-03-07

### Technical
- **ace-assign v0.22.4**: Removed no-op release entries from package changelog history (`0.22.3`, `0.22.1`) and refactored a create-command path-relativity test to use the shared temporary cache helper.

## [0.22.2] - 2026-03-07

### Fixed
- Normalized `ace-assign create` output path formatting so `Created:` and `Created from hidden spec:` use the same display-path strategy.

### Technical
- Added regression coverage for relative create output formatting and legacy `steps/` source-config path preservation.

## [0.22.0] - 2026-03-07

### Added
- `ace-assign create` now reports hidden-spec provenance with `Created from hidden spec: ...` when source config is under `.ace-local/assign/jobs/`.
- Added create-command and assignment-executor coverage for hidden-spec path retention and provenance output.

### Changed
- Assignment source-config archiving now preserves existing `jobs/` paths (including hidden specs in `.ace-local/assign/jobs/`) and archives non-job source configs into `<task>/jobs/<assignment-id>-job.yml` instead of `steps/`.
- `assign/create` workflow and `as-assign-create` skill contract now document the tracer path `work-on-task --taskref <id>` with hidden-spec rendering and deterministic `ace-assign create FILE` handoff.

## [0.21.3] - 2026-03-07

### Technical
- Completed shine-cycle assignment release step for PR #241: review execution remained blocked by upstream provider broken-pipe errors, and apply-feedback confirmed no pending items to apply.

## [0.21.2] - 2026-03-07

### Technical
- Completed fit-cycle assignment release step for PR #241: review execution failed upstream with provider broken-pipe errors, and apply-feedback confirmed no pending items in session context.

## [0.21.1] - 2026-03-07

### Technical
- Completed valid-cycle feedback application pass for PR #241 and confirmed there were no pending medium+ review feedback items to apply before release.

## [0.21.0] - 2026-03-07

### Added
- New `pre-commit-review` step catalog entry for subtree task workflows, enabling native client review gate behavior before verification/release.
- New subtree review defaults in assign config: `pre_commit_review`, `pre_commit_review_provider`, `pre_commit_review_block`, and `native_review_clients`.

### Changed
- `task/work` workflow sub-step sequence now includes `pre-commit-review` between `work-on-task` and `verify-test`.
- Child step instruction generation now renders config-aware native review run/skip/block guidance for `pre-commit-review`.

## [0.20.1] - 2026-03-05

### Fixed
- `fork-run` stall detection now targets the in-progress step within the subtree (`in_progress_in_subtree`) instead of the global current step, preventing `stall_reason` from being written to the wrong step during parallel fork execution.
- Stall-reason clearing on successful rerun now skips steps that never had a `stall_reason`, avoiding unnecessary file I/O on every subtree step.

## [0.20.0] - 2026-03-05

### Added
- Provider-specific session detection fallback in `ForkSessionLauncher` — when a provider doesn't return a native `session_id`, scans local session storage via `SessionFinder` to detect the forked session by prompt matching.
- Session metadata file (`<root>-session.yml`) written for every fork run, capturing `session_id`, `provider`, `model`, and `completed_at` for traceability.
- Stall error messages now include `Session: <id>` when session metadata is available, enabling direct trace to agent session.

## [0.19.3] - 2026-03-05

### Technical
- Extracted `STALL_REASON_MAX = 2000` constant in `ForkRun` to replace magic number and serve as shared source of truth for production code and tests.
- Tightened truncation test assertion to pin exact expected output length rather than a loose upper bound.

## [0.19.2] - 2026-03-05

### Fixed
- Simplified Layer 1 last-message write in `ForkSessionLauncher` from check-then-write to a single read-based guard, reducing double file access and improving robustness.
- Multiline `stall_reason` values in `ace-assign status` output now display with indented continuation lines for readable terminal formatting.

### Technical
- Added `test_stall_reason_cleared_after_successful_rerun` regression test verifying `stall_reason` is cleared across all subtree steps after a successful rerun.

## [0.19.1] - 2026-03-05

### Fixed
- `read_last_message` now rescues `SystemCallError` to prevent I/O errors from masking the stall error message.
- Clear stale `stall_reason` from all subtree step files on successful fork-run completion, preventing misleading status after recovery.

### Technical
- Added comment in `ForkSessionLauncher` documenting the blocking assumption that makes the Layer 1 check-then-write pattern safe from concurrent writes.

## [0.19.0] - 2026-03-05

### Added
- Surface forked agent last message on stall: `fork-run` now reads the agent's last message from `<cache_dir>/sessions/<fork_root>-last-message.md` and includes it in the stall error output.
- `stall_reason` field added to Step model and frontmatter: persisted when a fork stall is detected, visible via `ace-assign status`.
- Two-layer last-message capture: `ForkSessionLauncher` writes `result[:text]` after session ends (Layer 1 for all providers); Codex gets timeout-resilient capture via `--output-last-message` (Layer 2).

## [0.18.2] - 2026-03-04

### Fixed
- Enforced single-active subtree invariants in fork execution paths: `fork-run` and scoped `advance` now reject multiple in-progress steps in the same subtree and reuse existing active subtree work instead of activating sibling steps.

### Changed
- QueueState now exposes `in_progress_steps` and `in_progress_in_subtree` helpers used by fork/scoped execution guards.

## [0.18.1] - 2026-03-04

### Changed
- Default assignment cache directory now uses `.ace-local/assign`.


## [0.18.0] - 2026-03-04

### Changed
- Normalize `providers.cli_args` values to arrays and support mixed string/array CLI argument merging in fork launcher.

## [0.17.3] - 2026-03-04

### Changed
- Convert review cycles in assignment presets and prepare fixtures to forked cycle-parent steps with `sub_steps: [review-pr, apply-feedback, release]` for valid/fit/shine cycles
- Align compose recipes to the forked review-cycle model and set default `review_cycles` to 3
- Update assign compose/prepare workflow instructions and examples to document forked review-cycle expansion semantics

## [0.17.2] - 2026-03-04

### Fixed
- Workflow instructions (create, drive, start) corrected to use `.ace-local/assign/` path (not `.ace-local/ace-assign/`)

## [0.17.1] - 2026-03-04

### Fixed
- README assignment storage path corrected to short-name convention (`.ace-local/assign/` not `.ace-local/ace-assign/`)

## [0.17.0] - 2026-03-04

### Changed
- Default cache directory migrated from `.cache/ace-assign` to `.ace-local/assign`

## [0.16.2] - 2026-03-04

### Changed
- Rename PR skill references in assignment defaults from `ace-git-create-pr` / `ace-git-update-pr-desc` to `ace-github-pr-create` / `ace-github-pr-update`
- Update PR skill references in assign workflows and E2E fixture presets to the new `ace-github-pr-*` naming convention

## [0.16.1] - 2026-03-04

### Fixed
- Correct `.agents/skills` typo to `.agent/skills` in default config and `SkillAssignSourceResolver` — skill discovery now uses the canonical provider-neutral path

## [0.16.0] - 2026-03-04

### Added
- New `onboard-base` catalog step — loads base project context via `ace-bundle project-base`
- New `task-load` catalog step — loads task behavioral spec via `ace-bundle task://<taskref>`
- Taskref placeholder substitution in catalog step descriptions — `<taskref>` in step descriptions is replaced with actual task reference during child instruction building

### Changed
- Default assignment presets updated to use ace-task

### Fixed
- Apply session 8q2 learnings to workflow and presets

### Technical
- Increase timeout for hierarchy E2E scenario

## [0.15.1] - 2026-03-01

### Added
- Fork-run crash recovery protocol in drive workflow — detection, commit partial work, progress report, inject recovery steps, re-fork pattern for partial completion scenarios

## [0.15.0] - 2026-02-28

### Added
- Add `verify-test-suite` step to `work-on-task` preset between `mark-task-done` and `verify-e2e` with profiling and performance budget enforcement
- Add `verify-test-suite` step (number 012) to `work-on-tasks` preset between batch-parent and `verify-e2e`
- Enrich `verify-test-suite` step catalog with structured steps: `run-package-tests`, `check-performance-budgets`, `fix-violations`, `run-suite`
- Add performance budget thresholds to step definition: atoms <50ms, molecules <100ms, integration <1s, full package <30s
- Move `verify-test-suite` from Optional to Core in compose workflow for "Implement + PR" and "Batch tasks" intents
- Add `verify-test-suite` inclusion guidance note to compose workflow Step Selection Guidelines

### Changed
- Strengthen `verify-test-suite` composition rule from `recommended` to `required` when assignment includes `work-on-task` or `fix-bug`

## [0.14.0] - 2026-02-28

### Added
- Add `verify-e2e` step to catalog: E2E coverage review and targeted scenario execution for modified packages
- Add `update-docs` step to catalog: public-facing documentation updates when CLI contracts or public APIs change
- Add `verify-e2e` and `update-docs` steps to `work-on-task` preset (between `mark-task-done` and `release-minor`, and between `release-minor` and `create-pr`)
- Add batch-level `verify-e2e` (step 015) and `update-docs` (step 025) to `work-on-tasks` preset
- Add ordering rules to `composition-rules.yml`: `e2e-before-release`, `update-docs-after-release`, `update-docs-before-pr`, `e2e-after-verify`
- Add conditional rule to suggest `verify-e2e` and `update-docs` when assignment touches CLI commands or public API
- Add `e2e-review-run-pair` and `docs-update-validate-pair` to composition pairs
- Update `compose.wf.md` Step Selection Guidelines table to include `verify-e2e` and `update-docs` in all relevant workflow intents with skip guidance

## [0.13.4] - 2026-02-26

### Fixed
- Restore scoped status filter compatibility by honoring legacy `filter` formats (`010.01` and `(assignment@)010.01`) while preserving explicit `--assignment` targeting precedence
- Restore scoped fork PID telemetry lines in `status` output (`Scoped Fork PID`, PID tree, and PID file path) when fork metadata exists

### Added
- Re-add explicit `--filter` option to `status` command for CLI-level backward compatibility
- Add regression coverage ensuring `assignment` target overrides `filter` when both are provided

## [0.13.3] - 2026-02-26

### Added
- Document `advance()` legacy bridge behavior with explanatory comment
- Add `start` and piped stdin examples to CLI `--help` output
- Add "Starting Work" section to `docs/usage.md` documenting sequential auto-advance, explicit `start`, and piped stdin

### Changed
- Use standard Keep a Changelog section headers (replace non-standard `Technical` with `Changed`)

## [0.13.2] - 2026-02-26

### Fixed
- Short-circuit stdin read in `finish` when `--report` file content is already present, preventing unnecessary I/O or blocking
- Narrow `rescue` in `read_stdin_if_piped` to `IOError, Errno::EBADF` instead of broad `StandardError`
- Validate `fork_root` existence in `find_target_step_for_start` consistently regardless of `step_number` presence

### Added
- Integration test for `finish` auto-advance and `start` conflict detection across sequential steps
- Test for `--report` file precedence over piped stdin when both are present

## [0.13.1] - 2026-02-26

### Fixed
- Raise `StepNotFoundError` in `start_step` and `finish_step` when `--assignment <id@root>` specifies a non-existent subtree root, preventing silent fallback to the global queue
- Use `ConfigNotFoundError` (exit 3) in `advance()` for missing report files, consistent with `finish` command behavior

### Added
- Add positive test cases for `start` and `finish` commands with explicit `step` argument targeting

## [0.13.0] - 2026-02-26

### Added
- Add `start` command for explicit step lifecycle control: `ace-assign start [STEP]`
- Add `finish` command replacing `report`: `ace-assign finish [STEP] --report <file>` or via piped stdin
- Support piped stdin as report source in `finish`, eliminating mandatory temp-file creation
- Enforce strict `start` conflict detection: fails when another step is already `in_progress`
- Add `start_step` and `finish_step` APIs to assignment executor for programmatic lifecycle control

### Changed
- Replace `ace-assign report` with `ace-assign finish --report <file>` across all docs and workflows
- Update `assign/create.wf.md` and `assign/drive.wf.md` to use `finish` command pattern
- Update `README.md`, `docs/usage.md`, and `docs/exit-codes.md` to reflect new command surface
- Deterministic report input precedence: `--report` file wins over stdin when both are present

### Removed
- Remove `report` command from CLI surface (replaced by `finish`)

### Changed
- Replace `report_command_test.rb` with `finish_command_test.rb` and `start_command_test.rb`
- Update e2e test runner docs in `ace-assign` and `ace-overseer` to use `finish` pattern

## [0.12.23] - 2026-02-26

### Fixed
- Anchor FORK column detection regex to CHILDREN pattern in `assign/drive` workflow, preventing false matches on step names containing 'yes'

## [0.12.22] - 2026-02-26

### Added
- Add explicit FORK column to status output showing "yes" for steps with children, making delegation signal unmissable
- Introduce adaptive recovery for failed subtrees with retry/fail-children strategies
- Introduce fork PID telemetry and scoped status filtering for subprocess tracking

### Changed
- Decouple assignment targeting from environment variables; rely on explicit `--assignment <id>` flags
- Enhance plan-task instructions for behavioral spec adherence
- Update `assign/drive` workflow to reference FORK column instead of subtle "Fork subtree detected" message

### Technical
- Add validation order to E2E test expectations
- Update E2E test runner and verifier configurations
- Add test for FORK column in status output

## [0.12.21] - 2026-02-25

### Changed
- Remove runtime assignment context coupling to `ACE_ASSIGN_ID` and `ACE_ASSIGN_FORK_ROOT`; assignment targeting now relies on explicit `--assignment <id>` and scoped `--assignment <id>@<step>` usage.
- Update `assign/drive` workflow and fork-context guide to use explicit assignment flags for subprocess delegation.

### Fixed
- Eliminate scoped report/status behavior that depended on mutable process environment, reducing cross-process/test leakage risk.

## [0.12.20] - 2026-02-25

### Changed
- Update generated `plan-task` step action instructions to require planning against behavioral spec sections, cover relevant operating modes, and report missing spec details in a `Behavioral Gaps` section

## [0.12.19] - 2026-02-24

### Fixed
- Apply assignment scope (`<id>@<step>`) during report execution by setting `ACE_ASSIGN_FORK_ROOT` for the report command, so child-step completions resolve in the correct subtree.

### Technical
- Harden TS-ASSIGN-002 hierarchy E2E runner/verifier instructions for scoped completion commands and scoped subtree status assertions.

## [0.12.18] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.12.17] - 2026-02-22

### Changed
- Migrate CLI to standard help pattern: register HelpCommand for `--help`/`-h`, simplify `start()` by removing DWIM default routing

## [0.12.16] - 2026-02-22

### Fixed
- Prevent fork subtree recursion by auto-scoping `status` command to `ACE_ASSIGN_FORK_ROOT` when set
- Mark first workable child step as `in_progress` before launching forked session in `fork-run`

## [0.12.15] - 2026-02-22

### Technical
- Update `ace-bundle project` → `ace-bundle load project` in README, fork-context guide, and test fixture

## [0.12.14] - 2026-02-22

### Added
- Subtree guard step in drive workflow — driver reviews all fork report files before continuing to next step
- Report review instruction in split-subtree-root step template for fork context

## [0.12.13] - 2026-02-22

### Added
- Background execution guidance for fork-run in drive workflow (10-30 min timeout handling)
- Timeout note in split-subtree-root step template for environments with bash limits

## [0.12.11] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.12.10] - 2026-02-21

### Technical
- Stabilize `TS-ASSIGN-004` by replacing live `fork-run` invocation with deterministic scoped `status --assignment <id>@<step>` assertions
- Rewrite `TS-ASSIGN-006` to deterministic preset-expansion verification using `Ace::Assign::Atoms::PresetExpander` (no chat-skill invocation dependency)
- Add prepare-workflow fixture presets (`work-on-task.yml`, `work-on-tasks.yml`) for reproducible E2E generation checks

## [0.12.9] - 2026-02-21

### Changed
- Migrate skill name references to colon-free convention (`ace_domain_action` format) for non-Claude Code agent compatibility
- Update catalog steps and presets with new skill name format
- Update workflow instructions with new skill invocation patterns

## [0.12.8] - 2026-02-21

### Added
- Verification instructions in `mark-task-done` step requiring status confirmation after `ace-taskflow task done`
- Subtree completion section in drive workflow requiring task status verification before reporting complete

## [0.12.7] - 2026-02-21

### Fixed
- Add `CACHE_BASE` env var support to `cache_dir` so E2E sandboxes resolve the correct cache path
- Graceful return in `advance()` when fork subtree is exhausted (prevents "No step currently in progress" error)
- Nil guard in `report` command when `advance()` returns `completed: nil` after subtree exhaustion

## [0.12.6] - 2026-02-21

### Technical
- Add E2E tests for prepare workflow (from preset and from informal instructions)
- Fix `ASSIGNMENT_DIR` lookup in injection/renumbering E2E tests to use dynamic directory discovery
- Reorganize TS-ASSIGN-003b fixtures: replace flat `job.yaml` with structured `steps/` directory

## [0.12.5] - 2026-02-20

### Technical
- Update slash command refs to use git namespace (ace:git-create-pr, ace:git-update-pr-desc)

## [0.12.4] - 2026-02-19

### Technical
- Namespace workflow instructions into domain-specific subdirectories with updated wfi:// protocol URIs
- Update skill name references to use namespaced ace:namespace-action format

## [0.12.3] - 2026-02-19

### Changed
- Added clarifying comments for `skill: null` and `context.default: null` in reflect-and-refactor step

## [0.12.2] - 2026-02-19

### Changed
- Clarified `reflect-after-verify` ordering note to distinguish baseline verify from post-refactor re-verify
- Consolidated duplicate conditional suggestions for `work-on-task` into single entry with per-step strength overrides

## [0.12.1] - 2026-02-19

### Fixed
- `reflect-verify-cycle` pair changed from `sequential` to `conditional` — prevents overriding optional strength of reflect-and-refactor
- Renamed `max_recursion` to `max_reruns` in replan config for clarity

## [0.12.0] - 2026-02-19

### Added
- New `reflect-and-refactor` step in catalog — analyzes implementation against ATOM principles and executes targeted refactoring before PR creation
- Composition rules for reflect-and-refactor: ordering (after verify, before mark-done/release/retro), pairs (verify cycle, fix cycle, replan cycle), and conditional suggestion
- `create-retro` step now consumes `findings-report` from reflect-and-refactor as recommended prerequisite
- `implement-with-pr` recipe updated to include optional reflect-and-refactor step after work-on-task

## [0.11.18] - 2026-02-19

### Changed
- Remove dead `print_fork_scope_guidance` method and duplicate `fork_scope_root` definition from status command

## [0.11.17] - 2026-02-17

### Fixed

- `assignment_state` now checks `completed` before `failed` — assignments where all steps are done/failed correctly report `:completed` instead of `:failed`

### Added

- `recently_active?` method on `QueueState` to detect stale in-progress steps (threshold: 1 hour)
- New `:stalled` assignment state for in-progress steps with no recent activity

## [0.11.16] - 2026-02-17

### Added

- `current_in_subtree` method on `QueueState` to find in-progress step within a subtree

### Fixed

- Fork root executor now checks for existing in-progress step in subtree before advancing to next workable step

## [0.11.15] - 2026-02-17

### Added
- New catalog step definition `split-subtree-root` for split parent/fork-root orchestration instructions (default template in `.ace-defaults/assign/catalog/steps/`)

### Changed
- Split parent steps with `sub_steps` now materialize as orchestration-only subtree roots:
  - parent `skill` is removed to avoid duplicate execution semantics
  - parent keeps `source_skill` metadata for traceability
  - parent instructions are rendered from catalog template (project-overridable)
- Step catalog resolution now merges project overrides with default catalog by step name, so projects can override a single step definition without replacing the entire catalog

### Fixed
- Fork root parent steps no longer instruct direct `work-on-task` execution and now clearly drive subtree delegation/execution (`fork-run` + `assign-drive`) through child steps

## [0.11.14] - 2026-02-17

### Fixed
- Scoped status rendering for nested roots (for example `--assignment <id>@010.01`) now prints the subtree hierarchy correctly instead of collapsing to an empty queue section
- Runtime-expanded child steps now use explicit `taskref` metadata (when present) for deterministic task context, and preserve it in child step frontmatter
- Fork session launcher now loads `ace/llm` so `fork-run` handles provider errors without crashing on uninitialized LLM error constants

### Changed
- Preset expansion now substitutes placeholders across all step fields (including nested metadata), not only `name` and `instructions`

## [0.11.13] - 2026-02-17

### Fixed
- Scoped status (`--assignment <id>@<step>`) now selects the actionable step within the subtree instead of always reporting the scope root as current
- Runtime sub-step expansion now generates step-specific action instructions per child step and keeps parent goals as a verification checklist (instead of copy-pasting orchestration text into every child)

## [0.11.12] - 2026-02-17

### Added
- E2E regression scenario `TS-ASSIGN-005-no-skip-policy` to enforce hard no-skip drive policy and keep `ace:assign-drive` skill thin

### Changed
- `drive-assignment` workflow now enforces hard no-skip execution for planned steps and removes skip-assessment behavior
- Added required attempt-first failure evidence (command + exact error) and post-report/fail status transition verification in drive workflow

## [0.11.11] - 2026-02-17

### Changed
- `drive-assignment` workflow now auto-delegates detected fork-enabled subtrees via `ace-assign fork-run --assignment <id>@<root>` before inline step execution
- Fork context guide now documents the runtime delegation path where parent drive sessions detect subtree roots and delegate scoped execution with `fork-run`

## [0.11.10] - 2026-02-17

### Changed
- Use `Atoms::NumberGenerator.subtask` for sub-step numbering in runtime expansion to keep numbering logic centralized
- Tree formatter state labels now explicitly include `pending` and `in_progress`

### Fixed
- Added coverage for fork-scoped advancement when global current step is outside scoped subtree
- Added stable tests for CLI provider env propagation and query-interface sandbox propagation

## [0.11.9] - 2026-02-17

### Added
- Regression coverage for fork-scoped advancement when global current step is outside the scoped subtree

### Changed
- `ace-assign status` now prints explicit `Current Status: <status>` for easier machine parsing and E2E assertions

### Fixed
- Fork-scoped report advancement now selects and completes the next in-subtree step instead of completing an out-of-scope global current step
- E2E assertions for `parent` frontmatter now accept both single-quoted and double-quoted YAML scalars to avoid formatting-only false negatives

## [0.11.8] - 2026-02-17

### Added
- Shared assignment target parser for CLI commands with scoped syntax support: `--assignment <id>@<step>`
- New command tests covering assignment target parsing and scoped subtree execution behavior
- New E2E scenario scaffold for fork subtree scope isolation verification (`TS-ASSIGN-004`)

### Changed
- Assignment-targeting commands (`status`, `report`, `fail`, `add`, `retry`, `fork-run`) now use a shared target resolver
- `ace-assign fork-run` accepts subtree root from scoped assignment target (`<id>@<step>`) and validates conflicts with `--root`
- Scoped status output (`--assignment <id>@<step>`) now renders only the selected node subtree and uses the scope root as displayed current step

### Fixed
- Removed global current-step coupling in `fork-run` so subtree execution can start from any explicitly scoped root node

## [0.11.7] - 2026-02-17

### Added
- `ForkSessionLauncher` molecule to execute forked subtree sessions synchronously via `ace-llm` (`/ace:assign-drive`)
- Fork execution config defaults under assign namespace:
  - `execution.provider`, `execution.timeout`
  - `providers.cli`, `providers.cli_args`

### Changed
- `ace-assign fork-run` now launches provider sessions directly (blocking) instead of printing shell instructions
- `fork-run` supports `--provider`, `--cli-args`, and `--timeout` overrides
- Post-launch validation enforces subtree outcome: complete (success), failed/incomplete (error)

### Technical
- Add `ace-llm` runtime dependency for provider-driven fork execution
- Add command and molecule tests for launcher integration and fork-run completion/error paths

## [0.11.6] - 2026-02-17

### Added
- `ace-assign fork-run` command to initialize subtree-scoped fork execution using `ACE_ASSIGN_ID` and `ACE_ASSIGN_FORK_ROOT`
- Subtree scope helpers in queue state (`in_subtree?`, `subtree_steps`, `subtree_complete?`, `next_workable_in_subtree`, `nearest_fork_ancestor`)

### Changed
- Status output now detects forked ancestor scope and guides operators to run `fork-run` for whole-subtree delegation
- Report output now distinguishes subtree completion from full assignment completion when fork scope is active
- Fork context guide and workflow docs updated for explicit parent-only fork semantics and subtree execution model

### Fixed
- Split-substep expansion no longer writes `context: fork` on child steps (`onboard`, `plan-task`, `work-on-task`) when parent is forked
- Queue advancement in fork scope now stays inside `ACE_ASSIGN_FORK_ROOT` subtree and does not leak into sibling steps

## [0.11.5] - 2026-02-17

### Fixed
- Ensure runtime-expanded sub-steps are concrete and executable by materializing catalog metadata (skill, step focus) instead of generic placeholder instructions
- Preserve task context during sub-step expansion so child steps receive parent task instructions for deterministic parameter extraction
- Start assignments on the first workable leaf step (not parent container steps), preventing blocked progression in parent-child trees
- Use a single fork entrypoint for forked sub-step subtrees (first child), avoiding nested fork-per-child behavior

## [0.11.4] - 2026-02-17

### Changed
- Clarify assignment responsibility boundaries in workflow docs:
  - `compose-assignment` is catalog-only and no longer models source/frontmatter ingestion
  - `start-assignment` explicitly distinguishes catalog composition vs deterministic prepare/runtime expansion
  - `prepare-assignment` explicitly documents runtime metadata expansion as the canonical path
- Update assignment skills metadata to reflect compose/prepare boundary semantics

## [0.11.3] - 2026-02-17

### Added
- `SkillAssignSourceResolver` molecule to resolve skill frontmatter `assign.source` URIs (currently `wfi://...`) into workflow assignment metadata
- Default config paths for skill/workflow discovery:
  - `skill_source_paths`: `.agents/skills`, `.claude/skills`
  - `workflow_source_paths`: `ace-taskflow/handbook/workflow-instructions`, `ace-assign/handbook/workflow-instructions`

### Changed
- `AssignmentExecutor.start` now enriches steps with skill-declared workflow `assign.sub-steps` before expansion, enabling deterministic runtime sub-step materialization without compose-specific wiring
- `compose-assignment` workflow is now catalog-only and no longer documents source/frontmatter-driven step composition

## [0.11.2] - 2026-02-16

### Technical
- Add test cases for new composition ordering rules (`onboard-before-plan`, `plan-before-implementation`) and conditional `plan-task` suggestion

## [0.11.1] - 2026-02-16

### Fixed
- Consolidate duplicate conditional trigger for work-on-task in composition-rules

## [0.11.0] - 2026-02-16

### Added
- JIT plan-task step in implement-with-pr and implement-simple recipes (optional, between onboard and work-on-task)
- Composition rules: `onboard-before-plan` and `plan-before-implementation` ordering
- Conditional suggestion: recommend plan-task when work-on-task is included

### Changed
- plan-task step catalog entry: produces `[implementation-plan]` only (removed `task-spec`), consumes `[project-context, task-spec]`

## [0.10.2] - 2026-02-16

### Changed
- Rename review cycle steps by type: `review-cycle-1` → `review-valid-1`, `review-cycle-2` → `review-fit-1` (with matching apply/release steps)
- Add shine review cycle (`review-shine-1`, `apply-shine-1`, `release-shine-1`) to `work-on-task` and `work-on-tasks` presets
- Update `default_count` from 2 to 3 in composition rules to reflect three review types (valid, fit, shine)
- Renumber post-review steps: reorganize-commits → 130, push-to-remote → 140, update-pr-desc → 150

## [0.10.1] - 2026-02-16

### Added
- **Preset progression**: `preset_progression` mapping in composition rules (cycle 1→`code-valid`, 2→`code-fit`, 3→`code-shine`)

### Changed
- Review cycle presets in `work-on-task.yml` and `work-on-tasks.yml` now use step-specific presets instead of `code-deep`
- Updated `implement-with-pr.recipe.yml` to reference `preset_progression` from composition rules
- Updated `compose-assignment.wf.md` with preset progression documentation and examples

## [0.9.3] - 2026-02-15

### Fixed
- **AssignFrontmatterParser**: Validate that hint `include`/`skip` values are strings (rejects non-string types with descriptive error)

## [0.9.2] - 2026-02-14

### Fixed

- Frontmatter parser now rejects hints with both `include` and `skip` (mutual exclusivity validation)

## [0.9.1] - 2026-02-14

### Fixed

- Tree formatter now correctly handles child-before-parent input ordering (two-pass index build)
- Added regression test for unordered tree formatter input

## [0.9.0] - 2026-02-15

### Added

- Declarative assignment frontmatter: `assign:` block in `.s.md` and `.wf.md` files declares assignment intent (goal, variables, hints, sub-steps, context, parent)
- `AssignFrontmatterParser` atom for extracting and validating `assign:` frontmatter blocks
- `TreeFormatter` atom for rendering assignment hierarchy as indented tree with Unicode connectors
- Parent-child assignment linking via `parent` field in Assignment model
- `ace-assign list --tree` option for hierarchical assignment view
- Sub-step fork enforcement in executor: steps with sub-steps create batch parent in fork context
- Compose workflow integration: step 0 reads `assign:` frontmatter as structured input
- `documentation.recipe.yml` for documentation workflows with research step
- `release-only.recipe.yml` for version bump workflows without code changes
- `work-on-docs.yml` preset exposing documentation workflow
- `release-only.yml` preset exposing release-only workflow
- `quick-implement.yml` preset for simple task implementation
- `fix-bug.yml` preset for bug fix with review workflow

### Changed

- Update timestamp dependency from `ace-support-timestamp` to `ace-b36ts`

## [0.8.3] - 2026-02-14

### Added

- New `mark-task-done` step for marking tasks as done in ace-taskflow after implementation
- Composition rule to order `mark-task-done` after `work-on-task`
- Conditional rule suggesting `mark-task-done` when assignment includes `work-on-task`
- `mark-task-done` step in `work-on-task` preset (runs `ace-taskflow task done`)
- Mark-done instruction in `work-on-tasks` child template for per-task completion
- `mark-task-done` step in `implement-with-pr`, `implement-simple`, and `fix-and-review` recipes

## [0.8.2] - 2026-02-13

### Fixed

- `list` command now shows filtered count context (e.g., `1/2 assignment(s) shown`) when completed assignments are hidden

## [0.8.1] - 2026-02-13

### Added

- Tests for `--assignment` flag targeting on `add`, `fail`, `report`, and `retry` commands
- Performance documentation note on `AssignmentDiscoverer#find_all`

### Fixed

- Null safety for `info.name` in `list` command table output

## [0.8.0] - 2026-02-13

### Added

- Multi-assignment support with `.current` symlink for explicit assignment selection
- `ace-assign list` command with table/JSON output, `--task` filter, and `--all` flag
- `ace-assign select <id>` command for switching active assignment
- `AssignmentInfo` model wrapping assignment with computed state and progress
- `AssignmentDiscoverer` molecule for finding and filtering assignments
- `--assignment` flag on `status`, `report`, `fail`, `add`, and `retry` commands
- `ACE_ASSIGN_ID` environment variable for workflow context propagation
- Assignment state computation: running, paused, completed, failed
- Other assignments section in `status` output
- Context propagation and multi-assignment management documentation in drive-assignment workflow

## [0.7.5] - 2026-02-13

### Fixed

- Misplaced doc block: `check_pair_completeness` documentation was above `check_conditional_rule`
- Duplicate examples in `prepare-assignment.wf.md` now accurately reflect renamed `work-on-task` preset
- `CatalogLoader.parse_step_file` now warns on stderr when a step YAML file fails to parse (was silently returning nil)
- `compose-assignment.wf.md` uses Read/Glob tool references instead of `cat`/`ls` per project conventions

### Changed

- Added inline documentation for prefix matching constraints in `find_step_index`
- Added comment clarifying that mixed "and"/"or" conjunctions are not supported in conditional rules

## [0.7.4] - 2026-02-13

### Added

- New step catalog entries: `push-to-remote`, `release`, `reorganize-commits`

### Fixed

- Missing `skill: ace:apply-feedback` in work-on-tasks preset apply-feedback steps
- Ordering rules now match suffixed step names via prefix matching (e.g., `release` matches `release-minor`, `release-patch-1`)
- Conditional composition rules with "and" conjunction now correctly require all conditions (was using `any?` instead of `all?`)

### Changed

- Renamed `work-on-task-with-pr` preset to `work-on-task` (now the default/primary workflow)
- Updated workflow documentation to reflect preset rename

## [0.7.3] - 2026-02-13

### Added

- **Step catalog system**: Registry of available step types with prerequisites, produces/consumes, context defaults, and skip conditions (14 step definitions)
- **Composition rules**: Declarative ordering constraints, step pairs, and conditional suggestions for intelligent assignment composition
- **Recipe system**: Flexible example patterns replacing rigid presets (4 recipes: implement-with-pr, implement-simple, batch-tasks, fix-and-review)
- **Compose-assignment workflow**: LLM-driven assignment composition from step catalog and user intent
- `CatalogLoader` atom for loading and querying step catalog YAML files
- `CompositionRules` atom for loading, validating ordering, and suggesting step additions
- Conditional composition rule logic in `suggest_additions` for context-dependent step suggestions

### Changed

- Drive-assignment workflow now includes step decision points for skip assessment and adaptation
- Start-assignment workflow updated to offer compose as alternative path

### Fixed

- `apply-feedback.step.yml` now correctly references `ace:apply-feedback` skill (was null)

## [0.7.2] - 2026-02-12

### Changed

- E2E tests renamed from COWORKER to ASSIGN terminology
- All test references updated: coworker → assign, session → assignment, step → step, jobs → steps

## [0.7.1] - 2026-02-11

### Fixed

- E2E test scenario.yml files now use correct `test-id` field (was `test-suite-id`)
- E2E test case .tc.md files now use correct `tc-id` field (was `test-id`)

## [0.7.0] - 2026-02-11

### Fixed

- Array instruction substitution in foreach expansion now properly handles {{item}} placeholders
- Removed deprecated work-on-task preset (use `/ace:work-on-task` skill directly)

### Changed

- work-on-tasks preset simplified with onboard step and direct skill delegation

## [0.6.0] - 2026-02-11

### Changed

- Package renamed from ace-coworker to ace-assign
- Internal "session" concept renamed to "assignment"
- Internal "step" concept renamed to "step"
- Step file extension changed from .j.md to .st.md
- Cache directory changed from .cache/ace-coworker/ to .cache/ace-assign/
- Skills renamed from /ace:coworker-* to /ace:assign-*
- New combined /ace:assign-start skill added (prepare + create in one step)

## [0.5.3] - 2026-02-01

### Changed

- Removed `prepare` CLI command - use `/ace:assign-prepare` workflow instead (handles informal instructions and customizations)

## [0.5.2] - 2026-01-31

### Fixed

- `prepare` CLI now uses Base36 timestamps (e.g., `8ouxjt`) instead of datetime format
- `prepare` CLI now outputs step files to task's `steps/` folder (e.g., `.ace-taskflow/v.0.9.0/tasks/253-xxx/steps/`) when task refs provided
- Correctly extracts parent task ID from subtask refs (e.g., `253.01` -> task folder `253-xxx`)

## [0.5.1] - 2026-01-31

### Fixed

- `prepare` CLI command now actually works - implements preset loading, parameter parsing, and job.yaml generation (was just a stub in 0.5.0)

## [0.5.0] - 2026-01-31

### Added

- **Multi-task step preparation**: New `work-on-tasks` preset enables batch processing of multiple tasks in a single job
- `PresetExpander` atom for expanding preset templates with `expansion:` directives
- Support for `batch-parent` and `foreach` expansion directives in presets
- Array parameter parsing supporting comma-separated (`148,149,150`), range (`148-152`), and pattern (`240.*`) syntax
- Pre-assigned step numbers in job.yaml are now preserved by AssignmentExecutor
- Updated prepare-assignment workflow documentation with multi-task examples

### Fixed

- CLI help commands now return exit code 0 correctly

## [0.4.3] - 2026-01-30

### Changed

- Rewrote MT-ASSIGN-003 E2E test to match implemented behavior (dynamic hierarchy via `add --after --child` instead of static config)

### Technical

- MT-ASSIGN-003 test verified and stamped

## [0.4.2] - 2026-01-30

### Fixed

- MAX_DEPTH constant corrected to 2 (allowing 3 levels max: 010.01.01) to match documented behavior
- CLI `add --child` command now validates depth upfront with clear error message before calling executor

### Changed

- `auto_complete_parents` now emits warning when safety iteration limit is reached
- `rollback_renames` now captures and reports rollback failures instead of silently swallowing them

## [0.4.1] - 2026-01-30

### Changed

- `Ace::Assign.cache_dir` now returns an absolute path resolved from project root
- Cache directory respects `PROJECT_ROOT_PATH` environment variable for sandboxed/isolated testing

## [0.4.0] - 2026-01-30

### Added

- **Hierarchical step structure**: Steps can now have nested sub-steps (010.01, 010.02) with parent-child relationships
- New `StepNumbering` atom for parsing and generating hierarchical step numbers
- `--after` option for `add` command: inject steps after specific step numbers (`ace-assign add verify --after 010`)
- `--child` option for `add` command: create nested child steps (`ace-assign add verify --after 010 --child`)
- `--flat` option for `status` command: show flat list without hierarchy indentation
- Automatic step renumbering when inserting steps at occupied positions
- `children_of`, `descendants_of`, `has_incomplete_children?` methods on QueueState for hierarchy traversal
- `hierarchical` method on QueueState for tree-structured display
- Parent number extraction from filenames in `StepFileParser.parse_filename`
- Audit trail metadata: `added_by`, `parent`, `renumbered_from`, `renumbered_at` fields for tracking step history
- O(1) child lookups via parent index in QueueState for improved performance

### Changed

- Auto-complete parents now handles multi-level hierarchies in a single pass (grandparents complete when parents complete)
- Auto-complete now includes in_progress parents (not just pending) when all children finish
- Status command now shows hierarchical structure when nested steps exist
- Advance operation respects hierarchy: parent steps wait for all children to complete

### Fixed

- Cascade renumbering to descendants: when a step is shifted, all its children are also renamed to prevent orphaning
- Enforce hierarchy in `advance`: prevent marking parent as done while children are incomplete
- Validate `--after` step existence before injection (raises StepNotFoundError if not found)
- Replace fragile `instance_variable_set` mutation with local tracking Set in auto_complete_parents
- Add safety guard to prevent infinite loops in auto-completion (max iterations = step count)
- Re-scan state after auto_complete_parents to ensure find_next_step uses fresh data
- Use `next_workable` instead of `next_pending` in find_next_step to respect hierarchy
- QueueState now supports `top_level`, `all_numbers`, and `next_workable` methods

## [0.3.1] - 2026-01-30

### Fixed

- Step files already in a `steps/` directory are kept in place instead of being moved to a nested path when creating assignments

## [0.3.0] - 2026-01-30

### Added

- **Fork context support for steps**: Enable step files to declare `context: fork` in frontmatter to run steps in isolated agent contexts via Claude Code's Task tool
- New `context` field in Step model with `fork?` predicate method
- Context validation rejecting invalid values with helpful error messages (valid values: `fork`)
- `handbook/guides/fork-context.g.md` documentation for the fork context feature
- Status command outputs Task tool instructions for fork-context steps
- Shell escaping for step names in Task tool description field
- E2E test (TC-005) for fork context feature validation

### Changed

- Centralized `VALID_CONTEXTS` constant in Step model, referenced by parser
- QueueScanner surfaces ArgumentError for invalid step files instead of silent nil return
- Status output uses plain text separators instead of markdown backticks for better terminal compatibility
- Use deterministic project root from cache_dir instead of Dir.pwd
- Updated `work-on-task` preset to demonstrate fork pattern

## [0.2.1] - 2026-01-29

### Fixed

- Cache directory initialization bug where `.cache/ace-assign/` was never created before `generate_assignment_id` called `Dir.mkdir()`, causing `Errno::ENOENT` crash on first use

### Added

- CLI exit codes documentation (`docs/exit-codes.md`) documenting exit codes 0-3 with meanings and examples

### Changed

- Updated E2E test TC-004 to reflect actual `start` command behavior (migration alias to `create` with deprecation warning, exit 0)
- Added TC-004b test case to verify cache directory auto-creation on first use
- Added cache directory setup to E2E test environment setup to prevent ENOENT errors on first-time runs

## [0.1.7] - 2026-01-28

### Fixed

- CLI exit code wrapper propagation via `@captured_exit_code` and `wrap_command` method
- Race condition in `append_report` file locking: rewrite content in-place on locked file descriptor instead of temp file + rename (preserves POSIX locks)
- Assignment ID generation max retry limit (100 attempts) to prevent infinite loop
- E2E test comment: "creates separate .r.md report file" (was "appends report inline")

### Added

- Prepare command stub with helpful message directing users to create job.yaml manually or use the prepare-assignment workflow

### Changed

- Improve error messages with actionable suggestions (e.g., "Try 'ace-assign add' or 'ace-assign retry'")
- Migration UX for deprecated commands (start → create) with warning message

## [0.1.6] - 2026-01-28

### Changed

- Split `assignment.wf.md` into focused workflows: `create-assignment.wf.md` (assignment creation) and `drive-assignment.wf.md` (execution loop)
- Renamed `prepare-assignment-job.wf.md` → `prepare-assignment.wf.md` for verb-first naming convention
- Renamed skill `ace_assign-start` → `ace_assign-drive` for clarity
- All assign skills now use thin wrapper pattern pointing to workflows via `ace-bundle`

### Technical

- Fixed file extension documentation: `*.md` → `*.st.md` for step files in create-assignment workflow
- Clarified "source of truth" is `ace-assign status` command in workflow documentation
- Added note about archived job.yaml being for provenance only, not status queries
- Changed "Job files" → "Step files" terminology in README for clarity

## [0.1.5] - 2026-01-28

### Added

- Separate step and report files with `.st.md` and `.r.md` extensions
- New `reports/` directory structure for storing completion reports separately from step files
- Report files include YAML frontmatter with `step`, `name`, and `completed_at` fields for traceability

### Changed

- Step files now use `.st.md` extension (was `.md`)
- Reports are written to separate `.r.md` files instead of being embedded in step bodies
- `StepFileParser.extract_fields()` now returns `nil` for report (loaded separately)
- `StepFileParser.parse_filename()` handles both `.st.md` and `.r.md` extensions
- `StepFileParser.generate_filename()` produces `.st.md` filenames
- `StepFileParser.generate_report_filename()` produces `.r.md` filenames
- `StepSorter.sort_key()` strips `.st.md` extension
- `QueueScanner.scan()` and `step_numbers()` glob for `*.st.md` files
- `QueueScanner.load_report()` loads report content from corresponding `.r.md` file
- `AssignmentManager.create()` creates both `steps/` and `reports/` directories
- `Assignment.reports_dir` returns path to reports directory
- `StepWriter.mark_done()` accepts `reports_dir:` parameter and writes report separately
- `StepWriter.append_report()` accepts `reports_dir:` parameter and updates report files
- `StepWriter.write_report()` private helper for atomic report file writes
- `AssignmentExecutor.advance()` passes `reports_dir` to `mark_done()`
- CLI status command fallback filename uses `.st.md` extension
- `Step.to_display_row()` fallback filename uses `.st.md` extension

## [0.1.4] - 2026-01-28

### Added

- Archive job.yaml to task's `steps/` directory after assignment creation (`{assignment_id}-job.yml`)

## [0.1.3] - 2026-01-28

### Technical

- Standardize instructions format to arrays in prepare-assignment workflow doc
- Update e2e tests for workflow lifecycle with error paths and state verification
- Update CHANGELOGs with complete fix descriptions

## [0.1.2] - 2026-01-28

### Fixed

- CLI `start` command crashes with positional argument (`ace-assign start job.yaml`) because `option :config` requires `--config` flag — renamed command to `create` with `argument :config`
- `ace-bundle wfi://prepare-assignment` fails due to missing project-level wfi:// protocol registration

### Added

- Support array format for step instructions in presets (joined with newlines via `normalize_instructions`)

### Changed

- Rename CLI `start` command to `create` (CLI creates assignment; "start" is the skill that begins agent work)
- Preset files (`work-on-task.yml`, `work-on-task-with-pr.yml`) now use array instructions format
- Updated workflow instructions and README to reflect `create` command and array instructions format

## [0.1.1] - 2026-01-28

### Fixed

- Persist skill field from job.yaml steps through full pipeline (StepWriter, StepFileParser, QueueScanner, Step model)
- Display skill in status command output for current step
- Pass through extra step fields (beyond name/instructions) from job.yaml via AssignmentExecutor
- Update default job.yaml output path in prepare-assignment workflow to task folder

## [0.1.0] - 2026-01-28

### Added

- Initial release with work queue-based assignment management
- CLI commands: start, status, report, fail, add, retry
- File-based queue storage with markdown step files
- Assignment persistence via assignment.yaml
- History preservation (failed steps remain visible)
- Dynamic step addition with automatic numbering
- Retry mechanism that creates new steps linked to original


## [0.12.12] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
