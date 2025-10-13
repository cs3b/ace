---
id: v.0.9.0+task.071
status: pending
priority: high
estimate: 8-10h
dependencies: [v.0.9.0+task.072]
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
- ❌ **ace-lint Implementation**: ace-lint gem creation moved to separate task (v.0.9.0+task.072) - this task focuses on ace-docs batch analysis only

## References

- Task: .ace-taskflow/v.0.9.0/tasks/done/065-create-ace-docs-package/task.065.md
- Dependency: .ace-taskflow/v.0.9.0/tasks/072-feat-lint-ace-lint-standalone-linting-ge/task.072.md (ace-lint gem - must complete first)
- Ideas:
  - .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-auto-generation-feature.md (OUT OF SCOPE)
  - .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-external-linter-integration.md (MOVED TO TASK 072)
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

## Technical Approach

### Architecture Pattern

**ATOM Architecture Application:**
- **Atoms**: `FrontmatterParser` (existing), `TimeRangeCalculator` (new), `DiffFilterer` (new)
- **Molecules**: `TimeRangeFinder`, `DiffAnalyzer`, `ReportFormatter`, `ChangeDetector` (extend existing)
- **Organisms**: `DocumentRegistry` (extend existing), ace-lint `LinterOrchestrator`
- **Commands**: `AnalyzeCommand` (new), extract inline commands to classes
- **Models**: `Document` (existing), `AnalysisReport` (new), `LintResult` (new)

**Integration Pattern:**
- ace-docs uses ace-lint as a subprocess (not gem dependency)
- ace-docs uses ace-llm-query as subprocess for LLM calls
- Both gems follow shared ATOM architecture
- Configuration cascade via ace-core

**Key Architectural Decisions:**
1. Commands extracted from Thor CLI for testability
2. LLM integration via subprocess (no tight coupling)
3. External linter adapters with graceful fallbacks
4. Deterministic data gathering + LLM intelligence separation

### Technology Stack

**Core Dependencies:**
- **Ruby**: 3.1+ (existing ace-* standard)
- **ace-core**: Configuration management (~> 0.1)
- **Thor**: CLI framework (~> 1.3, existing)
- **yaml**: YAML parsing (~> 0.3, existing)
- **colorize**: Terminal colors (~> 1.1, existing)
- **terminal-table**: Table formatting (~> 3.0, existing)

**Subprocess Integrations:**
- **ace-llm-query**: LLM calls (installed, via bin/ace-llm-query)
- **markdownlint**: Optional Node.js markdown linter
- **yamllint**: Optional Python YAML linter
- **git**: Required for diff generation

**Development Dependencies:**
- **ace-test-support**: Shared testing infrastructure
- **minitest**: Test framework (~> 5.19)
- **simplecov**: Code coverage (~> 0.22)

### Implementation Strategy

**Phase Structure:**
1. **Foundation** (Command Extraction): Refactor CLI for testability
2. **Batch Analysis**: Implement analyze command with LLM integration
3. **Integration**: Connect with ace-lint (task 072), update workflows

**Note**: ace-lint gem creation moved to separate task (v.0.9.0+task.072) which must complete before this task's integration phase.

**Testing Strategy:**
- Mock subprocess calls (ace-llm-query, external linters) using ace-test-support helpers
- Fixture-based testing with sample diffs and expected reports
- Integration tests with real git repositories (test/fixtures/sample-repo/)
- Test coverage target: 85%+ overall, 90%+ for commands

**Rollback Considerations:**
- New files can be safely removed without affecting existing functionality
- Existing commands (status, diff, update, validate) remain unchanged
- ace-lint as separate gem allows independent rollback
- No database migrations or data changes required

## File Modifications

### Create

**ace-docs New Files:**

- `lib/ace/docs/commands/analyze_command.rb`
  - Purpose: Batch analysis command implementation
  - Key components: Document selection, time range detection, LLM analysis orchestration

- `lib/ace/docs/molecules/time_range_finder.rb`
  - Purpose: Find oldest last-updated date from document list
  - Key components: Date extraction, comparison, fallback logic

