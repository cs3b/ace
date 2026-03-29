# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

## [0.27.6] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.27.5] - 2026-03-29

### Technical
- Register package-level `.ace-defaults` skill-sources for ace-lint to enable canonical skill discovery in fresh installs.


## [0.27.4] - 2026-03-29

### Fixed
- **ace-lint v0.27.4**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.27.3] - 2026-03-26

### Fixed
- Corrected `--auto-fix --dry-run` file-count reporting to count unique lint result file paths instead of parsing formatted issue strings.

### Changed
- Extracted deterministic and agent-assisted auto-fix orchestration from the lint CLI command into `Organisms::AutoFixOrchestrator`.
- Centralized `ace-llm` test load-path setup in `test_helper` for agent-fix command tests.

### Technical
- Documented the frontmatter-prefix reconstruction contract in `MarkdownSurgicalFixer`.
- Marked internal structural-change guardrail helpers in `KramdownFormatter` as private class methods.

## [0.27.2] - 2026-03-26

### Fixed
- Made `--auto-fix-with-agent` apply concrete file edits from model output and fail fast when no editable changes are returned.
- Prevented stale pre-agent lint errors from being carried into post-agent validation results.
- Hardened markdown formatting guardrails to treat any HTML attribute-count change (increase or decrease) as structural risk.

### Changed
- Added an explicit warning before agent-assisted fixes that full file contents are sent to the selected model.
- Added payload-size limits for agent-fix prompt file content to avoid oversized requests.
- Refactored markdown fence-state handling to use a shared fence-aware line iterator across linter and fixer paths.

### Technical
- Added non-dry-run command tests for agent fix mode success and no-edit failure behavior.
- Added formatter coverage for HTML attribute-removal structural change detection.

## [0.27.1] - 2026-03-26

### Fixed
- Preserved markdown link destinations containing nested parentheses during typography-safe surgical fixes.
- Hardened agent prompt construction for `--auto-fix-with-agent` by using dynamic code fences that remain valid when file content already contains fenced blocks.

### Changed
- Updated `--auto-fix --dry-run` preview wording to avoid implying every issue is deterministically fixable.
- Aligned `--auto-fix` exit behavior with normal lint semantics: warning-only results now exit successfully while error results still fail.

### Technical
- Optimized `run_auto_fix` to skip redundant fix-mode passes for non-fixable file types while preserving final lint validation.

## [0.27.0] - 2026-03-26

### Added
- Added deterministic repair flags to `ace-lint`: `--auto-fix`, `--auto-fix-with-agent`, `--dry-run` (`-n`), and `--model`.
- Added agent-assisted lint repair flow that builds a structured prompt with remaining violations and full file content for affected files.
- Added command-level coverage for auto-fix dry-run, alias parity, warning precedence, and exit semantics.

### Fixed
- Fixed auto-fix exit behavior to return non-zero when violations remain after deterministic repair.
- Fixed help and docs drift by aligning CLI docs/examples and E2E fix-mode guidance with the new auto-fix contract.

### Changed
- Changed `--fix` semantics to an alias of `--auto-fix` (deterministic fix then re-lint).
- Changed auto-fix modes to ignore `--format` with an explicit warning.
- Added `lint.doctor_agent_model` default configuration for agent-assisted repair model selection.

### Technical
- Expanded task specification verification checklist evidence for the auto-fix and agent-assisted workflow implementation.

## [0.26.0] - 2026-03-26

### Added
- Added `MarkdownSurgicalFixer` for markdown-family `--fix` operations that apply targeted line edits without full document reserialization.
- Added structural guardrails for markdown `--format` to skip unsafe kramdown rewrites when frontmatter, code-block, table, or HTML-attribute drift is detected.

### Fixed
- Fixed markdown style checks to ignore heading/list spacing checks inside fenced code blocks.
- Added trailing whitespace detection for markdown style validation.

### Changed
- Changed markdown-family `--fix` behavior (`markdown`, `skill`, `workflow`, `agent`) to surgical edits, with `--fix --format` executing surgical fix first then guarded format.
- Updated CLI/help and usage docs to describe surgical `--fix` semantics and guarded `--format` behavior.

