# Changelog

All notable changes to ace-review will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.24.2] - 2025-12-16

### Fixed

* **PR Subject Parsing**: Refined context diff detection and PR subject parsing for more reliable PR reviews
  * Improved handling of PR references in subject configurations
  * Better validation of PR references before fetching

### Changed

* **ContentChecker Extraction**: Refactored diff merging logic into dedicated ContentChecker component
  * Cleaner architecture for content validation
  * Improved maintainability of review subject processing

### Technical

* Added test coverage for PR and section processing features

## [0.24.1] - 2025-12-16

### Fixed
- **pr: Array Consistency**: Changed `pr:` typed subject to return array format (`{"pr" => ["77"]}`) for consistency with `diffs:` and `files:` which are always arrays

## [0.24.0] - 2025-12-16

### Added
- **Subprocess Timeout Protection**: Added 10-second timeout to `ace-taskflow` subprocess in `task:` subject resolution
  - Prevents indefinite hangs when task lookup is stuck
  - New `CommandTimeoutError` provides clear error message with command and timeout details
  - Uses Ruby's `Timeout` module wrapping `Open3.capture3`
- **Dual Extraction Paths Documentation**: Added class-level documentation to `SubjectExtractor` explaining the two code paths
  - Direct extraction via `extract()` for immediate content
  - Config passthrough via `parse_typed_subject_config()` for optimized ReviewManager flow

### Fixed
- **Comment Accuracy**: Updated misleading comment in `SubjectExtractor#use_ace_context`
  - Comment now correctly reflects that ace-context supports both flat keys and nested `context:` structure

## [0.23.2] - 2025-12-14

### Fixed
- **Upstream bug fixes**: ace-llm dependency fixes benefit ace-review users
  - Zero-value generation parameters (`temperature: 0`) now preserved in MistralClient, AnthropicClient, GoogleClient
  - All LLM clients standardized with GENERATION_KEYS pattern for consistency

## [0.23.1] - 2025-12-14

### Changed
- **Workflow Simplification**: Simplified `review.wf.md` to match `review-pr.wf.md` pattern with full cycle workflow (review → plan → confirm → implement)

## [0.23.0] - 2025-12-08

### Added
- **PR Comment Developer Feedback**: Extract developer feedback from PR comments and inline review threads
  - New `--[no-]pr-comments` flag to control inclusion (default: true for `--pr` reviews)
  - Creates `review-dev-feedback.md` report alongside LLM reviews
  - Includes issue comments, review comments, and approval/change-request state
  - Integrated into synthesis reports when multi-model review is used
- **GhCommentResolver**: New molecule to reply to PRs and resolve review threads
  - `reply` - Post comment with commit reference
  - `resolve_thread` - Resolve review threads via GitHub GraphQL API
  - `reply_and_resolve` - Combined operation for workflow automation
- **Empty-Body Review Support**: Approvals and change-requests without body text now included with placeholder

### Fixed
- **Thread ID Validation**: Added format validation (`PRRT_xxx` pattern) to prevent GraphQL injection
- **Markdown Table Safety**: Escape pipe characters in table preview to prevent broken rendering

### Changed
- **Pagination Warnings**: Warn when GraphQL results are truncated (>100 threads or >50 comments per thread)
- **Comment Fetch Failure Logging**: Log warning instead of silent failure when PR comment fetch fails
- **Table Readability**: Wrap IDs in backticks for improved readability in markdown tables

### Documentation
- **README Updated**: Document `--[no-]pr-comments` flag and developer feedback feature
- **CLI Reference**: Added `--[no-]pr-comments` to GitHub PR options section

## [0.22.0] - 2025-12-03

### Added
- **Auto-Save Feature**: Automatically save reviews to task directories based on git branch name
  - Enable with `auto_save: true` in config
  - Configurable branch patterns via `auto_save_branch_patterns`
  - Release directory fallback via `auto_save_release_fallback`
  - Disable per-command with `--no-auto-save` flag
- **Multi-Model Auto-Save**: Individual model reports now saved to task directory (not just synthesis)
- **Auto-Save Integration Tests**: Comprehensive test coverage for branch detection and task resolution

### Fixed
- **Multi-Model Auto-Save**: All model reports now saved to task directory, matching explicit `--task` behavior

### Technical
- Remove unused `project_root` variable in TaskReportSaver
- Stabilize GitBranchReader tests with Open3 mocking and real detached HEAD test

## [0.21.0] - 2025-12-03