- `lib/ace/docs/molecules/diff_analyzer.rb`
  - Purpose: LLM integration for diff compaction
  - Key components: Subprocess call to ace-llm-query, response parsing, error handling

- `lib/ace/docs/molecules/report_formatter.rb`
  - Purpose: Format analysis results as markdown
  - Key components: Impact level organization, metadata header, change statistics

- `lib/ace/docs/atoms/time_range_calculator.rb`
  - Purpose: Calculate time ranges from dates
  - Key components: Date parsing, range calculation, formatting

- `lib/ace/docs/atoms/diff_filterer.rb`
  - Purpose: Filter diff content (remove test files, etc.)
  - Key components: Path filtering, hunk analysis

- `lib/ace/docs/models/analysis_report.rb`
  - Purpose: Data model for analysis reports
  - Key components: Metadata, changes, statistics, serialization

- `lib/ace/docs/prompts/compact_diff_prompt.rb`
  - Purpose: Build LLM prompts for diff compaction
  - Key components: System prompt, task description, output format instructions

**ace-docs Test Files:**

- `test/commands/analyze_command_test.rb`
  - Purpose: Test analyze command with mocked dependencies

- `test/molecules/time_range_finder_test.rb`
  - Purpose: Test time range detection logic

- `test/molecules/diff_analyzer_test.rb`
  - Purpose: Test LLM integration with mocked subprocess

- `test/molecules/report_formatter_test.rb`
  - Purpose: Test markdown report generation

- `test/atoms/time_range_calculator_test.rb`
  - Purpose: Test time range calculations

- `test/atoms/diff_filterer_test.rb`
  - Purpose: Test diff filtering logic

- `test/models/analysis_report_test.rb`
  - Purpose: Test analysis report model

- `test/prompts/compact_diff_prompt_test.rb`
  - Purpose: Test prompt generation

- `test/fixtures/sample-repo/` (directory)
  - Purpose: Test git repository with sample commits for integration tests

**Note**: ace-lint gem files moved to separate task v.0.9.0+task.072

### Modify

**ace-docs Existing Files:**

- `ace-docs/exe/ace-docs`
  - Changes: Add `analyze` command, extract inline command logic to command classes
  - Impact: Improve testability, maintain backward compatibility
  - Integration points: Commands delegated to new command classes

- `ace-docs/lib/ace/docs/molecules/change_detector.rb`
  - Changes: Extend with LLM analysis option, refactor for reuse by analyze command
  - Impact: Add optional LLM compaction without breaking existing diff command
  - Integration points: Used by both diff and analyze commands

- `ace-docs/lib/ace/docs/commands/status_command.rb`
  - Changes: Minor refactoring if needed for consistency with new command pattern
  - Impact: Ensure consistent command interface across all commands
  - Integration points: None (already extracted)

- `ace-docs/test/test_helper.rb`
  - Changes: Add helpers for mocking subprocess calls (ace-llm-query, ace-lint)
  - Impact: Enable testing of subprocess integrations
  - Integration points: Used by all test files testing subprocess calls

- `ace-docs/README.md`
  - Changes: Add documentation for analyze command and ace-lint integration
  - Impact: Update user-facing documentation
  - Integration points: Reference ace-lint gem

**Note**: Workspace integration for ace-lint handled in task v.0.9.0+task.072

### Delete

**No Files to Delete:**
- All changes are additive
- Existing functionality preserved
- No deprecated components removed

## Test Case Planning

### Test Scenarios

**Happy Path Scenarios:**

1. **Analyze documents needing updates**
   - Input: `ace-docs analyze --needs-update`
   - Expected: Markdown report generated with changes organized by impact
   - Test: Mock 3 documents with stale dates, verify report structure

2. **Analyze specific files**
   - Input: `ace-docs analyze docs/arch.md docs/tools.md`
   - Expected: Report for those 2 files only
   - Test: Verify document selection and time range detection

3. **Lint markdown with markdownlint available**
   - Input: `ace-lint docs/test.md --fix`
   - Expected: Markdownlint runs, fixes applied, success reported
   - Test: Mock markdownlint subprocess, verify command construction

