# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-01-13

### Changed
- **BREAKING: Package renamed** from `ace-llm-models-dev` to `ace-support-models`
  - Follows `ace-support-*` naming pattern for infrastructure gems
  - CLI executable renamed: `ace-llm-models` → `ace-models`
  - Ruby module renamed: `Ace::LLM::ModelsDev` → `Ace::Support::Models`
  - Require path changed: `require 'ace/llm/models/dev'` → `require 'ace/support/models'`
  - Cache directory changed: `~/.cache/ace-llm-models-dev` → `~/.cache/ace-models`
  - All functionality remains identical
- **CLI migrated to dry-cli** (task 179.16)
  - Replaced Thor-based CLI with dry-cli registry pattern
  - Thor dependency replaced with dry-cli ~> 1.1 in gemspec
  - Removed old Thor subcommand files (cache_cli.rb, providers_cli.rb, models_cli.rb)
  - New command classes in `cli/{cache,providers,models}/` directories
  - Commands now use keyword arguments for options
  - Subcommands registered hierarchically: `cache sync`, `providers list`, etc.
- **Internal refactor**: Renamed `Cli::` module to `Commands::` for consistency with other ACE gems
  - Directory renamed: `lib/ace/support/models/cli/` → `lib/ace/support/models/commands/`
  - All command classes now use `Commands::` namespace

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

---

*For history prior to 0.3.2 (versions 0.1.0-0.3.1), see git history under the original gem name `ace-llm-models-dev`.*
