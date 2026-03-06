---
title: "Meta: Review Guides"
command: "meta-review-guides"
description: "Review and validate development guides for quality and consistency"
author: "handbook"
tools_restricted: true
tools_allowed: Read, Glob, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: "1.0.0"
---

# Meta: Review Guides

Review and validate development guides for quality and consistency.

## Usage

Type `/as-handbook-review-guides [guide-name]` where:
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
/as-handbook-review-guides
/as-handbook-review-guides testing-strategy
/as-handbook-review-guides code-review
```

## Full Workflow

For detailed instructions, see: @ace-handbook/handbook/workflow-instructions/review-guides.wf.md