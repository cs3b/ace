# Changelog

All notable changes to ace-handbook-integration-opencode will be documented in this file.

## [Unreleased]

## [0.3.0] - 2026-03-12

### Changed
- Replaced the legacy `ace-handbook-integration-agent` dependency with a direct `ace-handbook` runtime dependency.
- Updated the package entrypoint and docs to treat OpenCode integration as a thin provider plugin on top of `ace-handbook`.

## [0.2.0] - 2026-03-10

### Added
- Added a shipped OpenCode provider manifest and packaging support so `ace-handbook sync` can project canonical skills into `.opencode/skills`.

## [0.1.1] - 2026-03-10

### Added
- Added the OpenCode-specific handbook integration package scaffold on top of the shared agent integration base.

## [0.1.0] - 2026-03-10

### Added
- Initial package scaffold for OpenCode handbook integration support.
