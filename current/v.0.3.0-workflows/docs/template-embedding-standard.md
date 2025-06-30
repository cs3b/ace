# Template Embedding Standard

## Overview

This document defines the standardized format for embedding templates within workflow instruction files. The standard moves all embedded templates to the end of documents with consistent reference formatting to enable automated synchronization.

**Version**: 1.0  
**Status**: Draft  
**Created**: 2024-12-30  

## Standard Format Specification

### 1. Template Reference Format

When referencing a template within workflow text, use this format:

```
Use the template: path (template_path)
```

**Examples**:

- `Use the ADR template: path (dev-handbook/templates/project-docs/decisions/adr.template.md)`
- `Follow the task format: path (dev-handbook/templates/release-tasks/task.template.md)`

### 2. Embedded Template Section

All embedded templates must be placed at the end of the document in a dedicated section:

```markdown
## Embedded Templates

### Template Name: path (template_path)

````markdown
[template content here]
````

```

### 3. Four-Tick Escaping

All embedded templates must use four backticks (`````) for proper markdown escaping:

```markdown
````markdown
# Template Content
[content here]
````

```

### 4. Template Path Format

Template paths must follow this structure:
- **Absolute path format**: `dev-handbook/templates/category/template-name.template.md`
- **Consistent naming**: All templates end with `.template.md`
- **Category organization**: Templates grouped in logical directories

## Implementation Rules

### 1. Document Structure

```markdown
# Workflow Title

[workflow content]

## Embedded Templates

### Template 1: path (dev-handbook/templates/category/template1.template.md)

````markdown
[template 1 content]
````

### Template 2: path (dev-handbook/templates/category/template2.template.md)

````yaml
[template 2 content if YAML]
````

```

### 2. Template Language Specification

Use appropriate language specifiers:
- `markdown` - For document templates
- `yaml` - For YAML frontmatter or configuration templates
- `json` - For JSON configuration templates
- `bash` - For shell script templates
- `ruby`, `javascript`, `python` - For code templates

### 3. Reference Consistency

- **In-text references**: Use `path (template_path)` format
- **Section headers**: Use `Template Name: path (template_path)` format
- **Path consistency**: Always use full relative path from project root

## Migration Guidelines

### Step 1: Identify Embedded Templates

1. Search for code blocks containing templates
2. Identify template content vs. examples
3. Note current template locations in text

### Step 2: Create Template Path References

1. Determine appropriate template file path
2. Update in-text references to use `path (template_path)` format
3. Verify template files exist in specified locations

### Step 3: Move Templates to End Section

1. Create "Embedded Templates" section at document end
2. Move template content using four-tick escaping
3. Add proper section headers with path references

### Step 4: Validate Format

1. Ensure all templates use four-tick escaping
2. Verify path references are consistent
3. Check template content is properly escaped

## Benefits

### 1. Consistency
- Standardized format across all workflow files
- Predictable template locations
- Uniform reference syntax

### 2. Maintainability
- Easy to find all templates in a document
- Clear separation of workflow logic and templates
- Simplified template updates

### 3. Automation Ready
- Machine-readable template references
- Consistent parsing format
- Enables automated synchronization

### 4. Readability
- Templates don't interrupt workflow flow
- Clear template organization
- Easy to navigate between content and templates

## Validation Checklist

- [ ] All embedded templates moved to end of document
- [ ] All templates use four-tick escaping (````)
- [ ] All template references use `path (template_path)` format
- [ ] Template paths match actual file locations
- [ ] Language specifiers are appropriate for content type
- [ ] Section headers include template names and paths
- [ ] No inline template content remains in workflow body

## Examples

### Before (Current Format)

```markdown
# Create ADR Workflow

1. Create a new file
2. Use this template:

```markdown
# ADR-XXX: Title
## Status
[content]
```

3. Fill in the content

```

### After (Standardized Format)

```markdown
# Create ADR Workflow

1. Create a new file
2. Use the ADR template: path (dev-handbook/templates/project-docs/decisions/adr.template.md)
3. Fill in the content

## Embedded Templates

### ADR Template: path (dev-handbook/templates/project-docs/decisions/adr.template.md)

````markdown
# ADR-XXX: Title
## Status
[content]
````

```

## Future Considerations

### Synchronization Support
- Template content can be automatically synchronized with template files
- Path references enable validation of template file existence
- Consistent format enables batch processing

### Version Control
- Template changes can be tracked separately from workflow changes
- Clear attribution of template sources
- Simplified merge conflict resolution

### Documentation Generation
- Templates can be extracted for documentation
- Cross-references between workflows and templates
- Template usage analytics

## Implementation Status

This standard is designed to support the template unification initiative and prepare workflow instructions for automated template synchronization.
