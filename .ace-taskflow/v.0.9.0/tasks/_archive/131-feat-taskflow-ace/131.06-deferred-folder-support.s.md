---
id: v.0.9.0+task.131.06
status: done
priority: medium
estimate: 2-3h
dependencies:
- v.0.9.0+task.131.02
parent: v.0.9.0+task.131
---

# Add _deferred Folder Support for Tasks

## Description

Add support for a `_deferred` folder within task directories. This folder is for tasks that are pushed to future releases - they're valid tasks but won't be completed in the current release.

## Acceptance Criteria

- [ ] Add `deferred_dir` to configuration (default: `_deferred`)
- [ ] Add `move_to_deferred` method to `TaskDirectoryMover`
- [ ] Add `task defer <ref>` command or integrate with `task move`
- [ ] Update task status to `deferred` when moving to _deferred folder
- [ ] Add `restore_from_deferred` method for reopening deferred tasks
- [ ] Update task listings to show deferred tasks separately
- [ ] All tests pass

## Implementation Notes

### Configuration

```ruby
# configuration.rb
def deferred_dir
  @deferred_dir ||= config.fetch('deferred_dir', '_deferred')
end
```

### TaskDirectoryMover Updates

```ruby
# molecules/task_directory_mover.rb
def move_to_deferred(task_path)
  # Similar to move_to_done but targets _deferred folder
  # Returns { success:, new_path:, message: }
end

def restore_from_deferred(task_path)
  # Similar to restore_from_done
  # Returns { success:, new_path:, message: }
end
```

### CLI Command Decision

**Chosen**: New subcommand (Option A) - better discoverability

```bash
ace-taskflow task defer 131.06        # Move to _deferred/
ace-taskflow task undefer 131.06      # Restore from _deferred/
```

**Rationale**:
- `task defer` is more discoverable than `task move --to deferred`
- Mirrors `task done` / `task undone` pattern
- Easier to type and remember
- Tab completion works naturally

### Task Status

- Add `deferred` to valid task statuses in StatusValidator
- When moving to _deferred: set status to `deferred`
- When restoring: set status to `pending` (or configurable via `.ace/taskflow/config.yml`)

**Schema update required**: Add `deferred` to valid status list in TaskLoader/StatusValidator

### Task Listing Behavior

`ace-taskflow tasks all` output should include deferred section:

```
v.0.9.0: 5/25 tasks • Mono-Repo Multiple Gems
Tasks: ⚫ 5 | ⚪ 2 | 🟡 3 | 🟢 10 | ⏸️ 5 | 🔴 0 • 25 total • 40% complete
========================================
  v.0.9.0+task.131 🟡 Folder Reorganization...
  ...

Deferred: 5
  v.0.9.0+task.099 ⏸️ Future feature X
  v.0.9.0+task.101 ⏸️ Nice to have Y
```

- Deferred tasks shown in separate section at bottom
- Use `⏸️` emoji for deferred status
- Include count in header summary

### Folder Structure

```
v.0.9.0/tasks/
├── _archive/         # Completed tasks
├── _deferred/        # Pushed to future release
└── 131-feat-*/       # Active tasks
```

## Related Tasks

- 131.02: Code changes for done → _archive (provides pattern)
- 131.03: undone command (similar restoration pattern)