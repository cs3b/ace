# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-03-02

### Changed
- `IdeaManager#list` defaults to `in_folder: "next"` — shows only root ideas by default (excludes _archive, _maybe, etc.)
- `IdeaScanner#scan_in_folder` supports virtual filters ("next" for root-only, "all" for everything)
- `IdeaCreator` rejects virtual filter names ("next", "all") in `--move-to` option
- Use `--in all` to see all ideas including special folders (previous default behavior)
- Remove `next: _next` from default config special folder mappings

## [0.5.0] - 2026-02-28

### Changed
- `IdeaMover#move` now accepts an optional `date:` keyword argument; when moving to `_archive`, the idea is placed under a B36TS month/week partition (e.g. `_archive/8p/4/{folder}/`) instead of a flat `_archive/` directory
- `IdeaManager#move` automatically extracts `completed_at` or `created_at` from idea frontmatter and passes it as the archive date, falling back to `Time.now`

## [0.4.2] - 2026-02-28

### Added
- `doctor_cli_args` configuration map for the `doctor --auto-fix-with-agent` workflow so each provider can define any required CLI args (default maps `gemini` to `yolo`).
### Fixed
- `ace-idea doctor --auto-fix-with-agent` now only passes CLI args when the configured map contains an entry, preventing Gemini CLI from receiving unsupported flags while still honoring other providers (tests cover the CLI map lookup).

## [0.4.1] - 2026-02-28

### Added
- `doctor` command: extended auto-fix support for additional issue types
  - Auto-fix for missing opening '---' delimiter (prepends proper frontmatter)
  - Auto-fix for legacy folder naming (generates new b36ts ID and renames folder)
  - Category folder detection (skips folders with only subdirectories, no files)
- 16 fixable patterns (up from 14)

### Technical
- 13 new tests for extended auto-fix functionality (230 total tests)

## [0.4.0] - 2026-02-28

### Added
- `doctor` command: comprehensive health checks for ideas with auto-fix and agent support
  - Structure validation (folder naming, spec files, stale backups, empty directories)
  - Frontmatter validation (delimiters, YAML syntax, required/recommended fields)
  - Scope/status consistency checks (terminal status in _archive, etc.)
  - Health score (0-100) based on errors/warnings
  - `--auto-fix` for safe automatic fixes (14 fixable patterns)
  - `--auto-fix-with-agent` to launch LLM agent for remaining issues
  - Output formats: `--json`, `--quiet`, `--verbose`, `--summary`
  - Filters: `--check (frontmatter|structure|scope)`, `--errors-only`
  - Other options: `--no-color`, `--dry-run`, `--model`
- `IdeaValidationRules` atom: pure validation predicates for status, ID, scope consistency
- `IdeaFrontmatterValidator` molecule: per-file frontmatter validation
- `IdeaStructureValidator` molecule: directory structure validation
- `IdeaDoctorFixer` molecule: auto-fix engine with dry-run support
- `IdeaDoctorReporter` molecule: terminal/JSON/summary formatting
- `IdeaDoctor` organism: orchestrates all validation checks
- `doctor_agent_model` config default (`gflash`) for `--auto-fix-with-agent`

### Technical
- 108 new tests covering all doctor components (230 total tests with v0.4.1 additions)

## [0.3.1] - 2026-02-28

### Fixed
- Test performance: stub `llm_available?` in LLM-related tests to prevent real API calls (43s → <0.2s)

## [0.3.0] - 2026-02-28

### Changed
- Refactored `IdeaLoader` to use shared `FrontmatterParser` and `TitleExtractor` from `ace-support-items`
- Refactored `IdeaFrontmatterDefaults.serialize` to delegate to shared `FrontmatterSerializer`
- Refactored `IdeaManager` to use shared `FrontmatterParser`, `FrontmatterSerializer`, and `FilterApplier`
- Updated dependency: `ace-support-items ~> 0.2` (was `~> 0.1`)

### Added
- `--filter` option on `list` command: `ace-idea list --filter status:pending --filter tags:ux|design`
- `IdeaManager#list` accepts `filters:` parameter for generic `key:value` filter syntax
- Supports OR values (`key:a|b`), negation (`key:!value`), and AND across multiple filters

## [0.2.4] - 2026-02-28

### Added
- E2E test scenario `TS-IDEA-001-idea-lifecycle` with three test cases: TC-001 (create idea), TC-002 (list with filters), TC-003 (move to folder)

### Technical
- Updated `idea/capture` workflow: corrected done-state description to use `ace-idea move <id> --to archive` + `ace-idea update <id> --set status=done`
- Updated `idea/prioritize` workflow: replaced `ace-idea reschedule` commands with folder-based `ace-idea move` prioritization
- Fixed `bin/ace-idea` wrapper to load from `ace-idea/exe/ace-idea` (was incorrectly loading from `ace-taskflow/exe/ace-idea`)

## [0.2.3] - 2026-02-28

### Technical
- Added explicit `require "json"` to `IdeaLlmEnhancer` (prevents runtime NameError in cold process)
- Removed unused `DEFAULT_STATUS` / `DEFAULT_LLM_MODEL` constants from `IdeaConfigLoader`
- Removed redundant inline `require "ace/support/items"` inside `IdeaCreator#generate_slug`

