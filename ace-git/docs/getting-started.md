---
doc-type: user
title: ace-git Getting Started
purpose: Tutorial for ace-git first-run workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-git

This walkthrough shows the core `ace-git` loop: inspect repository context, review a diff, and jump into a
guided workflow.

## Prerequisites

- Ruby 3.2+
- Git 2.23+
- `ace-git` installed
- Optional: GitHub CLI (`gh`) for PR-aware commands and workflows

## Installation

```bash
gem install ace-git
```

## 1. Check Repository Context

Start with the repo snapshot command:

```bash
ace-git status
```

This shows your current branch, tracking state, recent commits, and PR context when available.

## 2. Inspect the Diff

Use the summary format when you want a quick read on what changed:

```bash
ace-git diff --format summary
```

Switch to raw diff output later with `ace-git diff` when you need the full patch.

## 3. Open a Guided Workflow

Use `ace-nav` when you want to discover or load the rebase workflow entry point:

```bash
ace-nav wfi://git/rebase
```

When you are ready to run it directly, load the workflow with `ace-bundle wfi://git/rebase`.

## 4. Set Basic Preferences

Add project or user defaults in `.ace/git/config.yml`:

```yaml
git:
  default_branch: main
  remote: origin
  status:
    commits_limit: 5
```

Use this for preferences, not for redefining the workflow logic.

## Common Commands

| Goal | Command |
|------|---------|
| Show repo context | `ace-git status` |
| Show a quick diff summary | `ace-git diff --format summary` |
| Show branch tracking info | `ace-git branch` |
| Show PR metadata | `ace-git pr` |
| Show package version | `ace-git version` |

## Next Steps

- Load `wfi://github/pr/create` to open a structured PR workflow
- Load `wfi://github/pr/update` to refresh an existing PR description
- Load `wfi://git/reorganize-commits` to clean up branch history before review
- Run `ace-git --help` to browse command-level examples
