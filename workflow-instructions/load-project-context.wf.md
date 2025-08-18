# Load Project Context Workflow Instruction

## Goal

Load essential project documentation to understand the project's objectives, architecture, and structure. This workflow provides the foundational project understanding needed before executing any other workflows or tasks.

## Prerequisites

- The `context` tool is available (from dev-tools)
- Context presets configured in `.coding-agent/context.yml`

## Process Steps

1. **Load Project Context:**

   ```bash
   context --preset project
   ```

   This loads the project context as configured in your preset, typically including:
   - Core documentation files (README, architecture, design docs)
   - Project configuration and setup files
   - Current repository status (git status, branch info)
   - Recent activity (commits, tasks, changes)
   - Project structure and file organization
   - Any custom context defined in the preset

2. **Review Loaded Context:**

   From the context output, understand:
   - Project purpose and objectives
   - Technical architecture and design patterns
   - Development conventions and standards
   - Project structure and organization
   - Available tools and workflows
   - Current status and recent activity

3. **Load Additional Contexts (if requested):**

   ```bash
   # Load multiple presets if user specifically requests them
   context --preset dev-tools     # Additional submodule context
   context --preset dev-handbook  # Another submodule context

   # List available presets to see options
   context --list-presets
   ```

   Only load additional presets if the user explicitly asks for them.

## Success Criteria

- Project context successfully loaded from preset
- Clear understanding of project purpose and structure
- Familiarity with development conventions
- Ready to work with project-specific context

## Common Patterns

### When to Use

This workflow is typically invoked:
- At the beginning of a new work session
- Before starting work on a new area
- When switching between submodules
- When other workflows require project context

## Usage Examples

> `/load-project-context`
> "Load the project context"

> `/load-project-context dev-tools`
> "Load both project and dev-tools preset"
