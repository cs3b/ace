---
id: v.0.9.0+task.063
status: pending
priority: high
estimate: 8-12h
dependencies: []
---

# Create ace-docs package for generic documentation management

## Behavioral Specification

### User Experience
- **Input**: Markdown documents with self-describing frontmatter, commands for status checks, diff analysis, and document updates
- **Process**: Automatic detection of managed documents, intelligent change analysis, metadata tracking, validation against rules
- **Output**: Documentation status reports, change summaries, updated documents with current frontmatter, validation results

### Expected Behavior

The ace-docs tool provides a universal documentation management system that works with any markdown document through self-describing frontmatter. Each document declares its purpose, update triggers, and context requirements, making the system infinitely extensible.

Key behaviors:
- Auto-discovers all markdown files with ace-docs frontmatter
- Tracks document freshness based on configured update frequencies
- Analyzes repository changes relevant to each document's declared sources
- Provides intelligent change summaries using LLM analysis
- Updates frontmatter metadata (dates, versions, etc.)
- Validates documents against their declared rules (max-lines, required sections, no-duplicates)
- Supports auto-generation of sections from code (tools from gemspecs, decisions from ADRs)

### Interface Contract

```bash
# CLI Interface
ace-docs                                    # Show status of all managed documents
ace-docs status [--type TYPE] [--needs-update]  # Filtered status views

ace-docs diff [FILE|--preset PRESET|--needs-update] [--since DATE]
# Generates change analysis saved to .cache/ace-docs/diff-{timestamp}.md

ace-docs update FILE --set KEY=VALUE       # Update document frontmatter
ace-docs update --preset PRESET --set KEY=VALUE  # Bulk frontmatter updates

ace-docs sync FILE [--auto] [--with-llm]   # Sync auto-generated sections
ace-docs validate [FILE|PATTERN]           # Validate document rules

# Output formats
# Status: Tabular display with icons (✓ ⚠ ✗) and freshness indicators
# Diff: Structured markdown with changes grouped by impact area
# Validation: Pass/fail with specific rule violations
```

**Error Handling:**
- Missing frontmatter: Report as unmanaged document with suggestion to add frontmatter
- Invalid frontmatter schema: Show specific validation errors with expected format
- Failed change detection: Graceful degradation with partial results
- LLM unavailable: Fall back to basic diff without intelligent summarization

**Edge Cases:**
- Documents with future dates: Flag as suspicious, require confirmation
- Circular no-duplicate-from references: Detect and report cycles
- Massive diffs: Chunk analysis to avoid context limits
- Renamed/moved documents: Track through git history

### Success Criteria

- [ ] **Document Discovery**: Automatically finds all markdown files with ace-docs frontmatter
- [ ] **Freshness Tracking**: Shows last-updated dates and identifies stale documents based on configured frequencies
- [ ] **Change Analysis**: Generates relevant change summaries based on each document's declared sources
- [ ] **Metadata Management**: Updates frontmatter fields (dates, versions) accurately
- [ ] **Rule Validation**: Enforces max-lines, required sections, and no-duplicate rules
- [ ] **Auto-Generation**: Generates tool tables from gemspecs and decision summaries from ADRs
- [ ] **LLM Integration**: Uses ace-llm-query for intelligent change summarization
- [ ] **Context Integration**: Leverages ace-context for project awareness

### Validation Questions

- [ ] **Frontmatter Schema**: Should we support custom fields beyond the standard schema, and how flexible should validation be?
- [ ] **Update Triggers**: Should documents auto-update on certain events (pre-commit, CI) or remain manual-only?
- [ ] **Version Control**: Should ace-docs track document versions in frontmatter or rely solely on git?
- [ ] **Multi-Repository**: Should ace-docs support managing documents across multiple repositories?
- [ ] **Template System**: Should ace-docs include document templates for common types (guide, API, workflow)?

## Objective

Create a universal documentation management tool that enables any markdown document to be self-managed through descriptive frontmatter. This eliminates manual documentation maintenance by providing intelligent change detection, automatic section generation, and rule-based validation.

## Scope of Work

