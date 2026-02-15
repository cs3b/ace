# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2026-02-15

### Added

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
