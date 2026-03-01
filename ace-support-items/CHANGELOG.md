# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
