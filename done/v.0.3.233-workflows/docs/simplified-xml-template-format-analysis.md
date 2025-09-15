# Simplified XML Template Format Analysis

## Overview

Analysis of the simplified XML template embedding format used in workflow instruction files after migration from dual-attribute system to single-attribute system.

## Current Format Structure

### XML Template Section Format

```xml
<templates>
    <template path=".ace/handbook/templates/category/file.template.md">
[Template content embedded directly here]
    </template>
    
    <template path=".ace/handbook/templates/another/file.template.md">
[Another template content]
    </template>
</templates>
```

### Key Characteristics

1. **Single Attribute**: Only `path` attribute pointing to source template file
2. **XML Container**: All templates wrapped in `<templates>` section
3. **Direct Embedding**: Template content embedded directly within `<template>` tags
4. **End-of-Document**: All templates placed at the end of workflow files

## Simplified Attribute Structure

### Before (Dual-Attribute)

```xml
<template path="target-location" template-path="source-template-file">
```

### After (Single-Attribute)

```xml
<template path="source-template-file">
```

**Rationale for Change:**

- Eliminates redundancy (target path was not used by automation)
- Simplifies parsing logic (only one path to extract)
- Focuses on template source as primary identifier
- Reduces XML complexity and potential for attribute mismatches

## Template Path Patterns

### Standard Paths

- `.ace/handbook/templates/project-docs/decisions/adr.template.md` - ADR templates
- `.ace/handbook/templates/release-tasks/task.template.md` - Task templates  
- `.ace/handbook/templates/user-docs/user-guide.template.md` - User documentation
- `.ace/handbook/templates/code-docs/ruby-yard.template.md` - API documentation

### Variable Support

- `{current-release-path}` - Supported in paths for dynamic release directories
- Other variables can be added as needed for template flexibility

## XML Parsing Considerations

### Regex Patterns for Script Development

**Find all template sections:**

```regex
<templates>[\s\S]*?</templates>
```

**Extract individual templates:**

```regex
<template\s+path="([^"]+)">([\s\S]*?)</template>
```

**Capture groups:**

- Group 1: Template file path
- Group 2: Template content

**Validate template format:**

```regex
<template\s+path=".ace/handbook/templates/[^"]+\.template\.md">
```

### XML Structure Requirements

1. **Well-formed XML**: Must parse as valid XML
2. **Single path attribute**: Exactly one `path` attribute per template
3. **Template file extension**: Path must end with `.template.md`
4. **Template directory**: Path must start with `.ace/handbook/templates/`

## Content Synchronization Algorithm

### Detection Strategy

1. Parse XML `<templates>` sections from workflow files
2. Extract `path` attribute from each `<template>` tag
3. Read actual template file from filesystem using path
4. Compare embedded content with file content
5. Identify differences requiring synchronization

### Update Strategy

1. Replace embedded content between `<template>` tags
2. Preserve XML structure and path attribute
3. Maintain content formatting and indentation
4. Handle UTF-8 encoding consistently

### Error Handling

- Missing template files: Report path and suggest creation
- Invalid XML: Report parsing errors with line numbers  
- Path validation: Ensure paths follow template directory conventions
- Content encoding: Handle special characters and line endings

## Examples from Current Implementation

### ADR Template (create-adr.wf.md)

```xml
<templates>
    <template path=".ace/handbook/templates/project-docs/decisions/adr.template.md">
# ADR-XXX: Title of the Decision

## Status
[Proposed | Accepted | Deprecated | Superseded]
Date: YYYY-MM-DD

## Context
[Context content...]
    </template>
</templates>
```

### Task Template (create-task.wf.md)

```xml
<templates>
    <template path=".ace/handbook/templates/release-tasks/task.template.md">
---
id: v.X.Y.Z+task.NN
status: pending
priority: [high | medium | low]
estimate: Nh
dependencies: []
---

# Task Title
[Task content...]
    </template>
</templates>
```

## Automation Benefits

### Simplified Parsing

- Single path extraction per template
- No need to handle path/template-path mapping
- Cleaner XML structure for parsing libraries

### Consistent Source Reference

- Template file path is the single source of truth
- No ambiguity about which path to use for file operations
- Direct mapping from XML to filesystem

### Reduced Complexity

- Fewer attributes to validate
- Simpler error messages
- Less prone to configuration errors

## Script Implementation Requirements

### Core Functions Needed

1. **XML Parser**: Extract `<templates>` sections and individual templates
2. **Path Extractor**: Get template file paths from `path` attributes  
3. **Content Comparator**: Compare embedded vs file content
4. **Content Updater**: Replace embedded content while preserving XML structure
5. **File Operations**: Read template files, write updated workflow files

### Command-line Interface

- `--dry-run`: Show what would be changed without making changes
- `--verbose`: Detailed output of operations
- `--path`: Specify directory to scan (default: workflow-instructions)
- `--commit`: Automatically commit changes after sync

### Output Requirements

- Summary of files processed
- List of templates synchronized
- Count of changes made
- Error reporting for invalid XML or missing files

## Next Steps for Implementation

1. **Create main sync script** with XML parsing capabilities
2. **Implement template comparison logic** using simplified path structure
3. **Add command-line interface** with appropriate options
4. **Create wrapper scripts** following project patterns
5. **Test with current simplified XML format** to ensure compatibility

This simplified format provides the foundation for robust automated template synchronization while reducing complexity and potential for errors.
