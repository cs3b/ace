# Load Project Context Workflow Instruction

## Goal

Load essential project documentation to understand the project's objectives, architecture, and structure. This workflow provides the foundational project understanding needed before executing any other workflows or tasks.

## Prerequisites

- Access to the project's `docs/context/` directory
- Context definition files exist (`project.md`, `dev-tools.md`, `dev-handbook.md`)
- The `context` tool is available (from dev-tools)

## High-Level Execution Plan

### Planning Steps

- [ ] Verify context definition files exist
- [ ] Choose appropriate context(s) to load

### Execution Steps

- [ ] Run context loader for the target context
- [ ] Read the cached context file
- [ ] Review the loaded documentation and command outputs
- [ ] Summarize key project understanding

## Process Steps

1. **Load Project Context Using Context Tool:**
   
   Use the standardized context loading system:
   
   ```bash
   # Load the main project context
   bin/load-context project
   
   # For monorepo submodules, load specific contexts:
   bin/load-context dev-tools     # For dev-tools work
   bin/load-context dev-handbook  # For handbook work
   ```
   
   This will:
   - Process the context definition from `docs/context/{name}.md`
   - Load all specified files and run defined commands
   - Cache the output in `docs/context/cached/{name}.md`
   - Handle large contexts by splitting into chunks if needed

2. **Read the Cached Context:**
   
   After running the loader, read the cached context file:
   
   ```bash
   # The loader will output the path to read
   # Typically: docs/context/cached/project.md
   ```
   
   The cached context includes:
   - **Project Objectives**: From `docs/what-do-we-build.md`
   - **Architecture Overview**: From `docs/architecture.md` 
   - **Project Structure**: From `docs/blueprint.md`
   - **Development Tools**: From `docs/tools.md`
   - **Current Status**: Git status, task information, project tree
   - **Additional Context**: README files, configuration, etc.

3. **Review and Understand:**
   
   From the loaded context, understand:
   - What the project builds and its value proposition
   - The system architecture and design principles
   - The project structure and organization
   - Available tools and workflows
   - Current project status and next tasks

4. **Handle Large Contexts:**
   
   If the context is split into chunks:
   - The main file (`project.md`) will list all chunks
   - Read chunks sequentially as needed
   - Each chunk is under 150K lines for Claude Code compatibility

## Success Criteria

- All three core project documents are loaded and understood
- Clear understanding of project objectives and scope
- Familiarity with the architecture and design principles
- Knowledge of project structure and organization
- Ready to work with project-specific context

## Common Patterns

### File Locations

Context definition files are located at:
- `docs/context/project.md` - Main project context definition
- `docs/context/dev-tools.md` - Dev-tools submodule context
- `docs/context/dev-handbook.md` - Dev-handbook submodule context

Cached context files are generated at:
- `docs/context/cached/{name}.md` - Processed context output
- `docs/context/cached/{name}_chunk*.md` - Large context chunks

Core documentation files referenced:
- `docs/what-do-we-build.md` - Project objectives and vision
- `docs/architecture.md` - System design and technical architecture
- `docs/blueprint.md` - Project structure and organization
- `docs/tools.md` - Available development tools

### Usage Context

This workflow is typically invoked:

- At the beginning of a new work session
- When onboarding to the project
- Before starting work on a new area of the codebase
- When other workflows specify "project context loading" as a prerequisite
- When switching between different submodules in a monorepo

### Verification Commands

```bash
# List available context definitions
nav-ls --long docs/context/

# Check if cached context exists
nav-ls --long docs/context/cached/

# View context definition structure
cat docs/context/project.md

# Load and cache the context
bin/load-context project

# Check context file size
wc -l docs/context/cached/project.md
```

## Usage Example
>
> "Load the project context so I understand what we're building"
