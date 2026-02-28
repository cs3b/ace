---
title: 'Intent Engineering (Layer 3): Delegation Frameworks for Agent Workflows'
location: _archive
captured_at: '2026-02-24T12:00:00+00:00'
completed_at: '2026-02-25T15:10:40+00:00'
task_ref: v.0.9.0+task.281
id: 8pnwx0
status: done
tags: []
created_at: '2026-02-24 21:56:40'
---

# Intent Engineering (Layer 3): Delegation Frameworks for Agent Workflows

Research synthesis on translating human aspirations into agent-actionable parameters through structured delegation frameworks. The goal: help us delegate work to agents more efficiently.

## Rule of Thumb: The 3-Question Delegation Brief

Before delegating any task to an agent, answer three questions:

1. **What I hope to accomplish** — the impact we want to have, not the steps to get there. This is the *why*, framed as the change in the world we're after.
2. **What "complete" looks like** — a concrete description of the end state. The agent should be able to compare its output against this and know whether it's done.
3. **Specific success criteria** — a list of verifiable key results. Each one should be something the agent (or a reviewer) can check as pass/fail.

This is the minimum viable delegation brief. Everything else in this research — Huryn's 7 components, autonomy tiers, drift detection — builds on top of these three. If you only do one thing differently, do this.

**Why it works**: (1) separates intent from implementation so the agent can find its own path, (2) gives an unambiguous completion signal so the agent knows when to stop, (3) makes verification mechanical rather than subjective so review is fast.

**Applies beyond task delegation**: The same 3 questions work wherever intent needs to be communicated:
- **Task/idea specs** — what the work should achieve
- **PR descriptions** — what is the intention of this change, so reviewers know what to verify
- **Review focus** — reviewer evaluates against stated intent, not just code correctness
- **Commit messages** — why this change exists, not just what changed

The brief is a universal intent contract: the author states what they're trying to accomplish, and the reviewer (human or agent) checks whether the output achieves it.

**Anti-pattern**: Delegating with steps instead of outcomes ("do X, then Y, then Z") — this over-constrains the agent and makes it impossible to verify whether the *goal* was achieved vs. the *steps* were followed.

## Research Synthesis

### 1. Goal Translation Infrastructure

**Core problem**: Human goals are aspirational and ambiguous; agents need structured, actionable parameters. The gap between "make this better" and machine-executable instructions requires explicit translation infrastructure.

**Huryn's 7-Component Intent Spec** (ProductCompass 2025) provides the most actionable template:

| Component | Purpose | Example |
|-----------|---------|---------|
| Objective | What to achieve | "Reduce PR review turnaround to <4h" |
| Desired Outcomes | Success signals | "95% of PRs reviewed within SLA" |
| Health Metrics | Side-effect monitors | "Review quality score stays above 4/5" |
| Strategic Context | Why this matters now | "Scaling team from 5→15 engineers" |
| Constraints (Steering) | Trade-off guidance in prompts | "Prefer thoroughness over speed" |
| Constraints (Hard) | Non-negotiable boundaries in orchestration | "Never auto-merge without CI pass" |
| Decision Authority | What agent can decide alone | "Can request changes; cannot approve" |
| Stop Rules | When to halt and escalate | "If >3 review rounds, escalate to lead" |

**Steering vs Hard Constraints** — a critical distinction:
- **Steering constraints** live in prompts and guide trade-offs ("prefer X over Y"). They are soft, contextual, and the agent can weigh them.
- **Hard constraints** live in orchestration/tooling and are non-negotiable ("never do X"). They are enforced mechanically, not by agent judgment.

**Tericsoft's 4-Tier Autonomy Model** maps directly to delegation levels:

| Tier | Agent Behavior | Human Role | ACE Analog |
|------|---------------|------------|------------|
| Full Autonomy | Decides and acts | Informed after | Batch workflow, auto-commit |
| Guarded Autonomy | Decides and acts within bounds | Sets boundaries | Workflow with tool access controls |
| Proposal-First | Proposes, waits for approval | Approves/rejects | Plan mode, PR review |
| No Autonomy | Executes explicit instructions | Directs each step | Manual CLI tool usage |

**Signals pattern**: Every goal should decompose into:
- **Leading signals** (desired outcomes) — what success looks like
- **Lagging signals** (health metrics) — what must not degrade
- **Authorized actions** — what the agent can do to achieve signals
- **Trade-off rules** — when signals conflict, which wins

