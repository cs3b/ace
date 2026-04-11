# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Added a deterministic preflight discovery bridge that prefers `test/feat` and falls back to legacy `test/integration`, so packages can migrate to the new `fast / feat / e2e` taxonomy without breaking existing E2E runs.

### Fixed
- Removed accidental real LLM, subprocess, and tmux execution from unit-scoped organism/setup tests by injecting report/setup boundaries and moving live tmux session coverage into explicit integration tests.

## [0.31.0] - 2026-04-10

### Changed
- Restored the two-phase E2E harness to run deterministic `test/integration` coverage before agent scenarios from `test/e2e`, with integration failures short-circuiting scenario execution.
- Added deterministic integration execution, richer per-test-case manifests and artifact snapshotting, and refreshed CLI/docs/workflows/tests around the restarted layout and role-based runner/verifier contract.

### Fixed
- Accepted minimal verifier evidence responses in the runner pipeline so successful scenario runs no longer fail when a verifier omits the full structured envelope.

## [0.30.2] - 2026-04-10

### Fixed
- Surface `git diff` stderr when affected-package detection fails so invalid refs and shallow-clone failures no longer look like empty affected sets.

## [0.30.1] - 2026-04-10

### Fixed
- Raised the `ace-support-test-helpers` runtime dependency floor to `~> 0.14` so released installs accept the shared sandbox package-copy helper line used by the restarted runner.
- Restored the `TS-RUNNER-001` smoke scenario fixture source path so the CLI smoke scenario resolves its canonical demo fixture again.

## [0.30.0] - 2026-04-10

### Changed
- Reworked `ace-test-runner-e2e` back into a two-phase contract, with deterministic integration from `test/integration` before agent scenarios from `test/e2e`.
- Switched sandbox orchestration to the shared package-copy helper and refreshed CLI/docs/workflows for the restarted E2E structure.

### Fixed
- Hardened affected-file detection by capturing git diff stderr so provider-side affected checks fail with clearer diagnostics.

## [0.29.8] - 2026-04-01

### Fixed
- Replaced process-global `Dir.chdir` in pipeline LLM execution with explicit `working_dir` threading to avoid parallel scenario crashes (`RuntimeError: conflicting chdir during another chdir block`).

### Changed
- **ace-monorepo-e2e**: Added stronger command/output evidence gates to `TS-MONO-001-rubygems-install` and `TS-MONO-002-quickstart-local` so local sandbox installs and quick-start workflow checks validate real CLI behavior, output, and exit status rather than directory/file presence alone.
- **ace-monorepo-e2e**: Updated `ace-test-runner-e2e` workflow instructions and scenario template defaults to reduce false-positive E2E tests through command-level evidence, false-positive risk tagging, and duplicate-command consolidation rules.

## [0.29.6] - 2026-04-01

### Fixed
- Resolved `role:` provider references in CLI provider detection so sandbox isolation and pipeline execution apply when using role-based model selectors like `role:e2e-executor`.

## [0.29.5] - 2026-04-01

### Fixed
- Changed pipeline executor to `Dir.chdir` into sandbox before launching the LLM agent, preventing artifact leaks to the repo root.

## [0.29.4] - 2026-03-31

### Changed
- Role-based E2E runner model defaults.

## [0.29.3] - 2026-03-29

### Changed
- Role-based e2e execution and reporting defaults.


## [0.29.2] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.


## [0.29.1] - 2026-03-29

### Fixed
- **ace-test-runner-e2e v0.29.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.29.0] - 2026-03-24

### Added
- Documented `ace-test-e2e-sh` sandbox shell command in usage reference (previously undocumented executable).

### Changed
- Re-recorded getting-started demo with real `ace-test-e2e-suite --progress` execution at 8x playback speed.
- Fixed demo tape YAML structure (duplicate `commands:` key caused `cd` to be silently dropped).
- Normalized gemspec homepage and changelog URIs to use consistent interpolation pattern.

## [0.28.0] - 2026-03-23

### Changed
- Refreshed README layout, navigation links, and section flow to align with the current package README pattern.

