---
id: v.0.9.0+task.074
status: pending
priority: medium
estimate: 12-16h
dependencies: [v.0.9.0+task.073]
---

# Advanced LLM intelligence features for ace-docs

## Behavioral Specification

### User Experience

- **Input**: Documents needing updates, user requests for suggestions, cross-document validation runs
- **Process**: LLM analyzes documents against codebase changes, provides actionable recommendations, identifies cross-document inconsistencies, learns from user feedback on relevance
- **Output**: Structured suggestions for content improvements, recommendations for updates based on code changes, cross-document consistency reports, improved relevance filtering over time

### Expected Behavior

**Content Recommendations (Primary Feature):**

When codebase changes affect a document, LLM should recommend:
- New sections to add (e.g., "New ace-docs component added → Add to component list")
- Outdated content to update (e.g., "Error handling changed → Update error handling section")
- Missing context to include (e.g., "New integration patterns → Document integration approach")
- Specific locations and wording for changes

Example workflow:
```bash
ace-docs recommend docs/architecture.md
# Analyzes recent changes
# Returns:
# - HIGH: Add ace-docs to component architecture section
# - MEDIUM: Update error handling patterns (ace-core changes)
# - LOW: Consider mentioning new CLI flags
```

**Smart Suggestions Command:**

Users can request document analysis for improvements:
```bash
ace-docs suggest docs/guide.md
# Returns:
# - Clarity: Section "Installation" uses inconsistent terminology
# - Completeness: Missing troubleshooting section
# - Consistency: Contradicts architecture.md on component names
```

Different analysis modes:
- `--clarity` - Readability and explanation quality
- `--completeness` - Missing sections and gaps
- `--consistency` - Alignment with other documents
- `--all` - Complete analysis

**Cross-Document Analysis:**

Detect problems across multiple documents:
```bash
ace-docs analyze-consistency docs/
# Returns:
# - Terminology conflict: "gem" vs "package" (5 documents)
# - Duplicate content: Installation steps in README.md and docs/guide.md
# - Inconsistent versions: README shows 0.3.0, CHANGELOG shows 0.3.2
# - Consolidation opportunity: 3 documents explain same workflow
```

**Relevance Scoring with Learning:**

System learns from user feedback:
```bash
ace-docs diff docs/architecture.md
# Shows: "Test file changes (relevance: 15%)"
# User: ace-docs feedback --irrelevant test-changes
# System: Lowers future test file relevance for architecture docs
```

Feedback types:
- `--relevant` - Increase weight for similar changes
- `--irrelevant` - Decrease weight for similar changes
- `--critical` - Mark pattern as always relevant
- `--ignore` - Mark pattern as always irrelevant

### Interface Contract

```bash
# Content recommendations
ace-docs recommend FILE [OPTIONS]
  --since DATE          # Analyze changes since date (default: last-updated)
  --priority LEVEL      # Filter by priority (high/medium/low)
  --format FORMAT       # Output format (text/json/interactive)
  --apply               # Interactive mode to apply suggestions

# Output example:
# Content Recommendations for docs/architecture.md
# Based on changes since 2025-10-14
#
# HIGH PRIORITY (2):
# ┌─────────────────────────────────────────────────────────┐
# │ Add new component to architecture                       │
# │ Location: ## Component Architecture (line 45)           │
# │ Suggestion: Add ace-docs entry:                         │
# │   - ace-docs: Documentation management with LLM         │
# │ Reason: New gem added to ecosystem                      │
# └─────────────────────────────────────────────────────────┘

# Smart suggestions
ace-docs suggest FILE [OPTIONS]
  --clarity             # Check readability and clarity
  --completeness        # Check for missing content
  --consistency         # Check consistency with other docs
  --all                 # All checks (default)
  --model MODEL         # LLM model to use

# Cross-document analysis
ace-docs analyze-consistency [PATTERN] [OPTIONS]
  --type TYPE           # Document type filter
  --fix-terminology     # Suggest terminology standardization
  --detect-duplicates   # Find duplicate content
  --check-versions      # Verify version consistency

# Relevance feedback
ace-docs feedback --relevant PATTERN [OPTIONS]
ace-docs feedback --irrelevant PATTERN [OPTIONS]
ace-docs feedback --critical PATTERN [OPTIONS]
ace-docs feedback --ignore PATTERN [OPTIONS]
  --document FILE       # Apply to specific document
  --global              # Apply to all documents
```

**Error Handling:**

- Missing ace-llm-query: Clear error with installation instructions
- LLM API timeout: Retry with backoff, fall back to cache if available
- No changes detected: Skip recommendation generation
- Cross-document analysis on single file: Expand to find related documents
- Invalid feedback pattern: Suggest valid patterns based on history

**Edge Cases:**

- Document with no recent changes: Suggest based on document age and type
- Conflicting suggestions: Rank by confidence score
- User rejects all suggestions: Learn preference and adjust future scoring
- Large document set: Batch processing with progress indicator
- Contradictory feedback: Prompt user to resolve conflict

### Success Criteria

- [ ] **Content Recommendations Work**: Analyze changes and suggest specific document updates
- [ ] **Suggestions Are Actionable**: Clear location, wording, and reasoning for each
- [ ] **Cross-Document Analysis Functional**: Detect inconsistencies across document sets
- [ ] **Learning System Active**: Relevance scoring improves based on user feedback
- [ ] **Interactive Mode Available**: Users can review and apply suggestions interactively
- [ ] **Performance Acceptable**: Recommendations generated within 30s for typical documents

