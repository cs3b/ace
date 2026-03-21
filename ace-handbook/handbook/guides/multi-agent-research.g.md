---
doc-type: guide
title: Multi-Agent Research Guide
purpose: Documentation for ace-handbook/handbook/guides/multi-agent-research.g.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Multi-Agent Research Guide

This guide explains when and how to leverage multiple AI agents for research tasks, combining their diverse capabilities to produce higher-quality, more comprehensive results.

## Purpose

Multi-agent research uses parallel execution across different AI models followed by structured synthesis to:
- Reduce individual model blind spots through cross-validation
- Surface diverse perspectives and approaches
- Increase confidence in findings through consensus
- Extend effective context through task division

## When to Use Multi-Agent Research

### Good Use Cases

| Scenario | Why Multi-Agent Helps |
|----------|----------------------|
| Complex research topics | Different models have different knowledge and reasoning styles |
| High-stakes decisions | Cross-validation reduces hallucinations and errors |
| Novel domains | Diverse perspectives surface more options |
| Standard-setting | Consensus building across multiple viewpoints |
| Exploratory research | Broader coverage of solution space |

### When NOT to Use

| Scenario | Why Single Agent is Better |
|----------|---------------------------|
| Simple, well-defined tasks | Overhead not justified |
| Time-critical work | Parallel + synthesis adds latency |
| Cost-sensitive projects | 3x+ token usage |
| Clear single source of truth | No benefit from diversity |
| Implementation tasks | Execution benefits from consistency |

### Decision Criteria

Ask yourself:
1. **Is the task primarily research or implementation?** Multi-agent works best for research.
2. **Would multiple perspectives add value?** If one answer is clearly correct, single agent suffices.
3. **Is the cost justified?** Multi-agent typically costs 3-5x a single-agent approach.
4. **Do you have time for synthesis?** Plan for 20-30% additional effort for combination.

## Agent Selection Criteria

### Quality Over Diversity

Research shows that mixing high-quality agents produces better results than adding lower-quality agents for diversity. The key finding:

> "Diversity in MoA proposers might have an adverse effect... MoA performance is sensitive to the quality of the models being mixed."
> — Princeton Research on Mixture-of-Agents

### Selection Principles

1. **Choose capable models**: Each agent should be able to complete the task solo
2. **Prefer complementary strengths**: Agents with different training data or specializations
3. **Avoid weak links**: One poor agent can degrade overall synthesis quality
4. **Consider context limits**: Match agent capabilities to task requirements

### Recommended Configurations

| Research Type | Suggested Agents | Rationale |
|---------------|------------------|-----------|
| Code analysis | Claude, Codex, Gemini | Strong code understanding |
| Technical docs | Claude, Gemini | Strong reasoning and knowledge |
| Architecture | Claude, Gemini, GPT-4 | Diverse design perspectives |
| Security review | Multiple specialized models | Defense in depth |

## Task Formulation for Parallel Work

### Consistent Prompting

All agents should receive the same core prompt to enable meaningful comparison:

```markdown
## Research Task

**Topic**: [Clear description of what to research]
**Scope**: [Boundaries of the investigation]
**Expected Outputs**:
- Main report with findings
- Supplementary artifacts (guides, templates, etc.)
- Recommendations with rationale

## Context
[Shared context all agents need]

## Deliverables Format
[Consistent structure for outputs]
```

### Avoid These Pitfalls

- **Vague prompts**: Lead to incomparable outputs
- **Different scopes**: Make synthesis difficult
- **Inconsistent output formats**: Complicate comparison
- **Missing context**: Results in agents making different assumptions

## Cross-Review Protocol

The cross-review phase is critical for surfacing blind spots and building toward consensus.

### Process

1. **Distribution**: Each agent receives all other agents' reports
2. **Analysis**: Each agent identifies:
   - Points of agreement (reinforces confidence)
   - Points of disagreement (requires resolution)
   - Gaps in other reports (opportunities for contribution)
   - Improvements to incorporate
3. **Self-Enhancement**: Each agent improves own report with peer insights
4. **Attribution**: Credit sources when incorporating ideas

### Cross-Review Prompt Template

