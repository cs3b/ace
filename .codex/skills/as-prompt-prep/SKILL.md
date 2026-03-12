---
name: as-prompt-prep
description: Run ace-prompt-prep and follow the printed instructions
user-invocable: true
allowed-tools:
- Bash(ace-prompt-prep:*)
- Bash(ace-bundle:*)
- Read
last_modified: 2026-01-17
source: ace-prompt-prep
skill:
  kind: workflow
  execution:
    workflow: wfi://prompt-prep
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://prompt-prep`
