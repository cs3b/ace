# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-01-30

### Fixed

- Job files already in a `jobs/` directory are kept in place instead of being moved to a nested path when creating sessions

## [0.3.0] - 2026-01-30

### Added

- **Fork context support for jobs**: Enable job files to declare `context: fork` in frontmatter to run steps in isolated agent contexts via Claude Code's Task tool
- New `context` field in Step model with `fork?` predicate method
- Context validation rejecting invalid values with helpful error messages (valid values: `fork`)
- `handbook/guides/fork-context.g.md` documentation for the fork context feature
- Status command outputs Task tool instructions for fork-context jobs
- Shell escaping for step names in Task tool description field
- E2E test (TC-005) for fork context feature validation

### Changed

- Centralized `VALID_CONTEXTS` constant in Step model, referenced by parser
- QueueScanner surfaces ArgumentError for invalid job files instead of silent nil return
- Status output uses plain text separators instead of markdown backticks for better terminal compatibility
- Use deterministic project root from cache_dir instead of Dir.pwd
- Updated `work-on-task` preset to demonstrate fork pattern

## [0.2.1] - 2026-01-29

### Fixed

- Cache directory initialization bug where `.cache/ace-coworker/` was never created before `generate_session_id` called `Dir.mkdir()`, causing `Errno::ENOENT` crash on first use

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
- Session ID generation max retry limit (100 attempts) to prevent infinite loop
- E2E test comment: "creates separate .r.md report file" (was "appends report inline")

### Added

- Prepare command stub with helpful message directing users to create job.yaml manually or use the prepare-coworker-job workflow

### Changed

- Improve error messages with actionable suggestions (e.g., "Try 'ace-coworker add' or 'ace-coworker retry'")
- Migration UX for deprecated commands (start → create) with warning message

## [0.1.6] - 2026-01-28

### Changed

- Split `coworker-session.wf.md` into focused workflows: `create-coworker-session.wf.md` (session creation) and `drive-coworker-session.wf.md` (execution loop)
- Renamed `coworker-prepare-job.wf.md` → `prepare-coworker-job.wf.md` for verb-first naming convention
- Renamed skill `ace_coworker-start` → `ace_coworker-drive-session` for clarity
- All coworker skills now use thin wrapper pattern pointing to workflows via `ace-bundle`

### Technical

- Fixed file extension documentation: `*.md` → `*.j.md` for step files in create-coworker-session workflow
- Clarified "source of truth" is `ace-coworker status` command in workflow documentation
- Added note about archived job.yaml being for provenance only, not status queries
- Changed "Job files" → "Step files" terminology in README for clarity

## [0.1.5] - 2026-01-28

### Added

- Separate job and report files with `.j.md` and `.r.md` extensions
- New `reports/` directory structure for storing completion reports separately from job files
- Report files include YAML frontmatter with `job`, `name`, and `completed_at` fields for traceability

### Changed

- Job files now use `.j.md` extension (was `.md`)
- Reports are written to separate `.r.md` files instead of being embedded in job bodies
- `StepFileParser.extract_fields()` now returns `nil` for report (loaded separately)
- `StepFileParser.parse_filename()` handles both `.j.md` and `.r.md` extensions
- `StepFileParser.generate_filename()` produces `.j.md` filenames
- `StepFileParser.generate_report_filename()` produces `.r.md` filenames
- `StepSorter.sort_key()` strips `.j.md` extension
- `QueueScanner.scan()` and `step_numbers()` glob for `*.j.md` files
- `QueueScanner.load_report()` loads report content from corresponding `.r.md` file
- `SessionManager.create()` creates both `jobs/` and `reports/` directories
- `Session.reports_dir` returns path to reports directory
- `StepWriter.mark_done()` accepts `reports_dir:` parameter and writes report separately
- `StepWriter.append_report()` accepts `reports_dir:` parameter and updates report files
- `StepWriter.write_report()` private helper for atomic report file writes
- `WorkflowExecutor.advance()` passes `reports_dir` to `mark_done()`
- CLI status command fallback filename uses `.j.md` extension
- `Step.to_display_row()` fallback filename uses `.j.md` extension

## [0.1.4] - 2026-01-28

### Added

- Archive job.yaml to task's `jobs/` directory after session creation (`{session_id}-job.yml`)

## [0.1.3] - 2026-01-28

### Technical

- Standardize instructions format to arrays in coworker-prepare-job workflow doc
- Update e2e tests for workflow lifecycle with error paths and state verification
- Update CHANGELOGs with complete fix descriptions

## [0.1.2] - 2026-01-28

### Fixed

- CLI `start` command crashes with positional argument (`ace-coworker start job.yaml`) because `option :config` requires `--config` flag — renamed command to `create` with `argument :config`
- `ace-bundle wfi://coworker-prepare-job` fails due to missing project-level wfi:// protocol registration

### Added

- Support array format for step instructions in presets (joined with newlines via `normalize_instructions`)

### Changed

- Rename CLI `start` command to `create` (CLI creates session; "start" is the skill that begins agent work)
- Preset files (`work-on-task.yml`, `work-on-task-with-pr.yml`) now use array instructions format
- Updated workflow instructions and README to reflect `create` command and array instructions format

## [0.1.1] - 2026-01-28

### Fixed

- Persist skill field from job.yaml steps through full pipeline (StepWriter, StepFileParser, QueueScanner, Step model)
- Display skill in status command output for current step
- Pass through extra step fields (beyond name/instructions) from job.yaml via WorkflowExecutor
- Update default job.yaml output path in coworker-prepare workflow to task folder

## [0.1.0] - 2026-01-28

### Added

- Initial release with work queue-based session management
- CLI commands: start, status, report, fail, add, retry
- File-based queue storage with markdown step files
- Session persistence via session.yaml
- History preservation (failed steps remain visible)
- Dynamic step addition with automatic numbering
- Retry mechanism that creates new steps linked to original
