# Changelog

All notable changes to ace-review will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.44.1] - 2026-03-12

### Changed
- Updated review workflow instructions to reference bundle-first review flows instead of slash-command examples.

## [0.44.0] - 2026-03-10

### Added
- Added canonical handbook-owned review skills and the new `wfi://review/package` workflow for package-level review.


## [0.43.8] - 2026-03-08

### Fixed
- Resolve review preset/config discovery from the caller's explicit `project_root` and gem-default preset files, preventing temp-dir context extraction from crashing after project-root hardening in `ace-support-fs`.

### Technical
- Add regression coverage for gem-default preset discovery and temp-dir file-path context extraction.

## [0.43.7] - 2026-03-06

### Fixed
- Make `--dry-run` disable automatic model execution even when project defaults enable `auto_execute`.
- Allow `@` in review model identifiers so preset models can use `@ro`, `@rw`, and `@yolo` suffixes.

### Changed
- Reduce the shipped review preset surface to five explicit single-file presets: `code-valid`, `code-fit`, `code-shine`, `docs`, and `spec`.
- Align both package defaults and repo-level `.ace/review` overrides on the explicit five-preset review model.

## [0.43.6] - 2026-03-05

### Changed
- Renamed config key `auto_save_branch_patterns` → `task_branch_patterns` to reflect broader usage (task spec resolution, not just auto-save)

## [0.43.5] - 2026-03-04

### Fixed
- Feedback session discovery now prefers `.ace-local/review/sessions` with legacy `.cache` fallback.


## [0.43.4] - 2026-03-04

### Fixed
- Review workflow instructions (apply-feedback, pr, run) corrected to use `.ace-local/review/` (not `.ace-local/ace-review/`)

## [0.43.3] - 2026-03-04

### Fixed
- `feedback-workflow.md` session path examples corrected to short-name convention (`.ace-local/review/` not `.ace-local/ace-review/`)

## [0.43.2] - 2026-03-04

### Fixed
- Reverted feedback synthesis workspace handling to standard `Dir.mktmpdir` behavior instead of project-local temporary workspaces.

## [0.43.1] - 2026-03-04

### Fixed
- README session storage path examples corrected to short-name convention (`.ace-local/review/` not `.ace-local/ace-review/`)

## [0.43.0] - 2026-03-04

### Changed
- Default session directory migrated from `.cache/ace-review/sessions` to `.ace-local/review/sessions`
- Feedback synthesis workspace now uses `Ace::Support::Items::Atoms::TmpWorkspace` for deterministic `.ace-local/tmp` paths

## [0.42.7] - 2026-03-02

### Changed
- Replace `ace-taskflow` dependency with `ace-task` — migrate `TaskResolver`, `SubjectExtractor`, and `PresetManager` to ace-task APIs
- Remove dead `save_to_release` method from `TaskReportSaver` (used `ReleaseManager` from ace-taskflow, never called in production)
- Update CLI subprocess call from `ace-taskflow task REF --path` to `ace-task show REF --path`

## [0.42.6] - 2026-02-25

### Technical
- Bump runtime dependency constraint from `ace-git ~> 0.10` to `ace-git ~> 0.11`.

## [0.42.5] - 2026-02-25

### Technical
- Add test case for `nil` return from `extract_task_reference` when PR metadata contains no task reference

## [0.42.4] - 2026-02-25

### Fixed
- Safely extract task reference from PR text using safe navigation to avoid NoMethodError when regex match returns nil

## [0.42.3] - 2026-02-25

### Added
- Automatically include the task behavioral spec (`.s.md`) in PR review context when a task can be discovered from PR branch metadata or PR text references.
- Add `PrTaskSpecResolver` to map PR metadata to a single primary task spec file with graceful fallback.

### Changed
- Extend task resolution metadata with `spec_path` for direct behavioral spec selection.
- Extend PR metadata fetch fields to include PR `body` for task reference fallback detection.

## [0.42.2] - 2026-02-24

### Technical
- Strengthen TS-REVIEW-001 preset-composition E2E runner/verifier instructions by requiring explicit dry-run subject input and resilient artifact-based verification criteria.

## [0.42.1] - 2026-02-23

### Changed
- Centralized ContextComposerError and UnknownStrategyError into Ace::Review::Errors module
- Narrowed exception handling in feedback_file_reader, feedback_file_writer, and task_report_saver