### Added
- **Multi-Model Report Synthesis**: Automatically synthesize reviews from multiple LLM models
  - New `ace-review synthesize --session <dir>` standalone command
  - Auto-triggered after multi-model execution when 2+ models succeed
  - Identifies consensus findings, strong recommendations, unique insights, and conflicting views
  - Produces prioritized action items combining all model feedback
  - Configurable synthesis model via `--synthesis-model` or `synthesis.model` config
  - Disable with `--no-synthesize` flag or `synthesis.enabled: false` config
- **ReportSynthesizer Molecule**: LLM-powered report consolidation with structured prompt
- **Synthesis Prompt Template**: `handbook/prompts/synthesis-review-reports.system.md`
- **E2E Integration Test**: Full test coverage for multi-model auto-synthesis flow

### Changed
- **Default Synthesis Model**: `claude:sonnet` (was `google:gemini-2.5-flash`)

### Documentation
- **Configuration Defaults**: Clarify gem defaults in README
  - Default preset is `code` (basic single-model review)
  - Default `auto_execute` is `false` (prompts for confirmation)
  - Projects can override in their `.ace/review/config.yml`

## [0.20.6] - 2025-12-02

### Fixed
- **SlugGenerator**: Remove trailing hyphen after max_length truncation

### Documentation
- **Multi-Model Reviews**: Add section documenting CLI usage, preset config, and output structure
- **Preset Resolution Chain**: Document preset lookup order (project → gem defaults)

## [0.20.5] - 2025-12-02

### Technical
- Update documentation to use `code-pr` preset instead of deprecated `pr` preset

## [0.20.4] - 2025-12-02

### Added
- **LLM Timeout**: Configurable timeout (default: 300s) to prevent indefinite hangs
  - Set via `defaults.llm_timeout` in config
- **Model Name Validation**: CLI validates model names contain only safe characters

### Fixed
- **Example Config**: Default preset changed from 'pr' to 'code' (existing preset)

## [0.20.3] - 2025-12-02

### Fixed
- **Config Loading**: Use correct `Ace::Core.get` API to load `.ace/review/config.yml`
  - Was using `Ace::Core.config.get("ace", "review")` which returned nil
  - Now `defaults.preset` and other settings are properly read from config

## [0.20.2] - 2025-12-02

### Changed
- **Config-based Preset Default**: `defaults.preset` in config now used instead of hardcoded "pr" fallback
  - CLI `--preset NAME` overrides config default
  - Helpful error message when no preset specified and no config default set

## [0.20.1] - 2025-12-02

### Added
- **Config-based Settings**: Move runtime options from ENV to config file
  - `max_concurrent_models` - configurable in `defaults` section
  - `auto_execute` - skip confirmation prompt when set to `true`
- **Improved CLI Output**: Task directory output now shows directory once, then lists filenames

### Changed
- **Preset Consolidation**: Replace duplicated `pr.yml` with DRY `code-pr.yml` extending `code`
- **Concurrency Guard**: Clamp `max_concurrent_models` to minimum 1 to prevent crashes
- **Input Validation**: Filter blank entries from comma-separated model lists

## [0.20.0] - 2025-12-02

### Added
- **Multi-Model Concurrent Execution**: Run code reviews against multiple LLM models simultaneously
  - New `--model` flag accepts comma-separated models or multiple flags (e.g., `--model claude:opus,gpro`)
  - Configurable concurrency via `ACE_REVIEW_MAX_CONCURRENT_MODELS` environment variable (default: 3)
  - Thread-safe parallel execution with progress indicators
  - Individual model failures don't stop other executions
  - Preset support via `models:` array in YAML configuration

### Fixed
- **Output File Handling**: Pass `output_file` parameter to LlmExecutor for correct file creation
- **Effective Model Logic**: `effective_model` now respects `models` array for metadata and filenames
- **Task Report Filenames**: Use full model slug in filenames to prevent overwrites when using same-provider models
- **Task Path Propagation**: Fix result key from `:task_path` to `:path` so saved locations surface in CLI output

## [0.19.2] - 2025-12-01

### Fixed
- **Task Integration Fixes**: Multiple fixes to ensure `--task` flag works correctly
  - Add missing `require` for `ace/taskflow/organisms/task_manager` in TaskResolver
  - Pass actual review file path to TaskReportSaver instead of session directory
  - Add defensive guard for nil/empty `task[:path]` to prevent crashes

### Changed
- **Test Consistency**: Refactored TaskResolver tests to use `Minitest::Mock` consistently

## [0.19.1] - 2025-11-29

