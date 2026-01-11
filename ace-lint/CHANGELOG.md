# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

## [0.8.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Lint` dry-cli command class
  - Deleted `lint_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.8.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.03)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - User-facing command interface remains identical
  - All options and behavior preserved
  - Improved internal command structure and testability

## [0.7.0] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.6.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.5.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Support::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.5.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.4.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/lint/config.yml` and `.ace.example/lint/kramdown.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

## [0.3.3] - 2025-11-16

### Changed

- **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  - Ensures compatibility with latest PromptCacheManager features
  - Aligns with standardized dependency versions across ACE ecosystem

## [0.3.2] - 2025-11-11

### Fixed
- Address code review feedback on documentation and hygiene
- Fix test discovery and execution issues with ace-test integration

### Changed
- Update test structure to work with ace-test smoke pattern
- Rename ace-core and ace-test-support dependencies

## 0.3.0 - 2025-10-13

### Changed

* **BREAKING**: Configuration structure changed to support multiple tool configs
  - General config: `.ace/lint/config.yml`
  - Kramdown config: `.ace/lint/kramdown.yml` (flat structure, no nesting)
  - Future tool configs: `.ace/lint/yaml.yml`, etc.
* **BREAKING**: Removed custom ConfigLoader - now uses ace-core config cascade
* Configuration loaded via `Ace::Core.config.get('ace', 'lint', 'kramdown')`
* README updated with comprehensive configuration documentation
* Removed invented CONFIGURATION.md file (not used by other ace-* gems)

### Added

* Added ace-core dependency (~> 0.9) for config management
* Added `Ace::Lint.kramdown_config` method for tool-specific config
* Configuration examples in `.ace.example/lint/` directory
* Documentation for multi-tool config pattern

### Fixed

* Config loading now follows standard ace-* gem patterns
* No more hardcoded config file paths
* Proper config cascade: defaults → user home → project → CLI options

## 0.2.0 - 2025-10-13

### Changed

* **BREAKING**: Configuration moved from `.ace-lint.yml` to `.ace/lint/kramdown.yml`
* ConfigLoader now follows ace-* pattern with standard `.ace/` directory structure
* Configuration is now explicit - users see and edit kramdown settings directly
* All kramdown options now visible in config file (no hidden defaults)

### Added

* Configuration cascade: `.ace/lint/kramdown.yml` (project) → `~/.ace/lint/kramdown.yml` (user)
* Full kramdown configuration support in `.ace/lint/kramdown.yml`
* Updated CONFIGURATION.md with proper ace-* patterns and examples

### Fixed

* Removed `.ace-lint.yml` files (wrong location)
* Config now follows same pattern as other ace-* gems (e.g., `.ace/llm/providers/*.yml`)

## 0.1.3 - 2025-10-13

### Fixed

* Corrected kramdown warning handling - warnings are strings, not hashes
* Fixed parsing error that occurred with some markdown documents
* All kramdown warnings are now properly displayed as informational messages

## 0.1.2 - 2025-10-13

### Added

* Added markdown style checks with warnings for common issues:
  * Missing blank line after headings
  * Missing blank line before/after lists
  * Missing blank line before/after code blocks
* Warnings are displayed but don't fail validation (only errors fail)

### Changed

* Made `lint` the default command - can now use `ace-lint file.md` instead of `ace-lint lint file.md`
* Commands `version` and `help` still work as before

## [0.3.1] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.1.1] - 2025-10-13

### Fixed

* Fixed binstub availability by adding ace-lint to root Gemfile
* Committed all gem files to git so gemspec can detect executables
* ace-lint command now available in workspace after bundle install

## [0.1.0][4] - 2025-10-13

### Added

* Initial release of ace-lint standalone gem
* Ruby-only linting stack (kramdown + Psych, no Node.js or Python)
* Markdown validation via kramdown with GitHub Flavored Markdown support
* YAML validation via Psych (Ruby built-in)
* Frontmatter validation with schema checking
* Auto-fix/format support with kramdown formatter
* Colorized terminal output (green ✓, red ✗, yellow ⚠)
* CLI interface with Thor (`ace-lint lint [FILES] [OPTIONS]`)
* Command options: --fix, --format, --type, --quiet, --line-width
* Proper exit codes (0 = success, 1 = failures) for CI/CD integration
* Subprocess-callable interface for other ace-\* gems
* ATOM architecture (atoms, molecules, organisms, models, commands)
* Comprehensive README with usage examples and integration patterns
* Test fixtures for validation testing

### Technical Details

* Dependencies: kramdown ~> 2.4, kramdown-parser-gfm ~> 1.1, thor ~> 1.3, colorize ~> 1.1
* Ruby version requirement: >= 3.1.0
* Follows ace-\* gem conventions and ATOM pattern
* RuboCop compliant with auto-corrections applied



[1]: https://keepachangelog.com/en/1.0.0/
[2]: https://semver.org/spec/v2.0.0.html
[3]: https://github.com/your-org/ace-lint/compare/v0.1.0...v0.1.1
[4]: https://github.com/your-org/ace-lint/releases/tag/v0.1.0
