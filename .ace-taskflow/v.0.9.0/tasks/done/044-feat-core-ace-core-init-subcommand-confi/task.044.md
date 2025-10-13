---
id: v.0.9.0+task.044
status: done
estimate: 2h
dependencies: []
completed_at: 2025-09-29
---

# Implement ace-core init subcommand for configuration management

## Description

Implement a centralized `ace-core init` subcommand that manages configuration initialization for all ace-* gems. This command will copy example configurations from each gem's `ace.example/` directory to the appropriate `.ace/` location, with support for dry-run, diff viewing, and force overwrite options.

## Acceptance Criteria

- [x] Create `ace-core` CLI executable with `init` and `diff` subcommands
- [x] Each ace-* gem has an `ace.example/` directory mirroring `.ace/` structure
- [x] `init` command copies config files and reports copied vs skipped files
- [x] `diff` subcommand compares current configs with ace.example templates
- [x] Display `docs/config.md` content on first run when config is missing
- [x] Support `--force`, `--dry-run`, `--global` flags for init command
- [x] Support `--one-line`, `--file`, `--global/--local` options for diff command
- [x] All existing ace-* gems updated with ace.example directories

## Implementation Notes

### 1. Directory Structure
Each gem needs `ace.example/` directory with exact `.ace/` structure:
- ace-core/ace.example/core/settings.yml
- ace-taskflow/ace.example/taskflow/config.yml
- ace-context/ace.example/context/config.yml + presets/
- etc.

### 2. Core Components to Create
- `ace-core/exe/ace-core` - CLI executable
- `ace-core/lib/ace/core/cli.rb` - Main CLI class
- `ace-core/lib/ace/core/organisms/config_initializer.rb` - Init logic
- `ace-core/lib/ace/core/organisms/config_diff.rb` - Diff logic
- `ace-core/lib/ace/core/models/config_templates.rb` - Template registry

### 3. CLI Commands
```bash
ace-core init [GEM]         # Initialize config for specific gem or all
  --force                   # Overwrite existing files
  --dry-run                 # Show what would be done
  --global                  # Use ~/.ace instead of ./.ace
  --verbose                 # Show detailed output

ace-core diff               # Compare configs with examples
  --global                  # Compare global configs
  --local                   # Compare local configs (default)
  --file PATH              # Compare specific file
  --one-line               # One-line summary per file
```

### 4. Key Features
- Copy ace.example/ → .ace/ preserving structure
- Track and report copied vs skipped files
- Show docs/config.md on first run
- Use system diff/diff3 for comparisons
- Non-destructive by default (skip existing files)
