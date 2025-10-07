# Changelog

All notable changes to ace-review will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.7] - 2025-10-07

### Fixed

- **ace-llm-query integration**: Fixed command construction to work with updated ace-llm-query API
  - Replaced non-existent `--file` flag with new `--prompt` flag (added in ace-llm v0.9.1)
  - Added proper PROVIDER:MODEL positional argument as first parameter
  - Added `--output` flag to save review reports directly to session directory
  - Added `--timeout 600` for 10-minute timeout on long reviews
  - Added `--format markdown` for consistent markdown output
  - Output filename now uses model short name: `review-report-{model-short}.md`
  - Example: `review-report-gemini-2.5-flash.md` for model `google:gemini-2.5-flash`

### Changed

- **LlmExecutor API**: Updated `execute` method to require `session_dir:` parameter
  - Enables direct file output to session directory
  - Returns `output_file` path in result hash
- **ReviewManager**: Updated to pass `session_dir` to LlmExecutor
  - Simplified result handling (no longer needs to save output separately)

## [0.9.6] - 2025-10-06

### Changed

- **ace-context integration**: Refactored to use ace-context for unified content aggregation
  - `SubjectExtractor` now delegates to `Ace::Context.load_auto` for all content extraction
  - `ContextExtractor` now delegates to `Ace::Context.load_auto` for all content extraction
  - Preserved special behaviors (staged/working/pr keywords, project context defaults)
  - Eliminated duplicated file reading, command execution, and git extraction logic

### Added

- **ace-context dependency**: Added `ace-context ~> 0.9` as runtime dependency
- **Enhanced composition**: Can now combine files + commands + diffs + presets in unified configs
- **Preset support in context**: `presets:` key now functional in context configuration
- **Diffs support**: New `diffs:` key supported in subject and context configs

### Removed

- **Redundant atoms**: Deleted `git_extractor.rb` and `file_reader.rb` (now in ace-context)
- **Duplicated logic**: All content extraction now centralized in ace-context

## [0.9.5] - 2025-10-06

### Changed

- **Workflow command renamed**: `review-code.wf.md` → `review.wf.md`
  - Claude command changed from `/ace:review-code` to `/ace:review` for simplicity
  - Updated workflow invocation from `wfi://review-code` to `wfi://review`

### Fixed

- **Storage path detection**: Removed hardcoded storage defaults that prevented smart detection
  - `storage_config` now only checks user config, not module defaults
  - Properly implements 3-tier priority: user config → ace-taskflow → cache directory
  - Fallback path changed from `./reviews` to `.cache/ace-review/sessions/`
- **LLM command execution**: Fixed remaining `ace-llm` command reference in `llm_executor.rb`
  - Changed from `ace-llm query` to direct `ace-llm-query` invocation
  - Renamed method from `execute_ace_llm` to `execute_ace_llm_query` for clarity
- **Configuration comments**: Updated config file comments to reflect correct detection order

## [0.9.4] - 2025-10-05

### Changed

- **Dynamic storage path**: Storage now defaults to `$(ace-taskflow release --path reviews)`
  - Falls back to `./reviews` if ace-taskflow not available
  - Config `storage.base_path` commented out by default, uses smart detection
  - User can still override by uncommenting and setting custom path
- **Review file organization**: All review files now stored together with `.tmp` pattern
  - Session files in `{release_path}/reviews/review-{timestamp}/`
  - Temporary files use `.tmp` extension: `prompt.md.tmp`, `subject.md.tmp`, `context.md.tmp`
  - Committable files: `metadata.yml`, `review.md`
  - Gitignore pattern changed from `.ace-review-sessions/` to `**/*.tmp`
- **Command detection**: Binary check updated from `ace-llm` to `ace-llm-query`
  - Error message now correctly references `ace-llm-query`

### Fixed

- Review sessions no longer create separate `.ace-review-sessions` directory
- All review artifacts now properly organized in release-specific folders
- Temporary working files automatically gitignored via `.tmp` extension

## [0.9.3] - 2025-10-05

### Changed

- **Configuration file renamed**: `code.yml` → `config.yml` for consistency with ace-* naming conventions
  - Updated all references in code, tests, and documentation
  - Both `.ace.example/review/config.yml` and `.ace/review/config.yml` now use new name
