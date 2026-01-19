# Changelog

All notable changes to ace-bundle will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

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
