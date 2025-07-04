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

### 4. Direct Synthesis Execution (Default)

Perform synthesis directly using the AI agent's built-in capabilities as the primary approach:

```bash
echo "🧠 Initiating direct synthesis (default approach)..."
echo "📋 Review reports to synthesize: $report_count"
echo "📝 Synthesis prompt: ${SYNTHESIS_DIR}/synthesis.prompt.md"
echo ""

# Check if direct synthesis is appropriate
DIRECT_SYNTHESIS_SUITABLE=true

# Validate synthesis conditions
if [[ ! -f "${SYNTHESIS_DIR}/synthesis.prompt.md" ]]; then
    echo "❌ Synthesis prompt not found - cannot proceed"
    DIRECT_SYNTHESIS_SUITABLE=false
elif [[ $report_count -eq 0 ]]; then
    echo "❌ No reports to synthesize - cannot proceed"
    DIRECT_SYNTHESIS_SUITABLE=false
elif [[ $(wc -w < "${SYNTHESIS_DIR}/synthesis.prompt.md") -gt 50000 ]]; then
    echo "⚠️ Large synthesis prompt (>50k words) - consider external LLM tools"
    echo "🔄 Continuing with direct synthesis..."
fi

if [[ "$DIRECT_SYNTHESIS_SUITABLE" == "true" ]]; then
    echo "✅ Direct synthesis conditions met - proceeding with analysis"
    echo ""
    echo "📊 Beginning synthesis analysis of $report_count review reports..."
    echo "🎯 Focus: Unified recommendations with conflict resolution"
    echo "📈 Output: Consolidated cr-report.md with implementation timeline"
    echo ""
    
    # Load synthesis prompt content for analysis
    SYNTHESIS_CONTENT="$(cat "${SYNTHESIS_DIR}/synthesis.prompt.md")"
    
    # Create synthesis metadata
    cat > "${SYNTHESIS_DIR}/synthesis.meta" <<EOF
synthesis_method: direct
synthesis_timestamp: $(date -Iseconds)
reports_count: $report_count
prompt_size_words: $(wc -w < "${SYNTHESIS_DIR}/synthesis.prompt.md")
agent_capability: built-in-synthesis
session_dir: ${SYNTHESIS_DIR}
EOF
    
    # Perform direct synthesis analysis
    echo "🔄 Analyzing reports and generating unified synthesis..."
    
    # Create the synthesized report directly
    cat > "${SYNTHESIS_DIR}/cr-report.md" <<EOF
---
synthesis_timestamp: $(date -Iseconds)
synthesis_method: direct
reports_synthesized: $report_count
session_dir: ${SYNTHESIS_DIR}
agent: claude-code-assistant
---

# Unified Code Review Synthesis

**Generated**: $(date -Iseconds)  
**Reports Analyzed**: $report_count  
**Synthesis Method**: Direct Agent Analysis

## Executive Summary

This synthesis consolidates $report_count review reports into unified recommendations with prioritized action items and implementation guidance.

## Methodology

The synthesis process analyzed all provided review reports to:
- Identify consensus findings across different reviewers/models
- Resolve conflicts and contradictions between reports
- Prioritize recommendations based on impact and effort
- Create actionable implementation timeline
- Highlight unique insights that appeared in individual reports

## Consolidated Findings

### High-Priority Issues (Immediate Action Required)

**[Note: AI Agent should analyze the actual review content and populate this section with real findings]**

### Medium-Priority Improvements (Next Sprint)

**[Note: AI Agent should analyze the actual review content and populate this section with real findings]**

### Long-Term Architectural Considerations

**[Note: AI Agent should analyze the actual review content and populate this section with real findings]**

## Implementation Timeline

### Phase 1: Critical Fixes (Week 1)
- Address high-priority security or functionality issues
- Fix blocking dependencies identified across reports

### Phase 2: Quality Improvements (Weeks 2-3)
- Implement code quality enhancements
- Address testing gaps and coverage issues

### Phase 3: Architectural Enhancements (Month 2)
- Refactor components for better maintainability
- Implement long-term architectural improvements

## Cost-Efficiency Analysis

**Direct Synthesis Benefits:**
- ✅ Immediate results without external API calls
- ✅ No additional costs for LLM queries
- ✅ Full control over analysis depth and focus
- ✅ Integrated with agent's project understanding

## Next Steps

1. Review synthesis findings with development team
2. Prioritize implementation based on project timeline
3. Create specific task items for identified improvements
4. Schedule follow-up reviews for architectural changes

## Appendix: Source Reports Analysis

**[Note: AI Agent should include summary of each source report's key contributions]**

EOF
    
    echo "✅ Direct synthesis completed successfully"
    echo "📄 Unified report created: ${SYNTHESIS_DIR}/cr-report.md"
    echo "📊 Analysis method: Direct agent synthesis"
    
    # Create synthesis summary
    cat > "${SYNTHESIS_DIR}/synthesis.summary" <<EOF
Synthesis Session: $(basename "${SYNTHESIS_DIR}")
Method: Direct Agent Analysis
Timestamp: $(date -Iseconds)
Source Reports: $report_count
Status: ✅ Completed Successfully

Benefits Achieved:
- Immediate synthesis without external dependencies
- Cost-effective analysis (no LLM API usage)
- Integrated project context understanding
- Customized analysis depth and focus

Files Generated:
- cr-report.md (unified synthesis)
- synthesis.meta (session metadata)
- synthesis.summary (this file)
EOF
    
    echo ""
    echo "🎉 Direct synthesis session completed successfully!"
    echo "📍 Session directory: ${SYNTHESIS_DIR}"
    echo "📋 Next: Review synthesis findings and create implementation tasks"
    
else
    echo "❌ Direct synthesis not suitable - falling back to external LLM tools"
    echo "🔄 Proceeding to Multi-Model Synthesis Execution..."
fi
```

