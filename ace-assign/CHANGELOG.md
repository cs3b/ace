# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- New `onboard-base` catalog phase — loads base project context via `ace-bundle project-base`
- New `task-load` catalog phase — loads task behavioral spec via `ace-bundle task://<taskref>`
- Taskref placeholder substitution in catalog phase descriptions — `<taskref>` in phase descriptions is replaced with actual task reference during child instruction building

### Changed
- Default assignment presets updated to use ace-task

### Fixed
- Apply session 8q2 learnings to workflow and presets

### Technical
- Increase timeout for hierarchy E2E scenario

## [0.15.1] - 2026-03-01

### Added
- Fork-run crash recovery protocol in drive workflow — detection, commit partial work, progress report, inject recovery phases, re-fork pattern for partial completion scenarios

## [0.15.0] - 2026-02-28

### Added
- Add `verify-test-suite` step to `work-on-task` preset between `mark-task-done` and `verify-e2e` with profiling and performance budget enforcement
- Add `verify-test-suite` step (number 012) to `work-on-tasks` preset between batch-parent and `verify-e2e`
- Enrich `verify-test-suite` phase catalog with structured steps: `run-package-tests`, `check-performance-budgets`, `fix-violations`, `run-suite`
- Add performance budget thresholds to phase definition: atoms <50ms, molecules <100ms, integration <1s, full package <30s
- Move `verify-test-suite` from Optional to Core in compose workflow for "Implement + PR" and "Batch tasks" intents
- Add `verify-test-suite` inclusion guidance note to compose workflow Phase Selection Guidelines

### Changed
- Strengthen `verify-test-suite` composition rule from `recommended` to `required` when assignment includes `work-on-task` or `fix-bug`

## [0.14.0] - 2026-02-28

### Added
- Add `verify-e2e` phase to catalog: E2E coverage review and targeted scenario execution for modified packages
- Add `update-docs` phase to catalog: public-facing documentation updates when CLI contracts or public APIs change
- Add `verify-e2e` and `update-docs` steps to `work-on-task` preset (between `mark-task-done` and `release-minor`, and between `release-minor` and `create-pr`)
- Add batch-level `verify-e2e` (step 015) and `update-docs` (step 025) to `work-on-tasks` preset
- Add ordering rules to `composition-rules.yml`: `e2e-before-release`, `update-docs-after-release`, `update-docs-before-pr`, `e2e-after-verify`
- Add conditional rule to suggest `verify-e2e` and `update-docs` when assignment touches CLI commands or public API
- Add `e2e-review-run-pair` and `docs-update-validate-pair` to composition pairs
- Update `compose.wf.md` Phase Selection Guidelines table to include `verify-e2e` and `update-docs` in all relevant workflow intents with skip guidance

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
- Validate `fork_root` existence in `find_target_phase_for_start` consistently regardless of `phase_number` presence

### Added
- Integration test for `finish` auto-advance and `start` conflict detection across sequential phases
- Test for `--report` file precedence over piped stdin when both are present

## [0.13.1] - 2026-02-26

### Fixed
- Raise `PhaseNotFoundError` in `start_phase` and `finish_phase` when `--assignment <id@root>` specifies a non-existent subtree root, preventing silent fallback to the global queue
- Use `ConfigNotFoundError` (exit 3) in `advance()` for missing report files, consistent with `finish` command behavior

### Added
- Add positive test cases for `start` and `finish` commands with explicit `step` argument targeting

## [0.13.0] - 2026-02-26

### Added
- Add `start` command for explicit phase lifecycle control: `ace-assign start [STEP]`
- Add `finish` command replacing `report`: `ace-assign finish [STEP] --report <file>` or via piped stdin
- Support piped stdin as report source in `finish`, eliminating mandatory temp-file creation
- Enforce strict `start` conflict detection: fails when another phase is already `in_progress`
- Add `start_phase` and `finish_phase` APIs to assignment executor for programmatic lifecycle control

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
- Anchor FORK column detection regex to CHILDREN pattern in `assign/drive` workflow, preventing false matches on phase names containing 'yes'

