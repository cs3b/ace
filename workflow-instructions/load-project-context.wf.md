# Load Project Context Workflow Instruction

## Goal

Load essential project documentation to understand the project's objectives, architecture, and structure. This workflow provides the foundational project understanding needed before executing any other workflows or tasks.

## Prerequisites

- The `context` tool is available (from dev-tools)
- Context presets configured in `.coding-agent/context.yml`

## High-Level Execution Plan

### Planning Steps

- [ ] Verify context presets are available
- [ ] Choose appropriate preset(s) to load

### Execution Steps

- [ ] Run context command with preset
- [ ] Read the generated context output
- [ ] Review the loaded documentation and command outputs
- [ ] Summarize key project understanding

## Process Steps

1. **Load Project Context Using Context Tool:**
   
   Use the context tool with preset support:
   
   ```bash
   # Load the main project context
   context --preset project
   
   # For monorepo submodules, load specific contexts:
   context --preset dev-tools     # For dev-tools work
   context --preset dev-handbook  # For handbook work
   
   # List available presets
   context --list-presets
   ```
   
   This will:
   - Load the preset configuration from `.coding-agent/context.yml`
   - Process the template files and execute commands
   - Save output to the configured location (or override with --output)
   - Automatically chunk large contexts (>150K lines) if needed

2. **Read the Generated Context:**
   
   The context tool will output to the configured location:
   
   ```bash
   # Check preset configuration for output path
   context --list-presets
   
   # Or specify custom output
   context --preset project --output /tmp/project-context.md
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

Context configuration is located at:
- `.coding-agent/context.yml` - Preset definitions and configuration

Output files are generated based on preset configuration:
- Configured in each preset's `output` field
- Can be overridden with `--output` flag
- Large files automatically chunked with `_chunk*.md` suffix

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
# List available presets
context --list-presets

# View preset configuration
cat .coding-agent/context.yml

# Load context with preset
context --preset project

# Load with custom output
context --preset project --output /tmp/test.md

# Check output file size
wc -l <output-path-from-preset>
```

## Usage Example
>
> "Load the project context so I understand what we're building"
