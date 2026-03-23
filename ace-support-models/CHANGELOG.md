# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2026-03-23

### Changed
- Added `ace-models` and `ace-llm-providers` CLI references to README intro and new Quick Start section with usage examples.

### Technical
- Removed phantom `handbook/**/*` glob from gemspec (no handbook directory exists).

## [0.8.2] - 2026-03-23

### Fixed
- Normalize provider and model data shapes in cache manager — handles wrapped (`{"providers" => ...}`), array-of-hashes, and flat hash formats so cache reads don't break when the upstream response shape varies.

## [0.8.1] - 2026-03-22

### Changed
- Refreshed README structure with a dedicated purpose section, dual installation paths, a basic usage entry point, and the ACE project footer link.

## [0.8.0] - 2026-03-21

### Changed
- Added initial `TS-MODELS-001` value-gated smoke E2E coverage for `ace-models` and `ace-llm-providers`, including ADD/SKIP decision evidence.

## [0.7.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.7.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.6.3] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.6.2] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.6.1] - 2026-02-22

### Changed
- Migrate ace-llm-providers CLI to standard help pattern
  - Remove DefaultRouting extension and DWIM default behavior
  - Add HelpCommand registration for `--help` and `-h`
  - Update REGISTERED_COMMANDS to [name, description] format
  - Add explicit start(args) method for CLI invocation

## [0.6.0] - 2026-02-22

### Added
- Migrate CLI to standard help pattern with HelpCommand
  - Register `--help` and `-h` for formatted help output
  - No args now shows help instead of command list

### Changed
- Remove DefaultRouting extension and DWIM default behavior
  - Remove KNOWN_COMMANDS, DEFAULT_COMMAND, BUILTIN_COMMANDS constants
  - Update REGISTERED_COMMANDS to [name, description] format
  - Convert HELP_EXAMPLES to simple string array
  - Add explicit start(args) method for CLI invocation
- Centralize CLI help routing and formatting (shared with ace-support-core)
- Centralize CLI error handling and exit code management (shared)

### Technical
- Update CLI command usage in README
- Lower Ruby version requirement to >= 3.2.0

## [0.5.2] - 2026-02-02

### Technical
- Update support-packages metadata

## [0.5.1] - 2026-01-15

### Changed
- Migrate CLI commands to Hanami pattern
  - Move commands from `commands/` to `cli/commands/`
  - Update namespace from `Commands::*` to `CLI::Commands::*`
  - Models subcommands use `ModelsSubcommands::` to avoid namespace conflict
  - Update test file references for new namespace

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


## [0.5.2] - 2026-02-22

### Fixed
- Added command grouping (Cache, Providers, Models, Shortcuts)
- Fixed namespace subcommand help (cache/providers/models --help) to exit 0 and print to stdout
- Standardized quiet, verbose, debug option descriptions to canonical strings