### Technical
- Updated internal dependency version constraints to current releases

## [0.42.0] - 2026-02-22

### Changed
- **Breaking:** Migrated from multi-command Registry to single-command pattern (task 278)
  - Removed `review` subcommand: `ace-review review --preset pr` → `ace-review --preset pr`
  - Removed `list-presets` subcommand: `ace-review list-presets` → `ace-review --list-presets`
  - Removed `list-prompts` subcommand: `ace-review list-prompts` → `ace-review --list-prompts`
  - Removed `version`/`help` subcommands: use `--version`/`--help` flags only
  - Added `--version`, `--list-presets`, `--list-prompts` flags to main command
  - Simplified `preprocess_array_options` (no command name detection needed)
  - No backward compatibility (per ADR-024)

## [0.41.2] - 2026-02-22

### Fixed
- Add flag variants (`--help`, `-h`, `--version`) to KNOWN_COMMAND_NAMES for preprocessing safety

## [0.41.1] - 2026-02-22

### Fixed
- Include built-in help/version commands in KNOWN_COMMAND_NAMES for correct array option preprocessing

## [0.41.0] - 2026-02-22

### Changed
- Migrate ace-review-feedback CLI to standard help pattern (task 278.13)
- Remove DWIM default routing — no args now shows help instead of running list command

## [0.40.5] - 2026-02-22

### Fixed
- Migrate to standard help pattern with explicit `review` subcommand
- Remove DWIM default routing — no args now shows help instead of running review

## [0.40.3] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.40.2] - 2026-02-19

### Technical
- Namespace workflow instructions into review/ subdirectory with updated wfi:// URIs

## [0.40.1] - 2026-02-19

### Fixed
- Architecture-reflection preset diff range changed from `HEAD~1..HEAD` to `origin/main..HEAD` to capture all implementation commits

## [0.40.0] - 2026-02-19

### Added
- New `architecture-reflection` review preset for pre-PR self-assessment — combines ATOM compliance, over-engineering detection, and missing abstraction analysis
- New `reflection` focus prompt (`focus/architecture/reflection.md`) with refactor/accept/skip categorization output format

### Fixed
- **Feedback extraction failures no longer silently swallowed**: When synthesis LLM call fails, error is now propagated to CLI output and response hash instead of being silently dropped
- **CLI reports feedback status**: Multi-model review output now shows feedback item count on success or error message on failure

### Added
- **Fallback model support for feedback synthesis**: Configure `feedback.fallback_models` in config.yml to try alternative models when primary synthesis model fails
- Default fallback model `claude:glm` added to config

## [0.39.3] - 2026-02-17

### Changed
- Clarify review workflow execution guards to prevent premature follow-up actions:
  - `review-pr.wf.md`: explicitly require process exit before feedback commands
  - `review.wf.md`: explicitly require process exit before feedback commands
- Standardize timeout handling guidance for review workflows (10-minute timeout with stop-on-timeout behavior)
- Add explicit precondition + session-targeted feedback examples to reduce session ambiguity in feedback listing

## [0.39.2] - 2026-02-16

### Added
- **Phased review presets**: `code-valid` (correctness), `code-fit` (quality), `code-shine` (polish) for laser-focused review cycles
- **Backward-compatible** `code-deep` preset as composition of `code` with detailed format
- **Focus prompts**: `phase/correctness.md`, `phase/quality.md`, `phase/polish.md` with explicit scope and DO NOT Review sections
- Project-level preset configuration files for monorepo discovery

### Changed
- **Multi-model reviewers**: All 3 phased presets use `claude:opus`, `codex:max`, `gemini:pro-latest`
- **Focus distribution**: All 6 focus modules from `code` preset distributed across the 3 phased presets (security→code-fit, tests+ruby→code-fit, docs→code-shine)

## [0.38.1] - 2026-02-15

### Changed
- **LlmExecutor**: Pass `sandbox: "read-only"` to `QueryInterface.query()` to enforce non-agentic mode for CLI providers during reviews

## [0.38.0] - 2026-02-08

