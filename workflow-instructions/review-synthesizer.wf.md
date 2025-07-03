# Review Synthesizer Workflow Instruction

## Goal

Synthesize multiple code review reports into a unified, actionable improvement plan. This workflow works with structured session directories from @review-code, taking multiple review outputs (from different LLM providers, focus areas, or review runs) and creates a consolidated cr-report.md with resolved conflicts, prioritized recommendations, and clear implementation timeline.

## Prerequisites

- Multiple review reports in markdown format (cr-report-*.md files)
- Review reports follow standard section formats (11-section structure)
- Access to `dev-handbook/templates/review-synthesizer/system.prompt.md`
- LLM query tools available (`dev-tools/exe/llm-query`)
- Write access to session directories in `dev-taskflow/current/`
- Understanding of review session directory structure

## Project Context Loading

- Load workflow standards: `dev-handbook/.meta/gds/workflow-instructions-definition.g.md`
- Load synthesizer template: `dev-handbook/templates/review-synthesizer/system.prompt.md`
- Load session patterns: `dev-taskflow/current/*/code_review/*/`
- Load project structure: `docs/blueprint.md`

## Command Structure

```
@review-synthesizer [reports-source]
```

### Parameters

- **reports-source** (required): Source of review reports to synthesize
  - `session:session-name` - All cr-report-*.md files in specific session directory
  - `dir:reviews/` - All cr-report-*.md files in directory (session directory)
  - `files:report1.md,report2.md,report3.md` - Specific report files
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

### 1. Session Directory Detection and Report Source Resolution

Based on reports-source parameter:

#### Session-based Sources (Recommended)

```bash
# For session name (most common usage)
if [[ "${reports_source}" =~ ^session: ]]; then
    SESSION_NAME="${reports_source#session:}"
    SESSION_DIR="dev-taskflow/current/v.0.3.0-workflows/code_review/${SESSION_NAME}"
    
    if [[ ! -d "${SESSION_DIR}" ]]; then
        echo "❌ Session directory not found: ${SESSION_DIR}"
        exit 1
    fi
    
    # Use session directory for synthesis
    SYNTHESIS_DIR="${SESSION_DIR}"
    REPORTS_DIR="${SESSION_DIR}"
    
    echo "📁 Using session directory: ${SESSION_DIR}"
fi
```

#### Directory-based Sources

```bash
# For directory of reports (including session directories)
if [[ "${reports_source}" =~ ^dir: ]]; then
    REPORTS_DIR="${reports_source#dir:}"
    
    if [[ ! -d "${REPORTS_DIR}" ]]; then
        echo "❌ Reports directory not found: ${REPORTS_DIR}"
        exit 1
    fi
    
    # Check if this is a session directory
    if [[ -f "${REPORTS_DIR}/session.meta" ]]; then
        echo "📁 Detected session directory: ${REPORTS_DIR}"
        SYNTHESIS_DIR="${REPORTS_DIR}"
    else
        echo "📁 Using reports directory: ${REPORTS_DIR}"
        SYNTHESIS_DIR="$(pwd)/synthesis-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "${SYNTHESIS_DIR}"
    fi
fi

# Combine all cr-report-*.md files from the reports directory
echo "🔍 Looking for cr-report-*.md files in: ${REPORTS_DIR}"
REPORT_FILES=("${REPORTS_DIR}"/cr-report-*.md)

if [[ ${#REPORT_FILES[@]} -eq 0 ]] || [[ ! -f "${REPORT_FILES[0]}" ]]; then
    echo "❌ No cr-report-*.md files found in ${REPORTS_DIR}"
    exit 1
fi

echo "📄 Found ${#REPORT_FILES[@]} report files to synthesize"

# Create combined reports file
cat > "${SYNTHESIS_DIR}/combined_reports.md" <<EOF
# Combined Review Reports for Synthesis

Generated: $(date -Iseconds)
Source Directory: ${REPORTS_DIR}
Reports Found: ${#REPORT_FILES[@]}

EOF

# Add each report with proper headers
for file in "${REPORT_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        basename_file=$(basename "$file")
        echo "📝 Adding report: $basename_file"
        echo "" >> "${SYNTHESIS_DIR}/combined_reports.md"
        echo "=== Report from $basename_file ===" >> "${SYNTHESIS_DIR}/combined_reports.md"
        echo "" >> "${SYNTHESIS_DIR}/combined_reports.md"
        cat "$file" >> "${SYNTHESIS_DIR}/combined_reports.md"
        echo -e "\n\n---\n" >> "${SYNTHESIS_DIR}/combined_reports.md"
    fi
done
```

