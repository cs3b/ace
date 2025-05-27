# Initialize Project Structure Workflow Instruction

## Goal

Initialize the `docs-dev` and `docs-project` directory structures and create core documentation files (`what-do-we-build.md`, `architecture.md`, `blueprint.md`) to establish the foundation for an AI-assisted development workflow in a new or existing project.

## Process Steps

1. **Project Structure Setup**:
    - **Submodule Branch**: Verify the `docs-dev` submodule is checked out to a branch other than `main` or `master`. If it's on `main`/`master`, create and switch to a new branch (e.g., `git checkout -b project-specific-docs`) to allow for project-specific tailoring without affecting the upstream repository.
    - Create project management directories (`backlog`, `current`, `done`) inside the `docs-project` directory.
    - Create the `docs-project/decisions/` directory and an empty `.keep` file within it (`docs-project/decisions/.keep`).
    - Determine initial version (e.g., `v0.0.1` with codename setup-the-infrastructure).
    - Create initial version directory structure: `docs-project/backlog/<initial_version>/docs/`.
    - Initialize version control if needed.

2. **Core Documentation Generation**:
    - **Identify Source**: Check if `PRD.md` exists at the project root.
        - If yes: **Move** `PRD.md` to `docs-project/backlog/<initial_version>/docs/PRD.md`. Use this file as the primary source.
        - If no: Check if `README.md` exists at the project root. Use this file as the primary source.
        - If neither exists: Prepare to use interactive prompts.
    - **Extract/Prompt**: Extract core information **including primary technology stack** (e.g., Ruby, Rust, TypeScript) from the identified source file (`PRD.md` or `README.md`). If no source file, use interactive prompts to gather this information.
    - **Generate**: Create/update `docs-project/what-do-we-build.md`, `docs-project/architecture.md` (ensuring it includes a 'Technology Stack' section), and `docs-project/blueprint.md` (typically placed directly in `docs-project/`) based on the gathered information.

3. **Initialize Version Control**:
   - Add relevant patterns to `.gitignore` (e.g., `docs-dev/tools/.env`)
   - Create initial commit for docs structure

4. **Tailor Development Guides**:
    - **Review `docs-dev/guides/`**: Identify sub-directories or files containing language-specific guidance (e.g., `coding-standards/ruby.md`, `testing/rust.md`).
    - **Identify Project Stack**: Confirm the primary technologies used in the project **by referencing the 'Technology Stack' section in `docs-project/architecture.md`**.
    - **Remove Irrelevant Guides**: Delete the language-specific guide files or directories that do **not** match the project's confirmed technology stack.
    - **Create Review Task**: Create a new task file (e.g., `docs-project/backlog/<initial_version>/tasks/01-identify-stack-specific-guides.md`) prompting an analysis of the project's needs against the current `docs-dev` guides and workflows. The goal is to identify any **missing** guidance or the need for **new, project-specific** documentation (e.g., guides for a specific library, custom deployment steps) tailored to the chosen technology stack.
        - *Example Task Title*: `Identify Need for Project-Specific [Stack] Guides/Workflows`

5. **Setup Project `bin/` Scripts from Binstubs**:
    - **Create Project `bin/` Directory**:
        - If it doesn't already exist, create a `bin/` directory at the project root: `mkdir bin`.
    - **Identify Binstub Templates**:
        - The standard binstub templates are located in `docs-dev/tools/_binstubs/`. These typically include `test`, `lint`, `build`, `run`, `tn`, `tr`, and `tree`.
    - **Copy Binstubs to Project `bin/`**:
        - For each file in `docs-dev/tools/_binstubs/`:
            - Let `binstub_name` be the name of the file (e.g., `test`).
            - Check if `bin/{binstub_name}` already exists in the project.
            - If `bin/{binstub_name}` does **not** exist, copy `docs-dev/tools/_binstubs/{binstub_name}` to `bin/{binstub_name}`.
            - If `bin/{binstub_name}` **does** exist, skip it to avoid overwriting existing project-specific scripts. Inform the user which scripts were skipped.
    - **Make Copied Scripts Executable**:
        - For all scripts newly copied into `bin/`, make them executable: `chmod +x bin/*`.
    - **Guidance on Binstubs**:
        - Remind the user that scripts like `bin/test`, `bin/lint`, `bin/build`, and `bin/run` are general placeholders. They will need to be tailored with project-specific commands based on the technology stack chosen for the project. This customization is typically handled in a subsequent setup task.
        - Scripts like `bin/tn`, `bin/tr`, and `bin/tree` are often thin wrappers for tools in `docs-dev/tools/`. They should function if the underlying tools are present and correctly referenced within the wrappers.

## Prerequisites

- Project root directory must be accessible with write permissions.
- Optional: An existing `PRD.md` (within `docs-project`) or `README.md` (at project root) can provide information for extraction.
- Optional: Git repository initialized (the workflow instruction can add to `.gitignore`).

## User Input (if PRD.md or README.md not present)

The workflow instruction will prompt for:

1. **Project Overview**:
    - Project name and purpose
    - Key features and goals
    - Target audience/users

2. **Technical Information**:
    - **Primary Technology Stack (e.g., Ruby, Rust, TypeScript)**
    - Core libraries/frameworks used
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

The workflow instruction analyzes the project structure and gathered info to generate:

