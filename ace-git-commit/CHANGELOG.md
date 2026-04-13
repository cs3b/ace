# Changelog

All notable changes to ace-git-commit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [0.24.1] - 2026-04-13

### Changed
- Completed the batch i05 migration follow-through for this package and aligned it with the restarted `fast` / `feat` / `e2e` verification model.

### Technical
- Included in the coordinated assignment-driven patch release for batch i05 package updates.


## [0.24.0] - 2026-04-12

### Changed
- Migrated package tests to the restarted `fast` / `feat` / `e2e` model by moving deterministic suite files into `test/fast/` and keeping scenario workflows in `test/e2e/`.
- Added `unit-coverage-reviewed` metadata for `TS-COMMIT-001` and aligned scenario sandbox setup to support `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}`.
- Updated package docs (`README`, `docs/usage.md`, `docs/getting-started.md`) to teach the restarted testing contract (`ace-test`, `ace-test ... feat`, `ace-test-e2e`, `ace-test ... all`).

## [0.23.7] - 2026-04-10

### Fixed
- Restored packaged default split configuration (`git.split.enabled: true`, `git.split.strategy: config-scope`) and documented `--no-split` as the explicit single-commit override.
- Added packaged-default regression coverage in `test/default_config_test.rb` to enforce the split-default contract.

## [0.23.6] - 2026-03-31

### Changed
- Role-based commit generation defaults.

## [0.23.5] - 2026-03-29

### Changed
- Role-based commit model defaults in docs and fixtures.


## [0.23.4] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.23.3] - 2026-03-29

### Fixed
- Bumped the `ace-git` runtime dependency constraint to `~> 0.19` so ace-git-commit stays aligned with the current git workflow release.

## [0.23.2] - 2026-03-29

### Technical
- Register package-level `.ace-defaults` skill-sources for ace-git-commit to enable canonical skill discovery in fresh installs.


## [0.23.1] - 2026-03-29

### Fixed
- **ace-git-commit v0.23.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.23.0] - 2026-03-23

### Added
- Configuration section in README pointing to `.ace-defaults/git/commit.yml` for model overrides and `.ace-handbook/prompts/` for prompt template customization.

### Changed
- Aligned gemspec summary with README tagline.
- Moved Installation from README to Getting Started guide as a proper section.
- Redesigned getting-started demo tape: sandbox with real commits (specific files, then remaining), replaces dry-run-only scenes.
- Re-recorded getting-started demo GIF from new tape.

## [0.22.1] - 2026-03-23

### Changed
- Refreshed the package README to the current ACE package layout pattern with updated section flow and docs navigation links.

## [0.22.0] - 2026-03-18

### Changed
- Refined `TS-COMMIT-001` E2E runner guidance so each goal is self-contained and no longer depends on prior discovery output.

### Technical
- Normalized `TS-COMMIT-001` verifier expectation formatting for clearer impact-first evidence checks.
- Added task-scoped E2E review, change-plan, and rewrite-summary artifacts for `8qe.t.h5e.6`.

## [0.21.6] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.21.5] - 2026-03-15

### Fixed
- Fixed commit workflow embedded status using `git status -sb -uall` to show individual untracked files instead of collapsed directory entries.
- Added explicit guidance that untracked files (`??`) are committable changes, preventing agents from incorrectly reporting "nothing to commit" on untracked-only changes.

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.21.4] - 2026-03-13

### Technical
- Harmonized canonical git-commit skill structure with the unified execution contract.

## [0.21.3] - 2026-03-13

### Changed
- Replaced provider-specific Codex execution metadata on the canonical `as-git-commit` skill with a unified canonical skill body that declares arguments, variables, and explicit workflow-execution guidance.
- Limited provider-specific forking for `as-git-commit` to Claude frontmatter only.

## [0.21.2] - 2026-03-13

### Changed
- Updated the canonical `as-git-commit` Codex metadata to use `context: ace-llm` with frontmatter-driven variable and instruction rendering for projected Codex skills.

## [0.21.1] - 2026-03-12

### Changed
- Updated README prompt-path guidance to reference the package-local handbook prompt source.

## [0.21.0] - 2026-03-12

### Added
- Added provider-specific Claude and Codex execution overrides to the canonical `as-git-commit` skill so projected provider skills can request forked execution with provider-specific models.

## [0.20.0] - 2026-03-10

### Added
- Added the canonical handbook-owned git commit skill for agent-facing commit generation.


## [0.19.2] - 2026-03-08

### Fixed
- Improved split-commit message generation reliability by replacing brittle marker parsing with strict JSON batch parsing, validation, and one repair retry.
- Removed generic `chore: update <scope>` fallback for missing batch messages; split commits now fall back to per-scope message generation when batch parsing fails.

### Changed
- Strengthened git-commit prompting guidance to reduce generic `chore` usage for feature/fix/refactor-level code changes.

