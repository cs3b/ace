# Changelog

All notable changes to ace-review will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- **BREAKING**: Configuration moved from `.coding-agent/code-review.yml` to `.ace/review/code.yml`
- **BREAKING**: Storage location now defaults to `.ace-taskflow/<release>/reviews/`
- Preset files now support separate directory at `.ace/review/presets/`
- Improved preset override system with `--add-focus` option
- Enhanced prompt resolution with multiple lookup strategies

### Migration Notes

To migrate from the old code-review system:

1. Install ace-review gem
2. Copy `.coding-agent/code-review.yml` to `.ace/review/code.yml`
3. Update workflow files to use `ace-review code` instead of `code-review`
4. Synthesis is now handled via workflow instructions only (no CLI command)