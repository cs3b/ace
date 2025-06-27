# Initialize Project Structure Workflow Instruction

## Goal

Initialize the `dev-handbook` and `dev-taskflow` directory structures and create core documentation files
(`what-do-we-build.md`, `architecture.md`, `blueprint.md` in docs/ folder ) to establish the foundation for an
AI-assisted development workflow in a new or existing project.

**Idempotency**: This workflow is designed to be idempotent. Rerunning it will skip already completed steps or safely update existing files without overwriting customized content.

## Process Steps

1. **Project Structure Setup**:
    - **Submodule Branch**: Verify the `dev-handbook` submodule is checked out to a branch other than
      `main` or `master`. If it's on `main`/`master`, create and switch to a new branch
      (e.g., `git checkout -b project-specific-docs`) to allow for project-specific tailoring
      without affecting the upstream repository.
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

3. **Install and Customize Configuration Files**:
    - Follow the `dev-handbook/.meta/wfi/install-dotfiles.wf.md` workflow instructions

4. **Setup Project `bin/` Scripts from Binstubs**:
    - **Create Project `bin/` Directory**:
        - If it doesn't already exist, create a `bin/` directory at the project root: `mkdir bin`.
    - **Create Standard Binstubs**:
        - Create the following standard scripts in `bin/` by copying from the binstub templates:
          - `test` - Run project tests (from template)
          - `lint` - Run project linting (from template)
          - `build` - Build project artifacts (from template)
          - `run` - Run the application (from template)
        - Skip any that already exist to avoid overwriting
    - **Make Scripts Executable**:
        - For all scripts newly created in `bin/`, make them executable: `chmod +x bin/*`.
    - **Guidance on Binstubs**:
        - All scripts (`bin/test`, `bin/lint`, `bin/build`, and `bin/run`) are general placeholders that need to be tailored with project-specific commands based on the technology stack.
        - Task management commands (`tn`, `tr`, `tree`) are available through the dev-tools if needed but are not automatically added to project bin/.

4. **Setup v.0.0.0 Bootstrap Release Tracking**:
    - **Create v.0.0.0 Structure**: Create the v.0.0.0 bootstrap structure in `dev-taskflow/current/v.0.0.0-bootstrap/` using the bootstrap release template.
    - **Customize Template Tasks**: Replace template placeholders in copied task files:
        - Use `nav-path task-new` to create actual tasks from templates with proper IDs
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
    - **Release Management Overview**: Briefly explain how to use `task-manager next` and `task-manager recent` commands to track progress and manage the v.0.0.0 release.
    - **Transition to v.0.1.0**: Explain that once v.0.0.0 is complete and archived, the project will be ready for v.0.1.0 foundation planning using the draft-release workflow.

## Prerequisites

