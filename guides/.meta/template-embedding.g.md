# Template Embedding in Workflow Instructions

This guide establishes standards for embedding templates within workflow instruction files using XML-based template sections, ensuring consistency and enabling automated synchronization across the development handbook system.

## Goal

Define clear principles and standards for:
- How to properly embed templates using XML format in workflow files
- Template organization and placement within documents
- Maintaining template consistency across workflow instructions
- Enabling automated template synchronization through structured XML

## Core Principles

1. **Separation of Concerns**: Template content should be separated from workflow logic using XML structure
2. **Structured Metadata**: All template references should use XML attributes for path information
3. **XML Format Only**: Use XML `<templates>` sections for all template embedding (no markdown escaping)
4. **Automated Synchronization**: XML template format enables easy parsing and automated updates

## Template Embedding Format

### XML-Based Template Embedding (Recommended)

Use XML-based template embedding for clean, parseable template inclusion:

```xml
<templates>
    <template path="{target-path}" template-path="{source-template-path}">
    <!-- Template content goes here -->
    </template>
    
    <template path="{another-target-path}" template-path="{another-template-path}">
    <!-- Another template content -->
    </template>
</templates>
```

**Components:**
- `path`: Target location where template will be used (supports variables like `{current-release-path}`)
- `template-path`: Source template file path in `dev-handbook/templates/`
- Template content: Embedded directly within the `<template>` tags

**Examples:**
```xml
<templates>
    <template path="{current-release-path}/tasks/v.x.y.z.nnn-task-name.md" template-path="dev-handbook/templates/release-tasks/task.template.md">
---
id: v.X.Y.Z+task.N
status: pending
priority: medium
---

# Task Title
Task description and requirements.
    </template>
    
    <template path="docs/decisions/adr-NNN-title.md" template-path="dev-handbook/templates/project-docs/decisions/adr.template.md">
# ADR-NNN: Decision Title

## Status
Proposed

## Context
Context description.
    </template>
</templates>
```

## Code Block Escaping Standards

### XML Template Embedding: For Templates Only

Use XML `<templates>` sections for all embedded template content (NO escaping needed):

```xml
<templates>
    <template path="{target-path}" template-path="dev-handbook/templates/example.template.md">
<!-- Template content here -->
    </template>
</templates>
```

### Three-Tick Escaping (```): For All Code Examples

Use standard three-tick escaping for:
- Command examples
- Code snippets  
- Configuration examples
- Any code that is NOT a template or markdown demonstration

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

### Four-Tick Escaping (````): Not for Templates

Four-tick escaping is reserved for markdown-within-markdown demonstrations (see [Markdown Definition Guide](dev-handbook/guides/.meta/markdown-definition.g.md)). 

**Important**: Do NOT use four-tick escaping for templates - use XML format instead.

## Template Organization Structure

### Embedded Templates Section

All embedded templates must be placed at the end of workflow documents using XML format:

```xml
<templates>
    <template path="{target-path}" template-path="{source-template-path}">
<!-- Template content here -->
    </template>
    
    <!-- another template -->
    <template path="{another-path}" template-path="{another-source}">
<!-- Another template content -->
    </template>
</templates>
```

### Benefits of XML Format

- **Clear Structure**: Templates are explicitly contained and separated
- **Machine Parseable**: Easy to extract templates programmatically
- **Metadata Rich**: Path information is structured as attributes
- **Multiple Templates**: Simple to include multiple templates in one section
- **Variable Support**: Path attributes can use variables like `{current-release-path}`

### Template Path Conventions

Templates should be organized in logical directories under `dev-handbook/templates/`:

- `project-docs/` - Core project documentation templates
- `release-tasks/` - Task templates for releases
- `release-management/` - Release planning and tracking templates
- `code-docs/` - API and code documentation templates
- `user-docs/` - User-facing documentation templates
- `project-build/` - Build and development tool templates

## Validation and Quality Control

### Validation Patterns

**Find XML template sections:**
```regex
<templates>[\s\S]*?</templates>
```

**Validate template tags:**
```regex
<template\s+path="[^"]+"\s+template-path="[^"]+">[\s\S]*?</template>
```

**Find templates missing required attributes:**
```regex
<template(?!.*path=").*>
```
This finds template tags without path attribute.

```regex
<template(?!.*template-path=").*>
```
This finds template tags without template-path attribute.

