# Plan: Auto-Convert to Orchestrator + Archive Idempotency

## Context

Two bugs surfaced during the task-281 drafting session:

1. `ace-task create "X" --child-of 281` and `ace-task move 282 --child-of 281` both fail when 281 is a regular (non-orchestrator) task. The user must manually run `ace-task move 281 --child-of self` first. The fix: **auto-convert** the parent to orchestrator when needed.

2. `ace-idea done` on an idea already in `_archive/` moves it to `_archive/_archive/` (double-nesting). The `TaskDirectoryMover` has idempotence protection but `IdeaDirectoryMover` doesn't. The fix: **treat archive as terminal state** — return success without moving.

## Meta Observation

This plan was produced by the selfimprove workflow and represents an "implementation-first" approach — it jumped straight to code diffs and file modifications. The experiment (task 281) is to compare this against the "behavior-first" approach: drafting specs using the 3-Question Delegation Brief before touching code.

---

## Fix 1: Auto-Convert Parent to Orchestrator

### What Changes

Both `create_subtask` and `demote_to_subtask` in `TaskManager` currently fail when the parent isn't an orchestrator. Instead, they should auto-convert the parent first, then proceed.

### Files to Modify

**`ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb`**

**In `create_subtask` (lines 193-199)** — replace the error return:

```ruby
# Current (lines 193-199):
unless is_orchestrator_directory?(parent_dir, parent_number)
  return {
    success: false,
    message: "Task #{parent_number} is not an orchestrator..."
  }
end

# New:
unless is_orchestrator_directory?(parent_dir, parent_number)
  conversion = convert_to_orchestrator(parent_ref)
  unless conversion[:success]
    return { success: false, message: "Failed to auto-convert task #{parent_number} to orchestrator: #{conversion[:message]}" }
  end
  # Re-resolve parent_dir since conversion moved files
  parent_dir = find_parent_task_directory(release_path, parent_number)
end
```

**In `demote_to_subtask` (lines 868-874)** — same pattern:

```ruby
# Current (lines 868-874):
unless is_orchestrator_directory?(parent_dir, parent_number)
  return {
    success: false,
    message: "Parent task #{parent_ref} is not an orchestrator..."
  }
end

# New:
unless is_orchestrator_directory?(parent_dir, parent_number)
  conversion = convert_to_orchestrator(parent_ref)
  unless conversion[:success]
    return { success: false, message: "Failed to auto-convert parent #{parent_ref} to orchestrator: #{conversion[:message]}" }
  end
  # Re-resolve parent_dir since conversion moved files
  parent_dir = find_parent_task_directory(release_path, parent_number)
end
```

**`ace-taskflow/test/organisms/task_manager_reorganization_test.rb`**

Update `test_demote_to_subtask_parent_not_orchestrator` (line 172) — it currently expects failure; should now expect success with auto-conversion.

**`ace-taskflow/handbook/workflow-instructions/task/draft.wf.md`** (lines 102-113)

Update docs: Pattern B no longer needs step 2 (`--child-of self`). Remove the warning since auto-conversion makes it unnecessary. Keep the note that the original content becomes subtask `.01`.

**`ace-taskflow/handbook/workflow-instructions/task/draft-batch.wf.md`** (lines 42-45)

Same doc update — note auto-conversion behavior.

---

## Fix 2: Archive Idempotency for Ideas

### What Changes

`IdeaDirectoryMover.move_to_archive` should detect when an idea is already in `_archive/` and return success without moving. Same pattern as `TaskDirectoryMover`.

Also apply the same guard to `move_to_maybe` (same vulnerability with `_maybe/`).

### Files to Modify

**`ace-taskflow/lib/ace/taskflow/molecules/idea_directory_mover.rb`**

**In `move_to_archive` — add after line 18 (before normalization):**

```ruby
# Check if idea is already in archive directory (idempotent operation)
archive_dir_name = Ace::Taskflow.configuration.done_dir
if idea_path.include?("/#{archive_dir_name}/")
  # Still update metadata if possible
  update_completion_metadata_in_place(idea_path, timestamp)
  return {
    success: true,
    new_path: idea_path.is_a?(String) && File.file?(idea_path) ? File.dirname(idea_path) : idea_path,
    message: "Idea already in #{archive_dir_name}/"
  }
end
```

**In `move_to_maybe` — add after line 160 (before normalization):**

```ruby
# Check if idea is already in maybe directory (idempotent operation)
maybe_dir_name = Ace::Taskflow.configuration.maybe_dir
if idea_path.include?("/#{maybe_dir_name}/")
  return {
    success: true,
    new_path: idea_path.is_a?(String) && File.file?(idea_path) ? File.dirname(idea_path) : idea_path,
    message: "Idea already in #{maybe_dir_name}/"
  }
end
```

**Also change target-exists checks (lines 43-49, 182-188)** — return success (idempotent) instead of failure, matching `TaskDirectoryMover` behavior.

**Add private helper `update_completion_metadata_in_place`** — updates frontmatter (status: done, completed_at) for the already-archived idea without moving it. Reuses the existing `update_idea_completion_metadata` logic, finding the right .md file in the folder.

**`ace-taskflow/test/molecules/idea_directory_mover_test.rb`**

Add two tests:
- `test_move_to_archive_idempotent_when_already_archived` — idea in `_archive/`, call `move_to_archive`, assert `success: true`, path unchanged, no `_archive/_archive/` created
- `test_move_to_maybe_idempotent_when_already_in_maybe` — same for `_maybe/`

---

## Execution Order

1. Fix 2 first (IdeaDirectoryMover) — smaller, self-contained
2. Fix 1 (TaskManager auto-convert) — slightly more complex
3. Update handbook docs (draft.wf.md, draft-batch.wf.md)
4. Run `ace-test` in ace-taskflow to verify

## Verification

- `ace-test test/molecules/idea_directory_mover_test.rb` — new idempotency tests pass
- `ace-test test/organisms/task_manager_reorganization_test.rb` — updated auto-convert test passes
- `ace-test` — full ace-taskflow suite passes
- Manual: create a flat task, then `ace-task create "child" --child-of <flat-task>` succeeds without manual conversion
