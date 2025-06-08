# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0+tasks.1] - 2025-06-08

### Added
- **LLM Integration Framework**: Complete implementation of Google Gemini AI integration
  - `llm-gemini-query` command-line tool for querying Google Gemini API (gemini-2.0-flash-lite model)
  - Support for prompt input from string arguments or file paths
  - Explicit output formatting with `--format` flag (text or json)
  - Debug mode with `--debug` flag for verbose error output
  - Environment variable support for API key configuration (.env file)
- **ATOM Architecture Components**:
  - **Atoms**: HTTPClient, JSONFormatter, EnvReader for core functionality
  - **Molecules**: APICredentials, HTTPRequestBuilder, APIResponseParser for composed behavior
  - **Organisms**: GeminiClient, PromptProcessor for high-level AI operations
- **HTTP Client Integration**: Faraday HTTP client for reliable API communication
- **Comprehensive Testing Suite**:
  - Unit tests for all ATOM components with >95% code coverage
  - Integration tests with live API using VCR for CI-friendly testing
  - CI-aware VCR configuration for automated testing environments
- **Developer Experience**:
  - `.env.example` template for API key configuration
  - Detailed documentation for testing with VCR
  - Examples and refactoring guides for API credentials

### Changed
- Enhanced CLI framework to support LLM command namespace
- Updated gemspec to include Faraday dependency
- Improved error handling with graceful API failure management

## [0.1.0] - 2025-06-06

### Added
- Initial Ruby gem structure with ATOM architecture (atoms, molecules, organisms, ecosystems)
- CLI framework using dry-cli with version command
- Comprehensive build system with bin/build, bin/test, bin/lint scripts
- RSpec testing framework with SimpleCov coverage reporting
- StandardRB linting configuration
- GitHub Actions CI/CD pipeline with multi-Ruby version testing (3.2, 3.3, 3.4)
- Development guides and contribution documentation
- Git workflow with commit message templates and PR templates

### Changed
- Established semantic versioning starting with v0.1.0
- Updated project documentation structure with docs/ directory

#### Project Foundation (v0.0.0 - Development Phase)
- Created the initial project roadmap and defined initial release structure
- Consolidated ideas into Product Requirements Document with context hydration, git aliases, markdown tasks, task capture, and UX features
- Added architectural research and documentation fixes including ATOM architecture research
- Established initial project structure including placeholder scripts in `bin/` and core documentation in `docs-project/`
- Added the `docs-dev` submodule and initial `.gitignore` file

[Unreleased]: https://github.com/your-org/coding-agent-tools/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/your-org/coding-agent-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/your-org/coding-agent-tools/releases/tag/v0.1.0
