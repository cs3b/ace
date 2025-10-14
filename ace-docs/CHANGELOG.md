# Changelog

All notable changes to ace-docs will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-10-14

### Added

- **ADR Lifecycle Workflows**: Comprehensive workflow instructions for complete ADR lifecycle management
  - `create-adr.wf.md`: Guide for creating new Architecture Decision Records
  - `maintain-adrs.wf.md`: Workflow for evolution, archival, and synchronization of existing ADRs
  - Embedded templates for ADR creation, deprecation notices, evolution sections, and archive README
  - Cross-references between workflows for seamless lifecycle management
  - Real examples from October 2025 ADR archival session
  - Decision criteria for archive vs evolve vs scope update actions
  - Research process guidance using grep to verify pattern usage
  - Integration with ace-docs validation tools

### Changed

- **update-docs.wf.md**: Added "Architecture Decision Records" section with references to both ADR workflows

## [0.1.1] - 2025-10-14

### Added
- Implement proper document type inference hierarchy
- Standardize Rakefile test commands and add CI fallback

### Fixed
- Resolve symlink paths correctly on macOS
- Fix document discovery and ignore patterns

### Technical
- Add document-specific guidelines to update-docs workflow
- Add missing usage.md and document remaining work as future enhancements
- Add proper frontmatter with git dates to all managed documents

## [0.1.0] - 2025-10-13

### Added
- Initial release of ace-docs gem
- Document status tracking with YAML frontmatter
- Document type classification (guide, architecture, reference, etc.)
- Batch analysis and reporting capabilities
- Integration with ace-core for configuration management
- CLI commands for status checking and document updates
- Support for automatic document updates based on frontmatter metadata
