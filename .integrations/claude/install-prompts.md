# Claude Integration Install Prompts

## Overview

This guide shows how to create Claude Code commands for each workflow instruction. Each workflow file in `dev-handbook/workflow-instructions/*.wf.md` should have a corresponding command in `.claude/commands/`.

## Command Creation Process

### 1. Map Workflow Files to Commands

For each workflow instruction file, create a corresponding command file:

- `dev-handbook/workflow-instructions/draft-task.wf.md` → `.claude/commands/draft-task.md`
- `dev-handbook/workflow-instructions/work-on-task.wf.md` → `.claude/commands/work-on-task.md`
- `dev-handbook/workflow-instructions/plan-task.wf.md` → `.claude/commands/plan-task.md`

### 2. Command Template

Use below template, if custom template is missing (at the end of the file) for each command file:

```md
read whole file and follow @dev-handbook/workflow-instructions/workflow-name.wf.md

/commit
```

### 3. Example Commands

#### draft-task.md
```md
read whole file and follow @dev-handbook/workflow-instructions/draft-task.wf.md

/commit
```

#### work-on-task.md
```md
read whole file and follow @dev-handbook/workflow-instructions/work-on-task.wf.md

/commit
```

## Implementation Steps

1. **Copy custom multi-task commands**: Copy pre-built commands from templates
   ```bash
   cp dev-handbook/.integrations/claude/commands/*.md .claude/commands/
   ```
2. **Identify missing commands**: Compare workflow files with existing command files
3. **Create missing commands**: Use the template above for each missing workflow
4. **Test commands**: Verify each command references the correct workflow file
5. **Update commands list**: Ensure all commands are registered in `.claude/commands/commands.json`

## Naming Convention

- Remove `.wf` from the workflow filename
- Keep the base name and `.md` extension
- Example: `draft-task.wf.md` becomes `draft-task.md`

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
# Goal

Ensure all changes you have made in the current session, or what user point to are commit in git.

# PLAN

1. Ensure you commit (using `git-commit`) all changes that you have modified / created / deleted in this session (if user not ask differently). e.g.: git-commit item1/path/to item2/path/to item3/path/to ... --intention "write a intention of changes in the session" => `git-commit dev-tools/src/main.rb dev-tools/spec/test.rb dev-handbook/tpl/dotfiles/path.yml --intention "fix authentication bug"`

2. Run `git-status` to check if everything you modified have beedn commited.

# Supplementary Inforatiom about Git toolbox

1. **Check current status**: Run `git-status` to see all changes across repositories
2. **Commit with intention**:
   - **Specific files**: `git-commit path/1/file path/2/file --intention "why we commit"`
     - Use full paths from project root (works with submodules): `dev-tools/lib/main.rb dev-handbook/guide.md`
     - Or local paths from current directory: `lib/main.rb spec/test.rb`
   - **All changes**: `git-commit --intention "why we commit"`

**Examples:**
```bash
# Commit specific files with intention (local paths)
git-commit src/main.rb spec/test.rb --intention "fix authentication bug"

# Commit files across submodules (full paths from project root)
git-commit dev-tools/lib/main.rb dev-handbook/guides/setup.md --intention "update setup documentation"

# Commit all changes
git-commit --intention "update documentation"
```

The enhanced git-commit tool automatically generates appropriate commit messages based on changes and intention.
</template>

</templates>
