---
id: v.0.5.0+task.022
status: done
priority: medium
estimate: 15m
dependencies: []
---

# Add project context template for standardized documentation

## Behavioral Context

**Issue**: The context tool needed a standardized template for generating project context documentation, but no template existed in the templates directory structure.

**Key Behavioral Requirements**:
- Provide a reusable template for project context generation
- Define standard set of files and commands to include in context
- Support the context tool's embed functionality
- Enable consistent project documentation across different usage scenarios

## Objective

Create a project context template that defines a standard structure for loading project documentation and status information using the context tool's configuration format.

## Scope of Work

- Created project context template with embedded configuration
- Defined standard file inclusions for project documentation
- Specified useful commands for project status information
- Structured template for reusable context generation

### Deliverables

#### Create
- `dev-handbook/templates/context/project.md` - Project context template with embedded configuration

#### Modify
- None

#### Delete
- None

## Implementation Summary

### What Was Done

- **Problem Identification**: Need for standardized project context template that works with the context tool
- **Solution**: Created a template with embedded `<context-tool-config>` that defines files and commands to include
- **Structure**: Template provides project description and uses context tool configuration to embed documentation and status
- **Integration**: While no automatic installation script exists yet, the template can be referenced by context configurations

### Technical Details

**Template Structure**:
```markdown
# Project Context
[Project description]

## Context
<context-tool-config>
embed_document_source: true
files:
  - [list of documentation files]
commands:
  - [list of status commands]
</context-tool-config>
```

**Configuration Elements**:
- `embed_document_source: true` - Ensures file contents are embedded
- Files section includes core documentation:
  - `docs/what-do-we-build.md` - Project overview
  - `docs/architecture.md` - System architecture
  - `docs/decisions.md` - Architectural decisions
  - `docs/blueprint.md` - Project structure
  - `docs/tools.md` - Available tools reference
- Commands section includes status information:
  - `git-status --short` - Repository status
  - `task-manager recent --limit 5` - Recent tasks
  - `task-manager next --limit 5` - Upcoming tasks
  - `release-manager current` - Current release info
  - `git ls-files` - Project file listing
  - Submodule file listings for dev-handbook and dev-tools

### Use Cases

This template can be used:
1. As a reference in `.coding-agent/context.yml` presets
2. As a base for creating custom project context templates
3. For manual context generation using the context tool
4. As documentation of standard context structure

### Future Enhancements

While automatic installation isn't implemented yet, this template:
- Provides a foundation for future automation
- Standardizes context generation across projects
- Can be referenced by context tool presets
- Serves as documentation for context configuration

## References

- Template location: `dev-handbook/templates/context/project.md`
- Context tool configuration: `.coding-agent/context.yml`
- Context tool documentation: `dev-tools/docs/exe/context.md`
- Related work: Task 021 (dotfile templates creation)