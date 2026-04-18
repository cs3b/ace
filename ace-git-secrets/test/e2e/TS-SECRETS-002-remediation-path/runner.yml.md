---
description: "E2E runner input for ace-git-secrets saved-report remediation path"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-remediation-path.runner.md
---

# E2E Test Runner: ace-git-secrets remediation path

Tool under test: ace-git-secrets
Required tools: ace-git-secrets, git, gitleaks
Workspace root: (current directory)

Execute goals in listed order.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners.
- Save all artifacts to `results/tc/{NN}/` directories as specified.
- Do not assign PASS/FAIL verdicts in runner output.
- Do not fabricate output — all artifacts must come from real tool execution.
- If a goal fails, note the failure and continue collecting required artifacts.
