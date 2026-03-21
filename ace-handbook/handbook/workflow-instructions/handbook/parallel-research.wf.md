---
doc-type: workflow
title: Parallel Research Workflow
purpose: Documentation for ace-handbook/handbook/workflow-instructions/handbook/parallel-research.wf.md
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Parallel Research Workflow

## Goal

Set up and execute parallel research across multiple AI agents, producing consistent outputs ready for synthesis.

## Prerequisites

- Clear research question or topic defined
- Access to multiple AI agents (e.g., Claude Code, Gemini CLI, Codex CLI)
- Output folder for research results
- Understanding of multi-agent research principles (see `guide://multi-agent-research`)

## Project Context Loading

- Load multi-agent research guide: `ace-bundle guide://multi-agent-research`
- Check existing research folder structure if continuing previous work

## High-Level Execution Plan

### Phase 1: Setup
- [ ] Define research question clearly
- [ ] Select agents (quality > diversity)
- [ ] Create shared context and materials
- [ ] Prepare consistent prompt template

### Phase 2: Dispatch
- [ ] Create output folder structure
- [ ] Launch parallel research with identical prompts
- [ ] Assign unique timestamps to each agent

### Phase 3: Monitor
- [ ] Track agent completion
- [ ] Handle failures/retries
- [ ] Collect all outputs

### Phase 4: Cross-Review
- [ ] Distribute reports to all agents
- [ ] Each agent reviews peer reports
- [ ] Collect enhanced reports

### Phase 5: Handoff
- [ ] Verify all outputs collected
- [ ] Prepare for synthesis phase
- [ ] Invoke synthesize-research workflow

## Process Steps

### Phase 1: Setup

1. **Define Research Question**
   - Write a clear, specific research question
   - Define the scope and boundaries
   - List expected deliverables (report, guides, workflows, etc.)
   - Identify any constraints or requirements

2. **Select Agents**

   Follow quality > diversity principle:
   - Each agent should be capable of completing the task solo
   - Prefer agents with complementary strengths
   - Avoid adding weak agents just for diversity

   **Recommended configurations:**
   | Research Type | Suggested Agents |
   |---------------|------------------|
   | Code analysis | Claude, Codex, Gemini |
   | Technical docs | Claude, Gemini |
   | Architecture | Claude, Gemini, GPT-4 |

3. **Create Shared Context**
   - Gather all relevant background materials
   - Prepare codebase context if needed
   - Document any prior research or decisions
   - Create shared reference materials

4. **Prepare Prompt Template**

   Use the embedded template below for consistency:

### Phase 2: Dispatch

1. **Create Output Folder Structure**
   ```
   {task}/research/
   ├── context/                    # Shared materials
   │   ├── background.md
   │   └── references/
   └── agents/                     # Will contain agent outputs
   ```

2. **Generate Timestamps**
   - Use `ace-b36ts` or similar for unique IDs
   - Format: `{6-char-timestamp}-{agent-name}`
   - Example: `8ous1t-claude`, `8ous2a-gemini`

3. **Launch Parallel Research**
   - Send identical prompts to each agent
   - Include shared context materials
   - Specify output location and format
   - Start agents in parallel when possible

4. **Record Launch Details**
   ```markdown
   ## Research Launch Log
   | Agent | Model | Timestamp | Status |
   |-------|-------|-----------|--------|
   | Claude | claude-3-opus | 8ous1t | launched |
   | Gemini | gemini-pro | 8ous2a | launched |
   | Codex | gpt-4 | 8ous3b | launched |
   ```

### Phase 3: Monitor

1. **Track Completion**
   - Check each agent's progress
   - Note any errors or failures
   - Record completion times

2. **Handle Failures**
   - If an agent fails, assess cause
   - Retry with adjusted parameters if needed
   - Document any issues for future reference

3. **Collect Outputs**
   - Verify each agent produced expected deliverables
   - Move outputs to standard locations:
   ```
   {task}/research/
   ├── {ts1}-{agent1}-report.md
   ├── {ts1}-{agent1}-supplementary/
   ├── {ts2}-{agent2}-report.md
   ├── {ts2}-{agent2}-supplementary/
   └── ...
   ```

### Phase 4: Cross-Review

1. **Distribute Reports**
   - Each agent receives all other agents' reports
   - Include original shared context for reference

