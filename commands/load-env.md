# Load Environment Command

A systematic approach to load the project context, structure, and current development state for the AI Ruby Agent SDK.

## Process Steps

1. Load Project Context:
   - Review project objectives: [What Do We Build](../project/10-what-do-we-build.md)
   - Understand development process: [Project Management](../project/01-project-management.md)
   - Examine architecture: [Architecture](../project/11-architecture.md)
   - Check current work: [Current Work](../project/00-current-work.md)

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
   # View current tasks
   ls -la docs-dev/project/1-current/

   # View current version tasks
   ls -la docs-dev/project/1-current/v.0.1.0/
   ```

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
    ├── project/     # Project management and planning
    │   ├── 0-backlog/  # Future planned work
    │   ├── 1-current/  # Current sprint/milestone tasks
    │   └── 2-done/     # Completed work
    └── prompts/     # Reusable AI interaction templates
```

## Key Files

- `lib/aira.rb`: Main entry point for the SDK
- `lib/aira/version.rb`: Current SDK version
- `spec/spec_helper.rb`: Test configuration
- `docs-dev/project/00-current-work.md`: Current development context
- `docs-dev/project/10-what-do-we-build.md`: Project objectives
- `docs-dev/project/11-architecture.md`: System architecture

## Reference Documentation

- [Project Management](../project/01-project-management.md)
- [Coding Standards](../guides/coding-standards.md)
- [Testing Guidelines](../guides/testing.md)
- [Documentation Standards](../guides/documentation.md)
- [Release Process](../guides/ship-release.md)

## Success Criteria

1. Project Context Understood:
   - Project objectives clear
   - Development philosophy understood
   - Current work identified

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
