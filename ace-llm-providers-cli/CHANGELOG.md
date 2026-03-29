# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.27.2] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.


## [0.27.1] - 2026-03-29

### Fixed
- **ace-llm-providers-cli v0.27.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.27.0] - 2026-03-23

### Changed
- Updated gemspec description to include Gemini CLI, OpenCode, and pi-agent alongside Claude Code and Codex.
- Removed scaffolding boilerplate comment from gemspec.

## [0.26.2] - 2026-03-23

### Changed
- Refreshed README to the current package layout pattern with concise sections for how it works, use cases, features, quick start, and ACE linkage.

## [0.26.1] - 2026-03-22

### Changed
- Refreshed README structure with a dedicated purpose section, ACE-native test/lint command guidance, updated contributing workflow notes, and the canonical ACE footer link.

## [0.26.0] - 2026-03-21

### Changed
- Added initial `TS-LLMCLI-001` value-gated smoke E2E coverage for `ace-llm-providers-cli-check`, including deterministic no-tools and stubbed-tools command-path validation.

### Technical
- Added E2E runner/verifier artifacts and decision-record evidence for ADD/SKIP test-case gating.

## [0.25.7] - 2026-03-18

### Technical
- Added Claude command coverage for explicit tool allowlists so provider presets can distinguish tool-assisted read-only mode from strict no-tools prompt-only mode.

## [0.25.6] - 2026-03-18

### Fixed
- Preserve explicit empty CLI argument values in array-based `cli_args` normalization so flags like Claude `--tools ""` are forwarded correctly instead of losing their required value.

### Technical
- Added regression coverage for empty-value CLI arg normalization and Claude command construction.

## [0.25.5] - 2026-03-18

### Fixed
- Fixed Claude response extraction when the provider payload returned nested JSON content instead of a top-level string, preventing valid outputs from being dropped as empty.

### Technical
- Added nested payload parsing coverage for `parse_claude_response` to ensure future response-shape changes continue saving valid LLM output.

## [0.25.4] - 2026-03-17

### Fixed
- Raised `ProviderError` with structured payload details when Claude CLI exits successfully but returns empty response text.

### Technical
- Added regression coverage for parsed empty-response and `is_error` payload paths in `parse_claude_response`.

## [0.25.3] - 2026-03-17

### Fixed
- Rescue `Errno::EPIPE` in `SafeCapture` stdin write so broken-pipe crashes (e.g., Codex instant exit) capture stderr for the real error instead of raising an unhandled exception.
- Detect Claude CLI empty responses (exit 0 but 0-byte output) and raise `ProviderError` instead of silently writing empty files.
- Removed deprecated `--allowed-tools read_file` from Gemini CLI command builder; `--approval-mode` alone controls tool access.

### Technical
- Updated Gemini client tests to assert `--allowed-tools` is no longer present in built commands.

## [0.25.2] - 2026-03-15

### Fixed
- Removed unsupported CLI temperature forwarding for Claude Code CLI adapters so `--temperature` is no longer passed to subprocesses.

## [0.25.1] - 2026-03-12

### Fixed
- Resolved CLI-provider subprocess working directory from explicit `working_dir`, then `PROJECT_ROOT_PATH`, before falling back to process cwd, so sandbox-relative E2E artifact writes no longer leak into the repo root.
- Updated Codex, Claude, Claude OAI, Gemini, OpenCode, and Pi clients to use the resolved execution root for subprocess `chdir` and provider-side skill/worktree/prompt-cache path discovery.

## [0.25.0] - 2026-03-12

### Changed
- Codex now resolves skills from `.codex/skills` only and no longer falls back to `.agent/skills` or `.claude/skills`.
- Updated the default Codex provider `skills_dir` configuration to `.codex/skills`.

## [0.24.0] - 2026-03-10

### Changed
- PI now resolves skills from `.pi/skills` as its provider-native directory and no longer falls back to `.agent/skills` or `.claude/skills`.
- Updated the default PI provider `skills_dir` configuration to `.pi/skills`.

## [0.23.0] - 2026-03-09

