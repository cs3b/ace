---
doc-type: workflow
title: Drive Assignment Workflow
purpose: workflow instruction for driving ace-assign assignment execution
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# Drive Assignment Workflow

## Purpose

Drive agent execution through an active assignment by continuously checking status, executing the current step, and reporting completion. This is the main execution loop for working through an assignment workflow.

## Prerequisites

- An active assignment exists (created via `ace-assign create` or `/as-assign-create`)
- Assignment has at least one pending or in_progress step

## Assignment Context Propagation

When working with multiple concurrent assignments, the active assignment is resolved in this order:

1. `--assignment <id>` flag on any command (highest priority)
2. `.current` symlink (set via `ace-assign select <id>`)
3. `.latest` symlink (auto-updated on any activity)
4. Scan all assignments (fallback)

If this workflow is invoked with an argument (for example `/as-assign-drive abc123@010.01`), treat that value as the initial assignment target. If no argument is provided, resolve one active assignment and pin it for the entire loop.

```bash
# Set once from workflow argument (empty when not provided)
ASSIGNMENT_TARGET="${1:-}"

# Resolve and pin assignment identity for the full drive loop
if [ -n "$ASSIGNMENT_TARGET" ]; then
  STATUS_JSON=$(ace-assign status --assignment "$ASSIGNMENT_TARGET" --format json)
else
  # Only here: resolve active assignment once before pinning target
  STATUS_JSON=$(ace-assign status --format json)
fi
ASSIGNMENT_ID=$(echo "$STATUS_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read).dig("assignment", "id")')
if [ -z "$ASSIGNMENT_ID" ]; then
  echo "No active assignment found"
  exit 1
fi
if [ -z "$ASSIGNMENT_TARGET" ]; then
  ASSIGNMENT_TARGET="$ASSIGNMENT_ID"
fi
```

### Explicit Assignment Targeting (Recommended)

Use explicit flags to propagate assignment context across subprocesses and tools:

```bash
# Explicitly target assignment on every command
ace-assign status --assignment abc123
ace-assign finish --message done.md --assignment abc123
ace-assign fail --message "err" --assignment abc123
```

Once `ASSIGNMENT_TARGET` is pinned, do not run unscoped execution commands (`status`, `start`, `finish`, `fail`, `retry`, `add`) inside the drive loop.

### Subtree Fork Scope (Explicit `@<step-number>`)

For split-task delegation, run the entire subtree in one forked process:

```bash
ace-assign status --assignment abc123@010.01
ace-assign finish --message done.md --assignment abc123@010.01
```

When an assignment target includes scope (`<id>@<root>`), `ace-assign finish --message` advances only within that subtree and stops when the subtree is complete.

Helper command:

```bash
ace-assign fork-run --root 010.01 --assignment abc123
```

### Multi-Assignment Management

```bash
# List all active assignments
ace-assign list

# List including completed
ace-assign list --all

# Switch active assignment
ace-assign select <id>

# Clear explicit selection (revert to most recent)
ace-assign select --clear

# Target specific assignment without switching
ace-assign status --assignment <id>
ace-assign finish --message done.md --assignment <id>
```

## Execution Loop

Repeat the following cycle until all steps are done or failed:

### Step Execution Policy

- Planned steps are mandatory work items. Do not skip them by judgment.
- For each active step, do exactly one of:
  1. Execute the step and report completion with `ace-assign finish --message`
  2. Attempt execution, capture blocker evidence, and mark failed with `ace-assign fail`
