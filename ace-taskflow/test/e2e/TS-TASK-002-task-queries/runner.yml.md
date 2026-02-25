---
description: "E2E runner input for ace-task query workflows"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-show-task-details.runner.md
    - ./TC-002-filter-by-status.runner.md
    - ./TC-003-taskflow-status.runner.md
---

# E2E Test Runner: ace-task Query Workflows

Execute each goal in sequence and preserve raw command captures.
