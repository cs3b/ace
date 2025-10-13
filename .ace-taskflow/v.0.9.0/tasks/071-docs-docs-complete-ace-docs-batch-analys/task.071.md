---
id: v.0.9.0+task.071
status: draft
priority: high
estimate: 12-16h
dependencies: []
---

# Complete ace-docs with batch analysis and ace-lint integration

## Behavioral Specification

### User Experience
- **Input**: List of document files OR filter criteria (--needs-update, --type guide, --freshness stale)
- **Process**: Single command generates complete markdown analysis report of codebase changes, compacted by LLM to remove noise while preserving details
- **Output**: Markdown report saved to `.cache/ace-docs/analysis-{timestamp}.md` containing organized, relevant changes for documentation updates

### Expected Behavior

The ace-docs tool provides batch analysis capabilities that simplify documentation workflows:

**Document Discovery and Selection:**
- Accepts explicit file list: `ace-docs analyze file1.md file2.md file3.md`
- Accepts filter criteria: `ace-docs analyze --needs-update`, `--type guide`, `--freshness stale`
- Discovers documents automatically based on selection criteria
- Determines time range from oldest last-updated date in selected documents

**Batch Change Analysis:**
- Generates single git diff for entire codebase from determined time range
- Sends diff to LLM with system prompt: "Compact this diff - remove noise, keep relevant details"
- LLM removes test files, formatting changes, minor refactors while preserving significant changes
- Returns ONE markdown report organized by impact level (HIGH/MEDIUM/LOW)
- Saves report to `.cache/ace-docs/analysis-{timestamp}.md` with metadata header

**Workflow Integration:**
- Workflow reads the cached markdown report
- Iterates through each document from original list
- References report sections while updating each document
- After content updates, batch metadata update with `ace-docs update` command
- Validation delegated to separate `ace-lint` tool

**Linting Integration:**
- ace-docs validation delegates to ace-lint for syntax checking
- ace-lint is standalone gem used by multiple ace-* packages
- Supports markdown, YAML, frontmatter validation
- Provides auto-fix capabilities via external linters (markdownlint, yamllint)

### Interface Contract

```bash
# Primary batch analysis command
ace-docs analyze [FILES...] [OPTIONS]
  --needs-update         # Analyze documents needing updates
  --type TYPE            # Filter by document type
  --freshness STATUS     # Filter by freshness (current/stale/outdated)
  --since DATE           # Override automatic time range detection
  --exclude-renames      # Exclude renamed files from diff
  --exclude-moves        # Exclude moved files from diff
  --output FORMAT        # Output format: compact|detailed (default: compact)

# Examples:
ace-docs analyze --needs-update
ace-docs analyze --type guide --freshness stale
ace-docs analyze docs/architecture.md docs/tools.md
ace-docs analyze --needs-update --since "1 month ago"

# Output structure
.cache/ace-docs/analysis-{timestamp}.md:
---
generated: 2025-10-13T14:30:00Z
since: 2 weeks ago
documents: 5
document_list:
  - docs/architecture.md
  - docs/tools.md
  - docs/what-do-we-build.md
  - docs/blueprint.md
  - docs/decisions.md
---

# Codebase Changes Analysis
Period: 2025-09-29 to 2025-10-13

## Summary
3 high-priority changes affecting architecture documentation

## Significant Changes

### ace-docs Package (NEW) - HIGH Impact
Created new documentation management gem with:
- Document discovery via frontmatter
- Change detection using git
- Validation rules engine
- CLI: status, diff, update, validate commands

Files: ace-docs/lib/**/*.rb (15 files)

Relevant for:
- architecture.md: Add to component list
- tools.md: Add CLI documentation

[... more changes organized by impact ...]

## Ignored Changes (45)
- Test files: 32 changes
- Documentation: 8 changes
- Formatting: 3 changes

# Existing commands remain
ace-docs status [OPTIONS]
ace-docs discover
ace-docs update FILE --set KEY=VALUE
ace-docs validate [FILE] [OPTIONS]

# Validation delegates to ace-lint
ace-lint [FILES...] [OPTIONS]
  --type markdown|yaml|frontmatter
  --fix                  # Auto-fix issues
  --format              # Format document
```

**Error Handling:**
- No documents match criteria: Exit with clear message explaining filter criteria
- No changes detected: Exit with message "No changes in specified period"
- LLM unavailable: Fail with clear error message (no fallback to raw diff)
- Invalid time range: Report error and suggest valid formats

**Edge Cases:**
- Multiple documents with different staleness levels: Use oldest update date for time range
- Documents with future dates: Flag as suspicious and exclude from analysis
- Very large diffs (>100K lines): Warn about potential LLM context limits, consider chunking
- Empty repository: Report no history available for analysis

