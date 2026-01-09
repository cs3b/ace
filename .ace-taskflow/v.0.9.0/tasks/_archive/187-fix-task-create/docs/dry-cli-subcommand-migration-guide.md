# dry-cli Subcommand Migration Guide

## Purpose

Audit and migrate all ace-* CLI tools to use proper dry-cli nested subcommand registration, ensuring each subcommand has its own `--help` and proper argument handling.

## Problem Statement

The Thor-to-dry-cli migration left some commands in a hybrid state where:
- Top-level commands are dry-cli based
- Subcommands use legacy "wrapper" pattern that passes args to old command classes
- This causes: missing `--help` for subcommands, broken argument parsing, confusing errors

### Symptoms of Legacy Pattern

```bash
# Proper nested subcommand (works)
ace-taskflow task create --help     # Shows Create command help

# Legacy wrapper pattern (broken)
ace-taskflow task move --help       # ERROR: "ace-taskflow task" was called with arguments "move --help"
ace-taskflow task move 187 --child-of self  # Same error
```

## Audit Process

### Step 1: Identify All CLI Entry Points

Scan for CLI registries in ace-* packages:

```bash
# Find all dry-cli registries
fd -e rb . | xargs grep -l "extend Dry::CLI::Registry" | head -20

# Expected locations:
# ace-*/lib/ace/*/cli.rb
# ace-*/lib/ace/*.rb (some have CLI in main module)
```

### Step 2: List All Registered Commands

For each CLI registry, extract command registrations:

```bash
# Find all register statements
grep -rn "register " ace-*/lib/ace/*/cli.rb | grep -v "#"
```

### Step 3: Identify Legacy Wrapper Pattern

Look for these indicators in command classes:

```ruby
# LEGACY PATTERN - options[:args] usage
def call(**options)
  args = options[:args] || []  # <-- This is the problem
  command = SomeCommand.new(args, options)
  command.execute
end

# LEGACY PATTERN - no argument definitions, expects passthrough
class Task < Dry::CLI::Command
  # No `argument` declarations
  # Relies on options[:args] which dry-cli doesn't populate
end
```

Search command:
```bash
grep -rn "options\[:args\]" ace-*/lib/
```

### Step 4: Test Each Subcommand for --help

For each identified subcommand, verify it has proper help:

```bash
# Test pattern
ace-<tool> <command> <subcommand> --help

# Examples to test
ace-taskflow task create --help    # Should work
ace-taskflow task move --help      # Should work (currently broken)
ace-taskflow task show --help      # Should work (currently broken)
ace-git-commit commit --help       # Check this
ace-nav resolve --help             # Check this
```

## Migration Pattern

### Before (Legacy Wrapper)

```ruby
# cli.rb
module CLI
  extend Dry::CLI::Registry

  register "task", CLI::Task.new  # Single wrapper for all subcommands
end

# cli/task.rb - Legacy wrapper
class Task < Dry::CLI::Command
  def call(**options)
    args = options[:args] || []  # dry-cli doesn't populate this!
    command = TaskCommand.new(args, options)
    command.execute  # Dispatches to create/move/show/etc internally
  end
end
```

### After (Proper Nested Subcommands)

```ruby
# cli.rb
module CLI
  extend Dry::CLI::Registry

  # Base command for showing task (when no subcommand given)
  register "task", CLI::Task.new

  # Each subcommand is a proper nested command
  register "task create", Commands::Task::Create
  register "task move", Commands::Task::Move
  register "task show", Commands::Task::Show
  register "task start", Commands::Task::Start
  register "task done", Commands::Task::Done
  # ... etc
end

# commands/task/move.rb - Proper nested command
module Commands
  module Task
    class Move < Dry::CLI::Command
      include Ace::Core::CLI::DryCli::Base

      desc "Move a task to a different location"

      argument :task_ref, required: true, desc: "Task reference (e.g., 187)"

      option :"child-of", type: :string, desc: "Make subtask of specified parent"
      option :release, type: :string, desc: "Move to specified release"
      option :"dry-run", type: :boolean, aliases: ["-n"], desc: "Preview without moving"

      def call(task_ref:, **options)
        # Call business logic directly (TaskManager)
        manager = Organisms::TaskManager.new
        result = manager.move_task(task_ref, options)
        # ... handle result
      end
    end
  end
end
```

## Key Principles

### 1. Each Subcommand Gets Its Own Class

```
commands/
  task/
    create.rb    # Commands::Task::Create
    move.rb      # Commands::Task::Move
    show.rb      # Commands::Task::Show
    start.rb     # Commands::Task::Start
    done.rb      # Commands::Task::Done
```

### 2. Call Business Logic Directly

Don't rebuild args arrays to pass to legacy command classes. Call the organism/manager directly:

```ruby
# BAD - rebuilding args for legacy command
args = build_args_for_move(task_ref, options)
command = TaskCommand.new(args, options)
command.move_task(args)

# GOOD - call business logic directly
manager = Organisms::TaskManager.new
result = manager.move_task(task_ref, target: options[:target])
```

### 3. Define All Arguments and Options Explicitly

```ruby
argument :task_ref, required: true, desc: "Task reference"
argument :target, required: false, desc: "Target location"

option :"child-of", type: :string, desc: "Parent task"
option :"dry-run", type: :boolean, aliases: ["-n"], desc: "Preview mode"
```

### 4. Update TASK_SUBCOMMANDS Constant

Keep the routing disambiguation list in sync with registered subcommands:

```ruby
TASK_SUBCOMMANDS = %w[
  create show start done undone defer undefer move update
  add-dependency remove-dependency
].freeze

# All of these should have corresponding:
# register "task <subcommand>", Commands::Task::<Subcommand>
```

## Packages to Audit

### Priority 1 - Known Issues
- [ ] `ace-taskflow` - task subcommands (move, show, start, done, etc.)
- [ ] `ace-git-commit` - default command routing for flags

### Priority 2 - Full Audit
- [ ] `ace-context`
- [ ] `ace-nav`
- [ ] `ace-llm`
- [ ] `ace-review`
- [ ] `ace-search`
- [ ] `ace-test-runner`
- [ ] `ace-git-worktree`
- [ ] `ace-docs`
- [ ] `ace-lint`
- [ ] `ace-prompt`

## Verification Checklist

For each migrated subcommand:

- [ ] `<tool> <cmd> <subcmd> --help` shows proper help text
- [ ] Arguments are properly parsed (not in `options[:args]`)
- [ ] Options with values work (`--child-of 123`)
- [ ] Boolean options work (`--dry-run`)
- [ ] Short aliases work (`-n` for `--dry-run`)
- [ ] Error messages are clear for missing required args
- [ ] Unit tests call production code (not mirrored implementation)
- [ ] Integration tests verify end-to-end behavior

## Example Migration Task

```markdown
## Task: Migrate ace-taskflow task move to nested dry-cli subcommand

### Acceptance Criteria
1. `ace-taskflow task move --help` shows proper help
2. `ace-taskflow task move 187 --child-of 150` works
3. `ace-taskflow task move 187 --child-of self` works
4. `ace-taskflow task move 187 --release v.1.0.0` works
5. Unit tests exercise production code
6. Integration test verifies file move

### Implementation
1. Create `lib/ace/taskflow/commands/task/move.rb`
2. Register in cli.rb: `register "task move", Commands::Task::Move`
3. Call `TaskManager#move_task` directly
4. Add tests in `test/commands/task/move_test.rb`
```

## Related Documentation

- ADR-023: dry-cli Framework Migration
- docs/ace-gems.g.md: CLI Standards
- ace-support-core: DryCli::Base module
