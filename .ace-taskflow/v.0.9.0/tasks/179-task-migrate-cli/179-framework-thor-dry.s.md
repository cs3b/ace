---
id: v.0.9.0+task.179
status: draft
priority: high
estimate: 40h
dependencies: []
---

# Migrate CLI Framework from Thor to dry-cli

## Behavioral Specification

### User Experience
- **Input**: Users invoke ACE CLI tools with commands, subcommands, options, and arguments
- **Process**: CLI parses input, routes to appropriate command handler, executes with proper context
- **Output**: Command results, help text, error messages - identical behavior to current Thor implementation

### Expected Behavior

All 13+ ACE CLI tools should work identically after migration:
- Same command names and aliases
- Same options and arguments
- Same help text format
- Same exit codes
- Same error messages

Users should not notice any change in behavior - this is a framework swap, not a UX change.

### Interface Contract

```bash
# Current Thor pattern (BEFORE)
ace-git-worktree create --task 178
ace-taskflow task 150
ace-review --preset pr --task 121
ace-search "pattern" --file

# dry-cli pattern (AFTER) - IDENTICAL user interface
ace-git-worktree create --task 178
ace-taskflow task 150
ace-review --preset pr --task 121
ace-search "pattern" --file
```

**Error Handling:**
- Invalid option: Same error message format as Thor
- Missing required argument: Same error message format
- Unknown command: Same help text display

**Edge Cases:**
- `-h` and `--help` work on any command/subcommand
- Default commands work without explicit subcommand name
- Options with values: `--task 178` and `--task=178` both work

### Success Criteria

- [ ] All 13+ ACE CLI gems migrated to dry-cli
- [ ] All existing CLI tests pass without modification
- [ ] Help text format preserved (or improved)
- [ ] Exit codes unchanged
- [ ] No user-facing behavior changes
- [ ] ConfigSummary pattern still works
- [ ] Nested subcommands work natively (no workarounds)

### Validation Questions

- [ ] Should we maintain backward compatibility with Thor during transition?
- [ ] Do we need an abstraction layer (ace-cli-base) or direct dry-cli usage?
- [ ] Should we migrate all gems at once or incrementally?
- [ ] How do we handle `Ace::Core::CLI::Base` - rewrite or replace?

## Objective

