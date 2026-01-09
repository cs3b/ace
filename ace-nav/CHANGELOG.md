# Changelog

All notable changes to ace-nav will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.16.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `Create`, `List`, `Resolve`, and `Sources` dry-cli command classes
  - Deleted `create_command.rb`, `list_command.rb`, `resolve_command.rb`, and `sources_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.16.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.05)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Converted CLI to Registry pattern with `Ace::Nav::CLI.start(args)` entry point
  - Added dry-cli command classes for resolve, list, create, and sources
  - Maintained backward compatibility for `--sources` and `--create` flags

### Fixed
- Updated test expectations for dry-cli module-based CLI (no longer instantiable)

## [0.15.0] - 2026-01-05

### Added
- Thor CLI migration with standardized command structure
- ConfigSummary display for effective configuration with sensitive key filtering
- Comprehensive CLI help documentation across all commands

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Migrated from OptionParser to Thor framework
- Added method_missing for default subcommand support
- Improved config loading and thread safety

### Fixed
- CLI routing and dependency management for feature parity
- --help dispatch for all ACE commands
- Restored default subcommand behavior
- Addressed PR #123 review findings for Medium and higher priority issues

## [0.14.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.13.2] - 2026-01-01

### Changed

* Add thread-safe configuration initialization with Mutex pattern
* Improve error logging with gem prefix and exception class

## [0.13.1] - 2025-12-30

### Changed

* Replace ace-support-core dependency with ace-config and ace-support-fs
* Migrate from Ace::Core to Ace::Config.create() API

## [0.13.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.12.0] - 2025-12-29

### Changed
- Migrate DirectoryTraverser and ProjectRootFinder dependencies from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.11.0] - 2025-12-27

### Added

- **ADR-022 Configuration Pattern**: Migrate configuration to unified default/override pattern
  - Defaults loaded from `.ace.example/nav/config.yml` at runtime
  - User overrides via `.ace/nav/config.yml` cascade
  - Deep merge of user config over defaults
  - Single source of truth for default values

### Fixed

- Address review feedback for ADR-022 migration

### Changed

- Update infrastructure gem references (ace-core → ace-support-core)
- Consolidate test support infrastructure

## [0.10.2] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed runtime dependency from `ace-core` to `ace-support-core`
  - Changed development dependency from `ace-test-support` to `ace-support-test-helpers`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.10.1] - 2025-10-23

### Added
- Implement task:// protocol for command delegation with unified navigation interface

### Changed
- Improve command parsing robustness using Shellwords.split for proper quote handling
- Fix encapsulation by exposing config_loader via public accessor in ProtocolScanner

## [0.10.0] - 2025-10-23

### Added
- **task:// Protocol Support**: New command delegation protocol for navigating tasks via ace-taskflow
  - Delegates `task://` URIs to `ace-taskflow task` commands
  - Supports all ace-taskflow reference formats (018, task.018, v.0.9.0+task.018, backlog+025)
  - Pass-through support for --path, --content, and --tree options
  - New `CommandDelegator` organism for cmd-type protocol handling
  - Added `protocol_type` method to `ConfigLoader` for distinguishing cmd vs file protocols
  - Added `cmd_protocol?` method to `NavigationEngine`
  - Added `--path` option to CLI for consistency with ace-taskflow

### Changed
- **CLI Composability**: Refactored CLI to return exit codes instead of calling exit() directly
  - Improves testability and composability of CLI methods
  - Entry point now handles exit with returned codes
- **Performance Optimization**: ConfigLoader now reused from ProtocolScanner to avoid creating new instances

## [0.9.3] - 2025-10-08

### Changed

- **Test Structure Migration**: Migrated to flat ATOM structure
  - From: `test/ace/nav/atoms/`, `test/ace/nav/molecules/`, `test/ace/nav/models/`
  - To: `test/atoms/`, `test/molecules/`, `test/models/`
  - Moved top-level test files to root: `nav_test.rb`, `cli_test.rb`
  - Aligns with standardized test organization across all ACE packages

## [0.9.2] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.1] - 2025-10-05

### Added
- Subdirectory/prefix pattern support for protocols
  - Patterns ending with `/` now list all files with that prefix (e.g., `prompt://create/` lists create-task, create-project, etc.)
  - Actual subdirectories are also listed when they exist (e.g., `prompt://guidelines/` lists all files in guidelines/ directory)
- Auto-list mode for intuitive patterns
  - Patterns ending with `/` automatically enable list mode (no need for `--list` flag)
  - Wildcard patterns (`*` or `?`) automatically enable list mode
  - Protocol-only URIs continue to auto-list (e.g., `prompt://`)

### Fixed
- Duplicate entries in results when using subdirectory patterns
- Pattern matching now correctly handles both prefix matching and subdirectory listing

### Changed
- CLI now intelligently detects patterns that should return multiple results

## [0.9.0] - Previous Release

- Initial release with core navigation functionality
- Protocol-based resource discovery
- Support for workflows, templates, prompts, and guides
- Integration with ace-* gems and local configurations