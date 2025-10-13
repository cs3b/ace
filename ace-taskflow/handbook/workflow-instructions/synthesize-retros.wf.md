---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-10-02'
---

# Synthesize Reflection Notes Workflow Instruction

## Goal

Systematically analyze and compact multiple reflection notes to extract actionable insights for improving the gem's development workflows, with cross-referencing against architecture documentation, impact-based prioritization, and concrete solution proposals.

## Prerequisites

- Multiple reflection notes exist across dev-taskflow structure
- The `reflection-synthesize` command is available
- Understanding of the CAT Ruby gem project structure and patterns

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

## High-Level Execution Plan

### Execution Steps

- [ ] Run enhanced synthesis command with analytics to auto-discover and process reflections
- [ ] Review comprehensive synthesis report with analytical insights and priority rankings
- [ ] Extract priority-based action items for implementation planning

## Process Steps

### 1. Execute Reflection Synthesis

Use the `reflection-synthesize` command to automatically discover and process all reflection notes:

```bash
echo "🧠 Starting automated reflection synthesis..."

# Execute synthesis with auto-discovery, archival, and cost tracking
reflection-synthesize --archived --track-cost

# Monitor LLM usage for synthesis operations
llm-usage-report --session reflection-synthesis --verbose

echo "✅ Synthesis and archival completed automatically"
```

**What this does:**
- Automatically discovers all non-archived reflection notes in current release
- Synthesizes them using specialized LLM analysis with enhanced analytics capabilities
- Generates comprehensive improvement recommendations with priority rankings
- Identifies automation opportunities ranked by frequency and impact
- Consolidates tool and workflow proposals with implementation guidance
- Archives processed reflections to `reflections/archived/` directory
- Creates archive summary for traceability

**Validation:**
- Synthesis executes successfully with clear output
- Enhanced synthesis report generated with analytical insights and priority rankings
- Automation opportunities identified and ranked by impact/frequency
- Tool and workflow proposals consolidated with implementation guidance
- Original reflections moved to archived directory
- Archive summary created with metadata


## Success Criteria

- ✅ Reflection synthesis executed automatically without manual discovery
- ✅ Enhanced analysis report generated with LLM insights and analytical features
- ✅ Pattern detection identifies recurring themes with frequency analysis
- ✅ Automation opportunities ranked by frequency, impact, and implementation effort
- ✅ Tool and workflow proposals consolidated with clear rationale and priorities
- ✅ Cookbook patterns identified for documentation with reusability assessment
- ✅ Original reflection notes archived with proper organization
- ✅ Actionable priority lists generated with implementation guidance

## Error Handling

**No reflections found:**
- Verify reflection notes exist in current release
- Check `dev-taskflow/current/*/reflections/` directories
- Create reflection notes using `@create-reflection-note` if needed

**Synthesis command fails:**
- Check if command is available: `reflection-synthesize --help`
- Verify reflection note file formats and content
- Use `--debug` flag for detailed error information

**Insufficient reflections for synthesis:**
- Command requires minimum of 2 reflection notes
- Create additional reflections or wait for more development sessions
- Use manual analysis for single reflection notes

## Usage Examples

### Standard Workflow Execution

```bash
# Complete reflection synthesis workflow in one command
reflection-synthesize --archived

# Expected output:
# 🔍 Auto-discovering reflection notes in current release...
# ✅ Found 5 reflection notes
# 🔍 Collecting and validating reflection notes...
# ✅ Found 5 valid reflection notes
# 📅 Timestamp range: 2024-01-15 to 2024-01-26
# 📄 Output will be saved to: 20240115-20240126-reflection-synthesis.md
# 🧠 Starting synthesis with model: google:gemini-2.5-pro
# ✅ Synthesis completed successfully
# 📄 Report saved to: 20240115-20240126-reflection-synthesis.md
# 📦 Archived 5 reflection notes
# 📁 Archive location: dev-taskflow/current/v.0.3.0-migration/reflections/archived/synthesis-20240126-143022
```

### Advanced Usage

```bash
# Synthesize specific reflection files (manual selection)
reflection-synthesize reflection-auth-issues.md reflection-cli-improvements.md --archived

# Use different model for analysis
reflection-synthesize --model anthropic:claude-sonnet-4-20250514 --archived

# Preview what would be synthesized without execution
reflection-synthesize --dry-run

# Custom output location
reflection-synthesize --output quarterly-reflection-analysis.md --archived
```

## Benefits for CAT Development

- **Zero-Configuration**: Single command handles discovery, synthesis, and archival
- **Automated Workflow**: No manual file management or bash scripting required
- **Enhanced Analytics**: LLM-powered insights with pattern detection and priority ranking
- **Strategic Prioritization**: Automation opportunities ranked by frequency and impact
- **Proposal Consolidation**: Similar tool and workflow needs merged with clear rationale
- **Cookbook Identification**: Common patterns flagged for documentation with reusability metrics
- **Proper Archival**: Maintains clean workspace while preserving processed reflections
- **Actionable Output**: Specific implementation guidance tied to project architecture with priority lists
- **Time Efficiency**: Reduces 330+ line workflow to single command execution
- **Consistent Quality**: Standardized analysis using enhanced system prompt with analytical capabilities

## Command Reference

The workflow now centers around the enhanced `reflection-synthesize` command:

```bash
reflection-synthesize [REFLECTION_NOTES...] [options]

# Key options:
--archived                        # Automatically archive reflections after synthesis
--model google:gemini-2.5-pro     # LLM model for analysis (default)
--format markdown                 # Output format (default)
--system-prompt PATH              # Custom system prompt (default: dev-handbook/templates/release-reflections/synthsize.system.prompt.md)
--dry-run                        # Preview without execution
--debug                          # Detailed error information

# Zero-config usage (recommended):
reflection-synthesize --archived  # Auto-discover, synthesize, and archive
```

