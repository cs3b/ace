# Development Guides

This directory contains comprehensive development guidelines and standards for the project.

## Core Development Process

Our development workflow centers around:
- Iterative, task-based development 
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases

## Guide Organization

### Essential Guidelines
- [Coding Standards](coding-standards.md) - Code style and best practices
- [Testing Guidelines](testing.md) - Testing approach and frameworks
- [Documentation Standards](documentation.md) - Documentation requirements
- [Quality Assurance](quality-assurance.md) - Quality control processes
- [Version Control](version-control.md) - Git workflow and commit standards

### Technical Guidelines
- [Error Handling](error-handling.md) - Error handling patterns
- [Performance](performance.md) - Performance optimization guidelines
- [Security](security.md) - Security best practices

### Release Management
- [Release Process](ship-release.md) - Release workflow and checklists
- [Release Documentation Template](prepare-release/prepare-release-documentation.md) - Standard release documentation structure

## Task Management

Tasks are managed through a Kanban-style system in the `project/` directory:

- `0-backlog/`: Future planned work
- `1-next/`: Current sprint tasks 
- `2-done/`: Completed work

### Version Naming

We follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes (x.0.0)
- MINOR: New features (0.x.0) 
- PATCH: Bug fixes (0.0.x)

### Task Workflow

1. Tasks begin in `0-backlog/` with version prefix
2. Priority work moves to `1-next/` 
3. Completed work moves to `2-done/`
4. Document in release template structure

## Release Documentation

Each release version requires specific documentation based on type:

### Bug Fix Release (v.0.0.x)
- Bug description and fix details
- Regression tests
- Lessons learned

### Feature Release (v.0.x.0)
- Feature specification
- Technical decisions
- Feature validation
- Usage examples
- Release learnings

### Major Release (v.x.0.0)
- Migration tooling
- Architectural changes
- Complete feature documentation
- Investigation results
- Comprehensive test suite
- Detailed tutorials
- In-depth retrospective

For detailed release documentation structure, see [Release Documentation Guide](prepare-release/prepare-release-documentation.md)