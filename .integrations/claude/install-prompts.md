# Claude Integration Install Prompts

## Overview

This guide shows how to create Claude Code commands for each workflow instruction. Each workflow file in `dev-handbook/workflow-instructions/*.wf.md` should have a corresponding command in `.claude/commands/`.

## Automated Installation (Recommended)

Run the automated installation script from the project root:

```bash
# From project root (handbook-meta)
./bin/claude-integrate

# Or if you have it in your PATH
claude-integrate
```

The script will:
- Copy custom multi-task commands from templates
- Create command files for all workflow instructions
- Update `.claude/commands/commands.json` automatically
- Skip existing files to preserve user modifications
- Create backups before modifying JSON files

## Manual Command Creation Process

### 1. Map Workflow Files to Commands

For each workflow instruction file, create a corresponding command file:

- `dev-handbook/workflow-instructions/draft-task.wf.md` → `.claude/commands/draft-task.md`
- `dev-handbook/workflow-instructions/work-on-task.wf.md` → `.claude/commands/work-on-task.md`
- `dev-handbook/workflow-instructions/plan-task.wf.md` → `.claude/commands/plan-task.md`

### 2. Command Template

Use below template, if custom template is missing (at the end of the file) for each command file:

```md
read whole file and follow @dev-handbook/workflow-instructions/workflow-name.wf.md

read and run @.claude/commands/commit.md
```

### 3. Example Commands

#### draft-task.md
```md
read whole file and follow @dev-handbook/workflow-instructions/draft-task.wf.md

read and run @.claude/commands/commit.md
```

#### work-on-task.md
```md
read whole file and follow @dev-handbook/workflow-instructions/work-on-task.wf.md

/commit
read and run @.claude/commands/commit.md
```

## Script Output Example

```
Installing Claude Code commands...
Project root: /path/to/project

Copying custom multi-task commands...
✓ Created: draft-tasks.md
✓ Created: plan-tasks.md
✗ Skipped: work-on-tasks.md (already exists)

Found 25 workflow files
Creating command files...
✓ Created: draft-task.md
✓ Created: plan-task.md
✗ Skipped: work-on-task.md (already exists)

✓ Updated: commands.json (2 new entries added)

==================================================
Installation complete:
  4 created
  2 skipped
  1 files updated
==================================================
```

## Manual Implementation Steps

If you prefer manual setup or the automated script is not available:

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
