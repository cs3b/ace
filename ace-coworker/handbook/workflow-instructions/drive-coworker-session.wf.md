---
name: drive-coworker-session
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
description: Drive agent execution through an active coworker session
argument-hint: ""
doc-type: workflow
purpose: workflow instruction for driving ace-coworker session execution

update:
  frequency: on-change
  last-updated: '2026-01-28'
---

# Drive Coworker Session Workflow

## Purpose

Drive agent execution through an active coworker session by continuously checking status, executing the current step, and reporting completion. This is the main execution loop for working through a coworker workflow.

## Prerequisites

- An active coworker session exists (created via `ace-coworker create` or `/ace:coworker-create-session`)
- Session has at least one pending or in_progress step

## Execution Loop

Repeat the following cycle until all steps are done or failed:

### 1. Check Status

```bash
ace-coworker status
```

Read the output to identify:
- Current step number, name, and status
- Current step's instructions
- Current step's skill reference (if any)
- Remaining steps in the queue

**Note:** `ace-coworker status` is the source of truth for session state. The step files in the `jobs/` directory are the backing store, but always query status via the command for accurate information.

### 2. Execute Current Step

Based on the step configuration:

#### If Step Has a `skill:` Field

Invoke the referenced skill as the primary action, extracting parameters from the instructions:

```yaml
- name: work-on-task
  skill: ace:work-on-task
  instructions: |
    Work on task 148.
    Follow project conventions.
```

**Agent Action:** Run `/ace:work-on-task 148` then follow the skill workflow.

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

### 3. Write Report

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
ace-coworker report /tmp/step-report.md
```

Report content is appended to the step file, and the queue advances to the next step.

### 4. Handle Failures

If a step cannot be completed:

```bash
# Mark step as failed with reason
ace-coworker fail --message "Tests failed: test_greet, test_shout"
```

Then decide on next action:

#### Option A: Retry the Failed Step

```bash
ace-coworker retry <step-number>
```

Creates a new step linked to the original. Original remains visible as failed.

#### Option B: Add a Fix Step

```bash
ace-coworker add "fix-issue" --instructions "Fix the failing tests and verify"
```

New step is inserted after the current in-progress step.

#### Option C: Ask the User

If uncertain, ask the user whether to retry, add a fix step, or abort.

### 5. Repeat

Check status again:
- If there is a next step, continue the loop from step 1
- If all steps are `done`, proceed to Completion
- If session has failed steps and no fix is planned, report to user

## Completion

When `ace-coworker status` shows all steps as `done`:

```bash
ace-coworker status
```

Example output:
```
Session: work-on-task-123 (8or5kx)

Step  Status    Name
010   done      onboard
020   done      work-on-task
030   done      finalize

All steps complete!
```

Summarize the session results to the user:
- What was accomplished
- Any artifacts created (PRs, commits, etc.)
- Next steps or follow-up actions

## Skill Invocation Pattern

When executing a step with a `skill:` field:

1. **Read step instructions** - Understand context and parameters
2. **Extract parameters** - Get task IDs, PR numbers from instructions
3. **Invoke skill** - Run the referenced skill command
4. **Follow skill workflow** - Complete the skill's process
5. **Report completion** - Use `ace-coworker report` with results

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
| No active session | Create a session first via `/ace:coworker-create-session` |
| All steps done | Report completion to user |
| Step fails | Use `fail` then decide: retry, add fix, or ask user |
| Skill not found | Execute instructions directly without skill |
| Unclear instructions | Ask user for clarification |

## Session State Reference

### Step Status Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `pending` | Step not started | Cannot execute (wait for queue) |
| `in_progress` | Step is active | Execute this step |
| `done` | Step completed | Move to next step |
| `failed` | Step failed | Decide: retry, add fix, or abort |

### Session Directory Structure

```
.cache/ace-coworker/<session-id>/
├── session.yaml                   # Session metadata
├── jobs/                          # Step files (.j.md extension)
│   ├── 010-init.j.md             # done
│   ├── 020-implement.j.md        # in_progress
│   └── 030-test.j.md             # pending
└── reports/                       # Report files (.r.md extension)
    ├── 010-init.r.md             # completed report
    └── 020-implement.r.md        # in-progress report
```

Each step has:
- **Step file** (`jobs/NNN-name.j.md`) - Contains step instructions and status
- **Report file** (`reports/NNN-name.r.md`) - Contains completion report (created when step is done)

## Numbering Convention

| Pattern | Purpose | Example |
|---------|---------|---------|
| `010`, `020`, `030` | Main tasks (10-step gaps) | `010-init.j.md` |
| `010.01`, `010.02` | Subtasks | `010.01-setup.j.md` |
| `041`, `042` | Injected after existing | `041-fix.j.md` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | No active session |
| 3 | File not found (report file) |
| 4 | Invalid step reference |

## Success Criteria

- All steps processed (done or failed)
- Reports written for all completed steps
- Failed steps have clear failure reasons
- User informed of session completion state
- Artifacts and next steps clearly communicated

## Example Session Flow

```bash
# 1. Check status
$ ace-coworker status
Step 010: onboard [in_progress]

# 2. Execute step (has skill: onboard)
$ /onboard
[Onboarding workflow runs...]

# 3. Write report
$ ace-coworker report onboard-complete.md
Step 010 marked done, advancing to 020

# 4. Check status again
$ ace-coworker status
Step 020: work-on-task [in_progress]

# 5. Execute next step (has skill: ace:work-on-task)
$ /ace:work-on-task 148
[Task workflow runs...]

# 6. Report and continue...
$ ace-coworker report task-done.md

# 7. Eventually...
$ ace-coworker status
All steps complete!
```