### Added
- Unified feedback verification workflow with single `verify` command supporting three modes
- `--skip` option to `feedback verify` for marking items as skipped (correct but not fixing)
- Support for skipping both draft and pending status items (previously skip only worked on draft)
- Enhanced documentation with clear examples for when to use --valid, --invalid, or --skip
- Comprehensive test coverage for --skip mode and backward compatibility

### Changed
- `FeedbackManager.verify()` now supports `skip:` mode in addition to `valid:` parameter
- `FeedbackManager.skip()` now delegates to `verify()` with `skip: true` (backward compatible)
- Enhanced verification workflow documentation with clear decision criteria
- Improved CLI help text with examples for each verification mode

### Technical
- Added tests for skip mode transition from both draft and pending states
- Added tests for mutually exclusive validation in verify command
- Ensured backward compatibility for existing skip command usage

### Changed
- Embed CLI help reference in apply-feedback and verify-feedback workflows via bundle frontmatter
- Agents now see exact flag syntax per subcommand (verify/resolve/skip) when workflows load

## [0.37.3] - 2026-02-04

### Added
- Priority range filtering with `+` suffix for `feedback list` command
- `--priority medium+` filters for medium, high, and critical items
- `--priority high+` filters for high and critical items
- New `PriorityFilter` atom for priority filtering logic

## [0.37.2] - 2026-02-04

### Added
- `SubjectFilter` molecule extracting file filtering logic from Reviewer model
- README documentation for Subject Strategy Configuration (strategy types, adaptive mode)
- README documentation for Reviewers Format (attributes, file patterns, migration)
- `ContextLimitResolver` integration with ace-llm provider config for context limits

### Changed
- `Reviewer` model now delegates filtering to `SubjectFilter` molecule (ATOM architecture)

### Technical
- Comprehensive tests for `SubjectFilter` molecule

## [0.37.1] - 2026-02-04

### Fixed
- Graceful error handling for preset composition failures (circular deps, missing refs)
- E2E test MT-REVIEW-001 preset data now includes required `instructions:` key
- E2E test MT-REVIEW-001 uses valid model provider format

## [0.37.0] - 2026-02-04

### Added
- Token estimation foundation with `TokenEstimator` (chars/4 heuristic) and `ContextLimitResolver`
- `DiffBoundaryFinder` atom for parsing unified diffs into file blocks
- Subject strategy system with `SubjectStrategy` factory and registry
- `FullStrategy` for complete subject pass-through when content fits context
- `ChunkedStrategy` for file-boundary diff splitting of large subjects
- `AdaptiveStrategy` for auto-selecting between Full/Chunked based on token estimate
- `Reviewer` entity model with configurable focus, file patterns, and prompt additions

### Changed
- `FullStrategy` accepts `headroom` config option to customize context margin (aligns with `AdaptiveStrategy`)

### Fixed
- GPT-4 variant handling for 32k and preview models (gpt-4-32k, gpt-4-NNNN)
- Extended diff header preservation during truncation (rename operations)
- Chunk edge cases with non-positive available tokens

## [0.36.17] - 2026-02-04

### Added
- `--session all` flag for `feedback list` to aggregate feedback from all sessions
- `find_all_sessions` helper in `SessionDiscovery` module
- SESSION column in table output when viewing all sessions
- `session` field in JSON output when using `--session all`

## [0.36.16] - 2026-02-03

### Added
- `SessionDiscovery` shared module for DRY session resolution across feedback CLI commands

### Changed
- Refactored 6 feedback CLI commands to use shared `SessionDiscovery` module
- Updated CLI descriptions and error messages to remove obsolete `--task` references
- Added warn statement for lock file cleanup failures in `FeedbackFileWriter`

### Removed
- 5 deprecated auto-save methods from `ReviewManager` (~150 lines of dead code):
  - `save_multi_model_to_task`
  - `auto_save_review_if_enabled`
  - `auto_save_multi_model_reports`
  - `auto_save_to_release`
  - `save_to_task_if_requested`
- 11 deprecated auto-save tests (~270 lines)

### Fixed
- Documentation referencing outdated `--no-synthesize` flag in README.md
- Documentation referencing removed `--task` flag in feedback-workflow.md

## [0.36.15] - 2026-02-03

### Added
- Feedback list shows archived count when no active items exist with helpful hint to use `--archived`
- Status-based sorting for feedback list: draft → pending → done → skip → invalid (then by ID)

