# Initialize Project Structure Workflow Instruction

## Goal

Initialize the `dev-handbook` and `dev-taskflow` directory structures and create core documentation files
(`what-do-we-build.md`, `architecture.md`, `blueprint.md`) to establish the foundation for an
AI-assisted development workflow in a new or existing project.

**Idempotency**: This workflow is designed to be idempotent. Rerunning it will skip already completed steps or safely update existing files without overwriting customized content.

## Process Steps

1. **Project Structure Setup**:
    - **Submodule Verification**: Verify that both required submodules (`dev-handbook` and `dev-tools`) are present and properly initialized.
    - Create project management directories (`backlog`, `current`, `done`) inside the `dev-taskflow` directory.

2. **Core Documentation Generation**:
    - **Identify Source**: Check if `PRD.md` exists at the project root.
        - If yes: Use this file as the primary source. If the existing `PRD.md` lacks structure, populate it using the PRD template.
        - If no: Check if `README.md` exists at the project root. Use this file as the primary source. If the existing `README.md` lacks project information, enhance it using the README template.
        - If neither exists: Create initial `PRD.md` and `README.md` files using the project templates and prepare to use interactive prompts to populate them.
    - **Extract/Prompt**: Extract core information **including primary technology stack**
      (e.g., Ruby, Rust, TypeScript) from the identified source file (`PRD.md` or `README.md`).
      If no source file or incomplete information, use interactive prompts to gather missing details.
    - **Interactive Prompts**: When using interactive prompts, ask comprehensive questions such as:
        - "What is the project's name and primary purpose?"
        - "What is the main technology stack (e.g., Node.js, Python, Ruby, Rust)?"
        - "What are 2-3 key features this project will provide?"
        - "Who are the primary users or target audience?"
        - "What external APIs or services will this project integrate with?"
    - **Generate**: Create/update `docs/what-do-we-build.md`, `docs/architecture.md`
      (ensuring it includes a 'Technology Stack' section), and `docs/blueprint.md`
      based on the gathered information using the appropriate templates:
      - What We Build:
      - Architecture:
      - Blueprint:

3. **Setup Project `bin/` Scripts from Binstubs**:
    - **Create Project `bin/` Directory**:
        - If it doesn't already exist, create a `bin/` directory at the project root: `mkdir bin`.
    - **Create Standard Binstubs**:
        - Create the following standard scripts in `bin/` by copying from `dev-tools/exe-old/_binstubs/`:
          - `test` - Run project tests (copy from `dev-tools/exe-old/_binstubs/test`)
          - `lint` - Run project linting (copy from `dev-tools/exe-old/_binstubs/lint`)
          - `build` - Build project artifacts (copy from `dev-tools/exe-old/_binstubs/build`)
          - `run` - Run the application (copy from `dev-tools/exe-old/_binstubs/run`)
          - `tn` - Get next task ID (copy from `dev-tools/exe-old/_binstubs/tn`)
          - `tr` - List recent tasks (copy from `dev-tools/exe-old/_binstubs/tr`)
          - `tree` - Show project structure (copy from `dev-tools/exe-old/_binstubs/tree`)
        - Skip any that already exist to avoid overwriting
    - **Make Scripts Executable**:
        - For all scripts newly created in `bin/`, make them executable: `chmod +x bin/*`.
    - **Guidance on Binstubs**:
        - Scripts like `bin/test`, `bin/lint`, `bin/build`, and `bin/run` are general placeholders that need to be tailored with project-specific commands based on the technology stack.
        - Scripts like `bin/tn`, `bin/tr`, and `bin/tree` should work if the underlying Ruby tools are present.

4. **Setup v.0.0.0 Bootstrap Release Tracking**:
    - **Create v.0.0.0 Structure**: Create the v.0.0.0 bootstrap structure in `dev-taskflow/current/v.0.0.0-bootstrap/` using the bootstrap release template.
    - **Customize Template Tasks**: Replace template placeholders in copied task files:
        - Replace `TEMPLATE-task.X` IDs with actual task IDs using `bin/tnid v.0.0.0` for each task.
        - Replace `[PLACEHOLDER]` values in the release overview file with actual project information.
        - Update task dependencies to use the actual generated task IDs.
        - Remove template notes sections from all copied files.
    - **Mark Completed Tasks**: Update the status of tasks that were already completed during initialization:
        - Mark the dev-taskflow structure setup task as `done` if directories were created.
        - Mark the core documentation task as `in-progress` or `done` based on completion level.
        - Leave PRD completion and roadmap creation tasks as `pending` for user completion.
    - **Update Release Status**: Set the v.0.0.0 release overview status to `in-progress` and add the current date as the start date.