### Technical
- Expanded ace-lint tests for surgical fixer behavior, formatter guardrails, and orchestrator ordering.

## [0.25.0] - 2026-03-23

### Fixed
- Aligned gemspec summary to "Ruby-native" matching README tagline (was "Ruby-only").

### Changed
- Added example output section to `docs/usage.md` showing pass, fail, and doctor diagnostics.
- Rewrote demo tape with separate named scenes and real package files instead of sandbox fixtures.
- Re-recorded getting-started demo GIF.

## [0.24.3] - 2026-03-23

### Changed
- Refreshed `README.md` to align with the standardized package README layout (quick links, use cases, and canonical skill listing).

## [0.24.2] - 2026-03-22

### Changed
- Replaced placeholder commands in `docs/demo/ace-lint-getting-started.tape.yml` with real `ace-lint` getting-started command flow.

## [0.24.1] - 2026-03-22

### Fixed
- Reused shared `Ace::Core::Molecules::FrontmatterFreePolicy` for frontmatter-free config resolution and glob matching to keep lint behavior aligned with docs discovery.

## [0.24.0] - 2026-03-22

### Added
- Frontmatter-free file exemption in `FrontmatterValidator` — files matching configured `frontmatter_free` patterns (default: `**/README.md`) pass validation without requiring YAML frontmatter.

## [0.23.1] - 2026-03-22

### Changed
- Remove `mise exec --` wrapper from test fixture strings.

## [0.23.0] - 2026-03-22

### Changed
- Rewrote README into a landing page focused on value, integrations, and doc navigation.
- Added tutorial and reference docs: `docs/getting-started.md`, `docs/usage.md`, and `docs/handbook.md`.
- Added demo artifacts under `docs/demo/` and aligned gemspec messaging with the new Ruby-only positioning.

## [0.22.1] - 2026-03-21

### Fixed
- Restored malformed YAML in `test/fixtures/invalid.md` so invalid frontmatter coverage still exercises a genuinely broken fixture.

## [0.22.0] - 2026-03-18

### Changed
- Refined TS-LINT-001 E2E guidance by separating verifier validation order from explicit checks and clarifying config-routing fixture usage.

## [0.21.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.21.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.20.4] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.20.3] - 2026-03-13

### Changed
- Updated canonical lint skills to explicitly run bundled workflows in the current project and execute them end-to-end.

### Technical
- Updated markdown-linter fixture coverage for the new compact canonical skill execution template.

## [0.20.2] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-lint-run` skill so provider projections now inherit the canonical skill body unchanged.

## [0.20.1] - 2026-03-12

### Changed
- Updated README examples to reference current handbook skill and workflow paths instead of legacy provider-local example locations.

## [0.20.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-lint-run` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

## [0.19.1] - 2026-03-12

### Technical
- Expanded canonical skill validation fixtures to cover provider-specific execution overrides such as `context: fork` and provider model hints under `integration.providers.<provider>.frontmatter`.

## [0.19.0] - 2026-03-10

### Added
- Added validation support for `integration.targets` and `integration.providers.<provider>.frontmatter` in canonical skill files.

### Changed
- Expanded canonical skill lint validation to recognize additional ACE CLI prefixes and handbook editing tools used by migrated package skills.


## [0.18.1] - 2026-03-10

### Fixed
- Ignored YAML frontmatter when running markdown lint checks so canonical `SKILL.md` metadata no longer triggers false heading/link warnings.
- Added `ace-idea` to the known Bash prefix allowlist for canonical skill validation.

### Technical
- Added regression coverage for frontmatter-aware markdown linting and real ACE CLI prefix validation.

## [0.18.0] - 2026-03-09

### Added
- Canonical SKILL schema validation now requires `skill.kind` and `skill.execution.workflow`.
- Added nested schema checks for canonical fields and actionable errors for unknown `skill`/`skill.execution` keys.

### Changed
- Skill name validation now accepts canonical `as-*` names in addition to legacy `ace-*`.
- `known_bash_prefixes` includes `ace-assign` and `ace-b36ts` for canonical skill validation coverage.