#### File-based Sources

```bash
# For specific files
if [[ "${reports_source}" =~ ^files: ]]; then
    files_list="${reports_source#files:}"
    SYNTHESIS_DIR="$(pwd)/synthesis-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${SYNTHESIS_DIR}"
    
    IFS=',' read -ra FILES <<< "${files_list}"
    
    cat > "${SYNTHESIS_DIR}/combined_reports.md" <<EOF
# Combined Review Reports for Synthesis

Generated: $(date -Iseconds)
Source: Specific files
Files: ${files_list}

EOF
    
    for file in "${FILES[@]}"; do
        if [[ -f "$file" ]]; then
            echo "📝 Adding report: $file"
            echo "" >> "${SYNTHESIS_DIR}/combined_reports.md"
            echo "=== Report from $file ===" >> "${SYNTHESIS_DIR}/combined_reports.md"
            echo "" >> "${SYNTHESIS_DIR}/combined_reports.md"
            cat "$file" >> "${SYNTHESIS_DIR}/combined_reports.md"
            echo -e "\n\n---\n" >> "${SYNTHESIS_DIR}/combined_reports.md"
        fi
    done
fi
```

#### Interactive/Stdin Sources

```bash
# For interactive input
if [[ "${reports_source}" == "interactive" ]] || [[ "${reports_source}" == "stdin" ]]; then
    SYNTHESIS_DIR="$(pwd)/synthesis-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${SYNTHESIS_DIR}"
    
    echo "📝 Paste review reports (end with EOF or Ctrl+D):"
    cat > "${SYNTHESIS_DIR}/combined_reports.md"
fi
```

**Validation:**
- Reports source properly identified and validated
- Synthesis directory created or identified
- All cr-report-*.md files found and combined
- Combined reports file created successfully

### 2. Session Context Integration and Report Validation

Integrate session context and validate reports:

```bash
# Add session context if available
if [[ -f "${SYNTHESIS_DIR}/session.meta" ]]; then
    echo "📋 Loading session context..."
    
    cat > "${SYNTHESIS_DIR}/synthesis.meta" <<EOF
# Synthesis Metadata

Timestamp: $(date -Iseconds)
Synthesis Type: Session-based
Source Session: $(grep "command:" "${SYNTHESIS_DIR}/session.meta" | cut -d' ' -f2-)
Original Target: $(grep "target:" "${SYNTHESIS_DIR}/session.meta" | cut -d' ' -f2-)
Original Focus: $(grep "focus:" "${SYNTHESIS_DIR}/session.meta" | cut -d' ' -f2-)
Reports Synthesized: ${#REPORT_FILES[@]}

Session Files Available:
EOF
    
    ls -la "${SYNTHESIS_DIR}/" | grep -E '\.(md|meta|log|diff|xml)$' >> "${SYNTHESIS_DIR}/synthesis.meta"
else
    cat > "${SYNTHESIS_DIR}/synthesis.meta" <<EOF
# Synthesis Metadata

Timestamp: $(date -Iseconds)
Synthesis Type: Manual/Directory-based
Source Directory: ${REPORTS_DIR}
Reports Synthesized: ${#REPORT_FILES[@]}
EOF
fi

# Check for standard review sections
echo "🔍 Validating report structure..."
required_sections=(
    "Executive Summary"
    "Prioritised.*Action Items"
    "Implementation Recommendation"
)

validation_passed=true
for section in "${required_sections[@]}"; do
    if ! grep -q "## .*$section" "${SYNTHESIS_DIR}/combined_reports.md"; then
        echo "⚠️  Warning: Missing '$section' in one or more reports"
        validation_passed=false
    else
        echo "✅ Found: $section"
    fi
done

if [[ "$validation_passed" == "true" ]]; then
    echo "✅ All required sections found in reports"
else
    echo "⚠️  Some sections missing - synthesis will proceed but may be incomplete"
fi

# Count individual reports found
report_count=$(grep -c "=== Report from" "${SYNTHESIS_DIR}/combined_reports.md")
echo "📊 Ready to synthesize $report_count individual reports"
```

