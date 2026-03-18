# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.29.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.29.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.28.8] - 2026-03-18

### Changed
- Clarified that task-planning Claude native `--permission-mode plan` configuration is workflow-specific and not equivalent to the shared `ace-llm` `@ro` execution preset.

## [0.28.7] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.28.6] - 2026-03-13

### Changed
- Clarified draft task handling in `task/work` workflow for unattended/fork contexts — the assignment creation layer is now responsible for blocking draft tasks before they reach the workflow.

## [0.28.5] - 2026-03-13

### Technical
- Updated canonical task skills to support unified skill + workflow execution patterns.

## [0.28.4] - 2026-03-13

### Changed
- Updated canonical task, bug, docs, retro, idea, and test skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.28.3] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-task-finder` and `as-task-work` skills so provider projections now inherit the canonical skill body unchanged.

## [0.28.2] - 2026-03-12

### Fixed
- Restored the Codex model override on the canonical `as-task-work` skill so the generated Codex projection uses `gpt-5.3-codex-spark` consistently with the other fork-context skills.

## [0.28.1] - 2026-03-12

### Changed
- Updated task and bug workflow guidance to reference bundle-first follow-up workflows and current canonical handbook path examples.

## [0.28.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-release-navigator` and `as-task-finder` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

## [0.27.1] - 2026-03-12

### Fixed
- Removed the mistaken provider-specific model override from the canonical `as-task-work` skill so task work projections keep their intended shared metadata.

## [0.27.0] - 2026-03-10

### Added
- Added canonical handbook-owned release navigator and task finder skills with package workflows for release/task discovery.


## [0.26.1] - 2026-03-10

### Fixed
- Added missing canonical `# bundle:` and `# agent:` metadata to migrated task workflow skills so they pass the strict `SKILL.md` schema introduced with typed canonical skills.

## [0.26.0] - 2026-03-09

### Added
- Added canonical workflow skills for migrated task-domain capabilities under `handbook/skills/`, including bug/docs/idea/retro/task/test flows (`as-bug-*`, `as-docs-update-*`, `as-idea-*`, `as-retro-*`, `as-task-*`, `as-test-*`).

### Changed
- Expanded `skill://` canonical discovery coverage for `ace-task` from a single seed skill to a broader typed workflow set.


## [0.25.0] - 2026-03-09

### Added
- Marked `as-task-plan` skill as assign-capable with `assign.source` metadata

## [0.24.0] - 2026-03-09

### Added
- Added `skill-sources` gem defaults registration at `.ace-defaults/nav/protocols/skill-sources/ace-task.yml` so `skill://` can discover canonical `handbook/skills` entries from `ace-task`.

## [0.23.0] - 2026-03-09

### Added
- Added canonical workflow skill example at `handbook/skills/as-task-plan/SKILL.md` with execution binding to `wfi://task/plan`.

## [0.22.2] - 2026-03-08

### Technical
- Updated project-management and roadmap handbook references to use the canonical `release/publish` workflow name and `wfi://release/publish` URI.

## [0.22.1] - 2026-03-08

### Fixed
- Removed stale `task.plan.cli_args` provider mapping from `ace-task plan`; model selection now relies on `provider:model@preset` directly.

## [0.22.0] - 2026-03-08

### Changed
- Remove hardcoded `providers.cli_args` config; use ace-llm `@preset` suffixes for provider permission flags

## [0.21.0] - 2026-03-07

### Added
- `task/work` workflow sub-phase sequence now includes `pre-commit-review` between `work-on-task` and `verify-test`, enabling native client review gate in forked subtree assignments.

## [0.20.7] - 2026-03-05

### Fixed
- Fixed incorrect `ace-idea move` command in task/draft workflow; replaced non-existent `ace-idea move <id> --to archive` with correct `ace-idea update <id> --set status=done --move-to archive`

## [0.20.6] - 2026-03-05

### Added
- `create` command now accepts `--status` (`-s`) flag to set initial task status (draft, pending, blocked, etc.) with validation against allowed statuses.
- `create` command now accepts `--estimate` (`-e`) flag to set effort estimate (e.g. TBD, 2h, 1d) in frontmatter.
- `estimate:` parameter threaded through `TaskCreator`, `SubtaskCreator`, `TaskManager`, and `TaskFrontmatterDefaults`.