- **Preset organization improved**: All presets now stored as individual files
  - Extracted 7 presets from main config to separate `.yml` files in `review/presets/`
  - Main `config.yml` now contains only defaults and storage settings
  - Presets: pr, code, docs, security, performance, test, agents, ruby-atom
- **Configuration cascade integration**: Removed hardcoded paths in favor of ace-core
  - `PresetManager` now uses `Ace::Core::Molecules::ConfigFinder` for all file discovery
  - Automatic cascade resolution across `./.ace → ~/.ace` without hardcoded paths
  - Preset files discovered automatically across entire configuration cascade
  - Maintains backward compatibility with fallback for environments without ace-core

### Fixed

- Configuration system now properly respects ace-core's configuration cascade
- Preset loading works correctly from both local and user config directories

## [0.9.2] - 2025-10-05

### Fixed

- **Prompt resolution** now works correctly via ace-nav integration
  - Fixed custom `PromptResolver` that wasn't working properly
  - Replaced with `NavPromptResolver` using ace-nav's universal resolution
  - Registered ace-review prompts with ace-nav protocol for proper discovery
- **Critical command injection vulnerability** in `GitExtractor`
  - Fixed unsafe string interpolation in git commands
  - Now uses array arguments with `Open3.capture3(*command_parts)`
- **Code organization issues**
  - Fixed overly complex `ReviewManager#execute_review` method
  - Replaced hash options with proper `ReviewOptions` class
  - Improved separation of concerns throughout

### Changed

- Refactored `ReviewManager` into clearer, testable steps
- Dependencies now include `ace-nav ~> 0.9` for proper prompt resolution

## [0.9.1] - 2025-10-05

### Fixed

- Replaced Zeitwerk with explicit requires following ace-gems conventions
- Fixed all require_relative paths and namespace references
- Removed unnecessary dependencies (zeitwerk, tty-*, rainbow, dry-cli)
- Replaced dry-cli with OptionParser for consistency with other ace gems
- Simplified output formatting to use plain text without external libraries

### Changed

- Minimal dependencies - now only requires ace-core (~> 0.9)
- CLI implementation now follows standard ace-gems patterns

## [0.9.0] - 2025-10-05

### Changed

- **BREAKING**: Simplified CLI interface from `ace-review code` to just `ace-review`
- Tool is now more universal - presets determine what type of review (code, docs, security, etc.)
- Cleaner, more intuitive command structure
- Migration from v0.8 legacy code-review system

### Migration

Update all commands from:
```bash
ace-review code --preset pr
```

To:
```bash
ace-review --preset pr
```

## [0.1.0] - 2025-10-05

### Added

- Initial release of ace-review gem
- Migrated from dev-tools code-review implementation
- ATOM architecture with atoms, molecules, organisms, and models
- Preset-based review configuration system
- Prompt composition with base, format, focus, and guidelines modules
- Prompt cascade resolution (project → user → gem)
- prompt:// URI protocol for prompt references
- Support for direct file path references in prompts
- Multiple focus module composition
- Integration with ace-taskflow for release-based storage
- CLI command: `ace-review code` with various options
- Built-in presets: pr, code, docs, security, performance, test, agents
- Example configuration files in .ace.example/
- Comprehensive prompt library migrated from dev-handbook
- LLM execution via ace-llm integration
- Session management for dry-run mode
- List commands for presets and prompts

### Changed

- **BREAKING**: Replaced `code-review` command with `ace-review code`
- **BREAKING**: Removed `code-review-synthesize` CLI (use `wfi://synthesize-reviews` workflow)
- **BREAKING**: Configuration moved from `.coding-agent/code-review.yml` to `.ace/review/config.yml`
- **BREAKING**: Storage location now defaults to `.ace-taskflow/<release>/reviews/`
- Preset files now support separate directory at `.ace/review/presets/`
- Improved preset override system with `--add-focus` option
- Enhanced prompt resolution with multiple lookup strategies

### Migration Notes

To migrate from the old code-review system:

1. Install ace-review gem
2. Copy `.coding-agent/code-review.yml` to `.ace/review/config.yml`
3. Update workflow files to use `ace-review code` instead of `code-review`
4. Synthesis is now handled via workflow instructions only (no CLI command)