4. **Lint with external linters unavailable**
   - Input: `ace-lint docs/test.md`
   - Expected: Graceful fallback to basic validation, warning message
   - Test: Mock command detection failure, verify fallback behavior

**Edge Case Scenarios:**

1. **No documents match criteria**
   - Input: `ace-docs analyze --type nonexistent`
   - Expected: Clear error message with suggestions
   - Test: Verify error handling and exit code 1

2. **No changes detected in time range**
   - Input: `ace-docs analyze --since "1 week ago"`
   - Expected: "No changes detected" message, exit code 2
   - Test: Mock empty git diff output

3. **Very large diff (>100K lines)**
   - Input: `ace-docs analyze` with massive codebase changes
   - Expected: Warning about context limits, analysis attempted
   - Test: Mock large diff, verify warning message

4. **Document with future last-updated date**
   - Input: Document frontmatter has `last-updated: 2099-12-31`
   - Expected: Flag as suspicious, exclude from analysis
   - Test: Verify date validation and exclusion logic

5. **Multiple documents with different staleness**
   - Input: Mix of current, stale, and outdated documents
   - Expected: Use oldest update date for time range
   - Test: Verify time range finder selects oldest date

**Error Condition Scenarios:**

1. **LLM unavailable (ace-llm-query not found)**
   - Input: `ace-docs analyze --needs-update`
   - Expected: Clear error "ace-llm-query not found", exit code 3
   - Test: Mock command not found error

2. **LLM API failure (timeout, rate limit)**
   - Input: `ace-docs analyze --needs-update`
   - Expected: Error with retry suggestion, exit code 3
   - Test: Mock subprocess failure with various error codes

3. **Git repository not found**
   - Input: Run in non-git directory
   - Expected: Clear error "Not a git repository", exit code 4
   - Test: Mock git command failure

4. **Invalid time range format**
   - Input: `ace-docs analyze --since "invalid date"`
   - Expected: Error with valid format examples
   - Test: Verify date parsing error handling

**Integration Point Scenarios:**

1. **Full analyze → update → validate flow**
   - Steps: Generate analysis, update documents, run ace-lint validation
   - Expected: Complete workflow succeeds, all tools cooperate
   - Test: Integration test with real git repo and mocked LLM

2. **ace-lint subprocess from ace-docs validate**
   - Input: `ace-docs validate docs/test.md`
   - Expected: ace-lint called correctly, results parsed
   - Test: Mock ace-lint subprocess, verify argument passing

3. **ace-llm-query subprocess from diff analyzer**
   - Input: DiffAnalyzer calls LLM with prompt
   - Expected: Prompt constructed correctly, response parsed
   - Test: Mock ace-llm-query with various responses

### Test Type Categorization

**Unit Tests (High Priority):**
- TimeRangeCalculator atom (pure date math)
- DiffFilterer atom (pure string filtering)
- TimeRangeFinder molecule (date selection logic)
- ReportFormatter molecule (markdown generation)
- AnalysisReport model (data structure)
- CompactDiffPrompt (prompt construction)
- ace-lint CommandDetector atom (command checking)
- ace-lint OutputParser atom (output parsing)

**Integration Tests (Medium Priority):**
- AnalyzeCommand with mocked LLM and git
- DiffAnalyzer with mocked ace-llm-query subprocess
- Markdownlint/Yamllint adapters with mocked subprocesses
- LinterOrchestrator coordinating multiple linters
- Full CLI integration (ace-docs analyze + ace-lint)

**End-to-End Tests (Context Dependent):**
- Complete workflow: analyze → update → validate
- Real git repository with sample commits
- ace-lint running on actual markdown files (with fallback mocking)

**Performance Tests (If Applicable):**
- Large diff handling (100K+ lines)
- Multiple document analysis (50+ documents)
- LLM response time impact

### Test Coverage Expectations

- **Commands**: 90%+ coverage (critical user-facing)
- **Molecules/Organisms**: 85%+ coverage (core business logic)
- **Atoms**: 95%+ coverage (pure functions, easy to test)
- **Models**: 80%+ coverage (data structures)
- **Adapters**: 75%+ coverage (external dependencies, mocked)
- **Overall**: 85%+ across both gems

