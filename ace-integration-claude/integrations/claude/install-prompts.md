# Claude Integration Install Prompts

## Overview

This guide shows how to install Claude Code commands using the unified handbook CLI. Each workflow file in `dev-handbook/workflow-instructions/*.wf.md` gets a corresponding command in the Claude Code interface.

## Automated Installation (Recommended)

Use the handbook CLI to manage Claude integration:

```bash
# Run complete integration workflow
handbook claude integrate

# Or step by step:
handbook claude validate          # Check current status
handbook claude generate-commands # Create missing commands
handbook claude update-registry   # Update command registry
handbook claude integrate         # Install to Claude
```

The handbook CLI will:
- Validate existing command coverage
- Generate missing commands from workflow instructions
- Maintain separate custom and generated command directories
- Update the command registry automatically
- Preserve custom commands and user modifications
- Support dry-run mode for safe testing

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

## Command Output Example

```
$ handbook claude integrate

Validating Claude integration...
✓ Registry structure valid
✓ All workflows have commands
✓ All file references valid

Generating missing commands...
✓ Generated: capture-idea.md
✓ Generated: create-reflection-note.md
✗ Skipped: work-on-task.md (already exists)

Updating registry...
✓ Registry updated with 2 new commands

Installing to Claude...
✓ Installed 6 custom commands
✓ Installed 24 generated commands
✓ Installed 2 agents

==================================================
Integration complete:
  Commands: 30 (6 custom, 24 generated)
  Agents: 2
  Status: All systems operational
==================================================
```

## Command Organization

The handbook CLI organizes commands into two categories:

### Custom Commands (_custom/)
Hand-crafted commands with special behavior:
- `commit.md` - Intelligent git commit workflow
- `draft-tasks.md` - Multi-task creation
- `load-project-context.md` - Project context loading
- `plan-tasks.md` - Task planning and breakdown
- `review-tasks.md` - Task review and validation
- `work-on-tasks.md` - Sequential task execution

### Generated Commands (_generated/)
Auto-generated from workflow instructions:
- One command per workflow file
- Consistent format and structure
- Automatically updated when workflows change

## Manual Verification

To verify the installation:

```bash
# List all installed commands
handbook claude list --verbose

# Check specific command type
handbook claude list --type custom
handbook claude list --type generated

# Validate command coverage
handbook claude validate --strict
```

## Naming Convention

- Remove `.wf` from the workflow filename
- Keep the base name and `.md` extension
- Example: `draft-task.wf.md` becomes `draft-task.md`

## Troubleshooting

### Commands Not Appearing in Claude
1. Verify Claude is installed and running
2. Check the Claude commands directory exists
3. Run with verbose mode: `handbook claude integrate --verbose`
4. Force reinstall: `handbook claude integrate --force`

### Validation Failures
1. Run validation to see specific issues: `handbook claude validate`
2. Auto-fix issues if possible: `handbook claude validate --fix`
3. Check workflow file format matches expected structure
4. Ensure all file paths are correct

### Generation Issues
1. Preview what will be generated: `handbook claude generate-commands --dry-run`
2. Check for naming conflicts with custom commands
3. Verify workflow files have proper frontmatter
4. Enable debug mode: `HANDBOOK_DEBUG=1 handbook claude generate-commands`

## Notes

- Commands are organized in `_custom/` and `_generated/` directories
- The handbook CLI manages the complete integration lifecycle
- Custom commands are preserved during regeneration
- Use `--dry-run` to preview changes before applying them
- The system maintains backward compatibility with existing commands
