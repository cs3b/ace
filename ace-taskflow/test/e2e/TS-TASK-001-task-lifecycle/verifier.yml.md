---
description: "E2E verifier input for ace-task task lifecycle"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-create-task.verify.md
    - ./TC-002-start-task.verify.md
    - ./TC-003-complete-task.verify.md
    - ./TC-004-list-tasks.verify.md
---

# E2E Verification: ace-task Task Lifecycle

You are an E2E test verifier. Inspect artifacts and render PASS/FAIL verdicts.

## Rules

- Use impact-first verification order:
  1. sandbox/project state impact
  2. explicit artifacts under `results/tc/{NN}/`
  3. debug captures (`stdout`, `stderr`, `.exit`) only as fallback
- Evaluate each goal independently based only on artifacts in `results/`
- Do not infer missing evidence
- For each failed goal, include a category:
  test-spec-error | tool-bug | runner-error | infrastructure-error
- Follow the output format exactly

## Output Format

### Goal N — <title>
- **Verdict**: PASS | FAIL
- **Category**: <one of the categories above when FAIL>
- **Evidence**: <specific file/content citations>

Final line: **Results: X/4 passed**