### Fixed
- Reject `assign` metadata for `capability` skills and detect duplicate `assign.phases[].name` values.
- `SkillSchemaLoader` now loads fallback defaults reliably by requiring `date` during YAML safe-load.

## [0.17.1] - 2026-03-04

### Technical
- Updated cache cleanup guidance comments to reference `.ace-local/`.


## [0.17.0] - 2026-03-04

### Changed
- Default report directory migrated from `.cache/ace-lint` to `.ace-local/lint`

## [0.16.1] - 2026-02-23

### Changed
- Renamed YamlParser atom to YamlValidator to reflect its validation purpose
- Added backward-compatibility alias (YamlParser = YamlValidator)

### Technical
- Updated internal dependency version constraints to current releases

## [0.16.0] - 2026-02-23

### Changed
- **BREAKING**: Drop multi-command Registry in favor of single-command CLI pattern (ADR-024)
  - `ace-lint lint file.md` → `ace-lint file.md`
  - `ace-lint doctor` → `ace-lint --doctor`
  - `ace-lint doctor --verbose` → `ace-lint --doctor-verbose`
- Add `--version`, `--doctor`, `--doctor-verbose` options to main command
- Delete separate Doctor command class; logic absorbed into Lint command

## [0.15.14] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.15.13] - 2026-02-21

### Changed
- Update skill name validation pattern to colon-free convention (`ace_domain_action` format)
- Update test fixtures and validator tests for new skill naming convention

## [0.15.12] - 2026-02-19

### Technical
- Namespace workflow instructions into lint/ subdirectory with updated wfi:// URIs

## [0.15.11] - 2026-02-07

### Changed
- Further consolidate MT-LINT-004 bash blocks (10→7) and remove no-op cleanup block

## [0.15.10] - 2026-02-07

### Changed
- Consolidate bash blocks in E2E tests to reduce LLM round-trips and avoid timeouts
  - MT-LINT-002: 21→11 blocks (merge jq queries, verification steps)
  - MT-LINT-004: 17→10 blocks (merge exit code checks, report verification)
  - MT-LINT-007: 10→7 blocks (merge lint calls, config+lint steps)

## [0.15.9] - 2026-02-07

### Changed
- Split E2E tests for parallel execution: 5 files (36 cases) → 8 files (31 cases)
  - MT-LINT-001: 8→5 cases (validator overrides extracted to MT-LINT-007)
  - MT-LINT-002: 9→5 cases (markdown reports extracted to MT-LINT-006, --no-report duplicate removed)
  - MT-LINT-004: 7→5 cases (report default and --validators duplicates removed)
  - MT-LINT-005: 8→4 cases (modes/exit codes extracted to MT-LINT-008)
- Remove 5 duplicate test cases across files (--no-report, --validators override, report generation)

### Added
- MT-LINT-006: Report markdown files (ok.md, fixed.md, pending.md) — 3 cases
- MT-LINT-007: Validator configuration overrides (CLI, config, group routing) — 3 cases
- MT-LINT-008: Doctor modes and exit codes (quiet, verbose, healthy, syntax error) — 4 cases

## [0.15.8] - 2026-02-07

### Fixed
- Fix single-file `lint()` success inconsistency with `lint_batch()` — convention/warning-only offenses now return `success: true` instead of relying on runner exit status (which exits non-zero for any offense)

## [0.15.7] - 2026-02-07

### Fixed
- Fix E2E test MT-LINT-004 TC-002 fixture: use `syntax_error.rb` instead of `style_issues.rb` which only has convention/warning-severity offenses (exit 0)
- Add clarifying note to MT-LINT-002 TC-009 explaining severity-to-exit-code behavior

## [0.15.6] - 2026-02-07

### Fixed
- Fix `formatted` flag in RubyLinter to reflect actual file changes instead of just the fix option
  - Files are now marked as `formatted: true` only when their content actually changes
  - Previously, all files processed with `--fix` were incorrectly marked as formatted
  - E2E test improvements: fixed path extraction (`tr -d '/'` → `sed 's|/$||'`), added explicit PASS/FAIL echoes for weaker models
  - TC-002 in MT-LINT-004 now uses `style_issues.rb` instead of `invalid.md` (which only had warnings)

