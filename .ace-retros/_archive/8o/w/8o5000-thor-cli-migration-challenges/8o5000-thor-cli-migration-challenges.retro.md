---
id: 8o5000
title: Thor CLI Migration - Challenges and Alternatives
type: standard
tags: []
created_at: "2026-01-06 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8o5000-thor-cli-migration-challenges.md
---
# Reflection: Thor CLI Migration - Challenges and Alternatives

**Date**: 2026-01-06
**Context**: Post-mortem on Task 150 CLI Standardization - Thor migration across 13+ ACE gems
**Author**: Development Team
**Type**: Standard

## What Went Well

- Achieved consistent CLI structure across all ACE packages
- ConfigSummary pattern provides visibility into effective configuration
- Standard options (`--quiet`, `--verbose`, `--debug`) now work uniformly
- Thor's `desc` and `long_desc` provide excellent auto-generated help

## What Could Be Improved

- Thor's option parsing conflicts with command-specific argument handling
- Multiple bugs introduced during migration required immediate hotfixes
- Thor's behavior with `*args` variadic parameters is counterintuitive
- Nested subcommands (>1 level deep) are not well-supported
- Default command behavior requires workarounds

## Key Learnings

- Thor was designed primarily for Rails scaffolding, not general-purpose CLIs
- Our use case (command handlers with their own argument parsing) conflicts with Thor's design
- `stop_on_unknown_option!` is essential when delegating to command handlers
- Thor consumes options declared with `option :name` even when using `*args` parameters

## Challenge Patterns Identified

### High Impact Issues

- **Option Consumption Conflict**: Thor consumed `--task 178` instead of passing to CreateCommand
  - Occurrences: At least 1 critical bug (ace-git-worktree), likely more undiscovered
  - Impact: Commands showing help instead of executing - blocking user workflows
  - Root Cause: Thor parses declared options before calling method, leaving `*args` empty

- **Nested Subcommand Limitations**: Thor doesn't support subcommands >1 level deep
  - Occurrences: Known Thor issue #489 (open since 2014)
  - Impact: Forces flat command structure or complex workarounds
  - Root Cause: Thor's architecture wasn't designed for deeply nested commands

### Medium Impact Issues

- **Default Command Behavior**: Thor defaults to `help` without workarounds
  - Occurrences: Required manual handling in multiple packages
  - Impact: Extra code in each CLI to handle implicit default commands

- **Help Flag Handling**: Thor doesn't automatically handle `-h` in subcommands
  - Occurrences: Required explicit checks in all command methods
  - Impact: Boilerplate code like `if args.first == "--help"` scattered everywhere

## Alternative CLI Frameworks Researched

### dry-cli (Recommended for ACE use case)

**Pros:**
- Purpose-built for CLI development with nested subcommands
- Commands as objects - matches our existing Command pattern
- Native support for subcommands with their own arguments/options
- Part of well-maintained dry-rb ecosystem
- Clear separation between command registration and execution

**Cons:**
- Migration effort from Thor
- Less widespread adoption than Thor

**Documentation:** [dry-cli v1.1](https://dry-rb.org/gems/dry-cli/1.1/)

### GLI (Git-Like Interface)

**Pros:**
- Infinitely nested subcommands - explicitly designed for this
- Block-based DSL for command definition
- Battle-tested (used in many production CLIs)

**Cons:**
- Different paradigm from current object-based commands
- May require more significant refactoring

**Documentation:** [GLI GitHub](https://github.com/davetron5000/gli)

### TTY Toolkit

**Pros:**
- Modular approach - use only what you need
- Rich ecosystem (prompts, tables, spinners, etc.)
- Commands as plain Ruby classes

**Cons:**
- More complex setup
- Larger dependency footprint

**Documentation:** [TTY GitHub](https://github.com/piotrmurach/tty)

### Keep OptionParser (Simplest)

**Pros:**
- Zero dependencies (Ruby stdlib)
- Full control over parsing behavior
- Already proven pattern in our original CLI

**Cons:**
- More boilerplate for help generation
- No built-in subcommand support

## Action Items

### Stop Doing

- Declaring Thor `option` for commands that delegate to their own argument parsers
- Assuming Thor will pass-through arguments to `*args` when options are declared

### Continue Doing

- Using `stop_on_unknown_option!` for commands with their own parsing
- ConfigSummary pattern for configuration visibility
- Command classes with their own `run(args)` method signature

### Start Doing

- Evaluate dry-cli for future CLI development (create spike task)
- Document Thor limitations in ace-gems.g.md
- Consider gradual migration path to dry-cli starting with new gems
- Add integration tests that verify actual CLI behavior, not just Thor routing

## Technical Details

### Thor Workaround Applied (ace-git-worktree)

```ruby
class CLI < Ace::Core::CLI::Base
  # Prevent Thor from consuming command-specific options
  stop_on_unknown_option! :create, :switch, :remove, :prune, :list

  # Remove option declarations - let commands parse themselves
  def create(*args)
    Commands::CreateCommand.new.run(args)  # args now contains ["--task", "178"]
  end
end
```

### dry-cli Equivalent Pattern

```ruby
module Ace::Git::Worktree
  module Commands
    extend Dry::CLI::Registry

    class Create < Dry::CLI::Command
      desc "Create a new worktree"
      argument :branch, desc: "Branch name (optional)"
      option :task, desc: "Create worktree for task"
      option :pr, desc: "Create worktree for PR"

      def call(branch: nil, **options)
        # Direct access to parsed options - no delegation needed
      end
    end

    register "create", Create
  end
end
```

## Proposed Migration Strategy

1. **Immediate (v.0.9.x)**: Keep Thor with `stop_on_unknown_option!` workarounds
2. **Short-term**: Create ace-cli-base gem abstracting CLI framework choice
3. **Medium-term**: Spike dry-cli implementation for one new gem
4. **Long-term**: Gradual migration to dry-cli if spike proves successful

## Additional Context

- PR #123: CLI Standardization - Thor migration
- PR #124: Fix config summary on --help
- Hotfix: ace-git-worktree 0.10.1 - Thor option consumption bug
- Thor Issue #489: [Nested commands not supported](https://github.com/rails/thor/issues/489)
- Blog: [Fixing Thor's CLI Quirks](https://mattbrictson.com/blog/fixing-thor-cli-behavior)

## Sources

- [Thor GitHub](https://github.com/rails/thor)
- [dry-cli Documentation](https://dry-rb.org/gems/dry-cli/1.1/)
- [GLI GitHub](https://github.com/davetron5000/gli)
- [Hanami Mastery: Advanced CLI with dry-cli](https://hanamimastery.com/episodes/37-dry-cli)
- [dry-cli Subcommands with Params](https://dry-rb.org/gems/dry-cli/1.1/commands-with-subcommands-and-params/)