### Added
- Generalized provider skills directory resolution with multi-path fallback for Codex, CodexOAI, ClaudeOAI, and Pi clients
- Default `skills_dir` configuration for Codex and Pi providers pointing to `.agent/skills`

### Technical
- Added fallback order tests for `codex_client` and `pi_client` skill directory resolution

## [0.22.2] - 2026-03-09

### Technical
- Added `SkillNameReader` regression coverage to ensure canonical SKILL frontmatter with nested `skill`/`assign` metadata still yields provider skill names.
- Added malformed-frontmatter guard test coverage for `SkillNameReader`.

## [0.22.1] - 2026-03-05

### Fixed
- `SessionFinder` dispatcher test now exercises the actual dispatch path instead of calling the Claude finder directly.

### Changed
- Added explanatory comment in `OpenCodeSessionFinder` documenting why `project_id` serves as a nil-gate only (OpenCode sessions lack project references).
- Added explanatory comment in `ClaudeSessionFinder` documenting why substring matching (`include?`) is used instead of exact equality.

## [0.22.0] - 2026-03-05

### Added
- Provider-specific session finders for Claude, Codex, Pi, Gemini, and OpenCode that detect fork sessions by scanning local session storage and matching by prompt.
- `SessionFinder` molecule dispatcher that routes session detection to the correct provider-specific atom.

## [0.21.1] - 2026-03-05

### Technical
- Documented `--output-last-message` minimum version requirement for Codex CLI in README, including verification command and graceful-degradation note.

## [0.21.0] - 2026-03-05

### Added
- `--output-last-message <path>` flag in `CodexClient#build_codex_command` when `last_message_file:` option is provided, enabling progressive last-message capture for timeout-resilient stall diagnosis.

## [0.20.1] - 2026-03-04

### Changed
- Gemini CLI prompt staging now uses `.ace-local/llm/prompts`.


## [0.20.0] - 2026-03-04

### Added
- Split shell-style tokens within array CLI arguments so multi-word entries like `"--sandbox danger-full-access"` normalize to discrete CLI flags/values.

## [0.19.4] - 2026-03-04

### Fixed
- Normalize timeout input in CLI provider capture so numeric and numeric-string values are accepted consistently for dry-run provider execution.

## [0.19.3] - 2026-02-23

### Changed
- Refactored cli-check script into ATOM structure with ProviderDetector, AuthChecker atoms and HealthChecker molecule

### Technical
- Updated internal dependency version constraints to current releases

## [0.19.2] - 2026-02-22

### Fixed
- Document that first matching tier wins when multiple tiers map to the same model in `ClaudeOaiClient`

## [0.19.1] - 2026-02-22

### Fixed
- `ClaudeOaiClient` now passes tier alias (`sonnet`/`opus`/`haiku`) to `--model` instead of backend model name (`glm-5`), fixing claude CLI model recognition errors
- Sets `ANTHROPIC_DEFAULT_<TIER>_MODEL` env var so tier alias resolves to backend model name at runtime

### Added
- `model_tiers` mapping in backend config (`claudeoai.yml`) to associate backend models with Claude CLI tier aliases
- `resolve_model_tier` method for tier lookup with `sonnet` fallback

## [0.19.0] - 2026-02-22

### Added
- Git worktree sandbox support for `CodexClient` and `CodexOaiClient` — automatically appends `--add-dir` with the common `.git/` directory when running inside a git worktree, allowing Codex sandbox to write git metadata (index.lock etc.)
- New `WorktreeDirResolver` atom that detects git worktree environments and resolves the common git directory path

## [0.18.0] - 2026-02-22

