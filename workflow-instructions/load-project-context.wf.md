# Load Project Context Workflow Instruction

## Goal

Load essential project documentation to understand the project's objectives, architecture, and structure. This workflow provides the foundational project understanding needed before executing any other workflows or tasks.

## Prerequisites

- Access to the project's `docs/` directory
- Project documentation files exist and are populated

## High-Level Execution Plan

### Planning Steps

- [ ] Verify core project documentation files exist
- [ ] Identify any missing or incomplete documentation

### Execution Steps

- [ ] Load and review project objectives document
- [ ] Load and review architecture overview document
- [ ] Load and review project structure document
- [ ] Summarize key project context

## Process Steps

1. **Load Core Project Documentation:**
   Load and review the following essential project documents:

   - **Project Objectives**: `docs/what-do-we-build.md`
     - Understand what the project is building
     - Review the main goals and value proposition
     - Identify key features and capabilities

   - **Architecture Overview**: `docs/architecture.md`
     - Understand the high-level system design
     - Review architectural patterns and principles
     - Identify major components and their relationships

   - **Project Structure**: `docs/blueprint.md`
     - Understand the directory structure
     - Review key files and their purposes
     - Identify where different types of work are organized

2. **Verify Documentation Completeness:**
   - Check that all three core documents exist
   - Note any missing sections or outdated information
   - Report if any critical context is missing

3. **Summarize Key Context:**
   After loading all documents, create a mental model of:
   - What the project builds
   - How it's architected
   - Where things are located

## Success Criteria

- All three core project documents are loaded and understood
- Clear understanding of project objectives and scope
- Familiarity with the architecture and design principles
- Knowledge of project structure and organization
- Ready to work with project-specific context

## Common Patterns

### File Locations

The three core project context files are always located at:

- `docs/what-do-we-build.md` - Project objectives and vision
- `docs/architecture.md` - System design and technical architecture
- `docs/blueprint.md` - Project structure and organization

### Usage Context

This workflow is typically invoked:

- At the beginning of a new work session
- When onboarding to the project
- Before starting work on a new area of the codebase
- When other workflows specify "project context loading" as a prerequisite

### Verification Commands

```bash
# Check if all context files exist
ls -la docs/what-do-we-build.md docs/architecture.md docs/blueprint.md

# Check file sizes to ensure they're populated
wc -l docs/what-do-we-build.md docs/architecture.md docs/blueprint.md
```

## Usage Example
>
> "Load the project context so I understand what we're building"