- Never use report text to "skip" or synthesize completion for planned steps.
- **Fork-delegation constraint**: If the active step has `FORK: yes`, the driver MUST delegate via `ace-assign fork-run`. The driver MUST NOT execute fork-marked steps inline, absorb remaining fork children after partial failure, or inject retry steps as top-level siblings. All fork recovery goes through re-fork (see [Fork-Run Crash Recovery](#fork-run-crash-recovery-partial-completion)).
- **Conditional release in review subtrees**: A `release` step inside a review cycle (e.g., `[review-pr, apply-feedback, release]`) MUST skip the version bump when prior sibling steps produced no code changes. If `apply-feedback` reported no findings or `git diff HEAD~1 --stat` shows only report files, mark release done with "no-op: no changes to release" instead of bumping.

### Adaptation Assessment (After Each Step)

After completing or failing each step, evaluate whether the assignment needs adaptation:

- **Test failures detected** → Consider adding a fix-tests step:
  ```bash
  ace-assign add "fix-tests" --instructions "Fix failing tests identified in step NNN" --assignment "$ASSIGNMENT_TARGET"
   ```

- **Review found critical issues** → Consider adding an apply-critical-fixes step:
  ```bash
  ace-assign add "apply-critical-fixes" --instructions "Address critical review findings before proceeding" --assignment "$ASSIGNMENT_TARGET"
  ```

- **Missing prerequisite discovered** → Consider adding the prerequisite step:
  ```bash
  ace-assign add "missing-prereq" --instructions "Complete prerequisite work discovered during step NNN" --assignment "$ASSIGNMENT_TARGET"
  ```

- **Metadata hint**: Step file contains `trigger_on_failure` — if the step failed, inject the referenced step type

Use `decision_notes` from step metadata (if present) as additional guidance for these assessments.

- **Review-cycle circuit breaker**: When a review fork subtree fails due to provider unavailability (not code bugs), evaluate whether to attempt the next review cycle:
  - If the **first** review cycle (valid) failed on providers: skip remaining cycles (fit, shine). Mark them done with "skipped: provider unavailable for prior cycle" reports.
  - If the **second** cycle (fit) failed after valid succeeded: skip shine. Valid already captured correctness issues.
  - **Never retry a provider-failed review cycle more than once.** If the re-fork also fails on providers, mark the cycle done-with-skip and move on.

- **Transient network failure retry**: When a fork subtree fails due to a transient network error (connection reset, DNS timeout, socket hangup) — as opposed to provider unavailability or auth failure — wait 30 seconds and re-fork once. If the re-fork also fails on a network error, treat it as a hard failure and apply the circuit breaker rules above. Auth errors (401/403) and not-found errors (404) are never transient — fail immediately on those.

### 1. Check Status

```bash
STATUS_OUTPUT=$(ace-assign status --assignment "$ASSIGNMENT_TARGET" 2>&1)
echo "$STATUS_OUTPUT"
```

Read the output to identify:
- Assignment ID (must remain equal to pinned `ASSIGNMENT_ID`)
- Current step number, name, and status
- Current step's instructions
- Current step's skill reference (if any)
- Remaining steps in the queue

**Note:** `ace-assign status` is the source of truth for assignment state. The step files in the `steps/` directory are the backing store, but always query status via the command for accurate information.

### 2. Auto-Delegate Fork Subtrees (When Applicable)

Before executing the current step inline, check whether the active step is inside a fork-enabled subtree.

#### Delegation Rule

**FORK SIGNAL**: If a step row shows `yes` in the `FORK` column, the step itself has `context: fork` and MUST be delegated via `fork-run`.

| Column | Meaning | Action |
|--------|---------|--------|
| `FORK: yes` | Step has `context: fork` | Delegate via `fork-run` |
| `FORK: ` (empty) | Step is not fork-enabled | Execute inline (or inspect fork-enabled children if batch parent) |

**Example status output:**
```
NUMBER       STATUS       NAME                           FORK   CHILDREN
------------------------------------------------------------------------------
010          ✓ Done       onboard
020          ○ Pending    implement-step                 yes
```

Step 020 shows `FORK: yes` → run:
```bash
ace-assign fork-run --assignment <id>@020
```

**Delegation boundary rule**

- Outside a delegated fork scope, do NOT execute fork steps inline.
- If status output is already scoped to `Current Step: <root>.*` via `--assignment <id>@<root>`, the fork boundary is already entered: continue inline and never call `fork-run` again for the same `<root>`.
- If the current step is a top-level step with `FORK: yes` and no matching scope is active, delegate immediately.

#### Nested Batch Containers (Container → Fork Children)

A batch container (e.g., `010`) may have children but no fork context itself (`FORK` column empty). In that case, delegate child steps according to scheduler metadata on the parent:

- `batch_parent: true`
- `parallel: true|false`
- `max_parallel: <N>`
- `fork_retry_limit: <N>` (default `1`)

**How to distinguish:**
- **Direct fork target**: `FORK: yes` on the current step → fork-run the current step.
- **Batch container**: `FORK: ` on parent, but children include `FORK: yes` steps.

**Pattern for batch containers:**
```bash
# Read scheduler metadata from parent step 010
# parallel=false  => sequential, still fork every child
# parallel=true   => windowed fork concurrency with max_parallel
```

**Sequential mode (`parallel: false`)**

- Iterate pending child steps in number order.
- For each child with `FORK: yes`, run:
  - `ace-assign fork-run --assignment <id>@<child>`
- Re-check status after each child.
- Do not pause for user input between children — treat the batch loop as a single unit (see Batch Continuation Rule below).

**Parallel mode (`parallel: true`)**

- `max_parallel` is an in-flight concurrency cap, not a wave size.
- Maintain up to `max_parallel` in-flight child `fork-run` processes.
- Launch only child steps with `FORK: yes`.
- Refill a free slot immediately when any child completes, until pending queue is empty.
- Do not launch a fixed group and wait for the whole group to finish before launching more work.

**Rolling scheduler loop (required)**

1. Build pending fork-child queue in step-number order.
2. Launch children until `in_flight == max_parallel` or pending is empty.
3. Wait for any in-flight child to finish, then record done/failed state.
4. If child succeeded, immediately launch the next pending child; if no pending remains, continue draining in-flight children.
5. Stop only when both pending and in-flight are empty.

**Batch Continuation Rule**

The driver MUST NOT pause for user input between child fork-runs within a batch container. After each child completes:

1. Verify the child's reports (see Subtree Guard below).
2. If reports indicate successful completion, immediately launch the next pending child.
3. Treat the entire batch loop as a single unit of execution — only pause on quality concerns flagged during report review.
4. For timeout-constrained environments: launch `fork-run` in background, poll for completion, then loop to the next child without pausing.

**Failure policy (retry-then-stop)**

- On any child failure:
  - Pause launching new children immediately.
  - Wait for in-flight children to finish.
  - Retry failed child once (`fork_retry_limit=1` default).
  - If retry succeeds, resume launches.
  - If retry fails, stop driving and fail the batch subtree.

#### Example

```bash
STATUS_JSON=$(ace-assign status --assignment "$ASSIGNMENT_TARGET" --format json)
ASSIGNMENT_ID=$(echo "$STATUS_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read).dig("assignment", "id")')
FORK_ROOT=$(echo "$STATUS_JSON" | ruby -rjson -e '
  p = JSON.parse(STDIN.read)["current_step"]
  puts p["number"] if p && p["context"] == "fork"
')
if [ -n "$FORK_ROOT" ]; then
  ace-assign fork-run --assignment "${ASSIGNMENT_ID}@${FORK_ROOT}"
  # Re-check status after subtree delegation completes
  continue
fi
```

`fork-run` executes the entire subtree in one dedicated process and returns when the subtree is complete or failed.

> **Long-running execution:** `fork-run` typically takes 10-30 minutes depending on subtree complexity. If your environment has bash timeout limits (e.g., Claude Code's 10-minute Bash tool limit), run `fork-run` in background and poll for completion:
>
> ```bash
> # Run fork-run in background (use run_in_background: true in Claude Code)
> ace-assign fork-run --assignment "${ASSIGNMENT_ID}@${FORK_ROOT}" &
>
> # Poll scoped status every 5 minutes until subtree completes
> while true; do
>   STATUS_JSON=$(ace-assign status --assignment "${ASSIGNMENT_ID}@${FORK_ROOT}" --format json)
>   COMPLETE=$(echo "$STATUS_JSON" | ruby -rjson -e '
>     json = JSON.parse(STDIN.read)
>     steps = json["steps"] || []
>     puts steps.all? { |step| step["status"] == "done" || step["status"] == "failed" }
>   ')
>   [ "$COMPLETE" = "true" ] && break
>   sleep 300
> done
> ```

#### Subtree Completion: Task Status Verification

After a fork subtree completes (work-on-task finishes successfully):

1. **Verify ace-taskflow status matches assignment status.** If the assignment shows `work-on-task` as done but ace-taskflow still shows `in-progress`, status drift has occurred.

2. **If mark-task-done step was NOT included in the assignment** (common for ad-hoc assignments):
   ```bash
   # Manually sync status before reporting subtree complete
   ace-task done {taskref}
   ace-task {taskref}  # Verify it shows status: done
   ```

3. **Report the subtree complete only after verification.** This prevents the orchestrator from showing work as done while ace-taskflow shows it as in-progress.

#### Subtree Guard: Review Fork Reports Before Continuing

After fork-run returns and completion is verified, the driver acts as the **guard** for the subtree. Before continuing to the next step:

1. **Read all subtree report files** from `.ace-local/assign/<assignment-id>/reports/`:
   ```bash
   # List and read all reports for the completed subtree
   ls .ace-local/assign/${ASSIGNMENT_ID}/reports/${FORK_ROOT}.*
   # Read each report file to review the forked agent's work
   ```
2. **Verify quality**: Check that reports indicate successful completion, not just step advancement.
3. **Flag concerns**: If any report indicates partial work, errors, or skipped steps, stop and ask the user before continuing.
4. **Only then continue** the main drive loop to the next step.

> The driver is the only entity with cross-subtree visibility. Skipping report review means errors in one subtree propagate silently to the next.

#### Queue Advancement After Batch Container Completion

After all fork subtrees within a batch container complete, the container auto-marks as Done. However, the queue pointer may not automatically advance to the next top-level step.

**After verifying all fork subtree reports**, if `ace-assign status` shows no Active step (all completed steps but no new in-progress step), run:
```bash
ace-assign start --assignment "$ASSIGNMENT_TARGET"
```
This advances the queue to the next pending top-level step.

#### Fork-Run Recovery

When `fork-run` exits non-zero, invoke the fork recovery workflow:

```bash
ace-bundle wfi://assign/recover-fork
```

Or invoke via skill: `/as-assign-recover-fork ${ASSIGNMENT_ID}@${FORK_ROOT}`

The recovery workflow handles three scenarios:

| Scenario | Signal | Recovery |
|----------|--------|----------|
| **Crash with partial progress** | `exit != 0` + uncommitted files or mixed step status | Commit partial work, inject recovery-onboard + continue-work children, re-fork |
| **Provider unavailability** | `exit != 0` + timeout/hang error (no code bug) | LLM-tool steps: inline or retry child. Code steps: wait or escalate |
| **Mixed state after provider failure** | Done + failed + pending children | Inject retry children, re-fork |

**Key principles** (enforced by the recovery workflow):

- Never execute fork work inline (except LLM-tool steps during provider unavailability)
- Recovery steps are always children inside the subtree, never top-level siblings
- Recovery-onboard must list explicit report file paths (not semantic references)
- Continue-work must copy the original failed step's instructions verbatim

See `wfi://assign/recover-fork` for the full protocol, detection rules, and recovery step construction templates.

### 3. Execute Current Step

Based on the step configuration:

#### If Step Has a `skill:` Field

Invoke the referenced skill as the primary action, extracting parameters from the instructions:

```yaml
- name: work-on-task
  skill: as-task-work
  instructions: |
    Work on task 148.
    Follow project conventions.
```

**Agent Action:** Run `/as-task-work 148` then follow the skill workflow.

#### If Step Has No Skill

Follow the instructions directly, performing the described work:

```yaml
- name: setup
  instructions: |
    Install dependencies.
    Configure the database.
    Verify installation.
```

**Agent Action:** Execute each instruction line as a task.

### 4. External Action Rule (Attempt-First)

For external-facing steps (for example PR/review/release/push/update lifecycle steps):

- Attempt the step command(s) first.
- If blocked, capture concrete evidence:
  - command attempted
  - exact error output
  - why the step cannot proceed
- Mark step failed with evidence (do not report synthetic completion).

```bash
ace-assign fail --message "Command failed: <cmd>. Error: <exact stderr>" --assignment "$ASSIGNMENT_TARGET"
```

### 5. Write Report (Only After Real Execution)

After completing the step work, write a brief report summarizing what was accomplished:

```bash
# Write report content to a temp file
cat > /tmp/step-report.md << 'EOF'
## Summary

Completed the setup step successfully:

- Installed all dependencies via npm install
- Configured PostgreSQL database connection
- Verified installation with health check

All setup prerequisites are now satisfied.
EOF

# Submit report to advance the queue
ace-assign finish --message /tmp/step-report.md --assignment "$ASSIGNMENT_TARGET"
```

### 6. Verify State Transition (Required)

After each `ace-assign finish --message` or `ace-assign fail`, verify queue state:

```bash
POST_STATUS=$(ace-assign status --assignment "$ASSIGNMENT_TARGET" 2>&1)
echo "$POST_STATUS"
```

Required checks:
- If report succeeded: active step advanced consistently with work performed
- If fail succeeded: assignment is stalled or moved according to retry/add logic
- If output mismatches expected transition: stop and ask user before continuing

### 7. Handle Failures

If a step cannot be completed:

```bash
# Mark step as failed with reason
ace-assign fail --message "Tests failed: test_greet, test_shout" --assignment "$ASSIGNMENT_TARGET"
```

Then decide on next action:

#### Option A: Retry the Failed Step

```bash
ace-assign retry <step-number> --assignment "$ASSIGNMENT_TARGET"
```

Creates a new step linked to the original. Original remains visible as failed.

#### Option B: Add a Fix Step

```bash
ace-assign add "fix-issue" --instructions "Fix the failing tests and verify" --assignment "$ASSIGNMENT_TARGET"
```

New step is inserted after the current in-progress step.

#### Option C: Ask the User

If uncertain, ask the user whether to retry, add a fix step, or abort.

### 8. Repeat

Check status again:
- If there is a next step, continue the loop from step 1
- If all steps are `done`, proceed to Completion
- If assignment has failed steps and no fix is planned, report to user

## Completion

When `ace-assign status` shows all steps as `done`:

```bash
ace-assign status --assignment "$ASSIGNMENT_TARGET"
```

Example output:
```
Assignment: work-on-task-123 (8or5kx)

Step  Status    Name
010    done      onboard
020    done      work-on-task
030    done      finalize

All steps complete!
```

Summarize the assignment results to the user:
- What was accomplished
- Any artifacts created (PRs, commits, etc.)
- Next steps or follow-up actions

## Skill Invocation Pattern

When executing a step with a `skill:` field:

1. **Read step instructions** - Understand context and parameters
2. **Extract parameters** - Get task IDs, PR numbers from instructions
3. **Invoke skill** - Run the referenced skill command
4. **Follow skill workflow** - Complete the skill's process
5. **Report completion** - Use `ace-assign finish --message` with results

### Common Skill References

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `onboard` | `/as-onboard` | Load project context |
| `ace:task-work` | `/as-task-work <taskref>` | Implement task changes |
| `ace:github-pr-create` | `/as-github-pr-create` | Create pull request |
| `ace:review-pr` | `/as-review-pr [pr#]` | Review code changes |
| `ace:git-commit` | `/as-git-commit` | Generate commit message |
| `ace:github-pr-update` | `/as-github-pr-update` | Update PR description |

## Error Handling

| Scenario | Action |
|----------|--------|
| No active assignment | Create an assignment first via `/as-assign-create` |
| All steps done | Report completion to user |
| Step fails | Attempt first, then use `fail` with command/error evidence; decide retry/add/ask |
| Skill not found | Execute instructions directly without skill |
| Unclear instructions | Ask user for clarification |
| Provider/tool unavailable | For fork steps: see Provider-Unavailability Recovery. For inline steps: attempt with alternate model, then fail with evidence |

## Assignment State Reference

### Step Status Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `pending` | Step not started | Cannot execute (wait for queue) |
| `in_progress` | Step is active | Execute this step |
| `done` | Step completed | Move to next step |
| `failed` | Step failed | Decide: retry, add fix, or abort |

### Assignment Directory Structure

```
.ace-local/assign/
├── .latest → abc123/             # Auto-updated on any activity
├── .current → def456/            # Explicit user selection (optional)
├── abc123/
│   ├── assignment.yaml           # Assignment metadata
│   ├── steps/                   # Step files (.st.md extension)
│   │   ├── 010-init.st.md       # done
│   │   ├── 020-implement.st.md  # in_progress
│   │   └── 030-test.st.md       # pending
│   └── reports/                  # Report files (.r.md extension)
│       ├── 010-init.r.md        # completed report
│       └── 020-implement.r.md   # in-progress report
└── def456/
    ├── assignment.yaml
    ├── steps/
    └── reports/
```

Each step has:
- **Step file** (`steps/NNN-name.st.md`) - Contains step instructions and status
- **Report file** (`reports/NNN-name.r.md`) - Contains completion report (created when step is done)

## Numbering Convention

| Pattern | Purpose | Example |
|---------|---------|---------|
| `010`, `020`, `030` | Main tasks (10-step gaps) | `010-init.st.md` |
| `010.01`, `010.02` | Subtasks | `010.01-setup.st.md` |
| `041`, `042` | Injected after existing | `041-fix.st.md` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | No active assignment |
| 3 | File not found (report file) |
| 4 | Invalid step reference |

## Success Criteria

- All steps processed (done or failed)
- Reports written for all completed steps
- Failed steps have clear failure reasons
- No planned step is auto-completed via skip-by-assumption behavior
- User informed of assignment completion state
- Artifacts and next steps clearly communicated

## Example Assignment Flow

```bash
# 0. Pin assignment for this loop
$ ASSIGNMENT_TARGET=8or5kx

# 1. Check status
$ ace-assign status --assignment "$ASSIGNMENT_TARGET"
Step 010: onboard [in_progress]

# 2. Execute step (has skill: onboard)
$ /as-onboard
[Onboarding workflow runs...]

# 3. Write report
$ ace-assign finish --message onboard-complete.md --assignment "$ASSIGNMENT_TARGET"
Step 010 marked done, advancing to 020

# 4. Check status again
$ ace-assign status --assignment "$ASSIGNMENT_TARGET"
Step 020: work-on-task [in_progress]

# 5. Execute next step (has skill: as-task-work)
$ /as-task-work 148
[Task workflow runs...]

# 6. Report and continue...
$ ace-assign finish --message task-done.md --assignment "$ASSIGNMENT_TARGET"

# 7. Eventually...
$ ace-assign status --assignment "$ASSIGNMENT_TARGET"
All steps complete!
```