### Validation Questions

- [ ] **Storage Format**: How to store learned relevance patterns (YAML/JSON/SQLite)?
- [ ] **Learning Scope**: Document-specific vs document-type vs global relevance learning?
- [ ] **Suggestion Confidence**: How to calculate and display confidence scores?
- [ ] **Batch Processing**: Parallel analysis for multiple documents vs sequential?
- [ ] **Model Selection**: Same model for all features or specialized models per feature?

## Objective

Complete the advanced LLM integration features from the full LLM integration idea (20251013-ace-docs-llm-integration.md) that were not implemented in task.071 (diff summaries) or task.073 (semantic validation). Enable intelligent, context-aware documentation assistance through content recommendations, smart suggestions, cross-document analysis, and adaptive relevance learning.

## Scope of Work

### User Experience Scope

- **Content Recommendations**: Get actionable suggestions for document updates based on code changes
- **Smart Suggestions**: Request analysis for clarity, completeness, consistency improvements
- **Cross-Document Analysis**: Find and fix inconsistencies across documentation sets
- **Relevance Learning**: Train the system on what changes matter for different documents

### System Behavior Scope

- New `recommend` command for change-based suggestions
- New `suggest` command for document quality analysis
- New `analyze-consistency` command for cross-document validation
- New `feedback` command for relevance learning
- Feedback storage and retrieval system
- LLM prompt templates for each feature
- Confidence scoring and ranking system

### Interface Scope

- CLI commands: recommend, suggest, analyze-consistency, feedback
- Interactive mode for applying suggestions
- JSON output format for programmatic use
- Feedback pattern matching and storage
- Progress indicators for batch operations

### Deliverables

#### Behavioral Specifications

- Content recommendation flow and examples
- Smart suggestion categories and outputs
- Cross-document analysis patterns
- Relevance feedback loop and learning

#### Validation Artifacts

- Recommendation accuracy examples
- Suggestion quality metrics
- Cross-document consistency reports
- Learning effectiveness demonstrations

#### Workflow Components

- `ux/usage.md` with recommendation workflows
- Suggestion command patterns
- Cross-document validation examples
- Feedback training scenarios

## Out of Scope

- ❌ **Auto-Generation**: Dynamic content generation (task.071 explicitly excluded)
- ❌ **Semantic Validation**: Already implemented in task.073
- ❌ **Diff Summaries**: Already implemented in task.071 analyze command
- ❌ **Command Refactoring**: Already completed in task.071
- ❌ **Comprehensive Test Suite**: Deferred per task.071 pattern
- ❌ **Content Auto-Application**: Suggestions only, no automatic edits
- ❌ **Real-time Monitoring**: Batch analysis only, no watch mode

## References

- Idea: .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-llm-integration.md
- Parent Task (completed): .ace-taskflow/v.0.9.0/tasks/done/071-docs-docs-complete-ace-docs-batch-analys/task.071.md
- Prerequisite Task: .ace-taskflow/v.0.9.0/tasks/073-feat-docs-complete-documented-ace-docs-f/task.073.md
- Related: .ace-taskflow/v.0.9.0/ideas/20251013-ace-docs-llm-diff-summaries.md (analyze command in task.071)

## Technical Approach

### Architecture Pattern

**ATOM Architecture Application:**

- **Atoms**: `FeedbackPattern` (pattern matching), `ConfidenceScorer` (scoring logic), `TerminologyExtractor` (keyword extraction)
- **Molecules**: `RecommendationGenerator`, `ConsistencyAnalyzer`, `FeedbackManager`, `SuggestionFormatter`
- **Organisms**: `RecommendationEngine`, `CrossDocumentAnalyzer`, `RelevanceLearner`
- **Commands**: `RecommendCommand`, `SuggestCommand`, `AnalyzeConsistencyCommand`, `FeedbackCommand`
- **Models**: `Recommendation`, `Suggestion`, `ConsistencyReport`, `FeedbackEntry`

**Integration Pattern:**

- Follows task.071 pattern: LLM integration via ace-llm-query subprocess
- Each command is independent and focused on single responsibility
- Feedback storage in YAML format (`.ace/docs/feedback.yml`)
- Commands return structured data + status codes

**Key Architectural Decisions:**

1. Separate commands for each feature (recommend, suggest, analyze-consistency, feedback)
2. LLM integration via subprocess (consistent with existing pattern)
3. Feedback storage in config location (not cache - persistent learning)
4. Confidence scoring system for prioritization
5. Interactive mode via --apply flag (similar to analyze command)

### Technology Stack

**Core Dependencies (No New Gems Required):**

- **Ruby**: 3.1+ (existing ace-* standard)
- **ace-core**: Configuration management (~> 0.9)
- **Thor**: CLI framework (~> 1.3, existing)
- **YAML**: Feedback storage (stdlib)
- **Open3**: Subprocess calls (stdlib)

**Subprocess Integrations:**

- **ace-llm-query**: LLM calls (installed, via bin/ace-llm-query)
- **git**: Diff generation (required, existing)

**Development Dependencies:**

- **ace-test-support**: Shared testing infrastructure
- **minitest**: Test framework (~> 5.19)

**LLM Configuration by Feature:**

- **Content Recommendations**: Temperature 0.5 (balanced creativity/consistency)
- **Smart Suggestions**: Temperature 0.7 (more creative for suggestions)
- **Cross-Document Analysis**: Temperature 0.3 (deterministic for consistency checking)
- **Model Selection**: Use ace-llm-query defaults (configurable via .ace/docs/config.yml)

