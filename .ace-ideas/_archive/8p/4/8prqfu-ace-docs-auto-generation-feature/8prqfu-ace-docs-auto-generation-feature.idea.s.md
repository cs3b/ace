---
status: done
completed_at: 2025-10-15 01:18:10.000000000 +01:00
id: 8prqfu
title: ace-docs Auto-Generation Feature
tags: []
created_at: '2006-01-03 03:21:06'
---

# ace-docs Auto-Generation Feature

## Description

Implement auto-generation capabilities in ace-docs to dynamically create and update document sections based on code analysis and project metadata. This feature would automatically generate tool tables from gemspecs, decision summaries from ADRs, API documentation from routes, and other dynamic content.

## Motivation

Documentation often contains sections that directly reflect the codebase structure, such as:
- Tool lists that mirror installed gems
- Decision logs derived from ADR files
- API endpoint documentation from route definitions
- Component inventories from module structures

Manually maintaining these sections leads to inconsistencies and outdated information. Auto-generation would ensure these sections always reflect the current state of the code.

## Proposed Implementation

### Core Components

1. **Generation Engine**
   - `lib/ace/docs/organisms/generator.rb` - Main orchestrator for auto-generation
   - `lib/ace/docs/molecules/section_generator.rb` - Generates individual sections
   - `lib/ace/docs/atoms/content_extractor.rb` - Extracts data from source files

2. **Generator Types**
   ```ruby
   # lib/ace/docs/generators/
   ├── gemspec_generator.rb    # Generate tool tables from gemspecs
   ├── adr_generator.rb         # Generate decision summaries from ADRs
   ├── route_generator.rb       # Generate API docs from routes
   ├── module_generator.rb      # Generate component lists from modules
   └── changelog_generator.rb   # Generate changelog summaries
   ```

3. **Configuration**
   ```yaml
   # In document frontmatter
   rules:
     auto-generate:
       - tools-table:
           from: gemspecs
           pattern: "*/**.gemspec"
           format: markdown-table
       - decisions:
           from: adrs
           path: "docs/decisions/*.md"
           summarize: true
       - api-endpoints:
           from: routes
           source: "config/routes.rb"
           group-by: resource
   ```

### Integration Points

1. **With ace-docs commands**
   - `ace-docs generate FILE` - Regenerate sections in specific document
   - `ace-docs generate --all` - Regenerate all auto-generated sections
   - `--dry-run` flag to preview changes

2. **With validation**
   - Validate that auto-generated sections haven't been manually modified
   - Warn if source files are missing or changed

3. **With diff analysis**
   - Detect when source files change and flag documents for regeneration
   - Include regeneration suggestions in diff reports

### Document Markers

Use special markers to denote auto-generated sections:

```markdown
<!-- BEGIN AUTO-GENERATED: tools-table -->
| Gem | Version | Description |
|-----|---------|-------------|
| ace-docs | 0.1.0 | Documentation management |
| ace-context | 0.1.0 | Context loading |
<!-- END AUTO-GENERATED: tools-table -->
```

### Example Use Cases

1. **Tool Documentation**
   ```ruby
   # Reads all gemspecs in project
   # Generates markdown table with gem names, versions, descriptions
   # Updates tools.md document automatically
   ```

2. **ADR Summary**
   ```ruby
   # Scans ADR directory
   # Extracts titles, statuses, and dates
   # Creates decision log with links
   ```

3. **API Reference**
   ```ruby
   # Parses Rails routes or Sinatra endpoints
   # Groups by resource/controller
   # Generates endpoint documentation with parameters
   ```

## Benefits

- **Consistency**: Generated content always matches source of truth
- **Efficiency**: No manual updates for structural documentation
- **Accuracy**: Eliminates human error in listing components
- **Freshness**: Documentation automatically reflects latest changes
- **Traceability**: Clear markers show what's generated vs manual

## Implementation Priority

1. Start with gemspec → tool table generation (most common use case)
2. Add ADR summarization (high value for decision tracking)
3. Implement route/API generation (framework-specific)
4. Extend to custom generators via plugin system

## Future Enhancements

- **Template System**: User-defined templates for generated content
- **Smart Regeneration**: Only update changed sections
- **Cross-Reference Generation**: Auto-link between related documents
- **Dependency Graphs**: Visual representations of gem/module dependencies
- **Version Comparison**: Show what changed between versions

## Technical Considerations

- Use AST parsing for Ruby code analysis
- Cache parsed results for performance
- Support incremental generation for large projects
- Provide hooks for custom generators
- Ensure generated content is deterministic and reproducible

## Related Ideas

- Integration with ace-llm-query for intelligent summarization
- Connection to ace-taskflow for task documentation generation
- Coordination with ace-context for loading source files