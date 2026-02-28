# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
