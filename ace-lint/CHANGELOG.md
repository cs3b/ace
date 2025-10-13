# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

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

## [0.1.1][3] - 2025-10-13

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
