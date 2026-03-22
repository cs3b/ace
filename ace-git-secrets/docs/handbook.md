---
doc-type: user
title: ace-git-secrets Handbook Catalog
purpose: Catalog of ace-git-secrets workflows, skills, guides, and agents
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-git-secrets Handbook Catalog

Reference for package-owned handbook resources in `ace-git-secrets/handbook/`.

## Skills

| Skill | What it does |
|-------|--------------|
| `as-git-security-audit` | Run the package security-audit workflow to detect leaked tokens and report remediation guidance |
| `as-git-token-remediation` | Run the package remediation workflow to scan, revoke, and clean leaked credentials |

## Workflow Instructions

| Protocol Path | Purpose | Invoked by |
|---------------|---------|------------|
| `wfi://git/security-audit` | Guided detection and reporting workflow for leaked credentials | `as-git-security-audit` |
| `wfi://git/token-remediation` | Guided remediation workflow covering scan, revoke, rewrite, and follow-up actions | `as-git-token-remediation` |

## Agents

- `handbook/agents/security-audit.ag.md` for focused security-audit execution

## Guides

- `handbook/guides/security.g.md` for package-level security guidance
- `handbook/guides/security/ruby.md` for Ruby-specific security notes
- `handbook/guides/security/typescript.md` for TypeScript-specific security notes
- `handbook/guides/security/rust.md` for Rust-specific security notes

## Related Docs

- [Getting Started](getting-started.md)
- [CLI Usage Reference](usage.md)
- Load workflows directly with `ace-bundle`, for example `ace-bundle wfi://git/token-remediation`