### 2. Delegation Framework & Resolution Hierarchy

**The convergent 3 pillars**: Every framework — classical management theory, military doctrine, modern AI agent research — converges on three dimensions:

| Pillar | Classical | AI Agent | Key Insight |
|--------|-----------|----------|-------------|
| Intent/Purpose | Responsibility | Goal Specification | Can be shared across levels |
| Authority/Scope | Authority | Decision Boundaries | Can be delegated with limits |
| Accountability/Oversight | Accountability | Feedback & Governance | Cannot be delegated — stays with delegator |

**DeepMind's 5-Pillar Intelligent Delegation** (arXiv:2602.11865, Feb 2026):

1. **Dynamic Assessment** — continuously evaluate agent capability vs task requirements (not one-time)
2. **Adaptive Execution** — adjust delegation level in real-time based on performance signals
3. **Structural Transparency** — agent must expose its reasoning, not just its outputs
4. **Scalable Market Coordination** — multi-agent task allocation as a market mechanism
5. **Systemic Resilience** — graceful degradation when agents fail or drift

**Progressive autonomy models**:

- **Bloom's 3 Levels**: Direct → Semiautonomous → Autonomous. Key insight: autonomy is *earned* through demonstrated reliability, not granted upfront.
- **Appelo's 7 Levels**: Tell → Sell → Consult → Agree → Advise → Inquire → Delegate. Each level represents a different split of decision-making power.

**Anthropic's Principal Hierarchy**: A concrete resolution hierarchy for conflicting instructions:
1. Anthropic (hardcoded safety) — always wins
2. Operator (system prompt, softcoded) — sets boundaries
3. User (runtime adjustments) — operates within operator bounds

This maps to a general pattern: when policies conflict, the higher-trust principal wins. The hierarchy is explicit, not implicit.

**Resolution hierarchy as a design pattern**: When an agent encounters conflicting guidance, it needs a deterministic resolution order:
- Project-level policy > Team-level preferences > Individual task instructions
- Safety constraints > Performance constraints > Convenience constraints
- Explicit instructions > Inferred intent > Default behavior

**Description/metadata as routing primitive**: Both Anthropic Skills and Google ADK converge on using structured description/metadata (not just names) as the primary mechanism for routing tasks to agents. The description is the contract.

### 3. Feedback Loops & Alignment Drift Detection

**Two types of drift** — often conflated but requiring different responses:

| Type | What Drifts | Cause | Detection | Response |
|------|------------|-------|-----------|----------|
| Intent Drift | Goals become stale | Environment changes, priorities shift | Gap between spec and current needs | Update the spec |
| Model/Behavioral Drift | Agent behavior changes | Model updates, prompt rot, context changes | Gap between behavior and spec | Retrain/re-prompt |

**Behavioral drift detection cycle**:
1. **Baseline** — capture expected behavior patterns from intent spec
2. **Monitor** — observe actual agent outputs and decisions
3. **Detect** — compare against baseline; flag deviations
4. **Classify** — is the deviation harmful (fix) or productive (formalize)?
5. **Correct** — update agent config or update baseline to match new reality

**The HITL wall**: Multi-step agent workflows produce traces that humans cannot realistically review in full. The response is layered oversight:
- **AI-oversees-AI** for routine decisions (automated review)
- **Human review** for novel/edge cases and high-stakes decisions
- **Statistical monitoring** for drift detection at scale

**CrowdStrike pattern**: Human analysts review only novel/edge cases that automated systems flag. This generates RLHF-style data that improves the automated system over time. The human-in-the-loop is strategic, not comprehensive.

**Irreversibility as universal escalation criterion**: Across all frameworks studied, the single most consistent trigger for escalation to human oversight is irreversibility. If an action cannot be undone, it requires higher authorization — regardless of the agent's confidence level.

**Productive drift**: Not all drift is bad. When agents discover better patterns than specified, the system should capture these as candidates for formalization into updated best practices rather than simply correcting back to the original spec.

## Key Frameworks Reference