## [0.12.22] - 2026-02-26

### Added
- Add explicit FORK column to status output showing "yes" for phases with children, making delegation signal unmissable
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
- Remove runtime assignment context coupling to `ACE_ASSIGN_ID` and `ACE_ASSIGN_FORK_ROOT`; assignment targeting now relies on explicit `--assignment <id>` and scoped `--assignment <id>@<phase>` usage.
- Update `assign/drive` workflow and fork-context guide to use explicit assignment flags for subprocess delegation.

### Fixed
- Eliminate scoped report/status behavior that depended on mutable process environment, reducing cross-process/test leakage risk.

## [0.12.20] - 2026-02-25

### Changed
- Update generated `plan-task` phase action instructions to require planning against behavioral spec sections, cover relevant operating modes, and report missing spec details in a `Behavioral Gaps` section

## [0.12.19] - 2026-02-24

### Fixed
- Apply assignment scope (`<id>@<phase>`) during report execution by setting `ACE_ASSIGN_FORK_ROOT` for the report command, so child-phase completions resolve in the correct subtree.

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
- Mark first workable child phase as `in_progress` before launching forked session in `fork-run`

## [0.12.15] - 2026-02-22

### Technical
- Update `ace-bundle project` → `ace-bundle load project` in README, fork-context guide, and test fixture

## [0.12.14] - 2026-02-22

### Added
- Subtree guard step in drive workflow — driver reviews all fork report files before continuing to next phase
- Report review instruction in split-subtree-root phase template for fork context

## [0.12.13] - 2026-02-22

### Added
- Background execution guidance for fork-run in drive workflow (10-30 min timeout handling)
- Timeout note in split-subtree-root phase template for environments with bash limits

## [0.12.11] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.12.10] - 2026-02-21

### Technical
- Stabilize `TS-ASSIGN-004` by replacing live `fork-run` invocation with deterministic scoped `status --assignment <id>@<phase>` assertions
- Rewrite `TS-ASSIGN-006` to deterministic preset-expansion verification using `Ace::Assign::Atoms::PresetExpander` (no chat-skill invocation dependency)
- Add prepare-workflow fixture presets (`work-on-task.yml`, `work-on-tasks.yml`) for reproducible E2E generation checks

## [0.12.9] - 2026-02-21

### Changed
- Migrate skill name references to colon-free convention (`ace_domain_action` format) for non-Claude Code agent compatibility
- Update catalog phases and presets with new skill name format
- Update workflow instructions with new skill invocation patterns

## [0.12.8] - 2026-02-21

### Added
- Verification instructions in `mark-task-done` phase requiring status confirmation after `ace-taskflow task done`
- Subtree completion section in drive workflow requiring task status verification before reporting complete

## [0.12.7] - 2026-02-21

### Fixed
- Add `CACHE_BASE` env var support to `cache_dir` so E2E sandboxes resolve the correct cache path
- Graceful return in `advance()` when fork subtree is exhausted (prevents "No phase currently in progress" error)
- Nil guard in `report` command when `advance()` returns `completed: nil` after subtree exhaustion

## [0.12.6] - 2026-02-21

### Technical
- Add E2E tests for prepare workflow (from preset and from informal instructions)
- Fix `ASSIGNMENT_DIR` lookup in injection/renumbering E2E tests to use dynamic directory discovery
- Reorganize TS-ASSIGN-003b fixtures: replace flat `job.yaml` with structured `phases/` directory

## [0.12.5] - 2026-02-20

### Technical
- Update slash command refs to use git namespace (ace:git-create-pr, ace:git-update-pr-desc)

## [0.12.4] - 2026-02-19

### Technical
- Namespace workflow instructions into domain-specific subdirectories with updated wfi:// protocol URIs
- Update skill name references to use namespaced ace:namespace-action format

## [0.12.3] - 2026-02-19

### Changed
- Added clarifying comments for `skill: null` and `context.default: null` in reflect-and-refactor phase

## [0.12.2] - 2026-02-19