### Implementation Strategy

**Phase Structure:**

1. **Foundation** (2-3h): Feedback storage and management system
2. **Content Recommendations** (3-4h): Implement recommend command with LLM
3. **Smart Suggestions** (2-3h): Implement suggest command with multiple modes
4. **Cross-Document Analysis** (2-3h): Implement analyze-consistency command
5. **Integration & Polish** (2-3h): Interactive modes, error handling, documentation

**Note**: Following task.071 pattern - comprehensive tests deferred to future task

**Testing Strategy:**

- Mock ace-llm-query subprocess calls
- Fixture-based testing with sample documents and responses
- Manual testing for interactive modes
- Test coverage target: Demonstrate functionality, defer comprehensive suite

**Rollback Considerations:**

- New commands can be removed independently
- No changes to existing commands (status, diff, analyze, update, validate)
- Feedback storage is isolated in separate file
- No database migrations or schema changes required

## Tool Selection

### Evaluation Criteria

| Criteria | Assessment | Notes |
|----------|------------|-------|
| Performance | Excellent | Single LLM call per operation, minimal overhead |
| Integration | Excellent | ace-llm-query already integrated and tested |
| Maintenance | Excellent | Subprocess pattern is stable and proven |
| Learning Curve | Low | Follows existing patterns from task.071 |

### Selection Matrix

| Feature | Tool/Approach | Rationale |
|---------|---------------|-----------|
| LLM Integration | ace-llm-query (subprocess) | Consistent with task.071, already proven |
| Feedback Storage | YAML in .ace/docs/ | Consistent with config system, human-editable |
| Pattern Matching | Ruby Regexp | Native, sufficient for pattern matching |
| Confidence Scoring | Custom algorithm | Simple weighted scoring, no library needed |
| Subprocess Calls | Open3.capture3 | Ruby stdlib, proven in DiffAnalyzer |

### Dependencies

**No New Dependencies Required** - All features implementable with existing stack:
- ace-core for configuration ✓
- ace-llm-query for LLM calls ✓
- Thor for CLI ✓
- Ruby stdlib (YAML, Open3, Regexp) ✓

## File Modifications

### Create

**New Commands:**

- `ace-docs/lib/ace/docs/commands/recommend_command.rb`
  - Purpose: Content recommendation command implementation
  - Key components: Document selection, change analysis, recommendation generation
  - Dependencies: RecommendationEngine, RecommendationGenerator

- `ace-docs/lib/ace/docs/commands/suggest_command.rb`
  - Purpose: Smart suggestions command implementation
  - Key components: Document analysis, suggestion modes (clarity/completeness/consistency)
  - Dependencies: SuggestionFormatter, ace-llm-query

- `ace-docs/lib/ace/docs/commands/analyze_consistency_command.rb`
  - Purpose: Cross-document analysis command
  - Key components: Document set analysis, terminology conflicts, duplicate detection
  - Dependencies: CrossDocumentAnalyzer

- `ace-docs/lib/ace/docs/commands/feedback_command.rb`
  - Purpose: Relevance feedback command implementation
  - Key components: Feedback storage, pattern learning, scope management
  - Dependencies: FeedbackManager

**New Molecules:**

- `ace-docs/lib/ace/docs/molecules/recommendation_generator.rb`
  - Purpose: Generate actionable recommendations from changes
  - Key components: Change analysis, recommendation formatting, priority assignment
  - Methods: `generate(changes, document)`, `prioritize(recommendations)`

- `ace-docs/lib/ace/docs/molecules/consistency_analyzer.rb`
  - Purpose: Analyze consistency across multiple documents
  - Key components: Terminology extraction, conflict detection, duplicate identification
  - Methods: `analyze_set(documents)`, `find_conflicts()`, `detect_duplicates()`

- `ace-docs/lib/ace/docs/molecules/feedback_manager.rb`
  - Purpose: Manage feedback storage and retrieval
  - Key components: YAML I/O, pattern matching, scope resolution
  - Methods: `store_feedback(pattern, type, scope)`, `get_relevance_score(pattern, document)`

- `ace-docs/lib/ace/docs/molecules/suggestion_formatter.rb`
  - Purpose: Format suggestion results for display
  - Key components: Suggestion grouping, priority display, formatting
  - Methods: `format(suggestions, mode)`, `group_by_type(suggestions)`

**New Atoms:**

- `ace-docs/lib/ace/docs/atoms/feedback_pattern.rb`
  - Purpose: Pattern matching for feedback system
  - Key components: Pattern compilation, matching logic
  - Methods: `match?(pattern, text)`, `compile_pattern(pattern)`

- `ace-docs/lib/ace/docs/atoms/confidence_scorer.rb`
  - Purpose: Calculate confidence scores for recommendations
  - Key components: Weighted scoring, threshold checking
  - Methods: `score(recommendation)`, `above_threshold?(score)`

- `ace-docs/lib/ace/docs/atoms/terminology_extractor.rb`
  - Purpose: Extract key terminology from documents
  - Key components: Keyword extraction, frequency analysis
  - Methods: `extract(content)`, `find_conflicts(term_sets)`

**New Organisms:**

- `ace-docs/lib/ace/docs/organisms/recommendation_engine.rb`
  - Purpose: Orchestrate recommendation generation
  - Key components: Change analysis, LLM integration, recommendation assembly
  - Methods: `recommend(document, since)`, `apply_feedback_learning(recommendations)`

