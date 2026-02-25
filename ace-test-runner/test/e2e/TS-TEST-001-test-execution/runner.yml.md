---
description: "E2E runner input for ace-test core execution"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-run-package-tests.runner.md
    - ./TC-002-run-specific-file.runner.md
    - ./TC-003-run-test-group.runner.md
---

# E2E Test Runner: ace-test Core Execution

Execute each goal in order and capture stdout/stderr/exit for every command.
