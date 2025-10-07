# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
