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

Use below template, if custom template is missing (at the end of the file) for each command file:

```md
read whole file and follow @dev-handbook/workflow-instructions/workflow-name.wf.md

/commit
```

### 3. Example Commands

#### create-task.md
```md
read whole file and follow @dev-handbook/workflow-instructions/create-task.wf.md

/commit
```

#### work-on-task.md
```md
read whole file and follow @dev-handbook/workflow-instructions/work-on-task.wf.md

/commit
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
- The `@` prefix references files relative to project root
- Always include the commit instruction at the end
- Commands should be concise and follow the established pattern


<templates>

<template workflow="load-project-context.wf.md">
read whole file and follow @dev-handbook/workflow-instructions/load-project-context.wf.md

/commit
</template>

<template workflow="commit.wf.md">
Try the multi-repo commit command first:

1. **Primary approach**: Run `bin/gc -i "intention-of-changes"` (e.g., `bin/gc -i "chore: taskflow / tools"`)
2. **If bin/gc fails or doesn't exist**: Fall back to detailed investigation:
   - Check if `bin/gc` exists: `ls -la bin/gc`
   - Check for submodules: `git submodule status` or `ls -la .gitmodules`
   - Check git status: `git status`
   - Then read whole file and follow @dev-handbook/workflow-instructions/commit.wf.md

Execute the appropriate commit strategy:
- **If bin/gc works**: The command handles all repositories automatically
- **If submodules exist**: Handle submodule commits first, then main repo
- **If single repo**: Follow standard git commit workflow

The workflow handles all necessary commits - do not create additional commits afterward
</template>

</templates>
