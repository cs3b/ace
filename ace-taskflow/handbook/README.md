# ace-taskflow Handbook

This directory contains workflow instructions that have been migrated from the dev-handbook to be bundled with the ace-taskflow gem. These workflows are discoverable through the wfi-sources protocol system.

## Overview

The ace-taskflow gem provides integrated workflow management capabilities, combining task and release management with detailed workflow instructions. All workflows are now accessible directly from the installed gem.

## Workflow Instructions

The `workflow-instructions/` directory contains 12 core workflows for task and release management:

### Task Workflows
- **work-on-task.wf.md** - Execute tasks with embedded implementation plans
- **draft-task.wf.md** - Create initial task specifications
- **plan-task.wf.md** - Add detailed implementation plans to tasks
- **review-task.wf.md** - Review and validate task completion
- **replan-cascade-task.wf.md** - Cascade planning for dependent tasks
- **create-task-based-on-plan.wf.md** - Generate tasks from existing plans

### Release Workflows
- **draft-release.wf.md** - Create new release structures
- **publish-release.wf.md** - Finalize and publish releases

### Supporting Workflows
- **capture-idea.wf.md** - Capture and enhance raw ideas
- **create-reflection-note.wf.md** - Document lessons and insights
- **review-code.wf.md** - Perform code reviews
- **review-questions.wf.md** - Review and address project questions

## Command Reference

The workflows have been updated to use ace-taskflow commands:

### Task Management
```bash
# Get next task or navigate to specific task
ace-taskflow task                      # Get next pending task
ace-taskflow task 024                  # Navigate to task 024
ace-taskflow task v.0.9.0+024         # Navigate to specific version+task

# Create new tasks
ace-taskflow task create "Task Title"  # Create new task

# List tasks
ace-taskflow tasks                     # List all tasks
ace-taskflow tasks --status pending    # Filter by status
ace-taskflow tasks --current          # Tasks in current release
```

### Release Management
```bash
# Release operations
ace-taskflow release                   # Show current release info
ace-taskflow release create            # Create new release
```

### Idea Management
```bash
# Capture ideas
ace-taskflow idea "Your idea text"     # Capture idea from text
ace-taskflow idea --clipboard          # Capture from clipboard
ace-taskflow idea --file input.txt     # Capture from file
```

## Path References

Workflows now use dynamic path discovery instead of hardcoded paths:

- Use `ace-taskflow release` to get the current release path
- Replace hardcoded `.ace-taskflow/current/` with dynamic discovery
- Example: Instead of `.ace-taskflow/current/v.X.Y.Z/docs/`, use:
  1. Run `ace-taskflow release` to get path (e.g., `.ace-taskflow/v.0.9.0`)
  2. Append subdirectory (e.g., `.ace-taskflow/v.0.9.0/docs/`)

## Integration with dev-tools

The ace-taskflow workflows integrate seamlessly with dev-tools:
- Git operations remain unchanged (`git-commit`, `git mv`, `git push`)
- File creation tools will be enhanced in future ace-taskflow versions
- Current reflection creation is noted for future `ace-taskflow reflection create` command

## Protocol Configuration

The workflows are discoverable via the wfi-sources protocol:
- Configuration: `.ace.example/protocols/wfi-sources/ace-taskflow.yml`
- Type: `gem` (for gem-based discovery)
- Path: `handbook/workflow-instructions/`

## Migration Notes

This handbook was migrated from dev-handbook as part of task v.0.9.0+024:
- All 12 workflow files moved using `git mv`
- Path references updated to use `.ace-taskflow/` structure
- Commands updated to use `ace-taskflow` CLI
- Dynamic release path discovery implemented
- Protocol configuration added for workflow discovery

## Future Enhancements

Planned improvements for ace-taskflow workflows:
- `ace-taskflow reflection create` - Create reflection notes
- Enhanced file creation capabilities
- Integrated template management
- Workflow execution automation