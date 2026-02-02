---
name: ace-release
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

**Files updated:**
- `ace-[package]/lib/ace/[package]/version.rb`
- `ace-[package]/CHANGELOG.md` (package changelog)
- `/CHANGELOG.md` (main project changelog)
- `/Gemfile.lock`

---

## Step 1: Bump package version

Run workflow: `ace-bundle wfi://ace-bump-version`

Follow all steps (1-6). This updates version.rb, package CHANGELOG, and Gemfile.lock.

---

## Step 2: Update main CHANGELOG

Run workflow: `ace-bundle wfi://ace-update-changelog`

Follow all steps (1-4). This updates the main project CHANGELOG.md.

---

## Step 3: Commit all release files

Use ace-git-commit with all release files:

```bash
ace-git-commit \
  ace-[package]/lib/ace/[package]/version.rb \
  ace-[package]/CHANGELOG.md \
  CHANGELOG.md \
  Gemfile.lock \
  -m "chore(ace-[package]): release v[NEW_VERSION]"
```

---

## File Locations Summary

| File | Location | Updated In |
|------|----------|------------|
| version.rb | `ace-[package]/lib/ace/[package]/version.rb` | Step 1 |
| Package CHANGELOG | `ace-[package]/CHANGELOG.md` | Step 1 |
| Main CHANGELOG | `/CHANGELOG.md` (project root) | Step 2 |
| Gemfile.lock | `/Gemfile.lock` (project root) | Step 1 |
