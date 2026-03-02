# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-03-02

### Added
- `TaskScanner#scan_in_folder` method with virtual filter support ("next" for root-only, "all" for everything)

### Changed
- `TaskManager#list` defaults to `in_folder: "next"` — shows only root tasks by default (excludes _archive, _maybe, etc.)
- Use `--in all` to see all tasks including special folders (previous default behavior)
- Remove `next: _next` from default config special folder mappings

## [0.4.3] - 2026-03-01

### Changed
- Remove dead --tree conditional branch in show command

## [0.4.2] - 2026-03-01

### Fixed
- Add ace-support-markdown as runtime dependency in gemspec
- TaskDoctorFixer: log exception class and message in rescue blocks instead of silently swallowing
- TaskDoctorFixer: validate backup file extension before deletion in fix_stale_backup

## [0.4.1] - 2026-03-01

### Fixed
- Doctor command: soft-require ace/llm instead of hard top-level require (prevents LoadError without ace-llm)
- TaskDoctorFixer: add missing require_relative for TaskScanner
- Gemspec: include handbook/**/* in spec.files

## [0.4.0] - 2026-03-01

### Added

- `doctor` CLI command with health checks for tasks: structure validation, frontmatter validation, scope/status consistency
- `TaskValidationRules` atom defining valid statuses, terminal statuses, required fields, and scope rules
- `TaskStructureValidator` molecule checking folder naming (`{xxx.t.yyy}-{slug}`), spec files, stale backups, empty directories
- `TaskFrontmatterValidator` molecule validating delimiters, YAML parsing, required fields, field values, recommended fields
- `TaskDoctorReporter` molecule formatting results for terminal, JSON, and summary output with health score
- `TaskDoctorFixer` molecule auto-fixing 15+ issue patterns with dry-run support
- `TaskDoctor` organism orchestrating all checks with configurable check types
- Doctor flags: `--auto-fix`, `--auto-fix-with-agent`, `--check`, `--json`, `--verbose`, `--dry-run`, `--errors-only`, `--quiet`, `--model`, `--no-color`
- Config keys `doctor_agent_model` and `doctor_cli_args` in `.ace-defaults/task/config.yml`

## [0.3.0] - 2026-03-01

### Added

- `list` CLI command with `--status`, `--tags`, `--in`, `--root`, `--filter` options
- `move` CLI command with `--to` option for relocating tasks to special folders or root
- `update` CLI command with `--set`, `--add`, `--remove` for frontmatter field updates (comma-separated for multiple)
- `--priority`, `--tags`, `--child-of`, `--in` options on `create` command
- `--tree` output mode on `show` command
- `show` command now uses `TaskDisplayFormatter` for formatted output with status symbols
- Handbook migration: 17 task workflow instructions, 2 bug workflow instructions, 9 templates, and 3 guides moved from ace-taskflow

### Fixed

- `TaskManager#list` now normalizes folder names (e.g., "maybe" → "_maybe") before filtering

## [0.2.0] - 2026-03-01

### Added

- `TaskDisplayFormatter` molecule for terminal output formatting with status symbols and subtask tree display
- `TaskManager` organism orchestrating all task CRUD operations (create, show, list, update, move, create_subtask)
- `SubtaskCreator` molecule with sequential char allocation (a-z then 0-9, max 36)
- `TaskFilePattern` atom with glob patterns and primary vs subtask file detection
- `TaskFrontmatterDefaults` atom for building default frontmatter hashes

### Changed

- `Task` model expanded with priority, estimate, dependencies, tags, subtasks, parent_id fields
- `TaskScanner` expanded with subtask exclusion from primary scan and `scan_subtasks` method
- `TaskResolver` expanded with subtask reference resolution (`xxx.t.yyy.a`)
- `TaskLoader` expanded with subtask detection, parent_id population, and full field loading
- `TaskCreator` expanded with LLM slug generation, priority/tags/dependencies support

## [0.1.0] - 2026-03-01

### Added

- Initial gem scaffold with B36TS-based task ID format (`xxx.t.yyy`)
- `TaskIdFormatter` atom wrapping `ItemIdFormatter` with `.t.` type marker
- `TaskCreator` molecule for creating tasks with folder and spec file
- `TaskLoader` molecule for loading a single task from directory
- `TaskScanner` molecule wrapping `DirectoryScanner` with task-format ID extractor
- `TaskResolver` molecule wrapping `ShortcutResolver` with `full_id_length: 9`
- `TaskConfigLoader` molecule for configuration cascade
- `Task` model as value object
- Minimal CLI with `create` and `show` commands