---

This streamlined workflow leverages automated discovery and archival to provide comprehensive reflection analysis with minimal manual effort, enabling teams to focus on implementing improvements rather than managing the synthesis process.

<documents>
<template path="dev-handbook/templates/release-reflections/synthesis-analysis.template.md"># Coding Agent Tools: Reflection Synthesis Analysis

**Date**: YYYY-MM-DD HH:MM:SS
**Synthesis Session**: [Session ID/Directory]
**Reflections Analyzed**: [Count]
**Releases Covered**: [Release list]

## Executive Summary

[2-3 sentence overview of key findings and top recommendations for the CAT Ruby gem project]

## Methodology

This synthesis analyzed [count] reflection notes from [releases] to identify recurring development patterns, architecture compliance issues, and improvement opportunities specific to the Coding Agent Tools (CAT) Ruby Gem.

**Analysis Approach:**

- Systematic scanning across dev-taskflow release structure
- Pattern extraction using CAT-specific challenge categories
- Architecture compliance validation against project design principles (see docs/architecture.md)
- Impact-based prioritization using project-specific criteria
- Solution framing using gem's own CLI capabilities and architecture

## Critical Issues (Immediate Action Required)

### Issue 1: [Title] (Critical)

**Pattern**: [Recurring pattern observed across reflections]
**Occurrences**: [Count across releases]
**Examples**:

- From [reflection source]: [specific instance]
- From [task/session]: [specific instance]

**Architecture Impact**: [Analysis against docs/architecture.md and project principles]
**Root Cause**: [Analysis based on CAT gem structure and workflow]

**Proposed Solution**:

```ruby
# Concrete implementation approach
# [Project-specific code example following architecture patterns]
```

**Implementation Path**:

1. [Step with specific lib/coding_agent_tools/ file references]
2. [Integration with existing bin/ commands]
3. [Test strategy using project's RSpec setup]
4. [CLI interface updates for AI agent compatibility]

## High Priority Issues (Next Sprint)

### Issue 2: [Title] (High)

[Similar format as Critical issues]

## Medium Priority Issues (Future Consideration)

### Issue 3: [Title] (Medium)

[Similar format but more condensed]

## Low Priority Issues (Backlog)

### Issue 4: [Title] (Low)

[Brief description and recommendation]

## Architecture Compliance Assessment

### ATOM Pattern Adherence

- **Atoms**: [Assessment of smallest component compliance]
- **Molecules**: [Assessment of composed component patterns]
- **Organisms**: [Assessment of complex business logic organization]

### CLI Design Consistency

- **Command Structure**: [Assessment against established CLI patterns]
- **Error Handling**: [Assessment of error reporting consistency]
- **User Experience**: [Assessment of AI agent and human usability]

## Solution Prioritization Matrix

| Priority | Issue | Effort | Impact | Dependencies |
|----------|-------|--------|--------|--------------|
| Critical | [Issue 1] | [H/M/L] | [H/M/L] | [Dependencies] |
| High     | [Issue 2] | [H/M/L] | [H/M/L] | [Dependencies] |

## Recommended Action Plan

### Phase 1: Critical Fixes (Week 1-2)

1. **[Critical Issue 1]**
   - Owner: [Team/Person]
   - Timeline: [Specific timeframe]
   - Success Criteria: [Measurable outcomes]

### Phase 2: High Priority Items (Week 3-4)

1. **[High Priority Issue 1]**
   - Owner: [Team/Person]
   - Timeline: [Specific timeframe]
   - Success Criteria: [Measurable outcomes]

### Phase 3: Medium Priority (Month 2)

1. **[Medium Priority Items]**
   - Batch processing approach
   - Resource allocation strategy

## Implementation Support

### Existing Tools to Leverage

- `bin/[command]`: [How it supports the solution]
- `lib/coding_agent_tools/[module]`: [Existing capabilities to build upon]
- Test infrastructure: [How to validate improvements]

### New Tooling Requirements

- [Tool name]: [Purpose and scope]
- [Integration point]: [How it fits into existing architecture]

## Reflection Archive Summary

### Processed Files

```bash
# Reflections archived in this synthesis
[List of reflection files moved to archive]
```

### Retention Policy

- **Critical insights**: Retained in synthesis for 6 months
- **Implementation tracking**: Linked to task management system
- **Historical patterns**: Archived but searchable

## Next Steps

1. **Immediate Actions** (This Week)
   - [ ] Review and approve synthesis findings
   - [ ] Assign owners for Critical issues
   - [ ] Create tracking tasks in dev-taskflow

2. **Short Term** (Next 2 Weeks)
   - [ ] Implement Phase 1 critical fixes
   - [ ] Begin Phase 2 planning
   - [ ] Update architecture documentation if needed

3. **Long Term** (Next Month)
   - [ ] Execute Phase 2 and 3 improvements
   - [ ] Conduct follow-up reflection synthesis
   - [ ] Validate improvement effectiveness

## Appendix

### Detailed Pattern Analysis

[Optional: Detailed breakdown of patterns for reference]

### Architecture References

- [docs/architecture.md]: [Relevant sections]
- [docs/blueprint.md]: [Structural considerations]
- [ADR documents]: [Architectural decision context]

### Reflection Source Metadata

| Reflection File | Release | Date | Key Insights | Status |
|----------------|---------|------|--------------|--------|
| [filename] | [release] | [date] | [brief] | Archived |</template>
</documents>
