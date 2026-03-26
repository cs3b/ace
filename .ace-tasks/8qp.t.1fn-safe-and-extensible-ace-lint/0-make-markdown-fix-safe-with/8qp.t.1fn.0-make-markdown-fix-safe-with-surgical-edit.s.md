---
id: 8qp.t.1fn.0
status: pending
priority: medium
created_at: "2026-03-26 00:57:55"
estimate: TBD
dependencies: []
tags: [ace-lint, fix, markdown, bug]
parent: 8qp.t.1fn
bundle:
  presets: [project]
  files: [ace-lint/lib/ace/lint/organisms/lint_orchestrator.rb, ace-lint/lib/ace/lint/molecules/kramdown_formatter.rb, ace-lint/lib/ace/lint/molecules/markdown_linter.rb, ace-lint/lib/ace/lint/molecules/ruby_linter.rb, ace-lint/lib/ace/lint/atoms/kramdown_parser.rb, ace-lint/lib/ace/lint/models/lint_result.rb, ace-lint/lib/ace/lint/models/validation_error.rb, ace-lint/test/molecules/markdown_linter_test.rb, ace-lint/lib/ace/lint/cli/commands/lint.rb]
  commands: []
needs_review: false
---

## Review Questions (Resolved 2026-03-26)

All questions resolved. Answers integrated into spec below.

- [x] **[HIGH-A1] Blank-line fixability:** Yes, `--fix` auto-fixes missing blank lines (structural insertions included).
- [x] **[HIGH-A2] Code block false positives:** Yes, fix `check_markdown_style` to track code block state — added as deliverable.
- [x] **[HIGH-A3] Trailing whitespace:** Add trailing whitespace detection to `MarkdownLinter` — added as deliverable.
- [x] **[HIGH-A4] Exit code 2:** Yes, introduce exit code 2 for the main lint path (fatal errors).
- [x] **[MED-A1] `--fix --format` combined:** Surgical first, then kramdown-with-guardrails.
- [x] **[MED-A2] Skill/workflow/agent types:** Same surgical treatment as markdown.
- [x] **[MED-A3] Ordered lists:** Only unordered lists detected currently; ordered lists is separate enhancement.
- [x] **[MED-A4] `-f` alias transition:** Noted as intentional breaking behavioral change.
- [x] **[MED-A5] A's exit codes:** Simplified to success/error; violation-counting reserved for subtask B.

# Make Markdown Fix Safe with Surgical Edit Model

## Objective

Fix the destructive behavior of `ace-lint --fix` on markdown files. Currently, `--fix` routes markdown through a Kramdown parse-and-serialize round-trip that rewrites entire files, destroying frontmatter, code blocks, tables, HTML structure, and link styles. This was discovered 2026-03-23 when it damaged 57 files in ace-assign/. The fix should make `--fix` for markdown work like Ruby's `--fix` — applying surgical, line-level edits to specific violations only.

Additionally, this subtask fixes a pre-existing safety-critical bug in `check_markdown_style` (does not track fenced code block state, producing false positives for headings/lists inside code blocks) and adds trailing whitespace detection to `MarkdownLinter` (currently missing but needed for the surgical fixer to act on).

## Behavioral Specification

### User Experience

- **Input:** User runs `ace-lint --fix <markdown-files>` or `ace-lint --format <markdown-files>`
- **Process (`--fix`):** Each markdown file is scanned for fixable violations. Only the specific lines containing violations are modified. The file's overall structure (frontmatter, code blocks, tables, HTML, links) is never altered.
- **Process (`--format`):** The Kramdown round-trip is applied, but with a structural integrity check before writing. If the round-trip would damage frontmatter, code blocks, tables, or HTML, the write is aborted and the user is warned.
- **Output (`--fix`):** Files are updated in place with only targeted fixes. The report shows which violations were fixed. Exit code 0 if fix succeeded, exit code 1 if fix encountered errors. (Violation-counting exit codes are added by subtask B.)
- **Output (`--format`):** Files are rewritten with Kramdown normalization if safe. If unsafe, a per-file warning is emitted and the file is skipped.

### Expected Behavior

1. `ace-lint --fix` on markdown (and markdown-based types: skill, workflow, agent) applies surgical fixes for these specific violations:
   - **Em-dash replacement:** Replace `—` with `--` (outside code blocks and inline code)
   - **Smart quote replacement:** Replace `"` `"` `'` `'` with ASCII equivalents (outside code blocks and inline code)
   - **Trailing whitespace removal:** Remove trailing spaces/tabs from lines (new detection added to `MarkdownLinter`)
   - **Missing trailing newline:** Append `\n` if file doesn't end with one
   - **Missing blank lines:** Insert blank line before/after headings, unordered lists, and code blocks where the linter reports them missing (ordered list detection is a separate enhancement)

2. `ace-lint --fix` on markdown does **NOT**:
   - Reparse and serialize the entire file through Kramdown
   - Alter YAML frontmatter in any way
   - Convert fenced code blocks to indented blocks
   - Change link styles (inline vs. reference)
   - Escape pipe characters
   - Add Kramdown annotations (`{: .language-*}`)
   - Modify HTML structure or attributes
   - Modify content inside fenced code blocks or inline code spans

3. `ace-lint --format` retains Kramdown behavior but adds structural integrity pre-check:
   - Before writing, compare original vs. formatted content for structural damage signatures
   - If frontmatter would be altered (compare frontmatter section pre/post), skip file and warn
   - If fenced code block count changes, skip file and warn
   - If table row count changes, skip file and warn
   - If HTML blocks would gain new attributes, skip file and warn

4. Ruby `--fix` behavior is completely unchanged.

