# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.16.0] - 2026-02-12

### Added

- **TS-format E2E test structure** — complete infrastructure for per-TC test scenarios in `TS-*/scenario.yml` directories with separate test case files
- **TC-level execution pipeline** — independent test case execution enabling targeted re-runs of failed TCs only
- **Setup CLI subcommand** — `ace-test-e2e setup <package> <test-id>` for deterministic Ruby-based sandbox setup before LLM handoff
- **ScenarioLoader molecule** — loads TS-format scenario directories with scenario.yml, test cases, and fixtures
- **TestCase model** — data model for individual test cases with tc_id, content, and file metadata

### Changed

- **Remove legacy .mt.md support** — deleted ScenarioParser molecule; all test discovery and execution now uses TS-format directory structure only
- **Dual-mode → Single-mode discovery** — TestDiscoverer simplified to find only `TS-*/scenario.yml` patterns (no more `.mt.md` files)
- **Simplified extract methods** — `extract_test_name`, `extract_test_id`, `file_matches_test_id?` now work with directory names only
- **Config updated** — `discovery` pattern changed from `**/*.mt.md` to `TS-*/scenario.yml`, `test_id.pattern` from `MT-*` to `TS-*`

### Fixed

- **ScenarioParser TS-format fallback** — fixed delegation to ScenarioLoader for scenario.yml files
- **Display managers** — suite progress/simple display managers correctly extract test names from directory paths

## [0.15.1] - 2026-02-11

### Fixed

- Expand relative PROJECT_ROOT_PATH to absolute sandbox path in test orchestrator,
  ensuring agents running from monorepo root can find sandbox resources correctly

## [0.15.0] - 2026-02-11

### Added

- **fix-e2e-tests workflow** (v1.0) — new workflow for systematically diagnosing and fixing failing E2E tests with three-way root cause classification: application code issue, test definition issue, or runner/infrastructure issue
- **fix-e2e-tests skill** — `/ace:fix-e2e-tests` skill wrapping the new workflow, with cost-conscious re-run strategy and iterative fix loop

### Fixed

- Apply code review feedback from PR #197

## [0.14.0] - 2026-02-11

### Added

- **3-stage E2E pipeline** — redesigned E2E test lifecycle as explicit review → plan → rewrite pipeline, replacing the monolithic manage workflow
- **plan-e2e-changes workflow** (v1.0) — new Stage 2 workflow that analyzes coverage matrix and produces concrete change plans with REMOVE/KEEP/MODIFY/CONSOLIDATE/ADD classifications
- **rewrite-e2e-tests workflow** (v1.0) — new Stage 3 workflow that executes change plans: deletes, creates, modifies, and consolidates E2E test scenarios
- **TS-format display support** — `SuiteProgressDisplayManager` and `SuiteSimpleDisplayManager` now extract test names from TS-format `scenario.yml` paths (directory name) in addition to MT-format `.mt.md` paths
- **Metadata-based result override** — `SuiteOrchestrator` reads agent-written `metadata.yml` to correct subprocess exit code mismatches, matching `TestOrchestrator#read_agent_result` behavior

### Changed

- **review-e2e-tests workflow** (v1.2 → v2.0) — rewritten from health report generator to deep exploration producing a coverage matrix (functionality × unit tests × E2E), with overlap analysis, gap analysis, and consolidation opportunities
- **manage-e2e-tests workflow** (v1.2 → v2.0) — rewritten from 370-line monolithic flow to ~170-line lightweight orchestrator chaining the 3 pipeline stages with user confirmation gate
- **TC classifications** — replaced old ARCHIVE/CREATE/UPDATE/KEEP categories with REMOVE/KEEP/MODIFY/CONSOLIDATE/ADD for clearer intent

## [0.13.0] - 2026-02-11

### Added

- **E2E Value Gate** — embedded decision framework across all E2E testing documentation: guide, template, and workflows now require justification that each TC tests behavior needing real binary + real tools + real filesystem (not coverable by unit tests)
- **Coverage overlap analysis** — `review-e2e-tests.wf.md` (v1.2) includes new Step 5 to compare E2E TC coverage against unit test assertions, classifying overlap as none/partial/full with archival recommendations
- **CONSOLIDATE management action** — `manage-e2e-tests.wf.md` (v1.2) adds a new category for merging TCs that share CLI invocations, alongside archive/create/update/keep

### Changed