### Changed
- Clarified `reflect-after-verify` ordering note to distinguish baseline verify from post-refactor re-verify
- Consolidated duplicate conditional suggestions for `work-on-task` into single entry with per-phase strength overrides

## [0.12.1] - 2026-02-19

### Fixed
- `reflect-verify-cycle` pair changed from `sequential` to `conditional` — prevents overriding optional strength of reflect-and-refactor
- Renamed `max_recursion` to `max_reruns` in replan config for clarity

## [0.12.0] - 2026-02-19

### Added
- New `reflect-and-refactor` phase in catalog — analyzes implementation against ATOM principles and executes targeted refactoring before PR creation
- Composition rules for reflect-and-refactor: ordering (after verify, before mark-done/release/retro), pairs (verify cycle, fix cycle, replan cycle), and conditional suggestion
- `create-retro` phase now consumes `findings-report` from reflect-and-refactor as recommended prerequisite
- `implement-with-pr` recipe updated to include optional reflect-and-refactor phase after work-on-task

## [0.11.18] - 2026-02-19

### Changed
- Remove dead `print_fork_scope_guidance` method and duplicate `fork_scope_root` definition from status command

## [0.11.17] - 2026-02-17

### Fixed

- `assignment_state` now checks `completed` before `failed` — assignments where all phases are done/failed correctly report `:completed` instead of `:failed`

### Added

- `recently_active?` method on `QueueState` to detect stale in-progress phases (threshold: 1 hour)
- New `:stalled` assignment state for in-progress phases with no recent activity

## [0.11.16] - 2026-02-17

### Added

- `current_in_subtree` method on `QueueState` to find in-progress phase within a subtree

### Fixed

- Fork root executor now checks for existing in-progress phase in subtree before advancing to next workable phase

## [0.11.15] - 2026-02-17

### Added
- New catalog phase definition `split-subtree-root` for split parent/fork-root orchestration instructions (default template in `.ace-defaults/assign/catalog/phases/`)

### Changed
- Split parent phases with `sub_phases` now materialize as orchestration-only subtree roots:
  - parent `skill` is removed to avoid duplicate execution semantics
  - parent keeps `source_skill` metadata for traceability
  - parent instructions are rendered from catalog template (project-overridable)
- Phase catalog resolution now merges project overrides with default catalog by phase name, so projects can override a single phase definition without replacing the entire catalog

### Fixed
- Fork root parent phases no longer instruct direct `work-on-task` execution and now clearly drive subtree delegation/execution (`fork-run` + `assign-drive`) through child phases

## [0.11.14] - 2026-02-17

### Fixed
- Scoped status rendering for nested roots (for example `--assignment <id>@010.01`) now prints the subtree hierarchy correctly instead of collapsing to an empty queue section
- Runtime-expanded child phases now use explicit `taskref` metadata (when present) for deterministic task context, and preserve it in child phase frontmatter
- Fork session launcher now loads `ace/llm` so `fork-run` handles provider errors without crashing on uninitialized LLM error constants

### Changed
- Preset expansion now substitutes placeholders across all step fields (including nested metadata), not only `name` and `instructions`

## [0.11.13] - 2026-02-17

### Fixed
- Scoped status (`--assignment <id>@<phase>`) now selects the actionable phase within the subtree instead of always reporting the scope root as current
- Runtime sub-phase expansion now generates step-specific action instructions per child phase and keeps parent goals as a verification checklist (instead of copy-pasting orchestration text into every child)

## [0.11.12] - 2026-02-17

### Added
- E2E regression scenario `TS-ASSIGN-005-no-skip-policy` to enforce hard no-skip drive policy and keep `ace:assign-drive` skill thin

### Changed
- `drive-assignment` workflow now enforces hard no-skip execution for planned phases and removes skip-assessment behavior
- Added required attempt-first failure evidence (command + exact error) and post-report/fail status transition verification in drive workflow

## [0.11.11] - 2026-02-17

