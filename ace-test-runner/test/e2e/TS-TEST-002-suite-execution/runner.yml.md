---
description: "E2E runner input for ace-test-suite behavior"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-run-full-suite.runner.md
    - ./TC-002-verify-failure-propagation.runner.md
---

# E2E Test Runner: ace-test-suite Behavior

Goal 1 validates normal suite execution; Goal 2 intentionally introduces a
failing test file in sandbox and verifies non-zero propagation.
