# Research Workflow

## Goal

Conduct research on a topic with optional escalation to multi-agent research for complex or high-stakes investigations.

## Prerequisites

- Clear research question or topic
- Access to relevant codebase/documentation if researching implementation
- Understanding of when to use single vs multi-agent approach

## Project Context Loading

- Load relevant project documentation if researching project-specific topic
- Check for existing research on the topic

## High-Level Execution Plan

### Decision Point: Single vs Multi-Agent
- [ ] Evaluate research complexity
- [ ] Check multi-agent criteria
- [ ] Route to appropriate path

### Single-Agent Path
- [ ] Scope the research
- [ ] Gather information
- [ ] Analyze findings
- [ ] Produce deliverables

### Multi-Agent Path
- [ ] Invoke parallel-research workflow
- [ ] Follow synthesis workflow
- [ ] Validate combined output

## Process Steps

### Step 1: Evaluate Research Approach

Before beginning research, determine whether single-agent or multi-agent approach is appropriate.

**Use Multi-Agent Research When:**

| Criterion | Description |
|-----------|-------------|
| Complex topic | Research spans multiple domains or requires diverse expertise |
| High stakes | Errors would be costly; need cross-validation |
| Novel domain | Unknown territory benefits from multiple perspectives |
| Standard-setting | Establishing patterns/practices needs consensus |
| Exploratory | Broad search for options benefits from diversity |

**Use Single-Agent Research When:**

| Criterion | Description |
|-----------|-------------|
| Simple, well-defined | Clear scope with obvious approach |
| Time-critical | Need results quickly |
| Cost-sensitive | Budget constraints |
| Clear source of truth | Single authoritative answer exists |
| Implementation-focused | Execution benefits from consistency |

**Decision Questions:**
1. Would multiple perspectives add significant value?
2. Is the cost (3-5x tokens) justified by the stakes?
3. Do you have time for synthesis (20-30% additional effort)?

If answers are mostly **yes** → Multi-Agent Path
If answers are mostly **no** → Single-Agent Path

### Step 2A: Single-Agent Research

If single-agent approach selected:

1. **Scope the Research**
   - Define the research question precisely
   - Set boundaries (what's in/out of scope)
   - Identify expected deliverables
   - Set time/effort limits

2. **Gather Information**
   - Search codebase for relevant patterns
   - Review documentation
   - Consult external sources if appropriate
   - Note sources for all findings

3. **Analyze Findings**
   - Synthesize information into coherent narrative
   - Identify patterns and themes
   - Note gaps or uncertainties
   - Form recommendations

4. **Produce Deliverables**
   - Main research report
   - Supplementary artifacts as needed:
     - Guides (`.g.md`) for conceptual knowledge
     - Workflows (`.wf.md`) for processes
     - Templates for reusable structures

5. **Validate**
   - Does the report answer the research question?
   - Are findings well-supported?
   - Are recommendations actionable?

### Step 2B: Multi-Agent Research

If multi-agent approach selected:

1. **Load Parallel Research Workflow**
   ```
   ace-bundle wfi://handbook/parallel-research
   ```

2. **Complete Parallel Research Phases**
   - Setup: Define question, select agents
   - Dispatch: Launch parallel research
   - Monitor: Track completion
   - Cross-Review: Peer review phase
   - Handoff: Prepare for synthesis

3. **Load Synthesis Workflow**
   ```
   ace-bundle wfi://handbook/synthesize-research
   ```

4. **Complete Synthesis Phases**
   - Inventory: Catalog all outputs
   - Compare: Side-by-side analysis
   - Resolve: Handle conflicts
   - Synthesize: Combine outputs
   - Validate: Quality check

5. **Final Validation**
   - Does synthesis exceed individual agent quality?
   - Are all perspectives represented?
   - Are conflicts properly resolved?

## Research Report Template

```markdown
# {Topic} Research Report

**Date**: {YYYY-MM-DD}
**Researcher**: {agent/human}
**Approach**: Single-Agent / Multi-Agent

## Research Question

{Clear statement of what was investigated}

## Scope

**In Scope**:
- {item 1}
- {item 2}

**Out of Scope**:
- {item 1}

## Methodology

{How the research was conducted}

## Findings

### {Finding Category 1}

{Detailed findings with evidence}

### {Finding Category 2}

{Detailed findings with evidence}

## Recommendations

1. **{Recommendation 1}**
   - Rationale: {why}
   - Priority: {high/medium/low}

2. **{Recommendation 2}**
   - Rationale: {why}
   - Priority: {high/medium/low}

## Gaps and Limitations

- {Gap 1}: {what remains unknown}
- {Limitation 1}: {constraint on findings}

## References

- {Source 1}
- {Source 2}
```

## Success Criteria

- Research question is clearly answered
- Approach (single/multi-agent) is appropriate for complexity
- Findings are well-supported with evidence
- Recommendations are actionable
- Gaps and limitations are documented
- Deliverables follow project conventions

## Multi-Agent Option

For complex or high-stakes research, consider the multi-agent approach:

### When to Escalate

Evaluate these factors:

| Factor | Single-Agent | Multi-Agent |
|--------|--------------|-------------|
| Complexity | Low-Medium | High |
| Stakes | Low-Medium | High |
| Domain novelty | Familiar | Novel |
| Perspective value | Limited | High |
| Time available | Limited | Sufficient |
| Budget | Constrained | Flexible |

### How to Escalate

1. Review: `ace-bundle guide://multi-agent-research`
2. Invoke: `ace-bundle wfi://handbook/parallel-research`
3. Follow: Parallel Research → Synthesis workflows

### Expected Benefits

- 7-15% accuracy improvement (per ICE research)
- Reduced hallucinations through cross-validation
- Broader coverage of solution space
- Higher confidence in recommendations

## Related Resources

- [Multi-Agent Research Guide](guide://multi-agent-research) - Detailed guidance on multi-agent approach
- [Parallel Research Workflow](wfi://handbook/parallel-research) - Setting up parallel agent research
- [Synthesize Research Workflow](wfi://handbook/synthesize-research) - Combining agent outputs
- [Research Comparison Template](tmpl://research-comparison) - Template for synthesis