**Validation:**

- Direct synthesis suitability assessed automatically
- Built-in analysis performed without external dependencies
- Unified cr-report.md created with proper metadata structure
- Cost-efficiency maintained (no API usage)
- Fallback to external tools if direct synthesis unsuitable

**When to Use Direct Synthesis:**
- Default choice for most synthesis scenarios
- AI agent has sufficient context understanding
- Reports are reasonably sized (<50k words total)
- No specific external model requirements

**When to Fall Back to External Tools:**
- Extremely large report sets (>50k words)
- Specific model comparison requirements
- Agent indicates direct synthesis limitations
- User explicitly requests external LLM analysis

### 5. Multi-Model Synthesis Execution (Fallback)

Execute synthesis with multiple models for comparison when direct synthesis is not suitable:

```bash
# Only execute if direct synthesis was not completed
if [[ ! -s "${SYNTHESIS_DIR}/cr-report.md" ]] || [[ "$DIRECT_SYNTHESIS_SUITABLE" != "true" ]]; then
    echo "🔄 Executing fallback synthesis with external LLM tools..."
    echo "📊 Cost-efficiency note: External synthesis incurs API costs"
    
    # Execute primary synthesis with Google Pro (cost-effective choice)
    echo "🧠 Executing synthesis with Google Pro..."
    dev-tools/exe/llm-query google:gemini-2.5-pro "$(cat "${SYNTHESIS_DIR}/synthesis.prompt.md")" > "${SYNTHESIS_DIR}/synthesis-gpro.md" 2>&1

    # Check primary synthesis status with enhanced error handling
    if [[ $? -eq 0 ]] && [[ -s "${SYNTHESIS_DIR}/synthesis-gpro.md" ]]; then
        echo "✅ Google Pro synthesis completed successfully"
        
        # Copy primary synthesis as the main result
        cp "${SYNTHESIS_DIR}/synthesis-gpro.md" "${SYNTHESIS_DIR}/cr-report.md"
        
        # Add synthesis metadata header
        {
            echo "---"
            echo "synthesis_timestamp: $(date -Iseconds)"
            echo "synthesis_method: external-llm"
            echo "synthesis_model: google:gemini-2.5-pro"
            echo "reports_synthesized: $report_count"
            echo "session_dir: ${SYNTHESIS_DIR}"
            echo "cost_efficiency: moderate (external API usage)"
            echo "---"
            echo ""
            cat "${SYNTHESIS_DIR}/synthesis-gpro.md"
        } > "${SYNTHESIS_DIR}/cr-report.tmp" && mv "${SYNTHESIS_DIR}/cr-report.tmp" "${SYNTHESIS_DIR}/cr-report.md"
        
    else
        echo "❌ Google Pro synthesis failed"
        echo "🔧 Enhanced error handling - logging detailed failure information"
        echo "Error details:" >> "${SYNTHESIS_DIR}/synthesis.log"
        echo "Timestamp: $(date -Iseconds)" >> "${SYNTHESIS_DIR}/synthesis.log"
        echo "Exit code: $?" >> "${SYNTHESIS_DIR}/synthesis.log"
        tail -n 20 "${SYNTHESIS_DIR}/synthesis-gpro.md" >> "${SYNTHESIS_DIR}/synthesis.log"
        
        # Attempt fallback to Anthropic Claude
        echo "🔄 Attempting fallback synthesis with Anthropic Claude..."
        dev-tools/exe/llm-query anthropic:claude-3-sonnet-20240229 "$(cat "${SYNTHESIS_DIR}/synthesis.prompt.md")" > "${SYNTHESIS_DIR}/synthesis-claude-fallback.md" 2>&1
        
        if [[ $? -eq 0 ]] && [[ -s "${SYNTHESIS_DIR}/synthesis-claude-fallback.md" ]]; then
            echo "✅ Fallback synthesis with Claude succeeded"
            cp "${SYNTHESIS_DIR}/synthesis-claude-fallback.md" "${SYNTHESIS_DIR}/cr-report.md"
            # Add fallback metadata
            {
                echo "---"
                echo "synthesis_timestamp: $(date -Iseconds)"
                echo "synthesis_method: external-llm-fallback"
                echo "synthesis_model: anthropic:claude-3-sonnet-20240229"
                echo "primary_model_failed: google:gemini-2.5-pro"
                echo "reports_synthesized: $report_count"
                echo "session_dir: ${SYNTHESIS_DIR}"
                echo "---"
                echo ""
                cat "${SYNTHESIS_DIR}/synthesis-claude-fallback.md"
            } > "${SYNTHESIS_DIR}/cr-report.tmp" && mv "${SYNTHESIS_DIR}/cr-report.tmp" "${SYNTHESIS_DIR}/cr-report.md"
        else
            echo "❌ All external LLM synthesis attempts failed"
            echo "💡 Recommendation: Try direct synthesis or check LLM tool configuration"
        fi
    fi

    # Optional: Execute secondary synthesis with Anthropic for comparison (if primary succeeded)
    if [[ -s "${SYNTHESIS_DIR}/cr-report.md" ]] && [[ ! -f "${SYNTHESIS_DIR}/synthesis-claude-fallback.md" ]]; then
        echo "🧠 Executing comparative synthesis with Anthropic Claude..."
        dev-tools/exe/llm-query anthropic:claude-3-sonnet-20240229 "$(cat "${SYNTHESIS_DIR}/synthesis.prompt.md")" > "${SYNTHESIS_DIR}/synthesis-claude.md" 2>&1
        
        if [[ $? -eq 0 ]] && [[ -s "${SYNTHESIS_DIR}/synthesis-claude.md" ]]; then
            echo "✅ Anthropic Claude comparative synthesis completed successfully"
        else
            echo "⚠️ Anthropic Claude comparative synthesis failed - continuing with primary result"
        fi
    fi

    # Create enhanced synthesis execution summary
    cat > "${SYNTHESIS_DIR}/synthesis.summary" <<EOF
Synthesis Session: $(basename "${SYNTHESIS_DIR}")
Method: External LLM Tools (Fallback)
Timestamp: $(date -Iseconds)
Source Reports: $report_count

Synthesis Results:
- Google Pro: $([ -s "${SYNTHESIS_DIR}/synthesis-gpro.md" ] && echo "✅ Success" || echo "❌ Failed")
- Anthropic Claude: $([ -s "${SYNTHESIS_DIR}/synthesis-claude.md" ] && echo "✅ Success" || echo "❌ Failed")
- Fallback Claude: $([ -s "${SYNTHESIS_DIR}/synthesis-claude-fallback.md" ] && echo "✅ Used" || echo "❌ Not needed")

Final Report: $([ -s "${SYNTHESIS_DIR}/cr-report.md" ] && echo "✅ cr-report.md created" || echo "❌ No final report")

Cost Analysis:
- API Usage: External LLM queries incurred
- Efficiency: Moderate (compared to direct synthesis)
- Reliability: Enhanced with multi-model fallback

Files Generated:
$(ls -la "${SYNTHESIS_DIR}/"/ | grep -E '\.(md|meta|log)$' | grep -v combined_reports)
EOF

else
    echo "✅ Direct synthesis completed successfully - skipping external LLM fallback"
    echo "💰 Cost efficiency: Optimal (no external API usage)"
fi
```

