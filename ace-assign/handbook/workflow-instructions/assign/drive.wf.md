---
name: assign/drive
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
description: Drive agent execution through an active assignment
argument-hint: ""
doc-type: workflow
purpose: workflow instruction for driving ace-assign assignment execution

update:
  frequency: on-change
  last-updated: '2026-02-17'
---

# Drive Assignment Workflow

## Purpose

Drive agent execution through an active assignment by continuously checking status, executing the current phase, and reporting completion. This is the main execution loop for working through an assignment workflow.

## Prerequisites

- An active assignment exists (created via `ace-assign create` or `/ace:assign-create`)
- Assignment has at least one pending or in_progress phase

## Assignment Context Propagation

When working with multiple concurrent assignments, the active assignment is resolved in this order:

1. `--assignment <id>` flag on any command (highest priority)
2. `ACE_ASSIGN_ID` environment variable
3. `.current` symlink (set via `ace-assign select <id>`)
4. `.latest` symlink (auto-updated on any activity)
5. Scan all assignments (fallback)

### Using ACE_ASSIGN_ID

Set `ACE_ASSIGN_ID` to propagate assignment context across subprocesses:

```bash
# Set for current shell session
export ACE_ASSIGN_ID=abc123

# All commands now target this assignment
ace-assign status          # Shows abc123
ace-assign report done.md  # Reports to abc123
ace-assign fail -m "err"   # Fails phase in abc123
```

This is particularly useful for:
- Forked agent contexts (Task tool) where the parent sets the env var
- CI/CD pipelines running assignment-driven workflows
- Scripts operating on a specific assignment

### Subtree Fork Scope (`ACE_ASSIGN_FORK_ROOT`)

For split-task delegation, run the entire subtree in one forked process:

```bash
export ACE_ASSIGN_ID=abc123
export ACE_ASSIGN_FORK_ROOT=010.01
ace-assign status --assignment abc123
```

When `ACE_ASSIGN_FORK_ROOT` is set, `ace-assign report` advances only within that subtree and stops when the subtree is complete.

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
ace-assign report done.md --assignment <id>
```

## Execution Loop

Repeat the following cycle until all phases are done or failed:

### Phase Execution Policy

- Planned phases are mandatory work items. Do not skip them by judgment.
- For each active phase, do exactly one of:
  1. Execute the phase and report completion with `ace-assign report`
  2. Attempt execution, capture blocker evidence, and mark failed with `ace-assign fail`
- Never use report text to "skip" or synthesize completion for planned phases.

### Adaptation Assessment (After Each Phase)

After completing or failing each phase, evaluate whether the assignment needs adaptation:

- **Test failures detected** → Consider adding a fix-tests phase:
  ```bash
  ace-assign add "fix-tests" --instructions "Fix failing tests identified in phase NNN"
  ```

- **Review found critical issues** → Consider adding an apply-critical-fixes phase:
  ```bash
  ace-assign add "apply-critical-fixes" --instructions "Address critical review findings before proceeding"
  ```

- **Missing prerequisite discovered** → Consider adding the prerequisite phase:
  ```bash
  ace-assign add "missing-prereq" --instructions "Complete prerequisite work discovered during phase NNN"
  ```

- **Metadata hint**: Phase file contains `trigger_on_failure` — if the phase failed, inject the referenced phase type

Use `decision_notes` from phase metadata (if present) as additional guidance for these assessments.

### 1. Check Status

```bash
STATUS_OUTPUT=$(ace-assign status 2>&1)
echo "$STATUS_OUTPUT"
```

Read the output to identify:
- Current phase number, name, and status
- Current phase's instructions
- Current phase's skill reference (if any)
- Remaining phases in the queue

**Note:** `ace-assign status` is the source of truth for assignment state. The phase files in the `phases/` directory are the backing store, but always query status via the command for accurate information.

### 2. Auto-Delegate Fork Subtrees (When Applicable)

Before executing the current phase inline, check whether the active phase is inside a fork-enabled subtree.

#### Delegation Rule

- If `ACE_ASSIGN_FORK_ROOT` is already set: you are already inside fork scope, so continue inline.
- If `ACE_ASSIGN_FORK_ROOT` is not set and status output contains:
  - `Fork subtree detected (root: <phase-number> - <phase-name>).`
  then delegate the subtree via `fork-run` and restart the loop.

#### Example

```bash
# Only delegate from orchestrator context (not from an already forked subtree)
if [ -z "${ACE_ASSIGN_FORK_ROOT:-}" ]; then
  FORK_ROOT=$(echo "$STATUS_OUTPUT" | sed -n 's/.*Fork subtree detected (root: \([0-9.]*\) -.*/\1/p' | head -1)
  if [ -n "$FORK_ROOT" ]; then
    ASSIGNMENT_ID=${ACE_ASSIGN_ID:-$(basename "$(readlink .cache/ace-assign/.current 2>/dev/null || readlink .cache/ace-assign/.latest)")}
    ace-assign fork-run --assignment "${ASSIGNMENT_ID}@${FORK_ROOT}"
    # Re-check status after subtree delegation completes
    continue
  fi
