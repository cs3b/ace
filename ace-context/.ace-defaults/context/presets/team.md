---
description: Team context with extended timeout for CI environments
context:
  presets:
    - development
  params:
    timeout: 120
    output: cache
  files:
    - docs/decisions.md
  commands:
    - date
    - pwd
---

# Team Context

This preset extends development context with team-specific configuration including longer timeouts for CI environments and decision documentation.
