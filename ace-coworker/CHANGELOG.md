# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-01-28

### Added

- Initial release with work queue-based session management
- CLI commands: start, status, report, fail, add, retry
- File-based queue storage with markdown step files
- Session persistence via session.yaml
- History preservation (failed steps remain visible)
- Dynamic step addition with automatic numbering
- Retry mechanism that creates new steps linked to original
