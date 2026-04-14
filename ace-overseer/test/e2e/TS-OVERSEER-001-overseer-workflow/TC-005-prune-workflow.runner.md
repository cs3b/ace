# Goal 5 — Prune Workflow

## Goal

Test the full prune lifecycle: complete task 8pp.t.q7w assignment, then prune its worktree while preserving active task 8pp.t.r8x.

Execute the steps below **in exact order**. Do not reorder, skip, or improvise additional steps.

## Workspace

Save all output to `results/tc/05/`.

## Steps

### Step 1 — Mark task 8pp.t.q7w as done

Run `ace-task done 8pp.t.q7w` to mark the task as done.

### Step 2 — Resolve task 8pp.t.q7w worktree path

Run `ace-git-worktree list` and identify the worktree path for task 8pp.t.q7w.
Set `TASK_Q7W_WORKTREE` to this path for use in later steps.

### Step 3 — Check assignment status BEFORE completion

Run `(cd "$TASK_Q7W_WORKTREE" && ace-assign status --format json)` from the task worktree.
If this command succeeds, capture it for debugging as:
- `results/tc/05/task-q7w-assign-status-before.stdout`
- `results/tc/05/task-q7w-assign-status-before.stderr`
- `results/tc/05/task-q7w-assign-status-before.exit`
Do not fail the goal solely because the "before" status captures are absent; the required oracle is the completion/prune flow below.

### Step 4 — Complete task 8pp.t.q7w assignment

Create the step report file under sandbox scratch space, for example `.ace-local/e2e-inputs/tc05/task-q7w-step-report.md`.
Run `(cd "$TASK_Q7W_WORKTREE" && ace-assign finish --message "<scratch-path>/task-q7w-step-report.md")`.
Capture output to:
- `results/tc/05/task-q7w-assign-report.stdout`
- `results/tc/05/task-q7w-assign-report.stderr`
- `results/tc/05/task-q7w-assign-report.exit`

### Step 5 — Check assignment status AFTER completion

Run `(cd "$TASK_Q7W_WORKTREE" && ace-assign status --format json)` from the task worktree.
Capture output to:
- `results/tc/05/task-q7w-assign-status-after.stdout`
- `results/tc/05/task-q7w-assign-status-after.stderr`
- `results/tc/05/task-q7w-assign-status-after.exit`

Verify the assignment state is `completed` before proceeding.

### Step 6 — Prune dry-run

Return to the sandbox root before prune.
Run `ace-overseer prune --dry-run`.
Capture output to:
- `results/tc/05/dry-run.stdout`
- `results/tc/05/dry-run.stderr`
- `results/tc/05/dry-run.exit`

### Step 7 — Prune actual

Run `ace-overseer prune --yes`.
Capture output to:
- `results/tc/05/prune.stdout`
- `results/tc/05/prune.stderr`
- `results/tc/05/prune.exit`

### Step 8 — Worktree list after prune

Run `ace-git-worktree list`.
Capture output to:
- `results/tc/05/worktree-list-after-prune.stdout`
- `results/tc/05/worktree-list-after-prune.stderr`
- `results/tc/05/worktree-list-after-prune.exit`

The q7w worktree must NOT appear in this listing. The r8x worktree must still appear.

### Step 9 — Final dry-run (no more candidates)

Run `ace-overseer prune --dry-run`.
Capture output to:
- `results/tc/05/dry-run-final.stdout`
- `results/tc/05/dry-run-final.stderr`
- `results/tc/05/dry-run-final.exit`

## Constraints

- Do **not** use assignment prune mode/flags (for example `--assignment`).
- Do **not** use `--force`.
- Do **not** pass positional prune targets (for example `ace-overseer prune 8pp.t.q7w ...`).
- Do not create helper context-tracking files under `results/`.
- If normal prune returns 0 candidates or prunes 0 worktrees, capture that outcome and continue; do not run alternate prune modes.
- All artifacts must come from real tool execution, not fabricated.
- Mention the resolved q7w worktree path in final runner observations.
