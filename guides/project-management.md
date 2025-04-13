# Development Philosophy and Project Management

Our development workflow is centered around:
- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases
- Command-driven AI interactions

The project uses a command-based approach for AI interactions, replacing the previous prompts-based system. Each command in the `commands/` directory represents a specific workflow or interaction pattern with clear inputs, processes, and success criteria.

## Directory Structure

The `docs-dev` directory organizes project documentation and management:

```
docs-dev/
├── guides/           # Development standards and practices
├── commands/        # AI interaction commands and workflows
├── project/         # Project-specific materials
│   ├── backlog/     # Future planned work
│   ├── current/     # Current sprint/milestone tasks
│   └── done/        # Completed work
```

## Task Management

### 1. Task Organization

Tasks are managed through a Kanban-style directory system:

- `backlog/`: Future planned work
- `current/`: Current sprint tasks  
- `done/`: Completed work

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

1. Start tasks in `backlog/` with version prefix
2. Move prioritized work to `current/`
3. Complete work and move to `done/`
4. Document in appropriate release template

### 4. Task Transitions

When moving a task between states, follow these guidelines:

#### Moving from Backlog → Current:
- Complete feature specification using the template
- Create an implementation plan
- Ensure all dependencies are available
- Document test strategy and acceptance criteria

#### Moving from Current → Done:
- All tests passing (unit, integration, edge cases)
- Code meets style guidelines
- Documentation updated
- PR reviewed and approved
- Release notes drafted
- No undocumented technical debt

### 5. Implementation Process

1. **Planning Phase**:
   - Design interfaces and test structure
   - Set up necessary infrastructure
   - Create detailed implementation plan

2. **Development Phase**:
   - Follow Test-Driven Development approach
   - Create failing tests first
   - Implement code to make tests pass
   - Document design decisions

3. **Review Phase**:
   - Self-review using [Self-Reflect Command](../commands/self-reflect.md)
   - Peer review with clear criteria
   - Document learnings and improvements

## Additional Resources

Essential standards and guidelines:
- [Coding Standards](coding-standards.md)
- [Testing Guidelines](testing.md)
- [Documentation Standards](documentation.md)
- [Release Process](ship-release.md)
- [Error Handling](error-handling.md)
- [Performance](performance.md)
- [Security](security.md)
