# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.2] - 2025-10-07

### Fixed
- Fixed test file discovery by updating Rakefile to include both `test_*.rb` and `*_test.rb` patterns
- Test count increased from 25 to 53 tests (discovered 28 previously missing tests)

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
