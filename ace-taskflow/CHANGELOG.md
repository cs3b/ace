# Changelog

All notable changes to ace-taskflow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.42.11] - 2026-02-27

### Removed
- Remove `task/create` workflow instruction in favor of draft-first task authoring (`task/draft`) and review-gated promotion

### Changed
- Tighten draft/review quality gates with general-purpose checks: decision-complete behavior, explicit defaults, and verifiable success criteria
- Keep draft template lean and general-purpose by removing specialized simulation-style contract sections

## [0.42.10] - 2026-02-27

### Added
- Add `review-plan` workflow instruction (`wfi://task/review-plan`) for adversarial plan critique with six evaluation dimensions
- Add `review-work` workflow instruction (`wfi://task/review-work`) for adversarial work output critique with six evaluation dimensions

## [0.42.9] - 2026-02-26

### Fixed
- Display orphan subtasks with missing parent tasks instead of silently skipping them in `ace-task list` output
- Show `[missing parent: <parent_id>]` indicator for subtasks whose parent task doesn't exist

## [0.42.8] - 2026-02-26

### Fixed
- Make `IdeaDirectoryMover#move_to_archive` and `#move_to_maybe` idempotent when ideas are already in `_archive/` or `_maybe/`, preventing nested move targets like `_archive/_archive/`
- Treat existing archive/maybe destination folders as idempotent success instead of hard failure, matching task mover semantics

### Changed
- Update `ace-idea done` and `ace-idea park` output to report idempotent `already in` results from mover operations

### Technical
- Add mover coverage for already-archived/already-parked flows, target-exists idempotent behavior, metadata refresh in-place, and archive-substring false-positive guard
## [0.42.7] - 2026-02-25

### Fixed
- Make `ace-idea create --maybe` resolve through configured scope directories (default `_maybe`) instead of hardcoded `maybe/`

### Changed
- Route idea creation scope directory resolution through `Configuration#maybe_dir` and `Configuration#anyday_dir` in both dry-cli and legacy command paths
- Update default `maybe` list preset to prefer `_maybe` while preserving legacy `maybe/` compatibility

## [0.42.6] - 2026-02-25

### Changed
- Add spec-coverage readiness checks to review workflow for operating modes, degenerate inputs, and per-path variation handling
- Update plan workflow guidance to require section-by-section behavioral-spec coverage and explicit `Behavioral Gaps` reporting when spec details are missing

## [0.42.5] - 2026-02-25

### Changed
- Update work-subtasks delegation guidance to read parent task context before subtask execution and clarify parent-vs-subtask responsibility with graceful fallback when parent context is unavailable

## [0.42.4] - 2026-02-25

### Changed
- Add explicit intent-mapping guidance in task draft workflow to map enhanced 3-question idea sections into Objective, Expected Behavior, and Success Criteria while preserving advisory framing
- Update embedded task draft template `## Objective` guidance to carry forward the source idea's "What I Hope to Accomplish" as authoritative intent

## [0.42.3] - 2026-02-25

### Changed
- Replace LLM-enhanced idea output structure with the 3-Question Delegation Brief sections (`What I Hope to Accomplish`, `What "Complete" Looks Like`, `Success Criteria`)
- Update idea enhancement fallback stub and inline system prompt to use the same 3-section structure with clarifying gap prompts

### Technical
- Update idea enhancer and idea command tests to assert the new section headings

## [0.42.2] - 2026-02-25

### Technical
- Add clarifying comments for subtask number guard explaining dry-run vs real execution behavior

## [0.42.1] - 2026-02-25

### Fixed
- Add self-demotion guard to prevent state corruption when `demote_to_subtask` is called with task equal to parent
- Add subtask number guard in `demote_to_subtask` to ensure correct .02 numbering after auto-conversion (matching `create_subtask` behavior)

## [0.42.0] - 2026-02-25

### Added
- Add filtering by task status in list command

### Changed
- Auto-convert non-orchestrator parents when running `ace-task create --child-of` or `ace-task move --child-of`, eliminating the need for manual `--child-of self` conversions

### Technical
- Add goal-mode E2E lifecycle scenarios
- Update E2E test configurations for taskflow and idea lifecycles
- Refine E2E runner and verifier documentation

## [0.41.3] - 2026-02-24

### Added
- Add "End-State Coherence" checklist item to review workflow readiness gate for orchestrator subtasks
- Add "Spike-First Rule" guidance to draft workflow for engine/pipeline redesign tasks
- Add "Concept Inventory" section to orchestrator task template to track concept lifecycle across subtasks
- Add "Architecture Drift Check" (Step 3.10) to work-subtasks workflow to catch spec-implementation divergence early

## [0.41.2] - 2026-02-23

### Changed
- Renamed YamlParser atom to FrontmatterParser to reflect its frontmatter parsing purpose
- Added backward-compatibility alias (YamlParser = FrontmatterParser)
- Narrowed bare rescue in SafeYamlParser and StatsFormatter to specific exception classes

### Technical
- Updated internal dependency version constraints to current releases

## [0.41.1] - 2026-02-23

### Fixed
- Fix `ace-retro create` failing with "not found" error by creating dedicated CreateRetro command
- Title argument is now properly handled as a positional arg instead of being misrouted through subaction dispatching

## [0.41.0] - 2026-02-22

### Changed
- Migrate ace-retro CLI to standard help pattern with HelpCommand registration
- Remove DefaultRouting extension and DWIM command routing from RetroCLI
- Add no-args behavior to show help instead of running default command

## [0.40.6] - 2026-02-22

### Changed
- Migrate ace-release CLI to standard help pattern with HelpCommand registration
- Remove DefaultRouting extension and DWIM command routing from ReleaseCLI
- Move cache clearing from CLI.start override to exe/ace-release wrapper
- Add no-args behavior to show help instead of running default command

## [0.40.5] - 2026-02-22

### Changed
- Migrate ace-idea CLI to standard help pattern with HelpCommand registration
- Remove DefaultRouting extension and DWIM command routing from IdeaCLI
- Move cache clearing from CLI.start override to exe/ace-idea wrapper
- Add no-args behavior to show help instead of running default command

### Technical
- Update idea subcommands tests to test flat CLI pattern via IdeaCLI
- Update CLI routing integration tests to handle mixed old/new patterns

## [0.40.4] - 2026-02-22

### Changed
- Migrate ace-task CLI to standard help pattern with HelpCommand registration
- Remove DefaultRouting extension and DWIM command routing from TaskCLI
- Move cache clearing from CLI.start override to exe/ace-task wrapper
- Add no-args behavior to show help instead of running default command

## [0.40.3] - 2026-02-22

### Changed
- Migrate CLI to standard help pattern with HelpCommand registration
- Move cache clearing from CLI.start override to exe/ wrapper
- Add no-args behavior to show help instead of running default command
- Remove DefaultRouting extension and DWIM command routing

## [0.40.2] - 2026-02-22

### Technical
- Update workflow instructions to use `ace-search "pattern"` single-command syntax (drop `search` subcommand)

## [0.40.1] - 2026-02-22

### Changed
- Add release and verify-test-suite to work-on-task sub-phases for complete subtree lifecycle

## [0.39.7] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.39.6] - 2026-02-21

### Added
- Cross-package reference audit step in plan workflow using `ace-search` for rename/migration tasks
- Contradiction check in review workflow readiness checklist (conflicting directives, missing consumer packages, deliverables vs scope)
- Cross-reference validation step in work workflow (mandatory for rename/namespace/migration tasks)

## [0.39.5] - 2026-02-21

### Added
- LLM-assisted doctor fixes and model configuration
- Task management doctor and archiving capabilities

### Fixed
- Update work-on-task workflow to declare sub-phases
- Enhance doctor command with empty directory detection and auto-fix
- Load config from discovered project root in `ConfigLoader.find_root` to fix cross-project resolution

### Changed
- Remove duplicated and outdated workflow files

### Technical
- Normalize project context loading URIs across workflows
- Reorganize workflow instructions into domain subdirectories
- Update workflow references for git commit and token remediation

## [0.39.4] - 2026-02-19

### Technical
- Namespace workflow instructions into domain subdirectories: task/, bug/, idea/, retro/, release/
- Update wfi:// protocol URIs throughout

## [0.39.3] - 2026-02-19

### Fixed
- Fix `handle_auto_fix` in CLI doctor always finding zero fixable issues due to using an undiagnosed doctor instance; now uses `results[:issues]` from the already-run diagnosis
- Fix agent prompt issue list showing no file paths by using correct `:location` key instead of `:file`
- Downgrade empty directory warnings to info severity when the directory is under `/_archive/`

## [0.39.2] - 2026-02-19

