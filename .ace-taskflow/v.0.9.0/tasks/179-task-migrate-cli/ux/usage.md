# CLI Migration: Thor to dry-cli Usage Guide

## Overview

This migration replaces Thor with dry-cli as the CLI framework for all ACE gems. The user-facing interface remains **identical** - same commands, options, and behavior.

## Command Types

### Before (Thor-based) - NO CHANGE
```bash
ace-git-worktree create --task 178
ace-taskflow task 150
ace-review --preset pr --task 121
ace-search "pattern" --file
```

### After (dry-cli-based) - IDENTICAL
```bash
ace-git-worktree create --task 178
ace-taskflow task 150
ace-review --preset pr --task 121
ace-search "pattern" --file
```

## Usage Scenarios

### Scenario 1: Simple Command Execution
**Goal**: Run a basic command with options

```bash
# Works identically before and after migration
ace-search "TODO" --context 3

# Output unchanged:
# src/file.rb:42: TODO: implement this
# src/file.rb:43:
# src/file.rb:44: def placeholder
```

### Scenario 2: Nested Subcommands (Improved)
**Goal**: Use multi-level commands without workarounds

```bash
# Before: Works but required Thor workarounds internally
ace-git-worktree create --task 178

# After: Native nested command support
ace-git-worktree create --task 178

# Both produce identical output
# Created worktree at: ../ace-meta-task-178
```

### Scenario 3: Default Command Routing
**Goal**: Invoke default command implicitly

```bash
# ace-taskflow routes unknown commands to 'task'
ace-taskflow 150          # → ace-taskflow task 150
ace-taskflow 150 done     # → ace-taskflow task done 150

# ace-search routes to 'search'
ace-search "pattern"      # → ace-search search "pattern"

# Behavior identical before and after
```

### Scenario 4: Help Text Display
**Goal**: Get command help

```bash
# Works for all commands
ace-git-worktree --help
ace-git-worktree create --help
ace-taskflow task --help

# Help format may improve slightly due to dry-cli's
# native argument/option formatting
```

### Scenario 5: Option Formats
**Goal**: Pass options in different formats

```bash
# Both formats work (unchanged)
ace-git-worktree create --task 178
ace-git-worktree create --task=178

# Boolean flags
ace-review --preset pr --auto-execute
ace-search "pattern" --staged --tracked
```

### Scenario 6: Error Handling
**Goal**: Handle invalid input gracefully

```bash
# Invalid option
ace-git-worktree create --invalid-option
# Error: Unknown option: --invalid-option
# Usage: ace-git-worktree create [BRANCH] [OPTIONS]

# Missing required argument (where applicable)
# Error messages remain consistent
```

## Command Reference

### Pattern Migration: Thor → dry-cli

**Thor Pattern (Current)**:
```ruby
class CLI < Ace::Core::CLI::Base
  stop_on_unknown_option! :create  # WORKAROUND

  desc "create [BRANCH]", "Create worktree"
  option :task, type: :string
  def create(*args)
    if args.first == "--help"  # WORKAROUND
      invoke :help, ["create"]
      return 0
    end
    Commands::CreateCommand.new.run(args)
  end
end
```

**dry-cli Pattern (Target)**:
```ruby
module CLI
  extend Dry::CLI::Registry

  class Create < Dry::CLI::Command
    desc "Create a new worktree"

    argument :branch, required: false, desc: "Branch name"
    option :task, type: :string, desc: "Create for task ID"
    option :dry_run, type: :boolean, default: false

    def call(branch: nil, **options)
      # Options directly available - no workarounds needed
      Commands::CreateCommand.new.run(branch, **options)
    end
  end

  register "create", Create
end
```

### Internal Changes (Developer-Facing)

| Aspect | Thor | dry-cli |
|--------|------|---------|
| Command definition | Methods on CLI class | Separate Command classes |
| Option handling | Consumed before method | Passed to `call` as kwargs |
| Nested commands | Requires workarounds | Native support |
| Help generation | Automatic | Automatic |
| Default commands | `default_task` + workarounds | Register at root |

## Tips and Best Practices

### For Users

1. **No learning curve** - Commands work identically
2. **Check help** - `--help` available on any command
3. **Report issues** - If behavior differs, report as bug

### For Developers

1. **Follow conversion pattern** - Each Thor method → Command class
2. **Keep tests green** - Existing CLI tests should pass unchanged
3. **Preserve help text** - Transfer `desc` and `long_desc` content
4. **Update gemspec** - Replace `thor` with `dry-cli` dependency

## Migration Notes

### What Changes

- **Internal**: CLI framework code completely rewritten
- **Dependencies**: `thor ~> 1.3` → `dry-cli ~> 1.1`
- **File structure**: `cli.rb` converts to Registry + Command classes

### What Stays the Same

- All command names and aliases
- All option names and short forms
- All argument handling
- Exit codes (0 success, 1 error)
- Error message format
- Help text content

### Testing Migration

```bash
# Run existing tests - should pass without modification
ace-test ace-git-worktree
ace-test ace-taskflow
ace-test ace-search

# Manual verification
ace-git-worktree --help
ace-git-worktree create --help
ace-git-worktree create --task 999 --dry-run
```

## Troubleshooting

### Issue: Option not recognized
**Symptom**: `Unknown option: --foo`
**Solution**: Check option name matches exactly (no typos)

### Issue: Help not showing
**Symptom**: Command runs instead of showing help
**Solution**: Use `--help` at end of command: `ace-cmd subcmd --help`

### Issue: Exit code changed
**Symptom**: Script relying on exit codes fails
**Solution**: Report as bug - exit codes should be identical
