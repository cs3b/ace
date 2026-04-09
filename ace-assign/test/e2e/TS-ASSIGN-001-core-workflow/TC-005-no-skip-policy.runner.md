# Goal 5 — No-Skip Policy

## Goal

Verify that workflow drive guidance enforces no-skip policy: check the drive workflow file for no-skip mandate, prohibition of synthetic completion, and attempt-first external action rules. Verify the skill wrapper remains thin.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/preflight.stdout` — confirm required policy source files exist in test environment
- `results/tc/05/preflight.stderr`
- `results/tc/05/preflight.exit` — `0` if prerequisites are present, non-zero otherwise
- `results/tc/05/no-skip-rule.stdout` — exact grep output for the mandatory no-skip rule
- `results/tc/05/attempt-first.stdout` — exact grep output for the attempt-first section
- `results/tc/05/evidence-rules.stdout` — exact grep output for evidence requirements

Optional capture:
- `results/tc/05/analysis.md` — summary of policy enforcement findings
- `results/tc/05/skill-thin.stdout` — exact grep output proving the skill wrapper stays thin

Run a short pre-flight check first and fail fast if prerequisites are missing.

```bash
{
  if [ ! -f "ace-assign/handbook/workflow-instructions/assign/drive.wf.md" ]; then
    echo "Missing required file: ace-assign/handbook/workflow-instructions/assign/drive.wf.md" >&2
    exit 1
  fi

  if [ ! -f ".claude/skills/as-assign-drive/SKILL.md" ]; then
    echo "Missing required file: .claude/skills/as-assign-drive/SKILL.md" >&2
    exit 1
  fi

  echo "Policy prerequisite files present"
} > results/tc/05/preflight.stdout 2> results/tc/05/preflight.stderr
echo $? > results/tc/05/preflight.exit
```

## Constraints

- Use `rg` (ripgrep) to search the workflow file at `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`.
- If preflight fails, stop here and mark Goal 5 as incomplete.
- Verify: mandatory no-skip rule text ("Planned steps are mandatory work items. Do not skip them by judgment.").
- Verify: synthetic skip prohibition and Skip Assessment removal using real grep output where possible; `analysis.md` may summarize the conclusion as support evidence.
- Verify: attempt-first external action section ("External Action Rule (Attempt-First)").
- Verify: command evidence and exact error output requirements; `evidence-rules.stdout` should capture the relevant workflow text and `analysis.md` may summarize it.
- Verify: `.claude/skills/as-assign-drive/SKILL.md` does NOT duplicate policy guardrails; `skill-thin.stdout` is optional supporting evidence only.
- All artifacts must come from real tool execution.