fi
```

`fork-run` executes the entire subtree in one dedicated process and returns when the subtree is complete or failed.

#### Subtree Completion: Task Status Verification

After a fork subtree completes (work-on-task finishes successfully):

1. **Verify ace-taskflow status matches assignment status.** If the assignment shows `work-on-task` as done but ace-taskflow still shows `in-progress`, status drift has occurred.

2. **If mark-task-done phase was NOT included in the assignment** (common for ad-hoc assignments):
   ```bash
   # Manually sync status before reporting subtree complete
   ace-taskflow task done {taskref}
   ace-taskflow task {taskref}  # Verify it shows status: done
   ```

3. **Report the subtree complete only after verification.** This prevents the orchestrator from showing work as done while ace-taskflow shows it as in-progress.

### 3. Execute Current Phase

Based on the phase configuration:

#### If Phase Has a `skill:` Field

Invoke the referenced skill as the primary action, extracting parameters from the instructions:

```yaml
- name: work-on-task
  skill: ace:task-work
  instructions: |
    Work on task 148.
    Follow project conventions.
```

**Agent Action:** Run `/ace:task-work 148` then follow the skill workflow.

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
ace-assign fail --message "Command failed: <cmd>. Error: <exact stderr>"
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
ace-assign report /tmp/phase-report.md
```

### 6. Verify State Transition (Required)

After each `ace-assign report` or `ace-assign fail`, verify queue state:

```bash
POST_STATUS=$(ace-assign status 2>&1)
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
ace-assign fail --message "Tests failed: test_greet, test_shout"
```

Then decide on next action:

#### Option A: Retry the Failed Phase

```bash
ace-assign retry <phase-number>
```

Creates a new phase linked to the original. Original remains visible as failed.

#### Option B: Add a Fix Phase

```bash
ace-assign add "fix-issue" --instructions "Fix the failing tests and verify"
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
ace-assign status
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
5. **Report completion** - Use `ace-assign report` with results

### Common Skill References

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `onboard` | `/onboard` | Load project context |
| `ace:task-work` | `/ace:task-work <taskref>` | Implement task changes |
| `ace:git-create-pr` | `/ace:git-create-pr` | Create pull request |
| `ace:review-pr` | `/ace:review-pr [pr#]` | Review code changes |
| `ace:git-commit` | `/ace:git-commit` | Generate commit message |
| `ace:git-update-pr-desc` | `/ace:git-update-pr-desc` | Update PR description |

## Error Handling

| Scenario | Action |
|----------|--------|
| No active assignment | Create an assignment first via `/ace:assign-create` |
| All phases done | Report completion to user |
| Phase fails | Attempt first, then use `fail` with command/error evidence; decide retry/add/ask |
| Skill not found | Execute instructions directly without skill |
| Unclear instructions | Ask user for clarification |

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
.cache/ace-assign/
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
# 1. Check status
$ ace-assign status
Phase 010: onboard [in_progress]

# 2. Execute phase (has skill: onboard)
$ /onboard
[Onboarding workflow runs...]

# 3. Write report
$ ace-assign report onboard-complete.md
Phase 010 marked done, advancing to 020

# 4. Check status again
$ ace-assign status
Phase 020: work-on-task [in_progress]

# 5. Execute next phase (has skill: ace:task-work)
$ /ace:task-work 148
[Task workflow runs...]

# 6. Report and continue...
$ ace-assign report task-done.md

# 7. Eventually...
$ ace-assign status
All phases complete!
```
