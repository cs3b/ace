---
description: "E2E verifier input for ace-docs discover/validate/status/update operations"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-discover-docs.verify.md
    - ./TC-002-validate-docs.verify.md
    - ./TC-003-status-check.verify.md
    - ./TC-004-update-docs.verify.md
---

# E2E Verification: ace-docs Operations

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

For each goal output:

### Goal N — <title>
- **Verdict**: PASS | FAIL
- **Category**: <one of the categories above when FAIL>
- **Evidence**: <specific file/content citations>

Final line: **Results: X/4 passed**
