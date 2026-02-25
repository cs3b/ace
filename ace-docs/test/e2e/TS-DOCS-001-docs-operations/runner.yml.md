---
description: "E2E runner input for ace-docs operations"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-discover-docs.runner.md
    - ./TC-002-validate-docs.runner.md
    - ./TC-003-status-check.runner.md
---

# E2E Test Runner: ace-docs Operations

Run all goals sequentially and preserve command capture artifacts.