- **E2E testing guide** (v1.5) — replaced vague "When to Use" criteria with concrete Value Gate question, added Cost and Scope section (cost per TC, healthy 2-5 TCs/scenario, consolidation rule), added Coverage Overlap Review to Maintenance
- **Create workflow** (v1.2) — inserted E2E Value Gate Check as Step 7 (unit test overlap check before TC generation), added COST-AWARE rules to TC generation guidelines
- **Review workflow** (v1.2) — added overlap metrics to health report summary table and new Coverage Overlap section in report template
- **Manage workflow** (v1.2) — expanded ARCHIVE criteria to include unit test overlap and presentation-only TCs
- **E2E test template** — added E2E Justification section with unit test coverage checklist, TC consolidation guidance comment, and cost/value reminders

## [0.12.4] - 2026-02-11

### Added

- **TC fidelity validator** — new `TcFidelityValidator` atom detects when agents invent test cases instead of executing defined `.tc.md` files, flagging results as error when reported TC count doesn't match expected
- **Suite report post-validation** — `SuiteReportWriter` now validates LLM-generated "Overall" line against deterministic totals and replaces hallucinated aggregates with correct values

### Changed

- **Workflow TC discovery guardrails** — `execute-e2e-test.wf.md` now requires explicit TC listing before execution, includes a TC fidelity rule forbidding invented test cases, and adds a self-check step to verify result count matches discovery

## [0.12.3] - 2026-02-11

### Changed

- **Handbook TS-format support** — updated `run-e2e-test.wf.md` (v1.6), `run-e2e-tests.wf.md` (v1.1), `review-e2e-tests.wf.md` (v1.1), `create-e2e-test.wf.md` (v1.1), and `manage-e2e-tests.wf.md` (v1.1) to discover and reference both MT-format (`.mt.md`) and TS-format (`scenario.yml` / `.tc.md`) test scenarios
- **`create-e2e-test.wf.md`** — added `--format mt|ts` argument for creating TS-format scenario directories with `scenario.yml` and individual TC files
- **README and e2e-testing guide** — updated documentation to cover dual-format architecture, TS-format directory structure, and per-TC execution

## [0.12.2] - 2026-02-11

### Added

- **`execute-e2e-test.wf.md` workflow** — focused execution-only workflow for pre-populated sandboxes, handling test case discovery, execution, and reporting without setup steps

### Changed

- **SKILL.md conditional routing** — skill now routes to `wfi://execute-e2e-test` when `--sandbox` is present, `wfi://run-e2e-test` otherwise
- **Unified skill invocation for all CLI providers** — removed `skill_aware?` distinction; all CLI providers (claude, gemini, codex, etc.) now use `/ace:run-e2e-test` skill invocation instead of embedded workflow prompts
- **Simplified `SkillPromptBuilder`** (273 → 113 lines) — removed `build_workflow_prompt`, `build_tc_workflow_prompt`, `system_prompt_for`, and `skill_aware?` methods
- **Simplified `TestExecutor`** (347 → 296 lines) — removed `skill_aware?` branching, `load_workflow_content`, and `find_project_root` dead methods
- **Cleaned `run-e2e-test.wf.md`** (v1.5) — removed sandbox mode section and skip guards (now handled by `execute-e2e-test.wf.md`)

### Removed

- `skill_aware` config key from `config.yml` and `ConfigLoader#skill_aware_providers`

## [0.12.1] - 2026-02-11

### Added

- **Scenario-level sandbox pre-setup** — `TestOrchestrator` runs `SetupExecutor` in Ruby before LLM invocation for TS-format scenarios, passing `sandbox_path` and `env_vars` to skip deterministic setup steps in the LLM
- **Sandbox/env params in prompt builders** — `SkillPromptBuilder#build_skill_prompt` and `#build_workflow_prompt` accept `sandbox_path:` and `env_vars:` kwargs, appending `--sandbox` and `--env` flags
- **Workflow sandbox mode documentation** — `run-e2e-test.wf.md` documents scenario-level sandbox mode with `--sandbox` and `--env` arguments, skip guards on steps 4-5

### Changed

- `SetupExecutor#execute` now returns `env:` key in result hash containing accumulated environment variables
- `TestExecutor#execute` and `#execute_via_skill` accept and forward `sandbox_path:` and `env_vars:` kwargs

## [0.12.0] - 2026-02-11

### Added