5. **Review and Update Project Source Documentation**:
    - Review the information extracted or gathered through interactive prompts in Step 2.
    - Identify the primary source document (`PRD.md` or `README.md`) determined in Step 2.
    - Update the primary source document with the gathered project information (name, purpose, technology stack, key features, etc.).
    - For any information that was not fully gathered or requires further detail, add clear notes or placeholders within the document indicating where more information is needed.
    - Ensure the updated document aligns with the structure of the relevant template (`dev-handbook/templates/project-docs/prd.template.md` or README.md template) if templates were used to initially populate the file.

6. **Provide Next Steps Guidance**:
    - **Display v.0.0.0 Tasks**: List the created v.0.0.0 tasks and their current status, explaining what remains to be completed.
    - **PRD Completion Guidance**: Provide clear instructions for completing the PRD using the generated task, including the user verification step.
    - **Roadmap Creation Guidance**: Explain the roadmap creation process and how it integrates with the v.0.0.0 release completion.
    - **Release Management Overview**: Briefly explain how to use `bin/tn` and `bin/tr` commands to track progress and manage the v.0.0.0 release.
    - **Transition to v.0.1.0**: Explain that once v.0.0.0 is complete and archived, the project will be ready for v.0.1.0 foundation planning using the draft-release workflow.

## Prerequisites

- Project root directory must be accessible with write permissions.
- Optional: An existing `PRD.md` (within `dev-taskflow`) or `README.md` (at project root) can provide information for extraction.
- Optional: Git repository initialized (the workflow instruction can add to `.gitignore`).

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Assess existing project structure and documentation
- [ ] Determine which templates to use based on project type
- [ ] Plan directory structure creation strategy

### Execution Steps

- [ ] Create dev-taskflow directory structure and verify submodules
- [ ] Generate core documentation from embedded templates
- [ ] Setup bin/ scripts with appropriate stubs
- [ ] Initialize v.0.0.0 bootstrap release tracking
- [ ] Review and update source documentation

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

### docs/what-do-we-build.md

The workflow instruction generates this file with:

- Project overview and goals
- Key features and capabilities
- Core design principles
- Target use cases

The generated file includes sections for project overview, key features, design principles, and target use cases using the vision template.

### docs/architecture.md

The workflow instruction analyzes the project structure and gathered info to generate:

- High-level architecture overview
- **Technology Stack** (Primary languages, frameworks)
- Component relationships
- Data flow diagrams (if inferrable)
- Extension points

The generated file includes sections for technology stack, system architecture, command-line tools, and development patterns using the architecture template.

### docs/blueprint.md

The workflow instruction generates this file, which serves as a quick reference for project structure
and key operational guidelines for an AI agent. It includes sections for read-only and ignored paths
to guide agent behavior.

The generated file includes sections for project organization, technology stack, read-only paths, and ignored paths using the blueprint template.

## Success Criteria

1. **Directory Structure**:
   - `dev-handbook`, `dev-taskflow` directories present with standard structure.
   - Proper permissions set.
   - Git integration configured (`.gitignore` updated).

2. **Core Documentation**:
   - `docs/what-do-we-build.md` created with clear project vision using the template structure.
   - `docs/architecture.md` reflects actual project structure and includes the primary
     technology stack with command-line tools documentation.
   - `docs/blueprint.md` generated with sections for "Read-Only Paths" (including a
     placeholder for project-specific rules) and "Ignored Paths" (pre-populated with defaults like
     `dev-taskflow/done/**/*` and common examples).
   - Documentation is concise yet complete and follows established templates.

3. **Basic `bin/` Scripts Initialized**:
   - The project's `bin/` directory exists.
   - Binstubs from `dev-tools/exe-old/_binstubs/` (like `test`, `lint`, `build`, `run`, `tn`, `tr`,
     `tree`) have been copied to the project's `bin/` directory if they didn't already exist.
   - Copied scripts in `bin/` are executable.
   - User is aware that some `bin/` scripts (`test`, `lint`, `build`, `run`) are placeholders
     needing project-specific implementation.