2. **Execute Cross-Review**
   - Use the cross-review prompt template below
   - Each agent identifies:
     - Points of agreement
     - Points of disagreement
     - Gaps in other reports
     - Improvements to incorporate

3. **Collect Enhanced Reports**
   - Each agent produces updated report
   - Updates should include attribution for borrowed ideas
   - Save as `{ts}-{agent}-report-enhanced.md`

### Phase 5: Handoff

1. **Verify Completeness**
   - All agents have submitted reports
   - Cross-review phase completed
   - Enhanced reports collected

2. **Prepare Synthesis Folder**
   ```
   {task}/research/
   ├── {ts1}-{agent1}-report.md
   ├── {ts1}-{agent1}-report-enhanced.md
   ├── {ts1}-{agent1}-supplementary/
   ├── {ts2}-{agent2}-report.md
   ├── {ts2}-{agent2}-report-enhanced.md
   ├── {ts2}-{agent2}-supplementary/
   └── synthesis/                  # Ready for next phase
   ```

3. **Load Synthesis Workflow**
   - Run `ace-bundle wfi://handbook/synthesize-research`
   - Continue with the research folder prepared in this workflow

## Embedded Templates

### Research Prompt Template

```markdown
## Research Task

**Topic**: {topic}

**Research Question**: {clear research question}

**Scope**:
- In scope: {what to include}
- Out of scope: {what to exclude}

**Expected Outputs**:
1. Main research report (comprehensive findings)
2. Supplementary artifacts as appropriate:
   - Guides (`.g.md`) for conceptual knowledge
   - Workflows (`.wf.md`) for procedural instructions
   - Templates for reusable structures

## Context

{shared context materials}

## Deliverables Format

### Report Structure
1. Executive Summary
2. Methodology
3. Findings (organized by theme)
4. Recommendations
5. References

### File Naming
- Report: `{timestamp}-{agent}-report.md`
- Artifacts: `{timestamp}-{agent}-supplementary/{artifact-name}`

## Quality Expectations
- Comprehensive coverage of topic
- Evidence-based findings with sources
- Actionable recommendations
- Clear structure and organization
```

### Cross-Review Prompt Template

```markdown
## Cross-Review Task

You have completed initial research on: {topic}

Your report: {path to your report}

## Peer Reports

Below are reports from peer agents. Review them to:
1. Identify agreements (increases confidence)
2. Note disagreements (requires resolution)
3. Find gaps in your report that peers covered
4. Identify unique insights worth incorporating

### Agent A Report
{content or path}

### Agent B Report
{content or path}

## Your Task

1. **Document Agreements**
   - List 3-5 key points all reports agree on

2. **Document Disagreements**
   - List any conflicting claims or recommendations
   - Evaluate which position seems stronger and why

3. **Identify Gaps**
   - What did peer reports cover that yours missed?
   - What unique insights do peers offer?

4. **Enhance Your Report**
   - Incorporate valuable insights from peers
   - Credit sources: "As noted by [Agent X]..."
   - Address any gaps identified
   - Strengthen weak areas based on peer feedback

5. **Output Enhanced Report**
   - Save as: `{timestamp}-{agent}-report-enhanced.md`
   - Include attribution for borrowed ideas
```

## Success Criteria

- All selected agents completed research
- Outputs follow consistent format
- Cross-review phase completed
- Enhanced reports collected
- Research folder ready for synthesis
- No critical failures unaddressed

## Error Handling

**Agent Failure:**
- Document the failure with error details
- Assess if retry is worthwhile
- If agent cannot complete, proceed with remaining agents
- Note reduced agent count in synthesis

**Inconsistent Outputs:**
- If outputs don't match expected format, request correction
- Document any deviations for synthesis phase

**Time Constraints:**
- If time-limited, prioritize initial reports over cross-review
- Cross-review can be abbreviated or skipped if necessary
- Document any shortcuts taken

## Usage Examples

### Basic Usage
```bash
ace-bundle wfi://handbook/parallel-research
```

### With Agent Selection
```bash
ace-bundle wfi://handbook/parallel-research
```

### Full Specification
```bash
ace-bundle wfi://handbook/parallel-research
```

## Related Resources

- [Multi-Agent Research Guide](guide://multi-agent-research) - When and why to use multi-agent research
- [Synthesize Research Workflow](wfi://handbook/synthesize-research) - Next phase after parallel research
- [Research Comparison Template](tmpl://research-comparison) - Template for synthesis phase
