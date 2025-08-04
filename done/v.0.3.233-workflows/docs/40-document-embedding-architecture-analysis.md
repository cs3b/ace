# Task 40: Universal Document Embedding Architecture Analysis

## Current State Analysis

### Template Embedding Patterns Found

Based on analysis of dev-handbook/workflow-instructions/*.wf.md files:

**High Duplication:**

- `dev-handbook/templates/release-tasks/task.template.md` - Used 3 times
- `dev-handbook/templates/project-docs/blueprint.template.md` - Used 2 times

**Current XML Structure:**

```xml
<templates>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
        [template content here]
    </template>
</templates>
```

**Path Patterns:**

- All template paths are relative to project root
- Templates are stored in `dev-handbook/templates/` with `.template.md` extension
- Guides are stored in `dev-handbook/guides/` with `.g.md` extension

## Proposed Universal Document Embedding Architecture

### Core Design Principles

1. **Unified Container**: Replace `<templates>` with `<documents>` to support multiple document types
2. **Document Type Semantics**: Use `<guide>` and `<template>` tags to distinguish content types
3. **Consistent Paths**: All paths relative to project root
4. **Backward Compatibility**: Maintain support for existing `<templates>` format during transition

### New XML Structure

```xml
<documents>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
        [template content here]
    </template>
    
    <guide path="dev-handbook/guides/testing.g.md">
        [guide content here]
    </guide>
</documents>
```

### Benefits

1. **Eliminates Duplication**: Each document referenced once in a central location
2. **Supports Multiple Document Types**: Templates, guides, and potentially other types
3. **Maintains Clarity**: Clear semantic distinction between document types
4. **Enables Reuse**: Documents can be referenced across multiple workflows

### Implementation Strategy

1. **Phase 1**: Extend sync script to support `<documents>` format
2. **Phase 2**: Add backward compatibility for existing `<templates>` format
3. **Phase 3**: Migrate workflows one by one to new format
4. **Phase 4**: Validate and remove old format support

## Architectural Decisions Required

### Path Standards

- **Decision**: Always use paths relative to project root
- **Rationale**: Ensures consistency and predictability across all workflows
- **Impact**: Requires updating sync script validation logic

### Document Type Support

- **Decision**: Support `<guide>` and `<template>` tags within `<documents>`
- **Rationale**: Provides semantic clarity and enables different processing if needed
- **Impact**: Sync script needs to handle multiple document types

### Backward Compatibility

- **Decision**: Maintain support for existing `<templates>` format during transition
- **Rationale**: Allows gradual migration without breaking existing workflows
- **Impact**: Sync script must handle both formats simultaneously

## Technical Implementation Notes

### Sync Script Changes Required

1. **Parser Updates**: Modify `extract_templates()` to handle `<documents>` format
2. **Validation Updates**: Update path validation for guides vs templates
3. **Processing Updates**: Handle both `<guide>` and `<template>` tags
4. **Backward Compatibility**: Maintain existing `<templates>` processing

### File Organization Impact

- Templates: `dev-handbook/templates/**/*.template.md`
- Guides: `dev-handbook/guides/**/*.g.md`
- Workflows: `dev-handbook/workflow-instructions/**/*.wf.md`

## Migration Plan

### Priority Order (Based on Duplication)

1. **create-task.wf.md** (uses task.template.md - 3x total)
2. **review-task.wf.md** (uses task.template.md - 3x total)
3. **update-blueprint.wf.md** (uses blueprint.template.md - 2x total)
4. **Remaining 11 workflows** (single-use templates)

### Validation Approach

- Run sync script with `--dry-run` after each migration
- Validate template content matches source files
- Ensure no regressions in existing workflows
