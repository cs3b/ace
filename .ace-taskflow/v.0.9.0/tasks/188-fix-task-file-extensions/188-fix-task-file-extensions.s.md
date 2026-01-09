---
id: v.0.9.0+task.188
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Fix task file extensions from .idea.s.md to .s.md

## Objective

During migration commit `ac91ff80`, 855 task files were incorrectly renamed with `.idea.s.md` extension. Tasks should use `.s.md` extension (ideas use `.idea.s.md`). This task renames all incorrectly named task files back to the correct `.s.md` extension using `git mv`.

## Scope of Work

- Rename 855 task files from `.idea.s.md` to `.s.md` across all directories
- High priority: 22 files in backlog and v.0.9.0
- Lower priority: 833 files in archived versions

### Deliverables

#### Create
- Migration script to generate `git mv` commands
- Verification script to confirm all files renamed

#### Execute
- Execute `git mv` for all 855 task files
- Verify tasks are discoverable via `ace-taskflow tasks all`

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow tasks all` or searches for tasks
- **Process**: The system correctly identifies task files by their `.s.md` extension (not `.idea.s.md`)
- **Output**: All tasks are discoverable and listed correctly

### Expected Behavior
- Task files use `.s.md` extension (e.g., `task008.s.md`)
- Idea files use `.idea.s.md` extension (e.g., `add-feature.idea.s.md`)
- A migration script renames 855 incorrectly named task files from `.idea.s.md` to `.s.md`
- Files in `ideas/` directories are skipped (correctly named)

### Interface Contract
```bash
# Migration script generates git mv commands
/tmp/rename_tasks.sh

# Verify after migration
ace-taskflow tasks all
find .ace-taskflow/_backlog -name "*.idea.s.md"  # Should return empty
find .ace-taskflow/v.0.9.0 -name "*.idea.s.md"  # Should return empty
```

### Success Criteria
- [ ] All task files renamed: 855 files renamed from `.idea.s.md` to `.s.md`
- [ ] No task files in backlog remain with .idea.s.md extension
- [ ] No task files in current release remain with .idea.s.md extension
- [ ] Tasks are discoverable: `ace-taskflow tasks all` lists all tasks
- [ ] Idea files unaffected: Files in `ideas/` directories keep `.idea.s.md` extension

## Implementation Plan

### Planning Steps

- [ ] Finalize list of all 855 files to rename
  > TEST: Count Verification
  > Type: Pre-condition Check
  > Assert: 855 files identified with .idea.s.md extension in task directories
  > Command: # Count is 855

### Execution Steps

- [ ] Create migration script `/tmp/rename_tasks.sh`
  ```bash
  #!/bin/bash
  # Find all .idea.s.md files in task directories (not ideas)
  find /Users/mc/Ps/ace-meta/.ace-taskflow -name "*.idea.s.md" -type f | while read file; do
    # Skip if path contains "ideas" (those are correctly named)
    if echo "$file" | grep -q "ideas"; then
      continue
    fi

    # Check if file contains task frontmatter
    if head -20 "$file" | grep -q "id: v.*+task\."; then
      # Generate new filename by removing .idea part
      new_file="${file/.idea.s.md/.s.md}"

      # Generate git mv command
      echo "git mv \"$file\" \"$new_file\""
    fi
  done
  ```
- [ ] Generate and execute git mv commands for backlog files (8 files)
  > TEST: Backlog Verification
  > Type: Action Validation
  > Assert: No .idea.s.md files remain in _backlog/tasks/
  > Command: find .ace-taskflow/_backlog/tasks -name "*.idea.s.md"
- [ ] Generate and execute git mv commands for current release archived tasks (14+ files)
  > TEST: Current Release Verification
  > Type: Action Validation
  > Assert: No .idea.s.md files remain in v.0.9.0/tasks/_archive/
  > Command: find .ace-taskflow/v.0.9.0/tasks/_archive -name "*.idea.s.md"
- [ ] Generate and execute git mv commands for archived versions (833 files)
  > TEST: Archive Verification
  > Type: Action Validation
  > Assert: No .idea.s.md files remain in _archive/
  > Command: find .ace-taskflow/_archive -name "*.idea.s.md"
- [ ] Verify tasks are discoverable
  > TEST: Task Discovery
  > Type: Integration Validation
  > Assert: Tasks are listed correctly
  > Command: ace-taskflow tasks all | head -20

## Acceptance Criteria

- [ ] All 855 task files renamed from `.idea.s.md` to `.s.md`
- [ ] `git mv` used for all renames (preserves history)
- [ ] `ace-taskflow tasks all` lists all tasks correctly
- [ ] No `.idea.s.md` files remain in task directories
- [ ] Files in `ideas/` directories unchanged (keep `.idea.s.md`)

## Out of Scope

- Code changes to ace-taskflow (the core code is correct - this was a one-time migration bug)
- Updating documentation (task/idea naming is already documented correctly)

## References

- Migration commit that introduced the bug: `ac91ff80`
- ace-taskflow code:
  - `lib/ace/taskflow/organisms/task_manager.rb` (uses `.s.md` for tasks)
  - `lib/ace/taskflow/organisms/idea_writer.rb` (uses `.idea.s.md` for ideas)
