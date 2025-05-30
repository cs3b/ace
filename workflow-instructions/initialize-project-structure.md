# Initialize Project Structure Workflow Instruction

## Goal

Initialize the `docs-dev` and `docs-project` directory structures and create core documentation files
(`what-do-we-build.md`, `architecture.md`, `blueprint.md`) to establish the foundation for an
AI-assisted development workflow in a new or existing project.

**Idempotency**: This workflow is designed to be idempotent. Rerunning it will skip already completed steps or safely update existing files without overwriting customized content.

## Process Steps

1. **Project Structure Setup**:
    - **Submodule Branch**: Verify the `docs-dev` submodule is checked out to a branch other than
      `main` or `master`. If it's on `main`/`master`, create and switch to a new branch
      (e.g., `git checkout -b project-specific-docs`) to allow for project-specific tailoring
      without affecting the upstream repository.
    - Create project management directories (`backlog`, `current`, `done`) inside the `docs-project` directory.
    - Create the `docs-project/decisions/` directory and an empty `.keep` file within it (`docs-project/decisions/.keep`).

2. **Core Documentation Generation**:
    - **Identify Source**: Check if `PRD.md` exists at the project root.
        - If yes: Use this file as the primary source. If the existing `PRD.md` lacks structure, populate it using the template from `docs-dev/guides/initialize-project-templates/PRD.md`.
        - If no: Check if `README.md` exists at the project root. Use this file as the primary
          source. If the existing `README.md` lacks project information, enhance it using the template from `docs-dev/guides/initialize-project-templates/README.md`.
        - If neither exists: Create initial `PRD.md` and `README.md` files using the templates in `docs-dev/guides/initialize-project-templates/` and prepare to use interactive prompts to populate them.
    - **Extract/Prompt**: Extract core information **including primary technology stack**
      (e.g., Ruby, Rust, TypeScript) from the identified source file (`PRD.md` or `README.md`).
      If no source file or incomplete information, use interactive prompts to gather missing details.
    - **Interactive Prompts**: When using interactive prompts, ask comprehensive questions such as:
        - "What is the project's name and primary purpose?"
        - "What is the main technology stack (e.g., Node.js, Python, Ruby, Rust)?"
        - "What are 2-3 key features this project will provide?"
        - "Who are the primary users or target audience?"
        - "What external APIs or services will this project integrate with?"
    - **Generate**: Create/update `docs-project/what-do-we-build.md`, `docs-project/architecture.md`
      (ensuring it includes a 'Technology Stack' section), and `docs-project/blueprint.md`
      (typically placed directly in `docs-project/`) based on the gathered information and templates from `docs-dev/guides/initialize-project-templates/`.

3. **Setup Project `bin/` Scripts from Binstubs**:
    - **Create Project `bin/` Directory**:
        - If it doesn't already exist, create a `bin/` directory at the project root: `mkdir bin`.
    - **Identify Binstub Templates**:
        - The standard binstub templates are located in `docs-dev/tools/_binstubs/`. These typically
          include `test`, `lint`, `build`, `run`, `tn`, `tr`, and `tree`.
    - **Copy Binstubs to Project `bin/`**:
        - For each file in `docs-dev/tools/_binstubs/`:
            - Let `binstub_name` be the name of the file (e.g., `test`).
            - Check if `bin/{binstub_name}` already exists in the project.
            - If `bin/{binstub_name}` does **not** exist, copy
              `docs-dev/tools/_binstubs/{binstub_name}` to `bin/{binstub_name}`.
            - If `bin/{binstub_name}` **does** exist, skip it to avoid overwriting existing
              project-specific scripts. Inform the user which scripts were skipped.
    - **Make Copied Scripts Executable**:
        - For all scripts newly copied into `bin/`, make them executable: `chmod +x bin/*`.
    - **Guidance on Binstubs**:
        - Remind the user that scripts like `bin/test`, `bin/lint`, `bin/build`, and `bin/run` are
          general placeholders. They will need to be tailored with project-specific commands based
          on the technology stack chosen for the project. For detailed explanations of each binstub's purpose and common implementations, refer to the 'Command-line Tools (bin/)' section in `docs-project/architecture.md`.
        - Scripts like `bin/tn`, `bin/tr`, and `bin/tree` are often thin wrappers for tools in
          `docs-dev/tools/`. They should function if the underlying tools are present and correctly
          referenced within the wrappers.

## Prerequisites

