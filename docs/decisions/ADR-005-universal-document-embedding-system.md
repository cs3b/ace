# ADR-005: Universal Document Embedding System

## Status

Accepted

## Context

The current document embedding system in workflow instructions is limited to templates only, using `<templates>` containers. This creates several issues:

1. **Limited Scope**: Only templates are supported, not guides or other document types
2. **Template Duplication**: Analysis shows `task.template.md` is embedded 3 times and `blueprint.template.md` is embedded 2 times across workflows
3. **Single Document Type**: Cannot embed guides alongside templates in the same workflow
4. **Semantic Ambiguity**: `<templates>` doesn't distinguish between different document types

Current structure:

```xml
<templates>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
        [template content]
    </template>
</templates>
```

## Decision

We will implement a Universal Document Embedding System that supports multiple document types within a unified container structure.

### New Architecture

#### Universal Container Format

```xml
<documents>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
        [template content]
    </template>
    
    <guide path="dev-handbook/guides/testing.g.md">
        [guide content]
    </guide>
</documents>
```

#### Supported Document Types

1. **Templates** (`<template>` tags)
   - Path pattern: `dev-handbook/templates/**/*.template.md`
   - Purpose: Reusable template content for document creation
   - Validation: Must exist in templates directory

2. **Guides** (`<guide>` tags)
   - Path pattern: `dev-handbook/guides/**/*.g.md`
   - Purpose: Reference documentation and best practices
   - Validation: Must exist in guides directory

#### Semantic Structure

- **Container**: `<documents>` - Universal container for all document types
- **Document Types**: `<template>`, `<guide>` - Semantic tags for different content types
- **Path Attribute**: `path="relative/path/to/document"` - Consistent path reference
- **Content**: Embedded document content synchronized with source files

### Implementation Strategy

#### Phase 1: Extend Sync Script

1. Add support for `<documents>` container parsing
2. Implement `<guide>` tag processing alongside existing `<template>` support
3. Maintain backward compatibility with `<templates>` format

#### Phase 2: Gradual Migration

1. Migrate workflows with duplicate template references first
2. Convert workflows one by one to new format
3. Validate content integrity after each migration

#### Phase 3: Enhanced Features

1. Support for additional document types if needed
2. Cross-reference validation between documents
3. Dependency tracking between embedded documents

### Backward Compatibility

The system will maintain full backward compatibility during transition:

1. **Dual Format Support**: Sync script processes both `<templates>` and `<documents>` formats
2. **Gradual Migration**: Workflows can be migrated individually
3. **No Breaking Changes**: Existing workflows continue to function unchanged
4. **Validation**: Comprehensive testing ensures content integrity

## Consequences

### Positive

1. **Eliminates Duplication**: Each document referenced once, reducing maintenance burden
2. **Multi-Document Support**: Templates and guides can be embedded in same workflow
3. **Semantic Clarity**: Clear distinction between document types
4. **Extensibility**: Easy to add new document types in the future
5. **Consistency**: Unified approach to document embedding across all workflows

### Negative

1. **Migration Complexity**: Requires careful migration of 14 workflow files
2. **Sync Script Changes**: Significant updates to parsing and processing logic
3. **Dual Format Support**: Temporary complexity supporting both old and new formats
4. **Learning Curve**: Developers need to learn new format structure

### Neutral

1. **Implementation Effort**: Substantial but manageable development work
2. **Testing Requirements**: Comprehensive testing needed for both formats
3. **Documentation Updates**: Need to update guidelines and examples

## Alternatives Considered

### Alternative 1: Extend Current <templates> Format

- **Pros**: Minimal changes to existing structure
- **Cons**: Semantic confusion, doesn't solve duplication problem

### Alternative 2: Separate Containers (<templates> + <guides>)

- **Pros**: Clear separation of concerns
- **Cons**: More complex parsing, doesn't create unified system

### Alternative 3: Attribute-Based Document Types

```xml
<documents>
    <document type="template" path="...">content</document>
    <document type="guide" path="...">content</document>
</documents>
```

- **Pros**: Unified document tag
- **Cons**: Less semantic clarity, attribute-based typing is less explicit

## Implementation Details

### Sync Script Updates

#### Enhanced Parser

```ruby
def extract_documents(content)
  documents = []
  
  # Extract from <documents> format
  content.scan(/<documents>(.*?)<\/documents>/m) do |documents_section|
    section_content = documents_section[0]
    
    # Extract templates
    section_content.scan(/<template\s+path="([^"]+)">(.*?)<\/template>/m) do |path, content|
      documents << { path: path, content: content, type: :template }
    end
    
    # Extract guides
    section_content.scan(/<guide\s+path="([^"]+)">(.*?)<\/guide>/m) do |path, content|
      documents << { path: path, content: content, type: :guide }
    end
  end
  
  # Maintain backward compatibility with <templates>
  content.scan(/<templates>(.*?)<\/templates>/m) do |templates_section|
    section_content = templates_section[0]
    section_content.scan(/<template\s+path="([^"]+)">(.*?)<\/template>/m) do |path, content|
      documents << { path: path, content: content, type: :template }
    end
  end
  
  documents
end
```

### Migration Priority

1. **High Priority** (Duplicate Templates):
   - `draft-task.wf.md` (task.template.md)
   - `plan-task.wf.md` (task.template.md)  
   - `update-blueprint.wf.md` (blueprint.template.md)

2. **Medium Priority** (Single-Use Templates):
   - Remaining 11 workflow files

### Validation Strategy

1. **Content Integrity**: Verify embedded content matches source files
2. **Format Validation**: Ensure XML structure is well-formed
3. **Path Validation**: Confirm all referenced documents exist
4. **Sync Testing**: Validate synchronization works correctly

## Success Metrics

1. **Zero Duplication**: Each template/guide referenced exactly once
2. **Format Consistency**: All workflows use `<documents>` format
3. **Content Integrity**: No content differences after migration
4. **Backward Compatibility**: Existing workflows function during transition
5. **Sync Accuracy**: 100% synchronization success rate

## References

- [ADR-002: XML Template Embedding Architecture](./ADR-002-xml-template-embedding-architecture.md)
- [ADR-003: Template Directory Separation](./ADR-003-template-directory-separation.md)
- [ADR-004: Consistent Path Standards](./ADR-004-consistent-path-standards.md)
- Task 40: Implement Universal Document Embedding System
