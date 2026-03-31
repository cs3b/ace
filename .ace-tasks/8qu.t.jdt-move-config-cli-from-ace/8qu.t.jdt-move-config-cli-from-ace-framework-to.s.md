---
id: 8qu.t.jdt
status: pending
priority: medium
created_at: "2026-03-31 12:55:21"
estimate: TBD
dependencies: []
tags: [cli, config, ace-support-config, ace-support-core, dx]
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/cli.rb, ace-support-core/lib/ace/core/organisms/config_initializer.rb, ace-support-core/lib/ace/core/organisms/config_diff.rb, ace-support-core/lib/ace/core/models/config_templates.rb, ace-support-core/exe/ace-framework, ace-support-core/ace-support-core.gemspec, ace-support-config/ace-support-config.gemspec, ace-support-config/README.md, ace-support-config/docs/usage.md, bin/ace-framework, ace-support-core/test/integration/config_initializer_bootstrap_test.rb]
  commands: []
needs_review: false
---

# Move config CLI from ace-framework to ace-config in ace-support-config

## Objective

The `ace-framework` command lives in ace-support-core but manages configuration — a responsibility that belongs to ace-support-config. The name "framework" is misleading (there is no framework; it initializes, diffs, and lists `.ace/` config files). Renaming to `ace-config` and moving ownership to ace-support-config aligns the command with its actual purpose and the package that owns config infrastructure.

Source idea: `8qrz77` — Unify Ace configuration path and framework binary setup.

## Behavioral Specification

### User Experience

- **Input**: Users run `ace-config init|diff|list|version|help` with the same flags they use today with `ace-framework`
- **Process**: The command discovers ace-* gem config templates, copies/diffs/lists them against `.ace/` or `~/.ace/` directories — identical behavior to current `ace-framework`
- **Output**: Same output format, same exit codes, same error messages (with `ace-config` replacing `ace-framework` in all user-facing strings)

### Expected Behavior

Users who currently run `ace-framework init` will run `ace-config init` instead. All subcommands, flags, and output remain identical. The command is provided by the `ace-support-config` gem rather than `ace-support-core`. No compatibility shim is maintained for `ace-framework` (pre-1.0, ADR-024 applies).

`ace-support-config` is the sole owner of the new `ace-config` executable and implementation. Packaging changes are required in both gems: `ace-support-config` must ship `ace-config`, and `ace-support-core` must stop shipping `ace-framework`.

### Interface Contract

```bash
# CLI Interface — identical commands, new name
ace-config init [GEM] [--force] [--dry-run] [--global] [--verbose]
ace-config diff [GEM] [--global] [--local] [--file PATH] [--one-line]
ace-config list [--verbose]
ace-config version
ace-config help
```

Error Handling:
- Unknown command → prints error + help, exits 1 (unchanged)
- Unknown gem name → prints warning (unchanged)
- Missing config files → prints "Missing:" status (unchanged)

### Success Criteria

- `ace-config --help` prints help with `ace-config` in all strings (no `ace-framework` remnants)
- `ace-config init --dry-run` discovers and lists config templates from installed ace-* gems
- `ace-config list` shows all gems with `.ace-defaults/` directories
- `ace-config version` prints the ace-support-config version
- `ace-support-config` ships the `ace-config` executable in its gemspec and packaged files
- `ace-framework` is no longer an installed executable
- `ace-support-core` no longer ships `ace-framework` in its gemspec and packaged files
- `bin/ace-config` exists as the repo-root wrapper before old-command cleanup begins
- No references to `ace-framework` remain in onboarding docs (README.md, quick-start.md, DEVELOPMENT.md)
- `ace-support-config` docs describe `ace-config` as the canonical config-management CLI
- Existing bootstrap/config coverage from ace-support-core is preserved in ace-support-config
- Both ace-support-config and ace-support-core test suites pass with no dangling references

## Vertical Slice Decomposition (Task/Subtask Model)

| Subtask | Slice | Size | Outcome |
|---------|-------|------|---------|
| 8qu.t.jdt.0 | Implement ace-config CLI in ace-support-config | medium | `ace-config` executable works with all commands; tests pass in ace-support-config |
| 8qu.t.jdt.1 | Remove ace-framework from ace-support-core + update docs | medium | Old code removed; docs updated; ace-support-core tests pass |

## Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| `ace-config` executable | .0 | — | KEPT |
| `Ace::Support::Config::CLI` class | .0 | — | KEPT |
| Config modules in ace-support-config namespace | .0 | — | KEPT |
| `ace-framework` executable | (pre-existing) | .1 | REMOVED |
| `Ace::Core::FrameworkCLI` class | (pre-existing) | .1 | REMOVED |
| Config modules in Ace::Core namespace | (pre-existing) | .1 | REMOVED |

## Out of Scope

- Config file format changes or new config features
- Adding new subcommands beyond init/diff/list/version/help
- Changing the `.ace/` / `~/.ace/` directory structure
- Adding a compatibility shim or alias for `ace-framework`

## References

- Source idea: `.ace-ideas/8qrz77-unify-ace-configuration-path-and/`
- Current implementation: `ace-support-core/lib/ace/core/cli.rb` (FrameworkCLI)
- Current executable: `ace-support-core/exe/ace-framework`
- Config modules: `ace-support-core/lib/ace/core/organisms/config_initializer.rb`, `config_diff.rb`, `models/config_templates.rb`
