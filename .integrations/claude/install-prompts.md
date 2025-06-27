# Claude Integration Install Prompts

## Overview

This guide shows how to create Claude Code commands for each workflow instruction. Each workflow file in `dev-handbook/workflow-instructions/*.wf.md` should have a corresponding command in `.claude/commands/`.

## Command Creation Process

### 1. Map Workflow Files to Commands

For each workflow instruction file, create a corresponding command file:

- `dev-handbook/workflow-instructions/create-task.wf.md` → `.claude/commands/create-task.md`
- `dev-handbook/workflow-instructions/work-on-task.wf.md` → `.claude/commands/work-on-task.md`
- `dev-handbook/workflow-instructions/review-task.wf.md` → `.claude/commands/review-task.md`

### 2. Command Template

Use this template for each command file:

```md
READ the WHOLE workflow and follow instructions in [@workflow-name.md](@file:dev-handbook/workflow-instructions/workflow-name.wf.md)

Commit all changes you have made, after you are sure the work is done
```

### 3. Example Commands

#### create-task.md
```md
READ the WHOLE workflow and follow instructions in [@create-task.md](@file:dev-handbook/workflow-instructions/create-task.wf.md)

Commit all changes you have made, after you are sure the work is done
```

#### work-on-task.md
```md
READ the WHOLE workflow and follow instructions in [@work-on-task.md](@file:dev-handbook/workflow-instructions/work-on-task.wf.md)

Commit all changes you have made, after you are sure the work is done
```

## Implementation Steps

1. **Identify missing commands**: Compare workflow files with existing command files
2. **Create missing commands**: Use the template above for each missing workflow
3. **Test commands**: Verify each command references the correct workflow file
4. **Update commands list**: Ensure all commands are registered in `.claude/commands/commands.json`

## Naming Convention

- Remove `.wf` from the workflow filename
- Keep the base name and `.md` extension
- Example: `create-task.wf.md` becomes `create-task.md`

## Notes

- Each command should reference exactly one workflow file
- The `@file:` reference must use the correct relative path
- Always include the commit instruction at the end
- Commands should be concise and follow the established pattern