**Validation:**
- Session metadata integrated if available
- All required report sections validated
- Report count confirmed
- Synthesis metadata file created

### 3. Enhanced Synthesis Prompt Construction

Build the complete synthesis prompt with session context:

```bash
# Build comprehensive synthesis prompt
cat > "${SYNTHESIS_DIR}/synthesis.prompt.md" <<EOF
# Review Synthesis Prompt

Generated: $(date -Iseconds)
Synthesis Directory: ${SYNTHESIS_DIR}
Reports Count: $report_count

## System Prompt

EOF

# Add synthesizer system prompt
cat "dev-handbook/templates/review-synthesizer/system.prompt.md" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"

echo -e "\n\n## Session Context\n" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"

# Add session context if available
if [[ -f "${SYNTHESIS_DIR}/session.meta" ]]; then
    echo "### Original Review Session" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
    cat "${SYNTHESIS_DIR}/session.meta" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
    
    echo -e "\n### Session Statistics" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
    cat "${SYNTHESIS_DIR}/synthesis.meta" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
fi

echo -e "\n\n## Review Reports to Synthesize\n" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "The following $report_count review reports need to be synthesized into a unified analysis:" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"

# Add combined reports content
cat "${SYNTHESIS_DIR}/combined_reports.md" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"

echo -e "\n\n## Synthesis Instructions\n" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "Please synthesize these review reports following the structured format specified in the system prompt." >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "Focus on:" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "- Resolving conflicts between different model recommendations" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "- Identifying consensus items vs. unique insights" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "- Creating a unified priority list with clear implementation phases" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "- Providing comparative analysis of different model approaches" >> "${SYNTHESIS_DIR}/synthesis.prompt.md"

echo "📝 Synthesis prompt created: ${SYNTHESIS_DIR}/synthesis.prompt.md"
echo "📏 Prompt size: $(wc -w < "${SYNTHESIS_DIR}/synthesis.prompt.md") words"
```

**Validation:**
- Synthesis prompt file created with all sections
- Synthesizer system prompt template included
- Session context integrated if available
- Combined reports properly embedded
- Synthesis instructions clearly specified

### 4. Multi-Model Synthesis Execution

Execute synthesis with multiple models for comparison:

