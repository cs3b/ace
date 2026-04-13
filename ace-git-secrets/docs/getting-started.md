---
doc-type: user
title: Getting Started with ace-git-secrets
purpose: Tutorial for first-run ace-git-secrets workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-git-secrets

Use `ace-git-secrets` when you need to find leaked credentials, revoke them quickly, and remove them from Git history.

## Installation

```bash
gem install ace-git-secrets
```

Install the required scanner and optional history-rewrite tool:

```bash
# macOS
brew install gitleaks              # required scanner
brew install git-filter-repo       # optional, for history rewriting

# Arch Linux
pacman -S gitleaks                 # required scanner
pacman -S git-filter-repo          # optional, for history rewriting
```

Requires Ruby 3.2+ and `gitleaks` on your `PATH`.

## 1. Run your first scan

Start with the default scan:

```bash
ace-git-secrets scan
```

The command prints a summary to stdout and saves a reusable JSON report under `.ace-local/git-secrets/sessions/`. Keep
the exact path printed by the command because both `revoke` and `rewrite-history` can reuse it.

## 2. Read the report

The saved JSON report includes token type, confidence, commit, file path, and raw token values needed for follow-up
actions. When you want a shareable report for humans, run:

```bash
ace-git-secrets scan --report-format markdown
```

Use `--confidence high` when you want a narrower review, or `--since "30 days ago"` to limit large-repository scans.

## 3. Revoke exposed tokens

After a scan, revoke from the saved JSON report so you operate on the exact findings you reviewed:

```bash
ace-git-secrets revoke --scan-file .ace-local/git-secrets/sessions/abc123-report.json
```

Use `--service github` to narrow revocation to one provider, or `--token` when you already know the exact credential to
invalidate.

## 4. Preview history cleanup

Always dry-run history rewriting first:

```bash
ace-git-secrets rewrite-history --dry-run --scan-file .ace-local/git-secrets/sessions/abc123-report.json
```

When the preview looks correct, run the real rewrite with the same scan file:

```bash
ace-git-secrets rewrite-history --scan-file .ace-local/git-secrets/sessions/abc123-report.json
```

`rewrite-history` creates backups by default and prompts before destructive changes unless you pass `--force`.

## 5. Add a CI/CD gate

Use the release gate to block publishes when secrets are still present:

```bash
ace-git-secrets check-release --strict
```

This is the simplest command to drop into release workflows or pre-publish checks.

## Common Commands

| Goal | Command |
|------|---------|
| Scan the full repository history | `ace-git-secrets scan` |
| Save a Markdown report | `ace-git-secrets scan --report-format markdown` |
| Scan recent history only | `ace-git-secrets scan --since "30 days ago"` |
| Revoke tokens from a saved report | `ace-git-secrets revoke --scan-file .ace-local/git-secrets/sessions/abc123-report.json` |
| Preview cleanup | `ace-git-secrets rewrite-history --dry-run --scan-file .ace-local/git-secrets/sessions/abc123-report.json` |
| Block a release on findings | `ace-git-secrets check-release --strict` |

## Package Testing

When validating package changes:

- `ace-test ace-git-secrets` runs deterministic `test/fast` coverage.
- `ace-test ace-git-secrets feat` runs deterministic `test/feat` coverage when present.
- `ace-test-e2e ace-git-secrets` runs retained workflow scenarios in `test/e2e`.

## What to try next

- Add whitelist rules in `.ace/git-secrets/config.yml` for known documentation examples or test fixtures
- Load `ace-bundle wfi://git/security-audit` for a guided audit workflow
- Load `ace-bundle wfi://git/token-remediation` for full scan, revoke, and rewrite guidance
- Read [CLI Usage Reference](usage.md) for every option and output mode
