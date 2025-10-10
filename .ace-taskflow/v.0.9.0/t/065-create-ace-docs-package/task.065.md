---
id: v.0.9.0+task.065
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

The ace-docs tool provides documentation analysis and metadata management, supporting iterative agent/human collaboration for keeping docs current. It discovers documents through frontmatter and configuration patterns, then provides intelligence for update decisions.

Key behaviors:
- **Document Discovery**:
  - Finds documents with ace-docs frontmatter (explicit management)
  - Discovers documents matching type patterns in `.ace/docs/config.yml` (configuration-based)
- **Change Analysis** (deterministic data gathering):
  - Always analyzes full git diff with `-w` flag (ignore whitespace)
  - Provides complete diff to LLM for relevance filtering
  - Supports options: `--exclude-renames`, `--exclude-moves`
  - Returns structured analysis for agent/human to act upon
- **Metadata Management**:
  - Updates frontmatter fields (dates, versions, custom fields)
  - No automatic content updates - preserves human/agent control
- **Validation Hierarchy**:
  - Global rules in `.ace/docs/validation.yml`
  - Type-specific rules in configuration
  - Document-specific overrides in frontmatter
  - Delegates to linters for syntax, LLM for semantic validation

### Interface Contract

```bash
# CLI Interface
ace-docs                                    # Show status of all managed documents
ace-docs discover                          # Find and list all managed documents
ace-docs status [--type TYPE] [--needs-update]  # Filtered status views

ace-docs diff [FILE|--all|--needs-update] [--since DATE] [--exclude-renames] [--exclude-moves]
# Analyzes changes using git diff -w, saves to .cache/ace-docs/diff-{timestamp}.md
# Always provides full diff, LLM filters relevance based on document purpose

ace-docs update FILE --set KEY=VALUE       # Update document frontmatter only
ace-docs update --preset PRESET --set KEY=VALUE  # Bulk frontmatter updates

ace-docs validate [FILE|PATTERN] [--syntax|--semantic|--all]
# --syntax: Use linters (markdownlint, etc.)
# --semantic: Use LLM with guide context
# --all: Both syntax and semantic validation

# Output formats
# Status: Tabular display with icons (✓ ⚠ ✗) and freshness indicators
# Diff: Structured markdown with LLM-analyzed changes for human/agent action
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

Create a complete documentation management solution combining deterministic tooling (ace-docs CLI) with intelligent workflow orchestration. This provides both the data gathering/analysis tools AND the guided workflow for iterative documentation updates, ensuring documents stay current through agent/human collaboration. The solution eliminates manual documentation maintenance while preserving control over content decisions.

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
- CLI commands: discover, status, diff, update, validate
- Frontmatter schema for document self-description
- Workflow orchestration via update-docs.wf.md
- Claude command integration: /update-docs
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

#### Workflow Components
- update-docs.wf.md workflow instruction for orchestrated updates
- Claude command integration (.claude/commands/update-docs.md)
- Iterative update process orchestration
- Integration with existing update-context-docs workflow
- Complete solution documentation showing tool+workflow usage

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
- Optional update configuration: frequency, focus (for LLM relevance hints), last-updated
- Context requirements: preset, includes, excludes
- Content rules: max-lines, sections, no-duplicate-from

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

- [ ] Create update-docs workflow instruction
  ```markdown
  # ace-docs/handbook/workflow-instructions/update-docs.wf.md
  # Orchestrates ace-docs tools for iterative documentation updates
  # - Context loads document status via frontmatter
  # - Accepts flexible input: docs list, preset, or type
  # - Generates change analysis with ace-docs diff (exits if no changes)
  # - Guides through updates one by one
  # - Updates metadata with ace-docs update
  # - Presents summary of changes
  ```

- [ ] Create Claude command integration
  ```markdown
  # .claude/commands/update-docs.md
  ---
  description: Update documentation with ace-docs
  ---
  Update project documentation using ace-docs tools.
  Read and follow: ace-docs/handbook/workflow-instructions/update-docs.wf.md
  ```

- [ ] Integrate with existing workflows
  - Update update-context-docs.wf.md to reference ace-docs approach
  - Create migration guide for users transitioning to ace-docs
  - Document workflow+tool complete solution approach

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