## [0.20.5] - 2026-03-05

### Fixed
- Fixed task loading by requiring the task model before loading task metadata, which restores task-aware worktree and subtask discovery in mixed fixture formats.

## [0.20.4] - 2026-03-05

### Fixed
- Fixed task loading by explicitly requiring `Ace::Task::Atoms::TaskFilePattern` before lookup, restoring task-aware worktree and subtask discovery in mixed fixture formats.

## [0.20.3] - 2026-03-05

### Fixed
- `update --move-to archive` now handles subtasks safely: it soft-skips direct subtask archive when sibling subtasks are not all terminal, and archives the parent task folder when all subtasks are terminal.
- `doctor --auto-fix` archive moves now use standard archive partition routing and no longer strand subtask folders at archive partition root.
- `doctor --auto-fix` now skips unsafe subtask archive moves when sibling subtasks are not all terminal.

### Changed
- `update` command now prints informational notes for soft-skipped subtask archive requests and automatic parent archive behavior.
- Added regression coverage for subtask archive workflow in `TaskManager`, `update` CLI command, and `TaskDoctorFixer`.

## [0.20.2] - 2026-03-04

### Fixed
- Updated doctor CLI tests to match `provider_cli_args` method signature (`provider_model, cli_args_map, config`), resolving test failure after runtime signature expansion.

## [0.20.1] - 2026-03-04

### Fixed
- Restored backward-compatible `doctor_cli_args` fallback for doctor CLI argument migration from `task.doctor.cli_args`.

### Changed
- Preserved compatibility alias expansion for codex defaults (`full-auto`, `dangerously-bypass-approvals-and-sandbox`) when normalizing provider CLI args.
- Retained `required_cli_args` string compatibility while adding normalized array-oriented handling in `CliProviderAdapter`.

## [0.20.0] - 2026-03-04

### Changed
- Renamed doctor agent CLI argument config from `doctor_cli_args` to nested `doctor.cli_args`.
- Converted provider CLI args in `task.doctor.cli_args` and `task.plan.cli_args` to YAML arrays.
- Updated doctor command reads to use `config.dig("task", "doctor", "cli_args")` and preserved fallback behavior.
- Updated default plan CLI args to nested array format.

## [0.19.1] - 2026-03-04

### Fixed
- Bug workflow instructions corrected to short-name path convention (`.ace-local/task/bug-analysis/` not `.ace-local/ace-task/bug-analysis/`)

## [0.19.0] - 2026-03-04

### Changed
- Default plan cache directory migrated from `.cache/ace-task` to `.ace-local/task`

## [0.18.4] - 2026-03-04

### Fixed
- `TaskPlanGenerator` file-based prompt tests now create a minimal local `project` preset fixture so `ace-bundle` section preset resolution works in temp-directory test environments.
- `Doctor#provider_cli_args` now checks direct provider prefixes (`provider:model`) before parser fallback, restoring expected CLI-arg mapping behavior for provider aliases in tests and runtime.

## [0.18.3] - 2026-03-04

### Added
- Plan config key `task.plan.cli_args` for strict per-provider CLI argument passthrough during `ace-task plan` generation.

### Changed
- `TaskPlanPromptBuilder` now composes system prompts via section-based `ace-bundle` config using `base: tmpl://agent/plan-mode`, `workflow` (`wfi://task/plan`), `project_context` (`presets: [project]`), and repeated `repeat_instruction` guard section.
- `ace-task plan` now resolves provider-specific CLI args from `task.plan.cli_args` and passes them to `ace-llm` query calls.
- Strengthen planning prompt contracts in `tmpl://agent/plan-mode` and `wfi://task/plan` to require structured plan headings and reject permission/status-only output.

## [0.18.2] - 2026-03-04

### Fixed
- Prompt builder now fails fast on `ace-bundle` errors instead of silently degrading
- `fresh_context_files?` now returns true for empty context files, preventing unnecessary plan regeneration
- `build_unique_plan_path` uses current timestamp with collision suffix instead of future timestamps
- Squashed phantom intermediate CHANGELOG versions (0.15.1–0.18.0) into single 0.18.1 entry

## [0.18.1] - 2026-03-04

