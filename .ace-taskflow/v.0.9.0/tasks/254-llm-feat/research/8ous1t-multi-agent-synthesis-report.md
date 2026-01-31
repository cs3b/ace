# Multi-Agent Research Synthesis: Process & Best Practices

**ID**: 8ous1t
**Date**: 2026-01-31
**Topic**: How to combine outputs from multiple AI agents into unified results
**Context**: Experiment with 3 agents (Codex CLI, Gemini CLI, Claude Code) on task 253

---

## Executive Summary

Multi-agent collaboration follows a **"Propose → Critique → Synthesize"** pattern. Industry research shows that parallel agent outputs should be combined by a dedicated aggregator role, not just iterated independently. This report documents best practices and proposes workflows for ACE.

---

## 1. Experiment Analysis

### What Was Done (Task 253)

| Phase | Description | Outcome |
|-------|-------------|---------|
| 1. Parallel Research | 3 agents independently researched test optimization | 3 reports + supplementary artifacts |
| 2. Cross-Review | Each agent read other two reports | Identified improvements |
| 3. Self-Improve | Each agent enhanced own report | Enhanced reports |
| 4. Synthesis | **Missing** | Need unified output |

### Artifact Inventory

| Type | Claude (8oup7s) | Gemini (8oup93) | Codex (8oupdg) |
|------|-----------------|-----------------|----------------|
| Report | 476 lines (comprehensive) | 93 lines (concise) | 87 lines |
| Guides | 5 proposed | 2 proposed | 5 proposed |
| Workflows | 4 proposed | 2 proposed | 6 proposed |
| Templates | 4 proposed | 0 | 5 proposed |
| Skills | 0 | 0 | 6 proposed |

---

## 2. Industry Research Findings

### Key Multi-Agent Synthesis Patterns

