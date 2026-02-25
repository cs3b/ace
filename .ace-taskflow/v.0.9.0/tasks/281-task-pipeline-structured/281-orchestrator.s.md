---
id: v.0.9.0+task.281
status: draft
priority: medium
estimate: TBD
---

# Structured Intent Flow Through the ACE Pipeline

## Overview

The ACE pipeline currently loses work intention at each handoff. Ideas are raw text enhanced into generic Problem/Solution/Benefits sections. Task drafts fill a behavior-first template but don't inherit the idea's intent — they restate from scratch. Subtask agents get project context and their own spec but never see the parent task's objectives or vision.

This orchestrator introduces the "3-Question Delegation Brief" (from the intent engineering research) as a structured intent format that flows through the entire pipeline: **idea → task → subtask**.

The 3 questions:
1. **What I hope to accomplish** — the impact, the *why*
2. **What "complete" looks like** — concrete end state
3. **Specific success criteria** — verifiable pass/fail checks

Each subtask below addresses one handoff point where intent is currently lost.

### Packages Affected
- `ace-taskflow` (idea enhancement, task draft workflow, work-subtasks workflow, review + plan workflows)
- `ace-assign` (planning phase instruction in assignment executor)
- `ace-review` (review session context loading for spec inclusion)

## Subtasks

- **01**: Idea Capture with 3-Question Delegation Brief — replace the LLM enhancement output format with the 3-question structure
- **02**: Idea-to-Task Intent Inheritance — update the task draft workflow to map idea intent into task sections
- **03**: Parent Task as Subtask Context — update the work-subtasks delegation prompt to include parent task as context
- **04**: Spec-Aware Planning at the Spec-to-Agent Handoff — teach planning agents to plan against the behavioral spec structure; add operating-modes, degenerate-inputs, and per-path-variations checklists to review
- **05**: Review Agents Get Spec Context — include behavioral spec in review session context so reviewers validate code against spec decisions

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| 3-Question Delegation Brief as idea output | 281.01 | — | NEW |
| Italicized gap markers for incomplete intent | 281.01 | — | NEW |
| Intent mapping guidance in draft workflow | 281.02 | — | NEW |
| Graceful fallback for pre-3Q ideas | 281.02 | — | NEW |
| Parent task reference in subtask delegation | 281.03 | — | NEW |
| "Operating Modes Covered" review checklist item | 281.04 | — | NEW |
| "Degenerate Inputs Covered" review checklist item | 281.04 | — | NEW |
| "Per-Path Variations Covered" review checklist item | 281.04 | — | NEW |
| "Behavioral Gaps" section in planning output | 281.04 | — | NEW |
| Per-path enumeration in planning workflow | 281.04 | — | NEW |
| Behavioral spec as review session context | 281.05 | — | NEW |

## References

- `.ace-taskflow/v.0.9.0/ideas/_archive/8pnwx0-intent-engineering/intent-engineering-layer-3-delegation-frameworks.idea.s.md`
- `.ace-taskflow/v.0.9.0/ideas/_archive/8pnwx0-intent-engineering/intent-based-agentic-coding-engineering.md`