### Added
- `plan` CLI command: `ace-task plan <ref>` resolves a cached implementation plan or generates one when missing/stale
- `TaskPlanCache` molecule for plan artifact management under `.cache/ace-task/{task-id}/`, with latest-pointer fallback and freshness checks
- `TaskPlanGenerator` molecule for LLM-backed plan generation with `--model` override support
- `TaskPlanPromptBuilder` with file-based debugging and config file generation for prompt introspection
- Cache artifact contract for plan output (`{b36ts}-plan.md`, `latest-plan.md`, `latest-plan.meta.yml`)
- Anchored checklist template with stable step IDs, `path:line` anchors, dependencies, and verification commands
- New defaults key `task.plan.model` in `.ace-defaults/task/config.yml`
- Vertical slicing specs and modernized priority indicators (single glyph for critical)
- Dual-slug naming (folder context slug + file action slug) and short ID resolution
- Colored status symbols and global folder statistics to list output
- Execution Context as required section in plan output

### Changed
- Work workflow rewritten: plan-first execution with sub-phases `onboard-base → onboard → task-load → plan-task → work-on-task`
- Planning workflow transitioned to inline reporting contract (no file writes)
- Default plan model set to claude:opus
- Cache directory renamed from `.cache/task/` to `.cache/ace-task/` for consistency
- Narrowed exception rescue in `TaskPlanGenerator` to specific runtime/IO exceptions
- Extracted shared `PathUtils.relative_path` module from duplicated code
- Plan template verification commands use bare `ace-test`/`ace-lint` (removed `mise exec --` prefix)

### Fixed
- Draft workflow: corrected stale idea archive reference to use `ace-idea move` command
- Work workflow: clarified checkbox tracking with `path:line` anchor mapping to Success Criteria / Deliverables
- Bounded `build_unique_plan_path` loop with MAX_UNIQUE_ATTEMPTS guard to prevent infinite spin

### Removed
- Batch workflow instructions (consolidated into main workflows)

## [0.15.0] - 2026-03-03

### Added
- Short subtask folder names: subtask folders now use `{char}-{slug}` format (e.g., `0-setup-db`) instead of `{full_id}-{slug}` (e.g., `8pp.t.q7w.0-setup-db`), reducing path duplication while preserving full ID in spec filenames
- Backward-compatible dual-format scanning: all scanning code (`SubtaskCreator`, `TaskLoader`, `TaskScanner`, `TaskResolver`, `TaskReparenter`) recognizes both new and legacy subtask folder formats

### Fixed
- `TaskReparenter#convert_to_orchestrator`: fixed hardcoded `.a` subtask char to use `SUBTASK_CHARS[0]` (`"0"`), matching the 0-9 then a-z allocation order

## [0.14.1] - 2026-03-03

### Changed
- Config: replaced `special_folders` map with `special_folder_prefix: "_"` (prefix-based detection replaces hardcoded folder list)

## [0.14.0] - 2026-03-03

### Added
- `SubtaskCreator`: dual-slug naming — folder slug (5 words) and file slug (7 words), matching `TaskCreator` convention
- `TaskResolver`: short subtask ID resolution — `q7w.a` and `t.q7w.a` patterns now resolve to full subtask IDs

### Fixed
- `TaskReparenter` test: corrected expected first subtask char from `.a` to `.0` (base36 sequence starts at 0)
- `TaskManager` tests: corrected expected subtask char assertions to match 0-9 then a-z allocation order

## [0.13.0] - 2026-03-03

### Added
- `TaskCreator`: dual-slug support — folder slug (3-5 words, context) and file slug (4-7 words, action)
- `TaskValidationRules`: `MAX_TITLE_LENGTH = 80` constant
- `TaskFrontmatterValidator`: warning when title exceeds 80 characters
- Draft workflow: task naming convention guidelines (folder vs file slug rules)
- Review workflow: title length, folder slug, file slug, and slug repetition checklist items

### Changed
- `TaskCreator`: replaced `generate_slug` with `generate_folder_slug` (5-word limit) and `generate_file_slug` (7-word limit)
- `TaskCreator`: `generate_llm_slugs` now returns both folder and file slugs
- `SubtaskCreator`: slug generation uses 7-word limit instead of 40-char truncation

## [0.12.3] - 2026-03-03

### Fixed
- Subtask character allocation now follows base36 order (0-9 before a-z) matching Ruby's `to_s(36)`, ensuring correct lexicographic sorting

