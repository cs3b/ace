# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2026-02-07

### Changed

- Rename CLI binary from `ace-e2e-test` to `ace-test-e2e` to align with package name `ace-test-e2e-runner`
- Update all CLI display strings, help text, and usage examples to use `ace-test-e2e`
- Update report metadata agent identifier from `ace-e2e-test` to `ace-test-e2e`
- Update gemspec executable declaration and bin wrapper paths

### Technical

- 189 tests, 509 assertions, 0 failures

## [0.8.2] - 2026-02-07

### Added

- Support comma-separated test IDs in `ace-e2e-test` — e.g. `ace-e2e-test ace-lint 002,007` now discovers and runs multiple tests
- Multi-ID runs use parallel execution with progress display and suite reports (same as package-wide runs)

### Technical

- 189 tests, 509 assertions, 0 failures

## [0.8.1] - 2026-02-07

### Fixed

- Informative error message on test failure — was empty `Error.new("")`, now shows count and IDs of failed tests
- CLI help text `--provider` default now dynamically read from ConfigLoader instead of hardcoded stale value
- Added `pi` to fallback CLI provider arrays in ConfigLoader and SkillPromptBuilder
- Narrowed bare `rescue => _e` to `rescue StandardError => e` with debug logging in SuiteReportWriter

### Technical

- 185 tests, 501 assertions, 0 failures

## [0.8.0] - 2026-02-07

### Added

- **DisplayHelpers** atom — pure formatting module with `status_icon`, `format_elapsed`, `format_duration`, `tc_count_display`, `separator`, and `color` methods
- **SimpleDisplayManager** molecule — default line-by-line display with structured summary block (Duration/Tests/Test cases/Report)
- **ProgressDisplayManager** molecule — ANSI animated table with in-place row updates, running timers, and live footer
- `--progress` CLI option for live animated display mode
- Display helpers test suite (14 tests)

### Changed

- Extracted display logic from TestOrchestrator into pluggable display managers
- Improved output format: status icons (✓/✗), aligned elapsed times, structured summary block with separator
- TestOrchestrator accepts `progress:` parameter for display mode selection
- Test suite updated to 145 tests (from 131)

## [0.7.4] - 2026-02-07

### Fixed

- Remove redundant failure count line from CLI output — enhanced summary already communicates failure counts
- Add error handling rescue in TestExecutor to catch unexpected execution errors gracefully
- Remove hardcoded version string from CLI tests — now matches semver pattern

## [0.7.3] - 2026-02-07

### Added

- **SuiteReportPromptBuilder** atom — pure prompt builder with `SYSTEM_PROMPT` and `build()` for LLM-synthesized suite reports (root causes, friction analysis, suggestions)
- LLM-synthesized suite reports via `Ace::LLM::QueryInterface` in SuiteReportWriter, producing rich analysis instead of mechanical tables
- Configurable `reporting.model` and `reporting.timeout` in `.ace-defaults/e2e-runner/config.yml`
- Report file reading — SuiteReportWriter reads `summary.r.md` and `experience.r.md` from each test's report directory for LLM context

### Changed

- SuiteReportWriter accepts `config:` parameter for model/timeout configuration
- Static template report retained as automatic fallback on LLM failure
- Removed workflow Step 7.5 (agent-written suite report) — now handled by orchestrator's LLM synthesis
- Test suite expanded to 169 tests (from 156)

## [0.7.2] - 2026-02-07

### Added

- Deterministic report paths via `run_id` — orchestrator passes pre-generated timestamp IDs to executors and CLI providers (`--run-id` flag)
- Batch timestamp generation using `ace-timestamp encode --format 50ms --count N` for unique per-test IDs in parallel runs
- Agent metadata reading — `read_agent_result` parses `metadata.yml` from agent-written report directories for authoritative test status and TC counts
- SkillPromptBuilder `--run-id` support in both skill and workflow prompts
- Workflow instruction update documenting `RUN_ID` parameter for deterministic sandbox paths

### Changed

- CLI provider report discovery: uses expected path first (`report_dir_for` with run_id), falls back to glob pattern
- Test suite expanded to 156 tests (from 147)

## [0.7.1] - 2026-02-07

### Added

