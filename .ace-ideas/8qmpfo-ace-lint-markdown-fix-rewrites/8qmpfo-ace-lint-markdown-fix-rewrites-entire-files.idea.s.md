---
id: 8qmpfo
status: pending
title: "ace-lint: markdown --fix is destructive -- Kramdown round-trip damages files"
tags: [ace-lint, bug, markdown]
created_at: "2026-03-23 16:57:26"
---

# ace-lint: markdown --fix is destructive -- Kramdown round-trip damages files

## Problem

Running `ace-lint --fix` on markdown files parses through Kramdown and rewrites the entire file via `document.to_kramdown`. This round-trip is lossy and causes:

1. **YAML frontmatter destroyed** -- `---` delimiters converted to `* * *` (horizontal rule), all keys flattened to a single line. Breaks ace-docs metadata parsing.
2. **Fenced code blocks converted to 4-space indent** with `{: .language-bash}` Kramdown annotations. GitHub doesn't render Kramdown annotations -- syntax highlighting lost.
3. **Markdown tables mangled** -- separator rows like `|-------|------|` truncated to `|----------`.
4. **HTML structure rewritten** -- `<div align="center">` gets `markdown="1"` added, badge links reformatted to multi-line, self-closing tags altered.
5. **Inline links converted to reference-style** -- `[ACE](url)` becomes `[ACE][1]` with `[1]: url` at bottom.
6. **Pipe characters escaped** -- `|` in pipe-separated nav rows becomes `\|`.

## Root Cause

`KramdownFormatter.format_file()` at `ace-lint/lib/ace/lint/molecules/kramdown_formatter.rb` line 19 does `File.write(file_path, result[:formatted_content])` unconditionally after Kramdown parse-and-serialize. The Kramdown AST doesn't preserve the original formatting -- it normalizes to its own style.

## Contrast with Ruby --fix

Ruby `--fix` uses StandardRB which makes surgical in-place corrections to specific violations. It doesn't reparse and rewrite the entire file. This is the correct model.

## Proposed Fixes

### Option A: Surgical markdown fixes only (recommended)
Change `--fix` for markdown to only fix specific violations that ace-lint reports (em-dashes, trailing whitespace, missing blank lines), not rewrite the whole file. Keep the current Kramdown validation for _detecting_ issues but don't use Kramdown's serializer for _fixing_ them.

### Option B: Guard rails on Kramdown output
Before writing, compare structural elements (frontmatter, code blocks, HTML, tables) and abort if Kramdown would change them. Only write if changes are limited to whitespace/style.

### Option C: Separate --format from --fix
Make `--fix` handle only lint violations surgically. Move Kramdown full-rewrite to a separate `--format` flag with prominent warnings. This way `--fix` is always safe.

## Evidence

Discovered 2026-03-23 when `ace-lint --fix` on ace-assign/ damaged 57 markdown files (CHANGELOG, docs, handbook, e2e tests). All had to be reverted. The Ruby `--fix` on the same package (41 .rb files) worked correctly.
