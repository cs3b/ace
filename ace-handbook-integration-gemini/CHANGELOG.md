# Changelog

All notable changes to ace-handbook-integration-gemini will be documented in this file.

## [Unreleased]

## [0.3.4] - 2026-03-29

### Technical
- Updated the `ace-handbook` runtime dependency range from `~> 0.21` to `~> 0.22` to follow the new handbook minor release.

## [0.3.3] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.


## [0.3.2] - 2026-03-29

### Fixed
- **ace-handbook-integration-gemini v0.3.2**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.3.1] - 2026-03-22

### Technical
- Refreshed the package README with standardized handbook integration sections, Gemini-specific provider wording, and ACE/`ace-handbook` linkage.

## [0.3.0] - 2026-03-12

### Changed
- Replaced the legacy `ace-handbook-integration-agent` dependency with a direct `ace-handbook` runtime dependency.
- Updated the package entrypoint and docs to treat Gemini integration as a thin provider plugin on top of `ace-handbook`.

## [0.2.0] - 2026-03-10

### Added
- Added a shipped Gemini provider manifest and packaging support so `ace-handbook sync` can project canonical skills into `.gemini/skills`.

## [0.1.1] - 2026-03-10

### Added
- Added the Gemini-specific handbook integration package scaffold on top of the shared agent integration base.

## [0.1.0] - 2026-03-10

### Added
- Initial package scaffold for Gemini handbook integration support.