## [0.15.5] - 2026-02-07

### Fixed

- Update E2E tests (MT-LINT-001 through MT-LINT-005) with verified results and improved test cases
  - TC-002: Test fix mode instead of lint-only for style issues
  - TC-005: Test fix mode categorization with passed/fixed results
  - TC-008: Use syntax error file for pending.md testing (unfixable errors)
  - MT-LINT-004: Simplify invalid markdown fixture, remove unsupported TC-005 (--output flag)
  - MT-LINT-005: Fix invalid config fixtures with proper git init and file paths

## [0.15.4] - 2026-02-07

### Fixed
- Ensure help commands exit with status 0
- Migrate CLI and doctor integration tests to E2E, optimize with subprocess stubs

## [0.15.3] - 2026-01-31

### Fixed
- Eliminate random slow tests by pre-warming availability caches and ensuring all tests stub availability checks
  - Moved cache resets from test setup into stub helper methods
  - Added dual-runner cache pre-population in stub helpers
  - Added `available?` stubs to tests that only stubbed `:run`
  - Test suite now consistently runs in ~60-70ms (previously varied 60ms-1.6s randomly)

## [0.15.2] - 2026-01-31

### Performance
- Stub subprocess calls in slow tests to avoid real system() calls (task 251)
  - Tests now stub `available?` method instead of running real `rubocop --version` etc.
  - Test suite time reduced from ~2.1s to ~69ms
  - Affected tests: `standardrb_runner_test.rb`, `rubocop_runner_test.rb`, `validator_registry_test.rb`, `lint_doctor_test.rb`

## [0.15.1] - 2026-01-31

### Performance
- Moved CLI integration tests to E2E test suite (task 251.03)
  - Created `test/e2e/MT-LINT-004-cli-exit-codes.mt.md` for CLI behavior tests
  - Created `test/e2e/MT-LINT-005-doctor-command.mt.md` for doctor command tests
  - Removed `test/integration/cli_integration_test.rb` (7 tests)
  - Removed `test/integration/doctor_integration_test.rb` (8 tests)
  - Tests now run via `/ace:run-e2e-test ace-lint MT-LINT-004` and `MT-LINT-005`
  - Existing atom/molecule tests already use Open3 mocks (no additional mocking needed)

## [0.14.0] - 2026-01-22

### Added
- Typography validation for markdown files (task 218.10)
  - Detects em-dash characters (—) with suggestion to use double hyphens (--)
  - Detects smart quotes (", ", ', ') with suggestion to use ASCII quotes
  - Skips content inside fenced code blocks and inline code spans
  - Configurable severity levels (error/warn/off) in `.ace/lint/markdown.yml`
  - New `markdown_config` method following ADR-022 configuration cascade pattern
  - Default configuration in `.ace-defaults/lint/markdown.yml`

## [0.13.0] - 2026-01-22

### Added
- Skill, workflow, and agent file validation (task 226)
  - New `SkillSchemaLoader` atom for loading validation schemas from YAML
  - New `AllowedToolsValidator` atom for validating tool declarations against known Claude tools
  - New `CommentValidator` atom for verifying HTML-style markdown comment structure
  - New `SkillValidator` molecule orchestrating complete skill/workflow/agent validation
  - Extended `TypeDetector` to recognize SKILL.md, *.wf.md, and *.ag.md files
  - Default validation schema in `.ace-defaults/lint/skills.yml`
  - Auto-routing in `LintOrchestrator` for skill/workflow/agent file types

### Technical
- Validation checks: required frontmatter fields, allowed-tools against known tools, comment block structure
- Support for configurable validation rules per file type (skill, workflow, agent)

## [0.12.0] - 2026-01-19

### Added
- Three-file markdown report system for workflow delegation
  - `ok.md` - Lists files that passed with no issues
  - `fixed.md` - Lists files that were auto-fixed (only when --fix used)
  - `pending.md` - Groups issues by file with checkboxes for tracking
