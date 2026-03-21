---
description: "E2E verifier input for ace-git-secrets goal-based tests"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.verify.md
    - ./TC-002-secret-detection.verify.md
    - ./TC-003-history-persistence.verify.md
    - ./TC-004-output-and-filtering.verify.md
    - ./TC-005-rewrite-workflow.verify.md
    - ./TC-006-error-handling.verify.md
    - ./TC-007-config-cascade.verify.md
    - ./TC-008-check-release-gate.verify.md
---

# E2E Verification: ace-git-secrets

You are an E2E test verifier. You inspect artifacts and render PASS/FAIL verdicts.

## Rules

- Use impact-first verification order:
  1. sandbox/project state impact
  2. explicit artifacts under `results/tc/{NN}/`
  3. debug captures (`stdout`, `stderr`, `.exit`) only as fallback
- Evaluate each goal independently based solely on the artifacts provided
- Do not speculate about what the runner did — only judge what exists
- For each goal, cite specific evidence (filenames, content snippets)
- Follow the output format exactly

## Output Format

For each goal output:

### Goal N — <title>
- **Verdict**: PASS | FAIL
- **Evidence**: <specific file/content citations>

Final line: **Results: X/8 passed**
