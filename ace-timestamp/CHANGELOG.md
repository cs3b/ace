# Changelog

All notable changes to ace-timestamp will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