- **TestCase model** — `Models::TestCase` with title, steps, expected results, and setup/teardown support; `TestScenario` extended with `test_cases` collection for TS-format scenarios
- **ScenarioLoader** molecule — loads TS-format `scenario.yml` files with test case directory discovery, fixture path resolution, and setup script detection
- **FixtureCopier** molecule — copies fixture directories into sandbox with collision detection and path mapping
- **SetupExecutor** molecule — runs `setup.sh` scripts in sandbox context with timeout, output capture, and error reporting
- **TestCaseParser** atom — parses individual test case directories into `TestCase` models
- **Dual-mode test discovery** — `TestDiscoverer` supports both legacy `.mt.md` files and new TS-format `scenario.yml` directory structures
- **TC-level execution pipeline** — per-test-case independence with individual setup, execution, and reporting
- **`setup` CLI subcommand** — `ace-test-e2e setup PACKAGE [TEST_ID]` prepares sandbox without running tests

### Fixed

- `ScenarioParser#parse` now handles TS-format `scenario.yml` files — delegates to `ScenarioLoader` instead of crashing with `ArgumentError: No frontmatter found`
- Review cycle 1 feedback items (medium+ severity)
- Review cycle 2 feedback items (critical + high severity)

### Changed

- ace-lint E2E tests migrated from `.mt.md` to per-TC directory format
- E2E test configurations added for linting

## [0.11.2] - 2026-02-10

### Fixed

- `--only-failures` no longer re-runs passing scenarios in multi-scenario packages — SuiteOrchestrator now uses per-scenario failure data (`find_failures_by_scenario`) instead of flat per-package aggregation, so only scenarios with actual failures are launched
- `--only-failures` now correctly matches test files with descriptive filename suffixes (e.g. `MT-COMMIT-002-specific-file-commit.mt.md`) against metadata test-ids (`MT-COMMIT-002`) via prefix matching
- Per-scenario `--test-cases` filtering — each scenario now receives only its own failed TC IDs instead of the same flat list applied to every scenario in the package
- `SuiteProgressDisplayManager` no longer crashes with `NoMethodError` on nil `@footer_line` when the test queue is empty (defensive guard)

### Technical

- 74 tests across changed files, 262 assertions, 0 failures

## [0.11.1] - 2026-02-10

### Fixed

- `--only-failures` now detects tests that errored without writing metadata — `write_failure_stubs` in SuiteOrchestrator backfills stub `metadata.yml` for any test that failed/errored but has no metadata on disk (e.g., provider 503, timeout before report generation)
- FailureFinder wildcard fallback now recognizes `status: "error"` and `status: "incomplete"` in addition to `fail` and `partial`, ensuring error stubs trigger full test re-runs

### Technical

- 63 tests across changed files, 226 assertions, 0 failures

## [0.11.0] - 2026-02-08

### Added

- `ace-test-e2e-sh` sandbox wrapper script — enforces working directory and `PROJECT_ROOT_PATH` isolation for every bash command in E2E tests, preventing test artifacts from escaping the sandbox across separate shell invocations
- Wrapper validates sandbox path (must contain `.cache/ace-test-e2e/`), supports both args mode and stdin heredoc mode, and uses `exec` for transparent exit-code passthrough

### Changed

- Updated all 43 E2E test files across 10 packages to use `ace-test-e2e-sh` wrapper for Test Data and Test Cases bash blocks
- Updated `run-e2e-test.wf.md` sections 5 and 6 with wrapper usage instructions
- Updated `setup-e2e-sandbox.wf.md` with wrapper documentation and usage examples

## [0.10.10] - 2026-02-08

### Added

- Batch timestamp generation for `ace-test-suite-e2e` — `SuiteOrchestrator` pre-generates unique 50ms-offset run IDs and passes them to subprocesses via `--run-id`, giving coordinated sandbox/report paths across suite runs
- `--run-id` CLI option on `ace-test-e2e` for deterministic report paths when invoked by suite orchestrator
- `TestOrchestrator#run` accepts external `run_id:` keyword, using it instead of generating a timestamp when provided

### Technical

- 263 tests, 797 assertions, 0 failures

## [0.10.9] - 2026-02-08

### Fixed

- Surface silent failures in `SuiteOrchestrator#generate_suite_report` — replace blanket `rescue => _e; nil` with `warn` that prints error class and message; backtrace available via `DEBUG=1`
- Add DEBUG-gated warning when suite report is skipped due to no results matching test files
- Strip whitespace from `report_dir` regex captures in `parse_subprocess_result` and `run_single_test` to prevent path mismatches

### Technical

- 257 tests, 783 assertions, 0 failures

## [0.10.8] - 2026-02-08

### Added

- Package filtering for `ace-test-suite-e2e` — optional comma-separated `packages` positional argument filters suite execution to specific packages (e.g., `ace-test-suite-e2e ace-bundle,ace-lint`)
- Package filter composes with `--affected` via intersection — both filters narrow the package set independently

### Technical

- 256 tests, 769 assertions, 0 failures

