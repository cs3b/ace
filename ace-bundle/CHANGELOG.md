# Changelog

All notable changes to ace-bundle will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

## [0.31.9] - 2026-03-04

### Technical
- Update handbook reference: cache output path documented as `.ace-local/bundle/` (was `.cache/ace-bundle/`)

## [0.31.8] - 2026-03-04

### Fixed
- Guard against empty `base_content_resolved` replacing document content with nothing when base resolution fails

## [0.31.7] - 2026-03-04

### Fixed
- Resolve `cmd`-type protocol URIs (e.g., `task://`) in `ace-bundle` by capturing command output as a file path, enabling `ace-bundle task://...` to load task files correctly.

### Technical
- Add tests for `resolve_protocol` cmd-type fallback in `BundleLoaderTest`.

## [0.31.6] - 2026-03-03

### Fixed
- Preserve resolved `base` content when `embed_document_source` leaks from top-level preset merge, preventing base workflow content from being overwritten by raw config frontmatter.

## [0.31.5] - 2026-02-25

### Technical
- Bump runtime dependency constraint from `ace-git ~> 0.10` to `ace-git ~> 0.11`.

## [0.31.4] - 2026-02-25

### Fixed
- Ensure plain workflow files without YAML frontmatter load as bundle content instead of returning empty output (`ace-bundle wfi://...`).

### Technical
- Add regression coverage for non-frontmatter workflow loading and align loader tests with content-first behavior.

## [0.31.3] - 2026-02-24

### Technical
- Clarify TS-BUNDLE-001 CLI/API parity E2E runner instructions to treat API `result.metadata[:error]` as a non-zero failure in parity checks.

## [0.31.2] - 2026-02-23

### Fixed
- Resolve `./` prefixed file paths relative to template config directory instead of project root

## [0.31.1] - 2026-02-23

### Changed
- Centralized error class hierarchy: SectionValidationError and PresetLoadError now inherit from Ace::Bundle::Error
- Removed duplicate SectionValidationError definitions

### Technical
- Updated internal dependency version constraints to current releases

## [0.31.0] - 2026-02-22

### Changed
- **Breaking:** Migrated from multi-command Registry to single-command pattern (task 278)
  - Removed `load` subcommand: `ace-bundle load project` → `ace-bundle project`
  - Removed `list` subcommand: `ace-bundle list` → `ace-bundle --list-presets`
  - Removed `version`/`help` subcommands: use `--version`/`--help` flags only
  - Added `--version` and `--list-presets` flags to main command
  - No backward compatibility (per ADR-024)

## [0.30.11] - 2026-02-22

### Changed
- Replace ace-nav subprocess call with in-process SDK (`NavigationEngine#resolve`) for protocol resolution
- Add `ace-support-nav` as runtime dependency (was only used via CLI subprocess)

### Technical
- Remove ace-nav command mock from test helper (no longer needed)
- Update integration test to use SDK directly instead of `CommandExecutor`

## [0.30.10] - 2026-02-22

### Changed
- Standardize `ace-bundle` docs and usage examples to explicit `load` subcommand invocation.

### Technical
- Update CLI routing tests to assert executable behavior (`Open3`), including no-arg help and no implicit default routing.
- Refresh `load` command examples to remove stale `--list` reference and use `--inspect-config`.

## [0.30.9] - 2026-02-22

### Technical
- Update `ace-bundle project` → `ace-bundle load project` in README and usage docs
- Update `ace-bundle project-base` → `ace-bundle load project-base` throughout usage guide

## [0.30.7] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.30.6] - 2026-02-19

### Technical
- Update protocol reference documentation to reflect namespaced wfi:// URIs

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


## [0.30.8] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