Replace Thor CLI framework with dry-cli to eliminate:
1. Option consumption conflicts (`stop_on_unknown_option!` workarounds)
2. Nested subcommand limitations (Thor issue #489 - open since 2014)
3. Default command workarounds
4. Help flag handling boilerplate

## Background: Why Thor Doesn't Fit ACE

### Thor Limitations Discovered (Task 150 Post-Mortem)

1. **Option Consumption Conflict**
   - Thor consumes declared options before calling method
   - When using `*args`, options are NOT passed through
   - Required `stop_on_unknown_option!` workaround
   - Bug: `ace-git-worktree create --task 178` showed help (fixed in 0.10.1)

2. **Nested Subcommands Not Supported**
   - Thor issue #489 open since 2014
   - Subcommands >1 level deep require complex workarounds
   - Forces flat command structure

3. **Default Command Requires Workarounds**
   - Thor defaults to `help` method
   - Manual handling needed for implicit default commands

4. **Help Flag Boilerplate**
   - `-h` not automatically handled in subcommands
   - Required `if args.first == "--help"` checks everywhere

### Why dry-cli Fits Better

1. **Commands as Objects** - matches our `Commands::*Command` pattern
2. **Native Nested Subcommands** - register "worktree create", command
3. **Options Passed to `call`** - no consumption/pass-through conflicts
4. **Clean Registration** - explicit command → class mapping

## Scope of Work

### Phase 1: Foundation (Spike)
- Create `ace-cli` gem as dry-cli wrapper
- Implement base patterns (options, help, version)
- Migrate ONE gem as proof of concept (suggest: ace-search - simple)

### Phase 2: Core Infrastructure
- Replace `Ace::Core::CLI::Base` with dry-cli base
- Update ConfigSummary integration
- Create migration guide for other gems

### Phase 3: Gem Migration (Incremental)
Migrate in dependency order:
1. `ace-search` (simple, few commands)
2. `ace-lint` (simple, single command)
3. `ace-docs` (moderate complexity)
4. `ace-context` (moderate)
5. `ace-nav` (moderate)
6. `ace-git` (moderate)
7. `ace-git-commit` (simple)
8. `ace-git-secrets` (moderate)
9. `ace-git-worktree` (complex - nested commands, options)
10. `ace-taskflow` (complex - many subcommands)
11. `ace-review` (moderate)
12. `ace-prompt` (moderate)
13. `ace-test-runner` (simple)

### Phase 4: Cleanup
- Remove Thor dependency from all gems
- Update documentation
- Archive Thor-specific code

## Technical Details

### Current Thor Pattern

```ruby
# ace-git-worktree/lib/ace/git/worktree/cli.rb
require "ace/core/cli/base"

class CLI < Ace::Core::CLI::Base
  stop_on_unknown_option! :create, :switch  # WORKAROUND

  desc "create [BRANCH]", "Create worktree"
  # option :task removed - conflicts with args passing
  def create(*args)
    if args.first == "--help"  # WORKAROUND
      invoke :help, ["create"]
      return 0
    end
    Commands::CreateCommand.new.run(args)
  end
end
```

### Target dry-cli Pattern

```ruby
# ace-git-worktree/lib/ace/git/worktree/cli.rb
require "dry/cli"

module Ace::Git::Worktree
  module CLI
    extend Dry::CLI::Registry

    class Create < Dry::CLI::Command
      desc "Create a new worktree"

      argument :branch, required: false, desc: "Branch name"
      option :task, type: :string, desc: "Create for task ID"
      option :pr, type: :string, desc: "Create for PR number"
      option :dry_run, type: :boolean, default: false, desc: "Preview only"

      def call(branch: nil, **options)
        # Options directly available - no parsing needed
        if options[:task]
          create_task_worktree(options[:task], options)
        elsif options[:pr]
          create_pr_worktree(options[:pr], options)
        else
          create_traditional_worktree(branch, options)
        end
      end
    end

    # Clean registration - supports nested commands natively
    register "create", Create
    register "list", List
    register "switch", Switch
    register "remove", Remove
  end
end

# exe/ace-git-worktree
Dry::CLI.new(Ace::Git::Worktree::CLI).call
```

### ConfigSummary Integration

```ruby
class Create < Dry::CLI::Command
  def call(**options)
    display_config_summary("create", options) unless options[:quiet]
    # ... rest of command
  end

  private

  def display_config_summary(command, options)
    Ace::Core::Atoms::ConfigSummary.display(
      command: command,
      config: Ace::Git::Worktree.config,
      defaults: {},
      options: options,
      quiet: options[:quiet]
    )
  end
end
```

### Migration Checklist per Gem

- [ ] Add `dry-cli` dependency to gemspec
- [ ] Create new CLI module with `Dry::CLI::Registry`
- [ ] Convert each Thor method to dry-cli Command class
- [ ] Update exe/ entry point
- [ ] Run existing tests (should pass without changes)
- [ ] Remove Thor dependency
- [ ] Update CHANGELOG

## Deliverables

### Behavioral Specifications
- CLI behavior unchanged for all commands
- Help text preserved or improved
- Error handling consistent

### Validation Artifacts
- All existing CLI tests pass
- Manual testing checklist for each gem
- Integration tests for complex scenarios

## Out of Scope

- New CLI features (this is framework swap only)
- CLI redesign or command restructuring
- Performance optimization
- New command additions

## References

- Retro: `.ace-taskflow/v.0.9.0/retros/2026-01-06-thor-cli-migration-challenges.md`
- dry-cli docs: https://dry-rb.org/gems/dry-cli/1.1/
- dry-cli subcommands: https://dry-rb.org/gems/dry-cli/1.1/commands-with-subcommands-and-params/
- Thor issue #489: https://github.com/rails/thor/issues/489
- Task 150: CLI Standardization (Thor migration)
- Hotfix: ace-git-worktree 0.10.1 (Thor option bug)
