---
id: 8qm3z8
title: selfimprove-readme-process
type: self-improvement
tags: [process-fix]
created_at: "2026-03-23 02:39:09"
status: done
---

# selfimprove-readme-process

## What Went Well

- The ace-task README rewrite produced a proven pattern that works well as a template
- Use Cases format naturally weaves skills, CLI commands, and ecosystem links together
- Nav row above demo gives readers quick doc access without scrolling

## What Could Be Improved

- Template was too rigid: Problem/Solution framing doesn't fit feature-rich packages
- Documentation links were buried at bottom instead of prominent nav row
- Quick Start duplicated Getting Started content
- No skill reference convention (missing `/as-` prefix)
- CLI commands weren't linked to usage docs
- "Handbook" link lacked subtitle explaining what it contains
- Agent described features from plan notes without reading implementation code
- Template predated logo addition

## Action Items

- [x] Rewrite README template to match proven ace-task pattern (logo, nav row, intro, Use Cases)
- [x] Update documentation guide README section with new structure, conventions, and anti-patterns
- [x] Add template/guide fields to document type config (`.ace/docs/config.yml` and defaults)
- [x] Embed template/guide into analysis context via `document_analysis_prompt.rb`
- [x] Add template/guide verification instructions to `document-analysis.md` prompt
- [x] Verify all ace-docs tests pass (209 tests, 0 failures)

