---
name: as-handbook-review-guides
title: "Meta: Review Guides"
command: meta-review-guides
description: Review and validate development guides for quality and consistency
# context: no-fork
# agent: general-purpose
user-invocable: true
author: handbook
model_preference: claude-3-5-sonnet-latest
version: 1.0.0
last_modified: 2026-01-10
source: custom
allowed-tools:
  - Bash(ace-handbook:*)
  - Bash(ace-bundle:*)
  - Read
  - Glob
  - LS
  - TodoWrite
argument-hint: [guide-name]
---

# Meta: Review Guides

Review and validate development guides for quality and consistency.

## Usage

Type `/ace-handbook-review-guides [guide-name]` where:
- `guide-name` is optional - if not provided, reviews all guides

## What This Does

This meta workflow helps you:
1. Review guides for completeness and accuracy
2. Check consistency across related guides
3. Validate examples and code snippets
4. Ensure guides follow handbook standards
5. Identify outdated or missing information

## Process

The workflow will:
1. Load and analyze specified guide(s)
2. Check structure and formatting
3. Validate cross-references and links
4. Review examples for correctness
5. Generate review report with recommendations

## Examples

```
/ace-handbook-review-guides
/ace-handbook-review-guides testing-strategy
/ace-handbook-review-guides code-review
```

## Full Workflow

For detailed instructions, see: ace-bundle wfi://handbook/review-guides
