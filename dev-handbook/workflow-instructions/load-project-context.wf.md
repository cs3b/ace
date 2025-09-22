# Load Project Context Workflow Instruction

## Goal

Load essential project documentation to understand the project's objectives, architecture, and structure. This workflow provides the foundational project understanding needed before executing any other workflows or tasks.

## Prerequisites

- The `ace-context` tool is available (from ace-context gem)
- Context presets configured in `.ace/context/*.md` files

## Process Steps

1. **Load Project Context:**

   ```bash
   ace-context project
   ```

   This loads the project context as configured in your preset (in `.ace/context/project.md`), typically including:
   - Core documentation files (README, architecture, design docs)
   - Project configuration and setup files
   - Current repository status (git status, branch info)
   - Recent activity (commits, tasks, changes)
   - Project structure and file organization
   - Any custom context defined in the preset

2. **Review Loaded Context:**

   Read the complete cached context files to understand:

   ```bash
   # Read the full cached context files (not just snippets)
   # The ace-context tool outputs cache locations like:
   # .cache/ace-context/[preset-name].md
   ```
   
   From the full context, understand:
   - Project purpose and objectives
   - Technical architecture and design patterns
   - Development conventions and standards
   - Project structure and organization
   - Available tools and workflows
   - Current status and recent activity
   
   **IMPORTANT**: Always read the COMPLETE cached files, not partial snippets. The cached files contain essential project information that may be referenced throughout your work session.

3. **Load Additional Contexts (if requested):**

   ```bash
   # Load multiple presets if user specifically requests them
   ace-context dev-tools     # Additional context preset
   ace-context dev-handbook  # Another context preset

   # List available presets to see options
   ace-context --list
   ```

   Only load additional presets if the user explicitly asks for them.

## Success Criteria

- Project context successfully loaded from preset
- **Full cached context files have been read completely** (not just sampled)
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