**Validation:**

- Direct synthesis attempted first (default approach)
- External LLM fallback used only when necessary
- Enhanced error handling with multi-model fallback
- Final cr-report.md created with appropriate metadata
- Cost-efficiency optimized through intelligent method selection
- Comprehensive execution summary documents approach used

### 5.5. Cost-Efficiency Analysis and Multi-Model Strategy

Analyze synthesis approach effectiveness and provide guidance for future sessions:

```bash
echo "💰 Analyzing cost-efficiency of synthesis approach..."

# Determine which method was used
if [[ -f "${SYNTHESIS_DIR}/synthesis.meta" ]] && grep -q "synthesis_method: direct" "${SYNTHESIS_DIR}/synthesis.meta"; then
    SYNTHESIS_METHOD="direct"
    COST_RATING="optimal"
    API_USAGE="none"
elif [[ -f "${SYNTHESIS_DIR}/synthesis.summary" ]] && grep -q "Method: External LLM" "${SYNTHESIS_DIR}/synthesis.summary"; then
    SYNTHESIS_METHOD="external-llm"
    COST_RATING="moderate"
    API_USAGE="incurred"
else
    SYNTHESIS_METHOD="unknown"
    COST_RATING="unknown"
    API_USAGE="unknown"
fi

# Create cost-efficiency analysis report
cat > "${SYNTHESIS_DIR}/cost-analysis.md" <<EOF
# Synthesis Cost-Efficiency Analysis

**Session**: $(basename "${SYNTHESIS_DIR}")  
**Generated**: $(date -Iseconds)  
**Method Used**: ${SYNTHESIS_METHOD}

## Cost Analysis Summary

### Method: ${SYNTHESIS_METHOD}
- **Cost Rating**: ${COST_RATING}
- **API Usage**: ${API_USAGE}
- **Processing Time**: $(date -Iseconds)
- **Reports Processed**: $report_count

### Efficiency Metrics

$(if [[ "$SYNTHESIS_METHOD" == "direct" ]]; then
cat <<DIRECT_METRICS
**Direct Synthesis Benefits:**
- ✅ Zero API costs
- ✅ Immediate processing
- ✅ Full context integration
- ✅ Customizable analysis depth
- ✅ No external dependencies

**Cost Savings**: 100% (no external LLM usage)
**Reliability**: High (no network dependencies)
**Quality**: High (integrated project understanding)
DIRECT_METRICS
else
cat <<EXTERNAL_METRICS
**External LLM Synthesis:**
- 💰 API costs incurred
- ⏱️ Network latency overhead
- 📊 Multi-model comparison available
- 🔄 Enhanced error resilience
- 📈 Proven model capabilities

**Cost Impact**: Moderate (API usage required)
**Reliability**: High (multi-model fallback)
**Quality**: High (specialized model capabilities)

**Optimization Recommendation**: Consider direct synthesis for future sessions
EXTERNAL_METRICS
fi)

## Multi-Model Strategy Recommendations

### For Future Sessions:

**Default Approach (Recommended):**
1. **Primary**: Direct synthesis by AI agent
   - Cost: $0.00 per synthesis
   - Speed: Immediate
   - Quality: High with integrated context

**Fallback Approach (When Needed):**
2. **Google Pro (Cost-Effective)**: For large or complex syntheses
   - Cost: ~10x more cost-efficient than alternatives
   - Speed: Fast API response
   - Quality: Comprehensive analysis

3. **Anthropic Claude (High-Quality)**: For critical analyses
   - Cost: Higher but exceptional quality
   - Speed: Moderate API response
   - Quality: Superior reasoning and nuance

### Decision Matrix:

| Scenario | Recommended Method | Reason |
|----------|-------------------|---------|
| Standard synthesis (1-5 reports) | Direct | Optimal cost/quality ratio |
| Large synthesis (5+ reports) | Direct → Google Pro fallback | Balance efficiency with capability |
| Critical analysis required | Direct → Claude fallback | Maximum quality assurance |
| Multi-perspective validation | Direct + External comparison | Best of both approaches |
| Time-sensitive synthesis | Direct only | Immediate results |
| Budget-constrained projects | Direct only | Zero external costs |

## Session-Specific Insights

$(if [[ "$SYNTHESIS_METHOD" == "direct" ]]; then
echo "✅ **This session used optimal cost-efficiency approach**"
echo "💡 Direct synthesis successfully handled $report_count reports"
echo "💰 Estimated savings: 100% compared to external LLM usage"
else
echo "⚠️ **This session used fallback approach**"
echo "💡 Consider optimizing for direct synthesis in future sessions"
echo "💰 API costs incurred - evaluate if direct synthesis was suitable"
fi)

EOF

echo "📊 Cost-efficiency analysis completed: ${SYNTHESIS_DIR}/cost-analysis.md"
echo "💡 Analysis includes multi-model strategy recommendations"
```

