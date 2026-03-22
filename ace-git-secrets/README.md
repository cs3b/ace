---
doc-type: user
title: ace-git-secrets
purpose: Landing page for ace-git-secrets
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-git-secrets

Detect, revoke, and remove leaked tokens from Git history before they cause damage.

![ace-git-secrets demo](docs/demo/ace-git-secrets-getting-started.gif)

## Why

`ace-git-secrets` gives you a focused response loop when credentials leak into commits:

- scan Git history with gitleaks-backed detection for 100+ token types
- revoke exposed GitHub, Anthropic, OpenAI, AWS, and other supported credentials
- rewrite history with a dry-run-first cleanup workflow
- block releases in CI/CD when secrets are still present

## Works With

- `ace-bundle` for loading the package remediation workflows
- `ace-git` for repository context before cleanup or release checks
- `ace-git-commit` for follow-up commits after remediation work

## Agent Skills

Package-owned canonical skills:

- `as-git-security-audit`
- `as-git-token-remediation`

## Features

- gitleaks-powered scan reports with reusable JSON output for remediation and Markdown output for human review
- provider-aware revocation flows for GitHub PATs and other supported token classes
- `rewrite-history --dry-run` before destructive history cleanup
- `check-release` for CI/CD and release gating

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Catalog](docs/handbook.md)
- Command help: `ace-git-secrets --help`

## Part of ACE

`ace-git-secrets` is part of [ACE](../README.md), a CLI-first toolkit for developers and agents.
