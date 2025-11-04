# Changelog

All notable changes to ace-git-worktree will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-11-04

### Added
- Initial release of ace-git-worktree gem
- Task-aware worktree creation with `--task` flag
- Integration with ace-taskflow for metadata lookup
- Automatic task status update to in-progress (configurable)
- Worktree metadata addition to task frontmatter
- Automatic mise trust execution when mise.toml detected
- Traditional branch-based worktree creation
- List command showing all worktrees with task associations
- Switch command for navigation by task ID or name
- Remove command with cleanup
- Prune command for deleted worktrees
- Configuration via `.ace/git/worktree.yml`
- Support for custom naming formats with template variables
- Dry-run mode for preview without creation
- JSON and table output formats for listing
- Comprehensive test suite with ATOM architecture
- Handbook with workflow instructions and agent definitions

[Unreleased]: https://github.com/yourusername/ace-git-worktree/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/ace-git-worktree/releases/tag/v0.1.0