- `ace-docs/lib/ace/docs/organisms/cross_document_analyzer.rb`
  - Purpose: Orchestrate cross-document consistency analysis
  - Key components: Document set processing, LLM analysis, report generation
  - Methods: `analyze(documents)`, `find_inconsistencies()`

- `ace-docs/lib/ace/docs/organisms/relevance_learner.rb`
  - Purpose: Learn from user feedback to improve relevance scoring
  - Key components: Feedback aggregation, pattern weighting, score adjustment
  - Methods: `learn_from_feedback(feedback_entries)`, `adjust_scores(patterns)`

**New Models:**

- `ace-docs/lib/ace/docs/models/recommendation.rb`
  - Purpose: Data model for recommendations
  - Fields: priority, location, suggestion, reasoning, confidence
  - Methods: `to_h`, `to_s`, `high_priority?`

- `ace-docs/lib/ace/docs/models/suggestion.rb`
  - Purpose: Data model for suggestions
  - Fields: type (clarity/completeness/consistency), description, section, severity
  - Methods: `to_h`, `to_s`

- `ace-docs/lib/ace/docs/models/consistency_report.rb`
  - Purpose: Data model for consistency analysis reports
  - Fields: conflicts, duplicates, version_issues, consolidation_opportunities
  - Methods: `to_markdown`, `save_to_cache(cache_dir)`

- `ace-docs/lib/ace/docs/models/feedback_entry.rb`
  - Purpose: Data model for feedback entries
  - Fields: pattern, feedback_type, document_scope, global, timestamp
  - Methods: `to_h`, `matches?(pattern)`

**New Prompts:**

- `ace-docs/lib/ace/docs/prompts/recommend_prompt.rb`
  - Purpose: Build LLM prompts for content recommendations
  - Key components: Document context, change summary, output format instructions
  - Methods: `build(document, changes)`, `format_changes(changes)`

- `ace-docs/lib/ace/docs/prompts/suggest_prompt.rb`
  - Purpose: Build LLM prompts for smart suggestions
  - Key components: Document content, analysis mode, evaluation criteria
  - Methods: `build(document, mode)`, `mode_instructions(mode)`

- `ace-docs/lib/ace/docs/prompts/consistency_prompt.rb`
  - Purpose: Build LLM prompts for consistency analysis
  - Key components: Document set, analysis type, conflict identification
  - Methods: `build(documents, analysis_type)`, `format_document_set(documents)`

**Test Files** (Follow task.071 pattern - deferred):

- `test/commands/recommend_command_test.rb`
- `test/commands/suggest_command_test.rb`
- `test/commands/analyze_consistency_command_test.rb`
- `test/commands/feedback_command_test.rb`
- `test/molecules/recommendation_generator_test.rb`
- `test/molecules/consistency_analyzer_test.rb`
- `test/molecules/feedback_manager_test.rb`
- `test/molecules/suggestion_formatter_test.rb`
- `test/atoms/feedback_pattern_test.rb`
- `test/atoms/confidence_scorer_test.rb`
- `test/atoms/terminology_extractor_test.rb`
- `test/organisms/recommendation_engine_test.rb`
- `test/organisms/cross_document_analyzer_test.rb`
- `test/organisms/relevance_learner_test.rb`
- `test/models/recommendation_test.rb`
- `test/models/suggestion_test.rb`
- `test/models/consistency_report_test.rb`
- `test/models/feedback_entry_test.rb`
- `test/prompts/recommend_prompt_test.rb`
- `test/prompts/suggest_prompt_test.rb`
- `test/prompts/consistency_prompt_test.rb`

### Modify

**Existing ace-docs Files:**

- `ace-docs/exe/ace-docs`
  - Changes: Add `recommend`, `suggest`, `analyze-consistency`, `feedback` commands
  - Impact: New commands accessible via CLI
  - Integration points: Commands delegated to new command classes

- `ace-docs/lib/ace/docs.rb`
  - Changes: Add requires for new modules (organisms, commands, models, prompts)
  - Impact: New components accessible in module namespace
  - Integration points: Module loading

- `ace-docs/lib/ace/docs/version.rb`
  - Changes: Bump version to 0.4.0 (new features)
  - Impact: Version tracking
  - Integration points: Gem version

- `ace-docs/README.md`
  - Changes: Add documentation for new commands
  - Impact: User-facing documentation
  - Integration points: Command examples, feature descriptions

- `ace-docs/CHANGELOG.md`
  - Changes: Add v0.4.0 section with new features
  - Impact: Version history
  - Integration points: Release notes

**Configuration Files:**

- `.ace.example/docs/config.yml`
  - Changes: Add LLM configuration section for new features
  - Impact: Example configuration for users
  - Integration points: Temperature settings, model selection per feature

### Delete

**No Files to Delete:**

- All changes are additive
- Existing functionality preserved
- No deprecated components removed

## Test Case Planning

### Test Scenarios

**Happy Path Scenarios:**

1. **Content Recommendations - Basic**
   - Input: `ace-docs recommend docs/architecture.md`
   - Expected: List of HIGH/MEDIUM/LOW priority recommendations with locations
   - Test: Mock recent changes, verify recommendation structure

2. **Smart Suggestions - Clarity Mode**
   - Input: `ace-docs suggest docs/guide.md --clarity`
   - Expected: Clarity-focused suggestions with specific improvements
   - Test: Mock LLM response with clarity issues

3. **Cross-Document Analysis - Terminology**
   - Input: `ace-docs analyze-consistency docs/ --fix-terminology`
   - Expected: Report of terminology conflicts across documents
   - Test: Create docs with conflicting terms, verify detection

