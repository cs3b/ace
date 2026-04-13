# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.14.2] - 2026-04-13
### Fixed
- **ace-sim v0.14.2**: Improved run-id uniqueness by extending run-id generation and collision handling so `SimulationRunner` retries more times before failing when run directories already exist.

## [0.14.1] - 2026-04-13

### Changed
- Completed the batch i05 migration follow-through for this package and aligned it with the restarted `fast` / `feat` / `e2e` verification model.

### Technical
- Included in the coordinated assignment-driven patch release for batch i05 package updates.


### Changed
- Migrated deterministic package tests to `test/fast`, retained workflow-value E2E scenario coverage under `test/e2e`, added an E2E decision record, and aligned package docs and scenario artifact contracts with the restarted `fast` / `feat` / `e2e` model.

## [0.13.5] - 2026-03-31

### Changed
- Role-based simulation execution defaults.

## [0.13.4] - 2026-03-29

### Changed
- Role-based simulation provider defaults.


## [0.13.3] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.13.2] - 2026-03-29

### Technical
- Register package-level `.ace-defaults` skill-sources for ace-sim to enable canonical skill discovery in fresh installs.


## [0.13.1] - 2026-03-29

### Fixed
- **ace-sim v0.13.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.13.0] - 2026-03-24

### Changed
- Rewrote "How It Works" and docs to emphasize chained feedback: each step's output feeds the next, and synthesis gathers all stage feedback to propose improvements and produce revised source artifacts.
- Aligned README tagline and gemspec summary/description to unified framing.
- Added experimental status note to README.
- Removed demo GIF reference from README (dry-run hangs due to unguarded provider calls; tape has TODO).
- Updated demo tape with sandbox-free layout and TODO for dry-run fix.

## [0.12.0] - 2026-03-23

### Changed
- Refreshed `README.md` to align with the current package layout pattern, including top-level docs navigation, use-case framing, integration links, and updated feature wording.

## [0.11.1] - 2026-03-22

### Fixed
- Corrected handbook documentation links in `docs/handbook.md` so skill and workflow references resolve correctly.
- Updated usage guidance to document that `--dry-run` cannot be combined with `--writeback`, matching runtime validation behavior.

### Changed
- Re-recorded `docs/demo/ace-sim-run.gif` from the package tape so the demo reflects `ace-sim` behavior instead of a placeholder asset.

## [0.11.0] - 2026-03-22

### Added
- Rebuilt package documentation as a landing-page experience with updated README, getting-started tutorial, usage reference, and handbook catalog.

### Changed
- Added a generated VHS demo tape and screenshot for the documented getting-started workflow.
- Updated gem metadata text to reflect the new documentation-first positioning.

### Fixed
- Corrected validate-task chain phase numbering for `plan` and `work` steps so file artifacts use absolute phase indices (`02-plan`, `03-work`) when draft is intentionally omitted.
- Require explicit `--synthesis-workflow` when `--synthesis-provider` is provided, preventing preset default fallback from masking invalid provider/workflow combinations.

## [0.10.0] - 2026-03-20

### Changed
- Expanded `TS-SIM-001-next-phase-smoke` E2E coverage with two new goals: `validate-task` preset contract validation and deterministic synthesis-provider guard failure validation.
- Strengthened existing verifier assertions for help-surface flags and explicit single-step override behavior.

## [0.9.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.9.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.8.8] - 2026-03-17

### Changed
- Raised `TS-SIM-001-next-phase-smoke` E2E timeout from default to 15 minutes (`900` seconds).

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
