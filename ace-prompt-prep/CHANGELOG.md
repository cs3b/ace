# Changelog

All notable changes to ace-prompt-prep will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Aligned the E2E sandbox bootstrap to copy `mise.toml` from `ACE_E2E_SOURCE_ROOT` instead of sandbox `PROJECT_ROOT_PATH`.


## [0.23.6] - 2026-03-31

### Changed
- Role-based prompt enhancement defaults.

## [0.23.5] - 2026-03-29

### Fixed
- Bumped the `ace-bundle` runtime dependency constraint to `~> 0.41` to follow the new bundle minor release line.

## [0.23.4] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.23.3] - 2026-03-29

### Fixed
- Bumped the `ace-git` runtime dependency constraint to `~> 0.19` so ace-prompt-prep stays aligned with the current git workflow release.

## [0.23.2] - 2026-03-29

### Technical
- Register package-level `.ace-defaults` skill-sources for ace-prompt-prep to enable canonical skill discovery in fresh installs.


## [0.23.1] - 2026-03-29

### Fixed
- **ace-prompt-prep v0.23.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.23.0] - 2026-03-23

### Changed
- Removed stale `docs/security.md` which contained pervasively outdated references to old package name, module paths, CLI commands, and placeholder contact info.
- Re-recorded getting-started demo GIF.

### Technical
- Updated `docs/handbook.md` to remove broken security doc link.

## [0.22.3] - 2026-03-23

### Changed
- Refreshed `README.md` to align with the current ACE package layout pattern (quick links, use cases, works-with links, and standardized package sections).

## [0.22.2] - 2026-03-22

### Fixed
- Replaced a broken CLI help markdown link in `README.md` with a valid inline command reference.

## [0.22.1] - 2026-03-22

### Fixed
- Corrected the task-specific getting-started command to use `ace-prompt-prep process --task <id>` instead of an unsupported top-level `--task` invocation.
- Fixed handbook documentation links in `docs/handbook.md` so they resolve to the package `handbook/` directory.

## [0.22.0] - 2026-03-22

### Changed
- Reworked `ace-prompt-prep` documentation surface for user onboarding: landed a value-first README with new demo context, added `docs/getting-started.md`, rebuilt `docs/usage.md` and `docs/handbook.md`, and aligned package messaging to the new README headline.
- Added/updated demo assets under `docs/demo/` including a VHS tape + GIF showing setup and prompt enhancement flow.
- Updated gemspec metadata to match the documentation-centric positioning.

## [0.21.0] - 2026-03-21

### Changed
- Expanded `TS-PREP-001` E2E coverage with a new bundle-context goal and tightened runner/verifier artifact-evidence contracts across existing goals.

## [0.20.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.20.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.19.5] - 2026-03-17

### Fixed
- Updated CLI routing tests to accept `COMMANDS`/`USAGE` header rendering introduced by shared help formatting.

## [0.19.4] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.19.3] - 2026-03-13

### Changed
- Updated the canonical prompt-prep skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

## [0.19.2] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-prompt-prep` skill so provider projections now inherit the canonical skill body unchanged.

## [0.19.1] - 2026-03-12

### Fixed
- Registered the package WFI source so `wfi://prompt-prep` resolves for the canonical prompt-prep skill.

## [0.19.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-prompt-prep` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

## [0.18.0] - 2026-03-10

### Added
- Added the canonical handbook-owned prompt-prep skill and workflow entrypoint for prompt workspace preparation.


## [0.17.4] - 2026-03-09

### Fixed
- Updated bundle-enabled prompt-prep test expectations to match the current `ace-bundle` contract, asserting successful compressed bundle output instead of stale raw-markdown responses.

## [0.17.3] - 2026-03-04

### Fixed
- README migration note corrected: old path was `.cache/ace-prep` (not `.ace-local/ace-prep`)

## [0.17.2] - 2026-03-04

### Fixed
- Usage docs corrected to short-name path convention (`.ace-local/prompt-prep/` not `.ace-local/ace-prompt-prep/`)

## [0.17.1] - 2026-03-04

### Fixed
- README and usage docs updated to short-name path convention (`.ace-local/prompt-prep` not `.ace-local/ace-prompt-prep`)

## [0.17.0] - 2026-03-04

### Changed
- Default cache directory migrated from `.cache/ace-prompt-prep` to `.ace-local/prompt-prep`
- `PromptInitializer.default_prompt_dir` now returns path under `.ace-local/prompt-prep/prompts`

## [0.16.9] - 2026-03-02

### Changed
- Replace `ace-taskflow` dependency with `ace-task` — migrate `TaskPathResolver` to use `Ace::Task::Organisms::TaskManager.show()` API (returns struct with `.path` instead of hash with `:path`)

## [0.16.8] - 2026-02-25

