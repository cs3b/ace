---
id: v.0.9.0+task.074
status: draft
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