### Technical
- Added regression tests for JSON batch parsing, retry behavior, and per-scope fallback message generation in split commit execution.

## [0.19.1] - 2026-03-05

### Fixed
- Cap `max_tokens` at 8192 for commit message generation to prevent inflated thinking budgets from the provider's global 65536 default.

## [0.19.0] - 2026-03-03

### Added
- Group all `.ace/` config files into a single "ace-config" commit scope instead of creating separate per-package commits.

## [0.18.8] - 2026-02-26

### Fixed
- Run normal stage-all flow before deciding no-op, instead of short-circuiting at the top of execution.
- Correct change detection to include untracked files via `ace-git` command executor helpers.
- Preserve single-line no-op output: `No changes to commit` is printed only after staging confirms nothing is staged.

## [0.18.7] - 2026-02-26

### Fixed
- Treat "no changes to commit" as a successful no-op (exit 0) instead of a failure.
- Simplify no-op output to a single clear line: `No changes to commit` (without staging progress or generic failure messaging).

## [0.18.6] - 2026-02-25

### Technical
- Bump runtime dependency constraint from `ace-git ~> 0.10` to `ace-git ~> 0.11`.

## [0.18.5] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.18.4] - 2026-02-22

### Changed
- Migrate CLI entrypoint to single-command dry-cli execution (`ace-git-commit [FILES] [OPTIONS]`)
- Handle `--version` directly in commit command flow for single-command mode
- Add `--staged` as an alias for `--only-staged`

### Technical
- Remove registry/default-routing wiring from CLI module
- Rewrite CLI routing tests to executable-level single-command behavior checks

## [0.18.2] - 2026-02-21

### Added
- Enhance commit message generation with intent and action focus

### Technical
- Add staged rename verification to mixed operations test
- Standardize workflow instruction path

## [0.18.1] - 2026-02-19

### Technical
- Namespace commit workflow instruction to git/ subdirectory

## [0.18.0] - 2026-02-19

### Added
- "This commit will..." test in subject-crafting step to improve intent capture
- "Describe the action, not the content" guidance with concrete examples
- Specific handling for deletion-only commits (use "remove", "delete", "drop" verbs)

## [0.17.2] - 2026-02-11

### Added
- Exception-based CLI error reporting for consistent error handling

### Technical
- Migrate E2E tests to per-TC directory format
- Enhance E2E tests for commit splitting and path handling
- Standardize E2E test cache directory naming

## [0.17.1] - 2026-01-27

### Added
- Add `spec` commit type for task specifications and development artifacts
- Clarify `docs` type is for software documentation (user guides, API docs, README)

## [0.17.0] - 2026-01-27

### Added
- Path-based configuration splitting for scoped commits in mono-repos
- Batch LLM generation for multiple commit scopes in a single run
- Automatic scope detection based on file paths and glob patterns
- Support for scope-specific model overrides and type hints
- `scopes` configuration in `.ace/git/commit.yml` for defining file groupings

### Changed
- Enhanced commit workflow to support multiple atomic commits per scope
- Improved configuration resolution with path rules from ace-support-config

## [0.16.5] - 2026-01-20

### Fixed
- Validate paths by checking git status for deleted/renamed files

### Technical
- Update for ace-bundle integration

## [0.16.4] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.16.3] - 2026-01-10

### Changed
- Use shared `Ace::Core::CLI::DryCli::DefaultRouting` module for CLI routing
  - Removed duplicate routing code in favor of shared implementation
  - Maintains same behavior with less code duplication

## [0.16.2] - 2026-01-10

### Fixed
- Fix CLI default command routing to properly handle flags
  - Removed flawed `!args.first.start_with?("-")` check from routing condition
  - Flags like `-i`, `--dry-run` now correctly route to default `commit` command
  - Built-in flags (`--help`, `--version`) continue working via KNOWN_COMMANDS