4. **v.0.0.0 Bootstrap Release Tracking**:
   - `dev-taskflow/current/v.0.0.0-bootstrap/` directory exists with customized template structure.
   - v.0.0.0 release overview file contains project-specific information and current status.
   - Template tasks converted to actual tasks with proper IDs and dependencies.
   - Completed initialization steps marked as `done` in corresponding tasks.
   - Remaining tasks (PRD completion, roadmap creation) marked as `pending` for user completion.

5. **Project Context**:
   - Development philosophy established using templates.
   - Technical boundaries defined in generated documentation.
   - Extension points identified and documented.
   - Clear next steps provided for completing v.0.0.0 release and transitioning to v.0.1.0 planning.

## Workflow Instruction Context

Initialize an AI-driven development environment by creating necessary documentation structure
(`dev-handbook`, `dev-taskflow`) and core architectural documents using standardized templates. This command sets up the foundation for effective AI agent collaboration with consistent, well-structured project documentation.

## Behavior

- Preserves existing documentation if found, enhancing it with template structure when needed.
- Extracts project information from `PRD.md` or `README.md` when available, using project templates for missing sections.
- Creates consistent structure for AI-driven development using standardized templates.
- Uses interactive prompts with comprehensive example questions when source documents are unavailable.

## Embedded Templates

### PRD Template

<documents>
<template path="dev-handbook/templates/project-docs/prd.template.md">
# Product Requirements Document (PRD)

## Executive Summary

[Brief overview of the project, its purpose, and key objectives]

## Problem Statement

[Clear description of the problem being solved]

## Target Users

[Primary and secondary user personas]

## Core Features

## Technical Requirements

- **Primary Stack**: [e.g., Ruby on Rails, Node.js, Python/Django]
- **Database**: [e.g., PostgreSQL, MongoDB]
- **External Services**: [APIs, third-party services]
- **Performance Requirements**: [Response times, throughput]

## Success Metrics

- [Metric 1]: [Target value]
- [Metric 2]: [Target value]

## Constraints & Assumptions

- [Constraint 1]
- [Assumption 1]

## Timeline & Milestones

- v0.1.0: [Foundation - Core architecture]
- v0.2.0: [MVP - Basic features]
- v0.3.0: [Beta - Feature complete]
- v1.0.0: [Production ready]
</template>

</documents>

### README Template

<documents>
<template path="dev-handbook/templates/project-docs/README.template.md">
# [Project Name]

[One-line description of the project]

## Overview

[2-3 paragraphs explaining what the project does and why it exists]

## Features

- [Key feature 1]
- [Key feature 2]
- [Key feature 3]

## Technology Stack

- **Language**: [Primary language]
- **Framework**: [Main framework]
- **Database**: [Database system]
- **Testing**: [Test framework]

## Getting Started

### Prerequisites

- [Requirement 1]
- [Requirement 2]

### Installation

```bash
# Clone the repository
git clone [repository-url]
cd [project-name]

# Install dependencies
[package-manager] install

# Setup database
[database-setup-command]
```

### Running the Application

```bash
bin/run
```

### Running Tests

```bash
bin/test
```

## Development

- `bin/lint` - Run linting
- `bin/build` - Build the project
- `bin/test` - Run tests
- `bin/tn` - Get next task
- `bin/tr` - List recent tasks

## Contributing

[Contributing guidelines or link to CONTRIBUTING.md]

## License

[License information]
</template>
</documents>

### What We Build Template

<documents>
<template path="dev-handbook/templates/project-docs/vision.template.md">
# What Do We Build?

## Project Overview

[Project name] is [brief description of what it is and does].

## Core Purpose

[2-3 sentences about the fundamental reason this project exists]

## Key Features

### Feature 1: [Name]

[Description of the feature and its value]

### Feature 2: [Name]

[Description of the feature and its value]

### Feature 3: [Name]

[Description of the feature and its value]

## Design Principles

1. **[Principle 1]**: [Explanation]
2. **[Principle 2]**: [Explanation]
3. **[Principle 3]**: [Explanation]

