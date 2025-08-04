---
id: v.0.4.0+task.022
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Create Feature Research Subagent

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions - RESOLVED
- [x] **Model Selection**: Agent will use Opus model by default
  - **Decision**: Use Opus for maximum capability
  - **Implemented**: Added `model: opus` to YAML frontmatter

- [x] **Proactive Invocation**: Using recommended "use PROACTIVELY" phrasing
  - **Decision**: Follow best practices for automatic delegation
  - **Implemented**: Updated description to include "Use PROACTIVELY"

### [MEDIUM] Enhancement Questions - RESOLVED
- [x] **Parallel Research**: Enabled for multiple research areas
  - **Decision**: Use Task tool for parallel execution when multiple research streams identified
  - **Implemented**: Added parallel research instructions to system prompt

- [x] **Output Versioning**: Not required
  - **Decision**: No schema version needed in .fr.md files
  - **Implemented**: No changes needed

## Research Findings (Added During Review)

### Best Practices Beyond Documentation (2025)

#### 1. Model Selection Capability
As of Claude Code v1.0.64, subagents can specify which model to use:
```yaml
model: opus  # Selected for maximum capability
```
This allows cost optimization for specific tasks.

#### 2. Context Isolation Benefits
- Each subagent gets its own context window
- Prevents context pollution in long conversations
- Enables handling larger codebases effectively

#### 3. Orchestration Patterns
Common patterns for agent coordination:
- **Sequential**: A → B → C → Result
- **Parallel**: A + B (simultaneous) → Merge
- **Routing**: Analysis → Route to specialist
- **Review**: Primary → Review → Final

#### 4. Performance Optimizations
- Parallelism capped at 10 concurrent agents
- Task queueing for overflow
- Early delegation preserves main context

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

### Validation Questions (Original - Answered Through Research)
- [x] **Research Scope**: What level of detail is expected in the feature analysis?
  - **Answer**: Based on template, comprehensive 5-phase approach with executive summary level detail
- [x] **Prioritization Criteria**: What specific factors should drive feature prioritization?
  - **Answer**: Current prompt uses: user value, complexity, security, competitive parity
- [x] **External Research**: Should the agent research competitor products or focus only on internal gaps?
  - **Answer**: Phase 2 explicitly includes competitor research via WebSearch/WebFetch
- [x] **Implementation Assessment**: How deep should the technical feasibility analysis go?
  - **Answer**: High/Medium/Low complexity rating with dependencies list

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

### Planning Steps
* [ ] **Architecture Analysis**: Review Claude Code subagent architecture and file structure
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Subagent configuration structure and requirements are understood
  > Command: Verify .claude/agents/ directory structure and YAML frontmatter format

* [ ] **Research Methodology Design**: Analyze existing research patterns and best practices
  > TEST: Methodology Validation
  > Type: Design Review
  > Assert: Research methodology covers all required phases (analysis, research, gap identification, prioritization)
  > Command: Review methodology against example CMS admin research requirements

* [ ] **Tool Selection Analysis**: Verify required tools for comprehensive research
  > TEST: Tool Coverage Check
  > Type: Capability Validation
  > Assert: Selected tools (Read, Grep, Glob, WebSearch, WebFetch, TodoWrite, Write, Task) cover all research needs
  > Command: Validate each tool's purpose in research workflow

### Execution Steps

## Technical Approach

### Architecture Pattern
- [x] **Claude Code Subagent Pattern**: Markdown file with YAML frontmatter configuration
- [x] **Integration**: Project-level subagent in `.claude/agents/` directory
- [x] **Impact**: Extends Claude Code with specialized research capabilities

### Technology Stack
- [x] **Claude Code Platform**: Built-in subagent system with Task tool delegation
- [x] **Tool Access**: Read, Grep, Glob for code analysis; WebSearch, WebFetch for external research
- [x] **Output Format**: Markdown files (.fr.md) for structured documentation
- [x] **Version Compatibility**: Compatible with current Claude Code version

### Implementation Strategy
- [x] **Configuration-First Approach**: Leverage existing subagent infrastructure
- [x] **System Prompt Engineering**: Comprehensive instructions for autonomous research
- [x] **Template-Driven Output**: Structured .fr.md format for consistency
- [x] **Workflow Integration**: Outputs compatible with existing task management system
- [x] **Model Optimization**: Configured to use Opus model for maximum capability
- [x] **Parallel Processing**: Enabled sub-task delegation for large research scopes

## Tool Selection

| Criteria | Built-in Tools | External APIs | Custom Scripts | Selected |
|----------|---------------|---------------|----------------|----------|
| Performance | Excellent | Good | Fair | Built-in |
| Integration | Native | Requires setup | Complex | Built-in |
| Maintenance | Managed | API changes | High effort | Built-in |
| Security | Sandboxed | API keys | Risk exposure | Built-in |
| Learning Curve | Documented | Variable | High | Built-in |

**Selection Rationale:** Built-in Claude Code tools provide native integration, security, and maintenance-free operation

### Dependencies
- [x] **Claude Code Platform**: Required for subagent execution
- [x] **File System Access**: For reading code and writing research reports
- [x] **Web Access**: For external research (via WebSearch/WebFetch tools)


