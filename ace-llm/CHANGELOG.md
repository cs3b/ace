# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.26.12] - 2026-03-18

### Fixed
- Changed Claude `@ro` preset behavior to disable tools without entering native Claude `plan` mode, preserving read-only execution while avoiding empty-response failures in one-shot JSON output.
- Suppressed misleading `Total timeout exceeded (...)` status reporting after terminal single-provider failures so the real provider error remains the primary signal.

### Technical
- Added regression coverage for Claude `@ro` preset wiring and fallback terminal-error timeout reporting.

## [0.26.11] - 2026-03-17

### Fixed
- Updated default provider context limits: Anthropic from 200K to 1M tokens, OpenAI from 128K to 1.05M tokens to reflect modern model capabilities.

## [0.26.10] - 2026-03-17

### Fixed
- Resolve global alias inputs (for example `glite`) before provider/model validation so single-token alias-only provider inputs are accepted.

### Technical
- Fix `StubAliasResolver` test construction to pass hash as positional argument instead of keyword arguments.

## [0.26.8] - 2026-03-17

### Fixed
- Parse explicit `:high`/`:low`/`:medium`/`:xhigh` thinking suffixes before alias resolution so model aliases with thinking modifiers (for example `codex:gpt:high@ro`) resolve correctly.

## [0.26.7] - 2026-03-17

### Fixed
- Removed `--sandbox` from Gemini `ro` and `rw` presets; sandbox requires Docker/Podman and is orthogonal to `--approval-mode`.
- Changed Gemini `rw` preset `--approval-mode` from invalid `auto` to `auto_edit` (valid choices: `default`, `auto_edit`, `yolo`, `plan`).

## [0.26.6] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.26.5] - 2026-03-12

### Added
- Added `working_dir:` support to `QueryInterface.query` so CLI-backed provider executions can be anchored to an explicit filesystem root.

## [0.26.4] - 2026-03-12

### Changed
- Updated the handbook LLM reference guide to describe canonical package `handbook/skills/` ownership before provider projections.

### Fixed
- Restore provider preset defaults under `.ace-defaults/llm/presets/` after the preset refactor dropped `max_tokens: 16000` and rewrote Codex/Gemini sandbox CLI flags; keep the newer 600-second timeout standardization intact.

## [0.26.3] - 2026-03-07

### Changed
- Improve `--list-providers` output readability: show model count in provider header, wrap long model lists at 78 characters.

## [0.26.2] - 2026-03-07

### Changed
- Refactor `Configuration#provider` to use `Enumerable#find` for idiomatic Ruby.
- Use `<<~` HEREDOC for inactive-provider error message in `ProviderModelParser`.

## [0.26.1] - 2026-03-07

### Technical
- Move `configuration_test.rb` to `test/organisms/` per ADR-017 flat test structure.

## [0.26.0] - 2026-03-07

### Added
- Added provider allow-list filtering controls through `llm.providers.active` and `ACE_LLM_PROVIDERS_ACTIVE`, including normalization and env override handling.
- Added configuration and parser tests covering allow-list behavior, env precedence, and inactive-vs-unknown provider classification.

### Changed
- Updated `ace-llm --list-providers` to show filtered-mode summary and inactive provider section when an allow-list is active.

### Fixed
- Distinguish inactive providers (configured but filtered out) from unknown providers in query validation errors, with actionable enablement guidance.

## [0.25.1] - 2026-03-06

### Added
- Support explicit `:low`, `:medium`, `:high`, and `:xhigh` thinking suffixes on fully qualified model targets while preserving existing `@ro`, `@rw`, and `@yolo` preset behavior.
- Add provider-scoped thinking overlays for Codex and Claude so explicit thinking levels map cleanly to provider-native runtime options.

### Changed
- Allow `ace-llm query` preset resolution to merge explicit thinking overrides after preset loading and before direct CLI overrides.

## [0.25.0] - 2026-03-05

### Added
- `last_message_file:` parameter in `QueryInterface.query` to thread last-message file path through to provider clients via `generation_opts`.

## [0.24.8] - 2026-03-04

