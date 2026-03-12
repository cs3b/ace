---
name: ace-test-skill
description: A valid test skill for linting
# bundle: project
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Edit
source: ace-test
skill:
  kind: workflow
  execution:
    workflow: wfi://test/workflow
---

This is the skill body content.
