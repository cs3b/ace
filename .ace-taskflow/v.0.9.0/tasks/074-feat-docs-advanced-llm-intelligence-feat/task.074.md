---
id: v.0.9.0+task.074
status: in-progress
priority: medium
estimate: 3-4h
dependencies: [v.0.9.0+task.073]
---

# Cross-Document Consistency Analysis for ace-docs

## Behavioral Specification

### User Experience

- **Input**: Set of documents to analyze for consistency (pattern or --all)
- **Process**: LLM analyzes documents for terminology conflicts, duplicate content, version inconsistencies
- **Output**: Structured consistency report showing conflicts, duplicates, version issues, and consolidation opportunities

### Expected Behavior

**Cross-Document Analysis Command:**

Detect problems across multiple documents:
```bash
ace-docs analyze-consistency docs/
# Returns:
# - Terminology conflict: "gem" vs "package" (5 documents)
# - Duplicate content: Installation steps in README.md and docs/guide.md
# - Inconsistent versions: README shows 0.3.0, CHANGELOG shows 0.3.2
# - Consolidation opportunity: 3 documents explain same workflow
```

**Analysis Modes:**
```bash
# Full analysis (default)
ace-docs analyze-consistency docs/ --all

# Specific checks
ace-docs analyze-consistency docs/ --terminology    # Term conflicts only
ace-docs analyze-consistency docs/ --duplicates     # Duplicate content only
ace-docs analyze-consistency docs/ --versions       # Version conflicts only
```

**Output Format:**
```markdown
# Cross-Document Consistency Report

Generated: 2025-10-18 15:30:00
Documents analyzed: 12
Issues found: 8

## Terminology Conflicts (3)

### "gem" vs "package"
- README.md: uses "gem" (5 occurrences)
- docs/guide.md: uses "package" (8 occurrences)
- docs/install.md: mixed usage
Recommendation: Standardize to "gem" for Ruby context

### "analyze" vs "analyse"
- docs/workflow.md: "analyse" (UK spelling)
- All other docs: "analyze" (US spelling)
Recommendation: Standardize to "analyze"

## Duplicate Content (2)

### Installation Instructions
Files with duplicate content (85% similarity):
- README.md (lines 45-67)
- docs/getting-started.md (lines 12-34)
Recommendation: Keep in getting-started.md, reference from README

## Version Inconsistencies (2)

### ace-docs version
- README.md: "0.4.5"
- CHANGELOG.md: "0.4.6" (latest)
- docs/api.md: "0.4.4" (outdated)
Recommendation: Update all to 0.4.6

## Consolidation Opportunities (1)

### Workflow Instructions
Multiple documents explain similar workflow:
- docs/update-workflow.md
- docs/quick-update.md
- README.md (section "Updating Documents")
Recommendation: Consolidate into single workflow document
```

### Interface Contract

```bash
ace-docs analyze-consistency [PATTERN] [OPTIONS]
  --all                 # All analysis types (default)
  --terminology         # Check terminology conflicts only
  --duplicates          # Find duplicate content only
  --versions            # Check version consistency only
  --threshold PERCENT   # Similarity threshold for duplicates (default: 70)
  --output FORMAT       # Output format (text/json/markdown)
  --save                # Save report to cache directory
```

**Error Handling:**

- No documents found: Clear message with pattern help
- Single document: Expand to find related documents automatically
- LLM unavailable: Fallback to simple text analysis where possible
- Large document set (>50): Suggest filtering or warn about processing time

### Success Criteria

- [x] **Command Functional**: `ace-docs analyze-consistency` analyzes document sets
- [x] **Terminology Conflicts Detected**: Finds and reports word choice inconsistencies
- [x] **Duplicate Content Found**: Identifies similar content across documents
- [x] **Version Issues Caught**: Detects version number inconsistencies
- [x] **Clear Recommendations**: Each issue has actionable recommendation
- [x] **Performance Acceptable**: Analysis completes in <30s for typical doc sets

## Objective

Implement cross-document consistency analysis to help maintain documentation quality at scale. This high-value feature addresses real pain points in documentation maintenance by automatically detecting inconsistencies that are hard to spot manually.

## Scope of Work

### User Experience Scope

- **Cross-Document Analysis**: Find inconsistencies across documentation sets
- **Terminology Standardization**: Detect and suggest term standardization
- **Duplicate Detection**: Find redundant content that could be consolidated
- **Version Validation**: Ensure version numbers are consistent

### System Behavior Scope

- New `analyze-consistency` command
- Multiple analysis modes (terminology, duplicates, versions)
- LLM-powered semantic analysis
- Fallback to simple text analysis when LLM unavailable
- Structured report generation
- Cache report for future reference

### Deliverables

- Working `analyze-consistency` command
- Consistency report generation
- Documentation and examples
- Basic test coverage

## Out of Scope

- ❌ **Auto-Fix**: Only detection and recommendations, no automatic fixes
- ❌ **Learning System**: No feedback or relevance learning
- ❌ **Interactive Mode**: No --apply flag for this version
- ❌ **Real-time Monitoring**: Batch analysis only
- ❌ **Complex Scoring**: Simple detection without confidence scores

