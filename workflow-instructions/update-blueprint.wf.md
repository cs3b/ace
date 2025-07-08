# Update Project Blueprint Workflow Instruction

## Goal

Update the `docs/blueprint.md` file with a concise summary of the current project structure, key files, and
links to core project documents. The blueprint provides essential orientation for developers and AI agents to quickly
understand the project organization.

## Definition

A "blueprint" in this context is a concise overview document that provides orientation to the project's structure and
organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand
how to navigate the codebase.

## Prerequisites

- Project structure should be relatively stable
- Core documents (`what-do-we-build.md`, `architecture.md`) should exist and be reasonably up-to-date
- Write access to `dev-taskflow/` directory

## Project Context Loading

- Check existing blueprint: `docs/blueprint.md`
- Load project overview: `docs/what-do-we-build.md`
- Load architecture: `docs/architecture.md`
- Check for tools documentation: `docs/tools.md`
- Review current directory structure

## High-Level Execution Plan

### Planning Phase

- [ ] Analyze current project structure
- [ ] Identify key directories and files
- [ ] Check for existing specialized documentation (tools.md, etc.)
- [ ] Determine what has changed since last update

### Execution Phase

- [ ] Generate updated directory structure overview
- [ ] Update key file descriptions
- [ ] Verify and update document links
- [ ] Add read-only and ignored paths sections
- [ ] Save updated blueprint

## Process Steps

1. **Identify Core Project Documents:**
   - Verify `docs/what-do-we-build.md` and `docs/architecture.md` are present
   - Check for any additional core documentation files

2. **Generate Blueprint Structure:**

   Use the blueprint template:

3. **Analyze Project Structure:**
   - Use enhanced tree navigation to get current structure:

     ```bash
     nav-tree --project-structure --filter source
     ```

   - Identify main source directories with enhanced navigation:
     ```bash
     nav-ls --project-context --filter "src|app|lib"
     ```
   
   - Note test directory location and submodules with context awareness
   - Document any submodules if present

4. **Update Directory Descriptions:**
   - Replace placeholder directories with actual project structure
   - Add brief descriptions for each major directory
   - Include relationship between directories if relevant

5. **Identify Key Project-Specific Files:**
   - List critical configuration files
   - Include entry points and main modules
   - Focus on files unique to this project
   - Add version/build files (package.json, Gemfile, etc.)
   - **For tools**: If `docs/tools.md` exists, reference it instead of duplicating tool lists

6. **Extract Technology Stack:**
   - Read from architecture.md or analyze project files
   - Identify primary language and version
   - List main framework and key libraries
   - Include database and external services

7. **Define Agent Guidelines:**
   - Specify read-only paths (archived releases, etc.)
   - List ignored paths (dependencies, logs, etc.)
   - Add project-specific restrictions

8. **Update Links and Save:**
   - Ensure all internal document links are correct
   - Verify file paths are relative to blueprint location
   - Save the updated `docs/blueprint.md` file

## Common Directory Patterns

### Web Applications

```
app/          # Application code
config/       # Configuration files
public/       # Static assets
views/        # Templates
```

### Libraries/Packages

```
lib/          # Library source code
examples/     # Usage examples
benchmarks/   # Performance tests
```

### Microservices

```
services/     # Individual services
shared/       # Shared code
infra/        # Infrastructure config
```

## Technology Stack Detection

### Node.js

- Look for: `package.json`, `node_modules/`
- Key files: `index.js`, `server.js`, `app.js`

### Ruby

- Look for: `Gemfile`, `Rakefile`, `.ruby-version`
- Key files: `config.ru`, `app.rb`

### Python

- Look for: `requirements.txt`, `setup.py`, `pyproject.toml`
- Key files: `__main__.py`, `app.py`, `main.py`

### Rust

- Look for: `Cargo.toml`, `Cargo.lock`
- Key files: `main.rs`, `lib.rs`

## Output / Success Criteria

- `docs/blueprint.md` file is created or updated
- Contains accurate directory structure representation
- Technology stack is correctly identified
- Key files are listed with descriptions
- Read-only and ignored paths are specified
- All document links are valid and relative
- Information complements (not duplicates) other docs
- Tools information references `docs/tools.md` if it exists rather than duplicating

## Usage Example

Invoke this workflow when:

- Significant structural changes have occurred
- Before starting a major planning phase
- When onboarding new team members or AI agents
- After major refactoring or reorganization

Example:
> "Update the blueprint to reflect our new microservices structure"

## Best Practices

**DO:**

- Keep descriptions concise and focused
- Update after major structural changes
- Include technology versions when known
- Specify AI agent guidelines clearly
- Use relative paths for all links

