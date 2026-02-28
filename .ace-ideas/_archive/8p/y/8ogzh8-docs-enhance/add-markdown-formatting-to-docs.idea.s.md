---
id: 8ogzh8
status: done
title: 'Idea: Markdown Formatting Guide for Technical Docs'
tags: []
created_at: '2026-02-28 17:37:36'
---

# Idea: Markdown Formatting Guide for Technical Docs

**Captured**: 2026-01-17
**Origin**: Retro from vision.md cleanup session
**Tags**: docs, style-guide, markdown

## Problem

Technical markdown files (like vision.md) contain file trees, code examples, and structured content that should not be treated as prose. Currently there's no guidance distinguishing:

- **Prose markdown**: READMEs, blog posts, narrative documentation
- **Technical markdown**: Config references, architecture docs, API docs with file trees

## Observation

During vision.md cleanup, we learned:

1. **Em-dashes (—) are typographic, not plain-text** - In monospace fonts they're hard to distinguish from hyphens. Plain-text convention is ` - ` or ` -- `

2. **File trees belong in code blocks** - Not markdown lists with links
   - Links are lost but that's acceptable
   - Tree notation (`├──`, `└──`) provides visual hierarchy
   - Consistent with terminal output

3. **Nested structures clarify relationships** - Showing folder hierarchy makes override patterns visible:
   ```
   ace-git-commit/
   ├── handbook/prompts/
   │   └── git-commit.system.md    # package default

   .ace/
   ├── prompts/
   │   └── git-commit.system.md    # project override
   ```

## Proposed Guidelines

### For Technical Docs

- Use ` - ` (spaced hyphen) instead of em-dashes
- Use code blocks with tree notation for file structures
- Keep package/folder links in headers, not inline
- Align comments in tree blocks for readability

### Files to Apply

- `docs/*.md` - Technical documentation
- `**/README.md` in package dirs - Package references
- Workflow instructions showing file paths

## Implementation

Options:
1. A style guide section in docs/
2. An ace-lint rule to flag em-dashes
3. A template for technical docs

**Recommended**: Option 1 (style guide) - already created as `ace-docs/handbook/guides/markdown-style.g.md`. Consider this idea DONE.