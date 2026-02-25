---
description: "E2E runner input for ace-tmux management"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-list-presets.runner.md
    - ./TC-002-start-session.runner.md
---

# E2E Test Runner: ace-tmux Management

Run goals sequentially. Goal 1 discovers presets; Goal 2 uses discovered preset.
