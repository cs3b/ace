# ace-task

B36TS-based task management for ACE.

## Installation

Add to your Gemfile:

```ruby
gem "ace-task"
```

## Usage

```bash
# Create a task
ace-task create "Fix login bug"
ace-task create "Fix auth" --priority high --tags auth,security
ace-task create "Setup DB" --child-of q7w    # Subtask
ace-task create "Quick task" --in next        # In _next/ folder
ace-task create "Preview" --dry-run           # Show without writing

# Show a task
ace-task show q7w                # By suffix shortcut
ace-task show 8pp.t.q7w          # By full ID
ace-task show q7w --path         # Print file path only
ace-task show q7w --content      # Raw markdown
ace-task show q7w --tree         # With subtask tree

# Resolve/generate an implementation plan
ace-task plan q7w                            # Reuse fresh plan or generate
ace-task plan q7w --refresh                  # Force regeneration
ace-task plan q7w --content                  # Print plan content
ace-task plan q7w --model gemini:flash-latest # Override model

# List tasks
ace-task list                    # All tasks
ace-task list --status pending   # Filter by status
ace-task list --in maybe         # Tasks in _maybe/ folder
ace-task list --tags urgent      # Filter by tag

# Move a task
ace-task move q7w --to archive   # Move to _archive/
ace-task move q7w --to maybe     # Move to _maybe/
ace-task move q7w --to root      # Move back to root

# Update task metadata
ace-task update q7w --set status=done
ace-task update q7w --set status=done,priority=high
ace-task update q7w --add tags=shipped
ace-task update q7w --remove tags=pending-review

# Health check
ace-task doctor                      # Full health report
ace-task doctor --auto-fix           # Auto-fix common issues
ace-task doctor --auto-fix --dry-run # Preview fixes without applying
ace-task doctor --json               # JSON output
ace-task doctor --check              # Exit 1 if issues found (CI mode)
ace-task doctor --quiet              # Summary only
```

## Task ID Format

Tasks use a type-marked B36TS ID format: `xxx.t.yyy`

- `xxx` — first 3 chars of 6-char b36ts timestamp
- `.t.` — type marker for tasks
- `yyy` — last 3 chars of 6-char b36ts timestamp

Shortcuts: use the last 3 chars (`yyy`) to reference a task.

Subtask IDs append a character: `xxx.t.yyy.a`, `xxx.t.yyy.b`, etc.

## Configuration

Default config in `.ace-defaults/task/config.yml`:

```yaml
task:
  root_dir: .ace-tasks
  default_status: pending
  file_pattern: "*.s.md"
  plan:
    model: "gemini:flash-latest"
  special_folders:
    archive: _archive
    maybe: _maybe
    anytime: _anytime
    next: _next
```

Override at project level in `.ace/task/config.yml`.

## License

MIT
