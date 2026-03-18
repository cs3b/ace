# Changelog

All notable changes to ace-b36ts (formerly ace-support-timestamp) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.11.2] - 2026-03-18

### Fixed
- Treated naïve timestamp strings as UTC while preserving explicit timezone parsing in `ace-b36ts encode`.

## [0.11.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.11.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.10.3] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.10.2] - 2026-03-13

### Changed
- Updated the canonical `as-b36ts` skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

## [0.10.1] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-b36ts` skill so provider projections now inherit the canonical skill body unchanged.

## [0.10.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-b36ts` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

## [0.9.1] - 2026-03-10

### Fixed
- Added the missing canonical `# bundle:` metadata to the `as-b36ts` skill so it validates under the strict typed skill schema.

## [0.9.0] - 2026-03-09

### Added
- Added `skill-sources` gem defaults registration at `.ace-defaults/nav/protocols/skill-sources/ace-b36ts.yml` so `skill://` can discover canonical `handbook/skills` entries from `ace-b36ts`.

## [0.8.0] - 2026-03-09

### Added
- Added canonical capability skill example at `handbook/skills/as-b36ts/SKILL.md` with workflow binding to `wfi://b36ts`.

## [0.7.5] - 2026-02-28

### Fixed
- `encode_split` week token now uses ISO Thursday-based attribution (`iso_week_month_and_number`) instead of naive day-based calculation (`simple_week_in_month`)
- `encode_split` week token now correctly encodes values 31-35 (base36 `v`–`z`) instead of raw week numbers 1-5, matching `encode_week` output
- `encode_split` month component now uses the ISO week's month when `:week` is in levels, ensuring boundary dates (e.g., Sunday Mar 1 whose Thursday is Feb 26) partition to the correct month

## [0.7.4] - 2026-02-24

### Changed
- Migrated `ace-b36ts/test/e2e` to goal-mode pilot scenario `TS-B36TS-001-pilot`
- Replaced four legacy procedural E2E scenarios with runner/verifier split test assets
- Updated pilot `scenario.yml` with required loader fields (`area`, `setup`) for `ace-test-e2e` compatibility

## [0.7.3] - 2026-02-23

### Changed
- Extracted format-specific encode/decode/increment methods into FormatCodecs module
- Reduced CompactIdEncoder from 1,294 to 654 lines

### Technical
- Updated internal dependency version constraints to current releases

## [0.7.2] - 2026-02-22

### Changed
- Migrated to standard dry-cli help pattern (no args shows help)
- Removed DefaultRouting extension in favor of HelpCommand registration

## [0.7.1] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings

## [0.7.0] - 2026-02-17

### Changed
- Week format (`encode_week`/`decode_week`) now uses ISO Thursday rule instead of simple day-based calculation
  - A week belongs to the month containing its Thursday (ISO 8601 convention)
  - Boundary dates (e.g., Feb 1 on a Saturday) encode as the previous month's week
  - Year-crossing dates (e.g., Dec 31 on a Wednesday) encode as the next year's January
  - `decode_week` now returns the Thursday of the week (the defining day)
  - Week values remain 1-5 (encoded as 31-35); format is unchanged
- Split encoder (`encode_split`) retains simple day-based week calculation for path buckets

### Technical
- Added `iso_week_month_and_number` private helper for ISO Thursday-based week-in-month calculation
- Renamed `calculate_week_in_month` to `simple_week_in_month` (used by split encoder only)
- Added `calculate_months_offset_ym` helper for explicit year/month offset calculation
- Expanded week format test coverage with ISO boundary, year-crossing, and leap year cases

## [0.6.0] - 2026-02-14

### Changed
- **Breaking**: Gem renamed from `ace-support-timestamp` to `ace-b36ts` (task 267)
  - Namespace changed from `Ace::Support::Timestamp` to `Ace::B36ts`
  - Binary changed from `ace-timestamp` to `ace-b36ts`
  - Require path changed from `ace/support/timestamp` to `ace/b36ts`
  - Config namespace changed from `timestamp:` to `b36ts:` in YAML config files
  - Config directory changed from `.ace/timestamp/` to `.ace/b36ts/`
  - No backward compatibility shims provided (per ADR-024)

## [0.5.0] - 2026-02-03

### Added
- Sequence generation for multiple sequential IDs (`--count` / `-n` option)
  - `ace-timestamp encode --count 10 --format ms now` generates 10 sequential ms-precision IDs
  - `ace-timestamp encode -n 5 --format day now` generates 5 consecutive day IDs
  - JSON output support: `--count 3 --json` outputs as JSON array
- `CompactIdEncoder.encode_sequence` method for programmatic sequence generation
- `CompactIdEncoder.increment_id` method for incrementing any format ID
- Overflow cascade handling for all formats (ms → 50ms → 2sec → block → day → month)

## [0.4.1] - 2026-01-31

