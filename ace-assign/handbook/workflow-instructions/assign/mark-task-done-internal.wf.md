# mark-task-done-internal

## Purpose

Mark a task as done and verify the state transition persisted.

## Steps

1. Run `ace-task update <taskref> --set status=done --move-to archive --git-commit`.
2. Verify with `ace-task show <taskref>` and confirm `status: done`.
3. If the task has a parent, check whether siblings are all done; when true, mark the parent done and verify.
4. Repeat upward only while all siblings remain done.
