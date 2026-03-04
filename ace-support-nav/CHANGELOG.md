# Changelog

All notable changes to ace-support-nav will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.18.1] - 2026-03-04

### Changed
- Default nav cache directory now uses `.ace-local/nav`.


## [0.18.0] - 2026-03-04

### Added
- `resolve_cmd_to_path` method for programmatic resolution of cmd-type protocol URIs (e.g., `task://ref`)

### Fixed
- Prevent argument injection in `resolve_cmd_to_path` by escaping reference before command template interpolation
- Add 10-second timeout to cmd protocol execution to prevent indefinite hangs

## [0.17.10] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.17.9] - 2026-02-22

### Changed
- Migrate `ace-nav` to the standard multi-command help pattern with explicit top-level `help`, `--help`, and `-h` commands.
- Remove implicit default-command routing and require explicit `resolve`/`list`/`create`/`sources` command usage.
- Update README and command help examples to canonical explicit command forms.

### Technical
- Remove custom default-routing from `CLI` (`start`, `KNOWN_COMMANDS`, `DEFAULT_COMMAND`) and switch executable dispatch to `Dry::CLI.new(...).call(arguments: ...)`.
- Normalize no-argument invocation to `--help` in `exe/ace-nav` and preserve legacy `--sources` / `--create` aliases via executable argument translation.
- Update integration tests to assert explicit dry-cli invocation behavior.

## [0.17.7] - 2026-02-19

### Technical
- Add test coverage for subdirectory protocol resolution patterns

## [0.17.6] - 2026-02-17

### Fixed
- Add `--tree` option to Resolve command to prevent dry-cli from calling `exit(1)` on unknown option
  - This caused integration tests to crash mid-process, breaking both grouped and single-batch test execution
  - `ace-test-suite` reported 0 tests for ace-support-nav because the subprocess died before minitest output

### Technical
- Remove dead `navigation_integration_test.rb` that was permanently skipped via `runnable_methods` returning `[]`
- Consolidate E2E test configuration fixtures

## [0.17.5] - 2026-02-11

### Changed
- Simplified path resolution in `ProtocolSource` to consistently use project root
- Extracted `find_project_root` private method for cleaner code structure

### Technical
- Migrate E2E tests to per-TC directory format
- Add E2E tests for ace-nav and ace-timestamp

## [0.17.4] - 2026-02-02

### Fixed
- Protocol listing with empty path (`wfi://`) now correctly lists all resources
  - Empty path after `://` is now normalized to `nil` in `ResourceUri`
  - Enables `pattern = uri.path || "*"` to default to wildcard
- Bare protocol names (`wfi`, `tmpl`, `guide`) now auto-expand to `protocol://` format
  - Added `normalize_protocol_shorthand` in Resolve command
  - Both `ace-nav wfi` and `ace-nav wfi://` now list all workflow instructions
- Extension inference prefix matching bug (TC-004)
  - `start_with?` was too permissive, matching `multi-ext.guide.md` when searching for `multi-ext.g`
  - Now validates character following candidate is either end-of-string or dot separator

## [0.17.3] - 2026-01-24

### Added
- Extension inference for protocol resolution (task 224)
  - Add `ExtensionInferrer` atom for DWIM extension inference
  - Configure inference via `.ace/nav/config.yml` with `extension_inference.enabled` and `fallback_order`
  - Add `inferred_extensions` to protocol configs (guide.yml, wfi.yml)
  - Update `ProtocolScanner` to use inference when exact match fails
  - Strip extensions using both protocol and inferred extension lists

## [0.17.2] - 2026-01-16

### Changed
- Updated README.md references from ace-context to ace-bundle (task 206)

## [0.17.1] - 2026-01-15

### Changed
- Migrate CLI commands to Hanami pattern
  - Move commands from `commands/` to `cli/commands/`
  - Update namespace from `Commands::*` to `CLI::Commands::*`
  - Update test file references for new namespace

## [0.17.0] - 2026-01-12

### Changed
- **BREAKING**: Renamed gem from `ace-nav` to `ace-support-nav`
  - Namespace changed from `Ace::Nav` to `Ace::Support::Nav`
  - Import path changed from `require "ace/nav"` to `require "ace/support/nav"`
  - Gem dependency changed from `ace-nav` to `ace-support-nav`
  - Executable remains `ace-nav` for backwards compatibility
  - User config path `.ace/nav/` preserved for backward compatibility

### Migration Guide
```ruby
# Before
require "ace/nav"
Ace::Nav.config
Ace::Nav::CLI.start(ARGV)

# After
require "ace/support/nav"
Ace::Support::Nav.config
Ace::Support::Nav::CLI.start(ARGV)
```

## Previous Releases (as ace-nav)

For detailed changes prior to 0.17.0, see the git history of the ace-nav directory before the rename (commit da99d457b and earlier).

### Notable releases before rename:

- **0.16.1**: Eliminated wrapper pattern in dry-cli commands
- **0.16.0**: Migrated CLI framework from Thor to dry-cli
- **0.15.0**: Thor CLI migration with standardized command structure
- **0.14.0**: Minimum Ruby version raised to 3.3.0
- **0.13.0**: Renamed `.ace.example/` to `.ace-defaults/`
- **0.10.0**: Added task:// Protocol Support
- **0.9.0**: Initial release with core navigation functionality


## [0.17.8] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
