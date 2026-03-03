# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.13.1] - 2026-03-03

### Changed
- `StatsLineFormatter`: folder breakdown section (after em dash) is now dimmed via `AnsiColors` for visual distinction between current-view stats and system-wide totals
- `StatsLineFormatter`: folder names strip `_` prefix for display (`_archive` → `archive`, `_maybe` → `maybe`)

## [0.13.0] - 2026-03-03

### Added
- `AnsiColors` atom: TTY-aware ANSI color helpers with `colorize(text, color_code)` class method and color constants (RED, GREEN, YELLOW, CYAN, DIM, BOLD, RESET)
- `StatsLineFormatter`: new `global_folder_stats:` parameter that always appends folder breakdown to the stats line regardless of filtered/unfiltered state

## [0.12.0] - 2026-03-02

### Added
- `SortScoreCalculator` atom: computes sort scores using `priority_weight × 100 + age_days` with in-progress boost (+1000) and blocked penalty (×0.1), configurable weights and caps
- `PositionGenerator` atom: generates B36TS position values for pinning items in sort order (`first`, `last`, `after`, `before`, `between`)
- `SmartSorter` molecule: sorts items with pinned-first (by position ascending) + unpinned (by score descending) logic
- `StatusCategorizer` accepts optional `up_next_sorter:` proc for custom sort order in up-next bucket

## [0.11.0] - 2026-03-02

### Added
- `FolderCompletionDetector` atom: checks if all spec files in a directory have terminal status (done/skipped/blocked), with `recursive:` option for subtask subdirectories
- `SpecialFolderDetector.move_to_root?` method: recognizes "next", "root", and "/" as move-to-root aliases (case-insensitive)

## [0.10.0] - 2026-03-02

### Added
- `GitCommitter` molecule: shells out to `ace-git-commit` for auto-committing after CLI mutations, used by ace-task, ace-idea, and ace-retro `--git-commit` / `--gc` flag

## [0.9.0] - 2026-03-02

### Added
- `RelativeTimeFormatter` atom: formats a Time into human-readable relative strings (just now, 5m ago, 2h ago, 3d ago, 2w ago, 1mo ago, 1y ago) with injectable reference time
- `StatusCategorizer` molecule: categorizes items into "up next" (pending, root-only, sorted by ID) and "recently done" (done from all folders, sorted by file mtime desc) buckets for status overview displays

## [0.8.1] - 2026-03-02

### Fixed
- `DirectoryScanner` now recurses into special folders that contain orphan spec files (e.g., `_maybe/` with stray `.idea.s.md` files no longer blocks discovery of item subfolders)

## [0.8.0] - 2026-03-02

### Added
- `StatsLineFormatter.format` accepts `total_count:` parameter for "X of Y" filtered view display
- Filtered view (shown < total): displays "3 of 660" instead of redundant "3 total"
- Full view (shown == total): displays "660 total" with folder breakdown only when multi-folder

### Changed
- Single-folder stats no longer show redundant folder breakdown (e.g., "3 total" instead of "3 total — next 3")

## [0.7.0] - 2026-03-02

### Added
- `ItemStatistics` atom: pure counting logic for grouping items by any field (`count_by`) and computing completion rates (`completion_rate`)
- `StatsLineFormatter` atom: generic stats summary line builder with configurable label, status icons, ordering, and optional completion percentage

## [0.6.0] - 2026-03-02

### Added
- `SpecialFolderDetector.virtual_filter?` method for resolving virtual filter names ("next", "all") to symbols
- `VIRTUAL_FILTERS` constant mapping virtual filter names to symbols (`:next`, `:all`)

### Changed
- Remove `_next` from `SPECIAL_FOLDERS` and `SHORT_ALIASES` — "next" is now a virtual filter, not a physical folder
- `FolderMover#move` raises `ArgumentError` when target is a virtual filter ("next", "all")

## [0.5.0] - 2026-03-01

### Added
- `FieldUpdater` molecule for orchestrating --set/--add/--remove frontmatter field updates with nested dot-key support
- `FolderMover` molecule for generic folder moves with special folder normalization, archive partitioning, and cross-fs atomic moves
- `LlmSlugGenerator` molecule for LLM-powered slug generation with graceful fallback (moved from ace-taskflow)

### Fixed
- `FrontmatterSerializer` now correctly serializes nested Hash values with proper YAML indentation (previously produced Ruby Hash#to_s)

## [0.4.0] - 2026-03-01

### Added
- `ItemIdFormatter` atom: splits 6-char b36ts IDs into type-marked format (`prefix.marker.suffix`) and reconstructs
- `ItemIdParser` atom: parses all reference forms (full, short, suffix, subtask, raw) into `ItemId` model
- `ItemId` model: value object with `raw_b36ts`, `prefix`, `type_marker`, `suffix`, `subtask_char`

### Changed
- `DirectoryScanner`: added configurable `id_extractor:` proc parameter (default preserves existing 6-char behavior)
- `ShortcutResolver`: added `full_id_length:` parameter (default 6, set to 9 for type-marked IDs)

## [0.3.0] - 2026-02-28

### Added
- `DatePartitionPath` atom: computes a B36TS month/week partition path (e.g. `"8p/4"`) from a `Time` object for use in archive directory structures
- Runtime dependency on `ace-b36ts ~> 0.7`

## [0.2.0] - 2026-02-28

### Added

- `FrontmatterParser` atom for parsing YAML frontmatter from markdown files (tuple return: `[Hash, String]`)
- `FrontmatterSerializer` atom for serializing frontmatter hashes to YAML with inline arrays and value quoting
- `FilterParser` atom for parsing `--filter key:value` syntax with OR (`|`) and negation (`!`) support
- `TitleExtractor` atom for extracting first H1 heading from markdown body content
- `LoadedDocument` model as value object for parsed document with frontmatter, body, title, and attachments
- `DocumentLoader` molecule for loading documents from item directories with configurable file patterns
- `FilterApplier` molecule for applying parsed filter specs with AND/OR logic, negation, and custom value accessors
- `ItemSorter` molecule for sorting item collections by field with nil-last semantics
- `BaseFormatter` molecule with minimal default item/list formatting (overridable by gems)

## [0.1.1] - 2026-02-28

### Technical
- Moved `require "pathname"` to top-level in `SpecialFolderDetector` (was inline inside method)

## [0.1.0] - 2026-02-28

### Added

- Initial release with shared item management infrastructure
- `SlugSanitizer` atom for strict kebab-case slug sanitization
- `FieldArgumentParser` atom for parsing `key=value` CLI arguments with type inference
- `SpecialFolderDetector` atom for recognizing `_archive`, `_maybe`, `_anytime`, `_next` folders
- `ScanResult` model as value object for directory scan results
- `DirectoryScanner` molecule for recursive item directory scanning with special folder awareness
- `ShortcutResolver` molecule for resolving 3-char suffix shortcuts to full item IDs with ambiguity detection
