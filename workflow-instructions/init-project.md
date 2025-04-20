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
   - Create `docs-project/what-do-we-build.md` from responses
   - Generate initial `docs-project/architecture.md` based on available information

3. **Initialize Version Control**:
   - Add patterns to `.gitignore` (e.g., `docs-dev/tools/.env`)
   - Create initial commit for docs structure

## Prerequisites

- Project root directory must be accessible with write permissions.
- Optional: An existing `README.md` at the project root can provide information for extraction.
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

### docs-project/what-do-we-build.md

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

### docs-project/architecture.md

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
   - `docs-dev` and `docs-project` directories created with standard structure.
   - Proper permissions set.
   - Git integration configured (`.gitignore` updated).

2. **Core Documentation**:
   - `docs-project/what-do-we-build.md` created with clear project vision.
   - `docs-project/architecture.md` reflects actual project structure.
   - `docs-project/blueprint.md` generated (or placeholder created).
   - Documentation is concise yet complete.

3. **Project Context**:
   - Development philosophy established.
   - Technical boundaries defined.
   - Extension points identified.

## Workflow Instruction Context

Initialize an AI-driven development environment by creating necessary documentation structure (`docs-dev`, `docs-project`) and core architectural documents. This command sets up the foundation for effective AI agent collaboration.

## Behavior

- Preserves existing documentation if found.
- Extracts project information from `README.md` when available.
- Creates consistent structure for AI-driven development.
- Sets up version control integration for documentation.
## Reference Documentation
- [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
- [Project Management Guide](docs-dev/guides/project-management.md) (Explains the created structure)
- [What We Build Example](docs-project/what-do-we-build.md) (Actual generated file)
- [Architecture Example](docs-project/architecture.md) (Actual generated file)
- [Blueprint Example](docs-project/blueprint.md) (Actual generated file)

## Prerequisites

- Project root directory must be accessible.
- Write permissions for `docs-dev` and `docs-project` directories.
- `README.md` (optional) for project information extraction.

## Notes

- The workflow instruction preserves existing documentation if found.
- Merges information from `README.md` if available.
- Creates consistent structure for AI-driven development.
- Sets up proper git integration for documentation.
