# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
