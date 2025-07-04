# Documents Embedding Standards and Principles

This guide establishes standards for embedding documents (templates and guides) within workflow instruction files using XML-based `<documents>` containers, ensuring consistency and enabling automated synchronization across the development handbook system.

## Goal

Define clear principles and standards for:
- How to properly embed documents using universal `<documents>` XML format
- Document organization and placement within workflow files
- Maintaining document consistency across workflow instructions
- Enabling automated document synchronization through structured XML
- Supporting both templates and guides in a unified format

## Core Principles

1. **Universal Container Format**: Use `<documents>` container with `<template>` and `<guide>` tags for all document embedding
2. **Separation of Concerns**: Document content should be separated from workflow logic using XML structure
3. **Structured Metadata**: All document references should use XML attributes for path information
4. **XML Format Only**: Use XML sections for all document embedding (no markdown escaping)
5. **Automated Synchronization**: XML document format enables easy parsing and automated updates

## Universal Document Embedding Format

### XML-Based Document Container (Current Standard)

Use the universal `<documents>` container for clean, parseable document inclusion:

```xml
<documents>
    <template path="{source-template-path}">
    <!-- Template content goes here -->
    </template>
    
    <guide path="{source-guide-path}">
    <!-- Guide content goes here -->
    </guide>
    
    <template path="{another-template-path}">
    <!-- Another template content -->
    </template>
</documents>
```

**Components:**
- `<documents>`: Universal container for all embedded documents
- `<template path="...">`: Embedded template content from `dev-handbook/templates/`
- `<guide path="...">`: Embedded guide content from `dev-handbook/guides/`
- `path`: Source document file path (supports variables like `{current-release-path}`)

**Examples:**
```xml
<documents>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
---
id: v.X.Y.Z+task.N
status: pending
priority: medium
---

# Task Title
Task description and requirements.
    </template>
    
    <guide path="dev-handbook/guides/version-control-system.g.md">
# Version Control System Guide

This guide covers Git workflow standards...
    </guide>
    
    <template path="dev-handbook/templates/project-docs/decisions/adr.template.md">
# ADR-NNN: Decision Title

## Status
Proposed

## Context
Context description.
    </template>
</documents>
```

## Code Block Escaping Standards

### XML Document Embedding: For Templates and Guides

Use XML `<documents>` sections for all embedded document content (NO escaping needed):

```xml
<documents>
    <template path="dev-handbook/templates/example.template.md">
<!-- Template content here -->
    </template>
    
    <guide path="dev-handbook/guides/example.g.md">
<!-- Guide content here -->
    </guide>
</documents>
```

### Three-Tick Escaping (```): For All Code Examples

Use standard three-tick escaping for:
- Command examples
- Code snippets  
- Configuration examples
- Any code that is NOT a template/guide or markdown demonstration

```markdown
## Example Commands

```bash
git status
git add .
git commit -m "feat: add new feature"
```

## Configuration Example  

```yaml
version: 1.0
settings:
  debug: false
```
```

### Four-Tick Escaping (````): Not for Documents

Four-tick escaping is reserved for markdown-within-markdown demonstrations (see [Markdown Definition Guide](dev-handbook/guides/.meta/markdown-definition.g.md)). 

**Important**: Do NOT use four-tick escaping for templates or guides - use XML format instead.

## Document Organization Structure

### Embedded Documents Section

All embedded documents must be placed at the end of workflow documents using XML format:

```xml
<documents>
    <template path="{source-template-path}">
<!-- Template content here -->
    </template>
    
    <guide path="{source-guide-path}">
<!-- Guide content here -->
    </guide>
    
    <!-- additional documents -->
    <template path="{another-template-path}">
<!-- Another template content -->
    </template>
</documents>
```

### Benefits of Universal XML Format

- **Clear Structure**: Documents are explicitly contained and separated
- **Machine Parseable**: Easy to extract documents programmatically
- **Metadata Rich**: Path information is structured as attributes
- **Multiple Documents**: Simple to include multiple templates and guides in one section
- **Variable Support**: Path attributes can use variables like `{current-release-path}`
- **Type Safety**: Clear distinction between templates and guides
- **Unified Format**: Single container format for all document types

## Document Path Conventions

### Templates
Templates should be organized in logical directories under `dev-handbook/templates/`:

- `project-docs/` - Core project documentation templates
- `release-tasks/` - Task templates for releases
- `release-management/` - Release planning and tracking templates
- `code-docs/` - API and code documentation templates
- `user-docs/` - User-facing documentation templates
- `workflow-components/` - Reusable workflow step templates

### Guides
Guides should be organized under `dev-handbook/guides/`:

- Root level: Core development guides (`.g.md` extension)
- `.meta/` subdirectory: Meta-documentation and framework guides
- Specialized subdirectories for domain-specific guides

## Content Guidelines

### Template Content Standards
- Always include YAML frontmatter for metadata
- Use clear placeholder syntax (e.g., `{variable-name}`)
- Provide comprehensive documentation comments
- Follow consistent formatting and structure
- Include validation criteria where applicable

### Guide Content Standards
- Use clear, actionable headings
- Provide concrete examples and code snippets
- Include troubleshooting sections where relevant
- Cross-reference related guides and templates
- Maintain consistent tone and structure

## Synchronization Integration

The universal `<documents>` format integrates with the automated synchronization system:

- **Tool**: `bin/markdown-sync-embedded-documents`
- **Parsing**: XML structure enables reliable content extraction
- **Updates**: Automated synchronization between source files and embedded content
- **Validation**: Path verification and content consistency checks
- **Maintenance**: Automated detection of missing or outdated documents

## Migration from Legacy Formats

### From Individual Template Containers
```xml
<!-- Old format -->
<templates>
    <template path="...">...</template>
</templates>

<!-- New universal format -->
<documents>
    <template path="...">...</template>
</documents>
```

### From Mixed Formats
Consolidate all document types into single `<documents>` containers:

```xml
<documents>
    <template path="dev-handbook/templates/task.template.md">
    <!-- Template content -->
    </template>
    
    <guide path="dev-handbook/guides/workflow-guide.g.md">
    <!-- Guide content -->
    </guide>
</documents>
```

## Best Practices

1. **Single Container**: Use one `<documents>` container per workflow file
2. **Logical Grouping**: Group related templates and guides together
3. **Path Accuracy**: Ensure all path attributes are correct and up-to-date
4. **Content Freshness**: Regularly synchronize embedded content with source files
5. **Documentation**: Document the purpose and usage of embedded documents
6. **Validation**: Test embedded content in actual workflow contexts
7. **Consistency**: Follow established naming and organization conventions

## Related Documentation

- [Documents Embedded Sync Guide](dev-handbook/guides/documents-embedded-sync.g.md) - Tool usage and operations
- [Markdown Definition Guide](dev-handbook/guides/.meta/markdown-definition.g.md) - Markdown standards
- [Workflow Instructions Organization](dev-handbook/guides/workflow-instructions-organization.g.md) - Workflow structure

This universal documents embedding format provides a consistent, maintainable approach to including both templates and guides within workflow instructions while enabling automated synchronization and content management.