- Enhanced CLI progress output with `[started]` messages showing test titles
- Test case counts in `[done]` lines: `[N/M done] TEST-ID: PASS 7/8 (duration)`
- Test case counts in single-test `Result:` line: `Result: PASS 7/8`
- Summary line now includes TC stats: `Summary: 2/5 passed | 28/35 test cases (80%)`
- **SuiteReportWriter** molecule: generates `{timestamp}-final-report.md` with frontmatter, summary table, failed test details, and report directory links
- Suite report path printed after package runs: `Report: .cache/ace-test-e2e/{ts}-final-report.md`

### Changed

- Scenarios parsed upfront (before threading) for title display and report generation
- Test suite expanded to 147 tests (from 130)

## [0.7.0] - 2026-02-06

### Added

- Parallel E2E test execution with `--parallel N` CLI option (default: 3)
  - Thread pool with Queue + Mutex for concurrent I/O-bound LLM calls
  - Progress output: `[N/total done] TEST-ID: STATUS (duration)`
  - Results preserve original file order regardless of completion order
- ConfigLoader molecule for centralized configuration access via Ace::Support::Config
  - Class methods: `default_provider`, `default_timeout`, `default_parallel`, `cli_providers`, `skill_aware_providers`, `cli_args_for`
  - Follows ADR-022 configuration cascade (gem defaults → project config → CLI options)
- `ace-support-config` gem dependency for configuration resolution

### Changed

- SkillPromptBuilder refactored from hardcoded constants to config-driven instance pattern
  - Provider lists and CLI args now loaded from config.yml
  - Class methods delegate to lazily-loaded default instance
- CLI options `--provider` and `--timeout` now source defaults from ConfigLoader
- Test suite expanded to 130 tests (from 109)

## [0.6.1] - 2026-02-06

### Added

- Skill-based execution for CLI providers (claude, gemini, codex, opencode)
  - **SkillPromptBuilder** atom: CLI provider detection, skill/workflow prompt building, required CLI args
  - **SkillResultParser** atom: Parses subagent return contract markdown, falls back to JSON
- CLI provider report delegation — agents write reports via workflow, orchestrator skips ReportWriter
- Agent-written report directory discovery in TestOrchestrator

### Changed

- Default provider changed from `google:gemini-2.5-flash` to `claude:sonnet` (skill-aware execution)
- TestExecutor split into `execute_via_skill` (CLI providers) and `execute_via_prompt` (API providers)
- TestOrchestrator skips ReportWriter for CLI providers, looks for agent-written reports on disk
- Test suite expanded to 109 tests (from 71)

## [0.6.0] - 2026-02-06

### Added

- `ace-e2e-test` CLI command for executing E2E tests via LLM providers
- ATOM architecture components:
  - **Atoms:** PromptBuilder, ResultParser
  - **Molecules:** TestDiscoverer, ScenarioParser, TestExecutor (LLM-based), ReportWriter (summary, experience, metadata)
  - **Organisms:** TestOrchestrator (single and package-wide test execution)
  - **Models:** TestScenario, TestResult
- CLI with dry-cli: `ace-e2e-test PACKAGE [TEST_ID] [OPTIONS]`
- `--provider` option for LLM provider selection (default: google:gemini-2.5-flash)
- `--cli-args` passthrough for CLI-based LLM providers
- `--timeout` option for per-test timeout configuration
- Report generation following existing report path contract
- `exe/ace-e2e-test` executable and `bin/ace-e2e-test` monorepo wrapper
- Comprehensive test suite (71 tests) covering atoms, molecules, organisms, models, and CLI
- Injectable executor in TestOrchestrator for testability
- `TestResult#with_report_dir` for immutable copy-with-modification
- Injectable timestamp generator in TestOrchestrator for testability

### Changed

- Added `dry-cli`, `ace-support-core`, and `ace-llm` as gem dependencies

## [0.5.1] - 2026-02-04

### Added

- CLI-Based Testing Requirement section to create-e2e-test workflow documenting that E2E tests must test through CLI interface, not library imports

## [0.5.0] - 2026-02-01

### Added

- Sandbox isolation checkpoint with 3-check verification (path, git remotes, project markers)
- Standard Setup Script section as authoritative copy-executable source for sandbox setup
- Expected Variables documentation (PROJECT_ROOT, TEST_DIR, REPORTS_DIR, TIMESTAMP_ID)

