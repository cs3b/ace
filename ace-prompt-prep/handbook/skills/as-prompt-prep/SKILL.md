---
name: as-prompt-prep
description: Run ace-prompt-prep and follow the printed instructions
# bundle: wfi://prompt-prep
# context: fork for codex
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-prompt-prep:*)
  - Bash(ace-bundle:*)
  - Read
last_modified: 2026-01-17
source: ace-prompt-prep
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers:
    codex:
      frontmatter:
        context: fork
        model: gpt-5.3-codex-spark
skill:
  kind: workflow
  execution:
    workflow: wfi://prompt-prep
---

read and run `ace-bundle wfi://prompt-prep`
