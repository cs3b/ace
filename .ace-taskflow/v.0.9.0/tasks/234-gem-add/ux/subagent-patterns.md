# Subagent Patterns for ace-coworker

## Overview

ace-coworker workflows can instruct agents to spawn subagents for isolated task execution. The agent (Claude Code) drives subagent spawning via the Task tool; ace-coworker provides the patterns and captures the results.

## When to Use Subagents

### Use Subagents When

1. **Complex implementation needs isolation** - Subagent focuses on one thing without parent's workflow context
2. **Parallel work patterns** - Multiple subagents can work on different aspects (future enhancement)
3. **Retry isolation** - Failed subagent doesn't pollute parent's context
4. **Audit trail clarity** - Clear boundary between "what we delegated" and "what came back"

### Use Direct Execution When

1. **Simple commands** - `ace-test`, `ace-git-commit` run directly
2. **Workflow continuation** - `ace-bundle wfi://commit` keeps context
3. **Quick verifications** - Status checks, file reads
4. **Sequential dependencies** - Step needs previous step's context

## Instruction Patterns

### Pattern 1: Simple Subagent Delegation

```yaml
steps:
  - name: implement
    instructions: |
      Use the Task tool to delegate implementation:

      Task prompt:
      """
      Implement task $task following wfi://work-on-task

      Working directory: $working_dir
      Report: summary of changes, files modified, test results
      """

      After subagent returns, write combined report.
      Complete with: ace-coworker report <file>
```

### Pattern 2: Subagent with Worktree Isolation

```yaml
steps:
  - name: implement-in-worktree
    instructions: |
      1. Create worktree: ace-git-worktree create --task $task
         Capture: WORKTREE_PATH

      2. Use Task tool with explicit worktree:
         """
         Work on task $task

         CRITICAL: All work in $WORKTREE_PATH
         - cd $WORKTREE_PATH
         - Verify: git branch shows subtask branch
         - Implement changes per task file
         - Run tests: ace-test
         - Commit on subtask branch

         Report: changes made, files modified, test results
         """

      3. Write combined report with worktree results.
         Complete with: ace-coworker report <file>
```

### Pattern 3: Subagent with Specific Focus

```yaml
steps:
  - name: review-code
    instructions: |
      Use Task tool for focused review:
      """
      Review the code changes for security issues.

      Focus areas:
      - Input validation
      - Authentication/authorization
      - Secret handling

      Report: issues found, severity, recommendations
      """

      Summarize findings and continue workflow.
```

## Report Capture Flow

```
Parent Agent                    Subagent (Task tool)
     |                                |
     | 1. Read step instructions      |
     |                                |
     | 2. Spawn Task tool ----------->|
     |                                | 3. Execute isolated prompt
     |                                | 4. Produce output
     |<------ 5. Return result -------|
     |                                |
     | 6. Write combined report       |
     |    (parent summary + subagent output)
     |                                |
     | 7. ace-coworker report <file>  |
     |    (stores report, logs events, advances step)
```

## Context Isolation

### What Subagent Gets (Isolated)

| Aspect | Subagent View |
|--------|---------------|
| Instructions | Only the Task tool prompt |
| Session state | No access to parent's job.json |
| Conversation | Fresh context, no parent history |
| Workflow state | No knowledge of workflow steps |

### What is Shared

| Aspect | How Shared |
|--------|------------|
| Working directory | Same file system unless worktree used |
| Git state | Same repository and branch |
| Environment | Inherited from parent |
| Files created | Visible to both |

## Logging Events

ace-coworker logs subagent events in the session's log.jsonl:

```jsonl
{"ts":"8or5kz","event":"subagent_delegated","step":"implement","prompt_preview":"Implement task 228..."}
{"ts":"8or600","event":"subagent_completed","step":"implement","success":true}
```

The parent agent's combined report contains the full subagent output.

## Best Practices

### Do

- Give subagent explicit working directory paths
- Include verification commands in subagent prompt
- Request structured report format from subagent
- Summarize subagent results in parent's report

### Don't

- Expect subagent to know workflow context
- Rely on subagent reading parent's session state
- Spawn subagents for simple commands
- Skip writing combined report after subagent

## Example: Complete Workflow with Subagent

```yaml
name: task-with-subagent
description: Task completion using subagent for implementation

steps:
  - name: prepare
    instructions: |
      Read the task file and gather context.
      ace-taskflow task $task

  - name: implement
    instructions: |
      Use Task tool to delegate implementation:
      """
      Implement task $task

      Instructions:
      1. Read task: ace-taskflow task $task
      2. Follow the implementation plan
      3. Run tests: ace-test
      4. Commit changes with ace-git-commit

      Report:
      - Files created/modified
      - Test results
      - Commit hash
      """

      Write combined report summarizing subagent work.
      Complete with: ace-coworker report <file>

  - name: verify
    instructions: |
      Run final verification:
      - ace-test (all tests pass)
      - ace-lint (no lint errors)

      Report verification results.
      Complete with: ace-coworker report <file>
```

## Troubleshooting

### Subagent Ignores Working Directory

**Symptom:** Subagent works in wrong directory

**Solution:** Use explicit `cd` command and verification in prompt:
```
CRITICAL: Work in /path/to/worktree
1. cd /path/to/worktree
2. Verify: pwd shows correct path
3. Then proceed with work
```

### Subagent Output Lost

**Symptom:** Parent report missing subagent details

**Solution:** Instruct parent to include subagent output:
```
After subagent returns:
1. Copy key points from subagent output
2. Include file list and test results
3. Write combined report
```

### Subagent Context Pollution

**Symptom:** Subagent seems to know parent workflow details

**Solution:** Check that Task tool prompt is self-contained; don't reference "the current step" or "the workflow"