### Added
- Hierarchical split format for timestamp encoding/decoding (`encode_split`, `decode_path`)
- CLI options: `--split`, `--path-only`, `--json` for split encoding output
- Auto-detection of path separators (`/`, `\`, `:`) in decode

### Performance
- Moved CLI integration tests to E2E test suite
  - Tests now run via `/ace:run-e2e-test ace-support-timestamp MT-TIMESTAMP-004`
  - Test execution time reduced from 13.93s to ~61ms (99.6% reduction)

## [0.4.0] - 2026-01-24

### Added
- Precision-based format names for better clarity: `2sec` (~1.85s), `40min` (40-min blocks), `50ms` (~50ms), `ms` (~1.4ms)

### Fixed
- **Critical**: 4-char format now correctly uses 40-minute blocks (0-35) instead of hours (0-23)
  - This aligns with position 4 of the compact format design
  - Time at 12:30 now encodes to block 18, not hour 12

### Changed
- **Breaking**: Format options renamed to precision-based names
  - `compact` → `2sec`
  - `hour` → `40min` (with bug fix)
  - `high_7` → `50ms`
  - `high_8` → `ms`
  - Old format names are no longer accepted
- Default format changed from `compact` to `2sec`
- Updated all documentation and examples to use new format names

### Technical
- Renamed internal encoding/decoding methods to match precision-based names
- Updated all test files to use new format names
- Updated CLI help text with precision-based descriptions
- Updated fallback defaults in config resolver

## [0.3.0] - 2026-01-24

### Added
- Granular timestamp format templates: month (2 chars), week (3 chars), day (3 chars), hour (4 chars)
- High-precision timestamp formats: high-7 (7 chars, ~50ms), high-8 (8 chars, ~1.4ms)
- Format auto-detection for variable-length IDs (2-8 characters)
- `--format` option to encode CLI for specifying output format
- `default_format` configuration option (defaults to `compact` for backward compatibility)
- Day/week disambiguation for 3-char IDs using 3rd character value (0-30=day, 31-35=week)

### Changed
- Decode command now supports variable-length IDs with automatic format detection
- Updated CLI help text to reflect new format options

### Technical
- Added `atoms/format_specs.rb` with format specifications and detection logic
- Extended `CompactIdEncoder` with format-aware encode/decode methods
- Updated `Formats` module with patterns for all supported ID lengths

## [0.2.2] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.2.1] - 2026-01-14

### Changed
- Migrate CLI to Hanami pattern (per ADR-023)
  - Moved command classes from `cli/*.rb` to `cli/commands/*.rb`
  - Updated namespace from `Commands::*` to `CLI::Commands::*`
  - CLI registry updated to reference `CLI::Commands::*` classes

## [0.2.0] - 2026-01-11

### Changed
- **Breaking**: Gem renamed to `ace-support-timestamp` (task 202.03)
  - Namespace changed from `Ace::Timestamp` to `Ace::Support::Timestamp`
  - Executable remains `ace-timestamp` for backward compatibility
- **CLI migrated to dry-cli** (task 179.16)
  - Replaced Thor-based CLI with dry-cli registry pattern
  - Thor dependency replaced with dry-cli ~> 1.1 in gemspec
  - Command classes moved to `cli/` directory as separate files
  - Commands now use keyword arguments for options

### Removed
- Backward compatibility require shim (`require "ace/timestamp"`) per ADR-024
- Namespace alias `Ace::Timestamp` - use `Ace::Support::Timestamp` directly

## [0.1.1] - 2026-01-06

### Fixed

- Fix CLI exit code handling using standard ACE pattern (`result.is_a?(Integer) ? result : 0`)
- Change default CLI command from `help` to `encode` (encodes current time when no args)
- Fix timestamp parsing to check legacy format (YYYYMMDD-HHMMSS) before Time.parse
- Add configuration validation for alphabet (36 chars) and year_zero (1900-2100)
- Add ace-support-test-helpers to development dependencies
- Correct day range documentation from "0-35" to "0-30"

## [0.1.0] - 2026-01-06

### Added

- Initial release of ace-timestamp gem
- `CompactIdEncoder` atom for encoding/decoding timestamps to 6-character Base36 IDs
- `Formats` atom for detecting and parsing timestamp formats (compact vs timestamp)
- `ConfigResolver` molecule for ace-config cascade integration
- CLI commands: `encode`, `decode`, `config`
- Configurable `year_zero` for custom base year (default: 2000)
- 108-year coverage with ~1.85 second precision
- Chronologically sortable IDs (string sort = time sort)
- Comprehensive test suite

### Format Specification

- 6 Base36 characters (0-9, a-z)
- Positions 1-2: Month offset from year_zero (108 years of months)
- Position 3: Day of month (1-31 mapped to 0-30)
- Position 4: 40-minute block of day (36 blocks)
- Positions 5-6: Precision within block (~1.85s)
