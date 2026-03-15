# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.8.7] - 2026-03-15

### Fixed
- Made E2E handoff-check comparison step explicit so the runner produces non-empty verification artifacts

## [0.8.6] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.8.5] - 2026-03-13

### Changed
- Updated the canonical simulation skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

### Fixed
- Restored the built-in `validate-idea` and `validate-task` synthesis preset defaults to `claude:haiku` so default end-to-end simulations use the stable shipped synthesis path again.

## [0.8.4] - 2026-03-13

### Changed
- Updated the `TS-SIM-001` default preset E2E scenario to verify the shipped preset contract and chained handoff behavior while accepting either successful synthesis or a cleanly recorded final-stage failure.

## [0.8.2] - 2026-03-13

### Changed
- Updated the full-chain synthesis E2E scenario to verify complete chain aggregation and recorded final-stage outcomes, including cleanly captured external synthesis failures.

## [0.8.1] - 2026-03-12

### Fixed
- Switched simulation bundle/stage/final synthesis subprocess execution to the shared core command executor so failed external commands do not leak Ruby thread-read exceptions into run output handling.

### Technical
- Expanded simulation runner coverage to verify failed final synthesis still leaves inspection artifacts such as `synthesis.yml` and final input/source files.

## [0.8.0] - 2026-03-10

### Added
- Added the canonical handbook-owned simulation skill for scenario/provider comparison flows.


## [0.7.2] - 2026-03-04

### Changed
- Default simulation cache root now uses `.ace-local/sim`.


## [0.7.1] - 2026-03-04

### Fixed
- Usage docs artifact paths corrected to short-name convention (`.ace-local/sim/` not `.ace-local/ace-sim/`)

## [0.7.0] - 2026-03-04

### Changed
- Default session store directory migrated from `.cache/ace-sim` to `.ace-local/sim`

## [0.6.0] - 2026-02-28

### Changed
- **BREAKING**: `--source` now accepts multiple values via repeatable flag (not CSV parsing)
- `--source` values passed directly to `ace-bundle` without Ruby preprocessing
- `SourceResolver` deleted - ace-bundle handles glob expansion and file resolution
- `SimulationSession.source` is now an array instead of string

### Removed
- CSV parsing for comma-separated sources (use multiple `--source` flags)
- Ruby glob expansion (ace-bundle handles this)
- `SourceResolver` molecule (171 lines removed)

## [0.5.1] - 2026-02-28

### Fixed
- Simplify nil guard in `FinalSynthesisExecutor#copy_source` to use `||` operator

## [0.5.0] - 2026-02-28

### Added
- Multi-file input support via `--source` flag (repeatable)
- `SourceBundler` molecule creates bundle YAML and invokes `ace-bundle`
- Writeback guard: error when `--writeback` used with multiple sources

### Fixed
- Update preset provider assertions in command tests

## [0.4.4] - 2026-02-28

### Changed
- Update `sim/run` workflow: when source is a task with usage documentation (`ux/usage.md`), include both spec and usage files via comma-separated `--source` to provide behavioral acceptance context

## [0.4.3] - 2026-02-28

### Fixed
- Add missing "Apply Validated Changes" step (Step 4) to `sim/run` workflow so simulation refinements are written back to original source files, not left only in the simulation cache folder

### Technical
- Update model providers in `validate-task` preset

## [0.4.2] - 2026-02-28

### Added
- Add `sim/run` workflow instruction (`handbook/workflow-instructions/sim/run.wf.md`) for codified simulation execution
- Add `ace-sim-run` Claude skill for `/ace-sim-run` invocation
- Add WFI sources registration for `wfi://sim/*` protocol discovery

## [0.4.1] - 2026-02-28

### Added
- Add built-in preset defaults so `validate-idea` and `validate-task` can run with only `--source`.
- Add default synthesis workflow/provider mappings in preset files:
  - `validate-idea` -> `wfi://idea/review` + `claude:haiku`
  - `validate-task` -> `wfi://task/review` + `claude:haiku`

### Changed
- Update README and usage docs to show source-only preset invocations.
- Update run command tests to assert default preset contract values for provider and synthesis settings.

## [0.4.0] - 2026-02-27

