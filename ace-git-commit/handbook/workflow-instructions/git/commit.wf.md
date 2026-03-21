---
doc-type: workflow
title: Commit Workflow
purpose: commit workflow instruction
ace-docs:
  last-updated: 2026-03-15
  last-checked: 2026-03-21
---

# Commit Workflow

## Purpose

Create atomic Git commits with conventional format messages using ace-git-commit.

## Context

ace-git-commit automatically:
- Stages ALL changes by default (monorepo-friendly)
- Generates conventional commit messages via LLM
- Uses `glite` model (Gemini 2.0 Flash Lite) by default

## Variables

- `$intention`: Optional description to guide message generation (from argument)

## Instructions

1. **Repository status is embedded above** in `<current_repository_status>`.

   The current git state (status + diff summary) is already loaded in this workflow.
   Review it to understand what will be committed:
   - Which files are modified? (from status output)
   - How significant are the changes? (from diff --stat)
   - Is this the right scope for a single commit?

   No need to run git commands - the context is already provided.

   **Important**: Untracked files (`??` in status) ARE committable changes — `ace-git-commit` stages them by default.
   If status shows ANY modifications or untracked files, proceed to step 2.
   Only report "nothing to commit" if status is truly empty (no lines beyond the branch header).

2. **Execute commit** based on scope:
   - All changes: `ace-git-commit`
   - With intention: `ace-git-commit -i "$intention"`
   - Specific files: `ace-git-commit file1 file2`
   - Only staged: `ace-git-commit --only-staged`
   - Dry run first: `ace-git-commit --dry-run -i "$intention"`

3. **Verify result**:
   ```bash
   ace-git status
   ```

## Options Reference

- `-i, --intention`: Provide context for better messages
- `-m, --message`: Use direct message (bypass LLM)
- `--model MODEL`: Override LLM model (e.g., gflash)
- `-s, --only-staged`: Commit only staged changes
- `-n, --dry-run`: Preview without committing
- `-d, --debug`: Enable debug output

## Success Criteria

- Commit created with conventional format
- Only intended changes included
- Working directory in expected state

## Response Template

**Changes Committed:** [Brief summary of what was committed]
**Commit Message:** [The generated/used message]
**Files Modified:** [Number of files and brief description]
**Status:** ✓ Complete | ✗ Failed with [reason]