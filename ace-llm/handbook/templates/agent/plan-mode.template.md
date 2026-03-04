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
- All required headings are present exactly once.
</self_check>
