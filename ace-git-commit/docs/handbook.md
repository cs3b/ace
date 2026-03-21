---
doc-type: user
title: ace-git-commit Handbook Reference
purpose: Documentation for ace-git-commit/docs/handbook.md
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# ace-git-commit Handbook Reference

Skill, workflow, guide, and prompts shipped with ace-git-commit.

## Skills

| Skill | What it does |
|-------|-------------|
| `as-git-commit` | Generate intelligent commit message from staged or all changes, with optional intention context |

## Workflow Instructions

| Protocol Path | Description | Invoked by |
|--------------|-------------|------------|
| `wfi://git/commit` | Create atomic Git commits with conventional format messages using embedded repository status | `as-git-commit` |

## Guides

| Guide | Purpose |
|-------|---------|
| `version-control-system-message.g.md` | Comprehensive Conventional Commits guide — types, scopes, subject rules, body/footer conventions, breaking changes, anti-patterns, and integration with semantic versioning |

## Prompts

| Prompt | Purpose |
|--------|---------|
| `git-commit.system.md` | System prompt for LLM commit message generation — format spec, analysis process, type/scope selection rules, examples |
| `git-commit.md` | User-facing prompt template — task description, guidelines, response format |