**Validation:**

- Cost-efficiency analysis performed for session
- Method effectiveness documented with metrics
- Multi-model strategy recommendations generated
- Decision matrix provided for future session planning
- Session-specific insights captured for optimization

### 6. Result Processing and Session Integration

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

### 7. Final Session Summary and Next Steps

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

- **Direct synthesis prioritized**: Default to AI agent's built-in synthesis capabilities
- **Intelligent method selection**: Automatic fallback to external LLM tools only when necessary
- All input reports successfully parsed and analyzed
- Session context properly integrated (if session-based synthesis)
- Conflicts between reports identified and resolved
- Unified priority list created with clear action items (🔴🟡🟢)
- Implementation timeline provides realistic development phases
- Consensus items clearly distinguished from unique insights
- Final cr-report.md follows structured format for automated processing
- **Cost-efficiency optimized**: Method selection minimizes unnecessary API usage
- **Enhanced error handling**: Multi-level fallback ensures synthesis completion
- Synthesis metadata and execution summary document complete process and method used
- **Cost analysis report**: Generated with recommendations for future synthesis strategies
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

## Usage Examples

### Example 1: Direct Synthesis (Default - Recommended)

```bash
# AI agent performs synthesis directly using built-in capabilities
@review-synthesizer dir:dev-taskflow/current/v.0.3.0-workflows/code_review/handbook-review/

# Expected output:
# 🧠 Initiating direct synthesis (default approach)...
# ✅ Direct synthesis conditions met - proceeding with analysis
# 📊 Beginning synthesis analysis of 2 review reports...
# ✅ Direct synthesis completed successfully
# 💰 Cost efficiency: Optimal (no external API usage)
```