## Implementation Plan

### Planning Steps

* [ ] Review existing ace-docs codebase structure
  - Understand current command pattern (inline in exe/ace-docs)
  - Analyze existing molecules (ChangeDetector, DocumentLoader, FrontmatterManager)
  - Review test structure and helpers
  - Document integration points

* [ ] Research ace-llm-query subprocess interface
  - Test command: `ace-llm-query "test prompt" --model default`
  - Document expected input/output format
  - Identify error codes and messages
  - Plan prompt construction approach

* [ ] Research external linter availability and interfaces
  - Check markdownlint CLI: `markdownlint --version` (if available)
  - Check yamllint CLI: `yamllint --version` (if available)
  - Document command-line arguments and output formats
  - Plan graceful fallback strategy when not available

* [ ] Design LLM prompt template for diff compaction
  - Define system prompt (remove noise, keep relevant changes)
  - Plan diff formatting for LLM context
  - Define output format (markdown with impact levels)
  - Consider context window limits (100K lines warning threshold)

* [ ] Design analysis report markdown format
  - Define YAML frontmatter structure (generated, since, documents list)
  - Plan impact-level sections (HIGH/MEDIUM/LOW)
  - Design change description format (component, files, relevance)
  - Plan statistics section (commits, files, lines, relevant changes)

* [ ] Design ace-lint gem structure and API
  - Plan ATOM architecture (atoms, molecules, organisms, models)
  - Define linter adapter interface (detect, run, parse)
  - Design CLI command structure (lint, format, fix options)
  - Plan configuration cascade via ace-core

### Execution Steps

**Phase 1: Foundation (Command Extraction) - 2-3 hours**

**Note**: Phase 2 (ace-lint Gem Creation) has been moved to separate task v.0.9.0+task.072 which must complete before starting Phase 3 of this task.

- [ ] Create `test/commands/` directory in ace-docs
  > TEST: Directory Creation
  > Type: Pre-condition Check
  > Assert: Directory exists and is empty
  > Command: test -d ace-docs/test/commands && [ -z "$(ls -A ace-docs/test/commands)" ]

- [ ] Extract DiffCommand from exe/ace-docs to lib/ace/docs/commands/diff_command.rb
  - Move diff logic from CLI to DiffCommand class
  - Add execute method returning status code (0 success, 1 failure)
  - Update CLI to delegate: `Commands::DiffCommand.new(options).execute`

- [ ] Extract UpdateCommand from exe/ace-docs to lib/ace/docs/commands/update_command.rb
  - Move update logic from CLI to UpdateCommand class
  - Add execute method returning status code
  - Update CLI to delegate: `Commands::UpdateCommand.new(options).execute`

- [ ] Extract ValidateCommand from exe/ace-docs to lib/ace/docs/commands/validate_command.rb
  - Move validate logic from CLI to ValidateCommand class
  - Add execute method returning status code
  - Update CLI to delegate: `Commands::ValidateCommand.new(options).execute`

