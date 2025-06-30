# Release Templates Guide

## Overview

This directory contains standard templates for creating structured release documentation artifacts. These templates
ensure consistency and completeness across all project releases and serve as a starting point when creating new
release directories.

## Template Directory Structure

```text
draft-release/
└── v.x.x.x/                     # Base template directory
    ├── codemods/                # Scripts for automated code modifications
    │   └── _template.md
    ├── decisions/               # Architecture Decision Records (ADRs)
    │   └── _template.md
    ├── docs/                    # Feature/component documentation
    │   └── _template.md
    ├── reflections/             # Post-implementation reflections
    │   └── _template.md
    ├── researches/              # Research notes and findings
    │   └── _template.md
    ├── tasks/                   # Implementation tasks
    │   └── _template.md
    ├── test-cases/              # Test specifications
    │   └── _template.md
    ├── user-experience/         # UX design and user journey documentation
    │   └── _template.md
    └── v.x.x.x-codename.md      # Main release overview document
```

## When to Use Each Template

### Main Release Templates

- **`v.x.x.x-codename.md`**: The central document for a release that provides an overview, goals, implementation
  plan, and release checklist. Required for every release.

### Specialized Templates

- **`tasks/_template.md`**: For individual implementation tasks. Used for every discrete unit of work within a
  release.
- **`decisions/_template.md`**: For Architecture Decision Records (ADRs). Use when making significant technical
  decisions that impact the project architecture.
- **`docs/_template.md`**: For detailed feature documentation. Create one for each major feature or component in a
  release.
- **`test-cases/_template.md`**: For structured test specifications. Use when defining comprehensive test plans for
  features.
- **`user-experience/_template.md`**: For UX documentation. Use when implementing features with significant user
  interaction components.
- **`codemods/_template.md`**: For automated code modification scripts. Use when implementing large-scale code
  changes across multiple files.
- **`researches/_template.md`**: For research notes. Use when investigating solutions or approaches before
  implementation.
- **`reflections/_template.md`**: For post-implementation analysis. Use after completing significant features to
  document learnings.

## Usage Instructions

1. When creating a new release, first identify which templates you'll need based on the release scope.
2. Copy the main release template (`v.x.x.x-codename.md`) to your new release directory and rename it according to
   your release version and codename.
3. Create appropriate subdirectories in your release directory (tasks, docs, decisions, etc.)
4. Copy the needed specialized templates to their respective subdirectories.
5. When referencing these templates from workflows, use the path
   `dev-handbook/templates/release-[category]/[type].template.md`.

## Integration with Workflows

These templates are referenced directly from the `draft-release.md` workflow instruction and should be used when:

1. Creating a new release directory structure in the backlog
2. Generating task files for requirements
3. Creating documentation artifacts for a release
4. Documenting architectural decisions

For more details on how these templates integrate with the project management workflow, refer to:

- [Project Management Guide](dev-handbook/guides/project-management.g.md)
- [Breakdown Notes into Tasks Workflow](dev-handbook/workflow-instructions/create-task.wf.md)
- [Publish Release Guide](dev-handbook/guides/release-publish.g.md)

## Customization

While maintaining consistent structure is important, feel free to adapt these templates to your specific release needs by:

- Adding additional sections where needed
- Expanding on the provided sections with more detailed questions or prompts
- Including release-specific context or requirements

Always preserve the core structure to maintain compatibility with project workflows and documentation standards.
