---
name: as-git-token-remediation
description: Run token remediation and cleanup workflow for git history exposure incidents
# bundle: wfi://git/token-remediation
# context: no-fork
# agent: Bash
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

read and run `ace-bundle wfi://git/token-remediation`