## Target Use Cases

- **Use Case 1**: [Description]
- **Use Case 2**: [Description]
- **Use Case 3**: [Description]

## Non-Goals

- [What this project explicitly does not do]
- [Scope limitation 1]
- [Scope limitation 2]

## Success Criteria

- [Measurable outcome 1]
- [Measurable outcome 2]
- [Measurable outcome 3]
</template>

</documents>

### Architecture Template

<documents>
<template path="dev-handbook/templates/project-docs/architecture.template.md">
# Architecture

## Technology Stack

### Core Technologies

- **Primary Language**: [e.g., Ruby 3.2]
- **Framework**: [e.g., Rails 7.1]
- **Database**: [e.g., PostgreSQL 15]
- **Testing**: [e.g., RSpec, Jest]

### Supporting Tools

- **Linting**: [e.g., RuboCop, ESLint]
- **CI/CD**: [e.g., GitHub Actions]
- **Containerization**: [e.g., Docker]

## System Architecture

### High-Level Overview

[ASCII diagram or description of major components]

### Components

#### [Component 1]

- **Purpose**: [What it does]
- **Technology**: [Specific tech used]
- **Interfaces**: [How it connects to other components]

#### [Component 2]

- **Purpose**: [What it does]
- **Technology**: [Specific tech used]
- **Interfaces**: [How it connects to other components]

## Data Flow

1. [Step 1 in typical data flow]
2. [Step 2 in typical data flow]
3. [Step 3 in typical data flow]

## Command-line Tools (bin/)

### Core Development Commands

- `bin/test` - Runs the test suite
  - Example: `rspec` for Ruby, `npm test` for Node.js
- `bin/lint` - Runs code quality checks
  - Example: `rubocop` for Ruby, `eslint` for JavaScript
- `bin/build` - Builds the project
  - Example: `bundle install`, `npm run build`
- `bin/run` - Starts the application
  - Example: `rails server`, `npm start`

### Task Management Commands

- `bin/tn` - Shows next task to work on
- `bin/tr` - Lists recent tasks
- `bin/tree` - Shows project structure

## Development Patterns

### Code Organization

### Testing Strategy

- Unit tests for [what]
- Integration tests for [what]
- End-to-end tests for [what]

### Error Handling

- [Approach to error handling]
- [Logging strategy]

## Security Considerations

- [Security measure 1]
- [Security measure 2]
- [Security measure 3]

## Performance Considerations

- [Performance consideration 1]
- [Performance consideration 2]
- [Performance consideration 3]
</template>

</documents>

### Blueprint Template

<documents>
<template path="dev-handbook/templates/project-docs/blueprint.template.md">
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
├── dev-handbook/         # Development documentation (submodule)
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
</template>

</documents>

### Binstub Templates

**Note**: Binstub templates are sourced from `dev-tools/exe-old/_binstubs/` directory.

#### bin/test

<documents>
<template path="dev-tools/exe-old/_binstubs/test">
#!/usr/bin/env bash
# Run project tests

# TODO: Replace with project-specific test command

# Examples

# - Ruby: bundle exec rspec

# - Node.js: npm test

# - Python: pytest

# - Rust: cargo test

echo "Error: bin/test not configured for this project"
echo "Please update this script with your project's test command"
exit 1
</template>
</documents>

#### bin/lint

<documents>
<template path="dev-tools/exe-old/_binstubs/lint">
#!/usr/bin/env bash
# Run project linting

# TODO: Replace with project-specific lint command

# Examples

# - Ruby: bundle exec rubocop

# - Node.js: npm run lint

# - Python: flake8 . && black --check

# - Rust: cargo clippy

echo "Error: bin/lint not configured for this project"
echo "Please update this script with your project's lint command"
exit 1
</template>
</documents>

#### bin/build

<documents>
<template path="dev-tools/exe-old/_binstubs/build">
#!/usr/bin/env bash
# Build project artifacts

# TODO: Replace with project-specific build command

# Examples

# - Ruby: bundle install

# - Node.js: npm install && npm run build

# - Python: pip install -r requirements.txt

# - Rust: cargo build --release

echo "Error: bin/build not configured for this project"
echo "Please update this script with your project's build command"
exit 1
</template>
</documents>

