# Workflow Instruction Compliance Validation Criteria

## Template Embedding Format Validation

### 1. XML Template Section Structure

- [ ] Templates are wrapped in `<templates>` section
- [ ] Each template uses `<template path="...">` format with single path attribute
- [ ] Template content is embedded directly within template tags
- [ ] XML structure is valid and properly formatted

### 2. Template Positioning

- [ ] All templates are positioned at the end of the document
- [ ] Templates appear after all workflow content
- [ ] No content appears after the `</templates>` closing tag

### 3. Template Path Validation

- [ ] All paths start with `.ace/handbook/templates/`
- [ ] All paths end with `.template.md`
- [ ] Path references follow standard directory structure
- [ ] Variable placeholders (if any) use proper format: `{current-release-path}`, `{current-project-path}`

### 4. Deprecated Format Removal

- [ ] No use of old markdown code block format (````markdown)
- [ ] No dual-attribute format (path + template-path attributes)
- [ ] No "path (template_path)" reference format
- [ ] No four-tick escaping (`````) for template embedding

## Workflow Structure Validation

### 5. Self-Containment Compliance (ADR-001)

- [ ] Workflow is completely independent and executable
- [ ] No cross-dependencies on other workflows
- [ ] All essential content embedded directly
- [ ] Clear objective and scope sections

### 6. Standard Section Organization

- [ ] Proper front matter with metadata (id, status, priority, etc.)
- [ ] Clear objective statement
- [ ] Defined scope of work with deliverables
- [ ] Implementation plan with steps
- [ ] Acceptance criteria section

### 7. Template Reference Consistency

- [ ] Template paths are consistent with actual template file locations
- [ ] No broken or invalid template references
- [ ] Template content matches source template files (if applicable)

## Content Quality Validation

### 8. Documentation Standards

- [ ] Proper markdown formatting
- [ ] Clear and descriptive content
- [ ] No orphaned or incomplete sections
- [ ] Consistent language and terminology

### 9. Technical Accuracy

- [ ] Command examples are valid and executable
- [ ] File paths and references are correct
- [ ] Code blocks use proper syntax highlighting

## Validation Actions

### Quick Checks

1. **XML Template Search**: `grep -r "<templates>" .ace/handbook/workflow-instructions/`
2. **Deprecated Format Search**: `grep -r "````markdown" .ace/handbook/workflow-instructions/`
3. **Template Path Validation**: Check all paths start with `.ace/handbook/templates/` and end with `.template.md`
4. **Position Check**: Verify templates are at document end

### Comprehensive Review

1. Parse each workflow file for XML template sections
2. Validate template positioning and structure
3. Check for deprecated formats
4. Verify workflow self-containment
5. Document compliance issues and required fixes

## Compliance Scoring

### Critical Issues (Must Fix)

- Invalid XML template structure
- Templates not at document end
- Use of deprecated formats
- Broken workflow self-containment

### Minor Issues (Should Fix)

- Inconsistent path formatting
- Missing section organization
- Documentation quality issues

### Recommendations (Nice to Have)

- Enhanced content clarity
- Additional examples or context
- Improved formatting consistency