- [ ] Create command tests with mocked dependencies
  - test/commands/diff_command_test.rb
  - test/commands/update_command_test.rb
  - test/commands/validate_command_test.rb
  - Mock registry, molecules, subprocess calls
  > TEST: Command Tests Pass
  > Type: Action Validation
  > Assert: All command tests pass (3 test files, ~15 tests total)
  > Command: cd ace-docs && bundle exec rake test TEST=test/commands/*_test.rb

- [ ] Update exe/ace-docs to delegate all commands to command classes
  - Verify backward compatibility: `ace-docs status` still works
  - Verify return codes: Commands return 0 or 1
  > TEST: CLI Backward Compatibility
  > Type: Integration Validation
  > Assert: Existing commands work identically
  > Command: cd ace-docs && bundle exec ace-docs status && bundle exec ace-docs diff --help

**Phase 2: Batch Analysis Implementation - 4-6 hours**

- [ ] Implement TimeRangeCalculator atom (ace-docs/lib/ace/docs/atoms/time_range_calculator.rb)
  - Method: `calculate_since(date)` formats date for git
  - Method: `parse_date(string)` handles various formats
  - Method: `format_human(date)` for display ("2 weeks ago")
  - Test with various date formats

- [ ] Implement DiffFilterer atom (ace-docs/lib/ace/docs/atoms/diff_filterer.rb)
  - Method: `filter_paths(diff, exclude_patterns)` removes test files, etc.
  - Method: `estimate_size(diff)` counts lines
  - Test with sample diffs

- [ ] Implement TimeRangeFinder molecule (ace-docs/lib/ace/docs/molecules/time_range_finder.rb)
  - Method: `find_oldest_update(documents)` returns oldest last-updated date
  - Handle documents without last-updated (use default)
  - Exclude documents with suspicious/future dates
  - Return formatted since parameter for git
  - Test with various document combinations

- [ ] Implement CompactDiffPrompt (ace-docs/lib/ace/docs/prompts/compact_diff_prompt.rb)
  - Method: `build(diff, documents)` constructs LLM prompt
  - System prompt: "Compact this diff - remove noise, keep relevant details"
  - Include document list and types for context
  - Specify output format (markdown with impact levels)
  - Test prompt structure and content

- [ ] Implement DiffAnalyzer molecule (ace-docs/lib/ace/docs/molecules/diff_analyzer.rb)
  - Method: `analyze(diff, documents, options)` calls LLM
  - Use Open3.capture3 to call ace-llm-query subprocess
  - Build prompt via CompactDiffPrompt
  - Parse LLM response (expect markdown)
  - Handle errors (command not found, API failure, timeout)
  - Test with mocked subprocess (various responses and errors)

- [ ] Implement AnalysisReport model (ace-docs/lib/ace/docs/models/analysis_report.rb)
  - Fields: generated, since, documents[], compacted_changes, statistics
  - Methods: to_markdown, save_to_cache(cache_dir), to_h
  - Generate YAML frontmatter + markdown body
  - Test serialization and file writing

- [ ] Implement ReportFormatter molecule (ace-docs/lib/ace/docs/molecules/report_formatter.rb)
  - Method: `format(analysis_result, documents)` creates AnalysisReport
  - Parse LLM response into structured format
  - Organize by impact level (HIGH/MEDIUM/LOW)
  - Add metadata header and statistics footer
  - Test formatting with sample LLM responses

- [ ] Extend ChangeDetector molecule (ace-docs/lib/ace/docs/molecules/change_detector.rb)
  - Add method: `generate_batch_diff(documents, since, options)`
  - Combine with existing diff generation logic
  - Support exclude-renames, exclude-moves options
  - Test batch diff generation

- [ ] Implement AnalyzeCommand (ace-docs/lib/ace/docs/commands/analyze_command.rb)
  - Parse options: --needs-update, --type, --freshness, --since, etc.
  - Select documents via DocumentRegistry
  - Determine time range via TimeRangeFinder
  - Generate diff via ChangeDetector
  - Check diff size, warn if >100K lines
  - Analyze diff via DiffAnalyzer (LLM call)
  - Format report via ReportFormatter
  - Save report to .cache/ace-docs/analysis-{timestamp}.md
  - Display summary (documents, period, report path)
  - Return status code (0 success, 1 no docs, 2 no changes, 3 LLM error, 4 git error)
  - Test with mocked dependencies

- [ ] Add analyze command to exe/ace-docs CLI
  - Add Thor desc and options
  - Delegate to Commands::AnalyzeCommand.new(options).execute
  > TEST: Analyze Command Works
  > Type: Integration Validation
  > Assert: Command runs, generates report (with mocked LLM)
  > Command: cd ace-docs && bundle exec ace-docs analyze --help && bundle exec ace-docs analyze test/fixtures/sample.md --dry-run

- [ ] Create test fixtures for analyze command
  - test/fixtures/sample-repo/ with git history
  - Sample documents with various staleness levels
  - Sample LLM responses for different scenarios
  - Sample expected reports

- [ ] Write comprehensive analyze tests
  - test/commands/analyze_command_test.rb (mocked dependencies)
  - test/molecules/time_range_finder_test.rb
  - test/molecules/diff_analyzer_test.rb (mocked subprocess)
  - test/molecules/report_formatter_test.rb
  - test/models/analysis_report_test.rb
  - test/prompts/compact_diff_prompt_test.rb
  - test/integration/analyze_integration_test.rb (end-to-end with mocks)
  > TEST: Analyze Tests Pass
  > Type: Action Validation
  > Assert: All analyze-related tests pass
  > Command: cd ace-docs && bundle exec rake test TEST=test/commands/analyze_command_test.rb TEST=test/molecules/*_test.rb TEST=test/models/analysis_report_test.rb

**Phase 3: Integration and Finalization - 2-3 hours**

**Prerequisites**: Task v.0.9.0+task.072 (ace-lint gem) must be completed before starting this phase.

- [ ] Update ValidateCommand to delegate to ace-lint
  - Replace inline validation logic with subprocess call to ace-lint
  - Pass files and options to ace-lint
  - Parse ace-lint output and format for display
  - Handle ace-lint not available (graceful error)
  - Test with mocked ace-lint subprocess

- [ ] Update test_helper.rb with subprocess mocking helpers
  - Helper: `stub_subprocess(command, output, exit_code)`
  - Helper: `mock_ace_llm_query(response)`
  - Helper: `mock_ace_lint(result)`
  - Document usage in comments

- [ ] Create integration test for full workflow
  - test/integration/full_workflow_test.rb
  - Steps: analyze (mocked LLM) → update → validate (mocked ace-lint)
  - Verify data flows correctly between commands
  - Test error handling at each step
  > TEST: Full Workflow Integration
  > Type: End-to-End Validation
  > Assert: Complete workflow succeeds with mocked external dependencies
  > Command: cd ace-docs && bundle exec rake test TEST=test/integration/full_workflow_test.rb

- [ ] Update ace-docs README.md
  - Add analyze command documentation
  - Add ace-lint integration section
  - Update usage examples
  - Add batch analysis workflow example

- [ ] Verify test coverage across both gems
  - Run: `cd ace-docs && bundle exec rake test:coverage`
  - Run: `cd ace-lint && bundle exec rake test:coverage`
  - Verify: ace-docs >85%, ace-lint >80%, commands >90%
  > TEST: Coverage Targets Met
  > Type: Quality Gate
  > Assert: Test coverage meets targets
  > Command: cd ace-docs && bundle exec rake test && cd ../ace-lint && bundle exec rake test

- [ ] Run full workspace test suite
  - Ensure both gems pass all tests
  - Verify no regressions in other gems
  > TEST: Workspace Tests Pass
  > Type: Integration Validation
  > Assert: All ace-* gems pass tests
  > Command: ace-test

- [ ] Create example analysis report in ux/ directory
  - ux/example-analysis-report.md
  - Show realistic analysis output
  - Demonstrate impact levels and organization

- [ ] Final verification of ux/usage.md
  - Ensure all commands documented match implementation
  - Verify examples are accurate
  - Check troubleshooting section is complete
  > TEST: Documentation Accuracy
  > Type: Manual Validation
  > Assert: All commands in usage.md match implementation
  > Command: diff <(grep -E "^ace-docs|^ace-lint" .ace-taskflow/v.0.9.0/tasks/071*/ux/usage.md) <(ace-docs help && ace-lint help)