#### bin/run

<documents>
<template path="dev-tools/exe-old/_binstubs/run">
#!/usr/bin/env bash
# Run the application

# TODO: Replace with project-specific run command

# Examples

# - Ruby: bundle exec rails server

# - Node.js: npm start

# - Python: python app.py

# - Rust: cargo run

echo "Error: bin/run not configured for this project"
echo "Please update this script with your project's run command"
exit 1
</template>
</documents>

#### bin/tn

<documents>
<template path="dev-tools/exe-old/_binstubs/tn">
#!/usr/bin/env bash
# Get next task ID

ruby dev-tools/exe-old/tn.rb "$@"
</template>
</documents>

#### bin/tr

<documents>
<template path="dev-tools/exe-old/_binstubs/tr">
#!/usr/bin/env bash
# List recent tasks

ruby dev-tools/exe-old/tr.rb "$@"
</template>
</documents>

#### bin/tree

<documents>
<template path="dev-tools/exe-old/_binstubs/tree">
#!/usr/bin/env bash
# Show project structure

tree -I 'node_modules|vendor|.git|coverage|tmp|log' "$@"
</template>
</documents>

### v.0.0.0 Release Templates

#### Release Overview Template

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/release-overview.template.md">
---
status: in-progress
start_date: YYYY-MM-DD
end_date:
codename: bootstrap
---

# v.0.0.0 Bootstrap

## Overview

The v.0.0.0 Bootstrap release establishes the foundational project structure and documentation required for AI-assisted development workflow. This release focuses on setting up the development environment, creating core documentation, and establishing the project management framework.

## Goals

1. **Project Structure**: Establish dev-taskflow directory structure and verify submodules
2. **Core Documentation**: Create what-do-we-build.md, architecture.md, and blueprint.md files
3. **Development Tools**: Set up bin/ scripts for common development tasks
4. **Project Definition**: Complete PRD.md with comprehensive project requirements
5. **Roadmap Creation**: Establish initial project roadmap through v1.0.0

## Key Deliverables

- ✅ dev-taskflow directory structure (backlog/, current/, done/)
- ✅ Core documentation files created from templates
- ✅ bin/ scripts initialized (test, lint, build, run, tn, tr, tree)
- ⏳ PRD.md completed with all project requirements
- ⏳ Initial roadmap defined through v1.0.0

## Success Criteria

- [ ] All core directories and files are created
- [ ] PRD clearly defines project goals and requirements
- [ ] Architecture documentation reflects chosen technology stack
- [ ] Blueprint provides clear guidance for AI agents
- [ ] Roadmap outlines path to v1.0.0
- [ ] All bin/ scripts are executable and documented

## Timeline

- Start: YYYY-MM-DD
- Target: 1-2 days for structure setup
- PRD completion: Depends on project complexity
</template>

</documents>

#### Task Templates

##### v.0.0.0+task.1: Setup Structure

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/01-setup-structure.task.template.md">
---
id: v.0.0.0+task.1
status: done
priority: high
estimate: 1h
dependencies: []
---

# Setup dev-taskflow Structure

## Objective

Create the foundational directory structure for task management and project documentation.

## Scope of Work

- Create dev-taskflow/ directory with subdirectories
- Verify dev-handbook and dev-tools submodules are present
- Set up proper Git configuration
- Create initial .gitignore entries

### Deliverables

#### Create

- dev-taskflow/backlog/
- dev-taskflow/current/
- dev-taskflow/done/

## Implementation

### Execution Steps

- [x] Create dev-taskflow directory structure
- [x] Verify dev-handbook and dev-tools submodules
- [x] Add directories to Git
- [x] Update .gitignore if needed

## Acceptance Criteria

- [x] All directories exist with proper permissions
- [x] Git recognizes the new structure
- [x] .keep files prevent empty directory removal
</template>

</documents>

##### v.0.0.0+task.2: Create Core Docs

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/02-complete-documentation.task.template.md">
---
id: v.0.0.0+task.2
status: in-progress
priority: high
estimate: 2h
dependencies: [v.0.0.0+task.1]
---

# Create Core Documentation

## Objective

Generate the three foundational documentation files that guide project development and AI agent interaction.

## Scope of Work

