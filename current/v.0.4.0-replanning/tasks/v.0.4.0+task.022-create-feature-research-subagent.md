---
id: v.0.4.0+task.022
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Create Feature Research Subagent

## Behavioral Specification

### User Experience
- **Input**: Project context, specific research scope (e.g., "CMS admin features", "authentication system"), references to existing functionality
- **Process**: Agent performs deep analysis of current state, researches comparable systems, identifies gaps, and prioritizes findings
- **Output**: Comprehensive feature research report saved to `dev-taskflow/backlog/{datetime}-{topic}.fr.md` with prioritized feature list and implementation readiness assessment

### Expected Behavior
The feature research agent autonomously:
1. Analyzes the current state of specified system areas
2. Researches comparable systems and industry best practices
3. Identifies functionality gaps and missing features
4. Prioritizes discovered features based on user value and implementation complexity
5. Produces a structured research report with actionable recommendations
6. Saves findings to a standardized .fr.md (feature research) file format

### Interface Contract
```bash
# CLI Interface - Agent invocation
"Use the feature-research agent to analyze [area] and identify missing features"
"Research [topic] and create a prioritized feature list"

# Expected outputs
- Feature research report written to: dev-taskflow/backlog/{datetime}-{topic}.fr.md
- Example: dev-taskflow/backlog/20250204-1430-cms-admin-features.fr.md
```

**Error Handling:**
- Insufficient context: Request additional project information
- Ambiguous research scope: Ask for clarification on specific areas to analyze
- Unable to access resources: Report which resources are unavailable and continue with available information

**Edge Cases:**
- Research scope too broad: Break down into sub-topics and create multiple research reports
- No comparable systems found: Focus on user needs analysis and general best practices

### Success Criteria
- [ ] **Research Completeness**: Agent performs comprehensive analysis of specified system area
- [ ] **Feature Discovery**: Identifies and documents relevant missing features with clear rationale
- [ ] **Prioritization Quality**: Produces actionable priority matrix based on value and complexity
- [ ] **Output Format**: Creates properly formatted .fr.md file in correct location
- [ ] **Integration Ready**: Research findings can be converted to draft tasks using existing workflows

### Validation Questions
- [ ] **Research Scope**: What level of detail is expected in the feature analysis?
- [ ] **Prioritization Criteria**: What specific factors should drive feature prioritization (user value, technical debt, competitive advantage)?
- [ ] **External Research**: Should the agent research competitor products or focus only on internal gaps?
- [ ] **Implementation Assessment**: How deep should the technical feasibility analysis go?

## Objective

Create a specialized Claude Code subagent that autonomously researches and identifies missing features in the Coding Agent Workflow Toolkit. This agent will enable proactive feature discovery, gap analysis, and strategic planning by systematically analyzing system areas and producing prioritized, actionable feature recommendations.

## Scope of Work

- **Agent Configuration**: Create feature-research subagent with specialized system prompt and tool access
- **Research Methodology**: Define structured approach for feature discovery and analysis
- **Output Format**: Establish .fr.md file format for feature research reports
- **Integration**: Ensure research outputs integrate with existing task management workflows

### Deliverables

#### Behavioral Specifications
- Feature research methodology documentation
- Prioritization framework definition
- Output format specification (.fr.md template)

#### Agent Configuration
- Subagent configuration file with system prompt
- Tool access configuration
- Research workflow integration

#### Validation Artifacts
- Example research prompt and expected output
- Success criteria validation checklist
- Integration test scenarios

## Implementation Plan

### Phase 1: Agent Configuration
- [ ] Create `.claude/agents/feature-research.md` with specialized system prompt
- [ ] Configure tool access (Read, Grep, Glob, WebSearch, WebFetch, TodoWrite, Write, Task)
- [ ] Define agent invocation patterns and descriptions

### Phase 2: Research Methodology
- [ ] Develop structured research approach based on example CMS admin research
- [ ] Create prioritization framework for discovered features
- [ ] Define output format template for .fr.md files

### Phase 3: Integration & Testing
- [ ] Test agent with example research prompts
- [ ] Validate output file generation and format
- [ ] Ensure integration with task management workflows

## Technical Approach

### System Prompt Design
The agent's system prompt will include:
- Research methodology instructions
- Context analysis patterns
- Feature prioritization framework
- Documentation synthesis capabilities
- Comparative analysis approach
- Structured output formatting for .fr.md files

### Tool Configuration
```yaml
tools: Read, Grep, Glob, WebSearch, WebFetch, TodoWrite, Write, Task
```

### Output Format (.fr.md)
```markdown
# Feature Research: [Topic]
Date: {datetime}
Status: research-complete

## Executive Summary
[Brief overview of research findings]

## Current State Analysis
[Analysis of existing functionality]

## Comparable Systems Research
[Research on similar systems and best practices]

## Identified Gaps
[List of missing features with rationale]

## Prioritized Feature List
### High Priority
- Feature 1: [Description and justification]
- Feature 2: [Description and justification]

### Medium Priority
- Feature 3: [Description and justification]

### Low Priority
- Feature 4: [Description and justification]

## Implementation Readiness Assessment
[Technical feasibility and dependencies]

## Recommendations
[Next steps and action items]
```


## File Modifications

### Create
- `.claude/agents/feature-research.md`
  - Purpose: Subagent configuration with specialized system prompt
  - Key components: Agent metadata, tool access list, research methodology prompt
  - Dependencies: Claude Code subagent system

- `dev-taskflow/backlog/{datetime}-{topic}.fr.md` (output files)
  - Purpose: Structured feature research reports
  - Key components: Gap analysis, prioritized features, implementation readiness
  - Dependencies: Task management workflow

## Execution Steps

- [ ] **Create Agent Configuration**: Write `.claude/agents/feature-research.md` with system prompt
  > TEST: Agent Configuration Validation
  > Assert: Agent file exists with proper YAML frontmatter and system prompt
  > Command: Verify file structure and tool access configuration

- [ ] **Implement Research Methodology**: Define structured approach in system prompt
  > TEST: Methodology Completeness
  > Assert: System prompt includes all research phases and prioritization framework
  > Command: Review prompt for comprehensive research instructions

- [ ] **Configure Output Format**: Establish .fr.md template structure in agent prompt
  > TEST: Output Format Validation
  > Assert: Agent generates properly formatted feature research files
  > Command: Test with example prompt and verify output structure

- [ ] **Test Feature Discovery**: Validate agent can identify and prioritize features
  > TEST: Research Quality Check
  > Assert: Agent produces actionable, prioritized feature recommendations
  > Command: Run test research on known system area

- [ ] **Verify File Generation**: Ensure agent saves reports to correct location
  > TEST: File Output Validation
  > Assert: Research reports saved to dev-taskflow/backlog/ with correct naming
  > Command: Check file creation with proper datetime-topic.fr.md format



## Out of Scope

- ❌ **Implementation Details**: Specific code structure or technical architecture for discovered features
- ❌ **Automatic Task Creation**: Direct conversion of research findings to task files (use draft-task workflow)
- ❌ **Feature Implementation**: Actual coding of discovered features
- ❌ **External API Integration**: Direct integration with project management tools

## References

- Original idea: `dev-taskflow/backlog/ideas/20250804-1613-feature-research-agent.md`
- Claude Code Subagents Documentation: https://docs.anthropic.com/en/docs/claude-code/subagents
- Example research prompt from CMS admin analysis
- Task management workflows: `dev-handbook/workflow-instructions/`