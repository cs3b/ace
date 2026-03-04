# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
