# Init Project Workflow Instruction

## Goal
Initialize the `docs-dev` and `docs-project` directory structures and create core documentation files (`what-do-we-build.md`, `architecture.md`, `blueprint.md`) to establish the foundation for an AI-assisted development workflow in a new or existing project.

## Process Steps

1. **Project Structure Setup**:
   - Create docs-dev directory if it doesn't exist
   - Create project management directories (backlog, current, done) inside the docs-project directory
   - Set up versioning structure using semantic versioning with sequence numbers
   - Initialize version control if needed

2. **Core Documentation Generation**:

   A. From Existing README:
   - Extract core information from project's README.md
   - Transform into structured what-do-we-build.md format
   - Generate initial architecture.md based on project structure

   B. Without README:
   - Gather project information through interactive prompts
   - Create what-do-we-build.md from responses
   - Generate architecture.md based on available information

3. **Initialize Version Control**:
   - Add .gitignore patterns for docs-dev
   - Create initial commit for docs structure

## Prerequisites

- Project root directory must be accessible with write permissions.
- Optional: An existing `README.md` can provide information for extraction.
- Optional: Git repository initialized (the workflow instruction can add to `.gitignore`).
## User Input (if README not present)

The workflow instruction will prompt for:

1. **Project Overview**:
   - Project name and purpose
   - Key features and goals
   - Target audience/users

2. **Technical Information**:
   - Core technologies used
   - External dependencies
   - Integration points

## Generated Documentation

### what-do-we-build.md

The workflow instruction generates this file with:
- Project overview and goals
- Key features and capabilities
- Core design principles
- Target use cases

Example structure:
```markdown
# Project Name

## What We Build 🔍
[Concise description of the project purpose]

## ✨ Key Features
- Feature 1: Description
- Feature 2: Description
[...]

## Core Design Principles
- Principle 1
- Principle 2
[...]
```

### architecture.md

The workflow instruction analyzes the project structure and generates:
- High-level architecture overview
- Component relationships
- Data flow diagrams
- Extension points

Example structure:
```markdown
# Architecture

## Overview
[High-level architectural description]

## Core Components
[Component breakdown with relationships]

## Data Flow
[Data flow between components]

## Extension Points
[Customization and extension capabilities]
```

## Output / Success Criteria

1. **Directory Structure**:
   - All required directories created
   - Proper permissions set
   - Git integration configured

2. **Core Documentation**:
   - what-do-we-build.md created with clear project vision
   - architecture.md reflects actual project structure
   - Documentation is concise yet complete

3. **Project Context**:
   - Development philosophy established
   - Technical boundaries defined
   - Extension points identified

## Workflow Instruction Context

Initialize an AI-driven development environment by creating necessary documentation structure and core architectural documents. This command sets up the foundation for effective AI agent collaboration.

## Behavior

- Preserves existing documentation if found
- Extracts project information from README.md when available
- Creates consistent structure for AI-driven development
- Sets up version control integration for documentation
## Reference Documentation
- [Writing Workflow Instructions Guide](../guides/writing-workflow-instructions.md)
- [Project Management Guide](../guides/project-management.md) (Explains the created structure)
- [What We Build Example](../docs-project/what-do-we-build.md)
- [Architecture Example](../docs-project/architecture.md)
- [Blueprint Example](../docs-project/blueprint.md)

## Prerequisites

- Project root directory must be accessible
- Write permissions for docs-dev directory
- README.md (optional) for project information extraction

## Notes

- The workflow instruction preserves existing documentation if found
- Merges information from README.md if available
- Creates consistent structure for AI-driven development
- Sets up proper git integration for documentation