```bash
# Execute primary synthesis with Google Pro
echo "🧠 Executing synthesis with Google Pro..."
dev-tools/exe/llm-query google:gemini-2.5-pro "$(cat "${SYNTHESIS_DIR}/synthesis.prompt.md")" > "${SYNTHESIS_DIR}/synthesis-gpro.md" 2>&1

# Check primary synthesis status
if [[ $? -eq 0 ]] && [[ -s "${SYNTHESIS_DIR}/synthesis-gpro.md" ]]; then
    echo "✅ Google Pro synthesis completed successfully"
    
    # Copy primary synthesis as the main result
    cp "${SYNTHESIS_DIR}/synthesis-gpro.md" "${SYNTHESIS_DIR}/cr-report.md"
    
    # Add synthesis metadata header
    {
        echo "---"
        echo "synthesis_timestamp: $(date -Iseconds)"
        echo "synthesis_model: google:gemini-2.5-pro"
        echo "reports_synthesized: $report_count"
        echo "session_dir: ${SYNTHESIS_DIR}"
        echo "---"
        echo ""
        cat "${SYNTHESIS_DIR}/synthesis-gpro.md"
    } > "${SYNTHESIS_DIR}/cr-report.tmp" && mv "${SYNTHESIS_DIR}/cr-report.tmp" "${SYNTHESIS_DIR}/cr-report.md"
    
else
    echo "❌ Google Pro synthesis failed"
    echo "Error details:" >> "${SYNTHESIS_DIR}/synthesis.log"
    tail -n 20 "${SYNTHESIS_DIR}/synthesis-gpro.md" >> "${SYNTHESIS_DIR}/synthesis.log"
fi

# Optional: Execute secondary synthesis with Anthropic (if primary succeeded)
if [[ -s "${SYNTHESIS_DIR}/cr-report.md" ]]; then
    echo "🧠 Executing comparative synthesis with Anthropic Claude..."
    dev-tools/exe/llm-query anthropic:claude-3-sonnet-20240229 "$(cat "${SYNTHESIS_DIR}/synthesis.prompt.md")" > "${SYNTHESIS_DIR}/synthesis-claude.md" 2>&1
    
    if [[ $? -eq 0 ]] && [[ -s "${SYNTHESIS_DIR}/synthesis-claude.md" ]]; then
        echo "✅ Anthropic Claude synthesis completed successfully"
    else
        echo "⚠️ Anthropic Claude synthesis failed - continuing with primary result"
    fi
fi

# Create synthesis execution summary
cat > "${SYNTHESIS_DIR}/synthesis.summary" <<EOF
Synthesis Session: $(basename "${SYNTHESIS_DIR}")
Timestamp: $(date -Iseconds)
Source Reports: $report_count

Synthesis Results:
- Google Pro: $([ -s "${SYNTHESIS_DIR}/synthesis-gpro.md" ] && echo "✅ Success" || echo "❌ Failed")
- Anthropic Claude: $([ -s "${SYNTHESIS_DIR}/synthesis-claude.md" ] && echo "✅ Success" || echo "❌ Failed")

Final Report: $([ -s "${SYNTHESIS_DIR}/cr-report.md" ] && echo "✅ cr-report.md created" || echo "❌ No final report")

Files Generated:
$(ls -la "${SYNTHESIS_DIR}/"/ | grep -E '\.(md|meta|log)$' | grep -v combined_reports)
EOF
```

**Validation:**
- Primary synthesis executed successfully
- Final cr-report.md created with metadata
- Secondary synthesis attempted if primary succeeded
- Execution summary documents results

### 5. Result Processing and Session Integration

Process synthesis output and integrate with session:

```bash
# Validate synthesis output structure
echo "🔍 Validating synthesis output..."
if [[ -s "${SYNTHESIS_DIR}/cr-report.md" ]]; then
    
    # Check for required synthesis sections
    synthesis_sections=(
        "Executive Analysis"
        "Actionable Recommendations"
        "Implementation Timeline"
    )
    
    synthesis_valid=true
    for section in "${synthesis_sections[@]}"; do
        if grep -q "## .*$section" "${SYNTHESIS_DIR}/cr-report.md"; then
            echo "✅ Found: $section"
        else
            echo "⚠️  Missing: $section"
            synthesis_valid=false
        fi
    done
    
    # Extract key metrics from synthesis
    priority_items=$(grep -c "🔴\|🟡\|🟢" "${SYNTHESIS_DIR}/cr-report.md" || echo "0")
    timeline_phases=$(grep -c "Phase [0-9]" "${SYNTHESIS_DIR}/cr-report.md" || echo "0")
    
    echo "📊 Synthesis metrics: $priority_items priority items, $timeline_phases phases"
    
else
    echo "❌ No synthesis output generated"
    synthesis_valid=false
fi

# Create comprehensive session index if this is a session directory
if [[ -f "${SYNTHESIS_DIR}/session.meta" ]]; then
    echo "📋 Updating session index with synthesis results..."
    
    # Update the session README.md to include synthesis results
    cat >> "${SYNTHESIS_DIR}/README.md" <<EOF

## Synthesis Results

**Generated**: $(date -Iseconds)

### Synthesis Files
- [\`cr-report.md\`](./cr-report.md) - **Final synthesized review report**
- [\`synthesis.prompt.md\`](./synthesis.prompt.md) - Complete synthesis prompt
- [\`synthesis.summary\`](./synthesis.summary) - Synthesis execution results
- [\`combined_reports.md\`](./combined_reports.md) - All input reports combined

$([ -f "${SYNTHESIS_DIR}/synthesis-gpro.md" ] && echo "- [\\`synthesis-gpro.md\\`](./synthesis-gpro.md) - Google Pro synthesis output")
$([ -f "${SYNTHESIS_DIR}/synthesis-claude.md" ] && echo "- [\\`synthesis-claude.md\\`](./synthesis-claude.md) - Anthropic Claude synthesis output")

### Synthesis Statistics
- **Priority Items**: $priority_items
- **Implementation Phases**: $timeline_phases
- **Models Used**: $([ -f "${SYNTHESIS_DIR}/synthesis-gpro.md" ] && echo "Google Pro") $([ -f "${SYNTHESIS_DIR}/synthesis-claude.md" ] && echo "Anthropic Claude")
- **Synthesis Status**: $([ "$synthesis_valid" == "true" ] && echo "✅ Complete" || echo "⚠️ Incomplete")

### Session Complete

This session now contains the complete review workflow:
1. ✅ Input analysis (input.diff/input.xml)
2. ✅ Multi-model review (cr-report-*.md)
3. ✅ Unified synthesis (cr-report.md)

EOF
fi
```