### Changed
- Feedback list summary now shows archived count hint when viewing active items only

## [0.36.14] - 2026-02-03

### Fixed
- Feedback CLI commands failing from subdirectories - now uses `ProjectRootFinder` for session discovery

## [0.36.13] - 2026-02-03

### Fixed
- Workflow documentation referencing removed `--task` CLI flag in session discovery

### Changed
- Improved feedback categorization guide in review workflows with clearer skip/defer semantics

## [0.36.12] - 2026-02-03

### Fixed
- Non-unique feedback IDs when multiple items created in rapid succession within same millisecond

### Added
- `FeedbackIdGenerator.generate_sequence(count)` for batch unique ID generation using `encode_sequence`

### Changed
- `FeedbackSynthesizer.parse_synthesis_response` pre-generates unique sequential IDs for all findings
- `FeedbackSynthesizer.create_feedback_item` accepts optional `id:` keyword argument

## [0.36.11] - 2026-02-03

### Fixed
- Missing `feedback.synthesis_model` configuration in default config files

## [0.36.10] - 2026-02-03

### Fixed
- JSON parsing for Claude Opus responses that include text before JSON code fence
- `FeedbackSynthesizer.parse_synthesis_response` now handles "Based on my analysis..." preamble

### Technical
- Extracted `extract_json_from_response` helper for robust JSON extraction from LLM responses
- Added test case for text-before-JSON-fence pattern

## [0.36.9] - 2026-02-03

### Removed
- `extraction_model` config option (legacy alias) - use `synthesis_model` only
- `extract-feedback.system.md` prompt - unified into `synthesize-feedback.system.md`

### Changed
- Feedback model configuration simplified to single `synthesis_model` option
- `FeedbackSynthesizer.default_synthesis_model` cascade simplified to remove `extraction_model` fallback
- `ReviewManager.extract_feedback` cascade simplified to use `synthesis_model` only

### Technical
- Removed ~140 lines of legacy prompt code
- Simplified configuration cascade - reduces confusion from duplicate config options

## [0.36.8] - 2026-02-03

**BREAKING CHANGES**: Feedback CLI now session-scoped only (--task option removed)

### Removed
- `FeedbackContextResolver` molecule - task-based path resolution no longer needed
- `--task` option from all feedback commands (create, list, show, verify, skip, resolve)

### Changed
- **Feedback is now session-scoped only** - all commands use `--session` flag with latest session default
- Simplified path resolution across all feedback commands to use consistent session-based pattern
- Updated test helper to remove `with_context_resolver_stub` helper
- All feedback command tests updated to use `session:` option directly

### Technical
- Removed ~546 lines of overengineered task-based resolution code
- Simplified feedback path resolution to: explicit session → latest session cache

### Fixed
- Documentation drift: ID format updated from "10-char" to "8-char" in feedback-workflow.md
- Test base class violations: FeedbackFileWriter, FeedbackFileReader, FeedbackDirectoryManager tests now inherit from AceReviewTest
- Missing trailing newline in .ace-defaults/review/config.yml

## [0.36.6] - 2026-02-03

### Removed
- `FeedbackDeduplicator` atom - superseded by LLM-based deduplication in FeedbackSynthesizer
- `FeedbackExtractor` molecule - replaced by FeedbackSynthesizer which handles multi-report synthesis

### Technical
- Removed ~600 lines of dead code and tests that were not used in the current feedback architecture

## [0.36.5] - 2026-02-03

### Added
- Prompt size warning before LLM execution - warns when prompt exceeds 80% of typical context window (~160K tokens)
- `--session` flag for `feedback list` command - allows explicit session directory path
- Documentation for session-scoped feedback context in workflow instructions

### Fixed
- Lock file (.feedback.lock) now cleaned up after writes - prevents clutter in feedback directories

### Technical
- Added LlmExecutor and MultiModelExecutor prompt size warning with formatted token count
- Updated FeedbackFileWriter with ensure block for lock file cleanup
- Added tests for prompt size warning, lock file cleanup, and --session flag

## [0.36.4] - 2026-02-03

**BREAKING CHANGES**: Feedback-first architecture replaces synthesis-report.md output