- High-level architecture overview
- **Technology Stack** (Primary languages, frameworks)
- Component relationships
- Data flow diagrams (if inferrable)
- Extension points

Example structure:

```markdown
# Architecture

## Overview
[High-level architectural description]

## Technology Stack
- Language: [e.g., Ruby 3.2]
- Framework: [e.g., Rails 7]
- Key Libraries: [e.g., RSpec, Sidekiq]

## Core Components
[Component breakdown with relationships]

## Data Flow
[Data flow between components]

## Extension Points
[Customization and extension capabilities]
```

### docs-project/blueprint.md

The workflow instruction generates this file, which serves as a quick reference for project structure and key operational guidelines for an AI agent. It includes sections for read-only and ignored paths to guide agent behavior.

Example structure:

```markdown
# Project Blueprint: [Project Name]

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents
- [What We Build](docs-project/what-do-we-build.md) - Project vision and goals
- [Architecture](docs-project/architecture.md) - System design and implementation principles

## Project Organization

This project follows a documentation-first approach with these primary directories:

- **docs-dev/** - Development resources for the toolkit itself
  - **guides/** - Best practices and standards for various aspects of development
  - **tools/** - Utility scripts to support development workflows
  - **workflow-instructions/** - Structured commands for AI agents to execute common tasks
  - **zed/** - Integration with Zed editor

- **docs-project/** - Project-specific documentation
  - **current/** - Active release cycle work
  - **backlog/** - Pending tasks for future releases
  - **done/** - Completed releases and tasks
  - **decisions/** - Architecture Decision Records (ADRs)

- **bin/** - Executable scripts for project management and automation

## View Complete Directory Structure

To see the complete filtered directory structure, run:

` ``bash
bin/tree
` ``

This will show all project files while filtering out temporary files, session logs, and other non-essential directories.

## Key Project-Specific Files

- [Workflow Instructions](docs-dev/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](docs-dev/guides/README.md) - Development standards and best practices

## Read-Only Paths

This section lists files and directories that the agent should treat as read-only. Attempts to modify these paths should be flagged or prevented.

- *Add project-specific read-only globs here (e.g., `docs-project/releases/**/*`)*

## Ignored Paths

This section lists files, directories, or glob patterns that the agent should ignore entirely during its operations (e.g., when searching, reading, or editing files).

- `docs-project/done/**/*` # Default: Protects completed tasks and releases
- `**/node_modules/**`
- `**/.git/**`
- `**/__pycache__/**`
- `*.session.log`
- `*.lock`
- `*.tmp`
- `*~` # Backup files

## Submodules

The project currently has no Git submodules. All code is contained within this single repository.
```

## Output / Success Criteria

1. **Directory Structure**:
   - `docs-dev`, `docs-project`, and `docs-project/decisions` directories created with standard structure.
   - Proper permissions set.
   - Git integration configured (`.gitignore` updated).

2. **Core Documentation**:
   - `docs-project/what-do-we-build.md` created with clear project vision.
   - `docs-project/architecture.md` reflects actual project structure and includes the primary technology stack.
   - `docs-project/blueprint.md` generated with sections for "Read-Only Paths" (including a placeholder for project-specific rules) and "Ignored Paths" (pre-populated with defaults like `docs-project/done/**/*` and common examples).
   - Documentation is concise yet complete.

3. **Tailored Guides**:
   - Language-specific guides within `docs-dev/guides/` have been reviewed.
   - Guides irrelevant to the project's confirmed technology stack have been removed.
   - A backlog task has been created prompting identification of any missing or required new project-specific guides/workflows for the stack.

4. **Basic `bin/` Scripts Initialized**:
   - The project's `bin/` directory exists.
   - Binstubs from `docs-dev/tools/_binstubs/` (like `test`, `lint`, `build`, `run`, `tn`, `tr`, `tree`) have been copied to the project's `bin/` directory if they didn't already exist.
   - Copied scripts in `bin/` are executable.
   - User is aware that some `bin/` scripts (`test`, `lint`, `build`, `run`) are placeholders needing project-specific implementation.

5. **Project Context**:
   - Development philosophy established.
   - Technical boundaries defined.
   - Extension points identified.

## Workflow Instruction Context

Initialize an AI-driven development environment by creating necessary documentation structure (`docs-dev`, `docs-project`) and core architectural documents. This command sets up the foundation for effective AI agent collaboration.

## Behavior

- Preserves existing documentation if found.
- Extracts project information from `PRD.md` or `README.md` when available.
- Creates consistent structure for AI-driven development.
- Sets up version control integration for documentation.

## Reference Documentation

- [Project Management Guide](docs-dev/guides/project-management.md) (Explains the created structure)
- [What We Build Example](docs-project/what-do-we-build.md) (Actual generated file)
- [Architecture Example](docs-project/architecture.md) (Actual generated file)
- [Blueprint Example](docs-project/blueprint.md) (Actual generated file)

## Prerequisites

- Project root directory must be accessible.
- Write permissions for `docs-dev` and `docs-project` directories.
- `README.md` or `PRD.md` (optional) for project information extraction.

## Notes

- The workflow instruction preserves existing documentation if found.
- Merges information from `README.md` or `PRD.md` if available.
- Creates consistent structure for AI-driven development.
- Sets up proper git integration for documentation.