## [0.16.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Commit` dry-cli command class
  - Deleted `commit_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.16.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.07)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command class (commit)
  - Uses `Ace::Core::CLI::DryCli::Base` module for CLI helpers

## [0.15.2] - 2026-01-04

### Fixed

- ace-git-commit now respects `.gitignore` when staging directory paths
- Directories are passed directly to `git add` without file expansion
- Fixed issue where `ace-git-commit .ace-taskflow/` would try to stage files in gitignored subdirectories like `reviews/`
- Only glob patterns are expanded to file lists through PathResolver

## [0.15.1] - 2026-01-03

### Changed

- Enhanced `commit` workflow with `embed_document_source: true` to embed `<current_repository_status>`
- Workflow now includes pre-loaded git status and diff summary, eliminating redundant commands
- Reduced tool calls from 5 to 2-3 (40-60% improvement) when agents invoke `/ace:commit`

## [0.15.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.0.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.14.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.14.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.13.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/git/commit.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

### Fixed
- **Path Expansion**: Fixed gem root resolution in `load_gem_defaults` (4 levels instead of 5)
- **Debug Check Consistency**: Standardized `debug?` method to use `== "1"` pattern across all gems

## [0.12.4] - 2025-12-27

### Changed
- **Dependency Migration**: Migrated from `ace-git-diff (~> 0.1)` to `ace-git (~> 0.3)`
  - GitExecutor now delegates to `Ace::Git::Atoms::CommandExecutor`
  - Part of ace-git consolidation (ace-git-diff merged into ace-git)

## [0.12.3] - 2025-12-06

### Technical
- Updated ace-llm dependency from `~> 0.12.0` to `~> 0.13.0` for OpenRouter provider support

## [0.12.2] - 2025-11-17

### Technical
- Updated ace-llm dependency from `~> 0.10.0` to `~> 0.11.0` for graceful provider fallback support

## [0.12.1] - 2025-11-16

### Changed

- **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  - Provides access to latest PromptCacheManager features and infrastructure improvements
  - Maintains compatibility with standardized ACE ecosystem patterns

## [0.12.0] - 2025-11-15

### Added
- **Path restriction for targeted commits**: Support for committing only files within specified directories or paths
- **Glob pattern support**: Full glob pattern support (`**/*.rb`, `lib/**/*.test.js`) for flexible file selection
- **Repository boundary validation**: `within_repository?` method validates paths are within git repository boundaries
- **Early path validation**: Validates path existence before git operations with clear error messages
- **Comprehensive CLI documentation**: Updated help text with detailed path and pattern usage examples

### Changed
- **PathResolver architecture**: Made `glob_pattern?` public and consolidated path detection logic
- **Staging strategy**: Intelligent routing between simple file staging and path-restricted staging based on input type
- **Error messaging**: Enhanced error messages for invalid paths and empty glob pattern results

### Technical
- **Integration test coverage**: Added 4 comprehensive integration tests for path validation and glob pattern handling
- **Unit test expansion**: Added 6 new unit tests for `glob_pattern?` and `within_repository?` methods
- **Code quality improvements**: Removed method duplication between PathResolver and CommitOrchestrator

## [0.11.2] - 2025-11-12

### Fixed
- **Silent staging failures**: Staging operations now properly detect and report failures instead of continuing silently
- **Misleading error messages**: Error messages now accurately reflect operation outcomes with clear indicators (✓/✗)
- **Debug-only output**: Staging progress messages are now visible by default (not just in debug mode)
- **Error visibility in quiet mode**: Critical errors always display, even in quiet mode, ensuring users are informed of failures

### Added
- **Verbosity control**: Added `--verbose` (default) and `--quiet` flags for output control
- **Error context**: Staging failures now include specific error details and actionable suggestions
- **StageResult model**: Infrastructure for tracking per-file staging outcomes
- **Transparent feedback**: Clear staging progress and error reporting with actionable suggestions (documented in README)

### Changed
- **FileStager**: Now returns boolean success/failure status and stores error details in `last_error`
- **CommitOrchestrator**: Enhanced with visible staging progress, proper error handling, and fail-fast behavior
- **CommitOptions**: Extended with `verbose` (default: true) and `quiet` (default: false) options
- **User feedback**: All staging operations now provide clear, immediate feedback on success or failure

## [0.11.1] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Changed dependency from `ace-test-support` to `ace-support-test-helpers` (if applicable)
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.11.0]
 - 2025-10-23

### Changed
- Integrated with ace-git-diff for unified git command execution
- GitExecutor now delegates to ace-git-diff's CommandExecutor for all git operations
- Added ace-git-diff (~> 0.1.0) as runtime dependency
- Maintains full backward compatibility for all public APIs

## [0.10.0] - 2025-10-14

### Added
- Standardize Rakefile test commands and add CI fallback

### Technical
- Add proper frontmatter with git dates to all managed documents

## [0.9.2] - 2025-10-08

### Changed

- **Test Structure Reorganization**: Reorganized tests for consistency
  - Moved `test/ace/git_commit_test.rb` → `test/git_commit_test.rb`
  - Aligns with standardized flat ATOM structure across all ACE packages

## [0.9.1] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.0] - 2024-XX-XX

### Added
- Initial release with LLM-powered Git commit message generation
- Support for conventional commit format
- Automatic staging of all changes (monorepo-friendly)
- Gemini 2.0 Flash Lite (`glite`) as default model
- Flexible model selection with `--model` flag
- Intention-based message generation with `-i/--intention` flag
- Dry-run mode for previewing commit messages


## [0.18.3] - 2026-02-22

### Fixed
- Stripped duplicate command name prefix from commit examples
- Standardized quiet, verbose, debug option descriptions to canonical strings