### Changed
- **Feedback is now the primary output** - synthesis-report.md has been removed entirely
- FeedbackIdGenerator now uses 8-char millisecond timestamp format (was 10-char with random suffix)
- `should_extract_feedback?` always returns true if results exist (no config toggle)
- Workflow instructions updated to use feedback commands instead of synthesis

### Removed
- **ReportSynthesizer molecule** - no longer needed with feedback-first architecture
- `ace-review synthesize` CLI command removed
- `--synthesize`, `--no-synthesize`, `--synthesis-model` CLI flags removed
- `synthesis:` config section removed from config files
- `feedback.enabled` config removed (feedback always runs)
- `synthesize`, `no_synthesize`, `synthesis_model` options from ReviewOptions

### Technical
- Updated review.wf.md and review-pr.wf.md with feedback verification workflow
- Simplified ReviewManager by removing synthesis-related methods
- Tests updated for new 8-char feedback IDs and removed synthesis tests

## [0.36.3] - 2026-02-03

### Fixed
- Synthesis now disabled by default (feedback files are primary output per task 227 spec)
- Added `--synthesize` flag to opt-in to synthesis-report.md generation
- Added explicit `feedback.enabled: true` default to config

### Changed
- `should_synthesize?` now defaults to false, checks for --synthesize CLI flag
- ReviewOptions now includes :synthesize attribute

### Technical
- Updated default config to clarify synthesis is opt-in

## [0.36.2] - 2026-02-03

### Added
- FeedbackSynthesizer molecule for multi-reviewer consensus analysis
- Support for multiple reviewers per FeedbackItem (reviewers array format)
- Consensus detection: marks items agreed upon by 3+ models
- Synthesize feedback prompt template at handbook/prompts/synthesize-feedback.system.md

### Changed
- FeedbackItem now stores multiple reviewers with consensus flag
- FeedbackFileWriter handles new multi-reviewer format
- FeedbackManager integrates synthesis workflow
- ReviewManager adds synthesis step for multi-model reviews

### Technical
- Added FeedbackSynthesizer with LLM-based consensus detection
- Updated tests for multi-reviewer workflow

## [0.36.1] - 2026-02-03

### Changed
- **Session Symlink Architecture**: Task reviews now symlink to session directories instead of copying files
  - Multiple review sessions can be linked to the same task
  - All session artifacts (prompts, metadata, feedback) accessible via symlink
  - Feedback stays in session directory (gitignored via .cache)
  - New methods: `link_session_to_task`, `link_session_to_task_if_requested`, `auto_link_session_if_enabled`
  - Deprecated: `save_to_task_if_requested`, `save_multi_model_to_task`, `save_synthesis_to_task`

### Technical
- Simplified `determine_feedback_path` to always return session directory
- Updated feedback-workflow.md documentation for symlink architecture

## [0.36.0] - 2026-02-03

### Added
- **Feedback System**: Replace monolithic synthesis reports with tracked feedback items
  - `FeedbackItem` model with full lifecycle support (task 227.01)
  - File I/O with atomic writes and locking (task 227.02)
  - LLM-based feedback extraction with deduplication (task 227.03)
  - `FeedbackManager` organism for lifecycle orchestration (task 227.04)
  - Integration with review pipeline via `--no-feedback` flag (task 227.05)
  - CLI commands: `feedback list`, `show`, `verify`, `skip`, `resolve` (task 227.06)
  - Task integration with automatic directory creation (task 227.07)
  - Single-model feedback extraction (previously only multi-model supported)
  - Documentation at `docs/feedback-workflow.md` (task 227.08)

### Fixed
- Use blocking lock for reliable concurrent feedback file access
- Expand branch pattern to match `task-` prefix for auto-save
- Merge files on deduplication instead of discarding
- Use `extraction_model` config key for consistency
- Use dynamic distance threshold for deduplication
- Use dedicated lock file for concurrent write coordination
- Add random suffix to FeedbackIdGenerator for uniqueness

### Technical
- Update ID format documentation from 6-char to 10-char

## [0.35.6] - 2026-02-02

### Added

- Batch review preset for consolidated task evaluation
- Integration test for prompt path resolution

### Changed

- Review workflows now default to "medium and higher" priority threshold for coworker automation
- Removed AskUserQuestion from review skill allowed-tools (no longer needed)
- Migrated integration tests to E2E format with consolidated DeepMerger

