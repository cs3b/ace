# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-01-03

### Changed

- Updated CLAUDE.md template to use `ace-context wfi://` instead of `ace-nav wfi://` for workflow discovery

## [0.3.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.2.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


### Added
- CLAUDE.md template (`integrations/claude/templates/CLAUDE.md.tmpl`) for project setup
  - Clear distinction between Claude Commands (slash commands) and CLI Tools (terminal)
  - Common ace-* tool patterns with placeholder syntax
  - Output handling best practices
  - Testing constraints and agent integration sections

### Changed
- Updated install-prompts.md with CLAUDE.md template reference

## [0.1.0] - 2025-11-05

### Added
- Initial release of ace-integration-claude gem as pure integration package
- Claude Code integration workflow accessible via wfi:// protocol:
  - `wfi://update-integration-claude` - Synchronize Claude Code integration files
- Integration assets bundled with the package:
  - Command templates for development workflows
  - Agent definition templates
  - Integration documentation and reference guides
  - Custom command definitions structure
- Complete gem structure following ACE patterns
- Comprehensive documentation and setup instructions
- Auto-discovery support through ace-nav gem

### Changed
- Extracted Claude Code integration from ace-handbook package
- Centralized all Claude Code integration concerns in dedicated package
- Updated workflow paths to be project-root relative

### Migration
- Moved `update-integration-claude.wf.md` from ace-handbook to dedicated package
- Copied integration assets from dev-handbook/.integrations/claude/ to package
- Maintained backward compatibility with existing Claude Code integration setup

### Fixed
- Added ace-nav protocol registration (.ace.example/nav/protocols/wfi-sources/ace-integration-claude.yml)
- Updated gemspec to include protocol registration files for proper discovery

### Technical Details
- Pure integration package with no Ruby runtime dependencies
- Auto-discovery via ace-nav through handbook/workflow-instructions/ directory
- Protocol registration enables ace-nav to discover workflows from installed gem
- Integration assets packaged in integrations/claude/ directory
- Standard ACE gem structure with lib/, handbook/, integrations/, README, CHANGELOG
- Positioned for future growth of Claude Code integration workflows