| Framework | Source | Key Contribution | Year |
|-----------|--------|-------------------|------|
| 7-Component Intent Spec | Huryn / ProductCompass | Structured goal decomposition template | 2025 |
| 5-Pillar Intelligent Delegation | DeepMind (arXiv:2602.11865) | Dynamic assessment + adaptive execution | 2026 |
| 3-Pillar Safety Model | arXiv:2601.06223 | Transparency + Accountability + Trustworthiness | 2025 |
| 3-Level Delegation Hierarchy | Sahil Bloom | Direct → Semi → Autonomous (earned trust) | 2024 |
| 7 Levels of Delegation | Jurgen Appelo | Tell → Sell → Consult → Agree → Advise → Inquire → Delegate | 2015 |
| Principal Hierarchy | Anthropic | Hardcoded → Softcoded → Adjustable trust levels | 2024 |
| Governance-as-Infrastructure | OpenAI | Policy-as-code with guardrail tripwires | 2025 |
| 4-Tier Autonomy | Tericsoft | Full / Guarded / Proposal-First / No Autonomy | 2025 |
| Accountability by Design | McKinsey | Accountability cannot be delegated | 2025 |

## ACE Application Notes

### Existing ACE Concepts That Map to These Patterns

| Research Pattern | ACE Equivalent | Gap |
|-----------------|----------------|-----|
| Steering constraints | Workflow `.wf.md` instructions | No structured format for trade-off guidance |
| Hard constraints | Tool access controls, permission mode | Not declarative in workflow spec |
| Decision authority tiers | Permission prompts, plan mode | Not specified per-workflow or per-agent |
| Resolution hierarchy | Config cascade (project → package) | Cascade is for *settings*, not *decision authority* |
| Progressive autonomy | Manual → Plan → Auto modes | Not formalized as earned trust levels |
| Behavioral drift detection | Retrospectives (`.ace-taskflow/retros/`) | Retrospectives are manual, not systematic |
| Intent specification | Task spec `## Context` / workflow purpose | No structured signal/metric/stop-rule format |
| Description-based routing | Skill descriptions in `.claude/skills/` | Already aligned with industry convergence |

### Potential Enhancements

1. **Structured intent parameters in `.wf.md` or `.ag.md` frontmatter**: Add optional fields for `objective`, `desired_outcomes`, `health_metrics`, `constraints`, `decision_authority`, `stop_rules` — following Huryn's 7-component model.

2. **Decision authority cascade**: Extend config cascade concept beyond settings to include decision authority levels. When a workflow delegates to an agent, specify what the agent can decide autonomously vs. what requires escalation.

3. **Alignment drift detection in retrospectives**: Extend the retrospective system to include structured alignment review — did the agent's behavior match the workflow's intent? Capture deviations as either corrections (fix the agent) or improvements (update the spec).

4. **Irreversibility-based escalation**: Formalize the pattern where irreversible actions (force push, delete, publish) always require higher authorization, independent of the agent's autonomy tier.

5. **Productive drift capture**: When retrospectives identify agent behaviors that deviate from spec but produce better outcomes, provide a structured path to formalize these into updated workflow instructions.

## Sources

- [Intent Engineering Framework - ProductCompass](https://www.productcompass.pm/p/intent-engineering-framework-for-ai-agents)
- [Intent Engineering Beyond Context - Tericsoft](https://www.tericsoft.com/blogs/intent-engineering)
- [Intelligent AI Delegation - DeepMind arXiv:2602.11865](https://arxiv.org/abs/2602.11865)
- [Safe & Responsible AI Agents - arXiv:2601.06223](https://arxiv.org/html/2601.06223v1)
- [Hierarchy of Delegation - Sahil Bloom](https://www.sahilbloom.com/newsletter/the-hierarchy-of-delegation)
- [7 Levels of Delegation - Jurgen Appelo](https://medium.com/@jurgenappelo/the-7-levels-of-delegation-672ec2a48103)
- [Building Effective Agents - Anthropic](https://www.anthropic.com/research/building-effective-agents)
- [Context Engineering - Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Agentic Governance Cookbook - OpenAI](https://developers.openai.com/cookbook/examples/partners/agentic_governance_guide/agentic_governance_cookbook)
- [Multi-agent Patterns - Google ADK](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)
- [Accountability by Design - McKinsey](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-organization-blog/accountability-by-design-in-the-agentic-organization)
- [Delegation Thresholds - PhilArchive](https://philarchive.org/archive/KAHAWA-2)
- [Behavioral Drift - CIO](https://www.cio.com/article/4098673/behavioral-drift-the-hidden-risk-every-cio-must-manage.html)