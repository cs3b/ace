# Changelog

All notable changes to ace-context will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.4] - 2025-10-07

### Changed
- **Unified XML embedding format across all loading methods** (Breaking change)
  - Preset loading now uses XML format when `embed_document_source: true`
  - Files embedded as `<file path="...">content</file>` instead of markdown headers
  - Commands embedded as `<command name="..." success="true">output</command>` instead of markdown sections
  - Consistent format between protocol loading (`wfi://`) and preset loading (`--preset`)
  - **Impact**: Better nesting support for markdown files, clearer boundaries for LLM agents
  - **Migration**: If parsing preset output with `embed_document_source: true`, expect XML format instead of markdown headers

### Fixed
- **Preset loading formatter inconsistency**
  - Presets with `embed_document_source: true` now trigger XML formatting
  - Previously used markdown headers (### filename.md) while protocols used XML
  - Now both methods use `<files>` and `<file>` tags consistently
  - Default format is now `markdown-xml` when `embed_document_source: true`

## [0.11.3] - 2025-10-07

### Fixed
- **Incomplete migration from top-level params to context.params**
  - PresetManager now correctly reads params from `context.params` location
  - Previously only read from top-level `params:` (old structure)
  - Fixes issue where `context.params.output` and other params were ignored
- **File embedding not working with embed_document_source**
  - ContextLoader now correctly checks `context.embed_document_source` flag
  - Previously only checked deprecated `embed_itself` flag
  - Fixes issue where files listed in `context.files` were not embedded in output

### Changed
- **Removed backward compatibility** (pre-1.0 breaking change)
  - No longer supports top-level `params:` structure
  - No longer supports `embed_itself` flag
  - Only `context.params` and `embed_document_source` are supported
  - All tests updated to use new structure exclusively

### Migration Guide
Old structure (no longer supported):
```yaml
params:
  output: cache
  embed_itself: true
context:
  files: [...]
```

New structure (required):
```yaml
context:
  params:
    output: cache
  embed_document_source: true
  files: [...]
```

## [0.11.2] - 2025-10-06

### Changed
- **`embed_document_source` output format** - Raw content with XML blocks
  - Source document now output as unmodified raw content (frontmatter + markdown)
  - Embedded files, commands, and diffs wrapped in semantic XML blocks: `<files>`, `<commands>`, `<diffs>`
  - Removed "# Context" wrapper and markdown sections when embedding source
  - **Impact**: Cleaner separation between source document and embedded content
  - **Use case**: Workflow files can embed themselves with their dependent workflows in proper format

### Fixed
- **Frontmatter preservation in output** - YAML format maintained
  - Original YAML frontmatter now output with `---` delimiters instead of bulleted list
  - Applies to both `markdown` and `markdown-xml` output formats when using `embed_document_source`

## [0.11.1] - 2025-10-06

### Fixed
- **Regex anchor bug in `load_auto`** - Critical bugfix for YAML config detection
  - Changed `/^[\w-]+$/` to `/\A[\w-]+\z/` to match string boundaries, not line boundaries
  - Fixed protocol detection regex `/^[\w-]+:\/\//` to `/\A[\w-]+:\/\//`
  - Added detection for `include:`, `diffs:`, `presets:` keys in inline YAML
  - **Impact**: YAML configs like `files: ["lib/**/*.rb"]` were incorrectly detected as preset "---"
  - **Fixes**: "No code to review" error in ace-review when using file/diff configs
- **Glob pattern support in `files:` configuration**
  - Added automatic detection of glob characters (`*`, `?`, `[`) in file patterns
  - Routes glob patterns to `aggregate()` and literal paths to `aggregate_files()`
  - Added `exclude:` parameter support in file aggregation
  - **Impact**: Patterns like `lib/**/*.rb` now correctly expand to matching files

## [0.11.0] - 2025-10-06

### Added
- **Protocol resolution support** via ace-nav integration
  - Load resources using protocols: `ace-context wfi://workflow-name`
  - Supported protocols: `wfi://` (workflows), `guide://`, `task://`, and any ace-nav protocol
  - Works in input arguments and `context.files` arrays
- **YAML frontmatter template support**
  - Detect and process files with YAML frontmatter (starts with `---`)
  - Support `context:` key in frontmatter for configuration
  - Merge `params:` from frontmatter into processing options
- **Workflow embedding via protocols**
  - Reference workflows in `context.files: [wfi://draft-task, wfi://plan-task]`
  - Automatic recursive protocol resolution
  - Zero duplication - workflows reference each other declaratively

### Changed
- `load_auto()` now detects `://` pattern and delegates to protocol resolution
- `load_file()` treats files with YAML frontmatter as templates
- `load_template()` processes frontmatter config directly when `context:` key present
- CLI updated to use `load_auto()` instead of `load_preset()` for flexible input handling

### Technical Details
- `resolve_protocol()` delegates to `ace-nav` for path resolution
- `resolve_file_reference()` handles protocols in file arrays
- Protocol resolution integrated in both preset and template config processing
- Maintains backward compatibility with existing file paths, presets, and inline YAML

## [0.10.0] - 2025-10-06

### Added
- Git diff support via `diffs:` configuration key
- `Ace::Context::Atoms::GitExtractor` for secure git operations
- Support for combining files, commands, diffs, and presets in unified configuration
- Git diff formatting in all output modes (markdown, xml, markdown-xml, json, yaml)
- Comprehensive test suite for git operations (10 tests)

### Changed
- ace-core `OutputFormatter` now handles diffs section in all formats
- README updated with Content Sources section documenting all supported types

## [0.9.0] - 2025-10-05

Initial release with preset management, file aggregation, and command execution support.
