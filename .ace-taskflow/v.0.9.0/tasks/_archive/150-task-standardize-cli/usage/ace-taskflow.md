# ace-taskflow CLI Interface

## Current Implementation

- **Framework**: Custom case/when routing with lazy command loading
- **Entry Point**: `ace-taskflow/lib/ace/taskflow/cli.rb`
- **Lines of Code**: 152 (CLI) + 10+ command files
- **Migration Needed**: Yes

## Commands

### status
Show current taskflow status and activity.

**Options**: `--json`, `--markdown`, `--recently-done-limit N`, `--up-next-limit N`, `--include-drafts`, `--no-activity`

### doctor
Run health checks and auto-fix issues.

### migrate
Migrate folder structure to new naming convention.

### config
Show current configuration.

### idea
Operations on single ideas.

**Subcommands**: create, done, park, unpark, reschedule, to-task, archive, validate-structure, show

### ideas
Browse and list multiple ideas.

**Options**: `--filter`, `--limit`, `--stats`, `--tree`, `--path`, `--list`, `--days`, `--sort`, `--subtasks`, `--no-subtasks`, `--flat`, `--release`, `--backlog`

### task
Operations on single tasks.

**Subcommands**: next, show, create, start, done, undone, defer, undefer, move, update, add-dependency, remove-dependency

**Options**: `--path`, `--content`, `--tree`

### tasks
Browse and list multiple tasks.

**Options**: `--filter`, `--limit`, `--days`, `--stats`, `--tree`, `--path`, `--list`, `--subtasks`, `--no-subtasks`, `--flat`, `--release`, `--backlog`, `--sort`

### release
Operations on single releases.

**Subcommands**: show, create, promote, demote, reschedule, validate, changelog

**Options**: `--path`, `--content`, `--subfolder`

### releases
Browse and list multiple releases.

**Options**: `--filter`, `--stats`, `--limit`, `--sort`

### retro
Operations on single retrospective notes.

**Subcommands**: create, show, done

**Options**: `--release`, `--current`, `--backlog`

### retros
Browse and list retrospective notes.

**Options**: `--release`, `--current`, `--backlog`, `--all`, `--done`, `--limit`

**Examples**:
```bash
ace-taskflow task                    # Show next task
ace-taskflow tasks --status pending  # List pending tasks
ace-taskflow release                 # Show active release
ace-taskflow idea create 'Add caching'  # Capture idea
ace-taskflow status --json           # Status as JSON
ace-taskflow doctor                  # Health check
```

## Design Patterns

- **Singular/Plural**: `task`/`tasks`, `idea`/`ideas`, etc.
- **Lazy Loading**: Commands loaded only when needed
- **Cache Clearing**: Caches cleared at CLI start

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/taskflow/cli.rb
class CLI < Thor
  def self.start(args = ARGV, config = {})
    clear_caches!
    super
  end

  desc "status", "Show current taskflow status"
  option :json, type: :boolean
  option :markdown, type: :boolean
  option :recently_done_limit, type: :numeric
  option :up_next_limit, type: :numeric
  option :include_drafts, type: :boolean
  option :no_activity, type: :boolean
  option :quiet, type: :boolean, aliases: "-q"
  def status
    require_relative "commands/status_command"
    Commands::StatusCommand.new.execute(options_to_args)
  end

  desc "task SUBCOMMAND", "Task operations"
  subcommand "task", TaskCLI

  desc "tasks [PRESET]", "List tasks"
  option :filter, type: :string
  option :limit, type: :numeric
  # ... other options
  def tasks(preset = nil)
    require_relative "commands/tasks_command"
    Commands::TasksCommand.new.execute(build_args(preset))
  end

  # Similar for idea/ideas, release/releases, retro/retros

  desc "doctor", "Run health checks"
  def doctor
    require_relative "commands/doctor_command"
    Commands::DoctorCommand.new.execute([])
  end

  desc "config", "Show configuration"
  def config
    show_config
    0
  end
end

# Nested Thor for task subcommands
class TaskCLI < Thor
  desc "show REF", "Show task"
  def show(ref)
    # ...
  end

  desc "create TITLE", "Create task"
  def create(title)
    # ...
  end

  # ... other subcommands
end
```

### Migration Notes

- Most complex migration due to:
  - 12+ subcommands with their own subcommands
  - Singular/plural pattern (task/tasks)
  - Lazy command loading for performance
  - Cache clearing at start
- Options:
  1. Thor subcommands (nested `TaskCLI`, `IdeasCLI`, etc.)
  2. Single Thor class with many commands
  3. Hybrid: main commands in CLI, delegate to existing command classes
- Recommend: Hybrid approach - wrap existing command classes
- Preserve lazy loading pattern with require_relative
- Add ConfigSummary at top-level start