### Fixed
- Fix PR diff generation to use actual PR content instead of origin...HEAD when using `--pr` flag with presets
- Remove problematic default subject from `code-pr.yml` preset that contained `origin...HEAD`
- Add comprehensive integration tests for PR diff generation behavior

## [0.19.0] - 2025-11-27

### Added
- **Specification Review Focus**: New `scope/spec` focus for reviewing specifications and proposals
  - Goal clarity validation (single objective, no ambiguous terms, clear success criteria)
  - Usage expectations analysis (target audience, scenarios, inputs/outputs)
  - Test strategy evaluation (testable criteria, edge cases, validation approach)
  - Completeness checking (required sections, dependencies, assumptions)
  - Implementation feasibility assessment (achievable requirements, realistic estimates)
  - Consistency and traceability verification
- **Spec Preset**: New `spec.yml` preset for specification reviews
  - Default subject: `origin/main...HEAD` filtered to `**/*.s.md` (task specs)
  - Combines spec focus with standard format and tone guidelines

## [0.18.0] - 2025-11-17

### Added
- **GitHub Pull Request Review Mode**: Support for reviewing GitHub pull requests directly
  - New `--pr` option to specify pull request identifier (number, URL, or owner/repo#number)
  - `--post-comment` option to automatically post review as GitHub comment (requires `gh` CLI)
  - `--dry-run` option to preview comment without posting
  - Multiple PR identifier formats supported: `123`, `https://github.com/owner/repo/pull/123`, `owner/repo#123`
  - Automatic repository detection from git remote when using PR number only
  - Comprehensive error handling for authentication, network issues, and PR state
  - Retry logic with exponential backoff (capped at 32 seconds) for network resilience
  - PR state validation (prevents posting to closed/merged PRs)
  - Rich PR metadata included in review context (title, author, branch names, state)
  - Secure comment posting via tempfiles (prevents command injection)
  - Review cache saved to `.cache/ace-review/sessions/review-{timestamp}/`
- **New Molecules**:
  - `GhCliExecutor`: Safe execution of GitHub CLI commands with timeout and error handling
  - `PrIdentifierParser`: Parse and normalize PR identifiers to owner/repo/number format
  - `GhPrFetcher`: Fetch PR diffs and metadata with retry logic
  - `GhCommentPoster`: Post review comments to GitHub with dry-run support
- **New Atoms**:
  - `RetryWithBackoff`: Reusable retry logic with exponential backoff for operations with transient failures
- **New Error Classes**: Specific errors for GitHub integration (`GhCliNotInstalledError`, `GhAuthenticationError`, `PrNotFoundError`, `PrStateError`, `GhNetworkError`)
- **CLI Options**:
  - `--gh-timeout <seconds>`: Configure timeout for GitHub CLI operations (default: 30 seconds)
- **Markdown Sanitization**: LLM review output is now sanitized and wrapped in collapsible `<details>` tags
  - Automatically closes unclosed code fences to prevent broken GitHub comment rendering
  - Wraps review content in expandable section for better PR comment readability
- **README Documentation**: Comprehensive guide for GitHub PR review mode with examples, timeout configuration, and troubleshooting

### Changed
- **Default Timeout**: Reduced default timeout for GitHub CLI operations from 600 seconds (10 minutes) to 30 seconds
  - Provides faster failure feedback for network issues
  - Users can override with `--gh-timeout` option for large PRs or slow connections
- **Retry Logic Architecture**: Extracted retry logic from `GhPrFetcher` into reusable `RetryWithBackoff` atom
  - Improves testability and code reusability
  - Cleaner separation of concerns following ATOM architecture

### Fixed
- **Architectural Compliance**: Moved `GhCliExecutor` from `atoms/` to `molecules/` to properly reflect its side effects (shell command execution)
- **Test Coverage**: Uncommented and fixed previously failing tests in `gh_pr_fetcher_test.rb`
  - Fixed complex mocking chain issues by extracting retry logic into testable atom
  - All failure path and retry exhaustion tests now pass

## [0.17.0] - 2025-11-17

### Added
- **Task Integration**: New `--task` flag to save review reports to task directories
  - Accepts task references in multiple formats: `114`, `task.114`, `v.0.9.0+114`
  - Reports saved to `<task-dir>/reviews/` with timestamped filenames
  - Filename format: `YYYYMMDD-HHMMSS-{provider}-{preset}-review.md`
  - Graceful degradation when ace-taskflow unavailable or task not found
  - Created `TaskResolver` molecule for task reference resolution
  - Created `TaskReportSaver` molecule for report persistence
  - Updated `ReviewManager` organism to orchestrate task-aware saving
  - Added ace-taskflow ~> 0.19 as runtime dependency

## [0.16.1] - 2025-11-15

### Fixed
- **Git Worktree Cache Path Resolution**: Fixed cache directory creation to use project root instead of current working directory
  - Resolves issue where caches were created in deeply nested, incorrect paths in git worktrees (e.g., `/path/.ace-wt/task.094/ace-context/.cache/ace-review/sessions/`)
  - Modified `ReviewManager#create_cache_directory` to use `Ace::Core::Molecules::ProjectRootFinder.find_or_current`
  - Added `require "ace/core/molecules/project_root_finder"` to review_manager.rb
  - Each worktree now maintains its own cache at `.cache/ace-review/sessions/` relative to worktree root
  - Updated tests to expect cache at project root location
  - All 161 ace-review tests pass with no breaking changes to main repo usage
  - Transparent fix - tool "just works" in worktrees without user configuration

### Changed
- **Dependencies**: Updated to use ace-support-core ~> 0.10.1 for worktree support

## [0.16.0] - 2025-11-13

### Added
- **Preset Composition**: Support for composing review presets from reusable base configurations
  - New `presets:` array at root level for preset composition
  - Recursive preset loading with circular dependency detection (max depth: 10)
  - Smart merging strategies: arrays concatenate+deduplicate, hashes deep merge, scalars last-wins
  - **Composition order**: Base presets are loaded first, then the composing preset (last wins for scalars)
  - Full backward compatibility - existing presets without `presets:` key continue to work unchanged
  - New `PresetValidator` atom for validation and circular dependency detection
  - Preset name validation (prevents path traversal, enforces length limits)
  - Enhanced `PresetManager` molecule with `load_preset_with_composition` method
  - Comprehensive test coverage: 23 validator tests, 22 manager composition tests, 11 integration tests
- **Example Preset Refactoring**: New DRY preset structure
  - `code.yml` base preset with common review instructions
  - `code-pr.yml` composed preset for pull request reviews
  - `code-wip.yml` composed preset for work-in-progress reviews

### Changed
- **PresetManager**: Enhanced to support preset composition while maintaining backward compatibility
  - Recursive loading with visited set tracking
  - Deep merge support for nested hash structures
  - Array deduplication during composition
  - Intermediate caching prevents redundant composition (particularly beneficial for deeply nested presets)
  - Standardized internal metadata format (string keys for consistency)
  - Deep metadata stripping from nested structures
  - Added `strip_composition_metadata` helper method for DRY code
  - Performance instrumentation with debug mode support

### Technical
- Integrated test suite performance optimizations from v0.15.1
- Updated test patterns to match new test helper structure
- All 56 tests passing (23 validator + 22 manager + 11 integration)

## [0.15.1] - 2025-11-11

### Technical
- Optimize test suite performance with mocking (2.2x faster, 2.03s → 0.93s)
  - Add `Ace::Context.load_auto()` mocking in test_helper
  - Add `GitExtractor` mocking (staged_diff, working_diff, tracking_branch)
  - Remove real git operations from integration tests
  - Fix test issues (super calls, initialization timing, assertions)
  - All 108 tests passing (16 atoms + 53 molecules + 29 organisms + 10 integration)

## [0.15.0] - 2025-11-10

### Added
- **Section-Based Content Organization**: Support for `instructions.context.sections` format
  - Integration with ace-context v0.17.5+ section-based content organization
  - Structured organization of review content into semantic sections (focus, style, diff, etc.)
  - All built-in presets (pr, code, security, docs, performance, ruby-atom, agents, test) now use sections
  - PresetManager enhanced to preserve `instructions` field through resolution chain
  - New format detection helper for automatic backward compatibility

### Changed
- **ReviewManager**: Enhanced to support both legacy `system_prompt` and new `instructions` formats
  - Automatic format detection ensures seamless migration
  - New `create_system_context_file_with_instructions()` method for section-based contexts
  - Full backward compatibility maintained for existing user presets
- **CLI Output**: Updated to properly display system and user prompt file paths
  - Shows both `system.prompt.md` and `user.prompt.md` file paths
  - Provides correct `ace-llm query` command with `--file` and `--context` parameters
  - Maintains backward compatibility with legacy `prompt_file` format

### Documentation
- **README.md**: Added comprehensive documentation for new section-based format
  - Examples of `instructions` format with section organization
  - Legacy format documentation for backward compatibility
  - Migration guidance and best practices

### Testing
- **Comprehensive Test Coverage**: Added 6 new test methods for section-based functionality
  - Format detection validation
  - Section-based context file creation
  - Integration testing for both formats
  - Backward compatibility verification
  - All tests passing with 100% success rate

## [0.14.0] - 2025-11-05

### 🚀 **Major Performance Upgrade - Ruby API Migration & Context Fix**

### Changed
- **Architecture**: Complete migration from CLI subprocess to Ruby API calls
  - Replaced `ace-llm-query` subprocess calls with direct `Ace::LLM::QueryInterface.query()` calls
  - Eliminated all temp file creation and subprocess overhead
  - Achieved 98-99% reduction in LLM call latency (70-135ms → 1-2ms)

### Added
- **Ruby API Integration**: Direct ace-llm Ruby library usage
  - No more temp file management for prompts
  - Rich response metadata (usage stats, model info, provider details)
  - Structured exception-based error handling
  - Enhanced session files with `llm_metadata.yml`

- **Performance Benefits**:
  - Eliminated process spawning overhead
  - Removed shell interpretation delays
  - Native Ruby object handling (no JSON parsing)
  - Direct method calls with immediate response

- **Enhanced Error Handling**:
  - Specific exception types (`Ace::LLM::Error`, `Ace::LLM::ProviderError`, etc.)
  - Structured error responses with error categorization
  - Better debugging information with error types
  - Graceful handling of API vs CLI availability

- **Rich Metadata**:
  - Token usage information (`usage` field)
  - Model information and provider details
  - Response timing and metadata
  - Session persistence of LLM interaction data

### Technical
- **Dependency**: Added `ace-llm (~> 0.1)` runtime dependency
- **API Compatibility**: Maintains identical external interface
- **Backward Compatibility**: All existing CLI options and workflows unchanged
- **Error Recovery**: Enhanced error messages and recovery paths

### Fixed
- **Context Generation Bug**: Fixed empty user.context.md files that had no subject configuration
  - Updated `create_user_context_file` method to properly handle subject configuration fallbacks
  - Eliminated redundant subject.md file creation (subject now handled via ace-context workflow)
  - Enhanced configuration flow: explicit config → preset config → default "staged" configuration
  - Improved handling of file paths, preset shortcuts, and structured configurations

### Performance
- **98-99% faster** LLM calls
- **Zero temp file overhead**
- **Direct Ruby object responses**
- **Immediate availability** of results and metadata

### Technical
- **Streamlined Session Structure**: Removed subject.md and context.md files, now using ace-context workflow
- **Enhanced Configuration Handling**: Better fallback logic for subject configuration processing
- **Updated Tests**: Modified test expectations to match new v0.14.0 session structure

## [0.13.1] - 2025-11-05

### Fixed
- **Implementation Gap**: Actually completed the v0.13.0 architectural changes that were documented but not fully implemented
- **Removed Legacy Code**: Eliminated all prompt splitting logic and fallback methods as claimed in v0.13.0 CHANGELOG
- **Updated Tests**: Fixed test expectations to match new architecture and removed tests for removed methods
- **File Structure**: Corrected session file naming to use `system.prompt.md` and `user.prompt.md`
- **CLI Integration**: Fixed `undefined method 'subject_config'` error in ReviewManager parameter naming
- **ace-llm-query Interface**: Updated to use correct `--system` and `--prompt` flags instead of non-existent `--user` flag

### Technical
- **Code Cleanup**: Removed 214 lines of legacy code while maintaining functionality
- **Syntax Validation**: All Ruby files now pass syntax validation
- **Architecture Alignment**: Implementation now matches documented CHANGELOG claims

## [0.13.0] - 2025-11-05

### 🎯 **Major Architecture Fix - System/User Prompt Separation**

### Changed
- **Architecture**: Complete overhaul of prompt generation and processing
  - Removed arbitrary prompt splitting (`split_and_save_prompts` method)
  - Removed combined prompt generation (`build_review_prompt` method)
  - Implemented proper ace-context integration throughout
  - Fixed fundamental misunderstanding of system vs user prompts

### Added
- **System Prompt Generation**:
  - Creates `system.context.md` with YAML frontmatter containing prompt:// references
  - Integrates context configuration (e.g., "project" → presets: ["project"])
  - Uses ace-context to generate `system.prompt.md`
  - Proper base system instructions included after frontmatter

- **User Prompt Generation**:
  - Creates `user.context.md` with subject configuration
  - Supports commands, files, diffs, and inline content from presets
  - Uses ace-context to generate `user.prompt.md`
  - Handles all subject types from preset configurations

- **LLM Integration**:
  - LlmExecutor requires separate system and user prompts
  - New format: `--system-prompt` and `--user-prompt` flags via ace-llm-query
  - Removed legacy single prompt support for cleaner architecture

- **Session Structure**:
  ```
  session/
  ├── system.context.md   # ace-context input (system prompt config)
  ├── system.prompt.md    # ace-context output (generated system prompt)
  ├── user.context.md     # ace-context input (user prompt config)
  ├── user.prompt.md      # ace-context output (generated user prompt)
  ├── subject.md          # Extracted subject content
  ├── context.md          # Legacy context content
  ├── metadata.yml        # Session metadata
  └── review.md           # LLM output
  ```

### Fixed
- **Configuration Structure**: Renamed `prompt_composition` → `system_prompt` in all preset configs
- **Preset Parsing**: Updated all preset parsing logic to use new structure
- **Backward Compatibility**: All existing preset configurations continue to work unchanged
- **Ruby Syntax**: All syntax errors resolved and code validated

### Technical
- **YAML Frontmatter**: Follows ace-context patterns exactly with proper context structure
- **Error Handling**: Comprehensive fallback mechanisms for ace-context failures
- **Cache Management**: Enhanced cache-first storage model with proper file organization
- **Token Optimization**: Potential to reduce token usage through ace-context processing

### Breaking Changes
- **LlmExecutor API**: Removed legacy single prompt support, now requires system_prompt and user_prompt parameters
- **ReviewManager**: Removed fallback prompt generation methods, ace-context is now required
- **Session Structure**: Updated file naming from legacy `prompt.md` to `system.prompt.md` and `user.prompt.md`

## [0.12.0] - 2025-11-05

### Added
- **Context.md Pattern**: Adopt ace-docs context.md pattern for improved reproducibility
  - ContextComposer molecule generates context.md with YAML frontmatter
  - ContextExtractor delegates to ContextComposer for ace-context integration
  - Cache-first storage with `.cache/ace-review/sessions/` directory
  - Context.md files saved with embedded files and ace-context configuration

### Changed
- **Storage Model**: Implement cache-first storage approach
  - Working files stored in cache directory instead of release folder
  - Final reports copied to release folder `.ace-taskflow/v.*/reviews/`
  - Removed `.tmp` extensions from all session files
  - Split prompts into `prompt-system.md` and `prompt-user.md` files

### Enhanced
- **Ace-Context Integration**: Full integration with ace-context via `load_file_as_preset()`
  - Follows ace-docs pattern exactly for consistency
  - Support for presets, files, diffs, and commands in YAML frontmatter
  - Fail-fast error handling with clear error messages
  - Backward compatible CLI interface

### Technical
- **ContextComposer**: New molecule for context.md generation
- **ReviewManager**: Updated with cache-first storage and prompt splitting
- **ContextExtractor**: Refactored to delegate to ContextComposer
- **Comprehensive Tests**: Added test coverage for all new functionality
- **Backward Compatibility**: All existing presets work without modification

## [0.11.2] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Changed dependency from `ace-test-support`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.11.1]
 - 2025-10-24

### Fixed
- Address PR #3 review issues for ace-git-diff integration

### Technical
- Standardize diff/diffs API documentation to ace-git-diff format
- Add comprehensive integration and unit tests
- Update all presets and workflow instructions with standardized diff format

## [0.11.0] - 2025-10-23

### Changed
- Integrated with ace-git-diff for unified diff operations
- SubjectExtractor now handles new diff: format with ranges
- All example presets updated to use diff: key instead of commands:
- Added ace-git-diff (~> 0.1.0) as runtime dependency
- Delegates to ace-context which now uses ace-git-diff

### Technical
- Maintains backward compatibility with old diff: string format
- Supports both diff: { ranges: [...] } and legacy diff: "range" formats

## [0.10.0] - 2025-10-14

### Added
- Standardize Rakefile test commands and add CI fallback

### Technical
- Add proper frontmatter with git dates to all managed documents

## [0.9.9] - 2025-10-08

### Changed

- **Test Structure Migration**: Migrated to flat ATOM structure
  - From: `test/ace/review/molecules/`
  - To: `test/molecules/`
  - Aligns with standardized test organization across all ACE packages

## [0.9.8] - 2025-10-07

### Changed

- **Workflow documentation updated** for ace-context v0.9.6+ integration
  - Updated `review.wf.md` to reflect unified YAML schema
  - Removed references to deprecated `patterns:` key
  - Added comprehensive configuration schema section documenting `files:`, `diffs:`, `commands:`, `presets:`
  - Enhanced common scenarios with file-based review examples
  - Added "Review Specific Files" and "Compose Multiple Sources" scenarios
  - Improved troubleshooting section with "No code to review" → use `files:` guidance
  - Updated preset file examples to show proper YAML structure
  - Added simple string shortcuts documentation (staged, working, pr)
  - Updated all command examples to use correct YAML keys

## [0.9.7] - 2025-10-07

### Fixed

- **ace-llm-query integration**: Fixed command construction to work with updated ace-llm-query API
  - Replaced non-existent `--file` flag with new `--prompt` flag (added in ace-llm v0.9.1)
  - Added proper PROVIDER:MODEL positional argument as first parameter
  - Added `--output` flag to save review reports directly to session directory
  - Added `--timeout 600` for 10-minute timeout on long reviews
  - Added `--format markdown` for consistent markdown output
  - Output filename now uses model short name: `review-report-{model-short}.md`
  - Example: `review-report-gemini-2.5-flash.md` for model `google:gemini-2.5-flash`

### Changed

- **LlmExecutor API**: Updated `execute` method to require `session_dir:` parameter
  - Enables direct file output to session directory
  - Returns `output_file` path in result hash
- **ReviewManager**: Updated to pass `session_dir` to LlmExecutor
  - Simplified result handling (no longer needs to save output separately)

## [0.9.6] - 2025-10-06

### Changed

- **ace-context integration**: Refactored to use ace-context for unified content aggregation
  - `SubjectExtractor` now delegates to `Ace::Context.load_auto` for all content extraction
  - `ContextExtractor` now delegates to `Ace::Context.load_auto` for all content extraction
  - Preserved special behaviors (staged/working/pr keywords, project context defaults)
  - Eliminated duplicated file reading, command execution, and git extraction logic

### Added

- **ace-context dependency**: Added `ace-context ~> 0.9` as runtime dependency
- **Enhanced composition**: Can now combine files + commands + diffs + presets in unified configs
- **Preset support in context**: `presets:` key now functional in context configuration
- **Diffs support**: New `diffs:` key supported in subject and context configs

### Removed

- **Redundant atoms**: Deleted `git_extractor.rb` and `file_reader.rb` (now in ace-context)
- **Duplicated logic**: All content extraction now centralized in ace-context

## [0.9.5] - 2025-10-06

### Changed

- **Workflow command renamed**: `review-code.wf.md` → `review.wf.md`
  - Claude command changed from `/ace:review-code` to `/ace:review` for simplicity
  - Updated workflow invocation from `wfi://review-code` to `wfi://review`

### Fixed

- **Storage path detection**: Removed hardcoded storage defaults that prevented smart detection
  - `storage_config` now only checks user config, not module defaults
  - Properly implements 3-tier priority: user config → ace-taskflow → cache directory
  - Fallback path changed from `./reviews` to `.cache/ace-review/sessions/`
- **LLM command execution**: Fixed remaining `ace-llm` command reference in `llm_executor.rb`
  - Changed from `ace-llm query` to direct `ace-llm-query` invocation
  - Renamed method from `execute_ace_llm` to `execute_ace_llm_query` for clarity
- **Configuration comments**: Updated config file comments to reflect correct detection order

## [0.9.4] - 2025-10-05

### Changed

- **Dynamic storage path**: Storage now defaults to `$(ace-taskflow release --path reviews)`
  - Falls back to `./reviews` if ace-taskflow not available
  - Config `storage.base_path` commented out by default, uses smart detection
  - User can still override by uncommenting and setting custom path
- **Review file organization**: All review files now stored together with `.tmp` pattern
  - Session files in `{release_path}/reviews/review-{timestamp}/`
  - Temporary files use `.tmp` extension: `prompt.md.tmp`, `subject.md.tmp`, `context.md.tmp`
  - Committable files: `metadata.yml`, `review.md`
  - Gitignore pattern changed from `.ace-review-sessions/` to `**/*.tmp`
- **Command detection**: Binary check updated from `ace-llm` to `ace-llm-query`
  - Error message now correctly references `ace-llm-query`

### Fixed

- Review sessions no longer create separate `.ace-review-sessions` directory
- All review artifacts now properly organized in release-specific folders
- Temporary working files automatically gitignored via `.tmp` extension

## [0.9.3] - 2025-10-05

### Changed

- **Configuration file renamed**: `code.yml` → `config.yml` for consistency with ace-* naming conventions
  - Updated all references in code, tests, and documentation
  - Both `.ace.example/review/config.yml` and `.ace/review/config.yml` now use new name
- **Preset organization improved**: All presets now stored as individual files
  - Extracted 7 presets from main config to separate `.yml` files in `review/presets/`
  - Main `config.yml` now contains only defaults and storage settings
  - Presets: pr, code, docs, security, performance, test, agents, ruby-atom
- **Configuration cascade integration**: Removed hardcoded paths in favor of ace-core
  - `PresetManager` now uses `Ace::Core::Molecules::ConfigFinder` for all file discovery
  - Automatic cascade resolution across `./.ace → ~/.ace` without hardcoded paths
  - Preset files discovered automatically across entire configuration cascade
  - Maintains backward compatibility with fallback for environments without ace-core

### Fixed

- Configuration system now properly respects ace-core's configuration cascade
- Preset loading works correctly from both local and user config directories

## [0.9.2] - 2025-10-05

### Fixed

- **Prompt resolution** now works correctly via ace-nav integration
  - Fixed custom `PromptResolver` that wasn't working properly
  - Replaced with `NavPromptResolver` using ace-nav's universal resolution
  - Registered ace-review prompts with ace-nav protocol for proper discovery
- **Critical command injection vulnerability** in `GitExtractor`
  - Fixed unsafe string interpolation in git commands
  - Now uses array arguments with `Open3.capture3(*command_parts)`
- **Code organization issues**
  - Fixed overly complex `ReviewManager#execute_review` method
  - Replaced hash options with proper `ReviewOptions` class
  - Improved separation of concerns throughout

### Changed

- Refactored `ReviewManager` into clearer, testable steps
- Dependencies now include `ace-nav ~> 0.9` for proper prompt resolution

## [0.9.1] - 2025-10-05

### Fixed

- Replaced Zeitwerk with explicit requires following ace-gems conventions
- Fixed all require_relative paths and namespace references
- Removed unnecessary dependencies (zeitwerk, tty-*, rainbow, dry-cli)
- Replaced dry-cli with OptionParser for consistency with other ace gems
- Simplified output formatting to use plain text without external libraries

### Changed

- Minimal dependencies - now only requires ace-core (~> 0.9)
- CLI implementation now follows standard ace-gems patterns

## [0.9.0] - 2025-10-05

### Changed

- **BREAKING**: Simplified CLI interface from `ace-review code` to just `ace-review`
- Tool is now more universal - presets determine what type of review (code, docs, security, etc.)
- Cleaner, more intuitive command structure
- Migration from v0.8 legacy code-review system

### Migration

Update all commands from:
```bash
ace-review code --preset pr
```

To:
```bash
ace-review --preset pr
```

## [0.1.0] - 2025-10-05

### Added

- Initial release of ace-review gem
- Migrated from dev-tools code-review implementation
- ATOM architecture with atoms, molecules, organisms, and models
- Preset-based review configuration system
- Prompt composition with base, format, focus, and guidelines modules
- Prompt cascade resolution (project → user → gem)
- prompt:// URI protocol for prompt references
- Support for direct file path references in prompts
- Multiple focus module composition
- Integration with ace-taskflow for release-based storage
- CLI command: `ace-review code` with various options
- Built-in presets: pr, code, docs, security, performance, test, agents
- Example configuration files in .ace.example/
- Comprehensive prompt library migrated from dev-handbook
- LLM execution via ace-llm integration
- Session management for dry-run mode
- List commands for presets and prompts

### Changed

- **BREAKING**: Replaced `code-review` command with `ace-review code`
- **BREAKING**: Removed `code-review-synthesize` CLI (use `wfi://synthesize-reviews` workflow)
- **BREAKING**: Configuration moved from `.coding-agent/code-review.yml` to `.ace/review/config.yml`
- **BREAKING**: Storage location now defaults to `.ace-taskflow/<release>/reviews/`
- Preset files now support separate directory at `.ace/review/presets/`
- Improved preset override system with `--add-focus` option
- Enhanced prompt resolution with multiple lookup strategies

### Migration Notes

To migrate from the old code-review system:

1. Install ace-review gem
2. Copy `.coding-agent/code-review.yml` to `.ace/review/config.yml`
3. Update workflow files to use `ace-review code` instead of `code-review`
4. Synthesis is now handled via workflow instructions only (no CLI command)