4. **Feedback - Mark Pattern Relevant**
   - Input: `ace-docs feedback --relevant "test changes" --document docs/arch.md`
   - Expected: Feedback stored, future relevance scores adjusted
   - Test: Store feedback, verify YAML file created

**Edge Case Scenarios:**

1. **No Recommendations Available**
   - Input: `ace-docs recommend docs/current.md` (up-to-date doc)
   - Expected: Message "No recommendations at this time"
   - Test: Mock empty change set

2. **Suggestions on Perfect Document**
   - Input: `ace-docs suggest docs/perfect.md --all`
   - Expected: "No suggestions - document looks good"
   - Test: Mock LLM response with no issues

3. **Consistency Analysis on Single File**
   - Input: `ace-docs analyze-consistency docs/single.md`
   - Expected: Expand to find related documents automatically
   - Test: Verify automatic related document discovery

4. **Conflicting Feedback**
   - Input: User marks same pattern both relevant and irrelevant
   - Expected: Prompt to resolve conflict
   - Test: Detect conflict, verify resolution flow

**Error Condition Scenarios:**

1. **ace-llm-query Unavailable**
   - Input: Run any LLM-dependent command without ace-llm-query
   - Expected: Clear error with installation instructions
   - Test: Mock command not found

2. **LLM API Timeout**
   - Input: Command with API timeout
   - Expected: Error message with retry suggestion
   - Test: Mock subprocess timeout

3. **Invalid Feedback Pattern**
   - Input: `ace-docs feedback --relevant "invalid[regex"`
   - Expected: Error with valid pattern examples
   - Test: Verify pattern validation

4. **Missing Document for Feedback**
   - Input: `ace-docs feedback --relevant "pattern" --document nonexistent.md`
   - Expected: Error that document doesn't exist
   - Test: Verify document validation

**Integration Point Scenarios:**

1. **Recommendations with Feedback Learning**
   - Input: Generate recommendations after storing relevant feedback
   - Expected: Recommendations prioritized based on learned relevance
   - Test: Verify feedback affects scoring

2. **Interactive Apply Mode**
   - Input: `ace-docs recommend docs/arch.md --apply`
   - Expected: Interactive prompts to apply each recommendation
   - Test: Mock user input (y/n responses)

3. **Batch Suggestions**
   - Input: `ace-docs suggest "docs/**/*.md" --completeness`
   - Expected: Suggestions for all matched documents
   - Test: Verify batch processing with progress

### Test Type Categorization

**Unit Tests (High Priority - Deferred):**

- FeedbackPattern atom (pattern matching logic)
- ConfidenceScorer atom (scoring calculations)
- TerminologyExtractor atom (keyword extraction)
- Recommendation, Suggestion, FeedbackEntry models (data structures)
- Prompt builders (prompt construction)

**Integration Tests (Medium Priority - Deferred):**

- Commands with mocked ace-llm-query subprocess
- FeedbackManager with YAML I/O
- RecommendationEngine with change detection and LLM
- CrossDocumentAnalyzer with multiple documents

**End-to-End Tests (Context Dependent):**

- Full recommend → feedback → recommend flow
- Cross-document analysis with real document set
- Interactive mode user flows

**Manual Tests (This Task - REQUIRED):**

- Test each command with real documents
- Verify LLM integration works correctly
- Test interactive modes
- Verify feedback storage and learning
- Check all error handling paths

### Test Coverage Expectations

**Following task.071 pattern - comprehensive test suite deferred:**

- Manual testing: 100% (required before completion)
- Automated tests: Minimal (demonstrate key functionality only)
- Code coverage: Not measured (consistent with parent task)
- Focus: Functional validation, not comprehensive test coverage

## Implementation Plan

### Planning Steps

* [ ] Review task.071 implementation patterns
  - Read DiffAnalyzer for subprocess pattern
  - Read AnalyzeCommand for command structure
  - Read CompactDiffPrompt for prompt building
  - Document integration approaches

* [ ] Design LLM prompt templates for each feature
  - Recommendation prompt: Document context + changes → specific suggestions
  - Suggestion prompt: Document content + mode → quality feedback
  - Consistency prompt: Document set → conflicts and duplicates
  - Test prompts manually with ace-llm-query

* [ ] Design feedback storage format
  - YAML structure: patterns, types, scopes, timestamps
  - Location: `.ace/docs/feedback.yml`
  - Schema: Document fields and nesting
  - Plan migration/upgrade path

* [ ] Design confidence scoring algorithm
  - Factors: change size, document relevance, feedback history
  - Weights: HIGH (>0.7), MEDIUM (0.4-0.7), LOW (<0.4)
  - Threshold tuning: Test with sample data
  - Document scoring rationale

* [ ] Design interactive mode UX
  - Prompt format: Show recommendation + options (y/n/skip/quit)
  - Progress tracking: X of Y processed
  - Undo/rollback: Not in v1, document for future
  - Exit handling: Graceful on Ctrl+C

### Execution Steps

**Phase 1: Foundation (Feedback System) - 2-3 hours**

- [ ] **Step 1: Create feedback storage structure**
  - Create FeedbackEntry model with fields: pattern, type, scope, timestamp
  - Add validation: pattern must be valid regex, type must be valid enum
  - Add serialization methods: to_h, from_h
  - Test: Create and serialize feedback entries
  > TEST: Feedback Entry Model
  > Type: Unit Test
  > Assert: FeedbackEntry can be created, validated, serialized
  > Command: ruby -I lib -r ace/docs/models/feedback_entry -e "puts FeedbackEntry.new(...).to_h"