- Report directory output shows generated files with counts
- JSON report generation with timestamped directories

### Changed
- Report output format now shows directory with file list instead of individual paths
- Pending issues grouped by file with issue counts for better readability

### Fixed
- Show concise summary when report is generated (suppress per-file output)

### Technical
- Thread-safety improvements to ConfigLocator cache
- Code style updates with RuboCop modern Ruby syntax
- Require path and dependency consistency updates

## [0.11.0] - 2026-01-18

### Added
- Multi-validator architecture for running multiple linters per file type (task 215.03)
  - New `PatternMatcher` atom for glob pattern matching with specificity scoring
  - New `ValidatorRegistry` atom for mapping tool names to runner classes
  - New `ConfigLocator` atom for config file resolution with precedence rules
  - New `GroupResolver` molecule for pattern-based validator group resolution
  - New `ValidatorChain` molecule for executing multiple validators with deduplication
  - New `LintDoctor` organism for configuration health diagnostics
  - New `ace-lint doctor` CLI command for checking configuration health
  - New `--validators` CLI flag for specifying validators (e.g., `--validators standardrb,rubocop`)
  - Pattern-based groups configuration in `ruby.yml` for different validators per file pattern
  - Result deduplication when running multiple validators on same files

### Changed
- Updated `RubyLinter` to support ValidatorChain for multi-validator execution
- Updated `LintOrchestrator` with group-aware routing for Ruby files
- Updated `ruby.yml` configuration schema with groups-based validator configuration

## [0.10.0] - 2026-01-17

### Added
- RuboCop fallback support for Ruby linting when StandardRB is unavailable (task 216)
  - Automatic tool detection: tries StandardRB first, falls back to RuboCop
  - New `RuboCopRunner` atom mirroring `StandardrbRunner` interface
  - Updated `RubyLinter` molecule with fallback logic
  - Minimal `.rubocop.yml` configuration in `.ace-defaults/lint/`
  - Clear error messages when neither tool is installed

### Changed
- Updated README with Ruby linting fallback documentation
  - Documented StandardRB as preferred (zero-config) option
  - Documented RuboCop as automatic fallback
  - Added troubleshooting section for "No Ruby linter available" message
- Updated `.ace-defaults/lint/ruby.yml` with `fallback_linter: rubocop` configuration

## [0.9.1] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files (task 206)

## [0.9.0] - 2026-01-15

### Added
- Ruby file linting support using StandardRB (task 215)
  - Auto-detects .rb, .rake, and .gemspec files
  - Supports --fix flag for auto-formatting with StandardRB
  - Helpful error message when StandardRB is not installed
  - Configuration in `.ace-defaults/lint/ruby.yml` following ADR-022 pattern

### Changed
- Skip unsupported file types instead of reporting errors
  - Added `skipped` status to LintResult model
  - Updated ResultReporter to display skipped files with ⊘ symbol
  - Unknown file types are now gracefully skipped with summary count
- Renamed ace-config dependency to ace-support-config

### Technical
- Migrated CLI to Hanami pattern (task 213)
- Eliminated wrapper pattern in CLI command

