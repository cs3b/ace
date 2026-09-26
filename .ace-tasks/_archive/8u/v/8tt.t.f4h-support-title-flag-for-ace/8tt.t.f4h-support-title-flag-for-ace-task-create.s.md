---
id: 8tt.t.f4h
status: done
priority: medium
created_at: "2026-06-30 10:04:59"
estimate: TBD
dependencies: []
tags: []
---

# Support title flag for ace-task create compatibility

## Behavioral Specification

### User Experience

- **Input:** A developer or agent runs `ace-task create --title "Some task" --status draft`, following older workflow guidance or a common flag-based CLI pattern.
- **Process:** `ace-task create` accepts the explicit `--title` value as the task title, equivalent to the current positional `TITLE` argument.
- **Output:** The task is created or previewed successfully with the supplied title, and agents no longer hit `invalid option: --title` when following task workflow examples.

### Expected Behavior

`ace-task create` should support both title input styles:

```bash
ace-task create "Fix login bug" --status draft
ace-task create --title "Fix login bug" --status draft
```

Both commands should create the same kind of task. `--dry-run` should also work with either form and print the resolved title in the preview output.

If both positional `TITLE` and `--title` are provided, the command should fail with an actionable error instead of guessing which title wins.

### Interface Contract

```bash
ace-task create --title "Document completed work" --status done
# Expected: creates a task titled "Document completed work"

ace-task create --title "Preview task" --status draft --dry-run
# Expected: prints "Would create task" and "Title: Preview task"; writes no task files

ace-task create "Positional title" --title "Flag title" --dry-run
# Expected: exits non-zero with an actionable conflict error
```

Error Handling:

- Missing title in both forms should continue to fail as a required-title error.
- Providing both title forms should fail with a message that tells users to choose either positional `TITLE` or `--title`.
- Existing validation for status, GitHub issue, parent task, folder, tags, and estimate should be unchanged.

Edge Cases:

- `--title` should work with `--child-of`, `--in`, `--github-issue`, `--git-commit`, and `--dry-run` the same way positional titles work.
- Title strings containing spaces should not require different quoting than positional titles.
- Existing help should document both accepted title styles so agents choose valid syntax.

## Success Criteria

- `ace-task create --title "Probe title flag" --status draft --dry-run` no longer reports `invalid option: --title`.
- Positional title creation remains backward compatible.
- Supplying both positional and flag title values fails with a clear conflict error.
- Workflow/docs examples that currently teach `ace-task create --title ...` are either valid because the flag is supported or updated to match the canonical examples.
- Regression tests cover `--title`, positional title, conflict handling, and dry-run behavior.

## Validation Questions

- None open. Default behavior is to accept `--title` for compatibility rather than only correcting stale docs, because agents have already learned and reused the flag form.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Standalone task.
- **Slice outcome:** Agents and developers can create tasks with either positional `TITLE` or `--title`, with clear conflict handling.
- **Advisory size:** Small.
- **Context dependencies:** `ace-task` create command, command tests, task workflow docs that mention `--title`, and `ace-support-cli` argument/option behavior.

## Verification Plan

### Unit/Component Validation

- Add command coverage for `ace-task create --title "Flag title" --dry-run`.
- Add command coverage for real task creation with `--title`.
- Add command coverage that positional `TITLE` still works.
- Add command coverage that positional `TITLE` plus `--title` exits with a clear conflict error.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- If CLI help or workflow examples are updated, verify help output includes a valid `--title` example or no longer teaches invalid syntax.

### Failure/Invalid Path Validation

- Verify `ace-task create --status draft --dry-run` without any title still fails.
- Verify invalid status handling remains unchanged when using `--title`.

### Verification Commands

- `ace-test ace-task`

## Objective

Remove a recurring agent failure mode where agents call `ace-task create --title ...` and hit `invalid option: --title. Did you mean: --tags`. The command should be resilient to the documented/common flag form while preserving existing positional usage.

## Scope of Work

- Support `--title` as an alternate input for the task title in `ace-task create`.
- Preserve the positional `TITLE` argument as the primary documented usage.
- Add clear conflict handling when both title forms are supplied.
- Update stale task workflow guidance that currently shows `ace-task create --title ...`.

## Deliverables

- Updated `ace-task create` behavior for `--title`.
- Regression tests for title input forms and conflict errors.
- Documentation or workflow example update where needed.
- Changelog entry for `ace-task` if user-visible behavior changes.

## Out of Scope

- Changing other `ace-task` command argument styles.
- Adding aliases for unrelated create options.
- Reworking task creation storage, IDs, or frontmatter.

## References

- Current runtime evidence: `ace-task create --title "Probe title flag" --status draft --dry-run` exits with `invalid option: --title. Did you mean: --tags`.
- Current accepted syntax: `ace-task create TITLE [OPTIONS]`.
- Stale workflow example: `ace-task/handbook/workflow-instructions/task/document-unplanned.wf.md` shows `ace-task create --title "..."`