## Risk Assessment

### Technical Risks

- **Risk**: LLM API failures (rate limits, timeouts, service unavailable)
  - **Probability**: Medium
  - **Impact**: High (analyze command unusable)
  - **Mitigation**:
    - Clear error messages with suggestions ("Try again in 5 minutes")
    - Fail fast (no fallback to raw diff - keeps scope clean)
    - Document retry strategies in usage.md
  - **Rollback**: Remove analyze command, keep existing diff command

- **Risk**: Very large diffs exceed LLM context limits (>100K lines)
  - **Probability**: Low-Medium
  - **Impact**: Medium (analysis fails or truncated)
  - **Mitigation**:
    - Warn user when diff size >100K lines
    - Suggest using --exclude-renames, --exclude-moves, or --since options
    - Document workarounds in troubleshooting section
  - **Rollback**: Graceful failure with clear error message

- **Risk**: External linter availability varies across environments
  - **Probability**: High
  - **Impact**: Low (graceful fallbacks planned)
  - **Mitigation**:
    - CommandDetector checks availability at runtime
    - Graceful fallback to basic validation
    - Clear warnings when external linters not available
    - Documentation explains optional vs. required linters
  - **Rollback**: ace-lint still works with basic validation only

- **Risk**: Git history complexity (large merges, renames, rebases)
  - **Probability**: Medium
  - **Impact**: Medium (diff may be noisy or confusing)
  - **Mitigation**:
    - Support --exclude-renames and --exclude-moves flags
    - DiffFilterer atom can pre-filter obvious noise
    - LLM prompt instructs to remove noise
    - Test with complex git histories in fixtures
  - **Rollback**: Users can use --since to limit scope