### Fixed
- Embed formatted list of non-auto-fixable issues directly in agent prompt so the agent knows exactly what to work on without re-running `--auto-fix`

## [0.39.1] - 2026-02-19

### Fixed
- Wire up `--auto-fix`, `--auto-fix-with-agent`, and `--model` options in dry-cli layer (`cli/commands/doctor.rb`) — previously only the unused standalone `DoctorCommand` had these options
- Drop `--fix` backward-compatible alias per ADR-024

## [0.39.0] - 2026-02-19

### Added
- `--auto-fix-with-agent` option for doctor command — runs deterministic auto-fix first, then launches LLM agent via `Ace::LLM::QueryInterface` to handle remaining issues
- `--model MODEL` option to override provider:model for agent sessions
- `doctor_agent_model` configuration setting (default: `claude:sonnet`)
- `ace-llm` runtime dependency for agent-assisted fixing

### Fixed
- Pattern mismatch bug in `DoctorFixer` where `fix_issue`/`can_fix?` couldn't match task location messages from the doctor (regex expected "marked as done" but doctor generates "not in _archive/ directory")

### Changed
- Renamed `--fix` to `--auto-fix` (keeping `--fix` as backward-compatible alias)

## [0.38.2] - 2026-02-19

### Fixed
- Add `assign:` block to `work-on-task.wf.md` frontmatter declaring sub-phases (onboard, plan-task, work-on-task) so batch children expand into sub-steps during enrichment

## [0.38.1] - 2026-02-19

### Fixed
- Fix `doctor --fix` never finding fixable issues (was creating fresh doctor without running diagnosis)
- Make `auto_fixable?` public on `TaskflowDoctor` so command layer can filter diagnosed results

### Added
- Doctor check for empty directories under `tasks/` and `ideas/` (warning with auto-fix)
- Auto-fix handler for empty directories (recursive removal when no files present)

## [0.38.0] - 2026-02-19

### Added
- Doctor check for stale backup files in active task directories (warning with auto-fix)
- Doctor check for idea scope/status consistency (detects `maybe/_archive/` nesting, mismatched status/location)
- Doctor integration with `IdeaStructureValidator` for misplaced idea file detection
- Auto-fix handler for stale backup files (delete) and invalid idea nesting (move to correct `_archive/`)
- Implement `idea archive` command (was stub-only) using `IdeaDirectoryMover.move_to_archive`
- Clean up backup files when subtasks are marked as done (previously only cleaned on full task archive)

## [0.37.3] - 2026-02-19

### Fixed
- Clarify codemod location convention: task-level codemods go in `{task-folder}/codemods/`, never in `bin/`
- Add codemod deliverable hint to task template

## [0.37.2] - 2026-02-19

### Technical
- Remove dead `:orchestrator` branch in `build_task_relationships` (no longer emitted by `classify_task_file`)
- Fix stale `.00` references in code comments

## [0.37.1] - 2026-02-19

### Fixed
- Harden `.00` rejection: `valid?` and `qualified?` now return `false` for legacy `.00` references instead of propagating `ArgumentError`
- `format` now rejects subtask `00` with clear error, preventing generation of legacy references

## [0.37.0] - 2026-02-19

### Changed
- Remove `.00` suffix from orchestrator task filenames (`NNN.00-orchestrator.s.md` → `NNN-orchestrator.s.md`)
- Orchestrator detection now based on presence of subtask files rather than filename pattern
- Remove `is_orchestrator?` from TaskReferenceParser (filesystem concern, not reference concern)
- Reject `.00` references (e.g., `121.00`) with clear error message

## [0.36.3] - 2026-02-19

### Fixed
- Promote single-named parent tasks to orchestrators when subtasks reference them, preventing duplicate display in task listings
- Add `build_task_relationships` call to `load_tasks_with_glob` so glob-loaded tasks get proper parent-child linking

## [0.36.2] - 2026-02-16

### Fixed
- Fix review-task CLI syntax: split multi-field update into separate commands to avoid dry-cli repeat option issue
- Fix plan-task standalone dead path: clarify that review-task must promote draft to pending before plan-task

## [0.36.1] - 2026-02-16

### Fixed
- Standardize arrow notation in plan-task file modification checklist template
- Clear `needs_review` flag when promoting tasks from draft to pending in review-task
- Clarify that behavioral-spec-only tasks are valid in work-on-task validation

## [0.36.0] - 2026-02-16

### Changed
- Streamline task lifecycle: review-task becomes draft-to-pending readiness gate with checklist validation and status promotion
- Transform plan-task to JIT ephemeral planning (no task file modifications, no status changes)
- Update work-on-task to accept tasks with behavioral specs only (implementation plan optional)
- Update draft-task to reference review-task as next step instead of plan-task
- Update create-task workflow to decouple plan-task from task creation pipeline
- Update draft-tasks workflow to recommend review-task for draft validation

## [0.35.1] - 2026-02-16

### Fixed
- Deduplicate subtask IDs when orchestrator frontmatter mixes short IDs (e.g., "243.02") with canonical IDs (e.g., "v.0.9.0+task.243.02")

## [0.35.0] - 2026-02-14

### Added
- Add `ace:manage-task-status` skill for task lifecycle operations (start, done, undone)
- Add `ace:reorganize-task` skill for task hierarchy operations (promote, demote, convert)
- Add `manage-task-status` workflow for status management guidance

### Changed
- Update timestamp dependency to ace-b36ts

## [0.34.7] - 2026-02-12

### Fixed
- Case-insensitive `.md` file glob in `CodenameExtractor#find_main_file` to match both `.md` and `.MD` extensions
- Cross-platform clipboard error message matching in idea subcommands test (macOS vs Linux)

## [0.34.6] - 2026-01-31

### Technical
- Optimize slow tests with minimal fixtures instead of full test project setup

## [0.34.5] - 2026-01-31

### Fixed
- Update `test_missing_title_returns_error` to expect `Ace::Core::CLI::Error` exception per ADR-023

## [0.34.4] - 2026-01-31

### Fixed
- Update require paths and class references in create command tests
- Fix stub leak in `stub_llm_slug_generation` with proper teardown restoration

## [0.34.3] - 2026-01-29

### Added
- Expand task draft template with CLI-specific sections: exit codes, input validation, concurrency, cleanup
- Add CLI task example and requirements documentation to task templates README
- Add data-driven feature requirements checklist

### Fixed
- Exception-based exit codes for consistent CLI error handling

## [0.34.2] - 2026-01-27

### Added
- Add `default_idea_glob_pattern` alias for clearer method naming in Configuration

### Changed
- DRY up `get_statistics` to use `Configuration#default_task_glob_pattern` instead of hardcoded patterns

## [0.34.1] - 2026-01-27

### Fixed
- Resolve task counting discrepancy in preset listings
  - Add `default_task_glob_pattern` to Configuration for proper task file matching
  - Update ListPresetManager to use type-appropriate default globs (tasks vs ideas)
  - Update `get_statistics` glob to include orchestrator/subtask format (NNN.NN-*.s.md)
  - Before: "0/93 tasks" with "No tasks found for preset 'draft'"
  - After: "2/135 tasks" correctly displaying filtered tasks
- Rename duplicate task 227 to 230 to resolve task ID collision

## [0.34.0] - 2026-01-22

### Changed
- Update analyze-bug workflow to use guide:// protocol
- Now references ace-bundle guide://testing-philosophy

## [0.33.12] - 2026-01-22

### Fixed
- Fix recently done tasks to sort by file modification time, not dependency order
  - Task with dependencies now appears in recently done based on when it was last modified
  - Previously, dependency ordering took precedence, causing recently completed tasks to appear incorrectly
  - Added test case to verify temporal sorting regardless of dependencies

## [0.33.11] - 2026-01-22

### Fixed
- Fix `--child-of` flag to support dry-cli's required string values
  - Use `--child-of none` to promote subtask to standalone (was `--child-of` without value)
  - Maintains backwards compatibility with `--child-of=` (empty string)
  - Update legacy optparse parser to handle "none" sentinel value
  - Fix documentation examples to use subtask reference (e.g., `187.12 --child-of none`)
  - Add test coverage for "none" sentinel value behavior

## [0.33.10] - 2026-01-22

### Fixed
- Fix task 226 duplication in tasks listing by using TaskReferenceParser to qualify simple parent references for orchestrator matching
  - Orchestrator ID format mismatch caused subtasks to display as orphans with duplicate parent
  - Now converts simple parent references (e.g., "226") to qualified format (e.g., "v.0.9.0+task.226") before comparison
  - Task 226 now appears once with subtasks properly indented underneath

## [0.33.9] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.33.8] - 2026-01-14

