# Changelog

All notable changes to ace-bundle will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

## [0.30.5] - 2026-02-15

### Fixed
- **SectionProcessor**: Fix typo `orde2` → `order` in comment (line 100)
- **SectionProcessor**: Fix indentation alignment in `merge_contents` method (line 240)

## [0.30.4] - 2026-02-15

### Fixed
- **SectionFormatter**: Fix typo in `format_sections_json_full` method name (`foRmat` → `format`)

## [0.30.3] - 2026-01-31

### Performance
- Moved CLI integration tests to E2E test suite (Task 251.06)
  - Created `test/e2e/cli-api-parity.mt.md` for CLI/API output parity tests
  - Created `test/e2e/cli-auto-format.mt.md` for auto-format behavior tests
  - Removed `test/integration/cli_api_parity_test.rb` (1 test, ~0.94s)
  - Removed `test/integration/cli_auto_format_test.rb` (6 tests, ~1.2s)
  - Tests now run via `/ace:run-e2e-test ace-bundle MT-BUNDLE-002`
  - Saves ~2.1s of subprocess overhead from regular test runs

## [0.30.2] - 2026-01-31

### Performance
- Moved section workflow integration tests to E2E test suite (Task 251.05)
  - Created `test/e2e/MT-BUNDLE-001-section-workflow.mt.md` for section workflow tests
  - Removed `test/integration/section_workflow_integration_test.rb` (2 tests)
  - Tests now run via `/ace:run-e2e-test ace-bundle MT-BUNDLE-001`
  - Existing molecule tests already use proper mocking patterns

## [0.30.1] - 2026-01-19

### Added
- Support `preset` and `presets` keys in template frontmatter (Task 217)
  - Recognize preset/presets keys in workflow file frontmatter
  - Process presets from frontmatter with error handling
  - Store loaded presets and errors in bundle metadata

## [0.30.0] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.29.1] - 2026-01-15

### Technical
- Patch version bump

## [0.29.0] - 2026-01-15

### Added
- Initial release as ace-bundle (renamed from ace-context)
- All module namespaces updated from `Ace::Context` to `Ace::Bundle`
- All requires updated from `ace/context` to `ace/bundle`
- Configuration directory renamed from `.ace-defaults/context/` to `.ace-defaults/bundle/`

## [0.28.2] - 2026-01-11

### Fixed
- **Chunked output header**: Added stats header (lines, size, chunk count) before listing chunk paths
  - Previously showed bare paths with no context

## [0.28.1] - 2026-01-11

### Changed
- **Chunked output**: CLI now outputs chunk file paths directly (one per line) instead of index file path
  - Agents can read chunks directly without first reading the index
  - Non-chunked output still shows single file path

## [0.28.0] - 2026-01-11

### Added
- **ContextChunker**: Moved from ace-support-core (this package is the only consumer)
  - `Ace::Bundle::Molecules::ContextChunker` for splitting large outputs
  - `Ace::Bundle::Atoms::BoundaryFinder` for semantic XML boundary detection
  - Preserves `<file>` and `<output>` element integrity when chunking

### Changed
- **BREAKING**: Config key `chunk_limit` renamed to `max_lines` for clarity
- Default max_lines changed from 150000 to 2000 (more practical default)
- Configuration now loaded via `Ace::Bundle.max_lines` instead of `Ace::Core.get(...)`

## [0.27.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `Load` and `List` dry-cli command classes
  - Deleted `load_command.rb` and `list_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer
- Added `PresetListFormatter` atom for reusable list formatting logic

## [0.27.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.04)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Converted CLI class to `Dry::CLI::Registry` pattern with explicit command registration
  - Moved default command routing logic from method_missing to `CLI.start` method