### Integration Risks

- **Risk**: ace-llm-query not installed or misconfigured
  - **Probability**: Low (already in workspace)
  - **Impact**: High (analyze command fails)
  - **Mitigation**:
    - Check for ace-llm-query availability before analysis
    - Clear error: "ace-llm-query not found. Install ace-llm gem."
    - Document prerequisite in README
  - **Monitoring**: Command not found error in subprocess call

- **Risk**: Subprocess call overhead impacts performance
  - **Probability**: Low
  - **Impact**: Low (single subprocess call per operation)
  - **Mitigation**:
    - Single LLM call per analyze operation (efficient)
    - Cache analysis results for re-use
    - No subprocess calls in hot paths (atoms/models)
  - **Monitoring**: Add timing logs in DiffAnalyzer

- **Risk**: ace-lint and ace-docs version compatibility
  - **Probability**: Low (both in same mono-repo)
  - **Impact**: Low (subprocess interface is simple)
  - **Mitigation**:
    - Simple CLI interface (stable contract)
    - Version checking not required (subprocess call)
    - Both gems developed and tested together
  - **Monitoring**: Integration tests cover ace-lint calls

### Performance Risks

- **Risk**: LLM response time impacts UX (can be 5-30 seconds)
  - **Mitigation**:
    - Display progress: "Compacting changes with LLM..."
    - Set reasonable expectations in documentation
    - Single call per operation (no repeated calls)
  - **Monitoring**: Log LLM call duration
  - **Thresholds**: Warn if >60 seconds

- **Risk**: Large document sets (50+ documents) slow analysis
  - **Mitigation**:
    - Single git diff for all documents (efficient)
    - Single LLM call (not per-document)
    - Time range detection is O(n) documents
  - **Monitoring**: Log document count and analysis time
  - **Thresholds**: Warn if >100 documents

## Acceptance Criteria

- [ ] **Batch Analysis Command**: `ace-docs analyze` accepts file lists, filter options (--needs-update, --type, --freshness)
- [ ] **Automatic Time Range**: Determines analysis period from oldest last-updated date in document list
- [ ] **LLM Compaction**: Sends full codebase diff to ace-llm-query, receives compact markdown report with noise removed
- [ ] **Structured Report**: Markdown report organized by impact level (HIGH/MEDIUM/LOW) with file references and document relevance
- [ ] **Cache Management**: Analysis saved to `.cache/ace-docs/analysis-{timestamp}.md` with YAML frontmatter metadata
- [ ] **Workflow Ready**: Report format enables smooth document-by-document iteration in workflows (clear sections, relevance mapping)
- [ ] **Metadata Updates**: `ace-docs update` command accepts multiple files for batch frontmatter updates
- [ ] **ace-lint Integration**: Validation delegates to ace-lint tool via subprocess (requires task 072 completion)
- [ ] **Command Extraction**: All CLI commands extracted to testable command classes
- [ ] **Error Handling**: Clear error messages for all failure scenarios (no docs, no changes, LLM error, git error)
- [ ] **Test Coverage**: >85% overall, >90% for commands, all tests passing
- [ ] **Documentation**: README and ux/usage.md complete with examples, troubleshooting, and configuration guides

**Note**: ace-lint gem creation (items removed above) moved to task v.0.9.0+task.072
