# Review Synthesizer Workflow Instruction

## Goal

Synthesize multiple code review reports into a unified, actionable improvement plan. This workflow takes multiple review outputs (from different LLM providers, focus areas, or review runs) and creates a consolidated analysis with resolved conflicts, prioritized recommendations, and clear implementation timeline.

## Prerequisites

- Multiple review reports in markdown format
- Review reports follow standard section formats (11-section structure)
- Access to `dev-handbook/templates/review-synthesizer/system.prompt.md`
- LLM query tools available (`dev-tools/exe/llm-query`)

## Command Structure

```
@review-synthesizer [reports-source]
```

### Parameters

- **reports-source** (required): Source of review reports to synthesize
  - `files:report1.md,report2.md,report3.md` - Specific report files
  - `dir:reviews/` - All .md files in directory
  - `stdin` - Reports provided via standard input (pipe)
  - `interactive` - Paste reports in interactive session

## High-Level Execution Plan

### Planning Steps

- [ ] Identify and validate review report sources
- [ ] Parse report formats and extract key sections
- [ ] Identify review types and focus areas covered
- [ ] Prepare synthesis prompt with all report content

### Execution Steps

- [ ] Load review synthesizer system prompt
- [ ] Aggregate all review reports into single input
- [ ] Execute LLM synthesis analysis
- [ ] Format and present unified recommendations
- [ ] Generate actionable task lists if requested

## Process Steps

### 1. Report Source Resolution

Based on reports-source parameter:

#### File-based Sources

```bash
# For specific files
IFS=',' read -ra FILES <<< "${files_list}"
for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "=== Report from $file ===" >> combined_reports.md
        cat "$file" >> combined_reports.md
        echo -e "\n\n" >> combined_reports.md
    fi
done
```

#### Directory-based Sources

```bash
# For directory of reports
for file in "$directory"/*.md; do
    if [[ -f "$file" ]]; then
        basename_file=$(basename "$file")
        echo "=== Report from $basename_file ===" >> combined_reports.md
        cat "$file" >> combined_reports.md
        echo -e "\n\n" >> combined_reports.md
    fi
done
```

#### Interactive/Stdin Sources

```bash
# For interactive input
echo "Paste review reports (end with EOF or Ctrl+D):"
cat > combined_reports.md
```

### 2. Report Validation and Parsing

Validate each report contains expected sections:

```bash
# Check for standard review sections
required_sections=(
    "Executive Summary"
    "Prioritised Action Items"
    "Approval Recommendation"
)

for section in "${required_sections[@]}"; do
    if ! grep -q "## .*$section" combined_reports.md; then
        echo "Warning: Missing '$section' in one or more reports"
    fi
done
```

### 3. Synthesis Prompt Construction

Build the complete synthesis prompt:

```
[SYNTHESIZER SYSTEM PROMPT]

# Review Reports to Synthesize

[COMBINED REVIEW REPORTS CONTENT]

Please synthesize these review reports following the structured format specified in the system prompt.
```

### 4. LLM Synthesis Execution

Execute the synthesis analysis:

```bash
# Use existing LLM tools
dev-tools/exe/llm-query [model] "[constructed-synthesis-prompt]"
```

### 5. Result Processing and Formatting

Process the synthesis output:

- Extract unified priority lists
- Format implementation timeline
- Generate summary statistics (if multiple providers)
- Create actionable task checklist format

### 6. Optional Task Generation

If requested, convert synthesis output to task format:

- Extract critical and high-priority items
- Format as actionable task list
- Include time estimates and dependencies
- Reference source reports for traceability

## Implementation Examples

### Example 1: Synthesize Multiple Provider Reports

```
@review-synthesizer files:gemini-review.md,claude-review.md,gpt-review.md
```

- Combines reports from different LLM providers
- Compares findings and recommendations
- Resolves conflicts and identifies consensus
- Provides cost-quality analysis if pricing data available

### Example 2: Synthesize Focus Area Reports

```
@review-synthesizer files:code-review.md,test-review.md,docs-review.md
```

- Combines different focus area reviews
- Creates integrated improvement plan
- Identifies cross-cutting issues
- Provides holistic development recommendations

### Example 3: Synthesize Directory of Reports

```
@review-synthesizer dir:./reviews/latest/
```

- Processes all markdown files in directory
- Useful for batch review processing
- Combines multiple review runs or experiments
- Provides comprehensive analysis overview

### Example 4: Interactive Synthesis

```
@review-synthesizer interactive
```

- Allows pasting of review reports directly
- Useful for ad-hoc synthesis tasks
- Supports copying reports from various sources
- Immediate analysis and recommendations

## Output Structure

The synthesizer produces structured output with these key sections:

### Executive Analysis

- Methodology overview
- Consensus analysis across reports
- Unique insights identification
- Conflict resolution documentation

### Actionable Recommendations

- Unified improvement plan with priority levels
- Implementation timeline with phases
- Quality assurance checklist
- Key takeaways and patterns

### Meta-Analysis (when applicable)

- Quality scoring of different providers
- Cost-effectiveness analysis
- Provider ranking and recommendations
- Optimal review strategy suggestions

## Success Criteria

- All input reports successfully parsed and analyzed
- Conflicts between reports identified and resolved
- Unified priority list created with clear action items
- Implementation timeline provides realistic development phases
- Consensus items clearly distinguished from unique insights
- Output follows structured format for automated processing

## Error Handling

- **Invalid report format**: Warn about missing sections, continue with available data
- **Conflicting recommendations**: Document conflicts explicitly, provide resolution rationale
- **No consensus found**: Highlight areas where reviewers disagree, suggest additional analysis
- **Missing critical data**: Request specific information needed for proper synthesis
- **LLM synthesis failure**: Retry with simplified prompt or manual aggregation fallback

## Integration Points

### With Review Commands

- Designed to consume output from `/review-code` command
- Compatible with all review focus areas (code, tests, docs, combined)
- Handles multiple provider review outputs seamlessly

### With Task Management

- Synthesis output can be converted to task format
- Priority levels map to task priority systems
- Implementation phases align with sprint planning
- Action items include effort estimates when available

### With Quality Assurance

- Provides quality scoring for review provider comparison
- Identifies gaps in review coverage
- Suggests optimal review strategies
- Tracks review effectiveness over time

## Performance Considerations

- **Large report sets**: Process in batches if memory constraints exist
- **Complex synthesis**: Use more powerful LLM models for complex conflict resolution
- **Report standardization**: Ensure consistent input formats for better synthesis quality
- **Caching**: Cache synthesis results for repeated analysis of same report sets

## Security Considerations

- **Sensitive content**: Warn if review reports contain potential secrets or sensitive data
- **Report validation**: Verify report authenticity and source attribution
- **Output sanitization**: Ensure synthesis output doesn't leak sensitive information
- **Access control**: Validate permissions for accessing report files and directories

---

This workflow enables comprehensive synthesis of multiple review perspectives, providing teams with consolidated, actionable improvement plans that leverage the best insights from all available review sources.
