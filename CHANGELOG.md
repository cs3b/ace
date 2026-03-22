# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.9.911] - 2026-03-22

### Changed
- **ace-compressor v0.23.2**: Normalized installation and quick-start README examples to fenced code blocks and aligned command examples to consistent `mise exec --` execution format.
- **ace-support-nav v0.23.4**: Standardized README usage examples to consistently run `ace-nav` and `ace-test` commands via `mise exec --` for clear execution context.

## [0.9.910] - 2026-03-22

### Changed
- **ace-compressor v0.23.1**: Refreshed package README structure with dedicated purpose/install sections, preserved quick-start command coverage, and added the canonical ACE footer link.

## [0.9.909] - 2026-03-22

### Changed
- **ace-llm-providers-cli v0.26.1**: Refreshed package README structure with dedicated purpose framing, ACE-native testing guidance, updated contribution workflow notes, and canonical ACE footer linkage.

## [0.9.908] - 2026-03-22

### Changed
- **ace-integration-claude v0.3.9**: Refreshed package README structure with explicit purpose/install/usage framing, preserved legacy integration architecture notes, and added canonical ACE footer links.

## [0.9.907] - 2026-03-22

### Changed
- **ace-support-test-helpers v0.12.6**: Refreshed package README structure, preserved core usage/docs content, and added canonical ACE footer/license sections.

## [0.9.906] - 2026-03-22

### Changed
- **ace-support-nav v0.23.3**: Refreshed package README structure, added canonical `skill://` examples, and standardized ACE footer/license sections.

## [0.9.905] - 2026-03-22

### Changed
- **ace-support-models v0.8.1**: Refreshed package README structure with purpose/install/basic-usage framing and added the ACE footer link.

## [0.9.904] - 2026-03-22

### Changed
- **ace-support-markdown v0.2.2**: Refreshed package README structure, updated testing commands to `ace-test`, and added the ACE project footer link.

## [0.9.903] - 2026-03-22

### Technical
- **ace-handbook-integration-pi v0.3.2**: Standardized PI provider casing in README terminology to match package naming and changelog language.

## [0.9.902] - 2026-03-22

### Changed
- **ace-task v0.30.4**: Added task-work guidance to prefer path-mode planning and documented fallback behavior when `ace-task plan --content` stalls.

## [0.9.901] - 2026-03-22

### Technical
- **ace-handbook-integration-claude v0.3.2**: Refreshed README structure and package overview for Claude provider integration docs.
- **ace-handbook-integration-codex v0.3.1**: Refreshed README structure and package overview for Codex provider integration docs.
- **ace-handbook-integration-gemini v0.3.1**: Refreshed README structure and package overview for Gemini provider integration docs.
- **ace-handbook-integration-opencode v0.3.1**: Refreshed README structure and package overview for OpenCode provider integration docs.
- **ace-handbook-integration-pi v0.3.1**: Refreshed README structure and package overview for PI provider integration docs.

## [0.9.900] - 2026-03-22

### Technical
- **ace-support-cli v0.6.2**: Removed trailing blank lines from README code-fence examples for cleaner rendered snippets.
- **ace-support-config v0.8.5**: Updated README examples to use `resolve_file` instead of deprecated `resolve_for`.
- **ace-support-fs v0.2.3**: Updated README dependency example to the current `~> 0.2` constraint.
- **ace-support-items v0.15.3**: Updated README dependency example to the current `~> 0.15` constraint.
- **ace-support-mac-clipboard v0.2.3**: Corrected README integration guidance to reference `ace-idea` clipboard usage.

## [0.9.899] - 2026-03-22

### Changed
- **ace-test v0.5.0**: Rewrote README as a landing page, added getting-started/usage/handbook docs, added demo tape and GIF assets, and aligned gem metadata messaging.
- **ace-test-runner v0.17.0**: Rewrote README as a landing page, added getting-started/usage/handbook docs, added demo tape and GIF assets, and aligned gem metadata messaging.

### Technical
- **ace-support-core v0.28.2**: Corrected README namespace and dependency references to match `ace-support-config` API usage and gemspec version constraints.

## [0.9.898] - 2026-03-22

### Changed
- **ace-handbook v0.18.0**: Rewrote README as a landing page, added getting-started/usage/handbook docs, added demo tape and GIF assets, and aligned gem metadata messaging.

### Technical
- **ace-support-core v0.28.1**: Refreshed README structure with consistent tagline, installation, basic usage, API overview, and ACE project footer
- **ace-support-config v0.8.4**: Refreshed README structure with consistent tagline, corrected package naming, and ACE project footer
- **ace-support-fs v0.2.2**: Refreshed README structure with consistent tagline, overview, basic usage, and ACE project footer
- **ace-support-items v0.15.2**: Refreshed README structure with consistent tagline, installation, basic usage, and ACE project footer
- **ace-support-mac-clipboard v0.2.2**: Refreshed README structure with consistent tagline, overview, basic usage, and ACE project footer

## [0.9.897] - 2026-03-22

### Changed
- **ace-test-runner-e2e v0.27.0**: Rewrote README as a landing page, added getting-started/usage/handbook docs, added demo tape and GIF assets, and refreshed gemspec messaging.
- **ace-support-cli v0.6.1**: Expanded README structure with tagline, installation guidance, usage example, API overview, and ACE project footer.

## [0.9.896] - 2026-03-22

### Added
- **ace-overseer v0.10.0**: Added configurable tmux preset support for `work-on --preset work-on-tasks`, including a dedicated `cc /as-assign-drive` pane, active report-folder `nvim` pane, and `ace-task status`/`ace-assign status` pane.
- **ace-tmux v0.10.0**: Added `work-on-tasks` pane and window presets for overseer-driven assignment execution flows.

### Changed
- **ace-overseer v0.10.0**: Updated `ace-tmux` runtime dependency to `~> 0.10`.

## [0.9.895] - 2026-03-22

### Technical
- **ace-git-worktree v0.18.1**: Removed `release` template-variable support and release-based fixture assumptions from task worktree configuration, while preserving task-ID naming behavior.

## [0.9.894] - 2026-03-22

### Changed
- **ace-git-worktree v0.18.0**: Shortened default task worktree naming to `t.{task_id}` and added extraction support for `t.*`/`ace-t.*` IDs in task ID parsing paths.
- **ace-overseer v0.9.0**: Updated worktree context task-ID extraction to recognize `t.*` and `ace-t.*` worktree path naming patterns.

## [0.9.893] - 2026-03-22

### Fixed
- **ace-assign v0.36.8**: Align task completion marking with archiving behavior in single-task and batch assignment workflows; fix missed parent-archive closure in completed subtask hierarchies.

## [0.9.892] - 2026-03-22

### Fixed
- **ace-assign v0.36.7**: `mark-task-done` step now closes parent tasks when all children are done.

## [0.9.891] - 2026-03-22

### Changed
- **ace-assign v0.36.6**: Add `create-retro` as final child step in review-cycle and batch-task fork subtrees with ordering rules and review-session consumption.
- **ace-retro v0.15.2**: Add commit step and review-aware reflection prompts to the retro creation workflow.
- **ace-task v0.30.3**: Add `create-retro` to the work-on-task fork sub-steps.

## [0.9.890] - 2026-03-22

### Technical
- **ace-assign v0.36.5**: Clarified release notes so they document the intentional `codex:gpt@yolo` assignment default needed for current Codex CLI compatibility.
- **ace-git-secrets v0.12.1**: Replaced HTML-sensitive placeholder paths in getting-started examples with a concrete saved-report example.
- **ace-git-worktree v0.17.2**: Aligned the getting-started demo tape output path with the checked-in `docs/demo` asset.
- **ace-idea v0.17.3**: Aligned the demo tape output path with the checked-in asset and updated prioritize workflow wording to current queue terminology.
- **ace-llm v0.29.3**: Clarified release notes so they document why the Codex `@yolo` preset intentionally omits `--full-auto`.

## [0.9.889] - 2026-03-22

### Fixed
- **ace-assign v0.36.4**: Clarified that assignment execution remains on `codex:gpt@yolo` because the current Codex CLI cannot combine `--full-auto` with `--dangerously-bypass-approvals-and-sandbox`.
- **ace-idea v0.17.2**: Clarified docs so the `next` queue is documented as the root-scope view instead of a physical `_next` folder.
- **ace-llm v0.29.2**: Clarified that the Codex `@yolo` preset omits `--full-auto` because the current Codex CLI rejects it alongside `--dangerously-bypass-approvals-and-sandbox`.

## [0.9.888] - 2026-03-22

### Fixed
- **ace-assign v0.36.3**: Clarified the documented assignment execution default after docs drift described it as `codex:codex@yolo` instead of the intentional `codex:gpt@yolo`.
- **ace-git v0.17.1**: Added `docs/**/*` to the gemspec so package docs ship with the gem.
- **ace-git-worktree v0.17.1**: Fixed doc frontmatter, Markdown rendering, fenced code blocks, gem packaging for docs, and a duplicated usage option entry.
- **ace-idea v0.17.1**: Fixed fenced code block rendering in docs and shipped package docs with the gem.
- **ace-llm v0.29.1**: Clarified the Codex `@yolo` preset docs after changelog drift described `--full-auto` as restored when it is intentionally omitted for CLI compatibility.

## [0.9.887] - 2026-03-22

### Changed
- **ace-idea v0.17.0**: Reworked package documentation with a landing-page README, tutorial getting-started guide, full usage reference, handbook catalog, demo assets, refreshed gem metadata messaging, and updated idea workflows to match the current six-command CLI.

## [0.9.886] - 2026-03-22

### Changed
- **ace-git-secrets v0.12.0**: Reworked package documentation with a new landing-page README, tutorial getting-started guide, refreshed usage reference, handbook catalog, demo assets, shipped package docs with the gem, and corrected saved-report remediation guidance.

## [0.9.885] - 2026-03-22

### Changed
- **ace-git-worktree v0.17.0**: Rewrote the README as a landing page, added getting-started/usage/handbook docs, committed demo assets, and aligned package messaging with the new docs flow.

## [0.9.884] - 2026-03-22

### Changed
- **ace-git v0.17.0**: Rewrote the README as a landing page, added getting-started/usage/handbook docs, added demo artifacts, and refreshed gemspec metadata messaging.

## [0.9.883] - 2026-03-22

### Fixed
- **ace-test-runner v0.16.1**: Suite report-dir now includes package subdirectory so result aggregator finds reports correctly.

## [0.9.882] - 2026-03-22

### Fixed
- **ace-assign v0.36.2**: Remove trailing empty lines in documentation code blocks.
- **ace-overseer v0.8.2**: Align README messaging with actual `work-on` behavior.
- **ace-retro v0.15.1**: Add ID discovery hints to getting-started tutorial.
- **ace-tmux v0.9.2**: Restore YAML composition examples in usage docs.

## [0.9.881] - 2026-03-22

### Changed
- **ace-search v0.23.0**: Rewrote README as a landing page, added getting-started/usage/handbook docs, added demo tape and GIF, and refreshed gemspec metadata.

### Fixed
- **ace-assign v0.36.1**: Include `docs/**/*` in gemspec; remove piped command example from usage guide.
- **ace-overseer v0.8.1**: Include `docs/**/*` in gemspec so documentation ships with the gem.
- **ace-tmux v0.9.1**: Include `docs/**/*` in gemspec; fix tape output path; clarify reserved `on_project_exit` key.

## [0.9.880] - 2026-03-22

### Changed
- **ace-docs v0.28.0**: Rewrote the README as a landing page, added getting-started/usage/handbook docs, added demo artifacts, and refreshed gemspec metadata messaging.

### Added
- **ace-overseer v0.8.0**: Reworked package documentation with a new landing-page README, tutorial getting-started guide, full usage reference, handbook catalog, demo assets, and aligned gem metadata messaging.
- **ace-tmux v0.9.0**: Reworked package documentation with a new landing-page README, tutorial getting-started guide, full usage reference, handbook catalog, demo assets, and aligned gem metadata messaging.

## [0.9.879] - 2026-03-22

### Changed
- **ace-llm v0.29.0**: Rewrote README as a landing page, added getting-started/usage/handbook docs, added a demo tape, and refreshed gemspec description metadata.

### Added
- **ace-retro v0.15.0**: Reworked package documentation with a new landing-page README, tutorial getting-started guide, full usage reference, handbook catalog, demo assets, and aligned gem metadata messaging.

### Fixed
- **ace-sim v0.10.2**: Fixed validate-task chain artifact numbering so plan/work-only flows use absolute phase directories (`02-plan`, `03-work`) and continue to support existing run contracts.
- **ace-sim v0.10.1**: Enforced explicit `--synthesis-workflow` requirement when `--synthesis-provider` is set, closing an argument validation gap in `ace-sim run`.

## [0.9.878] - 2026-03-22

### Changed
- **ace-lint v0.23.0**: Rewrote the README into a landing page, added getting-started/usage/handbook docs, and introduced demo artifacts for the new docs flow.
- **ace-assign v0.36.0**: Reworked documentation experience with a new landing-page README, tutorial-style getting-started guide, updated usage reference, handbook catalog, demo assets, and aligned gem metadata messaging.
## [0.9.877] - 2026-03-21

### Technical
- **ace-bundle v0.38.1**: Documented the explicit `Date` safe-load allowance in `BundleLoader` so the wider YAML permission is explained at each parsing path.

## [0.9.876] - 2026-03-21

### Fixed
- **ace-docs v0.27.1**: Restored `Document#last_checked` compatibility by reading `ace-docs.last-checked` before falling back to legacy metadata.
- **ace-lint v0.22.1**: Restored malformed `invalid.md` fixture coverage so frontmatter negative-case checks still exercise invalid YAML.
- **ace-task v0.30.2**: Restored historical package changelog entries removed during the documentation sweep.
- **ace-test v0.4.6**: Restored historical package changelog entries removed during the documentation sweep.

### Technical
- **ace-task v0.30.2**: Removed stale projected provider skill wrappers for retired task skills.

## [0.9.875] - 2026-03-21

### Changed
- **ace-task v0.30.1**: Consolidated task workflow management by removing `task/reorganize` and routing coverage planning responsibilities out of task domain.
- **ace-test v0.4.5**: Added canonical coverage-planning workflow and skills under `wfi://test/improve-coverage` to replace task-domain coverage planning ownership.

## [0.9.874] - 2026-03-21

### Added
- **ace-git v0.16.1**: Add GitHub release publish workflow and skill for creating GitHub releases from unpublished CHANGELOG entries with daily grouping and dry-run support.
- **ace-handbook v0.17.1**: Add RubyGems publish workflow and skill for publishing ACE gems to RubyGems.org in dependency order with credential verification and dry-run support.

## [0.9.873] - 2026-03-21

### Added
- **ace-assign v0.35.1**: Added `mark-tasks-done` step to `work-on-tasks` batch preset so parent/umbrella tasks are marked done after subtask forks complete

## [0.9.872] - 2026-03-21

### Changed
- **ace-assign v0.35.0**: Added `create-retro` step to assignment presets; redesigned `verify-e2e` to run E2E tests with fix loops instead of coverage-only review; made `update-pr-desc` fork-enabled to prevent context truncation

## [0.9.871] - 2026-03-21

### Changed
- **ace-llm-providers-cli v0.26.0**: Added initial `TS-LLMCLI-001` value-gated smoke E2E coverage for `ace-llm-providers-cli-check` with deterministic no-tools and stubbed-tools command-path verification.

## [0.9.870] - 2026-03-21

### Changed
- **ace-handbook v0.17.0**: Added initial `TS-HANDBOOK-001` value-gated smoke E2E coverage for CLI help and status command contracts.

## [0.9.869] - 2026-03-21

### Changed
- **ace-compressor v0.23.0**: Added initial `TS-COMP-001` value-gated smoke E2E coverage with runner/verifier contracts and ADD/SKIP decision evidence.

## [0.9.868] - 2026-03-21

### Changed
- **ace-support-models v0.8.0**: Added initial `TS-MODELS-001` value-gated smoke E2E coverage for `ace-models` and `ace-llm-providers`, including ADD/SKIP decision evidence.

## [0.9.867] - 2026-03-21

### Changed
- **ace-demo v0.12.0**: Added initial `TS-DEMO-001` value-gated smoke E2E coverage and recorded ADD/SKIP decisions with unit-coverage evidence.

## [0.9.866] - 2026-03-21

### Changed
- **ace-retro v0.14.0**: Added initial `TS-RETRO-001` value-gated smoke E2E coverage and recorded ADD/SKIP decisions with unit-coverage evidence.

## [0.9.865] - 2026-03-21

### Changed
- **ace-task v0.30.0**: Added initial `TS-TASK-001` smoke E2E coverage for core CLI lifecycle flows (help discovery, create/show/list, archive updates, doctor health/error transitions) and recorded value-gate decisions with unit-coverage evidence.

## [0.9.864] - 2026-03-21

### Changed
- **ace-tmux v0.8.0**: Expanded `TS-TMUX-001` E2E lifecycle coverage with a new window-management goal and tightened artifact-evidence contracts for preset and session execution paths.

## [0.9.863] - 2026-03-21

### Changed
- **ace-llm v0.28.0**: Expanded `TS-LLM-001` E2E coverage with deterministic unknown-provider routing validation and tighter artifact-evidence verifier contracts for query/model-selection flows.

## [0.9.862] - 2026-03-21

### Changed
- **ace-prompt-prep v0.21.0**: Expanded `TS-PREP-001` E2E coverage with a new bundle-context goal and tightened runner/verifier artifact-evidence contracts.

## [0.9.861] - 2026-03-20

### Changed
- **ace-search v0.22.0**: Expanded `TS-SEARCH-001` E2E coverage with a new JSON-output goal and tightened runner/verifier artifact-evidence contracts.

## [0.9.860] - 2026-03-20

### Changed
- **ace-idea v0.16.0**: Expanded `TS-IDEA-001` E2E lifecycle coverage with archive-transition validation and corrected root-scope list-filter runner/verifier contracts.

## [0.9.859] - 2026-03-20

### Changed
- **ace-docs v0.27.0**: Expanded `TS-DOCS-001` E2E coverage with a new update-command goal and tightened discover/validate/status artifact-verification contracts.

## [0.9.858] - 2026-03-20

### Changed
- **ace-sim v0.10.0**: Expanded `TS-SIM-001` smoke E2E coverage with `validate-task` preset contract checks and deterministic synthesis-provider guard validation, and tightened existing verifier assertions.

## [0.9.857] - 2026-03-20

### Changed
- **ace-git v0.16.0**: Expanded `TS-GIT-001` E2E coverage with diff output-path security and deterministic status JSON/no-PR checks, and tightened PR fallback verification requirements.

## [0.9.856] - 2026-03-20

### Changed
- **ace-test-runner v0.16.0**: Tightened `TS-TEST-001` and `TS-TEST-002` E2E verifier contracts with stronger artifact and exit-evidence requirements for package, suite, and failure-propagation checks.

## [0.9.855] - 2026-03-19

### Changed
- **ace-support-nav v0.23.2**: Expanded `TS-NAV-001` help-survey E2E coverage to include `ace-nav sources` evidence and tightened error/cross-protocol verifier contracts for stronger artifact-based validation.

## [0.9.854] - 2026-03-19

### Changed
- **ace-overseer v0.7.1**: Refined `TS-OVERSEER-001` E2E verifier contracts with explicit impact-first check sections and expanded Goal 2 status coverage to require both table and JSON status evidence.

## [0.9.853] - 2026-03-18

### Changed
- **ace-bundle v0.38.0**: Consolidated TS-BUNDLE-001 output-routing E2E coverage by merging threshold and explicit `--output` override checks, reindexed CLI parity to Goal 5, and aligned scenario runner/verifier manifests to a 5-goal suite.

## [0.9.852] - 2026-03-18

### Changed
- **ace-git-commit v0.22.0**: Refined `TS-COMMIT-001` E2E runner guidance to remove cross-goal coupling and normalized verifier expectations with task-scoped review/plan/rewrite artifacts.

## [0.9.851] - 2026-03-18

### Changed
- **ace-git-secrets v0.11.0**: Expanded `TS-SECRETS-001` E2E coverage with a new `check-release` gate test case and synchronized scenario runner/verifier manifests to 8-goal execution.

## [0.9.850] - 2026-03-18

### Changed
- **ace-review v0.48.0**: Refined `TS-REVIEW-001` E2E verifier guidance with clearer impact-first structure and explicit check sections.

## [0.9.849] - 2026-03-18

### Changed
- **ace-lint v0.22.0**: Refined `TS-LINT-001` E2E runner/verifier guidance with clearer impact-first verification structure and explicit config-routing fixture expectations.

## [0.9.848] - 2026-03-18

### Changed
- **ace-b36ts v0.11.3**: Tightened E2E goal contracts (`TS-B36TS-001` Goals 5-8) with deterministic runner inputs, explicit artifact contracts, and stronger verifier evidence requirements.

## [0.9.847] - 2026-03-18

### Changed
- **ace-assign v0.34.1**: Added `unit-coverage-reviewed` decision evidence to E2E scenarios (`TS-ASSIGN-001`, `TS-ASSIGN-002`) to improve traceability between E2E coverage and unit-test coverage.

## [0.9.846] - 2026-03-18

### Fixed
- **ace-b36ts v0.11.2**: Treated naïve timestamps as UTC in `encode` while preserving explicit timezone parsing.
- **ace-bundle v0.37.2**: Fixed auto-format detection to use raw content for plain and frontmatter-preserved bundle inputs.
- **ace-test-runner v0.15.17**: Fixed `--report-dir` option precedence so explicit CLI report directories are respected.

## [0.9.845] - 2026-03-18

### Changed
- **ace-assign v0.34.0**: Renamed "phases" to "steps" throughout the assignment system — models, atoms, molecules, organisms, CLI, config, catalog (`catalog/phases/` → `catalog/steps/`, `*.phase.yml` → `*.step.yml`), file extension (`.ph.md` → `.st.md`), and YAML keys (`sub-phases` → `sub-steps`).
- **ace-overseer v0.7.0**: Updated assignment consumer references from "phase" to "step" terminology (`first_phase` → `first_step`, `current_phase` → `current_step`, `phase_summary` → `step_summary`).
- **ace-task v0.29.2**: Updated workflow frontmatter key from `sub-phases` to `sub-steps` and prose references in workflow instructions.

### Fixed
- **ace-assign v0.34.0**: `AssignmentExecutor.start` now reads `config["steps"]` matching what `AssignmentLauncher.write_job_file` writes, fixing "No phases defined in config" error in `ace-overseer work-on`.

## [0.9.844] - 2026-03-18

### Fixed
- **ace-test-runner v0.15.16**: Fixed explicit `--report-dir` handling in package execution so report artifacts no longer get forced into package-local `ace-*/results` directories.

### Technical
- **ace-test-runner v0.15.16**: Documented cleanup of temporary failure-injection fixtures used by `TS-TEST-002` E2E scenarios.

## [0.9.843] - 2026-03-18

### Changed
- **ace-support-cli v0.6.0**: Absorbed CLI infrastructure classes (Error, Base, StandardOptions, RegistryDsl) from ace-support-core; added VersionCommand.module() factory and HelpCommand args argument; Runner now raises Ace::Support::Cli::Error directly.
- **ace-support-core v0.28.0**: Removed 10 CLI wrapper/infrastructure files now canonical in ace-support-cli; kept ConfigSummaryMixin; updated ace-support-cli dep to ~> 0.6.
- **ace-assign v0.33.1, ace-b36ts v0.11.1, ace-bundle v0.37.1, ace-compressor v0.22.1, ace-demo v0.11.1, ace-docs v0.26.1, ace-git v0.15.1, ace-git-commit v0.21.6, ace-git-secrets v0.10.1, ace-git-worktree v0.16.1, ace-handbook v0.16.1, ace-idea v0.15.1, ace-lint v0.21.1, ace-llm v0.27.1, ace-overseer v0.6.1, ace-prompt-prep v0.20.1, ace-retro v0.13.1, ace-review v0.47.1, ace-search v0.21.8, ace-sim v0.9.1, ace-support-models v0.7.1, ace-support-nav v0.23.1, ace-support-test-helpers v0.12.5, ace-task v0.29.1, ace-test-runner v0.15.15, ace-test-runner-e2e v0.26.1, ace-tmux v0.7.1**: Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*`.

## [0.9.842] - 2026-03-18

### Changed
- **ace-assign v0.33.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-b36ts v0.11.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-bundle v0.37.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-compressor v0.22.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-demo v0.11.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-docs v0.26.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-git v0.15.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-git-secrets v0.10.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-git-worktree v0.16.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-handbook v0.16.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-idea v0.15.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-lint v0.21.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-llm v0.27.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-overseer v0.6.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-prompt-prep v0.20.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-retro v0.13.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-review v0.47.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-sim v0.9.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-support-core v0.27.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-support-models v0.7.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-support-nav v0.23.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-task v0.29.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-test-runner-e2e v0.26.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 
- **ace-tmux v0.7.0**: Removed legacy backward-compatibility behavior for the 0.10 compatibility cleanup. 


## [0.9.841] - 2026-03-18

### Fixed
- **ace-review v0.46.1**: Hardened feedback synthesis to preserve raw output, recover from common malformed JSON, and default synthesis to the Gemini CLI read-only provider (`gemini:flash-latest@ro`).

### Technical
- **ace-review v0.46.1**: Isolated synthesis artifacts under a dedicated review-session subdirectory and added regression coverage for JSON repair and session propagation.

## [0.9.840] - 2026-03-18

### Added
- **ace-llm v0.26.13**: Added Claude `@prompt` preset for strict prompt-only execution when a verified no-tools mode is available.

### Changed
- **ace-llm v0.26.13**: Updated Claude `@ro` to allow `Bash` and `Read` for richer read-only reviews, and documented that `@prompt` is currently provider-specific.

### Technical
- **ace-llm-providers-cli v0.25.7**: Added Claude command coverage for explicit tool allowlists supporting the `@ro` versus `@prompt` preset split.

## [0.9.839] - 2026-03-18

### Changed
- **ace-task v0.28.8**: Clarified that task-planning Claude native `--permission-mode plan` is workflow-specific and distinct from the shared `ace-llm` `@ro` execution preset.

### Fixed
- **ace-llm-providers-cli v0.25.6**: Fixed array-based CLI arg normalization so explicit empty values like Claude `--tools ""` are preserved instead of being dropped.
- **ace-llm v0.26.12**: Kept Claude `@ro` genuinely read-only without using native Claude `plan` mode, and removed misleading total-timeout status after terminal single-provider failures.

## [0.9.838] - 2026-03-18

### Fixed
- **ace-llm-providers-cli v0.25.5**: Fixed nested Claude response parsing to always persist valid output text when `result`/`response` payloads contain structured objects.

## [0.9.837] - 2026-03-18

### Changed
- **ace-review v0.46.0**: Removed review-to-task linking integration (`--task`, `--no-auto-save`, `auto_save` config, branch-based task detection, symlink creation) and simplified `PrTaskSpecResolver` branch extraction.

### Fixed
- **ace-handbook v0.15.9**: Updated `cli-support-cli.g.md` guide to remove stale `DryCli::` namespace prefix from CLI class references.

## [0.9.836] - 2026-03-17

### Fixed
- **ace-handbook v0.15.8**: Updated `cli-support-cli.g.md` examples and review timeout guidance to current APIs and behavior.
- **ace-llm-providers-cli v0.25.4**: Raised `ProviderError` with structured payload details when Claude CLI exits successfully with empty output text.
- **ace-review v0.45.3**: Fixed PR diff fallback, timeout forwarding, and raised default model timeout to 900 seconds.

### Technical
- Added regression coverage for timeout forwarding in `ace-review` and Claude empty/`is_error` response parsing in `ace-llm-providers-cli`.

## [0.9.835] - 2026-03-17

### Fixed
- **ace-llm v0.26.11**: Updated default provider context limits to match modern LLM capabilities (Anthropic 1M, OpenAI 1.05M).
- **ace-review v0.45.2**: Updated context limit resolver with Claude 1M, GPT-5.x/o4 patterns, and raised warning threshold from 160K to 800K tokens.

## [0.9.834] - 2026-03-17

### Fixed
- **ace-docs v0.25.6**: Updated CLI routing tests to match shared `ace-support-cli` help rendering.
- **ace-git v0.14.6**: Updated CLI routing tests for shared help header format and short-help behavior.
- **ace-git-worktree v0.15.7**: Updated CLI routing tests to accept `COMMANDS`/`USAGE` outputs from shared help rendering.
- **ace-prompt-prep v0.19.5**: Updated CLI routing tests for new shared help header casing and stability.
- **ace-test-runner v0.15.14**: Updated CLI help test expectations for single-command entrypoint behavior.
- **ace-tmux v0.6.3**: Updated CLI help-output assertions to match `ace-support-cli` `COMMANDS`/`EXAMPLES` headers.

## [0.9.833] - 2026-03-17

### Fixed
- **ace-llm v0.26.10**: Fix `StubAliasResolver` test construction and release unreleased alias resolution fix for global alias inputs.

## [0.9.832] - 2026-03-17

### Fixed
- **ace-support-cli v0.5.1**: Restored CLI compatibility for repeated scalar options, `key=value` hash parsing, `--` passthrough, top-level help/command lookup, usage rendering against real ACE registries, and the public `ArgvCoalescer` contract.

## [0.9.831] - 2026-03-17

### Fixed
- **ace-llm v0.26.9**: Resolve global aliases before provider validation so alias-only provider inputs (such as `glite`) are treated as valid.

## [0.9.830] - 2026-03-17

### Fixed
- **ace-llm v0.26.8**: Fixed model parsing so thinking suffixes are extracted before alias resolution, allowing `codex:gpt:high@ro` and similar identifiers to resolve correctly.
- **ace-review v0.45.1**: Removed hardcoded sandbox override from review execution and aligned the review presets to `codex:gpt@ro` model identifiers.

## [0.9.829] - 2026-03-17

### Added
- **ace-support-cli v0.5.0**: Rich `--help` interception in Parser/Runner — commands with `desc` or `examples` metadata now render structured help via Banner/Concise/TwoTierHelp formatters instead of OptionParser's bare-bones output

## [0.9.828] - 2026-03-17

### Changed
- **ace-sim v0.8.8**: Raised `TS-SIM-001-next-phase-smoke` test timeout to 15 minutes (`900` seconds).
- **ace-test-runner-e2e v0.25.0**: Added optional per-scenario `timeout` support in E2E scenarios, with scenario timeout taking precedence over suite/global timeout.

## [0.9.827] - 2026-03-17

### Fixed
- **ace-test-runner-e2e v0.24.13**: Ensure CLI E2E scenarios keep package-root references inside sandbox by provisioning package contents during pipeline setup, preventing path-not-found failures for package-bound paths.

## [0.9.826] - 2026-03-17

### Fixed
- **ace-llm-providers-cli v0.25.3**: Rescue `Errno::EPIPE` in SafeCapture stdin write to capture real errors from instant-exit subprocesses (e.g., Codex broken pipe); detect Claude CLI empty responses (exit 0, 0-byte output) and raise ProviderError; remove deprecated `--allowed-tools` flag from Gemini CLI command builder
- **ace-llm v0.26.7**: Remove `--sandbox` from Gemini `ro`/`rw` presets (requires Docker, orthogonal to approval mode); fix `rw` preset invalid `--approval-mode auto` → `auto_edit`

## [0.9.825] - 2026-03-15

### Fixed
- **ace-git-worktree v0.15.6**: Fixed `--delete-branch` flag raising "missing argument" error by replacing multi-char `-db` alias with `-D`
- **ace-overseer v0.5.6**: Restructured TC-005 prune E2E runner with strict step sequencing to prevent premature prune execution

## [0.9.824] - 2026-03-15

### Fixed
- **ace-git-worktree v0.15.5**: Fixed `list` command returning empty results after ace-support-cli migration due to nil options being treated as explicit `--no-*` filters
- **ace-overseer v0.5.5**: Removed dead `DryCli::ArgvCoalescer` call that caused NameError after migration
- **ace-search v0.21.7**: Updated E2E content-search test to use unambiguous search pattern
- **ace-sim v0.8.7**: Made E2E handoff-check comparison step explicit for reliable artifact production
- **ace-test-runner v0.15.13**: Fixed E2E report capture instructions and suite sandbox package discovery

## [0.9.823] - 2026-03-15

### Technical
- **ace-assign v0.32.4**: Optimized test suite I/O with class-level tmpdir reuse and sleep elimination

## [0.9.822] - 2026-03-15

### Added
- **ace-review v0.45.0**: Local git diff fallback when GitHub API rejects large PR diffs (HTTP 406 / 300-file limit)

### Fixed
- **ace-assign v0.32.3**: Release phase and review cycle presets now reference `wfi://release/publish` workflow

### Changed
- **ace-assign v0.32.3**: Drive workflow batch continuation rule and transient network failure retry guidance
- **ace-review v0.45.0**: Connection error retry guidance in PR review workflow

## [0.9.821] - 2026-03-15

### Changed
- **ace-support-cli v0.4.0**: Added runner improvements, registry DSL support, and parse error re-raising; removed runtime dependency on ace-support-core.
- **ace-assign v0.32.2**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-b36ts v0.10.3**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-bundle v0.36.7**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-compressor v0.21.3**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-demo v0.10.4**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-docs v0.25.5**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-git v0.14.5**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-git-commit v0.21.5**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-git-secrets v0.9.3**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-git-worktree v0.15.4**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-handbook v0.15.7**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-idea v0.14.4**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-lint v0.20.4**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-llm v0.26.6**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-overseer v0.5.4**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-prompt-prep v0.19.4**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-retro v0.12.2**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-review v0.44.5**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-search v0.21.6**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-sim v0.8.6**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-support-models v0.6.3**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-support-nav v0.22.1**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-task v0.28.7**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-test-runner v0.15.12**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-test-runner-e2e v0.24.12**: Migrated CLI framework from dry-cli to ace-support-cli.
- **ace-tmux v0.6.2**: Migrated CLI framework from dry-cli to ace-support-cli.

## [0.9.820] - 2026-03-15

### Changed
- **ace-support-core v0.26.0**: Migrated CLI infrastructure from `dry-cli` wrappers to `ace-support-cli` primitives with backward-compatible shims for downstream consumers.

## [0.9.819] - 2026-03-14

### Added
- **ace-support-cli v0.3.0**: Added a native help system with banner/usage/concise renderers, help/version command factories, and two-tier help dispatch plus component tests.

## [0.9.818] - 2026-03-13

### Added
- **ace-support-cli v0.2.0**: Added the new `ace-support-cli` package with command DSL, typed option parsing, nested registry routing, and runner primitives plus initial component tests.

## [0.9.817] - 2026-03-13

### Added
- **ace-support-core v0.25.4**: Added OptionParser spike executables under `dev/spikes/` to validate typed parsing behavior (integer/float coercion, repeated array flags, positionals, and parse-error handling) ahead of `ace-support-cli` implementation.

## [0.9.816] - 2026-03-13

### Fixed
- **ace-overseer v0.5.3**: Reject tasks with `draft` status at assignment creation time with actionable review guidance, preventing unattended forks from stalling on interactive confirmation.

### Changed
- **ace-task v0.28.6**: Clarified draft task handling in `task/work` workflow for unattended/fork contexts.

## [0.9.815] - 2026-03-09

### Fixed
- **ace-bundle v0.35.4**: Fixed `agent`-mode post-format compression for command-only/diff-only section bundles and preserved original file ordering for mixed per-source and merged section compression.

## [0.9.814] - 2026-03-09

### Fixed
- **ace-bundle v0.35.3**: Fixed section compression to use the current compressor cache-manifest API and restored rendered-content compression for plain-markdown bundle fallbacks.
- **ace-prompt-prep v0.17.4**: Fixed bundle-related test expectations to validate the current compressed-output contract instead of stale raw-markdown behavior.
- **ace-support-test-helpers v0.12.4**: Fixed temp-dir test isolation by resetting cached `Ace::Bundle` config when test helpers change working directories.

## [0.9.813] - 2026-03-09

### Fixed
- **ace-compressor v0.21.1**: Fixed ACE-native preset/protocol/config input caching and emitted `FILE|...` records so bundle-resolved runs now preserve stable logical source identity instead of using temp bundle paths.

## [0.9.812] - 2026-03-09

### Fixed
- **ace-bundle v0.35.2**: Fixed template bundles with command-only sections (e.g. `wfi://git/commit`) silently skipping compression by adding post-format in-memory compression when section-level compression is not applicable.

## [0.9.811] - 2026-03-09

### Added
- **ace-compressor v0.21.0**: Added `Ace::Compressor.compress_text(..., mode: "agent")` so in-memory text compression can use the agent engine while preserving the content-only API contract.

### Changed
- **ace-compressor v0.21.0**: Changed nested `ContextPack` fenced markdown handling to pass through structured records directly, improving recompression results for bundle-generated context files.
- **ace-bundle v0.35.1**: Refined the `project` preset for compressor-focused bundle validation and updated the runtime dependency constraint to `ace-compressor ~> 0.21`.

## [0.9.810] - 2026-03-09

### Added
- **ace-bundle v0.35.0**: Added content-only bundle compression for plain markdown files loaded via `load_file` and `load_plain_markdown`, using real resolved file paths with native cache support.

### Changed
- **ace-assign v0.31.0**: Retired hardcoded provider-tree skill defaults in favor of canonical `skill-sources` discovery and aligned assign compose/executor guidance with non-authoritative compatibility catalog behavior.

### Technical
- **ace-assign v0.31.0**: Updated resolver/executor test fixtures to canonical `handbook/skills` registration and refreshed migration language in docs.

## [0.9.809] - 2026-03-09

### Added
- **ace-bundle v0.34.0**: Added `--compressor on|off` CLI flag and global `compressor:` config section for centralized compressor defaults with CLI > preset > config precedence.
- **ace-compressor v0.20.0**: Added optional `labels:` parameter to `CacheStore#manifest` for stable cache keys independent of tmpdir filesystem paths.
- **ace-bundle v0.33.0**: Added native cache integration to `SectionCompressor`, eliminating redundant compression on repeated bundle runs with unchanged content.
- **ace-assign v0.30.0**: Added canonical workflow skills for assignment compose/create/drive/prepare/run-in-batches and expanded `skill://` discovery coverage.
- **ace-task v0.26.0**: Added canonical workflow skills across bug/docs/idea/retro/task/test domains and expanded `skill://` discovery coverage.

## [0.9.808] - 2026-03-09

### Fixed
- **ace-assign v0.31.1**: Fixed canonical assignment skill discovery to honor nav source priority while preserving package-default fallback lookup in local monorepo workflows.

- **ace-assign v0.32.1**: Corrected generated assignment phase rendering so `verify-test-suite` and `verify-e2e` persist assignment-safe phase bodies and child overlays no longer serialize malformed nested context blocks.

- **ace-b36ts v0.9.1**: Fixed the canonical `as-b36ts` skill metadata to include the required bundle declaration.

- **ace-bundle v0.36.4**: Handled frontmatter-only files in bundle section compression without dropping related sections by preserving source content and continuing the compression flow.

- **ace-compressor v0.21.2**: Preserved markdown frontmatter-only files in exact-mode compression so section compression and fixture-driven E2E runs no longer abort when a source contains only frontmatter.

- **ace-demo v0.10.1**: Registered the package WFI source so the canonical demo skills can resolve `wfi://demo/create` and `wfi://demo/record`.

- **ace-docs v0.24.1**: Fixed shipped prompt-source override guidance to use `.ace-handbook` and `~/.ace-handbook` instead of `.ace/handbook`.

- **ace-git v0.12.0**: Fixed resumed cherry-pick replay tracking by recording applied SHAs in the rebase session cache instead of relying on commit-subject matching.

- **ace-git-worktree v0.15.1**: Fixed JSON list output to stay JSON-only by suppressing CLI summary text in `--format json` mode.

- **ace-handbook v0.15.2**: Preserved the conditional sandbox execution branch when syncing canonical `as-e2e-run` skills into provider-native Claude and Codex trees.

- **ace-lint v0.18.1**: Fixed markdown linting to ignore YAML frontmatter and validated `ace-idea` as a supported canonical skill Bash prefix.

- **ace-llm-providers-cli v0.25.1**: Fixed CLI provider subprocesses and provider-side path discovery to anchor to the sandbox/root execution directory instead of leaking relative artifact writes into the repo root.

- **ace-llm-providers-cli v0.25.2**: Removed unsupported `--temperature` flag forwarding from Claude CLI adapters so generation defaults are no longer passed as CLI options.

- **ace-overseer v0.5.1**: Registered the package WFI source so the canonical overseer skill can resolve `wfi://overseer`.

- **ace-prompt-prep v0.19.1**: Registered the package WFI source so the canonical prompt-prep skill can resolve `wfi://prompt-prep`.

- **ace-sim v0.8.1**: Fixed simulation subprocess execution to use the shared core command executor, avoiding Ruby thread-read exceptions when external commands fail.

- **ace-sim v0.8.3**: Restored the built-in `validate-idea` and `validate-task` synthesis preset defaults to `claude:haiku`.

- **ace-support-core v0.25.3**: Re-exported `Ace::Core::Atoms::CommandExecutor` from `ace/core` so shared-core consumers can use the command executor without a separate direct require.

- **ace-task v0.26.1**: Fixed migrated canonical task skills to include the required strict-schema bundle/agent metadata.

- **ace-task v0.27.1**: Removed the mistaken provider-specific model override from the canonical `as-task-work` skill so task work projections keep their intended shared metadata.

- **ace-task v0.28.2**: Restored the Codex model override on `as-task-work` so the generated Codex projection uses `gpt-5.3-codex-spark`.

- **ace-test-runner v0.15.11**: Fixed suite/config bootstrap and failure propagation so `ace-test` exits non-zero on test failures and `ace-test-suite` reports missing suite configuration cleanly.

- **ace-test-runner-e2e v0.24.2**: Restored sandboxed `as-e2e-run` workflow routing, hardened verifier/result parsing against brace fragments in prose responses, and turned unstructured verifier output into deterministic error reports with failing verdict metadata.

- **ace-test-runner-e2e v0.24.4**: Fixed deterministic E2E pipeline runner and verifier invocations to pass the sandbox as the explicit working directory.


### Added
- **ace-assign v0.29.0**: Canonical skill resolution and assign-capable phase catalog reordering

- **ace-b36ts v0.10.0**: Added Codex-specific delegated execution metadata to the canonical `as-b36ts` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

- **ace-bundle v0.36.0**: Added canonical handbook-owned bundle and onboarding skills, including the new `wfi://onboard` workflow.

- **ace-demo v0.9.0**: Added canonical handbook-owned demo creation and recording skills.

- **ace-demo v0.10.0**: Added Codex-specific delegated execution metadata to the canonical `as-demo-create` and `as-demo-record` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

- **ace-docs v0.24.0**: Added canonical handbook-owned documentation workflow skills across ADR, API, user-doc, update, and changelog maintenance flows.

- **ace-docs v0.25.0**: Added Codex-specific delegated execution metadata to the canonical `as-docs-squash-changelog` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

- **ace-git v0.14.0**: Added Codex-specific delegated execution metadata to the canonical `as-github-pr-create` and `as-github-pr-update` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

- **ace-git-commit v0.21.0**: Added provider-specific Claude and Codex execution overrides to the canonical `as-git-commit` skill so projected provider skills can request forked execution with provider-specific models.

- **ace-git-worktree v0.15.0**: Added Codex-specific delegated execution metadata to the canonical `as-git-worktree` and `as-git-worktree-manage` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

- **ace-handbook v0.11.0**: Added canonical handbook-owned skills for handbook management, release workflows, and research/delivery orchestration.

- **ace-handbook v0.12.0**: Added a public `ace-handbook` CLI with provider sync/status commands and canonical skill projection services for provider-native folders.

- **ace-handbook v0.13.0**: Added canonical skill inventory counts by `source` and expanded provider sync-health reporting in `ace-handbook status`, including symlink-aware comparisons.

- **ace-handbook v0.15.0**: Added Codex-specific delegated execution metadata to the canonical `as-release-bump-version` and `as-release-update-changelog` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

- **ace-handbook-integration-agent v0.1.1**: Added the shared provider registry and projection merge helpers for provider-specific handbook integrations.

- **ace-lint v0.20.0**: Added Codex-specific delegated execution metadata to the canonical `as-lint-run` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

- **ace-llm v0.26.5**: Added `working_dir:` threading in `QueryInterface` for CLI-backed provider execution context.

- **ace-prompt-prep v0.19.0**: Added Codex-specific delegated execution metadata to the canonical `as-prompt-prep` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

- **ace-search v0.21.0**: Added Codex-specific delegated execution metadata to the canonical `as-search-run` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

- **ace-search v0.21.2**: Added a public `--count` CLI flag so count-oriented ripgrep execution is available through `ace-search`.

- **ace-support-nav v0.21.0**: Added dedicated project/user handbook override roots at `.ace-handbook` and `~/.ace-handbook`, including default `ace-nav create` targets under the new project root.

- **ace-support-nav v0.22.0**: Added explicit rooted source discovery for protocol registries, enabling nav-backed handbook skill inventory outside process-cwd assumptions.

- **ace-task v0.25.0**: Mark as-task-plan as assign-capable skill

- **ace-task v0.28.0**: Added Codex-specific delegated execution metadata to the canonical `as-release-navigator` and `as-task-finder` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

- **ace-test v0.4.0**: Added Codex-specific delegated execution metadata to the canonical `as-test-verify-suite` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

- **ace-git v0.13.0**, **ace-git-commit v0.20.0**, **ace-git-secrets v0.9.0**, and **ace-git-worktree v0.14.0**: Added canonical handbook-owned git workflow skills across commit, rebase, PR, security audit, and worktree management flows.

- **ace-handbook-integration-claude v0.1.1**, **ace-handbook-integration-codex v0.1.1**, **ace-handbook-integration-gemini v0.1.1**, **ace-handbook-integration-opencode v0.1.1**, and **ace-handbook-integration-pi v0.1.1**: Added provider-specific handbook integration packages on top of the shared integration base.

- **ace-handbook-integration-claude v0.2.0**, **ace-handbook-integration-codex v0.2.0**, **ace-handbook-integration-gemini v0.2.0**, **ace-handbook-integration-opencode v0.2.0**, and **ace-handbook-integration-pi v0.2.0**: Added shipped provider manifests and packaging support so handbook sync can discover and project provider-specific skill directories.

- **ace-overseer v0.5.0**, **ace-prompt-prep v0.18.0**, **ace-retro v0.12.0**, **ace-review v0.44.0**, **ace-search v0.20.0**, **ace-sim v0.8.0**, **ace-task v0.27.0**, **ace-test v0.3.0**, and **ace-test-runner-e2e v0.24.0**: Added canonical handbook-owned skills and workflow entrypoints for their agent-facing package capabilities.


### Changed
- **ace-assign v0.31.2**: Updated assignment E2E fixtures and hierarchy verification guidance to match the current `phases:` schema and copied auto-completion report artifacts.

- **ace-assign v0.31.3**: Added pre-flight fixture checks for `TC-005-no-skip-policy` and sandbox setup artifacts in `TS-ASSIGN-001`.

- **ace-assign v0.31.4**: Updated canonical assign skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-assign v0.31.5**: Completed canonical assign skill catalog composition and workflow-backed phase metadata wiring for public assignments.

- **ace-assign v0.32.0**: Switched generated public assignment phases to workflow-backed execution references and restored essential preset orchestration overlays for `work-on-task` and `work-on-tasks`.

- **ace-b36ts v0.10.1**: Removed Codex-specific delegated execution metadata from the canonical `as-b36ts` skill so provider projections inherit the canonical body unchanged.

- **ace-b36ts v0.10.2**: Updated the canonical `as-b36ts` skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

- **ace-bundle v0.36.1**: Updated bundle workflow guidance to use direct `ace-bundle` invocations instead of legacy slash-command examples.

- **ace-bundle v0.36.5**: Updated the canonical bundle and onboarding skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-bundle v0.36.6**: Updated canonical onboarding skill metadata for in-project workflow execution flow.

- **ace-demo v0.10.2**: Removed Codex-specific delegated execution metadata from the canonical `as-demo-create` and `as-demo-record` skills so provider projections inherit the canonical body unchanged.

- **ace-demo v0.10.3**: Updated canonical demo skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-docs v0.25.1**: Updated handbook guide and README examples to use current gem-scoped handbook paths and bundle-first workflow references.

- **ace-docs v0.25.2**: Removed Codex-specific delegated execution metadata from the canonical `as-docs-squash-changelog` skill so provider projections inherit the canonical body unchanged.

- **ace-docs v0.25.3**: Updated canonical docs skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-docs v0.25.4**: Updated canonical docs skills to align with shared workflow execution standards.

- **ace-git v0.12.0**: Changed the rebase workflow to keep localized conflicts on the normal rebase path and reserve cherry-pick for repeated, large, or user-requested conflict handling.

- **ace-git v0.14.1**: Updated README and handbook guide examples to load workflows through `ace-bundle` and removed legacy shared-handbook path assumptions.

- **ace-git v0.14.2**: Replaced provider-specific Codex execution metadata on `as-github-pr-create`, removed it from `as-github-pr-update`, and limited provider-specific forking to Claude frontmatter.

- **ace-git v0.14.3**: Updated canonical git workflow skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-git v0.14.4**: Updated canonical Git workflow skills for workflow-first execution compatibility.

- **ace-git-commit v0.21.1**: Updated README prompt-path guidance to reference the package-local handbook prompt source.

- **ace-git-commit v0.21.2**: Updated the canonical `as-git-commit` Codex metadata to use `context: ace-llm` with frontmatter-driven variable and instruction rendering in projected Codex skills.

- **ace-git-commit v0.21.3**: Replaced provider-specific Codex execution metadata on `as-git-commit` with a unified canonical skill body and limited provider-specific forking to Claude frontmatter.

- **ace-git-commit v0.21.4**: Harmonized canonical git-commit skill structure with unified execution contract.

- **ace-git-secrets v0.9.1**: Updated README remediation guidance to load the token-remediation workflow through `ace-bundle`.

- **ace-git-secrets v0.9.2**: Updated canonical git security skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-git-worktree v0.15.2**: Removed Codex-specific delegated execution metadata from the canonical worktree skills so provider projections inherit the canonical body unchanged.

- **ace-git-worktree v0.15.3**: Updated canonical worktree skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-handbook v0.14.0**: Changed canonical skill inventory and handbook status/sync projection inputs to use registered `skill://` sources through `ace-support-nav` instead of direct monorepo package scans.

- **ace-handbook v0.15.1**: Updated handbook README, workflow docs, and guidance to document bundle-first workflow usage and the current handbook structure.

- **ace-handbook v0.15.3**: Rendered Codex `ace-llm` skills from canonical frontmatter by deriving variables from `argument-hint` and generating `## Variables` / `## Instructions` sections in projected Codex skills.

- **ace-handbook v0.15.4**: Strengthened projected workflow skill instructions for Codex delegated execution and forked provider contexts so generated provider skills explicitly load and execute workflows in the current project instead of only reading or summarizing them.

- **ace-handbook v0.15.5**: Removed provider-specific skill body rendering and simplified handbook projection coverage around frontmatter overrides plus canonical body preservation.

- **ace-handbook v0.15.6**: Updated handbook-owned canonical skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-handbook-integration-claude v0.3.1**: Updated the canonical Claude integration sync skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

- **ace-idea v0.14.2**: Updated idea-lifecycle E2E guidance to capture created idea file content and frontmatter as explicit verification artifacts.

- **ace-idea v0.14.3**: Updated the canonical idea review skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

- **ace-integration-claude v0.3.7**: Updated legacy integration metadata documentation to describe direct provider projections from canonical package skills.

- **ace-integration-claude v0.3.8**: Updated the legacy integration README to clarify replacement-package status and current canonical skill ownership and projection boundaries.

- **ace-lint v0.19.0**: Added canonical skill validation support for provider-specific integration metadata and expanded the allowlist for migrated handbook skill tools.

- **ace-lint v0.20.1**: Updated README examples to reference current handbook skill and workflow paths instead of legacy provider-local example locations.

- **ace-lint v0.20.2**: Removed Codex-specific delegated execution metadata from the canonical `as-lint-run` skill so provider projections inherit the canonical body unchanged.

- **ace-lint v0.20.3**: Updated canonical lint skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-llm v0.26.4**: Updated the handbook LLM reference guide to describe canonical package `handbook/skills/` ownership before provider projections.

- **ace-llm-providers-cli v0.24.0**: Changed PI skill discovery to use `.pi/skills` as the provider-native directory without `.agent/skills` fallback.

- **ace-llm-providers-cli v0.25.0**: Changed Codex skill discovery to use `.codex/skills` as the provider-native directory without legacy `.agent/skills` or `.claude/skills` fallback.

- **ace-overseer v0.5.2**: Updated the canonical overseer skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

- **ace-prompt-prep v0.19.2**: Removed Codex-specific delegated execution metadata from the canonical `as-prompt-prep` skill so provider projections inherit the canonical body unchanged.

- **ace-prompt-prep v0.19.3**: Updated the canonical prompt-prep skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

- **ace-retro v0.12.1**: Updated the canonical handbook self-improvement skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

- **ace-review v0.44.1**: Updated review workflow instructions to reference bundle-first review flows instead of slash-command examples.

- **ace-review v0.44.2**: Updated the dry-run error-handling E2E scenario so invalid-model captures are treated as prepared-session output rather than validation failures.

- **ace-review v0.44.3**: Updated canonical review skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-review v0.44.4**: Updated canonical review skills to rely on workspace workflow execution flow.

- **ace-search v0.21.1**: Updated handbook search-agent examples to use current `ace-*/handbook/**/*` paths instead of legacy shared handbook locations.

- **ace-search v0.21.3**: Replaced provider-specific Codex execution metadata on `as-search-run` with a unified canonical skill body and limited provider-specific forking to Claude frontmatter.

- **ace-search v0.21.4**: Updated canonical search research skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-search v0.21.5**: Updated canonical search workflow skill metadata for bundled workflow execution.

- **ace-sim v0.8.2**: Updated the full-chain synthesis E2E scenario to verify aggregated step inputs and recorded final-stage outcomes, including cleanly captured external synthesis failures.

- **ace-sim v0.8.4**: Updated the `TS-SIM-001` default preset E2E scenario to verify preset contract and chain handoff behavior while allowing either successful synthesis or a cleanly recorded final-stage failure.

- **ace-sim v0.8.5**: Updated the canonical simulation skill to explicitly run its bundled workflow in the current project and execute it end-to-end.

- **ace-task v0.28.1**: Updated task and bug workflow guidance to reference bundle-first follow-up workflows and current canonical handbook path examples.

- **ace-task v0.28.3**: Removed Codex-specific delegated execution metadata from the canonical `as-task-finder` and `as-task-work` skills so provider projections inherit the canonical body unchanged.

- **ace-task v0.28.4**: Updated canonical task, bug, docs, retro, idea, and test skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-task v0.28.5**: Updated canonical task skills to support unified skill + workflow execution patterns.

- **ace-test v0.4.1**: Updated README and workflow guidance to use direct `ace-bundle` workflow loading instead of legacy slash-command references.

- **ace-test v0.4.2**: Removed Codex-specific delegated execution metadata from the canonical `as-test-verify-suite` skill so provider projections inherit the canonical body unchanged.

- **ace-test v0.4.3**: Updated canonical test-planning and suite-health skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-test v0.4.4**: Updated canonical test planning skills for direct workflow execution in this project.

- **ace-test-runner v0.15.10**: Updated `ace-test` E2E guidance to verify single-file and group-scoped runs from captured commands and report artifacts instead of brittle stdout wording.

- **ace-test-runner-e2e v0.24.1**: Updated README and E2E workflow documentation to use `ace-bundle` and `ace-test-e2e` examples instead of slash-command orchestration.

- **ace-test-runner-e2e v0.24.3**: Changed the default suite report-generation model in project E2E config to `codex:spark`.

- **ace-test-runner-e2e v0.24.5**: Updated the project E2E suite report-generation default model override to `claude:sonnet@ro`.

- **ace-test-runner-e2e v0.24.6**: Updated the `e2e/fix` workflow and canonical `as-e2e-fix` skill to require reruns after each fix iteration and a final `ace-test-e2e-suite --only-failures` checkpoint before closing a fix session.

- **ace-test-runner-e2e v0.24.7**: Increased the default E2E suite parallelism setting in project config from `6` to `8`.

- **ace-test-runner-e2e v0.24.8**: Removed the stale fork-context comment from `as-e2e-run` so only the selected Claude-fork skills retain provider-specific fork metadata.

- **ace-test-runner-e2e v0.24.9**: Updated `e2e/fix` workflow guidance for explicit scenario-level reruns and fixed experience report status mapping for pass/error outcomes.

- **ace-test-runner-e2e v0.24.10**: Updated canonical E2E workflow skills to explicitly run bundled workflows in the current project and execute them end-to-end.

- **ace-test-runner-e2e v0.24.11**: Updated canonical E2E workflow skills for workspace-based execution flow.

- **ace-handbook-integration-claude v0.3.0**, **ace-handbook-integration-codex v0.3.0**, **ace-handbook-integration-gemini v0.3.0**, **ace-handbook-integration-opencode v0.3.0**, and **ace-handbook-integration-pi v0.3.0**: Removed the deprecated shared integration-base dependency and made each provider package a thin plugin on top of `ace-handbook`.


### Technical
- **ace-bundle v0.35.5**: Hardened the invalid `bundle.pr` regression test to stub PR metadata fetches and validate the real loader error path without live GitHub access.

- **ace-bundle v0.36.2**: Added regression coverage for the restored demo, overseer, and prompt-prep WFI targets so `ace-bundle` continues to load those workflow-backed skills correctly.

- **ace-bundle v0.36.3**: Forced exact-mode compression in test execution paths so suite runtime no longer invokes the agent compressor path by default.

- **ace-handbook v0.13.1**: Added regression coverage for the `.agent/skills` retirement so provider sync/status validation now assumes provider-native skill trees only.

- **ace-handbook v0.14.1**: Updated provider sync regression coverage to verify provider-specific execution overrides on projected git-commit skills and to keep generated provider skills free of canonical `integration` metadata.

- **ace-handbook v0.15.6**: Refreshed provider sync and status collector regression coverage for the new compact canonical skill execution template.

- **ace-lint v0.19.1**: Expanded canonical skill validation fixtures to cover provider-specific execution overrides such as `context: fork` and provider model hints under `integration.providers.<provider>.frontmatter`.

- **ace-lint v0.20.3**: Updated markdown-linter fixture coverage for the new compact canonical skill execution template.

- **Project nav config**: Added the missing `.ace/nav/protocols/skill-sources/*.yml` registrations so this workspace activates the full canonical skill set through `skill://`.

- Coordinated release of `ace-assign` with phase-template rendering support and merged canonical/local assignment phase metadata preservation.

- Coordinated release of `ace-assign` with workflow-first phase materialization, parser/runtime `workflow` support, and updated assignment regression coverage.

- Coordinated release of all modified ACE packages.


## [0.9.807] - 2026-03-09

### Added
- **ace-bundle v0.32.0**: Added `--compressor-mode` and `--compressor-source-scope` CLI options with preset-level configuration for inline section compression using ace-compressor's exact and agent engines.
- **ace-compressor v0.19.2**: Added `compress_text` convenience method for in-memory text compression without filesystem access.
- **ace-assign v0.28.0**: Added `skill-sources` gem defaults registration so `skill://` can discover canonical `handbook/skills` entries from `ace-assign`.
- **ace-b36ts v0.9.0**: Added `skill-sources` gem defaults registration so `skill://` can discover canonical `handbook/skills` entries from `ace-b36ts`.
- **ace-task v0.24.0**: Added `skill-sources` gem defaults registration so `skill://` can discover canonical `handbook/skills` entries from `ace-task`.
- **ace-test-runner-e2e v0.23.0**: Added `skill-sources` gem defaults registration so `skill://` can discover canonical `handbook/skills` entries from `ace-test-runner-e2e`.

### Changed
- **ace-support-nav v0.20.0**: Added canonical `skill://` scanner/CLI regression coverage and switched default `skill-sources` registration to gem-backed canonical discovery config.

### Fixed
- **ace-bundle v0.32.0**: Fixed `compressor_mode: agent` crash - agent mode now works through the file-based compression path, producing correctly compressed output distinct from exact mode.

## [0.9.806] - 2026-03-09

### Added
- **ace-llm-providers-cli v0.23.0**: Generalized provider skills directory resolution with multi-path fallback for projected skill trees

### Fixed
- **ace-compressor v0.19.1**: Fixed temporary directory leak in `InputResolver` and removed dead code.

## [0.9.805] - 2026-03-09

### Added
- **ace-compressor v0.19.0**: Added `--source-scope` (`merged|per-source`) so protocol/preset/file inputs can emit one compressed output per resolved source in stable order.
- **ace-lint v0.18.0**: Added canonical SKILL schema enforcement for `skill.kind` and `skill.execution.workflow`, plus nested metadata validation for canonical ACE skill contracts.

### Changed
- **ace-integration-claude v0.3.6**: Updated metadata field reference docs with canonical `skill` and `assign` schema guidance.
- **ace-test-runner-e2e v0.22.1**: Updated `as-e2e-run` skill metadata to include canonical workflow typing fields.
- **ace-compressor v0.19.0**: Updated input resolution so protocol URLs (`wfi://...`) are routed through `ace-bundle` instead of being treated as missing filesystem paths.
- **ace-compressor v0.19.0**: Updated usage guidance for per-source mode, including multi-input output-path constraints and invocation examples.

### Technical
- **ace-compressor v0.19.0**: Expanded command/runner/resolver regression coverage for per-source output ordering, invalid scope errors, and unresolved protocol failures.
- **ace-llm-providers-cli v0.22.2**: Added `SkillNameReader` regression coverage for canonical nested SKILL frontmatter and malformed-frontmatter tolerance.

## [0.9.804] - 2026-03-09

### Added
- **ace-compressor v0.18.0**: Added ACE-native input resolution so `ace-compressor compress` accepts preset names and YAML bundle config files directly.
- **ace-b36ts v0.8.0**: Added canonical capability skill example at `handbook/skills/as-b36ts/SKILL.md` with `wfi://b36ts` binding.
- **ace-task v0.23.0**: Added canonical workflow skill example at `handbook/skills/as-task-plan/SKILL.md` with `wfi://task/plan` binding.
- **ace-assign v0.27.0**: Added canonical orchestration skill example at `handbook/skills/as-assign-start/SKILL.md` and restored `assign/start` compatibility workflow binding.
- **ace-support-nav v0.19.0**: Added canonical `skill://` protocol defaults and `skill-sources` scaffold for `handbook/skills` discovery.

### Changed
- **ace-assign v0.27.0**: Added projected provider-facing `.agent/skills/as-assign-start/SKILL.md` for representative orchestration skill parity.
- **ace-compressor v0.18.0**: Normalized preset/config inputs before mode dispatch while preserving existing ContextPack output shape and multi-source merge behavior.
- **ace-compressor v0.18.0**: Updated usage docs with preset/config invocation examples, mixed input handling, and clearer resolver failure semantics.

### Fixed
- **ace-compressor v0.18.0**: Fixed cache canonical stem derivation for resolver-generated external sources, preventing runtime crashes in preset/config flows.

### Technical
- **ace-compressor v0.18.0**: Added molecule/command regression coverage for input auto-detection, error propagation, and external-source cache path handling.

## [0.9.803] - 2026-03-09

### Added
- **ace-compressor v0.17.0**: Added a public `benchmark` command that compares `exact`, `compact`, and `agent` output on live sources with retention coverage against the exact baseline.
- **ace-compressor v0.17.0**: Added configurable shared per-machine workflow caching so stable handbook workflow files can be reused across worktrees on the same machine.

### Changed
- **ace-compressor v0.17.0**: Updated CLI/cache behavior so shared workflow cache hits are hydrated into the normal local canonical path while preserving existing `compress` output semantics.

### Technical
- **ace-compressor v0.17.0**: Added dedicated benchmark/retention-report internals and regression coverage for benchmark output plus cross-project workflow cache reuse.

## [0.9.802] - 2026-03-09

### Changed
- **ace-compressor v0.16.0**: Tightened exact-mode workflow compression by shortening long narrative `LIST|...` items and collapsing script-like shell fences into compact `CODE|bash|...` records.

### Technical
- **ace-compressor v0.16.0**: Added transformer regression coverage for the new list/shell normalization rules and refreshed cache contracts so exact/compact/agent workflow artifacts are rebuilt.

## [0.9.801] - 2026-03-09

### Added
- **ace-compressor v0.15.0**: Added deterministic list-item compaction so agent mode shrinks long `LIST|...` payloads while preserving one-to-one item identity.

### Changed
- **ace-compressor v0.15.0**: Replaced escaped-markdown table storage with semantic `cols=` and `rows=` table encoding, cutting table-heavy exact/agent packs such as `docs/tools.md`.

### Technical
- **ace-compressor v0.15.0**: Updated cache contracts and regression coverage for structured table records and list-item compaction behavior.

## [0.9.800] - 2026-03-08

### Fixed
- **ace-compressor v0.14.0**: Moved agent-mode model/template defaults into config and `tmpl://` resources, and eliminated prompt leakage by rebuilding agent mode as payload-only rewriting over exact output.

### Changed
- **ace-compressor v0.14.0**: Agent mode now keeps `ContextPack` structure deterministic while compacting `SUMMARY|`, `FACT|`, and long `LIST|...` payloads so sample docs compress beyond exact mode without refusal/fallback wrappers.

### Technical
- **ace-compressor v0.14.0**: Updated agent tests/docs/cache contract for JSON payload rewriting and added regression coverage against prompt scaffolding appearing in generated packs.

## [0.9.799] - 2026-03-08

### Fixed
- **ace-git-commit v0.19.2**: Hardened split-commit batch message generation with strict JSON parsing/validation and explicit repair retry handling.
- **ace-git-commit v0.19.2**: Removed generic `chore: update <scope>` fallback by using per-scope message generation when batch parsing fails.

### Changed
- **ace-git-commit v0.19.2**: Strengthened commit prompt guidance to reduce overuse of generic `chore` messages for feature and fix changes.

### Technical
- **ace-git-commit v0.19.2**: Added regression coverage for strict batch parsing, retry behavior, and per-scope fallback message generation.

## [0.9.798] - 2026-03-08

### Fixed
- **ace-assign v0.26.0**: Corrected status `FORK` semantics to represent `context: fork` instead of child-count presence.
- **ace-assign v0.26.1**: Fixed fork leaf execution startup by marking scoped leaf roots `in_progress` before launcher handoff, preventing pending-state drift and repeated self-fork attempts.
- **ace-assign v0.26.1**: Scoped status views for completed fork phases no longer print actionable fork-run execution instructions.
- **ace-review v0.43.8**: Fixed review preset discovery for temp-dir callers by resolving config/presets from the explicit project root plus gem-default preset files, preventing `ContextExtractor` crashes after the `ace-support-fs` project-root hardening.
- **ace-support-fs v0.2.1**: Fixed project-root detection so `PROJECT_ROOT_PATH` is only used when it encloses the active start path, preventing traversal from honoring unrelated roots.

### Added
- **ace-assign v0.25.0**: Added explicit phrase-intent metadata for compose phase resolution and introduced new `squash-changelog` and `rebase-with-main` catalog phases mapped to existing docs/git skills.
- **ace-assign v0.26.0**: Added batch scheduling metadata and `--max-parallel` contract guidance for controlled fork fan-out orchestration.
- **ace-compressor v0.13.0**: Added explicit degraded-success fallback metadata (`FALLBACK|source=...|from=agent|to=exact|...`) for agent-mode provider/validation failures.
- **ace-demo v0.8.0**: Added `ace-demo retime` for postprocessing GIF/MP4/WebM recordings into faster playback variants with validated playback speeds.
- **ace-demo v0.8.0**: Added a reusable `assign-drive-showcase` demo tape to demonstrate batch delegation and assignment driving flow.
- **ace-docs v0.23.0**: Added package/glob scoped document selection via repeatable `--package` and `--glob` options across status/discover/update/validate/analyze-consistency workflows.

### Changed
- **ace-assign v0.25.0**: Reworked `assign/create` and `assign/compose` workflows to treat explicit user steps as primary intent, apply hard ordering with named-rule explanations, and preserve runtime `assign.source` phase expansion boundaries.
- **ace-assign v0.25.1**: Removed the legacy `as-assign-start` compatibility entrypoint and retired the `assign/start` workflow in favor of the existing public create/drive flow.
- **ace-assign v0.26.0**: Updated batch/drive workflow guidance so sequential mode still forks each item and parallel mode documents retry-then-stop handling.
- **ace-assign v0.26.1**: Clarified `assign/drive` delegation boundaries to forbid re-running `fork-run` for the same already-entered scoped root.
- **ace-assign v0.26.2**: Clarified batch-parallel scheduling semantics so `max_parallel` is treated as a rolling in-flight concurrency cap with immediate slot refill guidance in assignment drive workflows.
- **ace-compressor v0.13.0**: Changed agent failure handling to emit exact-mode fallback artifacts with fidelity evidence and zero-exit degraded semantics.
- **ace-compressor v0.13.0**: Updated cache contract keying and CLI/runtime reporting so degraded agent fallback is both machine-detectable and user-visible.
- **ace-demo v0.8.0**: Extended `ace-demo record` with playback-speed postprocessing (CLI + config fallback) while preserving original artifacts and attaching retimed outputs for PR demo uploads.
- **ace-docs v0.23.0**: Applied scoped selection during registry discovery and updated docs/update workflow guidance and CLI usage examples for scoped operations.

### Technical
- **ace-assign v0.25.0**: Added composition-order rules for changelog-squash/rebase sequencing (`squash-before-rebase`, `rebase-before-push`, `rebase-before-update-pr`) to keep reorder behavior explainable.
- **ace-assign v0.26.1**: Added command-level regression tests for leaf fork activation and scoped done-phase status rendering.
- **ace-assign v0.26.2**: Added/normalized frontmatter tracking on package user/guide docs (`README.md`, `docs/usage.md`, `handbook/guides/fork-context.g.md`) for consistent `ace-docs` management.
- **ace-bundle v0.31.12**: Updated top-level preset composition integration coverage to assert `BundleData` composition metadata via `metadata` while keeping rendered output assertions content-focused.
- **ace-compressor v0.13.0**: Expanded organism/runner/command regression coverage for degraded fallback output and exit-code behavior.
- **ace-demo v0.8.0**: Added parser/retimer test coverage and updated demo docs/workflows for retime setup, usage, and postprocess defaults.
- **ace-docs v0.23.0**: Added scope normalization and scoped selection regression tests, and reduced expected no-frontmatter loader noise in scoped command output.
- **ace-review v0.43.8**: Added regression coverage for gem-default preset discovery and temp-dir file-path context extraction.
- **ace-support-fs v0.2.1**: Added regression tests for env-root fallback behavior and stabilized traversal molecule fixtures against ambient system config directories.

## [0.9.797] - 2026-03-08

### Added
- **ace-handbook v0.10.0**: Added `release/publish` as the coordinated multi-package release workflow, including modified-package auto-detection and shared package/root changelog updates.
- **ace-assign v0.24.0**: Added `codex` to the default subtree native-review client allow-list so `pre-commit-review` can run native `/review` in Codex runtimes.
- **ace-compressor v0.12.0**: Added a dedicated single-source agent minification template resource and handbook template path for prompt-composed `--mode agent` execution.

### Changed
- **ace-compressor v0.12.0**: Hardened agent-mode output contract validation (required record families, numeric fidelity, semantic payload checks, summary-collapse rejection, and size gate vs exact baseline).
- **ace-compressor v0.12.0**: Added single-source normalization/guardrails for source scopes and rule-heavy semantic backfill so `docs/vision.md`, `docs/architecture.md`, and `docs/decisions.md` succeed under `--mode agent`.

### Fixed
- **ace-assign v0.23.1**: Fixed assignment release guidance so `release*` phases publish all modified packages through `/as-release`, including suffixed review-cycle release steps.

### Technical
- **ace-task v0.22.2**: Updated project-management and roadmap docs to use the canonical `release/publish` workflow references.
- **ace-assign v0.24.0**: Updated assignment-executor regression fixtures to the current `wfi://task/work` assign-source and `ace-task` workflow-path layout.
- **ace-compressor v0.12.0**: Expanded agent-mode organism regression coverage for command/example retention, numeric token validation, summary/semantic failure paths, rule-heavy success, and size-gate behavior.

## [0.9.796] - 2026-03-08

### Added
- **ace-compressor v0.11.0**: Added `agent` mode spike path with protocol-composed prompt assembly (`ace-bundle`), `ace-llm` execution, validator-visible fidelity/refusal markers, and explicit concept-inventory records.

### Changed
- **ace-assign v0.23.0**: Consolidated public assignment guidance on `as-assign-create` + `as-assign-drive`, documented workflow-level `--run` handoff behavior, and demoted legacy `as-assign-prepare` / `as-assign-start` skills from public invocability.
- **ace-compressor v0.11.0**: Extended CLI/runner mode support to include `--mode agent` and mode-aware refusal messaging.
- **ace-compressor v0.11.0**: Updated usage docs for representative single-source agent validation flow and deferred-scope guidance.

### Fixed
- **ace-task v0.22.1**: Removed stale `task.plan.cli_args` provider mapping from `ace-task plan` so plan generation now follows `provider:model@preset` directly after migration.

### Technical
- **ace-idea v0.14.1**: Removed obsolete doctor CLI test coverage for deleted `provider_cli_args` behavior and corrected quiet-mode unhealthy test block closure.
- **ace-compressor v0.11.0**: Added focused organism/runner/command tests for agent-mode pass/fail/provider-unavailable scenarios.

## [0.9.795] - 2026-03-08

### Fixed
- **ace-overseer v0.4.21**: Restored resilience for stale/prunable worktree paths by recovering `work-on` provisioning after metadata drift and preventing `prune` from crashing on missing worktree directories.

### Changed
- **ace-overseer v0.4.21**: `prune` now performs pre-scan stale-metadata cleanup and limits default scans to task-associated worktrees unless explicit targets are provided.

## [0.9.794] - 2026-03-08

### Technical
- **ace-assign v0.22.7**: Stabilized create-command path-relativity tests under `mise` by scoping `PROJECT_ROOT_PATH` to test temp roots and clearing cached project-root resolution.

## [0.9.793] - 2026-03-08

### Fixed
- **ace-assign v0.22.6**: Child-phase injection now rebalances active execution from a newly blocked parent to the next workable child in the subtree, restoring hierarchical completion flows in TS-ASSIGN-002 auto-completion scenarios.

### Technical
- **ace-assign v0.22.6**: Added pending-state writer helper and regression coverage for parent/child/grandchild rebalance paths, and hardened TS-ASSIGN-002 fork-scope verification to use JSON status oracles.

## [0.9.792] - 2026-03-07

### Technical
- **ace-assign v0.22.5**: Updated create-command test setup to run under temporary cache paths so `Created:` output remains relative when expected.

## [0.9.791] - 2026-03-07

### Technical
- **ace-assign v0.22.4**: Consolidated root changelog ordering and removed duplicate/no-op entries; added a package release entry for changelog cleanup and test-temp-dir consistency updates.

## [0.9.790] - 2026-03-07

### Technical
- **ace-compressor v0.10.3**: Applied shine-cycle polish in compact mode by adding class-level docs and replacing table-strategy magic numbers with named constants.

## [0.9.789] - 2026-03-07

### Technical
- **ace-compressor v0.10.2**: Completed fit-cycle release step for PR #243; no actionable feedback items remained after review-feedback synthesis retries.

## [0.9.788] - 2026-03-07

### Technical
- **ace-compressor v0.10.1**: Completed valid-cycle release pass for PR #243 after correctness review found no pending medium+ feedback items.

## [0.9.787] - 2026-03-07

### Fixed
- **ace-assign v0.22.2**: Normalized `ace-assign create` output path formatting so the `Created:` and hidden-spec provenance lines use consistent path rendering.

### Added
- **ace-compressor v0.10.0**: Added explicit compact reduction metadata records for loss and deduplicated examples (`LOSS|...`, `EXAMPLE_REF|...`).

### Changed
- **ace-compressor v0.10.0**: Compact table output now declares per-table strategy (`preserve`, `schema_plus_key_rows`, `summarize_with_loss`) and reports retained/original data-row counts explicitly.

### Technical
- **ace-compressor v0.10.0**: Expanded compact-mode command/organism tests for strategy/loss signaling and mimicry-sensitive example handling.
- **ace-assign v0.22.2**: Added regression tests covering relative create output formatting and legacy `phases/` source-config preservation.

## [0.9.786] - 2026-03-07

### Added
- **ace-compressor v0.9.0**: Added mixed-source compact behavior with explicit fidelity/refusal metadata (`FIDELITY|`, `REFUSAL|`, `GUIDANCE|`) and mixed-doc rule-preservation handling (`action=compact_with_exact_rule_sections`).

### Changed
- **ace-compressor v0.9.0**: Compact mode now preserves safe-source output when another source refuses and returns non-zero when refusal metadata is present.
- **ace-compressor v0.9.0**: Added optional `ace-compressor compress ...` compatibility while retaining direct `ace-compressor <sources...>` usage.

### Technical
- **ace-compressor v0.9.0**: Expanded classifier/organism/command coverage for mixed-doc fidelity pass, rule-heavy refusal, and partial-failure exit semantics.

## [0.9.785] - 2026-03-07

### Added
- **ace-compressor v0.8.0**: Added compact narrative mode with runtime policy metadata (`POLICY|class=...|action=...`) and deterministic classification for `narrative-heavy` vs `unknown` sources.
- **ace-assign v0.22.0**: `ace-assign create` now surfaces hidden-spec provenance in standard output when assignments are created from `.ace-local/assign/jobs/...` specs.

### Changed
- **ace-compressor v0.8.0**: Extended CLI mode support to `--mode compact` with mode-aware compressor dispatch and conservative fallback behavior for ambiguous docs.
- **ace-compressor v0.8.0**: Added compact-mode classifier/compressor test coverage, preserved imperative-rule survivability under aggressive compaction, and updated usage/README contracts.
- **ace-assign v0.22.0**: Source-config provenance now preserves existing `jobs/` paths and archives non-job source configs into `<task>/jobs/<assignment-id>-job.yml` (replacing prior `phases/` archive behavior).
- **ace-assign v0.22.0**: Updated assign-create workflow/skill tracer contract for `work-on-task --taskref <id>` with deterministic hidden-spec handoff to `ace-assign create FILE`.

## [0.9.780] - 2026-03-07

### Technical
- **ace-assign v0.21.3**: Completed shine-cycle release step for PR #241 after repeated review-provider failures (`Broken pipe`) and confirmed no pending apply-feedback items.

## [0.9.779] - 2026-03-07

### Technical
- **ace-assign v0.21.2**: Completed fit-cycle release step for PR #241 after recorded review-provider failures (`Broken pipe`) and confirmed no pending apply-feedback items in session context.

## [0.9.778] - 2026-03-07

### Technical
- **ace-assign v0.21.1**: Completed the valid-cycle apply-feedback pass for PR #241 and confirmed there were no pending medium+ review feedback items before releasing.

## [0.9.777] - 2026-03-07

### Added
- **ace-assign v0.21.0**: Added subtree `pre-commit-review` phase support with configurable native client review defaults (`pre_commit_review`, provider mode, blocking toggle, and native client allowlist).

### Added
- **ace-task v0.21.0**: `task/work` workflow now includes `pre-commit-review` sub-phase between `work-on-task` and `verify-test`.

### Changed
- **ace-assign v0.21.0**: `task/work` forked sub-phase flow now inserts `pre-commit-review` between `work-on-task` and `verify-test`, with config-aware run/skip/block guidance in generated phase instructions.

## [0.9.776] - 2026-03-06

### Fixed
- **ace-compressor v0.7.1**: Corrected ContextPack/3 exact-mode scoping so `FILE|...` records now bracket the right source content, stabilized generic list output as `LIST|section|[...]`, and canonicalized prose `Example:` markers into `EXAMPLE|tool=...`.

### Technical
- **ace-compressor v0.7.1**: Updated package docs, changelogs, and focused regression coverage to lock the finalized exact-mode wire contract.

## [0.9.784] - 2026-03-07

### Changed
- **ace-compressor v0.7.0**: Migrated exact-mode output to ContextPack/3 and improved section-aware semantic records
  for deterministic markdown compression output.

### Technical
- **ace-compressor v0.7.0**: Added canonical markdown normalization and updated tests, CLI help text, and docs to
  document the new exact-mode contract.

## [0.9.783] - 2026-03-07

### Changed
- **ace-compressor v0.6.0**: Replaced verbose `ContextPack/1` exact-mode records with compact `ContextPack/2` output using a source table and implicit section context, cutting most structural overhead from packed content.

### Technical
- **ace-compressor v0.6.0**: Updated exact-mode tests, cache-key inputs, README, and usage docs to the new `ContextPack/2` wire format and compact record grammar.

## [0.9.782] - 2026-03-07

### Added
- **ace-assign v0.20.2**: Provider-unavailability recovery protocol for `fork-run` failures — distinguishes LLM-tool phases (inline retry allowed) from code phases (must re-fork), with detection heuristics and error-handling table entry.

## [0.9.781] - 2026-03-07

### Changed
- **ace-compressor v0.5.0**: Switched to a single-command CLI, added canonical cache-backed `--output` handling, and made `--format stats` human-readable with original-vs-packed byte and line comparisons.

### Technical
- **ace-compressor v0.5.0**: Added cache manifest metadata/backfill for source and packed totals, plus new command and organism coverage for cache reuse and stats reporting.

## [0.9.780] - 2026-03-07

### Technical
- **ace-compressor v0.4.3**: Polish — removed dead `return 0` in CLI command; expanded README with multi-source examples and docs link.

## [0.9.779] - 2026-03-07

### Technical
- **ace-compressor v0.4.2**: Removed redundant `uniq` pass in directory traversal (fit-cycle cleanup).

## [0.9.778] - 2026-03-07

### Fixed
- **ace-compressor v0.4.1**: Binary files with supported extensions (`.md`, `.txt`) inside directories are now correctly skipped during traversal rather than being silently included and producing corrupt ContextPack output.

### Technical
- **ace-compressor v0.4.1**: Added `docs/usage.md` with complete CLI reference, output format table, usage scenarios, error conditions, and troubleshooting guide.

## [0.9.777] - 2026-03-07

### Added
- **ace-compressor v0.4.0**: Added explicit exact-mode unresolved markers for image-only references and fallback markers for fenced code blocks, improving fidelity visibility for unsupported markdown constructs.
- **ace-llm v0.26.0**: Added provider allow-list controls via `llm.providers.active` and `ACE_LLM_PROVIDERS_ACTIVE`, including normalization and env override handling.
- **ace-llm v0.26.0**: Added focused tests for configuration allow-list behavior and parser inactive-vs-unknown provider classification.

### Fixed
- **ace-assign v0.21.1**: Corrected stale E2E constraint in TC-002-auto-completion runner — clarified that `--message` resolves as file content only when the path exists on the disk.
- **ace-compressor v0.4.0**: Hardened exact-mode preservation for rule-heavy and numeric content with regression coverage to prevent silent semantic drift.
- **ace-compressor v0.4.0**: Ensured table-bearing markdown content is represented explicitly in output records rather than being silently dropped.
- **ace-llm v0.26.0**: Query validation now distinguishes inactive configured providers from unknown providers and returns actionable inactive-provider guidance.

### Removed
- **ace-assign v0.21.0**: Removed `ace-assign finish --report` in favor of the unified `--message` contract.

### Changed
- **ace-assign v0.21.0**: `ace-assign finish` now uses `--message/-m` and accepts either inline report content or an existing file path, with resolution order `--message` → stdin → error.
- **ace-llm v0.26.2**: Polish `Configuration#provider` with `Enumerable#find`; use HEREDOC for inactive-provider error message.
- **ace-llm v0.26.3**: Improve `--list-providers` output readability with model counts and wrapped model lists.
- **ace-llm v0.26.0**: `ace-llm --list-providers` now renders filtered summary output with inactive provider reporting when filtering is active.

### Technical
- **ace-assign v0.21.2**: Removed redundant intermediate variable in `resolve_report_content` (`finish` command).
- **ace-compressor v0.4.0**: Expanded command and organism tests for unresolved/fallback/table behavior and exact-mode policy fidelity checks.
- **ace-llm v0.26.1**: Move `configuration_test.rb` to `test/organisms/` per ADR-017 flat test structure.

## [0.9.776] - 2026-03-06

### Added
- **ace-compressor v0.3.0**: Added exact-mode support for multi-file and directory inputs with deterministic ordering and merged output.

### Fixed
- **ace-compressor v0.3.0**: Added explicit failures for binary file inputs and empty-source directories, while preserving directory traversal behavior that ignores unsupported files by default.

### Technical
- **ace-compressor v0.3.0**: Expanded command/organism test coverage for multi-source exact-mode contracts (duplicates, directory traversal, verbose ignored-file reporting, and deterministic ordering).
- **ace-review v0.43.7**: `--dry-run` now suppresses model execution even when review defaults enable `auto_execute`.
- **ace-review v0.43.7**: Review model validation now accepts `@ro`, `@rw`, and `@yolo` style suffixes.

### Changed
- **ace-review v0.43.7**: Simplified the default review catalog to five explicit presets (`code-valid`, `code-fit`, `code-shine`, `docs`, `spec`) and aligned the repo-level `.ace/review` overrides to the same model.

## [0.9.775] - 2026-03-06

### Added
- **ace-compressor v0.2.0**: Introduced a new `ace-compressor` gem with a runnable exact-mode single-file compression path (`ace-compressor compress <file> --mode exact`) that emits minimal structured `ContextPack/1` records.
- **ace-llm v0.25.1**: Added explicit `:low|medium|high|xhigh` thinking-level suffix support for fully qualified model targets while preserving `@ro`, `@rw`, and `@yolo` execution presets.
- **ace-llm v0.25.1**: Added provider-scoped thinking overlays for Codex and Claude so explicit thinking levels map to provider-native runtime controls.

### Changed
- **ace-llm v0.25.1**: Query resolution now applies explicit thinking overrides after preset loading and before direct CLI overrides.
### Fixed
- **ace-compressor v0.2.0**: Added explicit non-zero error handling for missing file arguments, missing files, and empty input content in exact mode.

### Technical
- **ace-compressor v0.2.0**: Added package test coverage (atoms, organisms, commands), workspace registration (`Gemfile`), and executable wrapper (`bin/ace-compressor`) for repo-level command invocation.

## [0.9.774] - 2026-03-06

### Changed
- Renamed all 89 skill directories and references from `ace-*` to `as-*` ("ace skill") prefix to eliminate namespace collision with CLI tool binaries. Non-Claude agents (Codex, Gemini) no longer confuse skill slash commands with terminal executables. CLI tools (`ace-bundle`, `ace-test`, etc.) remain unchanged.

## [0.9.773] - 2026-03-06

### Fixed
- **ace-idea v0.13.5**: `ace-idea list` now shows a stats summary line even when no ideas are found for the current scope.

## [0.9.772] - 2026-03-05

### Fixed
- **ace-task v0.20.7**: Fixed incorrect `ace-idea move` command in task/draft workflow; replaced non-existent `ace-idea move <id> --to archive` with correct `ace-idea update <id> --set status=done --move-to archive`

## [0.9.771] - 2026-03-05

### Added
- **ace-task v0.20.6**: `ace-task create` now accepts `--status` (`-s`) flag to set initial task status with validation, and `--estimate` (`-e`) flag to set effort estimate in frontmatter. Fixes workflow/CLI mismatch where `wfi://task/draft` instructed agents to use flags that didn't exist.

## [0.9.770] - 2026-03-05

### Fixed
- **ace-idea v0.13.4**: `ace-idea list` no longer leaks legacy `cancelled` as a separate status; legacy values are normalized to canonical `obsolete` during load/display.

### Changed
- **ace-idea v0.13.4**: Frontmatter checks now flag derived `location` metadata as warning-only (non-failing) and keep path-derived scope as source of truth.
- **ace-idea v0.13.4**: `ace-idea doctor` auto-fix now supports removing `location` from idea frontmatter and migrating legacy `cancelled` values to `obsolete`.

### Technical
- **ace-idea v0.13.4**: Added regression tests for legacy status normalization and doctor validator/fixer migration paths.

## [0.9.769] - 2026-03-05

### Fixed
- **ace-git v0.11.18**: Rebase workflow cherry-pick skip detection now uses commit subject matching instead of SHA comparison (cherry-pick produces new SHAs, so SHA-based skip never fired on resume).
- **ace-git v0.11.18**: Rebase workflow Phase 3.3 now restores upstream tracking after `git branch -m` rename, which silently drops the upstream config.
- **ace-git v0.11.18**: Rebase workflow Phase 5 push now uses `-u` flag to guarantee tracking is set after force-push.

## [0.9.768] - 2026-03-05

### Changed

- **ace-review v0.43.6**: Renamed config key `auto_save_branch_patterns` → `task_branch_patterns` to reflect broader usage (task spec resolution, not just auto-save)

### Technical

- Added `.ace-tasks/**/reviews/` to `.gitignore` for review symlinks (alongside existing `.ace-taskflow/**/reviews/` pattern)

## [0.9.767] - 2026-03-05

### Fixed

- **ace-assign v0.20.1**: `fork-run` stall detection now targets the in-progress phase within the subtree instead of the global current phase, preventing `stall_reason` from being written to the wrong phase during parallel fork execution.
- **ace-assign v0.20.1**: Stall-reason clearing on successful rerun now skips phases that never had a `stall_reason`, avoiding unnecessary file I/O.
- **ace-llm-providers-cli v0.22.1**: `SessionFinder` dispatcher test now exercises the actual dispatch path instead of calling the Claude finder directly.

### Technical

- **ace-llm-providers-cli v0.22.1**: Added explanatory comments in `OpenCodeSessionFinder` (project_id nil-gate) and `ClaudeSessionFinder` (substring matching rationale).

## [0.9.766] - 2026-03-05

### Added

- **ace-llm-providers-cli v0.22.0**: Provider-specific session finders (atoms) for Claude, Codex, Pi, Gemini, and OpenCode that detect fork sessions by scanning each provider's local session storage and matching by prompt.
- **ace-llm-providers-cli v0.22.0**: `SessionFinder` molecule dispatcher that routes session detection to the correct provider-specific atom.
- **ace-assign v0.20.0**: Provider-specific session detection fallback in `ForkSessionLauncher` — when a provider doesn't return a native `session_id`, scans local session storage via `SessionFinder` to detect the forked session by prompt matching.
- **ace-assign v0.20.0**: Session metadata file (`<root>-session.yml`) written for every fork run, capturing `session_id`, `provider`, `model`, and `completed_at` for traceability.
- **ace-assign v0.20.0**: Stall error messages now include `Session: <id>` when session metadata is available, enabling direct trace to agent session.

## [0.9.765] - 2026-03-05

### Technical

- **ace-support-config v0.8.3**: Document `ProjectConfigScanner` in README — add to molecule list and add comparison table explaining when to use `ConfigFinder` vs `ProjectConfigScanner`
- **ace-assign v0.19.3**: Extracted `STALL_REASON_MAX = 2000` constant in `ForkRun` to replace magic number; tightened truncation test assertion to pin exact expected output length (shine-cycle polish).

## [0.9.764] - 2026-03-05

### Fixed

- **ace-support-config v0.8.2**: Narrow `Errno::EACCES` rescue in `ProjectConfigScanner#find_ace_dirs` to per-path scope so a permission error on one directory does not abort the entire scan; add test for graceful degradation when a subdirectory is permission-restricted.
- **ace-assign v0.19.2**: Simplified Layer 1 last-message write in `ForkSessionLauncher` from check-then-write to a single read-based guard, reducing double file access and improving robustness.
- **ace-assign v0.19.2**: Multiline `stall_reason` values in `ace-assign status` output now display with indented continuation lines for readable terminal formatting.

### Technical
- **ace-assign v0.19.2**: Added `test_stall_reason_cleared_after_successful_rerun` regression test verifying `stall_reason` is cleared across all subtree phases after a successful rerun.
- **ace-llm-providers-cli v0.21.1**: Documented `--output-last-message` minimum version requirement for Codex CLI in README with verification command and graceful-degradation note.

## [0.9.763] - 2026-03-05

### Fixed

- **ace-support-config v0.8.1**: `ProjectConfigScanner` now skips `.bundle`, `_legacy`, `.ace-local`, `.ace-tasks`, and `.ace-taskflow` directories to prevent false-positive config discovery; scan results are memoized for efficiency; symlinked directories are deduplicated via `File.realpath`; `Dir.glob` uses portable positional flags form.

## [0.9.762] - 2026-03-05

### Added

- **ace-support-config v0.8.0**: New `ProjectConfigScanner` molecule enables downward project tree traversal to discover all `.ace` config folders across a monorepo, complementing the existing `ConfigFinder` upward traversal.
- **ace-assign v0.19.1**: `read_last_message` now rescues `SystemCallError` to prevent I/O errors from masking the stall error message; stale `stall_reason` is cleared from all subtree phases on successful fork-run completion to prevent misleading status after recovery.

### Technical
- **ace-assign v0.19.1**: Added comment in `ForkSessionLauncher` documenting the blocking assumption that makes the Layer 1 check-then-write pattern safe from concurrent writes.

### Changed

- **ace-task v0.20.4**: `ace-task` task loading now requires `TaskFilePattern` correctly to prevent `Task not found` errors during task-aware worktree creation.
- **ace-git v0.11.17**: `ace-git` now derives changed-file diff ranges using available refs only, preventing failures when `origin/main` is missing.
- **ace-idea v0.13.2**: `ace-idea` E2E verification paths now align with default root-scope idea flow.
- **ace-search v0.19.8**: `ace-search` now switches `rg` parsing mode based on `files_with_matches`, improving command consistency.
- **ace-git-worktree v0.13.21**: `ace-git-worktree` task-aware fixtures now use `.ace-tasks` and non-legacy task IDs in E2E workflows.
- **ace-overseer v0.4.20**: `ace-overseer` E2E fixtures now validate against non-legacy `.ace-tasks` identifiers for task workflows.
- **ace-idea v0.13.3**: `ace-idea` move-to-next behavior expectations now match root-scope operation (no dedicated `_next` folder).

### Fixed

- **ace-task v0.20.4**: Restored task-aware worktree creation for legacy-formatted fixtures by ensuring `TaskFilePattern` is loaded before task loader resolution.
- **ace-task v0.20.5**: Restored task-aware worktree discovery after task model load-order regression by requiring `Ace::Task::Models::Task` before lookup.
- **ace-git-worktree v0.13.22**: Fixed command failure signaling so missing-task operations in `create` and `remove` now exit non-zero and include actionable guidance.

## [0.9.762] - 2026-03-05

### Fixed
- **ace-demo v0.4.1**: Fixed tape override precedence consistency, removed redundant VHS preflight spawn, made dry-run attachment offline-safe, removed unsupported VHS `--format` argument emission, eliminated duplicate `Error:` prefixing in CLI errors, and added debug diagnostics for config load failures.
- **ace-demo v0.4.2**: Aligned `ExecutionResult` with the models layer, optimized single-tape lookup in `TapeScanner#find`, and improved config-load failure diagnostics with explicit warning output.
- **ace-demo v0.4.3**: Extracted shared tape search directory and attach-output printer atoms, tightened PR-not-found stderr matching in comment posting, and applied `vhs_bin`/`output_dir` runtime config defaults in recorder paths with test coverage.
- **ace-demo v0.7.1**: Fixed command escaping in `TapeContentGenerator` for quotes/backslashes. Fixed path traversal in `TapeCreator` via `DemoNameSanitizer`. Fixed `--dry-run` in tape mode to skip recording. Narrowed auth error detection to specific patterns. Removed unused `format:` parameter from `VhsCommandBuilder`.
- **ace-demo v0.7.2**: Fixed `AttachOutputPrinter` printing comment body in live mode. Fixed `--output` silently ignored in inline recording mode. Fixed `--pr` with non-GIF formats producing broken image markdown (now uses link format for MP4/WebM). Fixed dry-run with `--pr` not previewing attachment step. Fixed env var example syntax in `demo/record` workflow. Renamed `gif_path:` to `file_path:` in `GhAssetUploader` and updated error messages to be format-neutral. Fixed docs expected output for `list`/`show` commands. Removed redundant project-level WFI source registration.
- **ace-git-commit v0.19.1**: Cap `max_tokens` at 8192 for commit message generation to prevent inflated thinking budgets from the provider's global 65536 default. Also fixed `glite` LLM alias resolving to `gemini-flash-latest` (thinking-enabled) instead of `gemini-flash-lite-latest`, restoring sub-second latency.

### Added
- **ace-assign v0.19.0**: Surface forked agent last message on stall — `fork-run` now captures the agent's final output and includes it in stall error messages; `stall_reason` is persisted to phase frontmatter and displayed in `ace-assign status`.
- **ace-llm v0.25.0**: `QueryInterface.query` accepts `last_message_file:` to thread last-message capture path to provider clients.
- **ace-llm-providers-cli v0.21.0**: `CodexClient` passes `--output-last-message <path>` to Codex CLI for progressive, timeout-resilient last-message capture.
- **ace-demo v0.2.0**: Added new package for VHS-based demo recording with tape preset resolution, record CLI command, execution pipeline, and full package test coverage.
- **ace-demo v0.3.0**: Added PR demo attachment workflow with `attach` command, `record --pr` chaining, GitHub release asset upload, and PR comment posting (including dry-run previews).
- **ace-demo v0.4.0**: Added demo tape library and discovery features with metadata parsing, cascade tape scanning, `list`/`show` CLI commands, and shipped default demo tapes.
- **ace-demo v0.5.0**: Added `create` command for generating tape files from shell commands, with `TapeContentGenerator` atom, `TapeWriter` molecule, `TapeCreator` organism, stdin support, and `--dry-run` preview. Updated defaults to 960x480px at font size 16.
- **ace-demo v0.6.0**: Added inline recording to `record` command (`ace-demo record <name> -- <commands...>`), with `InlineRecorder` molecule for session-scoped tape generation and VHS execution in timestamped directories, create-style options (`--timeout`, `--desc`, `--tags`, `--width`, `--height`, `--font-size`), stdin support, and dry-run preview.
- **ace-demo v0.7.0**: Added `DemoNameSanitizer` atom for filesystem-safe slug normalization of user-supplied demo names. Added `ace-b36ts` runtime dependency. Inline recording now uses compact 6-character b36ts session IDs instead of `YYYYMMDD-HHMMSS` timestamps, and sanitizes the `<name>` argument before use in tape and output paths.
- **ace-demo v0.7.1**: Added handbook workflow instructions (`demo/create`, `demo/record`) and skills integration (`ace-demo-create`, `ace-demo-record`) for agent workflow routing via `wfi://` protocol. Added WFI source registration for `ace-bundle wfi://demo/*` discovery.
- **ace-demo v0.7.2**: Added dedicated `DemoNameSanitizer` unit tests for edge cases. Added escaping regression test for `TapeContentGenerator`. Added `DemoCommentFormatter` test for non-GIF format rendering.

## [0.9.761] - 2026-03-05

### Fixed
- **ace-task v0.20.3**: `update --move-to archive` now handles subtasks safely by soft-skipping direct subtask archive when sibling subtasks are not all terminal, while archiving the parent task folder when all subtasks are terminal.
- **ace-task v0.20.3**: `doctor --auto-fix` archive moves now route through standard archive partitions and avoid stranding subtask folders at archive partition root.

### Changed
- **ace-task v0.20.3**: `update` command now prints informational notes for soft-skipped subtask archive requests and automatic parent archive behavior.

## [0.9.760] - 2026-03-04

### Changed
- **ace-test-runner v0.15.9**: Centralized `ace-test` report storage to `.ace-local/test/reports/<short-package>/<runid>/`, updated suite/report discovery to use configurable report roots, and retained legacy `test-reports` read fallback.

## [0.9.759] - 2026-03-04

### Fixed
- **ace-task v0.20.2**: Updated doctor CLI unit tests for `provider_cli_args` three-argument signature, resolving suite failures from stale test invocation.

## [0.9.758] - 2026-03-04

### Fixed
- **ace-support-test-helpers v0.12.3**: `with_cascade_configs` now isolates HOME to a temporary directory for home-config fixtures, fixing sandbox permission failures.

## [0.9.757] - 2026-03-04

### Fixed
- **ace-support-nav v0.18.2**: Test suite now uses sandbox-safe HOME isolation for user-source/user-protocol discovery tests, avoiding permission errors against real `~/.ace` paths.

## [0.9.756] - 2026-03-04

### Fixed
- **ace-assign v0.18.2**: Enforced single-active subtree invariants in fork execution (`fork-run` and scoped `advance`/`finish`) to prevent concurrent active sibling phases in the same fork subtree.

## [0.9.755] - 2026-03-04

### Fixed
- **ace-review v0.43.5**: Feedback session discovery now prefers `.ace-local/review/sessions` with legacy `.cache` fallback.

### Changed
- **ace-assign v0.18.1**: Default assignment cache directory now uses `.ace-local/assign`.
- **ace-bundle v0.31.11**: Cache output now defaults to `.ace-local/bundle`; cache writes now respect configured `cache_dir`.
- **ace-docs v0.22.4**: Default docs cache directory now uses `.ace-local/docs`.
- **ace-git v0.11.16**: Default diff ignore artifacts now use `.ace-local/**/*`.
- **ace-llm-providers-cli v0.20.1**: Gemini CLI prompt staging now uses `.ace-local/llm/prompts`.
- **ace-overseer v0.4.19**: Assignment launcher temporary job files now use `.ace-local/overseer`.
- **ace-sim v0.7.2**: Default simulation cache root now uses `.ace-local/sim`.
- **ace-support-core v0.25.2**: PromptCacheManager session paths now use `.ace-local/<short-name>/sessions`.
- **ace-support-nav v0.18.1**: Default nav cache directory now uses `.ace-local/nav`.
- **ace-test v0.2.2**: E2E sandbox checklist template now uses `.ace-local/test-e2e`.
- **ace-test-runner-e2e v0.21.2**: E2E runtime, wrappers, tests, and workflows now use `.ace-local/test-e2e` and sandbox-local `.ace-local/e2e` paths.

### Technical
- **ace-lint v0.17.1**: Updated cache cleanup guidance comments to reference `.ace-local/`.

## [0.9.754] - 2026-03-04

### Fixed
- **ace-task v0.20.1**: Restored backward-compatible legacy `doctor_cli_args` fallback behavior while using nested `task.doctor.cli_args`.
- **ace-idea v0.13.1**: Restored backward-compatible legacy `doctor_cli_args` fallback behavior while using nested `idea.doctor.cli_args`.
- **ace-retro v0.10.1**: Restored backward-compatible legacy `doctor_cli_args` fallback behavior while using nested `retro.doctor.cli_args`.
- **ace-test-runner-e2e v0.21.1**: Preserved external `required_cli_args` string contract and introduced `required_cli_args_list` normalization for internal execution.

### Changed
- **ace-task v0.20.1**: Preserved codex shorthand default compatibility (`full-auto` and `dangerously-bypass-approvals-and-sandbox`) and consolidated related changelog sectioning.

## [0.9.753] - 2026-03-04

### Changed
- **ace-llm-providers-cli v0.20.0**: `ArgsNormalizer` now Shellwords-splits each element when `cli_args` is an array, enabling multi-word entries like `"--sandbox danger-full-access"` to normalize correctly.
- **ace-assign v0.18.0**: Migrated `providers.cli_args` config values to array format; `fork_session_launcher` now supports mixed string/array arg merging.
- **ace-test-runner-e2e v0.21.0**: Migrated `providers.cli_args` config values to array format; `CliProviderAdapter` and `TestExecutor` now accept string or array CLI args.
- **ace-task v0.20.0**: Renamed doctor CLI config to nested `task.doctor.cli_args` and switched provider args to arrays in `task`/`idea`/`retro` docs and runtime paths.
- **ace-idea v0.13.0**: Renamed doctor CLI config to nested `idea.doctor.cli_args` and switched provider args to arrays.
- **ace-retro v0.10.0**: Renamed doctor CLI config to nested `retro.doctor.cli_args` and switched provider args to arrays.

## [0.9.752] - 2026-03-04

### Changed
- **ace-assign v0.17.3**: Convert valid/fit/shine review cycles to forked parent phases with `review-pr`/`apply-feedback`/`release` sub-phases, align compose defaults and recipes to 3-cycle forked expansion, and update assignment workflow docs plus E2E prepare fixtures accordingly.

## [0.9.751] - 2026-03-04

### Fixed
- **ace-docs v0.22.3**: `docs/update.wf.md` corrected to `.ace-local/docs/` (not `.ace-local/ace-docs/`)
- **ace-git v0.11.15**: Rebase workflow cleanup command corrected (final missed occurrence of `.ace-local/ace-git/`)
- **ace-prompt-prep v0.17.3**: README migration note old path corrected to `.cache/ace-prep` (not `.ace-local/ace-prep`)
- **ace-review v0.43.4**: Review workflow instructions (apply-feedback, pr, run) corrected to `.ace-local/review/`
- **ace-support-items**: VERSION constant indentation restored to match module nesting
- **ace-support-models**: Migration note old path corrected to `.cache/ace-llm-models-dev`; new path updated to `.ace-local/models` per short-name convention

## [0.9.750] - 2026-03-04

### Fixed
- **ace-assign v0.17.2**: Workflow instructions (create, drive, start) corrected to use `.ace-local/assign/` (not `.ace-local/ace-assign/`)
- **ace-docs v0.22.2**: Usage docs corrected to `.ace-local/docs/` (not `.ace-local/ace-docs/`)
- **ace-git v0.11.14**: Rebase workflow session path corrected to `.ace-local/git/` (not `.ace-local/ace-git/`)
- **ace-git-secrets v0.8.3**: Usage docs and token-remediation workflow corrected to `.ace-local/git-secrets/` (not `.ace-local/ace-git-secrets/`)
- **ace-prompt-prep v0.17.2**: Usage docs corrected to `.ace-local/prompt-prep/` (not `.ace-local/ace-prompt-prep/`)
- **ace-review v0.43.3**: `feedback-workflow.md` session path examples corrected to `.ace-local/review/` (not `.ace-local/ace-review/`)
- **docs/ace-gems.g.md**: Cache directory convention updated to `.ace-local/<short-name>` (drop `ace-` prefix)
- **docs/blueprint.md**: Agent ignore pattern updated to `.ace-local/**/*`

## [0.9.749] - 2026-03-04

### Fixed
- **ace-review v0.43.2**: Reverted feedback synthesis temporary workspace usage to standard `Dir.mktmpdir` handling and removed project-local `.ace-local/tmp` dependence.

## [0.9.748] - 2026-03-04

### Fixed
- **ace-git-secrets v0.8.2**: Reverted Gitleaks execution temporary workspace handling to standard `Tempfile`/`Dir.mktmpdir` behavior and removed project-local `.ace-local/tmp` usage.

## [0.9.747] - 2026-03-04

### Fixed
- **ace-support-items v0.15.1**: Reverted project-local temporary workspace usage and restored standard temporary file handling behavior.

## [0.9.746] - 2026-03-04

### Fixed
- **ace-assign v0.17.1**: README assignment storage path corrected to short-name convention (`.ace-local/assign/` not `.ace-local/ace-assign/`)
- **ace-bundle v0.31.10**: README cache output path example corrected to short-name convention (`.ace-local/bundle/` not `.ace-local/ace-bundle/`)
- **ace-docs v0.22.1**: README `cache_dir` example corrected to short-name convention (`.ace-local/docs` not `.ace-local/ace-docs`)
- **ace-git-secrets v0.8.1**: README and usage docs updated to short-name path convention (`.ace-local/git-secrets` not `.ace-local/ace-git-secrets`)
- **ace-prompt-prep v0.17.1**: README and usage docs updated to short-name path convention (`.ace-local/prompt-prep` not `.ace-local/ace-prompt-prep`)
- **ace-review v0.43.1**: README session storage path examples corrected to short-name convention (`.ace-local/review/` not `.ace-local/ace-review/`)
- **ace-sim v0.7.1**: Usage docs artifact paths corrected to short-name convention (`.ace-local/sim/` not `.ace-local/ace-sim/`)
- **ace-task v0.19.1**: Bug workflow instructions corrected to short-name path convention (`.ace-local/task/bug-analysis/` not `.ace-local/ace-task/bug-analysis/`)
- **AGENTS.md**: Temp file location guideline corrected to `.ace-local/<subfolder>/` (was `.cache/<subfolder>/`) with accurate example

## [0.9.745] - 2026-03-04

### Added
- **ace-support-items v0.15.0**: New `TmpWorkspace` atom for creating project-local, B36TS time-partitioned workspace directories under `.ace-local/tmp/`

### Changed
- **ace-assign v0.17.0**: Default assignment store directory migrated from `.cache/ace-assign` to `.ace-local/assign`
- **ace-docs v0.22.0**: Default cache directories migrated from `.cache/ace-docs` to `.ace-local/docs`
- **ace-git-secrets v0.8.0**: Default scan cache directory migrated from `.cache/ace-git-secrets` to `.ace-local/git-secrets`
- **ace-lint v0.17.0**: Default report directory migrated from `.cache/ace-lint` to `.ace-local/lint`
- **ace-prompt-prep v0.17.0**: Default cache directory migrated from `.cache/ace-prompt-prep` to `.ace-local/prompt-prep`
- **ace-review v0.43.0**: Default session cache directory migrated from `.cache/ace-review` to `.ace-local/review`
- **ace-sim v0.7.0**: Default session store directory migrated from `.cache/ace-sim` to `.ace-local/sim`
- **ace-task v0.19.0**: Default plan cache directory migrated from `.cache/ace-task` to `.ace-local/task`
- **ace-support-core v0.25.1**: Removed spurious `ace-support-items` and `ace-b36ts` runtime dependencies introduced during migration

### Technical
- **ace-bundle v0.31.9**: Update handbook reference to document cache output path as `.ace-local/bundle/`

## [0.9.744] - 2026-03-04

### Fixed
- **ace-llm v0.24.8**: Normalize `timeout` values before forwarding through query and fallback paths so `--timeout 600` no longer propagates as a string.

## [0.9.743] - 2026-03-04

### Fixed
- **ace-llm-providers-cli v0.19.4**: Normalize timeout input to numeric values in `SafeCapture` to avoid `no implicit conversion to float from string` on `--timeout` for CLI provider execution.

## [0.9.742] - 2026-03-04

### Fixed
- **ace-task v0.18.4**: Ensure file-based plan prompt tests can resolve `project` section preset in tmp test workspaces by creating a minimal local preset fixture.
- **ace-task v0.18.4**: Restore direct provider-prefix CLI arg mapping in `doctor` command before parser fallback, fixing provider alias handling.

## [0.9.741] - 2026-03-04

### Added
- **ace-task v0.18.3**: Add `task.plan.cli_args` for strict per-provider CLI argument passthrough during `ace-task plan`.
- **ace-llm v0.24.7**: Add reusable `tmpl://agent/plan-mode` template for planning-only prompt composition.

### Changed
- **ace-task v0.18.3**: Compose plan system prompts via section-based `ace-bundle` config (`base` + `workflow` + `project_context` + repeated guard section).
- **ace-task v0.18.3**: Pass provider-specific CLI args from config to `ace-llm` and harden planning contracts against permission/escalation or status-only output.
- **ace-llm v0.24.7**: Strengthen plan-mode template contract with explicit required headings and stricter output prohibitions.

## [0.9.740] - 2026-03-04

### Added
- **Agent skills**: Add `ace-github-pr-create` and `ace-github-pr-update` skill definitions under `.agent/skills/`

### Changed
- **ace-git v0.11.13**: Rename PR workflow URIs from `wfi://git/*` to `wfi://github/pr/*` and move workflow files to `handbook/workflow-instructions/github/pr/`
- **ace-assign v0.16.2**: Update assignment defaults, workflows, and E2E fixtures to use `ace-github-pr-*` skill names
- **ace-handbook v0.9.9**: Update `perform-delivery` workflow PR command reference to `/ace-github-pr-create`

## [0.9.739] - 2026-03-04

### Fixed
- **ace-assign v0.16.1**: Correct `.agents/skills` typo to `.agent/skills` in default config and `SkillAssignSourceResolver`

### Changed
- **docs/architecture.md**: Update skills path reference to `.agent/skills/` (canonical provider-neutral location)
- **docs/vision.md**: Update skill link to reference `.agent/skills/ace-git-commit/SKILL.md`

## [0.9.738] - 2026-03-04

### Added
- **Agent integration**: `.agent/skills/` canonical skill location — provider-neutral home for all 88 ACE skills following the AGENTS.md community standard

### Changed
- **Agent integration**: `.claude/skills`, `.codex/skills`, `.gemini/skills`, `.pi/skills` all now symlink to `.agent/skills/` instead of referencing `.claude/skills/` directly

## [0.9.737] - 2026-03-04

### Fixed
- **ace-support-nav v0.18.0**: Prevent argument injection in `resolve_cmd_to_path` by escaping reference before command template interpolation; add 10-second timeout to cmd protocol execution
- **ace-bundle v0.31.8**: Guard against empty `base_content_resolved` replacing document content with nothing when base resolution fails
- **ace-task v0.18.2**: Prompt builder now fails fast on `ace-bundle` errors instead of silently writing placeholder text
- **ace-task v0.18.2**: `fresh_context_files?` returns true for empty context files, preventing unnecessary plan regeneration
- **ace-task v0.18.2**: `build_unique_plan_path` uses current timestamp with collision suffix instead of future timestamps

### Added
- **ace-support-nav v0.18.0**: `resolve_cmd_to_path` method for programmatic resolution of cmd-type protocol URIs

### Changed
- Updated `ace-support-nav` dependency constraint to `~> 0.18` in ace-bundle, ace-prompt-prep, and ace-review gemspecs

## [0.9.736] - 2026-03-04

### Added
- **ace-assign v0.16.0**: New `onboard-base` and `task-load` catalog phases for plan-first task execution workflow
- **ace-assign v0.16.0**: Taskref placeholder substitution in catalog phase descriptions — `<taskref>` replaced with actual task reference during child instruction building

### Changed
- **ace-task v0.18.1**: Work workflow sub-phases updated to plan-first sequence (`onboard-base → onboard → task-load → plan-task → work-on-task`)
- **ace-overseer**: Bumped ace-assign dependency to ~> 0.16

## [0.9.735] - 2026-03-04

### Fixed
- **ace-bundle v0.31.7**: Resolve `cmd`-type protocol URIs (e.g., `task://`) by capturing command stdout as a file path, enabling `ace-bundle task://...` to load task files instead of failing with "Failed to resolve protocol". Adds `NavigationEngine#resolve_cmd_to_path` in ace-support-nav to support this.

## [0.9.734] - 2026-03-04

### Added
- **ace-task v0.18.0**: Plan command with cache-backed implementation planning and freshness checks
- **ace-task v0.18.0**: Vertical slicing specs, dual-slug naming, short subtask folder names
- **ace-task v0.18.0**: Colored status symbols and global folder statistics to list output

### Changed
- **ace-task v0.18.0**: Work workflow rewritten to lean execution directives with plan-first context loading
- **ace-task v0.18.0**: Planning workflow transitioned to inline reporting contract
- **ace-task v0.18.0**: Plan template verification commands use bare `ace-test`/`ace-lint`
- **ace-overseer**: Bumped ace-task dependency to ~> 0.18

### Fixed
- **ace-task v0.18.0**: Draft workflow corrected stale idea archive reference
- **ace-task v0.18.0**: Work workflow clarified checkbox tracking with anchor mapping

## [0.9.733] - 2026-03-03

### Fixed
- **ace-bundle v0.31.6**: Preserve resolved `base` content when `embed_document_source` leaks from top-level preset merge

## [0.9.732] - 2026-03-03

### Added
- **ace-task v0.17.0**: `TaskPlanPromptBuilder` with config file generation and debugging introspection
- **ace-task v0.17.0**: System prompt composed via ace-bundle (`base: wfi://task/plan` + `presets: [project]`)

### Changed
- **ace-task v0.17.0**: Plan generation uses `--format markdown-xml` for structured output
- **ace-task v0.17.0**: Generator passes prompt content directly to ace-llm SDK (no file passthrough)

## [0.9.731] - 2026-03-03

### Changed
- **ace-task v0.16.4**: Renamed cache directory from `.cache/task/` to `.cache/ace-task/` for consistency with other ace-* packages

## [0.9.730] - 2026-03-03

### Changed
- **ace-task v0.16.3**: Narrowed exception rescue in plan generator for better development error surfacing

## [0.9.729] - 2026-03-03

### Fixed
- **ace-task v0.16.2**: Bounded plan path generation loop with MAX_UNIQUE_ATTEMPTS guard
- **ace-task v0.16.2**: Empty context_files now correctly marks plans as stale
- **ace-task v0.16.2**: Missing context files emit stderr warnings instead of silent drop

### Changed
- **ace-task v0.16.2**: Extracted shared `PathUtils.relative_path` module, plan prompt includes anchored checklist schema, `write_plan` creates `latest-plan.meta.yml`

## [0.9.728] - 2026-03-03

### Added
- **ace-task v0.16.1**: `task/plan.wf.md` now defines explicit cache artifact outputs and an anchored plan checklist template (step IDs, `path:line` anchors, dependencies, verification commands)

### Changed
- **ace-task v0.16.1**: planning workflow contract is cache-backed (not ephemeral-only) with required freshness-input tracking and automatic stale regeneration guidance

## [0.9.727] - 2026-03-03

### Added
- **ace-task v0.16.0**: new `ace-task plan <ref>` command with freshness-aware cache reuse, `--refresh` regeneration, `--content` output mode, and `--model` override
- **ace-task v0.16.0**: plan cache + generation molecules (`TaskPlanCache`, `TaskPlanGenerator`) with tracked task/context mtime validation and latest-plan pointer management

### Changed
- **ace-task v0.16.0**: CLI help and README updated with plan command usage and option examples
- **ace-overseer**: gemspec dependency constraint updated from `ace-task ~> 0.15` to `~> 0.16` for compatibility with new minor release

## [0.9.726] - 2026-03-03

### Added
- **ace-overseer v0.4.18**: `StatusCollector` shows non-task worktrees in status when they have active assignments
- **ace-overseer v0.4.18**: `WorktreeContextCollector` supports B36TS task ID extraction from worktree paths and branch names

### Changed
- **ace-task v0.15.1**: `task/work.wf.md` is now plan-first with an explicit ensure-plan gate, fallback re-planning behavior, and refreshed command references aligned to `mise exec -- ace-task ...`

### Fixed
- **ace-overseer v0.4.18**: `PruneOrchestrator` allows pruning non-task worktrees when targeted by path
- **ace-git-worktree v0.13.20**: `TaskIDExtractor` supports B36TS directory naming (`ace-task.hy4`) in path-based extraction
- **ace-task v0.15.1**: corrected stale task/review command references in `task/work.wf.md` and resolved workflow markdown lint issues

## [0.9.725] - 2026-03-03

### Added
- **ace-retro v0.9.0**: Doctor `--auto-fix-with-agent` option — runs deterministic auto-fixes first, then launches an LLM agent to handle remaining issues
- **ace-retro v0.9.0**: Doctor `--model` option for configuring provider:model in agent sessions
- **ace-retro v0.9.0**: Default `doctor_agent_model` and `doctor_cli_args` config entries

## [0.9.724] - 2026-03-03

### Added
- **ace-task v0.15.0**: Short subtask folder names — subtask folders use `{char}-{slug}` format instead of `{full_id}-{slug}`, reducing path duplication while preserving full ID in spec filenames
- **ace-task v0.15.0**: Backward-compatible dual-format scanning across all subtask-aware modules (`SubtaskCreator`, `TaskLoader`, `TaskScanner`, `TaskResolver`, `TaskReparenter`)

### Fixed
- **ace-task v0.15.0**: `TaskReparenter#convert_to_orchestrator` used hardcoded `.a` subtask char instead of `SUBTASK_CHARS[0]` (`"0"`)

### Changed
- Renamed 13 active subtask folders from legacy long format to new short format

## [0.9.723] - 2026-03-03

### Fixed
- **ace-support-items v0.14.1**: `SpecialFolderDetector.normalize` uses prefix-based expansion — `--in backlog` now correctly finds items in `_backlog/` (and any custom special folder)

### Changed
- **ace-support-items v0.14.1**: Replaced hardcoded `SPECIAL_FOLDERS`/`SHORT_ALIASES` with `DEFAULT_PREFIX = "_"` for deterministic two-way folder name conversion
- **ace-task v0.14.1**, **ace-idea v0.12.4**, **ace-retro v0.8.3**: Config `special_folders` map replaced with `special_folder_prefix: "_"`

### Added
- **ace-support-items v0.14.1**: `SpecialFolderDetector.short_name` method for reverse prefix stripping

## [0.9.722] - 2026-03-03

### Added
- **ace-task v0.14.0**: `SubtaskCreator` dual-slug naming — folder slug (5 words) and file slug (7 words), matching `TaskCreator` convention
- **ace-task v0.14.0**: `TaskResolver` short subtask ID resolution — `q7w.a` and `t.q7w.a` patterns now resolve without requiring full parent ID

### Fixed
- **ace-task v0.14.0**: Subtask test assertions corrected to match base36 allocation order (0-9 before a-z)

### Changed
- Renamed 10 active subtask folders/files to follow two-tier naming convention (5-word folder, 7-word file)

## [0.9.721] - 2026-03-03

### Changed
- **ace-idea v0.12.3**: IdeaCreator uses two-tier naming — folder slug (5 words) and file slug (7 words)
- **ace-retro v0.8.2**: RetroCreator uses two-tier naming — folder slug (5 words) and file slug (7 words)
- Rename 31 active ideas and 8 active retros to follow two-tier folder/file naming convention

## [0.9.720] - 2026-03-03

### Added
- **ace-git-commit v0.19.0**: Group all `.ace/` config files into a single "ace-config" commit scope instead of creating separate per-package commits

## [0.9.719] - 2026-03-03

### Added
- **ace-support-items v0.14.0**: `SlugSanitizer` gains `max_length:` parameter and word-boundary truncation
- **ace-task v0.13.0**: Dual-slug task creation — folder slug (3-5 words, context) and file slug (4-7 words, action)
- **ace-task v0.13.0**: Title length validation (warning when >80 chars) in `TaskFrontmatterValidator`
- **ace-task v0.13.0**: Task naming convention guidelines in draft and review workflows

### Changed
- **ace-task v0.13.0**: `SubtaskCreator` uses 7-word limit instead of 40-char truncation
- Renamed all active and _maybe task folders/files to follow new two-tier naming convention

## [0.9.718] - 2026-03-03

### Fixed
- **ace-git-worktree v0.13.19**: `TaskIDExtractor` now recognises B36TS task ID format (`8pp.t.hy4`), fixing `ace-overseer work-on` failure when updating task status with new ace-task IDs

### Technical
- Promote skill-migration spec and add plan-first task execution spec set

## [0.9.717] - 2026-03-03

### Fixed
- **ace-task v0.12.3**: Subtask character allocation now follows base36 order (0-9 before a-z) matching Ruby's `to_s(36)`, ensuring correct lexicographic sorting

## [0.9.716] - 2026-03-03

### Changed
- **ace-task v0.12.2**: Critical priority uses single `▲` glyph (same as high, red color only) for consistent column alignment

## [0.9.715] - 2026-03-03

### Changed
- **ace-task v0.12.1**: Priority labels replaced with arrow glyphs (`▲▲` critical/red, `▲` high, `▼` low/dim); subtask indicator changed to `›N` and moved after title; list item metadata (ID, tags, folder) dimmed
- **ace-idea v0.12.2**, **ace-retro v0.8.1**: List item metadata (ID, tags, folder, type) dimmed for visual contrast with title
- **ace-idea v0.12.2**: Attachments only shown in `show` output, not in list items

## [0.9.714] - 2026-03-03

### Changed
- **ace-support-items v0.13.1**: Stats line folder breakdown is now dimmed for visual distinction between current-view stats and system-wide totals; folder names strip `_` prefix (`_archive` → `archive`, `_maybe` → `maybe`)

## [0.9.713] - 2026-03-03

### Fixed
- **ace-idea v0.12.1**: `ace-idea list` returned "No ideas found." — `IdeaScanner` was filtering root items with `special_folder == "next"` instead of `special_folder.nil?`

## [0.9.712] - 2026-03-03

### Added
- **ace-support-items v0.13.0**: `AnsiColors` atom with TTY-aware colorize helper and ANSI constants (RED, GREEN, YELLOW, CYAN, DIM, BOLD, RESET)
- **ace-support-items v0.13.0**: `StatsLineFormatter` `global_folder_stats:` parameter — always shows folder breakdown in stats line even when viewing filtered subsets
- **ace-task v0.12.0**, **ace-idea v0.12.0**, **ace-retro v0.8.0**: Colored status symbols in `list` output (TTY-aware); `last_folder_counts` on scanners and managers for global folder stats; colored status legend in `list --help`

### Changed
- **ace-idea v0.12.0**, **ace-retro v0.8.0**: Status symbols replaced from emoji (⚪🟡🟢⚫ / 🟡🟢) to Unicode shapes (○▶✓✗ / ○✓) for consistent colorization support
- **ace-task v0.12.0**: Status legend order in `list --help` reflects task lifecycle: draft → pending → in-progress → done

## [0.9.711] - 2026-03-02

### Changed
- **ace-overseer v0.4.17**: Replace `ace-taskflow` dependency with `ace-task` — migrate orchestrator and prune checker to `Ace::Task::Organisms::TaskManager` API
- **ace-prompt-prep v0.16.9**: Replace `ace-taskflow` dependency with `ace-task` — migrate `TaskPathResolver` to `TaskManager.show()` struct API
- **ace-review v0.42.7**: Replace `ace-taskflow` dependency with `ace-task` — migrate task resolver, subject extractor, and preset manager; remove dead `save_to_release` method
- **ace-git-worktree v0.13.18**: Replace `ace-taskflow` dependency with `ace-task` — migrate task fetcher, status updater, and ID extractor

### Removed
- **ace-taskflow**: Deleted gem directory, data directory (`.ace-taskflow/`), and binstub — superseded by ace-task, ace-idea, and ace-retro

## [0.9.710] - 2026-03-02

### Added
- **ace-support-items v0.12.0**: `SortScoreCalculator` atom for computing sort scores (priority × 100 + age with in-progress boost and blocked penalty)
- **ace-support-items v0.12.0**: `PositionGenerator` atom for generating B36TS position values (first, last, after, before, between)
- **ace-support-items v0.12.0**: `SmartSorter` molecule for pinned-first + score-descending sort logic
- **ace-support-items v0.12.0**: `StatusCategorizer` now accepts optional `up_next_sorter:` proc for custom sort order
- **ace-task v0.11.0**: Smart auto-sort as default for `list` command (priority × age scoring with status modifiers)
- **ace-task v0.11.0**: `--sort` option on `list` command (smart, id, priority, created)
- **ace-task v0.11.0**: `--position` option on `update` command for B36TS-based sort pinning (first, last, after:ref, before:ref)
- **ace-task v0.11.0**: `status` command up-next section now uses smart sort

## [0.9.709] - 2026-03-02

### Added
- **ace-support-items v0.11.0**: `FolderCompletionDetector` atom for checking if all spec files in a directory have terminal status (done/skipped/blocked)
- **ace-support-items v0.11.0**: `SpecialFolderDetector.move_to_root?` method recognizing "next", "root", "/" as move-to-root aliases
- **ace-task v0.10.0**: `--move-to` / `-m` option on `update` command to relocate tasks to special folders or back to root
- **ace-task v0.10.0**: `--move-as-child-of` option on `update` command for reparenting tasks (promote, orchestrator conversion, demote)
- **ace-task v0.10.0**: `TaskReparenter` molecule for promote/orchestrator/demote operations
- **ace-task v0.10.0**: Auto-archive hook — when all subtasks reach terminal status, parent auto-moves to archive
- **ace-idea v0.11.0**: `--move-to` / `-m` option on `update` command to relocate ideas to special folders or back to root
- **ace-retro v0.7.0**: `--move-to` / `-m` option on `update` command to relocate retros to special folders or back to root

### Removed
- **ace-task v0.10.0**: Standalone `move` command — use `update --move-to` instead
- **ace-idea v0.11.0**: Standalone `move` command — use `update --move-to` instead
- **ace-retro v0.7.0**: Standalone `move` command — use `update --move-to` instead

## [0.9.708] - 2026-03-02

### Added
- **ace-support-items v0.10.0**: `GitCommitter` molecule for auto-committing after CLI mutations via `ace-git-commit`
- **ace-task v0.9.0**: `--git-commit` / `--gc` flag on `create`, `update`, and `move` commands
- **ace-idea v0.10.0**: `--git-commit` / `--gc` flag on `create`, `update`, and `move` commands
- **ace-retro v0.6.0**: `--git-commit` / `--gc` flag on `create`, `update`, and `move` commands

## [0.9.707] - 2026-03-02

### Added
- **ace-support-items v0.9.0**: `RelativeTimeFormatter` atom for human-readable relative time strings (just now, 5m ago, 2h ago, 3d ago, 2w ago)
- **ace-support-items v0.9.0**: `StatusCategorizer` molecule for splitting items into up-next and recently-done buckets
- **ace-task v0.8.0**: `status` CLI command showing up-next tasks, summary stats, and recently completed tasks
- **ace-idea v0.9.0**: `status` CLI command showing up-next ideas, summary stats, and recently completed ideas
- Configurable limits via config.yml and CLI options (`--up-next-limit`, `--recently-done-limit`)

## [0.9.706] - 2026-03-02

### Fixed
- **ace-support-items v0.8.1**: `DirectoryScanner` now recurses into special folders that contain orphan spec files (fixes `ace-idea list --in maybe` returning empty when `_maybe/` has stray spec files alongside valid item subfolders)

## [0.9.705] - 2026-03-02

### Added
- **ace-support-items v0.8.0**: `StatsLineFormatter` accepts `total_count:` parameter for "X of Y" filtered view display
- **ace-task v0.7.0**: `TaskScanner#last_scan_total` and `TaskManager#last_list_total` expose total item count for contextual stats
- **ace-idea v0.8.0**: `IdeaScanner#last_scan_total` and `IdeaManager#last_list_total` expose total item count for contextual stats
- **ace-retro v0.5.0**: `RetroScanner#last_scan_total` and `RetroManager#last_list_total` expose total item count for contextual stats

### Changed
- Stats line now shows "X of Y" when viewing a filtered subset (e.g., "3 of 660" instead of redundant "3 total")
- Stats line shows folder breakdown only in full view with multiple folders (removes single-folder redundancy like "3 total — next 3")

## [0.9.704] - 2026-03-02

### Added
- **ace-support-items v0.7.0**: `ItemStatistics` atom for grouping items by field and computing completion rates
- **ace-support-items v0.7.0**: `StatsLineFormatter` atom for building stats summary lines with configurable icons, ordering, and completion percentage
- **ace-task v0.6.0**: Stats summary line appended to `list` output (e.g., "Tasks: ○ 2 | ▶ 1 | ✓ 5 • 8 total • 63% complete")
- **ace-idea v0.7.0**: Stats summary line appended to `list` output (e.g., "Ideas: ⚪ 3 | 🟡 1 | 🟢 2 • 6 total • 33% complete")
- **ace-retro v0.4.0**: Stats summary line appended to `list` output (e.g., "Retros: 🟡 2 | 🟢 5 • 7 total • 71% complete")

## [0.9.703] - 2026-03-02

### Added
- **ace-support-items v0.6.0**: Virtual filter concept in `SpecialFolderDetector` — `virtual_filter?` method resolves "next" and "all" to symbols for list filtering without physical folders
- **ace-task v0.5.0**: `TaskScanner#scan_in_folder` method with virtual filter support

### Changed
- **ace-support-items v0.6.0**: Remove `_next` from physical special folders — "next" is now a virtual filter meaning "root items only"
- **ace-task v0.5.0**: `list` defaults to `--in next` (root tasks only); use `--in all` for previous behavior
- **ace-idea v0.6.0**: `list` defaults to `--in next` (root ideas only); use `--in all` for previous behavior
- **ace-retro v0.3.0**: `list` defaults to `--in next` (root retros only); use `--in all` for previous behavior

## [0.9.702] - 2026-03-01

### Changed
- **ace-task v0.4.3**: Remove dead conditional branch in show command

## [0.9.701] - 2026-03-01

### Removed
- **ace-taskflow v0.43.1**: Remove retro workflow instructions (`retro/create.wf.md`, `retro/synthesize.wf.md`) migrated to ace-retro

### Fixed
- **ace-task v0.4.2**: Add ace-support-markdown dependency, log fixer exceptions, guard backup file deletion

## [0.9.700] - 2026-03-01

### Changed
- **ace-retro v0.2.3**: Rewrite workflow instructions to use `ace-retro` CLI and `ace-nav` protocol paths
  - `create.wf.md`: Simplify from 486 to ~90 lines, reference `tmpl://retro/retro` instead of embedding template
  - `selfimprove.wf.md`: Broaden input sources (session/retros/user), add retro creation and archive steps
  - `synthesize.wf.md`: Reduce to N retros → 1 retro pattern, remove `reflection-synthesize` references

### Removed
- **ace-retro v0.2.3**: Delete obsolete `synthesis-analytics.template.md` and `synthesize.system.prompt.md`

### Fixed
- **ace-task v0.4.1**: Soft-require ace/llm in doctor command, add missing TaskScanner require in fixer, include handbook in gemspec

## [0.9.699] - 2026-03-01

### Added
- **ace-assign v0.15.1**: Fork-run crash recovery protocol in drive workflow for partial completion scenarios

### Fixed
- **ace-retro v0.2.2**: Doctor flags invalid archive partitions (e.g., `2025-09/`) and fixer relocates retros to b36ts partitions via RetroMover

## [0.9.698] - 2026-03-01

### Added
- **ace-task v0.4.0**: `doctor` CLI command with comprehensive health checks — structure validation (folder naming, spec files, stale backups, empty dirs), frontmatter validation (delimiters, YAML, required fields, field values), scope/status consistency; auto-fix for 15+ issue patterns with dry-run support; agent-assisted fix via LLM; JSON/terminal/summary output with health scoring; all flags (--auto-fix, --check, --json, --verbose, --quiet, --dry-run, --errors-only, --no-color, --model, --auto-fix-with-agent)

### Fixed
- **ace-retro v0.2.1**: Wire `--root` option in list command, use date-partitioned archive paths in doctor auto-fix

## [0.9.697] - 2026-03-01

### Added
- **ace-retro v0.2.0**: Doctor command for retro health checks and auto-fixing
  - `ace-retro doctor` with structure, frontmatter, and scope/status validation
  - RetroValidationRules atom, RetroFrontmatterValidator and RetroStructureValidator molecules
  - RetroDoctorFixer with 15 auto-fixable patterns and dry-run mode
  - RetroDoctorReporter with terminal, JSON, and summary output formats
  - CLI options: `--auto-fix`, `--check`, `--verbose`, `--json`, `--dry-run`, `--quiet`
  - Health scoring (100 minus weighted deductions for errors/warnings)
  - 183 total tests, 440 assertions
- **ace-task v0.3.0**: `list`, `move`, `update` CLI commands; enhanced `create` with --priority/--tags/--child-of/--in; enhanced `show` with --tree and TaskDisplayFormatter output; handbook migration from ace-taskflow (17 task wfi, 2 bug wfi, 9 templates, 3 guides)

### Fixed
- **ace-task v0.3.0**: `TaskManager#list` now normalizes folder names before filtering

## [0.9.696] - 2026-03-01

### Added
- **ace-retro v0.1.0**: CLI commands and polish
  - dry-cli registry with 5 commands: create, show, list, move, update
  - `exe/ace-retro` executable with SIGINT handling (exit 130)
  - `--type`, `--tags`, `--task-ref`, `--move-to`, `--dry-run` options on create
  - `--path`, `--content` display modes on show
  - `--status`, `--type`, `--tags`, `--in` filters on list
  - `--set`, `--add`, `--remove` field operations on update
  - Handbook: workflow instructions and templates moved from ace-taskflow
  - 26 CLI integration tests (117 total, 327 assertions)
- **ace-task v0.2.0**: `TaskManager` organism with full CRUD API (create, show, list, update, move, create_subtask); `TaskDisplayFormatter` molecule for terminal output with status symbols, priority indicators, and subtask tree rendering; `SubtaskCreator` molecule with sequential char allocation (a-z then 0-9); `TaskFilePattern` and `TaskFrontmatterDefaults` atoms
- **ace-support-items v0.5.0**: `FieldUpdater` molecule for --set/--add/--remove frontmatter field updates with nested dot-key support; `FolderMover` molecule for generic folder moves with special folder normalization and archive partitioning; `LlmSlugGenerator` molecule for LLM-powered slug generation with fallback

### Changed
- **ace-task v0.2.0**: `Task` model expanded with priority, estimate, dependencies, tags, subtasks, parent_id; `TaskScanner`, `TaskResolver`, `TaskLoader`, `TaskCreator` expanded with subtask support and full field handling

### Fixed
- **ace-support-items v0.5.0**: `FrontmatterSerializer` now correctly serializes nested Hash values with proper YAML indentation

## [0.9.695] - 2026-03-01

### Added
- **ace-retro v0.1.0**: New gem for retrospective management with B36TS-based IDs
  - Core operations: create, show, list, update, move retros in `.ace-retros/`
  - 3 retro types with templates: standard, conversation-analysis, self-review
  - Task linking via `task_ref` field
  - Archive with chronological B36TS partitioning
  - Cross-filesystem move support (Errno::EXDEV handling)
  - 91 tests, 206 assertions
- **ace-task v0.1.0**: New gem with B36TS-based task management — type-marked IDs (`xxx.t.yyy`), `create` and `show` CLI commands, TaskCreator/TaskLoader/TaskScanner/TaskResolver molecules
- **ace-support-items v0.4.0**: `ItemIdFormatter` atom for splitting/reconstructing type-marked IDs, `ItemIdParser` for parsing all reference forms, `ItemId` value model; configurable `id_extractor:` on DirectoryScanner and `full_id_length:` on ShortcutResolver

## [0.9.694] - 2026-02-28

### Fixed
- **ace-b36ts v0.7.5**: `encode_split` week token now uses ISO Thursday-based attribution (`iso_week_month_and_number`) instead of naive day-based calculation, matching `encode_week` output
- **ace-b36ts v0.7.5**: `encode_split` week token now correctly encodes values 31-35 (base36 `v`–`z`) instead of raw week numbers 1-5; boundary dates (e.g., Sunday Mar 1 whose Thursday is Feb 26) now partition to the correct ISO week month

## [0.9.693] - 2026-02-28

### Added
- **ace-support-items v0.3.0**: `DatePartitionPath` atom computes a B36TS month/week partition path (e.g. `"8p/4"`) from a `Time` for use in date-organised archive directory structures; adds `ace-b36ts ~> 0.7` runtime dependency
- **ace-idea v0.5.0**: `IdeaMover#move` places archived ideas under `_archive/{month}/{week}/{folder}/` using B36TS partitions instead of a flat `_archive/`; `IdeaManager#move` automatically extracts `completed_at`/`created_at` from frontmatter as the partition date
- Three codemod scripts for migrating existing ideas to the new partition layout: `reorganize_archive.rb`, `migrate_release_archives.rb`, `migrate_backlog_ideas.rb` (all support `--dry-run`)

## [0.9.692] - 2026-02-28

### Added
- **ace-idea v0.4.1**: Extended `doctor --auto-fix` for additional issue types
  - Auto-fix for missing opening `---` delimiter (extracts ID/title, prepends frontmatter)
  - Auto-fix for legacy folder naming (generates new b36ts ID, renames folder and spec file)
  - Category folder detection (skips folders with only subdirectories, no files)
  - 16 fixable patterns (up from 14)

### Technical
- **ace-idea v0.4.1**: 13 new tests for extended auto-fix functionality (230 total tests)

## [0.9.691] - 2026-02-28

### Added
- **ace-idea v0.4.0**: `doctor` command — comprehensive health checks for ideas with auto-fix and agent support
  - Structure validation: folder naming (`{id}-{slug}`), spec file presence, stale backups, empty directories
  - Frontmatter validation: delimiters, YAML syntax, required fields (`id`, `status`, `title`), recommended fields (`tags`, `created_at`)
  - Scope/status consistency: terminal status in `_archive/`, non-terminal in archive, `_maybe/` with terminal
  - Health score (0-100) with errors weighted 10× and warnings 2×
  - `--auto-fix` for 14 safe automatic fixes (missing fields, stale backups, empty dirs, scope moves)
  - `--auto-fix-with-agent` to launch LLM agent for unfixable issues
  - Output formats: `--json`, `--quiet`, `--verbose`, terminal (default)
  - Filters: `--check (frontmatter|structure|scope)`, `--errors-only`
  - Options: `--no-color`, `--dry-run`, `--model`
- **ace-idea v0.4.0**: New atoms/molecules/organism for doctor feature — `IdeaValidationRules`, `IdeaFrontmatterValidator`, `IdeaStructureValidator`, `IdeaDoctorFixer`, `IdeaDoctorReporter`, `IdeaDoctor`

### Technical
- **ace-idea v0.4.0**: 108 new tests covering all doctor components (217 total tests)

## [0.9.690] - 2026-02-28

### Added
- **ace-assign v0.15.0**: Add `verify-test-suite` step to `work-on-task` and `work-on-tasks` presets with profiling and performance budget enforcement
- **ace-assign v0.15.0**: Enrich `verify-test-suite` phase catalog with structured steps (`run-package-tests`, `check-performance-budgets`, `fix-violations`, `run-suite`) and budget thresholds
- **ace-assign v0.15.0**: Move `verify-test-suite` from Optional to Core in compose workflow for "Implement + PR" and "Batch tasks" intents

### Changed
- **ace-assign v0.15.0**: Strengthen `verify-test-suite` composition rule from `recommended` to `required` when assignment includes `work-on-task` or `fix-bug`

## [0.9.689] - 2026-02-28

### Fixed
- **ace-idea v0.3.1**: Stub `llm_available?` in LLM-related tests to prevent real API calls during test runs (43s → <0.2s)

## [0.9.688] - 2026-02-28

### Added
- **ace-support-items v0.2.0**: `FrontmatterParser` atom for parsing YAML frontmatter (returns `[Hash, String]` tuple)
- **ace-support-items v0.2.0**: `FrontmatterSerializer` atom for YAML serialization with inline arrays and value quoting
- **ace-support-items v0.2.0**: `FilterParser` atom for `--filter key:value` syntax with OR (`|`) and negation (`!`)
- **ace-support-items v0.2.0**: `TitleExtractor` atom for extracting first H1 heading from markdown
- **ace-support-items v0.2.0**: `LoadedDocument` model, `DocumentLoader`, `FilterApplier`, `ItemSorter`, `BaseFormatter` molecules
- **ace-idea v0.3.0**: `--filter` option on `list` command with generic `key:value` filter syntax

### Changed
- **ace-idea v0.3.0**: Refactored `IdeaLoader`, `IdeaFrontmatterDefaults`, and `IdeaManager` to use shared atoms/molecules from `ace-support-items`
- **ace-idea v0.3.0**: Updated dependency `ace-support-items ~> 0.2` (was `~> 0.1`)

## [0.9.687] - 2026-02-28

### Added
- **ace-assign v0.14.0**: Add `verify-e2e` and `update-docs` phase catalog files with prerequisites, skip conditions, effort, and step definitions
- **ace-assign v0.14.0**: Add `verify-e2e` and `update-docs` steps to `work-on-task` and `work-on-tasks` presets (between mark-done → release and release → create-pr)
- **ace-assign v0.14.0**: Add ordering rules (`e2e-before-release`, `update-docs-after-release`, `update-docs-before-pr`, `e2e-after-verify`), conditional suggestion for CLI/API changes, and pairs to `composition-rules.yml`
- **ace-assign v0.14.0**: Update `compose.wf.md` Phase Selection Guidelines to include `verify-e2e` and `update-docs` in all relevant intents with skip guidance

## [0.9.686] - 2026-02-28

### Fixed
- **bin/ace-idea**: Wrapper now loads from `ace-idea/exe/ace-idea` (was incorrectly loading from `ace-taskflow/exe/ace-idea`)

### Added
- **ace-idea v0.2.4**: E2E test scenario `TS-IDEA-001-idea-lifecycle` — TC-001 (create), TC-002 (list with filters), TC-003 (move to folder)

### Changed
- **ace-taskflow v0.42.12**: Updated `task/draft` and `task/draft-batch` workflow instructions to use `ace-idea move/update` commands instead of legacy `ace-idea done/reschedule`
- **ace-taskflow v0.42.12**: Updated README to reflect ace-idea extraction as standalone gem; fixed preset README example syntax

### Technical
- Updated `docs/architecture.md` and `docs/blueprint.md` to list `ace-idea` as a distinct standalone gem
- **ace-idea v0.2.4**: Updated `idea/capture` and `idea/prioritize` handbook workflows to use current `ace-idea move/update` CLI syntax
- **ace-taskflow v0.42.12**: Corrected E2E TC-003 to use `ace-idea move --to maybe` (replaced legacy `ace-idea park`)

## [0.9.685] - 2026-02-28

### Technical
- **ace-idea v0.2.3**: Add explicit `require "json"`; remove unused constants; clean up redundant requires
- **ace-support-items v0.1.1**: Move `require "pathname"` to top-level in `SpecialFolderDetector`

## [0.9.684] - 2026-02-28

### Fixed
- **ace-idea v0.2.2**: Path traversal guards for `--to`/`--move-to`; YAML-ambiguous value quoting; consistent inline-array format in `rebuild_file`; LLM JSON preamble handling; hidden file filter in attachments

### Added
- **ace-idea v0.2.2**: `spec.executables` added to gemspec — `ace-idea` binary installs correctly

## [0.9.683] - 2026-02-28

### Fixed
- **ace-idea v0.2.1**: Security fixes — attachment path traversal, `--root` boundary check; atomic file writes; gem_root path; ArgumentError handling; YAML serializer special chars; formatting drift prevention; FieldArgumentParser for update command type inference

## [0.9.682] - 2026-02-28

### Added
- **ace-idea v0.2.0**: `ace-idea` CLI executable with 5 commands — `create`, `show`, `list`, `move`, `update` — wired to `IdeaManager` via dry-cli Registry pattern
- **ace-idea v0.2.0**: `create` supports `--title`, `--tags`, `--move-to`, `--clipboard`, `--llm-enhance`, `--dry-run`; `list` supports `--status`, `--tags`, `--in FOLDER`, `--root`; `update` supports `--set/--add/--remove K=V`
- **ace-idea v0.1.0/v0.1.1**: Initial release — `IdeaManager` organism, `IdeaCreator`/`IdeaScanner`/`IdeaResolver`/`IdeaLoader`/`IdeaMover`/`IdeaDisplayFormatter` molecules, `IdeaLlmEnhancer` with 3-Question Brief, clipboard capture, b36ts IDs, `.ace-ideas/` storage
- **ace-support-items**: Shared item management infrastructure used by ace-idea

### Changed
- **ace-idea**: Handbook workflow instructions (`idea/capture.wf.md`, `capture-features.wf.md`, `prioritize.wf.md`) moved from `ace-taskflow` to `ace-idea` package

## [0.9.681] - 2026-02-28

### Fixed
- **ace-llm v0.24.5**: Thread `--timeout` through fallback path — `FallbackOrchestrator` now forwards timeout to every `registry.get_client()` call, so `--timeout N` is no longer silently dropped when fallback is enabled
- **ace-llm v0.24.5**: Raise `max_tokens` defaults from 4096–8192 to 16384 across all gem providers and project-level `.ace/llm/providers/` overrides (16 files total)

## [0.9.680] - 2026-02-28

### Added
- **ace-sim v0.4.2**: Add `sim/run` workflow instruction and `/ace-sim-run` Claude skill for codified simulation execution
- **ace-sim v0.4.2**: Add WFI sources registration for `wfi://sim/*` protocol discovery

## [0.9.679] - 2026-02-28

### Added
- **ace-sim v0.4.1**: Add source-only preset defaults for `validate-idea` and `validate-task`, including default provider and synthesis workflow/provider mappings.

### Changed
- **ace-sim v0.4.1**: Update usage docs and tests for source-only preset execution and default synthesis workflow behavior.

## [0.9.678] - 2026-02-27

### Added
- **ace-sim v0.4.0**: Add optional final synthesis stage with `--synthesis-workflow` and `--synthesis-provider`, producing `final/suggestions.report.md` from chained step outputs.

### Changed
- **ace-sim v0.4.0**: Extend run/session synthesis metadata with final-stage status and fail overall run when requested final synthesis fails.

## [0.9.677] - 2026-02-27

### Changed
- **ace-sim v0.3.3**: Refactor list normalization, source resolution, and predicate methods for cleaner internal APIs; restore `dry_run?` predicate on `SimulationSession`

## [0.9.676] - 2026-02-27

### Fixed
- **ace-sim v0.3.2**: Handle unhandled runtime exceptions in `SimulationRunner#run` by rescuing `StandardError` and returning structured failure results instead of crashing the CLI

## [0.9.675] - 2026-02-27

### Removed
- **ace-taskflow**: Remove `wfi://task/create` workflow path and `ace-task-create` skill entrypoint in favor of draft-only task authoring (`wfi://task/draft`)

### Changed
- **ace-taskflow**: Improve draft/review quality with general decision-complete checks and explicit defaults while keeping task templates general-purpose
- **ace-bundle docs**: Update workflow URI examples from `wfi://task/create` to `wfi://task/draft`

## [0.9.674] - 2026-02-27

### Added
- **ace-taskflow v0.42.10**: Add `review-plan` and `review-work` workflow instructions for adversarial self-critique of plan and work outputs with structured six-dimension evaluation

### Changed
- **ace-sim v0.3.1**: Add self-critic pattern to `plan.md` and `work.md` sim steps with two-phase (build/critique) instruction structure and embedded review workflows

## [0.9.673] - 2026-02-27

### Fixed
- **ace-test-runner v0.15.8**: Sanitize subprocess environments to remove assignment context variables (`ACE_ASSIGN_ID`, `ACE_ASSIGN_FORK_ROOT`) in test execution paths, preventing assignment leakage into package test runs

## [0.9.672] - 2026-02-27

### Added
- **ace-sim v0.3.0**: Add strict markdown-step bundle templates with explicit context/workflow/report sections for `draft`, `plan`, and `work`

### Changed
- **ace-sim v0.3.0**: Switch simulation chain artifacts from YAML-based step I/O to markdown-first runtime (`input.md -> user.bundle.md -> user.prompt.md -> output.md`)
- **ace-sim v0.3.0**: Require `--source` to be an existing readable file path and seed step 1 by direct file copy
- **ace-sim v0.3.0**: Align usage docs, CLI examples, tests, and E2E scenario specs with the markdown chain contract

## [0.9.671] - 2026-02-27

### Added
- **ace-sim v0.2.0**: Add preset-driven simulation defaults with new `validate-idea` preset and bundle-compatible step configuration files under `.ace-defaults/sim/presets` and `.ace-defaults/sim/steps`

### Removed
- **ace-sim v0.2.0**: Remove scenario-based runtime/configuration path and legacy `result.yml` artifact output in favor of per-chain step artifacts and synthesis/session outputs

### Changed
- **ace-sim v0.2.0**: Rebuild execution model into minimal file-chained pipeline (`input.yml -> prompt.md -> output.yml`) with strict CLI-over-preset-over-default precedence and isolated provider x repeat chains

## [0.9.670] - 2026-02-27

### Changed
- Add `ace-sim` entries to `docs/tools.md` CLI reference

## [0.9.669] - 2026-02-27

### Fixed
- **ace-sim v0.1.3**: Disable YAML alias parsing for untrusted output, align config with ADR-022 pattern, remove redundant CLI flag, align dry-cli constraint

## [0.9.668] - 2026-02-27

### Fixed
- **ace-sim v0.1.2**: Validate `--scenario` CLI argument, detect missing output files after successful commands, fix output_path initialization in error paths, remove dead code

## [0.9.667] - 2026-02-27

### Added
- **ace-sim v0.1.1**: Add new standalone simulation package with `ace-sim run` CLI, step-chained execution (`draft -> plan`), provider/repeat support, deterministic session/stage/synthesis artifacts, and package-level tests/docs/e2e smoke scenario.

### Changed
- Add `bin/ace-sim` workspace wrapper and monorepo Gemfile wiring for `ace-sim`.

## [0.9.666] - 2026-02-27

### Changed
- **ace-git v0.11.12**: Add explicit code-block formatting rule and correct/incorrect example for grouped-stats output in PR creation and update workflows

## [0.9.665] - 2026-02-26

### Added
- **ace-support-core v0.25.0**: `ArgvCoalescer` utility for coalescing repeated CLI flags into comma-separated values, working around dry-cli's `type: :array` limitation

### Fixed
- **ace-overseer v0.4.16**: Fix repeated `--task` flags (`--task 288 --task 287`) being silently dropped by dry-cli; values are now coalesced before parsing

## [0.9.664] - 2026-02-26

### Fixed
- **ace-overseer v0.4.15**: Raise descriptive error when no valid task references are provided, preventing `NoMethodError` on empty input.

## [0.9.663] - 2026-02-26

### Added
- **ace-overseer v0.4.14**: Accept ordered multi-task `--task` input for `work-on` via repeated flags, comma-separated values, and mixed forms.

### Fixed
- **ace-overseer v0.4.14**: Validate all task refs before provisioning side effects and fail early when multi-task input is used with single-task presets.

### Changed
- **ace-overseer v0.4.14**: Preserve input order while expanding orchestrator refs into in-place subtask sequences for `taskrefs` presets.

## [0.9.662] - 2026-02-26

### Fixed
- **ace-git-commit v0.18.8**: Remove top-level no-op short-circuit and run stage-all flow first; preserve single-line no-op output only after staging confirms no staged changes
- **ace-git-commit v0.18.8**: Detect untracked-only repos as changed by including untracked-file checks in underlying git change detection

## [0.9.661] - 2026-02-26

### Fixed
- **ace-git v0.11.11**: Add untracked-file detection helper so consumers can correctly detect change state in untracked-only repositories

## [0.9.660] - 2026-02-26

### Fixed
- **ace-git-commit v0.18.7**: Treat "no changes to commit" as a successful no-op (exit 0) and simplify no-op output to a single clear line without staging progress or generic failure messaging

## [0.9.659] - 2026-02-26

### Fixed
- **ace-taskflow v0.42.9**: Display orphan subtasks with missing parent tasks instead of silently skipping them in `ace-task list` output, showing `[missing parent: <parent_id>]` indicator

## [0.9.658] - 2026-02-26

### Changed
- **ace-git v0.11.10**: Refine grouped-stats icon/name column separation and spacing, and preserve aligned name-column start across package, layer, and file rows

## [0.9.657] - 2026-02-26

### Fixed
- **ace-git v0.11.9**: Parse brace renames with empty-side segments (for example `{ => _archive}`) so grouped-stats keeps moved files in the correct package/group

### Changed
- **ace-git v0.11.9**: Compact grouped-stats headers when layer and package summaries match, normalize root labeling to `./`, suppress anonymous `other/` summary rows, and compact rename/path display for clearer output

## [0.9.656] - 2026-02-26

### Added
- **ace-git v0.11.8**: Add emoji-prefixed grouped-stats layer headers for faster scanning of `lib/`, `test/`, and `handbook/` sections

## [0.9.655] - 2026-02-26

### Fixed
- **ace-assign v0.13.4**: Restore scoped status filter compatibility for legacy filter forms (`010.01`, `(assignment@)010.01`) and restore scoped fork PID telemetry output lines

### Added
- **ace-assign v0.13.4**: Re-add explicit `status --filter` CLI option and add regression coverage for assignment-target precedence over filter

### Changed
- Test suite package list now includes `ace-assign`, so monorepo suite runs surface package regressions directly

## [0.9.654] - 2026-02-26

### Added
- **ace-assign v0.13.3**: Document `advance()` legacy bridge behavior; add `start` and stdin examples to CLI help; add "Starting Work" docs section

### Changed
- **ace-assign v0.13.3**: Use standard Keep a Changelog section headers (replace `Technical` with `Changed`)

## [0.9.653] - 2026-02-26

### Fixed
- **ace-assign v0.13.2**: Short-circuit stdin read when `--report` file content already present; narrow `rescue` to `IOError, Errno::EBADF`; consistent `fork_root` existence validation in `start_phase`

### Added
- **ace-assign v0.13.2**: Integration test for sequential finish auto-advance lifecycle; stdin vs `--report` precedence test

## [0.9.652] - 2026-02-26

### Fixed
- **ace-assign v0.13.1**: Fail fast with `PhaseNotFoundError` when `--assignment <id@scope>` specifies a non-existent subtree root instead of silently falling back to global queue
- **ace-assign v0.13.1**: `advance()` now raises `ConfigNotFoundError` (exit 3) for missing report files, consistent with `finish` command

### Added
- **ace-assign v0.13.1**: Positive test coverage for `start` and `finish` commands with explicit `step` argument

## [0.9.651] - 2026-02-26

### Added
- **ace-assign v0.13.0**: Add `start` command for explicit phase lifecycle control (`ace-assign start [STEP]`)
- **ace-assign v0.13.0**: Add `finish` command replacing `report`: supports `--report <file>` or piped stdin, eliminating mandatory temp-file creation
- **ace-assign v0.13.0**: Enforce strict `start` conflict detection — fails when another phase is already `in_progress`

### Removed
- **ace-assign v0.13.0**: Remove `report` command from CLI surface (replaced by `finish --report`)

### Changed
- **ace-assign v0.13.0**: Deterministic report input precedence — `--report` file wins over stdin when both are present
- **ace-assign v0.13.0**: Update `assign/drive.wf.md` and `assign/create.wf.md` to use `finish` command pattern

## [0.9.650] - 2026-02-26

### Fixed
- **ace-assign v0.12.23**: Anchor FORK column detection regex to CHILDREN pattern in `assign/drive` workflow, preventing false matches on phase names containing 'yes'

## [0.9.649] - 2026-02-26

### Fixed
- **ace-taskflow v0.42.8**: Make idea archive/maybe moves idempotent when the idea is already in the target scope, preventing nested `_archive/_archive/` and `_maybe/_maybe/` paths
- **ace-taskflow v0.42.8**: Treat pre-existing target folders in archive/maybe moves as idempotent success instead of failure, aligning mover behavior with task archiving semantics

### Changed
- **ace-taskflow v0.42.8**: Update `ace-idea done` and `ace-idea park` messaging to surface idempotent `already in` outcomes from mover operations

### Technical
- **ace-taskflow v0.42.8**: Add regression tests for already-archived/already-parked flows, target-exists idempotence, in-place metadata refresh, and archive-substring guard behavior

## [0.9.648] - 2026-02-26

### Added
- **ace-assign v0.12.22**: Add explicit FORK column to status output showing "yes" for phases with children, making delegation signal unmissable
- **ace-assign v0.12.22**: Introduce adaptive recovery for failed subtrees with retry/fail-children strategies
- **ace-assign v0.12.22**: Introduce fork PID telemetry and scoped status filtering for subprocess tracking

### Changed
- **ace-assign v0.12.22**: Decouple assignment targeting from environment variables; rely on explicit `--assignment <id>` flags
- **ace-assign v0.12.22**: Enhance plan-task instructions for behavioral spec adherence
- **ace-assign v0.12.22**: Update `assign/drive` workflow to reference FORK column instead of subtle "Fork subtree detected" message

### Technical
- **ace-assign v0.12.22**: Add validation order to E2E test expectations
- **ace-assign v0.12.22**: Update E2E test runner and verifier configurations
- **ace-assign v0.12.22**: Add test for FORK column in status output

## [0.9.647] - 2026-02-25

### Changed
- **ace-git v0.11.7**: Update `create-pr` and `update-pr-desc` workflows with emoji section headers and bold key-term bullet formatting rules for improved PR description readability

## [0.9.646] - 2026-02-25

### Fixed
- **ace-taskflow v0.42.7**: Make `ace-idea create --maybe` honor configured scope directory names (default `_maybe`) instead of writing to hardcoded `ideas/maybe/`

### Changed
- **ace-taskflow v0.42.7**: Align maybe preset globs to prefer `_maybe` with compatibility for legacy `maybe/` paths

### Technical
- **ace-taskflow v0.42.7**: Add regression coverage for `ace-idea create --maybe` directory resolution and maybe preset glob handling

## [0.9.645] - 2026-02-25

### Added
- **ace-git v0.11.6**: Squash repeated directory prefixes in `grouped-stats` — consecutive files in the same directory show the shared prefix once, subsequent files show only the indented basename
- **ace-git v0.11.6**: Squash consecutive renames sharing the same from-dir/to-dir — second and later renames show only the indented basenames on each side of the arrow

### Changed
- **ace-git v0.11.6**: `update-pr-desc` workflow now explicitly forbids trimming or abbreviating the grouped-stats output in `## File Changes`

## [0.9.644] - 2026-02-25

### Changed
- **ace-assign v0.12.21**: Remove assignment runtime env coupling and require explicit assignment targeting (`--assignment <id>` / `--assignment <id>@<scope>`) across forked workflow execution, including updated drive/fork guidance and scoped launcher invocation.

### Technical
- **ace-bundle v0.31.5**: Bump runtime dependency constraint to `ace-git ~> 0.11`.
- **ace-git-commit v0.18.6**: Bump runtime dependency constraint to `ace-git ~> 0.11`.
- **ace-git-worktree v0.13.17**: Bump runtime dependency constraint to `ace-git ~> 0.11`.
- **ace-prompt-prep v0.16.8**: Bump runtime dependency constraint to `ace-git ~> 0.11`.
- **ace-review v0.42.6**: Bump runtime dependency constraint to `ace-git ~> 0.11`.

## [0.9.643] - 2026-02-25

### Fixed
- **ace-git v0.11.5**: Remove spurious blank lines within groups in `grouped-stats` plain output
- **ace-git v0.11.5**: Wire positional `range` argument in `ace-git diff` so explicit ranges (e.g. `origin/main..HEAD`) reach the diff generator

### Changed
- **ace-git v0.11.5**: Align stats and name columns in `grouped-stats` output — fixed-width `%5s, %5s` stats block and right-padded file-count field so all names start at a consistent column
- **ace-git v0.11.5**: Update `update-pr-desc` workflow to use merge-base range for `grouped-stats` diff

## [0.9.642] - 2026-02-25

### Fixed
- **ace-git v0.11.4**: Classify single-segment root dotfiles (e.g. `.gitignore`) as "Project root" instead of isolated per-file groups

### Technical
- **ace-review v0.42.5**: Add nil-path test case for `PrTaskSpecResolver#extract_task_reference`
- **ace-git v0.11.4**: Add inline comment explaining unbraced exact-rename fallback in diff numstat parser

## [0.9.641] - 2026-02-25

### Fixed
- **ace-git v0.11.3**: Filter exclude patterns against both rename_from and rename_to paths; consolidate duplicate file classification branches

## [0.9.640] - 2026-02-25

### Fixed
- **ace-review v0.42.4**: Guard against NoMethodError when PR text contains no task reference (safe navigation on regex match)
- **ace-git v0.11.2**: Skip redundant full diff for `grouped-stats` format; standardize zero-value display between file and group levels

## [0.9.639] - 2026-02-25

### Changed
- **ace-git v0.11.1**: Make PR creation/update workflows evidence-based by enforcing section-level sourcing from diff/commits/tests/changelog, grouped-stats-first file reporting, and user-impact-first summary rules.

### Technical
- **ace-git v0.11.1**: Simplify feature/default PR templates and embedded workflow templates to the new evidence-oriented section structure.

## [0.9.638] - 2026-02-25

### Added
- **ace-git v0.11.0**: Add `ace-git diff --format grouped-stats` with package/layer grouped, aligned change statistics suitable for terminal review and PR description evidence.

### Changed
- **ace-git v0.11.0**: Add grouped-stats configuration support and wire numstat parsing/grouping/formatting through diff configuration, generator, orchestrator, and CLI output handling.

## [0.9.637] - 2026-02-25

### Added
- **ace-review v0.42.3**: Automatically include the directly relevant task behavioral spec (`.s.md`) in PR review context when task references are discoverable from PR branch metadata or PR text.

### Changed
- **ace-review v0.42.3**: Add PR task-spec resolution helpers and enrich PR metadata/task resolution wiring (`body` metadata and `spec_path`) to support graceful spec-aware review context loading.

## [0.9.636] - 2026-02-25

### Changed
- **ace-taskflow v0.42.6**: Strengthen task review and planning workflows with explicit behavioral-spec coverage for operating modes, degenerate inputs, and per-path differences, plus `Behavioral Gaps` reporting guidance
- **ace-assign v0.12.20**: Strengthen generated `plan-task` assignment instructions to require section-by-section behavioral-spec planning and explicit gap reporting when specs omit implementation-critical details

## [0.9.635] - 2026-02-25

### Changed
- **ace-taskflow v0.42.5**: Update subtask delegation workflow to read parent-task context before subtask execution, clarify context-vs-requirement responsibilities, and preserve graceful fallback when parent context cannot be loaded

## [0.9.634] - 2026-02-25

### Changed
- **ace-taskflow v0.42.4**: Add idea-to-task intent inheritance guidance in task draft workflow, mapping 3-question idea sections into Objective/Expected Behavior/Success Criteria and preserving advisory framing

## [0.9.633] - 2026-02-25

### Changed
- **ace-taskflow v0.42.3**: Replace LLM-enhanced idea output with 3-Question Delegation Brief sections and align fallback/system prompt content to the same structure

### Technical
- **ace-taskflow v0.42.3**: Update idea enhancement tests to assert the new section headings

## [0.9.632] - 2026-02-25

### Technical
- **ace-taskflow v0.42.2**: Add clarifying comments for subtask number guard behavior

## [0.9.631] - 2026-02-25

### Fixed
- **ace-taskflow v0.42.1**: Add self-demotion guard and subtask number guard in `demote_to_subtask` to prevent state corruption and ensure correct numbering after auto-conversion

## [0.9.630] - 2026-02-25

### Added
- **ace-taskflow v0.42.0**: Add filtering by task status in list command

### Changed
- **ace-taskflow v0.42.0**: Auto-convert non-orchestrator parents on `ace-task create --child-of` and `ace-task move --child-of`, eliminating the manual `--child-of self` intermediate step

### Technical
- **ace-taskflow v0.42.0**: Add goal-mode E2E lifecycle scenarios and update E2E test configurations

## [0.9.629] - 2026-02-25

### Changed
- **ace-test-e2e v0.20.4**: Standardize handbook runner/verifier contract to execution-only runner plus impact-first verifier, clarify setup ownership in `scenario.yml` + fixtures, and add non-autonomous E2E execution guardrails across workflows.

## [0.9.628] - 2026-02-25

### Fixed
- **ace-bundle v0.31.4**: Fix plain workflow loading so `ace-bundle wfi://...` returns file content for workflow files without YAML frontmatter.

### Technical
- **ace-bundle v0.31.4**: Add regression tests covering non-frontmatter workflow loading path and update loader direct-file expectations.

## [0.9.627] - 2026-02-24

### Fixed
- **ace-overseer v0.4.13**: Isolate `TS-OVERSEER-001` E2E tmux usage per run by adopting run-ID session naming (`tmux-session: { name-source: run-id }`) and eliminating implicit/default session collisions.

### Changed
- **ace-overseer v0.4.13**: Require tmux verification commands to target `ACE_TMUX_SESSION` explicitly in runner guidance.

## [0.9.626] - 2026-02-24

### Added
- **ace-test-e2e v0.20.3**: Add run-ID tmux session setup support (`tmux-session: { name-source: run-id }`) to isolate CLI pipeline runs with deterministic `ACE_TMUX_SESSION` naming.

### Changed
- **ace-test-e2e v0.20.3**: Wire setup execution to receive the run ID and update scenario authoring docs/templates with run-ID tmux session guidance and teardown lifecycle.

## [0.9.625] - 2026-02-24

### Changed
- **ace-test-e2e v0.20.2**: Make analyze/fix workflows autonomous by requiring concrete fix decisions (target layers, candidate files, and boundaries) and removing normal user-clarification branching for fix targeting.

## [0.9.624] - 2026-02-24

### Changed
- **ace-test v0.2.1**: Make analyze/fix workflows autonomous by requiring concrete fix decisions (target layers, candidate files, and boundaries) and removing normal user-clarification branching for fix targeting.

## [0.9.623] - 2026-02-24

### Changed
- **ace-test-e2e v0.20.1**: Consolidate mise.toml handling into `setup:` run steps, remove `sandbox-setup:` mechanism, rename `env:` → `agent-env:` for clarity, and re-export env vars in `SetupExecutor#handle_run` to protect against mise clobbering

## [0.9.622] - 2026-02-24

### Added
- **ace-test-e2e v0.20.0**: Generic `sandbox-setup:` field in scenario.yml for declaring shell commands that run inside the pipeline sandbox after infrastructure setup, replacing hardcoded `mise trust` with a scenario-driven mechanism

## [0.9.621] - 2026-02-24

### Fixed
- **ace-git-worktree v0.13.16**: Fix dry-cli list flag forwarding so `--task-associated`, `--no-task-associated`, and `--no-usable` apply the intended filters instead of collapsing false-valued flags.

## [0.9.620] - 2026-02-24

### Fixed
- **ace-test-e2e v0.19.3**: Remove sandbox copying of standalone TC definition files (`TC-*.runner.md` / `TC-*.verify.md`) and clarify SANDBOX_ROOT artifact-write rules for worktree-context execution.

### Changed
- **ace-overseer v0.4.12**: Tighten `TS-OVERSEER-001` TC-005 instructions to resolve and use the task.001 worktree context for `ace-assign` operations while persisting evidence in sandbox `results/`.

## [0.9.619] - 2026-02-24

### Fixed
- **ace-git-worktree v0.13.15**: Resolve task-association filtering through task-aware listing data whenever `--task-associated`/`--no-task-associated` is used, and add regression tests for filter-path behavior.
- **ace-test-e2e v0.19.2**: Improve verifier evidence parsing to preserve multiline failure evidence (including `Evidence of failure`) in generated metadata and reports.

### Changed
- **ace-overseer v0.4.11**: Update `TS-OVERSEER-001` TC-005 E2E workflow/verifier instructions to require explicit assignment-completion and post-prune evidence capture.

## [0.9.618] - 2026-02-24

### Fixed
- **ace-assign v0.12.19**: Scope report execution for `<assignment>@<phase>` to fork-subtree context so child-phase completion uses the correct report path resolution.
- **ace-git-worktree v0.13.14**: Fix filtered list statistics to compute totals from the filtered worktree set.

### Changed
- **ace-test-e2e v0.19.1**: Raise default CLI pipeline timeout to 600 seconds to reduce infrastructure timeout failures in longer scenarios.

### Technical
- **ace-bundle v0.31.3**: Harden CLI/API parity E2E error-path instructions to map API error metadata to non-zero failures.
- **ace-git-secrets v0.7.11**: Correct E2E config-path and whitelist instructions for `git-secrets` scenario execution.
- **ace-review v0.42.2**: Harden preset-composition E2E runner/verifier criteria for dry-run subject and artifact checks.

## [0.9.617] - 2026-02-24

### Added
- **ace-test v0.2.0**: Add `test/analyze-failures` workflow for evidence-based failure classification before changes.
- **ace-test-e2e v0.19.0**: Add `e2e/analyze-failures` workflow for scenario/TC classification and rerun-scope planning.

### Changed
- **ace-test v0.2.0**: Convert `test/fix` into an execution-only workflow gated on prior analysis output.
- **ace-test-e2e v0.19.0**: Convert `e2e/fix` into an execution-only workflow gated on prior analysis output and cost-aware rerun scope.

## [0.9.616] - 2026-02-24

### Changed
- **ace-test-e2e v0.18.2**: Rewrite `run.wf.md` and `execute.wf.md` to v2.0 with dual-mode execution, pipeline context, SetupExecutor contract, and dual-agent verifier documentation

### Added
- **ace-test-e2e v0.18.2**: Add `tags` field, execution pipeline section, and scenario-level configuration to handbook guides and templates; add `--tags`/`--exclude-tags` to workflow instructions; add essential E2E test suite plan for 10 new scenarios

### Fixed
- **ace-test-e2e v0.18.2**: Fix `cost-tier` default from `standard` to `smoke` and rename legacy report fields to TC-first schema across all handbook files

## [0.9.615] - 2026-02-24

### Fixed
- **ace-test-e2e v0.18.1**: Fix standalone pipeline report parsing and failure handling by accepting multiple goal heading formats, normalizing verifier verdict/category extraction, and always writing deterministic error reports when runner/verifier execution fails

### Changed
- **ace-test-e2e v0.18.1**: Rename CLI provider helper internals to `CliProviderAdapter` (with compatibility alias), improve suite subprocess result parsing/metadata reconciliation, and align `--only-failures` reruns to scenario-level execution with workspace-local executable resolution

## [0.9.614] - 2026-02-24

### Technical
- **ace-test-runner v0.15.7**: Patch release requested to keep package versioning aligned; no functional `ace-test-runner` code changes in this bump

## [0.9.613] - 2026-02-24

### Changed
- **ace-test-e2e v0.18.0**: Simplify `ace-test-e2e` and `ace-test-e2e-suite` to single-command CLIs — no more `run`/`suite`/`setup` subcommands, both executables now invoke their command class directly via `Dry::CLI`

### Removed
- **ace-test-e2e v0.18.0**: Remove multi-command CLI Registry and `ace-test-e2e setup` command (setup runs automatically during test execution)

## [0.9.612] - 2026-02-24

### Added
- **ace-taskflow v0.41.3**: Add orchestrator safeguards to workflow instructions — end-state coherence check in review workflow, spike-first rule and concept inventory in draft workflow, architecture drift check in work-subtasks workflow

## [0.9.611] - 2026-02-24

### Changed
- **ace-test-e2e v0.17.6**: Complete standalone-only execution model by removing scenario/test-case mode semantics, replacing goal-mode naming with neutral pipeline components, dropping suite `--mode` filtering, and updating E2E guides/templates/workflows to runner/verifier pair format

### Removed
- **ace-test-e2e v0.17.6**: Remove support for legacy `mode` and `execution-model` fields plus inline `.tc.md` test definitions; remove goal-mode-specific verify forcing path
## [0.9.610] - 2026-02-24

### Changed
- **ace-test-e2e v0.17.5**: Implement standalone goal-mode 6-phase execution pipeline (sandbox builder, runner/verifier prompt bundling, dual `ace-llm` execution, TC-first report generation), route standalone goal-mode away from slash-command skill invocation, and force verifier pass for this mode

## [0.9.609] - 2026-02-24

### Fixed
- **ace-test-e2e v0.17.4**: Fix synthetic TC ID collision and add parser test coverage

## [0.9.608] - 2026-02-24

### Fixed
- **ace-test-e2e v0.17.3**: Fix NoMethodError in failed TC parsing when category suffix missing

## [0.9.607] - 2026-02-24

### Changed
- **ace-test-e2e v0.17.2**: Add optional independent verifier mode (`--verify`) for run/suite, introduce TC-first verifier/result schema fields, and wire dual runner+verifier execution flow with updated reporting/failure extraction

## [0.9.606] - 2026-02-24

### Changed
- **ace-test-e2e v0.17.1**: Add inline goal-mode TC format support (`mode: goal`) with structure validation, criteria-aware parsing/reporting, and updated run/execute workflow guidance for procedural + goal execution paths

## [0.9.605] - 2026-02-24

### Changed
- **ace-test-e2e v0.17.0**: Add scenario tag/mode metadata and discovery-time filtering (`--tags`, `--exclude-tags`, `--mode`) plus goal-mode standalone TC discovery (`TC-*.runner.md` / `TC-*.verify.md`)

## [0.9.604] - 2026-02-24

### Changed
- **ace-b36ts v0.7.4**: Migrate package E2E suite to single goal-mode pilot scenario (`TS-B36TS-001-pilot`) with runner/verifier split artifacts and remove four legacy procedural scenarios

## [0.9.603] - 2026-02-23

### Fixed
- **ace-bundle v0.31.2**: Resolve `./` prefixed file paths relative to template config directory instead of project root

## [0.9.602] - 2026-02-23

### Fixed
- **ace-test-runner v0.15.6**: Enable ace-support-core integration (was disabled with stale TODO since v0.10)

### Changed
- **ace-b36ts v0.7.3**: Extract FormatCodecs module from CompactIdEncoder (1,294 to 654 lines)
- **ace-bundle v0.31.1**: Centralize error class hierarchy — SectionValidationError and PresetLoadError inherit from Ace::Bundle::Error
- **ace-lint v0.16.1**: Rename YamlParser atom to YamlValidator with backward-compat alias
- **ace-llm-providers-cli v0.19.3**: Refactor cli-check into ATOM structure (ProviderDetector, AuthChecker, HealthChecker)
- **ace-review v0.42.1**: Centralize error classes into Errors module, narrow exception handling in file I/O
- **ace-taskflow v0.41.2**: Rename YamlParser atom to FrontmatterParser with backward-compat alias, narrow bare rescues
- **ace-tmux v0.6.1**: Centralize error class hierarchy — PresetNotFoundError and NotInTmuxError inherit from Ace::Tmux::Error

### Removed
- **ace-support-core v0.24.1**: Remove legacy ConfigResolver wrapper with deprecated search_paths/file_patterns API

### Technical
- Standardized internal dependency version constraints across all 23 gemspecs to current releases
- Deprecated root Rakefile in favor of ace-test-suite

## [0.9.601] - 2026-02-23

### Changed
- **ace-lint v0.16.0**: Flatten CLI from multi-command Registry to single-command pattern — `ace-lint file.md` replaces `ace-lint lint file.md`, `--doctor` replaces `doctor` subcommand

### Removed
- **ace-lint v0.16.0**: Remove separate Doctor command class; diagnostics absorbed into Lint command as `--doctor`/`--doctor-verbose` flags

## [0.9.600] - 2026-02-23

### Fixed
- **ace-taskflow v0.41.1**: Fix `ace-retro create` failing with "not found" error — create dedicated `CreateRetro` command that handles title as a proper positional argument

## [0.9.599] - 2026-02-22

### Changed
- **ace-bundle v0.31.0**: Migrate from multi-command Registry to single-command pattern — `ace-bundle project` replaces `ace-bundle load project`, `--list-presets` replaces `list` subcommand
- **ace-llm v0.23.0**: Migrate from multi-command Registry to single-command pattern — `ace-llm gflash "prompt"` replaces `ace-llm query gflash "prompt"`, `--list-providers` replaces `list-providers` subcommand
- **ace-review v0.42.0**: Migrate from multi-command Registry to single-command pattern — `ace-review --preset pr` replaces `ace-review review --preset pr`, `--list-presets`/`--list-prompts` replace subcommands

### Removed
- **ace-bundle v0.31.0**: Remove `list` and `load` subcommands, `version`/`help` subcommands (use `--version`/`--help` flags)
- **ace-llm v0.23.0**: Remove `query` and `list-providers` subcommands, `version`/`help` subcommands
- **ace-review v0.42.0**: Remove `review`, `list-presets`, `list-prompts` subcommands, `version`/`help` subcommands, `KNOWN_COMMAND_NAMES` preprocessing

## [0.9.598] - 2026-02-22

### Fixed
- **ace-review v0.41.2**: Add flag variants (`--help`, `-h`, `--version`) to KNOWN_COMMAND_NAMES for preprocessing safety

## [0.9.597] - 2026-02-22

### Fixed
- **ace-review v0.41.1**: Include built-in help/version commands in KNOWN_COMMAND_NAMES for correct array option preprocessing
- **ace-llm-providers-cli v0.19.2**: Document first-matching-tier behavior in ClaudeOaiClient model tier resolution

## [0.9.596] - 2026-02-22

### Changed
- **ace-prompt-prep v0.16.5**: Migrate CLI to standard help pattern — remove DWIM default routing so no args shows help instead of routing to process command

### Technical
- **ace-prompt-prep v0.16.5**: Remove DefaultRouting extension; add PROGRAM_NAME, HELP_EXAMPLES, REGISTERED_COMMANDS with descriptions; register HelpCommand for --help/-h; update exe to use Dry::CLI.new().call() pattern with no-args default to --help; update all test helpers to use new invocation pattern

## [0.9.595] - 2026-02-22

### Changed
- **ace-overseer v0.4.9**: Migrate CLI to standard help pattern — remove DWIM default routing so no args shows help instead of custom usage display

### Technical
- **ace-overseer v0.4.9**: Remove KNOWN_COMMANDS, BUILTIN_COMMANDS constants and custom `start()` method; add PROGRAM_NAME, HELP_EXAMPLES, REGISTERED_COMMANDS with descriptions; register HelpCommand for --help/-h; update exe to use no-args → --help pattern

## [0.9.594] - 2026-02-22

### Changed
- **ace-test-e2e v0.16.21**: Migrate CLI to standard help pattern — remove DWIM default routing so users must now use explicit `run` subcommand

### Technical
- **ace-test-e2e v0.16.21**: Remove KNOWN_COMMANDS, BUILTIN_COMMANDS, DEFAULT_COMMAND constants and custom `start()` method; add PROGRAM_NAME, HELP_EXAMPLES, REGISTERED_COMMANDS with descriptions; register HelpCommand for --help/-h; update exe to use no-args → --help pattern

## [0.9.593] - 2026-02-22

### Changed
- **ace-docs v0.21.0**: Migrate CLI to standard help pattern — remove DWIM default routing so no args shows help instead of routing to status command

### Technical
- **ace-docs v0.21.0**: Remove KNOWN_COMMANDS, BUILTIN_COMMANDS, DEFAULT_COMMAND constants; add PROGRAM_NAME, HELP_EXAMPLES, REGISTERED_COMMANDS with descriptions; register HelpCommand for --help/-h; update exe/ace-docs to use Dry::CLI.new().call() pattern with no-args default to --help

## [0.9.592] - 2026-02-22

### Changed
- **ace-support-models v0.6.1**: Migrate ace-llm-providers CLI to standard help pattern — remove DWIM default routing so no args shows help instead of routing to list command

### Technical
- **ace-support-models v0.6.1**: Remove DefaultRouting extension from ProvidersCLI; convert REGISTERED_COMMANDS to [name, description] format; register HelpCommand for --help/-h; add no-args handling to exe/ace-llm-providers

## [0.9.591] - 2026-02-22

### Changed
- **ace-llm v0.22.6**: Migrate CLI to standard help pattern — remove DWIM default routing so no args shows help instead of routing to query command
- **ace-llm v0.22.6**: Update docs/tools.md to use explicit `ace-llm query` command syntax

### Technical
- **ace-llm v0.22.6**: Remove KNOWN_COMMANDS, DEFAULT_COMMAND, BUILTIN_COMMANDS; register HelpCommand for --help/-h; remove --list-providers alias; add no-args handling to exe/ace-llm

## [0.9.590] - 2026-02-22

### Changed
- **ace-tmux v0.6.0**: Migrate CLI to standard help pattern — remove DWIM context-aware routing so no args shows help instead of routing to start/window based on TMUX env

### Technical
- **ace-tmux v0.6.0**: Remove KNOWN_COMMANDS, DEFAULT_COMMAND, inside_tmux?, known_command? methods; register HelpCommand for --help/-h; add no-args handling to exe/ace-tmux

## [0.9.589] - 2026-02-22

### Changed
- **ace-assign v0.12.17**: Migrate CLI to standard help pattern — remove DWIM default routing so no args shows help instead of running status command

### Technical
- **ace-assign v0.12.17**: Remove KNOWN_COMMANDS, DEFAULT_COMMAND, deprecated command remapping; register HelpCommand for --help/-h; add no-args handling to exe/ace-assign

## [0.9.588] - 2026-02-22

### Changed
- **ace-taskflow v0.41.0**: Migrate ace-retro CLI to standard help pattern — remove DWIM default routing so no args shows help instead of running list command

### Technical
- **ace-taskflow v0.41.0**: Remove DefaultRouting extension and DWIM command routing from RetroCLI; add no-args handling to exe/ace-retro wrapper

## [0.9.587] - 2026-02-22

### Changed
- **ace-taskflow v0.40.5**: Migrate ace-idea CLI to standard help pattern — remove DWIM default routing so no args shows help instead of running list command

### Technical
- **ace-taskflow v0.40.5**: Remove DefaultRouting extension and DWIM command routing from IdeaCLI; move cache clearing from CLI.start override to exe/ace-idea wrapper

## [0.9.586] - 2026-02-22

### Changed
- **ace-taskflow v0.40.4**: Migrate ace-task CLI to standard help pattern — remove DWIM default routing so no args shows help instead of running list command

### Technical
- **ace-taskflow v0.40.4**: Remove DefaultRouting extension and DWIM command routing from TaskCLI; move cache clearing from CLI.start override to exe/ace-task wrapper

## [0.9.585] - 2026-02-22

### Changed
- **ace-taskflow v0.40.3**: Migrate CLI to standard help pattern with HelpCommand registration — no args shows help instead of running status by default

### Technical
- **ace-taskflow v0.40.3**: Remove DefaultRouting extension and DWIM command routing; move cache clearing from CLI.start override to exe/ wrapper

## [0.9.584] - 2026-02-22

### Changed
- **ace-review v0.41.0**: Migrate ace-review-feedback CLI to standard help pattern — remove DWIM default routing so no args shows help instead of running list command

## [0.9.583] - 2026-02-22

### Fixed
- **ace-review v0.40.5**: Migrate to standard help pattern with explicit `review` subcommand — remove DWIM default routing so no args shows help instead of running review

## [0.9.582] - 2026-02-22

### Fixed
- **ace-llm v0.22.5**: Pass `backends` config from provider YAML to client, fixing ClaudeOaiClient not receiving env vars and model tier mappings for non-Anthropic backends (e.g., zai)

## [0.9.581] - 2026-02-22

### Changed
- **ace-bundle v0.30.11**: Replace ace-nav subprocess with in-process SDK call (`NavigationEngine#resolve`) for protocol resolution, eliminating shell overhead and fixing compatibility with ace-nav's new multi-command CLI

### Technical
- **ace-bundle v0.30.11**: Add `ace-support-nav` as runtime dependency, remove ace-nav command mock from test helper, update integration test to use SDK directly

## [0.9.580] - 2026-02-22

### Changed
- **ace-support-nav v0.17.9**: Migrate `ace-nav` to the standard multi-command help pattern with explicit top-level help commands and explicit command selection.

### Technical
- **ace-support-nav v0.17.9**: Remove custom default-routing from CLI registry, move no-arg handling plus legacy `--sources`/`--create` alias translation to executable dispatch, and update integration tests for direct dry-cli invocation semantics.

## [0.9.579] - 2026-02-22

### Fixed
- **ace-llm-providers-cli v0.19.1**: `ClaudeOaiClient` now passes tier alias (`sonnet`/`opus`/`haiku`) to `--model` instead of backend model name, fixing claude CLI model recognition errors
- **ace-llm-providers-cli v0.19.1**: Sets `ANTHROPIC_DEFAULT_<TIER>_MODEL` env var for tier-to-model resolution at runtime

### Added
- **ace-llm-providers-cli v0.19.1**: `model_tiers` backend config mapping and `resolve_model_tier` method

## [0.9.578] - 2026-02-22

### Changed
- **ace-git-secrets v0.7.9**: Migrate to standard multi-command top-level help (`help`, `--help`, `-h`) and make no-arg invocation show help.

### Technical
- **ace-git-secrets v0.7.9**: Remove custom default-routing (`CLI.start`, command coercion) and move config preloading to executable-level dispatch.
- **ace-git-secrets v0.7.9**: Update CLI routing tests to use direct dry-cli dispatch semantics aligned with executable behavior.

## [0.9.577] - 2026-02-22

### Added
- **ace-llm-providers-cli v0.19.0**: Git worktree sandbox support — `CodexClient` and `CodexOaiClient` auto-detect worktrees and add `--add-dir` for git metadata writability
- **ace-llm-providers-cli v0.19.0**: New `WorktreeDirResolver` atom for worktree detection and common git dir resolution

## [0.9.576] - 2026-02-22

### Changed
- **ace-git-worktree v0.13.12**: Migrate to standard multi-command help pattern with explicit top-level help commands and no-args help behavior.

### Technical
- **ace-git-worktree v0.13.12**: Remove default-routing command coercion and update CLI routing tests to explicit Dry::CLI/executable assertions.

## [0.9.575] - 2026-02-22

### Added
- **ace-llm-providers-cli v0.18.0**: New `ClaudeOaiClient` provider for Claude over Anthropic-compatible APIs (Z.ai, OpenRouter) with backend env injection

## [0.9.574] - 2026-02-22

### Changed
- **ace-git v0.10.17**: Migrate to standard multi-command help pattern with explicit help commands and executable-level range shorthand routing.

### Technical
- **ace-git v0.10.17**: Replace legacy `CLI.start` routing tests with executable-level CLI routing coverage and update usage guide examples.

## [0.9.573] - 2026-02-22

### Changed
- **ace-bundle v0.30.10**: Standardize docs and examples to explicit `ace-bundle load ...` command usage across README and usage guide.

### Technical
- **ace-bundle v0.30.10**: Update CLI routing tests to executable-level assertions and remove stale `load` command example that referenced `--list`.

## [0.9.572] - 2026-02-22

### Changed
- **ace-test-runner v0.15.5**: Migrate `ace-test` to single-command dry-cli entrypoint and handle `--version` in command flow while preserving no-arg test execution

### Technical
- **ace-test-runner v0.15.5**: Remove legacy default-routing/registry scaffolding and update CLI routing tests for direct single-command invocation

## [0.9.571] - 2026-02-22

### Changed
- **ace-git-commit v0.18.4**: Migrate from registry/default-routing to single-command dry-cli entrypoint; no-arg invocation now shows command help
- **ace-git-commit v0.18.4**: Handle `--version` in command flow and accept `--staged` as alias for `--only-staged`

### Technical
- **ace-git-commit v0.18.4**: Remove legacy CLI routing scaffolding and update CLI routing tests to executable-level single-command coverage

## [0.9.570] - 2026-02-22

### Changed
- **ace-search v0.19.6**: Migrate CLI from registry/default-routing to single-command entrypoint; no-arg invocation now shows help instead of error
- **ace-search v0.19.6**: Handle `--version` directly in search command path for single-command mode

### Technical
- **ace-taskflow v0.40.2**: Update workflow instructions to use `ace-search "pattern"` single-command syntax
- **ace-test-runner-e2e v0.16.20**: Update e2e-testing guide to use `ace-search "pattern"` single-command syntax

## [0.9.569] - 2026-02-22

### Changed
- **ace-llm-providers-cli v0.17.1**: Update codexoai provider config — add backend `name` field, remove `wire_api`, rename env key to `ZAI_API_KEY`
- **ace-llm-providers-cli v0.17.1**: `CodexOaiClient` now passes provider `name` via `-c` config override with fallback to backend key

## [0.9.568] - 2026-02-22

### Added
- **ace-llm-providers-cli v0.17.0**: New `CodexOaiClient` multi-backend provider that wraps `codex` CLI to target OpenAI-compatible endpoints (Z.ai, DeepSeek, etc.) via dynamic `-c` flag overrides

### Removed
- **ace-llm-providers-cli v0.17.0**: Remove broken `CodexOSSClient` provider that called non-existent `codex-oss` binary

## [0.9.567] - 2026-02-22

### Changed
- **ace-search v0.19.6**: Migrate to single-command CLI entrypoint (`ace-search "pattern"`), add command-level `--version`, and normalize no-arg invocation to help output.

### Technical
- **ace-search v0.19.6**: Update workflow/guide references from `ace-search search "..."` to `ace-search "..."`; refresh CLI routing/integration tests for single-command behavior.

## [0.9.566] - 2026-02-22

### Fixed
- **ace-assign v0.12.16**: Prevent fork subtree recursion — auto-scope `status` to `ACE_ASSIGN_FORK_ROOT` and mark first workable child as `in_progress` before forked session launch

## [0.9.565] - 2026-02-22

### Technical
- **ace-bundle v0.30.9**: Update `ace-bundle project` → `ace-bundle load project` across docs and usage guide
- **ace-assign v0.12.15**: Update `ace-bundle project` → `ace-bundle load project` in README, fork-context guide, and test fixture
- **ace-docs v0.20.3**: Update `ace-bundle project` → `ace-bundle load project` in markdown-style guide
- **ace-handbook v0.9.7**: Update `ace-bundle project` → `ace-bundle load project` in update-docs workflow
- **ace-integration-claude v0.3.5**: Update `ace-bundle project` → `ace-bundle load project` in CLAUDE.md template

## [0.9.564] - 2026-02-22

### Added
- **ace-assign v0.12.14**: Subtree guard step — driver reviews fork report files before continuing; report review instruction in split-subtree-root template

## [0.9.563] - 2026-02-22

### Added
- **ace-support-core v0.24.0**: `HelpCommand.build` helper for standard top-level help commands in dry-cli registries

### Changed
- **ace-support-core v0.24.0**: Drop DWIM default routing — `DefaultRouting` and `HelpRouter` simplified to thin compatibility shims; empty args now show help

## [0.9.562] - 2026-02-22

### Changed
- **ace-taskflow v0.40.1**: Add release and verify-test-suite to work-on-task sub-phases for complete subtree lifecycle
- **ace-assign v0.12.13**: Background execution guidance for fork-run in drive workflow; timeout note in split-subtree-root phase template

## [0.9.561] - 2026-02-22

### Technical
- **ace-support-core v0.23.2**: Integration tests for two-tier help routing, documented dry-cli version coupling

## [0.9.560] - 2026-02-22

### Fixed
- **ace-support-core v0.23.1**: Clear instance variable state after use, nil-safe subcommand access, standardize hidden checks, use local Hash instead of ivars on external objects, fix CHANGELOG ordering

## [0.9.559] - 2026-02-22

### Added
- **ace-support-core v0.23.0**: Two-tier CLI help system — `-h` shows concise format, `--help` shows full ALL-CAPS reference (NAME, USAGE, DESCRIPTION, ARGUMENTS, OPTIONS, EXAMPLES). Adds usage_formatter, help_concise, command_groups, and standard_options modules.
- **ace-taskflow v0.40.0**: Command grouping in CLI help (Task Management, Idea Management, Release & Retro, Utilities)

### Fixed
- **ace-support-core v0.23.0**: Duplicate command name in examples auto-stripped; hidden subcommands filtered from help; ace-framework exe path fixed
- **ace-support-models v0.5.2**: Namespace subcommand help (cache/providers/models --help) now exits 0, outputs to stdout; command grouping added
- **ace-test-runner-e2e v0.16.19**: ace-test-e2e-sh now handles --help/-h flags (was causing FATAL error)
- **ace-review v0.40.4**: Hidden deprecated 'feedback skip' from help output
- **ace-taskflow v0.40.0**: Fixed misleading examples in task add-dependency/remove-dependency
- **ace-docs v0.20.2, ace-git-commit v0.18.3, ace-prompt-prep v0.16.4, ace-test-runner v0.15.4**: Stripped duplicate command name prefixes from examples

### Changed
- **21 packages**: Standardized quiet, verbose, debug option descriptions to canonical strings across all CLI commands

## [0.9.558] - 2026-02-22

### Changed
- **ace-assign v0.12.11**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-bundle v0.30.7**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-git v0.10.15**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-handbook v0.9.6**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-integration-claude v0.3.4**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-lint v0.15.14**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-llm-providers-cli v0.16.10**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-overseer v0.4.7**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-review v0.40.3**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-search v0.19.4**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-taskflow v0.39.7**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-test v0.1.5**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.
- **ace-test-runner-e2e v0.16.18**: Patch release for hyphenated skill naming migration (`ace-*`) and related reference updates.

## [0.9.557] - 2026-02-21

### Technical
- **ace-assign v0.12.10**: Stabilize `TS-ASSIGN-004` with deterministic scoped-status assertions (remove live nested `fork-run` dependency)
- **ace-assign v0.12.10**: Rewrite `TS-ASSIGN-006` to deterministic preset-expansion checks and add E2E preset fixtures for reproducible job generation

## [0.9.556] - 2026-02-21

### Fixed
- **ace-llm-providers-cli v0.16.9**: `ClaudeCodeClient` merges `subprocess_env` into actual subprocess environment, fixing env vars like `ACE_TMUX_SESSION` not reaching `claude -p` processes
- **ace-test-runner-e2e v0.16.17**: `TestExecutor` passes setup `env_vars` as `subprocess_env` to `QueryInterface.query`, preventing tmux windows from leaking into user sessions

### Added
- **ace-llm v0.22.3**: `subprocess_env:` parameter on `QueryInterface.query()` for CLI provider subprocess environment propagation

## [0.9.555] - 2026-02-21

### Fixed
- **ace-test-runner-e2e v0.16.16**: Fix tmux session leak — `SetupExecutor#teardown` now called via `ensure` blocks in `TestOrchestrator` for both single and parallel test paths

### Changed
- **ace-test-runner-e2e v0.16.16**: Tmux session naming uses scenario test ID (`{test_id}-e2e`) instead of generic timestamp for easier identification

## [0.9.554] - 2026-02-21

### Added
- **ace-llm-providers-cli v0.16.8**: Harden subprocess lifecycle with process-group cleanup in `SafeCapture`, including descendant cleanup on timeout and normal completion, plus new lifecycle regression tests
- **ace-test-runner-e2e v0.16.15**: Add debug-only suite diagnostics to detect lingering `claude -p` processes after E2E runs

### Changed
- **ace-llm-providers-cli v0.16.8**: Add opt-in CLI subprocess debug tracing via `ACE_LLM_DEBUG_SUBPROCESS=1`, including Claude client subprocess context logging

## [0.9.553] - 2026-02-21

### Changed
- **ace-assign v0.12.9**: Migrate skill name references to colon-free convention (`ace_domain_action` format) for non-Claude Code agent compatibility
- **ace-lint v0.15.13**: Update skill name validation pattern to colon-free convention
- **ace-llm-providers-cli v0.16.7**: Update skill name handling and documentation for colon-free convention
- **ace-test-runner-e2e v0.16.14**: Update skill invocation to colon-free convention (`ace_e2e_run` format)
- Migrate all skill directories and SKILL.md `name:` fields to colon-free `ace_domain_action` format
- Update CLAUDE.md documentation with new `/ace_` prefix convention

## [0.9.552] - 2026-02-21

### Added
- **ace-assign v0.12.8**: Verification instructions in `mark-task-done` phase; subtree completion section in drive workflow requiring task status verification
- **ace-handbook v0.9.5**: "Redundant computation" root cause category in selfimprove workflow with compute-once-pass-explicitly fix template
- **ace-taskflow v0.39.6**: Cross-package reference audit in plan workflow; contradiction check in review workflow; cross-reference validation in work workflow
- **ace-test-runner-e2e v0.16.13**: "Refactoring Resilience" section in E2E testing guide (pre-refactoring checklist, refactoring-proof patterns, post-refactoring smoke run)

## [0.9.551] - 2026-02-20

### Fixed
- **ace-assign v0.12.7**: Add `CACHE_BASE` env var support to `cache_dir` so E2E sandboxes resolve the correct cache path
- **ace-assign v0.12.7**: Graceful return in `advance()` when fork subtree is exhausted (prevents "No phase currently in progress" error)
- **ace-assign v0.12.7**: Fix ISO8601 regex to handle quoted YAML values in TC-002
- **ace-assign v0.12.7**: Correct `CACHE_BASE` path in TS-ASSIGN-003d scenario
- **ace-assign**: Update stale workflow path in TS-ASSIGN-005 E2E test after namespace rename
- **ace-b36ts**: Correct scenario.yml test-id fields for E2E tests
- **ace-git-commit v0.18.2**: Add `.gitignore` for test infrastructure files in TS-COMMIT-002 E2E scenario to prevent untracked file pollution
- **ace-git-commit**: Add staged-rename verification guard in TS-COMMIT-002 TC-003 to prevent out-of-order execution
- **ace-git-worktree v0.13.8**: Fix worktree filter to handle `false` values for `task_associated` and `usable` options (nil check instead of truthy check)
- **ace-git-worktree v0.13.8**: Show `target_branch` in dry-run output when present
- **ace-git-worktree v0.13.9**: Rewrite `from_git_output_list` to parse porcelain format by blank-line-separated blocks, correctly handling prunable and detached worktrees
- **ace-git-worktree v0.13.9**: Pass `--force` to `git worktree remove` when `ignore_untracked` is set
- **ace-git-worktree v0.13.9**: Use sandbox-local path for worktrees in TS-WORKTREE-001
- **ace-git-worktree v0.13.10**: Fix task ID extraction from worktree path matching incidental 3-digit numbers in parent directories by using `File.basename` instead of full path
- **ace-overseer v0.4.4**: E2E scenarios use `tmux-session` step instead of leaking windows into the developer's active tmux session
- **ace-overseer v0.4.5**: Fix `WorkOnOrchestrator` to pass `task_root_path` (resolved from `PROJECT_ROOT_PATH` env var) to `TaskLoader`, ensuring correct task lookup in worktree environments
- **ace-overseer v0.4.6**: Fix TC-003 tmux window verification to use `tmux list-windows -a` (all sessions)
- **ace-overseer v0.4.6**: Make `TmuxWindowOpener` idempotent and fix TC-001 output match
- **ace-taskflow v0.39.5**: Load config from discovered project root in `ConfigLoader.find_root` instead of `Dir.pwd`, fixing cross-project task resolution in E2E worktree tests
- **ace-test-runner-e2e v0.16.7**: Correct skill invocation from `/ace:run-e2e-test` → `/ace:e2e-run` (was causing 100% E2E test failure rate); fix broken `ace_e2e-run` symlink; add `tmux-session` setup step for isolated E2E tmux sessions
- **ace-test-runner-e2e v0.16.8**: Fix `short_id` regex to support digits in test area names (e.g., `TS-B36TS-001` → `ts001`)
- **ace-test-runner-e2e v0.16.8**: Copy test definition files (`.tc.md`) to sandbox before execution
- **ace-test-runner-e2e v0.16.9**: Downcase status in `normalize_status` and `normalize_result` so mixed-case statuses (`"Pass"`, `"PASS"`) are correctly recognized
- **ace-test-runner-e2e v0.16.9**: Reconcile scenario status with case counts in suite and test orchestrators — override to `"pass"` when all cases passed but metadata status is incorrect
- **ace-test-runner-e2e v0.16.11**: Add `-b main` to `git init` in `SetupExecutor` to ensure consistent default branch name regardless of system git configuration
- **ace-test-runner-e2e v0.16.12**: Pass `--report-dir` explicitly from suite orchestrator to inner subprocesses, eliminating directory name mismatch between Ruby `short_id` computation and LLM agent interpretation
- **ace-tmux v0.5.5**: `WindowManager` checks `ACE_TMUX_SESSION` env var first in `detect_current_session`, enabling test isolation without an active tmux session
- Fix E2E skill symlink for correct invocation

### Added
- **ace-test-runner-e2e v0.16.10**: Save subprocess raw output (`subprocess_output.log`) for all test results in report directories for diagnostic context
- **ace-test-runner-e2e v0.16.10**: Write `subprocess_output.log` alongside failure stub `metadata.yml` for tests with no report directory
- **ace-test-runner-e2e v0.16.12**: `--report-dir` CLI option and `REPORT_DIR` workflow parameter for explicit report directory path override

### Technical
- **ace-assign v0.12.6**: Add E2E tests for prepare workflow (from preset and informal instructions); fix `ASSIGNMENT_DIR` lookup in injection/renumbering tests
- **ace-git-commit v0.18.2**: Add staged rename verification to mixed operations test
- **ace-git-worktree v0.13.8**: Add regression tests for `false` filter values; improve E2E switch test
- **ace-handbook**: Add guide for renaming skills to prevent skill name drift
- **ace-overseer v0.4.5**: Fix E2E tests to use `ACE_TMUX_SESSION` variable instead of hardcoded session name
- **ace-taskflow v0.39.5**: Add unit test for `ConfigLoader.find_root` project root alignment
- **ace-test-runner-e2e v0.16.8**: Add test for skill name coupling in `SkillPromptBuilder`; add tests for `short_id` with digit-containing area names
- Record E2E test fixes retrospective session

## [0.9.550] - 2026-02-20

### Fixed

- **ace-assign v0.12.5**: Update slash command refs to use git namespace

## [0.9.549] - 2026-02-20

### Fixed

- **ace-handbook v0.9.4**: Update /ace:create-pr to /ace:git-create-pr in perform-delivery workflow

## [0.9.548] - 2026-02-20

### Fixed

- **ace-handbook v0.9.3**: Update stale wfi:// references in workflow definition guide
- **ace-test v0.1.4**: Update stale wfi://work-on-task references to wfi://task/work
- **ace-config**: Update release workflow context loading instructions

## [0.9.547] - 2026-02-19

### Changed

- **Namespace wfi:// Workflows (task 273)**: Reorganize all workflow instructions into domain-specific subdirectories across 16 packages
  - ace-assign 0.12.4: assign/ namespace
  - ace-bundle 0.30.6: updated protocol docs
  - ace-docs 0.20.1: docs/ namespace (+ migrated update-usage/update-roadmap from ace-taskflow)
  - ace-git 0.10.14, ace-git-commit 0.18.1, ace-git-secrets 0.7.7, ace-git-worktree 0.13.7: git/ namespace
  - ace-handbook 0.9.2: handbook/ namespace
  - ace-integration-claude 0.3.3: integration/ namespace
  - ace-lint 0.15.12: lint/ namespace
  - ace-review 0.40.2: review/ namespace
  - ace-search 0.19.3: search/ namespace
  - ace-support-nav 0.17.7: subdirectory protocol resolution test coverage
  - ace-taskflow 0.39.4: task/, bug/, idea/, retro/, release/ namespaces
  - ace-test 0.1.3: test/ namespace
  - ace-test-runner-e2e 0.16.6: e2e/ namespace

## [0.9.546] - 2026-02-19

### Fixed

- **ace-taskflow v0.39.3**: Fix `--auto-fix` always finding zero fixable issues (undiagnosed doctor instance); fix agent prompt issue list missing file paths (`:location` key); downgrade empty-directory warnings to info for `/_archive/` paths

## [0.9.545] - 2026-02-19

### Fixed

- **ace-taskflow v0.39.2**: Embed formatted list of non-auto-fixable issues directly in agent prompt so the agent knows exactly what to work on without re-running `--auto-fix`

## [0.9.544] - 2026-02-19

### Fixed

- **ace-overseer v0.4.3**: Prune orchestrator now deletes git branches when removing worktrees — previously left orphaned branches that blocked `work-on` from creating new worktrees for the same task

## [0.9.543] - 2026-02-19

### Fixed

- **ace-taskflow v0.39.1**: Wire up `--auto-fix`, `--auto-fix-with-agent`, and `--model` options in dry-cli layer — previously only the unused standalone `DoctorCommand` had these options; drop `--fix` alias per ADR-024

## [0.9.542] - 2026-02-19

### Added

- **ace-taskflow v0.39.0**: Doctor `--auto-fix-with-agent` option — runs deterministic auto-fix first, then launches LLM agent via `QueryInterface` to handle remaining issues; configurable via `--model` flag and `doctor.agent_model` config

### Fixed

- **ace-taskflow v0.39.0**: Fix pattern mismatch bug in `DoctorFixer` where regex couldn't match task location messages from doctor diagnosis

### Changed

- **ace-taskflow v0.39.0**: Rename `--fix` to `--auto-fix` (keeping `--fix` as backward-compatible alias)

## [0.9.541] - 2026-02-19

### Fixed

- **ace-taskflow v0.38.2**: Add `assign:` sub-phases declaration to `work-on-task.wf.md` so batch children expand into onboard/plan-task/work-on-task sub-steps during enrichment

## [0.9.540] - 2026-02-19

### Fixed

- **ace-taskflow v0.38.1**: Fix `doctor --fix` never applying fixes (fresh doctor had empty issues list), add empty directory detection and auto-fix for stale task/idea directories

## [0.9.539] - 2026-02-19

### Added

- **ace-taskflow v0.38.0**: Doctor & cleanup improvements — detect stale backup files and idea scope/status anomalies, auto-fix backup deletion and invalid `maybe/_archive/` nesting, implement `idea archive` command, clean up backups on subtask completion

## [0.9.538] - 2026-02-19

### Added

- **ace-git-commit v0.18.0**: Improve intent capture in commit message generation — add "This commit will..." test, "action not content" guidance, and deletion-specific handling to prevent LLM from describing file content instead of commit action

## [0.9.537] - 2026-02-19

### Added

- **ace-overseer v0.4.2**: Orchestrator subtask expansion — when working on an orchestrator task with `work-on-tasks` preset, subtasks are expanded into individual assignment phases

## [0.9.536] - 2026-02-19

### Fixed

- **ace-git-worktree v0.13.6**: Update TaskIDExtractor tests to remove `.00` orchestrator suffix references after TaskReferenceParser change

## [0.9.535] - 2026-02-19

### Fixed

- **ace-taskflow v0.37.3**: Clarify codemod location convention — task-level codemods go in `{task-folder}/codemods/`, never in `bin/`; add codemod deliverable hint to task template

## [0.9.534] - 2026-02-19

### Technical

- **ace-taskflow v0.37.2**: Remove dead orchestrator classification branch and fix stale `.00` comments

## [0.9.533] - 2026-02-19

### Fixed

- **ace-taskflow v0.37.1**: Harden `.00` reference rejection — `valid?` and `qualified?` return `false` instead of propagating exceptions; `format` rejects subtask `00`

## [0.9.532] - 2026-02-19

### Added

- **ace-overseer v0.4.1**: `--watch` / `-w` option for `status` command with auto-refreshing ANSI dashboard
- **ace-overseer v0.4.1**: Two-tier refresh — fast interval (15s) for assignment data, slow interval (5min) for git/PR metadata
- **ace-overseer v0.4.1**: `collect_assignments_only` on `WorktreeContextCollector` for lightweight assignment-only collection
- **ace-overseer v0.4.1**: `collect_quick` on `StatusCollector` reusing previous git data while refreshing assignments
- **ace-overseer v0.4.1**: Dim timestamp footer with countdown to next full refresh
- **ace-overseer v0.4.1**: Configurable watch intervals via `watch.refresh_interval` and `watch.git_refresh_interval` in config

## [0.9.531] - 2026-02-19

### Added

- **ace-overseer v0.4.0**: Progress bar visualization in assignment sub-rows with filled/empty bar segments alongside numeric counts
- **ace-overseer v0.4.0**: Current phase name display for running assignments shown dimmed after progress counts
- **ace-overseer v0.4.0**: Header row with column labels and separator line above hierarchical dashboard
- **ace-overseer v0.4.0**: Blank line separators between location groups for visual structure
- **ace-overseer v0.4.0**: `current_phase` field propagated from `QueueState` through `WorktreeContextCollector`

## [0.9.530] - 2026-02-19

### Changed

- **ace-overseer v0.3.1**: Hierarchical status display — location header rows (basename + PR + Git) with indented assignment sub-rows (ID + name + state + progress) replace flat single-row format
- **ace-overseer v0.3.1**: `WorkContext` model uses `assignments` array with derived `assignment_status` and `assignment_count` methods
- **ace-overseer v0.3.1**: `WorktreeContextCollector` loads all assignments via `AssignmentDiscoverer` instead of only active via `AssignmentExecutor`

## [0.9.529] - 2026-02-19

### Added

- **ace-overseer v0.3.0**: Assignment-aware status display — main branch appears in `status` when it has active assignments, assignment count shown per location
- **ace-overseer v0.3.0**: `--assignment` / `-a` option for `prune` command to remove a specific assignment's cache directory
- **ace-overseer v0.3.0**: `AssignmentPruneCandidate` model and `AssignmentPruneSafetyChecker` molecule for assignment-level prune safety
- **ace-assign**: `AssignmentManager#delete` method for removing assignment cache directories with symlink cleanup

### Changed

- **ace-overseer v0.3.0**: `StatusCollector` collects main branch context alongside worktree contexts; `StatusFormatter` sorts main branch last with dim `main` label
- **ace-overseer v0.3.0**: `WorktreeContextCollector` counts assignments per location; `WorkContext` model extended with `assignment_count` and `location_type` fields
- **ace-overseer v0.3.0**: `PruneOrchestrator` supports assignment-level pruning path with safety checks and force override

## [0.9.528] - 2026-02-19

### Changed

- **ace-overseer v0.2.17**: Fully delegate tmux management to ace-tmux — remove `WindowNameFormatter`, `tmux_session_name`/`window_name_format`/`window_preset` config options; `TmuxWindowOpener` now calls `ace-tmux window` CLI directly
- **ace-taskflow v0.37.0**: Remove `.00` suffix from orchestrator task filenames — orchestrators now named `NNN-orchestrator.s.md` instead of `NNN.00-orchestrator.s.md`, with detection based on subtask presence rather than filename pattern
- **ace-taskflow v0.37.0**: Remove `is_orchestrator?` from TaskReferenceParser; reject `.00` references with clear error
- **ace-test-runner-e2e**: Update taskflow fixture template to use new orchestrator naming

## [0.9.527] - 2026-02-19

### Fixed

- **ace-tmux v0.5.4**: Fix "index N in use" error when creating tmux windows in sessions with `base-index` set
- **ace-assign v0.12.1**: `reflect-verify-cycle` pair changed to conditional pattern; renamed `max_recursion` to `max_reruns` for clarity
- **ace-review v0.40.1**: Architecture-reflection preset diff range corrected to cover all implementation commits

### Added

- **ace-assign v0.12.0**: New `reflect-and-refactor` phase in catalog — analyzes implementation against ATOM principles and executes targeted refactoring before PR creation, with composition rules, recipe integration, and retro phase linkage
- **ace-review v0.40.0**: New `architecture-reflection` review preset and `reflection` focus prompt for pre-PR self-assessment with refactor/accept/skip categorization

### Changed

- **ace-overseer v0.2.16**: `TmuxWindowOpener` no longer manages tmux sessions — delegates entirely to ace-tmux `WindowManager` for window creation, session detection, and dedup
- **ace-assign v0.12.2**: Clarified ordering notes and consolidated duplicate conditional suggestions for composition rules
- **ace-assign v0.12.3**: Clarified `skill: null` and `context.default: null` semantics in reflect-and-refactor phase documentation

## [0.9.526] - 2026-02-19

### Fixed

- **ace-overseer v0.2.15**: Task ID extraction now recognizes `ace-task.NNN` worktree paths, fixing status mismatch with `ace-git-worktree list`

## [0.9.525] - 2026-02-19

### Added

- **ace-overseer v0.2.14**: `--force` flag and positional target filtering for `prune` command — force-remove unsafe worktrees and target specific task refs or folder names

### Fixed

- **ace-git-worktree v0.13.5**: Pass `--force` flag to `git worktree remove` when force removal is requested, fixing "contains modified or untracked files" errors

## [0.9.524] - 2026-02-19

### Fixed

- **ace-tmux v0.5.3**: Include stderr details in "Failed to create window" error message for better debugging

### Added

- **ace-overseer v0.2.13**: Progress callbacks for `work-on` and `prune` — real-time step-by-step output instead of post-hoc summary; prune shows safe/skipped candidates with reasons before confirmation prompt

## [0.9.523] - 2026-02-19

### Fixed

- **ace-taskflow v0.36.3**: Fix duplicate display of parent tasks in task listings — promote single-named parent tasks to orchestrators when subtasks reference them, and add relationship building to glob-loaded tasks

## [0.9.522] - 2026-02-17

### Fixed

- **ace-assign v0.11.16**: Fork root executor checks for existing in-progress phase in subtree before advancing to next workable phase
- **ace-assign v0.11.17**: `assignment_state` now checks `completed` before `failed` — assignments where all phases are done/failed correctly report `:completed` instead of `:failed`
- **ace-git v0.10.12**: PR matching now returns MERGED/CLOSED PRs for current branch when no OPEN PR exists, fixing empty PR metadata in overseer status
- **ace-git-worktree v0.13.3**: Ensure parent directory exists before worktree path validation to prevent PathExpander rejection when `.ace-wt/` directory doesn't exist yet
- **ace-git-worktree v0.13.4**: Add `ignore_untracked` support to worktree removal dirty checks so untracked-only worktrees can be safely pruned while tracked changes remain protected
- **ace-overseer v0.2.2**: Ensure `prune --quiet` still executes prune operations, add missing runtime dependencies, and handle `SIGINT` with exit code `130`
- **ace-overseer v0.2.5**: Set `PROJECT_ROOT_PATH` per worktree so each worktree resolves its own assignment cache instead of sharing the invoking worktree's data
- **ace-overseer v0.2.9**: Manage PROJECT_ROOT_PATH environment variable and clear ProjectRootFinder cache when switching worktree contexts to ensure ace-assign and other tools find correct configuration
- **ace-overseer v0.2.10**: Reuse existing tmux windows on rerun, treat untracked-only worktrees as prune-safe, and return user-friendly missing `--task` errors
- **ace-overseer v0.2.11**: Add `exit!(1)` safety net after `exec` in forked status worker and filter nil contexts from failed parallel workers to prevent `NoMethodError`
- **ace-overseer v0.2.12**: Prune now uses `ignore_untracked: true` for safe removals and tightens TS-OVERSEER-002 E2E assertions/config alignment to avoid path-matching false positives
- **ace-test-runner-e2e v0.16.1**: `ace-test-e2e-suite` now reads `execution.parallel` from config instead of hardcoding sequential execution
- **ace-test-runner-e2e v0.16.3**: Fix suite runner false positives — "partial" status now correctly counted, case-level counts shown in summary
- **ace-test-runner-e2e v0.16.5**: Detect slash-command mis-invocation failures early and enforce deterministic report-dir matching to prevent stale E2E report fallback

### Added

- **ace-assign v0.11.16**: `current_in_subtree` method on `QueueState` to find in-progress phase within a subtree
- **ace-assign v0.11.17**: `recently_active?` method on `QueueState` to detect stale in-progress phases (threshold: 1 hour)
- **ace-assign v0.11.17**: New `:stalled` assignment state for in-progress phases with no recent activity
- **ace-git v0.10.13**: `dirty_file_count` method and `dirty_files` key in RepoStatus for counting uncommitted files
- **ace-overseer v0.2.7**: Assign column showing compact assignment ID; Git dirty file count display (e.g., `✗ 3`)
- **ace-overseer v0.2.10**: Add command tests for `work-on` missing `--task` and task-not-found behavior

### Changed

- **ace-assign v0.11.18**: Remove dead `print_fork_scope_guidance` method and duplicate `fork_scope_root` definition from status command
- **ace-overseer v0.2.0**: Promote the initial `work-on`/`status`/`prune` control-plane implementation to the first minor release
- **ace-overseer v0.2.1**: Release patch after valid review cycle (no additional corrective changes required)
- **ace-overseer v0.2.2**: Expand assignment preset path coverage, improve `work-on` output timing phrasing, and harden prune task status checks for stale worktrees
- **ace-overseer v0.2.3**: Add thread-safe `gem_root` memoization, atomic assignment job writes, and more robust task ID extraction for worktree context collection
- **ace-overseer v0.2.4**: Replace release-centric status view with assignment-focused dashboard showing path, progress, and PR columns
- **ace-overseer v0.2.4**: Remove release resolver dependency from status collector, simplifying data flow
- **ace-overseer v0.2.4**: Add phase summary (total/done/failed) to worktree context and PR metadata display (OPN/MRG/CLS/DFT) to status output
- **ace-overseer v0.2.6**: Replace text status labels with Unicode icons and ANSI colors for compact, scannable dashboard output
- **ace-overseer v0.2.6**: Sort dashboard rows by PR number descending; rows without PR appear first (sorted by task desc)
- **ace-overseer v0.2.6**: Remove Path column (redundant with Task ID) to save horizontal space
- **ace-overseer v0.2.6**: Colorize PR state and Git state with ANSI colors; support new `:stalled` state icon
- **ace-overseer v0.2.7**: Reorder columns (Assign first, Progress last); fix column alignment; remove redundant title
- **ace-overseer v0.2.8**: Parallelize worktree context collection using fork/exec for 3-4x speedup (5-7s → 1.5s for 6 worktrees)
- **ace-overseer v0.2.10**: Right-size E2E coverage from 11 to 6 focused test cases and consolidate prune workflow assertions
- **ace-test-runner-e2e v0.16.2**: Remove all MT-format references from E2E testing guide and workflow instructions — TS-format is now the only documented convention
- **ace-test-runner-e2e v0.16.4**: Improve handbook guidance for balanced E2E vs unit coverage with required decision evidence and cost-tiered manual run strategy
- **ace-test-runner-e2e v0.16.5**: Clarify run-e2e skill/workflow guidance so `/ace:run-e2e-test` is explicitly executed in chat context, not bash
- **ace-test v0.1.2**: Remove all MT-format references from testing guides, workflows, and templates — TS-format is now the only documented E2E test format

## [0.9.521] - 2026-02-17

### Added

- **ace-assign v0.11.15**: Add catalog phase template `split-subtree-root` for split parent orchestration (project-overridable)

### Changed

- **ace-assign v0.11.15**: Split parent nodes with `sub_phases` now materialize as orchestration-only subtree roots (parent `skill` removed, `source_skill` metadata retained) and drive delegation/execution via fork root workflow
- **ace-assign v0.11.15**: Phase catalog loading now merges project overrides with defaults by phase name, enabling single-phase overrides without replacing full catalog

### Fixed

- **ace-assign v0.11.15**: Fork root parent instructions no longer duplicate `work-on-task` execution semantics and now correctly direct subtree drive flow

## [0.9.520] - 2026-02-17

### Fixed

- **ace-assign v0.11.14**: Scoped status now renders nested subtree roots correctly (for example `--assignment <id>@010.01`) with visible hierarchy and actionable current phase
- **ace-assign v0.11.14**: Runtime-expanded sub-phases now propagate and use explicit `taskref` metadata for deterministic task context and child phase frontmatter
- **ace-assign v0.11.14**: `fork-run` launcher now requires full `ace/llm`, preventing uninitialized LLM error constant crashes during provider failures

### Changed

- **ace-assign v0.11.14**: Preset expansion now applies placeholder substitution across all step fields (including nested metadata), not only `name`/`instructions`

## [0.9.519] - 2026-02-17

### Fixed

- **ace-assign v0.11.13**: Scoped assignment status now reports the actionable in-subtree phase (not always the scope root), enabling correct fork drive targeting with `--assignment <id>@<phase>`
- **ace-assign v0.11.13**: Runtime-expanded sub-phases now include step-specific action instructions and treat parent orchestration text as verification checklist rather than duplicated execution instructions

## [0.9.518] - 2026-02-17

### Changed

- **ace-assign v0.11.12**: `drive-assignment` now enforces hard no-skip phase execution with attempt-first failure evidence and required post-action state verification

### Added

- **ace-assign v0.11.12**: Add E2E policy scenario `TS-ASSIGN-005-no-skip-policy` to lock workflow-only no-skip guardrails

## [0.9.517] - 2026-02-17

### Changed

- **ace-assign v0.11.11**: `drive-assignment` workflow now auto-delegates detected fork-enabled subtrees with `ace-assign fork-run --assignment <id>@<root>` before inline phase execution

### Fixed

- **ace-support-nav v0.17.6**: Add `--tree` option to Resolve command to fix test suite crash
  - dry-cli called `exit(1)` on unrecognized `--tree` option, killing the process mid-test
  - This caused `ace-test-suite` to report 0 tests for ace-support-nav
  - Remove dead `navigation_integration_test.rb` (permanently skipped, testing non-existent class)

## [0.9.516] - 2026-02-16

### Fixed

- **ace-llm-providers-cli v0.16.6**: Add `SafeCapture` env-forwarding test coverage to validate subprocess environment propagation
- **ace-llm v0.22.2**: Add integration test to ensure `sandbox` parameter is threaded through `QueryInterface.query` generation options
- **ace-assign v0.11.10**: Add regression coverage for fork-scoped advancement when global current phase is outside subtree
- **ace-assign v0.11.10**: Add tests for CLI env propagation and query sandbox propagation in related runtime paths
- **ace-assign v0.11.9**: Fork-scoped report advancement now executes the scoped subtree phase instead of completing an out-of-scope global current phase
- **ace-assign v0.11.9**: E2E assertions for `parent` metadata now accept both single-quoted and double-quoted YAML values
- **ace-assign v0.11.8**: `fork-run` no longer depends on global current phase when explicit subtree scope is provided; scoped subtree execution can start from any node
- **ace-assign v0.11.6**: Remove child-level `context: fork` in split sub-phases and constrain advancement to fork subtree during scoped execution
- **ace-assign v0.11.5**: Runtime-expanded sub-phases now materialize concrete catalog metadata (skills + focused instructions), propagate parent task context to child phases, start from first workable leaf, and use single-entry fork delegation for forked subtrees
- **ace-taskflow v0.36.2**: Review cycle 2 fixes — CLI syntax for task promotion, plan-task standalone dead path
- **ace-assign v0.11.2**: Add test coverage for new composition ordering rules
- **ace-taskflow v0.36.1**: Review cycle 1 fixes — arrow notation, needs_review clearing, behavioral-spec validation
- **ace-assign v0.11.1**: Consolidate duplicate composition rule trigger

### Changed

- **ace-b36ts v0.7.0**: Week format now uses ISO Thursday rule for week-in-month calculation
  - Boundary dates encode to the month containing the week's Thursday
  - `decode_week` returns the Thursday of the week (the defining day)
  - Split encoder retains simple day-based weeks for path buckets

### Added

- **ace-assign v0.11.9**: Add regression test coverage for fork-scoped advancement when global current phase is outside the scoped subtree
- **ace-assign v0.11.8**: Add shared assignment target parsing with scoped syntax (`--assignment <id>@<phase>`) and coverage for scoped command behavior
- **ace-assign v0.11.7**: Add synchronous fork-session launcher (`ForkSessionLauncher`) using `ace-llm` and assign-level execution/provider defaults
- **ace-assign v0.11.6**: Add `ace-assign fork-run` command and subtree queue helpers for explicit fork-scope delegation
- **ace-assign v0.11.3**: `SkillAssignSourceResolver` molecule to resolve skill frontmatter `assign.source` URIs into workflow assignment metadata; default config paths for skill/workflow discovery
- **ace-taskflow v0.36.3**: `assign` frontmatter declaration to `work-on-task.wf.md` with canonical runtime sub-phases (`onboard`, `plan-task`, `work-on-task`) and `context: fork`

### Changed

- **ace-assign v0.11.10**: Centralize sub-phase numbering via `NumberGenerator.subtask` and complete tree state labels for pending/in-progress visibility
- **ace-assign v0.11.9**: Status output now includes explicit `Current Status` line for deterministic parsing
- **ace-review v0.39.3**: Harden review workflow instructions with explicit process-exit gating before feedback commands, standardized 10-minute timeout behavior, and session-targeted feedback examples
- **ace-assign v0.11.8**: Assignment-targeting commands now use a unified resolver; scoped status renders only the selected node subtree and shows scope root as current phase
- **ace-assign v0.11.7**: `ace-assign fork-run` now executes subtree sessions directly (blocking) with provider/cli-args/timeout overrides and explicit subtree outcome checks
- **ace-assign v0.11.6**: Status/report and fork-context docs now model parent-only fork markers with runtime subtree execution via `ACE_ASSIGN_FORK_ROOT`
- **ace-assign v0.11.4**: Clarify composition boundary — `compose-assignment` is catalog-only, while deterministic metadata-driven expansion is documented under prepare/runtime paths
- **ace-assign v0.11.3**: `AssignmentExecutor.start` now enriches phases with skill-declared workflow `assign.sub-phases` before expansion, enabling deterministic runtime sub-phase materialization without compose-specific wiring

### Technical

- **ace-assign v0.11.7**: Add `ace-llm` dependency and test coverage for launcher + fork-run integration
## [0.9.515] - 2026-02-16

### Changed

- **ace-taskflow v0.36.0**: Streamline task lifecycle — review-task becomes readiness gate, plan-task becomes JIT ephemeral, work-on-task accepts behavioral specs without plans
- **ace-assign v0.11.0**: Integrate JIT plan-task phase into recipes and composition rules
- **ace-assign v0.10.2**: Rename review cycle steps by type (`review-valid-1`, `review-fit-1`) and add shine cycle (`review-shine-1`, `apply-shine-1`, `release-shine-1`)
- **ace-assign v0.10.2**: Update `default_count` to 3 in composition rules for three review types (valid, fit, shine)

## [0.9.514] - 2026-02-16

### Changed

- **ace-assign v0.10.1**: Update preset progression references to new names (`code-valid`, `code-fit`, `code-shine`)

## [0.9.513] - 2026-02-16

### Changed

- **ace-review v0.39.2**: Rename phased presets — `code-correctness` → `code-valid`, `code-quality` → `code-fit`, `code-polish` → `code-shine`

## [0.9.512] - 2026-02-16

### Changed

- **ace-review v0.39.1**: Redistribute focus modules across phased presets — security/tests/ruby to code-quality, docs to code-polish; switch all 3 to multi-model reviewers (claude:opus, codex:max, gemini:pro-latest)

## [0.9.511] - 2026-02-16

### Added

- **ace-review v0.39.0**: Laser-focused phased review presets (`code-correctness`, `code-quality`, `code-polish`) with dedicated focus prompts and explicit scope boundaries
- **ace-review v0.39.0**: Backward-compatible `code-deep` preset as composition of `code` with detailed format
- **ace-assign v0.10.0**: Preset progression mapping in composition rules — review cycles now use phase-specific presets (correctness → quality → polish)

### Changed

- **ace-assign v0.10.0**: Review cycle presets in `work-on-task.yml` and `work-on-tasks.yml` updated from `code-deep` to phase-specific presets

## [0.9.510] - 2026-02-16

### Fixed

- **ace-git-worktree v0.13.2**: Fix ace-tmux invocation in CreateCommand — remove hardcoded `start` subcommand so ace-tmux auto-detects context (add window inside existing tmux session vs start new session)

## [0.9.509] - 2026-02-16

### Fixed

- **ace-git-worktree v0.13.1**: Fix `tmux_enabled?` and `should_auto_navigate?` config loading — remove redundant `WorktreeConfig.new()` wrapping that caused tmux config to be silently ignored

## [0.9.508] - 2026-02-16

### Added

- **ace-git-worktree v0.13.0**: Tmux integration for worktree creation — optional `tmux: true` config launches `ace-tmux` session rooted at new worktree after creation, with runtime binary detection and graceful fallback

## [0.9.507] - 2026-02-16

### Fixed

- **ace-taskflow v0.35.1**: Deduplicate subtask IDs when orchestrator frontmatter mixes short IDs (e.g., "243.02") with canonical IDs (e.g., "v.0.9.0+task.243.02")
- **ace-tmux v0.5.2**: First window name when starting a session with `--root` now derives from directory basename, matching `ace-tmux window` behavior
- **ace-llm-providers-cli v0.16.3**: Clear `CLAUDECODE` env var for subprocess spawning to fix nested session guard (Claude Code v2.1.41+); add `--sandbox read-only` to Codex to prevent agentic command execution during reviews

### Added

- **ace-taskflow v0.35.0**: `ace:manage-task-status` skill for task lifecycle operations (start, done, undone)
- **ace-taskflow v0.35.0**: `ace:reorganize-task` skill for task hierarchy operations (promote, demote, convert)
- **ace-taskflow v0.35.0**: `manage-task-status` workflow for status management guidance
- **ace-assign v0.9.0**: `documentation.recipe.yml` for documentation workflows with research phase
- **ace-assign v0.9.0**: `release-only.recipe.yml` for version bump workflows without code changes
- **ace-assign v0.9.0**: `work-on-docs.yml` preset for documentation workflow
- **ace-assign v0.9.0**: `release-only.yml` preset for release-only workflow
- **ace-assign v0.9.0**: `quick-implement.yml` preset for simple task implementation
- **ace-assign v0.9.0**: `fix-bug.yml` preset for bug fix with review workflow

### Changed

- **ace-test-runner-e2e**: Renamed package from `ace-test-e2e-runner` to `ace-test-runner-e2e` and binary from `ace-test-suite-e2e` to `ace-test-e2e-suite` for naming consistency
- **ace-taskflow v0.35.0**: Update timestamp dependency to ace-b36ts
- **ace-assign v0.9.0**: Update timestamp dependency from `ace-support-timestamp` to `ace-b36ts`

## [0.9.506] - 2026-02-14

### Fixed
- **ace-assign v0.9.1**: Tree formatter now correctly handles child-before-parent input ordering (two-pass index build)
- **ace-assign v0.9.2**: Frontmatter parser now rejects hints with both `include` and `skip` (mutual exclusivity validation)
- **ace-assign v0.9.3**: Validate that frontmatter hint `include`/`skip` values are strings
- **ace-bundle v0.30.4**: Fix typo in `format_sections_json_full` method name
- **ace-bundle v0.30.5**: Fix typo `orde2` → `order` and indentation alignment in `SectionProcessor`
- **ace-llm-providers-cli v0.16.4**: Pass Claude prompt via stdin to avoid Linux `MAX_ARG_STRLEN` (128KB) limit; remove redundant `--system-prompt` CLI arg
- **ace-llm-providers-cli v0.16.5**: Optimize subprocess environment — pass minimal env override instead of copying entire `ENV.to_h`

### Added
- **ace-assign v0.9.0**: Declarative assignment frontmatter — `assign:` block in `.s.md` and `.wf.md` files declares assignment intent (goal, variables, hints, sub-phases, context, parent)
- **ace-assign v0.9.0**: `AssignFrontmatterParser` atom for extracting and validating `assign:` frontmatter blocks
- **ace-assign v0.9.0**: `TreeFormatter` atom for rendering assignment hierarchy as indented tree with Unicode connectors
- **ace-assign v0.9.0**: Parent-child assignment linking via `parent` field in Assignment model
- **ace-assign v0.9.0**: `ace-assign list --tree` option for hierarchical assignment view
- **ace-assign v0.9.0**: Sub-phase fork enforcement in executor for phases with sub-phases
- **ace-assign v0.9.0**: Compose workflow integration — step 0 reads `assign:` frontmatter as structured input
- **ace-llm v0.22.1**: `sandbox:` parameter on `QueryInterface.query()` for controlling CLI provider sandbox mode

### Changed
- **ace-llm-providers-cli v0.16.4**: Codex `--sandbox` mode is now caller-controlled instead of hardcoded `read-only`
- **ace-review v0.38.1**: LlmExecutor passes `sandbox: "read-only"` to enforce non-agentic mode for CLI providers

## [0.9.505] - 2026-02-14

### Fixed

- **ace-tmux v0.5.1**: Bundler/Ruby environment variables (`BUNDLE_GEMFILE`, `BUNDLE_BIN_PATH`, `RUBYOPT`, `RUBYLIB`) no longer leak into tmux sessions and spawned processes

## [0.9.504] - 2026-02-14

### Added

- **ace-assign v0.8.3**: New `mark-task-done` phase for marking tasks as done in ace-taskflow after implementation
- **ace-assign v0.8.3**: Composition rules and conditional suggestions for `mark-task-done` phase
- **ace-assign v0.8.3**: `mark-task-done` step in `work-on-task`, `work-on-tasks` presets, and all task recipes

### Changed

- **ace-tmux v0.5.0**: Renamed gem from `ace-support-tmux` to `ace-tmux` — module namespace `Ace::Support::Tmux` to `Ace::Tmux`; binary and config paths unchanged (task 266)
- **ace-b36ts v0.6.0**: Renamed gem from `ace-support-timestamp` to `ace-b36ts` — module namespace `Ace::Support::Timestamp` to `Ace::B36ts`; binary `ace-timestamp` to `ace-b36ts`; config paths `timestamp` to `b36ts` (task 267)

## [0.9.503] - 2026-02-14

### Fixed

- **ace-support-tmux v0.4.1**: `ace-tmux --root /path` inside tmux now adds a window instead of erroring with "sessions should be nested" — unknown-arg routing is now context-aware

## [0.9.502] - 2026-02-14

### Added

- **ace-support-tmux v0.4.0**: Context-aware default presets — `ace-tmux` with no arguments starts default session (outside tmux) or adds default window (inside tmux)
- **ace-support-tmux v0.4.0**: `--root`/`-r` option on `start` command for working directory override

### Changed

- **ace-support-tmux v0.4.0**: `preset` argument now optional on `start` and `window` commands — falls back to configured defaults

## [0.9.501] - 2026-02-13

### Fixed

- **ace-support-tmux v0.3.4**: Session creation failing with `base-index 1` tmux config — uses window IDs (`@42` format) instead of index-based targeting

## [0.9.500] - 2026-02-13

### Fixed

- **ace-assign v0.8.2**: `list` command now shows filtered count context (e.g., `1/2 assignment(s) shown`) when completed assignments are hidden

## [0.9.499] - 2026-02-13

### Added

- **ace-assign v0.8.1**: Tests for `--assignment` flag targeting on mutating commands (add, fail, report, retry)

### Fixed

- **ace-assign v0.8.1**: Null safety for assignment name in `list` command table output

## [0.9.498] - 2026-02-13

### Added

- **ace-assign v0.8.0**: Multi-assignment support with `.current` symlink for explicit assignment selection
- **ace-assign v0.8.0**: `ace-assign list` command with table/JSON output, `--task` filter, and `--all` flag
- **ace-assign v0.8.0**: `ace-assign select <id>` command for switching active assignment
- **ace-assign v0.8.0**: `AssignmentInfo` model and `AssignmentDiscoverer` molecule for assignment state computation
- **ace-assign v0.8.0**: `--assignment` flag and `ACE_ASSIGN_ID` env var on all assignment commands
- **ace-assign v0.8.0**: Other assignments section in `status` output

## [0.9.497] - 2026-02-13

### Fixed

- **ace-support-tmux v0.3.3**: Window targeting uses unique window ID instead of name-based resolution, eliminating "can't find window" errors

### Added

- **ace-support-tmux v0.3.3**: `--name`/`-n` flag on `ace-tmux window` for explicit window name override

### Changed

- **ace-support-tmux v0.3.3**: Window name derived from `--root` basename instead of preset's `name` field

## [0.9.496] - 2026-02-13

### Fixed

- **ace-assign v0.7.3**: `apply-feedback.phase.yml` now correctly references `ace:apply-feedback` skill
- **ace-assign v0.7.4**: Missing `skill: ace:apply-feedback` in work-on-tasks preset; ordering rules now match suffixed phase names via prefix matching; "and" conditional rules now correctly require all conditions
- **ace-assign v0.7.5**: Misplaced doc block for `check_pair_completeness` moved to correct method in `CompositionRules`
- **ace-assign v0.7.5**: Duplicate examples in `prepare-assignment.wf.md` now accurately reflect renamed `work-on-task` preset
- **ace-assign v0.7.5**: `CatalogLoader.parse_phase_file` now warns on stderr when a phase YAML file fails to parse
- **ace-assign v0.7.5**: `compose-assignment.wf.md` uses Read/Glob tool references instead of `cat`/`ls`

### Added

- **ace-assign v0.7.3**: Flexible assignment composition system — phase catalog (14 phase types with prerequisites/produces/context metadata), composition rules (ordering constraints, phase pairs, conditional suggestions), recipe system (4 example patterns replacing rigid presets), and compose-assignment workflow for LLM-driven assignment building
- **ace-assign v0.7.3**: `CatalogLoader` and `CompositionRules` atoms for catalog querying and rule validation
- **ace-assign v0.7.3**: Conditional composition rule logic for context-dependent phase suggestions (e.g., suggest verify-test-suite when work-on-task is included)
- **ace-assign v0.7.4**: New phase catalog entries for push-to-remote, release, and reorganize-commits
- **ace-docs v0.20.0**: Squash-changelog workflow instruction for consolidating multiple CHANGELOG.md entries on feature branches before merge

### Changed

- **ace-assign v0.7.3**: Drive-assignment workflow now includes phase decision points for skip assessment and runtime adaptation
- **ace-assign v0.7.4**: Renamed `work-on-task-with-pr` preset to `work-on-task` as the default/primary workflow
- **ace-assign v0.7.5**: Added documentation for prefix matching constraints and mixed conjunction limitations in `CompositionRules`

## [0.9.495] - 2026-02-13

### Fixed

- **ace-support-tmux v0.3.2**: Fix pane startup race condition — `send-keys` now executes after `select-layout`, preventing resize artifacts; added `startup_delay` window attribute as proper replacement for per-pane sleep hacks

## [0.9.494] - 2026-02-13

### Fixed

- **ace-support-tmux v0.3.1**: Per-leaf pane `root` overrides now apply in nested layouts; `LayoutStringBuilder` pane ID fallback for short/empty arrays

## [0.9.493] - 2026-02-12

### Added

- **ace-support-tmux v0.3.0**: Nested pane layouts with arbitrary tree structure via `direction` key — `LayoutNode` model, `LayoutStringBuilder` atom for tmux custom layout strings, recursive preset resolution, and nested pane setup in `SessionManager`/`WindowManager`

## [0.9.492] - 2026-02-12

### Added

- **ace-support-tmux v0.2.0**: Generic `options` pass-through for window/pane tmux options, `--root`/`-r` flag on `window` command, improved default presets (3-pane layouts with claude/shell/nvim)

## [0.9.491] - 2026-02-12

### Added

- **ace-support-tmux v0.1.0**: New package — composable tmux session management via YAML presets with deep-merge composition at session, window, and pane levels, integrated with ACE config cascade

## [0.9.491] - 2026-02-12

### Fixed

- **ace-test-runner v0.15.3**: Replace shell-out to `hostname` with `Socket.gethostname` in test report environment capture — fixes `ace-test-suite` reporting errors on systems without `inetutils`

## [0.9.490] - 2026-02-12

### Fixed

- **ace-taskflow v0.34.7**: Case-insensitive `.md` file discovery in `CodenameExtractor` and cross-platform clipboard error handling in tests

## [0.9.489] - 2026-02-12

### Fixed

- **ace-support-mac-clipboard v0.2.1**: Guard module require and tests behind macOS platform check to prevent failures on non-macOS environments

## [0.9.488] - 2026-02-12

### Added

- **ace-prompt-prep v0.16.3**: Support `bundle.enabled: false` frontmatter flag to skip ace-bundle processing per prompt file

## [0.9.487] - 2026-02-12

### Fixed

- **ace-docs v0.19.2**: Anchor ignore patterns to project root in `DocumentRegistry` — prevents system paths like `/tmp/` from being incorrectly ignored by project-level glob rules

## [0.9.486] - 2026-02-12

### Fixed

- **ace-support-config v0.7.1**: Stabilize performance test threshold for `resolve_namespace` overhead (2.0x → 3.0x) to reduce CI flakiness

## [0.9.485] - 2026-02-12

### Changed

- **ace-test-e2e-runner v0.16.0**: Remove legacy .mt.md support — deleted ScenarioParser molecule; all test discovery and execution now uses TS-format directory structure only; dual-mode discovery simplified to single-mode

### Added

- **ace-test-e2e-runner v0.16.0**: TS-format E2E test structure — complete infrastructure for per-TC test scenarios in `TS-*/scenario.yml` directories; TC-level execution pipeline; Setup CLI subcommand; ScenarioLoader and TestCase molecules

### Fixed

- **ace-test-e2e-runner v0.16.0**: ScenarioParser TS-format fallback; display managers correctly extract test names from directory paths

## [0.9.484] - 2026-02-12

### Changed

- **ace-assign v0.7.2**: E2E tests renamed from COWORKER to ASSIGN terminology (coworker → assign, session → assignment, step → phase, jobs → phases)

## [0.9.483] - 2026-02-11

### Fixed

- **ace-assign v0.7.1**: E2E test scenario.yml files use correct `test-id` field (was `test-suite-id`); E2E test case .tc.md files use correct `tc-id` field (was `test-id`)

## [0.9.482] - 2026-02-11

### Fixed

- **ace-git-worktree v0.12.7**: TaskIDExtractor regex now correctly matches `task.NNN` in paths containing `ace-task.NNN` directory prefixes

### Technical

- **ace-git-secrets v0.7.6**: Remove legacy MT-SECRETS-002 E2E test file (functionality covered by TS-SECRETS-002)
- **ace-git-worktree v0.12.7**: Add path extraction test cases for TaskIDExtractor

## [0.9.481] - 2026-02-11

### Added

- **ace-git-commit v0.17.2**: Exception-based CLI error reporting for consistent error handling

### Technical

- **ace-git-commit v0.17.2**: Migrate E2E tests to per-TC directory format; Enhance E2E tests for commit splitting and path handling; Standardize E2E test cache directory naming

## [0.9.480] - 2026-02-11

### Changed

- **ace-support-nav v0.17.5**: Simplified path resolution in `ProtocolSource` to consistently use project root; extracted `find_project_root` private method

### Technical

- **ace-support-nav v0.17.5**: Migrate E2E tests to per-TC directory format; Add E2E tests for ace-nav and ace-timestamp

## [0.9.479] - 2026-02-11

### Fixed

- **ace-coworker v0.6.1**: E2E test suite reliability — split monolithic TC for isolation, fix Phase 2 setup for cascade test, use unique CACHE_BASE to prevent parallel test collisions

## [0.9.478] - 2026-02-11

### Fixed

- **ace-test-e2e-runner v0.15.1**: Expand relative PROJECT_ROOT_PATH to absolute sandbox path, ensuring agents running from monorepo root can find sandbox resources correctly

## [0.9.477] - 2026-02-11

### Added

- **ace-git-secrets v0.7.5**: E2E tests for scan, rewrite, and configuration workflows; full workflow and config cascade E2E tests

### Fixed

- **ace-git-secrets v0.7.5**: Ensure proper exit codes for scan, revoke, rewrite commands (CLI wrappers now raise Error with correct exit_code instead of returning 0); Move broken-report fixture out of .cache to avoid gitignore; Resolve non-zero exit code for --help flag

### Changed

- **ace-git-secrets v0.7.5**: Migrate E2E tests to per-TC directory format

## [0.9.476] - 2026-02-11

### Added

- **ace-test-e2e-runner v0.15.0**: `fix-e2e-tests` workflow and `/ace:fix-e2e-tests` skill — three-way diagnosis (code issue / test issue / runner issue) with cost-conscious iterative fix loop

### Fixed

- **ace-test-e2e-runner v0.15.0**: Code review feedback from PR #197

## [0.9.475] - 2026-02-11

### Added
- **ace-coworker v0.6.0**: `work-on-tasks` preset for multi-task batch execution with consolidated validation

### Fixed
- **ace-coworker v0.6.0**: Array instruction substitution in foreach expansion now properly handles {{item}} placeholders

### Technical
- **ace-coworker v0.6.0**: Removed deprecated work-on-task presets

## [0.9.474] - 2026-02-11

### Added

- **ace-test-e2e-runner v0.14.0**: 3-stage E2E pipeline — new `plan-e2e-changes` (Stage 2: decide) and `rewrite-e2e-tests` (Stage 3: execute) workflows with corresponding skills
- **ace-test-e2e-runner v0.14.0**: TS-format display support in suite display managers; metadata-based result override in suite orchestrator

### Changed

- **ace-test-e2e-runner v0.14.0**: `review-e2e-tests` (v2.0) rewritten from health report to coverage matrix (functionality × unit tests × E2E) with overlap/gap analysis
- **ace-test-e2e-runner v0.14.0**: `manage-e2e-tests` (v2.0) rewritten from 370-line monolithic flow to lightweight orchestrator chaining review → plan → rewrite
- **ace-test-e2e-runner v0.14.0**: TC classifications changed from ARCHIVE/CREATE/UPDATE/KEEP to REMOVE/KEEP/MODIFY/CONSOLIDATE/ADD

## [0.9.473] - 2026-02-11

### Added

- **ace-test-e2e-runner v0.13.0**: E2E Value Gate — decision framework embedded across guide (v1.5), template, and all 3 management workflows requiring justification that each TC needs real binary + real tools + real filesystem
- **ace-test-e2e-runner v0.13.0**: Coverage overlap analysis in `review-e2e-tests.wf.md` (v1.2) — new step comparing E2E TC coverage against unit test assertions with archival recommendations
- **ace-test-e2e-runner v0.13.0**: CONSOLIDATE management action in `manage-e2e-tests.wf.md` (v1.2) for merging TCs that share CLI invocations

### Changed

- **ace-lint E2E**: Restructured test suite from 8 scenarios / 31 TCs to 3 scenarios / 9 TCs — TS-LINT-001 (core lint pipeline, 5 TCs), TS-LINT-002 (config and routing, 2 TCs), TS-LINT-003 (doctor diagnostics, 2 TCs) — cutting LLM cost ~70% while preserving all unique integration value

## [0.9.472] - 2026-02-11

### Added

- **ace-test-e2e-runner v0.12.4**: TC fidelity validator — new `TcFidelityValidator` atom detects when agents invent test cases instead of executing defined `.tc.md` files; suite report post-validation replaces LLM-hallucinated aggregate numbers with deterministic totals

### Changed

- **ace-test-e2e-runner v0.12.4**: Workflow TC discovery guardrails — `execute-e2e-test.wf.md` requires explicit TC listing, forbids invented test cases, adds self-check step

### Fixed

- **ace-lint E2E**: TS-LINT-004 TC-004 replaced impossible validator name assertion with file-processing verification; TS-LINT-006 TC-002 replaced unreliably fixable fixture with code that has unambiguous standardrb violations

## [0.9.471] - 2026-02-11

### Changed

- **ace-test-e2e-runner v0.12.3**: Handbook TS-format support — updated 5 workflow files (`run-e2e-test`, `run-e2e-tests`, `review-e2e-tests`, `create-e2e-test`, `manage-e2e-tests`) to discover and reference both MT-format and TS-format scenarios; added `--format mt|ts` argument to `create-e2e-test` workflow; updated README and e2e-testing guide for dual-format architecture

## [0.9.470] - 2026-02-11

### Changed

- **ace-test-e2e-runner v0.12.2**: Decomposed E2E workflow — new `execute-e2e-test.wf.md` for pre-populated sandbox execution; skill routes conditionally based on `--sandbox` flag; removed `skill_aware?` distinction so all CLI providers use unified skill invocation; simplified `SkillPromptBuilder` and `TestExecutor` by removing embedded workflow prompt paths

## [0.9.469] - 2026-02-11

### Added

- **ace-test-e2e-runner v0.12.1**: Scenario-level sandbox pre-setup — `TestOrchestrator` runs `SetupExecutor` in Ruby before LLM invocation for TS-format scenarios, passing `sandbox_path` and `env_vars` to skip deterministic setup in the LLM; `SkillPromptBuilder` accepts `--sandbox` and `--env` params; workflow documents scenario-level sandbox mode

### Fixed

- **ace-assign v0.7.0**: Array instruction substitution in foreach expansion now properly handles `{{item}}` placeholders for both string and array instruction formats

### Changed

- **ace-assign v0.7.0**: work-on-tasks preset simplified with onboard step and direct skill delegation; E2E tests migrated from monolithic `.mt.md` format to per-TC directory structure with scenario.yml, test case files, and fixtures; Removed deprecated work-on-task preset (use `/ace:work-on-task` skill directly)

## [0.9.468] - 2026-02-11

### Added

- **ace-test-e2e-runner v0.12.0**: TS-format test infrastructure — TestCase model, ScenarioLoader, FixtureCopier, SetupExecutor molecules, TestCaseParser atom, dual-mode test discovery (`.mt.md` + `scenario.yml`), TC-level execution pipeline with per-test-case independence, `setup` CLI subcommand; ScenarioParser fix for `scenario.yml` delegation; ace-lint E2E tests migrated to per-TC directory format; review feedback addressed

### Changed

- **ace-assign v0.6.0**: Package renamed from ace-coworker to ace-assign; internal "session" concept renamed to "assignment"; internal "step" concept renamed to "phase"; phase file extension changed from .j.md to .ph.md; cache directory changed from .cache/ace-coworker/ to .cache/ace-assign/; skills renamed from /ace:coworker-* to /ace:assign-*; new combined /ace:assign-start skill (prepare + create in one step)

## [0.9.467] - 2026-02-10

### Fixed

- **ace-test-e2e-runner v0.11.2**: `--only-failures` no longer re-runs passing scenarios in multi-scenario packages — uses per-scenario failure data instead of flat per-package aggregation; correctly matches test files with descriptive filename suffixes against metadata test-ids; per-scenario `--test-cases` filtering passes each scenario only its own failed TC IDs; `SuiteProgressDisplayManager` nil guard for empty test queues

## [0.9.466] - 2026-02-10

### Fixed

- **ace-test-e2e-runner v0.11.1**: `--only-failures` now detects tests that errored without writing metadata — `write_failure_stubs` backfills stub `metadata.yml` for failed/errored tests with no cache entry (e.g., provider 503, timeout); FailureFinder wildcard fallback recognizes `status: "error"` and `"incomplete"` in addition to `fail` and `partial`

### Added

- **ace-test-e2e-runner v0.11.1**: `--test-cases` and `--dry-run` CLI flags for test case filtering; `--only-failures` flag for single-package and suite-level re-runs; `failed_test_cases` array in E2E `metadata.yml` for granular failure tracking

## [0.9.465] - 2026-02-08

### Added

- **ace-test-e2e-runner v0.11.0**: `ace-test-e2e-sh` sandbox wrapper script — enforces working directory and `PROJECT_ROOT_PATH` isolation for every bash command in E2E tests, preventing test artifacts from escaping the sandbox across separate shell invocations; all 43 E2E test files updated to use wrapper

## [0.9.464] - 2026-02-08

### Added

- **ace-test-e2e-runner v0.10.10**: Batch timestamp generation for `ace-test-suite-e2e` — `SuiteOrchestrator` pre-generates unique 50ms-offset run IDs and passes them via `--run-id` to subprocesses, giving coordinated sandbox/report paths across suite runs; `TestOrchestrator#run` accepts external `run_id:` for deterministic paths when invoked by suite

## [0.9.463] - 2026-02-08

### Fixed

- **ace-test-e2e-runner v0.10.9**: Surface silent failures in `SuiteOrchestrator#generate_suite_report` — replace blanket `rescue => _e; nil` with `warn` that prints error class and message; strip whitespace from `report_dir` regex captures to prevent path mismatches

## [0.9.462] - 2026-02-08

### Added

- **ace-test-e2e-runner v0.10.8**: Package filtering for `ace-test-suite-e2e` — optional comma-separated `packages` positional argument filters suite execution to specific packages (e.g., `ace-test-suite-e2e ace-bundle,ace-lint`), composable with `--affected` via intersection

## [0.9.461] - 2026-02-08

### Added

- **ace-test-e2e-runner v0.10.7**: Suite-level final report generation in `SuiteOrchestrator` — wires existing `SuiteReportWriter` into multi-package E2E runs, converting subprocess result hashes into `TestResult`/`TestScenario` models and producing LLM-synthesized reports after all tests complete

## [0.9.460] - 2026-02-08

### Fixed

- **ace-test-e2e-runner v0.10.6**: Unify timestamp precision to 7-char (`:"50ms"`) across all E2E paths — eliminates mixed 6/7-char timestamps in report folder names by making `default_timestamp` use `Timestamp.encode` with `:"50ms"` format and removing the `count <= 1` early return in `generate_timestamps`

## [0.9.459] - 2026-02-08

### Changed

- **ace-test-e2e-runner v0.10.5**: Extract `REFRESH_INTERVAL` constant for 4Hz refresh rate — replaces `0.25` magic number across both orchestrators and both progress display managers

## [0.9.458] - 2026-02-08

### Added

- **ace-test-e2e-runner v0.10.4**: Live timer refresh for single-package `--progress` display
  - Dedicated 4Hz refresh thread in `TestOrchestrator` updates running timers while tests execute
  - `ProgressDisplayManager#refresh` throttled to 250ms (matching `SuiteProgressDisplayManager` pattern)
  - New `ProgressDisplayManager` test coverage (header rendering, state transitions, throttle behavior)

## [0.9.457] - 2026-02-08

### Changed

- **ace-test-e2e-runner v0.10.3**: Throttle progress display refresh to ~4Hz (250ms) — reduces terminal I/O while keeping the poll loop responsive for process completion detection

## [0.9.456] - 2026-02-08

### Added

- **ace-test-e2e-runner v0.10.2**: `--progress` animated display for `ace-test-suite-e2e`
  - `SuiteProgressDisplayManager` with ANSI in-place row updates, running timers, and Active/Completed/Waiting footer
  - `SuiteSimpleDisplayManager` extracted from SuiteOrchestrator for default line-by-line display
  - SuiteOrchestrator delegates to pluggable display managers (matching TestOrchestrator pattern)

## [0.9.455] - 2026-02-08

### Changed

- **ace-test-e2e-runner v0.10.1**: Polished `ace-test-suite-e2e` output with columnar alignment and structured summary
  - Suite header with double-line `═` separators showing test/package counts
  - Per-test progress lines with aligned icon, duration, package, test name, and case counts
  - Structured summary block with failed test details, duration, pass/fail stats, and colored status
  - Suite-level `DisplayHelpers` formatting methods for duration, elapsed, test lines, and summary
  - Test case count extraction from subprocess output for richer progress display

## [0.9.454] - 2026-02-08

### Added

- **ace-test-e2e-runner v0.10.0**: `ace-test-suite-e2e` command for parallel E2E test execution across packages
  - `SuiteOrchestrator` organism for multi-package test orchestration
  - `AffectedDetector` molecule for detecting packages with recent changes
  - `--parallel N` option and `--affected` filter for targeted test runs
  - Shell injection prevention with array-based command execution
  - FrozenError fix in parallel execution output buffering

## [0.9.453] - 2026-02-07

### Added

- **ace-test-e2e-runner v0.9.0**: LLM-based E2E test execution CLI command with ATOM architecture
  - `ace-test-e2e` CLI for running E2E tests with parallel execution, display managers, and LLM-synthesized reports
  - Skill-based execution for CLI providers with configurable prompts and result parsing
  - Comma-separated test IDs support: `ace-test-e2e ace-lint 002,007`
  - Deterministic report paths via `run_id` and agent metadata reading
  - Enhanced CLI output with `[started]` messages, test case counts, and structured summaries
  - LLM-synthesized suite reports with root cause analysis, friction insights, and improvement suggestions

- **ace-llm-providers-cli v0.16.0**: New Pi CLI provider for multi-provider terminal AI agent access
  - Codex CLI skill command rewriting (`/name` → `$name` format)
  - Provider-agnostic `CommandRewriter` base class with configurable formatters
  - Thread-safe `SafeCapture` atom using process-level timeout

- **ace-llm v0.22.0**: `--cli-args` passthrough for CLI providers with docs and integration tests

- **ace-support-timestamp v0.1.0**: New gem for Base36 timestamp encoding/decoding

### Fixed

- **ace-lint v0.15.11**: Fix single-file `lint()` success inconsistency, help command exit codes, and E2E test fixtures
  - Convention/warning-only offenses now return `success: true`, matching `lint_batch()` behavior
  - Consolidated and optimized E2E tests for parallel execution (5→8 files, 36→31 cases)
  - Added MT-LINT-006 (report markdown), MT-LINT-007 (validator overrides), MT-LINT-008 (doctor modes)
  - Reduced bash blocks to minimize LLM round-trips and avoid E2E timeouts

## [0.9.426] - 2026-02-04

### Added

- **ace-review v0.37.3**: Priority range filtering with `+` suffix for `feedback list`
  - `--priority medium+` filters for medium, high, and critical items
  - `--priority high+` filters for high and critical items
  - New `PriorityFilter` atom for clean priority filtering logic

## [0.9.425] - 2026-02-04

### Added

- **ace-review v0.37.2**: SubjectFilter molecule and documentation (Task 233 feedback)
  - Extracted file filtering logic to `SubjectFilter` molecule (ATOM architecture)
  - README: Subject Strategy Configuration (strategy types, adaptive mode)
  - README: Reviewers Format documentation (attributes, file patterns, migration)
  - `ContextLimitResolver` now queries ace-llm provider config for context limits

## [0.9.424] - 2026-02-04

### Added

- **ace-llm v0.21.1**: Provider config `context_limit` field for model context window sizes
  - Google: 1M tokens (Gemini models)
  - Anthropic: 200K tokens (Claude models)
  - OpenAI: 128K tokens (GPT models)
  - Default 128K for unknown models in config.yml

## [0.9.423] - 2026-02-04

### Fixed

- **ace-review v0.37.1**: Graceful error handling for preset composition failures
  - Added nil check in `prepare_review_config()` for circular deps and missing refs
  - Returns actionable error message instead of crashing with nil method error
  - Updated E2E test MT-REVIEW-001 with valid test data (instructions, model format)

## [0.9.422] - 2026-02-04

### Added

- **ace-handbook v0.9.1**: Preference hierarchy for selfimprove workflow search targets
  - Workflows and guides preferred over skills for process improvements
  - Documents rationale: versioning, sharing, protocol support

## [0.9.421] - 2026-02-04

### Added

- **ace-test-e2e-runner v0.5.1**: CLI-Based Testing Requirement section in create-e2e-test workflow
  - Documents that E2E tests must test through CLI interface, not library imports
  - Provides valid/invalid approach examples and guidance for execution tests

## [0.9.420] - 2026-02-04

### Added

- **ace-review v0.37.0**: Multi-dimensional review architecture (Task 233)
  - Token estimation atoms: `TokenEstimator` (chars/4), `ContextLimitResolver` (model limits)
  - Subject strategy system: `FullStrategy`, `ChunkedStrategy`, `AdaptiveStrategy`
  - `Reviewer` entity model with configurable focus, patterns, and prompt additions
  - `DiffBoundaryFinder` for parsing unified diffs into file blocks

### Changed

- **ace-review v0.37.0**: `FullStrategy` accepts `headroom` config option

### Fixed

- **ace-review v0.37.0**: GPT-4 variant handling and diff header preservation

## [0.9.419] - 2026-02-04

### Added

- **ace-review v0.36.17**: Support for `--session all` in feedback list command
  - Aggregate feedback from all sessions in `.cache/ace-review/sessions/`
  - New `find_all_sessions` helper in `SessionDiscovery` module
  - SESSION column in table output when viewing all sessions
  - `session` field in JSON output for programmatic access

## [0.9.418] - 2026-02-04

### Changed

- **ace-git v0.10.11**: Improved reorganize-commits workflow with scope determination guidance
  - Added "Scope Determination" section to handle user-provided vs embedded status scope
  - When user provides explicit commit list/range, trust user's intent over embedded status
  - When mismatch detected (user provides 12 commits, status shows 5), ask for clarification
  - Added examples section showing common scenarios

## [0.9.417] - 2026-02-03

### Added

- **ace-handbook v0.9.0**: Self-improve workflow for transforming agent mistakes into system improvements
  - New `/ace:selfimprove` skill to analyze mistakes and improve processes
  - `selfimprove.wf.md` workflow with root cause analysis and fix templates

## [0.9.416] - 2026-02-03

### Changed

- **ace-review v0.36.16**: Refactored feedback CLI and removed legacy code
  - Added `SessionDiscovery` shared module for DRY session resolution (6 commands)
  - Removed 5 deprecated auto-save methods from `ReviewManager` (~150 lines)
  - Removed 11 deprecated auto-save tests (~270 lines)
  - Fixed documentation referencing obsolete `--task` and `--no-synthesize` flags

## [0.9.415] - 2026-02-03

### Added

- **ace-review v0.36.15**: Improved feedback list UX with archived item awareness
  - Shows archived count when no active items exist with hint to use `--archived`
  - Status-based sorting: draft → pending → done → skip → invalid (then by ID)
  - Summary line shows archived count hint when viewing active items only

## [0.9.414] - 2026-02-03

### Fixed

- **ace-review v0.36.14**: Feedback CLI commands failing when run from subdirectories
  - Replaced `Dir.pwd` with `ProjectRootFinder.find_or_current` in all 6 feedback commands
  - Session discovery now correctly finds project root regardless of current working directory

## [0.9.413] - 2026-02-03

### Fixed

- **ace-review v0.36.13**: Workflow documentation referencing removed `--task` CLI flag
  - Updated session discovery docs in `review.wf.md` and `review-pr.wf.md`
  - Improved feedback categorization guide with clearer skip/defer semantics

## [0.9.412] - 2026-02-03

### Fixed

- **ace-review v0.36.12**: Non-unique feedback IDs when batch-creating items in rapid succession
  - Pre-generate sequential IDs using `FeedbackIdGenerator.generate_sequence`
  - Uses ace-support-timestamp v0.5.0 `encode_sequence` for guaranteed uniqueness

## [0.9.411] - 2026-02-03

### Added

- **ace-support-timestamp v0.5.0**: Sequence generation for multiple sequential IDs
  - `--count` / `-n` option to generate N sequential IDs from a starting timestamp
  - JSON array output with `--count --json`
  - `CompactIdEncoder.encode_sequence` and `increment_id` methods
  - Overflow cascade handling (ms → 50ms → 2sec → block → day → month)

## [0.9.410] - 2026-02-03

### Fixed

- **ace-review v0.36.11**: Missing `feedback.synthesis_model` configuration in default config files
  - Added `feedback` section to `ace-review/.ace-defaults/review/config.yml` (package defaults)
  - Added `feedback` section to `.ace/review/config.yml` (project config)

## [0.9.409] - 2026-02-03

### Fixed

- **ace-review v0.36.10**: JSON parsing for Claude Opus feedback synthesis
  - `FeedbackSynthesizer.parse_synthesis_response` now handles LLM responses with text before JSON code fence
  - Fixes "Based on my analysis..." preamble causing `JSON::ParserError`

### Technical

- Extracted `extract_json_from_response` helper for robust JSON extraction from various LLM response formats

## [0.9.408] - 2026-02-03

### Changed

- **ace-review v0.36.9**: Feedback model configuration simplified
  - Removed `extraction_model` config alias (legacy) - use `synthesis_model` only
  - `FeedbackSynthesizer.default_synthesis_model` cascade simplified
  - `ReviewManager.extract_feedback` cascade simplified
  - Unified prompts - deleted `extract-feedback.system.md` (now uses `synthesize-feedback.system.md`)

### Technical

- ace-review test mock improvement for context extractor

## [0.9.407] - 2026-02-03

### Removed

- **ace-review v0.36.8**: Simplified feedback system - session-scoped only
  - `FeedbackContextResolver` molecule - task-based path resolution removed as overengineered
  - `--task` option from all feedback commands (create, list, show, verify, skip, resolve)
  - ~546 lines of code and tests removed

### Changed

- **ace-review v0.36.8**: Feedback is now session-scoped with `--session` flag across all commands
  - All feedback commands use consistent session-based resolution pattern
  - Latest session used as default when no `--session` specified

## [0.9.406] - 2026-02-03

### Fixed

- **ace-review v0.36.7**: PR review fixes
  - Documentation drift: ID format updated from "10-char" to "8-char" in feedback-workflow.md
  - Test base class violations: FeedbackFileWriter, FeedbackFileReader, FeedbackDirectoryManager tests now inherit from AceReviewTest
  - Missing trailing newline in .ace-defaults/review/config.yml

## [0.9.405] - 2026-02-03

### Removed

- **ace-review v0.36.6**: Dead code cleanup
  - `FeedbackDeduplicator` atom - superseded by LLM-based deduplication in FeedbackSynthesizer
  - `FeedbackExtractor` molecule - replaced by FeedbackSynthesizer which handles multi-report synthesis
  - ~600 lines of code and tests removed

## [0.9.404] - 2026-02-03

### Added

- **ace-review v0.36.5**: Post-review improvements from PR 189 feedback
  - Prompt size warning before LLM execution (warns at ~160K tokens, 80% of typical context)
  - `--session` flag for `feedback list` command to specify explicit session directory
  - Documentation for session-scoped feedback context in workflow instructions

### Fixed

- **ace-review v0.36.5**: Lock file (.feedback.lock) now cleaned up after writes

## [0.9.403] - 2026-02-03

### Changed

- **ace-review v0.36.4**: Remove synthesis entirely, feedback is now the primary output
  - FeedbackIdGenerator uses 8-char millisecond timestamp format (was 10-char with random suffix)
  - Workflow instructions updated to use feedback verification commands

### Removed

- **ace-review v0.36.4**: Synthesis system completely removed
  - `ReportSynthesizer` molecule and `ace-review synthesize` CLI command removed
  - `--synthesize`, `--no-synthesize`, `--synthesis-model` CLI flags removed
  - `synthesis:` and `feedback.enabled` config sections removed

## [0.9.402] - 2026-02-03

### Changed

- **ace-review v0.36.3**: Make feedback files the primary output (disable synthesis by default)
  - Synthesis now disabled by default per task 227 spec
  - Added `--synthesize` flag to opt-in to synthesis-report.md generation
  - Added explicit `feedback.enabled: true` default to config
  - Updated `should_synthesize?` to default to false, check for --synthesize CLI flag
  - ReviewOptions now includes :synthesize attribute

## [0.9.401] - 2026-02-03

### Added

- **ace-review v0.36.2**: Multi-reviewer consensus synthesis for feedback system
  - New `FeedbackSynthesizer` molecule with LLM-based consensus detection
  - Support for multiple reviewers per `FeedbackItem` (reviewers array format)
  - Consensus flag marks items agreed upon by 3+ models
  - Synthesis workflow integrated into review pipeline for multi-model reviews
  - New prompt template: `handbook/prompts/synthesize-feedback.system.md`

### Changed

- **ace-review v0.36.2**: FeedbackItem model updates for multi-reviewer support
  - New `reviewers` array attribute (replaces single `reviewer`)
  - Legacy `reviewer` accessor returns first reviewer for backward compatibility
  - `FeedbackFileWriter` handles new multi-reviewer format
  - `FeedbackManager` and `ReviewManager` integrate synthesis workflow

## [0.9.400] - 2026-02-03

### Added

- **ace-test v0.1.1**: Improve verify-test-suite workflow to detect unstubbed subprocess calls
  - Add Step 3b "Implementation Subprocess Detection" - search SOURCE files for subprocess patterns
  - Explicit subprocess source file search checklist for molecules tests
  - Add test base class check to test-review-checklist guide

## [0.9.399] - 2026-02-03

### Changed

- **ace-review v0.36.1**: Session symlink architecture for task reviews
  - Task reviews now symlink to session directories instead of copying files
  - Multiple review sessions can be linked to the same task
  - All session artifacts (prompts, metadata, feedback) accessible via symlink
  - Feedback stays in session directory (gitignored via .cache)

## [0.9.398] - 2026-02-03

### Added

- **ace-review v0.36.0**: Feedback-based review output architecture
  - Replace monolithic synthesis reports with tracked feedback items
  - `FeedbackItem` model with full lifecycle (pending → verified/skipped → resolved)
  - CLI commands: `feedback list`, `show`, `verify`, `skip`, `resolve`
  - Task integration with automatic `feedback/` directory creation
  - Single-model and multi-model feedback extraction
  - LLM-based extraction with semantic deduplication

## [0.9.397] - 2026-02-02

### Fixed

- **ace-support-nav v0.17.4**: Fix protocol listing with empty path and bare protocol names
  - `ace-nav wfi://` now correctly lists all resources (empty path normalized to nil)
  - `ace-nav wfi` (bare protocol) now auto-expands to `wfi://` for listing
  - Both shorthand forms now work identically to `ace-nav wfi://*`

## [0.9.396] - 2026-02-02

### Changed

- **ace-release workflow**: Streamlined to single commit - `/ace-bump-version` and `/ace-update-changelog` no longer commit independently; `/ace-release` orchestrates both and creates one atomic release commit with all 4 files (version.rb, package CHANGELOG, main CHANGELOG, Gemfile.lock)

## [0.9.395] - 2026-02-02

### Changed

- **ace-review v0.35.6**: Review workflows now default to "medium and higher" priority threshold for coworker automation, removing need for user confirmation

## [0.9.394] - 2026-02-01

### Changed

- **ace-git v0.10.10**: Improve stale git index lock handling - use progressive retry delays (1s, 2s, 3s, 4s) instead of fixed 500ms, lower stale threshold from 60s to 10s, always show lock wait messages

## [0.9.393] - 2026-02-01

### Changed

- **ace-coworker v0.5.3**: Remove `prepare` CLI command - use `/ace:coworker-prepare` workflow instead

## [0.9.392] - 2026-02-01

### Changed

- **ace-test-e2e-runner v0.5.0**: Consolidate E2E sandbox setup - move workflow from ace-test, add isolation checkpoint, delegate from run-e2e-test

## [0.9.391] - 2026-02-01

### Added
- **ace-taskflow**: Complete testing strategy subtasks
- **ace-test**: Integrate 6 testing guides into handbook
- **ace-test**: Integrate 4 new testing templates
- **ace-test**: Add 6 Claude skills for testing workflows

### Changed
- **ace-review**: Move subprocess test to integration layer

### Fixed
- **ace-git-worktree v0.12.6**: Stub `GitCommand.current_branch` in integration tests to prevent tests from reading actual git branch
- **ace-test**: Address code review feedback items

### Technical
- Document new testing skills in tools reference
- Add comprehensive testing guidance to ace-test README
- Register tmpl-sources for ace-test discovery
- Add 4 new testing workflows to handbook
- Register ace-test gem for guide protocol discovery

## [0.9.390] - 2026-01-31

### Fixed

- **ace-coworker v0.5.2**: Implement working `prepare` CLI command - uses Base36 timestamps, outputs to task's `jobs/` folder, correctly extracts parent task ID from subtask refs

## [0.9.389] - 2026-01-31

### Fixed

- **ace-bundle v0.9.4**: Correctly handle --help exit code
- **ace-coworker v0.5.0**: Ensure 0 exit code for help requests
- **ace-git-secrets v0.7.5**: Resolve non-zero exit code for --help
- **ace-git-worktree v0.3.1**: Prevent non-zero exit on help command
- **ace-lint v0.15.4**: Ensure help commands exit with status 0
- **ace-llm v0.5.5**: Correct help command exit status
- **ace-llm-providers-cli v0.1.1**: Handle --help flag correctly
- **ace-review v0.14.8**: Guarantee 0 exit code for help requests
- **ace-search v0.2.7**: Ensure help command returns exit code 0
- **ace-taskflow v0.34.7**: Correctly handle --help exit code
- **ace-test-runner v0.12.6**: Ensure help commands exit with status 0

### Added

- **ace-coworker v0.5.0**: Multi-task job preparation with PresetExpander atom - supports batch-parent/foreach expansion directives, array parameter parsing (comma, range, pattern syntax), and hierarchical step generation
- **ace-review v0.14.8**: Batch review preset for consolidated evaluation of multiple task implementations

### Changed

- **ace-core v0.4.3**: Standardize explicit help handling in CLI default routing pattern
- **docs**: Add warning about resetting uncommitted changes to agent integrations guide

## [0.9.388] - 2026-01-31

### Added

- **ace-handbook v0.8.0**: Multi-agent research synthesis capabilities - guide, workflows, templates, and skills for parallel agent research and output synthesis (Task 254)

## [0.9.387] - 2026-01-31

### Fixed

- **ace-git-secrets v0.7.4**: Optimize slow tests by stubbing subprocess calls - convert clean_working_directory? tests from real git calls to stubbed Open3.capture2, remove flaky availability test, suite time improved ~23%

## [0.9.386] - 2026-01-31

### Fixed

- **ace-lint v0.15.3**: Eliminate random slow tests by pre-warming availability caches and ensuring all tests stub availability checks (consistent ~60-70ms vs previous 60ms-1.6s variance)

## [0.9.385] - 2026-01-31

### Technical

- **ace-taskflow v0.34.6**: Optimize slow tests with minimal fixtures instead of full test project setup

## [0.9.384] - 2026-01-31

### Technical

- **ace-lint v0.15.2**: Stub subprocess calls in slow tests to avoid real system() calls for availability checks, reducing test suite time from ~2.1s to ~69ms

## [0.9.383] - 2026-01-31

### Fixed

- **ace-taskflow v0.34.5**: Update `test_missing_title_returns_error` to expect `CLI::Error` exception per ADR-023

## [0.9.382] - 2026-01-31

### Fixed

- **ace-support-core v0.22.2**: Preserve original message in `CLI::Error#message`, fix Ruby 3 keyword args in tests, fix `Dry::CLI::Registry` usage

## [0.9.381] - 2026-01-31

### Fixed

- **ace-support-test-helpers v0.12.2**: Add `respond_to?(:get)` check to `test_stub_ace_core_config_integration` skip condition

## [0.9.380] - 2026-01-31

### Fixed

- **ace-test-runner v0.15.2**: Fix `--profile` verbose mode to inject `--verbose` into Minitest ARGV; update result parser to support both Minitest::Reporters and standard Minitest formats

## [0.9.379] - 2026-01-31

### Performance

- **ace-bundle v0.30.3**: Moved CLI integration tests to E2E format (~2.1s savings)
  - `cli_api_parity_test.rb` → `test/e2e/cli-api-parity.mt.md`
  - `cli_auto_format_test.rb` → `test/e2e/cli-auto-format.mt.md`

## [0.9.378] - 2026-01-31

### Added

- **ace-test-runner v0.15.1**: Expanded default test patterns (smoke, commands, cli, prompts, fixtures, support, edge) for comprehensive test discovery

### Changed

- **Project config**: Updated `.ace/test/runner.yml` patterns: cli_commands → cli, added prompts, fixtures, support

## [0.9.377] - 2026-01-31

### Fixed

- **ace-taskflow v0.34.4**: Update require paths, class references, and fix stub leak in create command tests

## [0.9.376] - 2026-01-31

### Fixed

- **ace-support-test-helpers v0.12.1**: Improve `stub_ace_core_config` isolation with `respond_to?` guard and `define_singleton_method`

## [0.9.375] - 2026-01-31

### Fixed

- **ace-support-core v0.22.1**: Move GemClassMixin inside ConfigSummaryMixin to fix test isolation constant reference issues

## [0.9.374] - 2026-01-31

### Fixed

- **ace-search v0.19.2**: Reset config in test setup to prevent test isolation issues

## [0.9.373] - 2026-01-31

### Technical

- **ace-docs v0.19.1**: Stub ace-nav subprocess calls in document_analysis_prompt tests (3.4s → 0.7s, 80% faster)

## [0.9.372] - 2026-01-31

### Added

- **ace-test-runner v0.15.0**: Execution mode CLI flags for `ace-test`
  - `--run-in-sequence`/`--ris`: Run test groups sequentially (default behavior)
  - `--run-in-single-batch`/`--risb`: Run all tests together in a single batch
  - `ace-test-suite` now passes `--run-in-single-batch` to each package for cleaner output

## [0.9.371] - 2026-01-31

### Fixed

- **ace-git v0.10.9**: `load_for_pr` no longer fetches unnecessary PR activity

### Technical

- **ace-git v0.10.9**: Add missing test stubs for PR activity fetchers (2.3s → 16ms)

## [0.9.370] - 2026-01-31

### Fixed

- **ace-test-runner v0.14.0**: Fix profiling with grouped execution
  - `ace-test package --profile N` now shows actual test times instead of 0.000s
  - Bypasses grouped mode when profiling without a specific target
  - Group-specific profiling (`ace-test package group --profile N`) unchanged

## [0.9.369] - 2026-01-31

### Technical

- **ace-git v0.10.8**: Stub `Kernel.sleep` in lock retry tests for 98% speedup (2.5s → 32ms)

## [0.9.368] - 2026-01-31

### Added

- **ace-test-runner v0.13.0**: Slowest-first package scheduling for `ace-test-suite`
  - New `DurationEstimator` reads historical duration from `test-reports/latest/summary.json`
  - Orchestrator sorts packages by expected duration (descending), then priority
  - Prevents slow packages from becoming bottlenecks at end of parallel test runs

### Changed

- **ace-test-suite config**: Reduced `max_parallel` from 20 to 10
  - Balances speed vs resource contention on typical dev machines

## [0.9.367] - 2026-01-31

### Fixed

- **ace-test-runner v0.12.6**: Fix test suite timing discrepancy
  - Display managers now use `results[:duration]` instead of wall-clock `status[:elapsed]`
  - Eliminates subprocess startup overhead (~5s) from reported package times
  - `ace-test-suite` now shows accurate Minitest execution duration

## [0.9.366] - 2026-01-31

### Changed

- **ace-review v0.35.5**: Optimized test suite performance (62% reduction)
  - Added SharedTempDir module for opt-in per-class temp directory sharing
  - Migrated 58 integration-style tests to E2E format (MT-REVIEW-004, MT-REVIEW-005)
  - Test execution time reduced from 14.68s to 5.52s

## [0.9.365] - 2026-01-31

### Changed

- **ace-lint v0.15.1**: Moved CLI integration tests to E2E suite
  - Created MT-LINT-004 and MT-LINT-005 for CLI and doctor command tests
- **ace-git-secrets v0.7.3**: Moved integration tests to E2E suite
  - Created MT-SECRETS-001, MT-SECRETS-002, MT-SECRETS-003
  - Test execution time reduced from 4.5s to ~1.8s (60% reduction)
- **ace-bundle v0.30.2**: Moved section workflow tests to E2E suite
  - Created MT-BUNDLE-001 for section workflow tests
- **ace-review v0.35.4**: Moved integration tests to E2E suite and consolidated deep_merge_hash
  - Created MT-REVIEW-001, MT-REVIEW-002, MT-REVIEW-003
  - Consolidated duplicate deep_merge_hash to centralized DeepMerger
  - Test execution time reduced from 19.52s to ~13.5s (31% reduction)

## [0.9.364] - 2026-01-31

### Changed

- **ace-support-timestamp v0.4.1**: Moved CLI integration tests to E2E suite
  - Test execution time reduced from 13.93s to ~61ms (99.6% reduction)

## [0.9.363] - 2026-01-30

### Changed

- **ace-git v0.10.7**: Simplify rebase workflow from 677 to 373 lines (45% reduction)

## [0.9.362] - 2026-01-30

### Added

- **ace-git v0.10.6**: Improve rebase workflow with state capture and verification

### Technical

- **ace-git v0.10.6**: Apply review feedback to rebase workflow documentation

## [0.9.361] - 2026-01-30

### Changed

- **ace-test-runner v0.12.5**: Code quality improvements from PR review
  - Clarified DisplayHelpers docstring to explain `color()`/`colorize()` relationship
  - Package column width now calculated dynamically from actual package list
  - Removed unused `build_summary_text` method (dead code cleanup)
  - Added factory method tests for `create_display_manager`

## [0.9.360] - 2026-01-30

### Fixed

- **ace-test-runner v0.12.4**: Discovered and fixed orphaned suite tests
  - Tests in `test/suite/` were not being run by test runner (not a recognized group)
  - Moved to `test/integration/suite/` where they are now discovered and executed
  - Fixed test assertions to match current `DisplayHelpers` output format
  - Added 22 previously invisible tests to the test suite

## [0.9.359] - 2026-01-30

### Changed

- **ace-test-runner v0.12.3**: Aligned progress mode output format with simple mode
  - Consistent column ordering: status icon, time, package name, progress/stats
  - Status icons: `·` (waiting), `⋯` (running), `✓`/`?`/`✗` (completed)
  - Package name without brackets (25 chars, left-justified)
  - Columnar stats for completed: `N tests  M asserts  F fail`

## [0.9.358] - 2026-01-30

### Changed

- **ace-test-runner v0.12.2**: Refactored suite summary output for better visibility
  - Status line (`✓ ALL TESTS PASSED`) now appears last, always visible when run completes
  - Skipped packages shown as compact single line: `Skipped: pkg1 (2), pkg2 (14)`
  - Simplified stat format: removed totals, shows just `passed, failed`
  - Added checkmark/cross prefixes to status messages

## [0.9.357] - 2026-01-30

### Changed

- **ace-test-runner v0.12.1**: Improved output format for better readability
  - Status icon first (✓/✗/?) for easy visual scanning
  - Time second (right-aligned) to spot slow packages
  - Columnar stats with abbreviated labels (tests/asserts/fail)
  - Example: `✓   1.46s  ace-support-core  221 tests  601 asserts  0 fail`

## [0.9.356] - 2026-01-30

### Added

- **ace-test-runner v0.12.0**: Simple output mode as new default for `ace-test-suite` (task 244)
  - Line-by-line results without ANSI cursor control
  - New `--progress` flag enables animated progress bars (previous default)
  - `SimpleDisplayManager` class for agent-friendly output
  - `DisplayHelpers` module for shared display formatting logic
- **ace-test-runner v0.12.0**: Exception-based exit codes for cleaner CLI error handling

### Fixed

- **ace-test-runner v0.12.0**: Test require paths and fixtures in DisplayHelpersTest

### Changed

- **ace-test-runner v0.12.0**: Default display mode switched from animated to simple output (better for CI/CD, logs, and agents)

### Technical

- **ace-test-e2e-runner**: Refined E2E test creation workflow documentation

## [0.9.355] - 2026-01-30

### Changed

- **ace-coworker v0.4.3**: Rewrote MT-COWORKER-003 E2E test to match implemented behavior (dynamic hierarchy via `add --after --child` instead of static config)
- **ace-test-e2e-runner**: Improved E2E test creation workflow with lessons learned from test spec/implementation mismatches

### Technical

- **ace-coworker v0.4.3**: Version bump and E2E test verification stamp

## [0.9.354] - 2026-01-30

### Fixed

- **ace-coworker v0.4.2**: MAX_DEPTH constant corrected to 2 (allowing 3 levels max: 010.01.01) to match documented behavior
- **ace-coworker v0.4.2**: CLI `add --child` command validates depth upfront with clear error message

### Changed

- **ace-coworker v0.4.2**: `auto_complete_parents` emits warning when safety iteration limit is reached
- **ace-coworker v0.4.2**: `rollback_renames` captures and reports rollback failures instead of silently swallowing them

## [0.9.353] - 2026-01-30

### Fixed

- **ace-coworker v0.4.1**: Cache directory now respects `PROJECT_ROOT_PATH` for sandboxed/isolated E2E testing

## [0.9.352] - 2026-01-30

### Added

- **ace-coworker v0.4.0**: Hierarchical job structure - jobs can now have nested sub-jobs (010.01, 010.02) with parent-child relationships
- **ace-coworker v0.4.0**: `--after` and `--child` options for `add` command to inject jobs dynamically
- **ace-coworker v0.4.0**: `--flat` option for `status` command to show flat list without hierarchy
- **ace-coworker v0.4.0**: New `JobNumbering` atom for hierarchical number operations
- **ace-coworker v0.4.0**: Audit trail metadata (`added_by`, `parent`, `renumbered_from`) for job history tracking

### Fixed

- **ace-coworker v0.4.0**: Cascade renumbering to descendants when jobs are shifted (prevents orphaning)
- **ace-coworker v0.4.0**: Enforce hierarchy in advance - cannot mark parent done with incomplete children
- **ace-coworker v0.4.0**: Re-scan state after auto-completion to ensure fresh data for next step selection

### Changed

- **ace-coworker v0.4.0**: Auto-complete parents handles multi-level hierarchies in single pass
- **ace-coworker v0.4.0**: Uses `next_workable` instead of `next_pending` to respect hierarchy

## [0.9.351] - 2026-01-30

### Fixed

- **ace-coworker v0.3.1**: Job files already in a `jobs/` directory are kept in place instead of being moved to a nested path when creating sessions

### Changed

- **ace-release skill**: Updated instructions to use `Action: Skill('/ace:command')` format for clearer agent invocation

## [0.9.350] - 2026-01-30

### Added

- **ace-coworker v0.3.0**: Fork context support for jobs - enable job steps to run in isolated agent contexts via `context: fork` frontmatter with Task tool integration, context validation, and comprehensive documentation

## [0.9.349] - 2026-01-30

### Fixed

- **ace-test-e2e-runner v0.4.1**: Updated report path documentation from sibling pattern to subfolder pattern (`-reports/`) for consistency with implementation
- **ace-test-e2e-runner v0.4.1**: Removed incorrect `artifacts/` subdirectory from test data path examples in templates

### Technical

- **ace-test-e2e-runner v0.4.1**: Added pre-creation sandbox verification gate to workflow instructions
- **ace-test-e2e-runner v0.4.1**: Enhanced directory structure diagrams for consistency across guides and templates
- Added E2E test fixture files to project .gitignore

## [0.9.348] - 2026-01-29

### Changed

- **ace-git v0.10.5**: Clarified reorganize-commits workflow to emphasize that reorganize means reorder into logical groups, not squash into fewer commits

## [0.9.347] - 2026-01-29

### Added

- **ace-test-e2e-runner v0.4.0**: Parallel E2E test execution with subagents via `/ace:run-e2e-tests` orchestrator skill enabling concurrent test runs with aggregated suite reports
- **ace-test-e2e-runner v0.4.0**: Subagent return contract for structured result passing between orchestrator and worker skills
- **docs**: Skill definition for parallel E2E test runner in agent-integrations documentation

### Changed

- **ace-test-e2e-runner v0.4.0**: Renamed cache directory from `test-e2e` to `ace-test-e2e` for clear namespace identification
- **ace-test-e2e-runner v0.4.0**: Enhanced sandbox naming with test ID inclusion (`{timestamp}-{package}-{test-id}/`) for unique identification
- **ace-test-e2e-runner v0.4.0**: Moved reports outside sandbox as sibling files (`.summary.r.md`, `.experience.r.md`, `.metadata.yml`) enabling suite-level aggregation

### Technical

- Updated E2E tests across packages (ace-git-commit, ace-coworker, ace-git-worktree, ace-lint, ace-prompt-prep, ace-support-timestamp) for consistent cache directory naming convention
- Documented unplanned work from session 221 (tasks 244, 245)

## [0.9.346] - 2026-01-29

### Added

- **ace-test-e2e-runner v0.3.0**: Persistent test reports (test-report.md, agent-experience-report.md, metadata.yml) with automated generation and disk storage for comprehensive test execution tracking and agent experience insights
- **ace-test-e2e-runner v0.3.0**: ace-taskflow fixture template for standardized taskflow structure creation in E2E tests

### Changed

- **ace-test-e2e-runner v0.3.0**: Updated test environment structure to use artifacts/ subdirectory for test data organization, separating test data from generated reports
- **ace-test-e2e-runner v0.3.0**: Enhanced E2E testing guidelines with emphasis on error path coverage, negative test cases, and comprehensive error testing best practices

## [0.9.345] - 2026-01-29

### Fixed

- **ace-review v0.35.3**: Multi-model executor hanging on slow CLI providers by adding timeout to Thread.join with deadline-based join and error suppression for killed threads
- **ace-taskflow**: Use correct 'cancelled' status for skipped tasks per config valid_values (.ace/taskflow/config.yml)
- **ace-coworker**: Error handling showing exception object instead of message, improved session archiving with cache base directory creation

### Added

- **ace-coworker**: Fork context for jobs, enabling execution via Task tool in isolated agent context with dynamic workflows
- **ace-coworker**: Automatic review verification and auto-judgment using Chain of Verification (CoV) pattern for validated feedback

## [0.9.344] - 2026-01-29

### Added

- **ace-coworker v0.2.1**: CLI exit codes documentation (`docs/exit-codes.md`) documenting exit codes 0-3 with meanings and examples
- **ace-config**: WFI source protocol for ace-test gem

### Changed

- **ace-coworker v0.2.1**: Updated E2E test TC-004 to reflect actual `start` command behavior (migration alias to `create` with deprecation warning), added TC-004b test case for cache directory auto-creation, added cache directory setup to E2E test environment

### Fixed

- **ace-coworker v0.2.1**: Cache directory initialization bug where `.cache/ace-coworker/` was never created before `generate_session_id` called `Dir.mkdir()`, causing `Errno::ENOENT` crash on first use

### Technical

- Bump ace-coworker to version 0.2.1

## [0.9.343] - 2026-01-29

### Added

- **ace-review v0.35.2**: Enhanced review synthesis prompts with accuracy guidelines, conflict resolution rules, "Verification Required" section for unverifiable claims, and "Future Considerations" section to separate speculation from action items
- **ace-taskflow v0.34.3**: CLI-specific sections in task draft template (exit codes, input validation, concurrency, cleanup behavior)
- **docs**: CLI development checklist in ace-gems.g.md covering exit codes, error messages, input validation, resource cleanup, concurrency safety, and dependencies
- **ADR-023**: SIGINT handling convention (exit code 130), expanded exit code table (codes 2-4), exit code contract documentation requirements

### Changed

- **ace-handbook v0.7.1**: Refine exit code handling documentation in cli-dry-cli.g.md with exception-based pattern
- **ace-review**: Add severity classification and scope boundary guidance to base review prompt
- **ace-taskflow**: Add data-driven feature requirements checklist and CLI task examples to templates README

### Technical

- Bump ace-handbook to 0.7.1, ace-review to 0.35.2, ace-taskflow to 0.34.3

## [0.9.342] - 2026-01-28

### Added

- **ace-git v0.10.4**: Bundle section to reorganize-commits workflow for context loading via ace-bundle

### Technical

- Bump ace-git to version 0.10.4

## [0.9.341] - 2026-01-28

### Fixed

- **ace-coworker v0.1.7**: CLI exit code wrapper propagation via `@captured_exit_code` and `wrap_command` method for proper exit code handling
- **ace-coworker**: Race condition in `append_report` file locking - now rewrites content in-place on locked file descriptor instead of temp file + rename (preserves POSIX locks)
- **ace-coworker**: Session ID generation max retry limit (100 attempts) to prevent infinite loop

### Added

- **ace-coworker**: Prepare command stub with helpful message directing users to create job.yaml manually or use the prepare-coworker-job workflow
- **ace-coworker**: Migration UX for deprecated commands (start → create) with warning message

### Changed

- **ace-coworker**: Improve error messages with actionable suggestions (e.g., "Try 'ace-coworker add' or 'ace-coworker retry'")
- **ace-coworker**: E2E test comment alignment - "creates separate .r.md report file" (was "appends report inline")

## [0.9.340] - 2026-01-28

### Changed

- **ace-coworker v0.1.6**: Restructure workflows into focused commands: `create-coworker-session.wf.md` for session creation, `drive-coworker-session.wf.md` for execution loop, and `prepare-coworker-job.wf.md` for job preparation (renamed from `coworker-prepare-job.wf.md` for verb-first naming)
- **ace-coworker**: Clarify terminology by replacing "job files" with "step files" in documentation to avoid confusion with the non-existent `jobs.yml`

### Fixed

- **ace-coworker**: Address PR #178 review findings including report file handling, step number padding, state transitions, and error messages

### Technical

- Update ace-coworker MVP task file with current implementation status

## [0.9.339] - 2026-01-28

### Added

- **ace-coworker v0.1.5**: Separate job and report files with `.j.md` and `.r.md` extensions, new `reports/` directory structure for storing completion reports separately from job files

### Technical

- **ace-coworker**: Add retrospective spec for first ace-coworker cycle analysis
- **ace_work_on_task**: Update skill definition

## [0.9.338] - 2026-01-28

### Added

- **ace-coworker v0.1.4**: Archive job.yaml to task's `jobs/` directory after session creation (`{session_id}-job.yml`)

### Technical

- **ace-coworker**: Document state machine assertion fixes in mt-coworker-001 spec

## [0.9.337] - 2026-01-28

### Changed

- **ace-coworker v0.1.3**: Standardize instructions format to arrays in coworker-prepare-job workflow doc
- **ace-test-e2e-runner**: Improve E2E testing guidelines and templates

### Technical

- **ace-coworker v0.1.3**: Enhance workflow lifecycle E2E tests with error paths and state verification
- Update changelog generation instructions in workflow

## [0.9.336] - 2026-01-28

### Fixed

- **ace-coworker v0.1.2**: CLI `start` command crashes with positional argument — renamed to `create` with positional `argument :config`
- **ace-coworker v0.1.2**: `ace-bundle wfi://coworker-prepare-job` fails due to missing project-level wfi:// protocol registration

### Added

- **ace-coworker v0.1.2**: Support array format for step instructions in presets with `normalize_instructions`
- **skills**: Add `ace:coworker-create-session` skill for session creation from job.yaml
- **skills**: Add `ace:coworker-start` skill for driving agent execution through active session

### Changed

- **ace-coworker v0.1.2**: Preset files now use array instructions format, updated workflow instructions and README

## [0.9.335] - 2026-01-28

### Fixed

- **ace-git-worktree v0.12.5**: Use current branch as target branch fallback for non-subtask tasks instead of always defaulting to main, fixing wrong PR target branch when creating worktrees from feature branches
- **ace-coworker v0.1.1**: Persist skill field from job.yaml steps through full pipeline (StepWriter, StepFileParser, QueueScanner, Step model) and display in status command output

## [0.9.334] - 2026-01-27

### Changed

- **ace-git v0.10.3**: Improve git lock detection and CLI error handling
  - Lock retry now detects active lock PID and increases wait time on active locks
  - Lock cleanup reports lock status metadata (pid/age) for better diagnostics
  - CLI now shows error for unknown commands instead of routing to diff

## [0.9.333] - 2026-01-27

### Technical

- **ace-git v0.10.2**: Simplified reorganize-commits workflow documentation
  - Streamlined workflow instructions by removing verbose examples
  - Reduced documentation from 109 lines to 26 lines while preserving essential steps

## [0.9.332] - 2026-01-27

### Added

- **ace-git-commit v0.17.1**: Add `spec` commit type for development artifacts
  - Add `spec` as recognized commit type for task specifications, planning docs, retros, ideas
  - Clarify `docs` type is for software documentation (user guides, API docs, README)
  - Fix: type_hint config now properly influences LLM commit type selection

## [0.9.331] - 2026-01-27

### Changed

- **ace-taskflow v0.34.2**: Add explicit idea glob pattern alias and DRY improvements
  - Add `default_idea_glob_pattern` alias for clearer method naming
  - DRY up `get_statistics` to use `Configuration#default_task_glob_pattern`

### Technical

- **Task 226**: Enhance multi-dimensional review architecture specs based on review feedback
  - Add `<context_carryover>` XML format and FindingsExtractor atom spec for progressive strategy
  - Define overflow behavior with line-based truncation and summary size limits for chunked strategy
  - Add map-reduce condensation and thread-safe execution for multi-dimensional synthesis
  - Add error handling strategy section with timeout, rate limit, and partial results handling
  - Document context parameter type with full Hash structure
  - Add observability requirements for strategy selection logging
  - Replace TBD estimates with small/medium/large across all subtasks

## [0.9.330] - 2026-01-27

### Fixed

- **ace-taskflow v0.34.1**: Resolve task counting discrepancy in preset listings
  - Add `default_task_glob_pattern` for proper task file matching (legacy, single, orchestrator/subtask formats)
  - Update ListPresetManager to use type-appropriate default globs
  - Update `get_statistics` glob to include orchestrator/subtask format (NNN.NN-*.s.md)
  - Before: "0/93 tasks" with "No tasks found for preset 'draft'"
  - After: "2/135 tasks" correctly displaying filtered tasks

### Technical

- Rename duplicate task 227 to 230 to resolve task ID collision

## [0.9.329] - 2026-01-27

### Added

- **ace-git-commit v0.17.0**: Path-based configuration splitting for mono-repos (task 228)
  - Automatic scope detection based on file paths and glob patterns
  - Batch LLM generation for multiple commit scopes in a single run
  - Support for scope-specific model overrides and type hints
  - Enhanced commit workflow for multiple atomic commits per scope

- **ace-support-config v0.7.0**: Path rules for configuration resolution (task 228)
  - `PathRuleMatcher` atom for matching file paths against glob patterns
  - Support for glob arrays in path rules configuration
  - Project scanning capability to discover nested package configurations

### Changed

- **ace-git v0.10.1**: Renamed squash-commits to reorganize-commits workflow
  - Better reflects workflow purpose of organizing commits into logical groups

### Technical

- Removed redundant package-level `.ace/git/commit.yml` files across 18 packages
  - Project root configuration now handles all scopes via path-based config splitting

## [0.9.328] - 2026-01-26

### Added

- **ace-git v0.10.0**: Reset-split rebase strategy as default (task 228)
  - New default rebase workflow using `ace-git-commit` path-based splitting
  - Zero-conflict rebases with automatic scope grouping and message generation
  - Commits ordered logically: feat → fix → chore → docs
  - Three named strategies: `reset-split` (default), `manual`, `interactive`
  - Simplified default workflow to 3 steps: fetch, reset --soft, ace-git-commit

## [0.9.327] - 2026-01-24

### Added

- **ace-support-nav 0.17.3**: Extension inference for protocol resolution (task 224)
  - Add `ExtensionInferrer` atom for DWIM extension inference
  - Configure inference via `.ace/nav/config.yml` with `extension_inference.enabled` and `fallback_order`
  - Add `inferred_extensions` to protocol configs (guide.yml, wfi.yml)
  - Update `ProtocolScanner` to use inference when exact match fails
  - Strip extensions using both protocol and inferred extension lists

## [0.9.326] - 2026-01-24

### Added

- **ace-support-timestamp 0.4.0**: Precision-based format names (task 225.03)
  - New precision-based names: `2sec` (~1.85s), `40min` (40-min blocks), `50ms` (~50ms), `ms` (~1.4ms)
  - Format names now clearly communicate the precision they provide

### Fixed

- **ace-support-timestamp 0.4.0**: Critical bug in 4-char format encoding
  - Now correctly uses 40-minute blocks (0-35) instead of hours (0-23)
  - Aligns with position 4 of compact format design

### Changed

- **ace-support-timestamp 0.4.0**: Breaking change - format options renamed
  - `compact` → `2sec`
  - `hour` → `40min` (with bug fix)
  - `high_7` → `50ms`
  - `high_8` → `ms`
  - Old format names are no longer accepted
  - Default format changed from `compact` to `2sec`

## [0.9.325] - 2025-01-24

### Added

- **ace-support-timestamp 0.3.0**: Granular timestamp format templates (task 225)
  - New formats: month (2 chars), week (3 chars), day (3 chars), hour (4 chars), high-7 (7 chars), high-8 (8 chars)
  - High-precision formats: high-7 (~50ms), high-8 (~1.4ms)
  - Format auto-detection for variable-length IDs (2-8 characters)
  - `--format` option to encode CLI for specifying output format
  - `default_format` configuration option (defaults to `compact` for backward compatibility)
  - Day/week disambiguation for 3-char IDs using 3rd character value (0-30=day, 31-35=week)
  - Backward compatible - default format remains 6-char compact IDs

### Changed

- **ace-support-timestamp**: Decode command now supports variable-length IDs with automatic format detection

## [0.9.324] - 2026-01-22

### Changed

- **ace-taskflow 0.34.0**: Update analyze-bug workflow to use guide protocols
  - Now references ace-bundle guide://testing-philosophy

## [0.9.323] - 2026-01-22

### Changed

- **ace-docs 0.19.0**: Move embedded-testing-guide to ace-test package
  - Guide now available via ace-test package

## [0.9.322] - 2026-01-22

### Changed

- **ace-test-runner 0.11.0**: Move testing guides to ace-test package
  - Removed handbook/guides/ directory (16 files)
  - Removed .ace-defaults/nav/protocols/guide-sources/ace-test-runner.yml
  - Testing guides now consolidated in ace-test package

## [0.9.321] - 2026-01-22

### Fixed

- **ace-taskflow 0.33.12**: Fix recently done tasks to sort by file modification time, not dependency order
  - Task with dependencies now appears in recently done based on when it was last modified
  - Previously, dependency ordering took precedence, causing recently completed tasks to appear incorrectly
  - Added test case to verify temporal sorting regardless of dependencies

### Added

- **ace-test 0.1.0**: New package consolidating testing documentation (task 218.11)
  - Testing philosophy, TDD cycles, mocking patterns, and performance guides
  - Workflows for create-test-cases and fix-tests (moved from ace-taskflow)
  - Language-specific guides: Ruby, Rust, TypeScript/Vue

### Changed

- **ace-test-runner 0.10.6**: Update references to new ace-test package
  - Documentation now references consolidated testing guides

## [0.9.320] - 2026-01-22

### Added

- **ace-lint 0.14.0**: Typography validation for markdown files (task 218.10)
  - Detects em-dash characters (—) with suggestion to use double hyphens (--)
  - Detects smart quotes (", ", ', ') with suggestion to use ASCII quotes
  - Skips content inside fenced code blocks and inline code spans
  - Configurable severity levels (error/warn/off) in `.ace/lint/markdown.yml`

## [0.9.319] - 2026-01-22

### Fixed

- **ace-taskflow 0.33.10**: Fix `--child-of` flag to support dry-cli's required string values
  - Use `--child-of none` to promote subtask to standalone (was `--child-of` without value)
  - Maintains backwards compatibility with `--child-of=` (empty string)
  - Update legacy optparse parser to handle "none" sentinel value
  - Fix documentation examples to use subtask reference (e.g., `187.12 --child-of none`)
  - Add test coverage for "none" sentinel value behavior

## [0.9.318] - 2026-01-22

### Added

- **ace-handbook 0.7.0**: New guides extracted for better discoverability (task 218.09)
  - `prompt-caching.g.md` - PromptCacheManager patterns for LLM prompt generation
  - `cli-dry-cli.g.md` - Complete dry-cli framework reference
  - `mono-repo-patterns.g.md` - Mono-repo development patterns and binstubs

### Changed

- **docs/ace-gems.g.md**: Condensed from 826 to 221 lines with links to new guides
- **docs/decisions.md**: Condensed and raised max_lines limit to 250

## [0.9.317] - 2026-01-22

### Fixed

- **ace-llm-providers-cli 0.13.2**: Prevent OpenCode client hang on 400 error
  - Added `stdin_data: ""` to `Open3.capture3` to prevent hanging on interactive prompts
  - Added `--format json` flag for structured output
  - Improved 400 Bad Request error detection with clearer error messages

## [0.9.316] - 2026-01-22

### Fixed

- **ace-taskflow 0.33.10**: Fix task 226 duplication in tasks listing
  - Orchestrator ID format mismatch caused subtasks to display as orphans with duplicate parent
  - Now uses TaskReferenceParser to qualify simple parent references (e.g., "226") to qualified format (e.g., "v.0.9.0+task.226")
  - Task 226 now appears once with subtasks properly indented underneath

## [0.9.315] - 2026-01-22

### Changed

- **All 26 gemspecs**: Lower required Ruby version from >= 3.3.0 to >= 3.2.0
  - Pattern matching (`case/in`) has been stable since Ruby 3.0
  - `Data.define` was introduced in Ruby 3.2
  - No Ruby 3.3-specific features are used in the codebase
  - Allows gems to work on more Ruby versions

## [0.9.314] - 2026-01-22

### Added

- **ace-test-e2e-runner 0.2.1**: Container-based E2E test isolation documentation
  - Guide updates for macOS container support (Lima, OrbStack)
  - Template enhancements for containerized test scenarios

## [0.9.313] - 2026-01-22

### Fixed

- **ace-git-worktree 0.12.4**: Fix branch detection bugs in WorktreeCreator (task 222)
  - `branch_exists?`: Check local and remote refs separately (git show-ref --verify requires ALL refs, not ANY)
  - `detect_remote_branch`: Validate remote names to prevent `feature/login` from being treated as remote branch

## [0.9.312] - 2026-01-22

### Fixed

- **ace-git-worktree 0.12.3**: Fallback to current branch for target branch resolution (task 222)
  - When parent task has no worktree metadata, use current branch instead of defaulting to "main"
  - Fixes subtask creation when orchestrator doesn't use worktrees

## [0.9.311] - 2026-01-20

### Fixed

- **ace-git-commit 0.16.5**: Fix path validation for deleted and renamed files (task 220)
  - PathResolver now checks git status for non-existent filesystem paths
  - Deleted files (D status) are correctly validated as staged paths
  - Renamed files (R status) are validated using new path from git status
  - Graceful error handling when git commands fail

## [0.9.310] - 2026-01-19

### Fixed

- **ace-prompt-prep 0.16.2**: E2E test documentation updates
  - Update sample-prompt.md test data to use `bundle:` format instead of legacy `context:` format
  - Correct Base36 ID length documentation from "6-7 characters" to exactly "6 characters" (3 locations)

## [0.9.309] - 2026-01-19

### Changed

- **ace-prompt-prep 0.16.1**: Rename --context to --bundle flag (task 217)
  - CLI: `--context/-c` → `--bundle/-b`, `--no-context` → `--no-bundle`
  - Rename `ContextLoader` class to `BundleLoader`
  - Rename `context_loader.rb` → `bundle_loader.rb`
  - Add backward compatibility for legacy `"context"` config key

- **ace-bundle 0.32.1**: Add preset/presets support in template frontmatter (task 217)
  - Recognize `preset` and `presets` keys in workflow file frontmatter
  - Process presets from frontmatter with error handling
  - Store loaded presets and errors in bundle metadata

## [0.9.308] - 2026-01-19

### Added

- **ace-test-e2e-runner 0.2.0**: Add E2E test management skills for lifecycle orchestration
  - `/ace:review-e2e-tests` - Analyze test health, coverage gaps, and outdated scenarios
  - `/ace:create-e2e-test` - Create new test scenarios from template
  - `/ace:manage-e2e-tests` - Orchestrate full lifecycle (review, create, run)
  - Includes workflow instructions for all three skills

### Changed

- **ace-prompt-prep 0.16.0**: Rename ace-prep to ace-prompt-prep (task 218)
  - Renamed package from `ace-prep` to `ace-prompt-prep` to follow compound naming pattern
  - Updated Ruby namespace from `Ace::Prep` to `Ace::PromptPrep`
  - Renamed CLI binary from `ace-prep` to `ace-prompt-prep`
  - Updated config namespace from `prep` to `prompt-prep` (`.ace/prompt-prep/`, `.cache/ace-prompt-prep/`)
  - Updated all external references in docs, Gemfile, and skills
  - Follows compound naming pattern like `ace-git-commit`, `ace-git-secrets`
  - Makes semantic meaning explicit: this tool prepares prompts
  - No backward compatibility provided per ADR-024 (pre-1.0.0)
  - Migration: Update all references from `ace-prep` to `ace-prompt-prep` in scripts and configs

- **ace-prep 0.15.0**: Rename ace-prompt to ace-prep (task 217)
  - Renamed package from `ace-prompt` to `ace-prep` to better reflect its purpose as a prompt preparation tool
  - Updated Ruby namespace from `Ace::Prompt` to `Ace::Prep`
  - Renamed CLI binary from `ace-prompt` to `ace-prep`
  - Updated config namespace from `prompt` to `prep` (`.ace/prep/`, `.cache/ace-prep/`)
  - Updated all external references in docs, Gemfile, and skills
  - No backward compatibility provided per ADR-024 (pre-1.0.0)
  - Migration: Update all references from `ace-prompt` to `ace-prep` in scripts and configs

## [0.9.307] - 2026-01-16

### Fixed

- **ace-llm-providers-cli 0.13.1**: OpenCode CLI provider command syntax fix (task 216)
  - Changed from `opencode generate` to `opencode run` subcommand
  - Pass prompt as positional argument instead of `--prompt` flag
  - Removed unsupported flags: `--format`, `--temperature`, `--max-tokens`, `--system`
  - Handle system prompts by prepending to main prompt (no native `--system` flag)
  - Added regression tests for correct OpenCode command building

### Added

- **ace-lint 0.9.1**: Ruby linting support with StandardRB (task 215) and bundle config migration
  - Auto-detects .rb, .rake, and .gemspec files for Ruby linting
  - Supports --fix flag for auto-formatting with StandardRB
  - Helpful error message when StandardRB is not installed
  - Skips unsupported file types instead of reporting errors
  - Added `skipped` status to LintResult model
  - Updated ResultReporter to display skipped files with ⊘ symbol
  - Configuration in `.ace-defaults/lint/ruby.yml` following ADR-022 pattern
  - Rename context: to bundle: keys in configuration files

- **ace-bundle 0.29.1**: Create ace-bundle package (tasks 206.01-206.04)
  - Copy ace-context to ace-bundle with Ace::Bundle module namespace
  - Update all configuration paths to use bundle namespace (.ace/bundle/, .cache/ace-bundle/)
  - Create bin/ace-bundle binstub pointing to ace-bundle/exe/ace-bundle
  - Add ace-bundle to mono-repo Gemfile (alphabetical order)
  - Update .ace/test/suite.yml to include ace-bundle in tools group
  - Both ace-context and ace-bundle now coexist and tests pass

## [0.9.306] - 2026-01-16

### Changed

- **ace-bundle 0.29.2**: Rename context: to bundle: keys (task 206 completion)
  - Updated all preset files to use bundle: key instead of context:
  - Updated Ruby code to support both keys for backward compatibility
  - Updated documentation examples

- **ace-docs 0.18.1**: Rename context: to bundle: keys
- **ace-git-commit 0.16.4**: Rename context: to bundle: keys
- **ace-git-secrets 0.7.2**: Rename context: to bundle: keys
- **ace-git-worktree 0.12.2**: Rename context: to bundle: keys
- **ace-handbook 0.5.2**: Rename context: to bundle: keys
- **ace-prompt 0.14.1**: Rename context: to bundle: keys
- **ace-review 0.35.1**: Rename context: to bundle: keys
- **ace-search 0.19.1**: Rename context: to bundle: keys
- **ace-support-timestamp 0.2.2**: Rename context: to bundle: keys
- **ace-taskflow 0.33.9**: Rename context: to bundle: keys

- **ace-support-core 0.20.1**: ContextMerger moved to ace-bundle (task 206)
  - Removed ContextMerger molecule (now BundleMerger in ace-bundle)
  - Tests removed from ace-support-core

- **ace-git 0.8.2**: Updated README.md workflow examples from /ace:load-context to /ace:bundle (task 206)
- **ace-support-nav 0.17.2**: Updated README.md references from ace-context to ace-bundle (task 206)
- **ace-integration-claude 0.3.2**: Updated CLAUDE.md template with ace-bundle references (task 206)
- **ace-test-runner 0.10.5**: Updated package references from ace-context to ace-bundle (task 206)

## [0.9.305] - 2026-01-15

### Changed

- **ace-prompt 0.14.0**: Migrate from ace-context to ace-bundle (task 206.05)
  - Updated gemspec dependency from `ace-context ~> 0.8` to `ace-bundle ~> 0.29`
  - Updated all requires and API calls to use Ace::Bundle
  - Updated test helpers and mocks

- **ace-review 0.35.0**: Migrate from ace-context to ace-bundle (task 206.06)
  - Updated gemspec dependency from `ace-context ~> 0.9` to `ace-bundle ~> 0.29`
  - Updated all requires and API calls to use Ace::Bundle
  - Renamed methods: `load_context_via_ace_context` → `load_context_via_ace_bundle`

- **ace-support-test-helpers 0.11.1**: Update mocks for ace-bundle (task 206)
  - Updated ContextMocks to stub Ace::Bundle instead of Ace::Context
  - Updated TestRunnerMocks default package

### Technical

- **Documentation**: Updated 66 skill files with ace-bundle references
- **CI/CD**: Updated GitHub workflows to test ace-bundle instead of ace-context
- **Project Config**: Updated CLAUDE.md and docs with ace-bundle references
- **Workflow Instructions**: Updated all handbook workflow instructions

## [0.9.304] - 2026-01-15

### Changed

- **ace-test-runner 0.10.4**: Migrate CLI to Hanami pattern (task 213 Phase 5)
  - Move `commands/test.rb` to `cli/commands/test.rb`
  - Update namespace from `Commands::Test` to `CLI::Commands::Test`

- **ace-support-nav 0.17.1**: Migrate CLI to Hanami pattern (task 213 Phase 5)
  - Move commands from `commands/` to `cli/commands/`
  - Update namespace from `Commands::*` to `CLI::Commands::*`

- **ace-git-secrets 0.7.1**: Migrate CLI to Hanami pattern (task 213 Phase 5)
  - Move CLI commands from `commands/` to `cli/commands/`
  - Update namespace from `Commands::*` to `CLI::Commands::*`
  - Business logic command classes (`*Command`) remain in `commands/`

- **ace-support-models 0.5.1**: Migrate CLI to Hanami pattern (task 213 Phase 5)
  - Move commands from `commands/` to `cli/commands/`
  - Update namespace from `Commands::*` to `CLI::Commands::*`
  - Models subcommands use `ModelsSubcommands::` to avoid namespace conflict

## [0.9.303] - 2026-01-14

### Changed

- **ace-git-worktree 0.12.1**: Migrate CLI to Hanami pattern (task 213)
  - Moved command classes from `cli/*.rb` to `cli/commands/*.rb`
  - Updated namespace from `CLI::*` to `CLI::Commands::*`
  - SharedHelpers module moved to `cli/commands/shared_helpers.rb`

- **ace-support-timestamp 0.2.1**: Migrate CLI to Hanami pattern (task 213)
  - Moved command classes from `cli/*.rb` to `cli/commands/*.rb`
  - Updated namespace from `Commands::*` to `CLI::Commands::*`

## [0.9.302] - 2026-01-14

### Changed

- **ace-taskflow 0.33.8**: Migrate CLI to Hanami pattern (CLI::Commands::* namespace)
  - Move wrapper classes from `cli/*.rb` to `cli/commands/*.rb`
  - Unified command structure following ace-docs/ace-search pattern
  - Nested commands (task/*, idea/*) remain in Commands:: namespace for compatibility
  - All commands now follow consistent Hanami CLI pattern

## [0.9.301] - 2026-01-14

### Added

- **ace-docs 0.18.0**: Migrate CLI commands to Hanami pattern (task 213)
  - Move all command logic into `CLI::Commands::*` namespace under `cli/commands/` directory
  - Remove separate `Commands::` wrapper classes - business logic now integrated into CLI commands
  - Update command file naming to match class names (remove `_command` suffix)
  - Full implementation for all 6 commands: analyze, analyze_consistency, discover, status, update, validate

- **ace-search 0.19.0**: Migrate CLI to Hanami pattern (task 213)
  - Move command implementation from `commands/` to `cli/commands/` directory
  - Update module namespace to `CLI::Commands::Search` following Hanami/dry-cli standard
  - Clean up model requires by moving them from `cli.rb` into the command file

### Changed

- **ace-docs 0.18.0**: Consolidate CLI structure following Hanami/dry-cli authoritative pattern
  - Use `CLI::Commands::*` namespace throughout
  - Clean up require paths for proper module resolution

### Fixed

- **ace-search 0.19.0**: Fix critical search_path bug where local variable was used instead of instance variable
  - Changed `search_path = options[:search_path]` to `@search_path = options[:search_path]`
  - This ensures resolve_search_path receives the correct search path value

### Technical

- **ace-docs 0.18.0**: Remove obsolete unit and integration tests for deleted `Commands::*` classes
- **ace-search 0.19.0**: Update CLI pattern documentation to reflect Hanami standard
- **ace-search 0.19.0**: Remove obsolete `commands/` directory structure


## [0.9.300] - 2026-01-14

### Fixed

- **ace-taskflow 0.33.7**: Fix duplicate orchestrator display in hierarchical task listing
  - Orchestrator tasks were shown twice: once in main list, once as parent context
  - Root cause: ID format mismatch between orchestrator ID and subtask parent_id
  - Added helpers to handle ID prefix matching for proper parent-child detection

## [0.9.299] - 2026-01-14

### Added

- **ace-llm 0.21.0**: Configuration cascade for provider discovery
  - Provider configs now cascade from gem defaults, project, and user paths
  - Dynamic provider discovery without hardcoding in ace-llm
  - New Configuration class and ConfigLoader molecule

- **ace-review 0.34.0**: Gemini provider support in all review presets
  - Google Gemini 2.5 Flash as default model for code reviews
  - Updated LLM executor to handle gemini provider configuration

### Changed

- **ace-llm 0.21.0**: Removed CLI provider configs from ace-llm gem (.ace-defaults/)
- **ace-llm 0.21.0**: Updated ClientRegistry to use Configuration cascade

### Fixed

- **ace-llm 0.21.0**: Handle non-JSON xAI API error responses gracefully
- **ace-llm 0.21.0**: Improved CLI argument parsing for ambiguous provider/model arguments

## [0.9.298] - 2026-01-13

### Added

- **ace-llm-providers-cli 0.13.0**: GeminiClient for Google Gemini CLI provider integration
  - Supports Gemini 2.5 Flash, Gemini 2.5 Pro, Gemini 2.0 Flash, and Gemini 1.5 Pro models
  - JSON output parsing for structured responses with token metadata
  - System prompt embedding (Gemini CLI lacks native `--system-prompt` flag)
  - Provider aliases: `gflash`, `gpro`, `gemini-flash`, `gemini-pro`
  - Auto-registers with ace-llm provider system

## [0.9.297] - 2026-01-13

### Changed

- **ace-support-models 0.5.0**: Renamed from ace-llm-models-dev to ace-support-models
  - Follows ace-support-* naming pattern for infrastructure gems
  - Ruby module: `Ace::LLM::ModelsDev` → `Ace::Support::Models`
  - CLI executable: `ace-llm-models` → `ace-models`
  - Require path: `require 'ace/llm/models/dev'` → `require 'ace/support/models'`
  - Cache directory: `ace-llm-models-dev` → `ace-models`
  - All functionality remains identical, 185 tests passing

## [0.9.296] - 2026-01-13

### Fixed

- **ace-review 0.33.2**: Fix multi-model option handling
  - Store parsed models in `:models` key (array) instead of `:model` key
  - Resolves issue where multi-model reviews failed due to incorrect option key usage

## [0.9.295] - 2026-01-13

### Fixed

- **ace-llm 0.20.2**: Query command ambiguous argument handling when `--model` doesn't contain colon
  - Added validation to detect when positional arg is not a valid provider
  - Shows help instead of proceeding with invalid provider/model combination

## [0.9.294] - 2026-01-13

### Added

- **ace-git 0.8.1**: PID-based orphan detection for git lock files
  - New `orphaned?` method checks if lock-owning process still exists
  - Instant cleanup of orphaned locks (dead PID) regardless of age
  - Age-based stale detection remains as fallback for edge cases

### Changed

- **ace-git 0.8.1**: Improved lock retry timing and cleanup strategy
  - Lock retry now uses fixed 500ms delay (was exponential 50→100→200→400ms)
  - Lock cleanup attempted on every retry (was only first retry)
  - Updated `initial_delay_ms` default from 50 to 500 in config

## [0.9.293] - 2026-01-12

### Added

- **ace-git 0.8.0**: Git index lock retry with stale lock cleanup
  - `LockErrorDetector` atom to detect git index lock errors from stderr
  - `StaleLockCleaner` atom to detect and remove stale lock files (>60s old)
  - Automatic retry with exponential backoff (50ms → 100ms → 200ms → 400ms)
  - `lock_retry` configuration section for customizing retry behavior

### Changed

- **ace-git 0.8.0**: Modified `CommandExecutor.execute()` to wrap git commands with lock retry logic
  - Prevents "Unable to create .git/index.lock" errors in multi-worktree environments
  - Silent retries - no output unless all retries fail
  - All 459 tests pass including 30 new tests for lock retry behavior

## [0.9.292] - 2026-01-11

### Fixed

- **ace-taskflow 0.33.6**: Handle Float subtask references from YAML parsing in TaskReferenceParser
  - YAML parses unquoted `202.01` as Float, not String
  - Now converts to string before checking `.empty?` to prevent NoMethodError

## [0.9.291] - 2026-01-11

### Added

- **ace-taskflow 0.33.5**: Show parent task context for orphan subtasks in filtered results
  - Parent tasks display with `[context]` indicator when their subtasks match filter criteria
  - Subtasks displayed under parent with tree connectors (├─ and └─)
  - Parent does not count toward result count (it's context, not a match)

### Fixed

- **ace-taskflow 0.33.5**: Wrap CLI-invoking tests with `with_real_test_project`
  - Prevents creating test artifacts in actual project directory

## [0.9.290] - 2026-01-11

### Fixed

- **ace-taskflow 0.33.4**: Wrap CLI-invoking tests with `with_real_test_project`
  - Prevents creating test artifacts in actual project directory
  - Fixes issue where tests created `8oa1vl-test-default` directories

### Added

- **ace-taskflow 0.33.4**: Improve idea subcommand handling with nested commands

### Technical

- **ace-taskflow 0.33.4**: Merge philosophy and what-do-we-build into vision.md

## [0.9.289] - 2026-01-11

### Fixed

- **ace-context 0.28.2**: Added stats header for chunked output
  - Shows total lines, size, and chunk count before listing paths

## [0.9.288] - 2026-01-11

### Changed

- **ace-context 0.28.1**: Chunked output now shows chunk paths directly
  - CLI outputs chunk file paths (one per line) instead of index file
  - Agents read chunks directly without discovering via index first

## [0.9.287] - 2026-01-11

### Changed

- **ace-context 0.28.0**: ContextChunker moved from ace-support-core
  - `Ace::Context::Molecules::ContextChunker` for splitting large outputs
  - `Ace::Context::Atoms::BoundaryFinder` for semantic XML boundary detection
  - Config key `chunk_limit` renamed to `max_lines` for clarity
  - Default changed from 150000 to 2000 lines

- **ace-support-core 0.20.0**: ContextChunker removed (moved to ace-context)
  - Removed orphaned `context_chunker` config section
  - Config key `chunk_limit` renamed to `max_lines`

## [0.9.286] - 2026-01-10

### Added

- **ace-support-core 0.19.1**: Shared CLI routing logic module
  - `Ace::Core::CLI::DryCli::DefaultRouting` module with `start` and `known_command?` methods
  - Eliminates duplicate routing code across CLI gems
  - Provides consistent default command routing behavior

- **ace-taskflow 0.33.3**: CLI routing tests for nested idea subcommands
  - 15 new tests covering create, done, park, unpark, reschedule
  - Tests verify proper routing with flags and arguments

### Fixed

- **ace-taskflow 0.33.3**: Double content push in idea create command
  - Fixed content duplication when using `--note` flag
  - Changed flag order to add flags before positional content
  - Skip positional content when `--note` is provided

### Changed

- **ace-docs 0.17.2**: Use shared DefaultRouting module
  - Removed duplicate routing code in favor of shared implementation

- **ace-git-commit 0.16.3**: Use shared DefaultRouting module
  - Removed duplicate routing code in favor of shared implementation

- **ace-prompt 0.13.2**: Use shared DefaultRouting module
  - Removed duplicate routing code in favor of shared implementation

- **ace-taskflow 0.33.3**: Use shared DefaultRouting module
  - Removed duplicate routing code in favor of shared implementation

## [0.9.285] - 2026-01-10

### Fixed

- **ace-taskflow 0.33.2**: Migrate idea subcommands to nested dry-cli commands
  - Created 5 new nested subcommand classes: `Create`, `Done`, `Park`, `Unpark`, `Reschedule`
  - Updated `CommandRouter` molecule to support idea subcommand routing
  - Added `IDEA_SUBCOMMANDS` constant for routing disambiguation
  - Changed `CLI::Idea` to use `options[:args]` pattern (no argument declarations)
  - Fixes `idea create -gc` and other subcommand+flag combinations

### Technical

- **ace-taskflow 0.33.2**: Added regression tests for CLI routing with flags

## [0.9.284] - 2026-01-09

### Added

- **ace-taskflow 0.33.1**: Migrate task subcommands to nested dry-cli commands
  - Created 11 new nested subcommand classes: `Create`, `Show`, `Start`, `Done`, `Move`, `Update`, `Defer`, `Undefer`, `Undone`, `AddDependency`, `RemoveDependency`
  - Implemented `CommandRouter` molecule to disambiguate between `task <ref>` and `task <subcommand>`
  - Added comprehensive tests for create command
  - Updated `CLI` and `CLI::Task` registration to use nested subcommands

### Fixed

- **ace-taskflow 0.33.1**: Correct require_relative path for molecules in show command

### Changed

- **ace-taskflow 0.33.1**: Refactored create command to use TaskManager directly

## [0.9.283] - 2026-01-09

### Changed

- **ace-search 0.18.1**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Search` dry-cli command class
  - Deleted `search_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.9.282] - 2026-01-09

### Changed

- **ace-review 0.33.1**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `ListPresets`, `ListPrompts`, `Review`, and `Synthesize` dry-cli command classes
  - Deleted `list_presets_command.rb`, `list_prompts_command.rb`, `review_command.rb`, and `synthesize_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.9.281] - 2026-01-09

### Changed

- **ace-llm 0.19.1**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `ListProviders` and `Query` dry-cli command classes
  - Deleted `list_providers_command.rb` and `query_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.9.280] - 2026-01-09

### Changed

- **ace-lint 0.8.1**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Lint` dry-cli command class
  - Deleted `lint_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.9.279] - 2026-01-09

### Changed

- **ace-git-commit 0.16.1**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Commit` dry-cli command class
  - Deleted `commit_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.9.278] - 2026-01-09

### Changed

- **ace-git 0.7.1**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `Branch`, `Diff`, `PR`, and `Status` dry-cli command classes
  - Deleted `branch_command.rb`, `diff_command.rb`, `pr_command.rb`, and `status_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.9.277] - 2026-01-09

### Changed

- **ace-nav 0.16.1**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `Create`, `List`, `Resolve`, and `Sources` dry-cli command classes
  - Deleted `create_command.rb`, `list_command.rb`, `resolve_command.rb`, and `sources_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.9.276] - 2026-01-09

### Changed

- **ace-context 0.27.1**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `Load` and `List` dry-cli command classes
  - Deleted `load_command.rb` and `list_command.rb` wrapper files
  - Added `PresetListFormatter` atom for reusable list formatting logic

## [0.9.275] - 2026-01-08

### Removed

- **ace-taskflow 0.33.0**: Backward compatibility for legacy idea and retro file formats
  - Removed support for `idea.s.md` files (only `.idea.s.md` supported)
  - Removed support for `.s.md` flat files in ideas root
  - Removed support for `YYYY-MM-DD-{slug}.md` retro format
  - Removed support for `YYYYMMDD-{slug}.md` retro format
  - All existing files already use new formats (no migration needed)

### Changed

- **ace-taskflow 0.33.0**: Simplified file discovery logic
  - Removed 3-priority fallback system from IdeaLoader
  - Removed legacy date parsing from RetroLoader
  - Reduced codebase by ~150 lines of backward compatibility code
  - Updated tests to use only `.idea.s.md` and Base36 retro formats

## [0.9.274] - 2026-01-08

### Added

- **ace-taskflow 0.32.0**: Descriptive slugs for idea filenames and retrospectives (tasks 182, 184)
  - Idea filenames now use `{slug}.idea.s.md` pattern (e.g., `taskflow-add.idea.s.md`)
  - Retrospective filenames now use `{base36-id}-{slug}.md` pattern (e.g., `i50jj3-performance-analysis.md`)
  - File discovery priority: `.idea.s.md` > `.s.md` > `idea.s.md`
  - Directory deduplication prevents duplicate loading
  - Full backward compatibility with existing `idea.s.md` files
  - Added 4 new backward compatibility tests

### Changed

- **ace-taskflow 0.32.0**: Idea file creation and discovery improvements
  - IdeaWriter creates files with `.idea.s.md` extension
  - RetroManager generates Base36 compact ID filenames
  - IdeaLoader prioritizes new format while supporting legacy formats
  - IdeasCommand displays actual file paths instead of hardcoded `idea.s.md`

## [0.9.273] - 2026-01-08

### Fixed

- **ace-test-runner 0.10.2**: Report path resolution robustness and documentation (task 185)
  - Fixed ReportPathResolver to check for directory existence
  - Unified path handling and relative path output in FailedPackageReporter
  - Add test coverage for relative path calculation errors

## [0.9.272] - 2026-01-08

### Changed

- **ace-handbook 0.5.0**: dev-handbook content migration (task 180)
  - Migrated 31 guides to appropriate ace-* packages
  - Migrated 12 template directories to ace-docs, ace-taskflow, ace-review
  - Migrated initialize-project-structure.wf.md workflow
  - Added guide:// and tmpl:// protocol sources to 8 packages
  - Updated docs/blueprint.md and docs/architecture.md

### Removed

- **dev-handbook**: Content archived to _legacy/dev-handbook/
  - Workflows moved to ace-* package handbook/ directories
  - Guides distributed to thematically appropriate packages
  - Templates moved to ace-docs, ace-taskflow, ace-review

## [0.9.271] - 2026-01-08

### Added

- **ace-taskflow 0.31.0**: SharedOptions module for DRY option definitions
  - CLI routing tests for KNOWN_COMMANDS and command aliases
  - `migrate-paths` alias for backward compatibility with Thor CLI naming

### Changed

- **ace-taskflow 0.31.0**: Migrate CLI from Thor to dry-cli (task 179.15)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Converted CLI to dry-cli Registry pattern
  - Created 12 dry-cli command wrapper classes
  - Default command routing (`ace-taskflow 150` → `ace-taskflow task 150`)
  - Command aliases: `context` → `status`, `migrate-paths` → `migrate`
  - Type conversion for numeric options
  - Cache clearing integrated into CLI lifecycle

### Fixed

- **ace-taskflow 0.31.0**: CLI routing and option handling
  - Fixed default command routing for empty args
  - Improved numeric option conversion across commands
  - Fixed option passing to underlying command classes

## [0.9.270] - 2026-01-07

### Changed

- **ace-review 0.33.0**: Migrate CLI from Thor to dry-cli (task 179.14)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Converted CLI to dry-cli Registry pattern
  - Created dry-cli command classes (list_presets, list_prompts, review, synthesize)

## [0.9.269] - 2026-01-07

### Changed

- **ace-docs 0.17.0**: Migrate CLI from Thor to dry-cli (task 179.10)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command classes (analyze, analyze_consistency, discover, status, update, validate)

## [0.9.268] - 2026-01-07

### Changed

- **ace-git-secrets 0.7.0**: Migrate CLI from Thor to dry-cli (task 179.09)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command wrappers (Scan, Rewrite, Revoke, CheckRelease)

## [0.9.267] - 2026-01-07

### Changed

- **ace-test-runner 0.10.0**: Migrate CLI from Thor to dry-cli (task 179.12)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command class (test)

## [0.9.266] - 2026-01-07

### Changed

- **ace-git-commit 0.16.0**: Migrate CLI from Thor to dry-cli (task 179.07)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command class (commit)

## [0.9.265] - 2026-01-07

### Changed

- **ace-llm 0.19.0**: Migrate CLI from Thor to dry-cli (task 179.13)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command classes (query, list_providers)

## [0.9.264] - 2026-01-07

### Changed

- **ace-prompt 0.13.0**: Migrate CLI from Thor to dry-cli (task 179.11)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command classes (Process, Setup)

## [0.9.263] - 2026-01-07

### Changed

- **ace-git 0.7.0**: Migrate CLI from Thor to dry-cli (task 179.06)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command wrappers for all commands
  - Maintained magic git range routing

## [0.9.262] - 2026-01-07

### Changed

- **ace-nav 0.16.0**: Migrate CLI from Thor to dry-cli (task 179.05)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Converted to Registry pattern with explicit command classes
  - Maintained backward compatibility for flags

## [0.9.261] - 2026-01-07

### Changed

- **ace-context 0.27.0**: Migrate CLI from Thor to dry-cli (task 179.04)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Converted to `Dry::CLI::Registry` pattern with explicit command registration
  - Maintained backward compatibility for `--list` flag

## [0.9.260] - 2026-01-07

### Changed

- **ace-lint 0.8.0**: Migrate CLI from Thor to dry-cli (task 179.03)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - User-facing command interface remains identical

## [0.9.259] - 2026-01-07

### Changed

- **ace-search 0.18.0**: Migrate CLI from Thor to dry-cli (task 179.02)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - All user-facing commands, options, and behavior remain identical
  - Default command routing preserved
  - Standardized `KNOWN_COMMANDS` pattern

## [0.9.258] - 2026-01-07

### Added

- **ace-support-test-helpers 0.11.0**: CLI test helpers for dry-cli framework (task 179)
  - `CliHelpers` module for testing dry-cli based CLIs
  - `invoke_cli` for capturing stdout/stderr/result from CLI execution
  - `assert_cli_success` and `assert_cli_output_matches` assertion helpers

## [0.9.257] - 2026-01-07

### Added

- **ace-support-core 0.19.0**: dry-cli infrastructure for CLI framework migration (task 179.01)
  - `Ace::Core::CLI::DryCli::Base` module with common CLI patterns (verbose?, quiet?, debug?, exit codes, debug logging)
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display integration
  - `Ace::Core::CLI::DryCli::VersionCommand` helper for version commands
  - `convert_types` helper for dry-cli option type conversion (integer, float, boolean)

### Changed

- Standardized dry-cli dependency to ~> 1.0 across all gems

## [0.9.256] - 2026-01-07

### Added

- **ace-review 0.32.1**: Support `commit:HASH` subject type for reviewing individual commits
  - Accepts commit hashes with 6-40 hexadecimal characters
  - Validates hash format before git operations
  - Generates diff using `COMMIT~1..COMMIT` syntax to show commit's changes
  - Provides clear error messages for invalid formats
  - Updated documentation with usage examples

## [0.9.255] - 2026-01-07

### Added

- **ace-timestamp 0.1.1**: New package for Base36 compact ID generation
  - Encode/decode between timestamps and 6-character Base36 compact IDs
  - Configurable year_zero (default 2020) and precision (second/minute/hour)
  - CLI interface: `ace-timestamp encode/decode/config`
  - Thread-safe implementation with Ruby 3 pattern matching

### Changed

- **ace-taskflow 0.30.0**: Base36 compact ID support for idea directories
  - Default idea directory naming changed from YYYYMMDD-HHMMSS to 6-char Base36 IDs
  - Backward compatible: existing timestamp directories remain readable

- **ace-prompt 0.12.0**: Migrate to Base36 compact IDs for session archiving
  - Archive filenames changed from timestamps to 6-char Base36 compact IDs
  - Renamed TimestampGenerator to SessionIdGenerator

- **ace-review 0.32.0**: Migrate to Base36 compact IDs for review reports
  - Review report filenames changed from timestamps to 6-char Base36 compact IDs
  - Session directories now use compact ID format

- **ace-docs 0.16.0**: Migrate to Base36 compact IDs for session and file naming
  - Session directories and analysis reports use 6-char Base36 compact IDs

- **ace-test-runner 0.9.0**: Migrate to Base36 compact IDs for test reports
  - Test report directories changed from timestamps to 6-char Base36 compact IDs
  - Simplified configuration loading using ADR-022 pattern

- **ace-git-secrets 0.6.0**: Migrate to Base36 compact IDs and sessions subdirectory
  - Scan report filenames changed from timestamps to 6-char Base36 compact IDs
  - Reports now stored in `sessions/` subdirectory

## [0.9.254] - 2026-01-06

### Added

- **ace-taskflow 0.30.0**: Base36 compact ID support for idea directories
  - Add Base36 compact ID support for idea directories
  - Add Base36 compact ID extraction from idea titles
  - Integrate with ace-timestamp for compact timestamp generation

## [0.9.253] - 2026-01-06

### Fixed

- **ace-timestamp 0.1.1**: CLI exit code handling and default command
  - Fix exit code handling using standard ACE pattern (`result.is_a?(Integer) ? result : 0`)
  - Change default CLI command from `help` to `encode` (encodes current time when no args)
  - Fix timestamp parsing to check legacy format (YYYYMMDD-HHMMSS) before Time.parse
  - Add configuration validation for alphabet (36 chars) and year_zero (1900-2100)
  - Add ace-support-test-helpers to development dependencies
  - Correct day range documentation from "0-35" to "0-30"

## [0.9.252] - 2026-01-06

### Fixed

- **ace-taskflow 0.29.1**: Recently completed tasks not appearing in "Recently Done" section
  - Added missing `:modified` sort case to `DependencyResolver.apply_standard_sort()`
  - Tasks now correctly sorted by file modification time (newest first)
  - Subtasks completed recently now appear alongside parent tasks

## [0.9.251] - 2026-01-06

### Fixed

- **ace-git-worktree 0.10.2**: Thor CLI consuming `--files` option in `config` command
  - `ace-git-worktree config --files` was showing default config instead of file locations
  - Added `:config` to `stop_on_unknown_option!` to complete Thor workaround coverage

## [0.9.250] - 2026-01-06

### Fixed

- **ace-git-worktree 0.10.1**: Thor CLI consuming command-specific options (`--task`, `--pr`, `--branch`) instead of passing them to command handlers
  - `ace-git-worktree create --task 178` was showing help instead of executing
  - Added `stop_on_unknown_option!` to let command handlers parse their own options

## [0.9.249] - 2026-01-05

### Added

- **ace-support-core 0.18.0**: `ConfigSummary.display_if_needed` method for conditional configuration display
  - Checks for help flags (`--help`, `-h`) before displaying config
  - Added `ConfigSummary.help_requested?` helper to detect help flag presence
  - Prevents config summary from polluting help text output

### Changed

- **ace-support-core 0.18.0**: ConfigSummary now requires `--verbose` flag to display configuration details
  - Standard command output remains clean and uncluttered
  - Debug configuration available when explicitly requested
  - Improved help text clarity by separating concerns

- **ace-taskflow 0.29.0**: Adopted `ConfigSummary.display_if_needed` pattern in TaskCommand
  - Configuration summary now only displays with `--verbose` flag
  - Help text remains clean and uncluttered
  - Aligned with ace-support-core 0.18.0 conditional config display behavior

### Fixed

- **ace-support-core 0.18.0**: Config summary output appearing with `--help` commands
  - Configuration now only shows when both not in help mode AND verbose is enabled
  - Added tests for `help_requested?` detection logic

- **ace-taskflow 0.29.0**: Config summary output appearing with `--help` commands in task commands
  - Applied conditional display logic to TaskCommand
  - Tests added for help detection behavior

## [0.9.248] - 2026-01-05

### Technical

- **ace-review 0.31.1**: Clarified subject type prefix requirement in workflow documentation
  - Added explicit warnings that type prefixes (files:, pr:, diff:, task:) are required
  - Added Common Mistakes section with wrong/correct examples
  - Improved Step 1 examples with file pattern usage

## [0.9.247] - 2026-01-05

### Added

- **ace-taskflow 0.28.1**: Unified CommandOptionParser for all commands
  - New `CommandOptionParser` molecule with composable option sets (display, release, filter, limits, subtasks, sort, actions, help)
  - Custom options support via block syntax for command-specific flags

### Changed

- **ace-taskflow 0.28.1**: Migrated all commands from manual parsing to CommandOptionParser
  - Removed ARGV reconstruction patterns from TasksCommand, ReleasesCommand
  - Commands now receive options hash directly instead of parsing raw args
  - Net reduction of 357 lines of parsing code

## [0.9.246] - 2026-01-05

### Added

- **ace-lint 0.7.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration

- **ace-prompt 0.11.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration

- **ace-review 0.31.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration

- **ace-taskflow 0.28.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration

### Changed

- **ace-lint 0.7.0**: Adopted Ace::Core::CLI::Base for standardized options
- **ace-prompt 0.11.0**: Adopted Ace::Core::CLI::Base for standardized options
- **ace-review 0.31.0**: Adopted Ace::Core::CLI::Base for standardized options
- **ace-taskflow 0.28.0**: Adopted Ace::Core::CLI::Base for standardized options
- **ace-test-runner 0.8.0**: Adopted Ace::Core::CLI::Base for standardized options
- **ace-llm-models-dev 0.4.1**: Adopted Ace::Core::CLI::Base for standardized options

### Fixed

- **ace-test-runner 0.8.0**: CLI routing and dependency management fixes
- **ace-llm-models-dev 0.4.1**: CLI routing fixes


## [0.9.245] - 2026-01-05

### Added

- **ace-docs 0.15.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration with sensitive key filtering
  - Comprehensive CLI help documentation across all commands

### Changed

- **ace-docs 0.15.0**: Adopted Ace::Core::CLI::Base for standardized options
  - Migrated from OptionParser to Thor framework
  - Added method_missing for default subcommand support


## [0.9.244] - 2026-01-05

### Added

- **ace-search 0.17.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration with sensitive key filtering
  - Comprehensive CLI help documentation across all commands
  - self.help overrides for custom command descriptions

### Changed

- **ace-search 0.17.0**: Adopted Ace::Core::CLI::Base for standardized options
  - Migrated from OptionParser to Thor framework
  - Added method_missing for default subcommand support

### Fixed

- **ace-search 0.17.0**: CLI routing and configuration fixes
  - CLI routing and dependency management for feature parity
  - --help dispatch for all ACE commands
  - Resolved -v flag conflict and search interactive mode bug
  - Add handle_no_command_error for command name patterns
  - Addressed PR #123 review findings for Medium and higher priority issues

## [0.9.243] - 2026-01-05

### Added

- **ace-git-worktree 0.10.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration with sensitive key filtering
  - Comprehensive CLI help documentation across all commands
  - self.help overrides for custom command descriptions

### Changed

- **ace-git-worktree 0.10.0**: Adopted Ace::Core::CLI::Base for standardized options
  - Migrated from OptionParser to Thor framework
  - Added method_missing for default subcommand support

### Fixed

- **ace-git-worktree 0.10.0**: CLI routing and configuration fixes
  - CLI routing and dependency management for feature parity
  - --help dispatch for all ACE commands

### Technical

- **ace-git-worktree 0.10.0**: Refactored tests to use capture_io and assert exceptions

## [0.9.242] - 2026-01-05

### Added

- **ace-git-secrets 0.5.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration with sensitive key filtering
  - Comprehensive CLI help documentation across all commands
  - --help support for all subcommands
  - exit_on_failure and version mapping standardization

### Changed

- **ace-git-secrets 0.5.0**: Adopted Ace::Core::CLI::Base for standardized options
  - Migrated from OptionParser to Thor framework
  - Added method_missing for default subcommand support

## [0.9.241] - 2026-01-05

### Added

- **ace-llm 0.18.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration with sensitive key filtering
  - Comprehensive CLI help documentation across all commands
  - Routing for list-providers command

### Changed

- **ace-llm 0.18.0**: Adopted Ace::Core::CLI::Base for standardized options
  - Migrated from OptionParser to Thor framework
  - Added method_missing for default subcommand support

### Fixed

- **ace-llm 0.18.0**: CLI routing and configuration fixes
  - CLI routing and dependency management for feature parity
  - --help dispatch for all ACE commands
  - Addressed PR #123 review findings for Medium and higher priority issues

## [0.9.240] - 2026-01-05

### Changed

- **ace-git 0.6.1**: Adopted Ace::Core::CLI::Base for standardized options
  - Added method_missing for default subcommand support

### Fixed

- **ace-git 0.6.1**: CLI flag conflict and review findings
  - Resolved -v flag conflict between --verbose and --version
  - Addressed PR #123 review findings for Medium and higher priority issues

## [0.9.239] - 2026-01-05

### Added

- **ace-nav 0.15.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration with sensitive key filtering
  - Comprehensive CLI help documentation across all commands

### Changed

- **ace-nav 0.15.0**: Adopted Ace::Core::CLI::Base for standardized options
  - Migrated from OptionParser to Thor framework
  - Added method_missing for default subcommand support
  - Improved config loading and thread safety

### Fixed

- **ace-nav 0.15.0**: CLI routing and configuration fixes
  - CLI routing and dependency management for feature parity
  - --help dispatch for all ACE commands
  - Restored default subcommand behavior
  - Addressed PR #123 review findings for Medium and higher priority issues

## [0.9.238] - 2026-01-05

### Added

- **ace-context 0.26.0**: Thor CLI migration with ConfigSummary display
  - Thor CLI migration with standardized command structure
  - ConfigSummary display for effective configuration with sensitive key filtering
  - Comprehensive CLI help documentation across all commands

### Changed

- **ace-context 0.26.0**: Adopted Ace::Core::CLI::Base for standardized options
  - Migrated from OptionParser to Thor framework
  - Added method_missing for default subcommand support

### Fixed

- **ace-context 0.26.0**: CLI routing and configuration fixes
  - CLI routing and dependency management for feature parity
  - --help dispatch for all ACE commands
  - ConfigSummary display with proper config passing

## [0.9.237] - 2026-01-05

### Fixed

- **ace-config 0.5.1**: Performance test stabilization and CLI improvements
  - Stabilize performance tests with adjusted thresholds for CI consistency
  - Improve command default behavior and fix flaky test

## [0.9.236] - 2026-01-04

### Fixed

- **ace-git-commit 0.15.2**: Respect .gitignore when staging directory paths
  - Directories now pass directly to `git add` without file expansion
  - Fixed issue where `ace-git-commit .ace-taskflow/` would try to stage files in gitignored subdirectories like `reviews/`
  - Only glob patterns are expanded to file lists through PathResolver
  - Updated tests to reflect new directory handling behavior

## [0.9.235] - 2026-01-04

### Fixed

- **ace-taskflow 0.27.2**: Doctor command respects configured archive directory
  - Task location validation now uses `directories.completed` config instead of hardcoded `/done/` pattern
  - Improved path matching regex prevents substring false positives in directory detection
  - Added regression tests for custom `done_dir` configuration
  - Test factory now uses configured directory names for proper fixture generation
  - README updated to reference configurable archive directory

## [0.9.234] - 2026-01-03

### Added

- **ace-context 0.25.0**: Auto-format output based on line count threshold
  - Content below 500 lines displays inline to stdout
  - Content at/above 500 lines saves to cache file (path printed)
  - Configurable via `auto_format_threshold` in `.ace/context/config.yml`
  - `LineCounter` atom for counting content lines
  - Integration tests for CLI auto-format behavior

- **ace-support-core**: Semantic boundary-aware chunking (unreleased)
  - `BoundaryFinder` atom parses content into semantic blocks
  - `<file>` and `<output>` XML elements never split mid-element
  - Chunking respects element boundaries for LLM processing integrity

## [0.9.233] - 2026-01-03

### Added

- **ace-handbook 0.4.0**: Guides support with handbook/guides/ directory
  - `workflow-context-embedding.g.md` guide for `embed_document_source` pattern
  - Guide discovery protocol (.ace-defaults/nav/protocols/guide-sources/ace-handbook.yml)
  - Establishes pattern for gem-based guides in ace-handbook
  - Guide migrated from dev-handbook/guides/ to ace-handbook/handbook/guides/

## [0.9.232] - 2026-01-03

### Changed

- **ace-integration-claude 0.3.1**: Updated CLAUDE.md template to use ace-context
  - Template now uses `ace-context wfi://` instead of `ace-nav wfi://` for workflow discovery
  - Aligns with new best practice for Claude Code integration

## [0.9.231] - 2026-01-03

### Changed

- **ace-taskflow 0.27.1**: Migrated workflow instructions from ace-nav to ace-context
  - 19 workflows updated to use `ace-context wfi://` protocol
  - Standardizes on ace-context for all workflow discovery

## [0.9.230] - 2026-01-03

### Changed

- **ace-docs 0.14.1**: Migrated workflow instructions from ace-nav to ace-context
  - 7 workflows updated to use `ace-context wfi://` protocol
  - Standardizes on ace-context for all workflow discovery

## [0.9.229] - 2026-01-03

### Changed

- **ace-git-commit 0.15.1**: Enhanced commit workflow with embedded repository status
  - `embed_document_source: true` frontmatter with `<current_repository_status>` section
  - Pre-loaded git status and diff summary eliminates redundant commands
  - Reduced tool calls from 5 to 2-3 (40-60% improvement) when agents invoke `/ace:commit`

## [0.9.228] - 2026-01-03

### Added

- **ace-context 0.24.0**: Support for loading plain markdown files with frontmatter and embedded context in workflows
  - Returns raw content with metadata for non-template markdown files
  - `embed_document_source: true` frontmatter support for embedding dynamic context
  - Integration tests for plain markdown file loading
  - Enhanced `load-context` workflow to use embedded `<available_presets>` section
  - Reduced tool calls by 40-60% for workflows using embedded context

### Technical

- **ace-handbook/handbook/guides/workflow-context-embedding.g.md**: Pattern guide for workflow context embedding (accessed via `ace-context guide://workflow-context-embedding`)
  - Three core patterns: "Context Already Available", "Interactive Selection", "Validation"
  - Section naming conventions for embedded context
  - When to use `embed_document_source: true` vs manual context gathering
- **CLAUDE.md**: Added "Workflow Context Embedding" section explaining embedded context usage

## [0.9.227] - 2026-01-03

### Changed

**All ACE Gems (BREAKING)**: Standardize Ruby requirement and gemspec patterns

- **Ruby 3.3.0 minimum**: All 24 gems now require Ruby >= 3.3.0 (previously varied 3.0.0-3.2.0)
- Standardized gemspec `spec.files` to deterministic `Dir.glob` pattern
- Added MIT LICENSE to all packages
- MINOR version bump on all gems reflecting breaking Ruby change
- Fixed LICENSE file trailing newlines (4 files)

New versions:
- ace-config 0.5.0, ace-context 0.23.0, ace-docs 0.14.0, ace-git 0.6.0
- ace-git-commit 0.15.0, ace-git-secrets 0.4.0, ace-git-worktree 0.9.0
- ace-handbook 0.3.0, ace-integration-claude 0.3.0, ace-lint 0.6.0
- ace-llm 0.17.0, ace-llm-models-dev 0.4.0, ace-llm-providers-cli 0.12.0
- ace-nav 0.14.0, ace-prompt 0.10.0, ace-review 0.30.0, ace-search 0.16.0
- ace-support-core 0.15.0, ace-support-fs 0.2.0, ace-support-mac-clipboard 0.2.0
- ace-support-markdown 0.2.0, ace-support-test-helpers 0.10.0
- ace-taskflow 0.27.0, ace-test-runner 0.7.0

## [0.9.226] - 2026-01-03

### Added

- **docs/testing-patterns.md**: 6 new sections documenting test performance optimization patterns from tasks 167-175
  - Test Performance Targets: Thresholds by test layer (atoms <10ms, molecules <50ms, organisms <100ms, integration <500ms, E2E <2s)
  - E2E Test Strategy: "Keep ONE E2E per file" rule with migration examples
  - Composite Test Helpers: Pattern to reduce 6-7 level nesting to single helper calls
  - Subprocess Stubbing with Open3: Patterns for mocking subprocess calls
  - DiffOrchestrator Stubbing Pattern: Cross-package git stubbing for ace-git dependency
  - Sleep Stubbing for Retry Tests: Kernel.sleep stubbing pattern

### Changed

- **dev-handbook/workflow-instructions/fix-tests.wf.md**: Enhanced test performance troubleshooting section with diagnostics and performance targets
- **dev-handbook/guides/testing.g.md**: Added section 8 "Test Performance Optimization" with cross-references
- **dev-handbook/guides/testing/test-maintenance.md**: Added 5 optimization strategies (items 4-8) referencing new patterns

### Technical

- Documented learnings from 9-package test optimization achieving 60% average performance improvement
- Added Performance Cost Reference table (git init ~150-200ms, subprocess spawn ~150ms, etc.)
- Summary section reorganized into Core Principles, Performance Patterns, Mock & Stub Patterns, Testability Patterns

## [0.9.225] - 2026-01-03

### Changed

**ace-test-runner 0.6.2**: Optimize test performance from 3.3s to 1.78s (46% reduction)

- Reduce test suite execution time by 46% (3.3s → 1.78s)
- Convert 2 E2E integration tests to use mocked subprocess execution
- Retain 1 representative E2E test for genuine CLI validation
- Improve assertions per second from 105 to 194 (85% improvement)
- Add E2E Coverage Analysis documenting risk mitigation

### Technical

- Enhanced code comments explaining E2E test rationale
- Added performance measurement commands to documentation
- Documented CI benchmark/regression guard (5s threshold)

## [0.9.224] - 2026-01-03

### Changed

**ace-taskflow 0.26.3**: Optimize test performance from 10s to under 5s (Task 174)

- Reduced test suite execution time from 9.77s to 4.72s (51.7% reduction)
- Added `with_real_test_project` composite helper to reduce test nesting from 3 levels to 1
- Refactored test helpers to use `with_real_config` pattern for better test isolation

### Technical

- Test performance optimization through proper test_mode usage
- Include Ace::TestSupport::ConfigHelpers in AceTaskflowTestCase base class

## [0.9.223] - 2026-01-03

### Changed

**ace-git 0.5.2**: Optimize test performance from 6.5s to under 5s (Task 173)

- Reduced test suite execution time from 6.54s to 4.37s (33% reduction)
- Created `with_mock_repo_load` helper to replace 6-7 levels of nested stubs
- Created `with_mock_diff_orchestrator` helper for consolidated stub management
- Extracted `build_mock_prs` to test_helper.rb for reuse
- Organisms layer: 4.82s → 2.72s (44% faster)

### Technical

- Add `setup_repo_status_loader_defaults` helper for cleaner test setup
- Add comprehensive YARD documentation for test helpers
- Improve test hermeticity with proper stub defaults for `find_pr_for_branch` and `fetch_metadata`

## [0.9.222] - 2026-01-03

### Changed

**ace-git-worktree 0.8.4**: Optimize test performance from 6.6s to under 5s (Task 171)

- Optimize test execution time from 6.6s to 4.3-4.9s (28% improvement)
- Remove unnecessary git init calls from test setup (worktree_remover_test.rb, worktree_manager_contract_test.rb)
- Strengthen security assertions and add dependency injection to commands
- Add constructor-based dependency injection for CreateCommand, SwitchCommand, PruneCommand, RemoveCommand, ListCommand

### Technical

- Add detailed implementation plan for test performance optimization

## [0.9.221] - 2026-01-03

### Fixed

**ace-docs 0.13.3**: Optimize test performance from 14s to 1.5s (89% reduction) (Task 169)

- Mock correct git operations in ChangeDetector tests - stub `DiffOrchestrator.generate` instead of `execute_git_command`
- Extract `with_empty_git_diff` test helper to reduce duplication

## [0.9.220] - 2026-01-03

### Changed

**ace-config 0.4.3**: Optimize test performance (Task 172)

- Reduce test execution time from 11.77s to 1.64s (85% improvement)
- Reduce loop iterations in performance tests (100-1000 → 10-50)
- Reduce cascade depth from 5 to 2 levels for faster tests
- Reduce file count from 50 to 10 in file-based tests

## [0.9.219] - 2026-01-03

### Changed

**ace-review 0.29.4**: Optimize test performance (Task 170)

- Reduced test suite execution time from 7.15s to 1.77s (75% reduction)
- Removed unnecessary git init from MultiModelCliTest
- Added shared `stub_synthesizer_prompt_path` helper to avoid ace-nav subprocess calls
- Optimized `mock_llm_synthesis` to use block-based stubbing pattern

## [0.9.218] - 2026-01-02

### Added

**ace-config 0.4.2**: Add test mode for faster test execution (Task 157.12)

- Thread-safe test mode using `Thread.current` for parallel test environments
- `ACE_CONFIG_TEST_MODE` environment variable for CI/test runner integration
- `test_mode` and `mock_config` parameters to `Ace::Config.create`
- Test mode short-circuit in `resolve_type` and `find_configs` methods

## [0.9.217] - 2026-01-02

### Changed

**ace-git-worktree 0.8.3**: Improve error message for dependency-blocked tasks (Task 164)

- `TaskStatusUpdater#update_status` and related methods now return `{success:, message:}` hash instead of Boolean
- Enables rich error propagation for dependency-blocked tasks
- Displays actionable error messages with `--no-status-update` hint when task status update fails

## [0.9.216] - 2026-01-01

### Fixed

**ace-taskflow 0.26.2**: Fix task move --backlog command (Task 158)

- Fix `ace-taskflow task move <TASK_REF> --backlog` failing with "undefined method 'backlog_dir' for an instance of Hash"
- Use `Ace::Taskflow.configuration` for accessing Configuration object methods in TaskManager#resolve_release_path

## [0.9.215] - 2025-12-31

### Added

**ace-config Documentation**: Complete documentation suite for ace-config gem (Task 157.11)

- Migration guide at `docs/migrations/ace-config-migration.md` (263 lines)
  - Before/after migration examples for ace-* gems and external projects
  - API migration reference (resolve_for → resolve_file/resolve_namespace)
  - Directory naming changes (.ace.example/ → .ace-defaults/)
  - Error class namespace changes

### Changed

- ADR-022 updated with ace-config extraction rationale and recommended patterns
- docs/ace-gems.g.md updated to use ace-config patterns for configuration

## [0.9.214] - 2025-12-31

### Technical

**ace-config 0.4.1**: Add comprehensive tests (Task 157.10)

- Add edge case tests: deep nesting, unicode, nil values, special YAML types, large values
- Add custom path tests: custom config_dir, defaults_dir, cascade priority
- Total: 173 tests, 326 assertions

## [0.9.213] - 2025-12-30

### Added

**ace-config 0.4.0**: Add `merge()` method to Config model

- `merge()` method on Config model as the primary API for merging configuration data
- `with()` remains as an alias for backward compatibility
- Provides more intuitive API for gems merging CLI options or runtime overrides

## [0.9.212] - 2025-12-30

### Changed

**ace-config Migration**: Update 16 packages with ace-config dependency and API migration

All packages now use `Ace::Config.create()` API instead of `Ace::Core` for configuration cascade management.

| Package | Version | Change |
|---------|---------|--------|
| ace-context | 0.22.1 | +ace-config, API migration |
| ace-docs | 0.13.1 | +ace-config, API migration |
| ace-git | 0.5.1 | Replace ace-support-core with ace-config |
| ace-git-commit | 0.14.1 | Replace ace-support-core with ace-config |
| ace-git-secrets | 0.3.1 | Replace ace-support-core with ace-config |
| ace-git-worktree | 0.8.1 | Replace ace-support-core with ace-config |
| ace-lint | 0.5.1 | Replace ace-support-core with ace-config |
| ace-llm | 0.16.1 | +ace-config, ClientRegistry refactor |
| ace-llm-providers-cli | 0.11.1 | Replace ace-support-core with ace-config |
| ace-nav | 0.13.1 | Replace ace-support-core with ace-config + ace-support-fs |
| ace-prompt | 0.9.1 | Replace ace-support-core with ace-config |
| ace-review | 0.29.2 | +ace-config (keep ace-support-core for ProcessTerminator) |
| ace-search | 0.15.1 | Replace ace-support-core with ace-config |
| ace-support-core | 0.14.1 | +ace-config dependency |
| ace-taskflow | 0.26.1 | Replace ace-support-core with ace-config |
| ace-test-runner | 0.6.1 | Replace ace-support-core with ace-config |

## [0.9.211] - 2025-12-30

### Changed

**ace-llm-models-dev 0.3.3**: Update provider config paths for .ace-defaults rename

- Update provider config path references from `.ace.example` to `.ace-defaults`

**Migrate 9 packages from `resolve_for` to `resolve_namespace`**

Use the new `resolve_namespace` API for cleaner config loading. This eliminates manual pattern construction and removes deprecation warnings.

| Package | Version | Change |
|---------|---------|--------|
| ace-docs | 0.13.0 → 0.13.1 | Use `resolve_namespace("docs")` |
| ace-git | 0.5.0 → 0.5.1 | Use `resolve_namespace("git")` |
| ace-git-commit | 0.14.0 → 0.14.1 | Use `resolve_namespace("git", filename: "commit")` |
| ace-git-secrets | 0.3.0 → 0.3.1 | Use `resolve_namespace("git-secrets")` |
| ace-git-worktree | 0.8.0 → 0.8.1 | Use `resolve_namespace("git", filename: "worktree")` |
| ace-lint | 0.5.0 → 0.5.1 | Use `resolve_namespace("lint")` and `resolve_namespace("lint", filename: "kramdown")` |
| ace-prompt | 0.9.0 → 0.9.1 | Use `resolve_namespace("prompt")` |
| ace-review | 0.29.0 → 0.29.2 | Use `resolve_namespace("review")` |
| ace-search | 0.15.0 → 0.15.1 | Use `resolve_namespace("search")` |

## [0.9.210] - 2025-12-30

### Changed

**ace-config 0.2.1**: Add Date class support and release accumulated improvements

- Add `Date` class to permitted YAML classes for parsing date values in config files
- Add runtime dependency on `ace-support-fs` for filesystem utilities
- Add `class_get_env` class method on PathExpander for consistent ENV access pattern
- Reorganize ConfigResolver methods: all public methods grouped together before private section

### Added

**ace-config v0.2.0 → v0.3.0 (Task 157.14)**

- `resolve_namespace(*segments, filename: "config")` method to ConfigResolver for simplified namespace-based config resolution
- Automatically builds `.yml/.yaml` file patterns from path segments
- Reduces boilerplate across ace-* gems for config loading

## [0.9.209] - 2025-12-30

### Changed

**Task 157.08: Rename `.ace.example/` to `.ace-defaults/`**

Standardize gem defaults directory naming from `.ace.example` to `.ace-defaults` for clarity. The new naming makes it clearer these are bundled defaults shipped with gems, not user-provided examples.

| Package | Version | Change |
|---------|---------|--------|
| ace-context | 0.21.0 → 0.22.0 | Rename defaults directory |
| ace-docs | 0.12.0 → 0.13.0 | Rename defaults directory |
| ace-git | 0.4.0 → 0.5.0 | Rename defaults directory |
| ace-git-commit | 0.13.0 → 0.14.0 | Rename defaults directory |
| ace-git-secrets | 0.2.0 → 0.3.0 | Rename defaults directory |
| ace-git-worktree | 0.7.0 → 0.8.0 | Rename defaults directory |
| ace-handbook | 0.1.0 → 0.2.0 | Rename defaults directory |
| ace-integration-claude | 0.1.0 → 0.2.0 | Rename defaults directory |
| ace-lint | 0.4.0 → 0.5.0 | Rename defaults directory |
| ace-llm | 0.15.1 → 0.16.0 | Rename defaults directory |
| ace-llm-providers-cli | 0.10.2 → 0.11.0 | Rename defaults directory, update ace-llm dep |
| ace-nav | 0.12.0 → 0.13.0 | Rename defaults directory |
| ace-prompt | 0.8.0 → 0.9.0 | Rename defaults directory |
| ace-review | 0.28.0 → 0.29.0 | Rename defaults directory |
| ace-search | 0.14.0 → 0.15.0 | Rename defaults directory |
| ace-support-core | 0.13.0 → 0.14.0 | Rename defaults directory |
| ace-taskflow | 0.25.0 → 0.26.0 | Rename defaults directory |
| ace-test-runner | 0.5.0 → 0.6.0 | Rename defaults directory |

## [0.9.208] - 2025-12-30

### Changed

**ace-support-core v0.12.0 → v0.13.0**
- Configuration cascade now powered by ace-config gem
- Configuration resolution delegated to ace-config with `.ace` and `.ace-defaults` directories
- Added resolver caching for improved performance (avoids repeated FS traversal)
- Added `Ace::Core.reset_config!` to clear cached resolver for test isolation

### Deprecated

**ace-support-core v0.13.0**
- `Ace::Core.config(search_paths:, file_patterns:)` parameters are deprecated - use `Ace::Config.create(config_dir:, defaults_dir:)` for custom paths
- `Ace::Core::Organisms::ConfigResolver.new(search_paths:)` is deprecated - use new API with `config_dir:` and `defaults_dir:` parameters
- Both will be removed in a future minor version

### Added

**ace-support-core v0.13.0**
- Runtime dependencies: ace-config (~> 0.2), ace-support-fs (~> 0.1)
- Migration fallback: `.ace.example` fallback for gem defaults during migration period
- Test coverage: 10 new tests for deprecation warnings and caching

## [0.9.207] - 2025-12-29

### Changed

**Task 161: Migrate dependent gems to ace-support-fs**

Complete migration from `Ace::Core::Molecules::ProjectRootFinder` and `Ace::Core::Molecules::DirectoryTraverser` to use `Ace::Support::Fs::*` directly across all dependent gems.

| Package | Version | Change |
|---------|---------|--------|
| ace-test-runner | 0.4.0 → 0.5.0 | Migrate ProjectRootFinder to ace-support-fs |
| ace-search | 0.13.0 → 0.14.0 | Migrate ProjectRootFinder to ace-support-fs |
| ace-docs | 0.11.0 → 0.12.0 | Migrate ProjectRootFinder to ace-support-fs |
| ace-nav | 0.11.0 → 0.12.0 | Migrate DirectoryTraverser and ProjectRootFinder to ace-support-fs |
| ace-context | 0.20.0 → 0.21.0 | Migrate ProjectRootFinder to ace-support-fs |
| ace-review | 0.27.2 → 0.28.0 | Migrate file system operations to ace-support-fs |
| ace-prompt | 0.7.0 → 0.8.0 | Migrate ProjectRootFinder to ace-support-fs |
| ace-support-core | 0.11.1 → 0.12.0 | Remove backward compat aliases, update internal deps |

### Removed

**ace-support-core v0.12.0** (BREAKING)
- Removed `Ace::Core::Atoms::PathExpander` alias
- Removed `Ace::Core::Molecules::ProjectRootFinder` alias
- Removed `Ace::Core::Molecules::DirectoryTraverser` alias
- Use `Ace::Support::Fs::*` directly instead

## [0.9.206] - 2025-12-28

### Added

**ace-review v0.27.1 → v0.27.2**
- Prioritize developer feedback in synthesis: Human reviewer comments now receive special handling
- New "Developer Action Required" section appears before Consensus Findings
- Each unresolved comment gets its own subsection with exact text preserved
- Priority boosting ensures developer feedback is never ranked lower than Medium

## [0.9.205] - 2025-12-28

### Added

**ace-config v0.2.0** (new gem)
- Initial release of ace-config gem extracted from ace-support-core
- Generic configuration cascade with customizable folder names
- `Ace::Config.create` and `Ace::Config.virtual_resolver` factory methods
- Deep merging with configurable array strategies (:replace, :concat, :union)
- Project root detection, path expansion, YAML parsing
- Memoization for `resolve()` and `get()` methods
- Windows compatibility via `File::ALT_SEPARATOR` support
- Zero runtime dependencies (stdlib only)

## [0.9.204] - 2025-12-28

### Fixed

**ace-review v0.27.0 → v0.27.1**
- Fixed: Auto-discover repo for inline PR comments - when running `ace-review --pr <number>` (local PR number), inline code comments were silently not fetched because GraphQL requires owner/repo format. Now automatically discovers repository via `gh repo view`
- Fixed: Upgraded warning messages from Debug to Warning level for better visibility

## [0.9.203] - 2025-12-28

### Package Version Bumps (ADR-022 Configuration Pattern)

Six packages updated to implement ADR-022 configuration default and override pattern:

**ace-git-commit v0.12.4 → v0.13.0**
- Added: ADR-022 configuration pattern with `.ace.example/git/commit.yml` defaults
- Fixed: Path expansion in `load_gem_defaults` (4 levels instead of 5)
- Fixed: Debug check consistency (`== "1"` pattern)

**ace-docs v0.10.1 → v0.11.0**
- Added: ADR-022 configuration pattern with `.ace.example/docs/config.yml` defaults
- Changed: Migrated from ace-git-diff to ace-git

**ace-lint v0.3.3 → v0.4.0**
- Added: ADR-022 configuration pattern with `.ace.example/lint/config.yml` defaults

**ace-prompt v0.6.0 → v0.7.0**
- Added: ADR-022 configuration pattern with `.ace.example/prompt/config.yml` defaults

**ace-review v0.26.3 → v0.27.0**
- Added: ADR-022 configuration pattern with `.ace.example/review/config.yml` defaults
- Fixed: Debug check consistency (`== "1"` pattern)

**ace-search v0.12.0 → v0.13.0**
- Added: ADR-022 configuration pattern with `.ace.example/search/config.yml` defaults
- Fixed: Debug check consistency (`== "1"` pattern)

## [0.9.202] - 2025-12-27

### ace-test-runner v0.3.0 → v0.4.0

**Added**
- Migrate configuration to ADR-022 pattern
  - Defaults loaded from `.ace.example/test-runner/config.yml` at runtime
  - User config from `.ace/test/runner.yml` merged over defaults (deep merge)
  - Removed hardcoded defaults from Ruby code
  - New `normalize_config` method for consistent configuration normalization

**Fixed**
- Improved test isolation for config-dependent tests

**Technical**
- Optimized integration tests with stubbing and better config handling

## [0.9.201] - 2025-12-27

### ace-nav v0.10.2 → v0.11.0

**Added**
- Migrate configuration to ADR-022 pattern
  - Defaults loaded from `.ace.example/nav/config.yml` at runtime
  - User overrides via `.ace/nav/config.yml` cascade
  - Deep merge of user config over defaults
  - Single source of truth for default values

**Fixed**
- Address review feedback for ADR-022 migration

## [0.9.200] - 2025-12-27

### ace-git-worktree v0.6.1 → v0.7.0

**Changed**
- Migrate configuration to ADR-022 pattern
  - Removed unused `DEFAULT_*` constants from Configuration module
  - Configuration now fully delegated to ace-support-core cascade and `.ace.example` defaults
  - Default values remain available via `WorktreeConfig::DEFAULT_CONFIG` model

## [0.9.199] - 2025-12-27

### ace-taskflow v0.24.6 → v0.25.0

**Added**
- Migrate configuration to ADR-022 pattern with `.ace.example/` defaults
  - Load defaults from `.ace.example/taskflow/` at runtime
  - Merge user config over defaults using deep merge
  - Support backward compatibility for renamed keys

**Fixed**
- Improve warning message clarity for missing example config
- Address PR review feedback for configuration loading
- Restore richer idea.template format with full metadata structure

## [0.9.198] - 2025-12-27

### ace-taskflow v0.24.5 → v0.24.6

**Fixed**
- Prevent hidden `.s.md` filenames when `file_slug` is empty
  - IdeaWriter now checks for empty/blank slugs before using them
  - Falls back to `idea.s.md` for proper discoverability

## [0.9.197] - 2025-12-27

### ace-git-commit v0.12.3 → v0.12.4

**Changed**
- Dependency migration from ace-git-diff to ace-git
  - GitExecutor now delegates to `Ace::Git::Atoms::CommandExecutor`

### ace-git-worktree v0.6.0 → v0.6.1

**Changed**
- Improved error handling in `create_pr_worktree`
- Extracted error handling methods for better maintainability
- Added debug backtrace output for unknown errors
- Updated ace-git dependency to `~> 0.4`

## [0.9.196] - 2025-12-27

### ace-git v0.3.6 → v0.4.0

**Changed**
- **BREAKING**: Renamed `context` to `status` throughout
  - CLI: `ace-git status` (no `context` alias)
  - Config: `git.status.*` (not `git.context.*`)
  - Classes/files renamed: StatusCommand, StatusFormatter, RepoStatus, RepoStatusLoader
- Extracted `PR_FIELDS` constant in PrMetadataFetcher for maintainability

**Removed**
- `TimeFormatter.add_relative_times` - unused method (YAGNI cleanup)

### ace-git-worktree

**Changed**
- Updated ace-git dependency constraint to `~> 0.4`

## [0.9.195] - 2025-12-27

### ace-review v0.26.2 → v0.26.3

**Changed**
- Add verification step to review workflows (review.wf.md, review-pr.wf.md)
  - New Step 3 verifies Critical/High priority items before presenting to user
  - Categorizes as VALID/INVALID/EDGE CASE/SUGGESTION
  - Filters out LLM false positives to prevent wasted investigation time

## [0.9.194] - 2025-12-27

### PR #93 Review Feedback

**Changed**
- Updated stale ace-git-diff references to ace-git across 9 documentation files
  - ace-review/README.md, ace-git/README.md, ace-git/docs/usage.md
  - ace-git-worktree agent docs and code comments
  - ace-context configuration docs and example presets
  - Review preset YAML comments

### ace-support-test-helpers v0.9.2 → v0.9.3

**Changed**
- Added guarded require for ace-git in git contract tests
  - Enables integration test to exercise CommandExecutor stub when ace-git is available
  - Part of ace-git-diff to ace-git migration

### ace-git-commit (Unreleased)

**Changed**
- Added CHANGELOG entry documenting dependency migration from ace-git-diff to ace-git

## [0.9.193] - 2025-12-27

### ace-docs v0.10.0 → v0.10.1

**Fixed**
- CLI option mapping regression: `--exclude-renames`/`--exclude-moves` flags were being silently ignored
  - AnalyzeCommand.build_diff_options was emitting legacy `include_*` keys
  - CLI flags now correctly propagate to ace-git DiffOrchestrator

**Changed**
- Added deprecation warning for legacy `include_renames`/`include_moves` option keys
- Extracted `build_diff_options` helper method in ChangeDetector for centralized option construction

**Technical**
- Added 5 command-level tests for CLI option propagation
- Added 3 tests for legacy option key deprecation warnings

## [0.9.192] - 2025-12-27

### ace-docs v0.9.0 → v0.10.0

**Changed**
- Migrated from ace-git-diff to ace-git
  - Updated dependency from `ace-git-diff (~> 0.1)` to `ace-git (~> 0.3)`
  - Changed namespace from `Ace::GitDiff::*` to `Ace::Git::*`
  - Part of ace-git consolidation (Task 140.09)

**Fixed**
- Test isolation for DocumentRegistry and StatusCommand
- Test correctness for DocumentAnalysisPrompt assertions

**Technical**
- Integrated standardized prompt caching system from ace-support-core

## [0.9.191] - 2025-12-27

### ace-search v0.11.4 → v0.12.0

**Changed**
- Migrated GitScopeFilter to ace-git package
  - Now uses `Ace::Git::Atoms::GitScopeFilter` from ace-git (~> 0.3)
  - Removed local `Ace::Search::Molecules::GitScopeFilter` implementation
  - Centralizes Git file scope operations across ACE ecosystem

## [0.9.190] - 2025-12-26

### ace-review v0.26.2

**Technical**
- Add timeout guidance for Claude Code agents in workflow instructions
  - Recommended: 10-minute timeout (600000ms), inline mode (not background)
  - Prevents race conditions with TaskOutput when review takes 3-5 minutes

## [0.9.189] - 2025-12-26

### ace-git v0.3.6

**Added**
- `PrMetadataFetcher`: Fork detection fields (`isCrossRepository`, `headRepositoryOwner`)
- `BranchReader.detached?`: Explicit method to check if HEAD is detached

**Changed**
- `CommandExecutor.current_branch`: Now returns commit SHA when in detached HEAD state
  - Previously returned literal "HEAD", requiring consumer workarounds
  - Consumers should use `BranchReader.detached?` to detect detached state

### ace-git-worktree v0.5.0 → v0.6.0

**Added**
- Fork PR detection with warning when creating worktree for fork PRs
- `PR_NUMBER_PATTERN` constant for consistent PR number validation
- `ENV["DEBUG"]` support for unexpected error diagnostics
- CLI integration tests for `--pr` flag and timeout parameter tests

**Changed**
- Migrated from ace-git-diff to ace-git dependency (~> 0.3)
- Simplified `GitCommand.current_branch` - now delegates directly to ace-git
- Updated to Ruby 3 keyword argument forwarding syntax
- Promoted `with_git_stubs` test helper to shared `test_helper.rb`

**Removed**
- `molecules/pr_fetcher.rb` - replaced by ace-git's `PrMetadataFetcher`

## [0.9.188] - 2025-12-26

### ace-git v0.3.5

**Fixed**
- Empty/whitespace-only diff ranges are now filtered out instead of causing errors
  - `DiffGenerator.determine_range` now uses `reject { |r| r.nil? || r.strip.empty? }` for range filtering
  - Empty ranges fall back to smart defaults (working tree diff)

**Technical**
- Added comprehensive tests for empty range handling scenarios

### ace-context v0.19.2 → v0.20.0

**Changed**
- Migrated to ace-git package for Git/GitHub operations
  - Replaced `ace-git-diff` dependency with `ace-git` (~> 0.3)
  - Removed internal `GitExtractor`, `PrIdentifierParser`, `GhPrExecutor` - now uses ace-git equivalents
  - Uses centralized ace-git error types and timeout configuration

**Technical**
- Improved error handling: catch `Ace::Git::Error` base class instead of specific `Ace::Git::GitError`
- Added adapter tests for ace-git error type handling (`GhNotInstalledError`, `GhAuthenticationError`, `PrNotFoundError`, `TimeoutError`)
- Reduced code duplication by centralizing Git operations in ace-git

## [0.9.187] - 2025-12-26

### ace-review v0.26.0 → v0.26.1

**Fixed**
- Complete ace-git migration in SubjectExtractor
  - Replace `Ace::Context::Atoms::GitExtractor.tracking_branch` → `Ace::Git::Molecules::BranchReader.tracking_branch`
  - Replace `Ace::Context::Atoms::PrIdentifierParser.parse` → `Ace::Git::Atoms::PrIdentifierParser.parse`
  - Fixes `uninitialized constant` errors when using ace-review after ace-context v0.16 migration

## [0.9.186] - 2025-12-26

### ace-taskflow v0.24.4 → v0.24.5

**Technical**
- Add explicit PR review instructions to work-on-subtasks workflow
  - Use `ace-review --preset code --pr <number>` for subtask PRs targeting orchestrator branch
  - Document how to get PR number from `ace-git status`
  - Explain why `--pr` flag is required (ensures review against correct target branch)

## [0.9.185] - 2025-12-26

### ace-prompt v0.5.1 → v0.6.0

**Changed**
- Migrate to ace-git for branch reading (Task 140.04)
  - Replace local `GitBranchReader` molecule with `Ace::Git::Molecules::BranchReader`
  - Add `ace-git (~> 0.3)` dependency for unified git operations

**Added**
- Test for nil/failure path when branch detection fails (graceful fallback to project-level prompt)

**Removed**
- `Ace::Prompt::Molecules::GitBranchReader` - functionality now provided by ace-git

## [0.9.184] - 2025-12-26

### ace-review v0.25.0 → v0.26.0

**Changed**
- Migrate to ace-git for Git/GitHub operations
  - Replace `GitBranchReader`, `TaskAutoDetector`, `PrIdentifierParser` with ace-git equivalents
  - Add `ace-git (~> 0.3)` dependency
  - Remove 6 duplicated files (3 lib + 3 test)

## [0.9.183] - 2025-12-26

### ace-taskflow v0.24.3 → v0.24.4

**Technical**
- Clarify worktree isolation in work-on-subtasks workflow
- Add ace-git-worktree usage instructions for subagent delegation
- Add anti-patterns for directory handling in orchestrator workflows

## [0.9.182] - 2025-12-25

### ace-taskflow v0.24.1 → v0.24.2

**Changed**
- **BREAKING**: Renamed `context` subcommand to `status` for semantic clarity
- **BREAKING**: Config keys renamed from `context.activity.*` to `status.activity.*`

**Fixed**
- Zero-limit CLI options now correctly propagate (using `options.key?` instead of truthiness)
- Updated stale comments referencing "context" to "status"

## [0.9.181] - 2025-12-24

### ace-taskflow v0.24.0 → v0.24.1

**Added**
- Task activity awareness in `ace-taskflow status` command (formerly `context`)
  - Recently Done: Shows last 3 completed tasks with relative timestamps (e.g., "2h ago")
  - In Progress: Shows other in-progress tasks (excluding current task)
  - Up Next: Shows next 3 pending tasks in priority order
  - Includes worktree indicators for parallel work awareness

**Fixed**
- Release statistics in context command now show accurate done/total counts
  - Previously showed incorrect 0% progress due to different counting methodology
  - Now reuses StatsFormatter from tasks command for consistent statistics
  - Format changed to "## Release: v.X.Y.Z: done/total tasks • Codename"

## [0.9.180] - 2025-12-23

### ace-taskflow v0.23.1 → v0.24.0

**Added**
- Parent task context display for subtasks in `ace-taskflow status` command
  - Shows parent orchestrator task with full details when current task is a subtask
  - Adds `### Parent Task` header for clear visual separation
  - Automatically extracts parent number from `parent_id` field

**Fixed**
- Parent task context not showing for subtasks (incorrect field access: `task[:parent]` → `task[:parent_id]`)
- Regex pattern bug for end-of-string matching (`\\z` → `\z`)
- Private method access for task command invocation using `send(:show_task)`

## [0.9.179] - 2025-12-22

### ace-git v0.1.0 → v0.3.2

**Complete ace-git Package with CLI and Workflows**

#### CLI Commands (v0.3.0+)
- `ace-git diff [RANGE]` - Generate git diff with filtering
- `ace-git context` - Show repository context (branch, PR, task pattern)
- `ace-git branch` - Show current branch with tracking status
- `ace-git pr [NUMBER]` - Fetch and display PR metadata via GitHub CLI

#### Workflows (v0.1.0+)
- `wfi://rebase` - CHANGELOG-preserving rebase operations
- `wfi://create-pr` - Pull request creation with templates
- `wfi://squash-pr` - Version-based commit squashing (with logical grouping strategy)
- `wfi://update-pr-description` - Automated PR title/description generation

#### Version History
- **v0.3.2**: Error propagation for invalid diff ranges
- **v0.3.1**: CLI help improvements, compact PR output format
- **v0.3.0**: Full CLI executable with diff, context, branch, pr commands
- **v0.2.2**: Squash workflow enhancement (logical grouping over single-commit)
- **v0.2.1**: Dependency update (ace-support-core ~> 0.11)
- **v0.2.0**: PR description workflow (`wfi://update-pr-description`)
- **v0.1.0**: Initial release with rebase, create-pr, squash-pr workflows

## [0.9.177] - 2025-12-22

### ace-git-secrets v0.2.0

**Gitleaks-First Architecture**

- **Added**: Raw token persistence in scan results for remediation workflow
- **Added**: Thread-safe blob caching for improved performance
- **Added**: ADR-023 documenting security model decisions
- **Added**: Enhanced audit logging for compliance tracking
- **Changed**: **BREAKING** - Gitleaks is now required for scanning (removed internal Ruby pattern detection)
- **Changed**: Simplified architecture by delegating all pattern matching to gitleaks
- **Removed**: Internal Ruby pattern detection (TokenPatternMatcher, GitBlobReader, ThreadSafeBlobCache)
- **Fixed**: Repository path validation in GitRewriter

## [0.9.176] - 2025-12-20

### ace-test-runner v0.3.0

**Package Argument Support for Mono-repo Testing**

- **Added**: Run tests for any package from any directory in the mono-repo
  - `ace-test ace-context` runs all tests in ace-context package
  - `ace-test ace-nav atoms` runs only atom tests in ace-nav
  - `ace-test ./ace-search` supports relative paths
  - `ace-test /path/to/ace-docs` supports absolute paths
  - `ace-test ace-context/test/foo_test.rb` supports package-prefixed file paths
  - `ace-test ace-context/test/foo_test.rb:42` supports file paths with line numbers
- **Added**: New `PackageResolver` atom for package name/path resolution
- **Added**: Automatic directory change and restoration for package context
- **Changed**: CLI help and README updated with package examples

## [0.9.175] - 2025-12-18

### ace-git-worktree v0.5.0

**Current Task Symlink in Worktrees**

- **Added**: Creates `_current` symlink inside worktree when creating task worktrees
  - Symlink at worktree root (e.g., `.ace-wt/task.145/_current`) points to task directory
  - Quick access from worktree: `cat _current/*.s.md`, `ls _current/`
  - Configurable via `task.create_current_symlink` and `task.current_symlink_name`
  - Uses relative paths for portability
  - Non-blocking: symlink failure doesn't abort worktree creation
- **Added**: New `CurrentTaskLinker` molecule for symlink lifecycle management
- **Added**: Dry-run shows planned symlink creation

## [0.9.174] - 2025-12-17

### ace-review v0.25.0

**Multiple `--subject` Flags with Config Merging**

- **Added**: Support for combining multiple subject sources in a single review
  - `ace-review --subject pr:77 --subject files:README.md --subject pr:79`
  - Subjects merged into unified ace-context config via `merge_typed_subject_configs()`
- **Fixed**: Recursive nested hash merging in `deep_merge_arrays`
  - Two typed subjects like `diff:HEAD~3` and `diff:HEAD` now correctly merge their nested `context.diffs` arrays
  - Made merge operation immutable (no longer mutates input hashes)
- **Changed**: Simplified subject extraction architecture
  - Removed legacy content extraction paths (`extract(Array)`, `extract_and_merge_multiple`, `subject-content.md`)
  - All subjects now use config passthrough to ace-context

## [0.9.173] - 2025-12-16

### ace-context v0.19.2

**PR Array Handling and Diff Merging Refinements**

- **Fixed**: `pr:` array handling where multiple PRs only showed the first one
  - Arrays like `pr: [123, 456]` now correctly fetch and display all PR diffs
- **Improved**: Context diff detection and PR subject parsing
- **Refactored**: Extract ContentChecker atom and improve diff merging logic
  - Added PR reference validation for better error handling

### ace-review v0.24.2

**PR Subject Parsing and Architecture Improvements**

- **Fixed**: Refined context diff detection and PR subject parsing for more reliable PR reviews
  - Improved handling of PR references in subject configurations
  - Better validation of PR references before fetching
- **Refactored**: Diff merging logic into dedicated ContentChecker component
  - Cleaner architecture for content validation

## [0.9.172] - 2025-12-16

### ace-review v0.24.1

**pr: Array Consistency**

- **Fixed**: `pr:` typed subject now returns array format (`{"pr" => ["77"]}`) for consistency with `diffs:` and `files:` which are always arrays

## [0.9.171] - 2025-12-16

### ace-context v0.19.1

**Nested Context Config Support**

- **Fixed**: `load_inline_yaml` now unwraps nested `context:` key for template processing
  - Fixes empty content issue when using ace-review typed subjects (`diff:`, `files:`, `task:`)
  - Both flat (`diffs: [...]`) and nested (`context: { diffs: [...] }`) configs now work identically
- **Improved**: PR processing format guard ensures consistent output formatting

### ace-review v0.24.0

**Subprocess Timeout and Documentation**

- **Added**: 10-second timeout on `ace-taskflow` subprocess prevents indefinite hangs
  - New `CommandTimeoutError` with command and timeout details
- **Added**: Dual extraction paths documentation in `SubjectExtractor` class
- **Fixed**: Comment accuracy in `SubjectExtractor#use_ace_context`

## [0.9.170] - 2025-12-16

### ace-context v0.19.0

**PR Diff Support and CLI Enhancements**

- **PR Diff Support**: New `pr:` configuration key for loading GitHub Pull Request diffs via `gh` CLI
  - Supports simple numbers (`123`), qualified refs (`owner/repo#456`), and GitHub URLs
  - Graceful error handling for gh not installed, auth failures, and PR not found
  - Added `PrIdentifierParser` atom and `GhPrExecutor` molecule
- **CLI Flag for Source Embedding**: New `--embed-source` (`-e`) flag
  - Overrides `embed_document_source` frontmatter setting
  - Enables ace-prompt to delegate context aggregation to ace-context
- **Inline Base Content**: `context.base` now supports inline strings (not just file paths)
- **Bug Fixes**: Nil guard in CLI overrides, extension-less file resolution, load_file method reference

## [0.9.169] - 2025-12-14

### ace-llm v0.15.1

**Standardized GENERATION_KEYS Pattern**

- All LLM clients now use declarative `GENERATION_KEYS` constants
- OpenAIClient, OpenRouterClient, GroqClient, MistralClient, AnthropicClient use `GENERATION_KEYS`
- GoogleClient uses `GENERATION_KEY_MAPPING` (maps internal keys to Gemini camelCase API keys)
- Fixed zero-value handling bugs in MistralClient, AnthropicClient, GoogleClient (`temperature: 0` was dropped)

## [0.9.168] - 2025-12-14

### ace-review v0.23.2

**Upstream Dependency Fixes**

- ace-llm dependency fixes benefit ace-review users
- Zero-value generation parameters (`temperature: 0`) now preserved in MistralClient, AnthropicClient, GoogleClient
- All LLM clients standardized with GENERATION_KEYS pattern for consistency

## [0.9.167] - 2025-12-14

### ace-review v0.23.1

**Workflow Simplification**

- Simplified `review.wf.md` to match `review-pr.wf.md` pattern with full cycle workflow (review → plan → confirm → implement)
- Reduced from 326 lines to 105 lines (68% reduction)
- Added proper frontmatter: `name`, `argument-hint`, `allowed-tools`
- Removed configuration documentation (available via `ace-review --help`)

## [0.9.166] - 2025-12-13

### ace-test-runner v0.2.1

**Improved Error Message for File Not Found**
- Changed confusing "Unknown target: <path>" to clear "File not found: <path>"
- Added helpful guidance: "Make sure you're running from the correct directory or use an absolute path"
- Distinguishes between file paths (contain "/" or end with ".rb") and unknown target names

## [0.9.165] - 2025-12-13

### ace-taskflow v0.23.1

**GTD Naming and PR Review Fixes**

- **GTD Naming Convention**: Renamed internal directory concepts to align with GTD methodology
  - `deferred` → `anyday` (tasks for anytime, no urgency)
  - `parked` → `maybe` (ideas that might happen)
  - Config keys updated: `anyday_dir`, `maybe_dir`

- **Dynamic Folder Names**: CLI messages now use configuration values instead of hardcoded folder names

- **Code Cleanup**: Removed duplicate method definitions in idea_command.rb and task_command.rb

## [0.9.164] - 2025-12-13

### ace-taskflow v0.23.0

**Folder Reorganization and Task Lifecycle (Task 131)**

- **Directory Renaming**: System folders now use underscore prefix
  - `done/` → `_archive/` (completed releases/tasks/ideas)
  - `backlog/` → `_backlog/` (future releases)
  - New `_deferred/` folder for tasks to revisit later
  - New `_parked/` folder for ideas that are good but not now

- **Task Lifecycle Commands**:
  - `ace-taskflow task undone <ref>` - Reopen completed task from archive
  - `ace-taskflow task defer <ref>` - Move task to `_deferred/`
  - `ace-taskflow task undefer <ref>` - Restore from `_deferred/`

- **Idea Lifecycle Commands**:
  - `ace-taskflow idea park <ref>` - Move idea to `_parked/`
  - `ace-taskflow idea unpark <ref>` - Restore from `_parked/`

- **Migration Command**: `ace-taskflow migrate` for upgrading existing projects
  - Renames old folder structure to new underscore-prefixed format
  - Supports `--dry-run`, `--verbose`, `--no-git` flags
  - Uses `git mv` when in git repository to preserve history

- **ADR-022 Configuration Pattern**: Default config loading from `.ace.example/`
  - Single source of truth for defaults
  - Raise error if default file missing (packaging error detection)
  - Backward compatible: old `done` config key still works

- **Bug Fixes**:
  - Fixed `task undone` crash on Boolean return value
  - Fixed deprecation warning in `mark_idea_done`

### ace-git v0.2.2

**Squash Workflow Enhancement**
- Updated `wfi://squash-pr` to recommend logical grouping over single-commit squashing
- Reframed purpose: "cohesive, logical commits" instead of "one commit per version"
- Added RECOMMENDED banner for Logical Grouping strategy
- Reordered strategies: Logical Grouping (1st), Commit Per Feature (2nd), One Commit (3rd)
- Added real-world example: PR #72 squashed 16 → 3 logical commits

## [0.9.163] - 2025-12-09

### ace-taskflow v0.22.0

**Bug Analysis and Fix Workflows**
- New `analyze-bug.wf.md` workflow for systematic bug analysis
  - Gathers bug info (logs, stack traces, reproduction steps)
  - Attempts reproduction and records status
  - Identifies root cause through investigation
  - Proposes regression tests to catch the bug
  - Creates structured fix plan
- New `fix-bug.wf.md` workflow for executing bug fixes
  - Loads fix plan from analysis phase
  - Implements fixes with minimal changes
  - Creates regression tests (fail before / pass after)
  - Verifies resolution with full test suite
- Claude command wrappers: `/ace:analyze-bug`, `/ace:fix-bug`
- Analysis caching in `.cache/ace-taskflow/bug-analysis/` for workflow continuity
- ADR-002/005 compliant with embedded `<documents>` templates

## [0.9.162] - 2025-12-09

### ace-taskflow v0.21.1

**Convert to Orchestrator Fix**
- Fixed `--child-of self` to create proper orchestrator + subtask structure
- Original task content now becomes subtask `.01` (preserves work as actionable item)
- New orchestrator file (`.00`) created with minimal template
- Updated workflow documentation for new behavior

## [0.9.161] - 2025-12-09

### ace-taskflow v0.21.0

**Task Reorganization Workflow**
- New `move --child-of` command for restructuring task hierarchy
- Promote subtasks to standalone: `task move SUBTASK --child-of`
- Demote tasks to subtasks: `task move TASK --child-of PARENT`
- Convert to orchestrator: `task move TASK --child-of self`
- `--dry-run` flag previews operations without executing
- Preserves auxiliary files (docs/, notes) during demotion
- New `reorganize-tasks.wf.md` workflow documentation

## [0.9.160] - 2025-12-09

### ace-prompt v0.5.1

**Questions Section Restored**
- Added Questions section back to template structure (now 7 sections)

## [0.9.159] - 2025-12-09

### ace-prompt v0.5.0

**New 6-Section Template Structure**
- Updated default template to use Purpose, Variables, Codebase Structure, Instructions, Workflow, Report sections
- Synchronized enhance system prompt output format with new template structure

## [0.9.158] - 2025-12-09

### ace-taskflow v0.20.2

**Doctor Health Checks & Statistics Fixes**
- Exclude `review/`, `docs/`, `qa/`, and `.backup.*` files from task scanning
- Accept terminal states (`superseded`, `cancelled`, `skipped`) in done/ directory
- Support hierarchical subtask IDs in frontmatter validation (e.g., `v.X.Y.Z+task.NNN.NN`)
- Add backup file cleanup when moving tasks to done/ directory
- Restrict statistics glob to `tasks/` directory only (fixes phantom pending task counts)

## [0.9.157] - 2025-12-08

### ace-llm-models-dev v0.3.2 (Task 128.09)

**OpenRouter Model Canonicalization**
- Fixed sync false positives for OpenRouter models with routing suffixes (`:nitro`, `:floor`, `:online`, etc.)
- New ModelNameCanonicalizer atom strips known OpenRouter suffixes before comparing against models.dev
- Supports all 7 OpenRouter suffixes: `:nitro`, `:floor`, `:online`, `:free`, `:extended`, `:exacto`, `:thinking`
- Provider-aware: only applies canonicalization to OpenRouter provider
- Comprehensive tests following ADR-017 flat test structure

## [0.9.156] - 2025-12-06

### ace-llm v0.14.0 (Task 128.03)

**Groq Provider**
- New LLM provider for Groq's ultra-fast inference API
- Supports GPT-OSS 120B/20B, Kimi K2, and Mistral Saba models
- OpenAI-compatible API with ultra-fast inference
- Global aliases: `groq`, `groq-fast`, `groq-kimi`, `groq-saba`
- Model aliases: `gpt-oss`, `gpt-oss-120b`, `gpt-oss-20b`, `kimi-k2`, `saba`
- Environment variable: `GROQ_API_KEY`
- Comprehensive test coverage with mocked HTTP client

**Fixes (PR Review Feedback)**
- Zero-valued generation params now preserved (temperature: 0, frequency_penalty: 0)
- Stream flag explicitly disabled (streaming not implemented)

## [0.9.155] - 2025-12-06

### ace-llm v0.13.0 (Task 128.02)

**OpenRouter Provider**
- New LLM provider for OpenRouter's unified API (400+ models)
- OpenAI-compatible API with optional attribution headers (HTTP-Referer, X-Title)
- Focus: Exclusive providers (DeepSeek, Kimi, Qwen) + fast inference via `:nitro` routing (Groq/Cerebras)
- Fast inference aliases: `gpt-oss-nitro`, `kimi-nitro`, `qwen3-nitro`, `gpt-oss-small-nitro`
- Provider aliases: `deepseek`, `deepseek-r1`, `kimi`, `kimi-think`, `qwen-coder`, `qwq`, `hermes`, `glm`, `minimax`, `reka`, `devstral`
- Environment variable: `OPENROUTER_API_KEY`
- Robust error handling for non-JSON responses (HTML from 502 errors)
- Explicit nil checks for generation params (allows temperature: 0)

## [0.9.154] - 2025-12-06

### ace-llm v0.12.0 (Task 128.01)

**x.ai (Grok) Provider**
- New LLM provider for x.ai's Grok models via OpenAI-compatible API
- Supports grok-4, grok-4-fast, grok-4-1-fast, grok-code-fast-1, grok-3 variants, grok-2
- Default model: grok-4 with max_tokens: 4096
- Global aliases: `grok` → xai:grok-4, `grokfast`, `grokcode`
- Environment variable: `XAI_API_KEY`

**Provider Config Migration**
- Moved provider configs from `ace-llm/providers/` to `.ace.example/llm/providers/`
- Eliminates duplication between gem and project configurations
- Example configs serve as canonical source for gem distribution

### ace-llm-models-dev v0.3.1

- Provider config paths updated to use `.ace.example/llm/providers/` pattern
- CLI commands now return status codes instead of calling `exit 1` directly
- Various bug fixes and test improvements

## [0.9.153] - 2025-12-03

### ace-review v0.22.0 (Task 126.03)

**Auto-Save Feature**
- Automatically save reviews to task directories based on git branch name
- Enable with `auto_save: true` in `.ace/review/config.yml`
- Configurable branch patterns via `auto_save_branch_patterns`
- Release directory fallback via `auto_save_release_fallback`
- Disable per-command with `--no-auto-save` CLI flag

**Multi-Model Auto-Save Fix**
- Individual model reports now saved to task directory (not just synthesis)
- Matches explicit `--task` flag behavior

**Code Quality Improvements**
- Integration tests for auto-save flow (branch detection → task resolution)
- GitBranchReader tests stabilized with Open3 mocking
- Removed unused `project_root` variable in TaskReportSaver

## [0.9.152] - 2025-12-03

### ace-review v0.21.0 (Task 126.02)

**Multi-Model Report Synthesis**
- Automatically synthesize reviews from multiple LLM models into unified, actionable reports
- New `ace-review synthesize --session <dir>` standalone command
- Auto-triggered after multi-model execution when 2+ models succeed
- Identifies consensus findings, strong recommendations, unique insights, and conflicting views
- Produces prioritized action items combining all model feedback
- Configurable synthesis model via `--synthesis-model` or `synthesis.model` config
- Disable with `--no-synthesize` flag or `synthesis.enabled: false` config

**New Components**
- ReportSynthesizer molecule with LLM-powered report consolidation
- Synthesis prompt template: `handbook/prompts/synthesis-review-reports.system.md`
- E2E integration test for multi-model auto-synthesis flow

**Configuration Defaults Clarification**
- Default preset is `code` (basic single-model review)
- Default `auto_execute` is `false` (prompts for confirmation)
- Projects can override in their `.ace/review/config.yml`

## [0.9.151] - 2025-12-03

### ace-review v0.20.6
- **Fixed**: SlugGenerator removes trailing hyphen after max_length truncation
- **Documentation**: Added Multi-Model Reviews section to README
- **Documentation**: Added Preset Resolution Chain section to README

## [0.9.150] - 2025-12-03

### ace-review v0.20.0 → v0.20.5 (Task 126.01)

**Multi-Model Concurrent Execution**
- Run code reviews against multiple LLM models simultaneously
- New `--model` flag accepts comma-separated models or multiple flags
- Thread-safe parallel execution with progress indicators
- Preset support via `models:` array in YAML configuration

**Configuration Improvements**
- Config-based settings: `max_concurrent_models`, `auto_execute`, `llm_timeout`, `defaults.preset`
- Moved runtime options from ENV to `.ace/review/config.yml`
- Config-based preset default replaces hardcoded "pr" fallback
- LLM timeout (300s default) to prevent indefinite hangs

**Fixes & Hardening**
- Model name validation in CLI to prevent malformed strings
- Correct `Ace::Core.get` API for config loading
- Output file handling - pass `output_file` to LlmExecutor correctly
- Task report filenames use full model slug to prevent overwrites
- Concurrency guard - clamp to minimum 1, filter blank model entries

**Refactoring**
- Preset consolidation - replaced duplicated `pr.yml` with DRY `code-pr.yml`
- Improved CLI output - task directory shown once, then filenames listed
- Documentation updated to use `code-pr` preset

## [0.9.149] - 2025-12-03

### ace-git-worktree v0.4.8
- **Fixed**: Upstream branch tracking reliability - enhanced with fallback mechanism
  - Added `set_upstream` method using `git branch --set-upstream-to`
  - `setup_upstream_for_worktree` tries `git push -u` first, falls back to `--set-upstream-to` if push fails but remote branch exists
  - Added `remote_branch_exists?` helper for remote branch detection
  - Enabled `auto_setup_upstream` and `auto_push_task` in project config

## [0.9.148] - 2025-12-02

### ace-context v0.18.2 (Task 127)
- **Fixed**: Top-level preset support - enable `context.presets` at configuration root level
  - Process preset references in top-level context configuration (not just within sections)
  - Merge files, commands, and params from referenced presets
  - Apply "current config wins" precedence for overrides
- **Fixed**: Fail-fast error handling for preset loading
  - Raise clear error when any referenced preset fails to load
  - Remove silent debug-only warnings for preset failures
- **Changed**: Make `merge_preset_data` public method (remove `.send()` usage)

### ace-taskflow v0.20.1
- **Fixed**: IdeaDirectoryMover normalization - move entire folder when passed file path
- **Changed**: Update `draft-task.wf.md` documentation for idea done command

## [0.9.147] - 2025-12-01

### ace-review v0.19.2 (Task 114)
- **Fixed**: Task integration (`--task` flag) now works correctly
  - Add missing require for TaskManager class
  - Pass actual review file path to TaskReportSaver
  - Add defensive guard for missing task paths
- **Changed**: Refactored tests to use Minitest::Mock consistently

## [0.9.146] - 2025-12-01

### ace-prompt v0.4.0 (NEW GEM - Task 121)
New prompt workspace management gem with ATOM architecture. Features: archive with timestamps, setup command with template resolution (`tmpl://`), context loading via ace-context, LLM-powered enhancement (`--enhance/-e`), and task folder support (`--task/-t`) with branch detection.

### ace-git-worktree v0.4.7 (Task 124, 125)
Major workflow improvements: fixed branch source bug (now uses current branch as start-point), added `--source` option, upstream push and draft PR creation automation, and changed `auto_setup_upstream`/`auto_create_pr` to default `false` (opt-in for network operations).

### ace-review v0.19.1
Fixed PR diff generation to use actual PR content instead of origin...HEAD when using `--pr` flag with presets.

## [0.9.145] - 2025-11-29

### ace-prompt v0.3.0 (Task 121.03)
- **Added**: Context loading via ace-context integration
  - FrontmatterExtractor atom for parsing YAML frontmatter from prompts
  - ContextLoader molecule integrating with ace-context Ruby API
  - PromptProcessor enhanced with context embedding via `--context` flag
- **Changed**: Global configuration via ace-support-core config cascade
  - Simplified ContextLoader using ace-context Ruby API directly

## [0.9.144] - 2025-11-29

### Fixed
- **ace-review v0.19.1**: Fix PR diff generation to use actual PR content instead of origin...HEAD when using `--pr` flag with presets
- Remove problematic default subject from `code-pr.yml` preset that contained `origin...HEAD`
- Add comprehensive integration tests for PR diff generation behavior

### ace-prompt v0.2.0
- **Added**: Setup command for template initialization (Task 121.02)
  - `ace-prompt setup` initializes workspace with template
  - Template resolution via `tmpl://` protocol (ace-nav Ruby API)
  - Short form template support (`--template bug` → `tmpl://ace-prompt/the-prompt-bug`)
  - `--no-archive` and `--force` options to skip archiving existing prompts
  - Archive functionality by default (consolidated from removed reset command)
- **Changed**: Setup uses project root directory via ProjectRootFinder (Task 121.08)
  - Prompts now created in `{project_root}/.cache/ace-prompt/prompts/` not home directory
  - Consolidated reset command into setup (reset removed from CLI)
  - Template naming pattern: `the-prompt-{name}.template.md`
  - Template resolution uses ace-nav Ruby API (no shell execution)
- **Fixed**: CLI exit code handling for Thor Array return (Task 121.08)

## [0.9.143] - 2025-11-28

### ace-git-worktree v0.4.2
- **Fixed**: Branch source bug - worktrees now correctly use current branch as start-point
  - Previously, worktrees created from feature branches would base their branch on main worktree HEAD
  - Now `git worktree add` explicitly passes current branch (or commit SHA if detached) as start-point
- **Added**: `--source <ref>` option to specify custom git ref as branch start-point
  - Allows explicit control: `ace-git-worktree create --task 123 --source main`
- **Added**: `GitCommand.ref_exists?` method for git ref validation
- **Added**: Result hash includes `start_point` field showing which ref was used

## [0.9.142] - 2025-11-28

### ace-git-worktree v0.4.1
- **Fixed**: TaskPusher module loading bug that prevented remove command from working
  - Added missing require statement in main loader file
  - Restores functionality of `ace-git-worktree remove --task` command
  - Fixes "uninitialized constant Ace::Git::Worktree::Molecules::TaskPusher" error

## [0.9.141] - 2025-11-28

### ace-git-worktree v0.4.0
- **Added**: TaskIDExtractor atom for consistent hierarchical task ID handling across all components
  - Properly handles subtask IDs (e.g., `121.01`) without stripping to parent number
  - Shared `extract()` and `normalize()` methods used by all worktree operations
- **Changed**: TaskFetcher now uses `TaskManager` (organism-level API) instead of `TaskLoader`
  - Simplified integration with ace-taskflow through high-level API only
- **Changed**: All worktree components now use TaskIDExtractor
  - `worktree_info.rb`, `worktree_manager.rb`, `task_worktree_orchestrator.rb`
  - `task_status_updater.rb`, `worktree_creator.rb`, `worktree_config.rb`, `remove_command.rb`
- **Fixed**: Critical bug where subtask worktree operations affected wrong tasks
  - Worktrees for `121.01` no longer match or affect `121` parent task
  - Create, remove, and status operations now correctly isolate subtasks
- **Fixed**: `remove --task 121.01` not finding worktrees (lookup preserved subtask ID)

## [0.9.140] - 2025-11-27

### ace-taskflow v0.20.0
- **Added**: Comprehensive subtask workflow support for hierarchical task execution (Task 122)
  - Hierarchical task ID parser supporting `121`, `121.00`, `121.01` formats for parent-child relationships
  - Task scanner enhancement for orchestrator + subtask patterns with automatic relationship detection
  - CLI integration with `--child-of` flag for creating hierarchical task relationships
  - New `work-on-subtasks.wf.md` orchestration workflow with worktree-per-subtask isolation
  - Subtask display modes: `--subtasks/--no-subtasks/--flat` for flexible hierarchy viewing
  - Configurable terminal statuses through project configuration (`terminal_statuses` in `.ace/taskflow/config.yml`)
  - Dynamic PR base branch handling for subtask pull requests targeting parent branches
  - Comprehensive cascade handling for subtask completion and status updates
- **Fixed**: Task manager test configuration to use configured task_dir instead of hardcoded paths
  - Ensures proper test isolation and respects project configuration settings
  - Prevents test pollution across different task directory configurations
- **Technical**: Updated test fixtures and clarified documentation for subtask workflow patterns

## [0.9.139] - 2025-11-27

### ace-review v0.19.0
- **Added**: Specification review focus (`scope/spec`) for reviewing specifications and proposals
  - Goal clarity validation (single objective, no ambiguous terms, clear success criteria)
  - Usage expectations analysis (target audience, scenarios, inputs/outputs)
  - Test strategy evaluation (testable criteria, edge cases, validation approach)
  - Completeness checking (required sections, dependencies, assumptions)
  - Implementation feasibility assessment (achievable requirements, realistic estimates)
  - Consistency and traceability verification
- **Added**: New `spec.yml` preset for specification reviews
  - Default subject: `origin/main...HEAD` filtered to `**/*.s.md` (task specs)
  - Combines spec focus with standard format and tone guidelines

## [0.9.138] - 2025-11-17

### ace-review v0.18.0
- **Added**: GitHub Pull Request review mode with `gh` CLI integration
  - New `--pr` flag accepts PR number, URL, or owner/repo#number format
  - `--post-comment` flag to automatically post review as PR comment
  - `--dry-run` flag for comment preview without posting
  - `--gh-timeout` flag to configure GitHub CLI operation timeout (default 30s)
  - Automatic repository detection from git remote for PR numbers
  - Comprehensive error handling for authentication, network issues, and PR state
  - Retry logic with exponential backoff for network resilience
  - PR state validation prevents posting to closed/merged PRs
  - Rich PR metadata in review context (title, author, branch names, state)
  - Secure comment posting via tempfiles (prevents command injection)
  - Markdown sanitization with automatic code fence closing
  - New molecules: GhCliExecutor, PrIdentifierParser, GhPrFetcher, GhCommentPoster
  - New atom: RetryWithBackoff for reusable retry logic
  - New error classes for GitHub integration (GhCliNotInstalledError, GhAuthenticationError, etc.)
  - Comprehensive README documentation with examples and troubleshooting
- **Changed**: Reduced default GitHub CLI timeout from 600s to 30s for faster failure feedback
- **Changed**: Extracted retry logic into reusable RetryWithBackoff atom
- **Fixed**: Moved GhCliExecutor from atoms/ to molecules/ for architectural compliance
- **Fixed**: Uncommented and fixed previously failing tests in gh_pr_fetcher_test.rb

### ace-review v0.17.0
- **Added**: Task integration with `--task` flag to save review reports to task directories
  - Accepts task references: `114`, `task.114`, `v.0.9.0+114`
  - Reports saved to `<task-dir>/reviews/` with timestamped filenames
  - Graceful degradation when ace-taskflow unavailable
  - New molecules: TaskResolver, TaskReportSaver

## [0.9.137] - 2025-11-17

### ace-llm v0.11.0
- **Added**: Graceful LLM provider fallback with automatic retry logic
  - Automatic retry with exponential backoff (configurable, default 3 attempts)
  - Intelligent error classification (retryable, skip to next, terminal)
  - Fallback provider chain with configurable alternatives
  - Total timeout protection (default 30s) to prevent infinite retry loops
  - Jitter (10-30%) added to retry delays to prevent thundering herd issues
  - Configurable via environment variables (`ACE_LLM_FALLBACK_*`) and runtime parameters
  - Status callbacks for user visibility during fallback operations
  - Respects Retry-After headers for rate limit compliance
  - Comprehensive fallback configuration documentation (134 lines in README)
  - Environment variable reference for all `ACE_LLM_FALLBACK_*` settings with defaults
  - YAML configuration examples for project and user-wide settings
  - Provider chain examples: simple fallback, cost-optimized, multi-provider reliability, local + cloud hybrid
  - Complete explanation of fallback mechanism with error classification details
  - Performance characteristics: overhead, backoff strategy, timeout behavior
  - Programmatic usage examples in Ruby
- **Changed**: Improved fallback orchestrator code organization and maintainability
  - Extracted error handling logic into dedicated `handle_error` method for better separation of concerns
  - Refactored `FallbackConfig.from_hash` with helper method to support both symbol and string keys
  - Enhanced retry delay calculation with jitter to prevent synchronized retry storms
  - Improved test coverage with range-based assertions for jittered delays
  - Refactored FallbackOrchestrator tests for better performance
  - Extracted `sleep` call to protected `wait` method for easier stubbing
  - Updated 4 tests to use method stubbing instead of actual delays
  - Achieved 28% test performance improvement (1.7s → 1.22s)
  - Follows project testing patterns from `docs/testing-patterns.md`
- **Technical**: Comprehensive test coverage for fallback system (atoms, molecules, models, integration)
  - Follows ATOM architecture: ErrorClassifier (Atom), FallbackConfig (Model), FallbackOrchestrator (Molecule)

### ace-git-commit v0.12.2
- **Technical**: Updated ace-llm dependency from `~> 0.10.0` to `~> 0.11.0` for graceful provider fallback support

### ace-llm-providers-cli v0.10.1
- **Technical**: Updated ace-llm dependency from `~> 0.10.0` to `~> 0.11.0` for graceful provider fallback support

## [0.9.136] - 2025-11-16

### ace-support-core v0.11.0
- **Added**: Standardized prompt cache management via `PromptCacheManager`
  - Stateless utility class with consistent file naming (`system.prompt.md`, `user.prompt.md`)
  - Session-based caching with `.cache/{gem}/sessions/{operation}-{timestamp}/` pattern
  - Git worktree support via ProjectRootFinder
  - Comprehensive test coverage (26 tests) for reliable cross-gem functionality
- **Changed**: Refactored PromptCacheManager class method structure
  - Updated from private_class_method to class << self block pattern
  - Enhanced code organization and maintainability following Ruby idioms

### ace-docs v0.9.0
- **Changed**: Migrated prompt caching to use the new `PromptCacheManager`
  - File names: prompt-system.md → system.prompt.md, prompt-user.md → user.prompt.md
  - Directory: .cache/ace-docs/ → .cache/ace-docs/sessions/
  - Replace git rev-parse with PromptCacheManager (uses ProjectRootFinder)
- **Fixed**: Test isolation issues in document registry and status command tests
  - Tests now properly isolate to temporary directories
  - Prevents discovery of real project files during testing

### Dependency Updates
- **ace-git-diff v0.1.3**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
- **ace-search v0.11.4**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
- **ace-lint v0.3.3**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`

### ace-taskflow v0.19.3
- **Changed**: Standardize task reference format with 'task.' prefix
  - Updated qualified references from `v.0.9.0+018` to `v.0.9.0+task.018`
  - Ensures consistent and unambiguous format for task references across the system
  - Maintains backward compatibility with both old and new reference formats

### Documentation
- **ace-gems.g.md**: Added comprehensive "Prompt Caching Pattern" section
  - Documents structure, usage, benefits, and examples
  - Provides guidance for future gems implementing prompt caching

### Technical
- **Dependency Standardization**: Coordinated version updates across ACE ecosystem
  - Ensured all affected packages use consistent ace-support-core ~> 0.11 dependency
  - Maintains backward compatibility while enabling access to latest features
  - Simplified dependency management and reduces version conflicts

## [0.9.135] - 2025-11-16

### Fixed
- **ace-taskflow v0.19.2**: Task counting bug and canonical task ID format standardization
  - Fixed statistics counting where pending tasks showed incorrect count (3 instead of 12)
  - Updated `get_statistics` glob pattern to match both old format (`task.NNN.s.md`) and new hierarchical format (`NNN-slug.s.md`)
  - Standardized all task IDs to canonical format (`v.0.9.0+task.NNN`) for consistent task reference resolution
  - Updated test expectations to match canonical format
  - Ensures accurate task statistics across all task naming formats

## [0.9.134] - 2025-11-15

### Fixed
- **ace-review v0.16.1**: Git worktree cache path resolution
  - Fixed cache directory creation to use project root instead of current working directory
  - Resolves issue where caches were created in deeply nested, incorrect paths in git worktrees
  - Added `ProjectRootFinder` integration for consistent path resolution across worktree and main repo contexts
  - Each worktree now maintains its own cache at `.cache/ace-review/sessions/` relative to worktree root
  - Added `test_finds_git_worktree_root` test to verify `.git` file (worktree) vs directory (main repo) handling
  - All 161 ace-review tests pass with no breaking changes to main repo usage
  - Transparent fix - tool "just works" in worktrees without user configuration

### Changed
- **ace-taskflow v0.19.1**: Task 111 completion
  - Marked task 111 (Fix ace-review cache path resolution in git worktrees) as done
  - All success criteria met and verified
- **ace-support-core v0.10.1**: Test coverage improvements
  - Added worktree detection test to ProjectRootFinder test suite
  - Verified correct handling of `.git` as both file (worktree) and directory (main repo)

## [0.9.133] - 2025-11-15

### Added
- **ace-taskflow v0.19.0**: Idea folder structure validation and enforcement
  - New `validate-structure` command checks idea file organization with detailed error reporting
  - Enforces ideas must be in subfolders within ideas/ directory (e.g., `ideas/folder-name/file.md`)
  - Provides clear error messages with suggested proper locations for misplaced files
  - Warning shown in `ideas` list command when misplaced ideas are detected
  - `idea create` now returns full file path instead of directory for better UX
  - Environment variable `SKIP_IDEA_VALIDATION` for performance optimization in large repositories
  - Comprehensive YARD documentation with exit codes (0=success, 1=failures) for CI/CD integration
  - 26 comprehensive tests covering all validation scenarios including edge cases
  - Command integrated into help text for easy discoverability
- **ace-git v0.2.0**: PR Documentation Workflow - Automated PR title and description generation
  - New `update-pr-description` workflow extracts metadata from changelog and task files
  - Analyzes commit messages to identify change patterns and types
  - Generates structured PR descriptions with summary, changes breakdown, breaking changes, and related tasks
  - New `/ace:update-pr-desc` command for easy invocation from Claude Code
  - Auto-detects PR number from current branch or accepts explicit PR number argument
  - Uses conventional commits format for titles (e.g., `feat(scope): description`)
  - GitHub CLI integration for updating PR titles and descriptions
  - Comprehensive documentation with examples and best practices
  - Supports multi-line body formatting with heredoc for clean PR updates

### Changed
- **ace-taskflow v0.19.0**: Code quality improvements for better maintainability
  - Removed duplicate `format_path_relative_to_pwd` method from `IdeaCommand`
  - Now uses `Atoms::PathFormatter.format_relative_path` following DRY principle
  - Eliminates code duplication across command classes

## [0.9.132] - 2025-11-15

### Added
- **ace-git-commit v0.12.0**: Path restriction for targeted commits with glob pattern support
  - Support for committing only files within specified directories or paths
  - Full glob pattern support (`**/*.rb`, `lib/**/*.test.js`) for flexible file selection
  - Repository boundary validation to ensure paths are within git repository
  - Early path validation with clear error messages
  - Comprehensive CLI documentation with detailed path and pattern usage examples

## [0.9.131] - 2025-11-15

### Added
- **ace-llm v0.10.0**: System Prompt Control with Code Quality Improvements
  - New `--system-append` flag for flexible prompt composition
  - Enhanced CLI help text with provider-specific behavior notes
  - Comprehensive test coverage with 13 new tests for helper methods
- **ace-llm-providers-cli v0.10.0**: Claude Provider Bug Fix and Enhancement
  - Added support for `--append-system-prompt` flag mapping
  - Enables flexible prompt composition with Claude models

### Fixed
- **ace-llm**: Fixed ClaudeCodeClient to use correct `--system-prompt` flag
  - Resolves issue where system prompts were silently ignored with Claude
  - Enables fast, deterministic responses with Claude Haiku for tools like ace-git-commit

### Changed
- **ace-llm**: Code organization improvements based on multi-LLM code review
  - Made helper methods private for better encapsulation
  - Relocated test file to align with ACE flat test structure
  - Made system prompt separator configurable via constant
  - Improved system prompt handling with shared helpers and deep copy pattern

### Technical
- **ace-llm**: Added deprecation note for `append_system_prompt` option, prefer `system_append`
- **Dependencies**: Updated ace-git-commit and ace-llm-providers-cli to use ace-llm ~> 0.10.0

## [0.9.130] - 2025-11-15

### Added
- **ace-docs v0.8.0**: ISO 8601 UTC timestamp support with backward compatibility for date-only format. See ace-docs/CHANGELOG.md for details.

## [0.9.129] - 2025-11-13

### Added
- **ace-review v0.16.0**: Preset Composition - DRY configuration for review presets
  - New `presets:` array enables composing review presets from reusable base configurations
  - Smart merging: arrays concatenate+deduplicate, hashes deep merge, scalars last-wins
  - Circular dependency detection with max depth limit (10 levels)
  - Path traversal prevention and preset name validation for security
  - Intermediate caching for performance (beneficial for deeply nested presets)
  - New PresetValidator atom for validation logic
  - Enhanced PresetManager with recursive composition support
  - Full backward compatibility - existing presets work unchanged
  - Comprehensive test coverage: 60 tests (23 validator + 26 manager + 11 integration)
  - Example presets demonstrating DRY pattern (code.yml, code-pr.yml, code-wip.yml)

### Fixed
- **Security**: Preset name validation now properly enforced before filesystem access (prevents path traversal)
  - Added explicit ArgumentError raising for invalid preset names
  - Re-raise validation errors to prevent security check suppression
  - Added comprehensive security tests for path traversal attempts
- **Caching**: Intermediate caching now works correctly for shared base presets
  - Removed `visited.empty?` guard that prevented caching during recursive composition
  - Moved circular dependency check before cache lookup for correctness
  - Shared base presets are now cached and reused across compositions

### Improved
- **Code Quality**: Extracted metadata keys to constant and added clarifying comments
  - Added `COMPOSITION_METADATA_KEYS` constant to improve maintainability
  - Added array merge strategy comment for clarity
  - Added MAX_DEPTH explanation comment

## [0.9.128] - 2025-11-13

### Added
- **ace-docs v0.7.0**: Documentation workflow consolidation
  - Migrated 5 documentation generation workflows from dev-handbook to ace-docs
  - Added workflows: create-api-docs, create-user-docs, update-blueprint, update-context-docs, create-cookbook
  - All workflows accessible via `ace-nav wfi://workflow-name` protocol
  - Consolidates all documentation workflows in their proper architectural home

### Changed
- **ace-docs v0.7.0**: Path modernization and workflow consistency
  - Updated all workflow references to use protocol-based paths (wfi://)
  - Replaced hardcoded dev-handbook paths with project-agnostic references
  - Updated existing workflows (create-adr, maintain-adrs) for consistency
  - All workflows now work in any project context without legacy dependencies

### Fixed
- **ace-docs v0.7.0**: Workflow frontmatter restoration
  - Fixed YAML frontmatter corruption in create-adr and maintain-adrs workflows
  - Restored proper multi-line YAML structure after ace-lint formatting issue

## [0.9.127] - 2025-11-13

### Fixed
- **ace-git-commit v0.11.2**: Resolve silent staging failures and improve error reporting
  - Staging operations now properly detect and report failures with clear ✓/✗ indicators
  - Error messages always visible even in quiet mode for critical issues
  - Added `--verbose` (default) and `--quiet` flags for output control
  - Enhanced user feedback with actionable suggestions on failures
  - Improved error message format with file count feedback

### Added
- **ace-test-runner v0.1.7**: Skipped test reporting functionality
  - Added comprehensive skipped test reporting to console output and suite summaries
  - Displays count and visual indicators for skipped tests in execution summaries
  - Shows detailed skipped test information including reason when available
  - Includes skipped tests in final statistics with skip percentage

## [0.9.126] - 2025-11-13

### Added
- **ace-git v0.1.0**: New workflow-first gem providing comprehensive git operation workflows
  - Rebase workflow with CHANGELOG.md and version file preservation
  - PR creation workflow with GitHub CLI integration and structured templates (default, feature, bugfix)
  - Squash workflow for version-based commit squashing with automatic detection
  - Four templates for consistent PR descriptions and commit messages
  - ace-nav protocol integration (wfi:// and template://) for workflow discovery
  - Minimal, preference-based configuration with sensible defaults

### Fixed
- **ace-git v0.1.0**: Code review improvements
  - Removed built gem file from repository and added *.gem to .gitignore
  - Added MIT license metadata to gemspec
  - Differentiated gemspec URIs for better RubyGems.org display
  - Clarified Git version requirement to >= 2.23.0 for modern features

## [0.9.125] - 2025-11-13

### Added
- **ace-git-worktree v0.3.0**: PR and branch-based worktree creation
  - **NEW**: `--pr <number>` flag to create worktrees from GitHub pull requests
  - **NEW**: `-b <branch>` flag for worktrees from local/remote branches
  - GitHub CLI integration with automatic PR metadata fetching
  - Auto-detection of remote vs. local branches with smart tracking setup
  - Retry logic with exponential backoff for transient network failures
  - Fork PR detection with user warnings
  - Comprehensive test coverage (43 tests total)
  - Full documentation with usage examples and configuration guide

### Changed
- **ace-git-worktree v0.3.0**: Enhanced error messages and validation
  - Error messages now include repository context (e.g., "PR #123 not found in owner/repo")
  - Configuration validation detects invalid template variables with helpful suggestions
  - Git remote validation prevents confusing errors from invalid remote names
  - Code quality improvements with extracted helper methods

### Fixed
- **ace-git-worktree v0.3.0**: Branch naming collision resolution
  - Fixed collision issue when multiple remote branches share same last segment
  - Now uses full branch path: `origin/feature/auth/v1` → branch: `feature/auth/v1`, dir: `feature-auth-v1`

## [0.9.124] - 2025-11-11

### Technical
- **ace-git-worktree v0.3.0**: Architecture and performance improvements
  - Added `PrFetcher` molecule following ATOM pattern
  - Cached gh CLI availability check for performance
  - Extended `WorktreeCreator`, `WorktreeConfig`, and `WorktreeManager`
  - Template variable support: `{number}`, `{slug}`, `{base_branch}` for PR naming
  - Repository name caching for better error messages
  - Configuration validation with comprehensive template variable checking
  - Remote validation before git fetch operations
- **ace-git-worktree v0.2.2**: Test suite modernization and command enhancements
  - Simplified test architecture with 843 line reduction (focused smoke tests)
  - Added missing CLI flags (--no-mise-trust, --force)
  - Enhanced security validation for user inputs
  - Fixed command test mocks to match actual API signatures

## [0.9.123] - 2025-11-11

### Fixed
- **ace-review v0.15.1**: Optimize test suite performance with mocking (2.2x faster, 2.03s → 0.93s)
  - Add `Ace::Context.load_auto()` mocking in test_helper
  - Add `GitExtractor` mocking (staged_diff, working_diff, tracking_branch)
  - Remove real git operations from integration tests
  - Fix test issues (super calls, initialization timing, assertions)
  - All 108 tests passing (16 atoms + 53 molecules + 29 organisms + 10 integration)

## [0.9.123] - 2025-11-11

### Fixed
- **ace-git-worktree v0.2.1**: Hook execution fixes and code review improvements
  - Execute after-create hooks for classic branches (previously only worked for task-based)
  - Improved error messages for orphaned branch deletion with detailed reasons
  - Fixed hook configuration structure in tests for reliable execution

### Changed
- **ace-git-worktree v0.2.1**: Enhanced API encapsulation
  - Made `WorktreeRemover#delete_branch_if_safe` public for better encapsulation
  - Enhanced documentation with hooks configuration examples and orphaned branch cleanup

### Technical
- **ace-git-worktree v0.2.1**: Code quality improvements
  - Addressed code review feedback improving test coverage and encapsulation
  - Added test for hook failure handling as non-blocking warnings
  - Restored `pr.yml` preset for ace-review (unblocked CLI default)

## [0.9.122] - 2025-11-11

### Added
- **ace-git-worktree v0.2.0**: Configurable root_path and branch deletion features
  - Configurable worktree root path supporting paths outside project directory
  - New `--delete-branch` flag for safe branch deletion on worktree removal
  - Path expansion with optional base parameter for context-aware resolution
  - Comprehensive test coverage with 46 new tests across all components
  - Enhanced documentation with usage examples and benefits

## [0.9.121] - 2025-11-11

### Added
- **ace-handbook v0.1.0**: New pure workflow package for handbook management
  - 6 handbook management workflows accessible via wfi:// protocol
  - Workflows: manage-guides, review-guides, manage-workflow-instructions, review-workflows, manage-agents, update-handbook-docs
  - Complete gem structure following ACE patterns with comprehensive documentation
  - Extracted from dev-handbook/.meta/wfi/ for better maintainability and distribution
- **ace-integration-claude v0.1.0**: New dedicated package for Claude Code integration
  - Claude Code integration workflow: `wfi://update-integration-claude`
  - Bundled integration assets: templates, custom commands, documentation
  - 11 custom command definitions and reference guides
  - Positioned for future growth of Claude Code integration workflows
- **Package organization improvements**: Better domain separation across ACE packages
  - Moved `update-tools-docs.wf.md` to ace-docs package (tools documentation management)
  - Moved `update-integration-claude.wf.md` to ace-integration-claude package (Claude Code integration)
  - Maintained backward compatibility while improving package boundaries

## [0.9.120] - 2025-11-10

### Technical
- **ace-context v0.18.0**: Minor version bump with context.base support and file-based config parity
  - Added `context.base` field for generic base content handling
  - Fixed file-based configs to process sections and formatting same as presets
  - Enhanced ace-review integration with full section content generation

## [0.9.119] - 2025-11-10

### Added
- **ace-review v0.15.0**: Section-based content organization integration
  - Added support for `instructions.context.sections` format in ReviewManager
  - Integration with ace-context v0.17.5+ section-based content organization
  - Structured organization of review content into semantic sections (focus, style, diff, etc.)
  - All built-in presets (pr, code, security, docs, performance, ruby-atom, agents, test) now use sections
  - Enhanced PresetManager to preserve `instructions` field through resolution chain
  - Added automatic format detection for seamless backward compatibility

### Changed
- **ace-review v0.15.0**: Enhanced ReviewManager architecture
  - Created new `create_system_context_file_with_instructions()` method for section-based contexts
  - Full backward compatibility maintained for existing user presets with `system_prompt` format
  - Updated CLI to properly display system and user prompt file paths
  - CLI now shows correct `ace-llm query` command with `--file` and `--context` parameters

### Documentation
- **ace-review v0.15.0**: Comprehensive documentation updates
  - Added README.md documentation for new section-based format with examples
  - Documented legacy format for backward compatibility and migration guidance
  - Added comprehensive test coverage for new section-based functionality

## [0.9.118] - 2025-11-09

### Added
- **ace-context v0.17.5**: Documentation enhancement for preset nesting depth guidelines
  - Added comprehensive preset nesting depth documentation to `ace-context/docs/configuration.md`
  - Documented recommended maximum depth of 3-4 levels for optimal performance
  - Included examples of good, acceptable, and poor nesting patterns with refactoring guidance
  - Added performance impact table showing load time vs maintainability trade-offs

### Fixed
- **ace-context v0.17.5**: PR review preset configuration issue
  - Removed hardcoded PR number from `.ace/review/presets/pr.yml`
  - Changed from `gh pr diff 18` to generic `git diff origin/main...HEAD` and `git log origin/main..HEAD --oneline`
  - PR review preset now works for any PR branch, not just a specific PR number

## [0.9.117] - 2025-11-07

### Added
- **ace-context v0.17.3**: Integration tests and documentation enhancements based on review feedback
  - Added comprehensive integration tests for section-based workflows and preset composition
  - Enhanced documentation with preset discovery guidance and composition best practices
  - All 98 tests passing with no regressions introduced

### Technical
- Added section workflow integration test validating end-to-end functionality
- Added security review section test with preset-in-section composition
- Improved test coverage for complex section-based configurations

## [0.9.116] - 2025-11-06

### Added
- **ace-context v0.17.2**: Comprehensive improvements based on three-provider review feedback
  - Enhanced documentation structure with configuration.md and usage.md separation
  - Improved error messages with better context and troubleshooting guidance
  - Code refactoring for better performance and maintainability

### Fixed
- **ace-context**: Critical section merging bug where sections without content_type were losing content
- **ace-context**: Enhanced preset loading errors to show available preset options
- **ace-context**: Comprehensive test coverage for all new functionality (91 tests passing)

### Technical
- **ace-context**: Refactored detect_language method to use Hash lookup instead of case statement
- **ace-context**: Centralized content detection helper methods in SectionProcessor
- **ace-context**: Removed deprecated content_type references throughout test suite

## [0.9.115] - 2025-11-06

### Added
- **ace-context v0.17.1**: Enhanced section-based content organization with comprehensive fixes
  - Improved file order preservation within sections to maintain preset configuration order
  - Better format detection that respects explicit format requests even with embed_document_source
  - Enhanced section processing with proper exclude pattern handling

### Fixed
- **ace-context**: Critical embed_document_source access bug in ContextLoader that prevented files from being loaded
- **ace-context**: Exclude pattern handling in legacy-to-section migration to ensure proper file filtering
- **ace-context**: Command processing consistency to maintain backward compatibility with existing behavior
- **ace-context**: Infinite recursion bug in format_sections_for_yaml method that caused stack overflow errors
- **ace-context**: All test failures resolved - test suite now fully passing (91 tests, 0 failures, 0 errors)

### Changed
- **ace-review v0.13.1**: Complete v0.13.0 architectural implementation
  - Remove all prompt splitting logic and fallback methods that were documented but not implemented
  - Eliminate legacy single prompt support in LlmExecutor
  - Implement proper system/user prompt separation via ace-context
  - Fix session file structure to use `system.prompt.md` and `user.prompt.md`
  - Update test suite to remove tests for removed methods and fix expectations
  - Remove 214 lines of legacy code while maintaining functionality
  - Breaking changes: LlmExecutor now requires system_prompt and user_prompt parameters

## [0.9.114] - 2025-11-10

### Added
- **ace-context v0.17.6**: Add support for complex diff configuration format
  - Support both simple `diffs: [...]` and complex `diff: { ranges: [...] }` formats
  - Add `since` parameter that expands to `since...HEAD` range format
  - Normalize all diff formats to internal `ranges` structure in SectionProcessor
  - Maintain backward compatibility with legacy `diffs` format
  - Add 16 unit tests for format normalization
  - Update documentation with format comparison and examples

### Added
- **ace-context v0.17.0**: Major enhancement with preset-in-section functionality
  - Allow sections to reference and combine multiple presets for modular project context creation
  - Full preset composition support within sections with circular dependency detection
  - Intelligent content merging with automatic deduplication of files and commands
  - Mixed content support - combine preset content with local files, commands, and content
  - Enhanced section system with simplified usage (removed content_type and priority requirements)
  - Comprehensive test coverage and documentation

### Changed
- **ace-git-worktree v0.1.13**: Simplify PathExpander implementation and remove over-engineered security tests
  - Remove complex security pattern validation (7 test methods eliminated)
  - Reduce PathExpander implementation from 290+ to 190 lines (35% reduction)
  - Focus on worktree-specific functionality: path expansion, validation, writability checks
  - Remove over-engineered regex patterns and complex security checks
  - Update all tests to use proper `.ace-wt/` directory structure
  - All 25 PathExpander tests now pass vs 32 tests with 11+ failures previously
  - All 23 SlugGenerator tests continue to pass
  - Maintain essential functionality while dramatically improving maintainability
- **ace-git-worktree v0.1.12**: Fix critical task finding issue and remove over-engineered components
  - Fix "unknown keyword: :task_data" error in ace-git-worktree create --task command
  - Remove over-engineered TaskMetadata model (501 lines of code eliminated)
  - Simplify TaskFetcher from 496 to 240 lines (50% reduction in complexity)
  - Update all components to use hash-based task data instead of TaskMetadata objects
  - Fix API mismatches between TaskWorktreeOrchestrator, WorktreeCreator, and TaskStatusUpdater
  - Ensure clean delegation to ace-taskflow instead of duplicating task management logic
  - All 59 tests passing across molecules, organisms, models, and integration test suites
  - ace-git-worktree create --task 094 now works correctly with proper task data integration
- **ace-git-worktree v0.1.11**: Replace CLI subprocess calls with Ruby API integration
  - Update TaskFetcher and TaskStatusUpdater to use ace-taskflow Ruby API as primary method
  - Eliminate subprocess overhead and improve performance in mono-repo environments

## [0.9.114] - 2025-11-05

### Changed
- **ace-git-worktree v0.1.12**: Package version bump with enhanced stability and user experience
  - Resolve ace-git-worktree commit operation failures with enhanced error handling
  - Fix configuration loading and path validation issues for reliable operation
  - Add automatic navigation support for improved user experience
  - Add graceful fallback to CLI when Ruby API unavailable for standalone installations

### Added
- **ace-git-worktree v0.1.13**: Clean, maintainable PathExpander focused on practical worktree needs
- **ace-review**: Fallback configuration loading for improved standalone usage
- **ace-test suite**: Updated to include missing packages (ace-git-worktree and others)
  - Improve error messages to distinguish between mono-repo vs standalone environments
  - Add debug output for troubleshooting integration issues
- **ace-git-worktree v0.1.10**: Improve completed task cleanup messaging and user experience
  - Replace confusing "Task metadata cleanup would require task access" message with clear status-based messaging
  - Show "Task completed: no metadata cleanup needed" for done/completed tasks
  - Fix task status detection to handle stripped CLI format (" done" instead of "done")
  - Improve user experience for normal completed task workflows
- **ace-git-worktree v0.1.9**: Fix critical task lookup and CLI parsing issues
  - Fix ace-taskflow CLI output format mismatch causing "Task not found" errors
  - Implement robust CLI parser for human-readable ace-taskflow output format
  - Add proper support for completed tasks without associated worktrees
  - Fix Ruby syntax errors and method loading issues in TaskMetadata class
  - Enhance error messages to distinguish task vs worktree not found scenarios
  - Resolve timeout parameter issues in ace-taskflow command execution
- **ace-git-worktree v0.1.8**: Fix remove command inconsistency and add fallback for completed tasks
  - Fix critical bug where remove --dry-run worked but actual execution failed
  - Add fallback logic to remove worktrees even when task metadata not found
  - Implement consistent task validation between dry-run and actual execution
  - Enable cleanup of worktrees for tasks marked as done in ace-taskflow
- **ace-git-worktree v0.1.7**: Major worktree detection and parsing improvements
  - Fix critical worktree detection issue - now detects all 7 existing worktrees
  - Update porcelain format parsing to handle structured git worktree output
  - Fix CommandExecutor timeout parameter mismatch causing git help output
  - Add full support for mixed environments (task-aware + traditional worktrees)
  - Proper task ID extraction for existing worktrees (086, 089, 090, 091, 093, 097)

## [0.9.113] - 2025-11-04

### Security
- **ace-git-worktree v0.1.3**: Critical security fixes and comprehensive testing
  - **CRITICAL**: Fix path traversal vulnerability in PathExpander atom
  - **CRITICAL**: Fix command injection vulnerability in MiseTrustor and TaskFetcher
  - Add comprehensive input validation for task IDs and file paths
  - Implement command whitelisting and argument sanitization
  - Add protection against symlink-based attacks with realpath resolution

### Fixed
- **ace-git-worktree**: Configuration standards compliance
  - Update gemspec metadata from placeholder to correct author information
  - Fix Gemfile to use eval_gemfile pattern following ACE standards
  - Modernize Rakefile to use ace-test patterns
  - Remove Gemfile.lock from gem directory

### Added
- **ace-git-worktree**: Comprehensive test coverage and user experience
  - Complete test coverage for all CLI commands (6/6 commands)
  - Security tests for path traversal and command injection prevention
  - Integration tests for molecules and organisms
  - Graceful error handling when ace-taskflow is unavailable
  - Helpful error messages with installation guidance
  - Troubleshooting section in README.md

## [0.9.112] - 2025-11-04

### Fixed
- **ace-core removal**: Complete migration from ace-core to ace-support-core
  - Removed duplicate VERSION constant conflicts that caused warnings
  - Fixed "Failed to resolve protocol: wfi://create-task" errors
  - Updated all gem dependencies to use ace-support-core
  - Eliminated ace-core package entirely (75 files removed)
- **ace-git-worktree v0.1.2**: Updated dependencies and documentation
  - Fixed gemspec dependency from ace-core to ace-support-core
  - Added required support gems to resolve bundler conflicts
  - Updated README.md with correct dependency references

### Changed
- BREAKING CHANGE: ace-core package no longer exists, use ace-support-core
- Updated all documentation references to ace-support-core across codebase
- Regenerated Gemfile.lock files to remove ace-core references

### Technical
- Resolved VERSION constant conflicts between ace-core and ace-support-core
- Ensured proper dependency resolution for ace-nav, ace-context, ace-taskflow
- Verified wfi:// protocol resolution works correctly after migration

## [0.9.111] - 2025-11-04

### Added
- **ace-git-worktree v0.1.1**: Updated gem with fixes and improvements
  - Fixed syntax errors in model files (comment formatting, hash conditionals)
  - Fixed Ruby syntax errors (constant assignment, initialization order)
  - Implemented lazy loading for CLI commands to improve help command performance
  - Updated dependency constraints for better compatibility

### Technical
- Resolved runtime errors preventing ace-git-worktree from functioning
- Improved CLI architecture with lazy command registration pattern

## [0.9.110] - 2025-11-04

### Added
- **ace-git-worktree v0.1.0**: New gem for task-aware git worktree management
  - Task-aware worktree creation with ace-taskflow integration
  - Automatic task status updates and metadata tracking
  - Configuration-driven naming conventions and behaviors
  - Complete ATOM architecture implementation
  - CLI with comprehensive commands (create, list, switch, remove, prune, config)
  - Traditional worktree operations support
  - Automatic mise trust execution for development environments
  - Comprehensive documentation and workflow instructions
  - Example configuration templates and agent definitions

### Fixed
- **ace-taskflow v0.18.4**: Restored task update command implementation
  - Restored complete `ace-taskflow task update` command that was accidentally deleted
  - Restored TaskFieldUpdater molecule, FieldArgumentParser molecule, and all related methods
  - Command supports `--field key=value` syntax for simple and nested YAML field updates
  - Enables worktree metadata updates for ace-git-worktree integration (task 089)
  - Includes comprehensive unit tests (10 tests, 19 assertions, all passing)
  - Updated task 089 with verified working examples and implementation notes

### Integration
- Added ace-git-worktree to ace Gemfile for development
- Updated tools.md to include ace-git-worktree command reference
- Added comprehensive documentation with examples and integration patterns
- Created agent definition for worktree operations
- Integration with ace-ecosystem tools and configuration system

### Success Criteria
- ✅ Complete ATOM architecture implemented
- ✅ Task-aware worktree creation with automatic integration
- ✅ Traditional worktree operations supported
- ✅ Configuration system with validation
- ✅ CLI with comprehensive commands
- ✅ Documentation and handbook integration
- ✅ Example configuration and agent definitions
- ✅ Integration with ace-ecosystem complete

## [0.9.109] - 2025-11-04
- **ace-git-worktree v0.1.0**: New gem for task-aware git worktree management
  - Task-aware worktree creation with ace-taskflow integration
  - Automatic task status updates and metadata tracking
  - Configuration-driven naming conventions and behaviors
  - Complete ATOM architecture implementation
  - CLI with comprehensive commands (create, list, switch, remove, prune, config)
  - Traditional worktree operations support
  - Automatic mise trust execution for development environments
  - Comprehensive documentation and workflow instructions
  - Example configuration templates and agent definitions

### Fixed
- **ace-taskflow v0.18.4**: Restored task update command implementation
  - Restored complete `ace-taskflow task update` command that was accidentally deleted
  - Restored TaskFieldUpdater molecule, FieldArgumentParser molecule, and all related methods
  - Command supports `--field key=value` syntax for simple and nested YAML field updates
  - Enables worktree metadata updates for ace-git-worktree integration (task 089)
  - Includes comprehensive unit tests (10 tests, 19 assertions, all passing)
  - Updated task 089 with verified working examples and implementation notes

## [0.9.109] - 2025-11-04


## [0.9.108] - 2025-11-04

### Fixed
- **ace-taskflow v0.18.3**: Fixed missing task header statistics
  - Tasks command now displays full three-line header with release info, idea stats, and task counts
  - Fixed root_path initialization in StatsFormatter and TasksCommand
  - Pre-existing bug (not from unified filter PR)

## [0.9.107] - 2025-11-04

### Fixed
- **ace-taskflow v0.18.2**: Critical bug fix for releases preset type dispatch
  - Fixed missing `:releases` type parameter in `releases_command.rb` (3 locations)
  - Release-specific presets now correctly resolve instead of falling back to `:tasks` namespace
  - Identified by GPT-5 code review

## [0.9.106] - 2025-11-04

### Fixed
- **ace-taskflow v0.18.1**: Bug fixes from code review feedback
  - Fixed return value consistency in releases command (returns error code 1 instead of nil on preset failure)
  - Fixed error message whitespace handling for legacy flags (properly strips spaces after commas in migration suggestions)

## [0.9.105] - 2025-11-04

### Added
- **ace-taskflow v0.18.0 - Unified Filter System**: New `--filter key:value` syntax replaces legacy filtering flags across tasks, ideas, and releases commands
  - FilterParser Atom: Parses filter syntax with support for OR values (`key:value1|value2`), negation (`key:!value`), and array matching
  - FilterApplier Molecule: Applies filter specifications with AND logic across filters and OR logic within filters
  - Filter-Clear Flag: `--filter-clear` option to override preset filters while keeping release/scope/sort configuration
  - Universal Field Filtering: Filter by any frontmatter field including custom fields (e.g., `--filter team:backend`, `--filter sprint:12`)
  - 52 new tests (23 for FilterParser, 29 for FilterApplier) with 100% pass rate

### Changed
- **ace-taskflow v0.18.0 - Breaking Changes**: Clean break approach with helpful error messages
  - Removed `--status` and `--priority` flags from tasks/ideas commands - use `--filter status:value` or `--filter priority:value` instead
  - Removed `--active`, `--done`, and `--backlog` flags from releases command - use `--filter status:active|done|backlog` instead
  - Updated all command help text with new filter syntax, operators, and comprehensive examples
  - Enhanced TaskFilter molecule to integrate with FilterApplier for universal filtering

### Technical
- Comprehensive usage guide with 30+ examples in `ux/usage.md`
- Error messages show exact migration syntax when legacy flags are used
- Fixed test suite to use new filter syntax throughout

## [0.9.104] - 2025-11-02

### Added
- **ace-taskflow v0.17.0 - Flexible Task Transitions**: Tasks can now transition from any status directly to "done" without requiring intermediate steps (default behavior)
- **Custom Status Support**: Support for custom statuses like "ready-for-review" that aren't in the predefined status list
- **Idempotent Operations**: Running `task done` or status updates multiple times succeeds gracefully with informative messages instead of errors
- **Configuration Support**: New `strict_transitions` config option to enable rigid status validation (opt-in for legacy behavior)

### Fixed
- **Critical Bug - Frontmatter Corruption**: Replaced dangerous regex-based frontmatter editing with safe `DocumentEditor` from ace-support-markdown, preventing task files from being corrupted to 3 lines

### Changed
- **ace-taskflow Default Behavior**: Flexible transitions are now the default (can transition from any status to any other status)

## [0.9.103] - 2025-11-02

### Added

- **ace-taskflow v0.16.0**: Implemented `task update` command for programmatic metadata updates
  - Update any frontmatter field via `--field key=value` syntax
  - Dot notation support for nested YAML structures (e.g., `worktree.branch=feature-name`)
  - Batch updates with multiple `--field` flags in single command
  - Smart type inference for integers, floats, booleans, arrays, and strings
  - Atomic file writes with automatic timestamped backups
  - Comprehensive error handling with specific exit codes
  - 34 test cases covering all functionality
  - Primary use case: Enable ace-git-worktree to add worktree metadata to tasks

## [0.9.102] - 2025-11-02

### Changed
- **Infrastructure Gem Naming Alignment**: Renamed foundational gems to establish clear naming conventions
  - Renamed `ace-core` to `ace-support-core` (v0.10.0) - configuration cascade and shared functionality
  - Renamed `ace-test-support` to `ace-support-test-helpers` (v0.9.2) - test utilities and helpers
  - Updated all 12 dependent gems to use new package names with patch version bumps
  - Established naming pattern: `ace-*` for CLI tools, `ace-support-*` for library-only infrastructure
  - No breaking changes - module names and require paths remain unchanged

### Added
- **Migration Guide**: Comprehensive documentation for gem renaming transition
- **Naming Convention Documentation**: Formalized ace-* vs ace-support-* patterns in docs/ace-gems.g.md

### Technical
- Updated dependencies in 12 gems: ace-context, ace-docs, ace-git-commit, ace-git-diff, ace-lint, ace-llm, ace-nav, ace-review, ace-search, ace-support-markdown, ace-taskflow, ace-test-runner
- All affected gems received patch version bumps for dependency updates
- Updated root Gemfile to reference new gem names
- Created new gem directories alongside old ones for safer migration

## [0.9.101] - 2025-11-01

### Fixed
- **ace-taskflow v0.14.2**: File extension and GTD scope terminology
  - Fixed FileNamer to generate .s.md extension consistently
  - Fixed IdeaLoader default glob patterns to only match ideas directory (not tasks)
  - Updated all FileNamer tests to expect .s.md extension

### Changed
- **ace-taskflow v0.14.2**: Enhanced GTD scope documentation
  - Added comprehensive help text explaining GTD-based scopes (next/maybe/anyday/done)
  - Clarified that scope (folder location) is separate from status (metadata)
  - Updated comments throughout to distinguish scope from status

## [0.9.100] - 2025-11-01

### Fixed
- **ace-taskflow v0.14.1**: Universal preset glob patterns and statistics counting
  - Fixed glob patterns in all presets (next, maybe, anyday, all) to properly include both ideas/ and tasks/ directories
  - Fixed IdeaLoader to use context_root instead of idea_dir for correct glob pattern resolution
  - Fixed statistics counting to use specific globs: `ideas/**/*.s.md` for ideas, `tasks/**/task.*.s.md` for tasks
  - Added command-level filtering to separate idea patterns from task patterns
  - Corrected total count calculations in ideas command to use proper globs
  - Resolved issues where presets returned 0 results and statistics showed incorrect counts

### Technical
- **ace-taskflow**: Created comprehensive retrospective documenting critical testing gaps
  - Identified lack of integration tests for preset system
  - Documented that major functionality was broken despite passing unit tests
  - Proposed improvements: integration test suite, preset validation, and debug command
  - Emphasized importance of end-to-end testing for user-facing features

## [0.9.99] - 2025-10-26

### Added
- **ace-core v0.10.0**: Unified path resolution system with instance-based PathExpander API
  - Factory methods for automatic context inference (`for_file`, `for_cli`)
  - Instance-based `resolve()` method supporting all path types
  - Protocol URI support (wfi://, guide://, tmpl://, task://, prompt://) via plugin system
  - 76 comprehensive tests ensuring backward compatibility and new functionality
  - Updated documentation with usage examples and path resolution rules

## [0.9.98] - 2025-10-25

### Added
- **ace-taskflow v0.14.0**: Maybe and Anyday idea scopes for better idea organization
  - New subdirectories: `ideas/maybe/` for uncertain ideas, `ideas/anyday/` for low-priority ideas
  - Preset support: `ace-taskflow ideas maybe` and `ace-taskflow ideas anyday` commands
  - Creation flags: `--maybe` and `--anyday` for `ace-taskflow idea create`
  - Statistics display with emoji indicators: 💡 (pending), 🤔 (maybe), 📅 (anyday), ✅ (done)
  - Example configurations in `.ace.example/taskflow/presets/maybe.yml` and `anyday.yml`

### Changed
- **ace-taskflow v0.14.0**: Code quality improvements from dual code reviews
  - Extract SCOPE_SUBDIRECTORIES constant to centralize scope definitions
  - Add PRESET_TO_SCOPE mapping for cleaner preset-to-scope resolution
  - Improve status determination using dirname inspection instead of string matching
  - Reduce code duplication in IdeaLoader with loop-based scope loading
  - Add validate_subdirectory_exclusivity helper for mutual exclusivity checks

### Technical
- **ace-taskflow v0.14.0**: Enhanced test coverage and POSIX compliance
  - Add comprehensive test coverage for --maybe/--anyday flag mutual exclusivity (6 new tests)
  - Fix missing final newlines in IdeaWriter templates for POSIX compliance
  - Clean up test artifacts and finalize task 088

## [0.9.97] - 2025-10-25

### Fixed
- **ace-taskflow v0.13.2**: Task sorting issue in preset configurations
  - Tasks were displayed in reverse order when using `ace-taskflow tasks next` command
  - Fixed apply_preset_sorting to handle both string and symbol keys from YAML configs
  - Added comprehensive tests for ascending and descending sort orders

## [0.9.97] - 2025-10-25

### Added
- **ace-search v0.11.1**: Enhanced debugging and validation capabilities
  - Centralized DebugLogger module for unified debug output formatting
  - Path validation warnings for non-existent explicit search paths
  - Comprehensive troubleshooting guide in README
  - DEBUG environment variable documentation with example output

### Changed
- **ace-search v0.11.2**: Implement code review suggestions for clarity and documentation
  - Add design rationale comment to SearchPathResolver explaining ENV var validation
  - Add upgrade note in README linking to Troubleshooting section
  - Document DebugLogger threading context and caching behavior
  - Condense CLI warning message for non-existent paths

### Technical
- **ace-search v0.11.1**: Edge case test coverage for SearchPathResolver (symlinks, non-existent paths, relative paths)
  - Improved debug output consistency across executors
  - 21 additional test cases (17 DebugLogger, 4 edge cases)

## [0.9.96] - 2025-10-25

### Added
- **ace-search v0.11.0**: Project-wide search by default with optional search path argument
  - SearchPathResolver atom with 4-step priority resolution (explicit → env → project root → fallback)
  - Optional SEARCH_PATH positional argument in CLI
  - Display search path in output context for transparency
  - Support for PROJECT_ROOT_PATH environment variable

### Fixed
- **ace-search v0.11.0**: Fixed inconsistent search results from different directories
  - Execute ripgrep/fd from search directory using chdir for correct .gitignore processing
  - Fixed search_path propagation through UnifiedSearcher option builders

### Changed
- **ace-search v0.11.0**: BEHAVIOR CHANGE - Default search scope now project-wide instead of current directory
  - Use `ace-search "pattern" ./` to maintain old behavior (current directory only)

## [0.9.95] - 2025-10-24

### Added
- **ace-context v0.16.0**: File path and protocol arguments support for ace:load-context command
  - New workflow file `handbook/workflow-instructions/load-context.wf.md` with flexible input support
  - wfi:// protocol source registrations for workflow discovery
  - Support for preset names, file paths, and protocol URLs in context loading

### Changed
- **ace-context v0.16.0**: Compacted load-context workflow from 127 to 98 lines (23% reduction)
  - Converted error handling to scannable table format
  - Merged redundant sections for improved readability

### Technical
- **ace-context v0.16.0**: Updated README and documentation examples for flexible input
  - Updated slash command to thin interface pattern (delegates to wfi://load-context)

## [0.9.94] - 2025-10-24

### Technical
- Patch release: Documentation standardization for diff/diffs API
  - **ace-git-diff v0.1.1**: Standardized diff/diffs API documentation
  - **ace-context v0.15.1**: Updated README with unified diff format and deprecated legacy array format
  - **ace-docs v0.6.1**: Changed `filters:` to `paths:` for consistency with ace-git-diff
  - **ace-review v0.11.1**: Updated README and workflow instructions with standardized diff format

## [0.9.93] - 2025-10-23

### Changed

- **ace-context v0.15.0**: Full integration with ace-git-diff
  - GitExtractor delegates all diff operations to ace-git-diff
  - `git_diff()`, `staged_diff()`, `working_diff()` use ace-git-diff for consistent filtering
  - Example presets updated to show diff: key usage
  - All 80 tests passing

- **ace-docs v0.6.0**: ChangeDetector integration with ace-git-diff
  - `generate_git_diff()` now delegates to ace-git-diff
  - Updated test mocks to work with DiffResult objects
  - All ChangeDetector tests passing (17 tests, 66 assertions)
  - Example configs updated with diff filtering notes

- **ace-review v0.11.0**: SubjectExtractor supports new diff: format
  - Handles new `diff: { ranges: [...], paths: [...] }` configuration
  - All 8 example presets updated to use diff: key instead of commands:
  - Maintains backward compatibility with old diff: string format
  - Delegates to ace-context which now uses ace-git-diff

### Technical

- All three gems now use ace-git-diff for unified diff operations
- Global `.ace/diff/config.yml` configuration applies across all gems
- Consistent filtering behavior with user-configurable patterns
- Complete task 075 integration work

## [0.9.92] - 2025-10-23

### Added

- **ace-git-diff v0.1.0**: NEW - Unified git diff functionality for ACE ecosystem
  - Extracted and consolidated git diff logic from ace-context and ace-docs
  - User-configurable exclude patterns via `.ace/diff/config.yml` (no hardcoded constants)
  - ATOM architecture: 4 atoms, 3 molecules, 2 organisms, 2 models
  - CLI with smart defaults, `--output` flag for saving to file, and improved help
  - Configuration cascade: Global → Project → Instance (complete override)
  - Support for date/time resolution ("7d", "1 week ago", "2025-01-01")
  - Comprehensive test coverage (65 tests, 100% passing)
  - Integration helpers for ace-docs, ace-review, ace-context, ace-git-commit

### Changed

- **ace-git-commit v0.11.0**: Integrated with ace-git-diff for unified git command execution
  - GitExecutor now delegates to ace-git-diff's CommandExecutor for all git operations
  - Added ace-git-diff (~> 0.1.0) as runtime dependency
  - Maintains full backward compatibility for all public APIs
  - Analysis logic (detect_scope, analyze_diff) remains in ace-git-commit

## [0.9.91] - 2025-10-23

### Added

- **ace-nav v0.10.1**: Enhanced task:// protocol with improved robustness
  - Implemented task:// protocol for command delegation with unified navigation interface
  - Added comprehensive test coverage for task protocol integration

### Changed

- **ace-nav v0.10.1**: Code quality improvements
  - Improved command parsing robustness using Shellwords.split for proper quote handling
  - Fixed encapsulation by exposing config_loader via public accessor in ProtocolScanner

## [0.9.90] - 2025-10-23

### Added

- **ace-nav v0.10.0**: task:// protocol support with command delegation
  - New `CommandDelegator` organism for cmd-type protocol handling
  - Delegates `task://` URIs to `ace-taskflow task` commands
  - Supports all ace-taskflow reference formats (018, task.018, v.0.9.0+task.018, backlog+025)
  - Pass-through support for --path, --content, and --tree options
  - Added `protocol_type` method to `ConfigLoader` for distinguishing cmd vs file protocols
  - Added `cmd_protocol?` method to `NavigationEngine`
  - Added `--path` option to CLI for consistency with ace-taskflow

- **ace-taskflow v0.13.0**: task:// protocol configuration for ace-nav integration
  - Added `.ace.example/nav/protocols/task.yml` protocol configuration
  - Enables unified navigation interface across all ACE resources
  - Configuration supports all task reference formats and options

### Changed

- **ace-nav**: CLI refactored to return exit codes instead of calling exit() directly
  - Improves testability and composability of CLI methods
  - Entry point now handles exit with returned codes
  - Integration tests updated to check return values

- **ace-nav**: ConfigLoader optimization for performance
  - Reuses ConfigLoader instance from ProtocolScanner
  - Eliminates unnecessary object instantiation on every protocol check

## [0.9.89] - 2025-10-23

### Changed

- **ace-taskflow v0.12.1**: Standardized idea file organization in draft workflows
  - Updated draft-task and draft-tasks workflows to use `ace-taskflow idea done` command
  - Replaced manual git operations with standardized command interface
  - Fixed idea file paths from `docs/ideas/` to `ideas/done/` throughout documentation
  - Simplified workflow complexity (removed 21 lines of manual operations)

## [0.9.88] - 2025-10-23

### Documentation

- **ace-support-markdown v0.1.2**: Improved README examples with educational comments and automated validation
  - Added "why" explanations to all 6 real-world examples clarifying patterns and best practices
  - Refactored Example 5 to use cleaner begin/rescue/ensure pattern with success flag
  - Added automated README example validation (`test/integration/readme_examples_test.rb`)
  - Created comprehensive CONTRIBUTING.md (221 lines) with API sync guidelines
  - Added "Maintaining Documentation" section documenting sync strategy
  - Fixed API parameter documentation (`validate: true` → `validate_before: true`)
  - 8 new test cases ensure documentation stays in sync with code evolution

## [0.9.87] - 2025-10-23

### Documentation

- **ace-support-markdown v0.1.1**: Enhanced README with real-world examples
  - Added 6 comprehensive examples (390+ lines) based on production usage
  - Covers task management, documentation updates, error handling, batch operations
  - All examples extracted from actual ace-taskflow and ace-docs implementations

## [0.9.86] - 2025-10-23

### Changed

- **ace-docs v0.6.0**: Migrated frontmatter handling to ace-support-markdown
  - Replaced custom FrontmatterParser with unified MarkdownDocument.parse API
  - FrontmatterManager now delegates to DocumentEditor for atomic writes with automatic backup
  - Eliminated 605 lines of duplicate code (implementation + tests)
  - Zero breaking changes - maintains full backward compatibility
  - Completes task.082 migration

## [0.9.85] - 2025-10-23

### Changed

- **ace-taskflow v0.12.0**: Migrated to ace-support-markdown for safe file operations
  - DoctorFixer, TaskManager, and IdeaWriter now use SafeFileWriter and DocumentEditor
  - Eliminates file corruption risk through atomic writes and automatic backups
  - All 725 tests passing with no regressions
  - Completes task.081 migration

## [0.9.84] - 2025-10-23

### Changed

- **Documentation terminology standardization**: Consistent tool naming across all docs
  - Standardized to `ace-review` (not `code-review`)
  - Standardized to `ace-test` (not `ace-test-runner`)
  - Standardized to `ace-git-commit` (not `git-commit`)
  - Standardized to `ace-llm-query` (not `llm-query`)

### Technical

- **Removed duplicate workflow**: Deleted `ace-taskflow/handbook/workflow-instructions/review-code.wf.md`
  - Duplicate of `ace-review/handbook/workflow-instructions/review.wf.md`
  - Updated `ace-taskflow/handbook/README.md` to reference ace-review gem
- **Simplified ADR maintenance workflow**: Removed redundant deprecation notice instructions
  - Now references embedded template instead of duplicating content

## [0.9.83] - 2025-10-23

### Fixed

- **ace-docs configuration and performance fixes**: Critical improvements to analyze-consistency
  - Fixed configuration reading to properly respect `llm.model` from config.yml
  - Changed default model from gflash to glite (4-10s vs 2m28s performance improvement)
  - Fixed output handling to only display report path, not content
  - Now respects user configuration instead of ignoring it

### Changed

- **ace-docs version bumped to 0.5.3**: Configuration and performance fixes

## [0.9.82] - 2025-10-23

### Fixed

- **ace-docs analyze-consistency simplified**: Major refactoring for cleaner implementation
  - Now uses ace-llm's native `output:` option to save reports directly
  - Removed redundant report processing and duplicate file generation
  - Fixed cache directory to use git root path (prevents nested directories)
  - Eliminated unnecessary ConsistencyReport parsing - displays LLM response directly
  - Cleaner session directory with only essential files

### Changed

- **ace-docs version bumped to 0.5.2**: Simplified analyze-consistency implementation

## [0.9.81] - 2025-10-21

### Added

- **ace-docs cross-document consistency analysis**: Completed implementation (task.074)
  - LLM-powered analysis to detect terminology conflicts, duplicate content, version inconsistencies
  - Native ace-llm integration using Ruby library interface (not subprocess)
  - Session directory with full inspection capability (prompts, response, report)
  - ace-context integration for better document separation with XML embedding
  - Multiple output formats (markdown, json, text) with configurable thresholds

### Fixed

- **ace-docs analyze-consistency critical bugs**:
  - Fixed LLM response handling (changed from non-existent `result[:success]` to `result[:text]`)
  - Implemented ace-llm's native `output:` option to prevent loss of compute
  - Removed unnecessary document copying (now uses real file paths directly)
  - Added better error messages showing actual API errors
  - Added progress indicators throughout analysis phases

### Changed

- **ace-docs version bumped to 0.5.1**: Bug fixes for analyze-consistency command

## [0.9.80] - 2025-10-20

### Added

- **ace-docs multi-subject configuration**: Comprehensive test coverage and documentation
  - Added 16 tests for multi-subject functionality (Document model, ChangeDetector, DocumentAnalysisPrompt)
  - Created example documents demonstrating multi-subject and single-subject configurations
  - Implemented complete multi-subject configuration feature for categorizing changes

### Changed

- **Task management improvements**
  - Completed task.078 for ace-docs multi-subject configuration
  - Focused task.074 on high-value cross-document consistency analysis

### Technical

- ace-docs version bumped to 0.4.7 with comprehensive changelog
- Enhanced documentation for ace-docs analyze command and multi-subject support
- Updated README documentation with new analyze command features

## [0.9.79] - 2025-10-18

### Fixed

- **ace-docs v0.4.6**: LLM timeout issue in analyze command
  - Added configurable `llm_timeout` setting with default of 300 seconds (5 minutes)
  - Prevents `Net::ReadTimeout` errors during complex document analyses
  - Timeout can be customized via `.ace/docs/config.yml`
  - Resolves issue where analyses taking >60 seconds would fail

## [0.9.78] - 2025-10-18

### Changed

- **ace-docs v0.4.5**: Optimized update-docs workflow for specific file updates
  - Workflow now skips status check when specific files are provided, going directly to analysis
  - Clear decision logic: specific files → direct analysis, bulk operations → status-first
  - Restructured Quick Start section with two distinct paths (Direct Path vs Status-First)
  - Conditional workflow steps - Step 1 (Status Check) marked as "Bulk Operations Only"
  - Enhanced usage examples with dedicated "Update specific document" example
  - Improved efficiency for common use case: `/ace:update-docs ace-docs/README.md`

## [0.9.77] - 2025-10-18

### Added

- **ace-context v0.14.0**: File configuration loading support
  - New `-f/--file` CLI option to load configuration from YAML or markdown files
  - Support for multiple file loading with `-f file1.yml -f file2.md`
  - Mix presets and files: `ace-context -p base -f custom.yml`
  - Files can reference and compose with existing presets via `presets:` key
  - Positional argument now auto-detects input type (preset, file, protocol, inline YAML)
  - New API methods: `load_file_as_preset` and `load_multiple_inputs`
  - Comprehensive test coverage for file loading functionality

### Changed

- **ace-context**: Improved CLI help message and documentation
  - Updated banner from `[PRESET]` to `[INPUT]` to reflect all supported types
  - Added clear description of supported input types in help message
  - Enhanced documentation with input auto-detection section
  - Added examples showing file paths as positional arguments

## [0.9.76] - 2025-10-17

### Added

- **ace-context v0.13.0**: Preset composition support
  - Presets can reference other presets via `presets:` array in YAML configuration
  - CLI accepts multiple presets via `-p` flags or `--presets` comma-separated list
  - New `--inspect-config` flag to view merged configuration without execution
  - Intelligent merging with array deduplication and scalar "last wins" override
  - Circular dependency detection for preset references
  - Example composed presets: base, development, team

### Fixed

- **ace-context v0.13.0**: Preset composition parameter handling
  - Extract all params to root level in preset composition
  - Store preset output mode in metadata for multi-preset loading
  - Cache filename generation for multi-preset mode

## [0.9.75] - 2025-10-16

### Changed

- **ace-docs v0.4.2**: Refactored analyze command to general-purpose change analyzer
  - Removed document embedding and ace-context integration from analysis workflow
  - Simplified prompts to focus on diff summarization without doc-update assumptions
  - Updated system prompt for general change analysis instead of doc recommendations
  - Cleaned up internal architecture (removed create_context_markdown, load_context_md)
  - Net reduction: 126 lines of code for better performance and clarity

## [0.9.74] - 2025-10-14

### Added

- **ace-docs v0.3.0**: Batch analysis command with LLM-powered diff compaction
  - New `ace-docs analyze` command for intelligent documentation analysis
  - LLM compaction via ace-llm-query subprocess integration
  - Automatic time range detection from document staleness
  - Markdown reports organized by impact level (HIGH/MEDIUM/LOW)
  - Cache management with timestamped analysis reports
  - Command architecture refactoring with extracted command classes (DiffCommand, UpdateCommand, ValidateCommand, AnalyzeCommand)
  - ace-lint integration for validation delegation
  - Configuration system integrated with ace-core config cascade

### Fixed

- Task 071 file corruption - restored full task content (1134 lines) from git history after edit tool corruption reduced it to 5 lines

### Technical

- Created retrospective documenting broken task file edits pattern and proposing YAML-aware frontmatter update solutions
- Restored and updated task 071 with proper completion status and achievement summary

## [0.9.73] - 2025-10-14

### Added

- Task reference parsing improvements with ID-based search in ace-taskflow
- Support for v.0.9.0+task.070 reference format in ace-taskflow

### Fixed

- Task lookup for done tasks - simple references (072, task.072) now work correctly
- ace-taskflow now finds tasks in done directory by searching on ID field instead of path extraction

### Changed

- Upgraded ace-taskflow to v0.11.5

## [0.9.72] - 2025-10-14

### Added

- **ADR Lifecycle Management in ace-docs**: Comprehensive workflow infrastructure for Architecture Decision Records
  - Created `ace-docs/handbook/workflow-instructions/create-adr.wf.md` (325 lines)
  - Created `ace-docs/handbook/workflow-instructions/maintain-adrs.wf.md` (599 lines)
  - Embedded templates for ADR creation, deprecation notices, evolution sections, and archive README
  - Cross-references between workflows for complete lifecycle management
  - Real examples and decision criteria from October 2025 archival session

- **Claude Commands for ADR Management**: Organized thin command wrappers
  - Created `.claude/commands/ace/create-adr.md`
  - Created `.claude/commands/ace/maintain-adrs.md`
  - Organized ADR commands under `ace/` namespace for clarity

### Changed

- **ace-docs v0.2.0**: Bumped minor version for ADR workflow features
  - Updated `update-docs.wf.md` with ADR section referencing new workflows
  - Updated `.claude/commands/create-adr.md` to reference new ace-docs location

### Technical

- Removed old standalone `.claude/commands/create-adr.md` (consolidated into ace/ directory)
- ace-docs CHANGELOG updated with 0.2.0 release notes

## [0.9.71] - 2025-10-14

### Added

- **ADR Archive System**: Created `docs/decisions/archive/` directory structure for preserving historical ADRs
  - Archive README documenting deprecation rationale and migration context
  - Clear separation between active and obsolete architectural decisions

- **Six New ADRs**: Documented current gem patterns discovered during mono-repo analysis
  - ADR-016: Handbook Directory Architecture (gem/handbook/ pattern)
  - ADR-017: Flat Test Structure (test/{atoms,molecules,organisms,models}/)
  - ADR-018: Thor CLI Commands Pattern (lib/ace/gem/commands/)
  - ADR-019: Configuration Architecture (ace-core config cascade)
  - ADR-020: Semantic Versioning and CHANGELOG (Keep a Changelog format)
  - ADR-021: Standardized Rakefile (Rake::TestTask with CI compatibility)

### Changed

- **ADR-003 & ADR-004**: Added evolution sections documenting transition from centralized `dev-handbook/templates/` to distributed `gem/handbook/` pattern
- **ADR-013**: Updated scope to clarify naming convention principles still apply while Zeitwerk-specific inflections are legacy-only
- **docs/decisions.md**: Updated summary to reflect current active ADRs and archived decisions

### Technical

- **Archived Legacy ADRs**: Moved 4 obsolete ADRs to archive with deprecation notices
  - ADR-006: CI-Aware VCR Configuration (VCR not used in current gems)
  - ADR-007: Zeitwerk Autoloading (current gems use explicit requires)
  - ADR-008: Observability with dry-monitor (not used in current gems)
  - ADR-009: Centralized CLI Error Reporting (superseded by Thor patterns)
- **ADR-011**: Updated ATOM architecture examples to reflect current gem structure
- **ADR-015**: Documented completion of mono-repo migration with 15+ production gems

## [0.9.70] - 2025-10-14

### Added

#### Meta-Project Workflows

* **ACE Update Changelog Workflow**: Created workflow for main project CHANGELOG updates
  * File: `.ace/handbook/workflow-instructions/ace-update-changelog.wf.md`
  * Automatic versioning from current release with patch increment
  * Claude command: `/ace-update-changelog [description]`

* **ACE Bump Version Workflow**: Created comprehensive workflow instruction for semantic version bumping
  * File: `.ace/handbook/workflow-instructions/ace-bump-version.wf.md`
  * Automates version bumping for individual ACE gem packages
  * Analyzes commits using conventional commit format
  * Supports automatic bump detection (MAJOR/MINOR/PATCH based on commits)
  * Supports explicit bump level override (patch|minor|major parameter)
  * Updates `version.rb` and `CHANGELOG.md` atomically
  * Integrates with ace-git-commit for clean commits
  * Comprehensive troubleshooting with one-liner solutions
  * Claude command: `/ace-bump-version [package-name] [bump-level]`

#### ACE Ecosystem - Complete Foundation (October 2025)

This release represents the complete mono-repo migration from legacy dev-tools to modular ace-* gems, establishing the foundation for AI-assisted development.

**Core Infrastructure**

* **ace-core** (v0.9.0-v0.9.3): Shared utilities and configuration for ACE ecosystem
  * ConfigFinder with cascade resolution (project → user → defaults)
  * OutputFormatter supporting markdown, XML, and markdown-XML formats
  * PathResolver for cross-platform path handling
  * Environment variable cascade loading
  * Foundation library used by all ACE packages

* **ace-context** (v0.9.0-v0.11.4): Project context loading with protocol support
  * Protocol handlers: `wfi://` (workflows), `guide://`, `tmpl://` (templates), `adr://` (ADRs)
  * Preset system with YAML configuration
  * Document source embedding for LLM context
  * Smart caching for performance optimization
  * Git diff integration for change analysis
  * XML embedding format standardization

* **ace-nav** (v0.9.0-v0.9.3): Protocol-based navigation and discovery system
  * Unified access to workflows, guides, templates, ADRs
  * Subdirectory pattern matching
  * Auto-list mode for protocol discovery
  * Standard configuration patterns

**Workflow and Task Management**

* **ace-taskflow** (v0.9.0-v0.11.3): Comprehensive task and release management
  * Task and idea management with timestamped organization
  * Descriptive task paths with semantic directory names
  * Retrospective and release management
  * Configuration cascade system
  * Release command with directory structure support
  * Preset system for flexible task listing
  * Enhanced stats and summary displays
  * Dependency-aware sorting
  * Move-to-done and reschedule functionality
  * Batch operations support
  * Idea, feature, roadmap, and testing workflow migrations
  * Retrospective and review package creation
  * Doctor command for configuration validation
  * Rich clipboard support for ideas (macOS) with ace-support-mac-clipboard
  * Flexible metadata flags for task creation (--title, --status, --estimate, --dependencies)
  * Pending release direct support
  * Test isolation improvements preventing directory pollution
  * 700+ comprehensive tests covering all ATOM layers

**Development Tools**

* **ace-git-commit** (v0.9.0-v0.9.2): LLM-powered conventional commits
  * Automatic commit message generation via Gemini 2.0 Flash Lite
  * Monorepo-friendly (stages all changes by default)
  * Direct message support with `-m` flag
  * Intention-based generation with `-i` flag
  * Informative output for commit operations
  * Proper API key loading with environment cascade

* **ace-review** (v0.9.0-v0.9.9): Code review with LLM assistance
  * Dynamic storage paths for organized review sessions
  * ace-context integration for comprehensive context loading
  * Simplified single-command CLI
  * ace-core ConfigFinder integration
  * Multiple incremental improvements for stability

* **ace-search** (v0.9.0): Unified project-aware search tool
  * Complete migration from legacy dev-tools/exe/search to standalone gem
  * DWIM (Do What I Mean) query analysis with intelligent mode detection
  * Preset-based search configurations
  * Git scope filtering (--staged, --unstaged, --current-branch)
  * Time-based filtering (--since, --until, --recent)
  * fzf integration for interactive result selection
  * Full ATOM architecture: atoms, molecules, organisms, models
  * Default exclusions for archived tasks with override options
  * Sequential group execution support

* **ace-llm** (v0.9.0-v0.9.4): Multi-provider LLM client abstraction
  * Support for Anthropic, OpenAI, Gemini, and local models
  * Streaming response support
  * Model aliases (glite, gflash, sonnet, etc.)
  * Provider plugin architecture
  * Configuration-based provider selection
  * Environment cascade loading support
  * Proper binstubs for ace-llm-query
  * --model and --prompt flags for CLI usage

* **ace-llm-providers-cli** (v0.9.0): CLI-specific LLM providers
  * Local model support via CLI interfaces
  * Provider plugin architecture
  * Integration with ace-llm core

**Code Quality and Documentation**

* **ace-lint** (v0.1.0-v0.3.0): Multi-tool linting orchestration
  * Kramdown markdown linting with style checks
  * Autofix support for common issues
  * ace-core configuration integration
  * Support for multiple tool configurations
  * Configuration cascade: `.ace/lint/config.yml`, `.ace/lint/kramdown.yml`

* **ace-docs** (v0.9.0): Documentation management system
  * Frontmatter-based document discovery
  * Change analysis and validation against rules
  * Update workflow orchestration
  * Batch processing capabilities for multiple documents
  * Iterative agent/human collaboration support
  * Migration documentation for repository restructuring

**Testing Infrastructure**

* **ace-test-runner** (v0.9.0-v0.9.10+): Test execution and reporting
  * Minitest integration with intelligent test discovery
  * Configurable reporters (progress, documentation, minimal)
  * Smoke test pattern support for root-level files
  * Failure limits and fast-fail modes
  * Output control and debugging options
  * Rich developer experience with enhanced reporting
  * Comprehensive gem test coverage
  * Critical edge case testing
  * Performance optimization and profiling support

* **ace-test-support** (v0.9.0): Shared test utilities and helpers
  * Common test helpers and assertion extensions
  * Project scaffolding utilities for tests
  * Fixture management
  * Test isolation patterns

**Support Libraries**

* **ace-support-mac-clipboard** (v0.9.0): macOS clipboard integration
  * NSPasteboard FFI bridge to AppKit
  * Rich content support (images: PNG, JPEG, TIFF)
  * HTML and RTF formatted content preservation
  * File copy detection from Finder with original filenames
  * Platform detection with graceful fallback to text-only on non-macOS
  * Used by ace-taskflow for rich idea creation

### Changed

#### Architecture Standardization (September-October 2025)

**ATOM Pattern Adoption Across All Packages**

* Migrated all packages to standardized ATOM architecture:
  * **Atoms**: Single-responsibility units (executors, parsers, validators)
  * **Molecules**: Coordinated atom groups (managers, filters, integrators)
  * **Organisms**: High-level business logic (searchers, formatters, aggregators)
  * **Models**: Data structures (options, results, presets)
* Standardized flat test structure: `test/atoms/`, `test/molecules/`, `test/models/`, `test/organisms/`
* Consistent naming conventions and organization patterns
* Applied to: ace-core, ace-context, ace-nav, ace-taskflow, ace-git-commit, ace-review, ace-search, ace-llm, ace-lint, ace-docs, ace-test-runner, ace-test-support

**Configuration System Unification**

* Unified configuration via ace-core ConfigFinder across all packages
* Cascade resolution: project config → user config → package defaults
* YAML-based configuration files with package-specific namespaces
* Standardized config structure: `.ace/[package]/config.yml`
* Cross-package config consistency
* Configuration namespace restructuring for clarity

**Testing Standards**

* Comprehensive test coverage requirements across all packages
* Test isolation patterns preventing directory pollution
* Exit code handling standardization for CLI tools
* Version test improvements (regex validation vs exact matching)

**Mono-Repo Workspace**

* Root Gemfile workspace setup for coordinated development
* Shared dependencies across all ace-* gems
* Simplified development workflow with unified tooling

#### Legacy System Migration

**From Monolithic dev-tools to Modular ACE Ecosystem**

* Complete migration of dev-tools functionality to standalone ace-* gems
* Search functionality: `dev-tools/exe/search` → `ace-search` gem
* Taskflow functionality: `dev-taskflow` → `ace-taskflow` gem
* Git commit functionality: `dev-tools/exe/git-commit` → `ace-git-commit` gem
* Review functionality: `dev-tools/exe/review` → `ace-review` gem
* Context loading: `dev-tools/exe/context` → `ace-context` gem
* Navigation: `dev-tools/exe/nav` → `ace-nav` gem
* LLM integration: scattered code → `ace-llm` + `ace-llm-providers-cli` gems
* Testing: scattered scripts → `ace-test-runner` + `ace-test-support` gems
* Linting: scattered scripts → `ace-lint` gem
* Documentation: manual processes → `ace-docs` gem

### Fixed

#### Ecosystem Stabilization (October 2025)

**Cross-Package Integration**

* ace-review + ace-context integration for comprehensive context loading
* ace-lint + ace-core configuration cascade integration
* ace-taskflow test execution fixes preventing mid-execution halts
* ace-context XML embedding format consistency across all loading methods
* ace-review + ace-llm API compatibility updates
* ace-git-commit API key loading with proper environment cascade

**Test Infrastructure Fixes**

* Test isolation preventing directory pollution in main project (ace-taskflow)
* Minitest result parsing and summary display accuracy (ace-test-runner)
* Exit code handling across all CLI tools (proper Integer returns vs SystemExit)
* Clipboard tests compatibility across platforms with proper stubbing
* Version test improvements preventing failures on every version bump

**Configuration and Path Handling**

* Path resolution fixes for cross-platform compatibility
* Config discovery improvements with proper cascade handling
* Glob pattern support in configuration files
* Regex anchor fixes in YAML config detection
* Directory reference consistency across all tools

**ace-taskflow Specific**

* Fixed `ace-taskflow task create --help` creating a task named "--help"
* Current release detection improvements
* Retrospective directory naming corrections
* Pending release direct support fixes

## [0.8.1] - 2025-09-19

### Added

#### Testing Framework Migration

* **Minitest Framework**: Complete migration from RSpec to Minitest
  * Modern testing best practices with behavior-focused approach
  * Comprehensive testing guide documenting patterns and strategies
  * Fast CLI integration tests without VCR overhead
  * Balanced mocking strategy testing real behavior
  * Minitest + Aruba + VCR combination for comprehensive coverage

#### Test Infrastructure

* **Test Suite Organization**
  * Established test directory structure (test/unit, test/integration, test/cassettes)
  * Configured Minitest with proper test_helper.rb
  * Setup Aruba for CLI testing with in-process launcher
  * Configured VCR for HTTP boundary testing
  * Created test helper utilities for common patterns

* **Comprehensive Test Migration**
  * Migrated atoms unit tests with focus on critical behaviors
  * Migrated models unit tests with data validation patterns
  * Migrated molecules unit tests emphasizing composition
  * Migrated organisms unit tests for business logic
  * Migrated ecosystems unit tests for workflow coordination
  * Fast CLI integration tests for basic command validation
  * Complex integration tests for major command scenarios

#### Architecture Improvements

* **ATOM Layer Refinement**
  * Refactored constants, middlewares, and integrations to proper ATOM layers
  * Comprehensive atom structure refactoring for ace_tools
  * Consolidate duplicate PathResolver implementations
  * Convert stateless classes to modules for Ruby idiom
  * Standardize return patterns and clarify architecture documentation

#### Developer Experience

* **Enhanced Test Reporting**
  * Agent-friendly test reporter with clear output
  * Enhanced report generation with file:line paths
  * Profiling support for performance optimization
  * Editor integration removal with simple file:line format
  * Optimized test performance with fast execution

#### Security and Quality

* **Security Hardening**
  * Fixed shell injection vulnerabilities in security validator
  * Replace broad exception handling with specific exception types
  * Improved error handling and validation

* **CLI Provider Support**
  * Enabled Claude Code and Codex CLI providers for llm-query
  * Configuration-based provider architecture
  * Enhanced LLM integration capabilities

### Changed

* **Testing Philosophy**: Shifted from 1:1 RSpec conversion to behavior-focused testing
  * Testing important behaviors rather than implementation details
  * Creating maintainable test suite with confidence over brittleness
  * Establishing patterns that make tests easy to write and understand
  * Balancing test isolation with realistic behavior testing
  * Optimizing for both developer experience and CI performance

* **Architecture Documentation**: Updated architecture guide to reflect ATOM patterns and testing framework changes

### Fixed

* **Test Reliability**: Systematic resolution of failing unit tests
* **Path Resolution**: Fixed multiple path handling and resolution issues
* **Performance**: Optimized slow atom tests with profiling fixes

## [0.7.1] - 2025-09-16

### Added

#### ACE Migration

* **Complete Project Renaming**: Comprehensive migration from old naming conventions to ACE-based structure
  * Renamed all submodule paths from `dev-*` to `.ace/*` structure
  * Renamed Ruby gem from `CodingAgentTools` to `AceTools`
  * Updated module namespace from `CodingAgentTools` to `AceTools`
  * Systematic codemod-based migration ensuring completeness

#### Path Structure Changes

* **New Directory Organization**:
  * `.ace/tools/` - Development tools and utilities
  * `.ace/handbook/` - Workflow instructions and guides
  * `.ace/taskflow/` - Task and release management
  * `.ace/local/` - Local project customizations

#### Module and Gem Renaming

* **Systematic Renaming**:
  * `CodingAgentTools` → `AceTools` (Ruby module)
  * `coding_agent_tools` → `ace_tools` (Ruby files)
  * `coding-agent-tools` → `ace-tools` (gem name)
  * Updated gem executable: `coding-agent-tools` → `ace-tools`

### Changed

* **Codebase Migration**: 5,796 path occurrences updated across 967 files
* **Module References**: 2,991 module/gem occurrences updated across 645 files
* **Total Scope**: Over 1,000+ files systematically updated with codemods

#### Migration Tools

* Created path update codemods for all file types
* Created Ruby module renaming codemods
* Created file/directory renaming scripts
* Created verification scripts for completeness

### Fixed

* **Migration Verification**: Comprehensive search-based verification ensuring no references missed
* **Test Suite**: All tests updated and passing after migration
* **Documentation**: Complete documentation update reflecting new structure

## [0.6.0] - 2025-08-05

### Added

#### Unified Claude Code Integration

* **Claude Command Structure**: Created organized directory structure for commands under `.claude/commands/`
  * Implemented hybrid system supporting both custom hand-crafted commands and auto-generated ones
  * Created clear separation between static command management and dynamic generation
  * Established versioning control for all Claude commands within dev-handbook

* **Handbook CLI Integration**: Added comprehensive Claude subcommands to handbook CLI
  * `handbook claude generate-commands` - Smart command generation from workflow instructions
  * `handbook claude validate` - Coverage checking and validation framework
  * `handbook claude integrate` - Simplified installation via copy/link operation
  * `handbook claude list` - Status overview with table format display
  * Deprecated legacy standalone Claude integration script

* **Command Generation System**: Implemented intelligent command generation from workflows
  * Auto-detection of workflow instructions requiring Claude commands
  * Template-based command generation with YAML frontmatter
  * Validation system ensuring complete coverage of workflow instructions
  * Support for custom command metadata and tool specifications

* **ATOM Architecture Implementation**: Complete refactoring to ATOM architectural patterns
  * Refactored `claude_commands_installer` to ATOM architecture
  * Refactored `handbook-claude-tools` to ATOM architecture
  * Improved code organization and maintainability
  * Enhanced test coverage and code quality

### Changed

* **Command Organization**: Unified all Claude-related commands under handbook CLI
  * Moved from auto-generated commands only to hybrid approach
  * Simplified command discovery through single interface
  * Improved documentation and user experience
  * Enhanced meta workflow for command validation

* **Installation Process**: Streamlined Claude integration installation
  * Simplified to copy/link operation from complex script execution
  * Added proper YAML frontmatter preservation
  * Improved command count display in integration output
  * Enhanced error handling and validation

### Fixed

* **Command Integration Issues**: Resolved various integration and display problems
  * Fixed invalid Claude tool specifications in command metadata
  * Fixed command count display in handbook claude integrate
  * Fixed YAML frontmatter preservation during integration
  * Addressed code style violations with RuboCop compliance

* **Test Coverage**: Systematic improvements to test suite
  * Fixed handbook Claude CLI command tests
  * Improved test coverage to 70%+
  * Systematic test suite maintenance and cleanup
  * Enhanced test reliability and consistency

### Documentation

* **Claude Integration Documentation**: Comprehensive documentation updates
  * Updated install-prompts.md with new unified process
  * Created comprehensive command reference documentation
  * Enhanced template organization and standardization
  * Updated meta workflow documentation

* **Architecture Documentation**: Enhanced technical documentation
  * Added ATOM architecture implementation guides
  * Created migration guides and reports
  * Updated development setup and usage instructions
  * Improved troubleshooting and error handling guides

## [0.4.0] - 2025-08-04

### Added

#### Comprehensive Specification Cycle Architecture

* **Idea Management System**: Created ideas-manager tool for systematic idea capture
  * Implemented `capture-it` command for quick idea capture with automatic file management
  * Added automatic commit flag support for immediate git commits
  * Enabled raw input capture at end of idea files for better context preservation
  * Created structured idea templates with metadata tracking

* **Enhanced Task Workflows**: Refactored workflow system for clear phase separation
  * Created capture-idea workflow for initial idea recording
  * Enhanced draft-task workflow for behavioral specification focus
  * Split review-task workflow into plan-task and review-task components
  * Created cascade-review workflow for managing dependent task updates
  * Updated task template structure with distinct what/how sections

* **Task Management Enhancements**: Major improvements to task-manager tool
  * Added `list` command as primary alias for improved discoverability
  * Implemented `create` subcommand for direct task creation
  * Enhanced status summary capabilities with improved formatting
  * Added draft status support for better workflow integration
  * Improved CLI consistency across all subcommands

* **Multi-Repository Management**: New tools for cross-repository operations
  * Created git-tag tool for synchronized multi-repository tagging
  * Enhanced release management with multi-repo support
  * Improved git operations across submodules

* **Claude Code Integration**: Deep integration with Claude AI assistant
  * Integrated custom Claude commands into Claude Code workflow
  * Created .claude/commands/ directory structure for custom commands
  * Developed feature-research subagent for systematic feature analysis
  * Added installation prompts and configuration management

* **Advanced Features**: Additional capability enhancements
  * Dynamic flag handling in create-path tool
  * Automated idea file management for task creation
  * Configuration-based repository filtering for git commands
  * Enhanced template organization for draft/plan workflow separation

### Changed

* **Workflow Reorganization**: Fundamental restructuring of specification process
  * Renamed draft-task workflow to better reflect behavioral specification focus
  * Reorganized task templates for clearer draft/plan separation
  * Updated all workflow references to use new terminology
  * Enhanced documentation to explain phase boundaries

* **Tool Improvements**: CLI and usability enhancements
  * Updated task-manager CLI for consistency and clarity
  * Improved ideas-manager capture command naming (capture → capture-it)
  * Enhanced create-path with dynamic flag support
  * Refined git command filtering for better control

### Fixed

* **Workflow Issues**: Resolution of process-related problems
  * Fixed task status tracking inconsistencies
  * Resolved workflow dependency conflicts
  * Corrected template path references
  * Fixed cascade review update propagation

* **Tool Bugs**: Various tool-related fixes
  * Fixed ideas-manager file naming issues
  * Resolved task-manager ID generation conflicts
  * Corrected git-tag submodule handling
  * Fixed create-path flag parsing errors

### Documentation

* **Workflow Documentation**: Comprehensive updates to workflow instructions
  * Updated all 21 workflow instructions for new phase structure
  * Created detailed cascade-review workflow documentation
  * Enhanced draft-task and plan-task workflow guides
  * Added clear phase transition documentation

* **Tool Documentation**: Enhanced tool reference materials
  * Updated task-manager documentation with new commands
  * Created ideas-manager usage guide
  * Added git-tag tool documentation
  * Enhanced Claude integration documentation

## [0.3.233] - 2025-01-30

### Added

#### Workflow Independence & AI Agent Integration System

* **Complete Workflow Self-Containment**: Refactored all 21 workflow instructions to be fully independent and self-contained for AI agent integration (Claude Code, Windsurf, Zed)
  * Implemented ADR-001: Workflow Self-Containment Principle establishing architectural guidelines
  * Created universal document embedding system supporting `<documents>` and `<templates>` XML format
  * Developed template synchronization system with automated git integration and dry-run support
  * Added XML prompt structure for code reviews with YAML frontmatter integration
  * Established standardized execution templates and project context loading patterns

#### Comprehensive Test Coverage Initiative (80%+ Coverage Achievement)

* **Massive Testing Overhaul**: Implemented comprehensive unit tests for 145+ components achieving 80%+ test coverage
  * **Atoms**: Complete test coverage for core foundation components (FileContentReader, YamlFrontmatterParser, TemplateEmbeddingValidator, SubmoduleDetector, StatusColorFormatter, DotGraphWriter)
  * **Molecules**: Comprehensive testing for business logic helpers (PathResolver, UnifiedTaskFormatter, CircularDependencyDetector, SynthesisOrchestrator, MarkdownLintingPipeline, FilePatternExtractor, TaskSortEngine, DiffReviewAnalyzer, SessionPathInferrer, StatisticsCalculator, GitDiffExtractor, ReportCollector, TaskFilterParser, TaskSortParser, ReflectionReportCollector, CommitMessageGenerator, ReportFormatter, ExecutableWrapper, TaskDependencyChecker, FileAnalyzer)
  * **Organisms**: Full test coverage for complex orchestration components (GitOrchestrator, MultiPhaseQualityManager, AgentCoordinationFoundation, SessionManager, TaskManager, ReviewManager, PromptBuilder, GoogleClient)
  * **CLI Commands**: Complete test coverage for all command interfaces (NavTree, NavLS, ReleaseCurrent, TaskReschedule, ReleaseNext, CodeReviewNew, TaskAll, ReleaseAll, LLMModels, LLMUsageReport, CoverageAnalyze, ReflectionSynthesize, GitCommit, GitRm)
  * **Models & Ecosystems**: Full coverage for data structures and workflows (LintingConfig, UsageMetadataWithCost, FormatHandlers, CoverageAnalysisWorkflow)

#### Advanced Development Tools & Features

* **Coverage Analysis Tooling**: Comprehensive coverage analysis system with adaptive thresholds
  * Standalone `coverage-analyze` executable with ATOM architecture
  * Compact range format for efficient coverage reporting
  * Adaptive threshold calculator for intelligent coverage assessment
  * Integration with SimpleCov for Ruby projects
* **Enhanced Task Management**: Multi-release support and unified formatting
  * `create-path` command for intelligent file/directory creation with metadata
  * Multi-release support for task-manager commands
  * Unified compact formatter with modification time tracking
  * Task reschedule command with advanced sorting options
* **Parallel Testing Infrastructure**: High-performance testing with SimpleCov merging
  * Parallel RSpec execution with proper coverage aggregation
  * Optimized test performance with reduced output pollution
  * Integration test suite for comprehensive path resolution testing

#### Security Framework Enhancements

* **Comprehensive Security Hardening**: Multiple vulnerability fixes and security improvements
  * Fixed YAML security vulnerability using `YAML.safe_load_file`
  * Resolved command injection vulnerabilities in git command executor
  * Implemented standardized shell command escaping with `Shellwords.escape`
  * Enhanced input sanitization across all CLI tools
  * Added comprehensive error handling tests for security-critical components

#### Release Management & Path Resolution System

* **Advanced Release Management**: Enhanced release workflow coordination
  * PathResolver integration for release-relative paths
  * Release Manager CLI with --path option for flexible release handling
  * Reflection synthesis improvements with intelligent output path logic
  * Integration test suite for path resolution consistency

### Changed

#### Architecture & Code Quality Improvements

* **ATOM Architecture Hardening**: Complete refactoring of architectural patterns
  * Consolidated task_management namespace into taskflow_management
  * Refactored CommitMessageGenerator to use direct Ruby calls
  * Improved StandardRbValidator portability by removing global state
  * Implemented separate language-specific runners for code linting
  * Standardized executable patterns using ExecutableWrapper

#### Multi-Repository Workflow Enhancements

* **Enhanced Git Operations**: Improved multi-repository coordination
  * Unified command context creation for git operations
  * Fixed main repository command context issues
  * Improved error message readability and debugging
  * Enhanced multi-repo commit workflow with proper error handling

#### Development Process Improvements

* **Testing & Quality Assurance**: Comprehensive testing infrastructure improvements
  * Consolidated test structure and eliminated duplications
  * Optimized coverage report format for size reduction
  * Enhanced VCR configuration with environment-specific header handling
  * Improved integration testing with ProcessHelpers standardization

#### Tool Migration & Modernization

* **Command Migration**: Systematic tool migration and enhancement
  * Replaced nav-path with create-path for creation operations
  * Enhanced delegation format for create-path and nav-path commands
  * Migrated deprecated tool dependencies to modern alternatives
  * Updated documentation references from bin/markdown-sync to handbook sync-templates

### Fixed

#### Critical Bug Fixes & Stability Improvements

* **Test Reliability**: Systematic resolution of failing unit tests
  * Fixed CI test failures by unifying duplicate execute_gem_executable helper methods
  * Resolved failing tests in coverage, nav-ls, and directory navigation
  * Fixed path resolution and formatter test failures
  * Addressed git command execution order issues

#### Security Vulnerability Resolutions

* **Command Injection Prevention**: Multiple security vulnerability fixes
  * Fixed command injection vulnerability in create-path command
  * Resolved encapsulation violation in create-path PathResolver access
  * Implemented comprehensive error handling for security-critical paths
  * Enhanced input validation and sanitization

#### Code Quality & Linting Issues

* **StandardRB Compliance**: Complete code quality standardization
  * Fixed all unsafe linting issues with StandardRB auto-fix
  * Resolved GFM and error handling test failures
  * Implemented proper StandardRB configuration usage
  * Enhanced language-specific file filtering for linting

#### Integration & Performance Issues

* **System Integration**: Various integration and performance improvements
  * Fixed reflection synthesize LoadError and restored functionality
  * Resolved RSpec output pollution in test suite
  * Fixed YAML date parsing in task metadata
  * Improved task ID generation and validation logic

### Security

#### Vulnerability Fixes & Hardening

* **Critical Security Improvements**: Comprehensive security vulnerability resolution
  * **CVE Fixes**: Resolved YAML.load_file security vulnerability (Task 86)
  * **Command Injection Prevention**: Fixed multiple command injection vulnerabilities (Tasks 89, 113)
  * **Input Sanitization**: Standardized shell command escaping across all tools (Task 91)
  * **Secure Coding Practices**: Enhanced input validation and sanitization framework
  * **Dependency Security**: Updated insecure dependencies and implemented secure loading patterns

#### Security Framework Implementation

* **Defense in Depth**: Multi-layer security implementation
  * Comprehensive input validation at all CLI entry points
  * Secure file path handling with traversal attack prevention
  * Enhanced error handling to prevent information disclosure
  * Standardized security logging and monitoring integration

### Performance

#### Test Performance Optimization

* **Parallel Testing**: High-performance testing infrastructure
  * Implemented parallel RSpec testing with SimpleCov merging for 40% faster test execution
  * Optimized test database handling and fixture management
  * Reduced test output pollution and improved CI performance
  * Enhanced test reliability with proper timeout and retry mechanisms

#### Coverage Analysis Optimization

* **Efficient Coverage Reporting**: Optimized coverage analysis performance
  * Implemented compact range format reducing report size by 60%
  * Added adaptive threshold system for intelligent coverage assessment
  * Optimized SimpleCov integration for large codebases
  * Enhanced coverage calculation efficiency with unified algorithms

### Documentation

#### Comprehensive Documentation Overhaul

* **Workflow Documentation**: Complete workflow instruction system overhaul
  * Updated all 21 workflow instructions for AI agent compatibility
  * Created comprehensive AI agent integration guides
  * Developed standardized template embedding format documentation
  * Added error recovery procedures and troubleshooting guides

#### Technical Documentation Enhancements

* **Development Guides**: Enhanced developer experience documentation
  * Updated testing conventions to match ATOM architecture
  * Created comprehensive tool reference documentation
  * Added version control and git workflow guides
  * Developed release codenames and project management guides

## Impact Summary

This release represents **6 months of intensive development** with:
* **225 discrete tasks** completed across all project areas
* **187 git commits** implementing comprehensive improvements
* **80%+ test coverage** achieved across entire codebase
* **Complete workflow system overhaul** for AI agent integration
* **Comprehensive security hardening** with multiple vulnerability fixes
* **Advanced tooling ecosystem** with 25+ CLI tools fully tested and documented

This is the largest and most comprehensive release in the project's history, establishing a solid foundation for future AI-assisted development workflows while maintaining the highest standards of code quality, security, and reliability.

## \[v0.3.0\] - 2025-07-24

### Added

#### Ruby Gem - Coding Agent Tools (CAT)

* **Complete 25+ CLI Tool Suite**: Comprehensive development automation toolkit
  * **Git Operations**: `git-add`, `git-commit`, `git-fetch`, `git-log`, `git-pull`, `git-push`, `git-status`, `git-checkout`, `git-switch`,
    `git-mv`, `git-rm`, `git-restore` with multi-repository support
  * **Task Management**: `task-manager next`, `task-manager recent`, `task-manager list`, `task-manager generate-id` with dependency resolution and filtering
  * **Release Management**: `release-manager current`, `release-manager next`, `release-manager all` with validation and reporting
  * **Navigation Tools**: `nav-ls`, `nav-path`, `nav-tree` with intelligent path autocorrection
  * **LLM Integration**: `llm-query` unified interface supporting Google Gemini, OpenAI, Anthropic, Mistral, Together AI, LM Studio
  * **Code Review**: `code-review`, `code-review-prepare`, `code-review-synthesize` with ATOM architecture
  * **Documentation**: `handbook sync-templates` with XML template synchronization
  * **Reflection Tools**: `reflection-synthesize` for session analysis and archival

#### ATOM Architecture Implementation

* **Atoms**: Core utilities (`XDGDirectoryResolver`, `SecurityLogger`, `EnvReader`, `FileSystemScanner`, `YamlFrontmatterParser`, `TaskIdParser`,
  `DirectoryNavigator`, `ShellCommandExecutor`)
* **Molecules**: Behavior-oriented helpers (`CacheManager`, `MetadataNormalizer`, `APICredentials`, `HTTPRequestBuilder`, `TaskSortEngine`, `TaskFilterEngine`,
  `PathResolver`)
* **Organisms**: Business logic orchestration (`GoogleClient`, `LMStudioClient`, `OpenaiClient`, `AnthropicClient`, `MistralClient`, `TogetherAiClient`,
  `TaskManager`, `ReleaseManager`, `PromptProcessor`)
* **Ecosystems**: Complete workflow coordination with system-level integration
* **Models**: Pure data carriers (`LlmModelInfo`, `ParseResult`, `ReviewSession`, `ReviewTarget`, `ReviewPrompt`)

#### Multi-Provider LLM Integration

* **Google Gemini**: Full API integration with model discovery and cost tracking
* **OpenAI**: Complete GPT model support with token usage parsing
* **Anthropic Claude**: Claude model integration with comprehensive metadata
* **Mistral**: Mistral AI model support with unified interface
* **Together AI**: Together AI integration with model listing
* **LM Studio**: Local LLM support for offline development
* **Unified Interface**: Single `llm-query` command with provider:model syntax
* **Cost Tracking**: Comprehensive usage tracking with LiteLLM pricing database
* **Dynamic Aliases**: Provider shortcuts (e.g., gflash, csonet) for rapid access

#### Security Framework

* **Multi-Layer Security**: Path validation, sanitization, and secure logging
* **SecurePathValidator**: Directory traversal attack prevention
* **FileOperationConfirmer**: Interactive overwrite confirmation system
* **Secrets Scanning**: Gitleaks integration for local development security
* **XDG Compliance**: Standard-compliant caching with automatic migration

#### Development Infrastructure

* **ExecutableWrapper**: Standardized CLI executable framework
* **VCR Integration**: HTTP interaction recording for testing
* **Aruba Testing**: CLI integration testing framework
* **ProjectRootDetector**: Intelligent project root detection
* **BinstubInstaller**: Automated shell integration system
* **CI-Aware Configuration**: Robust testing in CI/CD environments

#### Task Management System

* **Dependency Resolution**: Topological sorting for task dependencies
* **Filtering & Sorting**: Advanced task filtering by status, priority, implementation order
* **Multi-Format Output**: JSON and text output formats for integration
* **Path Resolution**: Intelligent task file location detection
* **ID Generation**: Automated unique task ID generation with validation

#### Template Synchronization

* **XML Template Support**: `<documents>` and `<templates>` format support
* **Embedded Document Sync**: Automatic synchronization of embedded templates
* **Git Integration**: Automated commit functionality for template changes
* **Dry-Run Support**: Preview mode for template synchronization

### Changed

* **Migration from Shell Scripts**: Converted 20+ shell scripts to robust Ruby CLI tools
* **Unified Command Interface**: Consolidated multiple LLM provider commands into single `llm-query` interface
* **Enhanced Git Workflow**: Multi-repository operations with intelligent commit message generation
* **Improved Path Resolution**: Context-aware path handling for nested repository structures
* **Standardized CLI Patterns**: Consistent command structure across all tools
* **Enhanced Documentation**: Comprehensive tool reference with persona-based organization

### Fixed

* **Thread Synchronization**: Resolved concurrent git operation issues
* **Path Detection**: Fixed git command path detection for nested directories
* **URL Construction**: Corrected Gemini API URL construction for model info
* **Template Synchronization**: Resolved template sync errors and improved logging
* **Memory Management**: Fixed memory leaks in background processing
* **Test Reliability**: Optimized test performance and eliminated CI fragility

### Security

* **Path Traversal Protection**: Comprehensive validation against directory traversal attacks
* **Secure Credential Handling**: Environment-based API key management with validation
* **Input Sanitization**: Multi-layer input validation and sanitization
* **Secrets Detection**: Integrated Gitleaks for local secrets scanning

## \[v0.4.0\] - 2025-06-25

### Added

* Enhanced initialize-project-structure workflow with v.0.0.0 template release tracking
  * Created template v.0.0.0 release structure in dev-handbook/guides/initialize-project-templates/
  * Added template copying and customization logic for new projects
  * Integrated roadmap creation into project initialization process
  * Included clear user guidance for post-initialization steps

### Changed

* Renamed manage-roadmap workflow to update-roadmap for improved clarity
  * Updated all references across the codebase
  * Enhanced workflow with cleanup functionality for completed releases
* Improved roadmap management with post-release cleanup integration
  * Added cleanup step to remove completed releases from roadmap
  * Updated step numbering and error handling procedures

## \[v.0.2.0\] - 2025-01-15

### Added

* **Initial LLM Integration**: Foundation for multi-provider LLM communication
* **ATOM Architecture**: Established Atoms, Molecules, Organisms, Ecosystems pattern
* **Ruby Gem Structure**: Core gem foundation with dry-cli framework
* **Basic Git Tools**: Initial git command enhancements
* **Testing Infrastructure**: RSpec, VCR, and Aruba testing setup
* **CI/CD Pipeline**: GitHub Actions workflow with multi-Ruby testing

### Changed

* **Project Structure**: Migrated from shell scripts to Ruby gem architecture
* **Development Workflow**: Established standardized development processes

## \[v.0.1.0\] - 2024-12-01

### Added

* **Project Foundation**: Initial Ruby gem structure with ATOM architecture
* **Build System**: Comprehensive build, test, and lint infrastructure
* **Development Guides**: Git workflow and contribution guidelines
* **Documentation Framework**: Architecture and blueprint documentation

## \[v.0.0.0\] - 2024-11-01

### Added

* **Project Initialization**: Basic project structure and documentation
* **Git Submodules**: Multi-repository coordination setup
* **Initial Documentation**: PRD, roadmap, and architectural decisions

## \[v.0.3.0-workflows\] - 2025-06-04

### v.0.3.0+tasks.24 - 2025-06-02 - Implement Roadmap Release Lifecycle Management

* **Enhanced manage-roadmap workflow with release lifecycle integration** to automatically maintain roadmap accuracy:
  * | Added step 3 (Update Release Status) to check release folder locations (backlog | current | done) and update roadmap accordingly |
  
  * Added step 7 (Validate Synchronization) to ensure roadmap matches project folder structure and validate cross-references
  * Enhanced with comprehensive error handling for format validation, file system inconsistencies, and commit failures
  * Added cross-workflow dependency documentation specifying integration with draft-release and publish-release workflows
* **Updated draft-release workflow** to include roadmap management:
  * Added step 7 to update roadmap with new release information after release scaffolding completion
  * Integrated separate roadmap commit with standardized message format
  * Added roadmap update validation to success criteria
* **Updated publish-release workflow** to include roadmap cleanup:
  * Added step 15 to remove completed releases from roadmap during documentation archival phase
  * Implemented roadmap cleanup with cross-reference dependency updates
  * Enhanced critical success criteria to include roadmap accuracy validation
* **Enhanced roadmap definition guide** with comprehensive release lifecycle specifications:
  * Added release status tracking format specifying how releases should be represented based on folder location
  * Created systematic release removal process with validation checklist
  * Documented integration triggers specifying when roadmap updates occur during release workflows
  * Added comprehensive error handling and recovery procedures for failed roadmap updates
  * Established cross-workflow dependencies and validation requirements for release lifecycle management

### v.0.3.0+tasks.22 - 2025-06-02 - Create Roadmap Definition Guide

* **Created comprehensive roadmap definition guide** at `dev-handbook/guides/roadmap-definition.g.md`:
  * Established deterministic format requirements for all roadmap sections (Front Matter, Project Vision, Strategic Objectives, Key Themes & Epics, Planned
    Major Releases, Cross-Release Dependencies, Update History)
  * Defined precise table format specifications with column definitions and validation criteria
  * Created content guidelines and best practices for writing style, strategic alignment, and maintenance
  * Added validation criteria for structure, content, and quality compliance
  * Provided concrete examples demonstrating correct and incorrect roadmap formatting
  * Documented integration guidelines for workflow instructions to reference format requirements
* **Separated format specification from workflow process** following separation of concerns principle:
  * Removed embedded format rules from manage-roadmap workflow instruction
  * Established pattern for workflows to reference dedicated format guide rather than embedding specifications
  * Created foundation for consistent roadmap format validation across all related workflows

### v.0.3.0+tasks.16 - 2025-06-02 - Implement Agreed Naming Conventions for Guides and Workflow Instructions

* **Implemented file extension conventions** to establish clear distinction between guides and workflow instructions:
  * Applied `.wf.md` suffix to all 21 workflow instruction files (breakdown-notes-into-tasks, commit, create-adr, create-api-docs, create-reflection-note,
    create-release-overview, create-retrospective-document, create-review-checklist, create-test-cases, create-user-docs, draft-release, fix-tests,
    initialize-project-structure, load-env, save-session-context, manage-roadmap, publish-release, review-task, review-tasks-board-status, update-blueprint,
    work-on-task)
  * Applied `.g.md` suffix to all guide files with noun-based naming (changelog, coding-standards, documentation, error-handling, performance,
    project-management, quality-assurance, security, strategic-planning, temporary-file-management, testing, release-codenames, release-publish,
    testing-tdd-cycle, debug-troubleshooting, version-control-system, task-definition)
  * Moved and renamed workflow-specific guides: embedding-tests-in-workflows → .meta/workflow-embedding-tests.g.md, tools-guide → .meta/tools.g.md
* **Updated meta-documentation** to reflect new naming conventions:
  * Enhanced `dev-handbook/guides/.meta/writing-guides-guide.md` with `.g.md` convention documentation and noun-based naming examples
  * Enhanced `dev-handbook/guides/.meta/writing-workflow-instructions-guide.md` with `.wf.md` convention documentation and verb-first naming pattern
* **Fixed internal documentation links** throughout the codebase:
  * Updated all cross-references in workflow instructions and guides to use new `.wf.md` and `.g.md` filenames
  * Corrected relative paths in test-driven-development-cycle documentation
  * Verified link integrity with zero critical broken links remaining
* **Created Zed editor rule mapping documentation** for manual updates to development environment integration

### v.0.3.0+tasks.15 - 2025-06-01 - Rename "Prepare Release" to "Draft Release" and Ensure Independence from "Publish Release"

* **Renamed prepare-release to draft-release throughout codebase** for clearer separation from publish-release process:
  * Renamed `dev-handbook/workflow-instructions/prepare-release.md` to `dev-handbook/workflow-instructions/draft-release.md`
  * Renamed `dev-handbook/guides/prepare-release/` directory to `dev-handbook/guides/draft-release/`
  * Updated 147+ references across workflow instructions, guides, session files, and current tasks
* **Established complete independence between draft-release and publish-release processes**:
  * Removed inappropriate references to draft-release from publish-release documentation
  * Removed draft-release prerequisites from publish-release workflow instructions
  * Added clarifying note in draft-release.md explaining scope distinction from publish-release
* **Reorganized documentation structure** for better logical organization:
  * Split guides README.md into separate "Draft Release Management" and "Publish Release Management" sections
  * Restructured workflow instructions README.md with improved section hierarchy (Core Workflow, Project Initialization, Draft Releases, Testing, Project
    Management, Publish Release)
  * Added all missing guides to guides README.md including language-specific sub-guides and project initialization templates
* **Clarified process separation**: Draft Release focuses on creating and planning new releases in backlog, while Publish Release handles finalizing and
  deploying completed releases

### v.0.3.0+tasks.14 - 2025-06-01 - Define and Document "Publish Release" Process and Guide

* **Created comprehensive publish release process** replacing ship-release terminology:
  * `dev-handbook/guides/publish-release.md` - Detailed guide explaining release publishing philosophy, semantic versioning scheme (v<major>.<minor>.<patch>
    extracted from release folder names), and archival process from `dev-taskflow/current/` to `dev-taskflow/done/`</patch></minor></major>
  * `dev-handbook/workflow-instructions/publish-release.md` - Step-by-step workflow instruction for executing the complete publish release process including
    version finalization, package publication, documentation archival, and stakeholder communication
  * `dev-handbook/guides/changelog-guide.md` - Comprehensive changelog writing guide following Keep a Changelog format with project-specific adaptations and
    integration guidelines
* **Replaced ship-release terminology throughout codebase**:
  * Deleted `dev-handbook/workflow-instructions/ship-release.md` and `dev-handbook/guides/ship-release.md` files
  * Moved `dev-handbook/guides/ship-release/` directory to `dev-handbook/guides/publish-release/` with updated language-specific examples (ruby.md, rust.md,
    typescript.md)
  * Updated all references from "ship-release" to "publish-release" across documentation files, workflow instructions, and guides
* **Enhanced versioning documentation**:
  * Updated `dev-handbook/guides/version-control.md` with semantic versioning scheme documentation and examples showing version extraction from release folder
    names
  * Updated `dev-handbook/guides/project-management.md` with archival process description and consistent publish release terminology
* **Integrated technology-agnostic approach** supporting diverse project types through `bin/build` execution and flexible package publication processes
* **Established clear process separation** between preparation (handled by existing prepare-release workflow) and final deployment/archival (handled by new
  publish-release process)

### v.0.3.0+tasks.12 - 2025-06-01 - Remove Checkboxes from Guides and Workflow Instructions; Clarify Use of Acceptance Criteria

* **Converted inappropriate interactive checklists to bullet points** in guides:
  * `dev-handbook/guides/version-control.md` - Changed PR template example from checkboxes to bullet points
  * `dev-handbook/guides/security.md` - Converted security review checklist from interactive checkboxes to informational bullet points with bold headers
* **Enhanced meta documentation** with comprehensive checkbox usage guidelines:
  * `dev-handbook/guides/.meta/writing-guides-guide.md` - Added detailed section on appropriate vs inappropriate checkbox usage, with examples of when
    checkboxes are legitimate (templates, examples) vs inappropriate (interactive checklists)
  * `dev-handbook/guides/.meta/writing-workflow-instructions-guide.md` - Added "List Formatting in Workflows" section clarifying that Success Criteria should
    use simple bullet points, Process Steps should use numbered lists, and checkboxes are only appropriate in templates/examples
* **Standardized all workflow instruction Success Criteria** to use simple bullet points instead of checkboxes across 11 workflow files: `create-user-docs.md`,
  `create-test-cases.md`, `create-retrospective-document.md`, `create-release-overview.md`, `create-api-docs.md`, `create-adr.md`, `commit.md`,
  `create-review-checklist.md`, `review-tasks-board-status.md`, `create-reflection-note.md`, `prepare-release.md`
* **Converted Process Steps in ship-release.md** from checkboxes to numbered steps (1-24) for better sequential execution guidance
* **Established clear distinction** between reference documentation (guides) and actionable content (tasks), preventing AI agents from treating guides as
  interactive checklists while preserving legitimate checkbox usage in templates and examples

### v.0.3.0+tasks.11 - 2025-06-01 - Clarify Policy on Updating "Done" Tasks if Referenced Files Change

* Added comprehensive policy section to `dev-handbook/guides/project-management.md` under Agent Operational Boundaries
* Defined clear distinction between prohibited modifications (content changes, historical revisions, status changes) and allowed reference updates (broken link
  fixes, security annotations, accessibility improvements)
* Established process requirements for human updates including justification, additive approach, history preservation, clear attribution, and minimal scope
* Provided concrete examples of acceptable vs unacceptable modifications to done tasks
* Maintains balance between preserving historical accuracy and ensuring practical usability of project documentation

### v.0.3.0 - 2025-06-01 - Enhance Review Task Workflow for New Task Structure

* Updated the `review-task.md` workflow instruction to incorporate the new Planning Steps and Execution Steps structure for tasks.
* Added steps to the review process to evaluate task structure, recommend using Planning Steps for complex tasks, and suggest adding embedded tests.
* Ensured the workflow guides reviewers to maintain consistency with the updated task template and standards.

### v.0.3.0+tasks.10 - 2025-06-01 - Refine Task Template to Include Distinct "Plan" and "Execution" Sections

* Updated the task template (`dev-handbook/guides/prepare-release/v.x.x.x/tasks/_template.md`) to include separate "Planning Steps" (`* [ ]`) and "Execution
  Steps" (`- [ ]`) subsections within the "Implementation Plan".
* Updated the `write-actionable-task.md` guide to document the new structure, explaining the rationale, visual distinction, when to use planning steps, and how
  it relates to workflow phases (review vs. work).
* Added examples to the guide demonstrating tasks with only execution steps and tasks with both planning and execution steps, including embedded tests in both
  sections.

### v.0.3.x+task.8 - 2025-06-01 - Refine Initialize Project Test Task and Create Review Roadmap Task

* Updated `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/008-test-initialize-project.md` to align its scope with the "Initialize Project
  Structure" workflow, specifically excluding the creation of `roadmap.md` and initial release scaffolding.
* Created new task `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/v.0.3.0+task.21.md` to review the `manage-roadmap.md` workflow instruction,
  following the guide for writing actionable tasks.

### v.0.3.x - 2025-05-30 - Standardize Binstub Location and Rename gat to tal

* Renamed the `bin/gat` wrapper script to `bin/tal`.
* Updated documentation and task references for the `bin/gat` -> `bin/tal` rename.
* Added binstub scripts for `tnid`, `rc`, and `tal` to `dev-tools/exe-old/_binstubs/`.

### v.0.3.x - 2025-05-30 - Incorporate Codename Picking Guide into Prepare Release Workflow

### v.0.3.x+task.20 - 2025-05-30 - Improve Initialize Project Structure Workflow

* **Refactored `initialize-project-structure.md` Workflow:**
  * Added explicit idempotency statement to clarify rerun behavior.
  * Streamlined the workflow by removing the redundant "Initialize Version Control" (formerly Step 3) and the "Tailor Development Guides" (formerly Step 4)
    steps.
  * Renumbered the steps to reflect the removal of the two steps.
  * Enhanced the "Core Documentation Generation" step to reference new templates and include improved example questions for interactive prompts.
  * Updated the "Setup Project `bin/` Scripts" step (now Step 3) to refer to the `dev-taskflow/architecture.md` for binstub explanations.
* **Created New Project Initialization Templates:**
  * Added `dev-handbook/guides/initialize-project-templates/PRD.md` with a basic PRD structure.
  * Added `dev-handbook/guides/initialize-project-templates/README.md` with a basic README structure.
  * Added `dev-handbook/guides/initialize-project-templates/blueprint.md` based on the current project's blueprint structure.
  * Added `dev-handbook/guides/initialize-project-templates/architecture.md` based on the current project's architecture structure, including binstub
    explanations.
  * Added `dev-handbook/guides/initialize-project-templates/what-do-we-build.md` based on the current project's what-do-we-build structure.
* **Created New Guide for Codenames:**
  * Added `dev-handbook/guides/picking-codenames.md` with guidance on choosing themes, length, and uniqueness for project codenames.

### v.0.3.x - 2025-05-30 - Standardize Task ID Generation and Consolidate Task Templates

* **Task ID Generation Standardization:**
  * Updated `dev-handbook/guides/write-actionable-task.md`, `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md`, and
    `dev-handbook/guides/project-management.md` to mandate the use of the `bin/tnid` script for generating task IDs. This ensures unique, correctly formatted,
    and sequentially numbered task IDs.
* **Task Template and Example Consolidation:**
  * Moved the canonical task template to `dev-handbook/guides/prepare-release/v.x.x.x/tasks/_template.md`.
  * Relocated the full worked task example to `dev-handbook/guides/prepare-release/v.x.x.x/tasks/_example.md`.
  * Updated `dev-handbook/guides/write-actionable-task.md` to remove the embedded template and example, now linking to these new centralized locations. This
    streamlines task creation and ensures a single source of truth for the task structure.

### v.0.3.0+task.19 - 2025-05-28 - Fix Markdown Lint Errors

* **Documentation Quality Improvements:**
  * Fixed final markdown lint errors in `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/018-add-tool-for-getting-release-path.md`
  * Resolved MD013 line length violations by appropriately breaking long lines to comply with 120-character limit
  * Completed processing of all 81 markdown files in the project
* **Task Management:**
  * Updated task file checklist to mark final file as completed
  * Marked all scope of work items, deliverables, and acceptance criteria as completed
  * Changed task status from "in-progress" to "done"
* **Quality Assurance:**
  * All markdown files now pass `bin/lint` markdownlint checks
  * Project documentation now maintains consistent formatting standards
  * Improved documentation readability and compliance with style guidelines

### v.0.3.0+task.18 - 2025-05-27 - Add Tool for Getting Current Release Path and Version

* **Created New Development Tools:**
* Added `dev-tools/exe-old/get-current-release-path.sh` - Main tool script that determines the appropriate directory for storing newly created tasks and returns
  version information.
* Added `bin/rc` - Thin wrapper script for easy access to the get-current-release-path utility.
* Added `dev-tools/exe-old/test-get-current-release-path.sh` - Comprehensive test suite with 13 test assertions covering 5 test scenarios.

* **Tool Functionality:**
* Returns path to current release directory (e.g., `dev-taskflow/current/v.X.Y.Z-codename`) and version string (e.g., `v.X.Y.Z`) when a current release exists.
* Returns backlog tasks path (`dev-handbook/backlog/tasks`) and empty version when no current release is detected.
* Handles edge cases like multiple release directories gracefully.
* Includes help option and proper error handling for invalid arguments.

* **Workflow Integration:**
* Updated `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md` to utilize the new `bin/rc` tool in Step 6 for determining task storage location.
* Added instructions for creating necessary directories before saving task files.
* Integrated version information access for potential use in task metadata or naming.

* **Quality Assurance:**
* All automated tests pass, covering current release detection, backlog fallback, multiple directories, help functionality, and error handling.
* Tool correctly identifies and works with the actual project structure (`dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2`).

### v.0.3.x-fix - 2025-05-27 - Update Breakdown Notes to Tasks Workflow

* Updated the `breakdown-notes-into-tasks.md` workflow instructions.
* Added clarification on where formal task files should be stored (current release `tasks/` directory or `dev-handbook/backlog/tasks/`).
* Introduced a new Step 6 to formalize the task structure according to the `write-actionable-task.md` guide after user verification.
* Reviewed and updated the workflow's goal, inputs, process steps, output, and success criteria for consistency.

### v.0.3.0+task.7 - 2025-05-27 - Add .meta/ Subdirectories for Self-Referential Workflows and Guides

* Created the `.meta/` subdirectories within `dev-handbook/guides/` and `dev-handbook/workflow-instructions/`.
* Moved the `writing-guides-guide.md`, `writing-workflow-instructions.md` (and renamed it to `writing-workflow-instructions-guide.md`), and `tools-guide.md`
  files into `dev-handbook/guides/.meta/`.
* Updated all internal links within the project that pointed to these moved guide files.
* Added documentation explaining the purpose and usage of the `.meta/` directories in `dev-handbook/README.md`.
* Verified internal links using the lint tool.

### v.0.3.0+task.5 - 2025-05-27 - Ensure Uniqueness and Consistency of Task IDs and Release Versioning (and Tooling Fixes)

* **Task ID and Release Versioning Standardization**:
  * Implemented new task ID convention: `v.X.Y.Z+task.<sequential_number>`.
  * Standardized release directory naming to `v.X.Y.Z-codename`.
* **Tooling Enhancements & Fixes**:
  * Added `bin/tnid` (`dev-tools/exe-old/get-next-task-id`) to generate the next unique task ID.
  * Added `bin/gat` (`dev-tools/exe-old/get-all-tasks`) to list all tasks in a release, sorted by dependencies and highlighting the next actionable one.
  * Added `dev-tools/exe-old/lint-task-metadata` script (integrated into `bin/lint`) to validate task metadata against new conventions.
  * Modified `bin/tn` (`dev-tools/exe-old/get-next-task`) to correctly sort task IDs numerically and prioritize `in-progress` tasks.
  * Updated `dev-handbook/guides/tools-guide.md` with refined principles for path conventions, testing, and binstub simplicity.
  * Corrected path usage, regdev-tools/exes for version parsing, and fixed bugs in the newly created/modified tools (`get-next-task-id`, `get-all-tasks`,
    `lint-task-metadata`) and their binstubs (`bin/tnid`, `bin/gat`).
  * Fixed minor errors in `bin/lint` script.
* **Documentation Updates**:
  * Updated `dev-handbook/guides/project-management.md` with new task ID convention, release folder naming, and tool information.
  * Updated `dev-handbook/guides/write-actionable-task.md` with new task ID format in templates/examples.
  * Updated `dev-handbook/workflow-instructions/prepare-release.md` to reflect new ID generation and versioning. versioning.

### **Minor Fix:**

* Bring back the directory `dev-handbook/workflow-instructions/breakdown-notes-into-tasks`, deleted in 33af0d94cb0598baa4b5d36b8ffd273d3b8ebcc8

### v.0.3.x-4 - 2025-05-27 - Implement Immutability Rules for Specified Paths via Agent Blueprint

* **Agent Operational Boundaries:**
  * Added "Read-Only Paths" and "Ignored Paths" sections to `dev-taskflow/blueprint.md` to define file access rules for the agent.
    * Populated "Ignored Paths" with default common patterns (e.g., `dev-taskflow/done/**/*`, `**/node_modules/**`).
    * Added project-specific "Read-Only Paths" (e.g., `dev-taskflow/releases/**/*`, `docs/decisions/**/*`).
  * Updated `dev-handbook/workflow-instructions/initialize-project-structure.md` to include these new sections and their default content when generating a new
    `blueprint.md`.
  * Added a new "Agent Operational Boundaries" section to `dev-handbook/guides/project-management.md` to explain the purpose of these blueprint configurations
    and refer to `dev-taskflow/blueprint.md` for details.

### v.0.3.x-3 - 2025-05-27 - Establish Guidelines for Temporary File Usage by AI Agent

* **Temporary File Usage Guidelines:**
  * Defined criteria for appropriate use of temporary files by the agent.
  * Specified recommended locations, naming conventions, and cleanup responsibilities for temporary files.
  * Documented these guidelines in `dev-handbook/guides/temporary-file-management.md` and updated relevant links.
* **Development Cycle Documentation Refinement:**
  * Renamed `dev-handbook/guides/task-cycle.md` to `dev-handbook/guides/test-driven-development-cycle.md`.
  * Renamed directory `dev-handbook/guides/task-cycle/` to `dev-handbook/guides/test-driven-development-cycle/`.
  * Updated all internal references to these renamed paths.
  * Deleted redundant `dev-handbook/guides/testing/test-cycle.md`.

### v.0.3.x-2 - 2025-05-27 - Design a Standard for Incorporating Tests into AI Agent Workflows

* **Workflow Testing Standard:**
  * Defined a standard for embedding tests (`> TEST:`, `> VERIFY:`) in workflow instruction files.
  * Created `dev-handbook/guides/embedding-tests-in-workflows.md` detailing the standard.
  * Updated `dev-handbook/guides/writing-workflow-instructions.md` to reference the new testing guide.
  * Added a proposed `bin/test` script to `dev-taskflow/architecture.md`.
  * Integrated the testing standard into `dev-handbook/guides/write-actionable-task.md`, `dev-handbook/workflow-instructions/work-on-task.md`, and
    `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md`.

### v.0.3.x-13 - 2025-05-26 - Create `bin/` Aliases for Common Development Commands

* **Standardized `bin/` Commands:**
  * Introduced top-level `bin/test`, `bin/lint`, `bin/build`, and `bin/run` alias scripts.
  * These scripts wrap underlying project-specific commands for consistent developer experience.
  * Created placeholder binstub templates in `dev-tools/exe-old/_binstubs/` for new projects.
  * Documented the new `bin/` aliases.

### v.0.3.x-6 - 2025-05-26 - Merge tools and utils Directories

* **Tooling Structure Refinement:**
  * Merged `dev-handbook/utils` directory into `dev-tools/exe-old`.
  * Renamed scripts in `dev-tools/exe-old` to follow a verb-prefix naming convention (e.g., `recent-tasks` to `get-recent-tasks`).
  * Updated all internal and external references to the old script paths and names.
* **Minor Cleanup:**
  * Deleted duplicate directory `dev-handbook/workflow-instructions/breakdown-notes-into-tasks`.

* * *

## 2025-05-26

* Updated submodules for documentation.
* Rewrote `prepare-release` workflow.
* Scaffolded `v.x.y.z-ideas-after-toolkit-meta` release.
* Marked preflight task as "someday".
* Prepared release `v0.2.22`.

## 2025-05-09

* **Added:**
  * FAQ section to `README.md`.
  * `package-lock.json` to track dependencies.
  * `package.json` to define devDependencies.
* **Changed:**
  * Updated submodule commits.

## 2025-05-08

* **Added:**
  * `create-reflection-note` workflow.
* **Changed:**
  * Reviewed and restructured project management workflows.
  * Split Task `v.0.2.3-18` (Review and Restructure Project Management Workflows) into Plan & Execute phases.
  * Improved usage examples in `README.md` including initializing project structure, breaking down ideas into tasks, reviewing tasks, and working on tasks.
  * Drafted initial `README.md` content for the Coding Agent Workflow Toolkit, explaining key components, purpose, and setup.
  * Updated documentation subprojects.

## 2025-05-07

* **Changed:**
  * Updated `dev-taskflow` to `v0.2.3-17` which refactored documentation generation workflows. This includes:
    * Flattening the `dev-handbook/workflow-instructions/docs/` subdirectory.
    * Renaming documentation generation workflows to `create-<context>.md` (e.g., `create-adr.md`, `create-api-docs.md`).
    * Updating H1 titles and internal links.
  * Corrected introductory sentences in documentation to reference `breakdown-notes-into-tasks.md`.
  * Updated references to old workflow names.

* * *

## Prior to 2025-05-07 (Based on Release Summaries)

Changes in this period are summarized by their release version.

### Release v.0.2.3 (Feedback After Zed Extension)

(Corresponds to tasks completed around and before 2025-05-07, many of which are reflected in the 2025-05-07 and 2025-05-08 git logs)

* **Documentation Standardization:**
  * Refactored developer guides and workflow instructions by technology stack (Ruby, Rust, TypeScript). (Task `01-tailor-guides-tech-stack`,
    `07-tailor-workflow-instructions-tech-stack`)
  * Implemented consistent naming conventions for release documents (`02-release-doc-naming-consistency`), workflow instructions
    (`09-define-apply-workflow-naming-convention`), and task IDs (`08-define-task-id-convention`).
* **Workflow Streamlining:**
  * Consolidated task specification workflows (`lets-spec-*`) into `prepare-tasks` (now `breakdown-notes-into-tasks`). (Task `03-consolidate-spec-workflows`,
    `16-review-simplify-prepare-tasks-workflow`)
  * Reviewed, refined, and renamed core workflows:
    * `lets-start` to `work-on-task`. (Task `10-review-rename-lets-start-workflow`)
    * `lets-tests` (merged into `work-on-task`). (Task `11-review-lets-tests-workflow`)
    * `lets-fix-tests` to `fix-tests`. (Task `12-review-lets-fix-tests-workflow`)
    * `lets-release` reviewed (Task `13-review-lets-release-workflow`), leading to new `ship-release` workflow.
    * `init-project` to `initialize-project-structure`. (Task `14-review-rename-init-project-workflow`)
    * `generate-blueprint` reviewed and renamed. (Task `15-review-rename-generate-blueprint-workflow`)
    * Clarified and restructured project management (`review-tasks-board-status`) and reflection (`save-session-context`, `create-retrospective-document`)
      workflows. (Task `18-review-restructure-project-management-workflows`)
  * Reviewed and restructured documentation generation workflows (Task `17-review-documentation-generation-workflows` - details in 2025-05-07 log).
* **Project Planning & Execution Enhancements:**
  * Defined and implemented a project roadmap (`dev-taskflow/roadmap.md`) and strategic planning process (`dev-handbook/guides/strategic-planning-guide.md`,
    `dev-handbook/workflow-instructions/manage-roadmap.md`). (Task `20-define-roadmap-and-strategic-planning`)
  * Mandated and defined a structured "Implementation Plan" section within task files (`dev-handbook/guides/write-actionable-task.md`). (Task
    `21-define-embedded-plan-structure`)
  * Created a new `ship-release` workflow. (Task `22-create-ship-release-workflow`)
* **Documentation Quality & Structure Improvements:**
  * Created guides for troubleshooting (`dev-handbook/guides/troubleshooting-workflow.md`). (Task `04-high-level-dev-debug-workflow`)
  * Created guide for task implementation cycle (`dev-handbook/guides/test-driven-development-cycle.md`). (Task `05-support-writing-workflow-guide`)
  * Split testing guides by technology. (Task `06-split-testing-guides-by-tech`)
  * Reviewed and improved `prepare-release` templates. (Task `19-review-prepare-release-templates`)

### Release v-0.2.2 (Feedback to Process)

* Clarified "Command" terminology in documentation, replacing it with "Workflow Instruction".
* Updated development guides with research insights on AI-assisted development, prompting, and general best practices.
* Created a new guide on "Writing Workflow Instructions".

### Release v.0.2.1 (Spec from Diff)

* Introduced the `lets-spec-from-git-diff` workflow instruction to analyze git diffs and generate structured feedback and task specifications.

### Release v.0.2.0 (Dev Docs Review - Streamline Workflow)

* **Unified Task Management:** Solidified a single task management system using structured Markdown files in `dev-taskflow/{backlog,current,done}`. Removed the
  experimental `project/task-manager`.
* **Simplified Release Documentation:** Provided clearer guidelines for documentation required for different release types (Patch, Feature, Major).
* **Workflow Consistency:** Ensured consistent terminology and aligned Kanban board references. Commands were updated to link to guides rather than duplicating
  content.
* **Integrated Best Practices:** Incorporated research on "planning before coding" and structured task details into guides.
* Updated and created various workflow instructions (`load-env`, `work-on-task`, `lets-spec-from-pr-comments`, `review-kanban-board`, `self-reflect`,
  `lets-release`, `log-session`, `generate-blueprint`, `lets-spec-from-release-backlog`) to align with the unified system.
* Updated core guides (`project-management.md`, `ship-release.md`, `unified-workflow-guide.md`) and introduced a project blueprint.
* Separated context loading (`load-env`) from task execution (`work-on-task`).

### Release v.0.0.1 (Initial Release)

* Established initial project infrastructure.
* Set up the project structure and documentation framework.
* Documented the initial release process.