### Fixed

- Guarantee 0 exit code for help requests

## [0.35.5] - 2026-01-31

### Performance

- Optimized test suite from 14.68s to 5.52s (62% reduction)
  - Added `SharedTempDir` module for opt-in per-class temp directory sharing
  - Reduces setup/teardown overhead from ~10ms per test to near-zero
  - Test classes opt-in with `def self.use_shared_temp_dir?; true; end`

### Changed

- Migrated 58 integration-style molecule tests to E2E format
  - Created MT-REVIEW-004 (GitHub CLI integration) - 7 test cases
  - Created MT-REVIEW-005 (multi-model executor) - 5 test cases
  - Removed gh_cli_executor_test.rb (13 tests)
  - Removed gh_pr_fetcher_test.rb (13 tests)
  - Removed gh_pr_comment_fetcher_test.rb (19 tests)
  - Removed multi_model_executor_test.rb (13 tests)

## [0.35.4] - 2026-01-31

### Refactored

- Consolidated `deep_merge_hash` utility into centralized `Ace::Support::Config::Atoms::DeepMerger`
  - Removed duplicate implementations from `PresetManager` and `ReviewManager`
  - Both now use `DeepMerger.merge(base, overlay, array_strategy: :union)`
  - Improves maintainability and aligns with ATOM architecture (ADR-011)

### Performance

- Moved 8 integration test files to E2E test suite
  - Created MT-REVIEW-001 (preset composition), MT-REVIEW-002 (multi-subject), MT-REVIEW-003 (auto-save workflow)
  - E2E tests run via `/ace:run-e2e-test ace-review MT-REVIEW-001`
  - Test execution time reduced from 19.52s to ~13.5s (31% reduction)
  - Remaining time due to legitimate timeout tests in molecules layer

### Changed

- Removed integration test files (replaced by E2E tests):
  - preset_composition_integration_test.rb (12 tests)
  - multi_subject_integration_test.rb (8 tests)
  - auto_save_integration_test.rb (E2E flow moved, unit tests covered elsewhere)
  - preset_diff_integration_test.rb
  - multi_model_cli_test.rb
  - full_prompt_generation_test.rb
  - pr_diff_generation_test.rb
  - synthesis_test.rb

## [0.35.3] - 2026-01-29

### Fixed
- Multi-model executor hanging on slow CLI providers by adding timeout to Thread.join
- Added deadline-based join to ensure total wait is bounded regardless of stuck threads
- Suppressed IOError exceptions from killed threads for cleaner output
- Added warning display for threads killed after timeout

## [0.35.2] - 2026-01-29

### Added
- Enhanced review synthesis prompts with accuracy and conflict resolution guidelines
- Added "Verification Required" section for unverifiable model claims
- Added "Future Considerations" section to separate speculation from action items
- Added severity classification and scope boundary guidance to base review prompt

### Fixed
- Exception-based CLI error handling for consistent exit codes

## [0.35.1] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.35.0] - 2026-01-15

### Changed
- **Dependency Migration**: Replaced ace-context dependency with ace-bundle (~> 0.29)
  - Updated gemspec dependency from `ace-context ~> 0.9` to `ace-bundle ~> 0.29`
  - Updated all `require 'ace/context'` to `require 'ace/bundle'`
  - Updated all `Ace::Context` references to `Ace::Bundle`
  - Renamed `load_context_via_ace_context` to `load_context_via_ace_bundle`
  - Renamed `ace_context_preset_exists?` to `ace_bundle_preset_exists?`
- Updated error messages and comments to reference ace-bundle

### Technical
- Updated test helpers to stub Ace::Bundle instead of Ace::Context
- Updated all test files with ace-bundle references

## [0.34.0] - 2026-01-14

### Added
- Support for Gemini provider in all review presets
- Google Gemini 2.5 Flash as default model for code reviews

### Changed
- Updated LLM executor to handle gemini provider configuration
- All review presets now use gemini:gemini-2.5-flash as default model

## [0.33.2] - 2026-01-13

### Fixed
- Fix multi-model option handling: store parsed models in `:models` key (array) instead of `:model` key
  - Resolves issue where multi-model reviews failed due to incorrect option key usage

### Changed
- Update dependencies: ace-support-nav (renamed from ace-nav), ace-support-config (renamed from ace-config)

