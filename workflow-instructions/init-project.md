# Init Project Workflow Instruction

## Goal
Initialize the `docs-dev` and `docs-project` directory structures and create core documentation files (`what-do-we-build.md`, `architecture.md`, `blueprint.md`) to establish the foundation for an AI-assisted development workflow in a new or existing project.

## Process Steps

1.  **Project Structure Setup**:
    - **Submodule Branch**: Verify the `docs-dev` submodule is checked out to a branch other than `main` or `master`. If it's on `main`/`master`, create and switch to a new branch (e.g., `git checkout -b project-specific-docs`) to allow for project-specific tailoring without affecting the upstream repository.
    - Create project management directories (`backlog`, `current`, `done`) inside the `docs-project` directory.
    - Create the `docs-project/decisions/` directory and an empty `.keep` file within it (`docs-project/decisions/.keep`).
    - Determine initial version (e.g., `v0.0.1` with codename setup-the-infrastructure).
    - Create initial version directory structure: `docs-project/backlog/<initial_version>/docs/`.
    - Initialize version control if needed.

2.  **Core Documentation Generation**:
    - **Identify Source**: Check if `PRD.md` exists at the project root.
        - If yes: **Move** `PRD.md` to `docs-project/backlog/<initial_version>/docs/PRD.md`. Use this file as the primary source.
        - If no: Check if `README.md` exists at the project root. Use this file as the primary source.
        - If neither exists: Prepare to use interactive prompts.
    - **Extract/Prompt**: Extract core information **including primary technology stack** (e.g., Ruby, Rust, TypeScript) from the identified source file (`PRD.md` or `README.md`). If no source file, use interactive prompts to gather this information.
    - **Generate**: Create/update `docs-project/what-do-we-build.md`, `docs-project/architecture.md` (ensuring it includes a 'Technology Stack' section), and `docs-project/blueprint.md` (typically placed directly in `docs-project/`) based on the gathered information.

3. **Initialize Version Control**:
   - Add relevant patterns to `.gitignore` (e.g., `docs-dev/tools/.env`)
   - Create initial commit for docs structure

4.  **Tailor Development Guides**:
    - **Review `docs-dev/guides/`**: Identify sub-directories or files containing language-specific guidance (e.g., `coding-standards/ruby.md`, `testing/rust.md`).
    - **Identify Project Stack**: Confirm the primary technologies used in the project **by referencing the 'Technology Stack' section in `docs-project/architecture.md`**.
    - **Remove Irrelevant Guides**: Delete the language-specific guide files or directories that do **not** match the project's confirmed technology stack.
    - **Create Review Task**: Create a new task file (e.g., `docs-project/backlog/<initial_version>/tasks/01-identify-stack-specific-guides.md`) prompting an analysis of the project's needs against the current `docs-dev` guides and workflows. The goal is to identify any **missing** guidance or the need for **new, project-specific** documentation (e.g., guides for a specific library, custom deployment steps) tailored to the chosen technology stack.
        - *Example Task Title*: `Identify Need for Project-Specific [Stack] Guides/Workflows`

## Prerequisites

- Project root directory must be accessible with write permissions.
- Optional: An existing `PRD.md` (within `docs-project`) or `README.md` (at project root) can provide information for extraction.
- Optional: Git repository initialized (the workflow instruction can add to `.gitignore`).

## User Input (if PRD.md or README.md not present)

The workflow instruction will prompt for:

1.  **Project Overview**:
    - Project name and purpose
    - Key features and goals
    - Target audience/users

2.  **Technical Information**:
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

## Output / Success Criteria

1. **Directory Structure**:
   - `docs-dev`, `docs-project`, and `docs-project/decisions` directories created with standard structure.
   - Proper permissions set.
   - Git integration configured (`.gitignore` updated).

2. **Core Documentation**:
   - `docs-project/what-do-we-build.md` created with clear project vision.
   - `docs-project/architecture.md` reflects actual project structure and includes the primary technology stack.
   - `docs-project/blueprint.md` generated (or placeholder created).
   - Documentation is concise yet complete.

3. **Tailored Guides**:
   - Language-specific guides within `docs-dev/guides/` have been reviewed.
   - Guides irrelevant to the project's confirmed technology stack have been removed.
   - A backlog task has been created prompting identification of any missing or required new project-specific guides/workflows for the stack.

4. **Project Context**:
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
- [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
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
