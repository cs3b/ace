# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-01-03

### Added
- Guides support with handbook/guides/ directory
- workflow-context-embedding.g.md guide for embed_document_source pattern
- Guide discovery protocol (.ace-defaults/nav/protocols/guide-sources/ace-handbook.yml)

## [0.3.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.2.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory

## [0.1.0] - 2025-11-05

### Added
- Initial release of ace-handbook gem as pure workflow package
- 6 handbook management workflows accessible via wfi:// protocol:
  - `wfi://manage-guides` - Create and update development guides
  - `wfi://review-guides` - Review guides for quality and consistency
  - `wfi://manage-workflow-instructions` - Create and validate workflow files
  - `wfi://review-workflows` - Review workflow instructions
  - `wfi://manage-agents` - Create and update agent definitions
  - `wfi://update-handbook-docs` - Update handbook README and structure
- Path references updated for project-relative usage
- Complete gem structure following ACE patterns
- Comprehensive documentation and usage examples
- Auto-discovery support through ace-nav gem

### Changed
- Migrated workflows from dev-handbook/.meta/wfi/ to installable gem
- Updated path references to be project-root relative
- Removed dev-handbook specific dependencies

### Removed
- Moved `update-tools-docs.wf.md` to ace-docs package (tools documentation management)
- Moved `update-integration-claude.wf.md` to ace-integration-claude package (Claude Code integration)

### Fixed
- Added ace-nav protocol registration (.ace.example/nav/protocols/wfi-sources/ace-handbook.yml)
- Updated gemspec to include protocol registration files for proper discovery

### Technical Details
- Pure workflow package with no Ruby runtime dependencies
- Auto-discovery via ace-nav through handbook/workflow-instructions/ directory
- Protocol registration enables ace-nav to discover workflows from installed gem
- Template embedding framework ready for ADR-002 compliance
- Standard ACE gem structure with lib/, handbook/, gemspec, README, CHANGELOG