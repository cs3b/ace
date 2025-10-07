# Changelog

All notable changes to ace-core will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.2] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.1] - 2025-10-06

### Added
- **Git diff formatting support** in `OutputFormatter`
  - Added diffs section rendering in `format_markdown` (with ```diff blocks)
  - Added diffs section rendering in `format_xml` (<diffs> with CDATA)
  - Added diffs section rendering in `format_markdown_xml` (<diff> with attributes)
  - Supports rendering git diff output from ace-context

### Changed
- `OutputFormatter` now handles `data[:diffs]` array in all output formats

## [0.9.0] - 2025-10-05

Initial release with core functionality for ACE ecosystem.
