# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-03-02

### Added
- `RetroDisplayFormatter.format_stats_line` for generating stats summary (e.g., "Retros: 🟡 2 | 🟢 5 • 7 total • 71% complete")
- `format_list` now appends a stats summary line after the item list (omitted for empty lists)

## [0.3.0] - 2026-03-02

### Changed
- `RetroManager#list` defaults to `in_folder: "next"` — shows only root retros by default (excludes _archive)
- `RetroScanner#scan_in_folder` supports virtual filters ("next" for root-only, "all" for everything)
- Use `--in all` to see all retros including archived (previous default behavior)

## [0.2.3] - 2026-03-01

### Changed

- Rewrite create.wf.md: simplify from 486 to ~90 lines, reference `tmpl://retro/retro` instead of embedding template, use `ace-retro create` CLI
- Rewrite selfimprove.wf.md: broaden input sources (session/retros/user), use `ace-nav` protocol paths, add retro creation and archive steps
- Rewrite synthesize.wf.md: reduce to N retros → 1 retro pattern using `ace-retro` CLI, remove `reflection-synthesize` command references

### Removed

- Delete `synthesis-analytics.template.md` (synthesize workflow is self-contained)
- Delete `synthesize.system.prompt.md` (synthesize workflow is self-contained)

## [0.2.2] - 2026-03-01

### Fixed

- Doctor flags invalid archive partitions (e.g., `_archive/2025-09/`) and fixer relocates retros to correct b36ts partitions via RetroMover
- Doctor accepts valid b36ts archive partitions (e.g., `_archive/8o/`)

## [0.2.1] - 2026-03-01

### Fixed

- Wire `--root` option in `list` command to pass through to RetroManager
- Use DatePartitionPath for doctor auto-fix archive moves (consistent with RetroMover)

### Added

- Regression test for `--root` option in list CLI command

## [0.2.0] - 2026-03-01

### Added

- `doctor` command for comprehensive retro health checks
- RetroValidationRules atom with status validation, scope consistency, required/recommended field checks
- RetroFrontmatterValidator molecule for per-file frontmatter validation
- RetroStructureValidator molecule for directory structure checks (folder naming, retro files, backups, empty dirs)
- RetroDoctorFixer molecule with auto-fix support for 15 fixable patterns and dry-run mode
- RetroDoctorReporter molecule with terminal, JSON, and summary output formats
- RetroDoctor organism orchestrating structure, frontmatter, and scope checks with health scoring
- CLI options: `--auto-fix`, `--check`, `--verbose`, `--json`, `--errors-only`, `--no-color`, `--dry-run`, `--quiet`
- Exit code 0 when healthy, non-zero when errors found

## [0.1.0] - 2026-03-01

Extracted from ace-taskflow into standalone gem with b36ts-based retro management.

### Added

- Initial release of ace-retro gem
- RetroIdFormatter atom for raw b36ts ID generation
- RetroFilePattern atom for `.retro.md` file patterns
- RetroFrontmatterDefaults atom for retro frontmatter generation
- Retro model with id, status, title, type, tags, content, task_ref, folder_contents
- RetroConfigLoader molecule for configuration cascade
- RetroScanner molecule wrapping DirectoryScanner for `.retro.md` files
- RetroResolver molecule wrapping ShortcutResolver for ID resolution
- RetroLoader molecule for loading retros from directories
- RetroCreator molecule for full retro creation with b36ts ID
- RetroMover molecule with cross-filesystem move support (Errno::EXDEV)
- RetroDisplayFormatter molecule for terminal output
- RetroManager organism orchestrating create, show, list, update, move operations
- `.ace-defaults/retro/config.yml` with default configuration
- CLI registry (RetroCLI) with dry-cli following ace-idea pattern
- `create` command: `ace-retro create TITLE [--type TYPE] [--tags T] [--task-ref REF] [--move-to FOLDER] [--dry-run]`
- `show` command: `ace-retro show REF [--path | --content]`
- `list` command: `ace-retro list [--status S] [--type T] [--tags T] [--in FOLDER]`
- `move` command: `ace-retro move REF --to FOLDER`
- `update` command: `ace-retro update REF [--set K=V]... [--add K=V]... [--remove K=V]...`
- `version` and `help` commands
- Executable `exe/ace-retro` with SIGINT handling (exit 130) and error rescue
- Handbook: workflow instructions (retro/create, retro/synthesize) moved from ace-taskflow
- Handbook: templates (retro, synthesis-analytics, synthesize system prompt) moved from ace-taskflow
- CLI integration tests for all 5 commands