```markdown
## Cross-Review Task

You have completed initial research on [topic]. Below are reports from peer agents.

### Peer Reports
[Include all peer reports]

### Your Task
1. Identify agreements across reports
2. Note disagreements and evaluate which position is stronger
3. Find gaps in your report that peers covered
4. Enhance your report by incorporating valuable insights (with attribution)
5. Document your reasoning for key decisions
```

## Synthesis Process Overview

Synthesis combines multiple agent outputs into a unified result. See [Synthesize Research Workflow](wfi://handbook/synthesize-research) for detailed execution steps.

### Key Phases

```
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 1: INVENTORY                       │
│  - List all reports and supplementary artifacts             │
│  - Create comparison matrix (artifacts × agents)            │
│  - Rate quality and completeness                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 2: COMPARE                         │
│  - Side-by-side analysis by artifact type                   │
│  - Note conflicts and disagreements                         │
│  - Rate depth, accuracy, actionability                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 3: RESOLVE                         │
│  - Document conflicts with both positions                   │
│  - Research/verify factual disagreements                    │
│  - Make reasoned decisions with rationale                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 4: SYNTHESIZE                      │
│  - Select base (usually most comprehensive report)          │
│  - Merge unique contributions from others                   │
│  - Ensure consistent terminology                            │
│  - Credit source reports                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 5: VALIDATE                        │
│  - Completeness check (nothing valuable lost)               │
│  - Consistency check (no contradictions)                    │
│  - Gap identification (for future work)                     │
└─────────────────────────────────────────────────────────────┘
```

### Aggregator Role

The synthesis should be performed by a dedicated aggregator (human or agent) who:
- Has access to all agent outputs
- Can make objective comparisons
- Documents all decisions with rationale
- Produces unified, consistent output

## Quality Validation Checklist

### Before Parallel Research

- [ ] Research question is clearly defined
- [ ] All agents receive identical prompts
- [ ] Output format is specified consistently
- [ ] Shared context is complete and accurate
- [ ] Success criteria are defined

### After Cross-Review

- [ ] Each agent produced enhanced report
- [ ] Agreements are documented
- [ ] Disagreements are identified
- [ ] Sources are properly attributed

### After Synthesis

- [ ] Comparison matrix is complete
- [ ] All conflicts have documented resolutions
- [ ] Unified report covers all key findings
- [ ] No contradictions in final output
- [ ] Gaps are identified for future work
- [ ] All sources are credited

## Key Insights from Research

### Industry Patterns

| Pattern | Description | Benefit |
|---------|-------------|---------|
| Mixture-of-Agents (MoA) | Proposers generate, aggregator synthesizes | Outperforms single agents |
| Iterative Consensus (ICE) | 2-3 rounds of critique until consensus | +7-15% accuracy |
| LLM-BLENDER | Rank responses, blend best ones | Selects highest quality |

### Best Practices

1. **Quality > Quantity**: 3 quality agents outperform 5 mediocre ones
2. **Document decisions**: Synthesis rationale is valuable for future reference
3. **Human validation**: Final quality check remains important
4. **Iterate if needed**: 2-3 review rounds typically sufficient

## Related Resources

- [Research Comparison Template](tmpl://research-comparison) - Structured comparison matrix
- [Synthesize Research Workflow](wfi://handbook/synthesize-research) - Detailed synthesis process
- [Parallel Research Workflow](wfi://handbook/parallel-research) - Setting up parallel execution

## References

### Academic Sources
- [Mixture-of-Agents (arXiv 2406.04692)](https://arxiv.org/abs/2406.04692)
- [Multi-Agent Collaboration Mechanisms Survey (arXiv 2501.06322)](https://arxiv.org/abs/2501.06322)
- [Iterative Consensus Ensemble (ScienceDirect)](https://www.sciencedirect.com/science/article/abs/pii/S0010482525010820)

### Industry Sources
- [LLM Orchestration Best Practices (orq.ai)](https://orq.ai/blog/llm-orchestration)
- [Multi-Agent LLMs in 2025 (SuperAnnotate)](https://www.superannotate.com/blog/multi-agent-llms)
- [Awesome-LLM-Ensemble (GitHub)](https://github.com/junchenzhi/Awesome-LLM-Ensemble)