### Changed
- `drive-assignment` workflow now auto-delegates detected fork-enabled subtrees via `ace-assign fork-run --assignment <id>@<root>` before inline phase execution
- Fork context guide now documents the runtime delegation path where parent drive sessions detect subtree roots and delegate scoped execution with `fork-run`

## [0.11.10] - 2026-02-17

### Changed
- Use `Atoms::NumberGenerator.subtask` for sub-phase numbering in runtime expansion to keep numbering logic centralized
- Tree formatter state labels now explicitly include `pending` and `in_progress`

### Fixed
- Added coverage for fork-scoped advancement when global current phase is outside scoped subtree
- Added stable tests for CLI provider env propagation and query-interface sandbox propagation

## [0.11.9] - 2026-02-17

### Added
- Regression coverage for fork-scoped advancement when global current phase is outside the scoped subtree

### Changed
- `ace-assign status` now prints explicit `Current Status: <status>` for easier machine parsing and E2E assertions

### Fixed
- Fork-scoped report advancement now selects and completes the next in-subtree phase instead of completing an out-of-scope global current phase
- E2E assertions for `parent` frontmatter now accept both single-quoted and double-quoted YAML scalars to avoid formatting-only false negatives

## [0.11.8] - 2026-02-17

### Added
- Shared assignment target parser for CLI commands with scoped syntax support: `--assignment <id>@<phase>`
- New command tests covering assignment target parsing and scoped subtree execution behavior
- New E2E scenario scaffold for fork subtree scope isolation verification (`TS-ASSIGN-004`)

### Changed
- Assignment-targeting commands (`status`, `report`, `fail`, `add`, `retry`, `fork-run`) now use a shared target resolver
- `ace-assign fork-run` accepts subtree root from scoped assignment target (`<id>@<phase>`) and validates conflicts with `--root`
- Scoped status output (`--assignment <id>@<phase>`) now renders only the selected node subtree and uses the scope root as displayed current phase

### Fixed
- Removed global current-phase coupling in `fork-run` so subtree execution can start from any explicitly scoped root node

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
- Subtree scope helpers in queue state (`in_subtree?`, `subtree_phases`, `subtree_complete?`, `next_workable_in_subtree`, `nearest_fork_ancestor`)

### Changed
- Status output now detects forked ancestor scope and guides operators to run `fork-run` for whole-subtree delegation
- Report output now distinguishes subtree completion from full assignment completion when fork scope is active
- Fork context guide and workflow docs updated for explicit parent-only fork semantics and subtree execution model

### Fixed
- Split-subphase expansion no longer writes `context: fork` on child phases (`onboard`, `plan-task`, `work-on-task`) when parent is forked
- Queue advancement in fork scope now stays inside `ACE_ASSIGN_FORK_ROOT` subtree and does not leak into sibling phases

## [0.11.5] - 2026-02-17

### Fixed
- Ensure runtime-expanded sub-phases are concrete and executable by materializing catalog metadata (skill, phase focus) instead of generic placeholder instructions
- Preserve task context during sub-phase expansion so child phases receive parent task instructions for deterministic parameter extraction
- Start assignments on the first workable leaf phase (not parent container phases), preventing blocked progression in parent-child trees
- Use a single fork entrypoint for forked sub-phase subtrees (first child), avoiding nested fork-per-child behavior

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
- `AssignmentExecutor.start` now enriches phases with skill-declared workflow `assign.sub-phases` before expansion, enabling deterministic runtime sub-phase materialization without compose-specific wiring
- `compose-assignment` workflow is now catalog-only and no longer documents source/frontmatter-driven phase composition

## [0.11.2] - 2026-02-16

### Technical
- Add test cases for new composition ordering rules (`onboard-before-plan`, `plan-before-implementation`) and conditional `plan-task` suggestion

## [0.11.1] - 2026-02-16

### Fixed
- Consolidate duplicate conditional trigger for work-on-task in composition-rules

## [0.11.0] - 2026-02-16