## [0.27.0] - 2026-03-22

### Changed
- Reworked package documentation with a landing-page README, tutorial getting-started guide, full usage reference, handbook catalog, demo tape/GIF assets, and refreshed gem metadata messaging.

## [0.26.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.26.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.25.0] - 2026-03-17

### Added
- Added optional per-scenario `timeout` support (in seconds) in `scenario.yml`, with scenario timeout taking precedence over suite/global timeout.

## [0.24.13] - 2026-03-17

### Fixed
- Ensure CLI E2E scenarios keep package-root references inside sandbox by provisioning package contents during pipeline setup, preventing `$PROJECT_ROOT_PATH/<package>` path failures.

## [0.24.12] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.24.11] - 2026-03-13

### Technical
- Updated canonical E2E workflow skills for workspace-based execution flow.

## [0.24.10] - 2026-03-13

### Changed
- Updated canonical E2E workflow skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.24.9] - 2026-03-13

### Fixed
- Corrected experience report status output so only pass results are marked `complete`; partial or error states now consistently remain `incomplete`.

### Changed
- Updated `e2e/fix` workflow guidance to remove suite-level `--only-failures` checkpoints and require explicit scenario-level reruns for fix iteration.

### Technical
- Added regression coverage for experience report status behavior for pass, partial, and error results.

## [0.24.8] - 2026-03-13

### Changed
- Removed the stale fork-context comment from the canonical `as-e2e-run` skill so only the selected Claude-fork skills retain provider-specific fork metadata.

## [0.24.7] - 2026-03-13

### Changed
- Increased the default E2E suite parallelism setting in project config from `6` to `8`.

## [0.24.6] - 2026-03-13

### Changed
- Updated the `e2e/fix` workflow and canonical `as-e2e-fix` skill to require rerunning the selected failing scope after each fix and a final `ace-test-e2e-suite --only-failures` checkpoint before concluding a fix session.

## [0.24.5] - 2026-03-13

### Changed
- Updated the project E2E suite report-generation default model override to `claude:sonnet@ro`.

## [0.24.4] - 2026-03-12

### Fixed
- Threaded the sandbox path into CLI-provider E2E runner and verifier invocations as an explicit working directory so `results/tc/...` stays sandbox-local during deterministic pipeline execution.

## [0.24.3] - 2026-03-12

### Changed
- Switched the project E2E suite report-generation default model to `codex:spark`.

## [0.24.2] - 2026-03-12

### Fixed
- Restored the canonical `as-e2e-run` `--sandbox` path to `wfi://e2e/execute` so CLI-provider E2E runs use the pre-populated sandbox execution workflow again.
- Hardened verifier/result parsing so prose containing paths like `results/tc/{NN}` is no longer misclassified as raw JSON.
- Convert unstructured verifier responses into deterministic `error` reports and mark error metadata verdicts as `fail` instead of `pass`.

### Technical
- Added regression coverage for canonical E2E skill routing, brace-fragment parser handling, and unstructured verifier report generation.

## [0.24.1] - 2026-03-12

### Changed
- Updated README and E2E workflow documentation to use `ace-bundle` and `ace-test-e2e` examples instead of slash-command orchestration.

## [0.24.0] - 2026-03-10

### Added
- Added canonical handbook-owned E2E lifecycle skills for create, manage, review, planning, rewrite, fix, and sandbox setup.

### Changed
- Aligned canonical E2E skill tool declarations and metadata with the stricter handbook skill schema.


## [0.23.0] - 2026-03-09

### Added
- Added `skill-sources` gem defaults registration at `.ace-defaults/nav/protocols/skill-sources/ace-test-runner-e2e.yml` so `skill://` can discover canonical `handbook/skills` entries from `ace-test-runner-e2e`.

## [0.22.1] - 2026-03-09

### Changed
- Updated canonical `as-e2e-run` skill metadata with explicit workflow typing (`skill.kind`, `skill.execution.workflow`) and agent-context comments for schema-aligned projections.

## [0.22.0] - 2026-03-08