## Technical Approach

### Architecture Pattern

**ATOM Architecture:**

- **Atoms**: `TerminologyExtractor` (keyword extraction), `SimilarityChecker` (duplicate detection)
- **Molecules**: `ConsistencyAnalyzer` (analyze documents), `ReportFormatter` (format results)
- **Organisms**: `CrossDocumentAnalyzer` (orchestrate analysis)
- **Commands**: `AnalyzeConsistencyCommand` (CLI interface)
- **Models**: `ConsistencyReport` (data structure)

### Technology Stack

- Ruby 3.1+ (existing standard)
- ace-llm-query for LLM analysis (existing integration)
- YAML for report metadata
- Markdown for report output

### Implementation Strategy

1. **Terminology Extraction** (30min): Simple keyword frequency analysis
2. **Similarity Detection** (45min): Basic text comparison for duplicates
3. **LLM Integration** (1h): Semantic analysis via ace-llm-query
4. **Report Generation** (45min): Structured markdown output
5. **Command Implementation** (45min): CLI interface and options
6. **Testing & Documentation** (45min): Basic tests and usage docs

## File Modifications

### Create

**New Command:**
- `ace-docs/lib/ace/docs/commands/analyze_consistency_command.rb`
  - Parse options and arguments
  - Load documents based on pattern
  - Call CrossDocumentAnalyzer
  - Display/save report

**New Molecules:**
- `ace-docs/lib/ace/docs/molecules/consistency_analyzer.rb`
  - Analyze document set for conflicts
  - Coordinate terminology and duplicate checks
  - Call LLM for semantic analysis

- `ace-docs/lib/ace/docs/molecules/report_formatter.rb`
  - Format ConsistencyReport as markdown
  - Group issues by type
  - Add recommendations

**New Atoms:**
- `ace-docs/lib/ace/docs/atoms/terminology_extractor.rb`
  - Extract key terms from documents
  - Find term frequency
  - Identify conflicts

- `ace-docs/lib/ace/docs/atoms/similarity_checker.rb`
  - Compare text blocks for similarity
  - Calculate similarity percentage
  - Find duplicate sections

**New Organism:**
- `ace-docs/lib/ace/docs/organisms/cross_document_analyzer.rb`
  - Load document set
  - Run consistency analysis
  - Generate report
  - Handle caching

**New Model:**
- `ace-docs/lib/ace/docs/models/consistency_report.rb`
  - Store analysis results
  - Structure: conflicts, duplicates, versions, opportunities
  - Serialization methods

**New Prompt:**
- `ace-docs/lib/ace/docs/prompts/consistency_prompt.rb`
  - Build LLM prompt for semantic analysis
  - Include document excerpts
  - Request structured output

### Modify

- `ace-docs/exe/ace-docs`
  - Add `analyze_consistency` command
  - Add help text

- `ace-docs/lib/ace/docs.rb`
  - Add requires for new modules

- `ace-docs/README.md`
  - Add command documentation
  - Add examples

- `ace-docs/CHANGELOG.md`
  - Add unreleased section with new feature

## Implementation Plan

### Execution Steps

- [x] **Step 1: Create architecture diagram in task docs**
  - Document solution flow
  - Show component relationships
  - Explain data flow

- [x] **Step 2: Create ConsistencyPrompt**
  - Build system and user prompts for LLM
  - Define structured JSON response format
  - Include analysis guidelines

- [x] **Step 3: Create ConsistencyReport model**
  - Parse LLM JSON response
  - Format as markdown/json
  - Handle parsing failures gracefully

- [x] **Step 4: Create CrossDocumentAnalyzer organism**
  - Load documents from registry
  - Execute LLM query with timeout
  - Cache results
  - Return formatted report

- [x] **Step 5: Create AnalyzeConsistencyCommand**
  - Parse CLI options
  - Call analyzer
  - Display colored output
  - Support multiple output formats

- [x] **Step 6: Update CLI integration**
  - Add command to exe/ace-docs
  - Configure Thor options
  - Set up help text

- [x] **Step 7: Update documentation**
  - Comprehensive README with examples
  - CHANGELOG entry
  - Usage examples

- [x] **Step 8: Test command structure**
  - Verify help system works
  - Check command registration
  - Validate option parsing

## Risk Assessment

### Technical Risks

- **LLM response variability**: Mitigated by structured prompts and fallback to simple analysis
- **Large document sets**: Warn users, suggest filtering
- **Performance**: Single LLM call, efficient text analysis

### User Experience Risks

- **Too many false positives**: Adjustable thresholds, clear recommendations
- **Overwhelming output**: Group issues, prioritize by impact

## Acceptance Criteria

- [x] **Command works**: `ace-docs analyze-consistency` runs without errors
- [x] **Finds real issues**: Detects actual terminology conflicts and duplicates
- [x] **Useful output**: Clear, actionable recommendations
- [x] **Reasonable performance**: <30s for typical document sets
- [x] **Documentation complete**: README updated with examples