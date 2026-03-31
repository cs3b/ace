---
id: 8qu.t.jdt.0
status: draft
priority: medium
created_at: "2026-03-31 12:55:26"
estimate: TBD
dependencies: []
tags: [cli, config, ace-support-config]
parent: 8qu.t.jdt
bundle:
  presets: ["project"]
  files:
    - ace-support-core/lib/ace/core/cli.rb
    - ace-support-core/lib/ace/core/organisms/config_initializer.rb
    - ace-support-core/lib/ace/core/organisms/config_diff.rb
    - ace-support-core/lib/ace/core/models/config_templates.rb
    - ace-support-core/exe/ace-framework
    - ace-support-config/ace-support-config.gemspec
    - ace-support-config/lib/ace/support/config.rb
  commands: []
---

# Implement ace-config executable and modules in ace-support-config

## Behavioral Specification

### User Experience

- **Input**: User runs `ace-config init`, `ace-config diff`, `ace-config list`, `ace-config version`, or `ace-config help`
- **Process**: The command resolves config templates from installed ace-* gems using `.ace-defaults/` directories, then performs the requested operation (copy, diff, or list)
- **Output**: Same output as current `ace-framework` with `ace-config` replacing `ace-framework` in all user-facing strings (help text, banners, usage examples, footer messages)

### Expected Behavior

A new `ace-config` executable is added to ace-support-config. It provides identical functionality to the current `ace-framework`:

1. `ace-config init [GEM]` — copies `.ace-defaults/` files to `.ace/` (or `~/.ace/` with `--global`), with `--force`, `--dry-run`, `--verbose` flags
2. `ace-config diff [GEM]` — compares active config against `.ace-defaults/` examples, with `--global`, `--local`, `--file`, `--one-line` flags
3. `ace-config list` — lists all ace-* gems with `.ace-defaults/` directories, with `--verbose` flag
4. `ace-config version` — prints ace-support-config version
5. `ace-config help` / `--help` / `-h` — prints help text

All output, error messages, and exit codes are identical to current behavior, except the command name string changes from `ace-framework` to `ace-config`.

### Interface Contract

```bash
# All commands — identical interface to ace-framework
ace-config init [GEM] [--force] [--dry-run] [--global] [--verbose]
ace-config diff [GEM] [--global] [--local] [--file PATH] [--one-line]
ace-config list [--verbose]
ace-config version
ace-config help

# Error: unknown command
$ ace-config bogus
Unknown command: bogus
# (followed by help text, exit 1)

# Error: unknown gem
$ ace-config init nonexistent-gem
Warning: No configuration found for ace-nonexistent-gem
```

### Success Criteria

- `ace-config --help` prints help with `ace-config` in all strings
- `ace-config init --dry-run` discovers config templates from installed ace-* gems
- `ace-config list` output matches current `ace-framework list` output
- `ace-config version` prints the ace-support-config version string
- `ace-config diff --one-line` shows config drift summary
- CLI class lives in `Ace::Support::Config` namespace (not `Ace::Core`)
- Config modules (initializer, diff, templates) live in `ace-support-config` package
- ace-support-config gemspec declares `ace-config` as executable
- ace-support-config test suite passes with new CLI coverage

### Validation Questions

- Should `ace-config version` print the ace-support-config version or the ace-support-core version? **Default**: ace-support-config version, since that package now owns the command.
- Do ConfigInitializer/ConfigDiff/ConfigTemplates need any ace-support-core dependency? **Answer**: No — they use only stdlib (fileutils, pathname, open3, rubygems).

## Vertical Slice Decomposition

- **Slice type**: subtask of orchestrator 8qu.t.jdt
- **Slice outcome**: `ace-config` executable is functional and tested in ace-support-config
- **Advisory size**: medium — straightforward code move with namespace rename and string updates
- **Context dependencies**: current FrameworkCLI implementation in ace-support-core (listed in bundle files)

## Verification Plan

### Unit/Component Validation

- CLI dispatches `init`, `diff`, `list`, `version`, `help` commands correctly
- Unknown command prints error + help and exits 1
- ConfigInitializer copies files from `.ace-defaults/` to target directory
- ConfigDiff detects missing, changed, and identical config files
- ConfigTemplates discovers gems via monorepo scan and RubyGems

### Integration Validation

- `ace-config init --dry-run` end-to-end in a project with ace-* gems installed
- `ace-config list` discovers gems from both local and gem sources
- `ace-config diff --one-line` produces summary output

### Failure/Invalid Path Validation

- `ace-config bogus` → error message + help text + exit 1
- `ace-config init nonexistent-gem` → warning message
- `ace-config init` with no ace-* gems → empty initialization summary

### Verification Commands

- `cd ace-support-config && ace-test` — full test suite passes
- `ace-config --help` — prints help with correct command name
- `ace-config init --dry-run` — discovers templates
