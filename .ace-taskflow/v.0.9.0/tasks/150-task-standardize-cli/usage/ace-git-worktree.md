# ace-git-worktree CLI Interface

## Current Implementation

- **Framework**: Custom case/when routing (NOT Thor)
- **Entry Point**: `ace-git-worktree/lib/ace/git/worktree/cli.rb`
- **Lines of Code**: 196
- **Migration Needed**: Yes

## Commands

### create
Create new worktree with task-aware naming.

**Options**: `--task`, `--branch`, `--path`

### list (alias: ls)
List all worktrees with optional task info.

**Options**: `--show-tasks`, `--json`

### switch (alias: cd)
Switch to worktree by task ID or name.

### remove (alias: rm)
Remove worktree.

**Options**: `--task`, `--force`

### prune
Clean up deleted worktrees.

### config
Show/manage configuration.

**Examples**:
```bash
ace-git-worktree create --task 081     # Create task-aware worktree
ace-git-worktree list --show-tasks     # List with task info
ace-git-worktree switch 081            # Switch to task worktree
ace-git-worktree remove --task 081     # Remove by task
ace-git-worktree prune                 # Clean up
ace-git-worktree config                # Show config
```

## Command Aliases

- `ls` → `list`
- `cd` → `switch`
- `rm` → `remove`

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/git/worktree/cli.rb
class CLI < Thor
  desc "create", "Create new worktree"
  option :task, type: :string, desc: "Task ID for naming"
  option :branch, type: :string, desc: "Branch name"
  option :path, type: :string, desc: "Worktree path"
  option :quiet, type: :boolean, aliases: "-q"
  def create
    require_relative "commands/create_command"
    Commands::CreateCommand.new(options).execute
  end

  desc "list", "List all worktrees"
  option :show_tasks, type: :boolean, desc: "Show task info"
  option :json, type: :boolean, desc: "JSON output"
  def list
    require_relative "commands/list_command"
    Commands::ListCommand.new(options).execute
  end
  map "ls" => :list

  desc "switch REF", "Switch to worktree"
  def switch(ref)
    require_relative "commands/switch_command"
    Commands::SwitchCommand.new(ref, options).execute
  end
  map "cd" => :switch

  desc "remove", "Remove worktree"
  option :task, type: :string, desc: "Task ID"
  option :force, type: :boolean, aliases: "-f"
  def remove
    require_relative "commands/remove_command"
    Commands::RemoveCommand.new(options).execute
  end
  map "rm" => :remove

  desc "prune", "Clean up deleted worktrees"
  def prune
    require_relative "commands/prune_command"
    Commands::PruneCommand.new(options).execute
  end

  desc "config", "Show configuration"
  def config
    require_relative "commands/config_command"
    Commands::ConfigCommand.new(options).execute
  end
end
```

### Migration Notes

- Already has Commands:: pattern - straightforward wrap
- Use Thor `map` for aliases (ls, cd, rm)
- Each command class exists, just need Thor CLI wrapper
- Add ConfigSummary integration at top level