**Find incorrect four-tick usage in template files:**
```regex
````.*</templates>
```
This finds four-tick blocks incorrectly used near template sections (should use XML format instead).

### Common Template Embedding Issues

**❌ Incorrect: Old markdown header format for templates**

````markdown
### Task Template: path (dev-handbook/templates/task.template.md)

````markdown
---
id: task.1
````
````

**❌ Incorrect: Four-tick escaping for templates**

````markdown
````xml
<templates>
    <template path="...">
    </template>
</templates>
````
````

**✅ Correct: XML format for embedded templates**

```xml
<templates>
    <template path="{target-path}" template-path="dev-handbook/templates/task.template.md">
---
id: task.1
status: pending
---

# Task Title
Task description.
    </template>
</templates>
```

## Benefits of XML Template Embedding

### Superior Structure and Readability
- **Clear separation**: Templates are explicitly contained within `<templates>` sections
- **Self-documenting**: Attributes clearly show source and target paths
- **Multiple templates**: Easy to include several templates without confusion
- **No escaping conflicts**: No need to worry about markdown tick escaping

### Enhanced Automation
- **XML parsing**: Much easier to parse programmatically than markdown escaping
- **Structured metadata**: Path information is accessible as XML attributes
- **Variable support**: Template paths can use variables like `{current-release-path}`
- **Validation**: XML structure can be validated with standard tools

### Maintainability Improvements
- **Templates separated from logic**: Clear distinction between workflow and template content
- **Centralized template management**: All templates in one clearly marked section
- **Easy updates**: Template content and metadata in one structured location
- **Migration friendly**: Clear format makes it easy to update when templates change

### Comparison with Previous Four-Tick Format

| Aspect | XML Format | Previous Four-Tick Format |
|--------|-----------|---------------------------|
| **Parsing** | Native XML parsing | Complex regex patterns |
| **Metadata** | Structured attributes | Embedded in markdown headers |
| **Multiple templates** | Clean separation | Header confusion |
| **Path references** | `template-path` attribute | Parenthetical format |
| **Validation** | XML schema validation | Custom regex patterns |
| **Readability** | Self-contained blocks | Mixed with markdown formatting |

## Automated Synchronization Support

The standardized format enables future automated synchronization through:

**Template Update Scripts:**
- Parse XML `<templates>` sections from workflow files
- Extract `template-path` attributes to locate source templates
- Compare embedded content with actual template files
- Update embedded content when templates change
- Generate reports of synchronization actions

**Validation Scripts:**
- Parse XML structure to validate template syntax
- Verify all `template-path` attributes point to existing files
- Check that embedded template content matches source files
- Validate XML format compliance throughout workflow files
- Report inconsistencies and formatting issues

## Migration Guidelines

When updating existing workflow files to follow these standards:

1. **Identify Embedded Templates**: Find existing template content in workflow files
2. **Convert to XML**: Replace markdown headers and four-tick blocks with XML format
3. **Add Attributes**: Ensure all templates have `path` and `template-path` attributes
4. **Move to End**: Relocate all templates to `<templates>` section at document end
5. **Update References**: Convert in-text template references to mention XML format
6. **Verify Compliance**: Run validation patterns to check XML structure and attributes

## Best Practices

### Template Design
- Keep templates focused and single-purpose
- Use clear, descriptive template names
- Include comprehensive examples within templates
- Document template usage context and purpose

### Workflow Integration
- Reference templates using consistent language
- Provide context for when and how to use templates
- Link conceptual guidance to template implementation
- Maintain clear separation between instruction and template

### Maintenance
- Regularly validate template synchronization
- Update path references when templates are reorganized
- Review embedded template content for accuracy
- Keep template organization aligned with project structure

## Related Documentation

- [Markdown Definition Guide](dev-handbook/guides/.meta/markdown-definition.g.md) - For markdown escaping standards (non-template content)
- [Guides Definition](dev-handbook/guides/.meta/guides-definition.g.md) - For understanding guide vs workflow distinction
- [Project Management Guide](dev-handbook/guides/project-management.g.md) - For template organization principles
- [Workflow Instructions](dev-handbook/workflow-instructions/) - For implementation examples

This standardized XML approach ensures template consistency, enables automation, and maintains clear separation between workflow logic and template content across the entire development handbook system.
