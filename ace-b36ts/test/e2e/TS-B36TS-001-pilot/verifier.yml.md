---
description: "E2E verifier input for ace-b36ts real-work scenario"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-notes-reorganization.verify.md
---

# E2E Verification: ace-b36ts Real-Work Scenario

You are an E2E verifier. Validate only what exists in the sandbox.

Use impact-first order:
1. Filesystem impact under `notes/archive/`
2. Reflection artifact under `results/tc/01/`
3. Debug output only as fallback
