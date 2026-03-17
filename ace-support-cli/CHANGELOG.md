# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
