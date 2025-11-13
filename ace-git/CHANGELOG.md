# Changelog

All notable changes to ace-git will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-11

### Added

- Initial release of ace-git workflow package
- **Rebase Workflow** (`wfi://rebase`): Changelog-preserving rebase operations
  - CHANGELOG.md conflict resolution strategies
  - Version file preservation patterns
  - Recovery procedures for failed rebases
- **PR Creation Workflow** (`wfi://create-pr`): Pull request creation with templates
  - GitHub CLI integration examples
  - Three PR templates: default, feature, bugfix
  - Draft PR workflow support
  - Alternative platform instructions (GitLab, Bitbucket)
- **Squash Workflow** (`wfi://squash-pr`): Version-based commit squashing
  - Automatic version boundary detection
  - Multiple squashing strategies (version, interactive, manual)
  - CHANGELOG preservation during squash
  - Comprehensive commit message templates
- **Templates**: Structured templates for consistent documentation
  - PR templates: default, feature, bugfix
  - Commit squash template with structured format
- **Protocol Integration**: ace-nav protocol support
  - wfi:// protocol for workflow discovery
  - template:// protocol for template access
- **Configuration**: Minimal, preference-based configuration
  - Optional user preferences in `.ace/git/config.yml`
  - Sensible defaults inline in workflows
- Comprehensive README with usage examples
- MIT License

### Design Decisions

- Workflow-first architecture (no CLI executables)
- Self-contained workflows following ADR-001 principles
- Minimal configuration (preferences only, not behavior control)
- GitHub CLI as primary PR creation method with alternatives documented

[0.1.0]: https://github.com/cs3b/ace-meta/releases/tag/ace-git-v0.1.0