## [0.10.7] - 2026-02-08

### Added

- Suite-level final report generation in `SuiteOrchestrator` — wires `SuiteReportWriter` into multi-package runs to produce LLM-synthesized reports after all tests complete
- `finalize_run` helper extracts duplicated summary + return pattern from `run_sequential` and `run_parallel`
- `generate_suite_report` coordinates data conversion (result hashes → `TestResult` models, test files → `TestScenario` models) and report writing
- `build_test_result` converts raw subprocess result hashes into `Models::TestResult` with synthesized test case arrays
- `parse_scenario` parses `.mt.md` files via `ScenarioParser` with fallback to stub `TestScenario`
- Report path printed to output and included in return hash as `:report_path`
- Constructor accepts injectable `suite_report_writer`, `scenario_parser`, `timestamp_generator` for testability

### Technical

- 251 tests, 743 assertions, 0 failures

## [0.10.6] - 2026-02-08

### Fixed

- Unify timestamp precision to 7-char (`:"50ms"`) across all E2E paths — `default_timestamp` now uses `Timestamp.encode(Time.now.utc, format: :"50ms")` instead of `Timestamp.now`
- Remove `count <= 1` early return in `generate_timestamps` that fell back to 6-char path, causing mixed-length timestamps within the same method

### Technical

- 247 tests, 723 assertions, 0 failures

## [0.10.5] - 2026-02-08

### Changed

- Extract `REFRESH_INTERVAL = 0.25` constant for 4Hz refresh rate — replaces magic number across both orchestrators and both progress display managers

### Technical

- 247 tests, 723 assertions, 0 failures

## [0.10.4] - 2026-02-08

### Added

- Live timer refresh for single-package `--progress` display — dedicated 4Hz refresh thread in `TestOrchestrator` updates running timers while tests execute
- `ProgressDisplayManager` test coverage (header rendering, state transitions, throttle behavior)

### Changed

- Throttle `ProgressDisplayManager#refresh` to ~4Hz (250ms) — matches `SuiteProgressDisplayManager` pattern

### Technical

- 247 tests, 723 assertions, 0 failures

## [0.10.3] - 2026-02-08

### Changed

- Throttle `SuiteProgressDisplayManager#refresh` to ~4Hz (250ms) — reduces terminal I/O while maintaining responsive process completion detection

### Technical

- 242 tests, 693 assertions, 0 failures

## [0.10.2] - 2026-02-08

### Added

- `--progress` CLI option for live animated display in `ace-test-suite-e2e`
- `SuiteProgressDisplayManager` molecule — animated ANSI table with in-place row updates, running timers, and live footer (Active/Completed/Waiting)
- `SuiteSimpleDisplayManager` molecule — extracted default line-by-line display from SuiteOrchestrator

### Changed

- SuiteOrchestrator delegates display to pluggable display managers (same pattern as TestOrchestrator)
- SuiteOrchestrator accepts `progress:` parameter for display mode selection

### Technical

- 241 tests, 689 assertions, 0 failures

## [0.10.1] - 2026-02-08

### Changed

- Polished suite output with columnar alignment, double-line separators, and structured summary
- Suite header shows test and package counts with `═` separator borders
- Per-test progress lines now display icon, duration, package, test name, and case counts in aligned columns
- Suite summary shows failed test details, duration, pass/fail stats, and colored status message
- Added `use_color:` parameter to SuiteOrchestrator for ANSI color control (auto-detects TTY)

### Added

- `DisplayHelpers.double_separator` — 65-char `═` double-line separator for suite display
- `DisplayHelpers.format_suite_duration` — minute-range formatting (`4m 25s`)
- `DisplayHelpers.format_suite_elapsed` — right-aligned 7-char column for suite times
- `DisplayHelpers.format_suite_test_line` — columnar test result line builder
- `DisplayHelpers.format_suite_summary` — complete summary block formatter
- `SuiteOrchestrator.extract_test_name` — human-readable test name from file path
- Test case count extraction from subprocess output in `parse_subprocess_result`

### Technical

- 224 tests, 607 assertions, 0 failures

## [0.10.0] - 2026-02-08

### Added

- `ace-test-suite-e2e` command for running E2E tests across all packages
- `SuiteOrchestrator` organism for managing multi-package test execution
- `AffectedDetector` molecule for detecting packages affected by recent changes
- Parallel execution support with `--parallel N` option
- `--affected` filter to test only changed packages

### Fixed

- Prevent FrozenError in parallel execution output buffering
- Prevent shell injection vulnerability by using array-based command execution (`Open3.popen3`)
- Fix `--affected` edge case handling

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
