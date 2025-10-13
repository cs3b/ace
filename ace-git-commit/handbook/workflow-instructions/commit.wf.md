---
name: commit
allowed-tools: Bash, Read
description: Create well-structured Git commits using ace-git-commit's LLM-powered
  message generation
argument-hint: "[intention]"
doc-type: workflow
purpose: commit workflow instruction
update:
  frequency: on-change
  last-updated: '2025-09-26'
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

1. **Review changes** to understand what will be committed:
   ```bash
   git status
   git diff --stat
   ```

2. **Execute commit** based on scope:
   - All changes: `ace-git-commit`
   - With intention: `ace-git-commit -i "$intention"`
   - Specific files: `ace-git-commit file1 file2`
   - Only staged: `ace-git-commit --only-staged`
   - Dry run first: `ace-git-commit --dry-run -i "$intention"`

3. **Verify result**:
   ```bash
   git log -1 --oneline
   git status
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