### Added
- JIT plan-task phase in implement-with-pr and implement-simple recipes (optional, between onboard and work-on-task)
- Composition rules: `onboard-before-plan` and `plan-before-implementation` ordering
- Conditional suggestion: recommend plan-task when work-on-task is included

### Changed
- plan-task phase catalog entry: produces `[implementation-plan]` only (removed `task-spec`), consumes `[project-context, task-spec]`

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
- Review cycle presets in `work-on-task.yml` and `work-on-tasks.yml` now use phase-specific presets instead of `code-deep`
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

- Declarative assignment frontmatter: `assign:` block in `.s.md` and `.wf.md` files declares assignment intent (goal, variables, hints, sub-phases, context, parent)
- `AssignFrontmatterParser` atom for extracting and validating `assign:` frontmatter blocks
- `TreeFormatter` atom for rendering assignment hierarchy as indented tree with Unicode connectors
- Parent-child assignment linking via `parent` field in Assignment model
- `ace-assign list --tree` option for hierarchical assignment view
- Sub-phase fork enforcement in executor: phases with sub-phases create batch parent in fork context
- Compose workflow integration: step 0 reads `assign:` frontmatter as structured input
- `documentation.recipe.yml` for documentation workflows with research phase
- `release-only.recipe.yml` for version bump workflows without code changes
- `work-on-docs.yml` preset exposing documentation workflow
- `release-only.yml` preset exposing release-only workflow
- `quick-implement.yml` preset for simple task implementation
- `fix-bug.yml` preset for bug fix with review workflow

### Changed

- Update timestamp dependency from `ace-support-timestamp` to `ace-b36ts`

## [0.8.3] - 2026-02-14

### Added

- New `mark-task-done` phase for marking tasks as done in ace-taskflow after implementation
- Composition rule to order `mark-task-done` after `work-on-task`
- Conditional rule suggesting `mark-task-done` when assignment includes `work-on-task`
- `mark-task-done` step in `work-on-task` preset (runs `ace-taskflow task done`)
- Mark-done instruction in `work-on-tasks` child template for per-task completion
- `mark-task-done` phase in `implement-with-pr`, `implement-simple`, and `fix-and-review` recipes

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
- `CatalogLoader.parse_phase_file` now warns on stderr when a phase YAML file fails to parse (was silently returning nil)
- `compose-assignment.wf.md` uses Read/Glob tool references instead of `cat`/`ls` per project conventions

### Changed

- Added inline documentation for prefix matching constraints in `find_phase_index`
- Added comment clarifying that mixed "and"/"or" conjunctions are not supported in conditional rules

## [0.7.4] - 2026-02-13

### Added

- New phase catalog entries: `push-to-remote`, `release`, `reorganize-commits`

### Fixed

- Missing `skill: ace:apply-feedback` in work-on-tasks preset apply-feedback phases
- Ordering rules now match suffixed phase names via prefix matching (e.g., `release` matches `release-minor`, `release-patch-1`)
- Conditional composition rules with "and" conjunction now correctly require all conditions (was using `any?` instead of `all?`)

### Changed

- Renamed `work-on-task-with-pr` preset to `work-on-task` (now the default/primary workflow)
- Updated workflow documentation to reflect preset rename

## [0.7.3] - 2026-02-13

### Added

- **Phase catalog system**: Registry of available phase types with prerequisites, produces/consumes, context defaults, and skip conditions (14 phase definitions)
- **Composition rules**: Declarative ordering constraints, phase pairs, and conditional suggestions for intelligent assignment composition
- **Recipe system**: Flexible example patterns replacing rigid presets (4 recipes: implement-with-pr, implement-simple, batch-tasks, fix-and-review)
- **Compose-assignment workflow**: LLM-driven assignment composition from phase catalog and user intent
- `CatalogLoader` atom for loading and querying phase catalog YAML files
- `CompositionRules` atom for loading, validating ordering, and suggesting phase additions
- Conditional composition rule logic in `suggest_additions` for context-dependent phase suggestions

### Changed

- Drive-assignment workflow now includes phase decision points for skip assessment and adaptation
- Start-assignment workflow updated to offer compose as alternative path

