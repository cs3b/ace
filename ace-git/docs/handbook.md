---
doc-type: user
title: ace-git Handbook Catalog
purpose: Catalog of ace-git workflows, skills, guides, and templates
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-git Handbook Catalog

Reference for package-owned handbook resources in `ace-git/handbook/`.

## Skills

| Skill | What it does |
|-------|--------------|
| `as-git-rebase` | Guide changelog-preserving rebases |
| `as-git-reorganize-commits` | Rework commit history into reviewable logical groups |
| `as-git-pr-create` | Create an attempt-bound draft on the selected forge |
| `as-git-pr-update` | Update the exact attempt-bound PR and consume current evidence |
| `as-github-release-publish` | Publish a GitHub release from the ACE workflow |

## Workflow Instructions

| Protocol Path | Purpose | Invoked by |
|--------------|---------|------------|
| `wfi://git/rebase` | Rebase a branch while preserving changelog/version files | `as-git-rebase` |
| `wfi://git/reorganize-commits` | Consolidate or regroup commit history before review | `as-git-reorganize-commits` |
| `wfi://git/pr/create` | Create or reconcile the exact attempt-bound draft | `as-git-pr-create` |
| `wfi://git/pr/update` | Update the recorded PR and retain delivery identity | `as-git-pr-update` |
| `wfi://github/release-publish` | Publish a GitHub release | `as-github-release-publish` |

## Guides

- `handbook/guides/version-control-system-git.g.md`
- `handbook/guides/version-control/ruby.md`
- `handbook/guides/version-control/rust.md`
- `handbook/guides/version-control/typescript.md`

## Templates

- PR templates: `handbook/templates/pr/default.template.md`, `handbook/templates/pr/feature.template.md`, `handbook/templates/pr/bugfix.template.md`
- Commit templates: `handbook/templates/commit/squash.template.md`

## Related Docs

- [Getting Started](getting-started.md)
- [CLI Usage Reference](usage.md)
- Load workflows directly with `ace-bundle`, for example `ace-bundle wfi://git/rebase`
