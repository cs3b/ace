# Project Context - Enhanced Example

This document demonstrates the new enhanced context tool with multi-format input and tagged YAML support.

## About This Context

This example shows how to use the new `<context-tool-config>` tagged format for context configuration. This format provides:

- **Unambiguous YAML extraction** - No confusion with other YAML blocks in documentation
- **Document embedding support** - Option to embed processed context back into this document
- **Flexible configuration** - Multiple options for organizing context

## Context Configuration

<context-tool-config>
files:
  - docs/what-do-we-build.md
  - docs/architecture.md
  - docs/blueprint.md
  - README.md
  
commands:
  - git-status --short
  - task-manager recent --limit 3
  - release-manager current

format: markdown-xml
embed_document_source: true
</context-tool-config>

## Usage Examples

```bash
# Use this file with the new positional argument
context docs/context/project.md

# The tool will auto-detect the format and process the tagged YAML
# Since embed_document_source: true, the result will be this full document
# with the processed context embedded at the end

# Traditional usage still works
context --yaml old-template.yml
context --preset project
```

## Benefits of the New Format

1. **Clear separation** - Context configuration is clearly marked and separated from documentation
2. **Embedding support** - Processed results can be embedded back into source documents
3. **Auto-detection** - No need to specify format flags, the tool detects automatically
4. **Backward compatible** - All existing usage patterns continue to work

## Notes

When `embed_document_source: true` is set, the context tool will return this entire document with the processed context appended at the end, marked with `<!-- PROCESSED CONTEXT -->`.

This makes it easy to maintain documentation that includes both instructions and current context results.