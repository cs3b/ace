---
name: as-release
description: Bump Version and Update Both CHANGELOGs
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(bundle:*)
  - Read
  - Edit
argument-hint: "[package-name] [patch|minor|major]"
last_modified: 2026-02-02
source: ace-handbook
warning: ALL steps must be completed - there are TWO separate CHANGELOG.md files
---

# Release Package

Complete version bump for a package including BOTH CHANGELOGs in a single commit.

## What Counts as "Code"?

In this system, **handbook content IS code**:

- Workflow instructions (`.wf.md`) define agent execution paths
- Guides (`.g.md`) define conventions and best practices
- Phase definitions (`.phase.yml`) define assignment behavior
- Skills (`SKILL.md`) define agent capabilities

Changes to these files modify agent behavior and should trigger releases, just like Ruby code changes.

**Files updated:**
- `ace-[package]/lib/ace/[package]/version.rb`
- `ace-[package]/CHANGELOG.md` (package changelog)
- `/CHANGELOG.md` (main project changelog)
- `/Gemfile.lock`

---

## Step 1: Bump package version

Run workflow: `ace-bundle wfi://release/bump-version`

Follow all steps (1-6). This updates version.rb, package CHANGELOG, and Gemfile.lock.

---

## Step 2: Update main CHANGELOG

Run workflow: `ace-bundle wfi://release/update-changelog`

Follow all steps (1-4). This updates the main project CHANGELOG.md.

---

## Step 3: Commit all package changes

Commit **all changed files** in the package directory plus root release files:

```bash
ace-git-commit \
  ace-[package]/ \
  CHANGELOG.md \
  Gemfile.lock \
  -i "release v[NEW_VERSION] for ace-[package]"
```

This lets the LLM analyze each scope's actual diff and assign appropriate commit types (e.g., `fix` for code changes, `chore` for changelog/lockfile). The `-i` flag provides release context without overriding per-scope message generation.

---

## File Locations Summary

| File | Location | Updated In |
|------|----------|------------|
| Package code | `ace-[package]/` (all changed files) | Before release |
| version.rb | `ace-[package]/lib/ace/[package]/version.rb` | Step 1 |
| Package CHANGELOG | `ace-[package]/CHANGELOG.md` | Step 1 |
| Main CHANGELOG | `/CHANGELOG.md` (project root) | Step 2 |
| Gemfile.lock | `/Gemfile.lock` (project root) | Step 1 |