5. `--fix --format` combined in a single invocation: surgical fix runs first, then `--format` applies kramdown-with-guardrails on the already-fixed file.

6. **Pre-requisite fix:** `check_markdown_style` must track fenced code block state (same pattern as `check_typography`). Without this, false positive warnings for headings/lists inside code blocks would cause the surgical fixer to damage code blocks — the exact failure mode this task prevents.

7. **New detection:** Add trailing whitespace check to `MarkdownLinter.check_markdown_style` (simple line-level check: `/[ \t]+$/`). Currently not detected for markdown.

8. **Breaking behavioral change (intentional):** `-f` / `--fix` changes from Kramdown round-trip (destructive) to surgical edits (safe). Same flag, safer behavior.

### Interface Contract

```bash
# Surgical fix — safe for all markdown files (and skill, workflow, agent types)
ace-lint --fix README.md docs/**/*.md
# Fixes specific violations only, never alters structure
# Exit 0: fix succeeded without errors
# Exit 1: fix encountered errors

# Full Kramdown rewrite — opt-in, with safety guardrails
ace-lint --format README.md
# "Formatted: README.md" or "Skipped: README.md (structural change detected: frontmatter, code blocks)"
# Exit 0: all files formatted or safely skipped
# Exit 1: formatting errors

# Combined: surgical first, then kramdown-with-guardrails
ace-lint --fix --format README.md

# Sequential workflow
ace-lint --fix README.md     # fix violations
ace-lint README.md           # verify remaining violations
```

Error Handling:

- File not found: Same behavior as today (error in result)
- Fix would create invalid markdown: Do not write, report as unfixable violation
- `--format` structural damage detected: Skip file, emit warning with specific damage category, continue to next file
- File with zero violations: `--fix` is a no-op (does not write identical content)

Edge Cases:

- File with only frontmatter and no body: `--fix` is a no-op
- File with nested code blocks (triple-backtick inside a code block): Surgery respects code block nesting depth
- Binary or non-UTF8 file: Skip with warning
- Em-dash inside inline code (`\`code—here\``): Not fixed (correctly skipped)

### Success Criteria

- [ ] `ace-lint --fix` on the 57 previously-damaged ace-assign markdown files produces zero structural changes (frontmatter, code blocks, tables, HTML, links all preserved)
- [ ] `ace-lint --fix` correctly fixes em-dashes and smart quotes without altering surrounding content
- [ ] `ace-lint --fix` correctly fixes trailing whitespace on markdown lines
- [ ] `ace-lint --fix` correctly inserts missing blank lines at precise locations
- [ ] `ace-lint --fix` does not modify content inside code blocks or inline code
- [ ] `check_markdown_style` does not produce false positive warnings inside fenced code blocks
- [ ] `ace-lint --fix` works identically on skill, workflow, and agent file types (markdown-based)
- [ ] `ace-lint --fix --format` applies surgical fix first, then kramdown-with-guardrails
- [ ] `ace-lint --format` skips files where Kramdown round-trip would damage structure, with clear warning
- [ ] Ruby `--fix` behavior is completely unchanged
- [ ] Exit codes: 0 for fix succeeded without errors, 1 for fix encountered errors (violation-counting exit codes reserved for subtask B)

### Validation Questions

- [x] **`--fix` vs `--format` semantics:** `--fix` = surgical for violations, `--format` = full rewrite with guardrails. Confirmed.
- [x] **Missing blank line fixes:** Yes, include them. Structural insertions are low-risk and high-value. Confirmed 2026-03-26.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type:** Subtask of orchestrator 8qp.t.1fn
- **Slice outcome:** `ace-lint --fix` on markdown produces only surgical, line-level edits; `--format` has guardrails
- **Advisory size:** Medium
- **Context dependencies:** See bundle.files in frontmatter

## Verification Plan

### Unit / Component Validation

- [ ] Surgical fixer on content with em-dash returns content with `--`, nothing else changed
- [ ] Surgical fixer on content with smart quotes returns content with ASCII quotes, nothing else changed
- [ ] Surgical fixer on content with missing blank lines inserts blank lines at correct positions only
- [ ] Surgical fixer on content with no violations returns identical content (no mutation)
- [ ] Surgical fixer never alters frontmatter section
- [ ] Surgical fixer never alters content inside fenced code blocks
- [ ] Surgical fixer respects inline code spans (no fixes inside backticks)
- [ ] Surgical fixer removes trailing whitespace from lines (outside code blocks)
- [ ] `check_markdown_style` with heading inside fenced code block produces no false warning
- [ ] `check_markdown_style` detects trailing whitespace on markdown lines
- [ ] Surgical fixer works on skill/workflow/agent file types identically to markdown
- [ ] `--fix --format` combined: surgical runs first, then kramdown-with-guardrails
- [ ] `KramdownFormatter.format_file` with structural damage detection skips file and returns warning

### Integration / E2E Validation

- [ ] `ace-lint --fix` on a file with known em-dashes and smart quotes fixes them without altering frontmatter
- [ ] `ace-lint --fix` on a file with complex structure (tables, HTML, code blocks, frontmatter) fixes only typography and whitespace violations
- [ ] `ace-lint --format` on a file with YAML frontmatter skips it when frontmatter would be damaged

### Failure / Invalid-Path Validation

- [ ] `ace-lint --fix` on a non-existent file returns error result
- [ ] `ace-lint --format` on a file where Kramdown would destroy frontmatter: file is not modified, warning emitted
- [ ] `ace-lint --fix` on a binary file: skipped with warning

### Verification Commands

- [ ] `ace-test ace-lint` — full test suite passes
- [ ] `ace-lint --fix ace-assign/**/*.md && git diff` — confirm only targeted violations changed, no structural damage
