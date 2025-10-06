# Changelog

All notable changes to ace-context will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.0] - 2025-10-06

### Added
- Git diff support via `diffs:` configuration key
- `Ace::Context::Atoms::GitExtractor` for secure git operations
- Support for combining files, commands, diffs, and presets in unified configuration
- Git diff formatting in all output modes (markdown, xml, markdown-xml, json, yaml)
- Comprehensive test suite for git operations (10 tests)

### Changed
- ace-core `OutputFormatter` now handles diffs section in all formats
- README updated with Content Sources section documenting all supported types

## [0.9.0] - 2025-10-05

Initial release with preset management, file aggregation, and command execution support.
