---
id: v.0.9.0+task.278
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Drop DWIM Default Routing and Standardize CLI Help

## Behavioral Specification

### User Experience

- **Input**: User runs any `ace-*` CLI tool with `--help`, `-h`, or a subcommand
- **Process**: CLI follows standard conventions — explicit subcommands required, help always exits 0
- **Output**: Consistent help output across all 22 CLI tools; no implicit command routing

### Expected Behavior

Currently, all ACE CLI gems override `start()` to implement two custom behaviors:
1. **DWIM default routing** — `ace-bundle project` implicitly becomes `ace-bundle load project`
2. **Help flag interception** — because dry-cli exits 1 instead of 0 for registry-level `--help`

Both are eliminated. After this migration:

- **Subcommands are always explicit**: `ace-bundle load project`, not `ace-bundle project`
- **`--help` / `-h` at tool level**: Registered as commands (like `--version`), print subcommand list + examples, exit 0
- **`--help` / `-h` at command level**: Handled by dry-cli built-in (no custom code)
- **No `help` subcommand**: Not a git-era CLI; `--help`/`-h` is sufficient and universal
- **No `start()` override**: `Dry::CLI.new(self).call(arguments: ARGV)` called directly from `exe/` wrappers

### Interface Contract

**Tool-level help** (`ace-taskflow --help` or `ace-taskflow -h`):
```
ace-taskflow v0.5.0

Commands:
  status          # Show current task/release status
  doctor          # Run health checks and auto-fix
  config          # Show configuration

Examples:
  ace-taskflow status
  ace-taskflow doctor
  ace-taskflow config --format yaml

Options:
  --help, -h      # Print this help
  --version       # Print version
```

**Command-level help** (`ace-taskflow status --help`):
```
Command:
  ace-taskflow status

Usage:
  ace-taskflow status

Description:
  Show current taskflow status and activity

Options:
  --format=VALUE    # Output format, default: "text"
  --help, -h        # Print this help
```

This is dry-cli's built-in Banner output — no custom code.

**Running tool with no arguments** (`ace-taskflow`):
- Shows help output (same as `--help`) — no implicit default command

**Error Handling:**
- Unknown subcommand: dry-cli's built-in spell checker + command list, exit 1
- `--help` / `-h` at any level: Always exit 0

### Success Criteria

- [ ] All `start()` method overrides removed from CLI modules (currently 12 inline + 6 using DefaultRouting)
- [ ] `DefaultRouting` module deleted from ace-support-core
- [ ] `KNOWN_COMMANDS`, `DEFAULT_COMMAND` constants removed from all CLI modules
- [ ] `--help` and `-h` registered as commands in all CLI registries (reusable builder in ace-support-core)
- [ ] Tool-level help shows: version, commands with descriptions, curated examples, options
- [ ] `HELP_EXAMPLES` constant defined in each CLI module (~7 lines of real-world usage)
- [ ] All help exits with code 0
- [ ] Command-level help unchanged (dry-cli built-in)
- [ ] No `help` subcommand registered anywhere
- [ ] Running tool with no args shows help (not an error)
- [ ] All existing tests pass; help output tests updated
- [ ] exe/ wrappers simplified to direct `Dry::CLI.new(CLI).call` calls

### Validation Questions

- [ ] **ace-nav backward compat**: `ace-nav --sources` and `ace-nav --create URI` are flag-based legacy aliases. How to handle? Options: (a) drop them, (b) handle in exe/ wrapper, (c) register as hidden commands
- [ ] **ace-search path edge case**: `ace-search ./version` currently avoids matching as `version` command. Without DWIM, this is no longer an issue — but verify
- [ ] **ace-taskflow cache clearing**: `start()` currently clears caches before invocation. Move to `before` callback or exe/ wrapper?
- [ ] **Subcommand-only gems**: Some gems have only one real command (e.g., ace-bundle has `load` and `list`). Running `ace-bundle` without subcommand should show help, not error

## Objective

Align all ACE CLI tools with industry-standard CLI conventions (clig.dev). Eliminate 18 copy-pasted `start()` overrides, the `DefaultRouting` module, and the DWIM routing pattern. Result: simpler code, standard behavior, no forward-compatibility risk from implicit command routing.

## Scope of Work

### Gems affected (22 CLI registries)

**Have inline `start()` override (12):**
ace-bundle, ace-search, ace-lint, ace-git, ace-git-secrets, ace-assign, ace-review,
ace-tmux, ace-support-nav, ace-test-runner-e2e, ace-overseer, ace-support-core

**Use `DefaultRouting` module (6+ new CLIs):**
ace-taskflow, ace-taskflow/task_cli, ace-taskflow/idea_cli, ace-taskflow/release_cli,
ace-taskflow/retro_cli, and any others extending DefaultRouting

**Have `start()` but no DWIM (need help command only):**
ace-llm, ace-b36ts, ace-git-worktree, ace-git-commit, ace-docs, ace-prompt-prep,
ace-test-runner, ace-support-models, ace-review/feedback_cli

### Deliverables

1. **HelpCommand builder in ace-support-core** — reusable, like `VersionCommand.build()`
2. **Per-gem migration** — remove `start()`, add `--help`/`-h` registration, add `HELP_EXAMPLES`
3. **Delete DefaultRouting** module and related constants
4. **Update exe/ wrappers** — direct `Dry::CLI.new(CLI).call` invocation
5. **Update tests** — help output assertions, remove DWIM routing tests
6. **Update docs** — ADR-023, cli-dry-cli.g.md, ace-gems.g.md

## Out of Scope

- Implementation details (code structure, specific class design)
- Technology decisions beyond dry-cli's existing capabilities
- Per-command help customization (dry-cli built-in is sufficient)
- Adding new CLI commands or features to any gem

## References

- [clig.dev — Command Line Interface Guidelines](https://clig.dev/)
- [dry-cli documentation](https://dry-rb.org/gems/dry-cli/1.1/)
- ADR-023: dry-cli CLI Framework
- Task 274: Unified CLI Help (predecessor — established help formatting)
- Existing pattern: `Ace::Core::CLI::DryCli::VersionCommand.build()`