### Technical
- Bump runtime dependency constraint from `ace-git ~> 0.10` to `ace-git ~> 0.11`.

## [0.16.7] - 2026-02-25

### Fixed
- Align `BundleLoader` security test expectations with current return behavior for debug logging paths
- Resolve three failing tests in `bundle_loader_security_test.rb` by asserting returned content instead of empty string

## [0.16.6] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.16.5] - 2026-02-22

### Changed
- Migrate to standard dry-cli help pattern (Task 278.28)
  - Remove DefaultRouting pattern in favor of explicit HelpCommand registration
  - No args now shows help instead of running default command
  - Update tests to use Dry::CLI.new().call() pattern

## [0.16.3] - 2026-02-12

### Added
- Support `bundle.enabled: false` in prompt frontmatter to skip ace-bundle processing

### Changed
- Deduplicate `FrontmatterExtractor.extract` call — extract once and reuse for both bundle check and body fallback

## [0.16.2] - 2026-01-19

### Fixed
- E2E test documentation: update sample-prompt.md to use `bundle:` format instead of legacy `context:` format
- E2E test documentation: correct Base36 ID length from "6-7 characters" to exactly "6 characters" (3 locations)

## [0.16.1] - 2026-01-19

### Changed
- Rename `--context` flag to `--bundle` for clarity (Task 217)
  - CLI: `--context/-c` → `--bundle/-b`
  - CLI: `--no-context` → `--no-bundle`
  - Rename `ContextLoader` class to `BundleLoader`
  - Rename `context_loader.rb` → `bundle_loader.rb`
  - Update all test files and references
  - Add backward compatibility for legacy `"context"` config key

### Technical
- Update test files for renamed flags and classes
- Update E2E test TC-005 to use `--bundle` flag

## [0.16.0] - 2026-01-19

### Changed
- **BREAKING**: Renamed gem from `ace-prep` to `ace-prompt-prep` (Task 217)
  - Gem name: `ace-prep` → `ace-prompt-prep`
  - Module namespace: `Ace::Prep` → `Ace::PromptPrep`
  - Binary: `ace-prep` → `ace-prompt-prep`
  - Config directory: `.ace/prep/` → `.ace/prompt-prep/`
  - Cache directory: `.cache/ace-prep/` → `.cache/ace-prompt-prep/`
  - Follows compound naming pattern like `ace-git-commit`, `ace-git-secrets`
  - Makes semantic meaning explicit: this tool prepares prompts

### Migration
- Rename config directory: `mv .ace/prep .ace/prompt-prep`
- Update command references: `ace-prep` → `ace-prompt-prep`
- Update require statements: `require 'ace/prep'` → `require 'ace/prompt_prep'`
- Old cache at `.cache/ace-prep/` will be orphaned (no automatic migration)

## [0.14.1] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.14.0] - 2026-01-15

### Changed
- **Dependency Migration**: Replaced ace-context dependency with ace-bundle (~> 0.29)
  - Updated gemspec dependency from `ace-context ~> 0.8` to `ace-bundle ~> 0.29`
  - Updated all `require 'ace/context'` to `require 'ace/bundle'`
  - Updated all `Ace::Context` references to `Ace::Bundle`
  - All context loading now uses the ace-bundle API
- Updated CLI help text references from ace-context to ace-bundle

### Technical
- Updated test helpers to use ace-bundle path in load path
- Updated test mocks and stubs to reference Ace::Bundle

## [0.13.2] - 2026-01-10

### Changed
- Use shared `Ace::Core::CLI::DryCli::DefaultRouting` module for CLI routing
  - Removed duplicate routing code in favor of shared implementation
  - Maintains same behavior with less code duplication

## [0.13.1] - 2026-01-10

### Fixed
- Fix CLI default command routing to properly handle flags
  - Removed flawed `!args.first.start_with?("-")` check from routing condition
  - Flags like `--enhance`, `-t` now correctly route to default `process` command
  - Built-in flags (`--help`, `--version`) continue working via KNOWN_COMMANDS

## [0.13.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.11)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command classes in `lib/ace/prompt/commands/`
  - All commands and options maintain parity with Thor implementation

### Added
- `Process` command for prompt processing (default command)
- `Setup` command for workspace initialization

## [0.12.0] - 2026-01-07

### Changed
- **BREAKING**: Archive filenames changed from 14-character timestamps to 6-character Base36 compact IDs
  - Example: `20251129-143000.md` → `i50jj3.md`
  - Existing timestamp-formatted archives remain readable (dual-format support)
  - Archives are git-ignored, so no migration needed for existing files
  - `_previous.md` symlink now points to Base36-formatted archives
- Migrate to Base36 compact IDs for session archiving (via ace-timestamp)
- Renamed TimestampGenerator to SessionIdGenerator (atom refactor)

### Added
- Base36 compact ID format documentation in README with precision notes (~1.85s)

