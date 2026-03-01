# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-01

### Added

- Initial release of ace-retro gem
- RetroIdFormatter atom for raw b36ts ID generation
- RetroFilePattern atom for `.retro.md` file patterns
- RetroFrontmatterDefaults atom for retro frontmatter generation
- Retro model with id, status, title, type, tags, content, task_ref, folder_contents
- RetroConfigLoader molecule for configuration cascade
- RetroScanner molecule wrapping DirectoryScanner for `.retro.md` files
- RetroResolver molecule wrapping ShortcutResolver for ID resolution
- RetroLoader molecule for loading retros from directories
- RetroCreator molecule for full retro creation with b36ts ID
- RetroMover molecule with cross-filesystem move support (Errno::EXDEV)
- RetroDisplayFormatter molecule for terminal output
- RetroManager organism orchestrating create, show, list, update, move operations
- `.ace-defaults/retro/config.yml` with default configuration
- CLI registry (RetroCLI) with dry-cli following ace-idea pattern
- `create` command: `ace-retro create TITLE [--type TYPE] [--tags T] [--task-ref REF] [--move-to FOLDER] [--dry-run]`
- `show` command: `ace-retro show REF [--path | --content]`
- `list` command: `ace-retro list [--status S] [--type T] [--tags T] [--in FOLDER]`
- `move` command: `ace-retro move REF --to FOLDER`
- `update` command: `ace-retro update REF [--set K=V]... [--add K=V]... [--remove K=V]...`
- `version` and `help` commands
- Executable `exe/ace-retro` with SIGINT handling (exit 130) and error rescue
- Handbook: workflow instructions (retro/create, retro/synthesize) moved from ace-taskflow
- Handbook: templates (retro, synthesis-analytics, synthesize system prompt) moved from ace-taskflow
- CLI integration tests for all 5 commands
