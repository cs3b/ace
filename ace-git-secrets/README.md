# ace-git-secrets

Scan, revoke, and remove leaked credentials from Git history before they cause damage.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-git-secrets demo](docs/demo/ace-git-secrets-getting-started.gif)

`ace-git-secrets` gives developers and coding agents a focused remediation loop for leaked credentials:
detect exposure, revoke impacted tokens, and safely clean repository history with dry-run-first safeguards.

## Use Cases

**Detect leaked credentials in Git history** - scan commits with gitleaks-backed detection and capture a reusable
saved report for remediation workflows.

**Revoke exposed tokens by provider** - revoke high-confidence findings from the saved scan report before any history
rewrites.

**Clean history safely and gate releases** - preview rewrite changes with `rewrite-history --dry-run`, execute
cleanup when ready, then block release pipelines if secrets are still present.

## Works With

- **[ace-bundle](../ace-bundle)** for loading remediation workflows and handbook context.
- **[ace-git](../ace-git)** for repository context before cleanup and release checks.
- **[ace-git-commit](../ace-git-commit)** for follow-up commits after remediation work.

## Features

- Gitleaks-powered scan reports with reusable JSON output for remediation and Markdown output for human review.
- Provider-aware revocation flows for GitHub PATs and other supported token classes.
- Dry-run-first history cleanup with `rewrite-history --dry-run` before destructive rewrites.
- `check-release` gating for CI/CD and release pipelines.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-git-secrets --help`

## Agent Skills

Package-owned canonical skills:

- `as-git-security-audit`
- `as-git-token-remediation`

## Part of ACE

`ace-git-secrets` is part of [ACE](../README.md) (Agentic Coding Environment).
