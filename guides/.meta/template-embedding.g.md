# Template Embedding in Workflow Instructions

This guide establishes standards for embedding templates within workflow instruction files, ensuring consistency and enabling automated synchronization across the development handbook system.

## Goal

Define clear principles and standards for:
- How to properly reference and embed templates in workflow files
- When to use four-tick vs three-tick code block escaping
- Maintaining template consistency across workflow instructions
- Enabling automated template synchronization

## Core Principles

1. **Separation of Concerns**: Template content should be separated from workflow logic for better maintainability
2. **Consistent Referencing**: All template references should use standardized path format
3. **Proper Escaping**: Use four-tick escaping exclusively for embedded templates, three-tick for all other code examples
4. **Automated Synchronization**: Template format should enable automated updates and validation

## Template Reference Format

### Standard Reference Pattern

When referencing templates within workflow text, use this format:

```markdown
<type> <path> _(<template-path>)_
```

**Components:**
- `<type>`: Document type (e.g., "Use the task template", "Follow the ADR template")
- `<path>`: Logical path or description in workflow context  
- `<template-path>`: Actual file path to template in `dev-handbook/templates/`

**Examples:**
```markdown
Use the task template: path (dev-handbook/templates/release-tasks/task.template.md)
Follow the ADR template: path (dev-handbook/templates/project-docs/decisions/adr.template.md)
Create the changelog: path (dev-handbook/templates/release-management/changelog.template.md)
```

## Code Block Escaping Standards

### Four-Tick Escaping (````): ONLY for Embedded Templates

Use four-tick escaping **exclusively** for embedded template content that should be synchronized:

```markdown
### Task Template: path (dev-handbook/templates/release-tasks/task.template.md)

````markdown
---
id: v.X.Y.Z+task.N
status: pending
priority: [high | medium | low]
---

# [Task Title]
[Template content here]
````
```

### Three-Tick Escaping (```): For All Other Code Examples

Use standard three-tick escaping for:
- Command examples
- Code snippets
- Configuration examples  
- Any code that is NOT a synchronized template

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

## Template Organization Structure

### Embedded Templates Section

All embedded templates must be placed at the end of workflow documents in a dedicated section:

```markdown
## Embedded Templates

### Template Name: path (template-file-path)

````markdown
[Template content using four-tick escaping]
````

### Another Template: path (other-template-path)

````yaml
[YAML template content using four-tick escaping]
````
```

### Template Path Conventions

Templates should be organized in logical directories under `dev-handbook/templates/`:

- `project-docs/` - Core project documentation templates
- `release-tasks/` - Task templates for releases
- `release-management/` - Release planning and tracking templates
- `code-docs/` - API and code documentation templates
- `user-docs/` - User-facing documentation templates
- `project-build/` - Build and development tool templates

## Validation and Quality Control

### Regex Patterns for Validation

Use these regex patterns to identify incorrect escaping usage:

**Find incorrectly used four-tick blocks (should be three-tick):**
```regex
^````(?!markdown|yaml|json|bash).*$
```
This finds four-tick blocks that don't specify a template language.

**Find four-tick blocks outside Embedded Templates section:**
```regex
^````(?!.*## Embedded Templates)
```
This finds four-tick blocks not in the proper section.

**Find three-tick blocks in Embedded Templates section:**
```regex
(?<=## Embedded Templates)[\s\S]*?^```(?!`)
```
This finds three-tick blocks in the embedded templates section.

**Find missing path references in templates:**
```regex
^### .+Template(?!.*path \()
```
This finds template headers without proper path references.

### Common Validation Issues

**❌ Incorrect: Four-tick for regular code examples**
```markdown
````bash
git status  # This should use three ticks
````
```

**✅ Correct: Three-tick for regular code examples**
```markdown
```bash
git status  # Proper three-tick escaping
```
```

**❌ Incorrect: Three-tick for embedded templates**
```markdown
### Task Template: path (dev-handbook/templates/task.template.md)

```markdown  # This should use four ticks
---
id: task.1
````
```

**✅ Correct: Four-tick for embedded templates**
```markdown
### Task Template: path (dev-handbook/templates/task.template.md)

````markdown  # Proper four-tick escaping
---
id: task.1
````
```

## Benefits of Standardized Template Embedding

### Maintainability
- Templates are separated from workflow logic
- Changes to templates can be made in one location
- Consistent organization across all workflow files

### Automation Ready
- Machine-readable template references enable automated synchronization
- Validation scripts can ensure compliance
- Template updates can be automatically propagated

### Clarity
- Clear distinction between workflow instructions and template content
- Templates don't interrupt workflow reading flow
- Easy navigation between workflow logic and template examples

## Automated Synchronization Support

The standardized format enables future automated synchronization through:

**Template Update Scripts:**
- Scan workflow files for `````<language>` blocks in Embedded Templates sections
- Compare with actual template files using path references
- Update embedded content when templates change
- Generate reports of synchronization actions

**Validation Scripts:**
- Verify all path references point to existing template files
- Check that embedded template content matches source files
- Validate proper escaping usage throughout workflow files
- Report inconsistencies and formatting issues

## Migration Guidelines

When updating existing workflow files to follow these standards:

1. **Identify Embedded Templates**: Find code blocks that contain actual template content
2. **Add Path References**: Update template headers to include proper path references  
3. **Move to End**: Relocate all embedded templates to "Embedded Templates" section
4. **Update Escaping**: Convert template blocks to four-tick escaping
5. **Validate References**: Ensure in-text references use proper format
6. **Verify Compliance**: Run validation regex patterns to check for issues

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

- [Guides Definition](dev-handbook/guides/.meta/guides-definition.g.md) - For understanding guide vs workflow distinction
- [Project Management Guide](dev-handbook/guides/project-management.g.md) - For template organization principles
- [Workflow Instructions](dev-handbook/workflow-instructions/) - For implementation examples

This standardized approach ensures template consistency, enables automation, and maintains clear separation between workflow logic and template content across the entire development handbook system.