- Project root directory must be accessible with write permissions.
- Optional: An existing `PRD.md` (within `docs-project`) or `README.md` (at project root) can provide information for extraction.
- Optional: Git repository initialized (the workflow instruction can add to `.gitignore`).

## User Input (if PRD.md or README.md not present or incomplete)

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

The generated file follows the template structure from `docs-dev/guides/initialize-project-templates/what-do-we-build.md` with sections for project overview, key features, design principles, and target use cases.

### docs-project/architecture.md

The workflow instruction analyzes the project structure and gathered info to generate:

- High-level architecture overview
- **Technology Stack** (Primary languages, frameworks)
- Component relationships
- Data flow diagrams (if inferrable)
- Extension points

The generated file follows the template structure from `docs-dev/guides/initialize-project-templates/architecture.md` with sections for technology stack, system architecture, command-line tools, and development patterns.

### docs-project/blueprint.md

The workflow instruction generates this file, which serves as a quick reference for project structure
and key operational guidelines for an AI agent. It includes sections for read-only and ignored paths
to guide agent behavior.

The generated file follows the template structure from `docs-dev/guides/initialize-project-templates/blueprint.md` with sections for project organization, technology stack, read-only paths, and ignored paths.

## Output / Success Criteria

1. **Directory Structure**:
   - `docs-dev`, `docs-project`, and `docs-project/decisions` directories created with standard structure.
   - Proper permissions set.
   - Git integration configured (`.gitignore` updated).

2. **Core Documentation**:
   - `docs-project/what-do-we-build.md` created with clear project vision using the template structure.
   - `docs-project/architecture.md` reflects actual project structure and includes the primary
     technology stack with command-line tools documentation.
   - `docs-project/blueprint.md` generated with sections for "Read-Only Paths" (including a
     placeholder for project-specific rules) and "Ignored Paths" (pre-populated with defaults like
     `docs-project/done/**/*` and common examples).
   - Documentation is concise yet complete and follows established templates.

3. **Basic `bin/` Scripts Initialized**:
   - The project's `bin/` directory exists.
   - Binstubs from `docs-dev/tools/_binstubs/` (like `test`, `lint`, `build`, `run`, `tn`, `tr`,
     `tree`) have been copied to the project's `bin/` directory if they didn't already exist.
   - Copied scripts in `bin/` are executable.
   - User is aware that some `bin/` scripts (`test`, `lint`, `build`, `run`) are placeholders
     needing project-specific implementation.

4. **Project Context**:
   - Development philosophy established using templates.
   - Technical boundaries defined in generated documentation.
   - Extension points identified and documented.

## Workflow Instruction Context

Initialize an AI-driven development environment by creating necessary documentation structure
(`docs-dev`, `docs-project`) and core architectural documents using standardized templates. This command sets up the foundation for effective AI agent collaboration with consistent, well-structured project documentation.

## Behavior

- Preserves existing documentation if found, enhancing it with template structure when needed.
- Extracts project information from `PRD.md` or `README.md` when available, using templates for missing sections.
- Creates consistent structure for AI-driven development using established templates.
- Uses interactive prompts with comprehensive example questions when source documents are unavailable.

## Reference Documentation

- [Project Management Guide](docs-dev/guides/project-management.md) (Explains the created structure)
- [Picking Codenames Guide](docs-dev/guides/picking-codenames.md) (Guidance for selecting appropriate codenames)
- [PRD Template](docs-dev/guides/initialize-project-templates/PRD.md) (Template for Product Requirements Documents)
- [README Template](docs-dev/guides/initialize-project-templates/README.md) (Template for project README files)
- [What We Build Template](docs-dev/guides/initialize-project-templates/what-do-we-build.md) (Template for project vision)
- [Architecture Template](docs-dev/guides/initialize-project-templates/architecture.md) (Template for technical architecture)
- [Blueprint Template](docs-dev/guides/initialize-project-templates/blueprint.md) (Template for project structure overview)

## Setup Requirements

- Project root directory must be accessible.
- Write permissions for `docs-dev` and `docs-project` directories.
- `README.md` or `PRD.md` (optional) for project information extraction.
- Access to template files in `docs-dev/guides/initialize-project-templates/`.

## Notes

- The workflow instruction preserves existing documentation if found, enhancing it with template structure.
- Uses templates to ensure consistent, comprehensive documentation across projects.
- Provides interactive prompts with example questions when source documents are unavailable.
- Creates idempotent workflow that can be safely rerun without overwriting customizations.