### User Experience Scope
- Document discovery and status reporting for all managed documents
- Change analysis based on configurable sources (git, files, changelogs, ADRs)
- Frontmatter metadata management (dates, versions, custom fields)
- Rule validation and enforcement (size limits, sections, duplicates)
- Auto-generation of dynamic sections (tools, decisions)

### System Behavior Scope
- Recursive markdown file discovery with frontmatter parsing
- Git history analysis for relevant changes
- Integration with ace-context for project awareness
- Integration with ace-llm-query for intelligent summarization
- Caching of analysis results for performance

### Interface Scope
- CLI commands: status, diff, update, sync, validate
- Frontmatter schema for document self-description
- Output formats: status tables, diff reports, validation results
- Integration with workflows through deterministic operations

### Deliverables

#### Behavioral Specifications
- Self-describing document format with frontmatter schema
- Status reporting with freshness indicators
- Change detection and analysis system
- Validation rule engine
- Auto-generation system for dynamic content

#### Validation Artifacts
- Frontmatter schema validation
- Document rule compliance checks
- Change relevance filtering
- Test scenarios for all commands

## Out of Scope

- ❌ **Implementation Details**: Specific file structures, code organization patterns
- ❌ **Technology Decisions**: Choice of YAML parser, diff algorithms, caching strategies
- ❌ **Performance Optimization**: Specific caching mechanisms, parallel processing
- ❌ **Future Enhancements**: Real-time monitoring, web UI, collaborative editing
- ❌ **External Integrations**: GitHub Actions, pre-commit hooks, CI/CD pipelines

## References

- Original workflow: dev-handbook/workflow-instructions/update-context-docs.wf.md
- Related idea: .ace-taskflow/v.0.9.0/ideas/20251007-215947-update-context-docswfmd-should-be-udpate-and-all.md
- Existing patterns: ace-context for loading, ace-llm-query for analysis
- Similar tools: ace-taskflow for task management with frontmatter

## Technical Research

### Architecture Pattern Analysis
The ace-docs package will follow the established ATOM architecture pattern used across all ace-* gems. It will integrate with existing tools:
- **ace-context**: For loading project context and presets
- **ace-llm-query**: For intelligent change summarization
- **ace-core**: For configuration cascade and shared utilities

### Technology Stack
- **Ruby 3.x**: Standard for all ace-* gems
- **YAML frontmatter parsing**: Using standard YAML parser
- **Git integration**: Using git CLI commands for history analysis
- **Markdown processing**: For document parsing and validation
- **Thor or OptionParser**: For CLI command structure

### Frontmatter Schema Design
The frontmatter will use a hierarchical YAML structure with:
- Required fields: doc-type, purpose
- Optional update configuration: frequency, sources, last-updated
- Context requirements: preset, includes, excludes
- Content rules: max-lines, sections, no-duplicate-from, auto-generate

## Implementation Plan

### Planning Steps

* [ ] Research YAML frontmatter parsing approaches in Ruby
* [ ] Analyze ace-taskflow's frontmatter handling for patterns
* [ ] Study ace-context's preset and discovery mechanisms
* [ ] Review git command patterns for change detection
* [ ] Design caching strategy for diff analysis results
* [ ] Plan integration points with ace-llm-query
* [ ] Define document discovery search patterns
* [ ] Design validation rule engine architecture

### Execution Steps

- [ ] Create ace-docs gem structure
  ```bash
  bundle gem ace-docs --no-exe --no-coc --no-ext --no-mit
  mkdir -p ace-docs/lib/ace/docs/{atoms,molecules,organisms,models,commands}
  mkdir -p ace-docs/test/{atoms,molecules,organisms,models,integration,fixtures}
  mkdir -p ace-docs/{exe,bin,.ace.example/docs}
  ```

- [ ] Set up gem dependencies in gemspec
  - Add ace-core dependency
  - Add development dependency on ace-test-support
  - Configure test framework

- [ ] Implement frontmatter parser atom
  ```ruby
  # lib/ace/docs/atoms/frontmatter_parser.rb
  # Pure function to extract and parse YAML frontmatter
  ```
  > TEST: Frontmatter Parsing
  > Type: Unit Test
  > Assert: Correctly extracts and parses valid YAML frontmatter
  > Command: ace-test ace-docs test/atoms/frontmatter_parser_test.rb