### Fixed
- Normalize timeout inputs across `--timeout` flows in CLI query and fallback paths so string values are safely coerced to numeric before use.

## [0.24.7] - 2026-03-04

### Added
- Plan-mode template at `tmpl://agent/plan-mode` (`ace-llm/handbook/templates/agent/plan-mode.template.md`) for reusable planning-only instruction composition.

### Changed
- Strengthen plan-mode template contract with explicit required section headings and stricter prohibitions against permission/escalation and status-only outputs.

## [0.24.6] - 2026-02-28

### Fixed
- Resolve `provider:provider` format (e.g., `codex:codex`) to provider's default model instead of passing literal provider name as model; adds fallback in `ClientRegistry#resolve_alias` when model alias matches provider name

## [0.24.5] - 2026-02-28

### Fixed
- Thread `--timeout` through fallback path: `FallbackOrchestrator` now accepts and forwards `timeout` to each `registry.get_client()` call, so `--timeout 300` is no longer silently dropped when fallback is enabled
- Raise `max_tokens` defaults from 4096–8192 to 16384 across all gem providers (anthropic, openai, google, zai, groq, xai, mistral, togetherai, openrouter, lmstudio) and all project-level provider overrides in `.ace/llm/providers/`

## [0.24.4] - 2026-02-27

### Added
- Per-provider fallback chains: `chains` map in config allows each primary provider to have its own contextual fallback order
- `FallbackConfig#providers_for(primary)` returns chain-specific fallback list or default `providers`

## [0.24.3] - 2026-02-27

### Technical
- Document `ZAI_API_KEY` in README API key section

## [0.24.2] - 2026-02-27

### Fixed
- Add project-level fallback providers so `ace-git-commit` works without `ZAI_API_KEY`
- Re-add CLI-specific error diagnostics listing available providers when provider not found
- Tighten "window limit" quota-detection pattern to avoid matching "context window limit"

### Technical
- Add inline comment documenting per-layer normalization rationale in fallback config loading

## [0.24.1] - 2026-02-27

### Fixed
- Narrowed quota-detection patterns to avoid false positives on unrelated error messages containing "credit" (e.g., "credentials invalid")

## [0.24.0] - 2026-02-27

### Added
- Native `zai` API provider with direct HTTP calls and bearer auth (`ZAI_API_KEY`), supporting models `glm-4.7-flashx`, `glm-4.7`, and `glm-5`
- Centralized `llm.fallback` config in `.ace-defaults/llm/config.yml` for shared fallback policy across QueryInterface and CLI callers

### Fixed
- Quota/credit/window-limit exhaustion classified as immediate fallback (no retry), while overload/unavailable/rate-limit conditions remain retryable
- Fallback provider chains normalize and deduplicate entries (including aliases) while preserving order
- Z.AI provider error surfacing includes actionable HTTP status and non-JSON response snippets

### Changed
- `ace-llm` CLI query command routes through `Ace::LLM::QueryInterface` for consistent fallback behavior across CLI and Ruby API
- Fallback documentation updated to use `.ace/llm/config.yml` (`llm.fallback`) as primary configuration contract

## [0.23.1] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.23.0] - 2026-02-22

### Changed
- **Breaking:** Migrated from multi-command Registry to single-command pattern (task 278)
  - Removed `query` subcommand: `ace-llm query gflash "prompt"` → `ace-llm gflash "prompt"`
  - Removed `list-providers` subcommand: `ace-llm list-providers` → `ace-llm --list-providers`
  - Removed `version`/`help` subcommands: use `--version`/`--help` flags only
  - Added `--version` and `--list-providers` flags to main command
  - Updated help text references from `ace-llm-query` to `ace-llm`
  - No backward compatibility (per ADR-024)

## [0.22.6] - 2026-02-22

### Changed
- Migrated from DefaultRouting to standard help pattern (task 278.21)
  - Removed DWIM default routing to query command
  - Added explicit `query` command requirement
  - Removed `--list-providers` alias (use `list-providers` command)
  - Added HelpCommand registration for `--help`, `-h`, `help`
  - No-args now shows help instead of error