- Project root directory must be accessible with write permissions.
- Optional: An existing `PRD.md` (within `dev-taskflow`) or `README.md` (at project root) can provide information for extraction.
- Optional: Git repository initialized (the workflow instruction can add to `.gitignore`).

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`
- Load tools documentation: `docs/tools.md`

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
   - Standard binstub templates (`test`, `lint`, `build`, `run`) have been copied to the project's `bin/` directory if they didn't already exist.
   - Copied scripts in `bin/` are executable.
   - User is aware that all `bin/` scripts are placeholders needing project-specific implementation.

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
<template path="dev-handbook/templates/project-docs/prd.template.md"># Product Requirements Document (PRD) Template

## Project Overview

### Problem Statement
<!-- Describe the core problem this project aims to solve -->

### Proposed Solution
<!-- High-level description of your approach to solving the problem -->

### Success Metrics
<!-- How will you measure success? Include quantifiable goals where possible -->

## Project Details

### Project Name
<!-- The official name of your project -->

### Target Audience
<!-- Who are the primary users/beneficiaries of this project? -->

### Core Value Proposition
<!-- What unique value does this project provide? -->

## Functional Requirements

### Must-Have Features (P0)
<!-- Critical features without which the project cannot succeed -->
- [ ] Feature 1: Description
- [ ] Feature 2: Description

### Should-Have Features (P1)
<!-- Important features that significantly enhance the project -->
- [ ] Feature 1: Description
- [ ] Feature 2: Description

### Could-Have Features (P2)
<!-- Nice-to-have features for future consideration -->
- [ ] Feature 1: Description
- [ ] Feature 2: Description

## Technical Considerations

### Technology Stack
<!-- Preferred programming languages, frameworks, databases, etc. -->
- **Primary Language**:
- **Framework/Runtime**:
- **Database**:
- **Key Libraries**:
- **Deployment**:

### Architecture Requirements
<!-- High-level architectural constraints or preferences -->

### Performance Requirements
<!-- Speed, scalability, and resource constraints -->

### Security Requirements
<!-- Security considerations and compliance needs -->

### Integration Requirements
<!-- External systems or APIs this project needs to work with -->

## User Stories

### Primary User Flows
<!-- Describe the main user journeys through your application -->

#### User Story 1

**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

**Acceptance Criteria:**

- [ ] Criterion 1
- [ ] Criterion 2

#### User Story 2

**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

**Acceptance Criteria:**

- [ ] Criterion 1
- [ ] Criterion 2

## Implementation Timeline

### Phase 1: Foundation (Estimated: X weeks)
<!-- Core functionality and basic features -->

### Phase 2: Enhancement (Estimated: X weeks)
<!-- Additional features and improvements -->

### Phase 3: Polish (Estimated: X weeks)
<!-- Testing, optimization, documentation -->

## Dependencies and Risks

### External Dependencies
<!-- Third-party services, libraries, or resources you depend on -->

### Risk Assessment
<!-- Potential challenges and mitigation strategies -->
| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|-------------------|
| Risk 1 | High/Medium/Low | High/Medium/Low | Strategy description |

## Out of Scope

### Explicitly Excluded Features
<!-- Features that might be expected but are intentionally not included -->

### Future Considerations
<!-- Features or improvements for potential future phases -->

## Approval and Sign-off

### Stakeholders
<!-- List key stakeholders who need to approve this PRD -->

### Approval Status

- [ ] Technical Lead Approval
- [ ] Product Owner Approval
- [ ] Architecture Review Complete
- [ ] Ready for Implementation

---

*This PRD should be reviewed and updated as the project evolves. Version control and change tracking should be maintained for all modifications.*
</template>

</documents>

### README Template

<documents>
<template path="dev-handbook/templates/project-docs/README.template.md"># [Project Name]

## Overview

<!-- Brief description of what this project does and why it's valuable -->

## Features

<!-- Key features and capabilities -->

- Feature 1
- Feature 2
- Feature 3

## Quick Start

### Prerequisites

<!-- List any required dependencies or setup -->

- Prerequisite 1
- Prerequisite 2

### Installation

```bash
# Installation commands
```

### Usage

```bash
# Basic usage examples
```

## Documentation

<!-- Links to additional documentation -->

- [API Documentation](./docs/api.md)
- [User Guide](./docs/user-guide.md)
- [Developer Guide](./docs/developer-guide.md)
- [Architecture](./docs/architecture.md)

## Development

### Setup

```bash
# Development setup commands
```

### Testing

```bash
# Test commands
```

### Building

```bash
# Build commands
```

## Contributing

<!-- Guidelines for contributors -->

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

<!-- License information -->

[License Name] - See [LICENSE](./LICENSE) file for details

## Support

<!-- How to get help -->

- [Issue Tracker](./issues)
- [Documentation](./docs)
- [Community Forum](./discussions)

---

*This project is actively maintained. For the latest updates, see the [CHANGELOG](./CHANGELOG.md).*
</template>
</documents>

### What We Build Template

<documents>
<template path="dev-handbook/templates/project-docs/vision.template.md"># [Project Name]

## What We Build 🔍

<!-- Provide a clear, concise description of what this project does and why it exists -->

[Brief description of the project's core purpose and value proposition]

## ✨ Key Features

<!-- List the main features and capabilities that define this project -->

- **Feature 1**: [Description of what this feature does and why it's valuable]
- **Feature 2**: [Description of what this feature does and why it's valuable]
- **Feature 3**: [Description of what this feature does and why it's valuable]
- **Feature 4**: [Description of what this feature does and why it's valuable]

## Core Design Principles

<!-- Fundamental principles that guide the project's development and design decisions -->

- **[Principle 1]**: [Description of this principle and how it influences the project]
- **[Principle 2]**: [Description of this principle and how it influences the project]
- **[Principle 3]**: [Description of this principle and how it influences the project]
- **[Principle 4]**: [Description of this principle and how it influences the project]

## Target Use Cases

<!-- Describe the primary scenarios and users this project is designed to serve -->

### Primary Use Cases

- **[Use Case 1]**: [Description of who uses this and how]
- **[Use Case 2]**: [Description of who uses this and how]
- **[Use Case 3]**: [Description of who uses this and how]

### Secondary Use Cases

- **[Use Case 4]**: [Description of additional scenarios this project supports]
- **[Use Case 5]**: [Description of additional scenarios this project supports]

## User Personas

<!-- Define the types of users who will interact with this project -->

### Primary Users

**[User Type 1]**: [Description of this user group, their needs, and goals]

- Needs: [What they need from the project]
- Goals: [What they want to achieve]
- Pain Points: [Problems this project solves for them]

**[User Type 2]**: [Description of this user group, their needs, and goals]

- Needs: [What they need from the project]
- Goals: [What they want to achieve]
- Pain Points: [Problems this project solves for them]

### Secondary Users

**[User Type 3]**: [Description of additional user groups]

- Context: [When and why they interact with the project]

## Success Metrics

<!-- Define how success will be measured for this project -->

### Primary Metrics

- **[Metric 1]**: [What it measures and target values]
- **[Metric 2]**: [What it measures and target values]
- **[Metric 3]**: [What it measures and target values]

### Secondary Metrics

- **[Metric 4]**: [What it measures and why it's important]
- **[Metric 5]**: [What it measures and why it's important]

## Technology Philosophy

<!-- Describe the technical approach and philosophy -->

### Core Technology Choices

- **[Technology 1]**: [Why this was chosen and its benefits]
- **[Technology 2]**: [Why this was chosen and its benefits]
- **[Technology 3]**: [Why this was chosen and its benefits]

### Technical Principles

- **[Technical Principle 1]**: [How this guides technical decisions]
- **[Technical Principle 2]**: [How this guides technical decisions]

## Project Boundaries

### What We Build
<!-- Clearly define what is in scope -->
- [Specific capability or feature in scope]
- [Specific capability or feature in scope]
- [Specific capability or feature in scope]

### What We Don't Build
<!-- Clearly define what is explicitly out of scope -->
- [Capability or feature explicitly excluded]
- [Capability or feature explicitly excluded]
- [Capability or feature explicitly excluded]

## Value Proposition

### Problems We Solve
<!-- The specific problems this project addresses -->
1. **[Problem 1]**: [Description of the problem and how the project solves it]
2. **[Problem 2]**: [Description of the problem and how the project solves it]
3. **[Problem 3]**: [Description of the problem and how the project solves it]

### Unique Advantages
<!-- What makes this project different or better than alternatives -->
- **[Advantage 1]**: [What makes this unique and valuable]
- **[Advantage 2]**: [What makes this unique and valuable]
- **[Advantage 3]**: [What makes this unique and valuable]

## Future Vision

### Short-term Goals (3-6 months)

- [Goal 1]: [Description and success criteria]
- [Goal 2]: [Description and success criteria]

### Medium-term Goals (6-12 months)

- [Goal 1]: [Description and success criteria]
- [Goal 2]: [Description and success criteria]

### Long-term Vision (1+ years)

- [Vision element 1]: [Long-term aspiration]
- [Vision element 2]: [Long-term aspiration]

## Dependencies and Ecosystem

### Key Dependencies
<!-- Important external dependencies that enable this project -->
- **[Dependency 1]**: [Why it's needed and how it's used]
- **[Dependency 2]**: [Why it's needed and how it's used]

### Ecosystem Integration
<!-- How this project fits into larger ecosystems or workflows -->
- **[Integration 1]**: [How the project connects with other tools/systems]
- **[Integration 2]**: [How the project connects with other tools/systems]

---

*This document should be updated as the project evolves and new insights are gained about user needs and project direction.*
</template>

</documents>

### Architecture Template

<documents>
<template path="dev-handbook/templates/project-docs/architecture.template.md"># [Project Name] - Architecture

## Overview

<!-- High-level description of the system architecture -->

This document outlines the architectural design and technical implementation details for [Project Name]. It serves as a guide for developers and AI agents working on the project.

## Technology Stack

<!-- List the primary technologies, frameworks, and tools -->

### Core Technologies

- **Primary Language**: [e.g., JavaScript, Python, Rust, Ruby]
- **Runtime/Framework**: [e.g., Node.js, Django, Rails, Actix]
- **Database**: [e.g., PostgreSQL, MySQL, MongoDB, SQLite]
- **Package Manager**: [e.g., npm, pip, cargo, bundler]

### Development Tools

- **Build System**: [e.g., Webpack, Vite, Cargo, Make]
- **Testing Framework**: [e.g., Jest, PyTest, RSpec, Criterion]
- **Linting/Formatting**: [e.g., ESLint/Prettier, Black, RuboCop, rustfmt]
- **Type System**: [e.g., TypeScript, mypy, Sorbet, native]

### Infrastructure & Deployment

- **Containerization**: [e.g., Docker, Podman]
- **Cloud Platform**: [e.g., AWS, GCP, Azure, Heroku]
- **CI/CD**: [e.g., GitHub Actions, GitLab CI, Jenkins]
- **Monitoring**: [e.g., Sentry, DataDog, Prometheus]

## System Architecture

### High-Level Components

<!-- Describe the main components and their relationships -->

```
[Component Diagram - describe or link to actual diagram]

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend/UI   │◄──►│   Backend/API   │◄──►│    Database     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │ External APIs/  │
                       │    Services     │
                       └─────────────────┘
