---
name: ace-release
description: Bump Version and Update Both CHANGELOGs
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
  - Edit
argument-hint: "[package-name] [patch|minor|major]"
last_modified: 2025-12-23
source: ace-handbook
warning: ALL 3 steps must be completed - there are TWO separate CHANGELOG.md files
---

# Release Package

Complete version bump for a package including BOTH CHANGELOGs:

1. **Package CHANGELOG** (`ace-[package]/CHANGELOG.md`) - semantic versioning
2. **Main project CHANGELOG** (`/CHANGELOG.md`) - release-based versioning

---

## Step 1: Ensure all changes are committed
Action: Skill('/ace:commit')

---

## Step 2: Bump package version (updates package CHANGELOG)
Action: Skill('/ace-bump-version $package-name $level')

This updates:
- `lib/ace/[package]/version.rb` (e.g., 0.23.1 → 0.24.0)
- `ace-[package]/CHANGELOG.md` (package-specific changelog)
- `Gemfile.lock`

---

## Step 3: Update main project CHANGELOG ⚠️ OFTEN MISSED
Action: Skill('/ace-update-changelog')

This updates:
- `/CHANGELOG.md` at project root (main changelog)
- Version follows current release (e.g., 0.9.179 → 0.9.180)

⚠️ **IMPORTANT**: This is a DIFFERENT file than the package CHANGELOG from step 2!

---

## File Locations Summary

| File | Location | Updated In |
|------|----------|------------|
| version.rb | `ace-[package]/lib/ace/[package]/version.rb` | Step 2 |
| Package CHANGELOG | `ace-[package]/CHANGELOG.md` | Step 2 |
| Main CHANGELOG | `/CHANGELOG.md` (project root) | **Step 3** |
| Gemfile.lock | `/Gemfile.lock` (project root) | Step 2 |
