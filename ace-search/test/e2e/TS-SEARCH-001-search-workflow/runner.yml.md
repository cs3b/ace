---
description: "E2E runner input for ace-search workflow"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-content-search.runner.md
    - ./TC-002-file-search.runner.md
    - ./TC-003-count-mode.runner.md
---

# E2E Test Runner: ace-search Workflow

Run all goals in order and save artifacts in `results/tc/{NN}/`.
