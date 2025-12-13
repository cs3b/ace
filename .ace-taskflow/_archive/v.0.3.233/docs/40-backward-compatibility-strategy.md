# Task 40: Backward Compatibility Strategy

## Overview

This document outlines the strategy for maintaining backward compatibility during the migration from `<templates>` to `<documents>` format, ensuring no disruption to existing workflows.

## Compatibility Requirements

### Support Both Formats Simultaneously

- Sync script must process both `<templates>` and `<documents>` sections
- No breaking changes to existing workflow files during transition
- All existing functionality must remain intact

### Gradual Migration Path

- Workflows can be migrated one at a time
- Mixed environment support (some workflows using old format, others using new)
- Clear validation that migration is successful

## Technical Implementation

### Sync Script Updates

#### Enhanced Parser (`extract_templates()`)

```ruby
def extract_templates(content)
  templates = []
  
  # Extract from new <documents> format
  content.scan(/<documents>(.*?)<\/documents>/m) do |documents_section|
    section_content = documents_section[0]
    
    # Process <template> tags
    section_content.scan(/<template\s+path="([^"]+)">(.*?)<\/template>/m) do |path, template_content|
      templates << {
        path: path,
        content: template_content,
        type: :template
      }
    end
    
    # Process <guide> tags
    section_content.scan(/<guide\s+path="([^"]+)">(.*?)<\/guide>/m) do |path, guide_content|
      templates << {
        path: path,
        content: guide_content,
        type: :guide
      }
    end
  end
  
  # Extract from legacy <templates> format (backward compatibility)
  content.scan(/<templates>(.*?)<\/templates>/m) do |templates_section|
    section_content = templates_section[0]
    
    section_content.scan(/<template\s+path="([^"]+)">(.*?)<\/template>/m) do |path, template_content|
      templates << {
        path: path,
        content: template_content,
        type: :template
      }
    end
  end
  
  templates
end
```

#### Enhanced Validation (`process_template()`)

```ruby
def process_template(template_info, workflow_file_path)
  template_path = template_info[:path]
  document_type = template_info[:type]
  
  # Validate based on document type
  case document_type
  when :template
    validate_template_path(template_path)
  when :guide
    validate_guide_path(template_path)
  else
    return { status: :error, error: "Unknown document type: #{document_type}" }
  end
  
  # Continue with existing processing logic...
end

def validate_template_path(path)
  path.start_with?(".ace/handbook/templates/") && path.end_with?(".template.md")
end

def validate_guide_path(path)
  path.start_with?(".ace/handbook/guides/") && path.end_with?(".g.md")
end
```

#### Enhanced Content Updates

```ruby
def update_embedded_document(workflow_content, document_path, new_content, document_type)
  escaped_path = Regexp.escape(document_path)
  
  # Handle new format
  if document_type == :template
    # Try <documents><template> format first
    pattern = /(<documents>.*?<template\s+path="#{escaped_path}">)(.*?)(<\/template>.*?<\/documents>)/m
    if workflow_content.match(pattern)
      return workflow_content.gsub(pattern) { "#{$1}#{new_content}#{$3}" }
    end
  elsif document_type == :guide
    # Handle <documents><guide> format
    pattern = /(<documents>.*?<guide\s+path="#{escaped_path}">)(.*?)(<\/guide>.*?<\/documents>)/m
    if workflow_content.match(pattern)
      return workflow_content.gsub(pattern) { "#{$1}#{new_content}#{$3}" }
    end
  end
  
  # Fall back to legacy format
  pattern = /(<template\s+path="#{escaped_path}">)(.*?)(<\/template>)/m
  workflow_content.gsub(pattern) { "#{$1}#{new_content}#{$3}" }
end
```

## Migration Strategy

### Phase 1: Extend Sync Script (No Breaking Changes)

1. Add support for `<documents>` format
2. Maintain full backward compatibility with `<templates>`
3. Test with existing workflows to ensure no regressions

### Phase 2: Validate New Format

1. Create test workflow files using `<documents>` format
2. Verify sync script handles both formats correctly
3. Validate content synchronization accuracy

### Phase 3: Gradual Migration

1. Start with workflows that have template duplication
2. Migrate one workflow at a time
3. Validate each migration with `--dry-run` before committing

### Phase 4: Cleanup (Future)

1. After all workflows migrated, remove legacy format support
2. Simplify sync script code
3. Update documentation

## Testing Strategy

### Regression Testing

- Run sync script on all existing workflows before any changes
- Capture baseline behavior and output
- Ensure identical behavior after sync script updates

### New Format Testing

- Create test workflows using `<documents>` format
- Verify correct parsing and synchronization
- Test mixed format scenarios

### Migration Validation

- Compare before/after content for each migrated workflow
- Verify template content remains identical
- Ensure sync script reports no differences

## Risk Mitigation

### Rollback Plan

- Keep sync script changes backward compatible
- Maintain ability to revert individual workflow migrations
- Preserve original template content validation

### Error Handling

- Enhanced error messages for format-specific issues
- Clear distinction between template and guide validation errors
- Graceful handling of malformed XML

### Documentation

- Update sync script help text to mention both formats
- Document migration process for future reference
- Maintain changelog of format changes

## Success Criteria

1. **Zero Regressions**: All existing workflows continue to work exactly as before
2. **New Format Support**: `<documents>` format processes correctly
3. **Mixed Environment**: Workflows using different formats coexist successfully
4. **Migration Path**: Clear, safe process for migrating workflows one by one
5. **Validation**: Comprehensive testing ensures content integrity throughout migration
