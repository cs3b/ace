# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- **ace-support-cli v0.6.4**: Corrected top-level `--help` usage output formatting so usage is rendered consistently as `Usage: <program> [COMMAND]`, and aligned help tests to validate this contract.

### Changed
- **ace-support-cli v0.6.5**: Standardized shared package tests to the fast-only layout and updated testing flow defaults.

## [0.6.4] - 2026-04-11

### Changed
- Migrated deterministic test layout to `test/fast/` for fast-only package coverage.
- Documented fast-only testing contract in README and retained package verification commands:
  - `ace-test ace-support-cli`
  - `ace-test ace-support-cli all`

## [0.6.3] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.6.2] - 2026-03-22

### Technical
- Removed trailing blank lines in README code fences for installation and basic usage examples.

## [0.6.1] - 2026-03-22

### Changed
- Expanded the README with a clear package tagline, installation guidance, runnable basic usage example, API overview, and Part of ACE footer.

## [0.6.0] - 2026-03-18

### Added
- Moved `Error`, `Base`, `StandardOptions`, and `RegistryDsl` classes from ace-support-core into ace-support-cli as their canonical home.
- Added `.module(gem_name:, version:)` factory to `VersionCommand` for dynamic version display modules.
- Added `argument :args` to `HelpCommand` for accepting trailing arguments.

### Changed
- Runner now raises `Ace::Support::Cli::Error` directly instead of bridging through `Ace::Core::CLI::Error`.

## [0.5.1] - 2026-03-17

### Fixed
- Restored compatibility for repeated scalar options, `key=value` hash options, and `--` passthrough handling so migrated ACE CLIs preserve existing argument semantics.
- Normalized help and command resolution behavior: top-level help now renders without raw command lookup failures, rich help no longer exits the process directly, and usage rendering supports real ACE registry metadata shapes.
- Fixed the public `ArgvCoalescer` contract by loading it from the top-level entrypoint and aligning the canonical constant name with the file path while keeping the legacy alias available.

## [0.5.0] - 2026-03-17

### Added
- Rich `--help` interception in Parser: commands with `desc` or `examples` metadata now render structured help (NAME, USAGE, DESCRIPTION, OPTIONS, EXAMPLES) via the existing Banner/Concise/TwoTierHelp formatters instead of OptionParser's bare-bones output.
- Runner passes computed command name (e.g., `ace-task show`) to Parser for accurate help rendering.
- `PROGRAM_NAME` constant lookup on registry modules for correct program name resolution.

## [0.4.0] - 2026-03-15

### Added
- Runner improvements: enhanced command runner lifecycle with better error propagation and exit code handling
- Registry DSL support: added declarative registry definition helpers for cleaner command registration
- Parse error re-raising: parse errors now propagate with structured context for downstream error handling

### Changed
- Removed runtime dependency on `ace-support-core` to avoid circular dependency during support-core CLI migration.

## [0.3.0] - 2026-03-14

### Added
- Added a native help subsystem with full banner rendering, concise `-h` rendering, registry usage rendering, and two-tier help dispatch helpers.
- Added `HelpCommand` and `VersionCommand` factory modules in `Ace::Support::Cli`.
- Added focused tests for help rendering and dispatch behavior.

## [0.2.0] - 2026-03-13

### Added
- Initial `ace-support-cli` gem scaffold with core command/parsing/runtime classes.