### Changed
- Remove hardcoded `providers.cli_args` config; use ace-llm `@preset` suffixes for provider permission flags

## [0.21.2] - 2026-03-04

### Changed
- E2E runtime, wrappers, tests, and workflows now use `.ace-local/test-e2e` and sandbox-local `.ace-local/e2e` paths.


## [0.21.1] - 2026-03-04

### Changed
- Preserved `required_cli_args` string compatibility for external callers and added array-normalized internal usage via `required_cli_args_list`.

## [0.21.0] - 2026-03-04

### Changed
- Normalize `providers.cli_args` config values to arrays and support merged string/array CLI args in adapter and executor.

## [0.20.5] - 2026-02-25

### Technical
- Update taskflow fixture template task lookup examples to use `ace-task show`.

## [0.20.4] - 2026-02-25

### Changed
- Standardize handbook runner/verifier contract across E2E guides, templates, and workflows: runner is execution-only, verifier is impact-first (sandbox impact → artifacts → debug fallback).
- Add explicit setup ownership guidance (`scenario.yml` + fixtures) and remove runner-side setup anti-patterns from handbook instructions.
- Extend E2E workflow guardrails to avoid autonomous `ace-test-e2e` / `ace-test-e2e-suite` execution in constrained or uncertain environments.

## [0.20.3] - 2026-02-24

### Added
- Support run-ID-driven tmux session naming via `tmux-session: { name-source: run-id }` in scenario `setup` directives.

### Changed
- Pass the orchestrator run ID into setup execution so tmux setup can use deterministic per-run session names.
- Document run-ID tmux session setup and teardown behavior in scenario reference/template guidance.

### Technical
- Add regression coverage for run-ID tmux session naming in setup executor and orchestrator setup integration.

## [0.20.2] - 2026-02-24

### Changed
- Strengthen `e2e/analyze-failures` output contract with autonomous fix decisions, concrete candidate file targets, and explicit no-touch boundaries.
- Update `e2e/fix` to consume autonomous analysis decisions directly and proceed without user clarification for normal targeting/scope choices.

## [0.20.1] - 2026-02-24

### Changed
- Consolidate mise.toml handling into `setup:` as `run:` steps; remove `sandbox-setup:` mechanism from `PipelineSandboxBuilder`, `TestScenario`, and `ScenarioLoader`
- Rename `env:` → `agent-env:` in scenario.yml `setup:` to clarify these are environment variables passed to the runner/verifier agent subprocess, not setup commands
- Re-export env vars (including `PROJECT_ROOT_PATH`, `ACE_TASKFLOW_PATH`) after login shell profile sourcing in `SetupExecutor#handle_run` to protect against mise's shell hook clobbering

## [0.20.0] - 2026-02-24

### Added
- Generic `sandbox-setup:` field in scenario.yml for declaring shell commands that run inside the pipeline sandbox after infrastructure setup, with `$SANDBOX_PATH` and `$PROJECT_ROOT_PATH` environment variables
- `sandbox_setup` and `sandbox_teardown` attributes on `TestScenario` model
- `parse_sandbox_commands` method in `ScenarioLoader` for parsing sandbox command fields from YAML
- `execute_sandbox_setup` method in `PipelineSandboxBuilder` replacing hardcoded `trust_mise_config`

### Changed
- Replace hardcoded `mise trust` call in `PipelineSandboxBuilder` with generic `execute_sandbox_setup` mechanism driven by scenario configuration

## [0.19.3] - 2026-02-24

### Fixed
- Stop copying `TC-*.runner.md` / `TC-*.verify.md` scenario definitions into the sandbox root during setup; pipeline execution now relies on prompt bundling from scenario source files only.
- Clarify pipeline runner system prompt to treat initial cwd as `SANDBOX_ROOT` and keep artifact writes under `SANDBOX_ROOT/results` even when commands must run inside created worktrees.

## [0.19.2] - 2026-02-24

### Fixed
- Improve pipeline verifier evidence extraction to support multiline evidence blocks and `Evidence of failure` headings in report parsing.

### Technical
- Add parser regression coverage for multiline failure evidence propagation into metadata and report outputs.