### Fixed

- `apply-feedback.phase.yml` now correctly references `ace:apply-feedback` skill (was null)

## [0.7.2] - 2026-02-12

### Changed

- E2E tests renamed from COWORKER to ASSIGN terminology
- All test references updated: coworker → assign, session → assignment, step → phase, jobs → phases

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
- Internal "step" concept renamed to "phase"
- Phase file extension changed from .j.md to .ph.md
- Cache directory changed from .cache/ace-coworker/ to .cache/ace-assign/
- Skills renamed from /ace:coworker-* to /ace:assign-*
- New combined /ace:assign-start skill added (prepare + create in one step)

## [0.5.3] - 2026-02-01

### Changed

- Removed `prepare` CLI command - use `/ace:assign-prepare` workflow instead (handles informal instructions and customizations)

## [0.5.2] - 2026-01-31

### Fixed

- `prepare` CLI now uses Base36 timestamps (e.g., `8ouxjt`) instead of datetime format
- `prepare` CLI now outputs phase files to task's `phases/` folder (e.g., `.ace-taskflow/v.0.9.0/tasks/253-xxx/phases/`) when task refs provided
- Correctly extracts parent task ID from subtask refs (e.g., `253.01` -> task folder `253-xxx`)

## [0.5.1] - 2026-01-31

### Fixed

- `prepare` CLI command now actually works - implements preset loading, parameter parsing, and job.yaml generation (was just a stub in 0.5.0)

## [0.5.0] - 2026-01-31

### Added

- **Multi-task phase preparation**: New `work-on-tasks` preset enables batch processing of multiple tasks in a single job
- `PresetExpander` atom for expanding preset templates with `expansion:` directives
- Support for `batch-parent` and `foreach` expansion directives in presets
- Array parameter parsing supporting comma-separated (`148,149,150`), range (`148-152`), and pattern (`240.*`) syntax
- Pre-assigned phase numbers in job.yaml are now preserved by AssignmentExecutor
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

- **Hierarchical phase structure**: Phases can now have nested sub-phases (010.01, 010.02) with parent-child relationships
- New `PhaseNumbering` atom for parsing and generating hierarchical phase numbers
- `--after` option for `add` command: inject phases after specific phase numbers (`ace-assign add verify --after 010`)
- `--child` option for `add` command: create nested child phases (`ace-assign add verify --after 010 --child`)
- `--flat` option for `status` command: show flat list without hierarchy indentation
- Automatic phase renumbering when inserting phases at occupied positions
- `children_of`, `descendants_of`, `has_incomplete_children?` methods on QueueState for hierarchy traversal
- `hierarchical` method on QueueState for tree-structured display
- Parent number extraction from filenames in `PhaseFileParser.parse_filename`
- Audit trail metadata: `added_by`, `parent`, `renumbered_from`, `renumbered_at` fields for tracking phase history
- O(1) child lookups via parent index in QueueState for improved performance

### Changed

- Auto-complete parents now handles multi-level hierarchies in a single pass (grandparents complete when parents complete)
- Auto-complete now includes in_progress parents (not just pending) when all children finish
- Status command now shows hierarchical structure when nested phases exist
- Advance operation respects hierarchy: parent phases wait for all children to complete

### Fixed

- Cascade renumbering to descendants: when a phase is shifted, all its children are also renamed to prevent orphaning
- Enforce hierarchy in `advance`: prevent marking parent as done while children are incomplete
- Validate `--after` phase existence before injection (raises PhaseNotFoundError if not found)
- Replace fragile `instance_variable_set` mutation with local tracking Set in auto_complete_parents
- Add safety guard to prevent infinite loops in auto-completion (max iterations = phase count)
- Re-scan state after auto_complete_parents to ensure find_next_phase uses fresh data
- Use `next_workable` instead of `next_pending` in find_next_phase to respect hierarchy
- QueueState now supports `top_level`, `all_numbers`, and `next_workable` methods

## [0.3.1] - 2026-01-30

### Fixed

