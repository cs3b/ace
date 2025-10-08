# Changelog

All notable changes to ace-git-commit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