## [0.19.1] - 2026-02-24

### Changed
- Increase default CLI pipeline timeout from 300s to 600s in default E2E runner configuration.

## [0.19.0] - 2026-02-24

### Added
- Add `e2e/analyze-failures` workflow to classify failed scenarios/TCs before any fix is applied.

### Changed
- Rewrite `e2e/fix` as an execution-only workflow with a required analysis gate and explicit rerun-scope discipline.

## [0.18.2] - 2026-02-24

### Changed
- Rewrite `run.wf.md` (v2.0): restructure dual-mode execution, add `--tags`/`--exclude-tags`, add pipeline context section, standardize report fields to TC-first schema
- Rewrite `execute.wf.md` (v2.0): document SetupExecutor contract, add dual-agent verifier documentation, clarify tag filtering at discovery time

### Added
- Add `tags` field to scenario-yml-reference guide with naming conventions and OR filtering semantics
- Add `## Execution Pipeline` section to e2e-testing guide documenting 6-phase deterministic pipeline
- Add `## Scenario-Level Configuration` section to tc-authoring guide explaining tags, runner/verifier roles, and sequential context model
- Add `tags` field to scenario.yml template
- Add `score`, `verdict`, and `failed[]` (TC-first schema) to test-report template
- Add `--tags`/`--exclude-tags` arguments to manage, run-batch workflow instructions
- Add tag-related guidance to create, fix, rewrite, review, plan-changes, setup-sandbox workflows
- Add essential E2E test suite plan covering 10 new scenarios across 7 packages

### Fixed
- Fix `cost-tier` default from `standard` to `smoke` and values to `smoke|happy-path|deep` across all guides and templates
- Rename legacy `passed`/`failed`/`total` frontmatter fields to `tcs-passed`/`tcs-failed`/`tcs-total` in test-report template

## [0.18.1] - 2026-02-24

### Fixed
- Harden verifier goal parsing for standalone pipeline reports: accept both `##` and `###` goal headings, normalize emphasized verdict tokens, and extract failure categories from mixed category text
- Ensure deterministic `*-reports` output on pipeline failures by writing structured error reports (summary, experience, metadata, and goal report) instead of leaving missing report directories
- Improve suite subprocess parsing to reliably extract the final `Report:` and `Error:` lines and preserve error summaries from metadata reconciliation

### Changed
- Rename CLI provider helper to `CliProviderAdapter` and keep `SkillPromptBuilder` as a backward-compatible alias
- Route executor/orchestrator CLI-provider detection and required-args lookup through the new adapter name
- Standardize `--only-failures` behavior around scenario-level reruns and update suite messaging accordingly
- Prefer workspace-local `bin/ace-test-e2e` when suite orchestration spawns subprocesses

### Technical
- Expand parser and pipeline tests for h2/h3 goal headings, category normalization, deterministic failure report generation, and adapter alias compatibility
- Update workflow/config wording to reflect deterministic pipeline execution terminology

## [0.18.0] - 2026-02-24

### Changed
- Simplify `ace-test-e2e` to single-command CLI (no `run` subcommand needed)
- Simplify `ace-test-e2e-suite` to single-command CLI (clean `--help` output)

### Removed
- Multi-command Registry (`CLI` module with `run`/`suite`/`setup` subcommands)
- `ace-test-e2e setup` command (setup runs automatically during test execution)

## [0.17.6] - 2026-02-24

### Changed
- Simplify E2E execution to a single standalone pipeline model for CLI providers
- Rename internal pipeline components to neutral names:
  - `PipelineSandboxBuilder`
  - `PipelinePromptBundler`
  - `PipelineReportGenerator`
  - `PipelineExecutor`
- Update handbook guides, templates, and workflow instructions to standalone runner/verifier pair format

### Removed
- Scenario-level `mode` and `execution-model` support in `scenario.yml` parsing
- Inline `.tc.md` test-case format support in `ScenarioLoader`
- `ace-test-e2e suite --mode` option and mode-based scenario discovery filtering
- Goal-mode-specific verify forcing in `TestOrchestrator` (verify now respects CLI flag only)

