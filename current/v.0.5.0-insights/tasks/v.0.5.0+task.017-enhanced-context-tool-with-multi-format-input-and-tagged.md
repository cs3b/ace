---
id: v.0.5.0+task.017
status: completed
priority: high
estimate: 8h
dependencies: []
---

# Enhanced Context Tool with Multi-Format Input and Tagged YAML Support

## Behavioral Specification

### User Experience
- **Input**: Users provide context definitions via file paths or strings in multiple formats (pure YAML, agent markdown with embedded YAML, instruction markdown with embedded YAML)
- **Process**: The tool auto-detects the input format, extracts YAML configuration from tagged blocks (`<context-tool-config>`), processes the context template, and optionally embeds the result back into the source document
- **Output**: Either standalone processed context or the full document with embedded processed context, based on the `embed_document_source` option in YAML

### Expected Behavior
The context tool should accept a single positional parameter (like `llm-query`) that can be a file path or string. It should automatically detect whether the input is:
- Pure YAML file (`.yml` or `.yaml` extension)
- Agent markdown file (`.ag.md` extension with `<context-tool-config>` blocks)
- Instruction markdown file (`.md` extension with `<context-tool-config>` blocks)

The tool extracts YAML from `<context-tool-config>` tagged blocks in markdown files, preventing confusion with other YAML blocks in documentation. When the extracted YAML contains `embed_document_source: true`, the tool returns the full document with the processed context embedded; otherwise, it returns just the extracted context.

### Interface Contract

```bash
# CLI Interface - Positional parameter (auto-detect format)
context docs/context/project.md              # Markdown with <context-tool-config>
context .claude/agents/task-finder.ag.md     # Agent file
context template.yml                         # Pure YAML

# Backward compatible flags (existing behavior preserved)
context --preset project
context --yaml template.yml
context --from-agent agent.md
context --output result.md

# Expected outputs
# When embed_document_source: false or absent
<processed context only>

# When embed_document_source: true
<full document with embedded processed context>
```

**Error Handling:**
- [File not found]: Display error "File not found: <path>" with suggestion to check path
- [Invalid YAML]: Display parse error with line number and suggestion to validate YAML
- [No context-tool-config block]: Display "No <context-tool-config> block found in markdown file"
- [Invalid format]: Display "Unable to detect input format. Supported: .yml, .yaml, .md, .ag.md"

**Edge Cases:**
- [Multiple context-tool-config blocks]: Use the first block found and warn about others
- [Empty YAML block]: Display error "Empty YAML configuration in <context-tool-config> block"
- [Nested tags]: Tags cannot be nested; display error if detected

### Success Criteria
- [ ] **Format Auto-detection**: Tool correctly identifies input format from file extension and content
- [ ] **Tagged Block Extraction**: YAML is extracted only from `<context-tool-config>` blocks, ignoring other YAML
- [ ] **Document Embedding**: When `embed_document_source: true`, full document is returned with embedded content
- [ ] **Backward Compatibility**: All existing flags (--preset, --yaml, --from-agent) continue to work
- [ ] **Agent File Support**: All 6 existing agent files work with updated `<context-tool-config>` format

### Validation Questions
- [ ] **Tag Format**: Should we support shorthand like `<ctc>` in addition to `<context-tool-config>`?
- [ ] **Multiple Blocks**: If multiple `<context-tool-config>` blocks exist, should we merge them or use first only?
- [ ] **Embedding Marker**: When embedding back, should we preserve the original YAML or replace with processed content?
- [ ] **Migration Path**: Should we auto-convert old `## Context Definition` format or require manual update?

## Objective

Enable the context tool to seamlessly work with multiple input formats using unambiguous `<context-tool-config>` tags, making it more intuitive to load context from various sources while maintaining backward compatibility with existing usage patterns.

## Scope of Work

- Add positional parameter support to context CLI command for intuitive usage
- Implement auto-detection of input formats (YAML, agent markdown, instruction markdown)
- Create `<context-tool-config>` tag-based YAML extraction for unambiguous parsing
- Support `embed_document_source` option for returning full documents with embedded content
- Update all 6 existing agent files to use new `<context-tool-config>` format
- Create example markdown context files in `docs/context/` directory
- Maintain full backward compatibility with existing flags and usage patterns

### Deliverables

#### Create

- `lib/coding_agent_tools/molecules/context/input_format_detector.rb` - Format detection logic
- `lib/coding_agent_tools/molecules/context/markdown_yaml_extractor.rb` - Enhanced YAML extraction
- `lib/coding_agent_tools/molecules/context/document_embedder.rb` - Document embedding functionality
- `docs/context/project.md` - Project context with `<context-tool-config>` block
- `docs/context/dev-tools.md` - Dev-tools context with tagged YAML
- `docs/context/dev-handbook.md` - Handbook context with tagged YAML
- Test files for new molecules

#### Modify

