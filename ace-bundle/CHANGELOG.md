# Changelog

All notable changes to ace-bundle will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

## [0.36.6] - 2026-03-13

### Technical
- Updated canonical onboarding skill metadata for in-project workflow execution flow.

## [0.36.5] - 2026-03-13

### Changed
- Updated the canonical bundle and onboarding skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.36.4] - 2026-03-13

### Fixed
- Avoided section compression failures when a frontmatter-only source appears in a fixture by preserving that file content and continuing to compress neighboring files.

## [0.36.3] - 2026-03-12

### Technical
- Added exact-mode enforcement in test execution paths so `ace-bundle` tests no longer rely on agent-mode compression by default.

## [0.36.2] - 2026-03-12

### Technical
- Added regression coverage to verify the newly registered `wfi://demo/create`, `wfi://demo/record`, `wfi://overseer`, and `wfi://prompt-prep` workflow targets resolve and load through `ace-bundle`.

## [0.36.1] - 2026-03-12

### Changed
- Updated handbook workflow guidance to use direct `ace-bundle` invocations instead of legacy slash-command examples.

## [0.36.0] - 2026-03-10

### Added
- Added canonical handbook-owned bundle and onboarding skills, including the new `wfi://onboard` workflow for package-owned onboarding context.


## [0.35.5] - 2026-03-09

### Technical
- Hardened the invalid `bundle.pr` loader test to stub `Ace::Git::Molecules::PrMetadataFetcher.fetch_diff`, preventing accidental live GitHub CLI/API access during `ace-bundle` test runs.
- Updated the regression fixture to use a frontmatter template file so `load_file` exercises the PR-processing path and validates graceful error handling explicitly.

## [0.35.4] - 2026-03-09

### Fixed
- Fixed post-format bundle compression so command-only and diff-only section bundles still compress when `compressor_mode: agent` is enabled.
- Fixed `SectionCompressor` reordering mixed `_processed_files` arrays so per-source and merged compression preserve the original user-specified file order.

## [0.35.3] - 2026-03-09

### Fixed
- Fixed `SectionCompressor` compatibility with the updated `ace-compressor` cache manifest API so bundle section compression no longer crashes on the removed `labels:` keyword.
- Fixed plain-markdown bundle fallback so `load_plain_markdown` also applies rendered-content compression when compression is enabled.

### Technical
- Updated plain-markdown integration coverage to enable compression explicitly per test instead of depending on ambient repository config state.

## [0.35.2] - 2026-03-09

### Fixed
- Fixed template bundles with command-only sections silently skipping compression by adding post-format in-memory compression via `compress_text` when `SectionCompressor` finds no `_processed_files` to compress.

## [0.35.1] - 2026-03-09

### Changed
- Refined the `project` preset output shape for compression testing by keeping the bundle-focused preset content aligned with the current compressor defaults and validation workflow.

### Technical
- Updated the runtime dependency constraint to `ace-compressor ~> 0.21` for the expanded in-memory agent compression API.

## [0.35.0] - 2026-03-09

### Added
- Added content-only bundle compression for plain markdown files loaded via `load_file` and `load_plain_markdown`, using the real resolved file path directly (no temp files) with native cache support.

### Changed
- Changed `SectionCompressor#call` to compress content-only bundles (no sections) when the default mode is not "off", using the source metadata path for stable cache keys.
- Changed plain markdown integration tests to verify compression behavior under default config instead of bypassing with `compressor: "off"`.

## [0.34.0] - 2026-03-09

### Added
- Added `--compressor on|off` CLI flag as a simple toggle to enable or disable section compression.
- Added `compressor:` section to global bundle config (`source_scope`, `mode`) so projects can set compressor defaults centrally instead of per-preset.
- Added `compressor_config`, `compressor_source_scope`, and `compressor_mode` config helper methods to `Ace::Bundle` module.

### Changed
- Changed `compress_bundle_sections` resolution chain to CLI > preset params > global config, with `--compressor off` as absolute kill switch and `--compressor on` force-enabling `per-source` scope.

## [0.33.0] - 2026-03-09

### Added
- Added native cache integration to `SectionCompressor` using compressor's `CacheStore` with stable label-based keys, eliminating redundant compression on repeated bundle runs with unchanged content.

## [0.32.0] - 2026-03-09

### Added
- Added `--compressor-mode` (`exact`, `agent`) and `--compressor-source-scope` (`off`, `per-source`, `merged`) CLI options for inline section compression.
- Added `SectionCompressor` molecule that compresses bundle section content using ace-compressor's file-based API, supporting both exact and agent engines.
- Added preset-level `compressor_mode` and `compressor_source_scope` configuration with CLI override precedence.

### Fixed
- Fixed `compressor_mode: agent` crashing with `ArgumentError` — agent mode now works through the same file-based compression path as exact mode.

## [0.31.12] - 2026-03-08

### Technical
- Align top-level preset composition integration coverage with the current `BundleData` contract by asserting composition metadata via `result.metadata` and merged rendered output via `result.content`.

## [0.31.11] - 2026-03-04

### Changed
- Bundle cache output now defaults to `.ace-local/bundle`; cache writes respect configured `cache_dir`.


## [0.31.10] - 2026-03-04

### Fixed
- README cache output path example corrected to short-name convention (`.ace-local/bundle/` not `.ace-local/ace-bundle/`)

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
