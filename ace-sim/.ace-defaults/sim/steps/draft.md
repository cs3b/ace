---
description: "ace-sim draft step bundle"
bundle:
  embed_document_source: true
  sections:
    project_context:
      preset: project
    draft_workflow:
      files:
        - wfi://task/draft
    review_workflow:
      files:
        - wfi://task/review
    input:
      files:
        - ./input.md
---

# Purpose

Prepare a high-quality draft task from `<input>` using the workflow context and then self-review it.

## Instructions

1. Read `<project_context>` for repository constraints and conventions.
2. Read `<input>` as the source request.
3. Use `<draft_workflow>` to draft the task content.
4. Use `<review_workflow>` to review the drafted task quality.

## Workflow

Use the embedded workflow sections directly:
- `<draft_workflow>`
- `<review_workflow>`

## Report

Return markdown only with these tags:
1. `<observations>...</observations>`
2. `<task>...</task>`
3. `<task-review>...</task-review>`