### Success Criteria

- [ ] **Batch Analysis Command**: Single `ace-docs analyze` command accepts file lists or filter criteria
- [ ] **Automatic Time Range**: Determines analysis period from oldest last-updated date in document list
- [ ] **LLM Compaction**: Sends full codebase diff to LLM, receives compact markdown report with noise removed
- [ ] **Structured Report**: Markdown report organized by impact level (HIGH/MEDIUM/LOW) with file references
- [ ] **Cache Management**: Analysis saved to `.cache/ace-docs/analysis-{timestamp}.md` with metadata
- [ ] **Workflow Ready**: Report format enables smooth document-by-document iteration in workflows
- [ ] **Metadata Updates**: Batch update command for frontmatter after content changes
- [ ] **ace-lint Integration**: Validation properly delegates to ace-lint tool
- [ ] **Reusable Linting**: ace-lint usable by ace-taskflow doctor and other ace-* gems

### Validation Questions

- [ ] **LLM Model Selection**: Should model be configurable or fixed (gpt-4, claude-3.5-sonnet)?
- [ ] **Temperature Settings**: What temperature for compaction (0.3 for deterministic, 0.7 for creative)?
- [ ] **Context Limits**: How to handle massive diffs that exceed LLM context windows?
- [ ] **Parallel Analysis**: Should multiple documents be analyzed in parallel for performance?
- [ ] **Report Persistence**: How long to keep cached analysis reports? Auto-cleanup strategy?
- [ ] **ace-lint Scope**: What validation rules should ace-lint support initially (markdown, YAML, frontmatter)?
- [ ] **External Linters**: Which external linters to integrate first (markdownlint mandatory, others optional)?

## Objective

Complete the ace-docs package with batch analysis capabilities that enable efficient documentation maintenance workflows. The tool provides deterministic data gathering (diff generation) and LLM-powered intelligence (noise removal and compaction) while leaving content decisions to workflows. Introduce ace-lint as a reusable validation gem for cross-package linting needs.

## Scope of Work

### User Experience Scope
- Batch analysis command that processes multiple documents in one operation
- Automatic time range detection from document staleness
- LLM-compacted change reports that remove noise while preserving details
- Markdown report format optimized for workflow iteration
- Metadata update commands for post-content-change housekeeping
- Validation delegation to standalone ace-lint gem

### System Behavior Scope
- Document discovery via existing registry mechanisms
- Git diff generation for determined time ranges
- LLM integration via ace-llm-query subprocess calls
- Markdown report generation with structured sections
- Cache management for analysis persistence
- Integration with ace-lint for validation

### Interface Scope
- CLI commands: analyze (new), update, validate (refactored)
- Markdown report format with YAML frontmatter metadata
- ace-lint CLI: lint, format, validate with pluggable linters
- Workflow integration via cached report reading

### Deliverables

#### Behavioral Specifications
- Batch analysis command specification with all options
- LLM prompt template for diff compaction
- Markdown report format with impact-level organization
- ace-lint command specification and validation rules

#### Validation Artifacts
- Analysis report examples for different document types
- Time range calculation validation
- LLM response parsing and error handling
- ace-lint validation rule specifications

#### Workflow Components
- update-docs.wf.md updated to use batch analysis approach
- Analysis report reading and iteration patterns
- Batch metadata update workflows
- ace-lint integration patterns

## Out of Scope

- ❌ **Auto-Generation**: Dynamic content generation (tool tables, ADR summaries) - violates determinism principle
- ❌ **Content Updates**: LLM generating or updating document content directly
- ❌ **JSON Format**: Analysis output in JSON format (markdown only for human/agent readability)
- ❌ **Real-time Analysis**: Continuous monitoring or watch mode
- ❌ **Multi-Repository**: Cross-repository analysis and documentation management
- ❌ **Semantic Validation**: Deep LLM-based semantic accuracy checking (future enhancement)

## References

- Task: .ace-taskflow/v.0.9.0/tasks/done/065-create-ace-docs-package/task.065.md
- Ideas:
  - .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-auto-generation-feature.md (OUT OF SCOPE)
  - .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-external-linter-integration.md (IN SCOPE via ace-lint)
  - .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-llm-diff-summaries.md (IN SCOPE as analyze command)
  - .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-llm-integration.md (PARTIAL - analysis only, not semantic validation)
- Workflow: ace-docs/handbook/workflow-instructions/update-docs.wf.md
- Architecture: docs/architecture.md (ATOM pattern)
- Testing: docs/testing-patterns.md

