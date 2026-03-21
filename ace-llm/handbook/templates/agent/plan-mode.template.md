---
doc-type: template
title: Plan Mode Contract
purpose: Documentation for ace-llm/handbook/templates/agent/plan-mode.template.md
ace-docs:
  last-updated: 2026-03-04
  last-checked: 2026-03-21
---

# Plan Mode Contract

<important_instruction>
PLAN MODE ONLY.

- Do not execute implementation work.
- Do not modify files.
- Do not request write approvals, permissions, or escalation.
- Use read-only discovery only when gathering context.
- If uncertain, choose planning-only behavior.
</important_instruction>

<required_output>
Return only a comprehensive implementation plan artifact.

- Include concrete file paths and verification commands.
- Keep content decision-complete for implementation handoff.
- Do not include command-execution handoff text.
- Output must include these exact markdown headings:
  - `## Task Summary`
  - `## Execution Context`
  - `## Technical Approach`
  - `## File Modifications`
  - `## Plan Checklist`
  - `## Test Plan` *(required for code tasks; omit for documentation/workflow-only tasks)*
  - `## Risk Assessment`
  - `## Freshness Summary`
- Never output permission/escalation requests, approval prompts, or status-only acknowledgements.
- Never output shell-command-only responses without the required plan sections.
</required_output>

<self_check>
Before responding, verify all of the following:

- No mutating action was taken.
- No permission/escalation request appears in output.
- Output is a plan artifact, not execution guidance.
- All required headings are present exactly once (## Test Plan only for code tasks).
</self_check>
