# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.13.1] - 2026-01-16

### Fixed
- **OpenCodeClient**: Fixed command syntax to match current OpenCode CLI interface
  - Changed from `opencode generate` to `opencode run` subcommand
  - Pass prompt as positional argument instead of `--prompt` flag
  - Removed unsupported flags: `--format`, `--temperature`, `--max-tokens`, `--system`
  - Handle system prompts by prepending to main prompt (no native `--system` flag)
- Added regression tests for correct OpenCode command building

## [0.13.0] - 2026-01-13

### Added
- **GeminiClient**: Added Google Gemini CLI provider integration
  - Supports Gemini 2.5 Flash, Gemini 2.5 Pro, Gemini 2.0 Flash, and Gemini 1.5 Pro models
  - JSON output parsing for structured responses with token metadata
  - System prompt embedding (Gemini CLI lacks native `--system-prompt` flag)
  - Provider aliases: `gflash`, `gpro`, `gemini-flash`, `gemini-pro`
  - Auto-registers with ace-llm provider system

## [0.12.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.11.1] - 2025-12-30

### Changed

* Replace ace-support-core dependency with ace-config

## [0.11.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.10.2] - 2025-12-06

### Technical
- Updated ace-llm dependency from `~> 0.12.0` to `~> 0.13.0` for OpenRouter provider support

## [0.10.1] - 2025-11-17

### Technical
- Updated ace-llm dependency from `~> 0.10.0` to `~> 0.11.0` for graceful provider fallback support

## [0.10.0] - 2025-11-15

### Added
- **ClaudeCodeClient Enhancement**: Added support for `--append-system-prompt` flag
  - Maps `system_append` option to Claude CLI's `--append-system-prompt` flag
  - Enables flexible prompt composition with Claude models

### Fixed
- **ClaudeCodeClient Bug**: Fixed system prompt handling to use correct `--system-prompt` flag
  - Changed from non-existent `--system` to proper `--system-prompt` flag
  - Resolves issue where system prompts were ignored with Claude provider

### Changed
- **Dependency Update**: Updated ace-llm dependency to ~> 0.10.0
  - Aligns with ace-llm minor version bump for system prompt control features

### Technical
- Added deprecation note for `append_system_prompt` option, prefer `system_append` for consistency

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
