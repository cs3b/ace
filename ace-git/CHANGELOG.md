# Changelog

All notable changes to ace-git will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-11-15

### Added

- **PR Description Workflow** (`wfi://update-pr-description`): Automated PR title and description generation
  - New `/ace:update-pr-desc` command for easy invocation from Claude Code
  - Extracts metadata from CHANGELOG.md entries and task files
  - Analyzes commit messages to identify change patterns and types
  - Generates structured PR descriptions with summary, changes breakdown, breaking changes, and related tasks
  - Auto-detects PR number from current branch or accepts explicit PR number argument
  - Uses conventional commits format for PR titles (e.g., `feat(scope): description`)
  - GitHub CLI integration for updating PR titles and descriptions
  - Comprehensive documentation with examples and best practices
  - Supports multi-line body formatting with heredoc for clean PR updates

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