### Added
- Add optional final synthesis stage with `--synthesis-workflow` and `--synthesis-provider` run flags.
- Add `final/suggestions.report.md` run artifact generation with deterministic bundle/prompt/report files.
- Add `FinalSynthesisExecutor` molecule and unit tests for success/failure paths.

### Changed
- Extend simulation session/synthesis metadata with `synthesis_workflow`, `synthesis_provider`, and `final_stage`.
- Mark run as failed when final synthesis is enabled and fails.
- Update docs and CLI examples for final suggestions synthesis usage.

## [0.3.3] - 2026-02-27

### Changed
- Extract `normalize_list` helper to `Ace::Sim` module, replacing inline array normalization in CLI commands and session model
- Simplify `SourceResolver#resolve` to return minimal `{"path" => expanded}` hash
- Extract `chain_status` method from `SimulationRunner` to `SynthesisBuilder`
- Replace `value_from`/`present?`/`normalized_providers` helpers with `pick_value` and `normalize_list`
- Restore `dry_run?` predicate on `SimulationSession` and update all callers
- Remove `writeback?` predicate (use `writeback` attribute directly)
- Remove source-empty validation from `SimulationSession#validate!` (validated upstream)

## [0.3.2] - 2026-02-27

### Fixed
- Handle unhandled runtime exceptions in `SimulationRunner#run` by rescuing `StandardError` and returning structured failure result

## [0.3.1] - 2026-02-27

### Changed
- Add self-critic pattern to `plan.md` step: Phase 1 (Build) / Phase 2 (Critique) with `wfi://task/review-plan` embedding
- Add self-critic pattern to `work.md` step: Phase 1 (Execute) / Phase 2 (Critique) with `wfi://task/review-work` embedding
- Rename `<changes>` output tag to `<execution-report>` in work step for clarity

## [0.3.0] - 2026-02-27

### Added
- Enforce `--source` as a readable file path and copy source bytes directly to first-step `input.md`.
- Add strict, section-rich default step bundle templates for `draft`, `plan`, and `work` with explicit workflow/reporting structure.

### Changed
- Rewrite step runtime to markdown-first artifacts: `input.md`, `user.bundle.md`, `user.prompt.md`, `output.md`.
- Update chain execution to pass `output.md` directly into the next step as `input.md`.
- Update docs, help examples, and E2E scenario content to the markdown chain contract.

## [0.2.0] - 2026-02-27

### Changed
- Rebuilt runtime as minimal file-chained simulation: each step reads `input.yml`, writes `output.yml`, and output feeds next step.
- `ace-sim run` is now preset-driven with canonical `--preset` flag (no scenario flow).
- Added strict precedence model: CLI explicit flags override preset values, which override global defaults.
- Replaced step contract model with bundle-based step configs (`.ace/sim/steps/*.md`, fallback `.ace-defaults/sim/steps/*.md`).
- Replaced scenario defaults with preset defaults (`.ace-defaults/sim/presets/validate-idea.yml`).
- Provider execution now runs independent chains for each provider x repeat with failure isolation.

### Removed
- Scenario-specific machinery and schema-heavy step validation requirements.
- Final `result.yml` artifact path in favor of chain and synthesis artifacts.
- Default scenario file `.ace-defaults/sim/scenarios/next-phase.yml`.

## [0.1.3] - 2026-02-27

### Fixed
- Disable YAML alias parsing for untrusted LLM output (security hardening)
- Align config loading with ADR-022 pattern using Config::Models::Config.wrap
- Remove redundant `--no-writeback` CLI flag; writeback defaults to false
- Align dry-cli version constraint to `~> 1.0` matching monorepo convention

## [0.1.2] - 2026-02-27

### Fixed
- Validate `--scenario` CLI argument against configured scenarios; reject unknown scenarios with clear error
- Mark stage run as failed when ace-llm succeeds but output file is not created
- Initialize output_path before rescue block to prevent nil in error reports
- Remove redundant attr_reader shadowed by lazy initializer method

## [0.1.1] - 2026-02-27

### Added
- Initial `ace-sim` package scaffold.
- `ace-sim run` CLI for next-phase simulation execution.
- Session/stage/synthesis artifact generation under `.cache/ace-sim/simulations/`.
