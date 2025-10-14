# Changelog

All notable changes to ace-docs will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