## [0.12.2] - 2026-03-03

### Changed
- Critical priority uses single `▲` glyph (same as high), distinguished only by red color — consistent column alignment

## [0.12.1] - 2026-03-03

### Changed
- Priority labels replaced: `‼`/`!`/`↓` → `▲▲`/`▲`/`▼` (arrow glyphs); critical is red, low is dimmed
- Subtask indicator changed from `+N` to `›N` and moved right after title (before tags/folder)
- List items: ID, tags, folder, and subtask count are dimmed for visual contrast with title
- `list --help` legend updated with priority and subtask reference

## [0.12.0] - 2026-03-03

### Added
- Colored status symbols in list output: pending (default), draft (cyan), in-progress (yellow), done (green), blocked (red), skipped/cancelled (dim) — TTY-aware, no color when piped
- `last_folder_counts` on `TaskScanner` and `TaskManager`: exposes per-folder item counts from the full scan for use in stats line
- `list --help` status legend with ANSI colors matching list output

### Changed
- `format_list` and `format_stats_line` accept `global_folder_stats:` parameter, always showing folder breakdown in stats line even when viewing a filtered subset (e.g. `--in next`)
- Status legend order in `list --help` reflects lifecycle: draft → pending → in-progress → done

## [0.11.0] - 2026-03-02

### Added
- Smart auto-sort: `list` command now sorts by computed score (priority × 100 + age, with in-progress boost and blocked penalty) by default
- `--sort` option on `list` command: choose sort order — `smart` (default), `id`, `priority`, `created`
- `--position` option on `update` command: pin tasks in sort order using B36TS values — `first`, `last`, `after:<ref>`, `before:<ref>`
- Pinned tasks (with `position` frontmatter field) always sort before auto-sorted tasks
- `status` command up-next section now uses smart sort instead of chronological ID sort
- Remove position pin with `--remove position` to return task to auto-sort

## [0.10.0] - 2026-03-02

