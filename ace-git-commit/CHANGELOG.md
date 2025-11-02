# Changelog

All notable changes to ace-git-commit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.1] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Changed dependency from `ace-test-support` to `ace-support-test-helpers` (if applicable)
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.11.0]
 - 2025-10-23

### Changed
- Integrated with ace-git-diff for unified git command execution
- GitExecutor now delegates to ace-git-diff's CommandExecutor for all git operations
- Added ace-git-diff (~> 0.1.0) as runtime dependency
- Maintains full backward compatibility for all public APIs

## [0.10.0] - 2025-10-14

### Added
- Standardize Rakefile test commands and add CI fallback

### Technical
- Add proper frontmatter with git dates to all managed documents

## [0.9.2] - 2025-10-08

### Changed

- **Test Structure Reorganization**: Reorganized tests for consistency
  - Moved `test/ace/git_commit_test.rb` → `test/git_commit_test.rb`
  - Aligns with standardized flat ATOM structure across all ACE packages

## [0.9.1] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.0] - 2024-XX-XX

### Added
- Initial release with LLM-powered Git commit message generation
- Support for conventional commit format
- Automatic staging of all changes (monorepo-friendly)
- Gemini 2.0 Flash Lite (`glite`) as default model
- Flexible model selection with `--model` flag
- Intention-based message generation with `-i/--intention` flag
- Dry-run mode for previewing commit messages
