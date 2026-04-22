# Goal 8 — Setup Failure Guidance

## Goal

Validate that LLM setup failures provide actionable diagnostics and a
deterministic fallback commit command.

## Workspace

Save all output to `results/tc/08/`. Capture:
- `git status --short` before command execution
- `git diff --name-only --cached` before command execution
- Command stdout, stderr, and exit code for the failing LLM-backed invocation
- `git status --short` after command execution

## Constraints

- Stage at least one setup-like change (for example docs or config file edits).
- Stage setup-like changes via explicit paths only (`git add <path>`).
- Never use `git add .` or `git add -A` in this goal.
- Ensure generated `results/` artifacts are not staged before invoking the
  failing command (for example, `git restore --staged results || true`).
- Invoke an LLM-backed commit path expected to fail (use an intentionally invalid
  model override) with intention text:
  - `ace-git-commit --model codex:__invalid_setup_probe__ -i "set up ace tooling"`
- Do not use `-m`; this goal must exercise the LLM failure path.
- Preserve the working tree for subsequent inspection.
- All artifacts must come from real tool execution, not fabricated.
