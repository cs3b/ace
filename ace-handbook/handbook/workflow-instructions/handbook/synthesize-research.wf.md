# Synthesize Research Workflow

## Goal

Combine parallel agent research outputs into a unified, high-quality result through structured comparison, conflict resolution, and synthesis.

## Prerequisites

- Research folder containing outputs from multiple agents
- Completed parallel research phase (see `wfi://handbook/parallel-research`)
- Understanding of multi-agent research principles (see `guide://multi-agent-research`)

## Project Context Loading

- Load multi-agent research guide: `ace-bundle guide://multi-agent-research`
- Load comparison template: `ace-bundle tmpl://research-comparison`
- List research folder contents to identify agent outputs

## High-Level Execution Plan

### Phase 1: Inventory
- [ ] List all agent outputs (reports and supplementary artifacts)
- [ ] Create comparison matrix from template
- [ ] Mark artifact presence and initial quality assessment

### Phase 2: Compare
- [ ] Side-by-side analysis by artifact type
- [ ] Note conflicts and disagreements
- [ ] Rate depth, accuracy, actionability (1-5 scale)

### Phase 3: Resolve
- [ ] Document each conflict with both positions
- [ ] Research/verify factual disagreements
- [ ] Make decisions with documented rationale

### Phase 4: Synthesize
- [ ] Select base for each artifact (most comprehensive)
- [ ] Merge unique contributions from other agents
- [ ] Ensure consistent terminology
- [ ] Credit source reports

### Phase 5: Validate
- [ ] Completeness check (nothing valuable lost)
- [ ] Consistency check (no contradictions)
- [ ] Gap identification (for future work)

## Process Steps

### Phase 1: Inventory

1. **List All Agent Outputs**

   Scan the research folder to identify all outputs:
   ```bash
   ls -la {research_folder}/
   ```

   Expected pattern:
   ```
   {ts1}-{agent1}-report.md
   {ts1}-{agent1}-report-enhanced.md (if cross-review done)
   {ts1}-{agent1}-supplementary/
   {ts2}-{agent2}-report.md
   ...
   ```

2. **Create Comparison Matrix**

   Copy the comparison template to synthesis folder:
   ```
   {research_folder}/synthesis/comparison-matrix.md
   ```

   Fill in the Overview section:
   - Task description
   - Agent list with models
   - Timestamp range
   - Research folder path

3. **Catalog All Artifacts**

   For each agent, list:
   - Main report (and enhanced version if exists)
   - Guides (`.g.md` files)
   - Workflows (`.wf.md` files)
   - Templates (`.template.md` files)
   - Skills (if any)

   Record in the Artifact Inventory section of the matrix.

4. **Initial Quality Assessment**

   For each artifact, provide initial rating (1-5):
   - 5: Comprehensive, thorough, actionable
   - 4: Good coverage with useful detail
   - 3: Adequate, covers basics
   - 2: Basic, some gaps
   - 1: Minimal, significant issues

### Phase 2: Compare

1. **Reports Comparison**

   For main reports, analyze:

   | Dimension | What to Compare |
   |-----------|-----------------|
   | Coverage | Which topics each report addresses |
   | Depth | Level of detail on key topics |
   | Structure | Organization and readability |
   | Evidence | Use of sources and citations |
   | Actionability | Practical recommendations |

   Fill in the "Reports Comparison" section of the matrix.

2. **Artifacts Comparison**

   For each artifact type (guides, workflows, templates):
   - Identify overlapping artifacts (same purpose, different implementations)
   - Note unique artifacts (only one agent produced)
   - Compare quality of overlapping artifacts

   Fill in comparison tables for each type.

3. **Document Disagreements**

   When agents disagree on facts, recommendations, or approaches:
   - Record in the Conflict Log section
   - Note the topic and each agent's position
   - Mark for resolution in Phase 3

### Phase 3: Resolve

1. **Process Each Conflict**

   For each entry in the Conflict Log:

   a. **Document Both Positions**
      - What does Agent A claim/recommend?
      - What does Agent B claim/recommend?
      - Are there more positions from other agents?

   b. **Research/Verify**
      - If factual disagreement: check authoritative sources
      - If recommendation disagreement: evaluate trade-offs
      - If approach disagreement: consider context and use cases

   c. **Make Decision**
      - Choose the stronger position OR
      - Synthesize a combined approach OR
      - Note as "context-dependent" with guidance

   d. **Record Rationale**
      - Why was this resolution chosen?
      - What evidence supports it?
      - What are the trade-offs?

2. **Update Conflict Log**

   Complete the Resolution and Rationale fields for each conflict.

### Phase 4: Synthesize

1. **Create Synthesis Folder Structure**
   ```
   {research_folder}/synthesis/
   ├── report.md              # Unified report
   ├── comparison-matrix.md   # Decisions documented
   ├── sources.md             # Attribution
   └── artifacts/
       ├── guides/
       ├── workflows/
       ├── templates/
       └── skills/
   ```

2. **Synthesize Main Report**

   a. **Select Base**
      - Choose the most comprehensive report as starting point
      - Usually the highest-rated report from Phase 2

   b. **Merge Unique Content**
      - From each other report, identify unique valuable content
      - Add to the base report with attribution
      - Example: "As noted in the Gemini analysis..."

   c. **Integrate Resolved Conflicts**
      - Replace conflicting sections with resolved positions
      - Include rationale where helpful

   d. **Ensure Consistency**
      - Standardize terminology across merged content
      - Smooth transitions between sections
      - Remove redundancy

