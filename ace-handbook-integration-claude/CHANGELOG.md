# Changelog

All notable changes to ace-handbook-integration-claude will be documented in this file.

## [Unreleased]

## [0.3.1] - 2026-03-13

### Changed
- Updated the canonical Claude integration sync skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

## [0.3.0] - 2026-03-12

### Changed
- Replaced the legacy `ace-handbook-integration-agent` dependency with a direct `ace-handbook` runtime dependency.
- Updated the package entrypoint and docs to treat Claude integration as a thin provider plugin on top of `ace-handbook`.

## [0.2.0] - 2026-03-10

### Added
- Added a shipped Claude provider manifest so `ace-handbook sync` can discover `.claude/skills` as a first-class projection target.

## [0.1.1] - 2026-03-10

### Added
- Added the Claude-specific handbook integration package with canonical skill ownership and a namespaced update workflow.

## [0.1.0] - 2026-03-10

### Added
- Initial package scaffold for Claude handbook integration support.
