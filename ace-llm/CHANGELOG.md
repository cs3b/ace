# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.1] - 2025-11-16

### Changed

- **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  - Provides access to latest PromptCacheManager features and infrastructure improvements
  - Maintains compatibility with standardized ACE ecosystem patterns

## [0.10.0] - 2025-11-15

### Added
- **System Prompt Control**: Added `--system-append` flag to ace-llm-query for flexible prompt composition
  - `--system` flag now fully replaces provider defaults (clarified behavior)
  - `--system-append` flag appends to existing/default system prompts
  - Both flags can be used together for layered prompt control
  - Claude provider: Maps to `--system-prompt` and `--append-system-prompt` CLI flags
  - API providers (Anthropic, OpenAI, Google): Concatenates prompts with clear separator
- **Enhanced Help Text**: Added provider-specific behavior notes to CLI help for system prompt flags
  - Clarifies Claude uses native flags while API providers concatenate
  - Improves user understanding of flag behavior across different providers

### Fixed
- **Claude Provider Bug**: Fixed ClaudeCodeClient to use correct `--system-prompt` flag instead of non-existent `--system`
  - Resolves issue where system prompts were silently ignored with Claude
  - Enables fast, deterministic responses with Claude Haiku for tools like ace-git-commit

### Changed
- **Code Organization**: Improved BaseClient helper method encapsulation
  - Made helper methods (`concatenate_system_prompts`, `process_messages_with_system_append`, `deep_copy_messages`) private
  - Relocated test file from `test/integration/` to `test/organisms/base_client_helpers_test.rb`
  - Aligns with ACE flat test structure (tests are unit tests for organism helpers)
- **Configuration**: Made system prompt separator configurable via `DEFAULT_SYSTEM_PROMPT_SEPARATOR` constant
  - Addresses potential markdown conflicts in concatenated prompts
  - Can be overridden by subclasses if needed
- **Improved System Prompt Handling**: Refactored implementation with shared helpers
  - Extracted concatenation logic to reduce code duplication
  - Added safety checks and comprehensive test coverage (13 new tests)
  - Implemented deep copy pattern to prevent message mutations

### Technical
- Added deprecation note for `append_system_prompt` option, prefer `system_append` for consistency

## [0.9.5] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.9.4]
 - 2025-10-08

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
