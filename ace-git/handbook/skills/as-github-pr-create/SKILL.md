---
name: as-github-pr-create
description: Create GitHub pull request with generated description and summary
# bundle: wfi://github/pr/create
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(gh:*)
  - Read
argument-hint: pr-type
last_modified: 2026-01-10
source: ace-git
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
    workflow: wfi://github/pr/create
---

read and run `ace-bundle wfi://github/pr/create`
