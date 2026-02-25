---
description: "E2E runner input for ace-git operations"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-git-status.runner.md
    - ./TC-002-git-diff.runner.md
    - ./TC-003-branch-info.runner.md
    - ./TC-004-pr-summary.runner.md
---

# E2E Test Runner: ace-git Operations

Execute each goal in order and preserve raw command captures.