## [0.2.2] - 2026-02-28

### Fixed
- Path traversal in `--to` / `--move-to` options — boundary check via `File.expand_path` in `IdeaMover#move` and `IdeaCreator#determine_target_dir`
- YAML serializer now quotes YAML-ambiguous values (`true`, `false`, `null`, numbers)
- `rebuild_file` uses `IdeaFrontmatterDefaults.serialize` for consistent inline-array format (was: `YAML.dump` block format)
- `IdeaLlmEnhancer` JSON extraction uses regex to handle LLM preamble before code block
- `IdeaLoader#list_attachments` filters hidden OS files (`.DS_Store` etc.)

### Added
- `spec.executables` in gemspec — `ace-idea` binary now installs correctly via `gem install`

## [0.2.1] - 2026-02-28

### Fixed

- Sanitize attachment filenames to prevent path traversal (reject `../` and null bytes)
- `--root` option in `list` now validates path stays within `root_dir` boundary
- Atomic file writes in `update_idea_file` using temp file + `File.rename` pattern
- `gem_root` path calculation corrected (was resolving to `lib/` instead of gem root)
- `ArgumentError` from clipboard failures caught in `exe/ace-idea` with friendly message
- TOCTOU race condition in `IdeaMover` replaced with `File.rename` + cross-device fallback
- Same-path move in `IdeaMover` now returns early (no-op) instead of raising misleading error
- Config loader rescues only `Errno::ENOENT` / `Psych::SyntaxError` instead of `StandardError`
- Formatting drift after repeated `update` calls fixed (strip leading newline in `parse_file`)
- YAML serializer now quotes all YAML special characters (`@`, `*`, `&`, `!`, `%`, `[`, `]`, etc.)
- CLI `update` command uses `FieldArgumentParser` for type inference (arrays, booleans, numerics)

### Technical

- Regression tests for path traversal (attachment filenames, `--root`), same-path no-op, null bytes
- Total: 109 tests, 336 assertions, 0 failures

## [0.2.0] - 2026-02-28

### Added

- `ace-idea` CLI executable with 5 commands: `create`, `show`, `list`, `move`, `update`
- `IdeaCLI` registry (`lib/ace/idea/cli.rb`) following dry-cli Registry pattern
- `create` command: positional content, `--title`, `--tags`, `--move-to`, `--clipboard`, `--llm-enhance`, `--dry-run`
- `show` command: display by ref with `--path` and `--content` mode flags
- `list` command: filter by `--status`, `--tags`, `--in FOLDER`, `--root`
- `move` command: relocate idea with `--to FOLDER` (short names: archive, maybe, next, root)
- `update` command: `--set K=V`, `--add K=V`, `--remove K=V` for frontmatter mutation
- `version` and `help` commands via `ace-support-core` DryCli helpers
- SIGINT handling with exit code 130 in `exe/ace-idea`
- `dry-cli ~> 1.0` runtime dependency
- Handbook workflow instructions moved from `ace-taskflow`: `idea/capture.wf.md`, `idea/capture-features.wf.md`, `idea/prioritize.wf.md`
- CLI integration tests covering all 5 commands and error paths

## [0.1.1] - 2026-02-28

### Added

- Integration tests covering full create→show→update→move→list roundtrip lifecycle
- Clipboard edge case tests: empty content, binary data, oversized content, gem unavailable
- LLM enhancement fallback tests at the manager level
- Concurrent b36ts ID collision tests (two ideas within the 2-second encoding window)
- Performance tests verifying scan completes within threshold for 500+ idea collections

### Fixed

- `IdeaCreator` now handles duplicate folder names when two ideas share the same b36ts ID
  and slug (appends numeric counter `-2`, `-3`, etc. to ensure unique directories)

## [0.1.0] - 2026-02-28

Extracted from `ace-taskflow` v0.42.11 (was `Ace::Taskflow::Idea::*`) into a dedicated gem.

### Added

- Initial release with core operations and model
- `IdeaIdFormatter` atom for raw 6-char b36ts ID generation (no type markers)
- `IdeaFilePattern` atom for `.idea.s.md` file glob patterns
- `IdeaFrontmatterDefaults` atom for frontmatter generation and serialization
- `Idea` model (Struct) with id, status, title, tags, content, path, file_path, special_folder, created_at, attachments, metadata
- `IdeaConfigLoader` molecule for config cascade (gem defaults -> user -> project)
- `IdeaScanner` molecule wrapping DirectoryScanner for `.idea.s.md` files
- `IdeaResolver` molecule wrapping ShortcutResolver for 3-char suffix shortcuts
- `IdeaLoader` molecule for loading idea directories with frontmatter parsing and attachment enumeration
- `IdeaCreator` molecule for full idea creation with clipboard support and LLM enhancement
- `IdeaLlmEnhancer` molecule with hardcoded 3-Question Brief system prompt
- `IdeaClipboardReader` molecule for system clipboard capture (text, rich, images)
- `IdeaMover` molecule for relocating idea folders to special folders
- `IdeaDisplayFormatter` molecule for terminal output formatting
- `IdeaManager` organism orchestrating all operations with config-driven root directory
- Default configuration in `.ace-defaults/idea/config.yml`