## [0.17.5] - 2026-02-24

### Added
- Add standalone goal-mode execution pipeline components:
  - `GoalModeSandboxBuilder` (sandbox bootstrapping and tool validation)
  - `GoalModePromptBundler` (runner/verifier prompt preparation with artifact embedding)
  - `GoalModeReportGenerator` (TC-first report synthesis from verifier output)
  - `GoalModeExecutor` (Phase A-F orchestration)

### Changed
- Route standalone goal-mode scenarios away from slash-command skill invocation to deterministic dual-agent execution via `ace-llm` prompts
- Force verifier execution for standalone goal-mode scenarios regardless of CLI `--verify` flag (`--verify` is effectively always-on for this mode)
- Keep procedural and inline-goal execution behavior unchanged

## [0.17.4] - 2026-02-24

### Fixed
- Prevent synthetic TC ID collision with real failed TC IDs in verifier results
- Add test coverage for no-category TC parsing and unique TC ID guarantee

## [0.17.3] - 2026-02-24

### Fixed
- Fix NoMethodError in `parse_failed_tcs` when TC entry lacks category suffix

## [0.17.2] - 2026-02-24

### Added
- Optional independent verifier execution mode via `--verify` for `ace-test-e2e run` and `ace-test-e2e suite`
- Verifier parsing support for TC-first contracts including failure categorization (`test-spec-error`, `tool-bug`, `runner-error`, `infrastructure-error`)

### Changed
- `TestExecutor`/`TestOrchestrator` execution path now supports runner + verifier dual invocation while keeping default single-agent behavior unchanged
- Report metadata and summary frontmatter now emit TC-first fields (`tcs-passed`, `tcs-failed`, `tcs-total`, `score`, `verdict`) and structured `failed[].tc` entries
- Failure discovery and metadata reconciliation now read TC-first schema fields in addition to existing result counters
- Execute workflow documentation updated to reflect verify mode and TC-first report structure

## [0.17.1] - 2026-02-24

### Added
- Test case frontmatter `mode` support (`procedural` default, `goal` explicit) in `ScenarioLoader`/`TestCase`
- Inline goal-mode TC validation: required `Objective`/`Available Tools`/`Success Criteria` and rejection of `## Steps`

### Changed
- E2E execution workflow docs (`run.wf.md`, `execute.wf.md`) now define procedural, inline-goal, and standalone-goal execution paths
- Goal-mode report template examples now document `passed`/`failed` arrays plus `score` and `verdict` frontmatter fields
- TC/scenario authoring guides and templates updated for goal-mode conventions

## [0.17.0] - 2026-02-24

### Added
- Scenario-level metadata support for `tags`, `mode`, `execution-model`, `tool-under-test`, and `sandbox-layout`
- Goal-mode standalone discovery for `TC-*.runner.md` and `TC-*.verify.md` pairs with required `runner.yml.md` and `verifier.yml.md`
- CLI filtering options: `ace-test-e2e suite --tags/--exclude-tags/--mode` and `ace-test-e2e run --tags`

### Changed
- Apply tag and mode filtering at scenario discovery time so excluded scenarios never enter execution
- Extend sandbox definition copying to include goal-mode standalone files alongside procedural `.tc.md` files

### Technical
- Expanded model, loader, discoverer, orchestrator, and command test coverage for metadata parsing, filter semantics, and option wiring

## [0.16.22] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.16.21] - 2026-02-22

### Changed
- Migrate CLI to standard help pattern with explicit subcommands
- Remove DWIM default routing - users must now use `run` subcommand explicitly
- Empty args now shows help instead of requiring a command

### Technical
- Add `HELP_EXAMPLES` constant with usage examples
- Update tests to match new CLI pattern (remove `known_command?` tests)

### Technical
- Update e2e-testing guide to use `ace-search "pattern"` single-command syntax (drop `search` subcommand)

## [0.16.18] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.16.17] - 2026-02-21

