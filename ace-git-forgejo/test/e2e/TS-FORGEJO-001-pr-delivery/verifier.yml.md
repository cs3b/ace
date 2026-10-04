---
description: "E2E verifier input for Forgejo PR delivery lifecycle"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-create.verify.md
    - ./TC-002-ready.verify.md
    - ./TC-003-merge.verify.md
    - ./TC-004-response-loss.verify.md
    - ./TC-005-teardown.verify.md
---

# E2E Verification: Forgejo PR delivery lifecycle

You are an E2E verifier. Inspect artifacts and render PASS/FAIL verdicts.

## Rules

- Use impact-first verification order.

1. sandbox/project state impact
2. explicit artifacts under `results/tc/{NN}/`
3. debug captures (`stdout`, `stderr`, `.exit`) only as fallback

- Evaluate each goal independently based only on artifacts in `results/`
- Cite concrete evidence (filenames + key values)
- Refusal goals PASS only when the recorded error category matches the
  expected one AND the recorded `.exit` is nonzero.
- Follow output format exactly

## Output Format

For each goal output:

### Goal N - `<title>`

- **Verdict**: `PASS` | `FAIL`
- **Category**: `test-spec-error | tool-bug | runner-error | infrastructure-error` (when FAIL)
- **Evidence**: `<specific file/content citations>`

Final line: **Results: X/N passed**