- [ ] **Step 2: Implement FeedbackManager molecule**
  - Create feedback_manager.rb with YAML I/O
  - Methods: `store_feedback(pattern, type, scope)`, `load_feedback()`, `get_relevance_score(pattern, doc)`
  - Handle file creation, locking for concurrent access
  - Test: Store and retrieve feedback, verify YAML format
  > TEST: Feedback Storage
  > Type: Integration Test
  > Assert: Feedback stored in YAML, retrieved correctly
  > Command: Test store → load → verify cycle

- [ ] **Step 3: Create FeedbackCommand**
  - Parse options: --relevant, --irrelevant, --critical, --ignore, --document, --global
  - Validate: pattern, document existence (if specified)
  - Store feedback via FeedbackManager
  - Display confirmation message
  - Return status code (0 success, 1 error)
  > TEST: Feedback Command
  > Type: Integration Test
  > Assert: Command stores feedback, displays confirmation
  > Command: ace-docs feedback --relevant "test" --document docs/test.md

**Phase 2: Content Recommendations - 3-4 hours**

- [ ] **Step 4: Create Recommendation model**
  - Fields: priority (HIGH/MEDIUM/LOW), location, suggestion, reasoning, confidence
  - Methods: to_h, to_s, high_priority?, medium_priority?, low_priority?
  - Validation: priority must be valid enum, confidence 0.0-1.0
  - Test: Create recommendations with various priorities

- [ ] **Step 5: Create RecommendPrompt prompt builder**
  - Build prompt with: document context, changes summary, output format
  - System prompt: "Analyze changes and recommend specific document updates"
  - Include document type, purpose for context
  - Specify output format: priority, location, suggestion, reasoning
  - Test: Generate prompts, verify structure

- [ ] **Step 6: Implement RecommendationGenerator molecule**
  - Method: `generate(changes, document)` calls ace-llm-query
  - Use Open3.capture3 pattern from DiffAnalyzer
  - Parse LLM response into Recommendation objects
  - Calculate confidence scores
  - Handle errors: LLM unavailable, parsing failures
  - Test: Mock subprocess, verify recommendation generation
  > TEST: Recommendation Generation
  > Type: Integration Test
  > Assert: Changes → recommendations with priorities
  > Command: Mock LLM response, verify parsing

- [ ] **Step 7: Implement ConfidenceScorer atom**
  - Method: `score(recommendation, document, feedback)` calculates confidence
  - Factors: change magnitude, document type match, feedback history
  - Return score 0.0-1.0
  - Test: Score various recommendations, verify ranges

- [ ] **Step 8: Create RecommendationEngine organism**
  - Orchestrate: change detection → recommendation generation → confidence scoring
  - Apply feedback learning: adjust scores based on history
  - Filter: remove low-confidence recommendations (configurable threshold)
  - Sort: by priority then confidence
  - Test: End-to-end flow with mocked dependencies

- [ ] **Step 9: Create RecommendCommand**
  - Parse options: FILE, --since, --priority LEVEL, --format (text/json), --apply
  - Select document (explicit or discover)
  - Call RecommendationEngine
  - Format output: group by priority, show location/suggestion/reasoning
  - Handle --apply: interactive mode for each recommendation
  - Return status code
  > TEST: Recommend Command
  > Type: End-to-End Test
  > Assert: Command generates and displays recommendations
  > Command: ace-docs recommend docs/architecture.md (with mocked LLM)

**Phase 3: Smart Suggestions - 2-3 hours**

- [ ] **Step 10: Create Suggestion model**
  - Fields: type (clarity/completeness/consistency), description, section, severity
  - Methods: to_h, to_s, severity_color()
  - Validation: type and severity enums
  - Test: Create suggestions with various types

- [ ] **Step 11: Create SuggestPrompt prompt builder**
  - Method: `build(document, mode)` constructs analysis prompt
  - Mode-specific instructions:
    - clarity: Focus on readability, explanation quality
    - completeness: Check for missing sections, gaps
    - consistency: Check internal consistency, contradictions
    - all: Comprehensive analysis
  - Specify output format: type, description, section, severity
  - Test: Generate prompts for each mode

- [ ] **Step 12: Implement SuggestionFormatter molecule**
  - Method: `format(suggestions, mode)` organizes and formats
  - Group by: severity (HIGH/MEDIUM/LOW) within each type
  - Color coding: severity-based colors
  - Summary: count by type and severity
  - Test: Format various suggestion sets

- [ ] **Step 13: Create SuggestCommand**
  - Parse options: FILE, --clarity, --completeness, --consistency, --all, --model, --format
  - Call ace-llm-query with mode-specific prompt
  - Parse response into Suggestion objects
  - Format and display via SuggestionFormatter
  - Return status code
  > TEST: Suggest Command
  > Type: End-to-End Test
  > Assert: Command analyzes and suggests improvements
  > Command: ace-docs suggest docs/guide.md --clarity

**Phase 4: Cross-Document Analysis - 2-3 hours**

- [ ] **Step 14: Create ConsistencyReport model**
  - Fields: conflicts (terminology), duplicates, version_issues, consolidation_opportunities
  - Methods: to_markdown, to_h, has_issues?, issue_count
  - Format: Organized sections with examples
  - Test: Create reports, verify markdown generation

