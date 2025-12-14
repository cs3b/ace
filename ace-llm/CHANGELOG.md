# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.15.1] - 2025-12-14

### Changed
- **Standardized GENERATION_KEYS pattern**: All LLM clients now use declarative constants
  - OpenAIClient, OpenRouterClient, GroqClient, MistralClient, AnthropicClient use `GENERATION_KEYS`
  - GoogleClient uses `GENERATION_KEY_MAPPING` (maps internal keys to Gemini camelCase API keys)
  - XAIClient already used this pattern (model implementation)
  - Replaces inline nil checks with cleaner iteration loop
  - Single point of truth for each client's supported parameters

### Fixed
- **MistralClient zero-value handling**: Fixed bug where `temperature: 0` was dropped
  - Changed from truthiness checks to nil checks
- **AnthropicClient zero-value handling**: Fixed bug where `temperature: 0` was dropped
  - Changed from truthiness checks to nil checks
- **GoogleClient zero-value handling**: Fixed bug where `temperature: 0` was dropped
  - Changed from truthiness checks to nil checks

## [0.15.0] - 2025-12-14

### Added
- **OpenAICompatibleParams module**: Shared concern for extracting OpenAI-compatible parameters
  - Extracts `frequency_penalty` and `presence_penalty` using nil-safe logic
  - Preserves zero values (uses `nil?` check, not truthiness)
  - Included in XAIClient, OpenAIClient, and OpenRouterClient
  - DRYs up code across OpenAI-compatible providers

### Fixed
- **OpenAIClient zero-value handling**: Fixed bug where zero-valued penalties were dropped
  - `build_request_body` now uses nil checks for all generation parameters
  - Zero values for `frequency_penalty`, `presence_penalty`, `temperature`, `max_tokens`, `top_p` are preserved
- **YAML security hardening**: Removed Symbol from `permitted_classes` in `YAML.safe_load`
  - Prevents potential DoS attacks via symbol table exhaustion
  - All provider YAML configs already use string keys (no breaking changes)
  - Added specific `Psych::DisallowedClass` warning for better debugging

### Technical
- Added comprehensive OpenAIClient test suite (15 new tests)
- Added zero-value regression tests to XAIClient tests
- Improved symbol rejection test with warning message assertions

## [0.14.0] - 2025-12-07

### Added
- **Groq Provider**: New LLM provider for Groq's ultra-fast inference API
  - Supports GPT-OSS 120B/20B, Kimi K2, and Mistral Saba models
  - OpenAI-compatible API with ultra-fast inference
  - Default model: openai/gpt-oss-120b with max_tokens: 4096
  - Global aliases: `groq`, `groq-fast`, `groq-kimi`, `groq-saba`
  - Model aliases: `gpt-oss`, `gpt-oss-120b`, `gpt-oss-20b`, `kimi-k2`, `saba`
  - Environment variable: `GROQ_API_KEY`
  - Supports `stop` sequences parameter

### Fixed
- **Zero-valued generation params**: Changed from truthiness checks to nil checks
  - Allows `temperature: 0`, `frequency_penalty: 0`, `presence_penalty: 0`
  - Affects GroqClient and ensures consistent behavior with OpenRouterClient

### Changed
- Stream flag explicitly disabled (streaming not implemented)
- Parameter extraction refactored to use `Hash#slice` for cleaner code

### Breaking Changes
None

## [0.13.0] - 2025-12-06

### Added
- **OpenRouter Provider**: New LLM provider for OpenRouter's unified API (400+ models)
  - OpenAI-compatible API with optional attribution headers (HTTP-Referer, X-Title)
  - Focus: Exclusive providers (DeepSeek, Kimi, Qwen) + fast inference via `:nitro` routing (Groq/Cerebras)
  - Default model: openai/gpt-oss-120b:nitro with temperature: 0.7, max_tokens: 4096
  - Fast inference aliases: `gpt-oss-nitro`, `kimi-nitro`, `qwen3-nitro`, `gpt-oss-small-nitro`
  - Provider aliases: `deepseek`, `deepseek-r1`, `kimi`, `kimi-think`, `qwen-coder`, `qwq`, `hermes`, `glm`, `minimax`, `reka`, `devstral`
  - Environment variable: `OPENROUTER_API_KEY`
  - Handles non-JSON error responses (e.g., HTML from 502 errors)
  - Explicit nil checks for generation params (allows temperature: 0, frequency_penalty: 0)
  - Preserves `native_finish_reason` metadata from OpenRouter

## [0.12.0] - 2025-12-06

### Added
- **x.ai (Grok) Provider**: New LLM provider for x.ai's Grok models
  - Supports grok-4, grok-4-fast, grok-4-1-fast, grok-code-fast-1, grok-3, grok-3-fast, grok-3-mini, grok-2
  - OpenAI-compatible API with full generation options
  - Default model: grok-4 with max_tokens: 4096
  - Global aliases: `grok` → xai:grok-4, `grokfast` → xai:grok-4-1-fast, `grokcode` → xai:grok-code-fast-1
  - Environment variable: `XAI_API_KEY`

### Changed
- **Provider Config Migration**: Moved provider configs from `providers/` to `.ace.example/llm/providers/`
  - Eliminates duplication between gem and project configs
  - Example configs now serve as the canonical source
- **XAIClient**: Uses constant-driven GENERATION_KEYS iteration pattern
  - Explicit `rescue StandardError` instead of bare rescue

## [0.11.0] - 2025-11-17

### Added
- **Graceful Provider Fallback**: Implemented automatic provider fallback with retry logic
  - Automatic retry with exponential backoff (configurable, default 3 attempts)
  - Intelligent error classification (retryable, skip to next, terminal)
  - Fallback provider chain with configurable alternatives
  - Total timeout protection (default 30s) to prevent infinite retry loops
  - Jitter (10-30%) added to retry delays to prevent thundering herd issues
  - Configurable via environment variables (`ACE_LLM_FALLBACK_*`) and runtime parameters
  - Status callbacks for user visibility during fallback operations
  - Respects Retry-After headers for rate limit compliance

### Changed
- **Fallback Orchestrator Refactoring**: Improved code organization and maintainability
  - Extracted error handling logic into dedicated `handle_error` method for better separation of concerns
  - Refactored `FallbackConfig.from_hash` with helper method to support both symbol and string keys
  - Enhanced retry delay calculation with jitter to prevent synchronized retry storms
  - Improved test coverage with range-based assertions for jittered delays

### Technical
- Added comprehensive test coverage for fallback system (atoms, molecules, models, integration)
- Follows ATOM architecture pattern with clear separation: ErrorClassifier (Atom), FallbackConfig (Model), FallbackOrchestrator (Molecule)
- Fixed minor style issues (missing newline at end of files)

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
