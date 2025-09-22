---
description: Current release and task tracking context
params:
  output: cache
  embed_itself: true
  max_size: 5242880
  timeout: 20
context:
  files:
    - dev-taskflow/current/*/roadmap.md
    - dev-taskflow/current/*/tasks/*.md
    - CHANGELOG.md
  commands:
    - task-manager status
    - task-manager recent --limit 5
    - release-manager current
  exclude:
    - "**/done/**"
    - "**/archive/**"
---

# Release Context

This preset focuses on the current release, including active tasks, roadmap, and recent activity.

Ideal for understanding what's currently being worked on and the state of the current release cycle.

## Usage

```bash
ace-context release
ace-context release --output ./release-status.md
```

## Note

This example assumes you have task-manager and release-manager tools installed. Adjust the commands section based on your project's tooling.