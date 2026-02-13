---
name: drive-assignment
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
description: Drive agent execution through an active assignment
argument-hint: ""
doc-type: workflow
purpose: workflow instruction for driving ace-assign assignment execution

update:
  frequency: on-change
  last-updated: '2026-02-13'
---

# Drive Assignment Workflow

## Purpose

Drive agent execution through an active assignment by continuously checking status, executing the current phase, and reporting completion. This is the main execution loop for working through an assignment workflow.

## Prerequisites

- An active assignment exists (created via `ace-assign create` or `/ace:assign-create`)
- Assignment has at least one pending or in_progress phase

## Execution Loop

Repeat the following cycle until all phases are done or failed:

### Phase Decision Point

Before executing each phase, perform two assessments:

#### Skip Assessment

Evaluate whether the current phase should be skipped:

- **Already accomplished**: A previous phase already completed this work (e.g., tests were already run during implementation)
- **Not applicable**: Conditions changed and this phase is no longer relevant (e.g., no code changes were made, so lint is unnecessary)
- **Redundant**: An injected phase already covered this (e.g., a fix-tests phase already verified the test suite)
- **Metadata hint**: Phase file contains `skip_if` in its extra fields — evaluate the condition

If skipping is appropriate:
```bash
# Write a skip report explaining why
ace-assign report /tmp/skip-report.md
```

The report should clearly state the skip reason, e.g., "Skipped: tests already verified in phase 020."

#### Adaptation Assessment (After Each Phase)

After completing each phase, evaluate whether the assignment needs adaptation:

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
ace-assign status
```

Read the output to identify:
- Current phase number, name, and status
- Current phase's instructions
- Current phase's skill reference (if any)
- Remaining phases in the queue

**Note:** `ace-assign status` is the source of truth for assignment state. The phase files in the `phases/` directory are the backing store, but always query status via the command for accurate information.

### 2. Execute Current Phase

Based on the phase configuration:

#### If Phase Has a `skill:` Field

Invoke the referenced skill as the primary action, extracting parameters from the instructions:

```yaml
- name: work-on-task
  skill: ace:work-on-task
  instructions: |
    Work on task 148.
    Follow project conventions.
```

**Agent Action:** Run `/ace:work-on-task 148` then follow the skill workflow.

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

### 3. Write Report

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

Report content is appended to the phase file, and the queue advances to the next phase.

### 4. Handle Failures

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

### 5. Repeat

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
| `ace:work-on-task` | `/ace:work-on-task <taskref>` | Implement task changes |
| `ace:create-pr` | `/ace:create-pr` | Create pull request |
| `ace:review-pr` | `/ace:review-pr [pr#]` | Review code changes |
| `ace:commit` | `/ace:commit` | Generate commit message |
| `ace:update-pr-desc` | `/ace:update-pr-desc` | Update PR description |

## Error Handling

| Scenario | Action |
|----------|--------|
| No active assignment | Create an assignment first via `/ace:assign-create` |
| All phases done | Report completion to user |
| Phase fails | Use `fail` then decide: retry, add fix, or ask user |
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
.cache/ace-assign/<session-id>/
├── assignment.yaml               # Assignment metadata
├── phases/                       # Phase files (.ph.md extension)
│   ├── 010-init.ph.md           # done
│   ├── 020-implement.ph.md      # in_progress
│   └── 030-test.ph.md           # pending
└── reports/                      # Report files (.r.md extension)
    ├── 010-init.r.md            # completed report
    └── 020-implement.r.md       # in-progress report
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

# 5. Execute next phase (has skill: ace:work-on-task)
$ /ace:work-on-task 148
[Task workflow runs...]

# 6. Report and continue...
$ ace-assign report task-done.md

# 7. Eventually...
$ ace-assign status
All phases complete!
```