## [0.33.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `ListPresets`, `ListPrompts`, `Review`, and `Synthesize` dry-cli command classes
  - Deleted `list_presets_command.rb`, `list_prompts_command.rb`, `review_command.rb`, and `synthesize_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.33.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.14)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Converted CLI to dry-cli Registry pattern
  - Created dry-cli command classes (list_presets, list_prompts, review, synthesize)

## [0.32.1] - 2026-01-07

### Added
- Support `commit:HASH` subject type for reviewing individual commits
  - Accepts commit hashes with 6-40 hexadecimal characters
  - Validates hash format before git operations
  - Generates diff using `COMMIT~1..COMMIT` syntax to show commit's changes
  - Provides clear error messages for invalid formats
  - Updated documentation with usage examples

## [0.32.0] - 2026-01-07

### Changed
- **BREAKING**: Review report filenames changed from 14-character timestamps to 6-character Base36 compact IDs
  - Example: `20251129-143000-model-preset-review.md` → `i50jj3-model-preset-review.md`
  - Synthesis reports: `20251129-143000-synthesis.md` → `i50jj3-synthesis.md`
- Migrate to Base36 compact IDs for session directories (via ace-timestamp)

### Added
- Dependency on ace-timestamp for compact ID generation

## [0.31.1] - 2026-01-05

### Technical
- Clarified subject type prefix requirement in workflow documentation with explicit warnings and common mistakes examples

## [0.31.0] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.30.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.29.4] - 2026-01-03

### Changed

- **Test performance optimization**: Reduced test suite execution time from 7.15s to 1.77s (75% reduction)
  - Removed unnecessary git init from MultiModelCliTest (tests only parse CLI options)
  - Added shared `stub_synthesizer_prompt_path` helper to avoid ace-nav subprocess calls (~150-400ms per call)
  - Optimized `mock_llm_synthesis` to use block-based stubbing pattern for better isolation

### Technical

- Extract shared prompt path stubbing to `AceReviewTest#stub_synthesizer_prompt_path`
- Include `Ace::TestSupport::Fixtures::PromptHelpers` mixin in test helper
- Remove unused `require "tmpdir"` from multi_model_cli_test.rb

## [0.29.3] - 2026-01-01

### Fixed

- **Configurable timeout for gh CLI operations**: `execute_simple` and `execute` methods now use configurable timeout from config instead of hardcoded values
  - Added `gh_simple_timeout` config option (default: 10s) for simple commands like `--version`, `auth status`
  - `execute` now reads `gh_timeout` from config (default: 30s) instead of hardcoded fallback
  - Follows ADR-022 pattern with `Ace::Review.get("defaults", "key")` for config access

## [0.29.2] - 2025-12-30

### Changed

- Add ace-config dependency for configuration cascade management
- Migrate from Ace::Core to Ace::Config.create() API (keep ace-support-core for ProcessTerminator)
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.29.1] - 2025-12-30

### Changed

- **Workflow presentation format**: Improved review results presentation in `review.wf.md` and `review-pr.wf.md`
  - Separate "No Action Needed" section (no numbering) for INVALID and VERIFIED CORRECT items
  - Numbered "Action Items" table with priority column
  - New priority threshold selection: All, Medium+, High+, Critical only
  - Clearer categorization step (Step 5) before presentation

## [0.29.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.28.0] - 2025-12-29

### Changed
- Migrate file system operations from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.27.2] - 2025-12-28

### Added
- **Prioritize developer feedback in synthesis**: Human reviewer comments now receive special handling
  - New "Developer Action Required" section appears before Consensus Findings
  - Each unresolved comment gets its own subsection with exact text preserved
  - Priority boosting ensures developer feedback is never ranked lower than Medium
  - Added completeness requirements to prevent summarization of dev comments
  - Added anti-patterns and verification checklist for developer feedback

## [0.27.1] - 2025-12-28

### Fixed
- **Auto-discover repo for inline PR comments**: When running `ace-review --pr <number>` (local PR number), inline code comments were silently not fetched because GraphQL requires owner/repo format. Now automatically discovers repository via `gh repo view --json owner,name`
- **Improved warning messages**: Upgraded warning messages from Debug to Warning level for better visibility when inline comments cannot be fetched

## [0.27.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/review/config.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

