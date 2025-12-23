# Changelog

All notable changes to ace-git will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.2] - 2025-12-22

### Fixed

- **Error Propagation**: `ace-git diff` now properly reports git errors for invalid ranges
  - Previously returned "(no changes)" silently when git failed
  - Now shows actual git error message and exits with code 1
  - Added `handle_result` helper in DiffGenerator for consistent error handling

## [0.3.1] - 2025-12-22

### Added

- **Examples in Main Help**: `ace-git --help` now shows common usage examples
- **Explicit Diff Command**: `ace-git diff --help` shows full help with options
- **SYNTAX Section**: Clear `[RANGE] [OPTIONS]` documentation in diff help

### Changed

- **Compact PR Output**: Reduced PR section from ~11 lines to ~4 lines
  - Header line with PR #, title, and status in brackets
  - Key-value lines for branch, author, URL
  - Applies to both `ace-git context` and `ace-git pr` commands

## [0.3.0] - 2025-12-22

### Added

- **CLI Executable** (`ace-git`): Full CLI with Thor for all git operations
  - `ace-git diff [RANGE]` - Generate git diff with filtering (migrated from ace-git-diff)
  - `ace-git context` - Show repository context (branch, PR, task pattern)
  - `ace-git branch` - Show current branch information with tracking status
  - `ace-git pr [NUMBER]` - Fetch and display PR metadata via GitHub CLI
  - All commands support `--format json` for machine-readable output

- **Migrated Components** (from ace-git-diff):
  - Atoms: CommandExecutor, DateResolver, DiffParser, PatternFilter
  - Molecules: ConfigLoader, DiffFilter, DiffGenerator
  - Organisms: DiffOrchestrator
  - Models: DiffConfig, DiffResult
  - Full backward compatibility with ace-git-diff functionality

- **New Components**:
  - `TaskPatternExtractor` atom: Extract task IDs from branch names (e.g., "140-feature" -> "140")
  - `PrIdentifierParser` atom: Parse PR identifiers (number, owner/repo#number, GitHub URLs)
  - `RepositoryStateDetector` atom: Detect repository state (:clean, :dirty, :rebasing, :merging)
  - `RepositoryChecker` atom: Check repository type (normal, detached, bare, worktree)
  - `GitScopeFilter` atom: Filter files by git scope (staged, tracked, changed)
  - `BranchReader` molecule: Read branch info with tracking status
  - `PrMetadataFetcher` molecule: Fetch PR metadata via gh CLI
  - `RepoContextLoader` organism: Orchestrate complete context loading
  - `RepoContext` model: Structured repository context with markdown/JSON output

- **Dependencies**:
  - Added `thor` (~> 1.3) for CLI framework
  - Updated `ace-support-core` to ~> 0.11

### Changed

- Package now includes CLI executable (previously workflow-only)
- Updated gemspec to include exe directory and thor dependency
- Summary updated to reflect unified git operations

### Migration Notes

- This version consolidates functionality from ace-git-diff
- ace-git-diff will be deprecated in favor of ace-git
- Use `ace-git diff` instead of `ace-git-diff` for equivalent functionality
- Existing ace-git workflows (wfi://rebase, wfi://create-pr, wfi://squash-pr) remain unchanged

## [0.2.2] - 2025-12-13

### Changed

- **Squash Workflow Enhancement**: Updated `wfi://squash-pr` to recommend logical grouping over single-commit squashing
  - Reframed purpose: "cohesive, logical commits" instead of "one commit per version"
  - Added RECOMMENDED banner for Logical Grouping strategy
  - Reordered strategies: Logical Grouping (1st), Commit Per Feature (2nd), One Commit (3rd)
  - Added real-world example: PR #72 squashed 16 → 3 logical commits
  - Rationale: Single-commit squashing loses valuable context; logical grouping preserves separation of concerns

## [0.2.1] - 2025-11-16

### Changed

- **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  - Provides access to latest PromptCacheManager features and infrastructure improvements
  - Maintains compatibility with standardized ACE ecosystem patterns

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