- [ ] **Step 15: Create TerminologyExtractor atom**
  - Method: `extract(content)` finds key terms
  - Simple approach: word frequency, filter common words
  - Return: list of {term, count, locations}
  - Method: `find_conflicts(term_sets)` identifies mismatches
  - Test: Extract from sample documents

- [ ] **Step 16: Create ConsistencyPrompt prompt builder**
  - Method: `build(documents, analysis_type)` constructs prompt
  - Include document excerpts, types, purposes
  - Analysis types: terminology, duplicates, versions, all
  - Specify output format: structured conflict/duplicate reports
  - Test: Generate prompts for document sets

- [ ] **Step 17: Implement ConsistencyAnalyzer molecule**
  - Method: `analyze_set(documents, type)` performs analysis
  - Pre-analysis: TerminologyExtractor for quick wins
  - LLM analysis: Deep semantic consistency check
  - Combine results: Merge pre-analysis + LLM findings
  - Error handling: LLM failures, large document sets
  - Test: Analyze sample document sets

- [ ] **Step 18: Create CrossDocumentAnalyzer organism**
  - Orchestrate: document loading → consistency analysis → report generation
  - Handle large sets: batch processing if >20 documents
  - Progress reporting: "Analyzing X of Y documents..."
  - Create ConsistencyReport
  - Cache report: `.cache/ace-docs/consistency-{timestamp}.md`
  - Test: End-to-end analysis

- [ ] **Step 19: Create AnalyzeConsistencyCommand**
  - Parse options: PATTERN, --type (terminology/duplicates/versions/all), --fix-terminology, etc.
  - Select documents: glob pattern or all managed docs
  - Call CrossDocumentAnalyzer
  - Display report: formatted output
  - Save to cache: with timestamp
  - Return status code
  > TEST: Analyze Consistency Command
  > Type: End-to-End Test
  > Assert: Command analyzes and reports inconsistencies
  > Command: ace-docs analyze-consistency docs/ --type terminology

**Phase 5: Integration & Polish - 2-3 hours**

- [ ] **Step 20: Add commands to CLI (exe/ace-docs)**
  - Add Thor command definitions: recommend, suggest, analyze_consistency, feedback
  - Add help text and option descriptions
  - Delegate to command classes
  - Test: Verify all commands accessible via CLI

- [ ] **Step 21: Implement interactive mode for recommend**
  - Add --apply flag handling
  - For each recommendation: display + prompt (Apply? y/n/skip/quit)
  - Track: applied count, skipped count
  - Handle: Ctrl+C gracefully
  - Display summary at end
  - Test: Manual test with various user inputs
  > TEST: Interactive Mode
  > Type: Manual Test
  > Assert: Interactive prompts work, changes applied correctly
  > Command: ace-docs recommend docs/test.md --apply

- [ ] **Step 22: Add relevance learning integration**
  - In RecommendationEngine: load feedback, adjust scores
  - Apply weights: relevant (+0.2), irrelevant (-0.2), critical (+0.5), ignore (-1.0)
  - Filter: remove recommendations matching "ignore" patterns
  - Test: Verify feedback affects recommendation prioritization

- [ ] **Step 23: Update configuration examples**
  - Update `.ace.example/docs/config.yml`
  - Add sections for: recommendation settings, suggestion modes, consistency analysis
  - Document: temperature settings per feature, model selection
  - Example feedback patterns
  - Test: Load config, verify parsing

- [ ] **Step 24: Create comprehensive error handling**
  - Consistent error messages across commands
  - Error codes: 0 (success), 1 (invalid input), 2 (no results), 3 (LLM error), 4 (system error)
  - User-friendly messages with suggestions
  - Logging: optional debug mode (--debug flag)
  - Test: Trigger various errors, verify handling

- [ ] **Step 25: Update documentation**
  - Update README.md: add new commands section
  - Update CHANGELOG.md: v0.4.0 release notes
  - Create comprehensive examples for each command
  - Document feedback system and learning
  - Document interactive modes
  > TEST: Documentation Complete
  > Type: Manual Review
  > Assert: All new features documented with examples
  > Command: Review README.md, verify accuracy

- [ ] **Step 26: Manual end-to-end testing**
  - Test recommend: on real document with real changes
  - Test suggest: all modes on various document types
  - Test analyze-consistency: on real documentation set
  - Test feedback: store various patterns, verify learning
  - Test interactive mode: apply recommendations
  - Test error cases: missing ace-llm-query, invalid inputs
  - Test performance: large document sets, long prompts
  > TEST: Complete Manual Validation
  > Type: Manual End-to-End Test
  > Assert: All features working as specified
  > Command: Manual test plan execution

- [ ] **Step 27: Version bump and changelog**
  - Update ace-docs/lib/ace/docs/version.rb: VERSION = "0.4.0"
  - Update CHANGELOG.md: Add v0.4.0 section
  - List all new features, commands, breaking changes (if any)
  > TEST: Version Updated
  > Type: Validation
  > Assert: Version and changelog reflect new release
  > Command: grep "0.4.0" ace-docs/lib/ace/docs/version.rb && grep "0.4.0" ace-docs/CHANGELOG.md

## Risk Assessment

### Technical Risks

- **Risk**: LLM response format variability (parsing failures)
  - **Probability**: Medium
  - **Impact**: Medium (recommendations/suggestions fail to parse)
  - **Mitigation**:
    - Robust parsing with fallbacks
    - Clear output format instructions in prompts
    - Graceful degradation: show raw LLM output if parsing fails
  - **Rollback**: Disable affected command, fall back to basic analysis

