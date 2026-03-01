---
id: 8ogzgn
title: "vision.md Typography & Formatting Cleanup"
type: conversation-analysis
tags: []
created_at: "2026-01-17 23:38:29"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8ogzgn-vision-md-typography-cleanup.md
---
# Reflection: vision.md Typography & Formatting Cleanup

**Date**: 2026-01-17
**Context**: Session cleaning up vision.md - replacing em-dashes and reformatting file tree examples
**Author**: Claude + User
**Type**: Conversation Analysis

## What Went Well

- Plan was clear and actionable - specific line numbers and transformations
- Iterative refinement worked well - user guided formatting improvements step by step
- Final tree-style formatting is consistent with other blocks in the document
- Em-dash replacement completed systematically across all 15 instances

## What Could Be Improved

- Initial `replace_all` approach required multiple passes for spacing
  - First pass: ` — ` to ` -` (spaced em-dash)
  - Second pass: `—` to ` -` (unspaced em-dash)
  - Third pass: Fix missing trailing spaces (` -word` to ` - word`)
- Should have anticipated the spacing issue and done it in one careful pass

## Key Learnings

- **Em-dashes are typographic, not plain-text**: In monospace/markdown source, em-dashes (—) are hard to distinguish, require special input, and the plain-text convention is ` - ` or ` -- `
- **Code blocks lose links**: When converting markdown lists with links to code blocks, the links are lost - preserve important links in surrounding text
- **Tree-style formatting for file structures**: Using `├──`, `└──`, and `│` creates consistent visual hierarchy that matches file system conventions
- **Show nested structures to clarify relationships**: Showing `handbook/prompts/` with `└── git-commit.system.md` nested inside makes the override relationship with `.ace/prompts/git-commit.system.md` clearer

## Improvement Proposals

### Documentation Improvements

- **Markdown formatting guide for technical docs**: Documents like vision.md that show file trees should follow consistent formatting rules - treat them differently from prose
- **Code block vs. list heuristic**: When showing file paths, prefer code blocks with tree notation over markdown lists with inline links

### Tool Enhancements

- **ace-lint rule for em-dashes in markdown**: Could flag em-dashes in .md files as a style issue

## Action Items

### Start Doing

- Document formatting conventions for "system file tree" style in technical docs
- Consider file trees in code blocks as the default for showing package structure

## Technical Details

**Before:**
```markdown
- [`.ace-defaults/git/commit.yml`](../link) — model config
```

**After:**
```
ace-git-commit/
├── .ace-defaults/git/commit.yml     # model config
├── handbook/prompts/
│   └── git-commit.system.md         # commit style
```

## Additional Context

- Task: #218 - Restructure vision.md to focused manifesto
- Branch: `218-restructure-visionmd-to-focused-manifesto`
- Changes committed in: `26e213843`
