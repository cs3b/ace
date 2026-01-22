---
name: ace:invalid-tools
description: Skill with invalid tools
# bundle: project
# agent: general-purpose
user-invocable: true
allowed-tools:
  - InvalidTool
  - Bash(unknown-prefix:*)
  - Read
source: ace-test
---

This skill has invalid tool entries.
