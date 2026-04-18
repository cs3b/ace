---
description: "E2E runner input for ace-test-runner-e2e real execution coverage"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-real-package-run.runner.md
    - ./TC-002-verifier-output.runner.md
    - ./TC-003-shell-helper-surface.runner.md
---

# E2E Test Runner: ace-test-runner-e2e Real Run + Verify + Shell Helper

Tool under test: ace-test-e2e, ace-test-e2e-sh
Required tools: ace-test-e2e, ace-test-e2e-sh, git
Workspace root: (current directory)

Execute each goal in order.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners.
- Execute each goal in order (1 through 3).
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Save all artifacts to `results/tc/{NN}/` directories as specified.
- Do not assign PASS/FAIL verdicts in runner output.
- Do not fabricate output; all artifacts must come from real command execution.
- For each command capture stdout, stderr, and exit code.
- If a goal fails, continue to the next goal.
