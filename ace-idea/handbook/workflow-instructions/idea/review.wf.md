---
doc-type: workflow
title: Review Idea Workflow Instruction
purpose: Documentation for ace-idea/handbook/workflow-instructions/idea/review.wf.md
ace-docs:
  last-updated: 2026-03-02
  last-checked: 2026-03-21
---

# Review Idea Workflow Instruction

## Goal

Critically evaluate an idea for clarity, impact, scope boundaries, and execution readiness. This workflow acts as an adversarial quality gate before converting ideas into implementation tasks.

## When to Use

- Reviewing raw idea notes before drafting a task
- Final synthesis of simulation runs focused on idea quality
- Evaluating whether an idea is ready for prioritization or needs refinement

## Evaluation Dimensions

Evaluate against these six dimensions. Score each as **PASS**, **WEAK**, or **FAIL**.

### 1. Problem Clarity
- Is the problem concrete and specific?
- Is the current pain/risk explicitly described?

### 2. Outcome Clarity
- Is the desired end state measurable?
- Are success criteria observable and testable?

### 3. Scope Boundaries
- Are in-scope and out-of-scope boundaries explicit?
- Are assumptions/defaults documented?

### 4. Feasibility Signals
- Are technical constraints, dependencies, and risks acknowledged?
- Is the effort level realistic for the expected value?

### 5. Decision Gaps
- Are key unknowns listed with concrete questions?
- Are blocking decisions separated from nice-to-have details?

### 6. Next-Step Readiness
- Is there a clear immediate next action (draft task, research, reject, etc.)?
- Could another agent continue work without guessing?

## Output Format

Return markdown in this structure:

```markdown
## Idea Critique

**Verdict:** READY TO DRAFT | NEEDS REFINEMENT | INSUFFICIENT

### Dimension Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| Problem Clarity | PASS/WEAK/FAIL | One-line finding |
| Outcome Clarity | PASS/WEAK/FAIL | One-line finding |
| Scope Boundaries | PASS/WEAK/FAIL | One-line finding |
| Feasibility Signals | PASS/WEAK/FAIL | One-line finding |
| Decision Gaps | PASS/WEAK/FAIL | One-line finding |
| Next-Step Readiness | PASS/WEAK/FAIL | One-line finding |

### What to Update
- [Concrete updates to make the idea implementation-ready]

### What Needs Precision
- [Blocking questions and missing specifics]

### Prioritized Next Actions
1. [Highest impact next action]
2. [Second action]
3. [Third action]
```

## Verdict Criteria

- **READY TO DRAFT:** No FAIL scores, at most one WEAK score
- **NEEDS REFINEMENT:** No more than two FAIL scores, or three+ WEAK scores
- **INSUFFICIENT:** Three or more FAIL scores

## Review Principles

- Be adversarial and specific.
- Demand explicit decisions where ambiguity blocks execution.
- Prefer concrete, testable suggestions over generic advice.
- Avoid introducing implementation details beyond the idea stage unless required for feasibility.