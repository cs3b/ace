---
description: Current release context
params:
  output: cache
  embed_itself: true
  max_size: 5242880
  timeout: 20
context:
  files:
    - dev-taskflow/current/*/roadmap.md
    - dev-taskflow/current/*/tasks/*.md
  exclude:
    - "**/done/**"
---

# Release Context

This preset focuses on the current release including active tasks and roadmap.