## File Modifications

### Verify Existing
- `.claude/agents/feature-research.md`
  - Status: **Already exists** (created in draft-task workflow)
  - Purpose: Subagent configuration with specialized system prompt
  - Key components: YAML frontmatter (name, description, tools), 5-phase research methodology, output template
  - Dependencies: Claude Code subagent system
  - Validation: Ensure all components are properly configured

### Create (Runtime)
- `dev-taskflow/backlog/{datetime}-{topic}.fr.md` (output files)
  - Purpose: Structured feature research reports generated by agent
  - Key components: Executive summary, gap analysis, prioritized features, implementation readiness
  - Dependencies: Agent execution, Write tool access
  - Naming: ISO datetime format (YYYYMMDD-HHMM) with hyphenated topic

- [ ] **Step 1: Verify Agent Configuration Structure**
  > TEST: Configuration File Validation
  > Type: File Structure Check
  > Assert: .claude/agents/feature-research.md exists with correct YAML frontmatter (name, description, tools)
  > Command: cat .claude/agents/feature-research.md | head -10

- [ ] **Step 2: Validate System Prompt Components**
  > TEST: Prompt Completeness Check
  > Type: Content Validation
  > Assert: System prompt includes all 5 research phases, prioritization framework, and output template
  > Command: grep -E "Phase [1-5]:|Priority:|Output Format" .claude/agents/feature-research.md

- [ ] **Step 3: Test Agent Invocation**
  > TEST: Agent Accessibility
  > Type: Integration Test
  > Assert: Agent can be invoked with "Use the feature-research agent" command
  > Command: echo "Test: Agent responds to invocation pattern"

- [ ] **Step 4: Validate Research Methodology**
  > TEST: Research Workflow Validation
  > Type: Process Verification
  > Assert: Agent follows structured 5-phase research approach
  > Command: grep -A 5 "Research Methodology" .claude/agents/feature-research.md

- [ ] **Step 5: Verify Output Template**
  > TEST: Template Structure Check
  > Type: Format Validation
  > Assert: .fr.md template includes all required sections (Executive Summary, Current State, Gaps, Priorities, etc.)
  > Command: grep -E "Executive Summary|Current State|Identified Gaps|Prioritized Feature List" .claude/agents/feature-research.md

- [ ] **Step 6: Test File Output Configuration**
  > TEST: Output Path Validation
  > Type: Configuration Check
  > Assert: Agent configured to save files to dev-taskflow/backlog/ with {datetime}-{topic}.fr.md pattern
  > Command: grep "dev-taskflow/backlog" .claude/agents/feature-research.md

- [ ] **Step 7: Create Test Invocation Example**
  > TEST: Example Usage Documentation
  > Type: Documentation Validation
  > Assert: Agent includes clear invocation examples
  > Command: grep -A 3 "Example Invocation" .claude/agents/feature-research.md

- [ ] **Step 8: Document Integration Points**
  > TEST: Workflow Integration
  > Type: Process Integration Check
  > Assert: Research outputs can be used with draft-task workflow
  > Command: Verify .fr.md files can be referenced as input for task creation



## Additional Considerations (From Review)

### Prompt Engineering Enhancements
Based on best practices research:
- Consider adding "MUST BE USED" for stronger proactive invocation
- Include specific invocation triggers in description
- Add error recovery instructions in system prompt

### Integration Patterns
- Feature research → draft-task workflow confirmed compatible
- .fr.md format allows manual review before task creation
- Consider adding metadata fields for traceability

## Risk Assessment

### Technical Risks
- **Risk:** Agent may produce inconsistent output formats
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Detailed template in system prompt
  - **Rollback:** Manual formatting of research reports

### Integration Risks
- **Risk:** Research reports may not integrate with task workflow
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Standardized .fr.md format compatible with draft-task workflow
  - **Monitoring:** Test conversion of research to draft tasks

### Performance Risks
- **Risk:** Web research tools may timeout or fail
  - **Mitigation:** Agent instructed to continue with available information
  - **Monitoring:** Check research completeness in reports
  - **Thresholds:** Minimum 3 comparable systems researched

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] **Research Automation**: Agent performs autonomous feature research when invoked
- [ ] **Gap Analysis**: Agent identifies and documents missing features with rationale
- [ ] **Prioritization**: Features are categorized by priority with clear justification
- [ ] **Output Generation**: Research reports are saved to correct location with proper format

### Implementation Quality Assurance
- [ ] **Configuration Validity**: Agent file has correct YAML frontmatter and tools
- [ ] **Prompt Completeness**: System prompt includes all research phases and templates
- [ ] **Integration Verification**: Research outputs can be used with draft-task workflow
- [ ] **Error Handling**: Agent handles missing resources gracefully

### Documentation and Validation
- [ ] **Invocation Examples**: Clear examples for using the agent
- [ ] **Quality Standards**: Research meets defined quality criteria
- [ ] **Workflow Integration**: Documented path from research to task creation

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
- Best Practices Research (2025): Model selection, context isolation, orchestration patterns
- Example implementations: git-commit-manager agent (project reference)
