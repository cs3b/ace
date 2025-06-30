# Update Project Blueprint Workflow Instruction

## Goal

Update the `dev-taskflow/blueprint.md` file with a concise summary of the current project structure, key files, and
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

- Check existing blueprint: `dev-taskflow/blueprint.md`
- Load project overview: `dev-taskflow/what-do-we-build.md`
- Load architecture: `dev-taskflow/architecture.md`
- Review current directory structure

## High-Level Execution Plan

### Planning Phase

- [ ] Analyze current project structure
- [ ] Identify key directories and files
- [ ] Determine what has changed since last update

### Execution Phase

- [ ] Generate updated directory structure overview
- [ ] Update key file descriptions
- [ ] Verify and update document links
- [ ] Add read-only and ignored paths sections
- [ ] Save updated blueprint

## Process Steps

1. **Identify Core Project Documents:**
   - Verify `dev-taskflow/what-do-we-build.md` and `dev-taskflow/architecture.md` are present
   - Check for any additional core documentation files

2. **Generate Blueprint Structure:**
   
   Use the blueprint template: path (dev-handbook/templates/project-docs/blueprint.template.md)

3. **Analyze Project Structure:**
   - Use `tree` command or similar to get current structure:

     ```bash
     tree -I 'node_modules|vendor|.git|coverage|tmp|log' -L 3
     ```

   - Identify main source directories (src/, app/, lib/, etc.)
   - Note test directory location (test/, spec/, tests/, etc.)
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
   - Save the updated `dev-taskflow/blueprint.md` file

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

- `dev-taskflow/blueprint.md` file is created or updated
- Contains accurate directory structure representation
- Technology stack is correctly identified
- Key files are listed with descriptions
- Read-only and ignored paths are specified
- All document links are valid and relative
- Information complements (not duplicates) other docs

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
- List every single file
- Include sensitive information
- Use absolute file paths

<templates>
    <template path="docs/blueprint.md" template-path="dev-handbook/templates/project-docs/blueprint.template.md">
# Blueprint

## Project Organization

### Directory Structure
```

.
├── bin/                    # Executable scripts
├── dev-taskflow/          # Task management
│   ├── backlog/          # Future releases
│   ├── current/          # Active release
│   └── done/             # Completed releases
├── docs-dev/             # Development documentation
├── src/                  # Source code (or app/, lib/, etc.)
├── test/                 # Test files (or spec/, tests/, etc.)
└── [project-specific directories]

```

### Key Files
- `README.md` - Project overview and setup
- `PRD.md` - Product requirements (if applicable)
- `.gitignore` - Git ignore rules
- `[build-file]` - Build configuration (package.json, Gemfile, etc.)

## Technology Stack
- **Language**: [Primary language and version]
- **Framework**: [Main framework and version]
- **Database**: [Database system and version]
- **Key Libraries**: 
  - [Library 1]: [Purpose]
  - [Library 2]: [Purpose]

## Development Workflow
1. Use `bin/tn` to get next task
2. Update task status to in-progress
3. Implement changes following coding standards
4. Run `bin/test` to verify changes
5. Run `bin/lint` to check code quality
6. Commit changes with conventional commits
7. Update task status to done

## Coding Standards
- [Standard 1]
- [Standard 2]
- [Standard 3]

## Read-Only Paths
AI agents should treat these paths as read-only:
- `dev-taskflow/done/**/*` - Archived releases
- [Project-specific read-only paths]

## Ignored Paths
AI agents should ignore these paths:
- `.git/` - Git internals
- `node_modules/` - Dependencies (if applicable)
- `vendor/` - Vendor dependencies (if applicable)
- `tmp/` - Temporary files
- `log/` - Log files
- `coverage/` - Test coverage reports
- [Project-specific ignored paths]

## Extension Points
- [Where/how to add new features]
- [Plugin/module system if applicable]
- [Configuration extension points]

## Core Documentation
- [What We Build](./what-do-we-build.md) - Project vision and goals
- [Architecture](./architecture.md) - Technical architecture and design
- [Roadmap](./roadmap.md) - Release planning (if exists)
    </template>
</templates>
