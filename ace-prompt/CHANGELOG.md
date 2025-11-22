# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of ace-prompt gem
- Queue-based prompt workflow with single file (`the-prompt.md`)
- Automatic archiving with timestamp-based naming
- `_previous.md` symlink to last archived prompt
- Template system with tmpl:// protocol support
- Optional context loading via ace-context integration
- Optional LLM enhancement with caching
- Task-specific prompt support via `--task` flag
- Configuration cascade via `.ace/prompt/config.yml`
- Model aliases (glite, claude, haiku)
- Enhancement chain tracking with _e001, _e002 suffixes
- CLI commands: process (default), setup, reset

## [0.1.0] - 2025-11-22

### Added
- Initial gem structure following ACE ATOM architecture
- Thor CLI framework integration
- Comprehensive documentation and usage guide
