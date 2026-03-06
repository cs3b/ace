# Goal 5 — No-Skip Policy

## Goal

Verify that workflow drive guidance enforces no-skip policy: check the drive workflow file for no-skip mandate, prohibition of synthetic completion, and attempt-first external action rules. Verify the skill wrapper remains thin.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/no-skip-rule.stdout` — search for mandatory no-skip rule
- `results/tc/05/synthetic-skip.stdout` — search for synthetic skip prohibition
- `results/tc/05/skip-assessment.stdout` — verify old skip assessment removed
- `results/tc/05/attempt-first.stdout` — search for attempt-first section
- `results/tc/05/evidence-rules.stdout` — search for command/error evidence requirements
- `results/tc/05/skill-thin.stdout` — verify skill does not duplicate policy
- `results/tc/05/analysis.md` — summary of policy enforcement findings

## Constraints

- Use `rg` (ripgrep) to search the workflow file at `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`.
- Verify: mandatory no-skip rule text ("Planned phases are mandatory work items. Do not skip them by judgment.").
- Verify: synthetic skip prohibition ("Never use report text to \"skip\" or synthesize completion for planned phases.").
- Verify: old "Skip Assessment" section is removed (should NOT exist).
- Verify: attempt-first external action section ("External Action Rule (Attempt-First)").
- Verify: command evidence and exact error output requirements.
- Verify: `.claude/skills/as-assign-drive/SKILL.md` does NOT duplicate policy guardrails.
- All artifacts must come from real tool execution.
