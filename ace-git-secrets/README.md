# ace-git-secrets

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

<p align="center">
[![Gem Version](https://img.shields.io/gem/v/ace-git-secrets.svg)](https://rubygems.org/gems/ace-git-secrets)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
</p>

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
<p align="center">
  Scan, revoke, and remove leaked credentials from Git history before they cause damage.
</p>


![ace-git-secrets demo](docs/demo/ace-git-secrets-getting-started.gif)

`ace-git-secrets` gives developers and coding agents a focused remediation loop for leaked credentials: detect exposure with gitleaks-backed scanning, revoke impacted tokens by provider, and safely clean repository history with dry-run-first safeguards.

## How It Works

1. Scan commits with gitleaks-backed detection and capture a reusable saved report for remediation workflows.
2. Revoke high-confidence findings from the saved scan report using provider-aware revocation flows.
3. Preview history rewrites with `--dry-run`, execute cleanup when ready, then gate releases with `check-release`.

## Use Cases

**Detect leaked credentials in Git history** - run [`ace-git-secrets`](docs/usage.md) to scan commits and capture a reusable JSON report for remediation. Use `/as-git-security-audit` for the full agent-driven audit workflow.

**Revoke exposed tokens by provider** - use `/as-git-token-remediation` to revoke high-confidence findings from the saved scan report for GitHub PATs and other supported token classes before any history rewrites.

**Clean history safely with dry-run-first safeguards** - preview rewrite changes with [`ace-git-secrets rewrite-history --dry-run`](docs/usage.md), execute cleanup when ready, then block release pipelines if secrets are still present.

**Coordinate with git workflow tools** - pair with [ace-bundle](../ace-bundle) for loading remediation workflows, [ace-git](../ace-git) for repository context before cleanup, and [ace-git-commit](../ace-git-commit) for follow-up commits after remediation work.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
