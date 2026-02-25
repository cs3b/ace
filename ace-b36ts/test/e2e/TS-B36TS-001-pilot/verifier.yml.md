---
description: "E2E verifier input for ace-b36ts goal-based pilot"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.verify.md
    - ./TC-002-encode-today.verify.md
    - ./TC-003-decode-token.verify.md
    - ./TC-004-error-behavior.verify.md
    - ./TC-005-output-routing.verify.md
    - ./TC-006-structured-output.verify.md
    - ./TC-007-roundtrip-pipeline.verify.md
    - ./TC-008-batch-sort.verify.md
---

# E2E Verification: ace-b36ts Goal-Based Pilot

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