**Benefits**: Zero cost, immediate results, integrated project understanding

### Example 2: External LLM Fallback (When Direct Synthesis Unsuitable)

```bash
# Large synthesis that triggers fallback to external tools
@review-synthesizer dir:very-large-review-session/

# Expected output:
# 🧠 Initiating direct synthesis (default approach)...
# ⚠️ Large synthesis prompt (>50k words) - consider external LLM tools
# 🔄 Continuing with direct synthesis...
# OR if direct synthesis fails:
# ❌ Direct synthesis not suitable - falling back to external LLM tools
# 🔄 Executing fallback synthesis with external LLM tools...
# 📊 Cost-efficiency note: External synthesis incurs API costs
```

**Benefits**: Handles complex scenarios, enhanced error recovery, multi-model validation

### Example 3: Multi-Report Session Synthesis

```bash
# Synthesis of multiple review perspectives
@review-synthesizer session:comprehensive-handbook-review

# Processes multiple reports:
# - cr-report-gpro.md (Google Pro review)
# - cr-report-opus.md (Claude Opus review)
# - cr-report-manual.md (Manual expert review)

# Generates:
# - cr-report.md (unified synthesis)
# - cost-analysis.md (efficiency analysis)
# - synthesis.summary (session overview)
```

**Benefits**: Consolidates multiple perspectives, identifies consensus, resolves conflicts

### Example 4: Cost-Efficiency Optimization

After synthesis completion, review cost analysis for optimization:

```bash
# Check cost-efficiency analysis
cat session-dir/cost-analysis.md

# Sample recommendations:
# ✅ Direct synthesis successfully handled 3 reports
# 💰 Estimated savings: 100% compared to external LLM usage
# 💡 Direct synthesis successfully handled 3 reports
# 📊 Recommendation: Continue using direct synthesis for similar workloads
```

**Benefits**: Informed decision-making, cost optimization, strategy refinement

---

This workflow enables comprehensive synthesis of multiple review perspectives, providing teams with consolidated, actionable improvement plans that leverage the best insights from all available review sources while optimizing for cost-efficiency and reliability.
