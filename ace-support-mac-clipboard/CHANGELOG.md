# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

## [0.3.3] - 2026-04-13

### Changed
- **ace-support-mac-clipboard v0.3.3**: Standardized shared package tests to the fast-only layout and updated testing flow defaults.


## [0.3.2] - 2026-04-11

### Technical
- Migrated deterministic package tests to `test/fast/` (`test/mac_clipboard_test.rb` -> `test/fast/mac_clipboard_test.rb`).
- Documented `ace-support-mac-clipboard` as a fast-only package and kept deterministic verification on:
  - `ace-test ace-support-mac-clipboard`
  - `ace-test ace-support-mac-clipboard all`
- Confirmed this migration does not introduce `test/feat/` or `test/e2e/` layers.

## [0.3.1] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.3.0] - 2026-03-23

### Technical
- Removed phantom `handbook/**/*` glob from gemspec (no handbook directory exists).

## [0.2.3] - 2026-03-22

### Technical
- Corrected README integration guidance to reference `ace-idea` clipboard usage instead of `ace-taskflow`.

## [0.2.2] - 2026-03-22

### Technical
- Refreshed README structure with consistent tagline, overview, basic usage, and ACE project footer

## [0.2.1] - 2026-02-12

### Fixed
- Guard `require "ace/support/mac_clipboard"` behind platform check to prevent load errors on non-macOS
- Skip all tests gracefully on non-macOS platforms instead of failing

## [0.2.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.1.1] - 2025-11-11

### Added
- Comprehensive test suite with smoke test pattern compatibility
- Test infrastructure for all core components (Error, ContentType, Reader, ContentParser)

### Fixed
- Test discovery and execution issues with ace-test integration
- Module structure and constant loading verification tests

### Changed
- Update test structure to work with ace-test smoke pattern
- Improve test coverage for clipboard functionality

## 0.1.0 - 2025-10-13

### Added
- Initial release of ace-support-mac-clipboard
- Core clipboard functionality with FFI integration
- ContentType module for macOS clipboard type mappings
- Reader class for clipboard content access
- ContentParser class for data processing

[1]: https://keepachangelog.com/en/1.0.0/
[2]: https://semver.org/spec/v2.0.0.html