| Pattern | How It Works | Source |
|---------|--------------|--------|
| **Mixture-of-Agents (MoA)** | Layered architecture: proposers generate responses, aggregator synthesizes using all outputs as context | [arXiv 2406.04692](https://arxiv.org/abs/2406.04692) |
| **Iterative Consensus Ensemble (ICE)** | 3 LLMs critique each other until shared answer; typically 2-3 rounds; +7-15% accuracy | [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0010482525010820) |
| **LLM-BLENDER** | PairRanker selects TOP-K responses, GENFUSER blends into final output | [GitHub](https://github.com/junchenzhi/Awesome-LLM-Ensemble) |
| **DyLAN** | Multiple interaction rounds with early stopping mechanism | [IJCAI 2025](https://www.ijcai.org/proceedings/2025/0900.pdf) |

### Collaboration Stages (from Survey)

From [Multi-Agent Collaboration Mechanisms Survey](https://arxiv.org/abs/2501.06322):

1. **Early-stage**: Share data, context, environment
2. **Mid-stage**: Exchange parameters/weights (federated learning)
3. **Late-stage**: Ensemble outputs/actions toward collaborative goals

### Key Dimensions of Multi-Agent Collaboration

| Dimension | Options |
|-----------|---------|
| **Actors** | Homogeneous vs heterogeneous agents |
| **Types** | Cooperation, competition, coopetition |
| **Structures** | Peer-to-peer, centralized, distributed |
| **Strategies** | Role-based, model-based |
| **Coordination** | Synchronous, asynchronous, graph-based |

### Benefits of Multi-Agent Systems

From [SuperAnnotate](https://www.superannotate.com/blog/multi-agent-llms):
- **Accuracy**: Agents check each other's work (reduces hallucinations)
- **Extended context**: Divide tasks across agents
- **Efficiency**: Parallel processing
- **Expertise pooling**: Different agents contribute different strengths

### Important Caveat

From Princeton research cited in [BDTechTalks](https://bdtechtalks.com/2025/02/17/llm-ensembels-mixture-of-agents/):
> "Diversity in MoA proposers might have an adverse effect... MoA performance is sensitive to the quality of the models being mixed."

**Implication**: Quality > quantity. Don't add weak agents just for diversity.

---

## 3. Recommended Synthesis Workflow

### Complete Multi-Agent Research Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 1: PARALLEL RESEARCH               │
├─────────────────────────────────────────────────────────────┤
│  Agent A           │  Agent B           │  Agent C          │
│  (Model 1)         │  (Model 2)         │  (Model 3)        │
│    ↓ Report        │    ↓ Report        │    ↓ Report       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 PHASE 2: CROSS-REVIEW                       │
├─────────────────────────────────────────────────────────────┤
│  Each agent reads other reports                             │
│  Documents: agreements, conflicts, gaps, improvements       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 PHASE 3: SELF-IMPROVE                       │
├─────────────────────────────────────────────────────────────┤
│  Each agent enhances own report with peer insights          │
│  Credits sources where applicable                           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 PHASE 4: SYNTHESIZE                         │
├─────────────────────────────────────────────────────────────┤
│  Aggregator agent (can be any agent or dedicated 4th):     │
│  1. Creates comparison matrix (artifact × agent)            │
│  2. Identifies and resolves conflicts                       │
│  3. Produces unified report + artifacts                     │
│  4. Documents synthesis decisions with rationale            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 PHASE 5: VALIDATE                           │
├─────────────────────────────────────────────────────────────┤
│  Human review:                                              │
│  - Nothing valuable lost                                    │
│  - No contradictions in final output                        │
│  - Gaps identified for future work                          │
└─────────────────────────────────────────────────────────────┘
```

### Phase 4 Detailed: Aggregator Tasks

```yaml
aggregator_tasks:
  1_inventory:
    - List all reports and supplementary artifacts
    - Create comparison matrix (rows=artifacts, cols=agents)
    - Mark: present/absent, quality rating, unique contributions

  2_compare:
    - For each artifact type:
      - Side-by-side comparison
      - Note conflicts/disagreements
      - Rate: depth, accuracy, actionability (1-5 scale)

  3_resolve:
    - For each conflict:
      - Document both positions
      - Research/verify if factual disagreement
      - Make reasoned decision
      - Record rationale for future reference

  4_synthesize:
    - Select base (usually most comprehensive)
    - Merge unique contributions from others
    - Ensure consistent terminology
    - Credit source reports

  5_output:
    - synthesis/report.md - unified report
    - synthesis/comparison-matrix.md - how decisions were made
    - synthesis/artifacts/ - merged guides, workflows, templates
```

---

## 4. Synthesis Output Structure

### Recommended Directory Layout

```
{task}/research/
├── {ts1}-report.md              # Agent 1 report
├── {ts1}-supplementary/         # Agent 1 artifacts
├── {ts2}-report.md              # Agent 2 report
├── {ts2}-supplementary/         # Agent 2 artifacts
├── {ts3}-report.md              # Agent 3 report
├── {ts3}-supplementary/         # Agent 3 artifacts
└── synthesis/                   # Aggregator output
    ├── report.md                # Unified report
    ├── comparison-matrix.md     # Decisions documented
    ├── sources.md               # Attribution
    └── artifacts/
        ├── guides/
        ├── workflows/
        ├── templates/
        └── skills/
```

### Comparison Matrix Template

```markdown
## Artifact Comparison: {Artifact Type}

| Artifact Name | Agent A | Agent B | Agent C | Action | Rationale |
|---------------|---------|---------|---------|--------|-----------|
| example.g.md | Yes (5) | No | Yes (3) | Merge A+C | A more detailed |
| another.wf.md | Yes (4) | Yes (4) | No | Merge A+B | Both valuable |
```

**Rating scale**: 1=basic, 3=adequate, 5=comprehensive

---

## 5. Proposed ACE Artifacts

### Workflow: `/ace:synthesize-research`

```yaml
name: synthesize-research
purpose: Combine parallel agent research outputs into unified result
location: ace-handbook/handbook/workflow-instructions/synthesize-research.wf.md

inputs:
  research_folder: Path containing agent outputs
  output_folder: Where to write synthesis (default: {research_folder}/synthesis)

phases:
  - inventory
  - compare
  - resolve
  - synthesize
  - validate

outputs:
  - synthesis/report.md
  - synthesis/comparison-matrix.md
  - synthesis/artifacts/
```

### Guide: `multi-agent-research.g.md`

```yaml
name: multi-agent-research
purpose: How to run parallel agent research and synthesize results
location: ace-handbook/handbook/guides/multi-agent-research.g.md

sections:
  - when-to-use
  - agent-selection
  - task-formulation
  - cross-review-protocol
  - synthesis-process
  - quality-validation
```

### Template: `research-comparison.template.md`

```yaml
name: research-comparison
purpose: Comparison matrix for multi-agent outputs
location: ace-handbook/handbook/templates/research-comparison.template.md

sections:
  - overview
  - artifact-inventory
  - comparison-by-type
  - conflict-resolution
  - synthesis-decisions
```

---

## 6. When to Use Multi-Agent Research

### Good Use Cases

| Scenario | Why Multi-Agent Helps |
|----------|----------------------|
| Complex research topics | Different models have different knowledge |
| High-stakes decisions | Cross-validation reduces errors |
| Novel domains | Diverse perspectives surface options |
| Standard-setting | Consensus building |

### When NOT to Use

| Scenario | Why Single Agent is Better |
|----------|---------------------------|
| Simple, well-defined tasks | Overhead not justified |
| Time-critical work | Parallel + synthesis takes longer |
| Cost-sensitive | 3x+ token usage |
| Clear single source of truth | No benefit from diversity |

---

## 7. Key Insights

### From This Experiment

1. **Natural alignment with MoA**: Your cross-review step mirrors the "use prior outputs as context" pattern
2. **Missing synthesis role**: Industry patterns all include dedicated aggregation
3. **Quality over quantity**: 3 quality agents > 5 mediocre ones
4. **Document decisions**: Synthesis rationale is valuable for future reference

### From Research

1. **ICE achieves +7-15% accuracy** with 2-3 rounds of critique
2. **MoA outperformed GPT-4** on benchmarks using weaker models in ensemble
3. **Diversity can hurt** if low-quality agents are included
4. **Human validation** remains important for final quality check

---

## References

### Academic Sources
- [Mixture-of-Agents (arXiv 2406.04692)](https://arxiv.org/abs/2406.04692)
- [Multi-Agent Collaboration Mechanisms Survey (arXiv 2501.06322)](https://arxiv.org/abs/2501.06322)
- [Iterative Consensus Ensemble (ScienceDirect)](https://www.sciencedirect.com/science/article/abs/pii/S0010482525010820)
- [Dynamic LLM Ensemble (IJCAI 2025)](https://www.ijcai.org/proceedings/2025/0900.pdf)

### Industry Sources
- [LLM Orchestration Best Practices (orq.ai)](https://orq.ai/blog/llm-orchestration)
- [Multi-Agent LLMs in 2025 (SuperAnnotate)](https://www.superannotate.com/blog/multi-agent-llms)
- [Understanding LLM Ensembles (BDTechTalks)](https://bdtechtalks.com/2025/02/17/llm-ensembels-mixture-of-agents/)
- [Awesome-LLM-Ensemble (GitHub)](https://github.com/junchenzhi/Awesome-LLM-Ensemble)

### Related ACE Resources
- Task 253 research: `.ace-taskflow/v.0.9.0/tasks/253-test-perf/research/`
- Existing research workflow: `ace-handbook/handbook/workflow-instructions/research.wf.md`