- `lib/coding_agent_tools/cli/commands/context.rb` - Add positional argument support
- `lib/coding_agent_tools/atoms/context/template_parser.rb` - Support new extraction patterns
- `lib/coding_agent_tools/organisms/context_loader.rb` - Integrate new format support
- `dev-handbook/.integrations/claude/agents/task-finder.ag.md` - Add `<context-tool-config>` tags
- `dev-handbook/.integrations/claude/agents/task-creator.ag.md` - Add `<context-tool-config>` tags
- `dev-handbook/.integrations/claude/agents/create-path.ag.md` - Add `<context-tool-config>` tags
- `dev-handbook/.integrations/claude/agents/lint-files.ag.md` - Add `<context-tool-config>` tags
- `dev-handbook/.integrations/claude/agents/search.ag.md` - Add `<context-tool-config>` tags
- `dev-handbook/.integrations/claude/agents/release-navigator.ag.md` - Add `<context-tool-config>` tags

#### Delete

- None (maintaining backward compatibility)

## Phases

1. **Agent File Updates** - Add `<context-tool-config>` tags to existing agent files
2. **Core Implementation** - Create new molecules for format detection and extraction
3. **CLI Enhancement** - Add positional parameter support
4. **Documentation** - Create example context files with new format
5. **Testing** - Comprehensive test coverage for all new functionality

## Technical Approach

### Architecture Pattern
- [ ] **ATOM Architecture**: Following existing pattern with new Molecules for specific behaviors
- [ ] **Integration**: New molecules integrate with existing ContextLoader organism
- [ ] **Separation of Concerns**: Each molecule handles one responsibility (detection, extraction, embedding)

### Technology Stack
- [ ] **Ruby Standard Library**: Using built-in pattern matching and string manipulation
- [ ] **Existing dry-cli**: Leveraging argument support for positional parameters
- [ ] **No new dependencies**: Implementation uses existing gems and patterns
- [ ] **Security**: Path validation already handled by existing molecules

### Implementation Strategy
- [ ] **Incremental Enhancement**: Add new functionality without breaking existing behavior
- [ ] **Feature Flags**: New positional parameter takes precedence but falls back to flags
- [ ] **Backward Compatibility**: All existing usage patterns continue to work
- [ ] **Test-Driven**: Write tests for each new molecule before implementation

## Tool Selection

Not applicable - using existing tools and libraries already in the codebase.

### Dependencies
- No new dependencies required - implementation uses existing gems:
  - dry-cli (already used for CLI commands)
  - YAML (Ruby standard library)
  - File/pathname utilities (Ruby standard library)

## File Modifications

### Create
- `lib/coding_agent_tools/molecules/context/input_format_detector.rb`
  - Purpose: Detect input format from file extension and content
  - Key components: `detect_format(input)`, `is_markdown?`, `has_context_config_tag?`
  - Dependencies: File, Pathname from Ruby stdlib

- `lib/coding_agent_tools/molecules/context/markdown_yaml_extractor.rb`
  - Purpose: Extract YAML from `<context-tool-config>` tagged blocks
  - Key components: `extract_yaml(content)`, `find_config_blocks`, `parse_yaml_block`
  - Dependencies: YAML parser, existing TemplateParser atom

- `lib/coding_agent_tools/molecules/context/document_embedder.rb`
  - Purpose: Embed processed context back into source document
  - Key components: `embed_content(document, processed_content)`, `replace_config_block`
  - Dependencies: String manipulation utilities

- `docs/context/project.md`
  - Purpose: Example project context with instructions and `<context-tool-config>` block
  - Key components: Instructions, tagged YAML block with `embed_document_source` option
  - Dependencies: None

### Modify
- `lib/coding_agent_tools/cli/commands/context.rb`
  - Changes: Add `argument :input` for positional parameter, update call method logic
  - Impact: Enables positional parameter usage while maintaining backward compatibility
  - Integration points: Calls new format detector, falls back to existing flag logic

- `lib/coding_agent_tools/atoms/context/template_parser.rb`
  - Changes: Add `parse_markdown_with_tags` method for new extraction pattern
  - Impact: Supports both old `## Context Definition` and new `<context-tool-config>` formats
  - Integration points: Called by ContextLoader and new extractors

- Agent files (6 files in `dev-handbook/.integrations/claude/agents/`)
  - Changes: Wrap existing YAML blocks with `<context-tool-config>` tags
  - Impact: Makes YAML extraction unambiguous, prevents conflicts
  - Integration points: Used by context tool when processing agent files

### Delete
- None (maintaining backward compatibility)

## Implementation Plan

### Planning Steps

- [ ] **System Analysis**: Analyze current context tool implementation and CLI structure
  > TEST: Understanding Check
  > Type: Pre-condition Check  
  > Assert: Current ContextLoader, TemplateParser, and CLI command structure understood
  > Command: rspec spec/lib/coding_agent_tools/cli/commands/context_spec.rb
  
