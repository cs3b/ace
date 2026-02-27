---
description: "ace-sim plan step bundle"
bundle:
  embed_document_source: true
  sections:
    project_context:
      preset: project
    plan_workflow:
      files:
        - wfi://task/plan
    plan_critique:
      files:
        - wfi://task/review-plan
    input:
      files:
        - ./input.md
---

# Purpose

Create an implementation plan from the previous step output using repository context, then critically review it for completeness and executability.

## Instructions

### Phase 1: Build the Plan

Exhaust every detail. Do NOT shortcut — a vague plan produces vague execution.

1. Read `<project_context>` first.
2. Read `<input>` as the planning source.
3. Follow `<plan_workflow>` to produce a decision-complete implementation plan.
4. Be so specific that an agent could execute the plan without asking a single clarifying question.

### Phase 2: Critique the Plan

Now you are the adversarial reviewer. Forget that you wrote this plan — tear it apart.

1. Follow `<plan_critique>` to evaluate the plan you just produced.
2. Score every dimension honestly. Do NOT give yourself a pass out of convenience.
3. If the critique reveals gaps, fix them in the plan before reporting.

## Workflow

Use the embedded workflow sections:
- `<plan_workflow>` — for Phase 1 (building the plan)
- `<plan_critique>` — for Phase 2 (critiquing the plan)

## Report

Return markdown only with these tags:
1. `<observations>...</observations>`
2. `<implementation-plan>...</implementation-plan>`
3. `<plan-critique>...</plan-critique>`
4. `<open-questions>...</open-questions>`
