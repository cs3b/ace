# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.4] - 2025-10-08

### Changed

- **Test Structure Reorganization**: Reorganized tests for consistency
  - Moved `test/ace/llm_test.rb` → `test/llm_test.rb`
  - Moved `test/client_registry_test.rb` → `test/molecules/`
  - Moved `test/provider_config_validator_test.rb` → `test/atoms/`
  - Fixed require paths to match new structure
  - Aligns with standardized flat ATOM structure across all ACE packages

## [0.9.3] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.2] - 2025-10-07

### Fixed
- Standardized test file naming to follow project convention (`*_test.rb` suffix instead of `test_*` prefix)
- Renamed `test_provider_config_validator.rb` → `provider_config_validator_test.rb`
- Renamed `test_client_registry.rb` → `client_registry_test.rb`
- Test count increased from 25 to 53 tests (all tests now properly discovered)

## [0.9.1] - 2025-10-07

### Added
- `--model MODEL` flag for flexible LLM model specification in ace-llm-query CLI
- Model resolution with priority: flag > positional > provider default
- Dual syntax support: `PROVIDER[:MODEL]` and `PROVIDER --model MODEL`
- `model:` parameter to `QueryInterface.query()` Ruby API for programmatic model override

### Changed
- CLI help banner updated to show both syntax options
- README.md updated with `--model` flag documentation and examples

## [0.9.0] - 2024-XX-XX

### Added
- Initial release with LLM provider integration
- Unified CLI interface for querying multiple LLM providers
- Support for Google Gemini, OpenAI, Anthropic, Mistral, Together AI, and LM Studio
- Configuration-based provider architecture with YAML support
- LLM alias resolution for quick access to models
- Cost tracking and output formatting
- ATOM architecture pattern (Atoms, Molecules, Organisms, Commands)
