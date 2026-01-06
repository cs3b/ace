# Changelog

All notable changes to ace-prompt will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **BREAKING**: Archive filenames changed from 14-character timestamps to 6-character Base36 compact IDs
  - Example: `20251129-143000.md` → `i50jj3.md`
  - Existing timestamp-formatted archives remain readable (dual-format support)
  - Archives are git-ignored, so no migration needed for existing files
  - `_previous.md` symlink now points to Base36-formatted archives
- Migrate to Base36 compact IDs for session archiving (via ace-timestamp)
- Simplified TimestampGenerator atom (removed legacy timestamp format support since archives are gitignored)

### Added
- Base36 compact ID format documentation in README with precision notes (~1.85s)

## [0.11.0] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.10.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.9.2] - 2026-01-01

### Changed

* Add thread-safe configuration initialization with Mutex pattern
* Centralize cache paths in gem config file
* Improve error logging with gem prefix and exception class

## [0.9.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.9.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.8.0] - 2025-12-29

### Changed
- Migrate ProjectRootFinder dependency from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.7.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/prompt/config.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

## [0.6.0] - 2025-12-26

### Changed
- **Migrate to ace-git** (Task 140.04): Replace local `GitBranchReader` molecule with `Ace::Git::Molecules::BranchReader` for unified git operations across ace-* gems
- Add ace-git ~> 0.3 dependency for shared git operations

### Added
- Test for nil/failure path when `BranchReader.current_branch` returns nil (graceful fallback to project-level prompt)

### Removed
- `Ace::Prompt::Molecules::GitBranchReader` - functionality now provided by ace-git

## [0.5.1] - 2025-12-09

### Fixed
- Added Questions section back to template structure (now 7 sections)

## [0.5.0] - 2025-12-09

### Added
- New 6-section default template structure: Purpose, Variables, Codebase Structure, Instructions, Workflow, Report
- Updated enhance system prompt output format to match new template sections

## [0.4.0] - 2025-12-01

### Added
- **LLM Enhancement** (Task 121.04, 121.05)
  - `--enhance/-e` flag for LLM-powered prompt improvement
  - `--model` option with built-in aliases: `glite`, `claude`, `haiku`
  - `--temperature` option for LLM creativity control
  - `--system-prompt` option to customize enhancement instructions
  - EnhancementTracker molecule for content-based caching
  - PromptEnhancer organism integrating with ace-llm Ruby API
  - Enhancement archiving with `_e001` suffix pattern
  - System prompt loading via `prompt://` protocol
  - Frontmatter preservation when writing enhanced content back to source

- **Task Folder Support** (Task 121.06)
  - `--task/-t` flag for task-specific prompt directories
  - Branch detection for automatic task resolution (e.g., `121-feature` → task 121)
  - TaskPathResolver atom for task directory lookup
  - Subtask fallback support (121.01 → 121)
  - Integration with ace-taskflow for task path discovery

### Fixed
- Enhancement output now clean markdown (no JSON wrapper, no system prompt echo)
- Enhanced content correctly written back to `the-prompt.md`
- Archive path returns enhanced version, symlink updated properly

## [0.3.0] - 2025-11-28

### Added
- Global configuration via `Ace::Prompt.config` using ace-core config cascade
- Configuration file support at `.ace/prompt/config.yml`
- `context.enabled` config option to control context loading behavior
- Example config at `.ace.example/prompt/config.yml`

### Changed
- CLI now uses `Ace::Prompt.config` instead of custom ConfigLoader molecule
- Removed `ConfigLoader` molecule (replaced by standard ace-* config pattern)
- Simplified `ContextLoader` to pass file path directly to ace-context

## [0.2.0] - 2025-11-28

### Added
- Setup command for template initialization (Task 121.02)
- `ace-prompt setup` - Initialize workspace with template
- Template resolution via `tmpl://` protocol (ace-nav Ruby API)
- TemplateResolver molecule with short form support (`--template bug`)
- TemplateManager molecule for template operations
- PromptInitializer organism using ProjectRootFinder
- Default `the-prompt-base` template with frontmatter
- Protocol registration for ace-nav (`tmpl://ace-prompt/the-prompt-base`)
- `--template` option for custom templates (short form and full URI)
- `--no-archive` and `--force` options to skip archiving
- Automatic directory creation if not exists
- Archive functionality by default (consolidated from reset)
- Comprehensive test suite for new features

### Changed
- Setup uses project root directory (via ProjectRootFinder) instead of home directory (Task 121.08)
- Consolidated reset command into setup (reset removed from CLI)
- Template naming pattern: `the-prompt-{name}.template.md`
- Template resolution uses ace-nav Ruby API (no shell execution)
- TemplateResolver now validates URI format before resolution (rejects spaces)
- Added DEBUG-gated logging for ace-nav LoadError

### Fixed
- CLI exit code handling for Thor Array return (Task 121.08)

## [0.1.0] - 2025-11-28

### Added
- Initial release with basic functionality (Task 121.01)
- Read prompt file from `.cache/ace-prompt/prompts/the-prompt.md`
- Archive with timestamp format `YYYYMMDD-HHMMSS.md`
- Update `_previous.md` symlink to latest archive
- Output to stdout by default
- `--output` option to write to file
- ATOM architecture: atoms, molecules, organisms
- Comprehensive test suite with edge cases