### Added
- New `ClaudeOaiClient` provider for Claude over Anthropic-compatible APIs (Z.ai, OpenRouter)
- Provider config `claudeoai.yml` with Z.ai backend targeting Anthropic-compatible endpoint (`/api/anthropic`)
- Backend env injection: sets `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, and clears `ANTHROPIC_API_KEY` on subprocess
- Skill command rewriting support via `CommandRewriter` and `SkillNameReader`
- Tests for backend env injection, command building, model splitting, availability validation, and JSON response parsing

## [0.17.1] - 2026-02-22

### Changed
- Update codexoai provider: add `name` field to backend config, remove `wire_api` setting, rename env key to `ZAI_API_KEY`
- `CodexOaiClient` now passes provider `name` to codex via `-c` config override, falls back to backend key when name not configured
- Remove `wire_api` config override from `CodexOaiClient` (no longer needed)

### Technical
- Updated tests for new provider name assertion, env key rename, and name fallback behavior

## [0.17.0] - 2026-02-22

### Added
- New `CodexOaiClient` multi-backend provider that wraps `codex` CLI to target any OpenAI-compatible endpoint via `-c` flag overrides
- Provider config `codexoai.yml` with Z.ai backend (glm-5, glm-4.7, glm-4.6) and model aliases
- Tests for command building, backend model splitting, availability validation, and generate flow

### Removed
- `CodexOSSClient` and `codexoss.yml` provider (called non-existent `codex-oss` binary)

## [0.16.10] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.16.9] - 2026-02-21

### Fixed
- `ClaudeCodeClient` now merges `subprocess_env` into the subprocess environment, ensuring env vars like `ACE_TMUX_SESSION` are set on the actual `claude -p` process instead of only appearing as text in the prompt

### Added
- Unit tests for `ClaudeCodeClient` covering env merging, nil handling, and subprocess_env forwarding from `generate()`

## [0.16.8] - 2026-02-21

### Added
- Process-group lifecycle hardening in `SafeCapture`: isolate subprocesses in dedicated process groups and clean up descendants on timeout and successful parent exit
- Regression tests for success-path and timeout-path descendant cleanup in `SafeCapture`
- Debug lifecycle tracing for CLI subprocess management via `ACE_LLM_DEBUG_SUBPROCESS=1`

### Changed
- `ClaudeCodeClient` now emits debug subprocess context (timeout, command, prompt size) when `ACE_LLM_DEBUG_SUBPROCESS=1`

## [0.16.7] - 2026-02-21

### Changed
- Update skill name handling and documentation for colon-free convention (`ace_domain_action` format)
- Update command rewriter tests for new skill naming convention

## [0.16.6] - 2026-02-17

### Fixed
- Added `SafeCapture` molecule test coverage to verify `env:` parameter propagation into subprocess execution (`test_env_option_passed_to_subprocess`)

## [0.16.5] - 2026-02-15

### Changed
- **ClaudeCodeClient**: Optimize subprocess environment — pass minimal env override `{"CLAUDECODE" => nil}` instead of copying entire `ENV.to_h`

## [0.16.4] - 2026-02-15

### Fixed
- **ClaudeCodeClient**: Pass prompt via stdin instead of CLI argument to avoid Linux `MAX_ARG_STRLEN` (128KB) limit on large prompts
- **ClaudeCodeClient**: Remove `--system-prompt` and `--append-system-prompt` CLI args (system content already embedded in formatted prompt)

### Changed
- **CodexClient**: `--sandbox` mode is now caller-controlled via `options[:sandbox]` instead of hardcoded `read-only`

## [0.16.3] - 2026-02-15

### Fixed
- **ClaudeCodeClient**: Clear `CLAUDECODE` env var before spawning subprocess to allow `claude -p` (one-shot mode) to run from within a Claude Code session — works around nested session guard added in Claude Code v2.1.41
- **CodexClient**: Add `--sandbox read-only` to prevent agent from executing commands instead of reviewing the prompt content
- **SafeCapture**: Added optional `env:` parameter for subprocess environment control

## [0.16.2] - 2026-02-07

### Fixed
- **PiClient**: Thread-safety fix — removed `@pending_system_prompt` shared mutable state; `build_full_prompt` now returns `[prompt, system_prompt]` tuple passed explicitly to `build_pi_command`
- **SkillCommandRewriter**: Replaced misleading "Deprecated" docstring with accurate "Convenience wrapper" description

### Changed
- **SafeCapture**: Moved from `atoms/` to `molecules/` to comply with ATOM architecture (performs I/O via Open3, Process.kill, Thread spawning)
- Updated all 6 CLI clients to reference `Molecules::SafeCapture` instead of `Atoms::SafeCapture`

### Technical
- 215 tests, 511 assertions, 0 failures (10 skipped)

## [0.16.1] - 2026-02-07

### Fixed
- **PiClient**: Handle nested provider pattern with colon (e.g., `openrouter:openai/gpt-oss-120b`)
  - Updated `split_provider_model` to correctly parse provider:model format
  - Now splits on `:` before `/` when colon is present in model string
  - Added regression tests for standard provider/model format

### Technical
- 2 new tests for nested provider model parsing

## [0.16.0] - 2026-02-07

### Added
- **CodexClient**: Skill command rewriting support transforms `/name` → `$name` for Codex CLI skill discovery
- **CodexClient**: `skill_rewriting` capability and `skills_dir` configuration option in provider defaults

### Changed
- Refactored skill command rewriting into provider-agnostic `CommandRewriter` base class with configurable formatter proc
- `SkillCommandRewriter` now a thin wrapper using `CommandRewriter` with `PI_FORMATTER` for backward compatibility
- `PiClient` updated to use `CommandRewriter` with `CommandFormatters::PI_FORMATTER`

### Technical
- New `CommandRewriter` atom in `atoms/command_rewriter.rb` for provider-agnostic command rewriting
- New `CommandFormatters` module in `atoms/command_formatters.rb` with `PI_FORMATTER` and `CODEX_FORMATTER`
- 20 tests for `CommandRewriter` covering both Pi and Codex formatters
- 25 tests for `CodexClient` covering skill rewriting and configuration

## [0.15.0] - 2026-02-07

### Added
- **PiClient**: New CLI provider for Pi (v0.52.7), a multi-provider terminal AI agent
  - Supports ZAI, Anthropic, Google Gemini, and OpenAI Codex models via Pi's unified platform
  - Skill command rewriting: transforms `/name` → `/skill:name` for Pi's skill discovery
  - NDJSON response parsing with plain text fallback
  - System prompt support via native `--system-prompt` flag
  - 17 tests for `SkillCommandRewriter` atom covering code blocks, URLs, edge cases
  - 37 tests for `PiClient` covering command building, prompt preprocessing, NDJSON parsing

### Technical
- New `SkillCommandRewriter` atom in `atoms/skill_command_rewriter.rb` for pure function skill command rewriting
- New `SkillNameReader` molecule in `molecules/skill_name_reader.rb` for reading skill names from SKILL.md frontmatter

## [0.14.2] - 2026-02-06

### Fixed
- Replace unsafe `Timeout.timeout { Open3.capture3 }` with thread-safe `SafeCapture` atom using `Open3.popen3` + `Process.kill` for process-level timeout — eliminates "stream closed in another thread (IOError)" errors during parallel CLI execution

### Technical
- New `SafeCapture` atom in `atoms/safe_capture.rb` with 7 tests covering stdout/stderr capture, timeout kill, stdin_data, chdir, and error messages
- Updated all 5 CLI clients (Claude, Codex, Codex OSS, Gemini, OpenCode) to use `SafeCapture`
- Updated Gemini client test stub from `Open3.capture3` to `SafeCapture.call`

## [0.14.1] - 2026-02-06

### Fixed
- Honor `--` sentinel in ArgsNormalizer: args after `--` now pass through verbatim without auto-prefixing
- User CLI args now take precedence over command-generated flags (moved to end of command construction in all 4 clients)

## [0.14.0] - 2026-02-05

### Added
- CLI argument passthrough support with normalization for CLI providers

### Fixed
- Improved CLI argument error reporting and provider command wiring

## [0.13.2] - 2026-01-22

### Fixed
- **OpenCodeClient**: Prevent client hang on 400 error and improve output
  - Added `stdin_data: ""` to `Open3.capture3` to prevent hanging on interactive prompts
  - Added `--format json` flag for structured output
  - Improved 400 Bad Request error detection with clearer error messages
  - Updated test expectations for `--format json` flag

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