### Technical
- Updated CLI tests to use explicit `query` command prefix
- Removed tests for deprecated DefaultRouting behavior

## [0.22.5] - 2026-02-22

### Fixed
- Pass `backends` configuration from provider YAML to client, fixing ClaudeOaiClient missing env vars (`ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`) and model tier mappings

## [0.22.3] - 2026-02-21

### Added
- `subprocess_env:` parameter on `QueryInterface.query()` for passing environment variables to CLI provider subprocesses

## [0.22.2] - 2026-02-17

### Fixed
- Added integration coverage to verify `QueryInterface.query(..., sandbox: ...)` forwards sandbox mode into generation options

## [0.22.1] - 2026-02-15

### Added
- `sandbox:` parameter on `QueryInterface.query()` for controlling CLI provider sandbox mode (forwarded via `generation_opts`)

## [0.22.0] - 2026-02-05

### Added
- `--cli-args` passthrough for CLI providers, with documentation and integration tests

### Fixed
- `--timeout` parsing in CLI query command to avoid string timeout errors

## [0.21.1] - 2026-02-04

### Added
- Provider config now includes `context_limit` field for model context window sizes
  - Google: 1M tokens (Gemini models)
  - Anthropic: 200K tokens (Claude models)
  - OpenAI: 128K tokens (GPT models)
  - Other providers: 128K default
- Default `context_limit` in main config.yml for unknown models

### Technical
- Lower Ruby version requirement to >= 3.2.0 across all gemspecs

## [0.21.0] - 2026-01-14

### Added
- Configuration cascade for provider discovery
  - Provider configs now cascade from gem defaults, project, and user paths
  - Dynamic provider discovery without hardcoding in ace-llm
  - New Configuration class and ConfigLoader molecule

### Changed
- Removed CLI provider configs from ace-llm gem (.ace-defaults/)
- Updated ClientRegistry to use Configuration cascade

### Fixed
- Handle non-JSON xAI API error responses gracefully
- Improved CLI argument parsing for ambiguous provider/model arguments

## [0.20.2] - 2026-01-13

### Fixed
- Query command ambiguous argument handling when `--model` doesn't contain colon
  - Added validation to detect when positional arg is not a valid provider
  - Shows help instead of proceeding with invalid provider/model combination
  - Fixed test to use non-alias value ("unknown-model" instead of "grok")

## [0.20.1] - 2026-01-13

### Fixed
- Handle non-JSON xAI API error responses gracefully (task 205)
  - Guard against String response bodies (e.g., HTML error pages from 502 gateway errors)
  - Include HTTP status code in error messages for better debugging
  - Apply safe pattern from OpenRouter client with explicit StandardError rescue

## [0.20.0] - 2026-01-11

### Changed
- **BREAKING**: Renamed executable from `ace-llm-query` to `ace-llm` (task 202.01)
  - The gem name remains `ace-llm`
  - The executable is now `ace-llm` (previously `ace-llm-query`)
  - Update scripts and documentation to use `ace-llm` command
  - All functionality remains the same

## [0.19.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `ListProviders` and `Query` dry-cli command classes
  - Deleted `list_providers_command.rb` and `query_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.19.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.13)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command classes (query, list_providers)
  - Standardized option type handling (temperature as float)

### Fixed
- CLI test compatibility with dry-cli capture patterns
- Default command routing for query command

## [0.18.0] - 2026-01-05

### Added
- Thor CLI migration with standardized command structure
- ConfigSummary display for effective configuration with sensitive key filtering
- Comprehensive CLI help documentation across all commands
- Routing for list-providers command

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Migrated from OptionParser to Thor framework
- Added method_missing for default subcommand support

### Fixed
- CLI routing and dependency management for feature parity
- --help dispatch for all ACE commands
- Addressed PR #123 review findings for Medium and higher priority issues

## [0.17.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.16.1] - 2025-12-30

### Changed

* Add ace-config dependency for configuration cascade management
* Refactor ClientRegistry to use Ace::Config.create() with deep merge

## [0.16.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


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


## [0.22.4] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