### Fixed
- **Debug Check Consistency**: Standardized `debug?` method to use `== "1"` pattern (was `== "true"`)

## [0.26.3] - 2025-12-27

### Changed

- **Add verification step to review workflows**: New Step 3 in `review.wf.md` and `review-pr.wf.md` requires verifying Critical/High priority action items before presenting to user
  - Categorize items as VALID/INVALID/EDGE CASE/SUGGESTION
  - Filter out false positives from LLM reviewers
  - Prevents wasted investigation time on non-issues

## [0.26.2] - 2025-12-26

### Technical

- Add timeout guidance for Claude Code agents in workflow instructions (10-minute timeout, inline mode)

## [0.26.1] - 2025-12-26

### Fixed

- **Complete ace-git migration in SubjectExtractor**: Replace remaining ace-context references with ace-git equivalents
  - `Ace::Context::Atoms::GitExtractor.tracking_branch` → `Ace::Git::Molecules::BranchReader.tracking_branch`
  - `Ace::Context::Atoms::PrIdentifierParser.parse` → `Ace::Git::Atoms::PrIdentifierParser.parse`
  - Fixes `uninitialized constant` errors when using ace-review after ace-context v0.16 migration

## [0.26.0] - 2025-12-26

### Changed

- **Migrate to ace-git**: Replace duplicated Git/GitHub code with ace-git dependency
  - Removed `Ace::Review::Molecules::GitBranchReader` - now uses `Ace::Git::Molecules::BranchReader`
  - Removed `Ace::Review::Atoms::TaskAutoDetector` - now uses `Ace::Git::Atoms::TaskPatternExtractor`
  - Removed `Ace::Review::Molecules::PrIdentifierParser` - now uses `Ace::Git::Atoms::PrIdentifierParser`
  - Added `ace-git (~> 0.3)` as runtime dependency
  - Eliminates code duplication and centralizes Git operations in ace-git package
- **Fail fast on ace-git load**: Remove defensive begin/rescue around ace-git require since it's a hard dependency

### Fixed

- **GhCommentPoster fallback URL**: Fix URL construction when gh CLI output doesn't include URL
  - Now correctly uses ace-git's combined `:repo` format (owner/repo) instead of legacy separate `:owner`/`:repo` keys

### Removed

- Deleted `lib/ace/review/molecules/git_branch_reader.rb`
- Deleted `lib/ace/review/atoms/task_auto_detector.rb`
- Deleted `lib/ace/review/molecules/pr_identifier_parser.rb`
- Deleted corresponding test files
- Removed `ace-git-diff` dependency (functionality migrated to ace-git)

### Added

- `mock_parse_result` test helper in test_helper.rb for consistent ParseResult mock creation
- Tests for GhCommentPoster.extract_comment_url fallback path scenarios

## [0.25.0] - 2025-12-17

### Added

* **Multiple `--subject` Flags**: Support combining multiple subject sources in a single review
  * `ace-review --subject pr:77 --subject files:README.md --subject pr:79`
  * Subjects are merged into unified ace-context config
  * New `merge_typed_subject_configs()` public API for config merging

### Fixed

* **Nested Hash Merging**: Fixed `deep_merge_arrays` to recursively merge nested hashes
  * Two typed subjects like `diff:HEAD~3` and `diff:HEAD` now correctly merge their nested `context.diffs` arrays
  * Made merge operation immutable (no longer mutates input hashes)

### Changed

* **Simplified Subject Extraction**: Removed legacy content extraction paths
  * Removed `extract(Array)` - arrays now handled via `merge_typed_subject_configs`
  * Removed `extract_and_merge_multiple` - replaced by config passthrough
  * Removed `subject-content.md` creation - all subjects use ace-context config passthrough
  * Cleaner API: `parse_typed_subject_config` for single, `merge_typed_subject_configs` for multiple

### Technical

* Removed 17 tests for deprecated array extraction functionality
* Added 8 tests for `merge_typed_subject_configs` merged config validation
* Cleaned up `:subjects` intermediate key in CLI options

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


## [0.40.4] - 2026-02-22

### Fixed
- Hidden deprecated 'feedback skip' subcommand from help (use 'verify --skip' instead)
- Standardized quiet, verbose, debug option descriptions to canonical strings