- Extract or gather project information
- Create what-do-we-build.md
- Create architecture.md with technology stack
- Create blueprint.md with project structure

### Deliverables

#### Create

- docs/what-do-we-build.md
- docs/architecture.md
- docs/blueprint.md

## Implementation

### Planning Steps

- [x] Identify source documentation (PRD.md or README.md)
- [x] Extract project information or prepare prompts
- [ ] Gather technology stack details

### Execution Steps

- [ ] Generate what-do-we-build.md from template
- [ ] Generate architecture.md with tech stack
- [ ] Generate blueprint.md with structure rules
- [ ] Review and refine generated content

## Acceptance Criteria

- [ ] All three core files exist
- [ ] Technology stack is documented
- [ ] Project vision is clear
- [ ] AI agent guidelines are included
</template>

</documents>

##### v.0.0.0+task.3: Complete PRD

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/03-complete-prd.task.template.md">
---
id: v.0.0.0+task.3
status: pending
priority: high
estimate: 3h
dependencies: [v.0.0.0+task.2]
---

# Complete Product Requirements Document

## Objective

Finalize the PRD.md with comprehensive project requirements, ensuring all sections are complete and reviewed by stakeholders.

## Scope of Work

- Review and enhance PRD structure
- Fill in all placeholder sections
- Add detailed feature descriptions
- Define success metrics
- Get stakeholder approval

### Deliverables

#### Modify

- PRD.md (complete all sections)

## Implementation

### Planning Steps

- [ ] Review current PRD content
- [ ] Identify missing sections
- [ ] Gather additional requirements

### Execution Steps

- [ ] Complete executive summary
- [ ] Refine problem statement
- [ ] Detail all core features
- [ ] Specify technical requirements
- [ ] Define measurable success metrics
- [ ] Add constraints and assumptions
- [ ] Create initial timeline
- [ ] Review with stakeholders

## Acceptance Criteria

- [ ] All PRD sections are complete
- [ ] No placeholders remain
- [ ] Technical requirements are specific
- [ ] Success metrics are measurable
- [ ] Stakeholder approval obtained
</template>

</documents>

##### v.0.0.0+task.4: Create Roadmap

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/04-create-roadmap.task.template.md">---
id: TEMPLATE-task.4 # TEMPLATE - Replace with actual task ID using bin/tnid
status: pending
priority: high
estimate: 2h
dependencies: [TEMPLATE-task.3]
---

# TEMPLATE: Create Project Roadmap

**TEMPLATE NOTE:** This is a template task file. When copying to an actual project:

1. Replace "TEMPLATE" with actual project-specific task ID (use `bin/tnid v.0.0.0`)
2. Replace dependency IDs with actual task IDs
3. Remove this template note section
4. Customize content for specific project needs

## Objective

Create a comprehensive project roadmap that outlines planned releases, major milestones, and strategic development phases. The roadmap establishes a structured approach to release management starting with v.0.1.0 foundation setup and extending to future major releases.

## Scope of Work

### Deliverables

#### Create

- dev-taskflow/roadmap.md (complete project roadmap)

#### Modify

- None

#### Delete

- None

## Phases

1. Release Planning - Define major release milestones and scope
2. Timeline Development - Establish realistic development timelines
3. Dependency Mapping - Identify cross-release dependencies and prerequisites
4. Roadmap Documentation - Create structured roadmap document
5. Stakeholder Review - Validate roadmap with project stakeholders

## Implementation Plan

### Planning Steps

- [ ] Review completed PRD for feature scope and priority insights
  > TEST: PRD Review for Roadmap Planning
  > Type: Pre-condition Check
  > Assert: PRD is complete and contains feature priorities
  > Command: test -f PRD.md && grep -q "Priority\|Milestone\|Phase" PRD.md
- [ ] Analyze project complexity to determine appropriate release cadence
- [ ] Research roadmap templates and industry best practices
- [ ] Plan v.0.1.0 foundation release scope based on PRD requirements

### Execution Steps

- [ ] Create roadmap.md with standard structure and metadata
  > TEST: Roadmap File Creation
  > Type: Action Validation
  > Assert: roadmap.md exists with proper template structure
  > Command: test -f dev-taskflow/roadmap.md && grep -q "# Project Roadmap\|## Release Overview" dev-taskflow/roadmap.md
