# Changelog

All notable changes to ace-prompt will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