### Changed
- Migrate CLI to Hanami pattern (CLI::Commands::* namespace)
  - Moved wrapper classes from `cli/*.rb` to `cli/commands/*.rb`
  - Unified command structure under `CLI::Commands::` namespace
  - Maintained backward compatibility with nested commands in `Commands::Task::*` and `Commands::Idea::*`
  - All commands now follow consistent Hanami CLI pattern

## [0.33.7] - 2026-01-14

### Fixed
- Fix duplicate orchestrator display in hierarchical task listing
  - Orchestrator tasks were shown twice: once in main list, once as parent context
  - Root cause: ID format mismatch between orchestrator ID (`v.0.9.0+task.211.00`) and subtask parent_id (`v.0.9.0+task.211`)
  - Added `orchestrator_id_matches_parent?` helper to handle ID prefix matching
  - Subtasks now correctly display under their parent orchestrator

## [0.33.6] - 2026-01-11

### Fixed
- Handle Float subtask references from YAML parsing in TaskReferenceParser
  - YAML parses unquoted `202.01` as Float, not String
  - Now converts to string before checking `.empty?` to prevent NoMethodError

## [0.33.5] - 2026-01-11

### Added
- Show parent task context for orphan subtasks in filtered results
  - Parent tasks display with `[context]` indicator when their subtasks match filter criteria
  - Subtasks displayed under parent with tree connectors (├─ and └─)
  - Parent does not count toward result count (it's context, not a match)

### Fixed
- Wrap CLI-invoking tests with `with_real_test_project` to prevent creating test artifacts in actual project directory

## [0.33.4] - 2026-01-11

### Fixed
- Wrap CLI-invoking tests with `with_real_test_project` to prevent creating test artifacts in actual project directory

### Added
- Improve idea subcommand handling with nested commands

### Technical
- Merge philosophy and what-do-we-build into vision.md, streamline README

## [0.33.3] - 2026-01-10

### Fixed
- Fixed double content push in `idea create` when using `--note` flag
  - Changed flag order to add flags before positional content
  - Skip positional content when `--note` is provided to avoid duplication

### Added
- Added CLI routing tests for nested idea subcommands
  - 15 new tests covering create, done, park, unpark, reschedule
  - Tests verify proper routing with flags and arguments

### Changed
- Extracted CLI routing logic to use shared `Ace::Core::CLI::DryCli::DefaultRouting` module
  - Removed duplicate routing code in favor of shared implementation
  - Maintains same behavior with less code duplication

## [0.33.2] - 2026-01-10

### Fixed
- Migrate idea subcommands to nested dry-cli commands
  - Created 5 new nested subcommand classes: `Create`, `Done`, `Park`, `Unpark`, `Reschedule`
  - Updated `CommandRouter` molecule to support idea subcommand routing
  - Added `IDEA_SUBCOMMANDS` constant for routing disambiguation
  - Changed `CLI::Idea` to use `options[:args]` pattern (no argument declarations)
  - Fixes `idea create -gc` and other subcommand+flag combinations

### Technical
- Added regression tests for CLI routing with flags

## [0.33.1] - 2026-01-09

### Added
- **BREAKING**: Migrate task subcommands to nested dry-cli commands
  - Created 11 new nested subcommand classes: `Create`, `Show`, `Start`, `Done`, `Move`, `Update`, `Defer`, `Undefer`, `Undone`, `AddDependency`, `RemoveDependency`
  - Implemented `CommandRouter` molecule to disambiguate between `task <ref>` and `task <subcommand>`
  - Added comprehensive tests for create command
  - Updated `CLI` and `CLI::Task` registration to use nested subcommands

### Fixed
- Correct require_relative path for molecules in show command

### Changed
- Refactored create command to use TaskManager directly

## [0.33.0] - 2026-01-09

### Removed
- **BREAKING**: Backward compatibility for legacy idea file formats
  - Removed support for `idea.s.md` files (only `.idea.s.md` supported)
  - Removed support for `.s.md` flat files in ideas root
  - Migration completed: All 1,142 legacy idea files migrated to new format
- **BREAKING**: Backward compatibility for legacy retrospective date formats
  - Removed support for `YYYY-MM-DD-{slug}.md` format
  - Removed support for `YYYYMMDD-{slug}.md` format
  - Only Base36 ID format `{base36-id}-{slug}.md` supported
  - Migration completed: All 1,071 legacy retro files migrated to new format

### Changed
- Simplified idea file discovery logic (removed 3-priority fallback system)
- Simplified retro date extraction (Base36-only parsing, removed legacy formats)
- Removed 3 constants from IdeaLoader (PREFERRED_IDEA_EXT, ALTERNATIVE_IDEA_EXT, LEGACY_IDEA_FILE)
- Reduced codebase by ~150 lines of backward compatibility logic
- Removed 7 backward compatibility tests, added 2 new validation tests
- Updated README to remove migration sections and document current format

### Technical
- Simplified `load_all_with_glob` to only match `.idea.s.md` files
- Simplified `load_idea_from_directory` to single glob operation
- Simplified `extract_date_from_filename` to Base36-only parsing
- Removed `is_directory_based` detection logic
- Removed priority-based file selection system

## [0.32.0] - 2026-01-08

### Added
- Descriptive slug support for idea filenames using `{slug}.idea.s.md` pattern
- Base36 compact ID format for retrospective filenames
- File discovery priority for `.idea.s.md` format (preferred > alternative > legacy)
- Directory deduplication in IdeaLoader to prevent duplicate loading
- Title extraction from content header for all ideas (not just when include_content is true)
- `file_path` attribute to idea data for resolved file path (eliminates redundant I/O)
- `resolve_idea_file_path` helper in IdeasCommand for correct file path resolution
- Backward compatibility tests for mixed idea format support
- 5 new tests for `file_path` resolution across all idea formats

### Changed
- IdeaWriter creates files with `.idea.s.md` extension instead of `.s.md`
- **BREAKING**: RetroManager generates `{base36-id}-{slug}.md` filenames instead of `{date}-{slug}.md`
  - RetroLoader now decodes Base36 timestamps for date extraction
  - Legacy date-prefixed retros remain readable (dual-format detection)
- IdeaLoader file discovery prioritizes `.idea.s.md` over other formats
- IdeaLoader returns `file_path` in data hash (removes need for Command-layer resolution)
- IdeasCommand displays actual file paths using `idea[:file_path]` instead of calling `resolve_idea_file_path`
- IdeaLoader optimized to use single glob operation for all `.s.md` files

### Fixed
- Retro date parsing regression for Base36 filenames (now decodes via `Ace::Timestamp.decode`)
- Redundant file I/O in ideas display loops (file_path now resolved once in IdeaLoader)
- Removed duplicate `resolve_idea_file_path` method from IdeasCommand (now handled by IdeaLoader)

### Technical
- Added `ace/timestamp` require to RetroManager for Base36 ID generation
- Updated test assertions for new `.idea.s.md` pattern in idea_writer and integration tests
- Added 4 new backward compatibility tests to idea_loader_test.rb
- Added 5 new `file_path` resolution tests to idea_loader_test.rb
- Removed unused `::Regexp` prefix (redundant within class scope)

## [0.31.0] - 2026-01-08

### Added
- SharedOptions module for DRY option definitions across CLI commands
- CLI routing tests for KNOWN_COMMANDS and command aliases
- `migrate-paths` alias for backward compatibility with Thor CLI naming

### Changed
- Migrated CLI framework from Thor to dry-cli
  - All commands now use dry-cli with consistent Registry pattern
  - Default command routing (`ace-taskflow 150` → `ace-taskflow task 150`) handled in `CLI.start`
  - Cache clearing integrated into CLI lifecycle
  - Type conversion for numeric options (limit, recently_done_limit, up_next_limit)
  - KNOWN_COMMANDS pattern with COMMAND_ALIASES for auto-derived command validation
  - Command aliases supported (e.g., `context` → `status`, `migrate-paths` → `migrate`)
- CLI wrapper commands now properly pass options to underlying command classes
  - `ideas`, `retros`, `doctor`, `migrate` commands accept all expected flags
  - Options merged via CommandOptionParser's `thor_options:` parameter

### Removed
- `thor` dependency (replaced with `dry-cli`)

## [0.30.0] - 2026-01-06

### Added
- Base36 compact ID support for idea directories (default format)
- Base36 compact ID extraction from idea titles
- Configurable `id_format` option in `.ace/taskflow/config.yml` (base36 or timestamp)

### Changed
- **BREAKING**: Default idea directory naming changed from 14-character timestamps (YYYYMMDD-HHMMSS) to 6-character Base36 compact IDs
  - Example: `20250106-123000-dark-mode` → `i50jj3-dark-mode`
  - Existing timestamp-formatted directories remain readable (dual-format detection)
  - To restore legacy format, set `id_format: "timestamp"` in config
  - See README for migration notes and precision details (~1.85s precision)

## [0.29.1] - 2026-01-06

### Fixed
- Recently completed tasks not appearing in "Recently Done" section of `ace-taskflow status`
  - Added missing `:modified` sort case to `DependencyResolver.apply_standard_sort()`
  - Tasks are now correctly sorted by file modification time
  - Subtasks completed recently now appear alongside parent tasks

## [0.29.0] - 2026-01-05

### Changed
- Adopted `ConfigSummary.display_if_needed` pattern in TaskCommand
  - Configuration summary now only displays with `--verbose` flag
  - Help text remains clean and uncluttered
  - Aligned with ace-support-core 0.18.0 conditional config display behavior

### Fixed
- Config summary output appearing with `--help` commands in task commands
  - Applied conditional display logic to TaskCommand
  - Tests added for help detection behavior

## [0.28.1] - 2026-01-05

### Added
- Unified `CommandOptionParser` molecule with composable option sets (display, release, filter, limits, subtasks, sort, actions, help)
- Custom options support via block syntax for command-specific flags

### Changed
- Migrated all command classes to use CommandOptionParser, removing manual `while` loops
- Removed ARGV reconstruction patterns from TasksCommand, ReleasesCommand
- Commands now receive options hash directly instead of parsing raw args
- Net reduction of 357 lines of parsing code

## [0.28.0] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.27.2] - 2026-01-04

### Fixed

- Doctor command now respects configured archive directory (`directories.completed`) instead of hardcoded `/done/` pattern in task location validation
- Improved path matching regex to avoid substring false positives when validating task locations against archive directory

### Technical

- Added regression tests for custom `done_dir` configuration
- Updated README to reference configurable archive directory instead of hardcoded "done/" folder
- Test factory now uses configured directory names for proper test fixture generation

## [0.27.1] - 2026-01-03

### Changed

- Migrated 19 workflow instructions from `ace-nav wfi://` to `ace-context wfi://` for consistency
- Standardizes on ace-context for all workflow discovery across the package

## [0.27.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.26.3] - 2026-01-03

### Added

- `with_real_test_project` composite helper in test_helper.rb to reduce test nesting from 3 levels to 1

### Changed

- Refactor test helpers to use `with_real_config` pattern for better test isolation and performance

### Technical

- Test performance optimization: reduce test execution time from 10s to under 5s through proper test_mode usage

## [0.26.2] - 2026-01-01

### Fixed

- Fix `ace-taskflow task move <TASK_REF> --backlog` command failing with "undefined method 'backlog_dir' for an instance of Hash"

### Changed

- Use Ace::Taskflow.configuration for accessing Configuration object methods in TaskManager#resolve_release_path

## [0.26.1] - 2025-12-30

### Changed

* Replace ace-support-core dependency with ace-config for configuration cascade
* Migrate from Ace::Core to Ace::Config.create() API

## [0.26.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory

## [0.25.0] - 2025-12-27

### Added

- Migrate configuration to ADR-022 pattern with `.ace.example/` defaults
  - Load defaults from `.ace.example/taskflow/` at runtime
  - Merge user config over defaults using deep merge
  - Support backward compatibility for renamed keys

### Fixed

- Improve warning message clarity for missing example config
- Address PR review feedback for configuration loading
- Add warning when example config not found
- Restore richer idea.template format with full metadata structure

## [0.24.6] - 2025-12-27

### Fixed

- Prevent hidden `.s.md` filenames when `file_slug` is empty
  - IdeaWriter now checks `!file_slug.to_s.strip.empty?` before using slug
  - Falls back to `idea.s.md` when slug is empty/blank
  - Fixes issue where ideas were created with hidden filenames not discoverable by `ace-taskflow ideas`

## [0.24.5] - 2025-12-26

### Technical

- Add explicit PR review instructions to work-on-subtasks workflow
  - Use `ace-review --preset code --pr <number>` for subtask PRs
  - Document how to get PR number from `ace-git status`
  - Explain why `--pr` flag is required (targets orchestrator branch, not main)

## [0.24.4] - 2025-12-26

### Changed

- **BREAKING**: Config keys renamed from `context.activity.*` to `status.activity.*`
  - Update `.ace/taskflow/config.yml` to use `status` instead of `context`
  - Consistent with command name (`ace-taskflow status`)

### Fixed

- Remove redundant string prefix check in status_command relative path formatting
  - Simplified to use Pathname#relative_path_from consistently
  - More robust for case-insensitive filesystems and symlinks

### Technical

- Clarify worktree isolation in work-on-subtasks workflow
  - Add Critical: Worktree Isolation section explaining ace-git-worktree usage
  - Simplify step 3.1 to use ace-git-worktree create --task
  - Update subagent delegation with explicit worktree path verification

## [0.24.3] - 2025-12-25

### Added

- **`--[no-]include-activity` CLI flag**: Disable entire activity section for simpler output
  - `ace-taskflow status --no-include-activity` hides Recently Done, In Progress, and Up Next
  - Works with both markdown and JSON output formats
- **"completed" status support**: Recently Done section now includes both "done" and "completed" statuses
  - Ensures comprehensive activity tracking for projects using either convention

### Changed

- **Performance optimization**: Short-circuit evaluation when limits are zero
  - `find_recently_done` and `find_up_next` return early when limit=0, avoiding unnecessary filtering/sorting
- **UTF-8 BOM handling**: CodenameExtractor now strips UTF-8 BOM from README.md files

### Fixed

- Debug logging now uses `Ace::Core.logger.debug` for consistency across the codebase

## [0.24.2] - 2025-12-25

### Changed

- **BREAKING**: Renamed `context` subcommand to `status`
  - Better reflects the command's purpose of showing live operational state
  - Usage: `ace-taskflow status`
  - All options remain the same: `--json`, `--recently-done-limit`, `--up-next-limit`, `--include-drafts`
- **Limit=0 Behavior**: Sections now skip entirely when limit is set to 0
  - `--recently-done-limit 0` hides Recently Done section (no empty message)
  - `--up-next-limit 0` hides Up Next section (no empty message)

### Fixed

- Zero-limit CLI options now correctly propagate (using `options.key?` instead of truthiness)
- Updated stale comments referencing "context" to "status" in source and config
- Clarified ADR-022 fallback defaults in TaskActivityAnalyzer documentation

## [0.24.1] - 2025-12-24

### Added

- **Task Activity Awareness**: Status command (formerly context) shows task activity section
  - Recently Done: Last 3 completed tasks with relative timestamps
  - In Progress: Other in-progress tasks (excluding current)
  - Up Next: Next 3 pending tasks in priority order
  - Includes worktree indicators for parallel work awareness

### Fixed

- **Release Stats**: Status command now uses accurate release statistics
  - Reuses StatsFormatter from tasks command for consistent done/total counts
  - Shows "## Release: v.X.Y.Z: done/total tasks • Codename" format
  - Previously showed incorrect 0% progress due to different counting methodology

## [0.24.0] - 2025-12-23

### Added

- **Status Command**: Parent task context display for subtasks
  - When current task is a subtask, shows parent orchestrator task with full details
  - Adds `### Parent Task` header for clear visual separation
  - Automatically extracts parent number from `parent_id` field (e.g., "v.0.9.0+task.140" → "140")

- **Status Command**: `ace-taskflow status` provides task-aware repository context
  - Combines git state from ace-git with taskflow information
  - Resolves current task from branch pattern
  - Includes release progress and PR metadata
  - Supports `--json` and `--no-pr` options
  - **Compact output format**: Uses inline key-value format instead of markdown tables (matches ace-git context style)
  - **Integrated task details**: Displays full `ace-taskflow task` command output for complete task information
  - **Status icons**: Uses emoji indicators (🟡, 🟢, ⚪, etc.) instead of text status in headers
  - **Smart PR formatting**: Shows PR author as "login (name)" instead of raw hash
  - **Subtask awareness**: Shows parent task context when current task is a subtask

- **TaskflowContextLoader Organism**: Orchestrates loading complete taskflow context
  - Uses Ace::Git::Organisms::RepoContextLoader for repository context
  - Passes through RepoContext objects directly instead of converting to hashes (code reuse)
  - Resolves task from branch pattern via TaskLoader
  - Calculates release progress from statistics
  - Added `parent` field to task data for subtask context

- **GitCommitter Molecule**: Thin wrapper around ace-git for commit operations
  - Backward-compatible Result struct matching former GitExecutor interface
  - Uses Ace::Git::Atoms::CommandExecutor for git operations

### Changed

- **Context Command**: Refactored to reuse ace-git ContextFormatter
  - Uses `Ace::Git::Atoms::ContextFormatter.to_markdown` for git section formatting
  - Injects release progress info into repository display
  - Removed duplicate formatting code (~60 lines reduced)
  - Extracted subprocess calls into mockable `fetch_task_output` method for testability

- **Dependencies**: Added ace-git (~> 0.3) as runtime dependency for git operations

- **Tests**: Made context command tests deterministic and faster
  - Tests now mock subprocess calls instead of running real `ace-taskflow task` commands
  - 65x faster test execution (13ms vs 860ms)
  - Updated organism tests to work with RepoContext objects instead of hash structures

- **IdeaWriter**: Updated to use GitCommitter instead of GitExecutor
  - Improved path handling (supports directories)
  - Same functional behavior with ace-git backend
  - **Breaking (Internal)**: GitExecutor → GitCommitter - internal API change only

### Removed

- **GitExecutor Molecule**: Removed in favor of ace-git dependency
  - Functionality replaced by GitCommitter using ace-git
  - Associated tests migrated to git_committer_test.rb

## [0.23.1] - 2025-12-13

### Changed

- **GTD Naming Convention**: Renamed internal directory concepts to align with GTD methodology
  - `deferred` → `anyday` (tasks for anytime, no urgency)
  - `parked` → `maybe` (ideas that might happen)
  - Config keys updated: `anyday_dir`, `maybe_dir`

- **Dynamic Folder Names**: User messages in CLI now use configuration values instead of hardcoded folder names
  - `idea park/unpark` commands show actual folder from `maybe_dir` config
  - Help text reflects configured directory names

### Fixed

- **Duplicate Method Definitions**: Removed duplicate `park_idea`, `unpark_idea` methods in idea_command.rb
- **Duplicate Method Definitions**: Removed duplicate `defer_task`, `undefer_task`, `reopen_task` methods in task_command.rb

### Technical

- Added explanatory comment to `find_taskflow_root` in migrate_command.rb documenting why it's a local implementation
- Removed unused `pending` directory config

## [0.23.0] - 2025-12-13

### Added

- **Folder Migration Command**: `ace-taskflow migrate` renames old folder structure to new underscore-prefixed format
  - Renames `done/` → `_archive/`, `backlog/` → `_backlog/`
  - Supports `--dry-run`, `--verbose`, `--no-git` flags
  - Uses `git mv` when in git repository to preserve history
  - Cross-platform path handling with Pathname

- **Task Lifecycle Commands**:
  - `ace-taskflow task defer TASK_REF` - Move task to `_deferred/` folder for later revisit
  - `ace-taskflow task undone TASK_REF` - Reopen completed task, restore from `_archive/`
  - `ace-taskflow idea park IDEA_REF` - Move idea to `_parked/` folder

- **ADR-022 Configuration Pattern**: Default config loading from `.ace.example/`
  - Single source of truth for defaults in `.ace.example/taskflow/config.yml`
  - Runtime loading with error on missing file (packaging error detection)
  - Deep merge of user config over gem defaults
  - `reset_gem_defaults!` method for test isolation

### Changed

- **Directory Naming**: System directories now use underscore prefix for clarity
  - `done/` → `_archive/` (completed tasks)
  - `backlog/` → `_backlog/` (future releases)
  - New `_deferred/` (tasks to revisit later)
  - New `_parked/` (ideas that are good but not now)

- **Configuration Key Rename**: `directories.done` → `directories.completed`
  - Backward compatible: old key still works
  - Semantic naming to avoid confusion with `done` status value

### Fixed

- **Deprecation Warning**: `mark_idea_done` now uses `move_to_archive` instead of deprecated `move_to_done`
- **Path Handling**: FolderMigrator uses `Pathname#relative_path_from` for cross-platform robustness

## [0.22.0] - 2025-12-09

### Added

- **Bug Workflows**: Two complementary workflows for systematic bug handling
  - `analyze-bug.wf.md`: Gathers bug info, attempts reproduction, identifies root cause, proposes regression tests, creates fix plan
  - `fix-bug.wf.md`: Executes fix plan, creates regression tests, verifies resolution
  - Claude command wrappers: `/ace:analyze-bug`, `/ace:fix-bug`
  - Analysis caching in `.cache/ace-taskflow/bug-analysis/` for workflow continuity

## [0.21.1] - 2025-12-09

### Fixed

- **Convert to Orchestrator**: Create proper orchestrator + subtask structure
  - Previously just renamed task file to `.00-orchestrator.s.md`, losing original as actionable work
  - Now creates new orchestrator file (`.00`) with minimal template
  - Moves original task content to subtask `.01` with updated ID and parent field
  - Enables expected workflow where converting preserves original work as first subtask

### Changed

- **Task Reorganization Docs**: Update `reorganize-tasks.wf.md` for new convert behavior
  - Document that original task becomes subtask `.01`
  - Update example output to show orchestrator and subtask paths

## [0.21.0] - 2025-12-09

### Added

- **Task Reorganization Workflow**: Restructure task hierarchy with `move --child-of`
  - `ace-taskflow task move SUBTASK --child-of` promotes subtask to standalone task
  - `ace-taskflow task move TASK --child-of PARENT` demotes task to subtask under parent
  - `ace-taskflow task move TASK --child-of self` converts standalone to orchestrator
  - `--dry-run` flag previews operations without executing
  - New `reorganize-tasks.wf.md` workflow documentation
  - Preserves auxiliary files (docs/, notes) during demotion

### Changed

- **Task Move Command**: Enhanced with `--child-of` option for hierarchy reorganization
  - Coexists with existing release move functionality (`--release`, `--backlog`)
  - Improved argument parsing with OptionParser

## [0.20.2] - 2025-12-09

### Fixed

- **Doctor Health Checks**: Improve scanning exclusions and validation
  - Exclude `review/`, `docs/`, `qa/`, and `.backup.*` files from task scanning
  - Accept terminal states (`superseded`, `cancelled`, `skipped`) in done/ directory
  - Support hierarchical subtask IDs in frontmatter validation (e.g., `v.X.Y.Z+task.NNN.NN`)
- **Task Directory Mover**: Add backup file cleanup before moving to done/
  - Automatically remove `.backup.*` files when moving tasks to done/ directory
- **Statistics Counting**: Restrict glob to `tasks/` directory only
  - Prevents matching idea files with task-like naming patterns in `docs/ideas/`
  - Ensures accurate task counts and completion percentages

## [0.20.1] - 2025-12-02

### Fixed

- **IdeaDirectoryMover Normalization**: Fix `move_to_done` to normalize file paths to folder paths
  - When passed a file path inside an idea folder, now moves entire folder (not just the file)
  - Consistent behavior whether file or folder reference is passed
  - Prevents incorrect `ideas/IDEA/done/` subfolder structure

### Changed

- **Documentation**: Update `draft-task.wf.md` for idea done command
  - Clarify to use folder reference, not file path
  - Document correct behavior: moves entire folder to `ideas/done/`

## [0.20.0] - 2025-11-27

### Added

- **Subtask Workflow Support**: Comprehensive hierarchical task execution workflow for task 122
  - Added CLI support for subtasks with `--child-of` flag for creating hierarchical task relationships
  - Added task scanner support for orchestrator + subtask patterns to identify parent-child relationships
  - Added orchestration workflow for subtask execution with automated cascade handling
  - Honor `--release/--backlog` with `--child-of` for proper task placement in context hierarchy
  - Fixed display formatting and lifecycle management for hierarchical tasks
  - Made terminal statuses configurable through project configuration
  - Addressed code review feedback across multiple subtasks (122.03, 122.04, 122.05, 122.07, 122.08)
  - Updated task_manager test fixture to use configured task_dir for proper test isolation

### Fixed

- **Task Manager Test Configuration**: Fixed test fixture to use configured task_dir instead of hardcoded paths
  - Ensures proper test isolation and respects project configuration settings
  - Prevents test pollution across different task directory configurations

### Technical

- Clarified dynamic PR base branch documentation in work-on-subtasks workflow

## [0.19.3] - 2025-11-17

### Changed

- **Task Reference Format Standardization**: Introduced 'task.' prefix for qualified references
  - Updated qualified references from `v.0.9.0+018` to `v.0.9.0+task.018`
  - Modified `PathBuilder` to include 'task.' prefix when constructing qualified references
  - Updated `TaskReferenceParser` to parse both old and new formats for backward compatibility
  - Adjusted `Task` model to use new format for qualified task identifiers
  - Updated `TestFactory` to generate test data with standardized format
  - Ensures consistent and unambiguous format for task references across the system

## [0.19.2] - 2025-11-16

### Fixed

- **Task Counting Bug**: Fixed statistics counting where pending tasks showed incorrect count (3 instead of 12)
  - Updated `get_statistics` glob pattern to match both old format (`task.NNN.s.md`) and new hierarchical format (`NNN-slug.s.md`)
  - Standardized all task IDs to canonical format (`v.0.9.0+task.NNN`) for consistent task reference resolution
  - Updated test expectations to match canonical format
  - Ensures accurate task statistics across all task naming formats

### Technical

- Updated capture-idea workflow documentation with current API and examples
- Applied code review feedback improvements for better maintainability
- Improved idea create output to show full file path instead of folder path

## [0.19.1] - 2025-11-15

### Changed

- **Task 111 Completion**: Marked task 111 (Fix ace-review cache path resolution in git worktrees) as done
  - Moved task file from `tasks/` to `tasks/done/` folder
  - All success criteria met and verified
  - Core fix implemented and tested

## [0.19.0] - 2025-11-15

### Added

- **Idea Folder Structure Validation and Enforcement**: Comprehensive validation system for idea file organization
  - New `validate-structure` command checks idea file organization with detailed error reporting
  - Enforces ideas must be in subfolders within ideas/ directory (e.g., `ideas/folder-name/file.md`)
  - Provides clear error messages with suggested proper locations for misplaced files
  - Warning shown in `ideas` list command when misplaced ideas are detected
  - Environment variable `SKIP_IDEA_VALIDATION` available for performance optimization in large repositories
  - Comprehensive YARD documentation with exit codes (0=success, 1=failures) for CI/CD integration
  - 26 comprehensive tests covering all validation scenarios including edge cases
  - Command integrated into help text for easy discoverability

### Changed

- **Idea Create Output Enhancement**: Improved `ace-taskflow idea create` output to display full file path instead of just folder path
  - Modified `IdeaWriter#write` to return complete path to created `.s.md` file
  - Updated output message to show exact file created (e.g., `.ace-taskflow/v.0.9.0/ideas/20251115-085126-test/test.s.md`)
  - Makes it immediately clear which file was created and easier to open in editors
  - Added YARD documentation for `IdeaWriter#write` method with parameter and return value specifications
  - Added regression test to ensure file path (not directory) is returned
- **Code Quality Improvements**: Refactored path formatting for better maintainability
  - Removed duplicate `format_path_relative_to_pwd` method from `IdeaCommand`
  - Now uses `Atoms::PathFormatter.format_relative_path` for DRY principle
  - Eliminates code duplication across command classes

## [0.18.4] - 2025-11-04

### Fixed

- **Task Update Command Restoration**: Restored the complete `ace-taskflow task update` command implementation that was accidentally deleted in commit 54cac8b3
  - Restored `TaskFieldUpdater` molecule for field parsing and validation
  - Restored `FieldArgumentParser` molecule for CLI argument parsing
  - Restored `update_task` method in `task_command.rb` with full help text and examples
  - Restored `update_task_fields` in `task_manager.rb` for task orchestration
  - Restored `update_task_field` in `task_loader.rb` using ace-support-markdown integration
  - Restored comprehensive unit tests (10 tests, 19 assertions)
  - Command supports `--field key=value` syntax for simple and nested YAML updates
  - Enables worktree metadata updates for ace-git-worktree integration (task 089)
  - Updated task 089 with verified working examples and implementation notes

## [0.18.3] - 2025-11-04

### Fixed

- **Task Header Statistics**: Fixed missing three-line header with release statistics in `ace-taskflow tasks` output
  - Fixed `StatsFormatter#initialize` (line 36) to pass `@root_path` to `ReleaseResolver.new`
  - Fixed `TasksCommand#initialize` to initialize `@root_path` and pass it to `StatsFormatter.new`
  - Header now correctly displays release info, idea stats, and task counts instead of minimal "X tasks" output
  - Pre-existing bug (not introduced by unified filter PR) that manifested when running from subdirectories

## [0.18.2] - 2025-11-04

### Fixed

- **Releases Preset Type Dispatch**: Fixed `releases_command.rb` to correctly pass `:releases` type parameter to `ListPresetManager.apply_preset` method (3 occurrences at lines 64, 70, 251)
  - Without this fix, release-specific presets (e.g., `type: "releases"`) would fail to load, falling back to `:tasks` namespace and returning "preset not found" error
  - Affected commands: `ace-taskflow releases <preset>`, `ace-taskflow releases --stats`
  - Identified by GPT-5 code review (review-20251104-005003)

## [0.18.1] - 2025-11-04

### Fixed

- **Return Value Consistency**: Fixed `releases_command.rb` to return error code `1` instead of `nil` when preset configuration fails
- **Error Message Whitespace Handling**: Fixed legacy flag error messages to properly handle spaces after commas (e.g., `--status pending, done` now correctly suggests `--filter status:pending|done` instead of `--filter status:pending| done`)
  - Updated error message conversion in `tasks_command.rb` for `--status` and `--priority` flags
  - Updated error message conversion in `ideas_command.rb` for `--status` and `--priority` flags

## [0.18.0] - 2025-11-04

### Added

- **Unified Filter System**: New `--filter key:value` syntax replaces legacy filtering flags across tasks, ideas, and releases commands
- **FilterParser Atom**: Parses filter syntax with support for OR values (`key:value1|value2`), negation (`key:!value`), and array matching
- **FilterApplier Molecule**: Applies filter specifications with AND logic across filters and OR logic within filters
- **Filter-Clear Flag**: `--filter-clear` option to override preset filters while keeping release/scope/sort configuration
- **Universal Field Filtering**: Filter by any frontmatter field including custom fields (e.g., `--filter team:backend`, `--filter sprint:12`)
- **Comprehensive Test Coverage**: 52 new tests (23 for FilterParser, 29 for FilterApplier) with 100% pass rate

### Changed

- **BREAKING**: Removed `--status` flag from tasks/ideas commands - use `--filter status:value` instead
- **BREAKING**: Removed `--priority` flag from tasks/ideas commands - use `--filter priority:value` instead
- **BREAKING**: Removed `--active` flag from releases command - use `--filter status:active` instead
- **BREAKING**: Removed `--done` flag from releases command - use `--filter status:done` instead
- **BREAKING**: Removed `--backlog` flag from releases command - use `--filter status:backlog` instead
- Updated all command help text with new filter syntax, operators, and examples
- Enhanced TaskFilter molecule to integrate with FilterApplier for universal filtering

### Technical

- Helpful error messages show exact migration syntax when legacy flags are used
- Clean break approach for backward compatibility (no deprecation period)
- Comprehensive usage guide with 30+ examples in `ux/usage.md`
- Fixed test suite to use new filter syntax

## [0.17.0] - 2025-11-02

### Added

- **Flexible Task Transitions**: Tasks can now transition from any status directly to "done" without requiring intermediate steps (default behavior)
- **Custom Status Support**: Support for custom statuses like "ready-for-review" that aren't in the predefined status list
- **Idempotent Operations**: Running `task done` or status updates multiple times succeeds gracefully with informative messages instead of errors
- **Configuration Support**: New `strict_transitions` config option to enable rigid status validation (opt-in for legacy behavior)
- **Enhanced User Feedback**: Context-aware messages distinguish between new transitions, no-op operations, and already-satisfied states

### Fixed

- **Critical Bug - Frontmatter Corruption**: Replaced dangerous regex-based frontmatter editing with safe `DocumentEditor` from ace-support-markdown, preventing task files from being corrupted to 3 lines
- **Task Directory Mover Idempotency**: Moving tasks to done/ directory now succeeds when task is already in done/ instead of failing

### Changed

- **Default Behavior**: Flexible transitions are now the default (can transition from any status to any other status)
- **Status Validator**: Updated to support both flexible and strict modes with idempotency checks
- **Task Manager**: Enhanced to read configuration and provide better error messages

### Technical

- Added comprehensive test coverage: 12 new tests for flexible validation, 10 new tests for idempotent operations, 5 new safety tests for frontmatter preservation
- Updated existing tests to explicitly use strict mode where appropriate for backward compatibility

## [0.16.1] - 2025-11-02

### Added

- Enhance array parsing to handle quoted items with commas in CLI arguments

### Fixed

- Prevent accumulating newlines in task update command
- Address code review feedback for task update command

### Changed

- Complete ace-support-markdown integration for document manipulation
- Extract CLI parsing logic to FieldArgumentParser molecule
- Address code review feedback for task update command

## [0.16.0] - 2025-11-02

### Added

- **Task Update Command**: Implemented `ace-taskflow task update` command for updating task metadata fields
  - Support for updating any frontmatter field via `--field key=value` syntax
  - Dot notation support for nested YAML structures (e.g., `worktree.branch=value`)
  - Multiple `--field` flags for batch updates in a single command
  - Smart type inference for integers, floats, booleans, arrays, and strings
  - Atomic file writes with automatic timestamped backups
  - Comprehensive error handling with specific exit codes (0=success, 1=not found, 2=invalid syntax, 3=write error)
  - 34 comprehensive test cases covering all functionality
  - Primary use case: Enable ace-git-worktree to add worktree metadata to tasks

### Fixed

- Address code review feedback on documentation and hygiene
- Handle directory-based ideas in glob matching for idea_loader
- Correct Symbol loading and update task metadata
- Rename 'context' to 'release' across the codebase for consistency
- Remove hardcoded directory names from glob patterns
- Update file extension from .md to .s.md for task files
- Update TaskReferenceParser to return :release key
- Improve glob filtering and handle empty results

### Changed

- Refactor: Extract filter_glob_by_type to shared helper for better code organization
- Refactor: Rename 'context' to 'release' across the project for clarity
- Refactor: Rename context to release for IdeaLoader
- Refactor: Extract glob filtering logic to helper method
- Refactor: Refactor preset and configuration architecture

### Technical

- Update tests to use release parameter
- Rename infrastructure gems (ace-core → ace-support-core, ace-test-support → ace-support-test-helpers)
- Bump versions for dependency updates (0.15.0, 0.15.1)

## [0.15.2] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.15.1] - 2025-11-01

### Fixed

- **YAML Parser**: Added `Symbol` to permitted classes in `YamlParser.parse_frontmatter` to fix "Tried to load unspecified class: Symbol" error when running `ace-taskflow doctor` on files with Symbol-style YAML keys (`:key_name` format)
- **Task Metadata**: Fixed incomplete frontmatter in tasks 074 and 075 (missing closing `---` delimiter, priority, estimate, and dependencies fields)
- **Task Dependencies**: Removed invalid dependency references to non-existent `task.079` in tasks 081 and 082

### Changed

- Tasks 074 and 075 now include minimal task descriptions for better documentation

## [0.15.0] - 2025-11-01

### 🚨 Breaking Changes

#### API Renaming: Context → Release

Complete terminology change across the entire codebase for improved clarity. The term "release" better reflects the purpose of identifying which version/scope an item belongs to.

**Affected Components:**

- **Models**: `Task#context` → `Task#release`, `Idea#context` → `Idea#release`
- **Commands**: All CLI commands now use `--release` instead of `--context`
- **Configuration**: Preset YAML files now use `release:` key instead of `context:`
- **API Methods**: All method parameters renamed from `context` to `release`
- **Internal Components**: TaskReferenceParser, validators, formatters, loaders

**Migration Guide:**

For Ruby API usage:

```ruby
# Before
loader.load_all(context: "current")
task = Task.new(context: "v.1.0.0")

# After
loader.load_all(release: "current")
task = Task.new(release: "v.1.0.0")
```

For YAML preset files:

```yaml
# Before
context: current

# After
release: current
```

For CLI commands:

```bash
# Before
ace-taskflow tasks --context v.0.9.0

# After
ace-taskflow tasks --release v.0.9.0
```

**Impact**: 53+ files changed across models, commands, molecules, organisms, and tests. All existing code and configurations using `context` must be updated to use `release`.

### Changed

- **Architecture Improvements**:
  - Refactored preset and configuration architecture for better maintainability
  - Enhanced ListPresetManager with improved glob handling and error messages
  - Extracted `filter_glob_by_type` to shared `commands/helpers.rb` module
  - Reduced code duplication across IdeasCommand and TasksCommand
  - Improved PathBuilder and loader architecture

### Fixed

- **Glob Pattern Handling**: Removed hardcoded directory names from glob patterns
  - Added `Configuration#default_glob_pattern` method (returns `['**/*.s.md']`)
  - Single source of truth for default glob patterns
  - Patterns now automatically prefixed with correct directory (ideas/ or tasks/)

- **Empty Results Handling**: Improved glob filtering and error handling for empty result sets

- **File Extension References**: Fixed remaining `.md` references that should be `.s.md` in:
  - ReleaseResolver
  - StructureValidator
  - TaskManager

- **TaskReferenceParser**: Updated to return `:release` key instead of `:context` for consistency

### Technical

- Updated all 734 tests to use `release` parameter naming
- Comprehensive refactoring across 36+ files in final context→release migration
- All tests passing with new terminology

## [0.14.2] - 2025-11-01

### Added

- Use .s.md extension and clarify GTD scope

## [0.14.1] - 2025-11-01

### Added

- Implement .s.md extension and remove backward compatibility
- Implement glob-based preset system for ideas and tasks

### Fixed

- Adjust universal presets and statistics logic
- Require configuration and update universal preset expectations
- Fix glob patterns to be relative to ideas directory
- Address PR review feedback and fix failing tests

### Changed

- Clarify comments and refine exception handling
- Make presets universal and parse status/priority

## [0.14.0] - 2025-10-26

### 🚨 Breaking Changes

#### File Extension Migration

- **All spec files now use `.s.md` extension** (specification markdown)
  - Ideas: `*.md` → `*.s.md` (212 files migrated)
  - Tasks: `task.*.md` → `task.*.s.md` (623 files migrated)
  - Clear separation: `.s.md` = specifications, `.md` = documentation only

#### API Changes

- **`IdeaLoader#load_all` signature changed**:
  - **Removed**: `scope` parameter
  - **Added**: `glob` parameter (optional, defaults to `["**/*.s.md"]`)
  - Example: `loader.load_all(context: "current", glob: ["maybe/**/*.s.md"])`
- **Removed backward compatibility**: `PRESET_TO_SCOPE` constant deleted from IdeasCommand

#### Configuration Changes

- Simplified config: `ideas: "ideas"` (folder name only, not path)
- Removed path-splitting logic duplication from configuration

### Migration Guide

For custom scripts using the API:

```ruby
# Before
loader.load_all(context: "current", scope: :maybe)

# After
loader.load_all(context: "current", glob: ["maybe/**/*.s.md"])
```

For file references in custom scripts:

```bash
# Update any hardcoded .md extensions to .s.md
# Ideas: 20251026-123456-title.md → 20251026-123456-title.s.md
# Tasks: task.088.md → task.088.s.md
```

**Note**: All existing files have been automatically migrated. This only affects new integrations.

### Added

- **Glob-Based Preset System**: Eliminated configuration duplication with self-defining presets
  - Presets now declare content via glob patterns that work universally across contexts
  - Simplified patterns: `maybe/**/*.s.md` vs previous complex type-specific patterns
  - Glob validation: Rejects dangerous characters and absolute paths
  - Universal patterns work across backlog and all releases
- **Maybe and Anyday Idea Scopes**: Support for organizing ideas by priority and timeline
  - New subdirectories: `ideas/maybe/` for uncertain ideas, `ideas/anyday/` for low-priority ideas
  - Preset support: `ace-taskflow ideas maybe` and `ace-taskflow ideas anyday`
  - Creation flags: `--maybe` and `--anyday` for `ace-taskflow idea create`
  - Statistics display with emoji indicators: 💡 (pending), 🤔 (maybe), 📅 (anyday), ✅ (done)

### Changed

- **Architecture Improvements**:
  - Added `determine_context_root()` to IdeaLoader - returns release/backlog root path
  - Refactored `determine_idea_directory()` to use context_root + folder name
  - Simplified `IdeaLoader#load_all` to only use glob-based loading
  - Added glob support to TaskLoader with `load_tasks_with_glob()`
  - Configuration simplified: folder names instead of paths
- **Code Quality Improvements**: Refactored implementation based on code review recommendations
  - Extract SCOPE_SUBDIRECTORIES constant to centralize scope definitions
  - Improve status determination using dirname inspection
  - Reduce code duplication in IdeaLoader with loop-based scope loading
  - Add validate_subdirectory_exclusivity helper for mutual exclusivity checks

### Technical

- Updated all 835 spec files to use `.s.md` extension
- Updated test fixtures and assertions for new extension
- Add glob pattern validation in ListPresetManager
- Clean up test artifacts and finalize task 088
- Fix missing final newlines in IdeaWriter templates for POSIX compliance
- Add comprehensive test coverage for --maybe/--anyday flag mutual exclusivity
- All 734 tests passing

## [0.13.2] - 2025-10-25

### Fixed

- **Task Sorting**: Correct task sorting logic for string/symbol keys in preset configurations
  - Tasks were displayed in reverse order when using `ace-taskflow tasks next` command
  - Fixed apply_preset_sorting to handle both string and symbol keys from YAML configs
  - Added comprehensive tests for ascending and descending sort orders

## [0.13.1] - 2025-10-24

### Fixed

- **Task File Corruption Prevention**: Fixed incomplete ace-support-markdown integration in task_loader.rb
  - `update_task_status` and `update_task_dependencies` now use SafeFileWriter for atomic writes with backups
  - Previously these methods used raw `File.write`, which could corrupt task files if interrupted
  - All file write operations in ace-taskflow now use SafeFileWriter for data protection
  - Backup files (*.backup.*) are created automatically before modifications

## [0.13.0] - 2025-10-23

### Added

- **task:// Protocol Configuration**: Added `.ace.example/nav/protocols/task.yml` for ace-nav integration
  - Enables `ace-nav task://083` to delegate to `ace-taskflow task 083`
  - Provides unified navigation interface across all ACE resources
  - Configuration supports all task reference formats and options (--path, --content, --tree)

## [0.12.1] - 2025-10-23

### Added

- Standardize idea file organization by using ace-taskflow idea done command in draft workflows

## [0.12.0] - 2025-10-23

### Changed

- Use ace-support-markdown for safe file operations, eliminating file corruption risk

## [0.11.5] - 2025-10-14

### Added

- Improve task reference parsing and loading with ID-based search
- Support v.0.9.0+task.070 reference format

### Fixed

- Fix task lookup for done tasks by searching on ID field instead of path-based extraction
- Enable simple references (072, task.072) to find tasks in done directory

### Technical

- Update work-on-task instructions for task selection

## [0.11.4] - 2025-10-14

### Added

- Standardize Rakefile test commands and add CI fallback
- Improve usability and add markdown style checks
- Add support for pending release directory

### Fixed

- Fix 17 atom test failures with architecture-compliant patterns
- Load configuration.rb to resolve NoMethodError
- Make directory names configurable in validators

### Changed

- Consolidate retro directory and update workflows
- Standardize directory names for retros and tasks
- Update task directory configuration
- Extract context resolution and task loading logic
- Use configuration for task directory paths
- Respect configured directory names for component type detection

### Technical

- Update usage.md with resolved configuration decisions

## [0.11.3] - 2025-10-14

### Fixed

- **Work-on-Task Workflow**: Simplified task selection and eliminated unnecessary complexity
  - Removed manual directory scanning and release path lookups
  - Updated workflow to use `ace-taskflow task <ref>` for all task lookups
  - Command now handles all reference formats: `071`, `task.071`, `v.0.9.0+071`
  - Removed unnecessary task listing commands from dependency checking
  - Clearer usage examples showing all supported reference formats
  - Agents no longer struggle to find tasks - single command handles everything

## [0.11.2] - 2025-10-08

### Fixed

- **Idea Create Error Handling**: Improved error handling for `--current` flag when no active release exists
  - When `--current` flag is explicitly provided but no active release is found, displays clear error message
  - Error message suggests creating a release with `ace-taskflow release create` or omitting `--current` to save to backlog
  - Prevents silent fallback to backlog when user explicitly requests current release
  - Note: The `--current` flag path resolution was already working correctly (fixed in v0.9.0)

## [0.11.1] - 2025-10-08

### Fixed

- **Exit Code Handling**: Fixed TypeError when executing tasks and ideas commands
  - `TasksCommand` display methods now return proper Integer exit codes (0 for success, 1 for errors)
  - Fixed `display_tasks_with_preset`, `display_tree_with_preset`, `display_paths_with_preset`, `display_list_with_preset`
  - Fixed `show_statistics_for_preset` to return exit codes
  - Fixed `execute_with_preset` to propagate exit codes from display methods
  - `IdeasCommand` display methods now return proper Integer exit codes
  - Fixed `display_ideas_with_preset`, `display_ideas_as_json`, `show_statistics_for_preset`
  - Resolves `TypeError: no implicit conversion of Array into Integer` when calling `exit(exit_code)`

## [0.10.2] - 2025-10-08

### Fixed

- **Test Isolation**: Fixed tests leaking artifacts to main project directory
  - `IdeaCommand` now initialized inside `with_test_project` blocks to respect stubbed project root
  - Prevents idea files from being created in `.ace-taskflow/v.0.9.0/ideas/` during test runs
  - Fixed in `test_create_idea_with_git_commit` and `test_idea_with_llm_enhancement`

- **Clipboard Tests**: Fixed 9 failing clipboard reader tests on macOS
  - Stubbed `ClipboardReader.macos_clipboard_available?` to return false in tests
  - Forces tests to use fallback `Clipboard` gem path they're designed to test
  - Previously failed because macOS code path uses `Ace::Support::MacClipboard` instead

- **Test Expectations**: Updated test assertions to match actual behavior
  - Fixed retro command tests to expect title format (e.g., "Test retro 1") not slug format
  - Fixed git commit test to use correct flag `--git-commit` instead of `--git`
  - Updated assertion to expect committed file (clean status) not staged

- **Warning Suppression**: Fixed Ruby 3.4 compatibility issue
  - Replaced non-existent `Warning.silence` with `$VERBOSE = nil` pattern
  - Applied to clipboard test constant redefinitions

### Technical

- All 700 tests now pass (0 failures, 0 errors, 83 skips)
- Test isolation properly prevents pollution of main project directory
- Clipboard tests work on all platforms through proper stubbing

## [0.10.1] - 2025-10-08

### Fixed

- **Test Execution**: Fixed critical issue where tests would halt mid-execution and not report results
  - Commands now return status codes instead of calling `exit` directly
  - `RetrosCommand` and `RetroCommand` refactored to return 0 (success) or 1 (failure)
  - `IdeaWriter` organism now raises `IdeaWriterError` exceptions instead of calling exit
  - CLI entry point (`exe/ace-taskflow`) handles exit at top level only
  - Tests now complete properly and report full results (700 tests vs 0 previously)
  - Fixes issue where `ace-test` would report "0 tests, 0 assertions, 0 failures"

### Changed

- Command execution pattern: All commands should return status codes for testability
- Organism error handling: Organisms raise exceptions that commands handle and convert to status codes
- Test expectations: Updated tests to assert on return values and exceptions instead of `SystemExit`

### Technical

- Refactored `RetrosCommand#execute` to return status codes
- Refactored `RetroCommand#execute` and all private methods to return status codes
- Added `IdeaWriterError` exception class for organism-level errors
- Updated `CLI.start` to return status codes instead of exiting
- Updated test assertions for new status code pattern
- Documented exit call anti-pattern in `docs/testing-patterns.md`

## [0.10.0] - 2025-10-07

### Added

- **Rich Clipboard Support (macOS)**: Idea creation now supports rich clipboard content
  - Automatically detects and saves images (PNG, JPEG, TIFF)
  - Copies files from Finder with original filenames
  - Preserves HTML and RTF formatted content
  - Platform detection with graceful fallback to text-only on non-macOS
  - New `ace-support-mac-clipboard` gem with NSPasteboard FFI integration

- **Enhanced Ideas List Display**: Multiple display formats for different use cases
  - Default format shows file paths (LLM-optimized for direct file access)
  - `--short` flag hides paths and shows IDs (human-friendly)
  - `--format json` provides structured output with metadata
  - Rich ideas marked with 📎 icon and attachment count
  - Paths for rich ideas point to `idea.md` file inside directory

- **Directory-based Ideas**: Ideas with attachments stored as directories
  - Simple ideas: Single `.md` file (e.g., `20251007-125830-title.md`)
  - Rich ideas: Directory with `idea.md` + attachments (e.g., `20251007-125830-title/`)

### Changed

- Ideas list default format now optimized for LLM access (shows paths)
- ID display now conditional: hidden when paths shown, visible with `--short`
- Updated help text to document new display formats and options

### Technical

- Added `ace-support-mac-clipboard` package with FFI bridge to AppKit/NSPasteboard
- Implemented ContentType, Reader, and ContentParser for clipboard data
- Enhanced IdeaLoader to handle both flat file and directory-based ideas
- Updated AttachmentManager with `save_attachments` method
- IdeaWriter now supports clipboard merge and attachment handling

## [0.9.0] - 2025-09-24

### Initial Features

- Task and idea management with timestamped organization
- Descriptive task paths with semantic directory names
- Retrospective management
- Configuration cascade system
- ATOM architecture pattern


## [0.40.0] - 2026-02-22

### Added
- Command grouping in CLI help: Task Management, Idea Management, Release & Retro, Utilities

### Fixed
- Misleading examples in task add-dependency/remove-dependency (was showing --depends-on flag, now shows positional args)
- Standardized quiet, verbose, debug option descriptions to canonical strings