- [ ] Define v.0.1.0 foundation release with core infrastructure setup
  > TEST: v.0.1.0 Release Defined
  > Type: Action Validation
  > Assert: roadmap contains detailed v.0.1.0 release specification
  > Command: grep -q "## v\.0\.1\.0.*Foundation\|Infrastructure Setup" dev-taskflow/roadmap.md
- [ ] Plan v.0.2.0 and v.0.3.0 releases with major feature milestones
  > TEST: Future Releases Planned
  > Type: Action Validation
  > Assert: roadmap includes v.0.2.0 and v.0.3.0 planning
  > Command: grep -q "## v\.0\.2\.0\|## v\.0\.3\.0" dev-taskflow/roadmap.md
- [ ] Document release dependencies, prerequisites, and success criteria
  > TEST: Release Dependencies Documented
  > Type: Action Validation
  > Assert: roadmap includes dependencies and success criteria for each release
  > Command: grep -q "Dependencies\|Prerequisites\|Success Criteria" dev-taskflow/roadmap.md
- [ ] Include timeline estimates and target delivery windows
  > TEST: Timeline Information Complete
  > Type: Action Validation
  > Assert: roadmap contains realistic timeline estimates
  > Command: grep -q "Target Date\|Timeline\|Estimated Duration" dev-taskflow/roadmap.md
- [ ] Add release management processes and guidelines
  > TEST: Process Documentation Complete
  > Type: Action Validation
  > Assert: roadmap includes release management processes
  > Command: grep -q "Release Process\|Management\|Guidelines" dev-taskflow/roadmap.md
- [ ] Review roadmap with stakeholders for feasibility and alignment
  > VERIFY: Stakeholder Roadmap Review
  > Type: User Feedback
  > Prompt: Please review the created roadmap.md. Does it provide a realistic and achievable development plan? Are the release scopes appropriate and the timelines feasible? Are there any missing milestones or unrealistic expectations?
  > Options: (Approved / Needs Timeline Adjustment / Scope Changes Required / Major Revision Needed)
- [ ] Finalize roadmap with approval markers and version information
  > TEST: Roadmap Finalization
  > Type: Post-condition Check
  > Assert: roadmap is complete with approval and version tracking
  > Command: grep -q "Version\|Last Updated\|Status.*Approved" dev-taskflow/roadmap.md

## Acceptance Criteria

- [ ] AC 1: roadmap.md exists with comprehensive project development plan
- [ ] AC 2: v.0.1.0 foundation release clearly defined with infrastructure focus
- [ ] AC 3: Future releases (v.0.2.0, v.0.3.0+) planned with feature milestones
- [ ] AC 4: Release dependencies and prerequisites documented
- [ ] AC 5: Realistic timeline estimates provided for all planned releases
- [ ] AC 6: Release management processes and guidelines included
- [ ] AC 7: Stakeholder review completed with feedback incorporated
- [ ] AC 8: All automated tests in Implementation Plan pass

## Out of Scope

- ❌ Detailed task breakdown for future releases (done during draft-release workflow)
- ❌ Resource allocation and team assignment planning
- ❌ Budget and cost estimation for releases
- ❌ Risk assessment and mitigation strategies (covered in individual releases)
- ❌ Market timing and external dependency coordination

## References

- dev-taskflow/roadmap.md (target file)
- PRD.md (requirements source)
- dev-handbook/templates/release-planning/ (roadmap templates)
- dev-handbook/workflow-instructions/draft-release.wf.md
- dev-handbook/guides/project-management.g.md
- dev-handbook/guides/release-codenames.g.md
</template>

</documents>

## Common Patterns

### New Project Initialization

Set up complete project structure and documentation for greenfield projects.

### Legacy Project Modernization

Add AI-assisted development structure to existing projects without proper organization.

### Documentation Standardization

Apply consistent documentation templates across multiple projects in an organization.

### Bootstrap Release Management

Establish v.0.0.0 release tracking to manage initial project setup tasks.

## Notes

- The workflow preserves existing documentation if found, enhancing it with template structure
- Uses standardized templates to ensure consistent, comprehensive documentation across projects
- Provides interactive prompts with example questions when source documents are unavailable
- Creates idempotent workflow that can be safely rerun without overwriting customizations
