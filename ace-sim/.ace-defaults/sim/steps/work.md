---
description: "ace-sim work step bundle"
bundle:
  embed_document_source: true
  sections:
    project_context:
      preset: project
    work_workflow:
      files:
        - wfi://task/work
    work_critique:
      files:
        - wfi://task/review-work
    input:
      files:
        - ./input.md
---

# Purpose

Execute the implementation plan from `<input>` and produce a concrete delivery report, then critically review it for completeness and credibility.

## Instructions

### Phase 1: Execute the Plan

Be so specific that an agent could produce exact file changes from your report. Every claim must reference real files, real code patterns, and real project conventions.

1. Read `<project_context>` for constraints.
2. Read `<input>` for the implementation plan.
3. Follow `<work_workflow>` to execute and report outcomes.
4. Do NOT shortcut — list every file changed, every test written, every decision made.

### Phase 2: Critique the Execution

Now you are the adversarial reviewer. Compare the plan and the execution item-by-item.

1. Follow `<work_critique>` to evaluate the execution report you just produced.
2. Score every dimension honestly. Do NOT give yourself a pass out of convenience.
3. If the critique reveals gaps, fix them in the report before delivering.

## Workflow

Use the embedded workflow sections:
- `<work_workflow>` — for Phase 1 (executing the plan)
- `<work_critique>` — for Phase 2 (critiquing the execution)

## Report

Return markdown only with these tags:
1. `<observations>...</observations>`
2. `<execution-report>...</execution-report>`
3. `<work-critique>...</work-critique>`
4. `<risks>...</risks>`