### Changed

- Consolidated sandbox setup by moving `e2e-sandbox-setup.wf.md` into this package
- Renamed workflow to `setup-e2e-sandbox.wf.md` following verb-first convention
- Updated `run-e2e-test.wf.md` to delegate sandbox setup to `wfi://setup-e2e-sandbox`
- Removed ~30 lines of duplicated inline sandbox logic from run-e2e-test workflow
- Renamed skill from `ace_e2e-sandbox-setup` to `ace_setup-e2e-sandbox`

## [0.4.1] - 2026-01-30

### Fixed

- Updated report path documentation from sibling pattern to subfolder pattern (`-reports/`)
- Removed incorrect `artifacts/` subdirectory from test data path examples

### Technical

- Added pre-creation sandbox verification gate to workflow instructions
- Enhanced directory structure diagrams for consistency across guides and templates

## [0.4.0] - 2026-01-29

### Added

- Parallel E2E test execution with subagents via `/ace:run-e2e-tests` orchestrator skill
- Suite-level report aggregation for multi-test runs
- Subagent return contract for structured result passing between orchestrator and workers

### Changed

- Enhanced sandbox naming with test ID inclusion (`{timestamp}-{package}-{test-id}/`)
- Moved reports outside sandbox as sibling files (`.summary.r.md`, `.experience.r.md`, `.metadata.yml`)

### Breaking Changes

- **Cache directory renamed**: `.cache/test-e2e/` → `.cache/ace-test-e2e/`. External scripts referencing the old path will need updating.

## [0.3.0] - 2026-01-29

### Added

- Persistent test reports (`test-report.md`) capturing pass/fail status, test case details, and environment information
- Agent experience reports (`agent-experience-report.md`) documenting friction points, root cause analysis, and improvement suggestions
- Test execution metadata (`metadata.yml`) storing run-specific details like duration, Git context, and tool versions
- ace-taskflow fixture template for standardized taskflow structure creation in E2E tests

### Changed

- Updated test environment structure to use `artifacts/` subdirectory for test data organization
- Enhanced E2E testing guidelines with emphasis on error path coverage and negative test cases
- Improved test templates with error testing best practices and reviewer checklist
- Updated test execution workflow to automatically generate and persist reports at end of each run

## [0.2.1] - 2026-01-22

### Added

- Container-based E2E test isolation guide for macOS (Lima, OrbStack support)
- Template updates for containerized test scenarios

## [0.2.0] - 2026-01-19

### Added

- E2E test management skills for lifecycle orchestration:
  - `/ace:review-e2e-tests` - Analyze test health, coverage gaps, and outdated scenarios
  - `/ace:create-e2e-test` - Create new test scenarios from template
  - `/ace:manage-e2e-tests` - Orchestrate full lifecycle (review, create, run)
- Workflow instructions for all three new skills
- Protocol source registrations (wfi://, guide://, tmpl://)
- PROJECT_ROOT detection in workflow and template
- Gem entry point for programmatic access
- Expanded best practices section with learnings:
  - Environment setup guidance (PROJECT_ROOT capture)
  - Tool version manager workarounds (mise shim handling)
  - Test data and cleanup patterns

### Changed

- Renamed package from `ace-support-test-manual` to `ace-test-e2e-runner`
- Renamed workflow from `run-manual-test` to `run-e2e-test`
- Renamed test directory convention from `test/scenarios/` to `test/e2e/`
- Renamed cache directory from `.cache/test-manual/` to `.cache/test-e2e/`
- Made `PACKAGE` argument optional (defaults to current directory detection)
- Made `TEST_ID` argument optional (runs all tests in package when omitted)
- Cleanup is now optional and configurable via `cleanup.enabled` setting

### Improved

- Documentation for mise shim workarounds in TC-003
- README clarity on package purpose and usage

## [0.1.0] - 2026-01-18

### Added

- Initial package structure for E2E test support
- Test scenario template (`test-e2e.template.md`)
- Workflow for executing E2E tests (`run-e2e-test.wf.md`)
- Guide documenting E2E testing conventions (`e2e-testing.g.md`)
- Default configuration for test paths and patterns
- Skill for invoking E2E tests (`/ace:run-e2e-test`)
