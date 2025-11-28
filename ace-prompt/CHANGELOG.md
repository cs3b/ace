# Changelog

All notable changes to ace-prompt will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