### Added
- `--move-to` / `-m` option on `update` command: relocate task to a special folder (archive, maybe, anytime) or back to root (next/root//)
- `--move-as-child-of` option on `update` command: reparent tasks — "none" promotes subtask to standalone, "self" converts to orchestrator, `<ref>` demotes to subtask of another task
- `TaskReparenter` molecule: handles promote, orchestrator conversion, and demote operations with ID reassignment and frontmatter updates
- Auto-archive hook: when all subtasks in a parent directory reach terminal status (done/skipped/blocked), the parent folder auto-moves to archive

### Changed
- `update` command now accepts `--move-to` alone (no `--set` required), replacing the standalone `move` command

### Removed
- Standalone `move` command — use `update --move-to` instead
- `TaskManager#move` method — use `TaskManager#update(move_to:)` instead

## [0.9.0] - 2026-03-02

### Added
- `--git-commit` / `--gc` flag on `create`, `update`, and `move` commands to auto-commit changes via `ace-git-commit`

## [0.8.0] - 2026-03-02

### Added
- `status` CLI command showing up-next tasks, summary stats, and recently completed tasks
- `--up-next-limit` and `--recently-done-limit` options for status command (configurable via config.yml)
- `TaskDisplayFormatter.format_status` and `format_status_line` class methods for status overview rendering
- Config defaults: `status: { up_next_limit: 3, recently_done_limit: 9 }`

## [0.7.0] - 2026-03-02

### Added
- `TaskScanner#last_scan_total` exposes total item count before folder filtering
- `TaskManager#last_list_total` exposes total item count for "X of Y" stats display
- `TaskDisplayFormatter.format_list` and `format_stats_line` accept `total_count:` parameter
- CLI list command passes total count through to formatter for contextual stats

## [0.6.0] - 2026-03-02

### Added
- `TaskDisplayFormatter.format_stats_line` for generating stats summary (e.g., "Tasks: ○ 2 | ▶ 1 | ✓ 5 • 8 total • 63% complete")
- `format_list` now appends a stats summary line after the item list (omitted for empty lists)

## [0.5.0] - 2026-03-02

### Added
- `TaskScanner#scan_in_folder` method with virtual filter support ("next" for root-only, "all" for everything)

### Changed
- `TaskManager#list` defaults to `in_folder: "next"` — shows only root tasks by default (excludes _archive, _maybe, etc.)
- Use `--in all` to see all tasks including special folders (previous default behavior)
- Remove `next: _next` from default config special folder mappings

## [0.4.3] - 2026-03-01

### Changed
- Remove dead --tree conditional branch in show command

## [0.4.2] - 2026-03-01

### Fixed
- Add ace-support-markdown as runtime dependency in gemspec
- TaskDoctorFixer: log exception class and message in rescue blocks instead of silently swallowing
- TaskDoctorFixer: validate backup file extension before deletion in fix_stale_backup

## [0.4.1] - 2026-03-01

### Fixed
- Doctor command: soft-require ace/llm instead of hard top-level require (prevents LoadError without ace-llm)
- TaskDoctorFixer: add missing require_relative for TaskScanner
- Gemspec: include handbook/**/* in spec.files

## [0.4.0] - 2026-03-01

### Added

- `doctor` CLI command with health checks for tasks: structure validation, frontmatter validation, scope/status consistency
- `TaskValidationRules` atom defining valid statuses, terminal statuses, required fields, and scope rules
- `TaskStructureValidator` molecule checking folder naming (`{xxx.t.yyy}-{slug}`), spec files, stale backups, empty directories
- `TaskFrontmatterValidator` molecule validating delimiters, YAML parsing, required fields, field values, recommended fields
- `TaskDoctorReporter` molecule formatting results for terminal, JSON, and summary output with health score
- `TaskDoctorFixer` molecule auto-fixing 15+ issue patterns with dry-run support
- `TaskDoctor` organism orchestrating all checks with configurable check types
- Doctor flags: `--auto-fix`, `--auto-fix-with-agent`, `--check`, `--json`, `--verbose`, `--dry-run`, `--errors-only`, `--quiet`, `--model`, `--no-color`
- Config keys `doctor_agent_model` and `doctor_cli_args` in `.ace-defaults/task/config.yml`

## [0.3.0] - 2026-03-01

### Added

- `list` CLI command with `--status`, `--tags`, `--in`, `--root`, `--filter` options
- `move` CLI command with `--to` option for relocating tasks to special folders or root
- `update` CLI command with `--set`, `--add`, `--remove` for frontmatter field updates (comma-separated for multiple)
- `--priority`, `--tags`, `--child-of`, `--in` options on `create` command
- `--tree` output mode on `show` command
- `show` command now uses `TaskDisplayFormatter` for formatted output with status symbols
- Handbook migration: 17 task workflow instructions, 2 bug workflow instructions, 9 templates, and 3 guides moved from ace-taskflow

### Fixed

- `TaskManager#list` now normalizes folder names (e.g., "maybe" → "_maybe") before filtering

## [0.2.0] - 2026-03-01

### Added

- `TaskDisplayFormatter` molecule for terminal output formatting with status symbols and subtask tree display
- `TaskManager` organism orchestrating all task CRUD operations (create, show, list, update, move, create_subtask)
- `SubtaskCreator` molecule with sequential char allocation (a-z then 0-9, max 36)
- `TaskFilePattern` atom with glob patterns and primary vs subtask file detection
- `TaskFrontmatterDefaults` atom for building default frontmatter hashes

### Changed

- `Task` model expanded with priority, estimate, dependencies, tags, subtasks, parent_id fields
- `TaskScanner` expanded with subtask exclusion from primary scan and `scan_subtasks` method
- `TaskResolver` expanded with subtask reference resolution (`xxx.t.yyy.a`)
- `TaskLoader` expanded with subtask detection, parent_id population, and full field loading
- `TaskCreator` expanded with LLM slug generation, priority/tags/dependencies support

## [0.1.0] - 2026-03-01

### Added

- Initial gem scaffold with B36TS-based task ID format (`xxx.t.yyy`)
- `TaskIdFormatter` atom wrapping `ItemIdFormatter` with `.t.` type marker
- `TaskCreator` molecule for creating tasks with folder and spec file
- `TaskLoader` molecule for loading a single task from directory
- `TaskScanner` molecule wrapping `DirectoryScanner` with task-format ID extractor
- `TaskResolver` molecule wrapping `ShortcutResolver` with `full_id_length: 9`
- `TaskConfigLoader` molecule for configuration cascade
- `Task` model as value object
- Minimal CLI with `create` and `show` commands