## [0.11.0] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.10.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.9.2] - 2026-01-01

### Changed

* Add thread-safe configuration initialization with Mutex pattern
* Centralize cache paths in gem config file
* Improve error logging with gem prefix and exception class

## [0.9.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.9.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.8.0] - 2025-12-29

### Changed
- Migrate ProjectRootFinder dependency from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.7.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/prompt/config.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

## [0.6.0] - 2025-12-26

### Changed
- **Migrate to ace-git** (Task 140.04): Replace local `GitBranchReader` molecule with `Ace::Git::Molecules::BranchReader` for unified git operations across ace-* gems
- Add ace-git ~> 0.3 dependency for shared git operations

### Added
- Test for nil/failure path when `BranchReader.current_branch` returns nil (graceful fallback to project-level prompt)

### Removed
- `Ace::Prompt::Molecules::GitBranchReader` - functionality now provided by ace-git

## [0.5.1] - 2025-12-09

### Fixed
- Added Questions section back to template structure (now 7 sections)

## [0.5.0] - 2025-12-09

### Added
- New 6-section default template structure: Purpose, Variables, Codebase Structure, Instructions, Workflow, Report
- Updated enhance system prompt output format to match new template sections

## [0.4.0] - 2025-12-01

### Added
- **LLM Enhancement** (Task 121.04, 121.05)
  - `--enhance/-e` flag for LLM-powered prompt improvement
  - `--model` option with built-in aliases: `glite`, `claude`, `haiku`
  - `--temperature` option for LLM creativity control
  - `--system-prompt` option to customize enhancement instructions
  - EnhancementTracker molecule for content-based caching
  - PromptEnhancer organism integrating with ace-llm Ruby API
  - Enhancement archiving with `_e001` suffix pattern
  - System prompt loading via `prompt://` protocol
  - Frontmatter preservation when writing enhanced content back to source

- **Task Folder Support** (Task 121.06)
  - `--task/-t` flag for task-specific prompt directories
  - Branch detection for automatic task resolution (e.g., `121-feature` → task 121)
  - TaskPathResolver atom for task directory lookup
  - Subtask fallback support (121.01 → 121)
  - Integration with ace-taskflow for task path discovery

### Fixed
- Enhancement output now clean markdown (no JSON wrapper, no system prompt echo)
- Enhanced content correctly written back to `the-prompt.md`
- Archive path returns enhanced version, symlink updated properly

## [0.3.0] - 2025-11-28

### Added
- Global configuration via `Ace::Prompt.config` using ace-core config cascade
- Configuration file support at `.ace/prompt/config.yml`
- `context.enabled` config option to control context loading behavior
- Example config at `.ace.example/prompt/config.yml`

### Changed
- CLI now uses `Ace::Prompt.config` instead of custom ConfigLoader molecule
- Removed `ConfigLoader` molecule (replaced by standard ace-* config pattern)
- Simplified `ContextLoader` to pass file path directly to ace-context

## [0.2.0] - 2025-11-28

### Added
- Setup command for template initialization (Task 121.02)
- `ace-prompt-prep setup` - Initialize workspace with template
- Template resolution via `tmpl://` protocol (ace-nav Ruby API)
- TemplateResolver molecule with short form support (`--template bug`)
- TemplateManager molecule for template operations
- PromptInitializer organism using ProjectRootFinder
- Default `the-prompt-base` template with frontmatter
- Protocol registration for ace-nav (`tmpl://ace-prompt-prep/the-prompt-base`)
- `--template` option for custom templates (short form and full URI)
- `--no-archive` and `--force` options to skip archiving
- Automatic directory creation if not exists
- Archive functionality by default (consolidated from reset)
- Comprehensive test suite for new features

### Changed
- Setup uses project root directory (via ProjectRootFinder) instead of home directory (Task 121.08)
- Consolidated reset command into setup (reset removed from CLI)
- Template naming pattern: `the-prompt-{name}.template.md`
- Template resolution uses ace-nav Ruby API (no shell execution)
- TemplateResolver now validates URI format before resolution (rejects spaces)
- Added DEBUG-gated logging for ace-nav LoadError

### Fixed
- CLI exit code handling for Thor Array return (Task 121.08)

## [0.1.0] - 2025-11-28

### Added
- Initial release with basic functionality (Task 121.01)
- Read prompt file from `.cache/ace-prompt-prep/prompts/the-prompt.md`
- Archive with timestamp format `YYYYMMDD-HHMMSS.md`
- Update `_previous.md` symlink to latest archive
- Output to stdout by default
- `--output` option to write to file
- ATOM architecture: atoms, molecules, organisms
- Comprehensive test suite with edge cases


## [0.16.4] - 2026-02-22

### Fixed
- Stripped duplicate command name prefixes from example strings
- Standardized quiet, verbose, debug option descriptions to canonical strings
