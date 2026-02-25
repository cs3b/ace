---
description: "E2E runner input for ace-llm query scenarios"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-basic-query.runner.md
    - ./TC-002-model-selection.runner.md
---

# E2E Test Runner: ace-llm Query Scenarios

These goals require configured provider credentials in sandbox.
Capture stdout/stderr/exit for each command.