- [ ] Create document model
  ```ruby
  # lib/ace/docs/models/document.rb
  # Data structure for document with frontmatter and content
  ```

- [ ] Implement document loader molecule
  ```ruby
  # lib/ace/docs/molecules/document_loader.rb
  # Loads document files with frontmatter parsing
  ```

- [ ] Create document registry organism
  ```ruby
  # lib/ace/docs/organisms/document_registry.rb
  # Discovers and indexes all managed documents
  ```
  > TEST: Document Discovery
  > Type: Integration Test
  > Assert: Finds all markdown files with ace-docs frontmatter
  > Command: ace-test ace-docs test/organisms/document_registry_test.rb

- [ ] Implement status command
  ```ruby
  # lib/ace/docs/commands/status_command.rb
  # Shows document freshness and update status
  ```

- [ ] Create change detector molecule
  ```ruby
  # lib/ace/docs/molecules/change_detector.rb
  # Analyzes git history and file changes
  ```

- [ ] Implement diff command with LLM integration
  ```ruby
  # lib/ace/docs/commands/diff_command.rb
  # Generates intelligent change analysis
  ```
  > TEST: Change Analysis
  > Type: Integration Test
  > Assert: Correctly identifies relevant changes for documents
  > Command: ace-test ace-docs test/commands/diff_command_test.rb

- [ ] Create frontmatter manager molecule
  ```ruby
  # lib/ace/docs/molecules/frontmatter_manager.rb
  # Updates document frontmatter fields
  ```

- [ ] Implement update command
  ```ruby
  # lib/ace/docs/commands/update_command.rb
  # Updates frontmatter metadata
  ```

- [ ] Create validation rule engine
  ```ruby
  # lib/ace/docs/organisms/validator.rb
  # Validates documents against their declared rules
  ```
  > TEST: Rule Validation
  > Type: Unit Test
  > Assert: Enforces max-lines, sections, no-duplicates rules
  > Command: ace-test ace-docs test/organisms/validator_test.rb

- [ ] Implement validate command
  ```ruby
  # lib/ace/docs/commands/validate_command.rb
  # Runs validation checks on documents
  ```

- [ ] Create sync manager organism
  ```ruby
  # lib/ace/docs/organisms/sync_manager.rb
  # Auto-generates sections from code
  ```

- [ ] Implement sync command
  ```ruby
  # lib/ace/docs/commands/sync_command.rb
  # Syncs auto-generated content
  ```

- [ ] Create CLI entry point
  ```ruby
  # exe/ace-docs
  # Main CLI with subcommand routing
  ```

- [ ] Add example configuration
  ```yaml
  # .ace.example/docs/config.yml
  # Default configuration for ace-docs
  ```

- [ ] Create comprehensive test suite
  - Unit tests for atoms and molecules
  - Integration tests for commands
  - Fixture documents for testing

- [ ] Write documentation
  - README.md with usage examples
  - docs/usage.md with detailed command documentation

- [ ] Update workflow to use ace-docs
  - Modify update-context-docs.wf.md to leverage ace-docs commands
  - Create new update-docs.wf.md in ace-docs package

- [ ] Create Claude command integration
  ```markdown
  # .claude/commands/update-docs.md
  # Command to trigger documentation update workflow
  ```

## Test Case Planning

### Unit Tests
- Frontmatter parsing with valid/invalid YAML
- Date calculation for freshness checks
- Rule validation logic
- Change filtering algorithms

### Integration Tests
- Document discovery across directory trees
- Git history analysis for changes
- LLM integration for summarization
- Full command execution flows

### Edge Cases
- Documents without frontmatter
- Malformed YAML in frontmatter
- Missing required fields
- Circular references in no-duplicate-from
- Large repositories with many documents
- Documents with future dates

## Risk Analysis

### Technical Risks
- **LLM API failures**: Fallback to basic diff without summarization
- **Large diff context**: Chunk analysis to stay within limits
- **Performance with many documents**: Implement caching and lazy loading
- **Git history complexity**: Handle renames, merges, and branch differences

### Mitigation Strategies
- Graceful degradation for external service failures
- Configurable timeout and retry mechanisms
- Progress indicators for long operations
- Clear error messages with recovery suggestions