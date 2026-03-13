---
name: as-git-token-remediation
description: Run token remediation and cleanup workflow for git history exposure incidents
user-invocable: true
allowed-tools:
- Bash(ace-git-secrets:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[scan-only|full]"
last_modified: 2026-03-12
source: ace-git-secrets
skill:
  kind: workflow
  execution:
    workflow: wfi://git/token-remediation
---

Load and run `mise exec -- ace-bundle wfi://git/token-remediation` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
