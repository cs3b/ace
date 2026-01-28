---
name: coworker-session
allowed-tools: Bash, Read, Write
description: Manage workflow sessions using ace-coworker work queue model
argument-hint: "[start|status|report|fail|add|retry] [args]"
doc-type: workflow
purpose: workflow instruction for ace-coworker session management

update:
  frequency: on-change
  last-updated: '2026-01-28'
---

# Coworker Session Workflow

## Purpose

Manage workflow sessions using ace-coworker's file-based work queue model where:
- Steps have states: `done`, `in_progress`, `pending`, `failed`
- Failed steps remain visible as history (never overwritten)
- Work can be added dynamically during execution
- Retry creates new steps linked to the original

## Session Lifecycle

```
start (from config) → work on steps → report/fail → advance → complete
                              ↓
                    add (dynamic steps)
                              ↓
                    retry (failed steps)
```

## Commands

### Start Session

```bash
ace-coworker start --config job.yaml
```

Creates session directory with:
- `.cache/ace-coworker/<session-id>/session.yaml` - metadata
- `.cache/ace-coworker/<session-id>/jobs/*.md` - step files

### Check Status

```bash
ace-coworker status
```

Shows queue table with all steps and current instructions.

### Complete Step with Report

```bash
# Write your report
echo "Step completed successfully" > report.md

# Submit report
ace-coworker report report.md
```

Report content is appended to step file. Queue advances to next step.

### Mark Step as Failed

```bash
ace-coworker fail --message "2 tests failed: test_greet, test_shout"
```

Step is marked failed (preserved in history). No automatic advancement.

### Add Dynamic Step

```bash
ace-coworker add "fix-bug" --instructions "Fix the implementation"
```

New step inserted after current in-progress step.

### Retry Failed Step

```bash
ace-coworker retry 040
```

Creates new step linked to original. Original remains visible as failed.

## Job Configuration Format

```yaml
session:
  name: my-workflow
  description: Optional description

steps:
  - name: init
    instructions: |
      Set up the project structure.
      Report when done: ace-coworker report init.md

  - name: implement
    skill: ace:work-on-task      # Optional skill reference
    instructions: |
      Implement the feature.
      Report when done: ace-coworker report impl.md

  - name: test
    instructions: |
      Run tests and verify.
      Report when done: ace-coworker report test.md
```

## Skill-Aware Steps

Steps can include a `skill:` field that references a Claude Code skill to invoke:

### Recognizing Skill References

When a step has a `skill:` field, invoke that skill as the primary action:

```yaml
- name: work-on-task
  skill: ace:work-on-task
  instructions: |
    Work on task 123.
    Follow project conventions.
```

**Agent Action**: Invoke `/ace:work-on-task 123` then follow the skill workflow.

### Common Skill References

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `onboard` | `/onboard` | Load project context |
| `ace:work-on-task` | `/ace:work-on-task <taskref>` | Implement task changes |
| `ace:create-pr` | `/ace:create-pr` | Create pull request |
| `ace:review-pr` | `/ace:review-pr [pr#]` | Review code changes |
| `ace:commit` | `/ace:commit` | Generate commit message |
| `ace:update-pr-desc` | `/ace:update-pr-desc` | Update PR description |

### Skill Invocation Pattern

When executing a step with a skill:

1. **Read step instructions** - Understand context and parameters
2. **Extract parameters** - Get task IDs, PR numbers from instructions
3. **Invoke skill** - Run the referenced skill command
4. **Follow skill workflow** - Complete the skill's process
5. **Report completion** - Use `ace-coworker report` with results

### Parameter Passing

Extract parameters from instructions for skill invocation:

```yaml
- name: work-on-task
  skill: ace:work-on-task
  instructions: |
    Work on task 148.          # ← Extract "148" as taskref
    Implement required changes.
```

**Agent Action**: Run `/ace:work-on-task 148`

### Dynamic Parameter Updates

Some steps need parameters from previous steps (e.g., PR number):

```yaml
- name: create-pr
  skill: ace:create-pr
  instructions: |
    Create a pull request.
    Capture the PR number for subsequent review steps.
    Update the next steps with the PR number.
```

When completing this step:
1. Note the PR number from the skill output
2. Mentally track for subsequent review steps
3. Report includes the PR number for reference

## Step File Format

Each step is a markdown file with frontmatter:

```markdown
---
name: implement-feature
status: in_progress
started_at: 2026-01-28T10:00:00Z
---

# Instructions

Implement the feature...

---

# Report

(Appended when step is completed)
```

## Typical Workflow

1. **Create job.yaml** with session configuration and steps
2. **Start session**: `ace-coworker start --config job.yaml`
3. **Work on each step** following instructions
4. **Report completion**: `ace-coworker report my-report.md`
5. **Handle failures**: Use `fail`, `add`, or `retry` as needed
6. **Complete workflow**: All steps done or failed

## Error Handling

| Scenario | Command |
|----------|---------|
| Step fails | `ace-coworker fail --message "reason"` |
| Need fix step | `ace-coworker add "fix-step" --instructions "..."` |
| Retry after fix | `ace-coworker retry <step-number>` |
| Check progress | `ace-coworker status` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | No active session |
| 3 | File not found (config or report) |
| 4 | Invalid step reference |

## Success Criteria

- [ ] Session started from config
- [ ] Steps progress through queue
- [ ] Reports appended to step files
- [ ] Failed steps preserved in history
- [ ] Dynamic steps inserted correctly
- [ ] Retry creates linked steps
- [ ] Complete workflow visible in status
