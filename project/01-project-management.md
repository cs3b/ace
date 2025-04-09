## Development Philosophy

Our development workflow is centered around:
- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases

## Directory Structure

The `docs-dev` directory organizes project documentation and management:

```
docs-dev/
├── guides/           # Development standards and practices
├── project/          # Project management and planning
│   ├── 0-backlog/   # Future planned work
│   ├── 1-next/      # Current sprint/milestone tasks
│   └── 2-done/      # Completed work
└── prompts/         # Reusable AI interaction templates
```

## Task Management

### 1. Task Organization

Tasks are managed through a Kanban-style directory system:

- `0-backlog/`: Future planned work
- `1-next/`: Current sprint tasks
- `2-done/`: Completed work

Each task should:
- Have a clear version number prefix (e.g., v.0.1.0)
- Include implementation checklists
- Document decisions and findings

### 2. Version Naming

We follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes (x.0.0)
- MINOR: New features (0.x.0)
- PATCH: Bug fixes (0.0.x)

### 3. Task Workflow

1. Start tasks in `0-backlog/` with version prefix
2. Move prioritized work to `1-next/`
3. Complete work and move to `2-done/`
4. Document in appropriate release template
### 4. Task Transitions

When moving a task between states, follow these guidelines:

- **Backlog → Next**:
  - Complete the specification using the template
  - Create an implementation plan
  - Ensure all dependencies are available
  - Reference the [Transition Checklist](../project/template/transition-checklist.md)

- **Next → Done**:
  - Verify all tests pass
  - Ensure documentation is complete
  - Code review is completed
  - All items in [Transition Checklist](../project/template/transition-checklist.md) are satisfied

### 5. Implementation Process

1. **Planning Phase**:
   - Create detailed [Implementation Plan](../project/template/implementation-plan.md)
   - Design interfaces and test structure
   - Set up necessary infrastructure

2. **Development Phase**:
   - Follow Test-Driven Development approach
   - Create failing tests first
   - Implement code to make tests pass
   - Document design decisions

3. **Review Phase**:
   - Self-review using [Self-Reflect Command](../commands/self-reflect.md)
   - Peer review with clear criteria
   - Document learnings and improvements

## Release Management

For detailed release management procedures, see [Release Documentation Guide](../guides/release-template/prepare-release-documentation.md)

Key aspects:
- Version-based organization
- Required documentation per release type
- Standard directory structure for knowledge capture

## Additional Resources

Essential project standards and guidelines:
- [Coding Standards](../guides/coding-standards.md)
- [Testing Guidelines](../guides/testing.md)
- [Documentation Standards](../guides/documentation.md)
- [Release Process](../guides/release.md)
- [Error Handling](../guides/error-handling.md)
- [Performance](../guides/performance.md)
- [Security](../guides/security.md)
