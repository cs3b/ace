---
name: as-git-security-audit
description: Perform security audits to detect leaked authentication tokens
user-invocable: true
allowed-tools:
- Bash(ace-git-secrets:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[scan|check-release] [--since=SINCE] [--confidence=LEVEL] [options]"
last_modified: 2026-01-09
source: ace-git-secrets
skill:
  kind: workflow
  execution:
    workflow: wfi://git/security-audit
---

read and run `ace-bundle wfi://git/security-audit`
