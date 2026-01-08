# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **CLI migrated to dry-cli** (task 179.16)
  - Replaced Thor-based CLI with dry-cli registry pattern
  - Thor dependency replaced with dry-cli ~> 1.1 in gemspec
  - Removed old Thor subcommand files (cache_cli.rb, providers_cli.rb, models_cli.rb)
  - New command classes in `cli/{cache,providers,models}/` directories
  - Commands now use keyword arguments for options
  - Subcommands registered hierarchically: `cache sync`, `providers list`, etc.

## [0.4.1] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.4.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.3.3] - 2025-12-30

### Changed

- Update provider config path references from `.ace.example` to `.ace-defaults`

## [0.3.2] - 2025-12-08

### Fixed

- OpenRouter model sync false positives for suffixed models (`:nitro`, `:floor`, `:online`, etc.)
- ModelNameCanonicalizer now strips known routing suffixes before comparing against models.dev

### Added

- ModelNameCanonicalizer atom for OpenRouter model name canonicalization
- Comprehensive tests for canonicalization following ADR-017 flat structure

## [0.3.1] - 2025-12-06

### Fixed

- CLI commands now return status codes instead of calling `exit 1` directly
- Executable properly handles exit codes from CLI.start
- Race condition in `writable?` check using SecureRandom for unique test filenames
- Search optimization to avoid loading all results twice (single fetch with total count)
- Levenshtein pre-filter by length before expensive distance calculations
- Provider sync continues with remaining providers after individual failures

### Added

- ApiFetcher test coverage for network failures and error handling
- Modality type validation warning in ModelInfo

### Changed

- Provider config paths updated to use `.ace.example/llm/providers/` pattern

## [0.3.0] - 2025-12-06

### Added

- Git-style subcommand structure with `cache`, `providers`, and `models` groups
- New `cache clear` command - Clear local cache files
- New `providers list` command - List all providers with model counts
- New `providers show PROVIDER` command - Show provider details and models
- New `cache status` command (replaces `stats`)
- `--json` flag available on all commands for machine-readable output
- Search truncation message: "Showing X of Y results" when results are limited
- `--full` flag for `models info` command to show complete details
- Early model ID format validation to fail fast on invalid input
- Flow-style YAML array detection with helpful error messages

### Fixed

- CLI `exit_on_failure?` now returns false per project patterns
- Extracted hardcoded cache staleness constant `PROVIDER_SYNC_CACHE_MAX_AGE`

### Changed

- **BREAKING**: Refactored `ApiFetcher` to use Faraday with retry middleware (ADR-010 compliant)
  - Added automatic retries for transient network failures (429, 500, 502, 503, 504)
  - Added exponential backoff with jitter
- **BREAKING**: CLI restructured into git-style subcommands
  - `sync` → `cache sync` (top-level shortcut still available)
  - `stats` → `cache status`
  - `diff` → `cache diff`
  - `sync-providers` → `providers sync`
  - `search` → `models search` (top-level shortcut still available)
  - `info` → `models info` (top-level shortcut still available)
  - `cost` → `models cost`
- `models info` now shows brief output by default; use `--full` for complete details
- `validate` command merged into `models info` (brief output validates model existence)

### Removed

- `stats` command (replaced by `cache status`)
- `validate` command (merged into `models info`)

---

## [0.2.0] - 2024-12-05

### Added

- `info` command - Display complete model information with human-readable or JSON output
- `--json` flag for `info`, `cost`, and `search` commands - Output structured JSON for scripting
- `--filter` flag for `search` command - Filter models by key:value pairs (repeatable)
  - Supported filters: `provider`, `reasoning`, `tool_call`, `attachment`, `structured_output`, `temperature`, `open_weights`, `modality`, `min_context`, `max_input_cost`
- Optional query in `search` command - Omit query to list all models matching filters
- `ModelFilter` atom - Reusable filter predicates for model queries

### Changed

- `search` command now accepts optional query parameter (was required)
- `ModelSearcher.search` now accepts `filters:` parameter for additional filtering

## [0.1.0] - 2024-12-04

### Added

- Initial release
- `sync` command - Download and cache model data from models.dev
- `validate` command - Validate model names with suggestions
- `cost` command - Calculate query costs based on token usage
- `diff` command - Show changes between cache versions
- `search` command - Search for models by name
- `stats` command - Show cache statistics
- Ruby API for programmatic access
- Offline operation after initial sync
- XDG-compliant cache directory
