---
id: v.0.9.0+task.078
status: done
priority: medium
estimate: 4-6h
dependencies: []
---

# Add multi-subject configuration for ace-docs

## Behavioral Specification

### User Experience
- **Input**: Document configuration with multiple subject categories (code, config, docs) in YAML frontmatter
- **Process**: ace-docs analyze command processes each subject separately, generating category-specific diff files
- **Output**: Multiple diff files (code.diff, config.diff, docs.diff) integrated into context analysis

### Expected Behavior
Users can define multiple subject configurations in their document frontmatter to categorize and filter different types of changes separately. When running `ace-docs analyze`, the system will:
- Parse multi-subject configuration from document frontmatter
- Generate separate diff files for each subject category
- Include all diff files in the analysis context
- Provide dual-mode analysis separating code changes from documentation/config changes

The system maintains backward compatibility, allowing single-subject configurations to work unchanged.

### Interface Contract

```yaml
# Document frontmatter configuration
ace-docs:
  context:
    files:
      - CHANGELOG.md
  subject:
    - code:
        diff:
          filters:
            - ace-docs/**/*.rb
    - config:
        diff:
          filters:
            - ace-docs/**/*.yml
            - ace-docs/**/*.yaml
    - docs:
        diff:
          filters:
            - ace-docs/**/*.md
            - ace-docs/.ace.example/*.md
```

```bash
# CLI Interface
ace-docs analyze README.md
# Expected output:
# Analyzing document: README.md
# Document type: reference
# Subjects configured:
#   - code: ace-docs/**/*.rb
#   - config: ace-docs/**/*.yml, ace-docs/**/*.yaml
#   - docs: ace-docs/**/*.md, ace-docs/.ace.example/*.md
# Generating diffs for 3 subjects...
# Creating analysis context...
# Analysis complete: .cache/ace-docs/analyze-TIMESTAMP/

# With mode selection (future enhancement)
ace-docs analyze README.md --mode code
ace-docs analyze README.md --mode docs
ace-docs analyze README.md --mode all  # default
```

**Error Handling:**
- Invalid subject configuration: Display clear error message with example configuration
- No changes for subject: Skip diff generation for that subject, continue with others
- Missing filters in subject: Treat as empty filter set, skip that subject

**Edge Cases:**
- Empty subject list: Fall back to default single diff generation
- Mixed old/new format: Support backward compatibility with single subject
- Duplicate subject names: Use last definition or error with clear message

### Success Criteria
- [ ] **Multi-subject parsing**: System correctly parses and validates multi-subject configuration
- [ ] **Separate diff generation**: Each subject generates its own diff file with appropriate naming
- [ ] **Context integration**: All diff files are included in context.md with correct references
- [ ] **Backward compatibility**: Single-subject configurations continue to work unchanged
- [ ] **Dual analysis mode**: Analysis can separate code from docs/config changes
- [ ] **Clear user feedback**: Progress messages show multi-subject processing status

### Validation Questions
- [ ] **Subject naming**: Should subject names be restricted to predefined set (code, config, docs) or allow custom names?
- [ ] **Diff file naming**: Use subject name directly (code.diff) or include prefix (subject-code.diff)?
- [ ] **Empty subjects**: Should subjects with no matching files generate empty diff files or be skipped?
- [ ] **Analysis mode**: Should --mode flag be implemented in initial version or added later?

## Objective

Enable ace-docs to support multiple subject configurations for more granular diff generation and analysis. This allows users to separate different types of changes (code, configuration, documentation) for clearer, more focused analysis. The dual analysis capability will improve signal-to-noise ratio by preventing documentation changes from obscuring important code modifications.

## Scope of Work

- **Configuration Scope**: Support for multi-subject YAML configuration in document frontmatter
- **Diff Generation Scope**: Generate separate diff files for each configured subject
- **Context Integration Scope**: Include all generated diff files in analysis context
- **Analysis Enhancement Scope**: Support dual-mode analysis separating code from docs/config
- **User Experience Scope**: Clear progress feedback for multi-subject processing

### Deliverables

#### Behavioral Specifications
- Multi-subject configuration format specification
- User experience flow for multi-subject analysis
- Error handling and edge case behaviors

#### Validation Artifacts
- Success criteria for multi-subject parsing
- Test scenarios for backward compatibility
- Validation methods for dual analysis mode

## Out of Scope
- ❌ **Implementation Details**: Specific Ruby class structures or method implementations
- ❌ **Technology Decisions**: Choice of YAML parsing libraries or diff generation tools
- ❌ **Performance Optimization**: Specific caching or parallel processing strategies
- ❌ **Future Enhancements**: Web UI, automated subject detection, or machine learning categorization

## References

- Current ace-docs implementation (task.071, task.073)
- ace-context integration patterns
- Proposed dual analysis prompt improvements from user input

## Technical Research

### Architecture Analysis
The current ace-docs implementation uses a single-subject configuration pattern where diff filters are applied globally. The multi-subject feature requires extending this to support a list of subject configurations, each with its own name and filters. The existing ChangeDetector and DocumentAnalysisPrompt classes will need modification to handle multiple diffs.

### Implementation Approach
1. **Backward-compatible parsing**: Support both single object and array formats for subject configuration
2. **Named subject pattern**: Each subject is a hash with a single key (the name) containing diff configuration
3. **Separate diff generation**: Iterate through subjects and generate individual diff files
4. **Context aggregation**: Include all diff files in the context.md files array