- Phase files already in a `phases/` directory are kept in place instead of being moved to a nested path when creating assignments

## [0.3.0] - 2026-01-30

### Added

- **Fork context support for phases**: Enable phase files to declare `context: fork` in frontmatter to run phases in isolated agent contexts via Claude Code's Task tool
- New `context` field in Phase model with `fork?` predicate method
- Context validation rejecting invalid values with helpful error messages (valid values: `fork`)
- `handbook/guides/fork-context.g.md` documentation for the fork context feature
- Status command outputs Task tool instructions for fork-context phases
- Shell escaping for phase names in Task tool description field
- E2E test (TC-005) for fork context feature validation

### Changed

- Centralized `VALID_CONTEXTS` constant in Phase model, referenced by parser
- QueueScanner surfaces ArgumentError for invalid phase files instead of silent nil return
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

- Fixed file extension documentation: `*.md` → `*.ph.md` for phase files in create-assignment workflow
- Clarified "source of truth" is `ace-assign status` command in workflow documentation
- Added note about archived job.yaml being for provenance only, not status queries
- Changed "Job files" → "Phase files" terminology in README for clarity

## [0.1.5] - 2026-01-28

### Added

- Separate phase and report files with `.ph.md` and `.r.md` extensions
- New `reports/` directory structure for storing completion reports separately from phase files
- Report files include YAML frontmatter with `phase`, `name`, and `completed_at` fields for traceability

### Changed

- Phase files now use `.ph.md` extension (was `.md`)
- Reports are written to separate `.r.md` files instead of being embedded in phase bodies
- `PhaseFileParser.extract_fields()` now returns `nil` for report (loaded separately)
- `PhaseFileParser.parse_filename()` handles both `.ph.md` and `.r.md` extensions
- `PhaseFileParser.generate_filename()` produces `.ph.md` filenames
- `PhaseFileParser.generate_report_filename()` produces `.r.md` filenames
- `PhaseSorter.sort_key()` strips `.ph.md` extension
- `QueueScanner.scan()` and `phase_numbers()` glob for `*.ph.md` files
- `QueueScanner.load_report()` loads report content from corresponding `.r.md` file
- `AssignmentManager.create()` creates both `phases/` and `reports/` directories
- `Assignment.reports_dir` returns path to reports directory
- `PhaseWriter.mark_done()` accepts `reports_dir:` parameter and writes report separately
- `PhaseWriter.append_report()` accepts `reports_dir:` parameter and updates report files
- `PhaseWriter.write_report()` private helper for atomic report file writes
- `AssignmentExecutor.advance()` passes `reports_dir` to `mark_done()`
- CLI status command fallback filename uses `.ph.md` extension
- `Phase.to_display_row()` fallback filename uses `.ph.md` extension

## [0.1.4] - 2026-01-28

### Added

- Archive job.yaml to task's `phases/` directory after assignment creation (`{assignment_id}-job.yml`)

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

- Support array format for phase instructions in presets (joined with newlines via `normalize_instructions`)

### Changed

- Rename CLI `start` command to `create` (CLI creates assignment; "start" is the skill that begins agent work)
- Preset files (`work-on-task.yml`, `work-on-task-with-pr.yml`) now use array instructions format
- Updated workflow instructions and README to reflect `create` command and array instructions format

## [0.1.1] - 2026-01-28

### Fixed

- Persist skill field from job.yaml phases through full pipeline (PhaseWriter, PhaseFileParser, QueueScanner, Phase model)
- Display skill in status command output for current phase
- Pass through extra phase fields (beyond name/instructions) from job.yaml via AssignmentExecutor
- Update default job.yaml output path in prepare-assignment workflow to task folder

## [0.1.0] - 2026-01-28

### Added

- Initial release with work queue-based assignment management
- CLI commands: start, status, report, fail, add, retry
- File-based queue storage with markdown phase files
- Assignment persistence via assignment.yaml
- History preservation (failed phases remain visible)
- Dynamic phase addition with automatic numbering
- Retry mechanism that creates new phases linked to original


## [0.12.12] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