### Fixed
- `TestExecutor` now passes setup `env_vars` as `subprocess_env` to `QueryInterface.query`, ensuring environment variables (e.g., `ACE_TMUX_SESSION`) are set on the `claude -p` subprocess rather than only serialized as prompt text

### Added
- Unit tests verifying `env_vars` propagation as `subprocess_env` for both scenario and test-case execution paths

## [0.16.16] - 2026-02-21

### Fixed
- Tmux sessions created by E2E test setup (`tmux-session` step) are now cleaned up after test execution via `ensure` blocks in `TestOrchestrator`
- `SetupExecutor` instance returned from `setup_sandbox_if_ts` so `teardown` is called reliably in both single-test and parallel-test paths

### Changed
- Tmux session naming uses scenario test ID (`{test_id}-e2e`, e.g., `TS-OVERSEER-001-e2e`) instead of generic `ace-e2e-{timestamp}` for easier identification
- `SetupExecutor#execute` accepts `scenario_name:` parameter for descriptive session naming

### Added
- Unit tests for tmux session naming (scenario-based and fallback) and teardown cleanup

## [0.16.15] - 2026-02-21

### Added
- Debug-only post-suite diagnostics in `SuiteOrchestrator` to detect and report lingering `claude -p` processes when `ACE_LLM_DEBUG_SUBPROCESS=1`
- Unit tests for lingering-process diagnostics behavior in debug-enabled and debug-disabled modes

## [0.16.14] - 2026-02-21

### Changed
- Update skill invocation to colon-free convention (`ace_e2e_run` format)
- Update skill prompt builder and tests for new skill naming convention

## [0.16.13] - 2026-02-21

### Added
- "Refactoring Resilience" section in E2E testing guide: pre-refactoring checklist, refactoring-proof patterns (variables not literals, flexible regex, runtime path discovery), post-refactoring smoke run requirement

## [0.16.12] - 2026-02-21

### Fixed
- Pass `--report-dir` explicitly from suite orchestrator to inner subprocesses, eliminating directory name mismatch between Ruby `short_id` computation and LLM agent interpretation
- Thread `report_dir` parameter through the full execution chain: `SuiteOrchestrator` → CLI `--report-dir` option → `TestOrchestrator` → `TestExecutor` → `SkillPromptBuilder` → workflow

### Added
- `--report-dir` CLI option for `ace-test-e2e` to override computed report directory path
- `REPORT_DIR` parameter in `run.wf.md` workflow instructions for agent-side report path override

## [0.16.11] - 2026-02-21

### Fixed
- Add `-b main` to `git init` in `SetupExecutor` to ensure consistent default branch name regardless of system git configuration

## [0.16.10] - 2026-02-21

### Added
- Save subprocess raw output (`subprocess_output.log`) for all test results (pass, fail, error) in report directories for diagnostic context
- Write `subprocess_output.log` alongside failure stub `metadata.yml` when subprocess has no report directory

### Technical
- Add `save_subprocess_output` method to persist subprocess stdout+stderr to report directories
- Attach `:raw_output` to result hashes in both parallel and sequential execution paths
- Add tests for `parse_subprocess_result` raw output inclusion, `save_subprocess_output` behavior, and failure stub output logging

## [0.16.9] - 2026-02-21

### Fixed
- Downcase status in `SkillResultParser.normalize_status` so `"Pass"` and `"PASS"` are correctly recognized as `"pass"`
- Downcase status in `ResultParser.normalize_result` for JSON/API path consistency
- Reconcile scenario status with case counts in `SuiteOrchestrator.override_from_metadata` — override to `"pass"` when all cases passed but metadata status is incorrect
- Reconcile scenario status with case counts in `TestOrchestrator.read_agent_result` — same safety net for CLI provider metadata path

## [0.16.8] - 2026-02-21

### Fixed
- Fix `short_id` regex to support digits in test area names (e.g., `TS-B36TS-001` now correctly yields `ts001`)
- Copy test definition files (`.tc.md`) to sandbox before execution so the test runner can locate them during E2E runs

### Technical
- Add test for skill name coupling in `SkillPromptBuilder` to catch invocation name drift
- Add tests for `short_id` with digit-containing area names (`B36TS`, `ASSIGN`)

