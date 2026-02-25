---
description: "E2E runner input for ace-idea lifecycle"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-create-idea.runner.md
    - ./TC-002-list-ideas.runner.md
    - ./TC-003-park-idea.runner.md
---

# E2E Test Runner: ace-idea Lifecycle

Execute goals in order and preserve raw command artifacts in `results/tc/{NN}/`.