- [ ] **Format Detection Design**: Design logic for detecting YAML vs Markdown formats
  > TEST: Design Validation
  > Type: Design Review
  > Assert: Detection logic handles all specified formats correctly
  > Command: ruby -e "puts File.extname('test.ag.md')"
  
- [ ] **Extraction Pattern Analysis**: Analyze how to extract YAML from `<context-tool-config>` blocks
- [ ] **Embedding Strategy**: Design approach for embedding processed content back into documents
- [ ] **Backward Compatibility Check**: Verify all existing usage patterns will continue working

### Execution Steps

- [ ] **Update Agent Files**: Add `<context-tool-config>` tags to 6 agent files
  > TEST: Agent File Validation
  > Type: Format Check
  > Assert: All agent files have properly formatted `<context-tool-config>` blocks
  > Command: grep -l "<context-tool-config>" dev-handbook/.integrations/claude/agents/*.ag.md | wc -l
  
- [ ] **Create InputFormatDetector**: Implement format detection molecule
  > TEST: Format Detection Test
  > Type: Unit Test
  > Assert: Correctly identifies YAML, agent markdown, and instruction markdown
  > Command: rspec spec/lib/coding_agent_tools/molecules/context/input_format_detector_spec.rb
  
- [ ] **Create MarkdownYamlExtractor**: Implement YAML extraction from tagged blocks
  > TEST: Extraction Test
  > Type: Unit Test
  > Assert: Extracts YAML only from `<context-tool-config>` blocks
  > Command: rspec spec/lib/coding_agent_tools/molecules/context/markdown_yaml_extractor_spec.rb
  
- [ ] **Create DocumentEmbedder**: Implement document embedding functionality
  > TEST: Embedding Test
  > Type: Unit Test
  > Assert: Correctly embeds processed content when `embed_document_source: true`
  > Command: rspec spec/lib/coding_agent_tools/molecules/context/document_embedder_spec.rb
  
- [ ] **Update CLI Command**: Add positional argument support to context command
  > TEST: CLI Integration Test
  > Type: Integration Test
  > Assert: Positional parameter works alongside existing flags
  > Command: context docs/context/project.md --debug
  
- [ ] **Create Example Files**: Create markdown context files in `docs/context/`
  > TEST: Example File Test
  > Type: End-to-end Test
  > Assert: Example files work with new context tool
  > Command: context docs/context/project.md && echo "Success"
  
- [ ] **Integration Testing**: Test all combinations of inputs and options
  > TEST: Full Integration Test
  > Type: End-to-End Validation
  > Assert: All usage patterns work correctly
  > Command: bundle exec rspec spec/integration/context_tool_spec.rb

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing context tool functionality
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Comprehensive backward compatibility testing, feature flag approach
  - **Rollback:** Revert CLI changes, existing flags continue to work

- **Risk:** Ambiguous YAML extraction from multiple blocks
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Clear precedence rules (first block wins), warning messages
  - **Rollback:** Fall back to existing extraction methods

### Integration Risks
- **Risk:** Agent files fail with new format
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Test all agent files before deployment, support both formats initially
  - **Monitoring:** Check agent file usage in CI/CD

### Performance Risks
- **Risk:** Slower parsing with tag detection
  - **Mitigation:** Use efficient regex patterns, cache parsed results
  - **Monitoring:** Measure parse time for large documents
  - **Thresholds:** < 100ms for typical markdown files

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] **Format Auto-detection**: Tool correctly identifies all specified input formats
- [ ] **Positional Parameter**: `context <file>` works for YAML and markdown files
- [ ] **Tag-based Extraction**: YAML extracted only from `<context-tool-config>` blocks
- [ ] **Document Embedding**: `embed_document_source: true` returns full document with content
- [ ] **Backward Compatibility**: All existing CLI flags continue to work unchanged

### Implementation Quality Assurance
- [ ] **Agent Files Updated**: All 6 agent files have `<context-tool-config>` tags
- [ ] **Test Coverage**: All new molecules have comprehensive unit tests
- [ ] **Integration Tests**: End-to-end tests cover all usage scenarios
- [ ] **Error Messages**: Clear, helpful error messages for all failure cases

### Documentation and Validation
- [ ] **Example Files Created**: `docs/context/` contains working example files
- [ ] **Migration Guide**: Documentation explains tag format and migration
- [ ] **CLI Help Updated**: Help text reflects new positional parameter usage

## Out of Scope

- ❌ Removing existing `## Context Definition` support (maintaining compatibility)
- ❌ Changing preset configuration format or location
- ❌ Modifying existing context template YAML structure
- ❌ Auto-converting old format to new format (manual migration)

## References

- Current context tool implementation: `dev-tools/lib/coding_agent_tools/cli/commands/context.rb`
- Existing agent files: `dev-handbook/.integrations/claude/agents/*.ag.md`
- ATOM architecture documentation: `docs/architecture-tools.md`
- dry-cli documentation for argument support