## Technical Research (Preliminary)

### Architecture Pattern
- ace-docs follows ATOM architecture (atoms, molecules, organisms, models, commands)
- ace-lint follows same ATOM pattern as separate gem
- LLM integration via ace-llm-query subprocess (not library dependency)
- Commands extracted from Thor CLI into separate command classes for testability

### Key Components
```
ace-docs/
├── lib/ace/docs/
│   ├── commands/
│   │   ├── analyze_command.rb  (NEW - batch analysis)
│   │   ├── diff_command.rb     (EXTRACTED from exe/ace-docs)
│   │   ├── update_command.rb   (EXTRACTED from exe/ace-docs)
│   │   └── validate_command.rb (EXTRACTED, delegates to ace-lint)
│   ├── molecules/
│   │   ├── diff_analyzer.rb    (NEW - LLM integration)
│   │   ├── time_range_finder.rb (NEW - oldest date detection)
│   │   └── report_formatter.rb  (NEW - markdown generation)
│   └── prompts/
│       └── compact_diff_prompt.rb (NEW - LLM prompt builder)

ace-lint/ (NEW GEM)
├── lib/ace/lint/
│   ├── linters/
│   │   ├── markdown_linter.rb
│   │   ├── yaml_linter.rb
│   │   └── frontmatter_linter.rb
│   └── adapters/
│       ├── markdownlint_adapter.rb
│       └── yamllint_adapter.rb
```

### Technology Stack
- Ruby 3.x standard for all ace-* gems
- ace-llm-query subprocess for LLM calls (no direct API dependency)
- Git CLI commands for diff generation
- Thor for CLI (existing pattern in exe/ace-docs)
- External linters: markdownlint (Node.js), yamllint (Python) - optional with graceful fallbacks

### LLM Integration Strategy
- Single LLM call per analyze operation (cost-effective)
- Temperature: 0.3 (deterministic compaction)
- Model: Configurable via ace-llm-query (default: gpt-4 or claude-3.5-sonnet)
- Prompt: System prompt + diff + task description
- Output: Pure markdown (no JSON parsing required)
- Error handling: Fail fast if LLM unavailable (no fallback to raw diff)

### Testing Approach
- Mock ace-llm-query subprocess calls in tests
- Fixture-based testing with sample diffs and reports
- Command classes testable independently from CLI
- Integration tests with real git repositories (test fixtures)
- ace-lint tested with mock external linter subprocess calls

## Implementation Plan (Preliminary)

### Phase 1: Command Refactoring (Foundation)
- Extract DiffCommand, UpdateCommand, ValidateCommand from exe/ace-docs
- Create test/commands/ directory structure
- Write comprehensive command tests with mocked dependencies
- Update Thor CLI to delegate to command classes

### Phase 2: ace-lint Gem Creation
- Create ace-lint gem with ATOM structure
- Implement linter adapters (markdownlint, yamllint)
- Add detection logic and graceful fallbacks
- Comprehensive test suite with mocked subprocess calls
- CLI implementation with lint, format, fix commands

### Phase 3: Batch Analysis Implementation
- Create AnalyzeCommand with document selection logic
- Implement TimeRangeFinder molecule for oldest date detection
- Create DiffAnalyzer molecule for LLM integration
- Implement ReportFormatter for markdown generation
- Build CompactDiffPrompt for LLM prompting

### Phase 4: Integration and Workflow Updates
- Update ValidateCommand to delegate to ace-lint
- Update update-docs.wf.md for batch analysis flow
- Create example analysis reports for documentation
- Integration tests for full analyze → update → validate flow

### Test Coverage Targets
- Command classes: 90%+ coverage
- ace-lint adapters: 80%+ (external dependencies)
- LLM integration: 85%+ (mocked calls)
- Overall: 85%+ across both gems

### Estimated Timeline
- Phase 1 (Foundation): 2-3 hours
- Phase 2 (ace-lint): 4-6 hours
- Phase 3 (Analysis): 4-6 hours
- Phase 4 (Integration): 2-3 hours

**Total: 12-18 hours**

## Risk Analysis (Preliminary)

### Technical Risks
- **LLM API failures**: Fail fast with clear error message (no fallback complexity)
- **Large diff context**: Warn user, potentially chunk diffs in future enhancement
- **External linter availability**: Graceful fallbacks to basic validation in ace-lint
- **Git history complexity**: Handle renames, merges carefully in diff generation

### Mitigation Strategies
- Comprehensive error messages with recovery suggestions
- Clear validation of prerequisites (git repo, ace-llm-query available)
- Detailed logging for debugging LLM integration issues
- Extensive test coverage with edge cases and error conditions