**DON'T:**

- Include temporary or generated files
- Duplicate architecture documentation
- Duplicate detailed tools information (if `docs/tools.md` exists, reference it instead)
- List every single file
- Include sensitive information
- Use absolute file paths

<documents>
    <template path="dev-handbook/templates/project-docs/blueprint.template.md"># Project Blueprint: [Project Name]

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents

- [What We Build](docs/what-do-we-build.md) - Project vision and goals
- [Architecture](docs/architecture.md) - System design and implementation principles
- [Blueprint](docs/blueprint.md) - Project structure and organization

## Project Organization

<!-- Describe your project's main directory structure -->

This project follows a documentation-first approach with these primary directories:

- **dev-handbook/** - Development resources and workflows
  - **guides/** - Best practices and standards for development
  - **tools/** - Utility scripts to support development workflows
  - **workflow-instructions/** - Structured commands for AI agents
  - **zed/** - Editor integration (if applicable)

- **dev-taskflow/** - Project-specific documentation
  - **current/** - Active release cycle work
  - **backlog/** - Pending tasks for future releases
  - **done/** - Completed releases and tasks
  - **decisions/** - Architecture Decision Records (ADRs)

- **bin/** - Executable scripts for project management and automation

- **src/** - Source code (adjust directory names as needed)
  - **[component1]/** - Core functionality
  - **[component2]/** - Additional features
  - **utils/** - Shared utilities

- **tests/** - Test files and test utilities

- **config/** - Configuration files

<!-- Add your project-specific directories here -->

## View Complete Directory Structure

To see the complete filtered directory structure, run:

```bash
nav-tree
```

This will show all project files while filtering out temporary files, session logs, and other non-essential directories.

## Key Project-Specific Files

<!-- List important files that developers should know about -->

- [Workflow Instructions](dev-handbook/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](dev-handbook/guides/README.md) - Development standards and best practices
- [Configuration](README.md) - Configuration documentation (if applicable)

## Technology Stack

<!-- Summarize the main technologies used -->

- **Primary Language**: [e.g., JavaScript, Python, Rust]
- **Framework**: [e.g., React, Django, Axum]
- **Database**: [e.g., PostgreSQL, MongoDB, SQLite]
- **Key Libraries**: [List important dependencies]
- **Development Tools**: [e.g., Docker, Webpack, Cargo]

## Read-Only Paths

This section lists files and directories that the agent should treat as read-only. Attempts to modify these paths should be flagged or prevented.

<!-- Add project-specific read-only paths -->
- `docs/decisions/**/*`
- `dev-taskflow/done/**/*`
- `*.lock` # Dependency lock files
- `dist/**/*` # Built artifacts
- `build/**/*` # Build output

## Ignored Paths

This section lists files, directories, or glob patterns that the agent should ignore entirely during its operations (e.g., when searching, reading, or editing files).

- `dev-taskflow/done/**/*` # Default: Protects completed tasks and releases
- `**/node_modules/**`
- `**/.git/**`
- `**/__pycache__/**`
- `**/target/**` # Rust build artifacts
- `**/dist/**` # Built distributions
- `**/build/**` # Build artifacts
- `**/.env` # Environment files
- `**/.env.*` # Environment variants
- `*.session.log`
- `*.lock`
- `*.tmp`
- `*~` # Backup files
- `**/.DS_Store` # macOS system files
- `**/Thumbs.db` # Windows system files

## Entry Points

<!-- Document the main ways to start or interact with the project -->

### Development

```bash
# Start development server
bin/run

# Run tests
bin/test

# Build for production
bin/build
```

### Common Workflows

- **New Feature**: Use `task-manager next` to find next task, follow task workflow
- **Bug Fix**: Create task in backlog, prioritize, implement
- **Documentation**: Update relevant files in `dev-taskflow/`

## Dependencies

<!-- List major external dependencies and their purposes -->

### Runtime Dependencies

- [Library 1]: Purpose and version constraints
- [Library 2]: Purpose and version constraints

### Development Dependencies

## Submodules

<!-- Document any Git submodules used -->

### docs-dev (if applicable)

- Path: `docs-dev`
- Repository: [Repository URL]
- Purpose: Development workflows and guides
- **Important**: Commits for this submodule must be made from within the submodule directory

### [Other Submodules]

- Path: `[path]`
- Repository: [Repository URL]
- Purpose: [Description]

---

*This blueprint should be updated when significant structural changes are made to the project. Use the `update-blueprint` workflow to keep it current.*
</template>
</documents>