## [0.16.7] - 2026-02-20

### Fixed
- Correct skill invocation name from `/ace:run-e2e-test` to `/ace:e2e-run` in `SkillPromptBuilder` (was causing 100% E2E test failure rate)
- Fix broken `.claude/skills/ace_e2e-run` symlink target from non-existent `ace_run-e2e-test` to `ace_e2e-run`

### Added
- `tmux-session` setup step in `SetupExecutor` — creates an isolated detached tmux session, stores name as `ACE_TMUX_SESSION` env var, and cleans up via new `teardown` method

## [0.16.6] - 2026-02-19

### Technical
- Namespace workflow instructions into e2e/ subdirectory with updated wfi:// URIs
- Update skill name references to use namespaced ace:e2e-action format

## [0.16.5] - 2026-02-19

### Fixed

- Detect CLI-provider skill mis-invocation patterns (`/ace:...` in shell, invalid `ace-test e2e`, missing tests context) and return explicit infrastructure errors
- Require deterministic report-directory matching in `TestOrchestrator` for CLI-provider runs to prevent stale report reuse across run IDs

### Changed

- Harden `SkillPromptBuilder` prompts and handbook guidance to explicitly require slash-command execution in chat context (not bash)

## [0.16.4] - 2026-02-18

### Changed

- **Balanced E2E decision evidence across handbook/workflows** — `create-e2e-test.wf.md` (v1.3), `review-e2e-tests.wf.md` (v2.1), and `plan-e2e-changes.wf.md` (v1.1) now require explicit E2E-vs-unit justification with unit coverage references and replacement evidence for overlap-based removals
- **Scenario metadata expanded for manual, cost-aware runs** — `scenario.yml` reference/template and authoring guidance now include `cost-tier`, `e2e-justification`, and `unit-coverage-reviewed` fields
- **E2E guide refined to avoid duplicate layer testing** — `e2e-testing.g.md` (v1.6) now documents manual run order (`smoke` → `standard` → `deep`) and clarifies that negative/error TCs are required when they add E2E-only value or close a documented unit gap
- **TC authoring guidance updated** — `tc-authoring.g.md` (v1.1) now ties each TC back to scenario-level Value Gate evidence instead of requiring blanket error-TC duplication

## [0.16.3] - 2026-02-18

### Fixed

- Suite runner now correctly detects partial test failures when subprocess exits with code 0 but has fewer passed cases than total cases
- "partial" status now counted as failed in both sequential and parallel suite execution paths
- Suite summary now displays test-case-level counts (passed/failed/percentage) alongside test-level counts

## [0.16.2] - 2026-02-18

### Changed

- Remove all MT-format references from e2e-testing guide — TS-format is now the only documented convention
- Remove `--format mt` parameter from create-e2e-test workflow — TS-format is the only option
- Remove MT-format discovery commands (`find ... -name "*.mt.md"`) from run-e2e-test, run-e2e-tests, review-e2e-tests, and rewrite-e2e-tests workflows
- Update setup-e2e-sandbox workflow to use `TS-` prefix in examples and sed patterns
- Update fix-e2e-tests workflow to remove MT-format file references
- Update all example test IDs and cache paths from `MT-LINT-001`/`mt001` to `TS-LINT-001`/`ts001`

## [0.16.1] - 2026-02-18

### Fixed

- `ace-test-e2e-suite` now reads `execution.parallel` from config instead of hardcoding `0` (sequential), matching `ace-test-e2e` behavior

### Changed

- Package renamed from `ace-test-e2e-runner` to `ace-test-runner-e2e` for naming consistency with `ace-test-runner` base package
- Binary renamed from `ace-test-suite-e2e` to `ace-test-e2e-suite` to place `-e2e` qualifier as infix after `test`

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


## [0.16.19] - 2026-02-22

### Fixed
- Added --help/-h and --version flag handling to ace-test-e2e-sh (was causing FATAL error)
- Standardized quiet, verbose, debug option descriptions to canonical strings
