# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.3] - 2025-10-08

### Changed

- **Test Structure Reorganization**: Reorganized tests with proper ATOM categorization
  - Moved `test/ace/llm_providers_cli_test.rb` → `test/llm_providers_cli_test.rb`
  - Created `test/molecules/` for CLI provider tests
  - Created `test/edge/` for edge case tests (new pattern)
  - Created `test/integration/` for provider registration tests
  - Fixed require paths to match new structure
  - Aligns with standardized flat ATOM structure across all ACE packages

## [0.9.2] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.1] - 2025-10-07

### Fixed
- Standardized test file naming to follow project convention (`*_test.rb` suffix instead of `test_*` prefix)
- Renamed `test_cli_execution_edge.rb` → `cli_execution_edge_test.rb`
- Renamed `test_cli_providers.rb` → `cli_providers_test.rb`
- Renamed `test_provider_registration.rb` → `provider_registration_test.rb`
- Test count increased from 51 to 57 tests (all tests now properly discovered)

## [0.9.0] - 2024-XX-XX

### Added
- Initial release with CLI-based LLM provider support
- Support for Claude Code and Codex providers
- Provider registration and configuration system
- OpenCode client implementation
