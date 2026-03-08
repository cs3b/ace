---
name: assign/drive
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
description: Drive agent execution through an active assignment
argument-hint: ""
doc-type: workflow
purpose: workflow instruction for driving ace-assign assignment execution

update:
  frequency: on-change
  last-updated: '2026-03-08'
---

# Drive Assignment Workflow

## Purpose

Drive agent execution through an active assignment by continuously checking status, executing the current phase, and reporting completion. This is the main execution loop for working through an assignment workflow.

## Prerequisites

- An active assignment exists (created via `ace-assign create` or `/as-assign-create`)
- Assignment has at least one pending or in_progress phase

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

### Subtree Fork Scope (Explicit `@<phase-number>`)

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

Repeat the following cycle until all phases are done or failed:

### Phase Execution Policy

- Planned phases are mandatory work items. Do not skip them by judgment.
- For each active phase, do exactly one of:
  1. Execute the phase and report completion with `ace-assign finish --message`
  2. Attempt execution, capture blocker evidence, and mark failed with `ace-assign fail`
- Never use report text to "skip" or synthesize completion for planned phases.
- **Fork-delegation constraint**: If the active phase has `FORK: yes`, the driver MUST delegate via `ace-assign fork-run`. The driver MUST NOT execute fork-marked phases inline, absorb remaining fork children after partial failure, or inject retry phases as top-level siblings. All fork recovery goes through re-fork (see [Fork-Run Crash Recovery](#fork-run-crash-recovery-partial-completion)).
- **Conditional release in review subtrees**: A `release` phase inside a review cycle (e.g., `[review-pr, apply-feedback, release]`) MUST skip the version bump when prior sibling phases produced no code changes. If `apply-feedback` reported no findings or `git diff HEAD~1 --stat` shows only report files, mark release done with "no-op: no changes to release" instead of bumping.

### Adaptation Assessment (After Each Phase)

After completing or failing each phase, evaluate whether the assignment needs adaptation:

- **Test failures detected** → Consider adding a fix-tests phase:
  ```bash
  ace-assign add "fix-tests" --instructions "Fix failing tests identified in phase NNN" --assignment "$ASSIGNMENT_TARGET"
   ```

- **Review found critical issues** → Consider adding an apply-critical-fixes phase:
  ```bash
  ace-assign add "apply-critical-fixes" --instructions "Address critical review findings before proceeding" --assignment "$ASSIGNMENT_TARGET"
  ```

- **Missing prerequisite discovered** → Consider adding the prerequisite phase:
  ```bash
  ace-assign add "missing-prereq" --instructions "Complete prerequisite work discovered during phase NNN" --assignment "$ASSIGNMENT_TARGET"
  ```

- **Metadata hint**: Phase file contains `trigger_on_failure` — if the phase failed, inject the referenced phase type

Use `decision_notes` from phase metadata (if present) as additional guidance for these assessments.

- **Review-cycle circuit breaker**: When a review fork subtree fails due to provider unavailability (not code bugs), evaluate whether to attempt the next review cycle:
  - If the **first** review cycle (valid) failed on providers: skip remaining cycles (fit, shine). Mark them done with "skipped: provider unavailable for prior cycle" reports.
  - If the **second** cycle (fit) failed after valid succeeded: skip shine. Valid already captured correctness issues.
  - **Never retry a provider-failed review cycle more than once.** If the re-fork also fails on providers, mark the cycle done-with-skip and move on.

### 1. Check Status

```bash
STATUS_OUTPUT=$(ace-assign status --assignment "$ASSIGNMENT_TARGET" 2>&1)
echo "$STATUS_OUTPUT"
```

Read the output to identify:
- Assignment ID (must remain equal to pinned `ASSIGNMENT_ID`)
- Current phase number, name, and status
- Current phase's instructions
- Current phase's skill reference (if any)
- Remaining phases in the queue

**Note:** `ace-assign status` is the source of truth for assignment state. The phase files in the `phases/` directory are the backing store, but always query status via the command for accurate information.

### 2. Auto-Delegate Fork Subtrees (When Applicable)

Before executing the current phase inline, check whether the active phase is inside a fork-enabled subtree.

#### Delegation Rule

**FORK SIGNAL**: If a phase row shows `yes` in the `FORK` column, the phase itself has `context: fork` and MUST be delegated via `fork-run`.

| Column | Meaning | Action |
|--------|---------|--------|
| `FORK: yes` | Phase has `context: fork` | Delegate via `fork-run` |
| `FORK: ` (empty) | Phase is not fork-enabled | Execute inline (or inspect fork-enabled children if batch parent) |

**Example status output:**
```
NUMBER       STATUS       NAME                           FORK   CHILDREN
------------------------------------------------------------------------------
010          ✓ Done       onboard
020          ○ Pending    implement-step                 yes
```

Phase 020 shows `FORK: yes` → run:
```bash
ace-assign fork-run --assignment <id>@020
```

**Delegation boundary rule**

- Outside a delegated fork scope, do NOT execute fork phases inline.
- If status output is already scoped to `Current Phase: <root>.*` via `--assignment <id>@<root>`, the fork boundary is already entered: continue inline and never call `fork-run` again for the same `<root>`.
- If the current phase is a top-level phase with `FORK: yes` and no matching scope is active, delegate immediately.

#### Nested Batch Containers (Container → Fork Children)

A batch container (e.g., `010`) may have children but no fork context itself (`FORK` column empty). In that case, delegate child phases according to scheduler metadata on the parent:

- `batch_parent: true`
- `parallel: true|false`
- `max_parallel: <N>`
- `fork_retry_limit: <N>` (default `1`)

**How to distinguish:**
- **Direct fork target**: `FORK: yes` on the current phase → fork-run the current phase.
- **Batch container**: `FORK: ` on parent, but children include `FORK: yes` phases.

**Pattern for batch containers:**
```bash
# Read scheduler metadata from parent phase 010
# parallel=false  => sequential, still fork every child
# parallel=true   => windowed fork concurrency with max_parallel
```

**Sequential mode (`parallel: false`)**

- Iterate pending child phases in number order.
- For each child with `FORK: yes`, run:
  - `ace-assign fork-run --assignment <id>@<child>`
- Re-check status after each child.

**Parallel mode (`parallel: true`)**

- `max_parallel` is an in-flight concurrency cap, not a wave size.
- Maintain up to `max_parallel` in-flight child `fork-run` processes.
- Launch only child phases with `FORK: yes`.
- Refill a free slot immediately when any child completes, until pending queue is empty.
- Do not launch a fixed group and wait for the whole group to finish before launching more work.

**Rolling scheduler loop (required)**

1. Build pending fork-child queue in phase-number order.
2. Launch children until `in_flight == max_parallel` or pending is empty.
3. Wait for any in-flight child to finish, then record done/failed state.
4. If child succeeded, immediately launch the next pending child; if no pending remains, continue draining in-flight children.
5. Stop only when both pending and in-flight are empty.

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
  p = JSON.parse(STDIN.read)["current_phase"]
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
>     phases = json["phases"] || []
>     puts phases.all? { |phase| phase["status"] == "done" || phase["status"] == "failed" }
>   ')
>   [ "$COMPLETE" = "true" ] && break
>   sleep 300
> done
> ```

#### Subtree Completion: Task Status Verification

After a fork subtree completes (work-on-task finishes successfully):

1. **Verify ace-taskflow status matches assignment status.** If the assignment shows `work-on-task` as done but ace-taskflow still shows `in-progress`, status drift has occurred.

2. **If mark-task-done phase was NOT included in the assignment** (common for ad-hoc assignments):
   ```bash
   # Manually sync status before reporting subtree complete
   ace-task done {taskref}
   ace-task {taskref}  # Verify it shows status: done
   ```

3. **Report the subtree complete only after verification.** This prevents the orchestrator from showing work as done while ace-taskflow shows it as in-progress.

#### Subtree Guard: Review Fork Reports Before Continuing

After fork-run returns and completion is verified, the driver acts as the **guard** for the subtree. Before continuing to the next phase:

1. **Read all subtree report files** from `.ace-local/assign/<assignment-id>/reports/`:
   ```bash
   # List and read all reports for the completed subtree
   ls .ace-local/assign/${ASSIGNMENT_ID}/reports/${FORK_ROOT}.*
   # Read each report file to review the forked agent's work
   ```
2. **Verify quality**: Check that reports indicate successful completion, not just phase advancement.
3. **Flag concerns**: If any report indicates partial work, errors, or skipped steps, stop and ask the user before continuing.
4. **Only then continue** the main drive loop to the next phase.

> The driver is the only entity with cross-subtree visibility. Skipping report review means errors in one subtree propagate silently to the next.

#### Queue Advancement After Batch Container Completion

After all fork subtrees within a batch container complete, the container auto-marks as Done. However, the queue pointer may not automatically advance to the next top-level phase.

**After verifying all fork subtree reports**, if `ace-assign status` shows no Active phase (all completed phases but no new in-progress phase), run:
```bash
ace-assign start --assignment "$ASSIGNMENT_TARGET"
```
This advances the queue to the next pending top-level phase.

#### Fork-Run Crash Recovery (Partial Completion)

When `fork-run` exits non-zero but has made partial progress (uncommitted files, some phases done, some in-progress):

**Detection**: fork-run exit code != 0 AND (`git status --short` shows changes OR some child phases are done while others are still active).

**Recovery protocol**:

1. **Commit partial work** — Stage and commit any uncommitted changes from the crashed fork:
   ```bash
   git add -A
   ace-git-commit -i "partial: save fork progress for {subtree}"
   ```

2. **Write a progress report for the active phase** — Document what was accomplished and what remains:
   ```bash
   cat > /tmp/partial-report.md << 'EOF'
   ## Partial Completion (fork crashed)

   ### Completed
   - [list of files created/modified]
   - [tests passing: X tests, Y assertions]

   ### Remaining
   - [list of components not yet implemented]
   - [tests not yet written]
   EOF
   ace-assign finish --message /tmp/partial-report.md --assignment ${ASSIGNMENT_ID}@${active_phase}
   ```

3. **Inject recovery phases** — Add new child phases for the remaining work:
   ```bash
   # Recovery onboard: re-read the plan and progress reports
   ace-assign add "recovery-onboard" --after ${last_done_phase} --child \
     --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
     -i "Read reports from plan-task and work-on-task phases to understand progress. Continue implementation from where it stopped."

   # Continue work phase
   ace-assign add "continue-work" --after recovery-onboard --child \
     --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
     -i "Complete remaining implementation. Check git log and existing files to avoid redoing work."
  ```

4. **Re-fork** — The injected phases are pending, so fork-run will pick them up:
   ```bash
   ace-assign fork-run --assignment ${ASSIGNMENT_ID}@${FORK_ROOT}
   ```

**Key principle**: Never execute fork work inline — except for LLM-tool phases during provider unavailability (see below). The fork boundary exists for context isolation. If a fork crashes due to a code issue, recover and re-fork — don't absorb the work into the driver.

#### Fork-Run Failure: Provider Unavailability

When `fork-run` fails not because of a code bug but because an LLM provider timed out, hung, or returned no output, re-forking will crash the same way in a loop.

**Detection heuristics**: fork-run exit != 0 AND the failed phase error or last fork message indicates a timeout, hang, or empty response — not a code bug (no stack trace, no test failure, no syntax error).

**Recovery protocol**:

1. **Confirm provider failure** — Read the fork's last message and failed phase error. Look for: model timeout, API unavailability, empty/truncated response, connection reset, or tool hang with no output.

2. **Classify the failed phase**:
   - **LLM-tool phase** — Work that invokes an LLM-backed tool as its primary action (e.g., `ace-review`, `ace-lint`, audit, summarize). The fork existed to isolate the LLM call, not to produce code.
   - **Code phase** — Work that produces or modifies source code (e.g., implement, fix, refactor). The fork existed for context isolation of code-producing work.

3. **Fork-side action** — The fork MUST only fail and exit. It must NEVER inject phases:
   ```bash
   # Mark the crashed phase as failed with evidence, then exit
   ace-assign fail --message "Provider unavailable: <error details>" \
     --assignment ${ASSIGNMENT_ID}@${failed_phase}
   # EXIT — do not add phases, do not retry, do not modify the assignment tree
   ```

   **Forks NEVER inject phases outside their subtree scope. Recovery decisions belong to the driver.**

4. **Driver-side recovery** — After detecting a fork failure, the driver classifies and recovers:

   **LLM-tool phases** → execute equivalent work inline at driver level:
   ```bash
   # Option A: Execute inline (for LLM-tool phases only)
   # Read changed files, analyze each, write review report directly

   # Option B: Add retry as a child of the failed phase's parent
   ace-assign add "retry-<phase-name>" --after <failed_phase> --child \
     --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
     -i "Provider was unavailable for forked <phase-name>. Execute equivalent work inline: <specific instructions>"
   ```

   **Code phases** → do NOT execute inline. Wait for provider recovery or escalate:
   ```bash
   # Ask user whether to wait and retry later
   # Do NOT attempt the code work inline — context isolation is required
   ```

**Inline execution constraint**: Only LLM-tool phases may go inline during provider unavailability. Code-producing phases always require a fork for context isolation — wait for recovery or ask the user.

#### Re-Fork After Partial Provider Failure

When a fork subtree has a mix of done, failed, and pending children after a provider failure, the driver recovers by re-forking — not by absorbing remaining work inline.

**Protocol**:

1. **Inject retry as a child** of the failed phase's parent subtree (never as a top-level sibling):
   ```bash
   ace-assign add "retry-review-pr" --after ${failed_child} --child \
     --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
     -i "Retry review-pr after provider recovery."
   ```

2. **Re-fork the subtree** — fork-run re-enters and picks up pending/retry children:
   ```bash
   ace-assign fork-run --assignment "${ASSIGNMENT_ID}@${FORK_ROOT}"
   ```

3. **Do NOT inject phases as top-level siblings** — retry phases must be children of the original subtree root, never top-level phases like `101` or `121`.

**Anti-pattern**: Driver sees subtree 110 with 110.01 failed, 110.02 and 110.03 pending. Driver executes 110.02 and 110.03 inline. This defeats context isolation and violates the fork-delegation constraint.

### 3. Execute Current Phase

Based on the phase configuration:

#### If Phase Has a `skill:` Field

Invoke the referenced skill as the primary action, extracting parameters from the instructions:

```yaml
- name: work-on-task
  skill: as-task-work
  instructions: |
    Work on task 148.
    Follow project conventions.
```

**Agent Action:** Run `/as-task-work 148` then follow the skill workflow.

#### If Phase Has No Skill

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

For external-facing phases (for example PR/review/release/push/update lifecycle steps):

- Attempt the phase command(s) first.
- If blocked, capture concrete evidence:
  - command attempted
  - exact error output
  - why the phase cannot proceed
- Mark phase failed with evidence (do not report synthetic completion).

```bash
ace-assign fail --message "Command failed: <cmd>. Error: <exact stderr>" --assignment "$ASSIGNMENT_TARGET"
```

### 5. Write Report (Only After Real Execution)

After completing the phase work, write a brief report summarizing what was accomplished:

```bash
# Write report content to a temp file
cat > /tmp/phase-report.md << 'EOF'
## Summary

Completed the setup phase successfully:

- Installed all dependencies via npm install
- Configured PostgreSQL database connection
- Verified installation with health check

All setup prerequisites are now satisfied.
EOF

# Submit report to advance the queue
ace-assign finish --message /tmp/phase-report.md --assignment "$ASSIGNMENT_TARGET"
```

### 6. Verify State Transition (Required)

After each `ace-assign finish --message` or `ace-assign fail`, verify queue state:

```bash
POST_STATUS=$(ace-assign status --assignment "$ASSIGNMENT_TARGET" 2>&1)
echo "$POST_STATUS"
```

Required checks:
- If report succeeded: active phase advanced consistently with work performed
- If fail succeeded: assignment is stalled or moved according to retry/add logic
- If output mismatches expected transition: stop and ask user before continuing

### 7. Handle Failures

If a phase cannot be completed:

```bash
# Mark phase as failed with reason
ace-assign fail --message "Tests failed: test_greet, test_shout" --assignment "$ASSIGNMENT_TARGET"
```

Then decide on next action:

#### Option A: Retry the Failed Phase

```bash
ace-assign retry <phase-number> --assignment "$ASSIGNMENT_TARGET"
```

Creates a new phase linked to the original. Original remains visible as failed.

#### Option B: Add a Fix Phase

```bash
ace-assign add "fix-issue" --instructions "Fix the failing tests and verify" --assignment "$ASSIGNMENT_TARGET"
```

New phase is inserted after the current in-progress phase.

#### Option C: Ask the User

If uncertain, ask the user whether to retry, add a fix phase, or abort.

### 8. Repeat

Check status again:
- If there is a next phase, continue the loop from step 1
- If all phases are `done`, proceed to Completion
- If assignment has failed phases and no fix is planned, report to user

## Completion

When `ace-assign status` shows all phases as `done`:

```bash
ace-assign status --assignment "$ASSIGNMENT_TARGET"
```

Example output:
```
Assignment: work-on-task-123 (8or5kx)

Phase  Status    Name
010    done      onboard
020    done      work-on-task
030    done      finalize

All phases complete!
```

Summarize the assignment results to the user:
- What was accomplished
- Any artifacts created (PRs, commits, etc.)
- Next steps or follow-up actions

## Skill Invocation Pattern

When executing a phase with a `skill:` field:

1. **Read phase instructions** - Understand context and parameters
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
| All phases done | Report completion to user |
| Phase fails | Attempt first, then use `fail` with command/error evidence; decide retry/add/ask |
| Skill not found | Execute instructions directly without skill |
| Unclear instructions | Ask user for clarification |
| Provider/tool unavailable | For fork phases: see Provider-Unavailability Recovery. For inline phases: attempt with alternate model, then fail with evidence |

## Assignment State Reference

### Phase Status Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `pending` | Phase not started | Cannot execute (wait for queue) |
| `in_progress` | Phase is active | Execute this phase |
| `done` | Phase completed | Move to next phase |
| `failed` | Phase failed | Decide: retry, add fix, or abort |

### Assignment Directory Structure

```
.ace-local/assign/
├── .latest → abc123/             # Auto-updated on any activity
├── .current → def456/            # Explicit user selection (optional)
├── abc123/
│   ├── assignment.yaml           # Assignment metadata
│   ├── phases/                   # Phase files (.ph.md extension)
│   │   ├── 010-init.ph.md       # done
│   │   ├── 020-implement.ph.md  # in_progress
│   │   └── 030-test.ph.md       # pending
│   └── reports/                  # Report files (.r.md extension)
│       ├── 010-init.r.md        # completed report
│       └── 020-implement.r.md   # in-progress report
└── def456/
    ├── assignment.yaml
    ├── phases/
    └── reports/
```

Each phase has:
- **Phase file** (`phases/NNN-name.ph.md`) - Contains phase instructions and status
- **Report file** (`reports/NNN-name.r.md`) - Contains completion report (created when phase is done)

## Numbering Convention

| Pattern | Purpose | Example |
|---------|---------|---------|
| `010`, `020`, `030` | Main tasks (10-phase gaps) | `010-init.ph.md` |
| `010.01`, `010.02` | Subtasks | `010.01-setup.ph.md` |
| `041`, `042` | Injected after existing | `041-fix.ph.md` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | No active assignment |
| 3 | File not found (report file) |
| 4 | Invalid phase reference |

## Success Criteria

- All phases processed (done or failed)
- Reports written for all completed phases
- Failed phases have clear failure reasons
- No planned phase is auto-completed via skip-by-assumption behavior
- User informed of assignment completion state
- Artifacts and next steps clearly communicated

## Example Assignment Flow

```bash
# 0. Pin assignment for this loop
$ ASSIGNMENT_TARGET=8or5kx

# 1. Check status
$ ace-assign status --assignment "$ASSIGNMENT_TARGET"
Phase 010: onboard [in_progress]

# 2. Execute phase (has skill: onboard)
$ /as-onboard
[Onboarding workflow runs...]

# 3. Write report
$ ace-assign finish --message onboard-complete.md --assignment "$ASSIGNMENT_TARGET"
Phase 010 marked done, advancing to 020

# 4. Check status again
$ ace-assign status --assignment "$ASSIGNMENT_TARGET"
Phase 020: work-on-task [in_progress]

# 5. Execute next phase (has skill: as-task-work)
$ /as-task-work 148
[Task workflow runs...]

# 6. Report and continue...
$ ace-assign finish --message task-done.md --assignment "$ASSIGNMENT_TARGET"

# 7. Eventually...
$ ace-assign status --assignment "$ASSIGNMENT_TARGET"
All phases complete!
```