## [0.8.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Lint` dry-cli command class
  - Deleted `lint_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.8.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.03)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - User-facing command interface remains identical
  - All options and behavior preserved
  - Improved internal command structure and testability

## [0.7.0] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.6.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.5.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Support::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.5.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.4.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/lint/config.yml` and `.ace.example/lint/kramdown.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

## [0.3.3] - 2025-11-16

### Changed

- **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  - Ensures compatibility with latest PromptCacheManager features
  - Aligns with standardized dependency versions across ACE ecosystem

## [0.3.2] - 2025-11-11

### Fixed
- Address code review feedback on documentation and hygiene
- Fix test discovery and execution issues with ace-test integration

### Changed
- Update test structure to work with ace-test smoke pattern
- Rename ace-core and ace-test-support dependencies

## 0.3.0 - 2025-10-13

### Changed

* **BREAKING**: Configuration structure changed to support multiple tool configs
  - General config: `.ace/lint/config.yml`
  - Kramdown config: `.ace/lint/kramdown.yml` (flat structure, no nesting)
  - Future tool configs: `.ace/lint/yaml.yml`, etc.
* **BREAKING**: Removed custom ConfigLoader - now uses ace-core config cascade
* Configuration loaded via `Ace::Core.config.get('ace', 'lint', 'kramdown')`
* README updated with comprehensive configuration documentation
* Removed invented CONFIGURATION.md file (not used by other ace-* gems)

### Added

* Added ace-core dependency (~> 0.9) for config management
* Added `Ace::Lint.kramdown_config` method for tool-specific config
* Configuration examples in `.ace.example/lint/` directory
* Documentation for multi-tool config pattern

### Fixed

* Config loading now follows standard ace-* gem patterns
* No more hardcoded config file paths
* Proper config cascade: defaults → user home → project → CLI options

## 0.2.0 - 2025-10-13

### Changed

* **BREAKING**: Configuration moved from `.ace-lint.yml` to `.ace/lint/kramdown.yml`
* ConfigLoader now follows ace-* pattern with standard `.ace/` directory structure
* Configuration is now explicit - users see and edit kramdown settings directly
* All kramdown options now visible in config file (no hidden defaults)

### Added

* Configuration cascade: `.ace/lint/kramdown.yml` (project) → `~/.ace/lint/kramdown.yml` (user)
* Full kramdown configuration support in `.ace/lint/kramdown.yml`
* Updated CONFIGURATION.md with proper ace-* patterns and examples

### Fixed

* Removed `.ace-lint.yml` files (wrong location)
* Config now follows same pattern as other ace-* gems (e.g., `.ace/llm/providers/*.yml`)

## 0.1.3 - 2025-10-13

### Fixed

* Corrected kramdown warning handling - warnings are strings, not hashes
* Fixed parsing error that occurred with some markdown documents
* All kramdown warnings are now properly displayed as informational messages

## 0.1.2 - 2025-10-13

### Added

* Added markdown style checks with warnings for common issues:
  * Missing blank line after headings
  * Missing blank line before/after lists
  * Missing blank line before/after code blocks
* Warnings are displayed but don't fail validation (only errors fail)

### Changed

* Made `lint` the default command - can now use `ace-lint file.md` instead of `ace-lint lint file.md`
* Commands `version` and `help` still work as before

## [0.3.1] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.1.1] - 2025-10-13

### Fixed

* Fixed binstub availability by adding ace-lint to root Gemfile
* Committed all gem files to git so gemspec can detect executables
* ace-lint command now available in workspace after bundle install

## [0.1.0][4] - 2025-10-13

### Added

* Initial release of ace-lint standalone gem
* Ruby-only linting stack (kramdown + Psych, no Node.js or Python)
* Markdown validation via kramdown with GitHub Flavored Markdown support
* YAML validation via Psych (Ruby built-in)
* Frontmatter validation with schema checking
* Auto-fix/format support with kramdown formatter
* Colorized terminal output (green ✓, red ✗, yellow ⚠)
* CLI interface with Thor (`ace-lint lint [FILES] [OPTIONS]`)
* Command options: --fix, --format, --type, --quiet, --line-width
* Proper exit codes (0 = success, 1 = failures) for CI/CD integration
* Subprocess-callable interface for other ace-\* gems
* ATOM architecture (atoms, molecules, organisms, models, commands)
* Comprehensive README with usage examples and integration patterns
* Test fixtures for validation testing

### Technical Details

* Dependencies: kramdown ~> 2.4, kramdown-parser-gfm ~> 1.1, thor ~> 1.3, colorize ~> 1.1
* Ruby version requirement: >= 3.1.0
* Follows ace-\* gem conventions and ATOM pattern
* RuboCop compliant with auto-corrections applied



[1]: https://keepachangelog.com/en/1.0.0/
[2]: https://semver.org/spec/v2.0.0.html
[3]: https://github.com/your-org/ace-lint/compare/v0.1.0...v0.1.1
[4]: https://github.com/your-org/ace-lint/releases/tag/v0.1.0


## [0.15.15] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