- **Risk**: Feedback learning creates incorrect biases
  - **Probability**: Low-Medium
  - **Impact**: Medium (recommendations become less useful)
  - **Mitigation**:
    - Feedback weights are conservative (+/- 0.2, not +/- 1.0)
    - Users can clear feedback via editing .ace/docs/feedback.yml
    - Document feedback system clearly
    - Add --reset-feedback flag to clear learning
  - **Rollback**: Delete feedback file, system reverts to no learning

- **Risk**: Large document sets exceed LLM context limits
  - **Probability**: Medium
  - **Impact**: Medium (consistency analysis fails)
  - **Mitigation**:
    - Batch processing for >20 documents
    - Warn user about limits
    - Suggest filtering: --type, specific directories
    - Pre-analysis with TerminologyExtractor (no LLM)
  - **Rollback**: Graceful failure with clear error message

- **Risk**: Interactive mode state management complexity
  - **Probability**: Low
  - **Impact**: Low (interactive mode has issues)
  - **Mitigation**:
    - Keep state simple: just track applied/skipped counts
    - No undo in v1 (document for future)
    - Clear exit handling (Ctrl+C)
  - **Rollback**: Remove --apply flag, keep non-interactive mode

### Integration Risks

- **Risk**: ace-llm-query version incompatibility
  - **Probability**: Low
  - **Impact**: High (all LLM features fail)
  - **Mitigation**:
    - Test with current ace-llm-query version
    - Document minimum version requirement
    - Graceful error: "ace-llm-query not found or too old"
  - **Monitoring**: Check subprocess availability on command start

- **Risk**: YAML feedback file corruption
  - **Probability**: Low
  - **Impact**: Low (feedback loading fails)
  - **Mitigation**:
    - Validate YAML on load, clear error message
    - Backup on write: feedback.yml.bak
    - Document manual recovery (edit or delete file)
  - **Monitoring**: YAML parse errors

- **Risk**: Concurrent feedback writes (race condition)
  - **Probability**: Very Low
  - **Impact**: Low (feedback entry lost or duplicated)
  - **Mitigation**:
    - File locking during write operations
    - Atomic write pattern: write to temp, then rename
    - Document limitation: not designed for high concurrency
  - **Monitoring**: Log concurrent write attempts

### Performance Risks

- **Risk**: Multiple LLM calls slow workflow (5-30s each)
  - **Mitigation**:
    - Single LLM call per command invocation
    - Progress indicators: "Generating recommendations..."
    - Document expected wait times
    - No parallel calls in v1 (future optimization)
  - **Monitoring**: Log LLM call duration
  - **Thresholds**: Warn if >60s

- **Risk**: Consistency analysis on 50+ documents is very slow
  - **Mitigation**:
    - Batch processing with progress: "Analyzing 10/50..."
    - Cache results: reuse recent analysis if documents unchanged
    - Suggest filtering: specific document types or directories
  - **Monitoring**: Track document count, analysis time
  - **Thresholds**: Warn if >50 documents

- **Risk**: Feedback file grows large over time (degraded I/O)
  - **Mitigation**:
    - Efficient YAML structure (not too nested)
    - Periodic cleanup: remove old entries (>6 months)
    - Document cleanup strategy
    - Add --prune-feedback command (future)
  - **Monitoring**: Log feedback file size
  - **Thresholds**: Warn if >1MB

### User Experience Risks

- **Risk**: Interactive mode is confusing or cumbersome
  - **Mitigation**:
    - Clear prompts: "Apply this recommendation? (y)es, (n)o, (s)kip, (q)uit"
    - Help text: show at start of interactive session
    - Progress: "Recommendation 3 of 10"
    - Summary: "Applied 5, skipped 3, cancelled 2"
  - **Monitoring**: User testing feedback

- **Risk**: Recommendations are too vague or not actionable
  - **Mitigation**:
    - Prompt engineering: emphasize "specific location and wording"
    - Examples in prompt: show desired output format
    - Temperature tuning: 0.5 balances creativity and specificity
    - Feedback system: users can mark vague recommendations as irrelevant
  - **Monitoring**: Manual review of recommendation quality

## Acceptance Criteria

- [ ] **Content Recommendations Functional**: `ace-docs recommend` analyzes changes and provides actionable suggestions
- [ ] **Priority Levels Accurate**: Recommendations correctly prioritized as HIGH/MEDIUM/LOW based on impact
- [ ] **Smart Suggestions Work**: `ace-docs suggest` analyzes documents with clarity/completeness/consistency modes
- [ ] **Multiple Modes Supported**: --clarity, --completeness, --consistency, --all flags all functional
- [ ] **Cross-Document Analysis Functional**: `ace-docs analyze-consistency` identifies conflicts and duplicates
- [ ] **Terminology Conflicts Detected**: System finds and reports terminology inconsistencies
- [ ] **Feedback System Operational**: `ace-docs feedback` stores relevance patterns persistently
- [ ] **Feedback Learning Active**: Recommendations prioritized based on user feedback history
- [ ] **Interactive Mode Available**: --apply flag enables interactive recommendation application
- [ ] **Interactive Mode UX Good**: Clear prompts, progress tracking, graceful exit handling
- [ ] **Error Handling Complete**: All error scenarios have clear, actionable messages
- [ ] **Performance Acceptable**: Single operation completes in <60s for typical use cases
- [ ] **Documentation Complete**: README, usage.md, and examples cover all new features
- [ ] **Configuration Documented**: Example configs show all new settings
- [ ] **Manual Testing Passed**: All commands tested with real documents, edge cases verified
