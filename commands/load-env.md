# Load Environment Command

A systematic approach to load the project context, structure, and current development state for the AI Ruby Agent SDK.

## Process Steps

1. Load Project Context:
   - Review project objectives: [What Do We Build](../project/what-do-we-build.md)
   - Understand development process: [Project Management](../guides/project-management.md)
   - Examine architecture: [Architecture](../project/architecture.md)

2. Explore Code Structure:
   ```bash
   # View main directory structure
   ls -la

   # View lib structure (main code)
   ls -la lib/

   # View spec structure (tests)
   ls -la spec/

   # View documentation structure
   ls -la docs-dev/
   ```

3. Examine Current Tasks:
   ```bash
   # View the active release directory
   ls -la docs-dev/project/current/

   # View the tasks within the active release directory
   # (Tasks are structured .md files)
   ls -la docs-dev/project/current/*/tasks/
   # Example: ls -la docs-dev/project/current/v.0.2.0-StreamlineWorkflow/tasks/
   ```
   - Review the `.md` files within the `tasks/` subdirectory of the current release for details, status, and dependencies.

4. Check Recent Changes:
   ```bash
   # View recent commits
   git log -n 5 --oneline

   # View recent file changes
   git diff --name-status HEAD~5..HEAD
   ```

5. Load Development Guidelines:
   - Review [Coding Standards](../guides/coding-standards.md)
   - Check [Testing Guidelines](../guides/testing.md)
   - Understand [Version Control](../guides/version-control.md)

## Project Structure

The project follows this organization:
```
ai-ruby-agent-sdk/
├── lib/             # Main source code
├── spec/            # Test files
│   ├── aira/        # Unit tests
│   ├── integration/ # Integration tests
│   └── e2e/         # End-to-end tests
└── docs-dev/        # Development documentation
    ├── guides/      # Development standards and practices
    ├── project/     # Project Management (Kanban: backlog/current/done)
    │   ├── backlog/    # Contains directories for future releases (e.g., v.0.3.0/)
    │   ├── current/    # Contains the directory for the active release (e.g., v.0.2.0/)
    │   └── done/       # Archive of completed release directories
    ├── decisions/   # Architecture Decision Records (ADRs)
    └── commands/    # AI interaction command patterns
```

## Key Files

- `spec/spec_helper.rb`: Test configuration
- `docs-dev/project/what-do-we-build.md`: Project objectives
- `docs-dev/project/architecture.md`: System architecture
- `lib/aira.rb`: Main entry point for the SDK
- `lib/aira/version.rb`: Current SDK version

## Core Documentation

### Essential Guidelines
- [Project Management](../guides/project-management.md)
- [Coding Standards](../guides/coding-standards.md)
- [Testing Guidelines](../guides/testing.md)
- [Documentation](../guides/documentation.md)

### Process Guides
- [Release Process](../guides/ship-release.md)
- [Version Control](../guides/version-control.md)
- [Quality Assurance](../guides/quality-assurance.md)

## Success Criteria

1. Project Context Understood:
   - Project objectives clear ([What Do We Build](../project/what-do-we-build.md))
   - Development philosophy understood ([Project Management](../guides/project-management.md))
   - Current release and its tasks identified in `docs-dev/project/current/`

2. Code Structure Mapped:
   - Main components identified
   - File organization understood
   - Test structure examined

3. Development Environment Ready:
   - Working directory clean
   - Dependencies installed
   - Latest code pulled
   - Current task identified

4. Next Steps Identified:
   - Current task requirements reviewed
   - Development approach planned
   - Implementation order determined