### Technical Considerations
- YAML parsing already handles nested structures via the frontmatter gem
- Git diff command supports multiple path filters which maps well to subject filters
- ace-context already supports multiple files in the files array
- File naming convention should be simple and predictable (subject_name.diff)

## Implementation Plan

### Planning Steps

* [ ] Research current subject configuration parsing in Document model
* [ ] Analyze ChangeDetector diff generation flow for multi-subject support
* [ ] Review DocumentAnalysisPrompt context creation for multiple diff files
* [ ] Investigate ace-context file loading behavior with multiple diff files
* [ ] Design backward-compatible configuration format
* [ ] Plan test coverage for multi-subject scenarios

### Execution Steps

#### Phase 1: Core Multi-Subject Support

- [ ] Update Document model (`lib/ace/docs/models/document.rb`)
  - Modify `subject_diff_filters` to detect array vs object format
  - Add `subject_configurations` method to return structured subject data
  - Ensure backward compatibility with single subject format
  > TEST: Configuration Parsing
  > Type: Unit Test
  > Assert: Both single and multi-subject formats parse correctly
  > Command: # ace-test ace-docs/test/models/document_test.rb

- [ ] Enhance ChangeDetector (`lib/ace/docs/molecules/change_detector.rb`)
  - Add `get_diffs_for_subjects` method for multi-subject handling
  - Modify `get_diff_for_document` to delegate to new method when multiple subjects
  - Return hash of {subject_name => diff_content} for multiple subjects
  > TEST: Multi-Diff Generation
  > Type: Integration Test
  > Assert: Multiple diff files generated with correct content
  > Command: # ace-test ace-docs/test/molecules/change_detector_test.rb

- [ ] Update DocumentAnalysisPrompt (`lib/ace/docs/prompts/document_analysis_prompt.rb`)
  - Modify `build` method to handle multiple diff files
  - Save each diff with subject name (e.g., code.diff, config.diff)
  - Fix relative path issue: Use "subject_name.diff" not absolute paths
  - Update `create_context_markdown` to accept array of diff files
  > TEST: Context Integration
  > Type: Integration Test
  > Assert: All diff files included in context.md with relative paths
  > Command: # ace-test ace-docs/test/prompts/document_analysis_prompt_test.rb

#### Phase 2: Command & Display Updates

- [ ] Update AnalyzeCommand (`lib/ace/docs/commands/analyze_command.rb`)
  - Enhance subject display to show multiple configurations
  - Update progress messages for multi-subject processing
  - Ensure session directory contains all diff files
  > TEST: Command Execution
  > Type: End-to-End Test
  > Assert: Command displays correct progress and generates all files
  > Command: # ace-docs analyze test-doc.md --dry-run

- [ ] Create configuration examples (`.ace.example/docs/`)
  - Add multi-subject example to config.yml comments
  - Create sample document with multi-subject configuration
  - Document both single and multi-subject formats

#### Phase 3: Improved Analysis Prompts

- [ ] Create dual-mode system prompt (`lib/ace/docs/prompts/templates/ace-change-analyzer.system.md`)
  - Separate code analysis from documentation/config analysis sections
  - Include self-check mechanisms for coverage tracking
  - Support HIGH/MEDIUM/LOW prioritization

- [ ] Create user prompt template (`lib/ace/docs/prompts/templates/ace-change-analyzer.user.md`)
  - Specify analysis mode instructions
  - Include coverage tracking requirements
  - Provide clear output structure expectations

- [ ] Add prompt selection logic (`lib/ace/docs/prompts/document_analysis_prompt.rb`)
  - Detect multi-subject configuration
  - Select appropriate prompts based on subject types
  - Support for future --mode option

#### Phase 4: Testing & Documentation

- [ ] Add comprehensive tests
  - Unit tests for Document model multi-subject parsing
  - Integration tests for ChangeDetector multi-diff generation
  - End-to-end tests for complete multi-subject flow
  - Backward compatibility tests

- [ ] Update documentation
  - Update README.md with multi-subject examples
  - Add CHANGELOG.md entry for new feature
  - Create migration guide for existing configurations

- [ ] Validate implementation
  - Test with real ace-docs README.md using multi-subject config
  - Verify backward compatibility with existing single-subject docs
  - Ensure all diff files are properly generated and referenced
  > TEST: Full Integration
  > Type: Manual Validation
  > Assert: Multi-subject analysis works end-to-end
  > Command: # ace-docs analyze README.md && ls .cache/ace-docs/analyze-*/

## Test Case Planning

### Unit Tests
- Document model correctly parses single subject (backward compatibility)
- Document model correctly parses multi-subject array format
- Document model handles invalid subject configurations gracefully
- ChangeDetector generates correct diff for single subject
- ChangeDetector generates multiple diffs for multi-subject

### Integration Tests
- Multi-subject diffs are saved with correct names
- Context.md includes all diff files with relative paths
- Backward compatibility maintained for single-subject documents
- Empty subjects are handled appropriately (skipped or empty file)

### End-to-End Tests
- Complete multi-subject analysis flow from command to output
- Progress messages correctly show multi-subject processing
- Session directory contains all expected files
- Analysis results properly incorporate all subjects

## Risk Analysis

**Technical Risks:**
- Breaking backward compatibility with existing documents
- ace-context may have issues with multiple diff files
- Performance impact of generating multiple diffs

**Mitigation Strategies:**
- Extensive backward compatibility testing
- Fallback to single diff if multi-subject fails
- Parallel diff generation for performance (future optimization)

**Rollback Strategy:**
- Feature flag to disable multi-subject support
- Revert to previous Document model parsing logic
- Clear error messages guiding users to single-subject format