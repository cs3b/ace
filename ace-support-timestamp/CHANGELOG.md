# Changelog

All notable changes to ace-support-timestamp will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Hierarchical split format for timestamp encoding/decoding (`encode_split`, `decode_path`)
- CLI options: `--split`, `--path-only`, `--json` for split encoding output
- Auto-detection of path separators (`/`, `\`, `:`) in decode

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
