# ADR-002: XML-Based Template Embedding Architecture

## Status

Accepted
Date: 2025-06-30

## Context

The Coding Agent Workflow Toolkit contains 16 workflow instruction files that embed templates for various purposes (project initialization, release management, code review, etc.). Prior to this decision, embedded templates used markdown four-tick escaping (````), which created several issues:

### Problems with Four-Tick Markdown Escaping

1. **Parsing Complexity**: Four-tick blocks were difficult to parse programmatically, especially when templates contained nested markdown with their own code blocks.

2. **No Semantic Structure**: Four-tick blocks provided no way to identify template metadata such as file paths, purposes, or relationships between templates.

3. **Synchronization Challenges**: Without structured metadata, it was impossible to automatically synchronize embedded template content with standalone template files.

4. **Ambiguous Content Boundaries**: Nested markdown within four-tick blocks made it unclear where template content began and ended, particularly with complex templates containing their own code examples.

5. **No Path Association**: Templates lacked explicit path references, making it impossible to determine where template content should be written when extracted or synchronized.

### Analysis from Template Standardization Work

Analysis of 16 workflow files revealed:

- **5,291 four-tick instances** requiring review for conversion
- **66 template references** needing structured metadata
- **12 files with embeddable templates** requiring systematic organization
- **No automated way** to keep embedded templates synchronized with template files

## Decision

All embedded templates in workflow instruction files must use XML-based embedding with the following structure:

```xml
<templates>
    <template path="dev-handbook/templates/category/filename.template.md">
    Template content here, including:
    - Markdown formatting
    - Code blocks with triple-tick syntax
    - Variable placeholders
    - Multi-line content
    </template>
</templates>
```

### Key Requirements

1. **XML Structure**: All embedded templates must use `<templates>` wrapper with individual `<template>` elements.

2. **Path Attribute**: Each template must specify its file path using the `path` attribute pointing to the corresponding template file in `dev-handbook/templates/`.

3. **End-of-Document Placement**: All `<templates>` sections must be placed at the end of workflow instruction files for consistency.

4. **Content Preservation**: Template content within XML tags preserves all markdown formatting, including nested code blocks using standard triple-tick syntax.

5. **Variable Support**: Template paths support variable substitution (e.g., `{current-release-path}`) for dynamic path resolution.

## Consequences

### Positive

- **Automated Synchronization**: XML structure enables the `markdown-sync-embedded-documents` script to automatically keep embedded templates synchronized with template files.

- **Clear Metadata Association**: Path attributes explicitly link embedded content to their corresponding template files.

- **Improved Parsing**: XML provides unambiguous structure boundaries, making programmatic processing reliable and maintainable.

- **Template Organization**: Standardized format enables systematic organization and management of all embedded templates.

- **Content Integrity**: XML escaping preserves all markdown formatting and code blocks without ambiguity.

- **Maintainability**: Changes to template files can be automatically propagated to all workflow files that embed them.

### Negative

- **Migration Effort**: Required conversion of 5,291 four-tick instances across 16 workflow files to XML format.

- **Verbose Syntax**: XML syntax is more verbose than four-tick markdown, increasing file size and visual complexity.

- **New Tooling Dependency**: Requires custom synchronization script and XML parsing logic to maintain template consistency.

- **Learning Curve**: Workflow authors must learn XML embedding syntax instead of simple markdown four-tick blocks.

### Neutral

- **Changed Editing Workflow**: Template updates now require either direct file editing or synchronization script execution to maintain consistency.

- **Tool-Dependent Synchronization**: Manual template synchronization is replaced by automated tool-based synchronization.

## Alternatives Considered

### Alternative 1: Enhanced Four-Tick Format with Comments

- **Description**: Add metadata comments above four-tick blocks to specify paths and purposes
- **Why it wasn't chosen**:
  - Comments are not semantically structured and difficult to parse reliably
  - Still vulnerable to nested markdown parsing issues
  - Doesn't solve synchronization automation challenges
  - Metadata could easily become out of sync with content

### Alternative 2: YAML Front Matter for Template Metadata

- **Description**: Use YAML front matter to specify template metadata with four-tick content blocks
- **Why it wasn't chosen**:
  - Creates mixed format files that are harder to process
  - YAML parsing adds complexity without solving core parsing issues
  - Still doesn't address nested markdown boundary problems
  - Less explicit about content boundaries than XML

### Alternative 3: Separate Template Files Only

- **Description**: Remove all embedded templates and reference only external template files
- **Why it wasn't chosen**:
  - Conflicts with ADR-001 (Workflow Self-Containment Principle)
  - Would require AI agents to load multiple files, reducing context efficiency
  - Breaks self-contained workflow execution capability
  - Reintroduces external dependency management complexity

## Related Decisions

- **ADR-001**: Workflow Self-Containment Principle - establishes requirement for embedded templates
- **ADR-003**: Template Directory Separation - defines the target directory structure for template paths

## References

- **Implementation Tasks**:
  - v.0.3.0+task.21: Standardize Template Embedding Format
  - v.0.3.0+task.22: Implement Template Sync Script
- **Analysis**: Template embedding format standardization research
- **Tool Implementation**: `bin/markdown-sync-embedded-documents` synchronization script
- **Original Requirement**: improve-the-workflow-structure.md

## Examples

### Before: Four-Tick Markdown Format

````markdown
## Task Template

Use this template for new tasks:

````yaml
---
id: v.X.Y.Z+task.N
status: pending
priority: high
estimate: 4h
---

# Task Title

## Objective
[Description here]
````

````

### After: XML Template Format

```markdown
## Task Template

Use this template for new tasks (see embedded template below).

<templates>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
---
id: v.X.Y.Z+task.N
status: pending
priority: high
estimate: 4h
---

# Task Title

## Objective
[Description here]
    </template>
</templates>
```

This architectural decision enables automated template management while maintaining the self-contained nature of workflow instructions, supporting both human readability and programmatic processing.
