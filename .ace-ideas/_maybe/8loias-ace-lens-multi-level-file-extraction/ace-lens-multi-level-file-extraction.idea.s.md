---
title: "ace-lens: Multi-Level File Content Extraction"
filename_suggestion: ace-lens-multi-level-file-extraction
enhanced_at: 2026-03-05 00:00:00.000000000 +00:00
llm_model: claude-opus-4-6
id: 8loias
status: pending
tags:
- new-gem
- context
- parsing
created_at: '2025-10-25 12:11:58'
source: user
---

# ace-lens: Multi-Level File Content Extraction

## What I Hope to Accomplish

Create a tool that extracts file content at configurable detail levels without requiring an LLM for the structural work. For example: load only frontmatter, or title + subtitles (with configurable heading depth), or only comments, or only public method signatures with their documentation. This gives agents and workflows precise control over how much context they consume from a file -- from a skeleton overview down to full content. An optional LLM pass can generate summaries at each level for richer context compression.

## What "Complete" Looks Like

- **ace-lens gem** that reads source files and extracts content at requested detail levels
- **Predefined lenses**: `frontmatter`, `outline` (headings to configurable depth), `signatures` (public method definitions + docs), `comments`, `full`
- **Language-aware parsing**: Ruby (method defs, class/module structure, YARD docs), Markdown (frontmatter, headings, sections), YAML (top-level keys, nested structure)
- **CLI interface**:
  ```
  ace-lens show path/to/file.rb --level signatures
  ace-lens show path/to/spec.md --level outline --depth 2
  ace-lens show path/to/config.yml --level keys
  ```
- **Programmatic API** for use within other ace-* gems (e.g., ace-bundle could use lenses to control context size)
- **Optional LLM summarization**: `ace-lens summarize path/to/file.rb --level signatures` generates a concise summary via ace-llm

## Success Criteria

- Structural extraction (frontmatter, outline, signatures, comments) works without any LLM calls
- At least Ruby, Markdown, and YAML file types supported with language-aware parsing
- Configurable depth/detail controls how much content is returned
- Output is deterministic and parseable (suitable for agent consumption)
- Integrates with ace-bundle as a context-reduction strategy

---

## Original Idea

```
ace-lens -> so we can see files on different levels, eg: we want to load certain section frontmatter, title, subtitles (with levels scope), or we want only comments, only public methods definition with documentation, etc ... as much we can do without the llm, and also have llm can fast create different level summaries
```