```

### Component Descriptions

#### [Component 1 - e.g., Frontend]

- **Purpose**: [What this component does]
- **Technology**: [Specific tech stack]
- **Key Responsibilities**:
  - Responsibility 1
  - Responsibility 2
- **Interfaces**: [How it communicates with other components]

#### [Component 2 - e.g., Backend API]

- **Purpose**: [What this component does]
- **Technology**: [Specific tech stack]
- **Key Responsibilities**:
  - Responsibility 1
  - Responsibility 2
- **Interfaces**: [How it communicates with other components]

#### [Component 3 - e.g., Database]

- **Purpose**: [What this component does]
- **Technology**: [Specific tech stack]
- **Schema**: [Brief description or link to schema docs]

## Data Flow

### Request Processing Flow

<!-- Describe how data flows through the system -->

1. **Input**: [How requests/data enters the system]
2. **Processing**: [How data is processed]
3. **Storage**: [How data is persisted]
4. **Output**: [How results are returned]

### Data Models

<!-- Key data structures and relationships -->

#### Core Entities

- **[Entity 1]**: [Description and key attributes]
- **[Entity 2]**: [Description and key attributes]
- **[Entity 3]**: [Description and key attributes]

## Command-line Tools (bin/)

The `bin/` directory provides convenient wrappers for project automation and development tasks.

### Development Scripts

- **bin/run** — Start the development server or main application
- **bin/build** — Build the project for production deployment
- **bin/test** — Run the complete test suite
- **bin/lint** — Run code quality checks and linting

### Project Management Scripts

- **bin/tn** — Find the next actionable task in the current release
- **bin/tr** — Summarize recently updated or completed tasks
- **bin/gc** — Commit changes across the project and submodules
- **bin/gl** — Show recent git commits across all repositories

### Utility Scripts

- **bin/tree** — Display the project directory structure
- **bin/rc** — Get current release path and version information

<!-- Add project-specific scripts -->

### Custom Scripts

- **bin/[custom-script]** — [Description of what this script does]

## File Organization

### Source Code Structure

```
src/
├── [main-module]/          # Core application logic
├── [feature-module]/       # Feature-specific code
├── utils/                  # Shared utilities
├── config/                 # Configuration management
├── types/                  # Type definitions (if applicable)
└── [other-modules]/        # Additional modules
```

### Configuration Files

- **[config-file]**: [Purpose and key settings]
- **[env-file]**: [Environment-specific configurations]
- **[build-config]**: [Build and deployment settings]

## Development Patterns

### Code Organization Principles

<!-- Describe key patterns and conventions -->

- **[Pattern 1]**: [Description and usage]
- **[Pattern 2]**: [Description and usage]
- **[Pattern 3]**: [Description and usage]

### Error Handling

<!-- How errors are handled throughout the system -->

- **Error Types**: [Different categories of errors]
- **Error Propagation**: [How errors flow through the system]
- **Logging Strategy**: [How errors are logged and monitored]

## Security Considerations

### Authentication & Authorization

<!-- Security measures implemented -->

- **Authentication Method**: [How users are authenticated]
- **Authorization Model**: [How permissions are managed]
- **Session Management**: [How sessions are handled]

### Data Protection

- **Encryption**: [What data is encrypted and how]
- **Input Validation**: [How inputs are validated]
- **Security Headers**: [Security headers implemented]

## Performance Considerations

### Optimization Strategies

<!-- Performance optimization approaches -->

- **Caching**: [Caching strategies used]
- **Database Optimization**: [Query optimization, indexing]
- **Asset Optimization**: [How static assets are optimized]

### Monitoring & Metrics

- **Key Metrics**: [Important performance indicators]
- **Alerting**: [When and how alerts are triggered]
- **Profiling**: [Tools and strategies for performance profiling]

## Deployment Architecture

### Environment Strategy

<!-- Different deployment environments -->

- **Development**: [Local development setup]
- **Staging**: [Staging environment configuration]
- **Production**: [Production environment details]

### Deployment Process

1. **Build**: [How the application is built]
2. **Test**: [Testing in deployment pipeline]
3. **Deploy**: [Deployment steps and strategies]
4. **Monitor**: [Post-deployment monitoring]

## Extension Points

### Adding New Features

<!-- How to extend the system -->

- **[Extension Point 1]**: [How to add functionality here]
- **[Extension Point 2]**: [How to add functionality here]

### Plugin Architecture

<!-- If applicable, describe plugin/module system -->

- **Plugin Interface**: [How plugins integrate]
- **Plugin Discovery**: [How plugins are found and loaded]

## Dependencies

### Runtime Dependencies

<!-- Key libraries and their purposes -->

- **[Library 1]** (v[version]): [Purpose and why it was chosen]
- **[Library 2]** (v[version]): [Purpose and why it was chosen]

### Development Dependencies

- **[Dev Tool 1]**: [Purpose in development workflow]
- **[Dev Tool 2]**: [Purpose in development workflow]

## Decision Records

### Significant Architectural Decisions

<!-- Link to or summarize key architectural decisions -->

- **[Decision 1]**: [Brief summary and rationale]
- **[Decision 2]**: [Brief summary and rationale]

For detailed decision records, see [docs/decisions/](docs/decisions/).

## Troubleshooting

### Common Issues

<!-- Common problems and their solutions -->

**Issue**: [Problem description]

- **Symptoms**: [How to identify this issue]
- **Solution**: [How to resolve it]

**Issue**: [Problem description]

- **Symptoms**: [How to identify this issue]
- **Solution**: [How to resolve it]

## Future Considerations

### Planned Improvements

<!-- Architectural improvements planned for future releases -->

- **[Improvement 1]**: [Description and timeline]
- **[Improvement 2]**: [Description and timeline]

### Scalability Roadmap

- **Short-term**: [Immediate scalability plans]
- **Medium-term**: [6-12 month scalability goals]
- **Long-term**: [Future architectural evolution]

---

*This architecture document should be updated when significant changes are made to the system design or technology stack.*
</template>

</documents>

### Blueprint Template

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
bin/tree
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

- **New Feature**: Use `bin/tn` to find next task, follow task workflow
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

### Binstub Templates

#### bin/test

<documents>
<template path="dev-handbook/templates/binstubs/test.template.md">
#!/bin/sh
# Placeholder for project testing command.
# This script should be located in the project's `bin/` directory.
#
# The `initialize-project-structure.md` workflow, or a developer,
# should update this script to execute the project's actual test command.
#
# Examples:
# - Node.js: npm test
# - Node.js (Yarn): yarn test
# - Node.js (pnpm): pnpm test
# - Bun: bun test
# - Ruby (RSpec): bundle exec rspec
# - Ruby (Minitest): bundle exec rake test
# - Python (pytest): pytest
# - Python (unittest): python -m unittest discover
# - Rust: cargo test
# - Go: go test ./...
# - Java (Maven): mvn test
# - Java (Gradle): ./gradlew test
#
# Refer to `dev-handbook/guides/testing/` for
# technology-specific testing guidance.

set -e
cd "$(dirname "$0")"/.. # Ensure execution from project root

echo "INFO: Running 'bin/test' from project root: $(pwd)"
echo "INFO: This is a placeholder 'bin/test' script."
echo "INFO: Please update it to run your project's specific test suite."
echo "INFO: For example: 'npm test', 'bundle exec rspec', 'cargo test', etc."

# Add your project's actual test command here:
# Example: npm test -- "$@"
# Example: bundle exec rspec "$@"

echo "INFO: No test command configured in bin/test."
exit 0 # Succeed by default for placeholder, or change to 'exit 1' to indicate not configured.
</template>
</documents>

#### bin/lint

<documents>
<template path="dev-handbook/templates/binstubs/lint.template.md">
#!/bin/sh
# Placeholder for project linting script (bin/lint)
# This script should be adapted during project initialization or by developers
# to execute the project's specific linting command(s).
#
# This script might call multiple linters (e.g., code linters, documentation linters).
#
# Examples:
# - Node.js: npm run lint (which might run ESLint, Prettier, etc.)
# - Bun: bun run lint
# - Ruby/RuboCop: bundle exec rubocop
# - Python/Ruff: ruff check .
# - Python/Flake8: flake8
# - Rust: cargo clippy && cargo fmt -- --check
# - Go: golangci-lint run
# - Markdown links: ruby tools/lint-md-links.rb (example)
# - Makefile: make lint

set -e
cd "$(dirname "$0")"/.. # Ensure execution from project root

echo "INFO: Running 'bin/lint' from project root: $(pwd)"
echo "INFO: This is a placeholder 'bin/lint' script."
echo "INFO: Please update it to run your project's specific linting command(s)."
echo "INFO: For example: 'npm run lint', 'bundle exec rubocop', 'ruff check .', etc."
echo "INFO: This script can also call tools like linters for documentation (e.g., Markdown)."

# Add your project's lint command(s) here. For example:
# npm run lint -- "$@"
# bundle exec rubocop "$@"
# ruff check . "$@"

# Example: Call the Markdown link linter if it exists
# TOOLKIT_MD_LINT="dev-handbook/tools/lint-md-links.rb"
# if [ -f "$TOOLKIT_MD_LINT" ]; then
#   echo "Running Markdown link linter..."
#   ruby "$TOOLKIT_MD_LINT"
# else
#   echo "INFO: Toolkit Markdown linter not found at $TOOLKIT_MD_LINT"
# fi


echo "(Placeholder: No lint command executed)"
exit 0
</template>
</documents>

#### bin/build

<documents>
<template path="dev-handbook/templates/binstubs/build.template.md">
#!/bin/sh
# Placeholder for project build script (bin/build)
# This script should be adapted during project initialization or by developers
# to execute the project's specific build command, if applicable.
#
# Many interpreted language projects (e.g., Python, Ruby) may not have a separate "build" step
# unless they are producing distributable packages or assets.
#
# Examples:
# - Node.js/TypeScript: npm run build (which might run tsc)
# - Bun: bun run build
# - Rust: cargo build
# - Go: go build ./...
# - Java (Maven): mvn package
# - Java (Gradle): ./gradlew build
# - C/C++/Makefile: make
#
# If your project doesn't have a build step, this script can do nothing or be removed.

set -e
cd "$(dirname "$0")"/.. # Ensure execution from project root

echo "INFO: Running 'bin/build' from project root: $(pwd)"
echo "INFO: This is a placeholder 'bin/build' script."
echo "INFO: Please update it to run your project's specific build command, if applicable."
echo "INFO: For example: 'npm run build', 'cargo build', 'mvn package', etc."
echo "INFO: If your project doesn't have a dedicated build step, this script can do nothing or be removed."

# Add your project's build command here. For example:
# npm run build -- "$@"
# cargo build --release -- "$@"

echo "(Placeholder: No build command executed)"
exit 0
</template>
</documents>

#### bin/run

<documents>
<template path="dev-handbook/templates/binstubs/run.template.md">
#!/bin/sh
# Placeholder for project run script (bin/run)
# This script should be adapted during project initialization or by developers
# to execute the project's main application or development server.
#
# Examples:
# - Node.js: npm run start (or npm run dev)
# - Bun: bun run start (or bun run dev, or bun run <entry-file>)
# - Ruby/Rails: bundle exec rails server
# - Python/Django: python manage.py runserver
# - Python/Flask: flask run
# - Rust: cargo run
# - Go: go run main.go (or go run ./cmd/<command>)
# - Makefile: make run

set -e
cd "$(dirname "$0")"/.. # Ensure execution from project root

echo "INFO: Running 'bin/run' from project root: $(pwd)"
echo "INFO: This is a placeholder 'bin/run' script."
echo "INFO: Please update it to run your project's main application or development server."
echo "INFO: For example: 'npm run dev', 'cargo run', 'python app.py', etc."

# Add your project's run command here. For example:
# npm run dev -- "$@"
# cargo run -- "$@"
# python app.py "$@"

echo "(Placeholder: No run command executed)"
exit 0
</template>
</documents>

### v.0.0.0 Release Templates

#### Release Overview Template

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/release-overview.template.md"># v.0.0.0 Bootstrap Release

## Release Overview

This is the initial bootstrap release to establish the project foundation and core structure.

## Release Information

- **Type**: Bootstrap/Foundation
- **Start Date**: YYYY-MM-DD
- **Target Date**: YYYY-MM-DD
- **Status**: Planning

## Bootstrap Goals

### Primary Objectives

- [ ] Establish project structure and organization
- [ ] Create foundational documentation (PRD, Architecture, Blueprint)
- [ ] Set up development workflows and tooling
- [ ] Define project vision and roadmap

### Success Criteria

- [ ] All core documentation created and reviewed
- [ ] Development environment fully configured
- [ ] Project structure aligns with architectural decisions
- [ ] Next release (v.0.1.0) planning initiated

## Foundation Tasks

### Documentation & Structure

1. **Project Documentation**
   - [ ] Complete Product Requirements Document (PRD)
   - [ ] Finalize architecture documentation
   - [ ] Create comprehensive project blueprint
   - [ ] Document project vision and goals

2. **Development Setup**
   - [ ] Configure development environment
   - [ ] Set up testing framework
   - [ ] Establish code quality standards
   - [ ] Create development guides

3. **Project Organization**
   - [ ] Organize task management structure
   - [ ] Set up release management process
   - [ ] Create templates and workflows
   - [ ] Define contribution guidelines

### Quality Assurance

- [ ] All documentation reviewed and approved
- [ ] Project structure validated
- [ ] Development setup tested
- [ ] Templates and workflows validated

## Bootstrap Checklist

### Pre-Release

- [ ] All foundation tasks completed
- [ ] Documentation quality review passed
- [ ] Project structure validated
- [ ] Development environment tested

### Release Preparation

- [ ] Release notes drafted
- [ ] Stakeholder review completed
- [ ] Documentation published
- [ ] Next release planning initiated

### Post-Release

- [ ] Release archived and documented
- [ ] Lessons learned captured
- [ ] Process improvements identified
- [ ] Team feedback collected

## Notes

This bootstrap release focuses on establishing a solid foundation for the project. Success is measured by the completeness and quality of the foundational elements rather than feature delivery.

## Next Steps

Upon completion of v.0.0.0, the project will be ready for:

- Feature development in v.0.1.0
- Iterative development cycles
- Continuous improvement processes
- Stakeholder engagement and feedback
</template>

</documents>

#### Task Templates

##### v.0.0.0+task.1: Setup Structure

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/01-setup-structure.task.template.md">---
id: TEMPLATE-task.1 # TEMPLATE - Replace with actual task ID using nav-path
status: pending
priority: high
estimate: 1h
dependencies: []
---

# TEMPLATE: Setup dev-taskflow Structure

**TEMPLATE NOTE:** This is a template task file. When copying to an actual project:

1. Replace "TEMPLATE" with actual project-specific task ID (use `nav-path task-new`)
2. Remove this template note section
3. Customize content for specific project needs

## Objective

Initialize the foundational documentation structure for the project using the docs-dev framework. This establishes the directory structure, core documentation files, and bin scripts necessary for AI-assisted development workflow.

## Scope of Work

### Deliverables

#### Create

- dev-taskflow/ directory structure (backlog/, current/, done/, decisions/)
- dev-taskflow/what-do-we-build.md
- dev-taskflow/architecture.md
- dev-taskflow/blueprint.md
- bin/ scripts copied from docs-dev binstubs

#### Modify

- .gitignore (if exists) to include dev-taskflow patterns
- Project README.md (if enhancement needed)

#### Delete

- None

## Phases

1. Structure Creation - Set up directory hierarchy
2. Core Documentation - Generate foundational docs
3. Tool Setup - Install bin scripts
4. Validation - Verify structure completeness

## Implementation Plan

### Planning Steps

- [ ] Verify docs-dev submodule is available and accessible
  > TEST: Submodule Check
  > Type: Pre-condition Check
  > Assert: docs-dev directory exists and contains necessary templates
  > Command: test -d dev-handbook/templates/project-docs
- [ ] Review existing project files (README.md, PRD.md) for content extraction

### Execution Steps

- [ ] Run initialize-project-structure.wf.md workflow
  > TEST: Structure Creation
  > Type: Action Validation
  > Assert: dev-taskflow directory structure created successfully
  > Command: test -d dev-taskflow/backlog && test -d dev-taskflow/current && test -d dev-taskflow/done
- [ ] Verify core documentation files generated
  > TEST: Core Docs Generated
  > Type: Action Validation
  > Assert: All core documentation files exist and contain project-specific content
  > Command: test -f dev-taskflow/what-do-we-build.md && test -f dev-taskflow/architecture.md && test -f dev-taskflow/blueprint.md
- [ ] Confirm bin scripts are executable and functional
  > TEST: Bin Scripts Setup
  > Type: Action Validation
  > Assert: Essential bin scripts copied and executable
  > Command: test -x bin/tn && test -x bin/tr && test -x bin/tree

## Acceptance Criteria

- [ ] AC 1: Complete dev-taskflow directory structure exists
- [ ] AC 2: Core documentation files generated with project-specific content
- [ ] AC 3: bin scripts functional and executable
- [ ] AC 4: All automated tests in Implementation Plan pass
- [ ] AC 5: Structure ready for release planning and task management

## Out of Scope

- ❌ Creating specific project releases (covered by separate tasks)
- ❌ Detailed PRD completion (covered by separate task)
- ❌ Roadmap creation (covered by separate task)
- ❌ Project-specific customization beyond initial setup

## References

- dev-handbook/workflow-instructions/initialize-project-structure.wf.md
- dev-handbook/templates/project-docs/ (various templates)
- dev-handbook/guides/project-management.g.md
</template>

</documents>

##### v.0.0.0+task.2: Create Core Docs

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/02-complete-documentation.task.template.md">---
id: TEMPLATE-task.2 # TEMPLATE - Replace with actual task ID using nav-path
status: pending
priority: high
estimate: 2h
dependencies: [TEMPLATE-task.1]
---

# TEMPLATE: Complete Core Documentation

**TEMPLATE NOTE:** This is a template task file. When copying to an actual project:

1. Replace "TEMPLATE" with actual project-specific task ID (use `nav-path task-new`)
2. Replace dependency IDs with actual task IDs
3. Remove this template note section
4. Customize content for specific project needs

## Objective

Enhance and complete the core documentation files generated during project structure setup. This includes enriching the what-do-we-build.md, architecture.md, and blueprint.md files with comprehensive project-specific information, technology stack details, and development guidelines.

## Scope of Work

### Deliverables

#### Create

- None (files already exist from structure setup)

#### Modify

- dev-taskflow/what-do-we-build.md (enhance with detailed project vision)
- dev-taskflow/architecture.md (add technology stack and architectural patterns)
- dev-taskflow/blueprint.md (customize development guidelines and project structure)
- README.md (update with current project information if needed)

#### Delete

- None

## Phases

1. Content Review - Assess current documentation completeness
2. Information Gathering - Collect detailed project requirements and technical decisions
3. Documentation Enhancement - Enrich files with comprehensive content
4. Cross-Reference Validation - Ensure consistency across all documentation

## Implementation Plan

### Planning Steps

- [ ] Review generated core documentation for completeness and accuracy
  > TEST: Documentation Baseline Review
  > Type: Pre-condition Check
  > Assert: Core documentation files exist and contain basic structure
  > Command: test -s dev-taskflow/what-do-we-build.md && test -s dev-taskflow/architecture.md && test -s dev-taskflow/blueprint.md
- [ ] Identify missing information gaps in project vision and technical details
- [ ] Gather specific technology stack and architectural decision information

### Execution Steps

- [ ] Enhance what-do-we-build.md with detailed project vision, features, and user scenarios
  > TEST: Project Vision Complete
  > Type: Action Validation
  > Assert: what-do-we-build.md contains comprehensive project description
  > Command: grep -q "Key Features\|Target Users\|Core Functionality" dev-taskflow/what-do-we-build.md
- [ ] Complete architecture.md with technology stack, system components, and integration patterns
  > TEST: Architecture Documentation Complete
  > Type: Action Validation
  > Assert: architecture.md includes technology stack and system architecture
  > Command: grep -q "Technology Stack\|System Architecture\|Data Flow" dev-taskflow/architecture.md
- [ ] Customize blueprint.md with project-specific development guidelines and structure
  > TEST: Blueprint Customization Complete
  > Type: Action Validation
  > Assert: blueprint.md contains project-specific guidelines
  > Command: grep -q "Development Guidelines\|Project Structure\|AI Agent Guidelines" dev-taskflow/blueprint.md
- [ ] Update README.md to reflect current project status and documentation structure
  > TEST: README Alignment
  > Type: Action Validation
  > Assert: README.md aligns with core documentation
  > Command: grep -q "dev-taskflow\|Documentation" README.md
- [ ] Cross-validate consistency between all documentation files
  > TEST: Documentation Consistency
  > Type: Post-condition Check
  > Assert: All core documentation files are consistent and reference each other appropriately
  > Command: bin/test --check-doc-consistency dev-taskflow/

## Acceptance Criteria

- [ ] AC 1: what-do-we-build.md contains comprehensive project vision and feature descriptions
- [ ] AC 2: architecture.md includes complete technology stack and architectural patterns
- [ ] AC 3: blueprint.md provides clear development guidelines and project structure overview
- [ ] AC 4: All documentation is consistent and cross-references appropriately
- [ ] AC 5: README.md accurately reflects project status and documentation structure
- [ ] AC 6: All automated tests in Implementation Plan pass

## Out of Scope

- ❌ Detailed API documentation (covered in later releases)
- ❌ User manuals or end-user documentation
- ❌ Deployment and operations documentation
- ❌ Detailed implementation specifications (covered in specific feature tasks)

## References

- dev-handbook/templates/project-docs/ (documentation templates)
- dev-taskflow/what-do-we-build.md (target file)
- dev-taskflow/architecture.md (target file)
- dev-taskflow/blueprint.md (target file)
- dev-handbook/guides/project-management.g.md
</template>

</documents>

##### v.0.0.0+task.3: Complete PRD

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/03-complete-prd.task.template.md">---
id: TEMPLATE-task.3 # TEMPLATE - Replace with actual task ID using nav-path
status: pending
priority: high
estimate: 3h
dependencies: [TEMPLATE-task.2]
---

# TEMPLATE: Complete Product Requirements Document (PRD)

**TEMPLATE NOTE:** This is a template task file. When copying to an actual project:

1. Replace "TEMPLATE" with actual project-specific task ID (use `nav-path task-new`)
2. Replace dependency IDs with actual task IDs
3. Remove this template note section
4. Customize content for specific project needs

## Objective

Complete the Product Requirements Document (PRD) with comprehensive project requirements, user stories, technical specifications, and success criteria. This document serves as the definitive reference for project scope, features, and acceptance criteria throughout the development lifecycle.

## Scope of Work

### Deliverables

#### Create

- None (PRD.md already exists from structure setup)

#### Modify

- PRD.md (complete all sections with detailed requirements)
- dev-taskflow/what-do-we-build.md (ensure alignment with PRD)

#### Delete

- None

## Phases

1. Requirements Gathering - Collect detailed functional and non-functional requirements
2. User Story Development - Create comprehensive user stories and acceptance criteria
3. Technical Specification - Define technical constraints, dependencies, and integration points
4. Stakeholder Review - Validate requirements with stakeholders and gather feedback
5. Finalization - Complete PRD with all required sections and approvals

## Implementation Plan

### Planning Steps

- [ ] Review existing PRD structure and identify missing sections
  > TEST: PRD Structure Review
  > Type: Pre-condition Check
  > Assert: PRD.md exists and contains basic template structure
  > Command: test -f PRD.md && grep -q "## Overview\|## Features\|## Requirements" PRD.md
- [ ] Gather stakeholder input and requirements from project team
- [ ] Analyze core documentation for alignment and consistency requirements

### Execution Steps

- [ ] Complete PRD Overview section with project vision and business objectives
  > TEST: Overview Section Complete
  > Type: Action Validation
  > Assert: PRD Overview section contains comprehensive project description
  > Command: grep -A 10 "## Overview" PRD.md | grep -q "[A-Za-z]"
- [ ] Define detailed functional requirements and feature specifications
  > TEST: Functional Requirements Complete
  > Type: Action Validation
  > Assert: PRD contains detailed functional requirements
  > Command: grep -q "## Functional Requirements\|## Features" PRD.md && grep -A 5 "Functional Requirements\|Features" PRD.md | grep -q "- \["
- [ ] Document non-functional requirements (performance, security, scalability)
  > TEST: Non-Functional Requirements Complete
  > Type: Action Validation
  > Assert: PRD includes non-functional requirements section
  > Command: grep -q "## Non-Functional Requirements\|Performance\|Security" PRD.md
- [ ] Create comprehensive user stories with acceptance criteria
  > TEST: User Stories Complete
  > Type: Action Validation
  > Assert: PRD contains user stories with acceptance criteria
  > Command: grep -q "## User Stories\|As a.*I want\|Acceptance Criteria" PRD.md
- [ ] Define technical constraints, dependencies, and integration requirements
  > TEST: Technical Specifications Complete
  > Type: Action Validation
  > Assert: PRD includes technical constraints and dependencies
  > Command: grep -q "## Technical.*\|Dependencies\|Constraints" PRD.md
- [ ] Document success metrics and key performance indicators
  > TEST: Success Metrics Defined
  > Type: Action Validation
  > Assert: PRD contains measurable success criteria
  > Command: grep -q "## Success.*\|Metrics\|KPIs" PRD.md
- [ ] Review PRD with stakeholders and incorporate feedback
  > VERIFY: Stakeholder PRD Review
  > Type: User Feedback
  > Prompt: Please review the completed PRD.md. Does it accurately capture all project requirements, user needs, and technical specifications? Are there any missing elements or areas that need clarification?
  > Options: (Approved / Needs Revision / Major Changes Required)
- [ ] Ensure alignment between PRD and core documentation files
  > TEST: Documentation Alignment
  > Type: Post-condition Check
  > Assert: PRD aligns with what-do-we-build.md and architecture.md
  > Command: bin/test --check-prd-alignment PRD.md dev-taskflow/what-do-we-build.md dev-taskflow/architecture.md
- [ ] Finalize PRD with version control and approval tracking
  > TEST: PRD Finalization
  > Type: Post-condition Check
  > Assert: PRD is complete with all required sections and approval markers
  > Command: grep -q "## Approval\|Version.*1.0\|Status.*Approved" PRD.md

## Acceptance Criteria

- [ ] AC 1: PRD contains comprehensive project overview and business objectives
- [ ] AC 2: All functional requirements are clearly defined with detailed specifications
- [ ] AC 3: Non-functional requirements cover performance, security, and scalability needs
- [ ] AC 4: User stories include detailed acceptance criteria and edge cases
- [ ] AC 5: Technical constraints, dependencies, and integration points are documented
- [ ] AC 6: Success metrics and KPIs are measurable and time-bound
- [ ] AC 7: PRD approved by stakeholders with documented feedback incorporation
- [ ] AC 8: Documentation consistency verified across PRD and core files
- [ ] AC 9: All automated tests in Implementation Plan pass

## Out of Scope

- ❌ Detailed technical implementation specifications (covered in architecture docs)
- ❌ User interface mockups and design specifications
- ❌ Detailed project timeline and resource allocation
- ❌ Budget and cost analysis
- ❌ Market research and competitive analysis

## References

- PRD.md (target file)
- dev-handbook/templates/project-docs/prd.template.md (template reference)
- dev-taskflow/what-do-we-build.md (alignment reference)
- dev-taskflow/architecture.md (technical alignment reference)
- dev-handbook/guides/project-management.g.md
</template>

</documents>

##### v.0.0.0+task.4: Create Roadmap

<documents>
<template path="dev-handbook/templates/release-v.0.0.0/04-create-roadmap.task.template.md">---
id: TEMPLATE-task.4 # TEMPLATE - Replace with actual task ID using nav-path
status: pending
priority: high
estimate: 2h
dependencies: [TEMPLATE-task.3]
---

# TEMPLATE: Create Project Roadmap

**TEMPLATE NOTE:** This is a template task file. When copying to an actual project:

1. Replace "TEMPLATE" with actual project-specific task ID (use `nav-path task-new`)
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