**Validation:**
- Synthesis output structure validated
- Key metrics extracted from final report
- Session index updated with synthesis results
- Complete workflow documentation provided

### 6. Final Session Summary and Next Steps

Generate session completion summary:

```bash
# Display comprehensive completion summary
echo ""
echo "🎉 Review Synthesis Completed!"
echo ""
echo "📁 Session Directory: ${SYNTHESIS_DIR}/"
echo "📄 Final Report: ${SYNTHESIS_DIR}/cr-report.md"
echo ""
echo "📊 Synthesis Results:"
echo "   📝 Reports Synthesized: $report_count"
echo "   🎯 Priority Items: $priority_items"
echo "   📅 Implementation Phases: $timeline_phases"
echo "   ✅ Synthesis Status: $([ "$synthesis_valid" == "true" ] && echo "Complete" || echo "Incomplete")"
echo ""
echo "🔍 Generated Files:"
echo "   📋 cr-report.md - Final synthesized review"
echo "   📝 synthesis.prompt.md - Complete synthesis prompt"
echo "   📊 synthesis.summary - Execution results"
echo "   📄 combined_reports.md - Input reports combined"
echo ""

if [[ -f "${SYNTHESIS_DIR}/session.meta" ]]; then
    echo "🔗 Session Integration:"
    echo "   📁 Session README.md updated with synthesis results"
    echo "   📋 Complete review workflow documented"
    echo "   🔄 Ready for task creation or implementation"
else
    echo "📋 Standalone Synthesis:"
    echo "   📄 Results available in synthesis directory"
    echo "   🔄 Ready for integration into project workflow"
fi

echo ""
echo "💡 Next Steps:"
echo "   1. Review cr-report.md for actionable recommendations"
echo "   2. Create tasks from high-priority items"
echo "   3. Plan implementation timeline based on phases"
echo "   4. Track progress against synthesis recommendations"
echo ""

# Optional: Extract critical items for immediate attention
critical_count=$(grep -c "🔴" "${SYNTHESIS_DIR}/cr-report.md" 2>/dev/null || echo "0")
if [[ "$critical_count" -gt 0 ]]; then
    echo "⚠️  ATTENTION: $critical_count critical items require immediate action!"
    echo "   Review the '🔴 Critical' sections in cr-report.md"
    echo ""
fi
```

**Validation:**
- Comprehensive completion summary displayed
- File generation status confirmed
- Next steps clearly outlined
- Critical items highlighted for attention

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
- Session context properly integrated (if session-based synthesis)
- Conflicts between reports identified and resolved
- Unified priority list created with clear action items (🔴🟡🟢)
- Implementation timeline provides realistic development phases
- Consensus items clearly distinguished from unique insights
- Final cr-report.md follows structured format for automated processing
- Synthesis metadata and execution summary document complete process
- Session integration completed (README.md updated, file structure maintained)
- Critical items flagged for immediate attention

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