3. **Synthesize Artifacts**

   For each artifact type:

   | Scenario | Action |
   |----------|--------|
   | One agent only | Use as-is with attribution |
   | Multiple similar | Merge best elements |
   | Multiple different | Keep both if distinct purposes |
   | Low quality only | Improve or note gap |

   Apply decisions from comparison matrix.

4. **Create Attribution Document**

   In `synthesis/sources.md`:
   ```markdown
   # Synthesis Sources

   ## Agent Contributions

   ### Agent A (Claude, 8ous1t)
   - Base for main report structure
   - Guides: multi-agent-research.g.md
   - Workflows: synthesize-research.wf.md

   ### Agent B (Gemini, 8ous2a)
   - Examples section in main report
   - Templates: research-comparison.template.md

   ### Agent C (Codex, 8ous3b)
   - Edge cases analysis
   - Skills: parallel-research skill
   ```

### Phase 5: Validate

1. **Completeness Check**

   Review against original agent outputs:
   - [ ] All key findings from each report are represented
   - [ ] No valuable artifacts were accidentally dropped
   - [ ] Unique contributions from each agent preserved
   - [ ] All conflicts have documented resolutions

2. **Consistency Check**

   Review the synthesized output:
   - [ ] No contradictions within the report
   - [ ] Terminology is consistent throughout
   - [ ] Recommendations align with findings
   - [ ] Cross-references are accurate

3. **Gap Identification**

   Document any gaps discovered:
   - Topics no agent covered adequately
   - Questions raised but not answered
   - Areas needing future research

   Record in the Gaps Identified section of the matrix.

4. **Final Quality Assessment**

   Rate the synthesis overall:
   - Does it exceed the quality of individual reports?
   - Are the best insights from each agent preserved?
   - Is it actionable and well-organized?

## Embedded Templates

### Synthesis Report Template

```markdown
# {Topic} - Synthesis Report

**Synthesized**: {date}
**Sources**: {agent1} ({model}), {agent2} ({model}), {agent3} ({model})
**Research Folder**: {path}

## Executive Summary

[Combined key findings and recommendations]

## Methodology

This report synthesizes parallel research from {N} AI agents:
- {Agent1}: {brief contribution description}
- {Agent2}: {brief contribution description}
- {Agent3}: {brief contribution description}

Synthesis followed the multi-agent research workflow with:
- {N} artifacts compared
- {N} conflicts resolved
- {N} gaps identified

## Findings

### {Topic 1}

[Synthesized content with attribution where relevant]

### {Topic 2}

[Synthesized content]

## Recommendations

1. **{Recommendation 1}**
   - Rationale: [why]
   - Source: [which agent(s) proposed]

2. **{Recommendation 2}**
   - Rationale: [why]
   - Source: [which agent(s) proposed]

## Artifacts Produced

| Artifact | Type | Description |
|----------|------|-------------|
| [name] | guide | [description] |
| [name] | workflow | [description] |

## Gaps for Future Work

- [Gap 1]: [description and suggested follow-up]
- [Gap 2]: [description and suggested follow-up]

## References

[Combined references from all agents]

## Attribution

See `sources.md` for detailed contribution breakdown.
```

### Sources Template

```markdown
# Synthesis Sources

## Overview

| Agent | Model | Timestamp | Primary Contributions |
|-------|-------|-----------|----------------------|
| {agent1} | {model} | {ts} | {contributions} |
| {agent2} | {model} | {ts} | {contributions} |
| {agent3} | {model} | {ts} | {contributions} |

## Detailed Contributions

### {Agent 1}

**Report**: {ts}-{agent}-report.md

**Sections Used**:
- {Section name}: [how it was used]

**Artifacts Used**:
- {artifact}: [how it was used]

### {Agent 2}

[Similar structure]

## Conflict Resolutions

| Conflict | Resolution | Source |
|----------|------------|--------|
| {topic} | {decision} | {which agent's position} |

## Synthesis Decisions

| Decision | Rationale |
|----------|-----------|
| Used {agent} as base | Most comprehensive structure |
| Merged {agent}'s examples | Clearer practical guidance |
```

## Success Criteria

- Comparison matrix is complete with all artifacts
- All conflicts have documented resolutions with rationale
- Unified report covers all key findings from source reports
- No contradictions in final output
- Gaps identified for future work
- All sources properly credited
- Synthesis quality exceeds individual agent outputs

## Error Handling

**Missing Agent Output:**
- Document which agent output is missing
- Proceed with available outputs
- Note reduced coverage in validation

**Irreconcilable Conflict:**
- If no clear resolution, document both positions
- Mark as "context-dependent" with guidance
- Let users choose based on their context

**Quality Concerns:**
- If synthesis quality is lower than expected, iterate
- Consider re-running Phase 4 with different base selection
- Document any compromises made

## Usage Examples

### Basic Usage
```bash
ace-bundle wfi://handbook/synthesize-research
```

### With Custom Output
```bash
ace-bundle wfi://handbook/synthesize-research
```

## Related Resources

- [Multi-Agent Research Guide](guide://multi-agent-research) - Principles and best practices
- [Parallel Research Workflow](wfi://handbook/parallel-research) - Previous phase in the process
- [Research Comparison Template](tmpl://research-comparison) - Template for comparison matrix
